#!/usr/bin/env bash
# Fase 3 — Instala Docker en la VM/servidor (Ubuntu Server).
set -euo pipefail

sudo apt update
sudo apt install -y docker.io

# El paquete del plugin "docker compose" cambia de nombre según la versión de
# Ubuntu (docker-compose-plugin en algunas, docker-compose-v2 en otras).
if apt-cache show docker-compose-plugin >/dev/null 2>&1; then
  sudo apt install -y docker-compose-plugin
elif apt-cache show docker-compose-v2 >/dev/null 2>&1; then
  sudo apt install -y docker-compose-v2
else
  echo "No se encontró docker-compose-plugin ni docker-compose-v2 en los repos de apt." >&2
  echo "Instalá 'docker compose' manualmente o revisá 'apt-cache search compose'." >&2
  exit 1
fi

sudo systemctl enable --now docker

echo "Docker instalado. Versión:"
docker --version
docker compose version
