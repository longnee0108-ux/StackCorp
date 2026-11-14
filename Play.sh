#!/usr/bin/env sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
if command -v godot >/dev/null 2>&1; then ENGINE=godot
elif command -v godot4 >/dev/null 2>&1; then ENGINE=godot4
else printf '%s\n' 'Install standard Godot 4.6.1+, open project.godot and press F5.'; exit 1
fi
"$ENGINE" --headless --editor --import --path .
exec "$ENGINE" --path .

