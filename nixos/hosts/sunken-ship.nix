# NixOS server: hostname, user, SSH, auto-rebuild from dotfiles repo.
#
# One-time on server: clone repo to /etc/dotfiles (root needs git access).
# If private repo: use SSH (ssh:// or git@) and add root's key to GitHub, or use HTTPS + token.
# Then: sudo nixos-rebuild switch --flake /etc/dotfiles/nixos#sunken-ship
# If sudo git is not found: sudo nix run nixpkgs#git -- -C /etc/dotfiles pull origin main
# Timer runs every 15 min: git fetch, pull if origin/main changed, rebuild.
{ config, lib, pkgs, ... }:

let
  dotfilesDir = "/etc/dotfiles";
  flakeRef = "${dotfilesDir}/nixos#sunken-ship";
in
{
  imports = [ ./sunken-ship-hardware.nix ];

  networking.hostName = "sunken-ship";
  # No networks defined => uses /etc/wpa_supplicant.conf on the server
  networking.wireless.enable = true;
  time.timeZone = "Europe/Copenhagen";

  boot.kernelParams = [ "consoleblank=60" ];  # blank TTY after 60s to reduce burn-in

  # Turn off panel backlight after boot so the screen actually dims (consoleblank only blanks framebuffer).
  # At the console, run: brightnessctl set 100%  (or `brightnessctl max`) to restore brightness.
  systemd.services.server-backlight-off = {
    description = "Turn off panel backlight after console idle (reduce burn-in)";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.coreutils}/bin/sleep 65
      for d in /sys/class/backlight/*; do
        [ -f "$d/brightness" ] && echo 0 > "$d/brightness" 2>/dev/null || true
      done
    '';
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";

  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" ];  # video: backlight control via sysfs / brightnessctl
    # SSH keys: push via scp, don't commit. NixOS does not manage authorized_keys so scp'd keys persist.
    # Example: scp ~/.ssh/id_ed25519_sunken_ship.pub danny@server:/tmp/ then on server: mkdir -p ~/.ssh; cat /tmp/*.pub >> ~/.ssh/authorized_keys
  };

  # Key-only auth; no password or keyboard-interactive.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    # Optionally restrict to LAN: settings.ListenAddress = "10.0.0.1"; or similar.
  };

  # Passwordless sudo for wheel.
  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = with pkgs; [
    git # clone/bootstrap and dotfiles-rebuild timer
    brightnessctl # manual backlight; replaces removed `light` from nixpkgs
    uxplay # AirPlay mirroring receiver
  ];

  # Avahi (mDNS) — required for AirPlay discovery.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = { enable = true; userServices = true; };
  };

  # Open firewall for AirPlay (mDNS + UxPlay default ports).
  networking.firewall = {
    allowedTCPPorts = [ 7000 7001 7100 ];
    allowedUDPPorts = [ 5353 6000 6001 7011 ];
  };

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
