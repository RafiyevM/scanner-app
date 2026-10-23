#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$HOME/toolchains}"
FLUTTER_DIR="$TOOLCHAIN_DIR/flutter"
FLUTTER_VERSION="3.47.7"

if [[ -x "$FLUTTER_DIR/bin/flutter" ]]; then
    echo "Flutter is already installed:"
    "$FLUTTER_DIR/bin/flutter" --version
    exit 0
fi

case "$(uname -m)" in
    arm64)
        ARCHIVE="flutter_macos_arm64_${FLUTTER_VERSION}-stable.zip"
        ;;
    x86_64)
        ARCHIVE="flutter_macos_${FLUTTER_VERSION}-stable.zip"
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)" >&2
        exit 1
        ;;
esac

mkdir -p "$TOOLCHAIN_DIR"

if [[ -f "$TOOLCHAIN_DIR/flutter.zip" ]] && unzip -tq "$TOOLCHAIN_DIR/flutter.zip" >/dev/null 2>&1; then
    echo "Using existing complete Flutter archive."
else
    echo "Downloading/resuming Flutter $FLUTTER_VERSION..."
    curl -fL -C - \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/${ARCHIVE}" \
        -o "$TOOLCHAIN_DIR/flutter.zip"
fi

unzip -q "$TOOLCHAIN_DIR/flutter.zip" -d "$TOOLCHAIN_DIR"
rm -f "$TOOLCHAIN_DIR/flutter.zip"

if [[ -d "$TOOLCHAIN_DIR/android-sdk" ]]; then
    "$FLUTTER_DIR/bin/flutter" config \
        --android-sdk "$TOOLCHAIN_DIR/android-sdk"
fi

"$FLUTTER_DIR/bin/flutter" --version

echo
echo "Flutter installed at $FLUTTER_DIR"
echo "Run: $FLUTTER_DIR/bin/flutter doctor"
