#!/bin/bash

# Script para deployment manual con limpieza automática
# Uso: ./force-deploy.sh [tag]

set -e

# Configuración
DEFAULT_TAG="testing-latest"
TAG=${1:-$DEFAULT_TAG}
COMPOSE_FILE="docker-compose.testing.yml"

echo "🚀 Iniciando deployment forzado..."
echo "🏷️  Tag a usar: $TAG"

# Función para limpiar en caso de error
cleanup_on_error() {
    echo "❌ Error detectado. Limpiando..."
    sudo docker compose -f $COMPOSE_FILE down --remove-orphans || true
    exit 1
}

# Configurar trap para cleanup en caso de error
trap cleanup_on_error ERR

# 1. Detener contenedores actuales
echo "🛑 Deteniendo contenedores actuales..."
sudo docker compose -f $COMPOSE_FILE down --remove-orphans || true

# 2. Limpiar imágenes viejas
echo "🧹 Limpiando imágenes viejas..."
sudo docker image prune -f
sudo docker images | grep login-ejemplo | grep -v $TAG | awk '{print $3}' | xargs -r sudo docker rmi -f || true

# 3. Hacer login a ECR (asegúrate de tener credenciales configuradas)
echo "🔐 Haciendo login a ECR..."
if command -v aws &> /dev/null; then
    AWS_REGION=${AWS_REGION:-us-east-2}
    ECR_REGISTRY=$(aws ecr describe-registry --query 'registryId' --output text).dkr.ecr.$AWS_REGION.amazonaws.com
    aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin $ECR_REGISTRY
else
    echo "⚠️  AWS CLI no encontrado. Asegúrate de estar logueado a ECR manualmente."
fi

# 4. Forzar pull de la imagen
echo "📥 Descargando imagen: $TAG"
sudo docker pull $ECR_REGISTRY/login-ejemplo:$TAG --quiet || {
    echo "❌ Error al descargar la imagen. Verificando imágenes disponibles..."
    aws ecr describe-images --repository-name login-ejemplo --query 'imageDetails[*].imageTags' --output table || true
    exit 1
}

# 5. Actualizar docker-compose con el tag específico
echo "📝 Actualizando docker-compose.testing.yml..."
sed -i "s|image:.*login-ejemplo:.*|image: $ECR_REGISTRY/login-ejemplo:$TAG|g" $COMPOSE_FILE

# 6. Iniciar con recreación forzada
echo "🚀 Iniciando contenedores con recreación forzada..."
sudo docker compose -f $COMPOSE_FILE up -d --force-recreate --remove-orphans

# 7. Verificar que todo esté funcionando
echo "🔍 Verificando deployment..."
sleep 10

# Mostrar estado
echo "📊 Estado de los contenedores:"
sudo docker compose -f $COMPOSE_FILE ps

# Mostrar logs recientes
echo "📋 Logs recientes:"
sudo docker compose -f $COMPOSE_FILE logs --tail=20

# Test de conectividad
echo "🌐 Probando conectividad..."
if curl -s -f http://localhost:8080 > /dev/null; then
    echo "✅ ¡Deployment exitoso! La aplicación está respondiendo."
else
    echo "⚠️  La aplicación puede estar iniciándose. Verifica los logs si es necesario."
fi

echo "✅ Deployment completado!"
echo "🌍 La aplicación está disponible en http://localhost:8080"
