#!/bin/sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$PROJECT_DIR"

if ! command -v docker >/dev/null 2>&1; then
  echo 'Docker est introuvable. Vérifie que Docker Desktop est installé.'
  exit 1
fi

docker compose down
echo 'n8n est arrêté. Tes données sont conservées.'
