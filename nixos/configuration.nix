# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, ... }:

{
  imports = [
    # include NixOS-WSL modules
    <nixos-wsl/modules>
    ./tmux.nix
    ./neovim.nix
    ./fish.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "nixos";
  # wsl.nativeSystemd = false; # This (old) method of running systemd in a container (syschdemd) is deprecated.

  nix.settings.experimental-features = [ "nix-command" "flakes" ];  # for vscode remote server

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
  system.stateVersion = "24.05"; # Did you read the comment?

  users.users.dth = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "test";
  };

  nixpkgs.config.allowUnfree = true;
  environment.variables = {
    DBT_USER = "DNTH";
  };

  environment.systemPackages = with pkgs; [
    # tmux    # activated in tmux.nix
    # vim     # using neovim in stead
    # neovim  # activated in neovim.nix

    git
    ripgrep
    wget      # for vscode-server
    busybox   # useful programs e.g. tree, unzip etc

    # make default.nix in python project folders instead of using a top-level python environment manager
    # pyenv
    # poetry
    
    neofetch    # system info

    # gimp	# bloat
    # blender   # bloat
    # inkscape  # bloat

    cowsay
    lolcat
  ];

}
