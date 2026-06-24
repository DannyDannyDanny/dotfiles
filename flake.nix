{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    vscode-server.url = "github:nix-community/nixos-vscode-server";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # Auto-loads every .nix file under ./flake-modules as a flake-parts module.
    import-tree.url = "github:vic/import-tree";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    # Fleet/infra inputs (clan-core, clan-community, disko, nix-openclaw) moved
    # to the PRIVATE homelab repo as part of the INFRA-144 split. This public
    # repo is dev-machine (macOS + WSL) + devshell only.
  };

  outputs = inputs @ { flake-parts, import-tree, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      imports = [ (import-tree ./flake-modules) ];
    };
}
