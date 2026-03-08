# Server installer USB (NixOS + LUKS + WiFi)

Bootable USB that installs NixOS on a new server with disk encryption (LUKS) and optional WiFi from first boot. Only required input is the hostname (and LUKS passphrase when disko creates the volume). Existing hosts are not modified.

## Option A: Official NixOS ISO (works from macOS)

You **cannot** build the custom installer ISO on macOS (it is x86_64-linux only and `--system` is restricted). Use the official NixOS minimal ISO instead:

1. Download the [minimal ISO](https://nixos.org/download.html#nixos-iso) (e.g. `nixos-minimal-*-x86_64-linux.iso`).
2. Write it to your USB (on macOS: `diskutil unmountDisk diskN`, then `sudo dd if=path/to/nixos-minimal-*.iso of=/dev/rdiskN bs=4m`).
3. Boot the server from the USB. Attach Ethernet or use the **graphical** ISO if you need Wi‑Fi on the live system.
4. On the live system, clone this repo and run the install script (see [Install on the server](#install-on-the-server) below). The script runs `disko-install` and does LUKS + hostname; no custom ISO needed.

## Option B: Custom ISO (build on Linux only)

The custom ISO adds Wi‑Fi kernel modules and optional live Wi‑Fi; it must be built on **x86_64-linux** (or with a Nix remote builder configured for that system). Building on macOS will fail.

### Build from sunken-ship (one command from your Mac)

When the server is on the same network, run from the dotfiles repo:

```bash
./scripts/build-installer-iso-on-server.sh
```

This pushes the branch, SSHs to sunken-ship, clones the repo there, runs `nix build .#installer-iso`, and copies the ISO back to the current directory. Optional: `./scripts/build-installer-iso-on-server.sh sunken-ship /path/to/output`.

### Build directly on a Linux machine

From a Linux box (or on sunken-ship after SSH in):

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
3. Run **one** of the following (shortest first).

**Shortest — fetch and run (no clone step):**  
Exact URL (watch for typos: **.com** not .con, **usb** not ush, **DannyDannyDanny** with three capital Ds):

```bash
curl -sL https://raw.githubusercontent.com/DannyDannyDanny/dotfiles/server-installer-usb/scripts/bootstrap-install.sh | sudo bash
```

If you see `bash: 404: command not found`, the URL was wrong or the branch doesn’t exist. Check the URL, or verify first: `curl -sL "THE_URL_ABOVE" | head -1` should show `#!/bin/bash`, not HTML.

To type less, create a [git.io](https://git.io) short link once (paste the raw URL above), then on the machine run: `curl -sL https://git.io/YOUR_CODE | sudo bash`.

**Alternative — clone then run** (if you prefer not to pipe curl to bash):

```bash
nix run --extra-experimental-features "nix-command flakes" nixpkgs#git -- clone https://github.com/USER/REPO.git /tmp/dotfiles && cd /tmp/dotfiles && git checkout server-installer-usb && sudo ./scripts/nixos-server-install.sh
```

If you see `command not found` when running the script, use `sudo bash ./scripts/nixos-server-install.sh` instead of `sudo ./scripts/...`.

4. When prompted: enter **hostname** (e.g. `phantom-ship`), then **target disk** (default `/dev/sda`), then **y** to proceed. When disko creates the LUKS volume, enter your encryption passphrase.
5. When the script finishes, remove the USB and reboot. The new NixOS system will have LUKS root and the hostname you chose.

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
| **From macOS** | Use Option A: download official NixOS minimal ISO, write to USB, boot server, clone repo, run install script. |
| **From Linux** | Option B: `nix build .#installer-iso` in `nixos/`, then write `result/iso/*.iso` to USB. |
| Optional live WiFi | (Custom ISO only) Add `installer-wifi.nix` (gitignored), include in flake, rebuild on Linux. |
| Boot | Boot server from USB |
| Install | On live system: `curl -sL https://raw.githubusercontent.com/.../server-installer-usb/scripts/bootstrap-install.sh | sudo bash` (or clone then `sudo ./scripts/nixos-server-install.sh`) |
| Optional installed WiFi | Set `INSTALLER_SYSTEM_CONFIG_FILE` to a JSON file with wireless config |
| Reboot | Remove USB, reboot; set root password if needed, add SSH keys |
