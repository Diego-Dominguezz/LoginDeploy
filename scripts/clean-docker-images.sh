#!/bin/bash

# Script para limpiar imágenes Docker viejas en el servidor
# Uso: ./clean-docker-images.sh [keep-last-n]

set -e

KEEP_LAST=${1:-3}  # Por defecto mantener las últimas 3 imágenes

echo "🧹 Limpiando imágenes Docker viejas..."
echo "📊 Manteniendo las últimas $KEEP_LAST imágenes"

# Detener todos los contenedores de la aplicación
echo "🛑 Deteniendo contenedores de la aplicación..."
sudo docker compose -f docker-compose.testing.yml down --remove-orphans || true
sudo docker compose down --remove-orphans || true

# Mostrar imágenes actuales
echo "📋 Imágenes actuales de login-ejemplo:"
sudo docker images | grep login-ejemplo || echo "No se encontraron imágenes de login-ejemplo"

# Limpiar imágenes no utilizadas
echo "🗑️  Eliminando imágenes no utilizadas..."
sudo docker image prune -f

# Limpiar imágenes viejas de login-ejemplo (mantener las últimas N)
echo "🔍 Limpiando imágenes viejas de login-ejemplo..."
OLD_IMAGES=$(sudo docker images --format "table {{.Repository}}:{{.Tag}}\t{{.CreatedAt}}\t{{.ID}}" | \
    grep login-ejemplo | \
    sort -k2 -r | \
    tail -n +$((KEEP_LAST + 1)) | \
    awk '{print $3}')

if [ -n "$OLD_IMAGES" ]; then
    echo "🗑️  Eliminando imágenes viejas:"
    echo "$OLD_IMAGES"
    echo "$OLD_IMAGES" | xargs -r sudo docker rmi -f
    echo "✅ Imágenes viejas eliminadas"
else
    echo "ℹ️  No hay imágenes viejas para eliminar"
fi

# Limpiar contenedores parados
echo "🧽 Limpiando contenedores parados..."
sudo docker container prune -f

# Limpiar volúmenes no utilizados (opcional - comentado por seguridad)
# echo "💾 Limpiando volúmenes no utilizados..."
# sudo docker volume prune -f

# Mostrar estadísticas finales
echo "📊 Estado final:"
echo "🖼️  Imágenes de login-ejemplo restantes:"
sudo docker images | grep login-ejemplo || echo "No quedan imágenes de login-ejemplo"

echo "💾 Espacio en disco liberado:"
sudo docker system df

echo "✅ Limpieza completada!"
