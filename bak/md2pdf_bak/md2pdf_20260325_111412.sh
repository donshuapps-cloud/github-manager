#!/usr/bin/env bash
# ============================================================
# Script: md2pdf.sh
# Descripción: Wrapper para pandoc que convierte Markdown a PDF
# Autor: Donshu
# Contacto: donshu.apps@gmail.com
# GitHub: https://github.com/donshuapps-cloud
# ============================================================
set -euo pipefail  # Modo estricto: error en cualquier fallo, variables no definidas, pipelines fallidos
# ============================================================
# CONFIGURACIÓN POR DEFECTO
# ============================================================
DEFAULT_FONT="Arial"
DEFAULT_ENGINE="xelatex"
DEFAULT_TEMPLATE=""
DEFAULT_CSS=""
DEFAULT_OUTPUT_DIR="."
# Colores para output (opcional, mejora legibilidad)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
# ============================================================
# FUNCIONES DE AYUDA
# ============================================================
print_usage() {
    cat << EOF
Uso: $(basename "$0") [OPCIONES] <archivo.md>
Convierte archivos Markdown a PDF usando pandoc con engine XeLaTeX.
OPCIONES:
    -o, --output DIR      Directorio de salida (por defecto: directorio actual)
    -f, --font FUENTE     Fuente principal (por defecto: $DEFAULT_FONT)
    -e, --engine ENGINE   Engine de LaTeX (por defecto: $DEFAULT_ENGINE)
    -t, --template ARCH   Plantilla de pandoc personalizada
    -c, --css ARCH        Hoja de estilos CSS (requiere --pdf-engine=weasyprint o similar)
    -h, --help            Muestra esta ayuda
    -v, --verbose         Modo verbose (muestra comandos ejecutados)
    --keep-temp           Conserva archivos temporales (debug)
EJEMPLOS:
    $(basename "$0") documento.md
    $(basename "$0") -o ./pdfs -f "Times New Roman" documento.md
    $(basename "$0") -e lualatex -t mi-plantilla.latex documento.md
REQUISITOS:
    - pandoc instalado
    - Distribución LaTeX con XeLaTeX (TeX Live, MiKTeX, MacTeX)
EOF
}
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}
log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}
# ============================================================
# VALIDACIÓN DE DEPENDENCIAS
# ============================================================
check_dependencies() {
    local missing=0
    if ! command -v pandoc &> /dev/null; then
        log_error "pandoc no está instalado. Instálalo desde https://pandoc.org/installing.html"
        missing=1
    fi
    # Verificar engine LaTeX (solo si no se usa opción que no requiere LaTeX)
    if [[ -z "${NO_LATEX_CHECK:-}" ]]; then
        case "$ENGINE" in
            xelatex|lualatex|pdflatex)
                if ! command -v "$ENGINE" &> /dev/null; then
                    log_error "$ENGINE no está disponible. Asegúrate de tener instalada una distribución LaTeX."
                    log_error "Opciones: TeX Live (Linux), MiKTeX (Windows), MacTeX (macOS)"
                    missing=1
                fi
                ;;
        esac
    fi
    return $missing
}
# ============================================================
# FUNCIÓN PRINCIPAL DE CONVERSIÓN
# ============================================================
convert_md_to_pdf() {
    local input_file="$1"
    local output_dir="$2"
    local output_filename
    # Validar archivo de entrada
    if [[ ! -f "$input_file" ]]; then
        log_error "Archivo no encontrado: $input_file"
        return 1
    fi
    if [[ ! "$input_file" =~ \.md$ ]]; then
        log_warn "El archivo no tiene extensión .md, pero se intentará convertir: $input_file"
    fi
    # Crear directorio de salida si no existe
    if [[ ! -d "$output_dir" ]]; then
        mkdir -p "$output_dir" || {
            log_error "No se pudo crear el directorio: $output_dir"
            return 1
        }
        log_info "Directorio creado: $output_dir"
    fi
    # Generar nombre de salida
    local basename_input
    basename_input=$(basename "$input_file" .md)
    output_filename="$output_dir/${basename_input}.pdf"
    # Construir comando pandoc
    local pandoc_cmd="pandoc \"$input_file\" -o \"$output_filename\" --pdf-engine=$ENGINE -V mainfont=\"$FONT\""
    # Añadir plantilla si se especificó
    if [[ -n "$TEMPLATE" ]]; then
        if [[ -f "$TEMPLATE" ]]; then
            pandoc_cmd="$pandoc_cmd --template=\"$TEMPLATE\""
            log_info "Usando plantilla: $TEMPLATE"
        else
            log_warn "Plantilla no encontrada: $TEMPLATE, se omitirá"
        fi
    fi
    # Añadir CSS si se especificó (útil con weasyprint u otros engines)
    if [[ -n "$CSS" ]]; then
        if [[ -f "$CSS" ]]; then
            pandoc_cmd="$pandoc_cmd --css=\"$CSS\""
            log_info "Usando CSS: $CSS"
        else
            log_warn "CSS no encontrado: $CSS, se omitirá"
        fi
    fi
    # Opciones adicionales para mejor manejo de caracteres y tablas
    pandoc_cmd="$pandoc_cmd -V geometry:margin=1in -V geometry:paper=a4paper"
    # Modo verbose
    if [[ "$VERBOSE" == true ]]; then
        log_info "Ejecutando: $pandoc_cmd"
    fi
    # Ejecutar conversión
    echo ""
    log_info "Convirtiendo: $input_file"
    log_info "Destino: $output_filename"
    echo ""
    if eval "$pandoc_cmd"; then
        echo ""
        log_info "✅ Conversión exitosa!"
        log_info "PDF generado: $output_filename"
        # Mostrar tamaño del archivo
        if [[ -f "$output_filename" ]]; then
            local file_size
            file_size=$(du -h "$output_filename" | cut -f1)
            log_info "Tamaño: $file_size"
        fi
        return 0
    else
        log_error "❌ Falló la conversión"
        return 1
    fi
}
# ============================================================
# PROCESAMIENTO DE ARGUMENTOS
# ============================================================
main() {
    # Variables con valores por defecto
    FONT="$DEFAULT_FONT"
    ENGINE="$DEFAULT_ENGINE"
    TEMPLATE="$DEFAULT_TEMPLATE"
    CSS="$DEFAULT_CSS"
    OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"
    VERBOSE=false
    KEEP_TEMP=false
    # No arguments? Show help
    if [[ $# -eq 0 ]]; then
        print_usage
        exit 1
    fi
    # Parsear argumentos
    local input_file=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -f|--font)
                FONT="$2"
                shift 2
                ;;
            -e|--engine)
                ENGINE="$2"
                shift 2
                ;;
            -t|--template)
                TEMPLATE="$2"
                shift 2
                ;;
            -c|--css)
                CSS="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --keep-temp)
                KEEP_TEMP=true
                shift
                ;;
            -*)
                log_error "Opción desconocida: $1"
                print_usage
                exit 1
                ;;
            *)
                if [[ -z "$input_file" ]]; then
                    input_file="$1"
                else
                    log_error "Múltiples archivos de entrada no soportados. Usa: $input_file (ignorando $1)"
                fi
                shift
                ;;
        esac
    done
    # Validar que se especificó archivo de entrada
    if [[ -z "$input_file" ]]; then
        log_error "No se especificó archivo de entrada"
        print_usage
        exit 1
    fi
    # Validar dependencias
    check_dependencies || exit 1
    # Ejecutar conversión
    convert_md_to_pdf "$input_file" "$OUTPUT_DIR"
    exit $?
}
# ============================================================
# EJECUCIÓN PRINCIPAL
# ============================================================
main "$@"
