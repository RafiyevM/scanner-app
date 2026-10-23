#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$HOME/toolchains}"
if [[ ! -d "$TOOLCHAIN_DIR" && -d "$REPO_ROOT/.toolchain" ]]; then
    TOOLCHAIN_DIR="$REPO_ROOT/.toolchain"
fi
APP_DIR="$REPO_ROOT/Projects/MobileApp"

if [[ -x "$TOOLCHAIN_DIR/flutter/bin/flutter" ]]; then
    FLUTTER="$TOOLCHAIN_DIR/flutter/bin/flutter"
elif command -v flutter >/dev/null 2>&1; then
    FLUTTER="flutter"
else
    if [[ -f "$TOOLCHAIN_DIR/flutter.zip" ]]; then
        SIZE="$(du -h "$TOOLCHAIN_DIR/flutter.zip" | cut -f1)"
        echo "Flutter is not installed yet. The SDK download is in progress ($SIZE of ~2.16 GB)." >&2
        echo "Wait for Root/Scripts/bootstrap-flutter.sh to finish, then rerun this script." >&2
    else
        echo "Flutter not found. Run Root/Scripts/bootstrap-flutter.sh." >&2
    fi
    exit 1
fi

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "$SDK" ]]; then
    if [[ -d "$TOOLCHAIN_DIR/android-sdk" ]]; then
        SDK="$TOOLCHAIN_DIR/android-sdk"
    elif [[ -d "$HOME/Library/Android/sdk" ]]; then
        SDK="$HOME/Library/Android/sdk"
    else
        echo "Android SDK not configured. Set ANDROID_HOME or ANDROID_SDK_ROOT." >&2
        exit 1
    fi
fi
export ANDROID_HOME="$SDK"
export ANDROID_SDK_ROOT="$SDK"
export PATH="$SDK/platform-tools:$PATH"

find_jdk21() {
    local candidates=(
        "$TOOLCHAIN_DIR"/jdk21/*/Contents/Home
        "$TOOLCHAIN_DIR/jdk21/Contents/Home"
        /Library/Java/JavaVirtualMachines/jdk-21*.jdk/Contents/Home
        "$HOME"/Library/Java/JavaVirtualMachines/*21*/Contents/Home
        "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
        "${JAVA_HOME:-}"
    )

    local candidate
    local version
    for candidate in "${candidates[@]}"; do
        if [[ -n "$candidate" && -x "$candidate/bin/java" && -x "$candidate/bin/jar" ]]; then
            version="$("$candidate/bin/java" -version 2>&1 | head -1)"
            if [[ "$version" == *'version "21.'* ]]; then
                echo "$candidate"
                return 0
            fi
        fi
    done
    return 1
}

if JDK_HOME="$(find_jdk21)"; then
    export JAVA_HOME="$JDK_HOME"
else
    echo "JDK 21 not found. Install JDK 21 into ~/toolchains/jdk21 or set JAVA_HOME." >&2
    exit 1
fi

cd "$APP_DIR"

if [[ ! -d "$APP_DIR/android" ]]; then
    echo "Generating the Flutter Android scaffold..."

    SCAFFOLD_DIR="$(mktemp -d)"
    "$FLUTTER" create \
        --platforms=android \
        --android-language java \
        --org com.qrscanner \
        --project-name qr_scanner \
        "$SCAFFOLD_DIR/app" >/dev/null

    cp -R "$SCAFFOLD_DIR/app/android" "$APP_DIR/android"
    cp "$SCAFFOLD_DIR/app/.metadata" "$APP_DIR/.metadata" 2>/dev/null || true
    rm -rf "$SCAFFOLD_DIR"
fi

MANIFEST="$APP_DIR/android/app/src/main/AndroidManifest.xml"
if [[ -f "$MANIFEST" ]]; then
    python3 - "$MANIFEST" <<'PY'
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()

permissions = ""
if "android.permission.CAMERA" not in text:
    permissions += '    <uses-permission android:name="android.permission.CAMERA" />\n'
if "android.permission.INTERNET" not in text:
    permissions += '    <uses-permission android:name="android.permission.INTERNET" />\n'
if "android.hardware.camera.any" not in text:
    permissions += '    <uses-feature android:name="android.hardware.camera.any" android:required="true" />\n'
if permissions and "<application" in text:
    text = text.replace("<application", permissions + "    <application", 1)

text = text.replace('android:label="qr_scanner"', 'android:label="@string/app_name"')
if "usesCleartextTraffic" not in text and "<application" in text:
    text = text.replace(
        "<application",
        '<application android:usesCleartextTraffic="true"',
        1,
    )

path.write_text(text)
PY
fi

BUILD_ARGS=(--debug)
if [[ -n "${API_BASE_URL:-}" ]]; then
    BUILD_ARGS+=("--dart-define=API_BASE_URL=$API_BASE_URL")
    echo "API base URL: $API_BASE_URL"
fi

"$FLUTTER" pub get
"$FLUTTER" build apk "${BUILD_ARGS[@]}"

echo
echo "APK: $APP_DIR/build/app/outputs/flutter-apk/app-debug.apk"
