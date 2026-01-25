# ziglint-nix

Nix flake for [ziglint](https://github.com/rockorager/ziglint) - an opinionated linter for Zig source code.

## Usage

### Run directly

```bash
nix run github:uzaaft/ziglint-nix -- src/
```

### Add to your flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    ziglint.url = "github:uzaaft/ziglint-nix";
  };

  outputs = {
    nixpkgs,
    ziglint,
    ...
  }: let
    system = "x86_64-linux"; # or aarch64-darwin, etc.
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ziglint.overlays.default];
    };
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [pkgs.ziglint];
    };
  };
}
```

### Use the overlay

```nix
overlays = [ ziglint.overlays.default ];
# Then access via pkgs.ziglint
```

### Add to devShell

```nix
devShells.default = pkgs.mkShell {
  buildInputs = [ ziglint.packages.${system}.default ];
};
```
