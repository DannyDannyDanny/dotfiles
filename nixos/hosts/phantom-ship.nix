# NixOS server: SSH, auto-rebuild, NAT for rusty-anchor, OpenClaw gateway.
{ config, lib, pkgs, ... }:

let
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

  nixpkgs.config.permittedInsecurePackages = [ "openclaw-2026.3.12" "openclaw-2026.4.12" ];
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "claude-code" ];
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
    openai-whisper  # voice message transcription
    ffmpeg          # audio decoding for whisper
  ];

  # OpenClaw AI gateway — DISABLED. Replaced by Claude Code Channels below.
  # Config kept for easy rollback during validation; will be fully removed in a
  # follow-up commit once Channels is proven stable. Workspace state at
  # /var/lib/openclaw/ is preserved and also committed to vimwiki/openclaw/.
  # Secrets (not in repo): /etc/openclaw/telegram-bot-token, /etc/openclaw/env (ANTHROPIC_API_KEY)
  services.openclaw-gateway = {
    enable = false;
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

  # Claude Code Channels — Telegram bridge for @HarakatBot.
  # Uses claude.ai subscription auth (long-lived OAuth token) to bypass
  # the API rate limits OpenClaw was hitting.
  # Secret (not in repo): /etc/claude-channels/env (CLAUDE_CODE_OAUTH_TOKEN)
  # Plugin + pairing state lives at /home/danny/.claude/ (set up interactively).
  systemd.services.claude-channels = {
    description = "Claude Code Channels (Telegram bridge for @HarakatBot)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.claude-code pkgs.bun pkgs.git pkgs.util-linux ];
    environment = {
      HOME = "/home/danny";
    };
    serviceConfig = {
      Type = "simple";
      User = "danny";
      Group = "users";
      WorkingDirectory = "/home/danny";
      EnvironmentFile = "/etc/claude-channels/env";
      # claude needs a PTY; wrap with script(1). /dev/null discards the typescript.
      # Permission bypass lives in ~/.claude/settings.json (permissions.defaultMode)
      # — using the CLI flag triggers an interactive warning dialog at startup.
      ExecStart = ''${pkgs.util-linux}/bin/script -qfc "${pkgs.claude-code}/bin/claude --channels plugin:telegram@claude-plugins-official" /dev/null'';
      Restart = "always";
      RestartSec = 5;
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

  # Harden the openclaw-gateway systemd service (only when enabled).
  systemd.services.openclaw-gateway = lib.mkIf config.services.openclaw-gateway.enable {
    environment.GIT_CONFIG_GLOBAL = "/etc/openclaw/gitconfig";
    serviceConfig = {
      ProtectHome = "read-only";
      ProtectSystem = "strict";
      PrivateTmp = true;
      NoNewPrivileges = true;
      ReadWritePaths = [ "/var/lib/openclaw" "/etc/openclaw" ];
    };
  };

  # Auto-rebuild service/timer + safe.directory provided by the
  # shared dotfiles-rebuild NixOS module (see nixos/modules/dotfiles-rebuild.nix).
}
