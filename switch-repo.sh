#!/usr/bin/env bash
# Script para cambiar de repositorio local fácilmente
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 CAMBIAR REPOSITORIO LOCAL"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📌 ¿Qué deseas hacer?"
echo "   1) Clonar repositorio desde GitHub"
echo "   2) Cambiar remote de repositorio actual"
echo "   3) Inicializar nuevo repositorio local"
echo "   4) Salir"
echo ""
read -p "➤ Opción: " opt
case $opt in
    1)
        echo ""
        read -p "🔗 URL del repositorio (ej: git@github.com:usuario/repo.git): " repo_url
        read -p "📁 Directorio destino (dejar vacío para usar nombre del repo): " dest_dir
        if [ -z "$dest_dir" ]; then
            # Extraer nombre del repositorio de la URL
            dest_dir=$(basename "$repo_url" .git)
        fi
        echo ""
        echo "📦 Clonando: $repo_url"
        git clone "$repo_url" "$dest_dir"
        if [ $? -eq 0 ]; then
            echo "✅ Repositorio clonado en: $dest_dir"
            cd "$dest_dir" || exit
            echo "📂 Ahora estás en: $(pwd)"
        fi
        ;;
    2)
        echo ""
        echo "Repositorio actual: $(pwd)"
        echo "Remote actual:"
        git remote -v
        echo ""
        read -p "🔗 Nueva URL del remote: " new_url
        read -p "🌿 Nombre del remote (default: origin): " remote_name
        remote_name=${remote_name:-origin}
        # Cambiar remote
        if git remote | grep -q "$remote_name"; then
            git remote set-url "$remote_name" "$new_url"
            echo "✅ Remote '$remote_name' actualizado a: $new_url"
        else
            git remote add "$remote_name" "$new_url"
            echo "✅ Remote '$remote_name' agregado: $new_url"
        fi
        echo ""
        echo "📋 Nuevo remote:"
        git remote -v
        ;;
    3)
        echo ""
        read -p "📁 Nombre del directorio: " dir_name
        if [ -z "$dir_name" ]; then
            echo "❌ Nombre de directorio requerido"
            exit 1
        fi
        mkdir -p "$dir_name"
        cd "$dir_name" || exit
        git init
        echo "# $dir_name" > README.md
        git add README.md
        git commit -m "Initial commit"
        echo ""
        echo "✅ Repositorio inicializado en: $(pwd)"
        echo ""
        read -p "🔗 Agregar remote (opcional, Enter para omitir): " remote_url
        if [ -n "$remote_url" ]; then
            git remote add origin "$remote_url"
            echo "✅ Remote agregado: $remote_url"
            echo ""
            read -p "📤 ¿Subir cambios a GitHub? (s/n): " push_now
            if [[ "$push_now" =~ ^[Ss]$ ]]; then
                git push -u origin main
            fi
        fi
        ;;
    4)
        echo "👋 Hasta luego"
        exit 0
        ;;
    *)
        echo "❌ Opción inválida"
        exit 1
        ;;
esac
echo ""
echo "✅ Operación completada"
