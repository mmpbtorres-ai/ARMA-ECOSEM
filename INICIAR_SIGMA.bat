@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ==============================================
echo       SIGMA FLEET ENTERPRISE V1.0
echo ==============================================
where node >nul 2>nul || (echo ERROR: Instale Node.js 20 LTS o superior. & pause & exit /b 1)
if not exist .env (copy .env.example .env >nul & echo Se creo .env. Edite DATABASE_URL y credenciales antes de continuar.)
if not exist node_modules (echo Instalando dependencias... & call npm install || (pause & exit /b 1))
echo Iniciando SIGMA Fleet...
start "SIGMA Fleet" cmd /c "timeout /t 3 >nul & start http://localhost:3000"
call npm start
pause
