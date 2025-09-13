# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  wsl = {
    enable = true;
    defaultUser = "nixos";
    wslConf.network.generateResolvConf = false;
  };

  networking = {
    useDHCP = true;
    # nameserver sources: https://dnsmap.io/articles/most-popular-dns-servers
    nameservers = [ "84.200.69.80" "8.26.56.26" "1.1.1.1" "8.8.8.8" "64.6.65.6" "208.67.222.222" "209.244.0.3" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  programs.nix-ld.enable = true;
  # TODO: move to home manager (?)
  programs = {
    direnv = {
      enable = true;
      # enableFishIntegration = true;
      nix-direnv.enable = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  users.users.dth = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "test";
  };

  nixpkgs.config.allowUnfree = true;
  environment.variables = {
    DBT_USER = "DNTH";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  environment.systemPackages = with pkgs; [
    # tmux    # activated in tmux.nix
    # vim     # using neovim in stead
    # neovim  # activated in neovim.nix

    git       # version control
    gh        # github cli tool

    ripgrep   # faster grep
    wget      # for vscode-server
    busybox   # useful programs e.g. tree, unzip etc
    openssl   # cryptography swiss army knife
    xdg-utils # terminal desktop intergrations (i.e. allow terminal to open browser)

    # make default.nix in python project folders instead of using a top-level python environment manager
    # pyenv
    # poetry

    neofetch    # system info
    btop        # resource monitor
    tldr        # community alternative to man
    fzf         # fuzzy finder
    jq          # parse json

    # gimp	    # bloat
    # blender   # bloat
    # inkscape  # bloat

    cowsay
    lolcat
  ];

  services.ollama.enable = true;
  services.open-webui = { enable = true; port = 8080; };

  services.vscode-server.enable = true;
  security.rtkit.enable = true; # realtime kit hands out realtime scheduling priority
  services.pipewire = {
    enable = true; # if not already enabled
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

}
