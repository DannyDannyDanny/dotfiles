{ inputs, self, ... }: {
  # Custom minimal installer ISO (build with: nix build .#installer-iso).
  # nixos/installer-wifi.nix (gitignored) is auto-included when present, to
  # preconfigure live-system WiFi. See docs/server-installer-usb.md.
  flake.nixosConfigurations.installer-iso = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ ../nixos/installer-iso.nix ]
      ++ inputs.nixpkgs.lib.optional
        (builtins.pathExists ../nixos/installer-wifi.nix)
        ../nixos/installer-wifi.nix;
  };

  flake.packages.x86_64-linux.installer-iso =
    self.nixosConfigurations.installer-iso.config.system.build.isoImage;
}
