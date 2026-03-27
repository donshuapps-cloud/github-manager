# github-manager
![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
## 📋 Descripción
Proyecto desarrollado con GitHub Repository Manager
## 🚀 Tecnologías Utilizadas
• Documentation
## 📁 Estructura del Proyecto
```
.
|-- core
|   |-- auth.sh
|   |-- config.sh
|   `-- i18n.sh
|-- locales
|   |-- en.sh
|   `-- es.sh
|-- modules
|   |-- repo-actions.sh
|   |-- repo-branch.sh
|   |-- repo-clone.sh
|   |-- repo-create.sh
|   |-- repo-docs.sh
|   |-- repo-gitignore.sh
|   |-- repo-history.sh
|   |-- repo-init.sh
|   |-- repo-pages.sh
|   |-- repo-push.sh
|   |-- repo-remove-local.sh
|   |-- repo-status.sh
|   `-- repo-tags.sh
|-- utils
|   |-- logger.sh
|   `-- prompts.sh
|-- CHANGELOG.md
|-- LICENSE
|-- README.md
|-- README.pdf
|-- github-manager.sh
|-- interface.md
`-- interface.pdf

5 directories, 27 files
```
## 📦 Instalación
```bash
git clone https://github.com/usuario/github-manager.git
cd github-manager
```
## 🔧 Configuración
### Variables de Entorno
| Variable | Descripción | Por Defecto |
|----------|-------------|-------------|
| `GITHUB_TOKEN` | Token de acceso a GitHub | - |
| `GITHUB_USER` | Usuario de GitHub | - |
| `LANG` | Idioma (es/en) | es |
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
Este proyecto está bajo la licencia MIT. Consulta el archivo `LICENSE` para más detalles.
## 👤 Autor
**Donshu**
- GitHub: [donshuapps-cloud](https://github.com/donshuapps-cloud)
- Email: donshu.apps@gmail.com
---
_Generado automáticamente con [GitHub Repository Manager](https://github.com/donshuapps-cloud/github-manager)_
