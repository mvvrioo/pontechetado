@echo off
chcp 65001 >nul
title Apagar PonteChetado
cd /d "%~dp0"
echo Apagando los contenedores de PonteChetado ^(los datos se mantienen^)...
docker compose down
echo Listo. Para volver a encenderlo ejecuta INSTALAR.bat
pause
