#!/usr/bin/env bash
#===============================================================================
# Utilidades de Prompts Interactivos
#===============================================================================
# Prompt con validación de sí/no
prompt_yes_no() {
    local prompt_text="$1"
    local default="${2:-}"
    local response
    while true; do
        if [ -n "$default" ]; then
            read -p "$prompt_text [$default]: " response
            response=${response:-$default}
        else
            read -p "$prompt_text (s/n): " response
        fi
        case $response in
            [Ss]|[Yy]|s|y|si|Si|SI|yes|Yes|YES)
                return 0
                ;;
            [Nn]|n|no|No|NO)
                return 1
                ;;
            *)
                log_error "$MSG_VALIDATE_YES_NO"
                ;;
        esac
    done
}
# Prompt con validación de texto no vacío
prompt_non_empty() {
    local prompt_text="$1"
    local response
    while true; do
        read -p "$prompt_text " response
        if [ -n "$response" ]; then
            echo "$response"
            return 0
        else
            log_error "$MSG_VALIDATE_NAME"
        fi
    done
}
# Prompt con opciones
prompt_select() {
    local prompt_text="$1"
    shift
    local options=("$@")
    local choice
    echo "$prompt_text"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    echo ""
    read -p "Seleccione una opción [1-${#options[@]}]: " choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
        echo "${options[$((choice-1))]}"
        return 0
    else
        log_error "Opción inválida"
        return 1
    fi
}
# Prompt con validación de nombre de repositorio
prompt_repo_name() {
    local prompt_text="$1"
    local response
    while true; do
        read -p "$prompt_text " response
        if [ -z "$response" ]; then
            log_error "$MSG_VALIDATE_NAME"
        elif [[ ! "$response" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            log_error "$MSG_VALIDATE_NAME_INVALID"
        else
            echo "$response"
            return 0
        fi
    done
}
# Prompt para contraseña/token (modo silencioso)
prompt_secret() {
    local prompt_text="$1"
    local secret
    read -s -p "$prompt_text " secret
    echo ""
    echo "$secret"
}
# Exportar funciones
export -f prompt_yes_no
export -f prompt_non_empty
export -f prompt_select
export -f prompt_repo_name
export -f prompt_secret
