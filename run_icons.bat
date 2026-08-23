@echo off
cd /d "%~dp0"
echo Running flutter pub get...
call flutter pub get
echo.
echo Running flutter_launcher_icons...
call dart run flutter_launcher_icons
echo.
echo Done!
pause
