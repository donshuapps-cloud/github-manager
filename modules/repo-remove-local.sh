#!/usr/bin/env bash
#===============================================================================
# Módulo 10: Eliminar repositorio localmente
#===============================================================================
# Función para obtener tamaño del repositorio
get_repo_size() {
    local size
    size=$(du -sh . 2>/dev/null | cut -f1)
    echo "${size:-0B}"
}
# Función para contar archivos
count_files() {
    local count
    count=$(find . -type f -not -path "./.git/*" 2>/dev/null | wc -l | tr -d ' ')
    echo "${count:-0}"
}
# Función para mostrar información del repositorio
show_repo_info() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 INFORMACIÓN DEL REPOSITORIO"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local repo_name
    repo_name=$(basename "$(pwd)")
    local repo_size
    repo_size=$(get_repo_size)
    local file_count
    file_count=$(count_files)
    local last_commit
    last_commit=$(git log -1 --format="%h - %s" 2>/dev/null || echo "Sin commits")
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "No branch")
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null || echo "No remote")
    echo "   📁 Nombre:     $repo_name"
    echo "   📦 Tamaño:     $repo_size"
    echo "   📄 Archivos:   $file_count"
    echo "   🌿 Branch:     $current_branch"
    echo "   🔗 Remote:     $remote_url"
    echo "   💬 Último commit: $last_commit"
    echo ""
    # Mostrar archivos no trackeados importantes
    local untracked
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | head -5)
    if [ -n "$untracked" ]; then
        echo "   🆕 Archivos sin seguimiento:"
        echo "$untracked" | sed 's/^/      • /'
        local untracked_count
        untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
        if [ "$untracked_count" -gt 5 ]; then
            echo "      ... y $((untracked_count - 5)) más"
        fi
        echo ""
    fi
}
# Función para verificar cambios sin commit
check_uncommitted_changes() {
    local staged
    local unstaged
    local untracked
    staged=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    unstaged=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    if [ "$staged" -gt 0 ] || [ "$unstaged" -gt 0 ] || [ "$untracked" -gt 0 ]; then
        echo ""
        echo "⚠️  ADVERTENCIA: Hay cambios sin commitear:"
        [ "$staged" -gt 0 ] && echo "   • $staged archivo(s) staged"
        [ "$unstaged" -gt 0 ] && echo "   • $unstaged archivo(s) modificados sin stage"
        [ "$untracked" -gt 0 ] && echo "   • $untracked archivo(s) sin seguimiento"
        return 1
    fi
    return 0
}
# Función para verificar si hay commits por push
check_unpushed_commits() {
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$current_branch" ]; then
        local unpushed
        unpushed=$(git log origin/"$current_branch"..HEAD 2>/dev/null | wc -l | tr -d ' ')
        if [ "$unpushed" -gt 0 ]; then
            echo ""
            echo "⚠️  ADVERTENCIA: Hay $unpushed commit(s) sin subir a GitHub"
            git log origin/"$current_branch"..HEAD --oneline 2>/dev/null | head -5 | sed 's/^/   • /'
            return 1
        fi
    fi
    return 0
}
# Función para crear backup opcional
create_backup() {
    local backup_dir
    backup_dir="../$(basename "$(pwd)")_backup_$(date +%Y%m%d_%H%M%S)"
    echo ""
    log_info "Creando backup en: $backup_dir"
    if cp -r . "$backup_dir" 2>/dev/null; then
        log_success "Backup creado exitosamente"
        echo "   📂 Ubicación: $backup_dir"
        return 0
    else
        log_error "Error al crear backup"
        return 1
    fi
}
# Función para eliminar repositorio
remove_repository() {
    local current_dir
    current_dir=$(pwd)
    local repo_name
    repo_name=$(basename "$current_dir")
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🗑️  CONFIRMACIÓN DE ELIMINACIÓN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  ¡ATENCIÓN! Esta acción es IRREVERSIBLE"
    echo ""
    echo "Se eliminará permanentemente:"
    echo "   📁 $current_dir"
    echo "   📦 Tamaño: $(get_repo_size)"
    echo "   📄 Archivos: $(count_files)"
    echo ""
    echo "¿Estás ABSOLUTAMENTE seguro de que deseas continuar?"
    echo ""
    echo "   Para confirmar, escribe el nombre del repositorio: $repo_name"
    echo ""
    read -p "➤ Confirmar: " confirm_name
    if [ "$confirm_name" != "$repo_name" ]; then
        log_error "Confirmación fallida. El nombre no coincide."
        return 1
    fi
    echo ""
    echo "Última confirmación: ¿Eliminar repositorio? (s/N): "
    read -r final_confirm
    if [[ ! "$final_confirm" =~ ^[Ss]$ ]]; then
        log_info "Operación cancelada"
        return 0
    fi
    # Eliminar el directorio .git y luego el directorio completo
    echo ""
    log_info "Eliminando repositorio..."
    # Salir del directorio antes de eliminar
    cd .. || return 1
    if rm -rf "$repo_name" 2>/dev/null; then
        log_success "Repositorio '$repo_name' eliminado exitosamente"
        echo ""
        echo "📌 Estás ahora en: $(pwd)"
        return 0
    else
        log_error "Error al eliminar el repositorio"
        return 1
    fi
}
# Función principal para eliminar repositorio local
repo_remove_local() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "🗑️  ELIMINAR REPOSITORIO LOCALMENTE"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Verificar que estamos en un repositorio git
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "No estás en un repositorio Git"
        return 1
    fi
    # Mostrar información del repositorio
    show_repo_info
    # Verificar cambios sin commitear
    local has_uncommitted=1
    check_uncommitted_changes || has_uncommitted=$?
    # Verificar commits sin push
    local has_unpushed=1
    check_unpushed_commits || has_unpushed=$?
    # Si hay cambios sin commitear, advertencia adicional
    if [ $has_uncommitted -eq 1 ] || [ $has_unpushed -eq 1 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  ADVERTENCIA CRÍTICA"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Este repositorio tiene cambios que NO están en GitHub."
        echo "Si continúas, estos cambios se PERDERÁN PERMANENTEMENTE."
        echo ""
        read -p "¿Deseas crear un backup antes de eliminar? (s/n): " create_backup_choice
        if [[ "$create_backup_choice" =~ ^[Ss]$ ]]; then
            if ! create_backup; then
                read -p "Backup fallido. ¿Continuar de todas formas? (s/n): " continue_anyway
                if [[ ! "$continue_anyway" =~ ^[Ss]$ ]]; then
                    log_info "Operación cancelada"
                    return 0
                fi
            fi
        else
            echo ""
            echo "⚠️  Procediendo sin backup. Los cambios no guardados se perderán."
            read -p "¿Confirmas que deseas continuar? (s/n): " confirm_risk
            if [[ ! "$confirm_risk" =~ ^[Ss]$ ]]; then
                log_info "Operación cancelada"
                return 0
            fi
        fi
    fi
    # Preguntar si desea eliminar también el repositorio remoto
    echo ""
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [ -n "$remote_url" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🌐 REPOSITORIO REMOTO"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Este repositorio tiene un remote configurado:"
        echo "   🔗 $remote_url"
        echo ""
        echo "⚠️  NOTA: Este script SOLO elimina el repositorio LOCAL."
        echo "   El repositorio en GitHub NO será afectado."
        echo ""
        read -p "¿Deseas continuar con la eliminación local? (s/n): " continue_remote
        if [[ ! "$continue_remote" =~ ^[Ss]$ ]]; then
            log_info "Operación cancelada"
            return 0
        fi
    fi
    # Ejecutar eliminación
    if remove_repository; then
        log_success "Repositorio eliminado correctamente"
        # Sugerir volver al menú si el script sigue ejecutándose
        echo ""
        echo "💡 El script continuará ejecutándose en el directorio actual."
        echo "   Si deseas salir, presiona Ctrl+C o selecciona opción 0."
    else
        log_error "No se pudo eliminar el repositorio"
        return 1
    fi
}
# Exportar función
export -f repo_remove_local
