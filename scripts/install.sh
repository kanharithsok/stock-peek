#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_SRC="$ROOT/dist/MacStockWidget.app"
APP_DEST="/Applications/MacStockWidget.app"

if [ ! -d "$APP_SRC" ]; then
    echo "Building app first..."
    "$ROOT/scripts/build_app.sh"
fi

echo "==> Installing to $APP_DEST"
rm -rf "$APP_DEST"
cp -R "$APP_SRC" "$APP_DEST"

echo "==> Launching"
open "$APP_DEST"

echo "Done. Now enable Settings -> Launch at login (or System Settings -> Login Items)."
