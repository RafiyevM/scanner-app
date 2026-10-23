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

cd "$APP_DIR"
"$FLUTTER" pub get
"$FLUTTER" test
