#!/usr/bin/env bash
#===============================================================================
# Módulo 1: Crear nuevo repositorio desde cero
#===============================================================================
repo_create() {
    echo ""
    echo "$MSG_CREATE_REPO_TITLE"
    echo "$MSG_CREATE_REPO_HEADER"
    echo ""
    # Verificar que estamos en un directorio válido
    local current_dir
    current_dir=$(basename "$(pwd)")
    # Solicitar nombre del repositorio
    while true; do
        read -p "$MSG_REPO_NAME " repo_name
        if [ -z "$repo_name" ]; then
            log_error "$MSG_VALIDATE_NAME"
            continue
        fi
        # Validar nombre (solo letras, números, guiones, guiones bajos)
        if [[ ! "$repo_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            log_error "$MSG_VALIDATE_NAME_INVALID"
            continue
        fi
        break
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
    # Crear repositorio en GitHub
    local response
    local api_url="https://api.github.com/user/repos"
    # Verificar si usamos token (SSH no sirve para API)
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_error "Se requiere token para crear repositorio vía API"
        log_info "Configura GITHUB_TOKEN o usa SSH con GitHub CLI"
        return 1
    fi
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
        # Inicializar repositorio local
        echo ""
        log_info "$MSG_REPO_INIT_LOCAL"
        # Verificar si ya es un repositorio git
        if [ ! -d ".git" ]; then
            git init
            log_success "Git inicializado"
        else
            log_info "Repositorio Git ya existe"
        fi
        # Agregar archivo README inicial
        if [ ! -f "README.md" ]; then
            echo "# ${repo_name}" > README.md
            [ -n "$repo_desc" ] && echo "" >> README.md && echo "$repo_desc" >> README.md
            log_info "README.md creado"
        fi
        # Agregar .gitignore básico
        if [ ! -f ".gitignore" ]; then
            cat > .gitignore << EOF
# GitHub Repository Manager
github-manager/
# OS
.DS_Store
Thumbs.db
# IDE
.vscode/
.idea/
*.swp
*.swo
# Logs
*.log
EOF
            log_info ".gitignore básico creado"
        fi
        # Agregar y commitear
        git add .
        git commit -m "Initial commit: ${repo_name}"
        # Agregar remote
        log_info "$MSG_REPO_ADD_REMOTE"
        local remote_url
        remote_url=$(get_remote_url "$repo_name")
        git remote add origin "$remote_url"
        # Primer push
        log_info "$MSG_REPO_PUSH_FIRST"
        git branch -M main
        git push -u origin main
        log_success "¡Repositorio creado y sincronizado!"
    elif echo "$response" | grep -q '"message":"Repository creation failed"'; then
        log_error "$MSG_REPO_EXISTS"
        return 1
    else
        log_error "$MSG_REPO_CREATE_FAIL"
        log_error "Detalles: $(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)"
        return 1
    fi
}
# Exportar función
export -f repo_create
