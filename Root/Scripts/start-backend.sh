#!/usr/bin/env bash
# Starts PostgreSQL (Postgres.app), the ProductApi on the LAN, and a public
# Cloudflare quick tunnel. Prints the public HTTPS URL to use for the app.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$HOME/toolchains}"
API_DIR="$REPO_ROOT/Projects/Backend/ProductApi"
CLOUDFLARED="$TOOLCHAIN_DIR/bin/cloudflared"
CONNECTION_STRING="Host=localhost;Port=5432;Database=scanner;Username=scanner;Password=scanner"

if ! /Applications/Postgres.app/Contents/Versions/latest/bin/pg_isready -q 2>/dev/null; then
    echo "Starting Postgres.app..."
    open -a Postgres
    sleep 5
fi

echo "Starting ProductApi on 0.0.0.0:8080..."
(
    cd "$API_DIR"
    ConnectionStrings__Products="$CONNECTION_STRING" \
        ASPNETCORE_URLS="http://0.0.0.0:8080" \
        dotnet run
) &
API_PID=$!

cleanup() {
    kill "$API_PID" 2>/dev/null || true
    kill "$TUNNEL_PID" 2>/dev/null || true
}
TUNNEL_PID=""
trap cleanup EXIT INT TERM

for _ in $(seq 1 30); do
    if curl -s -m 2 http://127.0.0.1:8080/health >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if [[ ! -x "$CLOUDFLARED" ]]; then
    echo "cloudflared not found at $CLOUDFLARED." >&2
    echo "Download it from https://github.com/cloudflare/cloudflared/releases" >&2
    exit 1
fi

echo
echo "Starting public tunnel..."
"$CLOUDFLARED" tunnel --url http://127.0.0.1:8080 --no-autoupdate &
TUNNEL_PID=$!

echo
echo "Look for the https://*.trycloudflare.com URL above."
echo "Rebuild the app with that URL if it changed:"
echo "  cd Projects/MobileApp && flutter build apk \\"
echo "    --dart-define=API_BASE_URL=https://<your-tunnel>.trycloudflare.com/"
echo
echo "Press Ctrl-C to stop the API and tunnel."
wait
