# 🐳 Guía para Evitar Problemas de Imágenes Docker No Actualizadas

## 🚨 Problema Resuelto

El problema de `EADDRINUSE` se debía a que el servidor AWS estaba usando imágenes Docker viejas que aún contenían `server.js`. Al eliminar las imágenes viejas del servidor, el problema se solucionó.

## 🛡️ Estrategias para Prevenir este Problema en el Futuro

### 1. **Tags Únicos por Deploy** ✅ IMPLEMENTADO

- **Antes**: `login-ejemplo:testing` (siempre el mismo tag)
- **Ahora**: `login-ejemplo:testing-{commit-sha}-{run-number}`
- **Beneficio**: Cada deploy tiene un tag único, forzando descarga de imagen nueva

### 2. **Limpieza Automática en el Workflow** ✅ IMPLEMENTADO

El workflow ahora incluye:

```bash
# Detener contenedores existentes
sudo docker compose down --remove-orphans

# Limpiar imágenes viejas
sudo docker image prune -f
sudo docker images | grep login-ejemplo | awk '{print $3}' | xargs -r sudo docker rmi -f

# Forzar recreación de contenedores
sudo docker compose up -d --force-recreate
```

### 3. **Scripts de Limpieza Manual**

#### 📄 `scripts/clean-docker-images.sh`

Úsalo cuando necesites limpiar manualmente:

```bash
# En tu servidor EC2:
ssh -i "loginCreds.pem" ubuntu@18.191.74.193
cd ~/LoginDeploy-Testing
./clean-docker-images.sh 3  # Mantener últimas 3 imágenes
```

#### 📄 `scripts/force-deploy.sh`

Para deployments manuales con limpieza automática:

```bash
# En tu servidor EC2:
./force-deploy.sh testing-latest
```

### 4. **Comandos Docker Útiles**

#### 🔍 **Verificar Imágenes Actuales**

```bash
# Ver todas las imágenes de tu aplicación
docker images | grep login-ejemplo

# Ver contenedores corriendo
docker ps

# Ver logs de la aplicación
docker compose -f docker-compose.testing.yml logs -f
```

#### 🧹 **Limpieza Manual Rápida**

```bash
# Detener todos los contenedores
docker compose down --remove-orphans

# Limpiar todo lo no usado
docker system prune -af

# Forzar descarga nueva
docker compose pull --no-parallel
docker compose up -d --force-recreate
```

#### 🗑️ **Eliminar Imágenes Específicas**

```bash
# Listar imágenes de login-ejemplo
docker images | grep login-ejemplo

# Eliminar imagen específica por ID
docker rmi [IMAGE_ID]

# Eliminar todas las imágenes de login-ejemplo (¡cuidado!)
docker images | grep login-ejemplo | awk '{print $3}' | xargs docker rmi -f
```

### 5. **Configuración de Docker Compose Mejorada**

#### ✅ **Buenas Prácticas Implementadas**:

- `--force-recreate`: Siempre recrea contenedores
- `--remove-orphans`: Elimina contenedores huérfanos
- `--no-parallel`: Evita conflictos en el pull
- Tags únicos en lugar de `latest`

### 6. **Monitoreo y Verificación**

#### 🔍 **Verificar que se está usando la imagen correcta**:

```bash
# Ver qué imagen está usando el contenedor
docker inspect [CONTAINER_ID] | grep Image

# Ver detalles del contenedor
docker compose ps
```

#### 📊 **Verificar espacio en disco**:

```bash
# Ver uso de espacio de Docker
docker system df

# Ver imágenes por tamaño
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
```

## 🚀 **Flujo Recomendado para Deployments**

### Automático (GitHub Actions):

1. ✅ Commit/Push a `develop` o `testing`
2. ✅ GitHub Actions construye imagen con tag único
3. ✅ Sube imagen a ECR
4. ✅ Se conecta al servidor via SSH
5. ✅ Detiene contenedores viejos
6. ✅ Limpia imágenes viejas
7. ✅ Descarga imagen nueva
8. ✅ Inicia contenedores con `--force-recreate`

### Manual (emergencias):

```bash
# En tu servidor EC2
ssh -i "loginCreds.pem" ubuntu@18.191.74.193
cd ~/LoginDeploy-Testing

# Opción 1: Script automático
./force-deploy.sh

# Opción 2: Manual paso a paso
sudo docker compose down --remove-orphans
sudo docker system prune -f
sudo docker compose pull --no-parallel
sudo docker compose up -d --force-recreate
```

## 📋 **Checklist Post-Deploy**

- [ ] Verificar que el contenedor esté corriendo: `docker ps`
- [ ] Verificar logs: `docker compose logs --tail=50`
- [ ] Probar conectividad: `curl http://localhost:8080`
- [ ] Verificar que NO hay `server.js` en logs
- [ ] Verificar que dice "node app.js" en los logs

## 🆘 **Solución Rápida si Vuelve a Pasar**

```bash
# En el servidor EC2:
sudo docker compose down --remove-orphans
sudo docker system prune -af  # ¡CUIDADO! Elimina todo lo no usado
sudo docker compose pull --no-parallel
sudo docker compose up -d --force-recreate

# Verificar
docker compose logs --tail=20
curl http://localhost:8080
```

---

**💡 Tip**: Siempre que veas el error `EADDRINUSE` o referencias a `server.js` en los logs, significa que Docker está usando una imagen vieja. La solución es **siempre limpiar y forzar descarga nueva**.
