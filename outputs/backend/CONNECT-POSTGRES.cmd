@echo off
setlocal
title Small Steps - Connect PostgreSQL
cd /d "%~dp0"
".venv\Scripts\python.exe" "tool\setup_postgres.py"
