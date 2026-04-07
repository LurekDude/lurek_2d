#!/usr/bin/env python3
"""
gen_luadoc.py — Generate LuaCATS type-annotation stubs for the Luna2D VS Code extension.

Reads docs/API/lua_api_data.json and emits docs/API/luna.lua — a LuaCATS
stub file that gives the VS Code Lua language server full type information
for the luna.* API. Consumed by the vscode-extension IntelliSense provider.

Usage:
    python tools/docs/gen_luadoc.py                 # -> docs/API/luna.lua
"""
import json
import os
import re

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INPUT_FILE = os.path.join(WORKSPACE_ROOT, "docs", "API", "lua_api_data.json")
OUTPUT_FILE = os.path.join(WORKSPACE_ROOT, "docs", "API", "luna.lua")

def guess_type(text, is_return=False):
    t = text.lower()
    if is_return:
        if "two numbers" in t or "width, height" in t or "x, y" in t or "x and y" in t:
            return "number, number"
        elif "two strings" in t or "min, mag" in t:
            return "string, string"
        elif "width, height, channels" in t:
            return "number, number, number"
        if "quad, x, y" in t:
            return "Quad, number, number"

    if "string" in t or "path" in t or "filename" in t or "mode" in t:
        return "string"
    elif "int" in t or "number" in t or "float" in t or "id" in t or "index" in t or "radius" in t or "width" in t or "height" in t or "x" in t or "y" in t or "angle" in t or "scale" in t:
        return "number"
    elif "bool" in t or "true" in t or "false" in t:
        return "boolean"
    elif "table" in t:
        return "table"
    elif "function" in t or "callback" in t:
        return "function"
    elif "image" in t:
        return "Image"
    elif "font" in t:
        return "Font"
    elif "canvas" in t:
        return "Canvas"
    elif "spritebatch" in t:
        return "SpriteBatch"
    elif "mesh" in t:
        return "Mesh"
    elif "shader" in t:
        return "Shader"
    elif "sounddata" in t:
        return "SoundData"
    elif "imagedata" in t:
        return "ImageData"
    elif "quad" in t:
        return "Quad"
    elif "filehandle" in t:
        return "FileHandle"
    elif "audio source" in t or "audiosource" in t or "source" in t:
        return "Source"
    return "any"

def parse_params(fn):
    pkeys = []
    ptype_map = {}
    pdesc_map = {}

    # 1. Start with params_doc
    params_doc = fn.get("params_doc", "")
    for line in params_doc.splitlines():
        # Match lines like `- \`name\`` or `- \`n1\`, \`n2\`` followed by weird characters or typical separators
        m = re.match(r'^-\s+`([^`]+)`(?:,\s*`([^`]+)`)?\s*(?:[-:—\u2014]+|Ă.Ă.Ă.|\xef\xbf\xbd.+)?\s*(.*)$', line.strip())
        if not m:
            m = re.match(r'^-\s+`([^`]+)`(.*?)$', line.strip())

        if m:
            names = []
            desc = ""
            if len(m.groups()) == 3:
                n1, n2, parsed_desc = m.groups()
                names.append(n1)
                if n2: names.append(n2)
                desc = parsed_desc
            else:
                n1, rest = m.groups()
                names.append(n1)
                desc = re.sub(r'^(?:[-:—\u2014]+|Ă.Ă.Ă.|\xef\xbf\xbd.+)?\s*', '', rest)

            for n in names:
                n_clean = n if n == "..." else re.sub(r'[^a-zA-Z0-9_]', '', n.replace(' ', '_'))
                if n_clean and n_clean not in pkeys:
                    pkeys.append(n_clean)
                    ptype_map[n_clean] = guess_type(desc)
                    pdesc_map[n_clean] = desc.strip()

    # 2. Fallback to inferred_sig if params_doc yielded nothing
    if not pkeys:
        inferred_sig = fn.get("inferred_sig", "").strip()
        if inferred_sig.startswith("(") and inferred_sig.endswith(")"):
            inner = inferred_sig[1:-1].strip()
            if inner:
                parts = [p.strip() for p in inner.split(',')]
                for p in parts:
                    is_opt = False
                    name = p
                    if name.startswith('[') and name.endswith(']'):
                        name = name[1:-1].strip()
                        is_opt = True
                    elif name.endswith('?'):
                        name = name[:-1].strip()
                        is_opt = True

                    name_clean = name if name == "..." else re.sub(r'[^a-zA-Z0-9_]', '', name.replace(' ', '_'))
                    if name_clean and name_clean not in pkeys:
                        pkeys.append(name_clean)
                        ptype_map[name_clean] = "any"
                        pdesc_map[name_clean] = "(optional)" if is_opt else ""

    # 3. Fallback to typed_params if both empty (this handles edge cases)
    if not pkeys:
        typed = fn.get("typed_params", [])
        if typed:
            for p in typed:
                pname = p[0].strip()
                ptype = p[1].strip() if len(p) > 1 else "any"
                is_opt = p[2] if len(p) > 2 else False
                pname_clean = pname if pname == "..." else re.sub(r'[^a-zA-Z0-9_]', '', pname.replace(' ', '_'))
                if pname_clean not in pkeys:
                    pkeys.append(pname_clean)
                    ptype_map[pname_clean] = ptype
                    pdesc_map[pname_clean] = "(optional)" if is_opt else ""

    return pkeys, ptype_map, pdesc_map

def parse_returns(fn):
    ret_doc = fn.get('returns_doc', '').strip()
    if ret_doc:
        res = guess_type(ret_doc, is_return=True)
        if res != "any":
            return res
    inferred = fn.get('inferred_return', '').strip()
    if inferred:
        if inferred == "()":
            return None
        parts = inferred.split(',')
        if len(parts) > 1:
            return ', '.join([guess_type(p, is_return=False) if guess_type(p, is_return=False) != "any" else "any" for p in parts])
        return inferred
    if ret_doc:
        return "any"
    return None

def write_function_doc(out, fn, name):
    desc = fn.get("description", "").strip()
    if desc:
        for line in desc.splitlines():
            out.append(f"--- {line}")

    pkeys, ptyp, pdesc = parse_params(fn)
    param_names = []

    for k in pkeys:
        opt = ""
        pd = pdesc.get(k, "")
        t = ptyp.get(k, "any")

        if "?" in k or "optional" in pd.lower():
            opt = "?"
            k = k.replace("?", "")

        if k == "...":
            if pd:
                out.append(f"---@param ... {t} {pd}".strip())
            else:
                out.append(f"---@param ... {t}".strip())
            param_names.append("...")
        else:
            if pd:
                out.append(f"---@param {k}{opt} {t} {pd}".strip())
            else:
                out.append(f"---@param {k}{opt} {t}".strip())
            param_names.append(k)

    ret = parse_returns(fn)
    if ret:
        if "," in ret:
            for r in ret.split(','):
                out.append(f"---@return {r.strip()}")
        else:
            out.append(f"---@return {ret}")

    out.append(f"function {name}({', '.join(param_names)}) end")
    out.append("")

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"API data not found at {INPUT_FILE}")
        return

    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    lua_api = data.get("lua_api", {}).get("modules", {})

    out = []
    out.append("---@meta")
    out.append("--- Auto-generated Luna2D API documentation for LuaCATS.")
    out.append("")
    out.append("luna = {}")
    out.append("")

    for mod_name in sorted(lua_api.keys()):
        mod_data = lua_api[mod_name]
        out.append(f"---@class luna.{mod_name}")
        out.append(f"luna.{mod_name} = {{}}")
        out.append("")

        classes = mod_data.get("classes", {})
        for class_name in sorted(classes.keys()):
            class_data = classes[class_name]
            desc = class_data.get("description", "").strip()
            if desc:
                for line in desc.splitlines():
                    out.append(f"--- {line}")
            out.append(f"---@class {class_name}")
            out.append(f"local {class_name} = {{}}")
            out.append("")

            methods = class_data.get("methods", [])
            methods.sort(key=lambda x: x.get("name", ""))

            for method in methods:
                name = method.get("lua_name", f"{class_name}:{method['name']}")
                # fallback for missing lua_name:
                if ":" not in name and ("." not in name):
                    name = f"{class_name}:{method['name']}"
                write_function_doc(out, method, name)

        functions = mod_data.get("functions", [])
        functions.sort(key=lambda x: (x.get("kind", "function"), x.get("name", "")))

        for func in functions:
            name = func.get("lua_name", f"luna.{mod_name}.{func['name']}")
            if ":" in name:
                continue
            write_function_doc(out, func, name)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(out))

    print(f"Generated {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
