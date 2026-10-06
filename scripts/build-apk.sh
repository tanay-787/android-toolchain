#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "$SCRIPT_DIR/env.sh"

REPO_DIR="${1:-.}"
if [[ "$REPO_DIR" == -* ]]; then
  # First argument is a flag, assume current directory
  FLAG="$REPO_DIR"
  REPO_DIR="."
else
  FLAG="${2:-}"
fi

REPO_DIR="$(cd "$REPO_DIR" && pwd)"
REPO_NAME="$(basename "$REPO_DIR")"

echo "📂 Project: $REPO_DIR"

# Locate Android root (either $REPO_DIR/android or $REPO_DIR)
ANDROID_DIR="$REPO_DIR"
if [ -d "$REPO_DIR/android" ] && [ -f "$REPO_DIR/android/build.gradle" -o -f "$REPO_DIR/android/build.gradle.kts" ]; then
  ANDROID_DIR="$REPO_DIR/android"
fi

if [ ! -f "$ANDROID_DIR/gradlew" ] && [ ! -f "$ANDROID_DIR/build.gradle" ] && [ ! -f "$ANDROID_DIR/build.gradle.kts" ]; then
  echo "❌ Error: Could not find gradlew or build.gradle in $REPO_DIR or $ANDROID_DIR"
  exit 1
fi

# Apply lean gradle properties & local.properties
node "$SCRIPT_DIR/modify-gradle-props.js" "$REPO_DIR"

TARGET_BUILD=""
if [[ "$FLAG" == "--release" ]] || [[ "$FLAG" == "-r" ]]; then
  TARGET_BUILD="release"
elif [[ "$FLAG" == "--debug" ]] || [[ "$FLAG" == "-d" ]]; then
  TARGET_BUILD="debug"
fi

if [[ -z "$TARGET_BUILD" ]]; then
  if [[ -t 0 ]]; then
    echo ""
    echo "🔨 Select APK build type to compile:"
    echo "  [1] Debug   (./gradlew assembleDebug)"
    echo "  [2] Release (./gradlew assembleRelease)"
    read -rp "Enter choice [1/2] (default: 1): " choice
    if [[ "$choice" == "2" ]] || [[ "$choice" == "r" ]] || [[ "$choice" == "release" ]]; then
      TARGET_BUILD="release"
    else
      TARGET_BUILD="debug"
    fi
  else
    TARGET_BUILD="debug"
  fi
fi

cd "$ANDROID_DIR"

# Ensure gradlew is executable
if [ -f "./gradlew" ]; then
  chmod +x ./gradlew
fi

GRADLE_CMD="./gradlew"
if [ ! -f "./gradlew" ]; then
  echo "⚠️  No ./gradlew found in $ANDROID_DIR, attempting system gradle..."
  GRADLE_CMD="gradle"
fi

if [[ "$TARGET_BUILD" == "release" ]]; then
  echo "🚀 Compiling Release APK (assembleRelease)..."
  $GRADLE_CMD assembleRelease --no-daemon
else
  echo "🛠️ Compiling Debug APK (assembleDebug)..."
  $GRADLE_CMD assembleDebug --no-daemon
fi

# Locate generated APKs
OUTPUT_DEST="/home/user/practice/android-toolchain/output-apks/$REPO_NAME"
mkdir -p "$OUTPUT_DEST"

APK_FILES=$(find "$ANDROID_DIR" -name "*.apk" -type f 2>/dev/null || true)
if [ -n "$APK_FILES" ]; then
  echo ""
  echo "🎉 Compilation successful! Built APKs:"
  for apk in $APK_FILES; do
    apk_name="$(basename "$apk")"
    cp -f "$apk" "$OUTPUT_DEST/$apk_name"
    size=$(du -h "$OUTPUT_DEST/$apk_name" | cut -f1)
    echo "  - $OUTPUT_DEST/$apk_name ($size)"
  done
  echo ""
  echo "💡 To download or test on device, run:"
  echo "   node $SCRIPT_DIR/serve-apk-qr.js $OUTPUT_DEST"
else
  echo "⚠️ Build succeeded, but no .apk files were found under $ANDROID_DIR"
fi
