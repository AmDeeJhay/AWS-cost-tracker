@echo off
echo.
echo 🚀 Cloud Cost Tracker Setup Checker
echo ===================================
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ PowerShell not available
    echo Please install PowerShell or run the commands manually
    pause
    exit /b 1
)

REM Run the PowerShell setup script
powershell -ExecutionPolicy Bypass -File "setup.ps1"

pause
