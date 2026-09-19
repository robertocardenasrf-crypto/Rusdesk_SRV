# Instala Docker Desktop en Windows para correr el servidor RustDesk
# (prueba paralela con Radmin VPN). Correr en PowerShell como Administrador.
#
# Requiere WSL2. Si no está habilitado, este script lo activa, pero vas a
# necesitar REINICIAR la VM y volver a correr el script una segunda vez
# para que continúe con la instalación de Docker Desktop.

$ErrorActionPreference = "Stop"

$wslStatus = wsl --status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "WSL2 no está instalado/habilitado. Activándolo..."
    wsl --install --no-distribution
    Write-Host ""
    Write-Host "Listo. Reiniciá la VM ahora y volvé a correr este script"
    Write-Host "para continuar con la instalación de Docker Desktop."
    exit 0
}

$installerPath = Join-Path $env:TEMP "DockerDesktopInstaller.exe"
Write-Host "Descargando Docker Desktop..."
Invoke-WebRequest -Uri "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile $installerPath

Write-Host "Instalando en silencio (esto puede tardar varios minutos)..."
Start-Process -FilePath $installerPath -ArgumentList "install", "--quiet", "--accept-license" -Wait

Write-Host ""
Write-Host "Docker Desktop instalado. Reiniciá la VM, abrí Docker Desktop"
Write-Host "una vez manualmente para aceptar los términos iniciales, y"
Write-Host "esperá a que el ícono de la bandeja muestre 'Docker Desktop is running'."
Write-Host "Recién ahí corré deploy-windows.ps1."
