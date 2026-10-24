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

        rust = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "clippy" "rustfmt" ];
        };
        
        # Lista de librerías que necesitamos tanto para compilar como para ejecutar
        runtimeLibs = with pkgs; [
          wayland
          libxkbcommon
          libglvnd        # Para OpenGL
          xorg.libX11     # Winit a veces necesita fallback a X11
          xorg.libXcursor
          xorg.libXi
          xorg.libXrandr
          
          alsa-lib
          opencv
          openssl
          llvmPackages.libclang
          llvmPackages.libcxx
        ];
      in {
        devShells.default = pkgs.mkShell {
          name = "rust-dev-shell";

          nativeBuildInputs = with pkgs; [
            pkg-config
            cmake
            llvmPackages.llvm
            llvmPackages.clang
            rust
            rust-analyzer
          ];

          buildInputs = runtimeLibs;

          env = {
            RUST_BACKTRACE = "1";
            LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
            PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
            
            # Fix para bindgen (header files)
            BINDGEN_EXTRA_CLANG_ARGS = builtins.concatStringsSep " " [
              "-isystem ${pkgs.llvmPackages.libclang.lib}/lib/clang/${pkgs.llvmPackages.libclang.version}/include"
              "-isystem ${pkgs.lib.getDev pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version}"
              "-isystem ${pkgs.lib.getDev pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version}/${system}-gnu"
              "-isystem ${pkgs.glibc.dev}/include"
            ];

            # SOLUCIÓN PARA TU ERROR ACTUAL (NoWaylandLib):
            # Esto le dice al binario dónde buscar las librerías .so al ejecutarse
            LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath runtimeLibs}";
          };

          shellHook = ''
            echo "Environment loaded."
            echo "Wayland libraries injected into LD_LIBRARY_PATH"
          '';
        };
      });
}
