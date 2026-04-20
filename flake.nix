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

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nix-openclaw.url = "github:openclaw/nix-openclaw";
    nix-openclaw.inputs.nixpkgs.follows = "nixpkgs";

    clan-core.url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
    clan-core.inputs.nixpkgs.follows = "nixpkgs";
    clan-core.inputs.flake-parts.follows = "flake-parts";

    # clan-community: dm-pull-deploy etc. Pinned to our fork's fix branch
    # until clan/clan-community#25 (machine.name hyphen sanitization) lands.
    # Swap back to `archive/main.tar.gz` when merged.
    clan-community.url = "git+https://git.clan.lol/dannydannydanny/clan-community.git?ref=fix/dm-pull-deploy-hyphen-hostnames";
    clan-community.inputs.nixpkgs.follows = "nixpkgs";
    clan-community.inputs.clan-core.follows = "clan-core";
  };

  outputs = inputs @ { flake-parts, import-tree, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      imports = [ (import-tree ./flake-modules) ];
    };
}
