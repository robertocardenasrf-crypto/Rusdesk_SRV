# Fase 6 — Instala el cliente RustDesk en Windows y lo deja preconfigurado
# apuntando a este servidor propio, sin tocar nada a mano.
#
# Correr en PowerShell como Administrador:
#   powershell -ExecutionPolicy Bypass -File install-client-windows.ps1
#
# Nota: hay reportes (no confirmados por el proyecto) de que en algunas
# versiones el archivo de config se ignora si la app ya se abrió antes.
# Si después de instalar el ID Server no queda seteado, abrí RustDesk,
# andá a Configuración > Red y pegalo a mano, o usá "Import Config" con
# un string exportado desde un cliente que ya funcione.

$ErrorActionPreference = "Stop"

# --- Datos del servidor propio ---
$IdRelayServer = "100.64.234.119"
$ServerKey     = "j5aiBt2ybwp7+GAWhIpAOszP6tQkaAIWqQjo4aTnkl4="

Write-Host "Buscando el último instalador de RustDesk para Windows..."
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/rustdesk/rustdesk/releases/latest"
$asset = $release.assets | Where-Object {
    $_.name -match '^rustdesk-.*-x86_64\.exe$' -and $_.name -notmatch 'sciter'
} | Select-Object -First 1

if (-not $asset) {
    Write-Error "No se encontró el instalador .exe en el último release de GitHub."
    exit 1
}

$installerPath = Join-Path $env:TEMP $asset.name
Write-Host "Descargando $($asset.name)..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installerPath

Write-Host "Instalando en silencio..."
Start-Process -FilePath $installerPath -ArgumentList "--silent-install" -Wait

Write-Host "Esperando a que el instalador termine de crear la carpeta de configuración..."
$configDir = Join-Path $env:APPDATA "RustDesk\config"
$deadline = (Get-Date).AddSeconds(30)
while (-not (Test-Path $configDir) -and (Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 1
}
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

$configPath = Join-Path $configDir "RustDesk2.toml"
$configContent = @"
rendezvous_server = '$IdRelayServer'
nat_type = 1
serial = 0

[options]
custom-rendezvous-server = '$IdRelayServer'
key = '$ServerKey'
relay-server = '$IdRelayServer'
"@

Write-Host "Escribiendo configuración en $configPath..."
Set-Content -Path $configPath -Value $configContent -Encoding UTF8

Write-Host ""
Write-Host "Listo. RustDesk instalado y configurado con:"
Write-Host "  ID/Relay Server: $IdRelayServer"
Write-Host ""
Write-Host "Abrí RustDesk y confirmá en Configuración > Red que los valores"
Write-Host "quedaron cargados. Si aparecen vacíos, pegalos a mano una vez"
Write-Host "(o usá 'Import Config' con un string exportado desde otro cliente)."
