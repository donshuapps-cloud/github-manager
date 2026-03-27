#!/usr/bin/env bash
#===============================================================================
# Sistema de Internacionalización (i18n)
#===============================================================================
# Detectar idioma del sistema si no está configurado
detect_language() {
    if [ -z "${LANG:-}" ] || [ "$LANG" = "auto" ]; then
        # Detectar idioma del sistema - tomar solo los primeros 2 caracteres
        local sys_lang="${LANG:-${LC_ALL:-${LC_MESSAGES:-en}}}"
        # Extraer código de idioma (ej: es_VE.UTF-8 -> es)
        sys_lang="${sys_lang:0:2}"
        case "$sys_lang" in
            es) LANG="es" ;;
            en) LANG="en" ;;
            *) LANG="es" ;;  # Español por defecto
        esac
    fi
    # Asegurar que LANG tiene solo 2 caracteres
    LANG="${LANG:0:2}"
    # Cargar archivo de idioma
    load_language
}
# Cargar archivo de idioma específico
load_language() {
    local lang_file="${LOCALES_DIR:-$SCRIPT_DIR/locales}/${LANG}.sh"
    if [ -f "$lang_file" ]; then
        source "$lang_file"
        log_debug "Idioma cargado: ${LANG} (${lang_file})"
    else
        # Fallback a español si no existe el archivo
        log_warning "Idioma '${LANG}' no encontrado, usando español por defecto"
        LANG="es"
        lang_file="${LOCALES_DIR:-$SCRIPT_DIR/locales}/es.sh"
        if [ -f "$lang_file" ]; then
            source "$lang_file"
        else
            log_error "Archivo de idioma español no encontrado en $lang_file"
            exit 1
        fi
    fi
}
# Cambiar idioma dinámicamente
change_language() {
    echo ""
    echo "$MSG_CHANGE_LANGUAGE"
    echo "  1) Español"
    echo "  2) English"
    echo "  0) $MSG_CANCEL"
    echo ""
    read -p "$MSG_SELECT_OPTION " lang_choice
    case $lang_choice in
        1)
            LANG="es"
            load_language
            log_success "$MSG_LANG_CHANGED"
            ;;
        2)
            LANG="en"
            load_language
            log_success "$MSG_LANG_CHANGED"
            ;;
        0)
            return
            ;;
        *)
            log_error "$MSG_INVALID_OPTION"
            ;;
    esac
    save_config
    sleep 1
}
# Inicializar detección de idioma
detect_language
# Exportar funciones para uso en módulos
export -f change_language
