# Server installer USB (NixOS + LUKS)

Bootable USB that installs NixOS on a new server with disk encryption (LUKS). The install script handles partitioning, encryption, dotfiles cloning, SSH key setup, and hardware config generation. Only required inputs: hostname, LUKS passphrase, and target disk.

## Quick path (Ethernet server like phantom-ship)

### Prep (on sunken-ship or any Linux box)

1. Download the [NixOS minimal ISO](https://nixos.org/download.html#nixos-iso) on sunken-ship.
2. Plug in USB and write the ISO:
   ```bash
   # Find your USB device (e.g. /dev/sdc)
   lsblk
   sudo dd if=nixos-minimal-*.iso of=/dev/sdX status=progress bs=4M
   sync
   ```

### Install (on the new server)

3. Boot the new machine from USB, plug in Ethernet, verify connectivity (`ping 8.8.8.8`).
4. Start SSH on the live system so you can paste commands from your Mac:
   ```bash
   sudo systemctl start sshd
   sudo passwd nixos
   hostname -I   # note the IP
   ```
5. From your **Mac**, scp your SSH public key and SSH in:
   ```bash
   scp ~/.ssh/id_ed25519_phantom_ship.pub nixos@<IP>:/tmp/key.pub
   ssh nixos@<IP>
   ```
6. Run the bootstrap (one command):
   ```bash
   curl -sL https://raw.githubusercontent.com/DannyDannyDanny/dotfiles/main/scripts/bootstrap-install.sh | \
     INSTALLER_HOSTNAME=phantom-ship SSH_PUBKEY_FILE=/tmp/key.pub sudo -E bash
   ```
   This will prompt for: target disk, optional danny password, confirmation, and LUKS passphrase (twice: once for disko, once for post-install provisioning).

   The script automatically:
   - Partitions and encrypts the disk (LUKS + ext4)
   - Installs NixOS with the hostname
   - Clones dotfiles to `/etc/dotfiles`
   - Installs your SSH public key
   - Generates `phantom-ship-hardware.nix`

7. Reboot, remove USB, unlock LUKS.

### After first boot

8. SSH in: `ssh danny@phantom-ship`
9. First rebuild to switch from generic `server-install` to `phantom-ship` config:
   ```bash
   cd /etc/dotfiles && sudo nixos-rebuild switch --flake .#phantom-ship
   ```
10. Commit the generated `phantom-ship-hardware.nix` back to the repo.

## Environment variables

All optional; skip interactive prompts or add automation:

| Variable | Description |
|----------|-------------|
| `INSTALLER_HOSTNAME` | Skip hostname prompt |
| `INSTALLER_DISK` | Skip disk prompt (validated as block device) |
| `SSH_PUBKEY_FILE` | Path to `.pub` file; installed to danny's `authorized_keys` |
| `FLAKE_REF` | Override flake reference (default: auto-detect from repo) |
| `INSTALLER_SYSTEM_CONFIG_FILE` | JSON file merged into `--system-config` (e.g. WiFi config) |

## Option A: Official NixOS ISO (recommended)

Cannot build the custom ISO on macOS (x86_64-linux only). Use the official NixOS minimal ISO:

1. Download from [nixos.org](https://nixos.org/download.html#nixos-iso).
2. Write to USB from sunken-ship or any Linux box.
3. Boot, connect Ethernet, run bootstrap.

## Option B: Custom ISO (build on Linux only)

Adds WiFi kernel modules for servers that need WiFi on the live system.

### Build from sunken-ship

```bash
./scripts/build-installer-iso-on-server.sh
```

### Build directly on Linux

```bash
cd ~/dotfiles && nix build .#installer-iso
# Write to USB:
sudo dd if=result/iso/nixos-minimal-*.iso of=/dev/sdX status=progress bs=4M
```

## Live-system WiFi (optional, custom ISO only)

Create `nixos/installer-wifi.nix` (gitignored):

```nix
{
  networking.wireless.enable = true;
  networking.wireless.networks."YourSSID".psk = "your-password";
}
```

Add to flake's installer-iso modules, rebuild ISO on Linux.

## Installed-system WiFi (optional)

Pass a JSON file with wireless config:

```bash
sudo INSTALLER_SYSTEM_CONFIG_FILE=/path/to/wifi.json INSTALLER_HOSTNAME=my-server ./scripts/nixos-server-install.sh
```

## Manual install (without the script)

```bash
sudo nix run github:nix-community/disko/latest#disko-install -- \
  --flake 'path:/tmp/dotfiles#server-install' \
  --disk main /dev/sda \
  --system-config '{"networking":{"hostName":"my-server"}}'
```

## Summary

| Step | Action |
|------|--------|
| **Prep** | Download NixOS minimal ISO on sunken-ship, write to USB |
| **Boot** | Boot new server from USB, plug Ethernet |
| **Install** | `curl ... \| INSTALLER_HOSTNAME=phantom-ship SSH_PUBKEY_FILE=/tmp/key.pub sudo -E bash` |
| **Reboot** | Remove USB, unlock LUKS |
| **First rebuild** | `sudo nixos-rebuild switch --flake /etc/dotfiles#phantom-ship` |
| **Commit** | Push generated `phantom-ship-hardware.nix` to repo |
