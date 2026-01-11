{ config, lib, pkgs, ... }:

{
  # Apple Silicon + nix-darwin basics
  nixpkgs.hostPlatform = "aarch64-darwin";
  nix.enable = false; # Determinate manages Nix

  nixpkgs.config.allowUnfree = true;

  system.primaryUser = "danny";

  # Shells (fish config is in fish.nix, imported via flake.nix)
  environment.shells = [ pkgs.fish ];
  users.users.danny.shell = pkgs.fish;

  # ollama
  imports = [../ollama.nix];
  services.ollama = {
    enable = true;
  };

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
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = true;
      "com.apple.mouse.tapBehavior" = 1;
      "com.apple.sound.beep.volume" = 0.0;
      "com.apple.sound.beep.feedback" = 0;
    };

    # Finder & Dock
    finder.AppleShowAllExtensions = true;
    dock.autohide = true;
    dock.mru-spaces = false;
  };

  # User-specific packages and environment variables are now in home-manager (home.nix)
  # Only system-level packages should remain here if needed

  # Keep for darwin as well (tracks defaults across upgrades)
  # current max per nix-darwin; bump only if a release notes says so
  system.stateVersion = 6;

}
