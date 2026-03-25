#!/usr/bin/env bash
#===============================================================================
# Configuración Central
#===============================================================================
# Variables de entorno y configuración global
SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="GitHub Repository Manager"
# Configuración de usuario (se sobrescribe con settings.conf si existe)
GITHUB_USER="${GITHUB_USER:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
LANG="${LANG:-es}"
# Rutas de configuración
CONFIG_FILE="${CONFIG_DIR:-$SCRIPT_DIR/config}/settings.conf"
SSH_KEY_PATH="${HOME}/.ssh/id_ed25519"
# Colores para output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    MAGENTA='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    MAGENTA=''
    CYAN=''
    WHITE=''
    BOLD=''
    NC=''
fi
# Funciones de logging
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}
log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}
log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}
log_success() {
    echo -e "${GREEN}✓${NC} $1"
}
log_debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        echo -e "${CYAN}[DEBUG]${NC} $1"
    fi
}
# Cargar configuración persistente si existe
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        log_debug "Configuración cargada desde $CONFIG_FILE"
    fi
}
# Guardar configuración persistente
save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" << EOF
# GitHub Repository Manager Configuration
# Generado automáticamente el $(date)
GITHUB_USER="$GITHUB_USER"
DEFAULT_BRANCH="$DEFAULT_BRANCH"
LANG="$LANG"
EOF
    log_debug "Configuración guardada en $CONFIG_FILE"
}
# Verificar dependencias
check_dependencies() {
    local missing_deps=()
    # Verificar git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    # Verificar curl
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    # Verificar jq (opcional, se usa para API)
    if ! command -v jq &> /dev/null; then
        log_warning "jq no está instalado. Algunas funciones avanzadas pueden no funcionar."
        log_warning "Instálalo con: apt-get install jq  o  brew install jq"
    fi
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Dependencias faltantes: ${missing_deps[*]}"
        log_error "Por favor instálalas antes de continuar."
        exit 1
    fi
    log_success "Todas las dependencias están instaladas"
}
# Inicializar configuración
load_config
