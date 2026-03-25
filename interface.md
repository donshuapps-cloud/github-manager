# GitHub Repository Manager - Documentación del Módulo
## Descripción
Sistema modular bash para gestión de repositorios GitHub con interfaz interactiva.
## Autor
- **Nombre:** Donshu
- **Email:** donshu.apps@gmail.com
- **GitHub:** https://github.com/donshuapps-cloud
## Estructura del Módulo
```
github-manager/
├── github-manager.sh          # Script principal
├── core/                      # Núcleo funcional
│   ├── config.sh              # Configuración central
│   ├── i18n.sh                # Internacionalización
│   └── auth.sh                # Autenticación (SSH prioritario)
├── modules/                   # Módulos funcionales
│   ├── repo-create.sh         # 1) Crear repositorio
│   └── repo-init.sh           # 2) Inicializar en proyecto existente
├── locales/                   # Archivos de idioma
│   ├── es.sh                  # Español
│   └── en.sh                  # English
└── utils/                     # Utilidades
    ├── logger.sh              # Sistema de logs
    └── prompts.sh             # Prompts interactivos
```
## Dependencias
- `git` (>= 2.0)
- `curl` (para API calls)
- `jq` (opcional, para parsing JSON)
- Clave SSH configurada en GitHub (recomendado) o Personal Access Token
## Uso
### Instalación
```bash
# Clonar o descargar el módulo
git clone https://github.com/donshuapps-cloud/github-manager.git
# Dar permisos de ejecución
chmod +x github-manager/github-manager.sh
# Ejecutar desde cualquier proyecto
./github-manager/github-manager.sh
```
### Inyectar en otro proyecto
```bash
# Copiar el directorio al proyecto
cp -r github-manager /ruta/del/proyecto/
# Agregar al .gitignore del proyecto
echo "github-manager/" >> .gitignore
# Ejecutar
cd /ruta/del/proyecto
./github-manager/github-manager.sh
```
## Configuración
### Variables de entorno
| Variable | Descripción |
|----------|-------------|
| `GITHUB_TOKEN` | Personal Access Token (fallback si no hay SSH) |
| `GITHUB_USER` | Nombre de usuario de GitHub |
| `LANG` | Idioma: `es` o `en` |
| `DEBUG` | Activar modo debug: `1` |
### Autenticación SSH (recomendado)
```bash
# Generar clave SSH
ssh-keygen -t ed25519 -C "tu@email.com"
# Agregar a GitHub
cat ~/.ssh/id_ed25519.pub
# Copiar y pegar en: https://github.com/settings/ssh/new
# Verificar conexión
ssh -T git@github.com
```
## Flujo de Trabajo
```
        ┌─────────────┐
        │   INICIO    │
        └──────┬──────┘
               ▼
        ┌─────────────┐
        │ Verificar   │
        │ Dependencias│
        └──────┬──────┘
               ▼
        ┌─────────────┐
        │ Configurar  │
        │ Autenticación│◄─── SSH Priority
        └──────┬──────┘
               ▼
        ┌─────────────┐
        │ Mostrar     │
        │ Menú Principal│
        └──────┬──────┘
               ▼
    ┌──────────┼──────────┐
    │                     │
    ▼                     ▼
┌─────────┐         ┌──────────┐
│Módulo   │         │ Módulo   │
│Operación│         │ Salida   │
└────┬────┘         └──────────┘
     │
     ▼
┌─────────────┐
│  Volver al  │
│    Menú     │
└─────────────┘
```
## Próximos Módulos (Iteración 2+)
- Módulo 3: Subir cambios con auto-descripción
- Módulo 4: Clonar repositorio existente
- Módulo 5: Ver estado del repositorio
- Módulo 6: Gestionar ramas
- Módulo 7: Gestionar tags/releases
- Módulo 8: Configurar GitHub Pages
- Módulo 9: Configurar GitHub Actions
- Módulo 10: Eliminar repositorio local
- Módulo 11: Ver historial de commits
- Módulo 12: Configurar .gitignore personalizado
- Módulo 13: Generar documentación automática
## Licencia
MIT
## Soporte
Para soporte o consultas: donshu.apps@gmail.com
