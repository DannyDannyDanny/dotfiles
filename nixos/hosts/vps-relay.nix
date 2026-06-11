# Hetzner Cloud VPS — public reverse proxy into the clan.
#
# Role: terminates public TLS via Caddy + Let's Encrypt, reverse-proxies
# each declared subdomain over ZeroTier to the appropriate homelab host.
# No navidrome/bbbot data ever hits disk here; this box is a relay.
# Exception: the FTPS server (ftp.dannydannydanny.me) stores its files
# locally under /srv/ftp — FTP's separate data channel can't be relayed
# through Caddy like the HTTP vhosts.
{ config, lib, pkgs, ... }:
let
  # Fleet ZT IPv6 addresses — single source of truth in lib/zerotier-hosts.nix.
  zt = import ../../lib/zerotier-hosts.nix;
in
{
  imports = [ ../disko-cloud.nix ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Hetzner Cloud vServers boot in BIOS mode (confirmed via rescue:
  # /sys/firmware/efi doesn't exist, product_name=vServer). systemd-boot
  # is UEFI-only, so use GRUB/BIOS. disko's EF02 BIOS boot partition
  # already tells GRUB where to embed stage-1.5; we just enable grub +
  # set the install device list.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub.enable = lib.mkForce true;
  boot.loader.grub.efiSupport = lib.mkForce false;
  boot.loader.grub.devices = lib.mkForce [ "/dev/sda" ];
  # Ensure no default-set .device slips through and duplicates mirroredBoots.
  boot.loader.grub.device = lib.mkForce "nodev";

  # Hetzner Cloud cx23 uses QEMU virtio-scsi for the disk and virtio-net
  # for the NIC. Without these modules in initrd, the kernel can't find
  # the root partition and hangs during boot.
  boot.initrd.availableKernelModules = [
    "virtio_pci"
    "virtio_scsi"
    "virtio_net"
    "virtio_blk"
    "ata_piix"
    "sd_mod"
    "sr_mod"
  ];
  boot.kernelModules = [ "virtio_pci" "virtio_scsi" "virtio_net" ];

  # Cloud provisioners add the initial root SSH key via cloud-init or
  # equivalent; we don't run cloud-init. All config is baked at install.
  networking.hostName = "vps-relay";
  networking.useDHCP = lib.mkDefault true;
  time.timeZone = "Europe/Copenhagen";

  # --- User + SSH ------------------------------------------------------
  users.users.danny = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # Mac admin key (~/.ssh/id_ed25519_sunken_ship on the laptop — the
      # key the Mac uses to reach the fleet). Used for `clan machines
      # update vps-relay` from the Mac and at install via clan.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW/akfIiVU5o63YrTAJVZhMj7kXfYHOnXDtlpVFW7pf danny@mac-admin"
      # sunken-ship's own key, so the push node can SSH into vps-relay
      # over ZeroTier for mesh introspection / debugging.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB9t4YAaoHvVouqp+qyFOq8o3SAtXMiAmjF6J0ldyx4g danny@sunken-ship"
    ];
  };
  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.danny.openssh.authorizedKeys.keys;

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # --- Firewall --------------------------------------------------------
  # Public: 21 (FTPS control), 22 (SSH), 80 + 443 (Caddy).
  # ZT interface: trusted (set in the clan ZT module).
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 21 22 80 443 ];
  # FTP passive-mode data connections — must match pasv_min/max_port in
  # the vsftpd config below.
  networking.firewall.allowedTCPPortRanges = [ { from = 56000; to = 56010; } ];
  # CrowdSec Prometheus metrics — ZT-only so sunken-ship can scrape them.
  networking.firewall.interfaces."zt+".allowedTCPPorts = [ 6060 ];

  # fail2ban — public SSH gets brute-force probed within minutes of any
  # cloud VM being created. Ban offending IPs after a few failures.
  services.fail2ban = {
    enable = true;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      multipliers = "1 4 16 64 256";  # 1h, 4h, 16h, ~2.7d, ~10.7d
      maxtime = "30d";
    };
    jails.sshd.settings = {
      enabled = true;
      maxretry = 5;
      findtime = "10m";
    };
  };

  # Basic-auth gate hash for Grafana, kept out of the public repo as a
  # sops-encrypted clan var. Provide it once (any Linux box with the admin
  # key, or `clan vars set` from the mac):
  #   printf 'GRAFANA_BCRYPT=%s' "$(caddy hash-password --plaintext '<pw>')" \
  #     | clan vars set vps-relay grafana-basic-auth/auth
  # (var file is named "auth" not "env" — the repo .gitignore ignores env/)
  clan.core.vars.generators.grafana-basic-auth.files."auth" = { };

  # --- Caddy reverse proxy --------------------------------------------
  # Subdomains → clan backends over ZeroTier. IPs are sunken-ship's /
  # phantom-ship's ZT IPv6; brackets required in URLs.
  services.caddy = {
    enable = true;
    email = "powerhouseplayer@gmail.com";
    # GRAFANA_BCRYPT for the grafana vhost's basic_auth gate — loaded into
    # Caddy's process env, resolved at config provision as {env.GRAFANA_BCRYPT}.
    environmentFile = config.clan.core.vars.generators.grafana-basic-auth.files."auth".path;
    # Tell ACME to use Let's Encrypt's production endpoint (Caddy default).
    virtualHosts = {
      # Grafana (sunken-ship :3000) behind a basic_auth gate. It's admin
      # tooling, so a proxy-level password sits in front of Grafana's own
      # login (defense-in-depth) before anything is exposed publicly.
      "grafana.dannydannydanny.me".extraConfig = ''
        basic_auth {
          danny {env.GRAFANA_BCRYPT}
        }
        reverse_proxy http://[${zt."sunken-ship"}]:3000
      '';
      "navidrome.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."sunken-ship"}]:4533
      '';
      "bbbot.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."sunken-ship"}]:8080
      '';
      # B3Bot beta — bbbot's staging tenant under shipyard_poc_bot.
      # Same backend host as bbbot prod, port 8081.
      "b3.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."sunken-ship"}]:8081
      '';
      # Shelfish — phantom-ship's ZT IPv6.
      "shelfish.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8081
      '';
      # Scuttle — same backend, different port. WebSocket upgrade is
      # transparent under reverse_proxy.
      "scuttle.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8082
      '';
      # Bananasimulator — same backend, port 8083.
      "bananasimulator.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8083
      '';
      # Bananasimulator BETA — separate service on port 8084 with
      # BS_BETA_MODE=1 (cheat menu + faster ripening for testing).
      "bananasimulator-beta.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8084
      '';
      # KomTolk (formerly translate-platform) — same backend, port 8080.
      "komtolk.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8080
      '';
      # Forgejo on phantom-ship — Phase 1 of the de-platform-from-GitHub
      # roadmap (vimwiki/diary/2026-05-03.md).
      "git.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:3000
      '';
      # Escape Hormuz — turn-based boat-race Mini App, port 8090.
      "escapehormuz.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8090
      '';
      # bon — receipt scanner Mini App, port 8091. Camera capture in
      # the WebView needs HTTPS, which Caddy terminates here.
      "bon.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8091
      '';
      # TDPixi — Idle Tower Defence Mini App by @plasmagoat, port 8093.
      "tdpixi.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8093
      '';
      # Plane — self-hosted project tracker (Linear-alike). Full stack
      # runs as podman containers on phantom-ship (nixos/plane.nix);
      # Plane's bundled proxy listens on :8094 and path-routes the rest.
      "plane.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8094
      '';
      # notes — markdown blog (notes.X) + apex landing (X). Same backend
      # service on phantom :8092 routes by Host header.
      "notes.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8092
      '';
      "dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8092
      '';
      # kf — Kyranna Fardi architecture portfolio. Same notes service on
      # phantom :8092, routed by Host header (PORTFOLIO_HOST).
      "kf.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8092
      '';
      # map — curated-architecture world map by Kyranna. Same notes
      # service on phantom :8092, routed by Host header (MAP_HOST).
      "map.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8092
      '';
      # studio — Kyranna's private art-learning archive. Same notes
      # service on phantom :8092, routed by Host header (STUDIO_HOST).
      "studio.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[${zt."phantom-ship"}]:8092
      '';
      # Filebrowser web UI over the FTP tree (see filebrowser below).
      # Caddy fetches its own cert for this name (TLS-ALPN); the FTPS
      # daemon has a separate lego-managed one — two certs, same name,
      # which Let's Encrypt is fine with.
      "ftp.dannydannydanny.me".extraConfig = ''
        reverse_proxy localhost:8095
      '';
      # Port 80 for the same name: serve the lego HTTP-01 webroot for
      # the FTPS cert (security.acme below), redirect everything else to
      # https. The explicit http:// scheme keeps this block plain-HTTP.
      "http://ftp.dannydannydanny.me".extraConfig = ''
        @challenge path /.well-known/acme-challenge/*
        handle @challenge {
          root * /var/lib/acme/acme-challenge
          file_server
        }
        handle {
          redir https://ftp.dannydannydanny.me{uri} 308
        }
      '';
    };
  };

  # --- FTP server (ftp.dannydannydanny.me) -----------------------------
  # vsftpd with explicit FTPS (TLS upgrade on port 21). Unlike the HTTP
  # vhosts above this can't go through Caddy — FTP negotiates a second
  # data connection on a random port — so it terminates here directly.
  # Wildcard DNS *.dannydannydanny.me already resolves to this box.
  #
  # Login: user "ftpuser"; password is a clan var, readable on the box:
  #   ssh danny@<vps> sudo cat /run/secrets/vars/ftp-password/password
  # Chroot is /srv/ftp (must stay root-owned/non-writable or vsftpd
  # refuses login); uploads go in /srv/ftp/files.

  # Cert for FTPS via lego HTTP-01 against the Caddy-served webroot.
  security.acme = {
    acceptTerms = true;
    defaults.email = "powerhouseplayer@gmail.com";
    certs."ftp.dannydannydanny.me" = {
      webroot = "/var/lib/acme/acme-challenge";
      # vsftpd loads the cert once at daemon start (verified: it kept
      # serving the stale one after issuance), so bounce it on renewal.
      postRun = "systemctl restart vsftpd.service";
    };
  };
  # First issuance needs Caddy up to answer the HTTP-01 challenge.
  systemd.services."acme-ftp.dannydannydanny.me" = {
    after = [ "caddy.service" ];
    wants = [ "caddy.service" ];
  };
  # lego writes the challenge webroot 0750 acme:acme — without group
  # membership Caddy serves 403s and issuance fails. (The nginx/httpd
  # ACME integrations do this automatically; for Caddy it's manual.)
  users.users.caddy.extraGroups = [ "acme" ];

  users.users.ftpuser = {
    isSystemUser = true;
    group = "ftpuser";
    home = "/srv/ftp";
    description = "FTP-only login (no shell, no SSH key)";
    hashedPasswordFile =
      config.clan.core.vars.generators.ftp-password.files."password.hash".path;
  };
  users.groups.ftpuser = { };

  clan.core.vars.generators.ftp-password = {
    # The Mac is encrypt-only (no admin age key), so the plaintext must
    # be deployed to the machine to be retrievable at all — root-only
    # under /run/secrets. The hash is decrypted before user creation
    # (neededFor = "users").
    files."password" = { };
    files."password.hash".neededFor = "users";
    runtimeInputs = [ pkgs.coreutils pkgs.openssl ];
    script = ''
      head -c 32 /dev/urandom | base64 | tr -d '+/=\n' | head -c 24 > "$out"/password
      openssl passwd -6 -in "$out"/password | tr -d '\n' > "$out"/password.hash
    '';
  };

  # /srv/ftp/files is managed by the filebrowser module's tmpfiles entry
  # (0700 ftpuser:ftpuser) — declaring it here too would be a duplicate
  # tmpfiles line for the same path.
  systemd.tmpfiles.rules = [
    "d /srv/ftp 0755 root root - -"
    # crowdsec setup script writes credentials here; must be owned by the
    # crowdsec user from first boot (otherwise root:root breaks the write).
    "d /var/lib/crowdsec 0750 crowdsec crowdsec - -"
  ];

  # --- Filebrowser (web UI for the FTP tree) ---------------------------
  # https://ftp.dannydannydanny.me — browse + upload from a browser.
  # Runs as ftpuser over the FTP upload dir, so web uploads and FTP
  # uploads are the same files with the same owner. Login is the same
  # credential as FTP: preStart re-syncs the web user's password from
  # the ftp-password var on every start (a password changed in the web
  # UI is deliberately overwritten on the next restart).
  services.filebrowser = {
    enable = true;
    user = "ftpuser";
    group = "ftpuser";
    settings = {
      port = 8095;  # loopback only (default address = localhost)
      root = "/srv/ftp/files";
    };
  };
  systemd.services.filebrowser = {
    serviceConfig.LoadCredential = [
      "ftp-password:${config.clan.core.vars.generators.ftp-password.files."password".path}"
    ];
    # The password briefly appears in the CLI argv here; acceptable on a
    # single-admin box (it's readable in /run/secrets by root anyway).
    preStart = ''
      pw="$(cat "$CREDENTIALS_DIRECTORY/ftp-password")"
      fb() { ${lib.getExe pkgs.filebrowser} -d /var/lib/filebrowser/database.db "$@"; }
      if [ ! -f /var/lib/filebrowser/database.db ]; then
        fb config init
      fi
      if fb users ls | grep -q ftpuser; then
        fb users update ftpuser --password "$pw"
      else
        fb users add ftpuser "$pw" --perm.admin
      fi
      # filebrowser's first-run quick-setup can seed a stray "admin"
      # user with a random password; make sure it's gone.
      fb users rm admin || true
    '';
  };

  services.vsftpd = {
    enable = true;
    localUsers = true;
    writeEnable = true;
    chrootlocalUser = true;
    # Allow-list: only ftpuser may even attempt a login.
    userlistEnable = true;
    userlistDeny = false;
    userlist = [ "ftpuser" ];
    # TLS is mandatory — plain FTP would send the password in cleartext
    # over the public internet. If a legacy device ever needs plain FTP,
    # flip these two to false.
    forceLocalLoginsSSL = true;
    forceLocalDataSSL = true;
    rsaCertFile = "/var/lib/acme/ftp.dannydannydanny.me/fullchain.pem";
    rsaKeyFile = "/var/lib/acme/ftp.dannydannydanny.me/key.pem";
    extraConfig = ''
      # vsftpd's compiled-in cipher default (DES-CBC3-SHA) no longer
      # exists in modern OpenSSL — without this no client can connect.
      ssl_ciphers=HIGH
      # Strict TLS-session reuse on the data channel breaks several
      # clients (curl, older FileZilla).
      require_ssl_reuse=NO
      pasv_enable=YES
      pasv_min_port=56000
      pasv_max_port=56010
      # Login + transfer log to the journal (also feeds fail2ban).
      xferlog_enable=YES
      local_umask=022
      ftpd_banner=ftp.dannydannydanny.me
    '';
  };
  # The NixOS vsftpd module only defines a PAM service for its virtual
  # users; for local users PAM falls through to the "other" stack, which
  # is pam_deny — every login 530s without this.
  security.pam.services.vsftpd = { };
  systemd.services.vsftpd = {
    # Don't flap-restart against a cert that hasn't been issued yet.
    after = [ "acme-finished-ftp.dannydannydanny.me.target" ];
    wants = [ "acme-finished-ftp.dannydannydanny.me.target" ];
    serviceConfig.RestartSec = "5s";
  };

  services.fail2ban.jails.vsftpd.settings = {
    enabled = true;
    port = "ftp,ftp-data,ftps,ftps-data";
    backend = "systemd";
    maxretry = 5;
    findtime = "10m";
  };

  # --- CrowdSec (HTTP + SSH threat detection) --------------------------
  # LAPI + agent detect attacks from Caddy access logs and SSH journald.
  # Firewall bouncer translates ban decisions into nftables DROP rules.
  # Prometheus metrics at :6060 (ZT-only; scrape target added to sunken-ship).
  #
  # First deploy: register with the Central API to get crowd-sourced blocklists:
  #   ssh danny@vps-relay sudo cscli capi register
  #   sudo systemctl restart crowdsec
  services.crowdsec = {
    enable = true;

    hub.collections = [
      "crowdsecurity/linux"  # base syslog parser + common rules
      "crowdsecurity/sshd"   # SSH brute-force scenarios
      "crowdsecurity/caddy"  # Caddy HTTP access log scenarios
    ];

    localConfig.acquisitions = [
      # SSH logs from journald (same source as the fail2ban sshd jail above).
      {
        source = "journalctl";
        journalctl_filter = [ "_SYSTEMD_UNIT=sshd.service" ];
        labels.type = "syslog";
      }
      # Caddy access logs — the NixOS Caddy module writes one JSON file per
      # vhost to /var/log/caddy/access-<hostname>.log by default. Glob all.
      {
        source = "file";
        filenames = [ "/var/log/caddy/access-*.log" ];
        labels.type = "caddy";
      }
    ];

    # Enable standalone LAPI (log processor + local API in the same process).
    # Plain `true` wins over the module's `lib.mkDefault false` in the freeform
    # type merge (verified via `nix eval`). Do NOT set this in settings.general
    # because the module's `api.client.credentials_path = null` (a plain null)
    # causes a "defined both null and not null" error when merged with any
    # non-null override there.
    settings.lapi.credentialsFile = "/var/lib/crowdsec/local_api_credentials.yaml";

    settings.general = {
      api.server.enable = true;
      # Bind Prometheus metrics to all interfaces; firewall limits to ZT only.
      # The module default is 127.0.0.1 which is unreachable from sunken-ship.
      prometheus = {
        enabled = true;
        level = "full";
        listen_addr = "0.0.0.0";
        listen_port = 6060;
      };
    };
  };

  # Firewall bouncer: translates CrowdSec decisions → nftables DROP rules.
  #
  # We disable auto-register because the NixOS module's register helper has
  # two bugs: (1) it calls raw cscli without `-c <config>` so it can't find
  # /etc/crowdsec/config.yaml (which doesn't exist — NixOS stores the config
  # in the Nix store); (2) its StateDirectory claims /var/lib/crowdsec on
  # every start, stealing ownership from the main crowdsec service.
  #
  # Instead, generate the bouncer key once manually then store it as a clan var:
  #   ssh danny@<vps-relay-ip> sudo cscli bouncers add crowdsec-firewall-bouncer
  #   clan vars set vps-relay crowdsec-bouncer/key   # paste key at the prompt
  services.crowdsec-firewall-bouncer = {
    enable = true;
    registerBouncer.enable = false;
    secrets.apiKeyPath =
      config.clan.core.vars.generators.crowdsec-bouncer-key.files."key".path;
  };

  clan.core.vars.generators.crowdsec-bouncer-key = {
    files."key" = {};
    prompts.key = {
      description = "CrowdSec firewall bouncer API key (run `sudo cscli bouncers add crowdsec-firewall-bouncer` on vps-relay to generate it)";
      type = "hidden";
      persist = true;
    };
  };

  # The crowdsec-firewall-bouncer NixOS module generates the register helper
  # service even when registerBouncer.enable = false. Its StateDirectory
  # includes "crowdsec" which causes systemd to steal /var/lib/crowdsec
  # ownership (DynamicUser UID collision), breaking the main crowdsec.service.
  # Fix: remove "crowdsec" from its StateDirectory and disable auto-start.
  systemd.services.crowdsec-firewall-bouncer-register = {
    wantedBy = lib.mkForce [];
    serviceConfig.StateDirectory = lib.mkForce "crowdsec-firewall-bouncer-register";
  };

  # CrowdSec reads Caddy's log files; the caddy user/group owns them.
  users.users.crowdsec.extraGroups = [ "caddy" ];

  # Caddy's default UMask (0177) writes log files as 600 (no group read).
  # CrowdSec is in the caddy group, so 0027 → 640 lets it tail the logs.
  systemd.services.caddy.serviceConfig.UMask = "0027";

  # --- Basic tooling ---------------------------------------------------
  environment.systemPackages = with pkgs; [
    git
    htop
    tcpdump
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.11";
}
