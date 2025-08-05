# Smart deployment script with ECR fallback
# Usage: .\smart-deploy.ps1 [production|testing]

param(
    [string]$DeployType = "production"
)

$ErrorActionPreference = "Stop"

$PRIVATE_ECR_REGISTRY = "488343657053.dkr.ecr.us-east-2.amazonaws.com"
$PUBLIC_ECR_REGISTRY = "public.ecr.aws/diego-public"
$AWS_REGION = "us-east-2"

Write-Host "🚀 Starting smart deployment for $DeployType environment..." -ForegroundColor Green

# Set image tag based on deployment type
if ($DeployType -eq "testing") {
    $IMAGE_TAG = "testing"
    $HOST_PORT = "8080"
    $NODE_ENV = "testing"
} else {
    $IMAGE_TAG = "latest"
    $HOST_PORT = "80"
    $NODE_ENV = "production"
}

# Function to test ECR access
function Test-EcrAccess {
    param([string]$Registry)
    
    Write-Host "🔍 Testing access to $Registry..." -ForegroundColor Yellow
    
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        try {
            $loginToken = aws ecr get-login-password --region $AWS_REGION 2>$null
            if ($loginToken) {
                $loginToken | docker login --username AWS --password-stdin $Registry 2>$null | Out-Null
                Write-Host "✅ Successfully authenticated with private ECR" -ForegroundColor Green
                return $true
            }
        }
        catch {
            # Continue to fallback
        }
    }
    
    Write-Host "⚠️ Cannot authenticate with private ECR" -ForegroundColor Yellow
    return $false
}

# Function to pull image with fallback
function Get-ImageWithFallback {
    $imageName = "login-ejemplo:$IMAGE_TAG"
    
    # Try private ECR first
    if (Test-EcrAccess $PRIVATE_ECR_REGISTRY) {
        Write-Host "📥 Attempting to pull from private ECR..." -ForegroundColor Yellow
        try {
            docker pull "$PRIVATE_ECR_REGISTRY/$imageName" 2>$null | Out-Null
            $script:ECR_REGISTRY = $PRIVATE_ECR_REGISTRY
            Write-Host "✅ Successfully pulled from private ECR" -ForegroundColor Green
            return $true
        }
        catch {
            # Continue to fallback
        }
    }
    
    # Fallback to public ECR
    Write-Host "🔄 Falling back to public ECR..." -ForegroundColor Yellow
    try {
        docker pull "$PUBLIC_ECR_REGISTRY/$imageName" 2>$null | Out-Null
        $script:ECR_REGISTRY = $PUBLIC_ECR_REGISTRY
        Write-Host "✅ Successfully pulled from public ECR" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to pull from both private and public ECR" -ForegroundColor Red
        return $false
    }
}

# Function to create compose file
function New-ComposeFile {
    $composeFile = "docker-compose.smart.yml"
    
    Write-Host "📝 Creating $composeFile..." -ForegroundColor Yellow
    
    $composeContent = @"
version: "3.8"

services:
  login-app:
    image: `${ECR_REGISTRY}/login-ejemplo:$IMAGE_TAG
    ports:
      - "$HOST_PORT:3000"
    volumes:
      - ./logs:/var/log/app
    environment:
      - NODE_ENV=$NODE_ENV
      - MONGO_URI=mongodb://mongodb:27017/login-database
      - MONGODB_URI=mongodb://mongodb:27017/login-database
    restart: unless-stopped
    init: true
    depends_on:
      - mongodb
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 60s
      timeout: 15s
      retries: 5
      start_period: 90s

  mongodb:
    image: mongo:latest
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
      - ./logs:/var/log/mongodb
    environment:
      - MONGO_INITDB_DATABASE=login-database
    restart: unless-stopped

volumes:
  mongodb_data:
    driver: local
"@
    
    $composeContent | Out-File -FilePath $composeFile -Encoding UTF8
    Write-Host "✅ Docker Compose file created" -ForegroundColor Green
    return $composeFile
}

# Main deployment logic
function Main {
    # Create logs directory
    if (-not (Test-Path "logs")) {
        New-Item -ItemType Directory -Path "logs" | Out-Null
    }
    
    # Pull image with fallback logic
    if (-not (Get-ImageWithFallback)) {
        Write-Host "❌ Deployment failed - could not pull image" -ForegroundColor Red
        exit 1
    }
    
    # Create and use compose file
    $COMPOSE_FILE = New-ComposeFile
    
    # Set environment variables
    $env:ECR_REGISTRY = $script:ECR_REGISTRY
    $env:IMAGE_TAG = $IMAGE_TAG
    $env:HOST_PORT = $HOST_PORT
    $env:NODE_ENV = $NODE_ENV
    
    Write-Host "🚀 Starting deployment with $script:ECR_REGISTRY..." -ForegroundColor Green
    docker compose -f $COMPOSE_FILE up -d --remove-orphans
    
    Write-Host "🧹 Cleaning up old images..." -ForegroundColor Yellow
    docker image prune -f
    
    Write-Host "✅ Smart deployment completed successfully!" -ForegroundColor Green
    Write-Host "🌐 Application should be available on port $HOST_PORT" -ForegroundColor Cyan
    Write-Host "📊 Using registry: $script:ECR_REGISTRY" -ForegroundColor Cyan
    
    # Show running containers
    Write-Host "📊 Current running containers:" -ForegroundColor Yellow
    docker compose -f $COMPOSE_FILE ps
}

Main
