{
  description = "Modern and high-performance reproducible Python dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python3;
      in {
        devShells.default = pkgs.mkShell {
          name = "python-dev-shell";

          packages = with pkgs; [
            python
            # LSPs & Herramientas de análisis de tipos
            basedpyright
            pyright

            # Linter & Formatter ultrarrápido en Rust
            ruff

            # Gestor de paquetes ultrarrápido
            uv

            # Testing & Debugging
            python3Packages.pytest
            python3Packages.debugpy
          ];

          # Variables de entorno
          env = {
            PYTHONUNBUFFERED = "1";
            UV_LINK_MODE = "copy";
            UV_PYTHON_PREFERENCE = "only-system";
            # Librerías nativas esenciales en NixOS para compilar e importar paquetes C/C++ (numpy, pandas, etc.)
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
              stdenv.cc.cc.lib
              zlib
              glib
              libGL
              glibcLocales
            ]);
          };

          # Hook de inicialización del entorno virtual
          shellHook = ''
            if [ ! -f "pyproject.toml" ]; then
              echo "⚡ Inicializando proyecto declarativo con uv (pyproject.toml)..."
              uv init --bare --quiet
            else
              if [ ! -d ".venv" ]; then
                echo "⚡ Sincronizando entorno virtual con uv..."
                uv sync --quiet
              fi
            fi

            source .venv/bin/activate
            echo "🐍 Entorno Python activo ($(python --version)) con basedpyright, ruff y uv."
            echo "   - Usa 'uv add <paquete>' para agregar librerías al proyecto."
          '';
        };
      });
}
