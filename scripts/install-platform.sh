#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/env.sh"

SDKMANAGER="$SCRIPT_DIR/../bin/sdkmanager"

TARGET="${1:-}"

if [ -z "$TARGET" ]; then
  echo "Usage: $0 <platform-version-or-package>"
  echo "Examples:"
  echo "  $0 33              # Installs platforms;android-33"
  echo "  $0 35              # Installs platforms;android-35"
  echo "  $0 build-tools;34.0.0"
  exit 1
fi

if [[ "$TARGET" =~ ^[0-9]+$ ]]; then
  PKG="platforms;android-$TARGET"
else
  PKG="$TARGET"
fi

echo "📦 Installing Android SDK component: $PKG ..."
yes | "$SDKMANAGER" "$PKG"

echo ""
echo "✅ Successfully installed $PKG!"
"$SDKMANAGER" --list_installed | grep -E 'platforms;|build-tools;'
