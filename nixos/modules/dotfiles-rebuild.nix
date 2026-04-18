# Shared auto-rebuild-from-git service for homelab hosts.
#
# Every 15 min: git fetch origin, fast-forward main, and if there were any
# new commits run nixos-rebuild switch against `<dotfilesDir>/nixos#<host>`.
#
# Assumes /etc/dotfiles is an already-cloned checkout of the dotfiles repo.
{ config, lib, pkgs, ... }:
let
  dotfilesDir = "/etc/dotfiles";
  flakeRef = "${dotfilesDir}/nixos#${config.networking.hostName}";
in {
  environment.systemPackages = [ pkgs.git ];

  # Trust /etc/dotfiles as root even though it's owned by `danny`.
  # nix/libgit2 reads safe.directory from /etc/gitconfig; the GIT_CONFIG_*
  # env vars on the service only affect the git CLI, not nix.
  programs.git.enable = true;
  programs.git.config.safe.directory = [ dotfilesDir ];

  systemd.services.dotfiles-rebuild = {
    description = "Pull dotfiles and run nixos-rebuild if repo changed";
    path = with pkgs; [ git nix nixos-rebuild ];
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
