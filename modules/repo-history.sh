#!/usr/bin/env bash
#===============================================================================
# Módulo 11: Ver historial de commits
#===============================================================================
# Función para mostrar historial formateado
show_history_formatted() {
    local lines="$1"
    local format
    # Formato personalizado para mejor visualización
    format="%C(cyan)%h%C(reset) | %C(yellow)%ai%C(reset) | %C(green)%an%C(reset) | %C(white)%s%C(reset)"
    echo ""
    git log -"$lines" --pretty=format:"$format" 2>/dev/null
    echo ""
}
# Función para mostrar historial con estadísticas
show_history_with_stats() {
    local lines="$1"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 HISTORIAL CON ESTADÍSTICAS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    git log -"$lines" --stat 2>/dev/null
}
# Función para mostrar historial en formato one-line
show_history_oneline() {
    local lines="$1"
    echo ""
    git log -"$lines" --oneline 2>/dev/null
    echo ""
}
# Función para mostrar gráfico de ramas
show_branch_graph() {
    echo ""
    echo "🌿 GRÁFICO DE RAMAS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    git log --graph --pretty=oneline --abbrev-commit --all -20 2>/dev/null
    echo ""
}
# Función para mostrar estadísticas de contribución
show_contribution_stats() {
    echo ""
    echo "👥 ESTADÍSTICAS DE CONTRIBUCIÓN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    # Total de commits por autor
    echo ""
    echo "📊 Commits por autor:"
    git shortlog -s -n 2>/dev/null | head -10 | sed 's/^/   /'
    # Commits por día (últimos 7 días)
    echo ""
    echo "📅 Commits por día (últimos 7 días):"
    local last_week
    last_week=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null)
    if [ -n "$last_week" ]; then
        git log --since="$last_week" --format="%ad" --date=short 2>/dev/null | sort | uniq -c | sed 's/^/   /'
    fi
    # Archivos más modificados
    echo ""
    echo "📁 Archivos más modificados:"
    git log --pretty=format: --name-only 2>/dev/null | sort | uniq -c | sort -rn | head -10 | sed 's/^/   /'
}
# Función para buscar commits por patrón
search_commits() {
    local pattern="$1"
    echo ""
    echo "🔍 Buscando commits que contengan: '$pattern'"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    git log --grep="$pattern" --pretty=format:"%h | %ai | %s" 2>/dev/null
    echo ""
    local count
    count=$(git log --grep="$pattern" --oneline 2>/dev/null | wc -l | tr -d ' ')
    echo "   Encontrados $count commits"
}
# Función principal para ver historial
repo_history() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "📜 HISTORIAL DE COMMITS"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Verificar que estamos en un repositorio git
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "No estás en un repositorio Git"
        log_info "Ejecuta la opción 1 o 2 primero para inicializar un repositorio"
        return 1
    fi
    # Contar commits totales
    local total_commits
    total_commits=$(git rev-list --count HEAD 2>/dev/null)
    if [ "$total_commits" -eq 0 ] || [ -z "$total_commits" ]; then
        log_warning "No hay commits en este repositorio"
        log_info "Ejecuta la opción 3 para realizar tu primer commit"
        return 0
    fi
    echo ""
    echo "📊 Resumen: $total_commits commits en total"
    # Menú de opciones para visualización
    while true; do
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 SELECCIONA EL FORMATO DE VISUALIZACIÓN"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "   1) Formato completo (hash, fecha, autor, mensaje)"
        echo "   2) Formato one-line (hash + mensaje)"
        echo "   3) Con estadísticas de archivos"
        echo "   4) Gráfico de ramas"
        echo "   5) Estadísticas de contribución"
        echo "   6) Buscar commits"
        echo "   7) Cambiar cantidad de commits"
        echo "   8) Volver al menú principal"
        echo ""
        read -p "$MSG_SELECT_OPTION " history_option
        case $history_option in
            1)
                echo ""
                read -p "📊 ¿Cuántos commits quieres ver? (default: 10): " num_commits
                num_commits=${num_commits:-10}
                show_history_formatted "$num_commits"
                ;;
            2)
                echo ""
                read -p "📊 ¿Cuántos commits quieres ver? (default: 20): " num_commits
                num_commits=${num_commits:-20}
                show_history_oneline "$num_commits"
                ;;
            3)
                echo ""
                read -p "📊 ¿Cuántos commits quieres ver? (default: 5): " num_commits
                num_commits=${num_commits:-5}
                show_history_with_stats "$num_commits"
                ;;
            4)
                show_branch_graph
                ;;
            5)
                show_contribution_stats
                ;;
            6)
                echo ""
                read -p "🔍 Patrón de búsqueda: " search_pattern
                if [ -n "$search_pattern" ]; then
                    search_commits "$search_pattern"
                else
                    log_error "Patrón de búsqueda vacío"
                fi
                ;;
            7)
                # Solo vuelve a mostrar el menú
                continue
                ;;
            8)
                return 0
                ;;
            *)
                log_error "$MSG_INVALID_OPTION"
                ;;
        esac
        echo ""
        read -p "$MSG_PRESS_ENTER"
    done
}
# Exportar función
export -f repo_history
