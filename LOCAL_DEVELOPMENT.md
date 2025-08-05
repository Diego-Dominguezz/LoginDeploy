# Local Development Guide

This guide explains how to run the Login project locally using Docker without needing ECR access.

## Quick Start

### Option 1: Using NPM Scripts (Recommended)

```bash
npm run dockerize          # Build and start local containers
npm run dockerize:logs     # View container logs
npm run dockerize:stop     # Stop containers
npm run dockerize:clean    # Stop containers and clean up
```

### Option 2: Using Helper Scripts

```bash
# Windows Command Prompt
start-local.bat

# PowerShell
.\start-local.ps1
```

### Option 3: Direct Docker Compose

```bash
docker-compose -f docker-compose.local.yml up -d --build
```

## What's Included

The local setup includes:

- **Application Container**: Your Node.js login application
- **MongoDB Database**: Embedded within the same container
- **Volume Persistence**: Data persists between container restarts
- **Health Checks**: Automatic health monitoring
- **Log Management**: Centralized logging to `./logs` directory

## Configuration

### Environment Variables

The local setup uses `.env.local` for configuration:

```env
NODE_ENV=development
HOST_PORT=3000
JWT_SECRET=your-local-jwt-secret-key-here
DB_NAME=login-database
MONGO_URI=mongodb://localhost:27017/login-database
MONGODB_URI=mongodb://localhost:27017/login-database
PORT=3000
```

### Customizing the Setup

You can customize the local deployment by:

1. **Changing the port**: Modify `HOST_PORT` in `.env.local`
2. **Environment mode**: Change `NODE_ENV` (development/production)
3. **Database name**: Update `DB_NAME` and URI variables

## Container Architecture

The local Docker setup:

- Builds the image locally (no ECR dependency)
- Uses a single container with both Node.js and MongoDB
- Maps port 3000 from container to your specified host port
- Persists MongoDB data in a Docker volume
- Includes health checks for reliability

## Troubleshooting

### Common Issues

1. **Port already in use**:

   ```bash
   # Change HOST_PORT in .env.local to use a different port
   HOST_PORT=3001
   ```

2. **Docker not running**:

   - Start Docker Desktop
   - Verify with: `docker info`

3. **Build failures**:

   ```bash
   # Clean build
   npm run dockerize:clean
   npm run dockerize
   ```

4. **Database connection issues**:
   ```bash
   # Check container logs
   npm run dockerize:logs
   ```

### Useful Commands

```bash
# View running containers
docker ps

# Access container shell
docker exec -it <container-name> bash

# View container logs
docker logs <container-name>

# Check MongoDB status inside container
docker exec -it <container-name> mongosh --eval "db.runCommand('ping')"
```

## Development Workflow

1. **Start the local environment**:

   ```bash
   npm run dockerize
   ```

2. **Make code changes**: Edit your source files

3. **Rebuild with changes**:

   ```bash
   npm run dockerize:stop
   npm run dockerize
   ```

4. **View logs for debugging**:

   ```bash
   npm run dockerize:logs
   ```

5. **Clean up when done**:
   ```bash
   npm run dockerize:clean
   ```

## Performance Tips

- Use `npm run dockerize:logs` to monitor performance
- The application includes health checks for reliability
- MongoDB data persists in Docker volumes for faster restarts
- Logs are stored in `./logs` directory for analysis

## Comparison with Production

| Feature      | Local                       | Production       |
| ------------ | --------------------------- | ---------------- |
| Image Source | Built locally               | ECR Registry     |
| Database     | Embedded MongoDB            | External MongoDB |
| Port         | Configurable (default 3000) | 80 or 8080       |
| Environment  | Development                 | Production       |
| Persistence  | Docker volumes              | External volumes |

This local setup gives you a complete development environment that mirrors production behavior without requiring AWS credentials or ECR access.
