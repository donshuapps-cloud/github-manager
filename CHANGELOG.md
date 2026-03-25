# Changelog
All notable changes to the **GitHub Repository Manager** project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
---
## [1.0.0] - 2026-03-25
### 🎉 Initial Release
**GitHub Repository Manager** - Sistema modular bash para gestión completa de repositorios GitHub.
---
### ✨ Added - Core Infrastructure
#### Estructura Base
- Script principal `github-manager.sh` con menú interactivo
- Sistema de configuración central en `core/config.sh`
- Internacionalización (i18n) con soporte Español/Inglés en `core/i18n.sh`
- Sistema de autenticación con prioridad SSH en `core/auth.sh`
- Utilidades de logging con colores en `utils/logger.sh`
- Utilidades de prompts interactivos en `utils/prompts.sh`
#### Autenticación
- Autenticación SSH como método prioritario
- Fallback automático a Personal Access Token (PAT)
- Verificación de conexión SSH con `ssh -T git@github.com`
- Validación de tokens vía API REST de GitHub
- Configuración interactiva cuando no hay autenticación válida
---
### ✨ Added - Repository Management (Módulos 1-5)
#### Módulo 1: Crear repositorio desde cero (`repo-create.sh`)
- Creación de repositorio en GitHub vía API REST
- Validación de nombre (solo letras, números, guiones, guiones bajos)
- Configuración de visibilidad (público/privado)
- Inicialización local con Git
- Creación automática de README.md y .gitignore básico
- Primer commit y push automático
#### Módulo 2: Inicializar en proyecto existente (`repo-init.sh`)
- Inicialización de Git en proyectos no versionados
- Detección de repositorios ya inicializados
- Creación de repositorio en GitHub asociado
- Configuración de remote origin
- Push del contenido existente
#### Módulo 3: Subir cambios con auto-descripción (`repo-push.sh`)
- Análisis automático de cambios (staged/unstaged/untracked)
- Detección de tipo de cambio: docs, test, script, config, code, update
- Generación de mensajes de commit contextuales en Español/Inglés
- Resumen visual de cambios antes de commitear
- Selección interactiva de archivos a incluir
- Edición manual opcional del mensaje
- Push automático a GitHub
#### Módulo 4: Clonar repositorio existente (`repo-clone.sh`)
- Soporte para múltiples formatos de URL:
  - SSH: `git@github.com:usuario/repo.git`
  - HTTPS: `https://github.com/usuario/repo.git`
  - Formato corto: `usuario/repo`
- Listado de repositorios recientes del usuario (vía API)
- Detección automática del método de autenticación
- Directorio destino configurable
- Información detallada post-clonación
#### Módulo 5: Ver estado del repositorio (`repo-status.sh`)
- Información general: branch actual, commits totales, archivos totales
- Detalles del remote: tipo (SSH/HTTPS), URL
- Último commit: hash, fecha, mensaje
- Estado de archivos: staged, modified, untracked
- Lista detallada de archivos modificados
- Sugerencias según el estado actual
- Gráfico de sincronización con origin
---
### ✨ Added - Version Control (Módulos 6-7, 11)
#### Módulo 6: Gestionar ramas (`repo-branch.sh`)
- Visualización de ramas locales con indicador de rama actual
- Visualización de ramas remotas con fetch automático
- Creación de ramas con validación de nombre
- Cambio de rama (checkout) con verificación
- Fusión de ramas (merge) con manejo de conflictos
- Eliminación de ramas local y remotamente
- Publicación automática de nuevas ramas
#### Módulo 7: Gestionar tags/releases (`repo-tags.sh`)
- Validación de versiones semánticas (semver)
- Sugerencia automática de próxima versión
- Creación de tags locales con mensaje opcional
- Publicación de tags en GitHub
- Creación de releases vía API REST de GitHub
- Visualización de releases existentes con metadatos
- Eliminación de tags local y remotamente
#### Módulo 11: Ver historial de commits (`repo-history.sh`)
- Múltiples formatos de visualización:
  - Formato completo (hash, fecha, autor, mensaje)
  - Formato one-line (hash + mensaje)
  - Con estadísticas de archivos
  - Gráfico ASCII de ramas
- Estadísticas de contribución por autor y por día
- Búsqueda de commits por patrón en mensaje
- Configuración de cantidad de commits a mostrar
---
### ✨ Added - Advanced Configuration (Módulos 8-9, 12)
#### Módulo 8: Configurar GitHub Pages (`repo-pages.sh`)
- Detección automática de tipo de proyecto:
  - React, Vue, Angular, Node.js
  - Python, MkDocs
  - Rust, Go
  - Static sites
- Verificación de estado actual de Pages
- Sugerencias de configuración según proyecto
- Habilitación vía API REST de GitHub
- Creación automática de workflow de Pages con GitHub Actions
- Generación de index.html de prueba con diseño moderno
- Configuración de branch y path personalizados
#### Módulo 9: Configurar GitHub Actions (`repo-actions.sh`)
- Detección de lenguajes en el proyecto
- Creación de workflows específicos:
  - **Node.js**: Matrix de versiones (18, 20, 22), npm ci, build, test
  - **Python**: Matrix de versiones (3.9-3.12), pytest, flake8, coverage
  - **Rust**: cargo build, test, clippy
  - **Go**: Matrix de versiones (1.21-1.23), go test, golangci-lint
  - **Release**: Generación de changelog, creación de releases en tags
  - **Security**: Trivy scanner, CodeQL analysis
- Verificación de workflows existentes
- Commit y push automático opcional
#### Módulo 12: Configurar .gitignore personalizado (`repo-gitignore.sh`)
- **14 plantillas predefinidas:**
  - Python, Node.js, Java, Go, Rust, Ruby, PHP, C/C++
  - Docker, Terraform, Kubernetes
  - OS (macOS/Windows/Linux)
  - Editor (VS Code, IntelliJ, Vim)
  - Logs, Secrets
- Detección automática de tipo de proyecto
- Generación inteligente combinando plantillas detectadas
- Fusión con archivo .gitignore existente (sin duplicados)
- Agregado de reglas personalizadas
- Listado de archivos actualmente ignorados
- Limpieza de archivos ignorados del índice Git
---
### ✨ Added - Utilities (Módulo 10)
#### Módulo 10: Eliminar repositorio localmente (`repo-remove-local.sh`)
- Información detallada pre-eliminación:
  - Nombre, tamaño, número de archivos
  - Branch actual, remote URL, último commit
- Detección de cambios sin commitear
- Detección de commits sin push
- Backup opcional antes de eliminar
- Confirmación por escritura del nombre del repositorio
- Eliminación segura (solo local, no afecta GitHub)
- Múltiples capas de confirmación
---
### ✨ Added - Documentation (Módulo 13)
#### Módulo 13: Generar documentación automática (`repo-docs.sh`)
- Detección automática de información del proyecto desde:
  - `package.json` (Node.js)
  - `pyproject.toml` (Python)
  - `setup.py` (Python)
  - `Cargo.toml` (Rust)
- Generación de badges dinámicos vía GitHub API
- Creación de README.md en Español o Inglés
- README bilingüe (Español/English)
- Estructura de directorios con `tree`
- Comandos de instalación específicos por lenguaje
- Generación de archivos adicionales:
  - `LICENSE` (MIT por defecto)
  - `CONTRIBUTING.md`
  - `CHANGELOG.md`
- Commit y push automático opcional
---
### 🌐 Internationalization
#### Español (`locales/es.sh`)
- Todos los mensajes de interfaz en español
- Textos específicos por módulo
- Mensajes de validación y advertencias
- Ayuda contextual en español
#### English (`locales/en.sh`)
- Complete English translation of all messages
- Module-specific interface texts
- Validation messages and warnings
- Contextual help in English
---
### 🔧 Technical Specifications
#### Dependencias
- `git` (>= 2.0) - Control de versiones
- `curl` - Peticiones a API REST de GitHub
- `jq` (opcional) - Procesamiento JSON avanzado
#### Compatibilidad
- **Sistemas operativos:** Linux, macOS, WSL (Windows)
- **Shell:** Bash >= 4.0
- **GitHub:** API v3, SSH authentication
#### Estructura Modular
```
github-manager/
├── github-manager.sh          # Punto de entrada
├── core/                      # Núcleo funcional
├── modules/                   # 13 módulos independientes
├── locales/                   # Archivos de idioma
├── utils/                     # Utilidades compartidas
├── templates/                 # Plantillas de archivos
└── config/                    # Configuración persistente
```
---
### 📊 Statistics
| Métrica | Valor |
|---------|-------|
| **Módulos totales** | 13 |
| **Líneas de código** | ~3,500 |
| **Archivos** | 21 |
| **Idiomas soportados** | 2 (Español, English) |
| **Plantillas .gitignore** | 14 |
| **Workflows GitHub Actions** | 6 tipos |
| **Formatos de historial** | 5 modos |
---
### 🐛 Known Issues
| Issue | Estado | Workaround |
|-------|--------|------------|
| API GitHub requiere token para módulos 1,2,8,9 | Documentado | Configurar GITHUB_TOKEN |
| jq no instalado limita parsing JSON | Warning | Instalar jq para mejor experiencia |
| SSH no funciona para API REST | Documentado | Usar token para operaciones API |
---
### 🔜 Roadmap (Futuras Mejoras)
- [ ] Soporte para GitLab y otros proveedores
- [ ] Interfaz TUI con `dialog` o `whiptail`
- [ ] Integración con GitHub CLI (`gh`)
- [ ] Backup automático de repositorios
- [ ] Gestión de issues y pull requests
- [ ] Webhooks configurables
- [ ] Exportar configuración a archivo YAML
- [ ] Modo no-interactivo para CI/CD
---
### 👥 Contributors
- **Donshu** - Autor principal
  - GitHub: [donshuapps-cloud](https://github.com/donshuapps-cloud)
  - Email: donshu.apps@gmail.com
---
### 📄 License
MIT License - Copyright (c) 2026 Donshu
---
_This changelog follows [Keep a Changelog](https://keepachangelog.com/) format._
