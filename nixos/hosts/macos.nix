{ config, lib, pkgs, ... }:

{
  # Apple Silicon + nix-darwin basics
  nixpkgs.hostPlatform = "aarch64-darwin";
  services.nix-daemon.enable = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 3; Minute = 0; };
    };
  };

  nixpkgs.config.allowUnfree = true;

  # Shells & dev ergonomics
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
  # If you want fish as default shell, uncomment:
  # users.defaultUserShell = pkgs.fish;

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Networking (macOS-safe)
  networking = {
    # Set if you want a specific hostname in macOS UI as well:
    hostName = "Daniel-Macbook-Air";
    knownNetworkServices = [ "Wi-Fi" "Thunderbolt Bridge" ];
  };

  # macOS niceties
  security.pam.enableSudoTouchIdAuth = true;

  system.defaults = {
    # Keyboard
    NSGlobalDomain = {
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };

    # Finder & Dock
    finder.AppleShowAllExtensions = true;
    dock.autohide = true;
    dock.mru-spaces = false;
  };

  # Environment
  environment.variables = {
    DBT_USER = "DNTH";
  };

  environment.systemPackages = with pkgs; [
    gh
    ripgrep
    wget
    busybox
    git
    gnupg
    coreutils
    openssl
    neofetch
    btop
    tldr
    fzf
    cowsay
    lolcat
  ];

  # Keep for darwin as well (tracks defaults across upgrades)
  system.stateVersion = "25.05";
}
