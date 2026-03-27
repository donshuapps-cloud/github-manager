#!/usr/bin/env bash
#===============================================================================
# Gestión de Autenticación (SSH prioritario)
#===============================================================================
# Verificar conexión SSH
check_ssh() {
    log_info "$MSG_SSH_CHECK"
    # Verificar que existe clave SSH
    if [ ! -f "${SSH_KEY_PATH}" ] && [ ! -f "${HOME}/.ssh/id_rsa" ]; then
        log_warning "No se encontraron claves SSH"
        return 1
    fi
    # Probar conexión con GitHub
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_success "$MSG_SSH_OK"
        export GIT_REMOTE_PREFIX="git@github.com:"
        export USE_SSH=true
        return 0
    elif ssh -T git@github.com 2>&1 | grep -q "permission denied"; then
        log_error "Permiso denegado. La clave SSH no está agregada a GitHub"
        echo "$MSG_SSH_ADD_KEY"
        return 1
    else
        log_error "Error al conectar con GitHub via SSH"
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
    # Prioridad 2: Token en variable de entorno
    if check_token; then
        log_success "Autenticación con token configurada"
        return 0
    fi
    # Prioridad 3: Solicitar token interactivamente
    echo ""
    log_warning "No se encontró autenticación válida"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 Opciones:"
    echo "   1) Configurar SSH (recomendado)"
    echo "   2) Usar token (alternativa)"
    echo "   3) Salir"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "$MSG_SELECT_OPTION " auth_choice
    case $auth_choice in
        1)
            echo ""
            echo "$MSG_SSH_HELP"
            echo "$MSG_SSH_ADD_KEY"
            echo ""
            read -p "¿Has configurado SSH? (s/n): " ssh_configured
            if [[ "$ssh_configured" =~ ^[Ss]$ ]]; then
                setup_authentication  # Reintentar
            else
                log_error "No se pudo configurar SSH. Usando token como alternativa."
                prompt_for_token
            fi
            ;;
        2)
            prompt_for_token
            ;;
        3)
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
    else
        echo "https://github.com/${user}/${repo_name}.git"
    fi
}
# Exportar funciones
export -f check_ssh
export -f check_token
export -f setup_authentication
export -f get_remote_url
