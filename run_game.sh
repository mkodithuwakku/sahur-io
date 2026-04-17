#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/sahur-io"

if [[ ! -f "$PROJECT_DIR/project.godot" ]]; then
	echo "Could not find Godot project at: $PROJECT_DIR/project.godot" >&2
	exit 1
fi

if command -v godot >/dev/null 2>&1; then
	GODOT_BIN="godot"
elif command -v godot4 >/dev/null 2>&1; then
	GODOT_BIN="godot4"
else
	echo "Could not find Godot on PATH. Install Godot 4.x or add 'godot' to PATH." >&2
	exit 1
fi

exec "$GODOT_BIN" --path "$PROJECT_DIR" "$@"
