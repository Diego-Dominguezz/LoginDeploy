#!/bin/bash

# Build and push to both private and public ECR
# Usage: ./build-and-push.sh [test|testing|production]

set -e

TARGET=${1:-production}
ECR_REGISTRY="488343657053.dkr.ecr.us-east-2.amazonaws.com"
PUBLIC_ECR_REGISTRY="public.ecr.aws/diego-public"
AWS_REGION="us-east-2"

echo "🏗️ Building and pushing $TARGET target to both private and public ECR..."

# Function to check if AWS CLI is available
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI not found. Please install AWS CLI first."
        exit 1
    fi
}

# Function to login to private ECR
login_private_ecr() {
    echo "🔐 Logging in to private ECR..."
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
}

# Function to login to public ECR
login_public_ecr() {
    echo "🔐 Logging in to public ECR..."
    aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws
}

# Function to create repositories if they don't exist
create_repositories() {
    echo "📦 Ensuring repositories exist..."
    
    # Create private repository if it doesn't exist
    aws ecr describe-repositories --repository-names login-ejemplo --region "$AWS_REGION" 2>/dev/null || {
        echo "📦 Creating private ECR repository..."
        aws ecr create-repository --repository-name login-ejemplo --region "$AWS_REGION"
    }
    
    # Create public repository if it doesn't exist
    aws ecr-public describe-repositories --repository-names login-ejemplo --region us-east-1 2>/dev/null || {
        echo "📦 Creating public ECR repository..."
        aws ecr-public create-repository --repository-name login-ejemplo --region us-east-1
    }
}

# Function to build and push images
build_and_push() {
    echo "🏗️ Building images with docker bake..."
    
    # Set environment variables for docker bake
    export ECR_REGISTRY="$ECR_REGISTRY"
    export PUBLIC_ECR_REGISTRY="$PUBLIC_ECR_REGISTRY"
    
    # Build the target
    docker buildx bake "$TARGET" --push
    
    echo "✅ Successfully built and pushed $TARGET images to both registries!"
}

# Main execution
main() {
    check_aws_cli
    
    # Login to both registries
    login_private_ecr
    login_public_ecr
    
    # Create repositories
    create_repositories
    
    # Build and push
    build_and_push
    
    echo "🎉 Build and push completed successfully!"
    echo "📦 Private ECR: $ECR_REGISTRY/login-ejemplo:$([[ "$TARGET" == "production" ]] && echo "latest" || echo "$TARGET")"
    echo "🌐 Public ECR: $PUBLIC_ECR_REGISTRY/login-ejemplo:$([[ "$TARGET" == "production" ]] && echo "latest" || echo "$TARGET")"
}

main "$@"
