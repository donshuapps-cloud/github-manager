#!/usr/bin/env bash
#===============================================================================
# Módulo 9: Configurar GitHub Actions (CI/CD)
#===============================================================================
# Función para verificar si Actions está habilitado
check_actions_status() {
    local repo_path="$1"
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_warning "Se requiere token para verificar estado de Actions"
        return 1
    fi
    local response
    response=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
                    -H "Accept: application/vnd.github.v3+json" \
                    "https://api.github.com/repos/${repo_path}/actions/workflows" 2>/dev/null)
    local workflow_count
    workflow_count=$(echo "$response" | grep -o '"id"' | wc -l | tr -d ' ')
    if [ "$workflow_count" -gt 0 ]; then
        echo "✅ GitHub Actions está configurado con $workflow_count workflow(s)"
        echo ""
        echo "📋 Workflows disponibles:"
        echo "$response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | sed 's/^/   • /'
        return 0
    else
        echo "❌ No hay workflows configurados"
        return 1
    fi
}
# Función para detectar lenguajes en el proyecto
detect_languages() {
    local languages=()
    if [ -f "package.json" ]; then
        languages+=("node")
    fi
    if [ -f "requirements.txt" ] || [ -f "setup.py" ] || [ -f "pyproject.toml" ]; then
        languages+=("python")
    fi
    if [ -f "Gemfile" ]; then
        languages+=("ruby")
    fi
    if [ -f "Cargo.toml" ]; then
        languages+=("rust")
    fi
    if [ -f "go.mod" ]; then
        languages+=("golang")
    fi
    if [ -f "Dockerfile" ]; then
        languages+=("docker")
    fi
    if [ ${#languages[@]} -eq 0 ]; then
        languages+=("basic")
    fi
    echo "${languages[@]}"
}
# Función para crear workflow de CI básico
create_ci_workflow() {
    local workflow_dir=".github/workflows"
    mkdir -p "$workflow_dir"
    local workflow_file="${workflow_dir}/ci.yml"
    cat > "$workflow_file" << 'EOF'
# CI/CD Workflow
name: CI/CD
on:
  push:
    branches: [main, master, develop]
  pull_request:
    branches: [main, master]
  workflow_dispatch:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Setup environment
        run: echo "Setting up environment..."
      - name: Run tests
        run: echo "Running tests..."
      - name: Lint code
        run: echo "Linting code..."
EOF
    log_success "Workflow CI básico creado: $workflow_file"
}
# Función para crear workflow específico por lenguaje
create_language_workflow() {
    local language="$1"
    local workflow_dir=".github/workflows"
    mkdir -p "$workflow_dir"
    case $language in
        node)
            local workflow_file="${workflow_dir}/node-ci.yml"
            cat > "$workflow_file" << 'EOF'
# Node.js CI Workflow
name: Node.js CI
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [18.x, 20.x, 22.x]
    steps:
      - uses: actions/checkout@v4
      - name: Use Node.js ${{ matrix.node-version }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'
      - run: npm ci
      - run: npm run build --if-present
      - run: npm test
EOF
            ;;
        python)
            local workflow_file="${workflow_dir}/python-ci.yml"
            cat > "$workflow_file" << 'EOF'
# Python CI Workflow
name: Python CI
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ['3.9', '3.10', '3.11', '3.12']
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
          if [ -f requirements-dev.txt ]; then pip install -r requirements-dev.txt; fi
      - name: Lint with flake8
        run: |
          pip install flake8
          flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
      - name: Test with pytest
        run: |
          pip install pytest pytest-cov
          pytest --cov=. --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          file: ./coverage.xml
EOF
            ;;
        rust)
            local workflow_file="${workflow_dir}/rust-ci.yml"
            cat > "$workflow_file" << 'EOF'
# Rust CI Workflow
name: Rust CI
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Rust
        uses: actions-rs/toolchain@v1
        with:
          profile: minimal
          toolchain: stable
          override: true
      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: |
            ~/.cargo/registry
            ~/.cargo/git
            target
          key: ${{ runner.os }}-cargo-${{ hashFiles('**/Cargo.lock') }}
      - name: Build
        run: cargo build --verbose
      - name: Run tests
        run: cargo test --verbose
      - name: Lint
        run: cargo clippy -- -D warnings
EOF
            ;;
        golang)
            local workflow_file="${workflow_dir}/go-ci.yml"
            cat > "$workflow_file" << 'EOF'
# Go CI Workflow
name: Go CI
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        go-version: ['1.21', '1.22', '1.23']
    steps:
      - uses: actions/checkout@v4
      - name: Set up Go
        uses: actions/setup-go@v5
        with:
          go-version: ${{ matrix.go-version }}
      - name: Download dependencies
        run: go mod download
      - name: Test
        run: go test -v ./...
      - name: Lint
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest
EOF
            ;;
    esac
    log_success "Workflow para $language creado: $workflow_file"
}
# Función para crear workflow de release
create_release_workflow() {
    local workflow_dir=".github/workflows"
    mkdir -p "$workflow_dir"
    local workflow_file="${workflow_dir}/release.yml"
    cat > "$workflow_file" << 'EOF'
# Release Workflow
name: Release
on:
  push:
    tags:
      - 'v*'
  workflow_dispatch:
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      packages: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Generate changelog
        id: changelog
        run: |
          echo "changelog<<EOF" >> $GITHUB_OUTPUT
          git log $(git describe --tags --abbrev=0 HEAD^)..HEAD --pretty=format:"- %s" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: ${{ github.ref_name }}
          name: Release ${{ github.ref_name }}
          body: ${{ steps.changelog.outputs.changelog }}
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
EOF
    log_success "Workflow de release creado: $workflow_file"
}
# Función para crear workflow de seguridad
create_security_workflow() {
    local workflow_dir=".github/workflows"
    mkdir -p "$workflow_dir"
    local workflow_file="${workflow_dir}/security.yml"
    cat > "$workflow_file" << 'EOF'
# Security Scan Workflow
name: Security Scan
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]
  schedule:
    - cron: '0 0 * * 0'  # Weekly
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'
      - name: Run CodeQL Analysis
        uses: github/codeql-action/analyze@v3
EOF
    log_success "Workflow de seguridad creado: $workflow_file"
}
# Función principal para configurar Actions
repo_actions() {
    echo ""
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "⚙️  CONFIGURAR GITHUB ACTIONS (CI/CD)"
    echo "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    # Verificar dependencias
    if [ -z "${GITHUB_TOKEN:-}" ]; then
        log_error "Se requiere token de GitHub para configurar Actions"
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
    check_actions_status "$repo_path"
    # Detectar lenguajes
    local languages
    languages=$(detect_languages)
    echo ""
    echo "📁 Lenguajes detectados: $languages"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 TIPOS DE WORKFLOWS DISPONIBLES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   1) CI básico (testing simple)"
    echo "   2) CI específico por lenguaje"
    echo "   3) Release automático (tags)"
    echo "   4) Seguridad (CodeQL, Trivy)"
    echo "   5) Todos los anteriores"
    echo "   6) Cancelar"
    echo ""
    read -p "$MSG_SELECT_OPTION " workflow_choice
    case $workflow_choice in
        1)
            create_ci_workflow
            ;;
        2)
            echo ""
            echo "Lenguajes disponibles:"
            local lang_array=($languages)
            for i in "${!lang_array[@]}"; do
                echo "   $((i+1))) ${lang_array[$i]}"
            done
            echo ""
            read -p "Selecciona lenguaje [1-${#lang_array[@]}]: " lang_choice
            if [[ "$lang_choice" =~ ^[0-9]+$ ]] && [ "$lang_choice" -ge 1 ] && [ "$lang_choice" -le "${#lang_array[@]}" ]; then
                create_language_workflow "${lang_array[$((lang_choice-1))]}"
            else
                log_error "Opción inválida"
                return 1
            fi
            ;;
        3)
            create_release_workflow
            ;;
        4)
            create_security_workflow
            ;;
        5)
            create_ci_workflow
            for lang in $languages; do
                [ "$lang" != "basic" ] && create_language_workflow "$lang"
            done
            create_release_workflow
            create_security_workflow
            log_success "Todos los workflows creados"
            ;;
        6)
            log_info "Operación cancelada"
            return 0
            ;;
        *)
            log_error "$MSG_INVALID_OPTION"
            return 1
            ;;
    esac
    # Commit sugerido
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 PRÓXIMOS PASOS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   1. Revisa los workflows creados en .github/workflows/"
    echo "   2. Personaliza según las necesidades de tu proyecto"
    echo "   3. Haz commit y push:"
    echo ""
    echo "      git add .github/workflows/"
    echo "      git commit -m \"chore: add GitHub Actions workflows\""
    echo "      git push"
    echo ""
    echo "   4. Verifica la ejecución en: https://github.com/${repo_path}/actions"
    # Preguntar si desea commitear automáticamente
    echo ""
    read -p "¿Deseas hacer commit y push automáticamente? (s/n): " auto_commit
    if [[ "$auto_commit" =~ ^[Ss]$ ]]; then
        git add .github/workflows/
        git commit -m "chore: add GitHub Actions workflows" 2>/dev/null || log_info "No hay cambios para commitear"
        git push 2>/dev/null && log_success "Cambios subidos a GitHub" || log_warning "No se pudo hacer push automáticamente"
    fi
}
# Exportar función
export -f repo_actions
