@echo off
echo 🚀 Starting local Docker deployment...

REM Check if Docker is running
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)

REM Create logs directory if it doesn't exist
if not exist logs mkdir logs

REM Load environment variables from .env.local if it exists
if exist .env.local (
    echo 📝 Loading local environment variables...
    for /f "usebackq tokens=1,2 delims==" %%i in (".env.local") do (
        if not "%%i"=="" if not "%%i:~0,1%"=="#" set %%i=%%j
    )
)

echo 🏗️ Building and starting local containers...
docker-compose -f docker-compose.local.yml up -d --build

if %errorlevel% equ 0 (
    echo ✅ Local deployment started successfully!
    echo 🌐 Application should be available at http://localhost:%HOST_PORT%
    echo 📊 To view logs: npm run dockerize:logs
    echo 🛑 To stop: npm run dockerize:stop
) else (
    echo ❌ Failed to start local deployment
)

pause
