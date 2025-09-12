#!/bin/bash

# Sync Alacritty theme with system theme
# This script detects the current system theme and updates Alacritty configuration accordingly

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Paths
THEME_DETECTION_SCRIPT="$SCRIPT_DIR/detect-system-theme.sh"
LIGHT_THEME="$DOTFILES_DIR/assets/alacritty/catppuccin-light.yml"
DARK_THEME="$DOTFILES_DIR/assets/alacritty/catppuccin-dark.yml"

# Alacritty config locations (try different possible locations)
ALACRITTY_CONFIG_LOCATIONS=(
    "$HOME/.config/alacritty/alacritty.yml"
    "$HOME/.alacritty.yml"
    "$HOME/Library/Application Support/Alacritty/alacritty.yml"
)

# Find the actual Alacritty config file
ALACRITTY_CONFIG=""
for location in "${ALACRITTY_CONFIG_LOCATIONS[@]}"; do
    if [ -f "$location" ]; then
        ALACRITTY_CONFIG="$location"
        break
    fi
done

if [ -z "$ALACRITTY_CONFIG" ]; then
    echo "Error: Could not find Alacritty configuration file"
    echo "Tried locations:"
    for location in "${ALACRITTY_CONFIG_LOCATIONS[@]}"; do
        echo "  - $location"
    done
    exit 1
fi

# Detect current system theme
if [ ! -f "$THEME_DETECTION_SCRIPT" ]; then
    echo "Error: Theme detection script not found at $THEME_DETECTION_SCRIPT"
    exit 1
fi

CURRENT_THEME=$("$THEME_DETECTION_SCRIPT")
echo "Current system theme: $CURRENT_THEME"

# Determine which theme file to use
if [ "$CURRENT_THEME" = "light" ]; then
    THEME_FILE="$LIGHT_THEME"
    THEME_NAME="Catppuccin Latte (Light)"
elif [ "$CURRENT_THEME" = "dark" ]; then
    THEME_FILE="$DARK_THEME"
    THEME_NAME="Catppuccin Mocha (Dark)"
else
    echo "Error: Unknown theme '$CURRENT_THEME'. Expected 'light' or 'dark'"
    exit 1
fi

if [ ! -f "$THEME_FILE" ]; then
    echo "Error: Theme file not found at $THEME_FILE"
    exit 1
fi

echo "Applying theme: $THEME_NAME"

# Create backup of current config
BACKUP_FILE="${ALACRITTY_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$ALACRITTY_CONFIG" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Create a temporary file for the new config
TEMP_CONFIG=$(mktemp)

# Function to merge theme colors into config
merge_theme() {
    local config_file="$1"
    local theme_file="$2"
    local output_file="$3"
    
    # Use yq to merge the theme colors into the config
    # If yq is not available, fall back to a simpler approach
    if command -v yq >/dev/null 2>&1; then
        # Use yq for proper YAML merging
        yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$config_file" "$theme_file" > "$output_file"
    else
        # Fallback: simple approach that replaces the colors section
        # This is less robust but works without yq
        awk '
        BEGIN { in_colors = 0; colors_printed = 0 }
        /^colors:/ { 
            in_colors = 1
            if (!colors_printed) {
                print "colors:"
                while ((getline line < "'"$theme_file"'") > 0) {
                    if (line ~ /^colors:/) continue
                    print "  " line
                }
                close("'"$theme_file"'")
                colors_printed = 1
            }
            next
        }
        in_colors && /^[a-zA-Z]/ && !/^  / { in_colors = 0 }
        !in_colors { print }
        ' "$config_file" > "$output_file"
    fi
}

# Merge the theme into the config
merge_theme "$ALACRITTY_CONFIG" "$THEME_FILE" "$TEMP_CONFIG"

# Replace the original config with the new one
mv "$TEMP_CONFIG" "$ALACRITTY_CONFIG"

echo "Alacritty theme synchronized successfully!"
echo "Config file: $ALACRITTY_CONFIG"
echo "Applied theme: $THEME_NAME"

# Optionally, send a signal to running Alacritty instances to reload config
# This requires Alacritty to be running with live config reload enabled
if command -v osascript >/dev/null 2>&1; then
    # Try to reload Alacritty config using AppleScript
    osascript -e 'tell application "Alacritty" to quit' 2>/dev/null || true
    # Restart Alacritty (you might want to adjust this based on your setup)
    open -a Alacritty 2>/dev/null || true
fi
