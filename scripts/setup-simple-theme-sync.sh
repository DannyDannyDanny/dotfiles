#!/bin/bash
# One-shot sync of Alacritty palette + nvim marker from current macOS appearance.
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Syncing from system appearance..."
"$SCRIPT_DIR/alacritty-sync-system-theme.sh"
echo ""
echo "Done. Alacritty reloads colors automatically if live_config_reload is enabled."
echo "A LaunchAgent (nix-darwin: launchd.user.agents.alacritty-system-theme) runs this every 30s."
