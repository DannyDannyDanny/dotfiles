# Server installer USB (NixOS + LUKS + WiFi)

Bootable USB that installs NixOS on a new server with disk encryption (LUKS) and optional WiFi from first boot. Only required input is the hostname (and LUKS passphrase when disko creates the volume). Existing hosts are not modified.

## Build the ISO

From a machine that can build NixOS (e.g. your Mac with Nix, or a Linux box):

```bash
cd ~/dotfiles/nixos
nix build .#installer-iso
```

The image is at `result/iso/nixos-minimal-*.iso`. Write it to a USB stick (replace `sdX` with your device, e.g. `sda`):

```bash
# Linux
sudo dd if=result/iso/nixos-minimal-*.iso of=/dev/sdX status=progress
sync
```

On macOS, use the disk number (e.g. `4` for `disk4`):

```bash
sudo dd if=result/iso/nixos-minimal-*.iso of=/dev/rdisk4 bs=4m
diskutil eject disk4
```

Or adapt [scripts/make-ubuntu-usb.sh](../scripts/make-ubuntu-usb.sh) for the NixOS ISO path.

## Live-system WiFi (optional)

So the live system can reach the network (and fetch the flake) without Ethernet, add WiFi to the ISO at **build time**. Do not put SSID/PSK in the repo.

1. Create **`nixos/installer-wifi.nix`** (gitignored) with your network:

```nix
{
  networking.wireless.enable = true;
  networking.wireless.networks."YourSSID".psk = "your-password";
}
```

2. Add it to the flake for the installer ISO only. In `nixos/flake.nix`, change the `installer-iso` modules to:

```nix
installer-iso = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [ ./installer-iso.nix ./installer-wifi.nix ];  # add installer-wifi.nix
};
```

3. Ensure `nixos/installer-wifi.nix` is in `.gitignore`, then rebuild the ISO.

If you skip this, use Ethernet on the live system or the graphical NixOS installer to join Wi‑Fi, then run the install script.

## Install on the server

1. Boot the server from the USB.
2. If you did not bake WiFi into the ISO, attach Ethernet or (on graphical installer) join Wi‑Fi so the machine has network.
3. Clone this repo (or copy the install script onto the machine). For example:

```bash
nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- clone https://github.com/USER/dotfiles.git /tmp/dotfiles
cd /tmp/dotfiles
```

4. Run the install script (it will prompt for hostname and target disk):

```bash
sudo ./scripts/nixos-server-install.sh
```

The script uses the flake from the current repo by default (`path:$(pwd)/nixos`). To use the flake from GitHub instead:

```bash
sudo FLAKE_REF=github:USER/dotfiles ./scripts/nixos-server-install.sh
```

5. When disko creates the LUKS volume, enter the encryption passphrase when prompted.
6. When the script finishes, remove the USB and reboot. The new NixOS system will have LUKS root and the hostname you chose.

## WiFi on the installed system (optional)

To have WiFi configured from first boot (no manual step after reboot):

1. Create a JSON file **outside the repo** with the config to merge (hostname is set by the script from the prompt):

```json
{
  "networking": {
    "wireless": {
      "networks": {
        "YourSSID": { "psk": "your-password" }
      }
    }
  }
}
```

2. Copy that file onto the live system (e.g. put it on the USB or scp it). If the script is run with `jq` available and `INSTALLER_SYSTEM_CONFIG_FILE` set to that file, the script will merge it and set the hostname:

```bash
sudo INSTALLER_SYSTEM_CONFIG_FILE=/path/to/wifi-config.json ./scripts/nixos-server-install.sh
```

If you omit this, the installed system still has `networking.wireless.enable = true`. Add credentials after first boot (e.g. [imperative wpa_supplicant config](sunken-ship-wifi.md)).

## Manual install (without the script)

You can run disko-install yourself:

```bash
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake 'path:/tmp/dotfiles/nixos#server-install' \
  --disk main /dev/sda \
  --system-config '{"networking":{"hostName":"my-server"}}'
```

Adjust the flake path and `--system-config` (e.g. add WiFi) as needed.

## After install

- Add your SSH key: from your machine `scp ~/.ssh/id_ed25519_servers.pub danny@NEW-SERVER:/tmp/`, then on the server `mkdir -p ~/.ssh; cat /tmp/*.pub >> ~/.ssh/authorized_keys`.
- To switch this machine to another host config in the same flake (e.g. a full server profile), clone the repo on the new system and run `sudo nixos-rebuild switch --flake /path/to/nixos#other-host`.

## Summary

| Step | Action |
|------|--------|
| Build | `nix build .#installer-iso` in `nixos/` |
| Optional live WiFi | Add `installer-wifi.nix` (gitignored), include in flake, rebuild ISO |
| Write USB | `dd` or script to write `result/iso/*.iso` to USB |
| Boot | Boot server from USB |
| Install | Clone repo, run `sudo ./scripts/nixos-server-install.sh` (set `FLAKE_REF` if not from repo) |
| Optional installed WiFi | Set `INSTALLER_SYSTEM_CONFIG_FILE` to a JSON file with wireless config |
| Reboot | Remove USB, reboot; set root password if needed, add SSH keys |
