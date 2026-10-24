# Dev Templates (Nix Flakes)

Colección de plantillas reproducibles y declarativas para entornos de desarrollo bajo demanda usando **Nix Flakes** y **Direnv**.

Sigue la filosofía **Zero Global Dev Tools**: no se instalan compiladores, SDKs ni entornos de ejecución de forma global en el sistema. Cada proyecto declara sus dependencias y las activa automáticamente al entrar al directorio.

---

## 📦 Plantillas Disponibles

| Plantilla | Identificador (`#name`) | Descripción | Herramientas Principales |
| :--- | :--- | :--- | :--- |
| **Python** | `#python` | Entorno moderno con gestión declarativa rápida | `python3`, `uv`, `basedpyright`, `pyright`, `ruff`, `pytest`, `debugpy` |
| **Rust** | `#rust` | Toolchain estable con analizador de código oficial | `rust` (stable), `rust-analyzer`, `clippy`, `rustfmt` |
| **CoppeliaSim** | `#coppelia` | Simulación y robótica Scene-as-Code | ZeroMQ API, `uv`, stubs de tipos (`sim.*`), comando `simdoc`, `lemminx` |
| **Java** | `#java` | Entorno de desarrollo para Java empresarial y académico | `jdk21`, `maven`, `gradle`, `jdtls` (configurado para Linux) |
| **Low Level** | `#low_level` | Desarrollo de sistemas en C, C++ y Rust | `gcc`, `clang-tools`, `cmake`, `bear`, `gdb`, `valgrind`, `strace`, `man-pages` |
| **RustyRTC** | `#rustyrtc` | Streaming de medios y WebRTC en Rust | `rust`, `wayland`, `libglvnd` (OpenGL), `opencv`, `openssl`, `libclang` |

---

## 🚀 Uso Rápido

### 1. Inicializar en un proyecto (Nuevo o Existente)

Puedes inicializar cualquier plantilla ejecutando:

```bash
# En un proyecto nuevo:
mkdir mi-proyecto && cd mi-proyecto
nix flake init -t github:Ponnshe/dev-templates#<plantilla>
direnv allow

# En un proyecto ya existente:
cd /ruta/a/mi-proyecto-existente
nix flake init -t github:Ponnshe/dev-templates#<plantilla>
direnv allow
```

> **Nota:** Si estás dentro de un repositorio de Git, recuerda hacer `git add flake.nix` (o `git add -N flake.nix`) para que Nix pueda reconocer el archivo.

---

## ⚡ Atajo con Nix Registry

Para no escribir la URL completa de GitHub cada vez, puedes registrar un alias local:

```bash
nix registry add templates github:Ponnshe/dev-templates
```

O declarativamente en tu `configuration.nix` de NixOS:

```nix
nix.registry.templates.to = {
  type = "github";
  owner = "Ponnshe";
  repo = "dev-templates";
};
```

Luego, podrás inicializar cualquier entorno simplemente con:

```bash
nix flake init -t templates#python
nix flake init -t templates#rust
nix flake init -t templates#coppelia
```

---

## 🛠️ Herramientas de Mantenimiento (`tools/`)

La carpeta `tools/` contiene scripts utilizados para generar o mantener componentes de las plantillas (por ejemplo `generate_stubs.py` para regenerar los tipos de CoppeliaSim). Estos scripts están excluidos de las plantillas y no se copiarán al inicializar proyectos.
