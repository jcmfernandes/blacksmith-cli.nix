{
  description = "Blacksmith CLI, packaged from upstream's prebuilt binaries";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;
    systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    # Proprietary binary: allow just this one unfree package, so
    # `nix build` works here without NIXPKGS_ALLOW_UNFREE.
    forAllSystems = f:
      lib.genAttrs systems (system:
        f (import nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg: lib.getName pkg == "blacksmith-cli";
        }));
  in {
    overlays.default = final: _: {
      blacksmith-cli = final.callPackage ./package.nix {};
    };

    packages = forAllSystems (pkgs: {
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.blacksmith-cli;
      blacksmith-cli = pkgs.callPackage ./package.nix {};
    });
  };
}
