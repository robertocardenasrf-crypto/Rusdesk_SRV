#!/usr/bin/env bash
# Fase 3 — Levanta hbbs y hbbr con docker-compose.
# Requiere Docker instalado (ver install-docker.sh) y un .env (ver .env.example).
set -euo pipefail

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "No existe .env. Copiando desde .env.example..."
  cp .env.example .env
  echo "Editá .env con la IP/host correcto antes de continuar (RUSTDESK_RELAY_HOST)."
fi

mkdir -p rustdesk-server/data

docker compose up -d

echo ""
echo "Contenedores levantados. Estado:"
docker compose ps

echo ""
echo "Esperando a que hbbs genere el par de claves..."
for i in $(seq 1 10); do
  if [ -f rustdesk-server/data/id_ed25519.pub ]; then
    break
  fi
  sleep 1
done

if [ -f rustdesk-server/data/id_ed25519.pub ]; then
  echo "Clave pública del servidor (configurar en los clientes RustDesk):"
  cat rustdesk-server/data/id_ed25519.pub
else
  echo "Aún no se generó la clave pública. Revisá 'docker compose logs hbbs'."
fi
