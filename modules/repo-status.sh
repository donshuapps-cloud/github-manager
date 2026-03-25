#!/usr/bin/env bash
#===============================================================================
# Módulo 5: Ver estado del repositorio actual
#===============================================================================
# Función para obtener información del remote
get_remote_info() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [ -n "$remote_url" ]; then
        # Detectar tipo de autenticación
        if [[ "$remote_url" == git@* ]]; then
            echo "SSH"
        elif [[ "$remote_url" == https://* ]]; then
            echo "HTTPS"
        else
            echo "Desconocido"
        fi
        echo "$remote_url"
    else
        echo "No configurado"
        echo ""
    fi
}
# Función para obtener información del branch
get_branch_info() {
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)
    if [ -n "$current_branch" ]; then
        echo "$current_branch"
        # Verificar si hay commits por push/pull
        local ahead_behind
        ahead_behind=$(git rev-list --left-right --count origin/"$current_branch"...HEAD 2>/dev/null)
        if [ -n "$ahead_behind" ]; then
            local ahead
            local behind
            ahead=$(echo "$ahead_behind" | cut -f1)
            behind=$(echo "$ahead_behind" | cut -f2)
            if [ "$ahead" -gt 0 ]; then
                echo "↑ $ahead commits por subir"
            fi
            if [ "$behind" -gt 0 ]; then
                echo "↓ $behind commits por bajar"
            fi
            if [ "$ahead" -eq 0 ] && [ "$behind" -eq 0 ]; then
                echo "✓ Sincronizado con origin"
            fi
        fi
    else
        echo "No branch activo"
        echo ""
    fi
}
# Función para contar commits
count_commits() {
    local total_commits
    total_commits=$(git rev-list --count HEAD 2>/dev/null)
    echo "${total_commits:-0}"
}
# Función para obtener último commit
get_last_commit() {
    local last_hash
    local last_date
    local last_msg
    last_hash=$(git log -1 --format="%h" 2>/dev/null)
    last_date=$(git log -1 --format="%ai" 2>/dev/null | cut -d' ' -f1)
    last_msg=$(git log -1 --format="%s" 2>/dev/null)
    if [ -n "$last_hash" ]; then
        echo "$last_hash|$last_date|$last_msg"
    else
        echo "---|Sin commits|---"
    fi
}
# Función para mostrar estadísticas de archivos
show_file_stats() {
    local total_files
    local staged_files
    local modified_files
    local untracked_files
    total_files=$(find . -type f -not -path "./.git/*" -not -path "./github-manager/*" 2>/dev/null | wc -l | tr -d ' ')
    staged_files=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    modified_files=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    echo "$total_files|$staged_files|$modified_files|$untracked_files"
}
# Función para mostrar lista de archivos modificados
show_modified_files() {
    echo ""
    echo "📝 ARCHIVOS MODIFICADOS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local staged_files
    local unstaged_files
    local untracked_files
    staged_files=$(git diff --cached --name-only 2>/dev/null)
    unstaged_files=$(git diff --name-only 2>/dev/null)
    untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null)
    if [ -n "$staged_files" ]; then
        echo ""
        echo "✅ Preparados para commit (staged):"
        echo "$staged_files" | sed 's/^/   📌 /'
    fi
    if [ -n "$unstaged_files" ]; then
        echo ""
        echo "⚠️  Modificados no preparados (unstaged):"
        echo "$unstaged_files" | sed 's/^/   🔧 /'
    fi
    if [ -n "$untracked_files" ]; then
        echo ""
        echo "🆕 Sin seguimiento (untracked):"
        echo "$untracked_files" | sed 's/^/   📄 /'
    fi
    if [ -z "$staged_files" ] && [ -z "$unstaged_files" ] && [ -z "$untracked_files" ]; then
        echo ""
        echo "   ✨ No hay archivos modificados"
    fi
}
# Función principal para mostrar estado
repo_status() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "📊 ESTADO DEL REPOSITORIO"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Verificar que estamos en un repositorio git
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "No estás en un repositorio Git"
        log_info "Ejecuta la opción 1 o 2 primero para inicializar un repositorio"
        return 1
    fi
    # Obtener información
    local remote_type
    local remote_url
    read -r remote_type remote_url <<< "$(get_remote_info)"
    local branch_info
    branch_info=$(get_branch_info)
    local current_branch
    current_branch=$(echo "$branch_info" | head -1)
    local total_commits
    total_commits=$(count_commits)
    local last_commit_info
    last_commit_info=$(get_last_commit)
    IFS='|' read -r last_hash last_date last_msg <<< "$last_commit_info"
    local file_stats
    file_stats=$(show_file_stats)
    IFS='|' read -r total_files staged_files modified_files untracked_files <<< "$file_stats"
    # Mostrar información
    echo ""
    echo "📁 INFORMACIÓN GENERAL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   📂 Directorio:     $(pwd)"
    echo "   🌿 Branch actual:  $current_branch"
    echo "   📊 Total commits:  $total_commits"
    echo "   📁 Total archivos: $total_files"
    echo ""
    echo "🔗 REMOTO (ORIGIN)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   🔐 Tipo:          $remote_type"
    echo "   🔗 URL:           $remote_url"
    echo "$branch_info" | tail -n +2 | sed 's/^/   /'
    echo ""
    echo "📝 ÚLTIMO COMMIT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   🔑 Hash:          $last_hash"
    echo "   📅 Fecha:         $last_date"
    echo "   💬 Mensaje:       $last_msg"
    echo ""
    echo "📊 ESTADO DE ARCHIVOS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   ✅ Staged:        $staged_files archivo(s)"
    echo "   ⚠️  Modified:      $modified_files archivo(s)"
    echo "   🆕 Untracked:     $untracked_files archivo(s)"
    # Mostrar lista detallada de archivos modificados
    show_modified_files
    # Mostrar estadísticas de contribución
    echo ""
    echo "👥 CONTRIBUCIONES (últimos 5 commits)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    git log -5 --format="   %h | %ai | %s" 2>/dev/null | head -5
    if [ $? -ne 0 ]; then
        echo "   Sin commits todavía"
    fi
    # Sugerencias según el estado
    echo ""
    echo "💡 SUGERENCIAS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$staged_files" -gt 0 ]; then
        echo "   ✅ Tienes archivos preparados. Ejecuta opción 3 para commitear."
    fi
    if [ "$modified_files" -gt 0 ] || [ "$untracked_files" -gt 0 ]; then
        echo "   📝 Hay cambios sin preparar. Usa 'git add' o la opción 3."
    fi
    if [ "$staged_files" -eq 0 ] && [ "$modified_files" -eq 0 ] && [ "$untracked_files" -eq 0 ]; then
        echo "   ✨ Todo está limpio. El repositorio está sincronizado."
    fi
    echo ""
}
# Exportar función
export -f repo_status
