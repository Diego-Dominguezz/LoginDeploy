# Usamos una imagen base de Ubuntu para instalar tanto Node.js como MongoDB
FROM ubuntu:22.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Actualizar el sistema e instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    lsb-release \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Instalar MongoDB
RUN curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    && echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update \
    && apt-get install -y mongodb-org

# Crear directorios necesarios para MongoDB
RUN mkdir -p /data/db /var/log/mongodb \
    && chown -R mongodb:mongodb /data/db /var/log/mongodb


# Permitir build args para entorno
ARG NODE_ENV=production

# Directorio de trabajo para la aplicación
WORKDIR /usr/src/app

# Copiar package.json y package-lock.json
COPY package*.json ./


# Instalar dependencias de Node.js según entorno
RUN if [ "$NODE_ENV" = "production" ]; then \
    npm ci --only=production; \
    else \
    npm ci; \
    fi

# Copiar el resto del código de la aplicación
COPY . .

# Hacer ejecutable el script de inicio
RUN chmod +x start.sh

# Exponer los puertos necesarios
EXPOSE 3000 27017

# Comando por defecto para iniciar MongoDB y la aplicación
CMD ["./start.sh"]