#!/usr/bin/env bash
#===============================================================================
# Módulo 6: Gestionar ramas (branch)
#===============================================================================
# Función para mostrar ramas locales
show_local_branches() {
    echo ""
    echo "🌿 RAMAS LOCALES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    local current_branch
    current_branch=$(git branch --show-current 2>/dev/null)
    git branch -a 2>/dev/null | while read -r branch; do
        if [[ "$branch" == "* $current_branch" ]]; then
            echo "   ✅ ${branch}"
        elif [[ "$branch" == remotes/* ]]; then
            echo "   🌐 ${branch}"
        else
            echo "   📁 ${branch}"
        fi
    done
    echo ""
}
# Función para mostrar ramas remotas
show_remote_branches() {
    echo ""
    echo "🌐 RAMAS REMOTAS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    git fetch --all --prune 2>/dev/null
    git branch -r 2>/dev/null | while read -r branch; do
        echo "   📡 $branch"
    done
    echo ""
}
# Función para crear nueva rama
create_branch() {
    echo ""
    read -p "📝 Nombre de la nueva rama: " branch_name
    if [ -z "$branch_name" ]; then
        log_error "El nombre de la rama no puede estar vacío"
        return 1
    fi
    # Validar nombre de rama
    if [[ ! "$branch_name" =~ ^[a-zA-Z0-9/_-]+$ ]]; then
        log_error "Nombre de rama inválido. Usa solo letras, números, /, -, _"
        return 1
    fi
    # Verificar si la rama ya existe
    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        log_error "La rama '$branch_name' ya existe localmente"
        return 1
    fi
    # Crear rama
    git checkout -b "$branch_name"
    log_success "Rama '$branch_name' creada y cambiada a ella"
    # Preguntar si desea publicar la rama
    read -p "¿Deseas publicar esta rama en GitHub? (s/n): " publish
    if [[ "$publish" =~ ^[Ss]$ ]]; then
        git push -u origin "$branch_name"
        log_success "Rama '$branch_name' publicada en GitHub"
    fi
}
# Función para cambiar de rama
switch_branch() {
    echo ""
    echo "Ramas disponibles:"
    git branch 2>/dev/null | sed 's/^/   /'
    echo ""
    read -p "🔀 Cambiar a rama: " branch_name
    if [ -z "$branch_name" ]; then
        log_error "Debes especificar una rama"
        return 1
    fi
    if git checkout "$branch_name" 2>/dev/null; then
        log_success "Cambiado a rama '$branch_name'"
        # Mostrar estado actual
        local current_branch
        current_branch=$(git branch --show-current)
        echo "   🌿 Ahora en rama: $current_branch"
    else
        log_error "No se pudo cambiar a la rama '$branch_name'"
        log_info "Verifica que la rama existe"
        return 1
    fi
}
# Función para eliminar rama
delete_branch() {
    echo ""
    echo "Ramas disponibles:"
    git branch 2>/dev/null | sed 's/^/   /'
    echo ""
    read -p "🗑️  Eliminar rama: " branch_name
    if [ -z "$branch_name" ]; then
        log_error "Debes especificar una rama"
        return 1
    fi
    local current_branch
    current_branch=$(git branch --show-current)
    if [ "$branch_name" = "$current_branch" ]; then
        log_error "No puedes eliminar la rama actual ($current_branch)"
        log_info "Cambia a otra rama primero"
        return 1
    fi
    # Verificar si la rama existe
    if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
        log_error "La rama '$branch_name' no existe"
        return 1
    fi
    read -p "¿Eliminar también la rama remota? (s/n): " delete_remote
    read -p "Confirmar eliminación de rama '$branch_name' (s/n): " confirm
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        git branch -d "$branch_name"
        log_success "Rama local '$branch_name' eliminada"
        if [[ "$delete_remote" =~ ^[Ss]$ ]]; then
            git push origin --delete "$branch_name"
            log_success "Rama remota '$branch_name' eliminada"
        fi
    else
        log_info "Operación cancelada"
    fi
}
# Función para fusionar ramas
merge_branch() {
    echo ""
    echo "Ramas disponibles:"
    git branch 2>/dev/null | sed 's/^/   /'
    echo ""
    local current_branch
    current_branch=$(git branch --show-current)
    echo "📍 Rama actual: $current_branch"
    echo ""
    read -p "🔀 Fusionar rama (desde) en $current_branch (hacia): " from_branch
    if [ -z "$from_branch" ]; then
        log_error "Debes especificar una rama"
        return 1
    fi
    # Verificar si la rama existe
    if ! git show-ref --verify --quiet "refs/heads/$from_branch"; then
        log_error "La rama '$from_branch' no existe"
        return 1
    fi
    echo ""
    log_info "Fusionando '$from_branch' en '$current_branch'..."
    if git merge "$from_branch" --no-edit 2>&1; then
        log_success "Fusión completada exitosamente"
        # Preguntar si desea hacer push
        read -p "¿Deseas subir los cambios a GitHub? (s/n): " push_changes
        if [[ "$push_changes" =~ ^[Ss]$ ]]; then
            git push origin "$current_branch"
            log_success "Cambios subidos a GitHub"
        fi
    else
        log_error "Error en la fusión. Posibles conflictos detectados"
        echo ""
        echo "🔧 Para resolver conflictos:"
        echo "   1. git status (ver archivos en conflicto)"
        echo "   2. Editar archivos conflictivos"
        echo "   3. git add <archivos>"
        echo "   4. git commit -m \"Merge: resolviendo conflictos\""
        echo ""
        return 1
    fi
}
# Función principal para gestión de ramas
repo_branch() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "🌿 GESTIÓN DE RAMAS (BRANCHES)"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Verificar que estamos en un repositorio git
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "No estás en un repositorio Git"
        log_info "Ejecuta la opción 1 o 2 primero para inicializar un repositorio"
        return 1
    fi
    # Mostrar ramas actuales
    show_local_branches
    while true; do
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📋 SELECCIONA UNA OPERACIÓN"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "   1) Ver todas las ramas (incluyendo remotas)"
        echo "   2) Crear nueva rama"
        echo "   3) Cambiar de rama (checkout)"
        echo "   4) Fusionar rama (merge)"
        echo "   5) Eliminar rama"
        echo "   6) Volver al menú principal"
        echo ""
        read -p "$MSG_SELECT_OPTION " branch_option
        case $branch_option in
            1)
                show_local_branches
                show_remote_branches
                ;;
            2)
                create_branch
                ;;
            3)
                switch_branch
                ;;
            4)
                merge_branch
                ;;
            5)
                delete_branch
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
        if [[ "$branch_option" =~ ^[2-5]$ ]]; then
            clear
            echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo "🌿 GESTIÓN DE RAMAS (BRANCHES)"
            echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            show_local_branches
        fi
    done
}
# Exportar función
export -f repo_branch
