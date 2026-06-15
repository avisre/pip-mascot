#!/bin/sh
# Launches the Pip mascot from a source checkout. Used by the .desktop entry that
# install-launcher.sh sets up, but you can also run it directly.
APPDIR="$(cd "$(dirname "$0")/.." && pwd)"   # electron-app/
cd "$APPDIR" || exit 1

if [ -x ./node_modules/electron/dist/electron ]; then
  exec ./node_modules/electron/dist/electron .
elif command -v npx >/dev/null 2>&1; then
  exec npx electron .
else
  echo "Electron isn't installed. Run 'npm install' in $APPDIR first." >&2
  exit 1
fi
