# NixOS server: bare config with SSH, auto-rebuild, Ethernet.
# Services (OpenClaw, etc.) to be added later.
{ config, lib, pkgs, ... }:

let
  dotfilesDir = "/etc/dotfiles";
  flakeRef = "${dotfilesDir}/nixos#phantom-ship";
in
{
  imports = [ ./phantom-ship-hardware.nix ];

  networking.hostName = "phantom-ship";
  networking.useDHCP = lib.mkDefault true;
  networking.wireless.enable = true;  # credentials in /etc/wpa_supplicant.conf (outside repo)

  # NAT: share WiFi internet to rusty-anchor over ethernet
  networking.nat = {
    enable = true;
    externalInterface = "wlp1s0";
    internalInterfaces = [ "enp0s31f6" ];
  };
  networking.interfaces.enp0s31f6.ipv4.addresses = [{
    address = "10.0.0.1";
    prefixLength = 24;
  }];
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "enp0s31f6";
      dhcp-range = "10.0.0.10,10.0.0.50,24h";
      dhcp-option = [ "3,10.0.0.1" "6,10.0.0.1" ];  # gateway + DNS
    };
  };
  networking.firewall.trustedInterfaces = [ "enp0s31f6" ];

  hardware.enableRedistributableFirmware = true;  # iwlwifi (Intel 8260) + GPU + BT firmware
  time.timeZone = "Europe/Copenhagen";

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.nix-ld.enable = true;  # run dynamically linked binaries (e.g. Claude Code remote CLI)
  system.stateVersion = "24.11";

  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "changeme";  # console fallback; change after first login
  };

  # Key-only auth; no password or keyboard-interactive.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Passwordless sudo for wheel.
  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = with pkgs; [
    git  # clone/bootstrap and dotfiles-rebuild timer
  ];

  # Pull dotfiles and rebuild if the repo has new commits.
  systemd.services.dotfiles-rebuild = {
    description = "Pull dotfiles and run nixos-rebuild if repo changed";
    path = with pkgs; [ git nix ];
    environment.GIT_CONFIG_COUNT = "1";
    environment.GIT_CONFIG_KEY_0 = "safe.directory";
    environment.GIT_CONFIG_VALUE_0 = dotfilesDir;
    script = ''
      set -euo pipefail
      cd ${dotfilesDir}
      git fetch origin
      if [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ]; then
        exit 0
      fi
      git pull origin main
      exec nixos-rebuild switch --flake ${flakeRef}
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.dotfiles-rebuild = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*-*-* *:00/15:00";  # every 15 minutes
    timerConfig.RandomizedDelaySec = "2min";
  };
}
