#!/bin/bash
# Back-compat wrapper: sync Alacritty + nvim marker from macOS appearance.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/alacritty-sync-system-theme.sh"
