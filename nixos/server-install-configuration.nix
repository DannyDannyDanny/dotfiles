# Minimal server config for NixOS install (copy to /mnt/etc/nixos/configuration.nix on live system)
{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos-server";
  time.timeZone = "Europe/Copenhagen";

  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # After install, add keys via scp (see server-quickstart or nixos-server.nix comment).
  };

  services.openssh.enable = true;
}
