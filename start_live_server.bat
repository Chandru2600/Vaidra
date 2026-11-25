@echo off
title Vaidra AI Live Server
echo ========================================================
echo           Starting Vaidra AI Healthcare Server
echo ========================================================
echo.

cd /d "%~dp0backend"

echo [1/2] Starting Backend Server (Uvicorn on port 8000)...
start "Vaidra Backend" cmd /k "venv\Scripts\activate.bat && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000"

timeout /t 3 /nobreak >nul

echo [2/2] Starting Ngrok Public Tunnel...
cd /d "%~dp0"
start "Vaidra Ngrok Tunnel" .\ngrok.exe http 8000

echo.
echo ========================================================
echo  Server is now LIVE!
echo.
echo  Public Web App: https://imprudent-overcome-turbofan.ngrok-free.dev/app/
echo  Public Landing: https://imprudent-overcome-turbofan.ngrok-free.dev/
echo  Local Laptop:   http://localhost:8000/app/
echo  Local Wi-Fi:    http://192.168.24.158:8000/app/
echo.
echo  Accounts:
echo  - Username: admin          | Password: 123
echo  - Username: test@test.com  | Password: password123
echo ========================================================
pause
