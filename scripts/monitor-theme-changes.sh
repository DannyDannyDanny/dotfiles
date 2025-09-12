#!/bin/bash

# Monitor system theme changes and sync Alacritty theme
# This script runs continuously and only updates Alacritty when the theme changes

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync-alacritty-theme.sh"

# State file to track the last known theme
STATE_FILE="/tmp/alacritty-theme-state"

# Function to get current theme
get_current_theme() {
    "$SCRIPT_DIR/detect-system-theme.sh"
}

# Function to get last known theme
get_last_theme() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo ""
    fi
}

# Function to save current theme
save_theme() {
    echo "$1" > "$STATE_FILE"
}

# Initial sync
echo "Starting Alacritty theme monitor..."
CURRENT_THEME=$(get_current_theme)
echo "Current theme: $CURRENT_THEME"

# Run initial sync
"$SYNC_SCRIPT"
save_theme "$CURRENT_THEME"

# Monitor for changes
while true; do
    sleep 5  # Check every 5 seconds
    
    NEW_THEME=$(get_current_theme)
    LAST_THEME=$(get_last_theme)
    
    if [ "$NEW_THEME" != "$LAST_THEME" ]; then
        echo "Theme changed from '$LAST_THEME' to '$NEW_THEME'"
        "$SYNC_SCRIPT"
        save_theme "$NEW_THEME"
    fi
done
