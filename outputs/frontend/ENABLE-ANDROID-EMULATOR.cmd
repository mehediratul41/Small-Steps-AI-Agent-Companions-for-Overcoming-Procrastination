@echo off
setlocal
title Small Steps - Enable Android Emulator Acceleration
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tool\enable-android-emulator.ps1"
set "setupResult=%ERRORLEVEL%"
echo.
pause
exit /b %setupResult%
