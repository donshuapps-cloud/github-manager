#!/usr/bin/env bash
#===============================================================================
# Módulo 2: Inicializar repositorio en proyecto existente
#===============================================================================
# Función para crear repositorio usando GitHub CLI
create_repo_with_gh() {
    local repo_name="$1"
    local repo_desc="$2"
    local is_private="$3"
    local visibility="--public"
    if [ "$is_private" = "true" ]; then
        visibility="--private"
    fi
    log_info "Creando repositorio con GitHub CLI..."
    if gh repo create "$repo_name" $visibility --description "$repo_desc" --source=. --remote=origin --push 2>&1; then
        log_success "Repositorio creado y sincronizado con GitHub CLI"
        return 0
    else
        log_error "Error al crear repositorio con GitHub CLI"
        return 1
    fi
}
# Función para crear repositorio usando API con token
create_repo_with_token() {
    local repo_name="$1"
    local repo_desc="$2"
    local private_flag="$3"
    log_info "Creando repositorio vía API con token..."
    local response
    local api_url="https://api.github.com/user/repos"
    response=$(curl -s -X POST "$api_url" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{
            \"name\": \"${repo_name}\",
            \"description\": \"${repo_desc}\",
            \"private\": ${private_flag},
            \"auto_init\": false
        }")
    if echo "$response" | grep -q '"html_url"'; then
        local repo_url
        repo_url=$(echo "$response" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)
        log_success "$MSG_REPO_CREATED"
        log_info "$MSG_REPO_URL $repo_url"
        # Configurar remote y push
        local remote_url
        if [ "${USE_SSH:-false}" = true ]; then
            remote_url="git@github.com:${GITHUB_USER}/${repo_name}.git"
        else
            remote_url="https://github.com/${GITHUB_USER}/${repo_name}.git"
        fi
        git remote add origin "$remote_url"
        git branch -M main
        git push -u origin main
        return 0
    else
        log_error "$MSG_REPO_CREATE_FAIL"
        local error_msg
        error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        [ -n "$error_msg" ] && log_error "Detalles: $error_msg"
        return 1
    fi
}
repo_init() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "📁 INICIALIZAR REPOSITORIO EN PROYECTO EXISTENTE"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Solicitar ruta del proyecto
    local project_path
    read -p "$MSG_INIT_REPO_PATH " project_path
    if [ -z "$project_path" ]; then
        project_path="$(pwd)"
    fi
    # Verificar que la ruta existe
    if [ ! -d "$project_path" ]; then
        log_error "La ruta no existe: $project_path"
        return 1
    fi
    # Cambiar al directorio
    cd "$project_path" || return 1
    # Verificar si ya es repositorio git
    if [ -d ".git" ]; then
        log_warning "$MSG_REPO_ALREADY_INIT"
        # Mostrar información del remote si existe
        if git remote -v | grep -q origin; then
            log_info "Remote origin actual:"
            git remote -v
        fi
        read -p "¿Deseas continuar y configurar GitHub? (s/n): " continue_init
        if [[ ! "$continue_init" =~ ^[Ss]$ ]]; then
            return 0
        fi
    else
        log_info "$MSG_INIT_GIT"
        git init
        log_success "Git inicializado"
    fi
    # Solicitar nombre del repositorio en GitHub
    echo ""
    read -p "$MSG_REPO_NAME " repo_name
    while [ -z "$repo_name" ]; do
        log_error "$MSG_VALIDATE_NAME"
        read -p "$MSG_REPO_NAME " repo_name
    done
    # Solicitar descripción
    read -p "$MSG_REPO_DESC " repo_desc
    # Solicitar privacidad
    while true; do
        read -p "$MSG_REPO_PRIVATE " is_private_input
        if [[ "$is_private_input" =~ ^[Ss]$ ]] || [[ "$is_private_input" =~ ^[Yy]$ ]] || [ "$is_private_input" = "$MSG_YES" ] || [ "$is_private_input" = "$MSG_YES_CAPS" ]; then
            private_flag="true"
            break
        elif [[ "$is_private_input" =~ ^[Nn]$ ]] || [ "$is_private_input" = "$MSG_NO" ] || [ "$is_private_input" = "$MSG_NO_CAPS" ]; then
            private_flag="false"
            break
        elif [ -z "$is_private_input" ]; then
            # Por defecto: público
            private_flag="false"
            break
        else
            log_error "$MSG_VALIDATE_YES_NO"
        fi
    done
    echo ""
    # Detectar método de creación disponible
    local use_gh=false
    local use_token=false
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        use_gh=true
        log_info "✅ GitHub CLI detectado y autenticado"
    elif [ -n "${GITHUB_TOKEN:-}" ]; then
        use_token=true
        log_info "✅ Token de GitHub detectado"
    else
        log_error "No se encontró autenticación válida para crear repositorio"
        echo ""
        echo "📌 Opciones disponibles:"
        echo "   1) Instalar y autenticar GitHub CLI (recomendado)"
        echo "      gh auth login"
        echo ""
        echo "   2) Configurar token manualmente:"
        echo "      export GITHUB_TOKEN=\"tu_token\""
        echo ""
        return 1
    fi
    # Crear repositorio
    if [ "$use_gh" = true ]; then
        if create_repo_with_gh "$repo_name" "$repo_desc" "$private_flag"; then
            log_success "Repositorio inicializado exitosamente"
        else
            log_error "Error al inicializar repositorio con GitHub CLI"
            return 1
        fi
    elif [ "$use_token" = true ]; then
        if create_repo_with_token "$repo_name" "$repo_desc" "$private_flag"; then
            log_success "Repositorio inicializado exitosamente"
        else
            log_error "Error al inicializar repositorio con token"
            return 1
        fi
    fi
}
# Exportar función
export -f repo_init
