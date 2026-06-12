#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="PurrBreak"
CREATE_DESKTOP_LINK=1
INSTALL_SCOPE="auto"

for arg in "$@"; do
  case "$arg" in
    --no-desktop)
      CREATE_DESKTOP_LINK=0
      ;;
    --user)
      INSTALL_SCOPE="user"
      ;;
    --system)
      INSTALL_SCOPE="system"
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 64
      ;;
  esac
done

if [[ "$INSTALL_SCOPE" == "system" || ( "$INSTALL_SCOPE" == "auto" && -w "/Applications" ) ]]; then
  INSTALL_DIR="/Applications"
else
  INSTALL_DIR="$HOME/Applications"
fi

TARGET_APP="$INSTALL_DIR/$APP_NAME.app"

BUILD_OUTPUT="$("$ROOT_DIR/scripts/build-app.sh")"
APP_PATH="$(printf "%s\n" "$BUILD_OUTPUT" | tail -n 1)"

mkdir -p "$INSTALL_DIR"
rm -rf "$TARGET_APP"
/usr/bin/ditto "$APP_PATH" "$TARGET_APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$TARGET_APP" >/dev/null 2>&1 || true

if [[ "$CREATE_DESKTOP_LINK" -eq 1 && -d "$HOME/Desktop" ]]; then
  DESKTOP_LINK="$HOME/Desktop/$APP_NAME.app"

  if [[ -L "$DESKTOP_LINK" || -f "$DESKTOP_LINK" ]]; then
    rm -f "$DESKTOP_LINK"
  fi

  if [[ ! -e "$DESKTOP_LINK" ]]; then
    ln -s "$TARGET_APP" "$DESKTOP_LINK"
  else
    echo "Desktop item already exists, leaving it untouched: $DESKTOP_LINK"
  fi
fi

/usr/bin/open -R "$TARGET_APP"

echo "Installed: $TARGET_APP"
if [[ "$INSTALL_DIR" == "/Applications" ]]; then
  echo "Launchpad/Spotlight app: /Applications/$APP_NAME.app"
else
  echo "User app: $TARGET_APP"
fi
if [[ "$CREATE_DESKTOP_LINK" -eq 1 ]]; then
  echo "Desktop shortcut: $HOME/Desktop/$APP_NAME.app"
fi
