@echo off
echo Starting Mobile App...
cd /d "%~dp0vaidra"
set "PATH=%~dp0flutter\bin;%PATH%"
set "FLUTTER_SUPPRESS_ANALYTICS=true"
flutter run
pause
