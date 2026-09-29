#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
PID_FILE="$PROJECT_ROOT/.n8n.pid"
cd "$PROJECT_ROOT"

if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo 'Node.js est introuvable.'
  echo 'Installe Node.js 24 depuis https://nodejs.org/fr/download puis réessaie.'
  exit 1
fi

node_major=$(node -p "process.versions.node.split('.')[0]")
if [ "$node_major" -lt 24 ]; then
  echo "Ta version de Node.js est trop ancienne : $(node --version)"
  echo 'Installe Node.js 24 ou une version plus récente depuis https://nodejs.org/fr/download'
  exit 1
fi

if [ ! -f .env ]; then
  encryption_key=$(od -An -N32 -tx1 /dev/urandom | tr -d ' \n')
  sed "s/GENERATED_BY_START_SCRIPT/$encryption_key/" .env.example > .env
  chmod 600 .env
fi

set -a
. "$PROJECT_ROOT/.env"
set +a

host_port=${N8N_HOST_PORT:-5678}

if [ -f "$PID_FILE" ]; then
  previous_pid=$(cat "$PID_FILE" 2>/dev/null || true)
  case "$previous_pid" in
    ''|*[!0-9]*) rm -f "$PID_FILE" ;;
    *)
      previous_command=$(ps -p "$previous_pid" -o command= 2>/dev/null || true)
      case "$previous_command" in
        *"$PROJECT_ROOT/node_modules/"*n8n*)
          echo 'n8n est déjà lancé.'
          open "http://localhost:$host_port"
          exit 0
          ;;
        *) rm -f "$PID_FILE" ;;
      esac
      ;;
  esac
fi

installed_version=''
if [ -f node_modules/n8n/package.json ]; then
  installed_version=$(node -p "require('./node_modules/n8n/package.json').version" 2>/dev/null || true)
fi

if [ "$installed_version" != '2.41.3' ]; then
  echo 'Installation de n8n en cours. Cela peut prendre quelques minutes...'
  npm install --no-audit --no-fund --prefer-online --no-package-lock
fi

export N8N_HOST='localhost'
export N8N_PORT="$host_port"
export N8N_PROTOCOL='http'
export N8N_LISTEN_ADDRESS='127.0.0.1'
export N8N_EDITOR_BASE_URL="http://localhost:$host_port"
export N8N_WEBHOOK_URL="http://localhost:$host_port"
export N8N_INTERNAL_URL="http://127.0.0.1:$host_port"
export N8N_SECURE_COOKIE='false'
export N8N_USER_FOLDER="$PROJECT_ROOT/.local-data"
export N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS='true'
export N8N_DIAGNOSTICS_ENABLED='false'
export N8N_PERSONALIZATION_ENABLED='false'
export N8N_VERSION_NOTIFICATIONS_ENABLED='false'
export N8N_UNVERIFIED_PACKAGES_ENABLED='false'
export EXECUTIONS_DATA_PRUNE='true'
export EXECUTIONS_DATA_MAX_AGE='168'
export TZ="${GENERIC_TIMEZONE:-Europe/Paris}"

"$PROJECT_ROOT/node_modules/.bin/n8n" start &
n8n_pid=$!
printf '%s\n' "$n8n_pid" > "$PID_FILE"

cleanup() {
  trap - EXIT INT TERM HUP
  if kill -0 "$n8n_pid" 2>/dev/null; then
    kill "$n8n_pid" 2>/dev/null || true
    wait "$n8n_pid" 2>/dev/null || true
  fi
  rm -f "$PID_FILE"
}
trap cleanup EXIT INT TERM HUP

node "$PROJECT_ROOT/scripts/init-owner.mjs"

printf '\nn8n est prêt : http://localhost:%s\n' "$host_port"
echo "E-mail : $N8N_OWNER_EMAIL"
echo "Mot de passe : $N8N_OWNER_PASSWORD"
echo 'Garde cette fenêtre ouverte pendant que tu utilises n8n.'
open "http://localhost:$host_port"

wait "$n8n_pid"
