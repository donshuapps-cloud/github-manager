#!/usr/bin/env bash
#===============================================================================
# Módulo 2: Inicializar repositorio en proyecto existente
#===============================================================================
repo_init() {
    echo ""
    echo "$MSG_INIT_REPO_TITLE"
    echo "$MSG_INIT_REPO_HEADER"
    echo ""
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
        read -p "$MSG_REPO_PRIVATE " is_private
        if [[ "$is_private" =~ ^[Ss]$ ]] || [[ "$is_private" =~ ^[Yy]$ ]] || [ "$is_private" = "$MSG_YES" ] || [ "$is_private" = "$MSG_YES_CAPS" ]; then
            private_flag="true"
            break
        elif [[ "$is_private" =~ ^[Nn]$ ]] || [ "$is_private" = "$MSG_NO" ] || [ "$is_private" = "$MSG_NO_CAPS" ]; then
            private_flag="false"
            break
        else
            log_error "$MSG_VALIDATE_YES_NO"
        fi
    done
    echo ""
    log_info "Creando repositorio '${repo_name}' en GitHub..."
    # Verificar token para API
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_error "Se requiere token para crear repositorio vía API"
        return 1
    fi
    # Crear repositorio en GitHub
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
    # Verificar respuesta
    if echo "$response" | grep -q '"html_url"'; then
        local repo_url
        repo_url=$(echo "$response" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)
        log_success "$MSG_REPO_CREATED"
        log_info "$MSG_REPO_URL $repo_url"
        # Verificar si ya hay commits
        if ! git rev-parse HEAD &>/dev/null; then
            log_info "$MSG_INIT_FIRST_COMMIT"
            # Crear README si no existe
            if [ ! -f "README.md" ]; then
                echo "# ${repo_name}" > README.md
                [ -n "$repo_desc" ] && echo "" >> README.md && echo "$repo_desc" >> README.md
                log_info "README.md creado"
            fi
            git add .
            git commit -m "Initial commit: ${repo_name}"
        fi
        # Configurar remote
        log_info "$MSG_REPO_ADD_REMOTE"
        local remote_url
        remote_url=$(get_remote_url "$repo_name")
        # Verificar si ya existe remote origin
        if git remote | grep -q origin; then
            git remote set-url origin "$remote_url"
            log_info "Remote origin actualizado"
        else
            git remote add origin "$remote_url"
            log_info "Remote origin agregado"
        fi
        # Push
        log_info "$MSG_REPO_PUSH_FIRST"
        # Obtener branch actual
        local current_branch
        current_branch=$(git branch --show-current)
        if [ -z "$current_branch" ]; then
            current_branch="main"
            git branch -M main
        fi
        git push -u origin "$current_branch"
        log_success "¡Repositorio sincronizado exitosamente!"
    elif echo "$response" | grep -q '"message":"Repository creation failed"'; then
        log_error "$MSG_REPO_EXISTS"
        return 1
    else
        log_error "$MSG_REPO_CREATE_FAIL"
        local error_msg
        error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        [ -n "$error_msg" ] && log_error "Detalles: $error_msg"
        return 1
    fi
}
# Exportar función
export -f repo_init
