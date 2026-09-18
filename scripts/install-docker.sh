#!/usr/bin/env bash
# Fase 3 — Instala Docker en la VM/servidor (Ubuntu Server).
set -euo pipefail

sudo apt update
sudo apt install -y docker.io docker-compose-plugin
sudo systemctl enable --now docker

echo "Docker instalado. Versión:"
docker --version
docker compose version
