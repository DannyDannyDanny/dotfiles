# Minimal NixOS config for disko-install (new servers).
# Hostname and WiFi networks are overridden at install time via:
#   disko-install --system-config '{"networking":{"hostName":"my-server"},...}'
# No host-specific hardware import; filesystems and LUKS come from disko-server.nix.
{ config, lib, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = lib.mkDefault "nixos";  # Overridden by --system-config at install
  networking.wireless.enable = true;
  # networks."SSID".psk set via --system-config or imperative.conf after boot

  time.timeZone = "Europe/Copenhagen";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";

  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # SSH keys: scp pubkey to server after install, then cat >> ~/.ssh/authorized_keys
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = [ pkgs.git ];
}
