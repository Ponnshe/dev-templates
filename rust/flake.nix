{
  description = "Minimal reproducible Rust dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        # Toolchain Rust completo y reproducible
        rust = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "clippy" "rustfmt" ];
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "rust-dev-shell";

          packages = with pkgs; [
            rust
            rust-analyzer
          ];

          # Entorno limpio, sin dependencias pesadas
          env = {
            RUST_BACKTRACE = "1";
          };
        };
      });
}
