{
  description = "Application packaged using poetry2nix";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.poetry2nix.url = "github:nix-community/poetry2nix";

  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    {
      # Nixpkgs overlay providing the application
      overlay = nixpkgs.lib.composeManyExtensions [
        poetry2nix.overlay
        (final: prev: {
          wg-netns = prev.poetry2nix.mkPoetryApplication rec {
            projectDir = ./.;
            src = builtins.fetchGit {
              url = "https://github.com/dadevel/wg-netns";
              ref = "main";
              rev = "2542d9f4cdf99b281c263d84795ac5422d9d4854";
            };
            pyproject = src + "/pyproject.toml";
            poetrylock = src + "/poetry.lock";
          };
        })
      ];
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ self.overlay ];
        pkgs = builtins.foldl' (acc: overlay: acc.extend overlay)
          nixpkgs.legacyPackages.${system} overlays;
      in rec {
        apps = { wg-netns = pkgs.wg-netns; };
        packages = pkgs.wg-netns;
        defaultPackage = pkgs.wg-netns;
        devShells.default = pkgs.mkShell { buildInputs = [ pkgs.poetry ]; };
      }));
}
