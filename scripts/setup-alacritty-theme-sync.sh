#!/bin/bash

# Setup script for Alacritty theme synchronization
# This script installs the necessary components to sync Alacritty with system theme

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

echo "Setting up Alacritty theme synchronization..."

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Error: This script is designed for macOS"
    exit 1
fi

# Check if Alacritty is installed
if ! command -v alacritty >/dev/null 2>&1; then
    echo "Warning: Alacritty is not installed or not in PATH"
    echo "Please install Alacritty first: brew install alacritty"
fi

# Create Alacritty config directory if it doesn't exist
ALACRITTY_CONFIG_DIR="$HOME/.config/alacritty"
mkdir -p "$ALACRITTY_CONFIG_DIR"

# Check if Alacritty config exists
ALACRITTY_CONFIG="$ALACRITTY_CONFIG_DIR/alacritty.yml"
if [ ! -f "$ALACRITTY_CONFIG" ]; then
    echo "Creating default Alacritty configuration..."
    cat > "$ALACRITTY_CONFIG" << 'EOF'
# Alacritty configuration
# This file will be automatically updated by the theme sync script

window:
  padding:
    x: 8
    y: 8
  dynamic_padding: true
  decorations: buttonless
  opacity: 0.95
  startup_mode: Fullscreen
  option_as_alt: Both

scrolling:
  history: 10000
  multiplier: 3

font:
  size: 13.0

cursor:
  style: Block
  unfocused_hollow: true

terminal:
  shell:
    program: /bin/fish

# Colors will be automatically managed by theme sync
colors:
  primary:
    background: '0x1e1e2e'
    foreground: '0xcdd6f4'
EOF
    echo "Created default Alacritty config at $ALACRITTY_CONFIG"
fi

# Test the theme detection script
echo "Testing theme detection..."
CURRENT_THEME=$("$SCRIPT_DIR/detect-system-theme.sh")
echo "Current system theme: $CURRENT_THEME"

# Test the sync script
echo "Testing theme synchronization..."
"$SCRIPT_DIR/sync-alacritty-theme.sh"

echo ""
echo "Setup complete! Here's what was configured:"
echo ""
echo "1. Theme detection script: $SCRIPT_DIR/detect-system-theme.sh"
echo "2. Theme sync script: $SCRIPT_DIR/sync-alacritty-theme.sh"
echo "3. Theme monitor script: $SCRIPT_DIR/monitor-theme-changes.sh"
echo "4. Alacritty config: $ALACRITTY_CONFIG"
echo ""
echo "To enable automatic theme switching, you have several options:"
echo ""
echo "Option 1 - Manual sync (run when needed):"
echo "  $SCRIPT_DIR/sync-alacritty-theme.sh"
echo ""
echo "Option 2 - Background monitoring (runs continuously):"
echo "  $SCRIPT_DIR/monitor-theme-changes.sh &"
echo ""
echo "Option 3 - LaunchAgent (automatic startup):"
echo "  cp $DOTFILES_DIR/assets/launchd/com.user.alacritty-theme-sync.plist ~/Library/LaunchAgents/"
echo "  launchctl load ~/Library/LaunchAgents/com.user.alacritty-theme-sync.plist"
echo ""
echo "Option 4 - Add to shell profile (runs on terminal startup):"
echo "  echo 'source $SCRIPT_DIR/sync-alacritty-theme.sh' >> ~/.config/fish/config.fish"
echo ""
echo "Current theme applied: $CURRENT_THEME"
