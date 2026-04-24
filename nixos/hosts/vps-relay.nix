# Hetzner Cloud VPS — public reverse proxy into the clan.
#
# Role: terminates public TLS via Caddy + Let's Encrypt, reverse-proxies
# each declared subdomain over ZeroTier to the appropriate homelab host.
# No navidrome/bbbot data ever hits disk here; this box is a relay.
{ config, lib, pkgs, ... }:
{
  imports = [ ../disko-cloud.nix ];

  nixpkgs.hostPlatform = "x86_64-linux";

  # Hetzner Cloud boots EFI with systemd-boot.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
