#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
cd "$PROJECT_ROOT"

if ! command -v docker >/dev/null 2>&1; then
  echo 'Docker est introuvable. Installez ou démarrez Docker.' >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo 'Docker ne répond pas. Démarrez Docker puis réessayez.' >&2
  exit 1
fi

if [ ! -f .env ]; then
  encryption_key=$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')
  sed "s/GENERATED_BY_START_SCRIPT/$encryption_key/" .env.example > .env
  chmod 600 .env
  echo 'Fichier .env local créé avec une clé de chiffrement aléatoire.'
fi

docker compose config --quiet
docker compose up -d --wait n8n
docker compose --profile setup run --rm init-owner

host_port=$(sed -n 's/^N8N_HOST_PORT=//p' .env | head -n 1)
host_port=${host_port:-5678}

printf '\nn8n est prêt : http://localhost:%s\n' "$host_port"
echo 'Compte par défaut : admin@local.test / Admin123'

if command -v open >/dev/null 2>&1; then
  open "http://localhost:$host_port"
fi
