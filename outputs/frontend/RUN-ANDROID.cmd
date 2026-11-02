@echo off
setlocal
title Small Steps - Build and Run Android
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool\run-android.ps1"
set "runResult=%ERRORLEVEL%"
echo.
pause
exit /b %runResult%
