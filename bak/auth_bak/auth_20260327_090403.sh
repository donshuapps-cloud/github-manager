#!/usr/bin/env bash
#===============================================================================
# Gestión de Autenticación (SSH prioritario)
#===============================================================================
# Verificar conexión SSH
check_ssh() {
    log_info "$MSG_SSH_CHECK"
    # Verificar que existe clave SSH
    if [ ! -f "${SSH_KEY_PATH}" ] && [ ! -f "${HOME}/.ssh/id_rsa" ] && [ ! -f "${HOME}/.ssh/id_ed25519" ]; then
        log_warning "No se encontraron claves SSH en ~/.ssh/"
        log_info "   Buscado: id_ed25519, id_rsa"
        return 1
    fi
    # Probar conexión con GitHub - Capturar tanto stdout como stderr
    local ssh_output
    ssh_output=$(ssh -T git@github.com 2>&1)
    local ssh_exit_code=$?
    # Depuración
    log_debug "SSH exit code: $ssh_exit_code"
    log_debug "SSH output: $ssh_output"
    # Verificar diferentes formas de éxito
    if [ $ssh_exit_code -eq 0 ]; then
        # Éxito por código de salida
        log_success "$MSG_SSH_OK"
        export GIT_REMOTE_PREFIX="git@github.com:"
        export USE_SSH=true
        return 0
    elif echo "$ssh_output" | grep -q "successfully authenticated"; then
        # Éxito por mensaje
        log_success "$MSG_SSH_OK"
        export GIT_REMOTE_PREFIX="git@github.com:"
        export USE_SSH=true
        return 0
    elif echo "$ssh_output" | grep -q "You've successfully authenticated"; then
        # Éxito por mensaje alternativo
        log_success "$MSG_SSH_OK"
        export GIT_REMOTE_PREFIX="git@github.com:"
        export USE_SSH=true
        return 0
    elif echo "$ssh_output" | grep -q "Hi.*! You've successfully authenticated"; then
        # Éxito por mensaje con nombre de usuario
        log_success "$MSG_SSH_OK"
        export GIT_REMOTE_PREFIX="git@github.com:"
        export USE_SSH=true
        # Extraer nombre de usuario si es posible
        local github_user
        github_user=$(echo "$ssh_output" | grep -o "Hi [^!]*" | cut -d' ' -f2)
        if [ -n "$github_user" ] && [ -z "${GITHUB_USER:-}" ]; then
            GITHUB_USER="$github_user"
            log_info "Usuario GitHub detectado: $GITHUB_USER"
        fi
        return 0
    else
        # Error de autenticación
        log_error "No se pudo autenticar con GitHub via SSH"
        log_info "   Mensaje: $ssh_output"
        if echo "$ssh_output" | grep -q "permission denied"; then
            log_info "💡 La clave SSH no está agregada a GitHub"
            echo "$MSG_SSH_ADD_KEY"
        elif echo "$ssh_output" | grep -q "Host key verification failed"; then
            log_info "💡 Es la primera vez que te conectas. Acepta la huella digital:"
            log_info "   ssh -T git@github.com # y escribe 'yes'"
        fi
        return 1
    fi
}
# Verificar token
check_token() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        log_info "$MSG_TOKEN_FALLBACK"
        export GIT_REMOTE_PREFIX="https://oauth2:${GITHUB_TOKEN}@github.com/"
        export USE_SSH=false
        export USE_TOKEN=true
        # Verificar token con API
        local response
        response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
                        -H "Accept: application/vnd.github.v3+json" \
                        https://api.github.com/user 2>/dev/null)
        if echo "$response" | grep -q "login"; then
            local user
            user=$(echo "$response" | grep -o '"login":"[^"]*"' | cut -d'"' -f4)
            GITHUB_USER="${GITHUB_USER:-$user}"
            log_success "Token válido para usuario: ${GITHUB_USER}"
            return 0
        else
            log_error "Token inválido o expirado"
            return 1
        fi
    fi
    return 1
}
# Verificar GitHub CLI como alternativa
check_gh_cli() {
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            log_info "✅ GitHub CLI detectado y autenticado"
            export USE_GH_CLI=true
            export GIT_REMOTE_PREFIX="https://github.com/"
            return 0
        fi
    fi
    return 1
}
# Solicitar token interactivamente
prompt_for_token() {
    echo ""
    echo "$MSG_TOKEN_PROMPT"
    echo "💡 Puedes crear un token en: https://github.com/settings/tokens"
    echo "   (Necesita permisos: repo, workflow, write:packages)"
    echo ""
    read -s -p "Token: " GITHUB_TOKEN
    echo ""
    if [ -n "$GITHUB_TOKEN" ]; then
        export GITHUB_TOKEN
        log_success "$MSG_TOKEN_SAVED"
        return 0
    else
        log_error "Token no proporcionado"
        return 1
    fi
}
# Configurar autenticación (prioridad SSH)
setup_authentication() {
    log_info "Configurando autenticación..."
    # Prioridad 1: SSH
    if check_ssh; then
        log_success "Autenticación SSH configurada"
        return 0
    fi
    # Prioridad 2: GitHub CLI
    if check_gh_cli; then
        log_success "Autenticación con GitHub CLI configurada"
        return 0
    fi
    # Prioridad 3: Token en variable de entorno
    if check_token; then
        log_success "Autenticación con token configurada"
        return 0
    fi
    # Prioridad 4: Solicitar token interactivamente
    echo ""
    log_warning "No se encontró autenticación válida"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 Opciones:"
    echo "   1) Configurar SSH (recomendado)"
    echo "   2) Usar token (alternativa)"
    echo "   3) Usar GitHub CLI (gh)"
    echo "   4) Salir"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "$MSG_SELECT_OPTION " auth_choice
    case $auth_choice in
        1)
            echo ""
            echo "$MSG_SSH_HELP"
            echo "$MSG_SSH_ADD_KEY"
            echo ""
            echo "🔧 Comando para probar SSH:"
            echo "   ssh -T git@github.com"
            echo ""
            read -p "¿Has configurado SSH? (s/n): " ssh_configured
            if [[ "$ssh_configured" =~ ^[Ss]$ ]]; then
                setup_authentication  # Reintentar
            else
                log_info "Puedes configurar SSH ahora o usar token como alternativa."
                prompt_for_token
            fi
            ;;
        2)
            prompt_for_token
            ;;
        3)
            if command -v gh &> /dev/null; then
                log_info "Ejecutando 'gh auth login' para configurar..."
                gh auth login
                setup_authentication
            else
                log_error "GitHub CLI no está instalado"
                log_info "Instálalo con: https://cli.github.com/"
                prompt_for_token
            fi
            ;;
        4)
            log_error "Autenticación requerida para continuar"
            exit 1
            ;;
        *)
            log_error "$MSG_INVALID_OPTION"
            setup_authentication  # Reintentar
            ;;
    esac
}
# Obtener URL remota según método de autenticación
get_remote_url() {
    local repo_name="$1"
    local user="${GITHUB_USER:-$(git config user.name 2>/dev/null)}"
    if [ "${USE_SSH:-false}" = true ]; then
        echo "git@github.com:${user}/${repo_name}.git"
    elif [ "${USE_GH_CLI:-false}" = true ]; then
        echo "https://github.com/${user}/${repo_name}.git"
    else
        echo "https://github.com/${user}/${repo_name}.git"
    fi
}
# Exportar funciones
export -f check_ssh
export -f check_token
export -f check_gh_cli
export -f setup_authentication
export -f get_remote_url
