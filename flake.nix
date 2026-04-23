{
  description = "Nix flake for ziglint - an opinionated linter for Zig source code";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
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

        src = pkgs.fetchFromGitHub {
          owner = "rockorager";
          repo = "ziglint";
          rev = "bfcb30d14d5506940344096e4cf3b0c13b210439";
          hash = "sha256-kP+1bnp2bkYGcIkJDQLtuh5Q+kSH196Qw9sSYaFvqkI=";
        };

        nativeBuildInputs = [pkgs.zig_0_15];

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
