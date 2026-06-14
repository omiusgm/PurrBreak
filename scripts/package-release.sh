#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="PurrBreak"
VERSION="${1:-$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")}"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macOS.zip"

APP_PATH="$(PURRBREAK_VERSION="$VERSION" "$ROOT_DIR/scripts/build-app.sh" | tail -n 1)"

rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

(
  cd "$(dirname "$APP_PATH")"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$ZIP_PATH"
)

echo "$ZIP_PATH"
