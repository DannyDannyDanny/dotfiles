{ config, lib, pkgs, ... }:

{
  # Apple Silicon + nix-darwin basics
  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.enable = false; # Determinate manages Nix

  nixpkgs.config.allowUnfree = true;
  
  system.primaryUser = "danny";

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
  security.pam.services.sudo_local.touchIdAuth = true;

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
    # busybox #TODO: doesn't run on darwin
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
  # current max per nix-darwin; bump only if a release notes says so
  system.stateVersion = 6;

}
