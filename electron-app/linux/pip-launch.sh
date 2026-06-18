#!/bin/sh
# Launches the Pip mascot from a source checkout. Used by the .desktop entry that
# install-launcher.sh sets up, but you can also run it directly.

# Every run appends here so you can see what happened if a launcher click seems
# to do nothing: tail -n 40 /tmp/pip-launch.log
LOG="${TMPDIR:-/tmp}/pip-launch.log"

# If set, Electron runs as a plain Node process instead of opening the GUI. Some
# environments (e.g. an editor's integrated terminal) export this; clear it so the
# launcher always starts the actual app.
unset ELECTRON_RUN_AS_NODE

# Scrub env that breaks the bundled Electron when the launcher is started from a
# contaminated context. Snap apps (e.g. the VS Code snap) inject snap library and
# module paths into child processes, which cause "symbol lookup error /
# GLIBC_PRIVATE" crashes — the app then dies silently and "nothing opens".
unset LD_LIBRARY_PATH LD_PRELOAD GTK_PATH GTK_EXE_PREFIX GTK_IM_MODULE_FILE \
      GIO_MODULE_DIR GDK_PIXBUF_MODULE_FILE GDK_PIXBUF_MODULEDIR LOCPATH \
      GSETTINGS_SCHEMA_DIR GICONV_PATH GDK_BACKEND_VENDOR

APPDIR="$(cd "$(dirname "$0")/.." && pwd)"   # electron-app/
cd "$APPDIR" || exit 1

{
  echo "=== pip-launch $(date) pid=$$ ==="
  echo "APPDIR=$APPDIR"
} >> "$LOG" 2>&1

# --no-sandbox: a run-from-source checkout has no root-owned chrome-sandbox, and
# when GNOME launches us from the dock the user-namespace sandbox is blocked, so
# Electron would abort. Safe for a local-only mascot.
if [ -x ./node_modules/electron/dist/electron ]; then
  echo "starting: ./node_modules/electron/dist/electron --no-sandbox ." >> "$LOG" 2>&1
  exec ./node_modules/electron/dist/electron --no-sandbox . >> "$LOG" 2>&1
elif command -v npx >/dev/null 2>&1; then
  echo "starting: npx electron --no-sandbox ." >> "$LOG" 2>&1
  exec npx electron --no-sandbox . >> "$LOG" 2>&1
else
  echo "Electron isn't installed. Run 'npm install' in $APPDIR first." | tee -a "$LOG" >&2
  exit 1
fi
