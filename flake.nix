{
  description = "Nix flake for ziglint - an opinionated linter for Zig source code";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    ziglint-src = {
      url = "github:rockorager/ziglint";
      flake = false;
    };
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ziglint-src,
    zig-overlay,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [zig-overlay.overlays.default];
        };

        zig = pkgs.zigpkgs."0.15.2";

        ziglint = pkgs.stdenv.mkDerivation {
          pname = "ziglint";
          version = "0.2.2";

          src = ziglint-src;

          nativeBuildInputs = [zig];

          dontConfigure = true;
          dontInstall = true;

          buildPhase = ''
            runHook preBuild

            export XDG_CACHE_HOME=$(mktemp -d)
            zig build -Doptimize=ReleaseFast --prefix $out

            runHook postBuild
          '';

          meta = with pkgs.lib; {
            description = "Opinionated linting to keep your agent in check";
            homepage = "https://github.com/rockorager/ziglint";
            license = licenses.mit;
            maintainers = [];
            platforms = platforms.unix;
            mainProgram = "ziglint";
          };
        };
      in {
        packages = {
          default = ziglint;
          inherit ziglint;
        };

        apps.default = flake-utils.lib.mkApp {
          drv = ziglint;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ziglint];
        };
      }
    )
    // {
      overlays.default = final: prev: {
        ziglint = self.packages.${prev.system}.ziglint;
      };
    };
}
