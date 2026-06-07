# Standalone nixosSystem registration for distant-shore.
# Temporary: clan integration (zerotier/data-mesher/dm-pull-deploy) needs
# vars generated via sops on the admin machine. Until that runs, this
# keeps the box buildable without clan deps. Delete this file when
# distant-shore moves into flake-modules/clan.nix.
{ inputs, ... }: {
  flake.nixosConfigurations.distant-shore = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      inputs.disko.nixosModules.disko
      ../nixos/hosts/distant-shore.nix
    ];
  };
}
