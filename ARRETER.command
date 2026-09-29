#!/bin/sh

set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PID_FILE="$PROJECT_DIR/.n8n.pid"

if [ ! -f "$PID_FILE" ]; then
  echo "n8n n'est pas lancé."
  exit 0
fi

n8n_pid=$(cat "$PID_FILE" 2>/dev/null || true)
case "$n8n_pid" in
  ''|*[!0-9]*)
    rm -f "$PID_FILE"
    echo "n8n n'est pas lancé."
    exit 0
    ;;
esac

n8n_command=$(ps -p "$n8n_pid" -o command= 2>/dev/null || true)
case "$n8n_command" in
  *"$PROJECT_DIR/node_modules/"*n8n*)
    kill "$n8n_pid"
    echo 'n8n est arrêté. Tes données sont conservées.'
    ;;
  *)
    echo "n8n n'était plus lancé."
    ;;
esac

rm -f "$PID_FILE"
