#!/usr/bin/env zsh
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/publish-github.sh <git-remote-url>" >&2
  echo "Example: ./scripts/publish-github.sh git@github.com:USERNAME/PurrBreak.git" >&2
  echo "Example: ./scripts/publish-github.sh https://github.com/USERNAME/PurrBreak.git" >&2
  exit 64
fi

REMOTE_URL="$1"

if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

git push -u origin main
git push origin v0.1.0
