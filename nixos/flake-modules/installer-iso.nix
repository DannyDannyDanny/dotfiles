{ inputs, self, ... }: {
  # Custom minimal installer ISO (build with: nix build .#installer-iso).
  # Optional: add ./installer-wifi.nix (gitignored) to modules for live WiFi.
  flake.nixosConfigurations.installer-iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ ../installer-iso.nix ];
  };

  flake.packages.x86_64-linux.installer-iso =
    self.nixosConfigurations.installer-iso.config.system.build.isoImage;
}
