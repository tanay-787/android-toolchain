#!/usr/bin/env node

/**
 * inject-lean-props.js
 * Injects memory caps, worker limits, caching, and single-ABI flags into gradle.properties.
 * Optimized specifically for GitHub Actions runners to maximize speed and minimize resource exhaustion.
 *
 * Usage: node inject-lean-props.js [path-to-project-or-android-dir]
 */

const fs = require('fs');
const path = require('path');

let targetArg = process.argv[2] ? path.resolve(process.argv[2]) : process.cwd();
let targetAbi = process.env.REACT_NATIVE_ARCHITECTURES || 'arm64-v8a';

// Support either root dir or android/ subfolder
let androidDir = targetArg;
if (fs.existsSync(path.join(targetArg, 'android'))) {
  androidDir = path.join(targetArg, 'android');
}

const gradlePropsPath = path.join(androidDir, 'gradle.properties');

function updateFile(filePath, replacements) {
  let content = fs.existsSync(filePath) ? fs.readFileSync(filePath, 'utf8') : '';
  let updated = content;

  for (const { pattern, value } of replacements) {
    if (pattern.test(updated)) {
      updated = updated.replace(pattern, value);
    } else {
      updated = `${updated.replace(/\s*$/, '')}\n${value}\n`;
    }
  }

  updated = updated.replace(/\n{3,}/g, '\n\n').trim() + '\n';
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, updated);
}

const leanProps = [
  // 3GB JVM max keeps build well within 7GB runner RAM while allowing smooth Dex/R8 execution
  { pattern: /^org\.gradle\.jvmargs=.*$/m, value: 'org.gradle.jvmargs=-Xmx3072m -XX:MaxMetaspaceSize=512m -XX:+UseG1GC -Djava.net.preferIPv4Stack=true' },
  { pattern: /^kotlin\.daemon\.jvmargs=.*$/m, value: 'kotlin.daemon.jvmargs=-Xmx1024m -XX:MaxMetaspaceSize=256m' },
  // Ephemeral CI does not need daemons persisting
  { pattern: /^org\.gradle\.daemon=.*$/m, value: 'org.gradle.daemon=false' },
  // GitHub hosted runner has 2 vCPUs - capping workers prevents thrashing and out-of-memory
  { pattern: /^org\.gradle\.workers\.max=.*$/m, value: 'org.gradle.workers.max=2' },
  { pattern: /^org\.gradle\.parallel=.*$/m, value: 'org.gradle.parallel=false' },
  { pattern: /^org\.gradle\.vfs\.watch=.*$/m, value: 'org.gradle.vfs.watch=false' },
  { pattern: /^org\.gradle\.caching=.*$/m, value: 'org.gradle.caching=true' },
  // Cuts build times & disk usage significantly by only compiling arm64 for React Native / Expo / NDK
  { pattern: /^reactNativeArchitectures=.*$/m, value: `reactNativeArchitectures=${targetAbi}` },
];

updateFile(gradlePropsPath, leanProps);
console.log(`✅ Injected lean build optimizations into ${gradlePropsPath}`);
