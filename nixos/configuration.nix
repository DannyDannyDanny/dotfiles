# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
      ./hardware-configuration.nix
      ./tmux.nix
      ./neovim.nix
      ./fish.nix
      # ./uxplay.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-04715655-635c-46ee-8100-1a5a4f3700a5".device = "/dev/disk/by-uuid/04715655-635c-46ee-8100-1a5a4f3700a5";
  networking.hostName = "nixos"; # Define your hostname.
  # NOTE: You can not use networking.networkmanager with networking.wireless
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];  # for vscode remote server

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  programs.nix-ld.enable = true;
  # TODO: move to home manager (?)
  programs = {
    direnv = {
      enable = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  hardware.alsa.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.dth = {
    isNormalUser = true;
    description = "dth";
    extraGroups = [ "networkmanager" "wheel" ];
    # TODO: use home manager to define user packages
    packages = with pkgs; [
      vlc     # video player
      kate    # editor
      ripgrep # faster grep
      nextcloud-client  # private cloud
      # thunderbird # bloat
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # install kde partition manager
  programs.partition-manager.enable = true;

  # TODO: install gnome disk manager
  # programs.gnome-disks.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    # tmux    # activated in tmux.nix
    # vim     # using neovim in stead
    # neovim  # activated in neovim.nix

    git       # version control
    gh        # github cli tool

    ripgrep   # faster grep
    busybox   # useful programs e.g. tree, unzip etc
    openssl   # cryptography swiss army knife
    xdg-utils # terminal desktop intergrations (i.e. allow terminal to open browser)

    neofetch    # system info
    btop        # resource monitor
    wget        # downloader
    tldr			  # community driven manpage alternative

    ntfs3g      # mount NTFS drives on linux
    gptfdisk    # formatting drives - like fdisk but better
                # this stuff runs gparted

    # gimp	    # bloat image editing
    # blender   # bloat 3D modelling
    # inkscape  # bloat vecor graphics / drawing
    # kdenlive  # bloat video editor

    # desktop applications
    thunderbird		    # email / calendar
    telegram-desktop	# instant messager

    cowsay
    lolcat

  ];

  # firefox smooth scrolling
  environment.sessionVariables = {
    MOZ_USE_XINPUT2 = "1";
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
