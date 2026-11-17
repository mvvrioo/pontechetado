@echo off
chcp 65001 >nul
title Instalar PonteChetado
cd /d "%~dp0"
echo.
echo  =====================================================
echo    PonteChetado - Instalación completa con Docker
echo    App web + API + base de datos con un solo clic
echo  =====================================================
echo.

where docker >nul 2>&1
if errorlevel 1 (
  echo  [X] Docker Desktop no está instalado.
  echo      Se abrirá la página de descarga. Instálalo, ábrelo y vuelve a ejecutar este archivo.
  start "" https://www.docker.com/products/docker-desktop/
  pause
  exit /b 1
)

docker info >nul 2>&1
if errorlevel 1 (
  echo  [X] Docker Desktop no está abierto.
  echo      Ábrelo, espera a que diga "Engine running" y vuelve a ejecutar este archivo.
  pause
  exit /b 1
)

if not exist .env (
  echo  [1/3] Creando la contraseña de la base de datos ^(.env^)...
  for /f %%c in ('powershell -NoProfile -Command "[guid]::NewGuid().ToString('N').Substring(0,16)"') do echo DB_PASSWORD=%%c> .env
) else (
  echo  [1/3] Ya existe el archivo .env, se usa esa contraseña.
)

echo  [2/3] Construyendo y levantando los contenedores ^(la primera vez tarda varios minutos^)...
docker compose up -d --build
if errorlevel 1 (
  echo.
  echo  [X] No se pudo levantar el proyecto. Revisa los mensajes de arriba.
  pause
  exit /b 1
)

echo  [3/3] Esperando a que la app esté lista...
set /a intentos=0
:esperar
powershell -NoProfile -Command "try { Invoke-WebRequest -UseBasicParsing http://localhost:8081 -TimeoutSec 3 | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if not errorlevel 1 goto listo
set /a intentos+=1
if %intentos% geq 60 (
  echo  [X] La app no respondió. Revisa con: docker compose logs
  pause
  exit /b 1
)
timeout /t 3 /nobreak >nul
goto esperar

:listo
echo.
echo  =====================================================
echo    ¡Listo! PonteChetado está funcionando
echo  =====================================================
echo    App:  http://localhost:8081
echo    API:  http://localhost:8080/PonteChetado/api
echo.
echo    Cuentas de demostración ^(contraseña: Chetado2026^):
echo      superadmin.demo@pontechetado.test
echo      admin.demo@pontechetado.test
echo      entrenador.demo@pontechetado.test
echo      usuario.demo@pontechetado.test   ^(socio Premium^)
echo      gratis.demo@pontechetado.test    ^(socio gratis^)
echo.
echo    Para apagarlo: APAGAR.bat
echo  =====================================================
start "" http://localhost:8081
pause
