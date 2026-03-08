# Custom minimal NixOS installer ISO for server installs (disko-install).
# Optional: add nixos/installer-wifi.nix (gitignored) to the flake modules to
# preconfigure live-system WiFi so the installer can reach the network.
{ config, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];

  # Kernel modules for typical server WiFi (Intel). Add others if needed for your hardware.
  boot.kernelModules = [ "iwlwifi" ];
  boot.extraModulePackages = [ ];
}
