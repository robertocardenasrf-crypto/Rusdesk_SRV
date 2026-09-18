#!/usr/bin/env bash
# Fase 4 — Respalda el par de claves del servidor (id_ed25519 / id_ed25519.pub)
# fuera del host. Si se pierden, todos los clientes deben reconfigurar la key.
set -euo pipefail

cd "$(dirname "$0")/.."

SRC_DIR="rustdesk-server/data"
DEST_DIR="${1:-./backups}"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$SRC_DIR/id_ed25519" ] || [ ! -f "$SRC_DIR/id_ed25519.pub" ]; then
  echo "No se encontraron claves en $SRC_DIR. ¿Ya levantaste el servidor?" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"
tar -czf "$DEST_DIR/rustdesk-keys-$STAMP.tar.gz" -C "$SRC_DIR" id_ed25519 id_ed25519.pub

echo "Backup guardado en $DEST_DIR/rustdesk-keys-$STAMP.tar.gz"
echo "Guardalo en un lugar seguro fuera de esta máquina (gestor de contraseñas, almacenamiento cifrado, etc.)."
