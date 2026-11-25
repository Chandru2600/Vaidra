@echo off
title Vaidra Public Shareable Tunnel
echo ================================================================
echo             Starting Vaidra Public Tunnel (Port 8000)           
echo ================================================================
echo.
echo Make sure your backend (start_backend.bat) is running on port 8000!
echo.
echo Connecting to secure public tunnel...
echo Look for your public HTTPS link below:
echo.
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -R 80:127.0.0.1:8000 serveo.net
pause
