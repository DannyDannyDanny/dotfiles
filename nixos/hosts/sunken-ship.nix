# NixOS server: hostname, user, SSH, auto-rebuild from dotfiles repo.
#
# One-time on server: clone repo to /etc/dotfiles (root needs git access).
# If private repo: use SSH (ssh:// or git@) and add root's key to GitHub, or use HTTPS + token.
# Then: sudo nixos-rebuild switch --flake /etc/dotfiles#sunken-ship
# If sudo git is not found: sudo nix run nixpkgs#git -- -C /etc/dotfiles pull origin main
# Timer runs every 15 min: git fetch, pull if origin/main changed, rebuild.
{ config, lib, pkgs, ... }:

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
    openssh.authorizedKeys.keys = [
      # Mac admin (~/.ssh/id_ed25519_sunken_ship on Daniel-Macbook-Air).
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW/akfIiVU5o63YrTAJVZhMj7kXfYHOnXDtlpVFW7pf danny@sunken-ship"
      # Self-loopback (used by clan ssh-ng:// during nix-copy-closure
      # back to this same host on `clan machines update`). Pubkey of the
      # /home/danny/.ssh/id_ed25519 that lives on this host.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB9t4YAaoHvVouqp+qyFOq8o3SAtXMiAmjF6J0ldyx4g danny@sunken-ship self"
    ];
  };

  # root needs the mac admin key so `clan machines update` can SSH to
  # root@<host> to upload SOPS keys (sops-install-secrets bootstrap).
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW/akfIiVU5o63YrTAJVZhMj7kXfYHOnXDtlpVFW7pf danny@sunken-ship"
  ];

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

  # Trust `danny` for Nix remote builds (so the mac can delegate
  # x86_64-linux builds here via ssh-ng://danny@sunken-ship-zt).
  nix.settings.trusted-users = [ "root" "danny" ];
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
  # bbbot's HTTP backend (port 8080) is intentionally NOT in the global
  # allowedTCPPorts — it's only allowed on the ZeroTier interface
  # (clan-managed name; matches anything starting with `zt`) so the
  # vps-relay Caddy can reach it via the ZT mesh. Same trick could lock
  # 4533 down later but Navidrome stays globally accessible for now (LAN
  # convenience).
  networking.firewall = {
    allowedTCPPorts = [ 7000 7001 7100 4533 ];
    allowedUDPPorts = [ 5353 6000 6001 7011 ];
    # 8080: bbbot HTTP backend. 8091: mulbo-server companion service.
    # Both ZT-only — see vps-relay.nix for reverse proxy if exposing
    # publicly later.
    interfaces."zt+".allowedTCPPorts = [ 8080 8091 ];
  };

  # Navidrome — self-hosted music streaming server (Subsonic API).
  # Music library: /srv/music (bind-mounted from /home/danny/music).
  # Web UI + Substreamer client on port 4533.
  services.navidrome = {
    enable = true;
    settings = {
      Address = "0.0.0.0";
      Port = 4533;
      MusicFolder = "/srv/music";
    };
  };

  # Navidrome's Subsonic API path field is tag-virtual; only the internal
  # SQLite has real fs paths. mulbo-server reads navidrome.db ro to
  # power /folders + POST /tracks resolution. UMask=0027 makes new DB
  # files (and WAL rotations) group-readable; the tmpfile rule fixes the
  # existing files written under the previous 0600 umask.
  systemd.services.navidrome.serviceConfig.UMask = lib.mkForce "0027";

  # Persist the bind mount so navidrome can read music outside ProtectHome.
  fileSystems."/srv/music" = {
    device = "/home/danny/music";
    fsType = "none";
    options = [ "bind" "ro" ];
  };

  # Navidrome is now reachable only over the ZeroTier mesh — see the
  # sunken-ship-zt SSH alias on the mac, or hit http://[fdd5:53a2:de33:
  # d269:6499:93d5:53a2:de33]:4533 directly from any ZT-joined device.
  # The Cloudflare Tunnel + its clan vars generator were retired in 4d;
  # delete the tunnel itself in the Cloudflare Zero Trust dashboard.

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
  # Code: https://github.com/DannyDannyDanny/bigbiggerbiggestbot cloned at /home/danny/tg_fitness_bot
  # Bot token: ~danny/.secrets/bigbiggerbiggestbot
  # Deployment: fitness-bot-pull timer below runs every 15 min, git pulls, restarts service on changes.
  #
  # Mini App URL is fronted by Caddy on the vps-relay host at
  # https://bbbot.dannydannydanny.me (VPS → ZeroTier → localhost:8080).
  # The bot's start.py honors WEBAPP_URL to skip starting its own
  # cloudflared Quick Tunnel when we've got a stable URL from the VPS.
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
    path = [ pythonEnv ];
    environment.WEBAPP_URL = "https://bbbot.dannydannydanny.me";
    # Bind dual-stack so the VPS Caddy can reach us over ZT IPv6.
    environment.API_HOST = "::";
    serviceConfig = {
      WorkingDirectory = "/home/danny/tg_fitness_bot";
      ExecStart = "${pythonEnv}/bin/python start.py";
      Restart = "on-failure";
      RestartSec = 10;
      User = "danny";
    };
  };

  # Pull fitness bot from GitHub and restart the service if the repo has new commits.
  # Code lives at /home/danny/tg_fitness_bot (git clone of DannyDannyDanny/bigbiggerbiggestbot).
  # workouts.db is gitignored — preserved across pulls.
  systemd.services.fitness-bot-pull = {
    description = "Pull fitness bot and restart service if repo changed";
    path = with pkgs; [ git systemd ];
    environment.GIT_CONFIG_COUNT = "1";
    environment.GIT_CONFIG_KEY_0 = "safe.directory";
    environment.GIT_CONFIG_VALUE_0 = "/home/danny/tg_fitness_bot";
    script = ''
      set -euo pipefail
      cd /home/danny/tg_fitness_bot
      git fetch origin
      if [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ]; then
        exit 0
      fi
      git pull origin main
      systemctl restart fitness-bot
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.fitness-bot-pull = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*-*-* *:07/15:00";  # every 15 minutes, offset from dotfiles-rebuild
    timerConfig.RandomizedDelaySec = "2min";
  };

  # Mulbo companion service (Phase 5: uploads + dedup index + folders).
  # Wire spec: ~danny/python-projects/20_mulbo/SERVER_API.md.
  # Bootstrap (one-time): git clone git@github.com:DannyDannyDanny/python-projects.git /home/danny/python-projects
  # (uses sunken-ship's id_ed25519 as a read-only deploy key on the repo)
  # ZT-only via the firewall rule above (port 8091). Runs as `danny` so
  # writes go through to /home/danny/music/mulbo-uploads, which Navidrome
  # reads via the existing /srv/music ro bind-mount with no mount changes.
  systemd.tmpfiles.rules = [
    "d /home/danny/music/mulbo-uploads 0755 danny users -"
    # One-time fix for the existing navidrome.db (+ WAL/SHM) created
    # under the old 0600 umask. UMask=0027 above keeps future writes
    # group-readable.
    "z /var/lib/navidrome/navidrome.db     0640 navidrome navidrome -"
    "z /var/lib/navidrome/navidrome.db-wal 0640 navidrome navidrome -"
    "z /var/lib/navidrome/navidrome.db-shm 0640 navidrome navidrome -"
  ];

  systemd.services.mulbo-server = let
    pythonEnv = pkgs.python312.withPackages (ps: with ps; [
      fastapi
      uvicorn
      python-multipart
    ]);
  in {
    description = "Mulbo companion service (uploads, dedup, folders)";
    after = [ "network-online.target" "navidrome.service" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      MULBO_UPLOADS_DIR   = "/home/danny/music/mulbo-uploads";
      MULBO_INDEX_DB      = "/var/lib/mulbo-server/index.db";
      MULBO_MUSIC_ROOT    = "/srv/music";  # for /folders fs walk
      MULBO_NAVIDROME_URL = "http://localhost:4533";
      MULBO_BIND_HOST     = "::";
      MULBO_BIND_PORT     = "8091";
      PYTHONUNBUFFERED    = "1";  # immediate journal output
    };
    serviceConfig = {
      WorkingDirectory   = "/home/danny/python-projects/20_mulbo";
      ExecStart          = "${pythonEnv}/bin/python mulbo_server/app.py";
      Restart            = "on-failure";
      RestartSec         = 5;
      User               = "danny";
      # Read-only access to navidrome.db (+WAL/SHM) — see UMask override
      # on the navidrome service above.
      SupplementaryGroups = [ "navidrome" ];
      StateDirectory     = "mulbo-server";  # /var/lib/mulbo-server, owned by danny
      # Navidrome credentials — file format: KEY=value lines.
      # Required keys: MULBO_NAVIDROME_USER, MULBO_NAVIDROME_PASS.
      # Created manually on sunken-ship (mode 600, owned by danny):
      #   echo -e "MULBO_NAVIDROME_USER=DannyDannyDanny\nMULBO_NAVIDROME_PASS=..." > ~/.secrets/mulbo-server-navidrome
      #   chmod 600 ~/.secrets/mulbo-server-navidrome
      EnvironmentFile    = "/home/danny/.secrets/mulbo-server-navidrome";
    };
  };

  # Pull mulbo (python-projects repo) and restart service if repo changed.
  # Repo lives at /home/danny/python-projects (must be cloned manually first
  # — see bootstrap note above). DBs/state live in /var/lib/mulbo-server,
  # not in the repo, so they survive pulls.
  systemd.services.mulbo-pull = {
    description = "Pull mulbo repo and restart mulbo-server if changed";
    path = with pkgs; [ git systemd ];
    environment = {
      GIT_CONFIG_COUNT   = "1";
      GIT_CONFIG_KEY_0   = "safe.directory";
      GIT_CONFIG_VALUE_0 = "/home/danny/python-projects";
    };
    script = ''
      set -euo pipefail
      cd /home/danny/python-projects
      git fetch origin
      if [ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ]; then
        exit 0
      fi
      git pull origin main
      systemctl restart mulbo-server
    '';
    serviceConfig.Type = "oneshot";
  };

  systemd.timers.mulbo-pull = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*-*-* *:11/15:00";  # every 15 min, offset from fitness-bot-pull and dotfiles-rebuild
    timerConfig.RandomizedDelaySec = "2min";
  };

  # One-shot backfill: walks Navidrome's media_file, computes
  # (sha256, chromaprint) per file, populates mulbo-server's tracks_index
  # with the corresponding navidrome_track_id. Idempotent — existing rows
  # left alone. Without this, /tracks/by-hash misses for every existing
  # offshore track and `mulbo reconcile-local` duplicates content.
  #
  # Trigger manually:   sudo systemctl start mulbo-server-backfill
  # Follow progress:    journalctl -fu mulbo-server-backfill
  systemd.services.mulbo-server-backfill = let
    pythonEnv = pkgs.python312.withPackages (ps: with ps; [ ]);
  in {
    description = "Backfill mulbo-server tracks_index from Navidrome catalog";
    after = [ "mulbo-server.service" ];
    requires = [ "mulbo-server.service" ];
    path = [ pkgs.chromaprint ];  # provides fpcalc
    environment = {
      MULBO_INDEX_DB     = "/var/lib/mulbo-server/index.db";
      MULBO_NAVIDROME_DB = "/var/lib/navidrome/navidrome.db";
      MULBO_MUSIC_ROOT   = "/srv/music";
      PYTHONUNBUFFERED   = "1";
    };
    serviceConfig = {
      Type             = "oneshot";
      WorkingDirectory = "/home/danny/python-projects/20_mulbo";
      ExecStart        = "${pythonEnv}/bin/python mulbo_server/backfill.py";
      User             = "danny";
      SupplementaryGroups = [ "navidrome" ];   # ro access to navidrome.db
      StateDirectory   = "mulbo-server";       # so /var/lib/mulbo-server/index.db stays writable
      TimeoutSec       = "8h";                 # full backfill on 274 GB ≈ 1h, leave headroom
    };
  };

  # Auto-rebuild service/timer + safe.directory provided by the
  # shared dotfiles-rebuild NixOS module (see nixos/modules/dotfiles-rebuild.nix).
}
