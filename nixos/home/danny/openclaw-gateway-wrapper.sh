#!/usr/bin/env bash
# Load OPENCLAW_GATEWAY_TOKEN from a file and exec the real gateway.
# Install: token in ~/.secrets/openclaw-gateway-token (one line, no newline).
set -euo pipefail
TOKEN_FILE="${OPENCLAW_GATEWAY_TOKEN_FILE:-$HOME/.secrets/openclaw-gateway-token}"
if [ -f "$TOKEN_FILE" ]; then
  export OPENCLAW_GATEWAY_TOKEN=$(cat "$TOKEN_FILE")
fi
exec "$@"
