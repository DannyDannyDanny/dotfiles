# Alacritty Theme Synchronization

Simple theme synchronization for Alacritty that automatically switches between Catppuccin light and dark themes based on your macOS system theme.

**This solution uses Nix conditional configuration - no complex scripts or wrappers needed!**

## How It Works

1. The system detects your current macOS theme using `defaults read -g AppleInterfaceStyle`
2. The theme is written to `/Users/danny/.local/share/nvim_color_scheme`
3. Your NixOS configuration reads this file and conditionally applies:
   - **Light theme** → Catppuccin Latte
   - **Dark theme** → Catppuccin Mocha
4. Alacritty gets the correct theme colors through Nix configuration

## Setup

1. **Run the setup script:**
   ```bash
   ./scripts/setup-simple-theme-sync.sh
   ```

2. **Apply the theme to Alacritty:**
   ```bash
   home-manager switch
   ```

That's it! Your Alacritty will now use the correct theme based on your system theme.

## Usage

### Manual Theme Sync
When you change your system theme, run:
```bash
./scripts/sync-alacritty-theme.sh && home-manager switch
```

### Automatic Theme Switching (Optional)
For automatic switching, you can set up a LaunchAgent:
```bash
cp assets/launchd/com.user.alacritty-theme-sync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.alacritty-theme-sync.plist
```

## Files

- `scripts/detect-system-theme.sh` - Detects current macOS system theme
- `scripts/sync-alacritty-theme.sh` - Updates the theme file that Nix reads
- `scripts/setup-simple-theme-sync.sh` - One-time setup script
- `nixos/home/danny/home.nix` - Contains the conditional Alacritty configuration

## Theme Colors

### Catppuccin Latte (Light)
- Background: `#eff1f5` (base)
- Foreground: `#4c4f69` (text)
- Accent colors optimized for light backgrounds

### Catppuccin Mocha (Dark)
- Background: `#1e1e2e` (base)
- Foreground: `#cdd6f4` (text)
- Accent colors optimized for dark backgrounds

## Integration with NixOS

The solution uses Nix's conditional configuration in `home.nix`:

```nix
colors = let
  systemThemeFile = "/Users/danny/.local/share/nvim_color_scheme";
  isLightTheme = builtins.pathExists systemThemeFile && 
                 builtins.readFile systemThemeFile == "light\n";
  
  lightColors = { /* Catppuccin Latte colors */ };
  darkColors = { /* Catppuccin Mocha colors */ };
in if isLightTheme then lightColors else darkColors;
```

This approach:
- ✅ Works with Spotlight/Applications folder launches
- ✅ No shell aliases or wrapper scripts needed
- ✅ Integrates cleanly with NixOS configuration
- ✅ Minimal complexity - just 3 simple scripts
- ✅ Uses the same theme file as your Neovim configuration