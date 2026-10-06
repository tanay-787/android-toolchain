#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/env.sh"

echo "================================================"
echo "🤖 Android Lean Toolchain Environment Check"
echo "================================================"
echo ""
echo "☕ Java / JDK:"
java -version 2>&1 | head -n 2
echo "   JAVA_HOME: $JAVA_HOME"
echo "   javac: $(javac -version 2>&1)"
echo ""
echo "📱 Android SDK:"
echo "   ANDROID_HOME: $ANDROID_HOME"
echo "   adb: $(adb version | head -n 1)"
echo "   sdkmanager: $(sdkmanager --version 2>/dev/null | tail -n 1)"
echo ""
echo "📦 Installed Platforms & Build-Tools:"
sdkmanager --list_installed 2>/dev/null | grep -E 'platforms;|build-tools;' || true
echo ""
echo "⚙️ Lean Compilation Settings:"
echo "   MAKEFLAGS: $MAKEFLAGS"
echo "   CMAKE_BUILD_PARALLEL_LEVEL: $CMAKE_BUILD_PARALLEL_LEVEL"
echo "   Global gradle.properties:"
cat "$HOME/.gradle/gradle.properties" | sed 's/^/     /'
echo ""
echo "💾 Storage & Memory:"
df -h /home
free -h | head -n 2
echo "================================================"
