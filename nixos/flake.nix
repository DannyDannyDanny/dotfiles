{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    # for later
    # home-manager.url = "github:nix-community/home-manager";
    # home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    nixos-wsl,
    vscode-server,
    self,
    # home-manager,
    ...
  }: {
    nixosConfigurations = {

      wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.default
          vscode-server.nixosModules.default
          ./hosts/wsl.nix # previously configuration.nix
          ./tmux.nix
          ./neovim.nix
          ./fish.nix
          # home-manager.nixosModules.default
        ];
      };

      macbookair = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          vscode-server.nixosModules.default
          ./hosts/macbookair.nix # previously configuration.nix
          ./hardware-configuration.nix
          ./tmux.nix
          ./neovim.nix
          ./fish.nix
          # home-manager.nixosModules.default
          # ./configuration.nix   # shouldn't this be necessary???
          # ./uxplay.nix
        ];
      };

    };
  };
}
