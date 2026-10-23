#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CORE_DIR="$REPO_ROOT/Projects/MobileApp.CSharp"

if ! command -v dotnet >/dev/null 2>&1; then
    echo "dotnet not found. Install the .NET 10 SDK." >&2
    exit 1
fi

cd "$CORE_DIR"
dotnet run --project QRScanner.Core.Tests/QRScanner.Core.Tests.csproj
