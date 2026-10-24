#!/usr/bin/env python3
import sys
import re
from pathlib import Path

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print("Uso: simdoc <funcion_o_constante>")
        print("Ejemplos:")
        print("  simdoc createPrimitiveShape")
        print("  simdoc primitiveshape")
        print("  simdoc getObject")
        sys.exit(0)

    query = sys.argv[1].strip()
    if query.startswith("sim."):
        query = query[4:]

    stub_path = Path.cwd() / "typings" / "coppeliasim_zmqremoteapi_client" / "__init__.pyi"

    if not stub_path.exists():
        print("Error: No se encontro el archivo de tipos (__init__.pyi) en ./typings.")
        print("Ejecuta 'simstubs' para generarlo a partir de tu instalacion de CoppeliaSim.")
        sys.exit(1)

    with open(stub_path, "r", encoding="utf-8") as f:
        content = f.read()

    func_pattern = rf"def ({re.escape(query)}\(.*?\)\s*->\s*[^:]+:.*?)(?=\n    def |\nclass |\Z)"
    match = re.search(func_pattern, content, re.DOTALL | re.IGNORECASE)

    if match:
        full = match.group(1).strip()
        sig = full.split("\n")[0].strip()
        doc_match = re.search(r'"""(.*?)"""', full, re.DOTALL)
        doc = doc_match.group(1).strip() if doc_match else ""

        print("\033[1;36m" + "=" * 65 + "\033[0m")
        print(f"\033[1;32mFirma:\033[0m \033[1;37msim.{sig}\033[0m\n")
        if doc:
            print("\033[1;33mDocumentacion oficial:\033[0m")
            print(doc)
        print("\033[1;36m" + "=" * 65 + "\033[0m")
        return

    const_pattern = rf"({re.escape(query)}\w*:\s*Final\[int\])"
    matches = re.findall(const_pattern, content, re.IGNORECASE)
    if matches:
        print(f"\033[1;32mConstantes encontradas en CoppeliaSim que coinciden con '{query}':\033[0m")
        for m in matches[:30]:
            cname = m.split(":")[0].strip()
            print(f"  \033[1;34msim.{cname}\033[0m")
        if len(matches) > 30:
            print(f"  ... y {len(matches) - 30} mas.")
        return

    print(f"\033[1;31mNo se encontro \"{query}\" en la API de CoppeliaSim.\033[0m")
    sys.exit(1)

if __name__ == "__main__":
    main()
