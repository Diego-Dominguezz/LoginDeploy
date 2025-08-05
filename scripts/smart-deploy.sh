#!/bin/bash

# Smart deployment script with ECR fallback
# Usage: ./smart-deploy.sh [production|testing]

set -e

DEPLOY_TYPE=${1:-production}
PRIVATE_ECR_REGISTRY="488343657053.dkr.ecr.us-east-2.amazonaws.com"
PUBLIC_ECR_REGISTRY="public.ecr.aws/diego-public"
AWS_REGION="us-east-2"

echo "🚀 Starting smart deployment for $DEPLOY_TYPE environment..."

# Set image tag based on deployment type
if [ "$DEPLOY_TYPE" = "testing" ]; then
    IMAGE_TAG="testing"
    HOST_PORT="8080"
    NODE_ENV="testing"
else
    IMAGE_TAG="latest"
    HOST_PORT="80"
    NODE_ENV="production"
fi

# Function to test ECR access
test_ecr_access() {
    local registry=$1
    echo "🔍 Testing access to $registry..."
    
    if command -v aws &> /dev/null; then
        if aws ecr get-login-password --region "$AWS_REGION" >/dev/null 2>&1; then
            if aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$registry" >/dev/null 2>&1; then
                echo "✅ Successfully authenticated with private ECR"
                return 0
            fi
        fi
    fi
    
    echo "⚠️ Cannot authenticate with private ECR"
    return 1
}

# Function to pull image with fallback
pull_image_with_fallback() {
    local image_name="login-ejemplo:$IMAGE_TAG"
    
    # Try private ECR first
    if test_ecr_access "$PRIVATE_ECR_REGISTRY"; then
        echo "📥 Attempting to pull from private ECR..."
        if docker pull "$PRIVATE_ECR_REGISTRY/$image_name" 2>/dev/null; then
            export ECR_REGISTRY="$PRIVATE_ECR_REGISTRY"
            echo "✅ Successfully pulled from private ECR"
            return 0
        fi
    fi
    
    # Fallback to public ECR
    echo "🔄 Falling back to public ECR..."
    if docker pull "$PUBLIC_ECR_REGISTRY/$image_name" 2>/dev/null; then
        export ECR_REGISTRY="$PUBLIC_ECR_REGISTRY"
        echo "✅ Successfully pulled from public ECR"
        return 0
    fi
    
    echo "❌ Failed to pull from both private and public ECR"
    return 1
}

# Function to create compose file
create_compose_file() {
    local compose_file="docker-compose.smart.yml"
    
    echo "📝 Creating $compose_file..."
    cat > "$compose_file" << EOF
version: "3.8"

services:
  login-app:
    image: \${ECR_REGISTRY}/login-ejemplo:$IMAGE_TAG
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
EOF
    
    echo "✅ Docker Compose file created"
    echo "$compose_file"
}

# Main deployment logic
main() {
    # Create logs directory
    mkdir -p logs
    
    # Pull image with fallback logic
    if ! pull_image_with_fallback; then
        echo "❌ Deployment failed - could not pull image"
        exit 1
    fi
    
    # Create and use compose file
    COMPOSE_FILE=$(create_compose_file)
    
    # Set environment variables
    export IMAGE_TAG="$IMAGE_TAG"
    export HOST_PORT="$HOST_PORT"
    export NODE_ENV="$NODE_ENV"
    
    echo "🚀 Starting deployment with $ECR_REGISTRY..."
    docker compose -f "$COMPOSE_FILE" up -d --remove-orphans
    
    echo "🧹 Cleaning up old images..."
    docker image prune -f
    
    echo "✅ Smart deployment completed successfully!"
    echo "🌐 Application should be available on port $HOST_PORT"
    echo "📊 Using registry: $ECR_REGISTRY"
    
    # Show running containers
    echo "📊 Current running containers:"
    docker compose -f "$COMPOSE_FILE" ps
}

main "$@"
