# Guía de Solución de Problemas - Despliegue AWS ECR + EC2

## Secretos Requeridos en GitHub

Configura estos en la configuración de tu repositorio GitHub (Settings > Secrets and variables > Actions):

### Configuración AWS

```
AWS_ACCESS_KEY_ID=tu_access_key_id
AWS_SECRET_ACCESS_KEY=tu_secret_access_key
AWS_REGION=us-east-1  # o tu región preferida
```

### Configuración EC2

```
EC2_HOST=ip-servidor-produccion
EC2_TESTING_HOST=ip-servidor-testing  # si usas servidor de testing separado
EC2_SSH_KEY=contenido_clave_ssh_privada
```

## Configuración AWS

### 1. Crear Repositorio ECR

```bash
aws ecr create-repository --repository-name login-ejemplo --region us-east-1
```

### 2. Crear Usuario IAM con Permisos ECR

Crea un usuario IAM con estas políticas:

- `AmazonEC2ContainerRegistryFullAccess`
- O política personalizada:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ecr:GetAuthorizationToken",
				"ecr:BatchCheckLayerAvailability",
				"ecr:GetDownloadUrlForLayer",
				"ecr:BatchGetImage",
				"ecr:InitiateLayerUpload",
				"ecr:UploadLayerPart",
				"ecr:CompleteLayerUpload",
				"ecr:PutImage"
			],
			"Resource": "*"
		}
	]
}
```

## Configuración EC2

### 1. Lanzar Instancia Ubuntu 20.04+

- Grupo de Seguridad: Permitir SSH (22), HTTP (80), y puerto personalizado 8080 para testing
- Par de claves: Usa la misma clave para instancias de producción y testing

### 2. Configuración Inicial del Servidor (ejecutar una vez en cada instancia EC2)

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Crear usuario si es necesario (opcional, los workflows usan usuario ubuntu)
# Los workflows instalarán automáticamente Docker y AWS CLI

# Asegurar que el usuario ubuntu tenga privilegios sudo
sudo usermod -aG sudo ubuntu

# Crear directorio de despliegue
mkdir -p ~/LoginDeploy
mkdir -p ~/LoginDeploy-Testing  # para servidor de testing
```

## Problemas Comunes y Soluciones

### 1. "No se encontraron credenciales AWS"

**Solución**: Asegúrate de que los secretos AWS estén configurados correctamente en GitHub:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`

### 2. "Permiso denegado en Docker"

**Solución**: El workflow ahora maneja esto automáticamente:

- Agregando usuario al grupo docker
- Usando sudo para comandos docker
- Reiniciando el servicio docker

### 3. "Falló el login a ECR"

**Solución**: Verifica que:

- El repositorio ECR existe: `login-ejemplo`
- El usuario IAM tiene permisos ECR
- La región AWS es correcta

### 4. "Falló la conexión SSH"

**Solución**: Verifica:

- La instancia EC2 está ejecutándose
- El grupo de seguridad permite SSH en puerto 22
- La clave SSH es correcta y está en formato OpenSSH

### 5. "Puerto ya en uso"

**Solución**: Detener contenedores existentes:

```bash
# En servidor de producción
cd ~/LoginDeploy
sudo docker compose down

# En servidor de testing
cd ~/LoginDeploy-Testing
sudo docker compose -f docker-compose.testing.yml down
```

## Probar el Despliegue

### 1. Verificar si los servicios están ejecutándose

```bash
# Producción (puerto 80)
curl http://ip-produccion

# Testing (puerto 8080)
curl http://ip-testing:8080
```

### 2. Ver logs de contenedores

```bash
# Producción
cd ~/LoginDeploy
sudo docker compose logs -f

# Testing
cd ~/LoginDeploy-Testing
sudo docker compose -f docker-compose.testing.yml logs -f
```

### 3. Verificar estado de contenedores

```bash
# Producción
sudo docker compose ps

# Testing
sudo docker compose -f docker-compose.testing.yml ps
```

## Disparadores de Workflow

- **Despliegue Producción**: Push a rama `main`
- **Despliegue Testing**: Push a rama `develop` o `testing`

## Despliegue Manual (Emergencia)

Si los workflows fallan, puedes desplegar manualmente:

```bash
# SSH a tu servidor
ssh -i tu-clave.pem ubuntu@ip-servidor

# Navegar al directorio de despliegue
cd ~/LoginDeploy

# Login a ECR manualmente
aws ecr get-login-password --region us-east-1 | sudo docker login --username AWS --password-stdin tu-account-id.dkr.ecr.us-east-1.amazonaws.com

# Descargar e iniciar servicios
sudo docker compose pull
sudo docker compose up -d --remove-orphans
```

## Monitoreo

### Verificar GitHub Actions

1. Ve a tu repo > pestaña Actions
2. Haz clic en el workflow fallido para ver logs
3. Busca mensajes de error específicos

### Verificar AWS ECR

```bash
# Listar imágenes en repositorio
aws ecr describe-images --repository-name login-ejemplo --region us-east-1
```

### Verificar Recursos EC2

```bash
# Verificar espacio en disco
df -h

# Verificar memoria
free -h

# Verificar procesos ejecutándose
ps aux | grep docker
```

## Comandos Útiles de Troubleshooting

### En el Servidor EC2

```bash
# Verificar estado de Docker
sudo systemctl status docker

# Reiniciar Docker si es necesario
sudo systemctl restart docker

# Verificar si el usuario está en grupo docker
groups ubuntu

# Ver contenedores ejecutándose
sudo docker ps

# Ver todas las imágenes
sudo docker images

# Limpiar imágenes no utilizadas
sudo docker system prune -f

# Ver logs del sistema
sudo journalctl -u docker.service
```

### Verificar Conectividad

```bash
# Desde tu máquina local, probar SSH
ssh -i tu-clave.pem ubuntu@ip-servidor "echo 'Conexión exitosa'"

# Probar conectividad a ECR
aws ecr describe-repositories --region us-east-1

# Verificar que la aplicación responde
curl -I http://ip-servidor  # Producción
curl -I http://ip-servidor:8080  # Testing
```

## Estructura de Archivos Esperada

Después de un despliegue exitoso, deberías ver:

```
~/LoginDeploy/
├── docker-compose.yml
├── logs/
└── (archivos generados por Docker)

~/LoginDeploy-Testing/  # Solo en servidor de testing
├── docker-compose.testing.yml
├── logs/
└── (archivos generados por Docker)
```

## Contacto y Soporte

Si continúas teniendo problemas:

1. **Revisa los logs** de GitHub Actions primero
2. **Verifica la conectividad** SSH y AWS
3. **Comprueba los recursos** de EC2 (CPU, memoria, disco)
4. **Valida la configuración** de secretos en GitHub

El sistema está diseñado para ser auto-reparable, pero estos pasos te ayudarán a diagnosticar problemas específicos.
