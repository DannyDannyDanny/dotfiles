# CLAUDE.md

Public, dev-machine dotfiles: macOS (nix-darwin) + WSL (NixOS) plus the shared
home-manager dev environment (shell, editor, terminal, dev tooling). The
homelab/fleet config (servers, clan, topology, secrets) lives in a **separate
private `homelab` repo** and is not part of this repo.

## Build commands

```bash
# macOS (from ~/dotfiles)
darwin-rebuild switch --flake .#Daniel-Macbook-Air

# WSL
sudo nixos-rebuild switch --flake ~/dotfiles#wsl

# Update flake + rebuild (fish alias: nixupdate)
cd ~/dotfiles && sudo nix flake update && sudo darwin-rebuild switch --flake ~/dotfiles#Daniel-Macbook-Air
```

## Rebuild protocol

**Never run rebuild commands automatically.** When changing Nix config files, always ask the user to rebuild first. Do not assume packages are available until after a successful rebuild.

## Flake architecture

- **Flake:** `flake.nix` at the repo root (flake-parts + `import-tree` of `flake-modules/`).
- **Inputs:** nixpkgs-unstable, nix-darwin, home-manager, nixos-wsl, vscode-server, zen-browser.
- **Hosts** (`nixos/hosts/`): `daniel-macbook-air.nix` (hostname `Daniel-Macbook-Air`, aarch64-darwin) and `wsl.nix` (x86_64-linux).
- **Home Manager dev env:** `nixos/home/danny/home.nix` (+ `nixos/neovim.nix`), wired via `lib/home-manager-user.nix`.
- **Shared modules:** `nixos/fish.nix` (fish + bash), `nixos/ollama.nix`.
- **Darwin config name:** `Daniel-Macbook-Air` (must match in rebuild commands).

The private `homelab` repo consumes this repo as a flake input to reuse the dev
env (`lib/home-manager-user.nix`) — no duplication.

## Repo rules

- **Public repo** — no keys, tokens, identifying secrets, or fleet topology. Use `scp` or config outside the repo.
- **SSH keys:** one key per purpose (e.g. `id_ed25519_github`). Use `IdentityFile` + `IdentitiesOnly yes` in `~/.ssh/config`. Keys stay outside the repo.
- **Fleet ZeroTier SSH aliases** come from a gitignored `lib/zerotier-ssh.local.nix` (host names + addresses are topology and stay out of this repo).

## Ollama

Custom nix-darwin module at `nixos/ollama.nix` (upstream PR not yet merged). Enabled on macOS via `nixos/hosts/daniel-macbook-air.nix`. Runs as a launchd user agent with `ollama serve`.

## Alacritty (macOS)

Terminal colors follow **System Settings → Appearance**: `programs.alacritty` imports `~/.config/alacritty/active-colors.toml`; `scripts/alacritty-sync-system-theme.sh` copies Catppuccin latte/mocha there when the OS mode changes. **nix-darwin** `launchd.user.agents.alacritty-system-theme` polls every 30s; **fish** runs the same script on interactive startup. After changing Nix, one `darwin-rebuild switch`. Details: `assets/alacritty/README.md`.

## Shell

Fish is the default shell. Bash auto-execs fish unless the parent process is already fish. Vi keybindings with fzf integration. Zoxide aliased to `cd`.
