{
  description = "Colección de plantillas reproducibles de desarrollo (Nix Flakes) y herramientas CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      toolsOutputs = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          packages = {
            simdoc = pkgs.writeScriptBin "simdoc" ''
              #!${pkgs.python3}/bin/python3
              ${builtins.readFile ./tools/simdoc.py}
            '';

            simstubs = pkgs.writeScriptBin "simstubs" ''
              #!${pkgs.python3}/bin/python3
              ${builtins.readFile ./tools/generate_stubs.py}
            '';
          };
        });
    in
    toolsOutputs // {
      templates = {
        python = {
          path = ./python;
          description = "Entorno Python reproducible con uv, basedpyright y ruff";
        };

        rust = {
          path = ./rust;
          description = "Toolchain de Rust (stable) con rust-analyzer, clippy y rustfmt";
        };

        coppelia = {
          path = ./coppelia;
          description = "CoppeliaSim + Python ZeroMQ Remote API con tipado estático (stubs) y simdoc";
        };

        java = {
          path = ./java;
          description = "Entorno Java con OpenJDK 21, Maven, Gradle y wrapper de JDTLS";
        };

        low_level = {
          path = ./low_level;
          description = "Entorno de bajo nivel C/C++ y Rust con GDB, Valgrind, Bear y Clangd";
        };

        rustyrtc = {
          path = ./rustyrtc;
          description = "Entorno de desarrollo WebRTC en Rust con Wayland, OpenGL y OpenCV";
        };
      };

      templates.default = self.templates.python;
    };
}
