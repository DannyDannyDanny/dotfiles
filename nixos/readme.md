Rebuild nixos and points to dotfiles dir:

```
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#macbookair
# or
sudo nixos-rebuild switch --flake ~/dotfiles/nixos#wsl
# or (macOS)
sudo -H nix run github:lnl7/nix-darwin -- switch --flake ~/dotfiles/nixos#Daniel-Macbook-Air
```

## Server (nixos-server)

One-time on the server (git is not installed until after the first rebuild, so use nix run to get git):

```bash
nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- clone https://github.com/DannyDannyDanny/dotfiles.git /tmp/dotfiles
sudo mv /tmp/dotfiles /etc/dotfiles
# Enable flakes for this run (needed if the current system config does not)
sudo nixos-rebuild switch --flake /etc/dotfiles/nixos#nixos-server --option accept-flake-config true
```
If that fails with "does not provide attribute ... nixos-rebuild", enable flakes for the Nix daemon via the current config (on NixOS, `/etc/nix/nix.conf` is often read-only), then build and switch manually.

**From your Mac:** push a config that enables flakes, then on the server copy it and rebuild:
```bash
scp nixos/server-configuration-with-flakes.nix danny@<server>:/tmp/configuration.nix
```
**On the server:**
```bash
sudo cp /tmp/configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch
```
Then build and switch to the flake:
```bash
sudo nix build /etc/dotfiles/nixos#nixosConfigurations.nixos-server.config.system.build.toplevel -o /tmp/nixos-result
sudo /tmp/nixos-result/bin/switch-to-configuration switch
```

Use `git@github.com:DannyDannyDanny/dotfiles.git` if the repo is private (clone as danny then `sudo mv` and `sudo chown -R root:root /etc/dotfiles`).

SSH keys for danny (not in repo): from your machine `scp ~/.ssh/*.pub danny@server:/tmp/`, then on server `mkdir -p ~/.ssh; cat /tmp/*.pub >> ~/.ssh/authorized_keys`.

After that, a timer pulls and rebuilds every 15 min when `main` changes. Config lives in `hosts/nixos-server.nix` and `hosts/nixos-server-hardware.nix`.

**Pull when git is not in PATH** (e.g. before first rebuild or when `sudo git` says "command not found"):
```bash
sudo nix run nixpkgs#git -- -C /etc/dotfiles pull origin main
```
Then run `sudo nixos-rebuild switch --flake /etc/dotfiles/nixos#nixos-server` as usual. After that, git is in the system profile; for manual pulls you can use `sudo /run/current-system/sw/bin/git -C /etc/dotfiles pull origin main` if `sudo git` still isn’t in PATH.
