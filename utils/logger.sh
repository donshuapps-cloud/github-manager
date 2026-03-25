#!/usr/bin/env bash
#===============================================================================
# Utilidades de Logging
#===============================================================================
# Niveles de log
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARNING=2
LOG_LEVEL_ERROR=3
LOG_LEVEL_SILENT=4
# Nivel actual (por defecto INFO)
CURRENT_LOG_LEVEL=${CURRENT_LOG_LEVEL:-$LOG_LEVEL_INFO}
# Función para establecer nivel de log
set_log_level() {
    case $1 in
        debug) CURRENT_LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
        info) CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
        warning) CURRENT_LOG_LEVEL=$LOG_LEVEL_WARNING ;;
        error) CURRENT_LOG_LEVEL=$LOG_LEVEL_ERROR ;;
        silent) CURRENT_LOG_LEVEL=$LOG_LEVEL_SILENT ;;
        *) CURRENT_LOG_LEVEL=$LOG_LEVEL_INFO ;;
    esac
}
# Log con timestamp
log_timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}
# Debug
log_debug() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_DEBUG ]; then
        echo -e "${CYAN}[DEBUG]${NC} $(log_timestamp) - $1" >&2
    fi
}
# Info
log_info() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
}
# Warning
log_warning() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARNING ]; then
        echo -e "${YELLOW}[WARN]${NC} $1" >&2
    fi
}
# Error
log_error() {
    if [ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ]; then
        echo -e "${RED}[ERROR]${NC} $1" >&2
    fi
}
# Success (formato especial)
log_success() {
    echo -e "${GREEN}✓${NC} $1"
}
# Exportar funciones
export -f log_debug
export -f log_info
export -f log_warning
export -f log_error
export -f log_success
export -f set_log_level
