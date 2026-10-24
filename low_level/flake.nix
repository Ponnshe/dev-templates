{
  description = "Low Level Dev Environment: Rust + C + Debugging Tools";

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
        rust-toolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "clippy" "rustfmt" ];
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "low-level-shell";

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          packages = with pkgs; [
            # --- Herramientas de Construcción y LSP ---
            bear         # LA PIEZA QUE FALTA
            llvmPackages_20.clang-tools
            gcc
            gnumake
            cmake
            glibc.dev

            # --- Rust ---
            rust-toolchain
            rust-analyzer

            # --- Debugging ---
            gdb
            valgrind
            strace
            ltrace
            binutils

            # --- Docs ---
            man-pages
            man-db
            man-pages-posix
          ];

          env = {
            RUST_BACKTRACE = "1";
            RUST_SRC_PATH = "${rust-toolchain}/lib/rustlib/src/rust/library";
            # Importante para que clangd encuentre los headers de la glibc en NixOS
            CPATH = "${pkgs.glibc.dev}/include";
            C_INCLUDE_PATH = "${pkgs.glibc.dev}/include";
            MANPATH = "${pkgs.man-pages}/share/man:${pkgs.man-pages-posix}/share/man:$MANPATH";
          };

          shellHook = ''
            echo "🛠️ Entorno Low Level Activado con Bear"
            echo "Usa: 'bear -- gcc archivo.c' para generar el compile_commands.json"
          '';
        };
      });
}
