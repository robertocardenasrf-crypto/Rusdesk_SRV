#!/usr/bin/env bash
# Fase 4/5 — Endurece el firewall de la VM: SSH y los puertos de RustDesk
# solo quedan accesibles a través de la interfaz de Tailscale (tailscale0),
# no desde la LAN normal. También activa actualizaciones de seguridad
# automáticas.
#
# Requiere Tailscale ya instalado y conectado (ver setup-tailscale.sh).
set -euo pipefail

TAILSCALE_IFACE="${TAILSCALE_IFACE:-tailscale0}"

if ! ip link show "$TAILSCALE_IFACE" >/dev/null 2>&1; then
  echo "No se encontró la interfaz '$TAILSCALE_IFACE'. ¿Corriste setup-tailscale.sh y 'tailscale up'?" >&2
  exit 1
fi

sudo apt update
sudo apt install -y ufw unattended-upgrades

echo "Configurando ufw (SSH y puertos RustDesk solo por $TAILSCALE_IFACE)..."

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow in on "$TAILSCALE_IFACE" to any port 22 proto tcp comment 'SSH via Tailscale'
sudo ufw allow in on "$TAILSCALE_IFACE" to any port 21115 proto tcp comment 'RustDesk NAT test'
sudo ufw allow in on "$TAILSCALE_IFACE" to any port 21116 proto tcp comment 'RustDesk ID/heartbeat'
sudo ufw allow in on "$TAILSCALE_IFACE" to any port 21116 proto udp comment 'RustDesk ID/heartbeat'
sudo ufw allow in on "$TAILSCALE_IFACE" to any port 21117 proto tcp comment 'RustDesk relay'
sudo ufw allow in on "$TAILSCALE_IFACE" to any port 21118 proto tcp comment 'RustDesk web client'
sudo ufw allow in on "$TAILSCALE_IFACE" to any port 21119 proto tcp comment 'RustDesk relay web'

sudo ufw --force enable

echo ""
echo "Estado del firewall:"
sudo ufw status verbose

echo ""
echo "Activando actualizaciones de seguridad automáticas (unattended-upgrades)..."
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

echo ""
echo "Listo. SSH y los puertos de RustDesk ahora solo responden por $TAILSCALE_IFACE."
echo "Si te quedás sin acceso por SSH/Tailscale, todavía podés entrar por la consola"
echo "de la VM en VMware (no depende de la red)."
