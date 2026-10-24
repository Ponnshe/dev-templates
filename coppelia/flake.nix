{
  description = "Reproducible Python dev environment for CoppeliaSim with type stubs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    dev-templates.url = "github:ponnshe/dev-templates";
  };

  outputs = { self, nixpkgs, flake-utils, dev-templates, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python3;
        tools = dev-templates.packages.${system};
      in {
        devShells.default = pkgs.mkShell {
          name = "coppelia-python-dev-shell";

          packages = with pkgs; [
            python
            basedpyright
            pyright
            ruff
            uv
            python3Packages.pytest
            python3Packages.debugpy
            tools.simdoc
            tools.simstubs
            lemminx
            libxml2
          ];

          env = {
            PYTHONUNBUFFERED = "1";
            UV_LINK_MODE = "copy";
            UV_PYTHON_PREFERENCE = "only-system";
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (with pkgs; [
              stdenv.cc.cc.lib
              zlib
              glib
              libGL
              glibcLocales
            ]);
          };

          shellHook = ''
            # 1. Inicializar proyecto declarativo si no existe pyproject.toml
            if [ ! -f "pyproject.toml" ]; then
              echo "⚡ Inicializando proyecto declarativo con uv (pyproject.toml)..."
              uv init --bare --quiet
              echo "📦 Agregando coppeliasim-zmqremoteapi-client y lxml..."
              uv add coppeliasim-zmqremoteapi-client lxml --quiet
            else
              # 2. Si ya existe, sincronizar el entorno virtual
              if [ ! -d ".venv" ]; then
                echo "⚡ Sincronizando entorno virtual con uv..."
                uv sync --quiet
              fi
            fi

            source .venv/bin/activate

            # 3. Generar stubs de tipado si no existen
            if [ ! -d "typings" ]; then
              echo "⚡ Generando stubs de tipado para CoppeliaSim con simstubs..."
              simstubs || true
            fi

            echo "🤖 Entorno CoppeliaSim + Python activo ($(python --version))."
            echo "   - Stubs de tipado disponibles en ./typings (usa 'simstubs' para regenerar)."
            echo "   - Soporte XML/URDF/SDF activo (lemminx, libxml2, lxml)."
            echo "   - Usa 'uv add <paquete>' para agregar librerías (ej. uv add numpy)."
            echo "   - Usa 'simdoc <nombre>' para ver la documentación oficial en terminal."
          '';
        };
      });
}
