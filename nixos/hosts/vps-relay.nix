# Hetzner Cloud VPS — public reverse proxy into the clan.
#
# Role: terminates public TLS via Caddy + Let's Encrypt, reverse-proxies
# each declared subdomain over ZeroTier to the appropriate homelab host.
# No navidrome/bbbot data ever hits disk here; this box is a relay.
# Exception: the FTPS server (ftp.dannydannydanny.me) stores its files
# locally under /srv/ftp — FTP's separate data channel can't be relayed
# through Caddy like the HTTP vhosts.
{ config, lib, pkgs, ... }:
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

  # --- Caddy reverse proxy --------------------------------------------
  # Subdomains → clan backends over ZeroTier. IPs are sunken-ship's /
  # phantom-ship's ZT IPv6; brackets required in URLs.
  services.caddy = {
    enable = true;
    email = "powerhouseplayer@gmail.com";
    # Tell ACME to use Let's Encrypt's production endpoint (Caddy default).
    virtualHosts = {
      "navidrome.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:93d5:53a2:de33]:4533
      '';
      "bbbot.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:93d5:53a2:de33]:8080
      '';
      # B3Bot beta — bbbot's staging tenant under shipyard_poc_bot.
      # Same backend host as bbbot prod, port 8081.
      "b3.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:93d5:53a2:de33]:8081
      '';
      # Shelfish — phantom-ship's ZT IPv6.
      "shelfish.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8081
      '';
      # Scuttle — same backend, different port. WebSocket upgrade is
      # transparent under reverse_proxy.
      "scuttle.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8082
      '';
      # Bananasimulator — same backend, port 8083.
      "bananasimulator.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8083
      '';
      # Bananasimulator BETA — separate service on port 8084 with
      # BS_BETA_MODE=1 (cheat menu + faster ripening for testing).
      "bananasimulator-beta.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8084
      '';
      # KomTolk (formerly translate-platform) — same backend, port 8080.
      "komtolk.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8080
      '';
      # Forgejo on phantom-ship — Phase 1 of the de-platform-from-GitHub
      # roadmap (vimwiki/diary/2026-05-03.md).
      "git.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:3000
      '';
      # Escape Hormuz — turn-based boat-race Mini App, port 8090.
      "escapehormuz.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8090
      '';
      # bon — receipt scanner Mini App, port 8091. Camera capture in
      # the WebView needs HTTPS, which Caddy terminates here.
      "bon.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8091
      '';
      # TDPixi — Idle Tower Defence Mini App by @plasmagoat, port 8093.
      "tdpixi.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8093
      '';
      # notes — markdown blog (notes.X) + apex landing (X). Same backend
      # service on phantom :8092 routes by Host header.
      "notes.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8092
      '';
      "dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8092
      '';
      # kf — Kyranna Fardi architecture portfolio. Same notes service on
      # phantom :8092, routed by Host header (PORTFOLIO_HOST).
      "kf.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8092
      '';
      # map — curated-architecture world map by Kyranna. Same notes
      # service on phantom :8092, routed by Host header (MAP_HOST).
      "map.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8092
      '';
      # studio — Kyranna's private art-learning archive. Same notes
      # service on phantom :8092, routed by Host header (STUDIO_HOST).
      "studio.dannydannydanny.me".extraConfig = ''
        reverse_proxy http://[fdd5:53a2:de33:d269:6499:936c:48a:bbdc]:8092
      '';
      # ACME HTTP-01 webroot for the FTPS cert (security.acme below) —
      # the explicit http:// scheme stops Caddy from also trying to
      # manage TLS for this name.
      "http://ftp.dannydannydanny.me".extraConfig = ''
        root * /var/lib/acme/acme-challenge
        file_server
      '';
    };
  };

  # --- FTP server (ftp.dannydannydanny.me) -----------------------------
  # vsftpd with explicit FTPS (TLS upgrade on port 21). Unlike the HTTP
  # vhosts above this can't go through Caddy — FTP negotiates a second
  # data connection on a random port — so it terminates here directly.
  # Wildcard DNS *.dannydannydanny.me already resolves to this box.
  #
  # Login: user "ftpuser"; password is a clan var:
  #   clan vars get vps-relay ftp-password/password
  # Chroot is /srv/ftp (must stay root-owned/non-writable or vsftpd
  # refuses login); uploads go in /srv/ftp/files.

  # Cert for FTPS via lego HTTP-01 against the Caddy-served webroot.
  # vsftpd forks per session and re-reads the cert each time, so
  # renewals need no service reload.
  security.acme = {
    acceptTerms = true;
    defaults.email = "powerhouseplayer@gmail.com";
    certs."ftp.dannydannydanny.me".webroot = "/var/lib/acme/acme-challenge";
  };
  # First issuance needs Caddy up to answer the HTTP-01 challenge.
  systemd.services."acme-ftp.dannydannydanny.me" = {
    after = [ "caddy.service" ];
    wants = [ "caddy.service" ];
  };

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
    # Plaintext stays in the encrypted store only (deploy = false) so it
    # can be looked up; the machine gets just the hash, decrypted before
    # user creation (neededFor = "users").
    files."password".deploy = false;
    files."password.hash".neededFor = "users";
    runtimeInputs = [ pkgs.coreutils pkgs.openssl ];
    script = ''
      head -c 32 /dev/urandom | base64 | tr -d '+/=\n' | head -c 24 > "$out"/password
      openssl passwd -6 -in "$out"/password | tr -d '\n' > "$out"/password.hash
    '';
  };

  systemd.tmpfiles.rules = [
    "d /srv/ftp 0755 root root - -"
    "d /srv/ftp/files 0755 ftpuser ftpuser - -"
  ];

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

  # --- Basic tooling ---------------------------------------------------
  environment.systemPackages = with pkgs; [
    git
    htop
    tcpdump
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.11";
}
