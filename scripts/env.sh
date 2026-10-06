#!/usr/bin/env bash
# Environment loader for Lean Android Toolchain

export JAVA_HOME="/nix/store/5badkg3gmzg1c29akwglknkizfg6zj0g-openjdk-17.0.17+8"
export ANDROID_HOME="/home/user/.androidsdkroot"
export ANDROID_SDK_ROOT="/home/user/.androidsdkroot"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-/home/user/.gradle}"

# Ensure legacy ndk-bundle symlink is cleaned up to prevent inconsistent location warning
[ -L "$ANDROID_HOME/ndk-bundle" ] && rm -f "$ANDROID_HOME/ndk-bundle" 2>/dev/null || true

# Limit C++ parallel compilation jobs (Ninja/CMake) to prevent NDK clang++ exit code 134 (OOM / SIGABRT)
export MAKEFLAGS="-j2"
export CMAKE_BUILD_PARALLEL_LEVEL=2

# Toolchain binary paths
TOOLCHAIN_BIN="/home/user/practice/android-toolchain/bin"
PATH="$TOOLCHAIN_BIN:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/19.0/bin:$PATH"
export PATH

# Handy aliases
alias build-apk="/home/user/practice/android-toolchain/scripts/build-apk.sh"
alias serve-apk="node /home/user/practice/android-toolchain/scripts/serve-apk-qr.js"
alias modify-gradle-props="node /home/user/practice/android-toolchain/scripts/modify-gradle-props.js"
alias clean-android-cache="/home/user/practice/android-toolchain/scripts/clean-cache.sh"
alias check-android-env="/home/user/practice/android-toolchain/scripts/check-env.sh"
