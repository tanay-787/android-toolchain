#!/usr/bin/env node

/**
 * modify-gradle-props.js
 * Injects lean memory, CPU, and single-ABI compilation flags into Android Gradle properties.
 * Usage: node modify-gradle-props.js [path-to-repo-root-or-android-dir]
 */

const fs = require('fs');
const path = require('path');

const targetArg = process.argv[2] ? path.resolve(process.argv[2]) : process.cwd();

// Find android directory or gradle.properties
let androidDir = targetArg;
if (fs.existsSync(path.join(targetArg, 'android'))) {
  androidDir = path.join(targetArg, 'android');
}

const gradlePropsPath = path.join(androidDir, 'gradle.properties');
const localPropsPath = path.join(androidDir, 'local.properties');
const wrapperPath = path.join(androidDir, 'gradle', 'wrapper', 'gradle-wrapper.properties');

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

  if (updated !== content) {
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, updated);
    return true;
  }
  return false;
}

// 1. Ensure local.properties has sdk.dir
const sdkDirLine = 'sdk.dir=/home/user/.androidsdkroot';
const localChanged = updateFile(localPropsPath, [
  { pattern: /^sdk\.dir=.*$/m, value: sdkDirLine },
]);

// 2. Configure lean gradle.properties
const leanProps = [
  { pattern: /^org\.gradle\.jvmargs=.*$/m, value: 'org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=384m -XX:+UseG1GC -Djava.net.preferIPv4Stack=true' },
  { pattern: /^kotlin\.daemon\.jvmargs=.*$/m, value: 'kotlin.daemon.jvmargs=-Xmx1024m -XX:MaxMetaspaceSize=256m' },
  { pattern: /^org\.gradle\.daemon=.*$/m, value: 'org.gradle.daemon=false' },
  { pattern: /^org\.gradle\.workers\.max=.*$/m, value: 'org.gradle.workers.max=2' },
  { pattern: /^org\.gradle\.parallel=.*$/m, value: 'org.gradle.parallel=false' },
  { pattern: /^org\.gradle\.vfs\.watch=.*$/m, value: 'org.gradle.vfs.watch=false' },
  { pattern: /^org\.gradle\.java\.home=.*$/m, value: 'org.gradle.java.home=/nix/store/5badkg3gmzg1c29akwglknkizfg6zj0g-openjdk-17.0.17+8' },
  { pattern: /^reactNativeArchitectures=.*$/m, value: 'reactNativeArchitectures=arm64-v8a' },
];
const gradlePropsChanged = updateFile(gradlePropsPath, leanProps);

console.log('✅ Applied lean Gradle configurations:');
console.log(` - ${localPropsPath}: ${localChanged ? 'updated' : 'already configured'}`);
console.log(` - ${gradlePropsPath}: ${gradlePropsChanged ? 'updated' : 'already configured'}`);
