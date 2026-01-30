# Agent Instructions

## Nix/Darwin Rebuilds

**IMPORTANT**: When making changes to Nix configuration files (e.g., `nixos/home/danny/home.nix`, `nixos/flake.nix`, etc.), **always ask the user to rebuild** before assuming packages are available.

To rebuild:
```bash
cd ~/dotfiles/nixos
darwin-rebuild switch --flake .
```

Do not automatically run rebuild commands - ask the user first.

