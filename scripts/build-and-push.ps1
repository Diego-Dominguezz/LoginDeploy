# Build and push to both private and public ECR
# Usage: .\build-and-push.ps1 [test|testing|production]

param(
    [string]$Target = "production"
)

$ErrorActionPreference = "Stop"

$ECR_REGISTRY = "488343657053.dkr.ecr.us-east-2.amazonaws.com"
$PUBLIC_ECR_REGISTRY = "public.ecr.aws/diego-public"
$AWS_REGION = "us-east-2"

Write-Host "🏗️ Building and pushing $Target target to both private and public ECR..." -ForegroundColor Green

# Function to check if AWS CLI is available
function Test-AwsCli {
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Host "❌ AWS CLI not found. Please install AWS CLI first." -ForegroundColor Red
        exit 1
    }
}

# Function to login to private ECR
function Connect-PrivateEcr {
    Write-Host "🔐 Logging in to private ECR..." -ForegroundColor Yellow
    $loginToken = aws ecr get-login-password --region $AWS_REGION
    $loginToken | docker login --username AWS --password-stdin $ECR_REGISTRY
}

# Function to login to public ECR
function Connect-PublicEcr {
    Write-Host "🔐 Logging in to public ECR..." -ForegroundColor Yellow
    $loginToken = aws ecr-public get-login-password --region us-east-1
    $loginToken | docker login --username AWS --password-stdin public.ecr.aws
}

# Function to create repositories if they don't exist
function New-Repositories {
    Write-Host "📦 Ensuring repositories exist..." -ForegroundColor Yellow
    
    # Create private repository if it doesn't exist
    try {
        aws ecr describe-repositories --repository-names login-ejemplo --region $AWS_REGION | Out-Null
    }
    catch {
        Write-Host "📦 Creating private ECR repository..." -ForegroundColor Yellow
        aws ecr create-repository --repository-name login-ejemplo --region $AWS_REGION
    }
    
    # Create public repository if it doesn't exist
    try {
        aws ecr-public describe-repositories --repository-names login-ejemplo --region us-east-1 | Out-Null
    }
    catch {
        Write-Host "📦 Creating public ECR repository..." -ForegroundColor Yellow
        aws ecr-public create-repository --repository-name login-ejemplo --region us-east-1
    }
}

# Function to build and push images
function Build-AndPush {
    Write-Host "🏗️ Building images with docker bake..." -ForegroundColor Yellow
    
    # Set environment variables for docker bake
    $env:ECR_REGISTRY = $ECR_REGISTRY
    $env:PUBLIC_ECR_REGISTRY = $PUBLIC_ECR_REGISTRY
    
    # Build the target
    docker buildx bake $Target --push
    
    Write-Host "✅ Successfully built and pushed $Target images to both registries!" -ForegroundColor Green
}

# Main execution
function Main {
    Test-AwsCli
    
    # Login to both registries
    Connect-PrivateEcr
    Connect-PublicEcr
    
    # Create repositories
    New-Repositories
    
    # Build and push
    Build-AndPush
    
    $imageTag = if ($Target -eq "production") { "latest" } else { $Target }
    
    Write-Host "🎉 Build and push completed successfully!" -ForegroundColor Green
    Write-Host "📦 Private ECR: $ECR_REGISTRY/login-ejemplo:$imageTag" -ForegroundColor Cyan
    Write-Host "🌐 Public ECR: $PUBLIC_ECR_REGISTRY/login-ejemplo:$imageTag" -ForegroundColor Cyan
}

Main
