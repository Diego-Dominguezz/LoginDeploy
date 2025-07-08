#!/bin/bash
set -e

# Función para manejar la salida limpia
cleanup() {
    echo "Cerrando servicios..."
    pkill mongod || true
    exit 0
}

# Manejar señales de terminación
trap cleanup SIGTERM SIGINT

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

# Función para verificar si la aplicación está funcionando
check_app() {
    curl -f http://localhost:3000 > /dev/null 2>&1
}

# Iniciar la aplicación Node.js
echo "Iniciando aplicación Node.js..."
node app.js &
APP_PID=$!

# Esperar a que la aplicación esté lista
echo "Esperando a que la aplicación esté lista..."
sleep 5

# Verificar que tanto MongoDB como la aplicación estén funcionando
if ! pgrep mongod > /dev/null; then
    echo "Error: MongoDB no está funcionando"
    exit 1
fi

if ! kill -0 $APP_PID 2>/dev/null; then
    echo "Error: La aplicación Node.js no está funcionando"
    exit 1
fi

echo "Aplicación iniciada exitosamente"
echo "- Aplicación web: http://localhost:3000"
echo "- MongoDB: localhost:27017"

# Mantener el contenedor funcionando
wait $APP_PID
