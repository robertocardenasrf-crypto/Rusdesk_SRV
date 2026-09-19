# Levanta hbbs/hbbr en la VM Windows (instancia paralela, para la prueba
# con Radmin VPN). Requiere Docker Desktop instalado y corriendo (ver
# install-docker-desktop-windows.ps1) y Radmin VPN ya instalado/unido a la
# red, con la IP virtual completada en .env.

$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..")

if (-not (Test-Path ".env")) {
    Write-Host "No existe .env. Copiando desde .env.windows.example..."
    Copy-Item ".env.windows.example" ".env"
    Write-Host "Editá .env y completá RUSTDESK_RELAY_HOST con la IP de Radmin VPN antes de continuar."
    exit 1
}

$envContent = Get-Content ".env" -Raw
if ($envContent -notmatch "RUSTDESK_RELAY_HOST=\S") {
    Write-Error "RUSTDESK_RELAY_HOST está vacío en .env. Completalo con la IP de Radmin VPN (ventana de Radmin VPN, red 26.x.x.x) antes de continuar."
    exit 1
}

New-Item -ItemType Directory -Force -Path "rustdesk-server\data" | Out-Null

docker compose -f docker-compose.windows.yml up -d

Write-Host ""
Write-Host "Contenedores levantados. Estado:"
docker compose -f docker-compose.windows.yml ps

Write-Host ""
Write-Host "Esperando a que hbbs genere el par de claves..."
$keyPath = "rustdesk-server\data\id_ed25519.pub"
$deadline = (Get-Date).AddSeconds(10)
while (-not (Test-Path $keyPath) -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 1
}

if (Test-Path $keyPath) {
    Write-Host "Clave pública del servidor (configurar en los clientes RustDesk):"
    Get-Content $keyPath
} else {
    Write-Host "Aún no se generó la clave pública. Revisá 'docker compose -f docker-compose.windows.yml logs hbbs'."
}
