#!/usr/bin/env bash
#===============================================================================
# Módulo 3: Subir cambios a GitHub con auto-descripción
#===============================================================================
# Función para analizar cambios y generar mensaje automático
analyze_changes() {
    local staged_files=""
    local unstaged_files=""
    local untracked_files=""
    # Obtener archivos staged
    staged_files=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    # Obtener archivos unstaged
    unstaged_files=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    # Obtener archivos untracked
    untracked_files=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    echo "$staged_files|$unstaged_files|$untracked_files"
}
# Función para detectar tipo de cambios
detect_change_type() {
    local files="$1"
    local change_type="update"
    # Analizar patrones en los archivos modificados
    if echo "$files" | grep -q -E "(\.md$|README|docs/)"; then
        change_type="docs"
    elif echo "$files" | grep -q -E "(test_|spec\.|\.test\.|\.spec\.)"; then
        change_type="test"
    elif echo "$files" | grep -q -E "(\.sh$|\.bash$|\.zsh$)"; then
        change_type="script"
    elif echo "$files" | grep -q -E "(\.py$|\.js$|\.ts$|\.go$|\.rs$)"; then
        change_type="code"
    elif echo "$files" | grep -q -E "(package\.json|requirements\.txt|Cargo\.toml|go\.mod)"; then
        change_type="config"
    fi
    echo "$change_type"
}
# Función para generar mensaje de commit en español
generate_commit_message_es() {
    local files="$1"
    local change_type
    change_type=$(detect_change_type "$files")
    # Contar archivos modificados
    local file_count
    file_count=$(echo "$files" | wc -l | tr -d ' ')
    # Generar mensaje según tipo de cambio
    case $change_type in
        docs)
            echo "📝 docs: actualización de documentación"
            ;;
        test)
            echo "✅ test: actualización de pruebas"
            ;;
        script)
            echo "🔧 script: actualización de scripts"
            ;;
        config)
            echo "⚙️  config: actualización de configuración"
            ;;
        code)
            if [ "$file_count" -eq 1 ]; then
                local single_file
                single_file=$(echo "$files" | head -1 | xargs basename)
                echo "✨ feat: actualización en ${single_file}"
            else
                echo "✨ feat: actualización en ${file_count} archivos"
            fi
            ;;
        *)
            echo "🔄 update: cambios generales"
            ;;
    esac
}
# Función para generar mensaje de commit en inglés
generate_commit_message_en() {
    local files="$1"
    local change_type
    change_type=$(detect_change_type "$files")
    # Contar archivos modificados
    local file_count
    file_count=$(echo "$files" | wc -l | tr -d ' ')
    # Generate message based on change type
    case $change_type in
        docs)
            echo "📝 docs: documentation update"
            ;;
        test)
            echo "✅ test: test updates"
            ;;
        script)
            echo "🔧 script: script updates"
            ;;
        config)
            echo "⚙️  config: configuration updates"
            ;;
        code)
            if [ "$file_count" -eq 1 ]; then
                local single_file
                single_file=$(echo "$files" | head -1 | xargs basename)
                echo "✨ feat: update in ${single_file}"
            else
                echo "✨ feat: updates in ${file_count} files"
            fi
            ;;
        *)
            echo "🔄 update: general changes"
            ;;
    esac
}
# Función para mostrar resumen de cambios
show_changes_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 RESUMEN DE CAMBIOS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    # Archivos staged
    local staged_count
    staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "$staged_count" -gt 0 ]; then
        echo ""
        echo "📌 Archivos preparados (staged):"
        git diff --cached --stat 2>/dev/null | tail -n +1
    fi
    # Archivos modificados no staged
    local unstaged_count
    unstaged_count=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    if [ "$unstaged_count" -gt 0 ]; then
        echo ""
        echo "⚠️  Archivos modificados no preparados:"
        git diff --name-only 2>/dev/null | sed 's/^/   /'
    fi
    # Archivos untracked
    local untracked_count
    untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    if [ "$untracked_count" -gt 0 ]; then
        echo ""
        echo "🆕 Archivos sin seguimiento (untracked):"
        git ls-files --others --exclude-standard 2>/dev/null | sed 's/^/   /'
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
# Función para agregar archivos interactivamente
interactive_add() {
    echo ""
    echo "📁 ¿Qué archivos deseas agregar al commit?"
    echo "   1) Todos los archivos (git add .)"
    echo "   2) Archivos modificados (git add -u)"
    echo "   3) Seleccionar manualmente"
    echo "   4) Cancelar"
    echo ""
    read -p "$MSG_SELECT_OPTION " add_choice
    case $add_choice in
        1)
            git add .
            log_success "Todos los archivos agregados"
            return 0
            ;;
        2)
            git add -u
            log_success "Archivos modificados agregados"
            return 0
            ;;
        3)
            echo ""
            echo "Archivos disponibles:"
            git status --porcelain 2>/dev/null
            echo ""
            read -p "Ingresa los archivos a agregar (separados por espacio): " files_to_add
            if [ -n "$files_to_add" ]; then
                git add $files_to_add
                log_success "Archivos agregados"
            fi
            return 0
            ;;
        4)
            return 1
            ;;
        *)
            log_error "$MSG_INVALID_OPTION"
            return 1
            ;;
    esac
}
# Función principal para subir cambios
repo_push() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "📤 SUBIR CAMBIOS A GITHUB"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Verificar que estamos en un repositorio git
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "No estás en un repositorio Git"
        log_info "Ejecuta la opción 1 o 2 primero para inicializar un repositorio"
        return 1
    fi
    # Verificar que existe remote
    if ! git remote -v | grep -q origin; then
        log_error "No hay remote configurado (origin)"
        log_info "Ejecuta la opción 1 o 2 para configurar el remote"
        return 1
    fi
    # Mostrar resumen de cambios
    show_changes_summary
    # Verificar si hay cambios para commitear
    local staged_count
    staged_count=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')
    local unstaged_count
    unstaged_count=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    local untracked_count
    untracked_count=$(git ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
    if [ "$staged_count" -eq 0 ] && [ "$unstaged_count" -eq 0 ] && [ "$untracked_count" -eq 0 ]; then
        log_warning "No hay cambios para subir"
        log_info "El repositorio está al día con GitHub"
        # Mostrar estado remoto
        echo ""
        git remote -v
        git branch -vv
        return 0
    fi
    # Si no hay archivos staged, ofrecer agregar
    if [ "$staged_count" -eq 0 ]; then
        log_warning "No hay archivos preparados para commit"
        if ! interactive_add; then
            return 0
        fi
    fi
    # Obtener archivos staged para análisis
    local staged_files
    staged_files=$(git diff --cached --name-only 2>/dev/null)
    # Generar mensaje de commit automático
    local commit_msg
    if [ "$LANG" = "es" ]; then
        commit_msg=$(generate_commit_message_es "$staged_files")
    else
        commit_msg=$(generate_commit_message_en "$staged_files")
    fi
    # Mostrar mensaje generado y permitir edición
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💬 Mensaje de commit generado automáticamente:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   $commit_msg"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "¿Qué deseas hacer?"
    echo "   1) Usar mensaje automático"
    echo "   2) Editar mensaje"
    echo "   3) Cancelar"
    echo ""
    read -p "$MSG_SELECT_OPTION " msg_choice
    case $msg_choice in
        1)
            # Usar mensaje automático
            git commit -m "$commit_msg"
            log_success "Commit realizado: $commit_msg"
            ;;
        2)
            # Editar mensaje
            echo ""
            read -p "✏️  Ingresa tu mensaje de commit: " custom_msg
            if [ -n "$custom_msg" ]; then
                git commit -m "$custom_msg"
                log_success "Commit realizado: $custom_msg"
            else
                log_error "Mensaje vacío, cancelando commit"
                return 1
            fi
            ;;
        3)
            log_info "Operación cancelada"
            return 0
            ;;
        *)
            log_error "$MSG_INVALID_OPTION"
            return 1
            ;;
    esac
    # Obtener branch actual
    local current_branch
    current_branch=$(git branch --show-current)
    # Subir cambios a GitHub
    echo ""
    log_info "Subiendo cambios a GitHub (branch: $current_branch)..."
    if git push -u origin "$current_branch"; then
        log_success "Cambios subidos exitosamente"
        # Mostrar último commit
        echo ""
        echo "📋 Último commit:"
        git log -1 --oneline
    else
        log_error "Error al subir cambios"
        log_info "Verifica tu conexión y autenticación"
        return 1
    fi
}
# Exportar función
export -f repo_push
