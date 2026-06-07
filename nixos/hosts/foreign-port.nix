# NixOS laptop server. WiFi-only, headless, unattended auto-rebuild via
# clan dm-pull-deploy. No LUKS (mirrors sunken-ship) so reboots don't
# block on a passphrase.
#
# Blank-slate server for now — no application services. Give it a purpose
# later (just add services here and let dm-pull-deploy roll it out).
{ config, lib, pkgs, ... }:

{
  imports = [
    ./foreign-port-hardware.nix
    ../disko-foreign-port.nix
  ];

  boot.loader.systemd-boot.enable = true;
  # Firmware-locked Secure Boot: we can't enrol our own keys into the
  # firmware key DB, so a vendor-signed shim is the firmware-booted binary
  # and chain-loads a locally-signed systemd-boot + kernel. The NVRAM
  # entry points at shim; bootctl is kept away from EFI variables so
  # rebuilds don't clobber the entry.
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot";  # matches disko ESP mountpoint

  # --- Locally-signed boot chain --------------------------------------------
  # On every bootloader install: re-sign systemd-boot and every kernel
  # image, refresh the shim binary on the ESP, and place the helper binary
  # beside it. Re-runs on each nixos-rebuild so auto-deployed generations
  # stay bootable. Signing material lives in /etc/secrets, never the repo.
  boot.loader.systemd-boot.extraInstallCommands = ''
    # NixOS's bootloader-install systemd unit runs with a minimal PATH that
    # doesn't include coreutils, so use absolute paths for cp/mv.
    KEY=/etc/secrets/MOK.key
    CRT=/etc/secrets/MOK.crt
    sb() { ${pkgs.sbsigntool}/bin/sbsign --key "$KEY" --cert "$CRT" --output "$2" "$1"; }
    # systemd-boot -> shim's chain-load target
    sb /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/BOOT/grubx64.efi
    # shim is the firmware-booted binary; helper binary sits beside it
    ${pkgs.coreutils}/bin/cp -f /etc/secrets/shimx64.efi /boot/EFI/BOOT/BOOTX64.EFI
    ${pkgs.coreutils}/bin/cp -f /etc/secrets/mmx64.efi  /boot/EFI/BOOT/mmx64.efi
    # sign each kernel (skip if already signed; leave initrds untouched)
    for k in /boot/EFI/nixos/*bzImage.efi; do
      [ -e "$k" ] || continue
      if ! ${pkgs.sbsigntool}/bin/sbverify --cert "$CRT" "$k" >/dev/null 2>&1; then
        ${pkgs.sbsigntool}/bin/sbsign --key "$KEY" --cert "$CRT" --output "$k.tmp" "$k" \
          && ${pkgs.coreutils}/bin/mv -f "$k.tmp" "$k"
      fi
    done
  '';

  networking.hostName = "foreign-port";
  # WiFi via NetworkManager. The wpa_supplicant stack hit two issues on this
  # box: (1) it strips CAP_CHOWN so wpa couldn't create its ctrl_interface,
  # and (2) dhcpcd didn't grab a lease after the (late) association at boot,
  # needing a manual restart — fatal for an unattended headless server. NM
  # handles association + DHCP atomically and connected first-try here.
  # The PSK stays out of the repo: it's substituted from /etc/secrets/nm.env
  # ($PSK_INTENO) into the declared profile at activation.
  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles.environmentFiles = [ "/etc/secrets/nm.env" ];
  networking.networkmanager.ensureProfiles.profiles."Inteno-89FE-5GHz" = {
    connection = { id = "Inteno-89FE-5GHz"; type = "wifi"; autoconnect = true; };
    wifi = { ssid = "Inteno-89FE-5GHz"; mode = "infrastructure"; };
    wifi-security = { key-mgmt = "wpa-psk"; psk = "$PSK_INTENO"; };
    ipv4.method = "auto";
    ipv6.method = "auto";
  };
  hardware.enableRedistributableFirmware = true;  # WiFi firmware blobs
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
      # TODO: add a per-host key (~/.ssh/id_ed25519_foreign_port) for
      # plain `ssh foreign-port`. Generate when convenient.
      # sunken-ship (dm-pull-deploy push node) — reach foreign-port over ZT.
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

  # mokutil + sbsigntool — manage the shim trust chain and inspect signed
  # bootloader/kernel images when debugging.
  environment.systemPackages = with pkgs; [ git mokutil sbsigntool ];
}
