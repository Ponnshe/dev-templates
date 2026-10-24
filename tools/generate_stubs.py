#!/usr/bin/env python3
"""
Generator script to produce Python type stubs (.pyi) for CoppeliaSim's Remote API.
Extracts functions and docstrings from regularApi.xml and constants from sim-ce-x.lua.
"""

import os
import sys
import glob
import re
import html
import xml.etree.ElementTree as ET
from pathlib import Path


def clean_html(text: str) -> str:
    if not text:
        return ""
    # Convert <br>, <p>, <li> to newlines / list items
    text = re.sub(r'<br\s*/?>', '\n', text)
    text = re.sub(r'</?p>', '\n', text)
    text = re.sub(r'<li>', '\n  * ', text)
    text = re.sub(r'</li>', '', text)
    text = re.sub(r'<[^>]+>', '', text)
    text = html.unescape(text)
    # Normalize multiple newlines and spaces
    lines = [line.strip() for line in text.splitlines()]
    non_empty = []
    for line in lines:
        if line:
            non_empty.append(line)
    return "\n".join(non_empty)


def map_type(t: str) -> str:
    t = t.strip()
    mapping = {
        'int': 'int',
        'float': 'float',
        'double': 'float',
        'string': 'str',
        'bool': 'bool',
        'list': 'list[Any]',
        'map': 'dict[str, Any]',
        'buffer': 'bytes',
        'any': 'Any',
    }
    return mapping.get(t, 'Any')


def parse_params(param_str: str) -> str:
    if not param_str.strip():
        return ""
    
    parts = []
    # Split by comma respecting brackets/parentheses
    current = []
    depth = 0
    for char in param_str:
        if char in '([{\'"':
            depth += 1
            current.append(char)
        elif char in ')]}\'"':
            depth -= 1
            current.append(char)
        elif char == ',' and depth == 0:
            parts.append("".join(current).strip())
            current = []
        else:
            current.append(char)
    if current:
        parts.append("".join(current).strip())

    parsed = []
    for p in parts:
        if not p:
            continue
        # handle default values: e.g. "int options = 0", "list color = None", "int options=0"
        default = None
        if '=' in p:
            p_decl, default = p.split('=', 1)
            p_decl = p_decl.strip()
            default = default.strip()
            # Normalize default values
            if default == 'None':
                default = 'None'
            elif default == 'nil':
                default = 'None'
            elif default == 'pi':
                default = '3.14159265'
            elif re.match(r'^\[.*\]$', default):
                # Fix list literal like [0 1, 0] or {1, 1, 0}
                default = re.sub(r'([0-9\.]+)\s+([0-9\.]+)', r'\1, \2', default)
            elif default.startswith('{') and default.endswith('}'):
                default = '[' + default[1:-1] + ']'
        else:
            p_decl = p.strip()

        tokens = p_decl.split()
        if len(tokens) >= 2:
            ptype = map_type(tokens[0])
            pname = tokens[1]
        elif len(tokens) == 1:
            pname = tokens[0]
            ptype = 'Any'
        else:
            continue

        # Sanitize parameter name
        pname = re.sub(r'[^a-zA-Z0-9_]', '', pname)
        if pname in ('from', 'import', 'global', 'def', 'class', 'return', 'pass', 'lambda'):
            pname = f"{pname}_"

        if default is not None:
            parsed.append(f"{pname}: {ptype} = ...")
        else:
            parsed.append(f"{pname}: {ptype}")

    return ", ".join(parsed)


def main():
    if "-h" in sys.argv or "--help" in sys.argv:
        print("Uso: simstubs [ruta_coppeliasim] [directorio_salida]")
        print("Por defecto busca CoppeliaSim en /nix/store y genera en ./typings")
        sys.exit(0)

    # 1. Locate CoppeliaSim directory
    coppelia_dir = None
    target_dir = Path.cwd()

    if len(sys.argv) > 1 and Path(sys.argv[1]).exists():
        coppelia_dir = Path(sys.argv[1])
        if len(sys.argv) > 2:
            target_dir = Path(sys.argv[2])
    else:
        if len(sys.argv) > 1:
            target_dir = Path(sys.argv[1])
        candidates = [
            Path(p) for p in glob.glob("/nix/store/*-Coppelia-nix-*")
            if not p.endswith(".drv") and (Path(p) / "manual" / "regularApi.xml").exists()
        ]
        if candidates:
            coppelia_dir = candidates[-1]

    if not coppelia_dir or not coppelia_dir.exists():
        print("Aviso: No se encontró el directorio de CoppeliaSim en /nix/store.")
        print("Asegúrate de tener CoppeliaSim instalado en NixOS para poder generar stubs.")
        sys.exit(1)

    print(f"Using CoppeliaSim from: {coppelia_dir}")
    xml_path = coppelia_dir / "manual" / "regularApi.xml"
    lua_path = coppelia_dir / "lua" / "sim-ce-x.lua"

    if not xml_path.exists():
        print(f"Error: {xml_path} does not exist.")
        sys.exit(1)

    # 2. Extract constants from sim-ce-x.lua
    constants = set()
    if lua_path.exists():
        with open(lua_path, 'r', errors='ignore') as f:
            for line in f:
                line = line.strip()
                if line.startswith("sim.") and "(" not in line and "=" not in line:
                    cname = line.replace("sim.", "").strip()
                    if re.match(r'^[a-zA-Z0-9_]+$', cname):
                        constants.add(cname)
    print(f"Found {len(constants)} constants.")

    # 3. Parse functions from regularApi.xml
    tree = ET.parse(xml_path)
    root = tree.getroot()

    functions = []
    for func in root.findall('function'):
        syn = func.find('api-synopsis-python')
        if syn is None or not syn.text:
            continue

        name_el = func.find('api-function-name')
        raw_name = name_el.text.strip() if name_el is not None and name_el.text else ""
        if "sim." in raw_name:
            fname = raw_name.split("sim.")[1]
        else:
            fname = raw_name
        if not fname or not re.match(r'^[a-zA-Z0-9_]+$', fname):
            continue

        stext = " ".join(syn.text.split())

        # Determine return type and call part
        if '=' in stext:
            ret_part, call_part = stext.split('=', 1)
            ret_part = ret_part.strip()
            call_part = call_part.strip()
            ret_items = [x.strip() for x in ret_part.split(',') if x.strip()]
            ret_types = []
            for item in ret_items:
                tokens = item.split()
                if tokens:
                    ret_types.append(map_type(tokens[0]))
                else:
                    ret_types.append('Any')
            if len(ret_types) == 1:
                ret_str = ret_types[0]
            else:
                ret_str = f"tuple[{', '.join(ret_types)}]"
        else:
            call_part = stext.strip()
            ret_str = "None"

        # Extract parameters from call_part: sim.foo(args...)
        m = re.search(r'\((.*)\)', call_part)
        params_str = m.group(1) if m else ""
        parsed_params = parse_params(params_str)

        # Documentation
        desc_el = func.find('api-description')
        desc = clean_html(desc_el.text) if desc_el is not None and desc_el.text else ""

        in_el = func.find('api-input-python-lua')
        in_desc = clean_html(ET.tostring(in_el, encoding='unicode', method='text')) if in_el is not None else ""

        out_el = func.find('api-output-python-lua')
        out_desc = clean_html(ET.tostring(out_el, encoding='unicode', method='text')) if out_el is not None else ""

        doc_parts = []
        if desc:
            doc_parts.append(desc)
        if in_desc:
            doc_parts.append(f"\nParameters:\n{in_desc}")
        if out_desc:
            doc_parts.append(f"\nReturns:\n{out_desc}")
        full_doc = "\n\n".join(doc_parts).strip()

        functions.append({
            'name': fname,
            'params': parsed_params,
            'return': ret_str,
            'doc': full_doc,
        })

    print(f"Extracted {len(functions)} Python API functions.")

    # 4. Generate .pyi content
    out_dir = target_dir / "typings" / "coppeliasim_zmqremoteapi_client"
    out_dir.mkdir(parents=True, exist_ok=True)
    stub_file = out_dir / "__init__.pyi"
    typed_file = out_dir / "py.typed"

    with open(stub_file, "w", encoding="utf-8") as out:
        out.write('"""\nType stub for coppeliasim_zmqremoteapi_client.\nGenerated automatically from CoppeliaSim documentation.\n"""\n\n')
        out.write('from typing import Any, Literal, overload, Final\n\n')

        out.write('class Sim:\n')
        out.write('    """CoppeliaSim core API (`sim`)."""\n\n')

        # Write constants
        out.write('    # --- Constants ---\n')
        for c in sorted(constants):
            out.write(f'    {c}: Final[int]\n')
        out.write('\n')

        # Write functions
        out.write('    # --- Functions ---\n')
        for f in sorted(functions, key=lambda x: x['name']):
            fname = f['name']
            params = f['params']
            ret = f['return']
            doc = f['doc']

            method_sig = f"    def {fname}(self"
            if params:
                method_sig += f", {params}"
            method_sig += f") -> {ret}:"

            out.write(f"{method_sig}\n")
            if doc:
                doc_escaped = doc.replace('"""', r'\"\"\"')
                out.write('        """\n')
                for line in doc_escaped.splitlines():
                    out.write(f'        {line}\n')
                out.write('        """\n')
            out.write('        ...\n\n')

        # Write RemoteAPIClient
        out.write('\nclass RemoteAPIClient:\n')
        out.write('    """Client to connect to CoppeliaSim\'s ZeroMQ Remote API."""\n\n')
        out.write('    def __init__(self, host: str = "localhost", port: int = 23000, cntport: int | None = None, *, verbose: int | None = None) -> None: ...\n')
        out.write('    @overload\n')
        out.write('    def require(self, name: Literal["sim"]) -> Sim: ...\n')
        out.write('    @overload\n')
        out.write('    def require(self, name: str) -> Any: ...\n')
        out.write('    def require(self, name: str) -> Any: ...\n')
        out.write('    def getObject(self, name: str) -> Any: ...\n')
        out.write('    def call(self, func: str, args: list[Any]) -> Any: ...\n')
        out.write('    def step(self, wait: bool = True) -> None: ...\n')
        out.write('    def setStepping(self, enable: bool = True) -> None: ...\n\n')

        out.write('__all__ = ["RemoteAPIClient", "Sim"]\n')

    typed_file.touch(exist_ok=True)
    print(f"Stubs written successfully to: {stub_file}")


if __name__ == "__main__":
    main()
