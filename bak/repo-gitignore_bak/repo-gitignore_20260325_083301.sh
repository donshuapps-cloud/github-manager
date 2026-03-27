#!/usr/bin/env bash
#===============================================================================
# Módulo 12: Configurar .gitignore personalizado
#===============================================================================
# Plantillas predefinidas de .gitignore
declare -A GITIGNORE_TEMPLATES
# Inicializar plantillas
init_templates() {
    GITIGNORE_TEMPLATES=(
        ["python"]="# Python\n__pycache__/\n*.py[cod]\n*$py.class\n*.so\n.Python\nenv/\nvenv/\nENV/\n.venv\npip-log.txt\npip-delete-this-directory.txt\n.pytest_cache/\n.coverage\nhtmlcov/\n.tox/\n.mypy_cache/\n.dmypy.json\ndmypy.json\n.pyre/\n"
        ["node"]="# Node.js\nnode_modules/\nnpm-debug.log*\nyarn-debug.log*\nyarn-error.log*\npackage-lock.json\nyarn.lock\n.env\n.env.local\n.env.development.local\n.env.test.local\n.env.production.local\n.DS_Store\ndist/\nbuild/\ncoverage/\n"
        ["python-node"]="# Python + Node.js\n# Python\n__pycache__/\n*.py[cod]\nvenv/\n.venv/\n# Node.js\nnode_modules/\nnpm-debug.log*\npackage-lock.json\n.env\n"
        ["java"]="# Java\n*.class\n*.jar\n*.war\n*.ear\n*.nar\nhs_err_pid*\ntarget/\nbuild/\n.mvn/\nmvnw\nmvnw.cmd\n\n# IDE\n.idea/\n*.iml\n.classpath\n.project\n.settings/\n"
        ["go"]="# Go\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\n*.test\n*.out\n/vendor/\n/bin/\n/pkg/\n/dist/\n\n# IDE\n.idea/\n*.iml\n.vscode/\n"
        ["rust"]="# Rust\n/target/\n**/*.rs.bk\n*.pdb\nCargo.lock\n\n# IDE\n.idea/\n*.iml\n.vscode/\n"
        ["ruby"]="# Ruby\n*.gem\n*.rbc\n/.config\n/coverage/\n/InstalledFiles\n/pkg/\n/spec/reports/\n/spec/examples.txt\n/test/tmp/\n/test/version_tmp/\n/tmp/\n\n# rvm\n.rvmrc\n"
        ["php"]="# PHP\ncomposer.phar\n/vendor/\ncomposer.lock\n.env\n.phpunit.result.cache\n*.log\n\n# IDE\n.idea/\n*.iml\n.vscode/\n"
        ["c"]="# C/C++\n*.o\n*.obj\n*.exe\n*.dll\n*.so\n*.dylib\n*.a\n*.lib\n*.out\n*.app\n\n# IDE\n.vscode/\n.idea/\n*.swp\n*.swo\n*~\n"
        ["docker"]="# Docker\n*.tar\n*.tar.gz\n*.log\n.Dockerfile*\ndocker-compose.override.yml\n\n# IDE\n.vscode/\n.idea/\n"
        ["terraform"]="# Terraform\n*.tfstate\n*.tfstate.*\n.terraform/\ncrash.log\noverride.tf\noverride.tf.json\n*_override.tf\n*_override.tf.json\n.terraformrc\nterraform.rc\n"
        ["kubernetes"]="# Kubernetes\n*.secret.yaml\n*.secret.yml\n*.local.yaml\n*.local.yml\nkubeconfig\n\n# Helm\ncharts/*.tgz\n"
        ["os"]="# OS\n.DS_Store\n.DS_Store?\n._*\n.Spotlight-V100\n.Trashes\nehthumbs.db\nThumbs.db\n*.swp\n*.swo\n*~\n"
        ["editor"]="# Editor\n.vscode/\n.idea/\n*.sublime-project\n*.sublime-workspace\n.project\n.classpath\n.settings/\n*.swp\n*.swo\n*~\n"
        ["logs"]="# Logs\n*.log\nnpm-debug.log*\nyarn-debug.log*\nyarn-error.log*\nlerna-debug.log*\nlogs/\nlog/\n"
        ["secrets"]="# Secrets\n.env\n.env.local\n.env.*.local\n*.key\n*.pem\n*.cert\n*.crt\n*.p12\n*.pfx\nsecrets/\ncredentials/\n"
        ["custom"]="# Custom .gitignore\n# Agrega tus propias reglas aquí\n\n"
    )
}
# Función para detectar tipo de proyecto
detect_project_type_for_gitignore() {
    local detected=()
    if [ -f "package.json" ]; then
        detected+=("node")
    fi
    if [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        detected+=("python")
    fi
    if [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
        detected+=("java")
    fi
    if [ -f "go.mod" ]; then
        detected+=("go")
    fi
    if [ -f "Cargo.toml" ]; then
        detected+=("rust")
    fi
    if [ -f "Gemfile" ]; then
        detected+=("ruby")
    fi
    if [ -f "composer.json" ]; then
        detected+=("php")
    fi
    if [ -f "Dockerfile" ]; then
        detected+=("docker")
    fi
    if [ -f "main.tf" ] || [ -f "terraform.tf" ]; then
        detected+=("terraform")
    fi
    if [ -f "k8s/" ] || [ -d "k8s" ]; then
        detected+=("kubernetes")
    fi
    # Siempre agregar OS, Editor, Logs, Secrets como base
    detected+=("os" "editor" "logs" "secrets")
    echo "${detected[@]}"
}
# Función para mostrar .gitignore actual
show_current_gitignore() {
    if [ -f ".gitignore" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📄 CONTENIDO ACTUAL DE .gitignore"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        cat .gitignore
        echo ""
        local line_count
        line_count=$(wc -l < .gitignore | tr -d ' ')
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "Total: $line_count líneas"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    else
        echo ""
        echo "📄 No existe archivo .gitignore en el proyecto"
    fi
}
# Función para crear .gitignore desde plantilla
create_gitignore_from_template() {
    local template_name="$1"
    local output_file="$2"
    if [ -n "${GITIGNORE_TEMPLATES[$template_name]}" ]; then
        echo -e "${GITIGNORE_TEMPLATES[$template_name]}" >> "$output_file"
        return 0
    fi
    return 1
}
# Función para generar .gitignore inteligente
generate_intelligent_gitignore() {
    local output_file="$1"
    local detected_types
    detected_types=($(detect_project_type_for_gitignore))
    echo ""
    log_info "Generando .gitignore basado en el tipo de proyecto detectado..."
    # Crear archivo con header
    cat > "$output_file" << 'EOF'
# ============================================================================
# .gitignore generado automáticamente por GitHub Repository Manager
# Fecha: $(date)
# Proyecto: $(basename "$(pwd)")
# ============================================================================
EOF
    # Agregar plantillas según tipos detectados
    local added_templates=()
    for type in "${detected_types[@]}"; do
        if create_gitignore_from_template "$type" "$output_file"; then
            added_templates+=("$type")
            echo "" >> "$output_file"
        fi
    done
    # Agregar el propio script al .gitignore si existe
    if [ -d "github-manager" ]; then
        echo "" >> "$output_file"
        echo "# GitHub Repository Manager (auto-incluido)" >> "$output_file"
        echo "github-manager/" >> "$output_file"
        added_templates+=("github-manager")
    fi
    echo ""
    log_success ".gitignore generado con los siguientes tipos: ${added_templates[*]}"
}
# Función para fusionar .gitignore existente con nueva configuración
merge_gitignore() {
    local existing_file="$1"
    local new_content="$2"
    local temp_file
    temp_file=$(mktemp)
    # Copiar contenido existente
    cp "$existing_file" "$temp_file"
    # Agregar separador
    echo "" >> "$temp_file"
    echo "# ============================================================================" >> "$temp_file"
    echo "# Agregado por GitHub Repository Manager el $(date)" >> "$temp_file"
    echo "# ============================================================================" >> "$temp_file"
    echo "" >> "$temp_file"
    # Agregar nuevo contenido
    echo "$new_content" >> "$temp_file"
    # Eliminar duplicados manteniendo orden
    awk '!seen[$0]++' "$temp_file" > "$existing_file"
    rm "$temp_file"
    log_success "Configuración fusionada con .gitignore existente"
}
# Función para agregar regla personalizada
add_custom_rule() {
    echo ""
    echo "➕ AGREGAR REGLA PERSONALIZADA"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 Ejemplos de reglas:"
    echo "   • *.log                    # Ignorar todos los logs"
    echo "   • temp/                    # Ignorar directorio temp"
    echo "   • config.local.*           # Ignorar archivos config.local.*"
    echo "   • !.env.example            # Exceptuar .env.example"
    echo ""
    read -p "🔧 Ingresa la regla: " custom_rule
    if [ -n "$custom_rule" ]; then
        if [ -f ".gitignore" ]; then
            echo "" >> .gitignore
            echo "# Regla personalizada agregada el $(date)" >> .gitignore
            echo "$custom_rule" >> .gitignore
        else
            echo "# Regla personalizada agregada el $(date)" > .gitignore
            echo "$custom_rule" >> .gitignore
        fi
        log_success "Regla agregada: $custom_rule"
    else
        log_error "Regla vacía, no se agregó nada"
    fi
}
# Función para listar archivos ignorados
list_ignored_files() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 ARCHIVOS IGNORADOS ACTUALMENTE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if git ls-files --ignored --exclude-standard 2>/dev/null | head -20 | while read -r file; do
        echo "   📄 $file"
    done; then
        local total
        total=$(git ls-files --ignored --exclude-standard 2>/dev/null | wc -l | tr -d ' ')
        if [ "$total" -gt 20 ]; then
            echo "   ... y $((total - 20)) archivos más"
        fi
        echo ""
        echo "Total: $total archivos ignorados"
    else
        echo "   No hay archivos ignorados"
    fi
}
# Función principal para configurar .gitignore
repo_gitignore() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "📄 CONFIGURAR .gitignore PERSONALIZADO"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Inicializar plantillas
    init_templates
    # Verificar que estamos en un repositorio git
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "No estás en un repositorio Git"
        log_info "Ejecuta la opción 1 o 2 primero para inicializar un repositorio"
        return 1
    fi
    # Mostrar .gitignore actual
    show_current_gitignore
    # Detectar tipos de proyecto
    local detected_types
    detected_types=($(detect_project_type_for_gitignore))
    echo ""
    echo "🔍 Tipo de proyecto detectado: ${detected_types[*]}"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 OPCIONES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   1) Generar .gitignore inteligente (basado en el proyecto)"
    echo "   2) Agregar regla personalizada"
    echo "   3) Ver archivos actualmente ignorados"
    echo "   4) Limpiar archivos ignorados del repositorio"
    echo "   5) Volver al menú principal"
    echo ""
    read -p "$MSG_SELECT_OPTION " gitignore_option
    case $gitignore_option in
        1)
            if [ -f ".gitignore" ]; then
                echo ""
                read -p "Ya existe .gitignore. ¿Deseas fusionar con la nueva configuración? (s/n): " merge_choice
                if [[ "$merge_choice" =~ ^[Ss]$ ]]; then
                    local temp_content
                    temp_content=$(mktemp)
                    generate_intelligent_gitignore "$temp_content"
                    merge_gitignore ".gitignore" "$(cat "$temp_content")"
                    rm "$temp_content"
                else
                    read -p "¿Deseas sobrescribir el archivo existente? (s/n): " overwrite_choice
                    if [[ "$overwrite_choice" =~ ^[Ss]$ ]]; then
                        generate_intelligent_gitignore ".gitignore"
                    else
                        log_info "Operación cancelada"
                    fi
                fi
            else
                generate_intelligent_gitignore ".gitignore"
            fi
            echo ""
            log_success ".gitignore configurado exitosamente"
            echo ""
            echo "📌 Próximos pasos:"
            echo "   1. Revisa el archivo .gitignore generado"
            echo "   2. Si hay archivos que ya estaban trackeados y quieres ignorarlos:"
            echo "      git rm --cached <archivo>"
            echo "   3. Haz commit de los cambios:"
            echo "      git add .gitignore"
            echo "      git commit -m \"chore: update .gitignore\""
            ;;
        2)
            add_custom_rule
            ;;
        3)
            list_ignored_files
            ;;
        4)
            echo ""
            echo "⚠️  Esto eliminará del repositorio los archivos ignorados que ya estaban trackeados"
            read -p "¿Deseas continuar? (s/n): " clean_choice
            if [[ "$clean_choice" =~ ^[Ss]$ ]]; then
                git ls-files -i --exclude-standard -z | xargs -0 git rm --cached 2>/dev/null
                log_success "Archivos ignorados removidos del índice"
                echo "💡 Recuerda hacer commit de los cambios"
            fi
            ;;
        5)
            return 0
            ;;
        *)
            log_error "$MSG_INVALID_OPTION"
            ;;
    esac
    echo ""
    read -p "$MSG_PRESS_ENTER"
}
# Exportar función
export -f repo_gitignore
