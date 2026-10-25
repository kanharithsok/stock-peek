#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Stock Peek"
APP_SRC="$ROOT/dist/$APP_NAME.app"
APP_DEST="/Applications/$APP_NAME.app"
LEGACY_APP="/Applications/MacStockWidget.app"

pkill -x StockPeek 2>/dev/null || true
if pgrep -f "$LEGACY_APP/Contents/MacOS/MacStockWidget" >/dev/null 2>&1; then
    pkill -f "$LEGACY_APP/Contents/MacOS/MacStockWidget" 2>/dev/null || true
    sleep 1
fi

if [ ! -d "$APP_SRC" ]; then
    echo "Building app first..."
    "$ROOT/scripts/build_app.sh"
fi

if [ -d "$LEGACY_APP" ]; then
    echo "==> Removing legacy $LEGACY_APP"
    rm -rf "$LEGACY_APP"
fi

echo "==> Installing to $APP_DEST"
rm -rf "$APP_DEST"
cp -R "$APP_SRC" "$APP_DEST"

echo "==> Launching"
open "$APP_DEST"

echo "Done. If you previously enabled Launch at login, re-enable it in Settings because the bundle identifier changed."
