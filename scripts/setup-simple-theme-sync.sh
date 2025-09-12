#!/bin/bash

# Simple setup for Alacritty theme synchronization
# This creates the theme file and rebuilds the Nix configuration

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Setting up simple Alacritty theme synchronization..."

# Run the theme sync script to create the initial theme file
echo "Detecting current system theme..."
"$SCRIPT_DIR/sync-alacritty-theme.sh"

echo ""
echo "Setup complete!"
echo ""
echo "To apply the theme to Alacritty, run:"
echo "  cd nixos && sudo darwin-rebuild switch --flake .#Daniel-Macbook-Air"
echo ""
echo "To sync themes when your system theme changes:"
echo "  $SCRIPT_DIR/sync-alacritty-theme.sh && cd nixos && sudo darwin-rebuild switch --flake .#Daniel-Macbook-Air"
echo ""
echo "For automatic theme switching, you can set up a LaunchAgent or"
echo "run the sync script manually when needed."
