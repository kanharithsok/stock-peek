#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="MacStockWidget"
BUILD_DIR="$ROOT/.build"
APP_DIR="$ROOT/dist/$APP_NAME.app"

echo "==> Building (swift build -c release)"
swift build -c release --package-path "$ROOT"

BIN="$BUILD_DIR/release/$APP_NAME"
if [ ! -f "$BIN" ]; then
    echo "ERROR: binary not found at $BIN" >&2
    exit 1
fi

echo "==> Assembling $APP_DIR"
rm -rf "$ROOT/dist"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

echo "==> Ad-hoc codesigning"
codesign --force --sign - "$APP_DIR"

echo "==> Done: $APP_DIR"
echo "Launch with: open \"$APP_DIR\""
