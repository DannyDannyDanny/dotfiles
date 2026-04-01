# TODO

- [ ] **USB installer**: Refine the installer USB workflow (`scripts/nixos-server-install.sh`, `disko-server.nix`, `installer-iso.nix`). Goal: boot USB, provide hostname, get a LUKS-encrypted NixOS server with WiFi ready to go.
- [ ] **Encrypt sunken-ship**: Currently running on plain ext4. Needs reinstall with LUKS via disko, or in-place migration (backup, reformat, restore).
- [ ] **Tailscale**: Investigate setting up Tailscale mesh VPN across devices (sunken-ship, Mac, iPhone). Would allow SSH, AirPlay, and Claude Code remote sessions from anywhere. Free tier, ~5 lines of NixOS config. See: https://tailscale.com
- [ ] **Server alerting**: Get notified when a server goes down (power loss, crash, etc). Options: simple ping-based cron on Mac sending macOS notifications, or lightweight uptime monitor (Uptime Kuma on one of the servers).
