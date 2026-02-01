{
  description = "f-around-firefox (faf) script environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
      pythonEnv = pkgs.python3.withPackages (ps: with ps; [
        lz4
        websockets
      ]);
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          pythonEnv
          pkgs.lz4
        ];
        shellHook = ''
          echo "faf script environment ready"
          echo "Python: $(which python3)"
          echo "Run: faf"
        '';
      };
    };
}

