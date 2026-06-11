# TODO

- [ ] **USB installer**: Refine the installer USB workflow (`scripts/nixos-server-install.sh`, `disko-server.nix`, `installer-iso.nix`). Goal: boot USB, provide hostname, get a LUKS-encrypted NixOS server with WiFi ready to go.
- [ ] **Encrypt all servers**: LUKS everywhere, not just phantom-ship (the only one encrypted today, via `phantom-ship-hardware.nix`).
  - sunken-ship: plain ext4 — reinstall with LUKS via disko, or in-place migration (backup, reformat, restore).
  - vps-relay: `disko-cloud.nix` has no LUKS — Hetzner cloud needs remote unlock (initrd SSH) or stays unencrypted; decide.
  - foreign-port: `disko-foreign-port.nix` has no LUKS.
  - distant-shore: `disko-distant-shore.nix` has no LUKS — add before first install (machine still blocked on BIOS password anyway).
- [ ] **Server alerting**: Get notified when a server goes down (power loss, crash, etc). Options: simple ping-based cron on Mac sending macOS notifications, or lightweight uptime monitor (Uptime Kuma on one of the servers).
