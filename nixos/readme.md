# NixOS flake

Rebuild from dotfiles dir:

```bash
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#macbookair
# or #wsl
# macOS: cd ~/dotfiles/nixos && darwin-rebuild switch --flake .
```

## Server (sunken-ship)

One-time bootstrap (no git until first rebuild):

```bash
nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- clone https://github.com/DannyDannyDanny/dotfiles.git /tmp/dotfiles
sudo mv /tmp/dotfiles /etc/dotfiles
sudo nixos-rebuild switch --flake /etc/dotfiles/nixos#sunken-ship --option accept-flake-config true
```

If the daemon doesn’t have flakes: copy [server-configuration-with-flakes.nix](server-configuration-with-flakes.nix) to `/etc/nixos/configuration.nix`, run `sudo nixos-rebuild switch`, then build and switch to the flake (see [server-quickstart.md](../server-quickstart.md) for SSH keys).

SSH keys (not in repo): `scp ~/.ssh/*.pub danny@server:/tmp/`, then on server `mkdir -p ~/.ssh; cat /tmp/*.pub >> ~/.ssh/authorized_keys`. See [docs/ssh-and-secrets.md](../docs/ssh-and-secrets.md).

Timer: every 15 min the server pulls and rebuilds when `main` changes. Config: `hosts/sunken-ship.nix`, `hosts/sunken-ship-hardware.nix`.

No git in PATH: `sudo nix run nixpkgs#git -- -C /etc/dotfiles pull origin main`.
