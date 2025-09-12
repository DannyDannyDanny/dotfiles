# Alacritty Theme Synchronization

This directory contains the theme synchronization system for Alacritty that automatically switches between Catppuccin light and dark themes based on your macOS system theme.

## Files

- `catppuccin-light.yml` - Catppuccin Latte (light) theme colors
- `catppuccin-dark.yml` - Catppuccin Mocha (dark) theme colors
- `README.md` - This documentation

## Scripts

The theme synchronization scripts are located in `/scripts/`:

- `detect-system-theme.sh` - Detects current macOS system theme (light/dark)
- `sync-alacritty-theme.sh` - Syncs Alacritty config with current system theme
- `monitor-theme-changes.sh` - Continuously monitors for theme changes
- `setup-alacritty-theme-sync.sh` - Setup script for initial configuration

## Setup

1. Run the setup script:
   ```bash
   ./scripts/setup-alacritty-theme-sync.sh
   ```

2. Choose your preferred method for automatic theme switching:

### Option 1: Manual Sync
Run the sync script whenever you want to update the theme:
```bash
./scripts/sync-alacritty-theme.sh
```

### Option 2: Background Monitoring
Run the monitor script in the background:
```bash
./scripts/monitor-theme-changes.sh &
```

### Option 3: LaunchAgent (Recommended)
Install as a system service that runs automatically:
```bash
cp assets/launchd/com.user.alacritty-theme-sync.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.user.alacritty-theme-sync.plist
```

### Option 4: Shell Integration
Add to your Fish shell configuration:
```bash
echo 'source /Users/danny/dotfiles/scripts/sync-alacritty-theme.sh' >> ~/.config/fish/config.fish
```

## How It Works

1. The system detects your current macOS theme using `defaults read -g AppleInterfaceStyle`
2. Based on the theme, it applies the appropriate Catppuccin color scheme:
   - **Light theme** → Catppuccin Latte
   - **Dark theme** → Catppuccin Mocha
3. The Alacritty configuration is updated with the new colors
4. Running Alacritty instances are restarted to apply the new theme

## Theme Colors

### Catppuccin Latte (Light)
- Background: `#eff1f5` (base)
- Foreground: `#4c4f69` (text)
- Accent colors optimized for light backgrounds

### Catppuccin Mocha (Dark)
- Background: `#1e1e2e` (base)
- Foreground: `#cdd6f4` (text)
- Accent colors optimized for dark backgrounds

## Troubleshooting

### Theme not updating
- Check if Alacritty config file exists and is writable
- Verify the theme detection script works: `./scripts/detect-system-theme.sh`
- Check logs in `/tmp/alacritty-theme-sync.log`

### LaunchAgent not working
- Check if the plist file is in the correct location
- Verify permissions: `ls -la ~/Library/LaunchAgents/`
- Check launchctl status: `launchctl list | grep alacritty`

### Manual theme override
If you want to manually set a theme regardless of system setting:
```bash
# Force light theme
ALACRITTY_THEME=light ./scripts/sync-alacritty-theme.sh

# Force dark theme  
ALACRITTY_THEME=dark ./scripts/sync-alacritty-theme.sh
```

## Integration with NixOS

The NixOS configuration in `nixos/home/danny/home.nix` provides the base Alacritty configuration. The theme sync scripts work on top of this configuration, dynamically updating the colors section while preserving all other settings.

## Customization

To customize the themes:

1. Edit the color values in `catppuccin-light.yml` or `catppuccin-dark.yml`
2. Run the sync script to apply changes
3. The changes will persist until the next theme switch

For more advanced customization, you can modify the sync script to use different theme files or add additional theme variants.
