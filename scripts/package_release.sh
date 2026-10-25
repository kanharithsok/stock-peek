#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(/usr/bin/plutil -extract CFBundleShortVersionString raw "$ROOT/Resources/Info.plist")}"
APP_NAME="MacStockWidget"
ZIP_NAME="$APP_NAME-$VERSION.zip"
ZIP_PATH="$ROOT/dist/$ZIP_NAME"

"$ROOT/scripts/build_app.sh"

echo "==> Packaging $ZIP_NAME"
rm -f "$ZIP_PATH"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent \
    "$ROOT/dist/$APP_NAME.app" "$ZIP_PATH"

echo "==> SHA-256"
/usr/bin/shasum -a 256 "$ZIP_PATH"
echo "==> Done: $ZIP_PATH"
echo
echo "Publish with:"
echo "  gh release create v$VERSION \"$ZIP_PATH\" --title \"v$VERSION\" --notes \"...\""
