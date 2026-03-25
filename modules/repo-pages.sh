#!/usr/bin/env bash
#===============================================================================
# Módulo 8: Configurar GitHub Pages
#===============================================================================
# Función para obtener información del repositorio
get_repo_info() {
    local remote_url
    remote_url=$(git remote get-url origin 2>/dev/null)
    if [ -z "$remote_url" ]; then
        log_error "No hay remote configurado"
        return 1
    fi
    # Extraer usuario/repo
    if [[ "$remote_url" =~ github\.com[:/]([^/]+/[^/]+)(\.git)?$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    else
        log_error "No se pudo determinar el repositorio"
        return 1
    fi
}
# Función para verificar estado actual de Pages
check_pages_status() {
    local repo_path="$1"
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_warning "Se requiere token para verificar estado de Pages"
        return 1
    fi
    local response
    response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
                    -H "Accept: application/vnd.github.v3+json" \
                    "https://api.github.com/repos/${repo_path}/pages" 2>/dev/null)
    if echo "$response" | grep -q '"html_url"'; then
        local pages_url
        pages_url=$(echo "$response" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)
        local branch
        branch=$(echo "$response" | grep -o '"branch":"[^"]*"' | cut -d'"' -f4)
        local path
        path=$(echo "$response" | grep -o '"path":"[^"]*"' | cut -d'"' -f4)
        echo "✅ GitHub Pages está activo"
        echo "   🔗 URL: $pages_url"
        echo "   🌿 Branch: $branch"
        echo "   📁 Path: $path"
        return 0
    elif echo "$response" | grep -q '"message":"Not Found"'; then
        echo "❌ GitHub Pages no está configurado"
        return 2
    else
        echo "⚠️  No se pudo verificar el estado de Pages"
        return 1
    fi
}
# Función para detectar tipo de proyecto
detect_project_type() {
    local project_type="static"
    if [ -f "package.json" ]; then
        if grep -q '"react"' package.json || grep -q '"next"' package.json; then
            project_type="react"
        elif grep -q '"vue"' package.json; then
            project_type="vue"
        elif grep -q '"angular"' package.json; then
            project_type="angular"
        else
            project_type="node"
        fi
    elif [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
        project_type="python"
    elif [ -f "Gemfile" ]; then
        project_type="ruby"
    elif [ -f "Cargo.toml" ]; then
        project_type="rust"
    elif [ -f "go.mod" ]; then
        project_type="golang"
    elif [ -f "mkdocs.yml" ]; then
        project_type="mkdocs"
    elif [ -f "docs/index.html" ] || [ -f "public/index.html" ]; then
        project_type="static"
    fi
    echo "$project_type"
}
# Función para sugerir configuración según tipo de proyecto
suggest_pages_config() {
    local project_type="$1"
    echo ""
    echo "💡 Configuración sugerida para $project_type:"
    case $project_type in
        react|vue|angular)
            echo "   📦 Build command: npm run build"
            echo "   📁 Publish directory: dist/ (o build/)"
            echo "   🌿 Branch: gh-pages"
            ;;
        node)
            echo "   📦 Build command: npm run build (si existe)"
            echo "   📁 Publish directory: ./"
            echo "   🌿 Branch: main"
            ;;
        python)
            echo "   📁 Publish directory: ./docs/"
            echo "   🌿 Branch: gh-pages"
            ;;
        mkdocs)
            echo "   📦 Build command: mkdocs build"
            echo "   📁 Publish directory: site/"
            echo "   🌿 Branch: gh-pages"
            ;;
        static)
            echo "   📁 Publish directory: ./"
            echo "   🌿 Branch: main"
            ;;
    esac
}
# Función para crear archivo de workflow de Pages
create_pages_workflow() {
    local project_type="$1"
    local workflow_dir=".github/workflows"
    mkdir -p "$workflow_dir"
    local workflow_file="${workflow_dir}/pages.yml"
    cat > "$workflow_file" << 'EOF'
# GitHub Pages workflow
name: Deploy to GitHub Pages
on:
  push:
    branches: [main, master]
  workflow_dispatch:
permissions:
  contents: read
  pages: write
  id-token: write
concurrency:
  group: pages
  cancel-in-progress: false
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
EOF
    # Agregar steps específicos según tipo de proyecto
    case $project_type in
        react|vue|angular|node)
            cat >> "$workflow_file" << 'EOF'
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - name: Install dependencies
        run: npm ci
      - name: Build
        run: npm run build
EOF
            ;;
        python)
            cat >> "$workflow_file" << 'EOF'
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.x'
      - name: Build documentation
        run: |
          pip install -r requirements.txt
          mkdocs build --site-dir _site || true
EOF
            ;;
        mkdocs)
            cat >> "$workflow_file" << 'EOF'
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.x'
      - name: Install mkdocs
        run: pip install mkdocs mkdocs-material
      - name: Build site
        run: mkdocs build
EOF
            ;;
    esac
    # Agregar step de upload
    cat >> "$workflow_file" << 'EOF'
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: .
EOF
    cat >> "$workflow_file" << 'EOF'
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF
    log_success "Workflow de Pages creado: $workflow_file"
}
# Función para crear archivo index.html de prueba
create_test_index() {
    local repo_name
    repo_name=$(basename "$(pwd)")
    if [ ! -f "index.html" ] && [ ! -d "public" ] && [ ! -d "docs" ]; then
        cat > "index.html" << EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${repo_name} - GitHub Pages</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
            text-align: center;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: white;
        }
        .container {
            background: rgba(255,255,255,0.1);
            border-radius: 20px;
            padding: 2rem;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        .repo { font-size: 1.2rem; opacity: 0.9; }
        .footer { margin-top: 2rem; font-size: 0.9rem; opacity: 0.8; }
        a { color: white; text-decoration: underline; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 ${repo_name}</h1>
        <p class="repo">GitHub Pages activado con GitHub Repository Manager</p>
        <p>Sitio en construcción. Configura tu contenido en la rama configurada.</p>
        <div class="footer">
            <p>📦 Generado por <a href="https://github.com/donshuapps-cloud">Donshu Apps</a></p>
        </div>
    </div>
</body>
</html>
EOF
        log_info "Archivo index.html de prueba creado"
    fi
}
# Función para habilitar Pages vía API
enable_pages_api() {
    local repo_path="$1"
    local branch="$2"
    local path="$3"
    local response
    response=$(curl -s -X POST "https://api.github.com/repos/${repo_path}/pages" \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -d "{
            \"source\": {
                \"branch\": \"${branch}\",
                \"path\": \"${path}\"
            }
        }")
    if echo "$response" | grep -q '"html_url"'; then
        local pages_url
        pages_url=$(echo "$response" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)
        log_success "GitHub Pages habilitado: $pages_url"
        return 0
    else
        local error_msg
        error_msg=$(echo "$response" | grep -o '"message":"[^"]*"' | cut -d'"' -f4)
        log_error "Error al habilitar Pages: ${error_msg:-Desconocido}"
        return 1
    fi
}
# Función principal para configurar Pages
repo_pages() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "🌐 CONFIGURAR GITHUB PAGES"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Verificar dependencias
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_error "Se requiere token de GitHub para configurar Pages"
        log_info "Configura la variable de entorno GITHUB_TOKEN"
        return 1
    fi
    # Verificar que estamos en un repositorio git
    if ! git rev-parse --git-dir &>/dev/null; then
        log_error "No estás en un repositorio Git"
        log_info "Ejecuta la opción 1 o 2 primero para inicializar un repositorio"
        return 1
    fi
    # Obtener información del repositorio
    local repo_path
    repo_path=$(get_repo_info)
    if [ -z "$repo_path" ]; then
        return 1
    fi
    echo ""
    echo "📦 Repositorio: $repo_path"
    # Verificar estado actual
    echo ""
    check_pages_status "$repo_path"
    local pages_status=$?
    # Detectar tipo de proyecto
    local project_type
    project_type=$(detect_project_type)
    echo ""
    echo "📁 Tipo de proyecto detectado: $project_type"
    # Sugerir configuración
    suggest_pages_config "$project_type"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 CONFIGURACIÓN DE GITHUB PAGES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    # Solicitar branch
    local default_branch
    default_branch=$(git branch --show-current)
    default_branch="${default_branch:-main}"
    read -p "🌿 Branch para Pages [${default_branch}]: " pages_branch
    pages_branch="${pages_branch:-$default_branch}"
    # Solicitar path
    echo ""
    echo "📁 Path del contenido:"
    echo "   • / (root) - para contenido en la raíz"
    echo "   • /docs - para contenido en carpeta docs/"
    read -p "Selecciona path [/ o docs] [/]: " pages_path
    if [ -z "$pages_path" ] || [ "$pages_path" = "/" ]; then
        pages_path="/"
    elif [ "$pages_path" = "docs" ]; then
        pages_path="/docs"
    else
        pages_path="/"
    fi
    echo ""
    echo "📋 Resumen de configuración:"
    echo "   🔗 Repositorio: $repo_path"
    echo "   🌿 Branch: $pages_branch"
    echo "   📁 Path: $pages_path"
    echo ""
    read -p "¿Confirmar y habilitar GitHub Pages? (s/n): " confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        log_info "Operación cancelada"
        return 0
    fi
    # Crear archivo de prueba si no existe contenido
    create_test_index
    # Habilitar Pages vía API
    if enable_pages_api "$repo_path" "$pages_branch" "$pages_path"; then
        echo ""
        log_success "GitHub Pages configurado exitosamente"
        # Preguntar si desea crear workflow automático
        echo ""
        read -p "¿Deseas crear un workflow de GitHub Actions para automatizar Pages? (s/n): " create_workflow
        if [[ "$create_workflow" =~ ^[Ss]$ ]]; then
            create_pages_workflow "$project_type"
            git add .github/workflows/pages.yml
            log_info "Workflow agregado. No olvides commitear y pushear los cambios."
        fi
        echo ""
        echo "📌 Próximos pasos:"
        echo "   1. Asegúrate de tener contenido en la rama '$pages_branch' en la ruta '$pages_path'"
        echo "   2. Espera unos minutos a que GitHub procese la configuración"
        echo "   3. Visita: https://${repo_path%/*}.github.io/${repo_path#*/}/"
        echo "   4. (Opcional) Configura un dominio personalizado en la sección Pages del repositorio"
    fi
}
# Exportar función
export -f repo_pages
