$ErrorActionPreference = 'Stop'
Write-Host 'SIGMA FLEET ENTERPRISE V1.0 - Configuracion Windows' -ForegroundColor Cyan
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) { throw 'Instale Node.js 20 LTS o superior desde https://nodejs.org/ y vuelva a ejecutar este instalador.' }
$version = [int]((node -v).TrimStart('v').Split('.')[0])
if ($version -lt 20) { throw 'Se requiere Node.js 20 o superior.' }
if (-not (Test-Path '.env')) { Copy-Item '.env.example' '.env'; Write-Host 'Se creo .env. Configure DATABASE_URL, SESSION_SECRET y ADMIN_PASSWORD.' -ForegroundColor Yellow }
Write-Host 'Instalando dependencias Node.js...' -ForegroundColor Cyan
npm install
if ($LASTEXITCODE -ne 0) { throw 'Fallo npm install.' }
Write-Host 'Verificando sintaxis...' -ForegroundColor Cyan
npm run verify
if ($LASTEXITCODE -ne 0) { throw 'La verificacion de codigo fallo.' }
Write-Host 'Instalacion de dependencias completada.' -ForegroundColor Green
Write-Host 'Configure PostgreSQL y las variables de .env; luego ejecute INICIAR_SIGMA.bat.'
