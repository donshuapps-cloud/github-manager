#!/usr/bin/env bash
#===============================================================================
# Módulo 2: Inicializar repositorio en proyecto existente
#===============================================================================
# Función para verificar GitHub CLI
check_gh_cli_available() {
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            log_info "✅ GitHub CLI detectado y autenticado"
            return 0
        else
            log_warning "GitHub CLI instalado pero no autenticado"
            log_info "Ejecuta: gh auth login"
            return 1
        fi
    fi
    return 1
}
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
    # Guardar directorio actual
    local current_dir
    current_dir=$(pwd)
    local repo_path="$current_dir"
    # Crear repositorio en GitHub y vincular con directorio actual
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
        # Verificar si ya existe remote
        if git remote | grep -q origin; then
            git remote set-url origin "$remote_url"
        else
            git remote add origin "$remote_url"
        fi
        # Hacer push
        local current_branch
        current_branch=$(git branch --show-current 2>/dev/null || echo "main")
        git push -u origin "$current_branch"
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
    echo ""
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
    log_info "Directorio actual: $(pwd)"
    # Verificar si ya es repositorio git
    if [ -d ".git" ]; then
        log_warning "$MSG_REPO_ALREADY_INIT"
        # Mostrar información del remote si existe
        if git remote -v | grep -q origin; then
            log_info "Remote origin actual:"
            git remote -v
        fi
        echo ""
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
    local private_flag="false"
    while true; do
        echo ""
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
    # Verificar GitHub CLI
    if command -v gh &> /dev/null; then
        log_info "Verificando autenticación de GitHub CLI..."
        if gh auth status &> /dev/null; then
            use_gh=true
            log_success "✅ GitHub CLI autenticado correctamente"
        else
            log_warning "GitHub CLI instalado pero no autenticado"
            echo ""
            echo "   Para autenticar GitHub CLI, ejecuta:"
            echo "   gh auth login"
            echo "   Luego selecciona: GitHub.com -> SSH -> Usar clave SSH existente"
            echo ""
        fi
    fi
    # Verificar token si GitHub CLI no está disponible
    if [ "$use_gh" = false ] && [ -n "${GITHUB_TOKEN:-}" ]; then
        use_token=true
        log_success "✅ Token de GitHub detectado"
    fi
    # Si no hay autenticación, mostrar opciones
    if [ "$use_gh" = false ] && [ "$use_token" = false ]; then
        log_error "No se encontró autenticación válida para crear repositorio"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📌 OPCIONES PARA AUTENTICACIÓN"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "1) GitHub CLI (recomendado - usa tu clave SSH existente)"
        echo ""
        echo "   # Instalar GitHub CLI"
        echo "   curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
        echo "   echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
        echo "   sudo apt update && sudo apt install gh"
        echo ""
        echo "   # Autenticar (usará tu SSH)"
        echo "   gh auth login"
        echo ""
        echo "2) Token Personal (alternativa)"
        echo ""
        echo "   export GITHUB_TOKEN=\"tu_token_aqui\""
        echo ""
        echo "   Crear token en: https://github.com/settings/tokens"
        echo "   (Permisos necesarios: repo, workflow)"
        echo ""
        return 1
    fi
    # Crear repositorio
    if [ "$use_gh" = true ]; then
        if create_repo_with_gh "$repo_name" "$repo_desc" "$private_flag"; then
            log_success "✅ Repositorio inicializado exitosamente"
            return 0
        else
            log_error "Error al inicializar repositorio con GitHub CLI"
            return 1
        fi
    elif [ "$use_token" = true ]; then
        if create_repo_with_token "$repo_name" "$repo_desc" "$private_flag"; then
            log_success "✅ Repositorio inicializado exitosamente"
            return 0
        else
            log_error "Error al inicializar repositorio con token"
            return 1
        fi
    fi
}
# Exportar función
export -f repo_init
