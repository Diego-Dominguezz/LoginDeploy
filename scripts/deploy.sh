#!/bin/bash

# Deployment script for Login project
# Usage: ./deploy.sh [production|testing]

set -e  # Exit on any error

DEPLOY_TYPE=${1:-production}
DEPLOY_DIR="$HOME/LoginDeploy"

echo "🚀 Starting deployment for $DEPLOY_TYPE environment..."

# Create deployment directory
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

echo "📂 Working directory: $(pwd)"

# Function to install AWS CLI
install_aws_cli() {
    echo "📦 Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt update && sudo apt install -y unzip
    unzip -o awscliv2.zip
    sudo ./aws/install --update
    rm -rf aws awscliv2.zip
    echo "✅ AWS CLI installed successfully"
}

# Function to install Docker
install_docker() {
    echo "📦 Installing Docker..."
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add user to docker group and restart docker
    sudo usermod -aG docker "$USER"
    sudo systemctl enable docker
    sudo systemctl restart docker
    
    echo "✅ Docker installed successfully"
}

# Check and install AWS CLI if needed
if ! command -v aws &> /dev/null; then
    install_aws_cli
else
    echo "✅ AWS CLI already installed"
fi

# Check and install Docker if needed
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "✅ Docker already installed"
fi

# Ensure user is in docker group
if ! groups "$USER" | grep -q docker; then
    echo "👤 Adding user to docker group..."
    sudo usermod -aG docker "$USER"
    echo "⚠️  User added to docker group. May need to logout/login for changes to take effect."
fi

# Create docker-compose file based on deployment type
if [ "$DEPLOY_TYPE" = "testing" ]; then
    COMPOSE_FILE="docker-compose.testing.yml"
    IMAGE_TAG="testing"
    PORT="8080"
    SERVICE_NAME="login-app-testing"
    VOLUME_NAME="mongodb_data_testing"
    NODE_ENV="testing"
else
    COMPOSE_FILE="docker-compose.yml"
    IMAGE_TAG="latest"
    PORT="80"
    SERVICE_NAME="login-app"
    VOLUME_NAME="mongodb_data"
    NODE_ENV="production"
fi

echo "📝 Creating $COMPOSE_FILE..."
cat > "$COMPOSE_FILE" << EOF
version: "3.8"
services:
  $SERVICE_NAME:
    image: \${ECR_REGISTRY}/login-ejemplo:$IMAGE_TAG
    ports:
      - "$PORT:3000"
    volumes:
      - $VOLUME_NAME:/data/db
      - ./logs:/var/log/mongodb
    environment:
      - NODE_ENV=$NODE_ENV
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  $VOLUME_NAME:
    driver: local
EOF

echo "✅ Docker Compose file created"

# Set environment variables for this session
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION="${AWS_REGION}"

echo "🔐 Logging in to ECR..."
# Use sudo for docker commands to ensure permissions
aws ecr get-login-password --region "$AWS_REGION" | sudo docker login --username AWS --password-stdin "$ECR_REGISTRY"

echo "📥 Pulling latest image..."
sudo docker compose -f "$COMPOSE_FILE" pull

echo "🚀 Starting deployment..."
sudo docker compose -f "$COMPOSE_FILE" up -d --remove-orphans

echo "🧹 Cleaning up old images..."
sudo docker image prune -f

echo "✅ Deployment completed successfully!"
echo "🌐 Application should be available on port $PORT"

# Show running containers
echo "📊 Current running containers:"
sudo docker compose -f "$COMPOSE_FILE" ps
