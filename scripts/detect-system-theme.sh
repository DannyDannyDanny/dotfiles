#!/bin/bash

# Detect macOS system theme (light/dark mode)
# Returns "light" or "dark"

# Get the current appearance setting
appearance=$(defaults read -g AppleInterfaceStyle 2>/dev/null)

if [ "$appearance" = "Dark" ]; then
    echo "dark"
else
    echo "light"
fi
