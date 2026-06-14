#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")}"
EXTENSION_NAME="PurrBreak-Companion"
SOURCE_DIR="$ROOT_DIR/extensions/purrbreak-companion"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$DIST_DIR/purrbreak-companion"
ZIP_PATH="$DIST_DIR/$EXTENSION_NAME-$VERSION.zip"

rm -rf "$STAGING_DIR" "$ZIP_PATH"
mkdir -p "$DIST_DIR"
mkdir -p "$STAGING_DIR"

rsync -a \
  --exclude ".DS_Store" \
  "$SOURCE_DIR"/ \
  "$STAGING_DIR"/

(
  cd "$DIST_DIR"
  /usr/bin/zip -qr -X "$ZIP_PATH" "purrbreak-companion"
)

rm -rf "$STAGING_DIR"

echo "$ZIP_PATH"
