#!/bin/bash

# Script para ejecutar tests en Docker

echo "🧪 Ejecutando pruebas en contenedor Docker..."

# Ejecutar tests dentro del contenedor
docker-compose exec login-app npm test

echo "✅ Pruebas completadas"
