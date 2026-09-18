#!/usr/bin/env bash
# Fase 5 (opción Tailscale) — Instala Tailscale en esta máquina (servidor o cliente)
# y la une a tu tailnet. Requiere ejecutar "sudo tailscale up" interactivamente
# la primera vez (abre una URL de login).
set -euo pipefail

curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

echo ""
echo "IP de Tailscale de esta máquina:"
tailscale ip -4

echo ""
echo "Configurá el cliente RustDesk (Configuración > Red) para que apunte a esta IP"
echo "100.x.x.x en vez de la IP LAN/pública, tanto en el servidor como en cada cliente."
