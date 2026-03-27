#!/usr/bin/env bash
#===============================================================================
# GitHub Repository Manager - Script principal
# Versión: 1.0.0
# Autor: Donshu
# GitHub: https://github.com/donshuapps-cloud
# Email: donshu.apps@gmail.com
#===============================================================================
set -euo pipefail
IFS=$'\n\t'
#===============================================================================
# CONFIGURACIÓN INICIAL
#===============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
MODULES_DIR="${SCRIPT_DIR}/modules"
CORE_DIR="${SCRIPT_DIR}/core"
LOCALES_DIR="${SCRIPT_DIR}/locales"
UTILS_DIR="${SCRIPT_DIR}/utils"
# Cargar configuración
source "${CORE_DIR}/config.sh"
source "${CORE_DIR}/i18n.sh"
source "${CORE_DIR}/auth.sh"
#===============================================================================
# FUNCIONES PRINCIPALES
#===============================================================================
show_header() {
    clear
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║     🚀 GITHUB REPOSITORY MANAGER v1.0                            ║"
    echo "║     📦 Sistema de gestión de repositorios GitHub                  ║"
    echo "║                                                                   ║"
    echo "║     👤 Usuario: ${GITHUB_USER:-$(git config user.name 2>/dev/null || echo 'No configurado')}        ║"
    echo "║     📁 Proyecto: $(basename "$(pwd)" 2>/dev/null || echo 'Sin proyecto')                           ║"
    echo "║     🌐 Idioma: ${LANG^^}                                          ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo ""
}
show_main_menu() {
    echo "$MSG_MENU_MAIN_TITLE"
    echo ""
    echo "📦 $MSG_MENU_REPO_SECTION"
    echo "  1) $MSG_MENU_CREATE_NEW"
    echo "  2) $MSG_MENU_INIT_EXISTING"
    echo "  3) $MSG_MENU_PUSH_CHANGES"
    echo "  4) $MSG_MENU_CLONE_REPO"
    echo "  5) $MSG_MENU_VIEW_STATUS"
    echo ""
    echo "🌿 $MSG_MENU_VERSION_SECTION"
    echo "  6) $MSG_MENU_MANAGE_BRANCHES"
    echo "  7) $MSG_MENU_MANAGE_TAGS"
    echo " 11) $MSG_MENU_VIEW_HISTORY"
    echo ""
    echo "⚙️  $MSG_MENU_ADVANCED_SECTION"
    echo "  8) $MSG_MENU_SETUP_PAGES"
    echo "  9) $MSG_MENU_SETUP_ACTIONS"
    echo " 12) $MSG_MENU_SETUP_GITIGNORE"
    echo " 13) $MSG_MENU_GENERATE_DOCS"
    echo ""
    echo "🗑️  $MSG_MENU_UTILITIES_SECTION"
    echo " 10) $MSG_MENU_REMOVE_LOCAL"
    echo "  0) $MSG_MENU_EXIT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}
main() {
    # Verificar dependencias
    check_dependencies
    # Configurar autenticación
    setup_authentication
    # Bucle principal
    while true; do
        show_header
        show_main_menu
        read -p "$MSG_SELECT_OPTION " option
        case $option in
            1) source "${MODULES_DIR}/repo-create.sh"; repo_create ;;
            2) source "${MODULES_DIR}/repo-init.sh"; repo_init ;;
            3) source "${MODULES_DIR}/repo-push.sh"; repo_push ;;
            4) source "${MODULES_DIR}/repo-clone.sh"; repo_clone ;;
            5) source "${MODULES_DIR}/repo-status.sh"; repo_status ;;
            6) source "${MODULES_DIR}/repo-branch.sh"; repo_branch ;;
            7) source "${MODULES_DIR}/repo-tags.sh"; repo_tags ;;
            8) source "${MODULES_DIR}/repo-pages.sh"; repo_pages ;;
            9) source "${MODULES_DIR}/repo-actions.sh"; repo_actions ;;
            10) source "${MODULES_DIR}/repo-remove-local.sh"; repo_remove_local ;;
            11) source "${MODULES_DIR}/repo-history.sh"; repo_history ;;
            12) source "${MODULES_DIR}/repo-gitignore.sh"; repo_gitignore ;;
            13) echo "Módulo 13: Próximamente en Iteración 6"; sleep 2 ;;
            0) echo "$MSG_GOODBYE"; exit 0 ;;
            *) echo "$MSG_INVALID_OPTION"; sleep 2 ;;
        esac
        echo ""
        read -p "$MSG_PRESS_ENTER"
    done
}
#===============================================================================
# PUNTO DE ENTRADA
#===============================================================================
main "$@"
