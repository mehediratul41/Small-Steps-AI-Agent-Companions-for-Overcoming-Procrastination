@echo off
setlocal
title Small Steps - Build Android APK
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool\build-apk.ps1"
set "buildResult=%ERRORLEVEL%"
echo.
if not "%buildResult%"=="0" echo Build failed. See the log path above.
pause
exit /b %buildResult%
