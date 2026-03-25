# GitHub Repository Manager
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Language](https://img.shields.io/badge/language-Bash-orange.svg)
**GitHub Repository Manager** es un sistema modular bash para la gestión completa de repositorios GitHub, con interfaz interactiva y soporte multi-idioma.
## 📋 Descripción
Sistema interactivo que permite gestionar repositorios GitHub de forma sencilla y eficiente, priorizando autenticación SSH y ofreciendo funcionalidades avanzadas como configuración automática de GitHub Pages, GitHub Actions, gestión de ramas, tags y más.
## 🚀 Tecnologías Utilizadas
• Bash (>= 4.0)
• Git (>= 2.0)
• Curl
• jq (opcional)
## 📁 Estructura del Proyecto
```
github-manager/
├── github-manager.sh          # Script principal
├── core/                      # Núcleo funcional
│   ├── config.sh              # Configuración central
│   ├── i18n.sh                # Internacionalización
│   └── auth.sh                # Autenticación SSH prioritario
├── modules/                   # 13 módulos funcionales
│   ├── repo-create.sh         # 1) Crear repositorio
│   ├── repo-init.sh           # 2) Inicializar proyecto existente
│   ├── repo-push.sh           # 3) Subir cambios (auto-descripción)
│   ├── repo-clone.sh          # 4) Clonar repositorio
│   ├── repo-status.sh         # 5) Ver estado
│   ├── repo-branch.sh         # 6) Gestionar ramas
│   ├── repo-tags.sh           # 7) Gestionar tags/releases
│   ├── repo-pages.sh          # 8) Configurar GitHub Pages
│   ├── repo-actions.sh        # 9) Configurar GitHub Actions
│   ├── repo-remove-local.sh   # 10) Eliminar repositorio local
│   ├── repo-history.sh        # 11) Ver historial de commits
│   ├── repo-gitignore.sh      # 12) Configurar .gitignore
│   └── repo-docs.sh           # 13) Generar documentación
├── locales/                   # Archivos de idioma
│   ├── es.sh                  # Español
│   └── en.sh                  # English
└── utils/                     # Utilidades
    ├── logger.sh              # Sistema de logs
    └── prompts.sh             # Prompts interactivos
```
## 📦 Instalación
```bash
# Clonar el repositorio
git clone https://github.com/donshuapps-cloud/github-manager.git
cd github-manager
# Dar permisos de ejecución
chmod +x github-manager.sh
```
## 🔧 Uso
```bash
# Ejecutar desde cualquier proyecto
./github-manager.sh
# O inyectar en otro proyecto
cp -r github-manager /ruta/del/proyecto/
cd /ruta/del/proyecto
./github-manager/github-manager.sh
```
## 🔧 Configuración
### Variables de Entorno
| Variable | Descripción | Por Defecto |
|----------|-------------|-------------|
| `GITHUB_TOKEN` | Token de acceso a GitHub | - |
| `GITHUB_USER` | Usuario de GitHub | - |
| `LANG` | Idioma (es/en) | es |
| `DEBUG` | Modo debug (0/1) | 0 |
### Autenticación
El sistema soporta dos métodos de autenticación:
1. **SSH (Recomendado)**
   ```bash
   ssh-keygen -t ed25519 -C "tu@email.com"
   cat ~/.ssh/id_ed25519.pub
   # Agregar a: https://github.com/settings/ssh/new
   ```
2. **Token**
   ```bash
   export GITHUB_TOKEN="tu_token_aqui"
   ```
## 📊 Características
| Módulo | Descripción |
|--------|-------------|
| 🔧 Crear repositorio | Crear nuevo repositorio desde cero en GitHub |
| 📁 Inicializar | Inicializar repositorio en proyecto existente |
| 📤 Subir cambios | Push con auto-descripción de commits |
| 📦 Clonar | Clonar repositorios existentes |
| 📊 Estado | Ver estado detallado del repositorio |
| 🌿 Ramas | Gestionar branches (crear, cambiar, fusionar, eliminar) |
| 🏷️ Tags | Gestionar tags y releases |
| 🌐 GitHub Pages | Configurar GitHub Pages automáticamente |
| ⚙️ GitHub Actions | Configurar workflows CI/CD |
| 📜 Historial | Ver historial de commits con múltiples formatos |
| 📄 .gitignore | Configurar .gitignore personalizado e inteligente |
| 🗑️ Eliminar | Eliminar repositorio local con seguridad |
| 📚 Documentación | Generar documentación automática |
## 🤝 Contribución
1. Fork el proyecto
2. Crea tu rama de feature (`git checkout -b feature/amazing`)
3. Commit tus cambios (`git commit -m 'Add amazing feature'`)
4. Push a la rama (`git push origin feature/amazing`)
5. Abre un Pull Request
## 📄 Licencia
MIT License - Copyright (c) 2025 Donshu (donshu.apps@gmail.com)
## 👤 Autor
**Donshu**
- GitHub: [donshuapps-cloud](https://github.com/donshuapps-cloud)
- Email: donshu.apps@gmail.com
---
_Generado automáticamente con GitHub Repository Manager_
