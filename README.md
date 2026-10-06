# 🤖 Lean Android Compilation Toolchain for Firebase Studio / IDX

A lightweight, zero-overhead Android compilation toolchain designed specifically for cloud workspaces (Project IDX / Firebase Studio). 

It leverages the pre-provisioned Nix/system layer for the Android SDK and OpenJDK 17 without consuming persistent workspace storage, and applies aggressive resource and single-ABI optimization flags adapted from [`tanay-787/refind`](https://github.com/tanay-787/refind).

---

## 📁 Directory Structure

```
android-toolchain/
├── bin/                      # SDK and JDK executables linked into PATH
│   ├── java, javac, jar, ... # OpenJDK 17 binaries (Nix store)
│   ├── adb, fastboot         # Android platform-tools
│   ├── sdkmanager            # Writable-root SDK manager wrapper
│   └── d8, r8, apkanalyzer   # Android cmdline-tools
├── config/
│   └── gradle.properties     # Lean Gradle properties template
├── scripts/
│   ├── env.sh                # Environment loader (JAVA_HOME, ANDROID_HOME, MAKEFLAGS)
│   ├── check-env.sh          # Toolchain & resource diagnostics script
│   ├── build-apk.sh          # Automated lean APK build runner
│   ├── modify-gradle-props.js# Injects lean flags & local.properties into any repo
│   ├── serve-apk-qr.js       # Zero-dependency local APK HTTP server with terminal QR code
│   ├── install-platform.sh   # Helper to install extra Android SDK platforms
│   └── clean-cache.sh        # Purges Gradle and build caches to reclaim disk
└── output-apks/              # Central destination for compiled APKs
```

---

## ⚡ Lean Optimizations Included

Adapted from [`tanay-787/refind`](https://github.com/tanay-787/refind):

1. **Gradle JVM Memory Capping**:
   ```properties
   org.gradle.jvmargs=-Xmx3072m -XX:MaxMetaspaceSize=512m -XX:+UseG1GC
   ```
   Prevents out-of-memory errors on the workspace's 7.8 GB RAM.

2. **Worker Limitation**:
   ```properties
   org.gradle.workers.max=2
   org.gradle.parallel=false
   ```
   Matches the 2 vCPU capacity and avoids thread contention.

3. **C++ / NDK Clang++ Concurrency Caps**:
   ```bash
   export MAKEFLAGS="-j2"
   export CMAKE_BUILD_PARALLEL_LEVEL=2
   ```
   Prevents NDK `clang++` `exit code 134` (OOM / `SIGABRT`) when compiling native dependencies.

4. **Single-Architecture Compilation (React Native / Expo)**:
   ```properties
   reactNativeArchitectures=arm64-v8a
   ```
   Restricts native compilation to modern 64-bit ARM (`arm64-v8a`), cutting build times and disk usage by ~75%.

5. **Filesystem Watcher Disabled**:
   ```properties
   org.gradle.vfs.watch=false
   ```
   Saves background file descriptor monitoring overhead in container environments.

---

## 🚀 Quick Usage

### 1. Build an APK for any Repository
Run from the root of any Android / React Native / Expo repository:
```bash
build-apk
```
Or specify path and build type:
```bash
build-apk /path/to/my-repo --debug
build-apk /path/to/my-repo --release
```
The compiled APK will automatically be copied to:
`android-toolchain/output-apks/<repo-name>/`

### 2. Download / Test on Device via QR Code
Run:
```bash
serve-apk
# Or specify an APK file directly:
node android-toolchain/scripts/serve-apk-qr.js /path/to/app.apk
```
Displays a local download link and an ASCII QR code directly in the terminal to scan and download with your test phone.

### 3. Inject Lean Properties into an Existing Repo
```bash
modify-gradle-props /path/to/my-repo
```

### 4. Install Extra Android SDK Platforms
```bash
android-toolchain/scripts/install-platform.sh 33   # Installs platforms;android-33
android-toolchain/scripts/install-platform.sh 35   # Installs platforms;android-35
```

### 5. Check Health & Diagnostics
```bash
check-android-env
```

### 6. Clean Caches & Reclaim Storage
```bash
clean-android-cache
```
