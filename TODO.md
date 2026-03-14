# TODO

1. **OpenClaw:** Remove the activation-backup + force overrides in `nixos/home/danny/openclaw.nix`. They work around "file is in the way" / "would be clobbered" when home-manager manages `~/.openclaw/`. Prefer fixing upstream (nix-openclaw) or a cleaner approach (e.g. deploy to a different path, or let the module handle existing files).

2. Create a setup/boot USB that: installs NixOS on the server with encryption and WiFi configured from the start; only required input is the server's name (e.g. sunken-ship).
   * I have a set wifi SSID/PSK, assume servers will start up and be able to reach this wifi.
   * I don't know how to go about the rest of this.

3. Encrypt sunken-ship (LUKS); update hardware/config for encrypted root and boot.

4. Host telegram bot once again (for what purpose?)
