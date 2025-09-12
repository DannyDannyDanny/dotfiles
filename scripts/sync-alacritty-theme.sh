#!/bin/bash

# Sync Alacritty theme with system theme
# This script detects the current system theme and updates the theme file that Nix reads

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Paths
THEME_DETECTION_SCRIPT="$SCRIPT_DIR/detect-system-theme.sh"
THEME_FILE="/Users/danny/.local/share/nvim_color_scheme"

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$THEME_FILE")"

# Detect current system theme
if [ ! -f "$THEME_DETECTION_SCRIPT" ]; then
    echo "Error: Theme detection script not found at $THEME_DETECTION_SCRIPT"
    exit 1
fi

CURRENT_THEME=$("$THEME_DETECTION_SCRIPT")
echo "Current system theme: $CURRENT_THEME"

# Write the theme to the file that Nix reads
echo "$CURRENT_THEME" > "$THEME_FILE"

echo "Theme file updated: $THEME_FILE"
echo "Run 'home-manager switch' to apply the new theme to Alacritty"