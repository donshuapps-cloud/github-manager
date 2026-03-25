#!/usr/bin/env bash
#===============================================================================
# Módulo 7: Gestionar tags/releases
#===============================================================================
# Función para validar formato de versión semántica
validate_semver() {
    local version="$1"
    if [[ "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$ ]]; then
        return 0
    fi
    return 1
}
# Función para sugerir próxima versión
suggest_next_version() {
    local current_version="$1"
    if [[ "$current_version" =~ v?([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        local patch="${BASH_REMATCH[3]}"
        echo ""
        echo "💡 Versiones sugeridas:"
        echo "   • patch: v${major}.${minor}.$((patch + 1)) (cambios menores, fixes)"
        echo "   • minor: v${major}.$((minor + 1)).0 (nuevas funcionalidades)"
        echo "   • major: v$((major + 1)).0.0 (cambios incompatibles)"
        echo ""
    fi
}
# Función para mostrar tags existentes
show_tags() {
    echo ""
    echo "🏷️  TAGS EXISTENTES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local tags
    tags=$(git tag -l 2>/dev/null | sort -V)
    if [ -z "$tags" ]; then
        echo "   📭 No hay tags en este repositorio"
    else
        echo "$tags" | while read -r tag; do
            # Obtener información del tag
            local tag_date
            local tag_msg
            tag_date=$(git log -1 --format="%ai" "$tag" 2>/dev/null | cut -d' ' -f1)
            tag_msg=$(git tag -l -n1 "$tag" 2>/dev/null | sed "s/^$tag[[:space:]]*//")
            if [ -n "$tag_date" ]; then
                echo "   📌 $tag ($tag_date)"
                [ -n "$tag_msg" ] && echo "      💬 $tag_msg"
            else
                echo "   📌 $tag"
            fi
        done
    fi
    echo ""
}
# Función para mostrar releases de GitHub
show_releases() {
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_warning "Se requiere token para ver releases de GitHub"
        return 1
    fi
    # Obtener remote URL para extraer usuario/repo
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [ -z "$remote_url" ]; then
        log_error "No hay remote configurado"
        return 1
    fi
    # Extraer usuario/repo
    local repo_path
    if [[ "$remote_url" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
        repo_path="${BASH_REMATCH[1]}"
    else
        log_error "No se pudo determinar el repositorio"
        return 1
    fi
    echo ""
    echo "🚀 RELEASES EN GITHUB"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local response
    response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
                    -H "Accept: application/vnd.github.v3+json" \
                    "https://api.github.com/repos/${repo_path}/releases" 2>/dev/null)
    if echo "$response" | grep -q '"tag_name"'; then
        local count=0
        while IFS= read -r line; do
            if echo "$line" | grep -q '"tag_name"'; then
                local tag_name
                tag_name=$(echo "$line" | grep -o '"tag_name":"[^"]*"' | cut -d'"' -f4)
                local release_name
                release_name=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
                local published_at
                published_at=$(echo "$line" | grep -o '"published_at":"[^"]*"' | cut -d'"' -f4 | cut -d'T' -f1)
                echo "   🚀 $tag_name${release_name:+ - $release_name} ($published_at)"
                ((count++))
                [ $count -ge 5 ] && break
            fi
        done <<< "$response"
        if [ $count -eq 0 ]; then
            echo "   📭 No hay releases en GitHub"
        fi
    else
        echo "   📭 No se pudieron obtener releases"
    fi
    echo ""
}
# Función para crear tag local
create_tag() {
    echo ""
    read -p "🏷️  Nombre del tag (ej: v1.0.0): " tag_name
    if [ -z "$tag_name" ]; then
        log_error "El nombre del tag no puede estar vacío"
        return 1
    fi
    # Validar formato semántico
    if ! validate_semver "$tag_name"; then
        log_warning "Formato de versión no estándar. Se recomienda usar semver (ej: v1.0.0)"
        read -p "¿Deseas continuar? (s/n): " continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Ss]$ ]]; then
            return 1
        fi
    fi
    # Verificar si el tag ya existe
    if git rev-parse "$tag_name" >/dev/null 2>&1; then
        log_error "El tag '$tag_name' ya existe"
        return 1
    fi
    # Solicitar mensaje
    echo ""
    read -p "💬 Mensaje para el tag (opcional): " tag_msg
    # Crear tag
    if [ -n "$tag_msg" ]; then
        git tag -a "$tag_name" -m "$tag_msg"
    else
        git tag "$tag_name"
    fi
    log_success "Tag '$tag_name' creado localmente"
    # Preguntar si desea publicar
    read -p "¿Deseas publicar este tag en GitHub? (s/n): " publish
    if [[ "$publish" =~ ^[Ss]$ ]]; then
        if git push origin "$tag_name"; then
            log_success "Tag '$tag_name' publicado en GitHub"
            # Preguntar si desea crear release
            read -p "¿Deseas crear un release en GitHub para este tag? (s/n): " create_release
            if [[ "$create_release" =~ ^[Ss]$ ]]; then
                create_github_release "$tag_name"
            fi
        else
            log_error "Error al publicar tag"
        fi
    fi
}
# Función para crear release en GitHub
create_github_release() {
    local tag_name="$1"
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_error "Se requiere token para crear releases"
        return 1
    fi
    # Obtener remote URL
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [ -z "$remote_url" ]; then
        log_error "No hay remote configurado"
        return 1
    fi
    # Extraer usuario/repo
    local repo_path
    if [[ "$remote_url" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
        repo_path="${BASH_REMATCH[1]}"
    else
        log_error "No se pudo determinar el repositorio"
        return 1
    fi
    echo ""
    read -p "📝 Título del release [${tag_name}]: " release_title
    release_title="${release_title:-$tag_name}"
    echo ""
    echo "📄 Descripción del release (línea vacía para terminar):"
    local release_body=""
    while IFS= read -r line; do
        [ -z "$line" ] && break
        release_body="${release_body}${line}\n"
    done
    # Crear release via API
    local response
    response=$(curl -s -X POST "https://api.github.com/repos/${repo_path}/releases" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{
            \"tag_name\": \"${tag_name}\",
            \"name\": \"${release_title}\",
            \"body\": \"${release_body}\",
            \"draft\": false,
            \"prerelease\": false
        }")
    if echo "$response" | grep -q '"html_url"'; then
        local release_url
        release_url=$(echo "$response" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)
        log_success "Release creado: $release_url"
    else
        log_error "Error al crear release"
        local error_msg
        error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        [ -n "$error_msg" ] && log_error "Detalles: $error_msg"
    fi
}
# Función para eliminar tag
delete_tag() {
    echo ""
    echo "Tags disponibles:"
    git tag -l 2>/dev/null | sort -V | sed 's/^/   /'
    echo ""
    read -p "🗑️  Eliminar tag: " tag_name
    if [ -z "$tag_name" ]; then
        log_error "Debes especificar un tag"
        return 1
    fi
    # Verificar si existe
    if ! git rev-parse "$tag_name" >/dev/null 2>&1; then
        log_error "El tag '$tag_name' no existe"
        return 1
    fi
    read -p "¿Eliminar también del remoto? (s/n): " delete_remote
    read -p "Confirmar eliminación de tag '$tag_name' (s/n): " confirm
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        git tag -d "$tag_name"
        log_success "Tag local '$tag_name' eliminado"
        if [[ "$delete_remote" =~ ^[Ss]$ ]]; then
            git push origin --delete "$tag_name"
            log_success "Tag remoto '$tag_name' eliminado"
        fi
    else
        log_info "Operación cancelada"
    fi
}
# Función principal para gestión de tags
repo_tags() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "🏷️  GESTIÓN DE TAGS Y RELEASES"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Verificar que estamos en un repositorio git
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "No estás en un repositorio Git"
        log_info "Ejecuta la opción 1 o 2 primero para inicializar un repositorio"
        return 1
    fi
    # Mostrar tags existentes
    show_tags
    # Mostrar releases de GitHub si hay token
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        show_releases
    fi
    while true; do
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 SELECCIONA UNA OPERACIÓN"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "   1) Crear nuevo tag"
        echo "   2) Publicar tag existente en GitHub"
        echo "   3) Crear release en GitHub (desde tag)"
        echo "   4) Eliminar tag"
        echo "   5) Ver todos los tags"
        echo "   6) Volver al menú principal"
        echo ""
        read -p "$MSG_SELECT_OPTION " tag_option
        case $tag_option in
            1)
                create_tag
                ;;
            2)
                echo ""
                echo "Tags locales no publicados:"
                git tag -l 2>/dev/null | while read -r tag; do
                    if ! git ls-remote --tags origin "$tag" 2>/dev/null | grep -q "$tag"; then
                        echo "   📌 $tag (no publicado)"
                    fi
                done
                echo ""
                read -p "🏷️  Tag a publicar: " tag_name
                if [ -n "$tag_name" ] && git push origin "$tag_name" 2>/dev/null; then
                    log_success "Tag '$tag_name' publicado"
                else
                    log_error "No se pudo publicar el tag"
                fi
                ;;
            3)
                echo ""
                read -p "🏷️  Tag para el release: " tag_name
                if [ -n "$tag_name" ] && git rev-parse "$tag_name" >/dev/null 2>&1; then
                    create_github_release "$tag_name"
                else
                    log_error "El tag '$tag_name' no existe localmente"
                fi
                ;;
            4)
                delete_tag
                ;;
            5)
                show_tags
                if [ -n "${GITHUB_TOKEN:-}" ]; then
                    show_releases
                fi
                ;;
            6)
                return 0
                ;;
            *)
                log_error "$MSG_INVALID_OPTION"
                ;;
        esac
        echo ""
        read -p "$MSG_PRESS_ENTER"
        # Actualizar vista después de cambios
        if [[ "$tag_option" =~ ^[1-4]$ ]]; then
            clear
            echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "🏷️  GESTIÓN DE TAGS Y RELEASES"
            echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            show_tags
            if [ -n "${GITHUB_TOKEN:-}" ]; then
                show_releases
            fi
        fi
    done
}
# Exportar función
export -f repo_tags
