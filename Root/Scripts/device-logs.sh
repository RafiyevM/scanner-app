#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$HOME/toolchains}"
if [[ ! -d "$TOOLCHAIN_DIR" && -d "$REPO_ROOT/.toolchain" ]]; then
    TOOLCHAIN_DIR="$REPO_ROOT/.toolchain"
fi
APPLICATION_ID="com.qrscanner.qr_scanner"

if [[ $# -gt 0 && "$1" != -* ]]; then
    APPLICATION_ID="$1"
    shift
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
    echo "adb not found. Install Android platform-tools first." >&2
    exit 1
fi

PID="$("$ADB" shell pidof -s "$APPLICATION_ID" | tr -d '\r')"

if [[ -z "$PID" ]]; then
    echo "App is not running; showing unfiltered logs." >&2
    exec "$ADB" logcat "$@"
fi

exec "$ADB" logcat --pid="$PID" "$@"
