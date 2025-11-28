@echo off
REM Quick start script for NILM Backend API (Windows)

echo ======================================
echo 🚀 NILM Backend API - Quick Start
echo ======================================

echo.
echo Step 1: Installing Node.js dependencies...
call npm install
if errorlevel 1 (
    echo ❌ Failed to install Node.js dependencies
    exit /b 1
)
echo ✅ Node.js dependencies installed

echo.
echo Step 2: Setting up Python environment...
cd python_service
if not exist "venv" (
    python -m venv venv
    echo ✅ Virtual environment created
) else (
    echo ✅ Virtual environment already exists
)

call venv\Scripts\activate.bat

pip install -r requirements.txt
if errorlevel 1 (
    echo ❌ Failed to install Python dependencies
    exit /b 1
)
echo ✅ Python dependencies installed

cd ..

echo.
echo ======================================
echo ✅ Setup Complete!
echo ======================================

echo.
echo Next steps:
echo 1. Copy .env.example to .env and configure:
echo    copy .env.example .env
echo.
echo 2. Start the Python Flask service:
echo    cd python_service
echo    venv\Scripts\activate.bat
echo    python model_service.py
echo.
echo 3. In another terminal, start Express API:
echo    npm start
echo.
echo 4. Test the API:
echo    curl http://localhost:3000/api/health
echo.
echo For more details, see README.md
echo.
pause
