# Local Docker deployment script
# Usage: .\start-local.ps1

Write-Host "🚀 Starting local Docker deployment..." -ForegroundColor Green

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
}
catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create logs directory if it doesn't exist
if (-not (Test-Path "logs")) {
    Write-Host "📁 Creating logs directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path "logs" | Out-Null
}

# Load environment variables from .env.local if it exists
if (Test-Path ".env.local") {
    Write-Host "📝 Loading local environment variables..." -ForegroundColor Yellow
    Get-Content ".env.local" | ForEach-Object {
        if ($_ -match "^([^#][^=]+)=(.*)$") {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }
}

Write-Host "🏗️ Building and starting local containers..." -ForegroundColor Yellow

try {
    docker-compose -f docker-compose.local.yml up -d --build
    
    $hostPort = if ($env:HOST_PORT) { $env:HOST_PORT } else { "3000" }
    
    Write-Host "✅ Local deployment started successfully!" -ForegroundColor Green
    Write-Host "🌐 Application should be available at http://localhost:$hostPort" -ForegroundColor Cyan
    Write-Host "📊 To view logs: npm run dockerize:logs" -ForegroundColor Cyan
    Write-Host "🛑 To stop: npm run dockerize:stop" -ForegroundColor Cyan
}
catch {
    Write-Host "❌ Failed to start local deployment: $($_.Exception.Message)" -ForegroundColor Red
}

Read-Host "Press Enter to continue"
