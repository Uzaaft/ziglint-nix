{
  description = "Nix flake for ziglint - an opinionated linter for Zig source code";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ziglint-src = {
      url = "github:rockorager/ziglint";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ziglint-src,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    pkgsFor = system: import nixpkgs {inherit system;};
    ziglintFor = system: let
      pkgs = pkgsFor system;
    in
      pkgs.stdenv.mkDerivation {
        pname = "ziglint";
        version = "0.3.0";

        src = ziglint-src;

        nativeBuildInputs = [pkgs.zig];

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
    packages = forAllSystems (system: let
      ziglint = ziglintFor system;
    in {
      default = ziglint;
      inherit ziglint;
    });

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${ziglintFor system}/bin/ziglint";
      };
    });

    devShells = forAllSystems (system: {
      default = (pkgsFor system).mkShell {
        buildInputs = [(ziglintFor system)];
      };
    });

    overlays.default = final: prev: {
      ziglint = self.packages.${prev.system}.ziglint;
    };
  };
}
