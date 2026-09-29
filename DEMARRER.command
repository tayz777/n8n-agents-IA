#!/bin/sh

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec sh "$PROJECT_DIR/scripts/start.sh"
