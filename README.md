# 🤖 Android Toolchain (GitHub Actions CI)

A centralized, reusable Android compilation toolchain designed for GitHub Actions. It allows you to build debug APKs across multiple Android, React Native, and Expo repositories from a single shared setup while staying strictly within your monthly GitHub limits (3,000 runner minutes and 2 GB storage).

---

## ⚡ Key Optimizations & Quota Protectors

1. **Gradle Caching (Saves Runner Minutes)**:
   * Powered by `gradle/actions/setup-gradle@v4`.
   * Leverages GitHub's **free 10 GB per-repository cache pool** (does **not** consume your 2 GB account storage).
   * Reduces build times from ~6–8 minutes down to ~1.5–2 minutes on warm builds.

2. **Aggressive Retention Cap (Protects 2 GB Storage)**:
   * Debug artifacts default to `retention-days: 1` (or 2).
   * Prevents accumulating dozens of 30–80 MB APKs that would quickly exhaust your 2 GB quota.

3. **Lean JVM & Worker Throttling**:
   * Capped to `-Xmx3072m` JVM and 2 worker threads to match standard GitHub runner specs (2 vCPU, 7 GB RAM).
   * Eliminates runner out-of-memory errors and Gradle worker thread contention.
   * Native C++ concurrency capped (`MAKEFLAGS="-j2"`, `CMAKE_BUILD_PARALLEL_LEVEL=2`).

4. **Single-Architecture Compilation (`arm64-v8a`)**:
   * Automatically sets `reactNativeArchitectures=arm64-v8a` for React Native / Expo / NDK builds.
   * Eliminates unnecessary x86/x86_64/armeabi-v7a compiling, reducing build times and APK sizes by ~70%.

---

## 🚀 How to Use in Your Repositories

### Option 1: Reusable Workflow (Recommended)

In any calling repository, create `.github/workflows/build-debug.yml`:

```yaml
name: Build Debug APK

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  build:
    uses: tanay-787/android-toolchain/.github/workflows/compile-debug-apk.yml@main
    with:
      # Use '.' for pure Android apps, or 'android' for React Native / Expo
      android-path: '.'
      java-version: '17'
      # Keep retention short to protect your 2GB monthly storage quota
      retention-days: 1
```

### Option 2: Composite Action (Inside Existing Workflow Job)

If your calling repository already has custom preparatory steps (e.g. `npm install`, asset bundling, linting):

```yaml
name: CI

on:
  push:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # ... any custom setup steps (npm install, etc.) ...

      - name: Compile Debug APK
        uses: tanay-787/android-toolchain@main
        with:
          android-path: '.'
          java-version: '17'

      - name: Upload Debug APK
        uses: actions/upload-artifact@v4
        with:
          name: debug-apk-${{ github.run_id }}
          path: '**/build/outputs/apk/debug/*.apk'
          retention-days: 1
```

---

## ⚙️ Configuration Inputs

Both the reusable workflow and composite action support the following inputs:

| Input | Description | Default |
| :--- | :--- | :--- |
| `android-path` | Directory containing `gradlew` (`.` for native, `android` for React Native/Expo) | `.` |
| `java-version` | Java JDK version | `17` |
| `java-distribution` | JDK vendor distribution (`temurin`, `zulu`, etc.) | `temurin` |
| `gradle-task` | Gradle task to execute | `assembleDebug` |
| `optimize-gradle` | Injects lean memory, concurrency & single-ABI flags into `gradle.properties` | `true` |
| `target-abi` | Architecture target for React Native / Expo builds | `arm64-v8a` |
| `artifact-name`* | Prefix for the uploaded APK artifact (*reusable workflow only*) | `debug-apk` |
| `retention-days`* | Days to retain uploaded artifact in storage (*reusable workflow only*) | `1` |

---

## 🔒 Private Repository Access Setup

If this `android-toolchain` repository is private, ensure your other repositories have permission to call it:

1. In this repo, navigate to **Settings** > **Actions** > **General**.
2. Scroll down to **Access**.
3. Select **"Accessible from repositories in the 'tanay-787' organization / user account"**.
4. Click **Save**.

---

## 📁 Repository Structure

```
android-toolchain/
├── .github/
│   └── workflows/
│       └── compile-debug-apk.yml    # Reusable workflow (workflow_call)
├── action.yml                       # Composite action (uses: tanay-787/android-toolchain@main)
├── config/
│   └── gradle.properties            # Reference lean Gradle properties
├── scripts/
│   └── inject-lean-props.js         # Zero-dependency lean property injection script
└── README.md
```
