# NixOS server: SSH, auto-rebuild, NAT for rusty-anchor, OpenClaw gateway.
{ config, lib, pkgs, ... }:

let
  dotfilesDir = "/etc/dotfiles";
  flakeRef = "${dotfilesDir}/nixos#phantom-ship";

  # Telegram user ID(s) — gitignored, not committed to public repo.
  # Create openclaw-allow-from.nix with e.g.: [ 12345678 ]
  allowFromPath = ./openclaw-allow-from.nix;
  openclawAllowFrom = if builtins.pathExists allowFromPath then import allowFromPath else [ ];
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

  boot.kernelParams = [ "consoleblank=60" ];  # blank TTY after 60s to reduce burn-in

  # Turn off panel backlight after boot so the screen actually dims.
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
  time.timeZone = "Europe/Copenhagen";

  nixpkgs.config.permittedInsecurePackages = [ "openclaw-2026.3.12" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  programs.nix-ld.enable = true;  # run dynamically linked binaries (e.g. Claude Code remote CLI)
  system.stateVersion = "24.11";

  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    # Password is locked (key-only SSH). Use NixOS installer or recovery to reset if needed.
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
    git          # clone/bootstrap and dotfiles-rebuild timer
    nodejs       # npm for openclaw plugin installs
    python3      # node-gyp dependency for openclaw plugins
    wakeonlan    # wake rusty-anchor: wakeonlan 00:16:cb:87:20:ba
    bun          # runtime for claude-code channel plugins
    claude-code  # Claude Code CLI (channels replaces openclaw)
  ];

  # OpenClaw AI gateway — Telegram bot, Anthropic API.
  # Secrets (not in repo): /etc/openclaw/telegram-bot-token, /etc/openclaw/env (ANTHROPIC_API_KEY)
  services.openclaw-gateway = {
    enable = true;
    environmentFiles = [ "/etc/openclaw/env" ];
    servicePath = [ pkgs.git pkgs.nodejs pkgs.openai-whisper ];
    config = {
      gateway.mode = "local";
      channels.telegram = {
        tokenFile = "/etc/openclaw/telegram-bot-token";
        allowFrom = openclawAllowFrom;
      };
    };
  };

  # OpenClaw gateway needs write access to its config dir and repo clones.
  systemd.tmpfiles.rules = [
    "d /etc/openclaw 0775 root openclaw - -"
    "d /var/lib/openclaw/repos 0750 openclaw openclaw - -"
  ];

  # Git config for the openclaw user: credential helper reads PAT from file.
  # PAT (not in repo): /etc/openclaw/github-token (fine-grained, scoped to specific repos)
  environment.etc."openclaw/gitconfig" = {
    text = ''
      [user]
        name = OpenClaw Bot
        email = noreply@openclaw.local
      [credential "https://github.com"]
        helper = "!f() { echo username=x-access-token; echo password=$(cat /etc/openclaw/github-token); }; f"
      [safe]
        directory = /var/lib/openclaw/repos
    '';
    mode = "0644";
  };

  # Harden the openclaw-gateway systemd service.
  systemd.services.openclaw-gateway.environment.GIT_CONFIG_GLOBAL = "/etc/openclaw/gitconfig";
  systemd.services.openclaw-gateway.serviceConfig = {
    ProtectHome = "read-only";
    ProtectSystem = "strict";
    PrivateTmp = true;
    NoNewPrivileges = true;
    ReadWritePaths = [ "/var/lib/openclaw" "/etc/openclaw" ];
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
