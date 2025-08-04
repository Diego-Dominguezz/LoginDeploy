#!/bin/bash
set -e

# Función para manejar la salida limpia
cleanup() {
    echo "Cerrando servicios..."
    pkill mongod || true
    pkill node || true
    exit 0
}

# Manejar señales de terminación
trap cleanup SIGTERM SIGINT

# Limpiar procesos anteriores que puedan estar corriendo
echo "Limpiando procesos anteriores..."
pkill -9 -f mongod || true
pkill -9 -f node || true
pkill -9 -f app.js || true
pkill -9 -f "node.*app" || true
killall -9 mongod || true
killall -9 node || true
sleep 5

# Verificar que el puerto 3000 esté libre más exhaustivamente
echo "Verificando puerto 3000..."
for i in {1..3}; do
    if netstat -tlnp | grep :3000 > /dev/null 2>&1; then
        echo "Intento $i: Puerto 3000 ocupado, forzando liberación..."
        fuser -k 3000/tcp || true
        # Intentar con lsof si está disponible
        lsof -ti:3000 | xargs -r kill -9 || true
        sleep 3
    else
        echo "Puerto 3000 libre en intento $i ✓"
        break
    fi
    
    if [ $i -eq 3 ] && netstat -tlnp | grep :3000 > /dev/null 2>&1; then
        echo "Error: No se pudo liberar el puerto 3000 después de múltiples intentos"
        echo "Procesos usando el puerto:"
        netstat -tlnp | grep :3000
        echo "Todos los procesos:"
        ps -A
        exit 1
    fi
done

# Crear directorio de logs si no existe
mkdir -p /var/log

# Iniciar MongoDB en segundo plano
echo "Iniciando MongoDB..."
mongod --dbpath /data/db --logpath /var/log/mongodb.log --fork --bind_ip_all

# Esperar a que MongoDB esté listo
echo "Esperando a que MongoDB esté listo..."
timeout=60
counter=0
until mongosh --eval "print('MongoDB is ready')" > /dev/null 2>&1; do
    if [ $counter -eq $timeout ]; then
        echo "Error: MongoDB no pudo iniciarse en $timeout segundos"
        exit 1
    fi
    sleep 2
    counter=$((counter + 2))
done

echo "MongoDB está listo y funcionando"

# Inicializar la base de datos si es necesario
echo "Configurando base de datos..."
mongosh logindb --eval "
try {
    db.user.createIndex({ username: 1 }, { unique: true });
    print('Índice único creado en la colección user');
} catch(e) {
    if (e.code === 85) {
        print('El índice ya existe');
    } else {
        print('Error creando índice:', e.message);
    }
}
" || echo "Error en la configuración de la base de datos (continuando...)"

# Verificar nuevamente que el puerto esté libre antes de iniciar Node.js
echo "Verificación final del puerto 3000..."
for i in {1..5}; do
    if netstat -tlnp | grep :3000 > /dev/null 2>&1; then
        echo "Verificación final intento $i: Puerto 3000 todavía ocupado"
        echo "Procesos usando el puerto:"
        netstat -tlnp | grep :3000
        echo "Intentando limpiar..."
        fuser -k 3000/tcp || true
        lsof -ti:3000 | xargs -r kill -9 || true
        sleep 2
    else
        echo "Puerto 3000 libre en verificación final ✓"
        break
    fi
    
    if [ $i -eq 5 ]; then
        echo "Error: Puerto 3000 todavía ocupado después de múltiples verificaciones"
        echo "Procesos usando el puerto:"
        netstat -tlnp | grep :3000
        echo "Todos los procesos:"
        ps -A
        exit 1
    fi
done

# Iniciar la aplicación Node.js en primer plano (no en background)
echo "Iniciando aplicación Node.js..."
echo "Directorio actual: $(pwd)"
echo "Archivos disponibles:"
ls -la

# Exportar variables de entorno para asegurar que están disponibles
export MONGODB_URI="mongodb://localhost:27017/logindb"
export MONGO_URI="mongodb://localhost:27017/logindb"
export NODE_ENV="production"
export PORT="3000"
export JWT_SECRET="your-jwt-secret-key-here"
export DB_NAME="logindb"

echo "Variables de entorno configuradas:"
echo "MONGODB_URI: $MONGODB_URI"
echo "NODE_ENV: $NODE_ENV"
echo "PORT: $PORT"

# Ejecutar Node.js en primer plano para evitar procesos duplicados
exec node app.js
