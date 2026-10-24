# Entorno de Desarrollo CoppeliaSim + Python (Nix Flake)

Plantilla de desarrollo reproducible y declarativa para proyectos de simulación y robótica con **CoppeliaSim** y **Python**, orientada a un flujo de trabajo **Scene-as-Code** (construcción y control de escenas mediante código, minimizando la interacción con la GUI de CoppeliaSim).

---

## 🎯 ¿Qué hace este Flake y cómo está pensado para ser usado?

### Propósito
Siguiendo la filosofía **Zero Global Dev Tools** del sistema:
1. **Cero dependencias globales:** No necesitas instalar Python, compiladores, ni librerías en tu sistema base de NixOS. Todo vive aislado y reproducible dentro del proyecto.
2. **Automatización con `uv`:** Al entrar al directorio, inicializa automáticamente `pyproject.toml` e instala en un entorno virtual (`.venv`) las dependencias básicas (`coppeliasim-zmqremoteapi-client` y `lxml`).
3. **Tipado Estático Dinámico y Reproducible (`simstubs`):** En lugar de arrastrar archivos de tipos estáticos en Git, el entorno incluye el comando `simstubs`. Al entrar a un proyecto, genera automáticamente `./typings` leyendo la versión exacta de CoppeliaSim instalada en `/nix/store`. Si actualizas CoppeliaSim en tu sistema, solo corres `simstubs` para refrescar la API al instante.
4. **Inspección Rápida de API (`simdoc`):** Comando de terminal incluido para consultar firmas de funciones, docstrings oficiales y constantes de CoppeliaSim al instante.
5. **Soporte XML / URDF / SDF:** Incluye `lemminx` (LSP de XML) y `libxml2` (`xmllint`) para escribir, validar y formatear archivos de descripción de robots y escenas sin errores de sintaxis.

### Flujo de Trabajo Recomendado (Scene-as-Code)
Este entorno está pensado para evitar la pérdida de tiempo buscando botones y menús en la interfaz de CoppeliaSim:
* **Escribir / Generar la Escena:** Describes tus modelos en archivos XML/URDF/SDF o escribes scripts en Python con `lxml` que instancian primitivas, articulaciones y mallas.
* **Control Remoto vía ZeroMQ:** Un script de Python se comunica con CoppeliaSim (que puede correr en segundo plano o en modo *headless* con `-h`) mediante la ZeroMQ Remote API para cargar modelos, reiniciar la física e iniciar la simulación.
* **Feedback Inmediato:** Editas tus scripts o modelos en Neovim, ejecutas el script o recarga automática, y ves el resultado en la simulación sin tocar el ratón.

## 🛠️ Comandos y Herramientas Disponibles

Una vez dentro del entorno (vía `direnv` o `nix develop`):

| Comando | Descripción |
| :--- | :--- |
| `simstubs` | Genera o actualiza los stubs de tipado en `./typings` leyendo tu CoppeliaSim local de `/nix/store` |
| `simdoc <consulta>` | Busca funciones o constantes de CoppeliaSim. Ej: `simdoc createPrimitiveShape` o `simdoc shape_` |
| `uv add <paquete>` | Añade una librería a `pyproject.toml` e instala en el `.venv`. Ej: `uv add numpy matplotlib` |
| `uv run <script.py>` | Ejecuta un script dentro del entorno virtual |
| `python <script.py>` | Ejecuta directamente usando el Python del `.venv` activo |
| `xmllint --format <archivo.xml>` | Formatea y valida archivos XML/URDF/SDF |
| `ruff check .` / `ruff format .` | Linter y formateador ultrarrápido de código Python |

---

## 📂 Archivos y Carpetas a Ignorar en Git (`.gitignore`)

La plantilla incluye un archivo `.gitignore.example`. Los proyectos que usen este flake deben ignorar:

```gitignore
# Entorno virtual gestionado por uv
.venv/

# Caché del cargador de entorno de Nix
.direnv/

# Tipos autogenerados bajo demanda (se generan con simstubs)
typings/

# Bloqueos locales y archivos generados
__pycache__/
*.py[cod]
*$py.class

# Caché de linters y pruebas
.pytest_cache/
.ruff_cache/
```

> **Nota sobre Git:**  
> Asegúrate de hacer commit de `flake.nix`, `.envrc`, `pyproject.toml` y `uv.lock`. La carpeta `typings/` **no** necesita commitearse porque es un artefacto derivado que `simstubs` genera en 0.2 segundos directamente desde tu versión de CoppeliaSim.
