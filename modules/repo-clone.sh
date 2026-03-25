#!/usr/bin/env bash
#===============================================================================
# Módulo 4: Clonar repositorio existente
#===============================================================================
# Función para validar URL de repositorio
validate_repo_url() {
    local url="$1"
    # Validar formato SSH
    if [[ "$url" =~ ^git@github\.com:[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+\.git$ ]]; then
        echo "ssh"
        return 0
    fi
    # Validar formato HTTPS
    if [[ "$url" =~ ^https://github\.com/[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+\.git$ ]]; then
        echo "https"
        return 0
    fi
    # Validar formato URL corta (usuario/repo)
    if [[ "$url" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_-]+$ ]]; then
        echo "short"
        return 0
    fi
    return 1
}
# Función para construir URL según método de autenticación
build_clone_url() {
    local repo_path="$1"
    local method="$2"
    case $method in
        ssh)
            echo "git@github.com:${repo_path}.git"
            ;;
        https)
            if [ -n "${GITHUB_TOKEN:-}" ]; then
                echo "https://oauth2:${GITHUB_TOKEN}@github.com/${repo_path}.git"
            else
                echo "https://github.com/${repo_path}.git"
            fi
            ;;
        short)
            if [ "${USE_SSH:-false}" = true ]; then
                echo "git@github.com:${repo_path}.git"
            elif [ -n "${GITHUB_TOKEN:-}" ]; then
                echo "https://oauth2:${GITHUB_TOKEN}@github.com/${repo_path}.git"
            else
                echo "https://github.com/${repo_path}.git"
            fi
            ;;
    esac
}
# Función para listar repositorios del usuario (si hay token)
list_user_repos() {
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        echo ""
        log_info "Obteniendo lista de tus repositorios..."
        local response
        response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
                        -H "Accept: application/vnd.github.v3+json" \
                        "https://api.github.com/user/repos?per_page=20&sort=updated" 2>/dev/null)
        if echo "$response" | grep -q '"name"'; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📋 TUS ÚLTIMOS REPOSITORIOS"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            local count=0
            while IFS= read -r line; do
                if echo "$line" | grep -q '"name"'; then
                    local repo_name
                    repo_name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
                    local repo_private
                    repo_private=$(echo "$line" | grep -o '"private":[^,]*' | cut -d':' -f2 | tr -d ' ')
                    if [ "$repo_private" = "true" ]; then
                        echo "   🔒 $repo_name"
                    else
                        echo "   📁 $repo_name"
                    fi
                    ((count++))
                    [ $count -ge 10 ] && break
                fi
            done <<< "$response"
            echo ""
        fi
    fi
}
# Función principal para clonar
repo_clone() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "📦 CLONAR REPOSITORIO EXISTENTE"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Mostrar repositorios del usuario si hay token
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        list_user_repos
    fi
    # Solicitar URL o ruta del repositorio
    echo ""
    echo "📝 Formatos aceptados:"
    echo "   • git@github.com:usuario/repo.git (SSH)"
    echo "   • https://github.com/usuario/repo.git (HTTPS)"
    echo "   • usuario/repo (formato corto)"
    echo ""
    read -p "🔗 URL o ruta del repositorio: " repo_input
    if [ -z "$repo_input" ]; then
        log_error "Debes proporcionar una URL o ruta de repositorio"
        return 1
    fi
    # Validar formato
    local url_type
    if ! url_type=$(validate_repo_url "$repo_input"); then
        log_error "Formato de repositorio inválido"
        log_info "Ejemplos válidos:"
        log_info "  • git@github.com:donshuapps-cloud/mi-repo.git"
        log_info "  • https://github.com/donshuapps-cloud/mi-repo.git"
        log_info "  • donshuapps-cloud/mi-repo"
        return 1
    fi
    # Construir URL de clonación
    local clone_url
    local repo_path
    if [ "$url_type" = "short" ]; then
        repo_path="$repo_input"
        clone_url=$(build_clone_url "$repo_path" "short")
    elif [ "$url_type" = "ssh" ] || [ "$url_type" = "https" ]; then
        # Extraer usuario/repo de la URL
        if [[ "$repo_input" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
            repo_path="${BASH_REMATCH[1]}"
            clone_url="$repo_input"
        else
            log_error "No se pudo extraer la ruta del repositorio"
            return 1
        fi
    fi
    # Solicitar directorio destino
    local target_dir
    local default_dir
    default_dir=$(basename "$repo_path" .git)
    read -p "📂 Directorio destino [${default_dir}]: " target_dir
    target_dir="${target_dir:-$default_dir}"
    # Verificar si el directorio ya existe
    if [ -d "$target_dir" ]; then
        log_error "El directorio '$target_dir' ya existe"
        read -p "¿Deseas sobrescribir? (s/n): " overwrite
        if [[ ! "$overwrite" =~ ^[Ss]$ ]]; then
            return 1
        fi
        rm -rf "$target_dir"
    fi
    # Mostrar información de clonación
    echo ""
    log_info "Clonando repositorio..."
    echo "   📦 Repositorio: $repo_path"
    echo "   📂 Destino: $target_dir"
    echo "   🔐 Método: $([ "$url_type" = "ssh" ] || [ "${USE_SSH:-false}" = true ] && echo "SSH" || echo "HTTPS")"
    echo ""
    # Ejecutar clonación
    if git clone "$clone_url" "$target_dir" 2>&1; then
        log_success "Repositorio clonado exitosamente"
        # Cambiar al directorio clonado
        cd "$target_dir" || return 1
        # Mostrar información del repositorio
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📊 INFORMACIÓN DEL REPOSITORIO CLONADO"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        local current_branch
        current_branch=$(git branch --show-current 2>/dev/null)
        echo "   🌿 Branch actual: ${current_branch:-main}"
        local remote_url
        remote_url=$(git remote get-url origin 2>/dev/null)
        echo "   🔗 Remote: $remote_url"
        local commit_count
        commit_count=$(git rev-list --count HEAD 2>/dev/null)
        echo "   📊 Total commits: ${commit_count:-0}"
        echo ""
        log_info "Has sido movido al directorio: $(pwd)"
        echo ""
        # Preguntar si desea abrir el directorio
        read -p "¿Deseas abrir este directorio? (s/n): " open_dir
        if [[ "$open_dir" =~ ^[Ss]$ ]]; then
            if command -v explorer.exe &>/dev/null; then
                explorer.exe .
            elif command -v open &>/dev/null; then
                open .
            elif command -v xdg-open &>/dev/null; then
                xdg-open .
            else
                log_info "No se pudo abrir el directorio automáticamente"
            fi
        fi
    else
        log_error "Error al clonar el repositorio"
        log_info "Verifica que:"
        log_info "  1. La URL es correcta"
        log_info "  2. Tienes permisos de acceso"
        log_info "  3. Tu autenticación está configurada correctamente"
        return 1
    fi
}
# Exportar función
export -f repo_clone
