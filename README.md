# Proyecto Login con MongoDB Containerizado

Este proyecto es una aplicación de login con Node.js, Express y MongoDB, completamente containerizada con Docker.

## Características

- **Node.js 20** con Express
- **MongoDB 7.0** integrado en la misma imagen
- **Autenticación** con bcrypt
- **Sesiones** con express-session
- **Interfaz web** completa

## Estructura del Proyecto

```
ProyectoLogin/
├── app.js              # Aplicación principal
├── package.json        # Dependencias de Node.js
├── Dockerfile         # Configuración de Docker
├── docker-compose.yml # Orquestación de servicios
├── start.sh           # Script de inicialización
├── .env               # Variables de entorno
├── public/            # Archivos estáticos (HTML, CSS, JS)
└── models/            # Modelos de datos
```

## Instalación y Uso

### Opción 1: Usar Docker Compose (Recomendado)

```bash
# Construir y ejecutar la aplicación
docker-compose up --build

# Ejecutar en segundo plano
docker-compose up -d --build

# Ver logs
docker-compose logs -f

# Detener la aplicación
docker-compose down
```

### Opción 2: Usar Docker directamente

```bash
# Construir la imagen
docker build -t login-app .

# Ejecutar el contenedor
docker run -p 3000:3000 -p 27017:27017 --name login-container login-app

# Detener el contenedor
docker stop login-container
```

## Acceso a la Aplicación

Una vez que el contenedor esté ejecutándose:

- **Aplicación web**: http://localhost:3000
- **MongoDB**: localhost:27017 (si necesitas acceso directo)

## Funcionalidades

- **Registro de usuarios**: Página de signup con validación
- **Login de usuarios**: Autenticación segura con bcrypt
- **Sesiones**: Manejo de sesiones de usuario
- **Logout**: Cierre de sesión seguro
- **Páginas protegidas**: Acceso controlado a contenido

## Configuración

Las variables de entorno se encuentran en el archivo `.env`:

```
MONGODB_URI=mongodb://localhost:27017/logindb
SESSION_SECRET=my-super-secret-session-key-2024
```

## Datos Persistentes

Los datos de MongoDB se almacenan en un volumen Docker llamado `mongodb_data`, por lo que persisten entre reinicios del contenedor.

## Troubleshooting

### Si hay problemas con MongoDB:

```bash
# Ver logs del contenedor
docker logs login-container

# Entrar al contenedor para debugging
docker exec -it login-container bash

# Verificar estado de MongoDB
docker exec -it login-container mongosh --eval "db.adminCommand('ismaster')"
```

### Si el puerto 3000 está ocupado:

Cambiar el puerto en `docker-compose.yml`:

```yaml
ports:
  - "3001:3000" # Usar puerto 3001 en lugar de 3000
```

## Desarrollo

Para desarrollo local sin Docker:

```bash
# Instalar dependencias
npm install

# Iniciar en modo desarrollo
npm run dev

# Ejecutar tests
npm test

# Ejecutar tests con cobertura
npm run test:coverage
```

## Testing

Este proyecto incluye pruebas automatizadas con Jest y Supertest.

### Configuración de Tests

- **Jest**: Framework de testing
- **Supertest**: Para pruebas de endpoints HTTP
- **Cobertura**: Reportes de cobertura de código
- **Base de datos de pruebas**: Usa `logindb_test` para no interferir con datos reales

### Ejecutar Pruebas

```bash
# Ejecutar todas las pruebas
npm test

# Ejecutar pruebas en modo watch (recarga automática)
npm run test:watch

# Ejecutar pruebas con reporte de cobertura
npm run test:coverage

# Ejecutar pruebas con salida detallada
npm run test:verbose

# Ejecutar pruebas sin salida (para CI)
npm run test:silent

# Ejecutar pruebas en modo CI (para integración continua)
npm run test:ci
```

### Ejecutar Pruebas en Docker

```bash
# Si el contenedor está ejecutándose
docker-compose exec login-app npm test

# Usar el script de pruebas
./test-docker.sh
```

### Tipos de Pruebas

1. **Tests de Autenticación** (`tests/auth.test.js`):

   - Registro de usuarios
   - Login con credenciales correctas/incorrectas
   - Logout

2. **Tests de Modelo** (`tests/user.test.js`):

   - Creación de usuarios
   - Validación de campos
   - Restricciones de unicidad

3. **Tests de Integración** (`tests/integration.test.js`):
   - Flujo completo de registro y login
   - Manejo de sesiones
   - Servicio de archivos estáticos

### Estructura de Tests

```
tests/
├── auth.test.js       # Pruebas de autenticación
├── user.test.js       # Pruebas del modelo de usuario
└── integration.test.js # Pruebas de integración
```

### Configuración de Testing

- `jest.config.js`: Configuración principal de Jest
- `jest.setup.js`: Configuración inicial para tests
- `.env.test`: Variables de entorno para pruebas

### Reporte de Cobertura

Después de ejecutar `npm run test:coverage`, puedes ver el reporte en:

- Terminal: Reporte texto
- Browser: Abrir `coverage/lcov-report/index.html`

## Notas Importantes

1. **Seguridad**: Cambiar `SESSION_SECRET` en producción
2. **Datos**: Los datos se persisten en el volumen `mongodb_data`
3. **Puertos**: Se exponen tanto el 3000 (app) como el 27017 (MongoDB)
4. **Healthcheck**: Se incluye verificación de salud del contenedor
