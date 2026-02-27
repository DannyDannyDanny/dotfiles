# NixOS server: hostname, user, SSH, auto-rebuild from dotfiles repo.
#
# One-time on server: clone repo to /etc/dotfiles (root needs git access).
# If private repo: use SSH (ssh:// or git@) and add root's key to GitHub, or use HTTPS + token.
# Then: sudo nixos-rebuild switch --flake /etc/dotfiles/nixos#nixos-server
# Timer runs every 15 min: git fetch, pull if origin/main changed, rebuild.
{ config, lib, pkgs, ... }:

let
  dotfilesDir = "/etc/dotfiles";
  flakeRef = "${dotfilesDir}/nixos#nixos-server";
in
{
  imports = [ ./nixos-server-hardware.nix ];

  networking.hostName = "nixos-server";
  time.timeZone = "Europe/Copenhagen";

  boot.kernelParams = [ "consoleblank=60" ];  # blank TTY after 60s to reduce burn-in

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";

  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # SSH keys: push via scp, don't commit. NixOS does not manage authorized_keys so scp’d keys persist.
    # Example: scp ~/.ssh/id_*_github.pub danny@server:/tmp/ then on server: mkdir -p ~/.ssh; cat /tmp/*.pub >> ~/.ssh/authorized_keys
  };

  services.openssh.enable = true;
  environment.systemPackages = [ pkgs.git ];  # for clone/bootstrap and timer

  # Pull dotfiles and rebuild if the repo has new commits.
  systemd.services.dotfiles-rebuild = {
    description = "Pull dotfiles and run nixos-rebuild if repo changed";
    path = with pkgs; [ git nix ];
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
