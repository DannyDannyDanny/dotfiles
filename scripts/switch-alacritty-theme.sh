#!/bin/bash

# Switch Alacritty theme by updating the Nix configuration
# This script changes the isLightTheme variable in home.nix and rebuilds

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
HOME_NIX="$DOTFILES_DIR/nixos/home/danny/home.nix"

# Check if home.nix exists
if [ ! -f "$HOME_NIX" ]; then
    echo "Error: home.nix not found at $HOME_NIX"
    exit 1
fi

# Function to switch to light theme
switch_to_light() {
    echo "Switching to light theme (Catppuccin Latte)..."
    sed -i '' 's/isLightTheme = false;/isLightTheme = true;/' "$HOME_NIX"
}

# Function to switch to dark theme
switch_to_dark() {
    echo "Switching to dark theme (Catppuccin Mocha)..."
    sed -i '' 's/isLightTheme = true;/isLightTheme = false;/' "$HOME_NIX"
}

# Function to show current theme
show_current() {
    if grep -q "isLightTheme = true" "$HOME_NIX"; then
        echo "Current theme: Light (Catppuccin Latte)"
    else
        echo "Current theme: Dark (Catppuccin Mocha)"
    fi
}

# Function to rebuild the configuration
rebuild() {
    echo "Rebuilding configuration..."
    cd "$DOTFILES_DIR/nixos"
    sudo darwin-rebuild switch --flake .#Daniel-Macbook-Air
}

# Main logic
case "${1:-}" in
    "light")
        switch_to_light
        rebuild
        ;;
    "dark")
        switch_to_dark
        rebuild
        ;;
    "toggle")
        if grep -q "isLightTheme = true" "$HOME_NIX"; then
            switch_to_dark
        else
            switch_to_light
        fi
        rebuild
        ;;
    "status"|"current")
        show_current
        ;;
    *)
        echo "Usage: $0 {light|dark|toggle|status}"
        echo ""
        echo "Commands:"
        echo "  light   - Switch to light theme (Catppuccin Latte)"
        echo "  dark    - Switch to dark theme (Catppuccin Mocha)"
        echo "  toggle  - Toggle between light and dark themes"
        echo "  status  - Show current theme"
        echo ""
        show_current
        exit 1
        ;;
esac
