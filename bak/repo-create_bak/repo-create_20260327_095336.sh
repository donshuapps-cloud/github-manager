#!/usr/bin/env bash
#===============================================================================
# Módulo 1: Crear nuevo repositorio desde cero
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
    # Crear repositorio en GitHub
    if gh repo create "$repo_name" $visibility --description "$repo_desc" --clone 2>&1; then
        log_success "Repositorio creado en GitHub"
        # El repositorio ya está clonado por gh, necesitamos mover el contenido
        local cloned_dir="$repo_name"
        if [ -d "$cloned_dir" ]; then
            # Mover todo excepto el directorio clonado
            shopt -s dotglob
            for item in *; do
                if [ "$item" != "$cloned_dir" ] && [ "$item" != "." ] && [ "$item" != ".." ]; then
                    mv "$item" "$cloned_dir/" 2>/dev/null || true
                fi
            done
            shopt -u dotglob
            cd "$cloned_dir" || return 1
        fi
        # Crear README si no existe
        if [ ! -f "README.md" ]; then
            echo "# ${repo_name}" > README.md
            [ -n "$repo_desc" ] && echo "" >> README.md && echo "$repo_desc" >> README.md
        fi
        # Commit y push
        git add .
        git commit -m "Initial commit: ${repo_name}" 2>/dev/null || true
        git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null
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
        # Inicializar repositorio local
        log_info "$MSG_REPO_INIT_LOCAL"
        if [ ! -d ".git" ]; then
            git init
        fi
        # Crear README
        if [ ! -f "README.md" ]; then
            echo "# ${repo_name}" > README.md
            [ -n "$repo_desc" ] && echo "" >> README.md && echo "$repo_desc" >> README.md
        fi
        # Crear .gitignore básico
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
        fi
        # Commit y push
        git add .
        git commit -m "Initial commit: ${repo_name}"
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
repo_create() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "🚀 CREAR NUEVO REPOSITORIO DESDE CERO"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Solicitar nombre del repositorio
    while true; do
        read -p "$MSG_REPO_NAME " repo_name
        if [ -z "$repo_name" ]; then
            log_error "$MSG_VALIDATE_NAME"
            continue
        fi
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
        read -p "$MSG_REPO_PRIVATE " is_private_input
        if [[ "$is_private_input" =~ ^[Ss]$ ]] || [[ "$is_private_input" =~ ^[Yy]$ ]]; then
            private_flag="true"
            break
        elif [[ "$is_private_input" =~ ^[Nn]$ ]] || [ -z "$is_private_input" ]; then
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
        log_info "✅ GitHub CLI detectado y autenticado - usando SSH"
    elif [ -n "${GITHUB_TOKEN:-}" ]; then
        use_token=true
        log_info "✅ Token de GitHub detectado"
    else
        log_error "No se encontró autenticación válida para crear repositorio"
        echo ""
        echo "📌 Opciones disponibles:"
        echo "   1) Instalar y autenticar GitHub CLI (recomendado - usa SSH)"
        echo "      sudo apt install gh"
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
            log_success "¡Repositorio creado y sincronizado con GitHub CLI!"
            return 0
        else
            return 1
        fi
    elif [ "$use_token" = true ]; then
        if create_repo_with_token "$repo_name" "$repo_desc" "$private_flag"; then
            log_success "¡Repositorio creado y sincronizado!"
            return 0
        else
            return 1
        fi
    fi
}
# Exportar función
export -f repo_create
