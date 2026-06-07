# NixOS server on a ThinkPad X13 Gen 2 (Intel i5-1145G7, 16 GB).
# WiFi-only, headless, unattended auto-rebuild via clan dm-pull-deploy.
# No LUKS (mirrors sunken-ship) so reboots don't block on a passphrase.
#
# Blank-slate server for now — no application services. Give it a purpose
# later (just add services here and let dm-pull-deploy roll it out).
{ config, lib, pkgs, ... }:

{
  imports = [
    ./distant-shore-hardware.nix
    ../disko-distant-shore.nix
  ];

  boot.loader.systemd-boot.enable = true;
  # Secure Boot is enforced and the BIOS supervisor password is unknown, so
  # we can't enrol our own SB keys. Instead, shim (MS-signed) is placed on
  # the ESP and chain-loads systemd-boot; the NVRAM boot entry points at
  # shim. We manage that entry imperatively via efibootmgr; letting bootctl
  # touch EFI variables would replace it on every rebuild.
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot";  # matches disko ESP mountpoint

  # --- Secure Boot via shim + MOK (no firmware key enrolment possible) ------
  # The firmware trusts Microsoft-signed shim; shim trusts our enrolled MOK.
  # On every bootloader install we: (1) sign systemd-boot with the MOK and
  # drop it where shim chain-loads it (grubx64.efi), (2) install shim as the
  # firmware-booted binary (+ MokManager), (3) MOK-sign every kernel image
  # systemd-boot will hand off to (shim verifies them via the shim-lock
  # protocol). Re-runs on each nixos-rebuild so auto-deployed generations
  # stay bootable. Keys + shim live in /etc/secrets (outside the repo).
  boot.loader.systemd-boot.extraInstallCommands = ''
    # NixOS's bootloader-install systemd unit runs with a minimal PATH that
    # doesn't include coreutils, so use absolute paths for cp/mv.
    KEY=/etc/secrets/MOK.key
    CRT=/etc/secrets/MOK.crt
    sb() { ${pkgs.sbsigntool}/bin/sbsign --key "$KEY" --cert "$CRT" --output "$2" "$1"; }
    # systemd-boot -> shim's chain-load target
    sb /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/BOOT/grubx64.efi
    # shim (MS-signed) is what the firmware boots; MokManager beside it
    ${pkgs.coreutils}/bin/cp -f /etc/secrets/shimx64.efi /boot/EFI/BOOT/BOOTX64.EFI
    ${pkgs.coreutils}/bin/cp -f /etc/secrets/mmx64.efi  /boot/EFI/BOOT/mmx64.efi
    # MOK-sign each kernel (skip already-signed; never touch initrds)
    for k in /boot/EFI/nixos/*bzImage.efi; do
      [ -e "$k" ] || continue
      if ! ${pkgs.sbsigntool}/bin/sbverify --cert "$CRT" "$k" >/dev/null 2>&1; then
        ${pkgs.sbsigntool}/bin/sbsign --key "$KEY" --cert "$CRT" --output "$k.tmp" "$k" \
          && ${pkgs.coreutils}/bin/mv -f "$k.tmp" "$k"
      fi
    done
  '';

  networking.hostName = "distant-shore";
  # WiFi via NetworkManager. The wpa_supplicant stack hit two issues on this
  # box: (1) it strips CAP_CHOWN so wpa couldn't create its ctrl_interface,
  # and (2) dhcpcd didn't grab a lease after the (late) association at boot,
  # needing a manual restart — fatal for an unattended headless server. NM
  # handles association + DHCP atomically and connected first-try here.
  # The PSK stays out of the repo: it's substituted from /etc/secrets/nm.env
  # ($PSK_INTENO) into the declared profile at activation.
  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles.environmentFiles = [ "/etc/secrets/nm.env" ];
  networking.networkmanager.ensureProfiles.profiles."Inteno-89FE" = {
    connection = { id = "Inteno-89FE"; type = "wifi"; autoconnect = true; };
    wifi = { ssid = "Inteno-89FE"; mode = "infrastructure"; };
    wifi-security = { key-mgmt = "wpa-psk"; psk = "$PSK_INTENO"; };
    ipv4.method = "auto";
    ipv6.method = "auto";
  };
  hardware.enableRedistributableFirmware = true;  # iwlwifi for the Intel AX201 WiFi
  time.timeZone = "Europe/Copenhagen";

  # It's a laptop acting as a server: keep running with the lid shut.
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  # Reduce screen burn-in / power: blank the TTY after a minute.
  boot.kernelParams = [ "consoleblank=60" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.nix-ld.enable = true;  # run dynamically linked binaries (e.g. Claude Code remote CLI)
  nix.settings.trusted-users = [ "root" "danny" ];
  system.stateVersion = "25.11";

  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" ];
    openssh.authorizedKeys.keys = [
      # Mac admin / fleet key (~/.ssh/id_ed25519_sunken_ship) — the key the
      # Mac uses to reach the fleet; clan machines update relies on it.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW/akfIiVU5o63YrTAJVZhMj7kXfYHOnXDtlpVFW7pf danny@mac-admin"
      # Per-host key (~/.ssh/id_ed25519_distant_shore) — plain `ssh distant-shore`.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH61JOiOOPrAXekakAwTJg5yCSDfOIjlSvMYkpXrarAf distant-shore"
      # sunken-ship (dm-pull-deploy push node) — reach distant-shore over ZT.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB9t4YAaoHvVouqp+qyFOq8o3SAtXMiAmjF6J0ldyx4g danny@sunken-ship"
    ];
  };
  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.danny.openssh.authorizedKeys.keys;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  security.sudo.wheelNeedsPassword = false;

  # mokutil — manage MOK enrolment for the shim chain; sbsigntool — inspect
  # signatures on bootloader/kernel images when debugging.
  environment.systemPackages = with pkgs; [ git mokutil sbsigntool ];
}
