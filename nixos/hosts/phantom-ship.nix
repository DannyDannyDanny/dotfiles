# NixOS server: SSH, auto-rebuild, NAT for rusty-anchor, OpenClaw gateway.
{ config, lib, pkgs, ... }:

let
  # Telegram user ID(s) - gitignored, not committed to public repo.
  # Create openclaw-allow-from.nix with e.g.: [ 12345678 ]
  allowFromPath = ./openclaw-allow-from.nix;
  openclawAllowFrom = if builtins.pathExists allowFromPath then import allowFromPath else [ ];

  haraGmailMcp = pkgs.callPackage ../pkgs/hara-gmail-mcp { };
  haraMcpServersJson = builtins.toJSON {
    mcpServers = {
      gmail = {
        command = "${haraGmailMcp}/bin/hara-gmail-mcp";
        args = [ ];
        env = { };
      };
    };
  };
in
{
  imports = [
    ./phantom-ship-hardware.nix
    ../pkgs/hara-gmail-mcp/module.nix
  ];

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

  # KomTolk (:8080), Shelfish (:8081), Scuttle (:8082), Bananasimulator
  # (:8083) are reachable only over the ZeroTier mesh — the vps-relay
  # Caddy reverse-proxies into them. Same pattern as sunken-ship's bbbot.
  # Not in global allowedTCPPorts, so the WAN side stays closed.
  networking.firewall.interfaces."zt+".allowedTCPPorts = [ 8080 8081 8082 8083 ];

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
    openssh.authorizedKeys.keys = [
      # Mac admin (~/.ssh/id_ed25519_phantom_ship on Daniel-Macbook-Air).
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDNl6PrKcEhmYJVqSXNcFU6cba3neekLBGnQCkD7lWAc danny@phantom-ship"
      # Self-loopback (clan ssh-ng:// back to this host).
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPyEX8De/b+sMAxUZIqqiPphcrWCoAsN5p8gRFubzqvB danny@phantom-ship"
    ];
  };

  # root needs the mac admin key so `clan machines update` can SSH to
  # root@<host> for SOPS upload.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDNl6PrKcEhmYJVqSXNcFU6cba3neekLBGnQCkD7lWAc danny@phantom-ship"
  ];

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
      ExecStart = ''${pkgs.util-linux}/bin/script -qfc "${pkgs.claude-code}/bin/claude --channels plugin:telegram@claude-plugins-official --mcp-config /etc/hara/mcp-servers.json" /dev/null'';
      Restart = "always";
      RestartSec = 5;
    };
  };

  # OpenClaw gateway needs write access to its config dir and repo clones;
  # shelfish wants its DB outside the rsynced code dir.
  systemd.tmpfiles.rules = [
    "d /etc/openclaw 0775 root openclaw - -"
    "d /var/lib/openclaw/repos 0750 openclaw openclaw - -"
    "d /home/danny/.local/share/shelfish 0755 danny users - -"
    "d /home/danny/.local/share/scuttle 0755 danny users - -"
    "d /home/danny/.local/share/bananasimulator 0755 danny users - -"
    "d /home/danny/.local/share/komtolk 0755 danny users - -"
    "d /home/danny/.local/share/scuttle/tiles 0755 danny users - -"
  ];

  # Hara Gmail MCP server (path 1: IMAP+SMTP). Replaced by an OAuth2
  # Gmail+Calendar server in path 2.
  services.hara-gmail-mcp = {
    enable = true;
    package = haraGmailMcp;
    accounts = [
      {
        email = "powerhouseplayer@gmail.com";
        password_file = "/etc/openclaw/gmail-powerhouseplayer-app-password";
      }
      {
        email = "wildstylewarrior@gmail.com";
        password_file = "/etc/openclaw/gmail-wildstylewarrior-app-password";
      }
      {
        email = "danielth95@gmail.com";
        password_file = "/etc/openclaw/gmail-danielth95-app-password";
      }
    ];
  };

  # MCP server registry consumed by claude-channels via --mcp-config.
  environment.etc."hara/mcp-servers.json" = {
    text = haraMcpServersJson;
    mode = "0644";
  };

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

  # Shipyard — Telegram bot that lists Danny's mini-apps and collects feedback.
  # Code deployed out-of-band via rsync to /home/danny/shipyard/
  # (staying in-tree in ~/python-projects/26_shipyard/ until spun out to its own repo).
  # Bot token (not in repo): ~danny/.secrets/telegram-bot-token-shipyard
  # Data (feedback.jsonl, pointer cache): ~danny/.local/share/shipyard/
  systemd.services.shipyard = let
    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      python-telegram-bot
      httpx
    ]);
  in {
    description = "Shipyard Telegram bot (mini-app launcher + feedback)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pythonEnv ];
    environment = {
      SHIPYARD_BOT_TOKEN_FILE = "/home/danny/.secrets/telegram-bot-token-shipyard";
      # Owner-only commands (/admin, /grant, /revoke) — anyone else gets ignored.
      SHIPYARD_OWNER_ID = "66070351";  # @DannyDannyDanny
    };
    serviceConfig = {
      WorkingDirectory = "/home/danny/shipyard";
      ExecStart = "${pythonEnv}/bin/python bot.py";
      Restart = "on-failure";
      RestartSec = 10;
      User = "danny";
    };
  };

  # Shelfish — Goodreads-flavoured book club Mini App.
  # Public traffic comes through vps-relay's Caddy → ZeroTier → here.
  # See vps-relay.nix for the public-facing virtualHost. We never expose
  # this host's IP directly.
  # Code deployed out-of-band via rsync to /home/danny/shelfish/
  # (staying in-tree in ~/python-projects/27_shelfish/ until spun out).
  # Auth: validates Telegram WebApp initData against shipyard's bot token
  # (the bot that publishes shelfish via shipyard's project list).
  # DB lives outside the rsynced code dir so deploys don't clobber state.
  # (tmpfiles rule for the DB dir is bundled into the OpenClaw block above.)
  systemd.services.shelfish = let
    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      fastapi
      uvicorn
      httpx
      python-telegram-bot
    ]);
  in {
    description = "Shelfish FastAPI server (book club Mini App)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pythonEnv ];
    environment = {
      SHIPYARD_BOT_TOKEN_FILE = "/home/danny/.secrets/telegram-bot-token-shipyard";
      SH_DB_PATH = "/home/danny/.local/share/shelfish/shelfish.db";
    };
    serviceConfig = {
      WorkingDirectory = "/home/danny/shelfish";
      ExecStart = "${pythonEnv}/bin/python -m uvicorn server:app --host :: --port 8081";
      Restart = "on-failure";
      RestartSec = 10;
      User = "danny";
    };
  };

  # Scuttle — topdown tilt-to-move multiplayer Mini App.
  # Same vps-relay-fronted ZT path as shelfish; binds to :: so the
  # ZeroTier IPv6 address can reach it.
  # Code rsync'd from ~/python-projects/26_scuttle/ to /home/danny/scuttle/
  # DB at ~/.local/share/scuttle/scuttle.db.
  systemd.services.scuttle = let
    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      fastapi
      uvicorn
      httpx
      websockets
      python-telegram-bot
    ]);
  in {
    description = "Scuttle FastAPI + WebSocket game server (geo: Østerbro)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pythonEnv ];
    environment = {
      SHIPYARD_BOT_TOKEN_FILE = "/home/danny/.secrets/telegram-bot-token-shipyard";
      SC_DB_PATH = "/home/danny/.local/share/scuttle/scuttle.db";
      SC_TILES_DIR = "/home/danny/.local/share/scuttle/tiles";
    };
    serviceConfig = {
      WorkingDirectory = "/home/danny/scuttle";
      ExecStart = "${pythonEnv}/bin/python -m uvicorn server:app --host :: --port 8082";
      Restart = "on-failure";
      RestartSec = 10;
      User = "danny";
    };
  };

  # Bananasimulator — the actual project at https://bananasimulator.dannydannydanny.me
  # (was a placeholder in shipyard's apps.json for ages). You ARE a banana.
  # Code rsync'd from ~/python-projects/26_bananasimulator/ to /home/danny/bananasimulator/
  systemd.services.bananasimulator = let
    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      fastapi
      uvicorn
      httpx
      python-telegram-bot
    ]);
  in {
    description = "Bananasimulator FastAPI server";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pythonEnv ];
    environment = {
      SHIPYARD_BOT_TOKEN_FILE = "/home/danny/.secrets/telegram-bot-token-shipyard";
      BS_DB_PATH = "/home/danny/.local/share/bananasimulator/bananasimulator.db";
      BS_RIPE_MIN_PER_STAGE = "2";   # 2 min/stage → 30 min to compost in production
    };
    serviceConfig = {
      WorkingDirectory = "/home/danny/bananasimulator";
      ExecStart = "${pythonEnv}/bin/python -m uvicorn server:app --host :: --port 8083";
      Restart = "on-failure";
      RestartSec = 10;
      User = "danny";
    };
  };

  # KomTolk (formerly translate-platform) — Copenhagen translation gigs Mini App.
  # Code rsync'd from ~/python-projects/26_komtolk/ to /home/danny/komtolk/
  systemd.services.komtolk = let
    pythonEnv = pkgs.python3.withPackages (ps: with ps; [
      fastapi
      uvicorn
      httpx
      python-telegram-bot
    ]);
  in {
    description = "KomTolk FastAPI server (Copenhagen translation gigs)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pythonEnv ];
    environment = {
      SHIPYARD_BOT_TOKEN_FILE = "/home/danny/.secrets/telegram-bot-token-shipyard";
      KT_DB_PATH = "/home/danny/.local/share/komtolk/komtolk.db";
    };
    serviceConfig = {
      WorkingDirectory = "/home/danny/komtolk";
      ExecStart = "${pythonEnv}/bin/python -m uvicorn server:app --host :: --port 8080";
      Restart = "on-failure";
      RestartSec = 10;
      User = "danny";
    };
  };

  # Hara morning heartbeat — daily email check + Telegram good-morning ping.
  # Runs claude in print mode with the Gmail MCP, then sends output via Bot API.
  # Token lives in ~/.claude/channels/telegram/.env (managed by the telegram plugin).
  systemd.services.hara-heartbeat = {
    description = "Hara morning heartbeat (email check + Telegram ping)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ pkgs.claude-code pkgs.curl pkgs.jq ];
    environment = {
      HOME = "/home/danny";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "danny";
      Group = "users";
      WorkingDirectory = "/home/danny";
      EnvironmentFile = "/etc/claude-channels/env";
    };
    script = ''
      set -euo pipefail
      CHAT_ID="66070351"
      BOT_TOKEN=$(grep '^TELEGRAM_BOT_TOKEN=' /home/danny/.claude/channels/telegram/.env | cut -d= -f2-)
      MSG=$(${pkgs.claude-code}/bin/claude -p \
        "You are Hara, a concise cat-energy AI assistant. Read ~/.hara/HEARTBEAT.md. Check Gmail for all three accounts (danielth95, powerhouseplayer, wildstylewarrior) for urgent unread emails — security alerts, invoices, anything requiring a decision; skip newsletters and marketing. Compose a short message for Danny: flag urgent emails if any, otherwise just a brief check-in. One message, very short, cat energy." \
        --mcp-config /etc/hara/mcp-servers.json \
        2>/dev/null)
      ${pkgs.curl}/bin/curl -sf -X POST \
        "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
        -H "Content-Type: application/json" \
        -d "{\"chat_id\": $CHAT_ID, \"text\": $(echo "$MSG" | ${pkgs.jq}/bin/jq -Rs .)}" \
        > /dev/null
    '';
  };

  systemd.timers.hara-heartbeat = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "06,10,14,18:07";
      Timezone = "Europe/Copenhagen";
      Persistent = true;
    };
  };

  # Auto-rebuild service/timer + safe.directory provided by the
  # shared dotfiles-rebuild NixOS module (see nixos/modules/dotfiles-rebuild.nix).
}
