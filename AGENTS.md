# Agent Instructions

See **CLAUDE.md** for build commands, rebuild protocol, flake architecture, repo rules, and SSH key strategy. This file covers agent-specific operational details.

## Running commands on sunken-ship

From the Mac, agents can SSH to sunken-ship:

```bash
ssh -i ~/.ssh/id_ed25519_sunken_ship danny@sunken-ship 'hostname; ip addr'
```

Rebuild on the server: `ssh ... 'cd /etc/dotfiles/nixos && sudo nixos-rebuild switch --flake .#sunken-ship'`. The server has WiFi; it remains reachable when ethernet is unplugged.

## Server installer USB (new machines only)

Build from **Linux**: `cd ~/dotfiles/nixos && nix build .#installer-iso` (x86_64-linux only; cannot build on macOS). Or use official NixOS minimal ISO, write to USB, boot server, clone repo, run [scripts/nixos-server-install.sh](scripts/nixos-server-install.sh). See [docs/server-installer-usb.md](docs/server-installer-usb.md). Optional live WiFi: add `nixos/installer-wifi.nix` (gitignored) when building custom ISO on Linux.

## Learnings (NixOS server)

- Minimal ISO: use Ethernet or the graphical installer (Wi‑Fi on minimal is fiddly).
- Server hardware: stub in repo; user replaces with `nixos-generate-config --show-hardware-config` from the server.
- Root password: console only; set danny's password as root once for sudo.
- SSH keys: use actual key names on the machine (e.g. `id_ed25519_github`), not assumed `id_ed25519`.
