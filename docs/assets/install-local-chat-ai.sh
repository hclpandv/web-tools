#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${HOME}/.local/share/local-chat-ai"
BIN_DIR="${HOME}/.local/bin"
PORT=8080
URL="https://hclpandv.github.io/web-tools/local-chat-ai"

# Check dependencies
if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: Python 3 is required."
    exit 1
fi

if command -v curl >/dev/null 2>&1; then
    DOWNLOAD="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOAD="wget"
else
    echo "Error: curl or wget is required."
    exit 1
fi

mkdir -p "$APP_DIR" "$BIN_DIR"

# Download the page
if [ "$DOWNLOAD" = "curl" ]; then
    curl -fsSL "$URL" -o "$APP_DIR/index.html"
else
    wget -q "$URL" -O "$APP_DIR/index.html"
fi

# Create the launcher
cat > "$BIN_DIR/local-chat-ai" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="${HOME}/.local/share/local-chat-ai"
PORT="${PORT:-8080}"

cd "$APP_DIR"

# Start a loopback-only HTTP server
python3 -m http.server "$PORT" --bind 127.0.0.1 &
SERVER_PID=$!

cleanup() {
    kill "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

URL="http://127.0.0.1:${PORT}/"

if command -v open >/dev/null 2>&1; then
    open "$URL"
elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL"
else
    echo "Open $URL in your browser"
fi

wait "$SERVER_PID"
LAUNCHER

chmod u+x "$BIN_DIR/local-chat-ai"

echo
echo "Local Chat AI installed!"
echo "Launch with: $BIN_DIR/local-chat-ai"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) echo "Optional: add $BIN_DIR to your PATH." ;;
esac
