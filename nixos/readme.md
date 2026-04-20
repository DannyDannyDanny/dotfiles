# NixOS modules

Host-specific NixOS and home-manager modules live under this dir:

- `hosts/<machine>.nix` + `hosts/<machine>-hardware.nix`
- `home/danny/home.nix` (home-manager)
- `fish.nix`, `neovim.nix`, `ollama.nix`, `installer-iso.nix`, `disko-server.nix`

The flake itself (`flake.nix`, `flake.lock`, `flake-modules/`, `lib/`, `modules/`, `sops/`, `vars/`) lives at the **repo root**, not here. See [CLAUDE.md](../CLAUDE.md) at the repo root for rebuild commands, clan.lol operations, and the `dotfiles-rebuild` timer.

## Quick rebuild reference

```bash
# macOS
cd ~/dotfiles && darwin-rebuild switch --flake .

# WSL
sudo nixos-rebuild switch --flake ~/dotfiles#wsl

# Servers (via clan from mac)
nix run git+https://git.clan.lol/clan/clan-core#clan-cli -- \
  machines update sunken-ship --flake ~/dotfiles
```

## Server bootstrap (one-time)

```bash
nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- \
  clone https://github.com/DannyDannyDanny/dotfiles.git /tmp/dotfiles
sudo mv /tmp/dotfiles /etc/dotfiles
sudo nixos-rebuild switch --flake /etc/dotfiles#sunken-ship \
  --option accept-flake-config true
```

If the daemon doesn't have flakes: copy [server-configuration-with-flakes.nix](server-configuration-with-flakes.nix) to `/etc/nixos/configuration.nix`, `sudo nixos-rebuild switch`, then build the flake.

SSH keys (not in repo): `scp ~/.ssh/*.pub danny@server:/tmp/`, then on server `mkdir -p ~/.ssh; cat /tmp/*.pub >> ~/.ssh/authorized_keys`. See [docs/ssh-and-secrets.md](../docs/ssh-and-secrets.md).

No git in PATH: `sudo nix run nixpkgs#git -- -C /etc/dotfiles pull origin main`.
