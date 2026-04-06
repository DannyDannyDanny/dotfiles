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
  programs.nix-ld.enable = true;  # run dynamically linked binaries (e.g. Claude Code remote CLI)
  system.stateVersion = "24.11";

  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" ];  # video: backlight; audio: sound devices
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
    alsa-utils # aplay, amixer, arecord for audio debugging
  ];

  # Avahi (mDNS) — required for AirPlay discovery.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = { enable = true; userServices = true; };
  };

  # Open firewall for AirPlay (mDNS + UxPlay default ports) + Navidrome.
  networking.firewall = {
    allowedTCPPorts = [ 7000 7001 7100 4533 ];
    allowedUDPPorts = [ 5353 6000 6001 7011 ];
  };

  # Navidrome — self-hosted music streaming server (Subsonic API).
  # Music library: /home/danny/music
  # Web UI + Substreamer client on port 4533.
  services.navidrome = {
    enable = true;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/home/danny/music";
    };
  };
  users.users.navidrome.extraGroups = [ "users" ];

  # UxPlay AirPlay receiver — audio-only, outputs directly to Scarlett Solo via ALSA.
  # Runs as a system service (no PipeWire needed on a headless server).
  systemd.services.uxplay = {
    description = "UxPlay AirPlay receiver";
    after = [ "network-online.target" "avahi-daemon.service" ];
    wants = [ "network-online.target" "avahi-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = ''${pkgs.uxplay}/bin/uxplay -n sunken-ship -p -vs 0 -as "audioconvert ! audioresample ! alsasink device=plughw:USB,0 buffer-time=200000"'';
      Restart = "on-failure";
      RestartSec = 5;
      User = "danny";
      SupplementaryGroups = [ "audio" ];
    };
  };

  # BigBiggerBiggestBot — Telegram fitness tracker with Mini App.
  # Code deployed separately via rsync (private repo, not referenced here).
  # Bot token: ~danny/.secrets/bigbiggerbiggestbot
  systemd.services.fitness-bot = let
    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      python-telegram-bot
      python-dotenv
      aiohttp
    ]);
  in {
    description = "BigBiggerBiggestBot Telegram fitness tracker";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pythonEnv pkgs.cloudflared ];
    serviceConfig = {
      WorkingDirectory = "/home/danny/tg_fitness_bot";
      ExecStart = "${pythonEnv}/bin/python start.py";
      Restart = "on-failure";
      RestartSec = 10;
      User = "danny";
    };
  };

  # Pull dotfiles and rebuild if the repo has new commits.
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
