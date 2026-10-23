#!/usr/bin/env bash
# Removes the obsolete C#/.NET MAUI build that was installed before Flutter.
# The current app is com.qrscanner.qr_scanner; the old package is
# com.qrscanner.app.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$HOME/toolchains}"
if [[ ! -d "$TOOLCHAIN_DIR" && -d "$REPO_ROOT/.toolchain" ]]; then
    TOOLCHAIN_DIR="$REPO_ROOT/.toolchain"
fi

if [[ -n "${ANDROID_SDK_ROOT:-}" && -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]]; then
    ADB="$ANDROID_SDK_ROOT/platform-tools/adb"
elif [[ -n "${ANDROID_HOME:-}" && -x "$ANDROID_HOME/platform-tools/adb" ]]; then
    ADB="$ANDROID_HOME/platform-tools/adb"
elif [[ -x "$TOOLCHAIN_DIR/android-sdk/platform-tools/adb" ]]; then
    ADB="$TOOLCHAIN_DIR/android-sdk/platform-tools/adb"
elif command -v adb >/dev/null 2>&1; then
    ADB="adb"
else
    echo "adb not found." >&2
    exit 1
fi

DEVICES="$("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1 }')"
if [[ -z "$DEVICES" ]]; then
    echo "No authorized Android device detected." >&2
    exit 1
fi

echo "Installed scanner packages:"
"$ADB" shell pm list packages | tr -d '\r' | grep -i qrscanner || true

if "$ADB" shell pm list packages | tr -d '\r' | grep -qx 'package:com.qrscanner.app'; then
    echo "Uninstalling obsolete com.qrscanner.app..."
    "$ADB" uninstall com.qrscanner.app
else
    echo "Obsolete com.qrscanner.app is not installed."
fi

echo "Remaining scanner packages:"
"$ADB" shell pm list packages | tr -d '\r' | grep -i qrscanner || true
