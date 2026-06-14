#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="PurrBreak"
APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
EXECUTABLE="$ROOT_DIR/.build/release/$APP_NAME"
ICON_FILE="$ROOT_DIR/.build/$APP_NAME.icns"
VERSION="${PURRBREAK_VERSION:-${1:-$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")}}"

cd "$ROOT_DIR"
swift build -c release >&2
swift "$ROOT_DIR/scripts/make-icon.swift" "$ICON_FILE" >&2

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp "$ICON_FILE" "$APP_DIR/Contents/Resources/$APP_NAME.icns"
if [[ -d "$ROOT_DIR/Sources/PurrBreak/Resources" ]]; then
  cp "$ROOT_DIR"/Sources/PurrBreak/Resources/* "$APP_DIR/Contents/Resources/"
fi

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>ru</string>
  <key>CFBundleExecutable</key>
  <string>PurrBreak</string>
  <key>CFBundleIdentifier</key>
  <string>local.purrbreak.app</string>
  <key>CFBundleIconFile</key>
  <string>PurrBreak.icns</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>PurrBreak</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>__VERSION__</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSAppleEventsUsageDescription</key>
  <string>PurrBreak reads the active browser tab URL to count YouTube time only. / PurrBreak читает адрес активной вкладки браузера, чтобы считать только время на YouTube.</string>
  <key>NSHumanReadableCopyright</key>
  <string>Personal use</string>
</dict>
</plist>
PLIST

/usr/bin/sed -i '' "s/__VERSION__/$VERSION/g" "$APP_DIR/Contents/Info.plist"

codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "$APP_DIR"
