# Hetzner Cloud VPS — public reverse proxy into the clan.
#
# Role: terminates public TLS via Caddy + Let's Encrypt, reverse-proxies
# each declared subdomain over ZeroTier to the appropriate homelab host.
# No navidrome/bbbot data ever hits disk here; this box is a relay.
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
      # Same pubkey used to reach sunken-ship; set at install via clan.
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKW/akfIiVU5o63YrTAJVZhMj7kXfYHOnXDtlpVFW7pf danny@sunken-ship"
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
  # Public: 22 (SSH), 80 + 443 (Caddy).
  # ZT interface: trusted (set in the clan ZT module).
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

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
    };
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
