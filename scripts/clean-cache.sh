#!/usr/bin/env bash
# Cache cleaning script to keep Firebase Studio workspace lean

echo "📊 Current Disk Usage on /home:"
df -h /home

echo ""
echo "🧹 Cleaning Gradle caches & temp files..."
if [ -d "$HOME/.gradle/caches" ]; then
  rm -rf "$HOME/.gradle/caches"
  echo " - Cleaned ~/.gradle/caches"
fi
if [ -d "$HOME/.gradle/daemon" ]; then
  rm -rf "$HOME/.gradle/daemon"
  echo " - Cleaned ~/.gradle/daemon"
fi

# Clean npm cache if present
if which npm >/dev/null 2>&1; then
  npm cache clean --force >/dev/null 2>&1 || true
  echo " - Cleaned ~/.npm cache"
fi

echo ""
echo "📊 Updated Disk Usage on /home:"
df -h /home
