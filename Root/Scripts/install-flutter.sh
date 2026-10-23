#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$HOME/toolchains}"
if [[ ! -d "$TOOLCHAIN_DIR" && -d "$REPO_ROOT/.toolchain" ]]; then
    TOOLCHAIN_DIR="$REPO_ROOT/.toolchain"
fi
APP_DIR="$REPO_ROOT/Projects/MobileApp"
APPLICATION_ID="com.qrscanner.qr_scanner"
APK="$APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"

if [[ -n "${ANDROID_SDK_ROOT:-}" && -x "$ANDROID_SDK_ROOT/platform-tools/adb" ]]; then
    ADB="$ANDROID_SDK_ROOT/platform-tools/adb"
elif [[ -n "${ANDROID_HOME:-}" && -x "$ANDROID_HOME/platform-tools/adb" ]]; then
    ADB="$ANDROID_HOME/platform-tools/adb"
elif [[ -x "$TOOLCHAIN_DIR/android-sdk/platform-tools/adb" ]]; then
    ADB="$TOOLCHAIN_DIR/android-sdk/platform-tools/adb"
elif command -v adb >/dev/null 2>&1; then
    ADB="adb"
else
    echo "adb not found. Install Android platform-tools first." >&2
    exit 1
fi

if [[ ! -f "$APK" ]]; then
    echo "Flutter APK not found. Run Root/Scripts/build-flutter.sh first." >&2
    exit 1
fi

DEVICES="$("$ADB" devices | awk 'NR > 1 && $2 == "device" { print $1 }')"
if [[ -z "$DEVICES" ]]; then
    echo "No authorized Android device detected." >&2
    "$ADB" devices >&2 || true
    echo "Connect a device, enable USB debugging, and accept the RSA prompt." >&2
    exit 1
fi

"$ADB" install -r "$APK"
"$ADB" shell monkey -p "$APPLICATION_ID" -c android.intent.category.LAUNCHER 1
