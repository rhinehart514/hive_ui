@echo off
echo ===================================================
echo FIREBASE WINDOWS FIX - BATCH WRAPPER
echo ===================================================

:: Check if running with admin privileges
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges
) else (
    echo WARNING: Not running with administrator privileges
    echo Some fixes may require admin rights to modify protected files
    echo Consider running this script as administrator
    timeout /t 3
)

:: Execute the main PowerShell script
echo.
echo Executing Firebase fix scripts...
PowerShell -ExecutionPolicy Bypass -File "%~dp0fix_firebase_all.ps1"

echo.
echo ===================================================
echo Script execution completed
echo If you encounter any issues, please see windows/README.md
echo ===================================================
pause 