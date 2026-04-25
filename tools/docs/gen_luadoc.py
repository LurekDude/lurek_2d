#!/usr/bin/env python3
"""
gen_luadoc.py — Generate LuaCATS type-annotation stubs for the Lurek2D VS Code extension.

Reads logs/data/lua_api_data.json and emits docs/api/lurek.lua — a LuaCATS
stub file that gives the VS Code Lua language server full type information
for the lurek.* API. Consumed by the vscode-extension IntelliSense provider.

Usage:
    python tools/docs/gen_luadoc.py                 # -> docs/api/lurek.lua
"""
import json
import os
import re

# Lua reserved keywords — cannot be used as parameter names in stub declarations.
LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for",
    "function", "goto", "if", "in", "local", "nil", "not", "or",
    "repeat", "return", "then", "true", "until", "while",
}

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INPUT_FILE = os.path.join(WORKSPACE_ROOT, "logs", "data", "lua_api_data.json")
OUTPUT_FILE = os.path.join(WORKSPACE_ROOT, "docs", "api", "lurek.lua")

BUILTIN_TYPES = {
    "any", "nil", "boolean", "number", "integer", "string", "table",
    "function", "userdata", "thread", "unknown", "self",
}

TYPE_NORMALIZATIONS = {
    "bool": "boolean",
    "int": "integer",
    "u8": "integer",
    "u16": "integer",
    "u32": "integer",
    "u64": "integer",
    "usize": "integer",
    "isize": "integer",
    "f32": "number",
    "f64": "number",
    "index": "integer",
    "count": "integer",
    "Thread": "ThreadHandle",
    "void": "nil",
}


def split_top_level_types(text):
    parts = []
    current = []
    depth_angle = 0
    depth_brace = 0
    depth_paren = 0
    depth_bracket = 0

    for ch in text:
        if ch == "<":
            depth_angle += 1
        elif ch == ">" and depth_angle > 0:
            depth_angle -= 1
        elif ch == "{":
            depth_brace += 1
        elif ch == "}" and depth_brace > 0:
            depth_brace -= 1
        elif ch == "(":
            depth_paren += 1
        elif ch == ")" and depth_paren > 0:
            depth_paren -= 1
        elif ch == "[":
            depth_bracket += 1
        elif ch == "]" and depth_bracket > 0:
            depth_bracket -= 1

        if ch == "," and depth_angle == 0 and depth_brace == 0 and depth_paren == 0 and depth_bracket == 0:
            part = "".join(current).strip()
            if part:
                parts.append(part)
            current = []
            continue

        current.append(ch)

    tail = "".join(current).strip()
    if tail:
        parts.append(tail)
    return parts


def normalize_type(type_name):
    if not type_name:
        return "any"

    type_name = type_name.strip()
    type_name = re.sub(r"\s*([<>|,{}()\[\]])\s*", r"\1", type_name)

    for old, new in TYPE_NORMALIZATIONS.items():
        type_name = re.sub(rf"\b{re.escape(old)}\b", new, type_name)

    return type_name or "any"


def extract_return_from_full_doc(full_doc):
    for line in full_doc.splitlines():
        match = re.match(r"^@return\s+(.+?)\s*$", line.strip())
        if match:
            return match.group(1).strip()
    return ""


def normalize_param_type(type_name, is_optional=False):
    normalized = normalize_type(type_name)
    optional = is_optional or normalized.endswith("?")
    if normalized.endswith("?"):
        normalized = normalized[:-1] or "any"
    if optional and normalized != "nil" and "|nil" not in normalized:
        normalized = f"{normalized}|nil"
    return normalized


def collect_declared_and_referenced_types(lua_api):
    declared = set(BUILTIN_TYPES)
    referenced = set()

    def collect_from_type(type_name):
        normalized = normalize_type(type_name)
        for token in re.findall(r"[A-Za-z_][A-Za-z0-9_]*", normalized):
            lowered = token.lower()
            if lowered in BUILTIN_TYPES or token == "lurek":
                continue
            referenced.add(token)

    for mod_name, mod_data in lua_api.items():
        declared.add(mod_name)
        for class_name, class_data in mod_data.get("classes", {}).items():
            declared.add(class_name)
            for method in class_data.get("methods", []):
                for param in method.get("typed_params", []):
                    if len(param) > 1:
                        collect_from_type(param[1])
                collect_from_type(method.get("inferred_return", ""))
        for func in mod_data.get("functions", []):
            for param in func.get("typed_params", []):
                if len(param) > 1:
                    collect_from_type(param[1])
            collect_from_type(func.get("inferred_return", ""))

    return declared, referenced

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
            return "LQuad, number, number"

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
        return "LImage"
    elif "font" in t:
        return "LFont"
    elif "canvas" in t:
        return "LCanvas"
    elif "spritebatch" in t:
        return "LSpriteBatch"
    elif "mesh" in t:
        return "LMesh"
    elif "shader" in t:
        return "LShader"
    elif "sounddata" in t:
        return "LSoundData"
    elif "imagedata" in t:
        return "LImageData"
    elif "quad" in t:
        return "LQuad"
    elif "filehandle" in t:
        return "LFileHandle"
    elif "audio source" in t or "audiosource" in t or "source" in t:
        return "LSource"
    return "any"

def parse_params(fn):
    pkeys = []
    ptype_map = {}
    pdesc_map = {}

    typed = fn.get("typed_params", [])
    if typed:
        for p in typed:
            pname = p[0].strip()
            ptype = p[1].strip() if len(p) > 1 else "any"
            is_opt = p[2] if len(p) > 2 else False
            pname_clean = pname if pname == "..." else re.sub(r'[^a-zA-Z0-9_]', '', pname.replace(' ', '_'))
            if pname_clean and pname_clean not in pkeys:
                pkeys.append(pname_clean)
                ptype_map[pname_clean] = normalize_param_type(ptype, is_opt)
                pdesc_map[pname_clean] = "(optional)" if is_opt else ""
        return pkeys, ptype_map, pdesc_map

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
                        ptype_map[name_clean] = normalize_param_type("any", is_opt)
                        pdesc_map[name_clean] = "(optional)" if is_opt else ""

    return pkeys, ptype_map, pdesc_map

def parse_returns(fn):
    ret_doc = fn.get('returns_doc', '').strip()
    if not ret_doc:
        ret_doc = extract_return_from_full_doc(fn.get('full_doc', ''))

    if ret_doc:
        # If it looks like a class/type name (starts with uppercase), use it directly
        # without the heuristic guess_type, which can false-match on substrings like "y".
        if ret_doc and ret_doc[0].isupper():
            return normalize_type(ret_doc)
        # Extract just the type token (before 2+ spaces / inline description).
        # e.g. "table  {x, y, width, height}" → "table" to avoid heuristic
        # false-matches on description words (e.g. "width, height" → "number, number").
        type_token = re.split(r'\s{2,}', ret_doc)[0].strip()
        res = guess_type(type_token, is_return=True)
        if res != "any":
            return normalize_type(res)
        if re.match(r'^[A-Za-z_][A-Za-z0-9_<>{}, |?]*$', ret_doc):
            return normalize_type(ret_doc)

    inferred = fn.get('inferred_return', '').strip()
    if inferred:
        if inferred == "()":
            return None
        return normalize_type(inferred)
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
        pd = pdesc.get(k, "")
        t = ptyp.get(k, "any")
        k = k.replace("?", "")

        is_optional = pd == "(optional)"

        if k == "...":
            if pd:
                out.append(f"---@param ... {t} {pd}".strip())
            else:
                out.append(f"---@param ... {t}".strip())
            param_names.append("...")
        else:
            safe_k = (k + "_") if k in LUA_KEYWORDS else k
            if is_optional:
                # LuaCATS optional syntax: name? type (NOT name type|nil)
                clean_t = re.sub(r"\|nil$", "", t) or "any"
                out.append(f"---@param {safe_k}? {clean_t}".strip())
            elif pd:
                out.append(f"---@param {safe_k} {t} {pd}".strip())
            else:
                out.append(f"---@param {safe_k} {t}".strip())
            param_names.append(safe_k)

    ret = parse_returns(fn)
    if ret:
        ret_parts = split_top_level_types(ret)
        if len(ret_parts) > 1:
            for r in ret_parts:
                out.append(f"---@return {r.strip()}")
        else:
            out.append(f"---@return {ret}")

    signature = ', '.join(param_names)
    if ':' in name:
        out.append(f"function {name}({signature}) end")
    else:
        out.append(f"{name} = function({signature}) end")
    out.append("")

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"API data not found at {INPUT_FILE}")
        return

    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    lua_api = data.get("lua_api", {}).get("modules", {})

    # Maps internal json key → actual Lua namespace (for modules that register under a different name)
    _LUA_NAMESPACE = {
        "timer":      "time",
        "event":      "signal",
        "automation": "simulator",
    }

    out = []
    out.append("---@meta")
    out.append("--- Auto-generated Lurek2D API documentation for LuaCATS.")
    out.append("")
    out.append("lurek = {}")
    out.append("")

    declared_types, referenced_types = collect_declared_and_referenced_types(lua_api)
    opaque_types = sorted(
        token for token in referenced_types
        if token not in declared_types and (token[0].isupper() or token in {"Lua", "LuaValue", "Thread"})
    )

    # LuaValue is mlua's dynamic value type — alias to `any` so LuaLS treats it correctly.
    # Old-name → L-prefix aliases: if a referenced type "Foo" has a declared counterpart "LFoo",
    # emit an alias instead of a duplicate stub class.  This happens when docstring @return tags
    # still use the pre-L-prefix name.
    #
    # Manual overrides for types whose canonical L-prefix name cannot be derived automatically
    # (casing mismatches, suffix changes, or genuinely internal/non-userdata types).
    _OPAQUE_ALIASES: dict[str, str] = {
        "LuaValue":     "any",   # mlua's dynamic value — not a Lurek userdata type
        "MultiValue":   "any",   # mlua multi-return — not a Lurek userdata type
        "Environment":  "any",   # OS/Lua environment table — not a Lurek userdata type
        "GID":          "integer",  # tilemap global tile ID — integer alias
        "ID":           "integer",  # generic ID — integer alias
        "Radius":       "number",   # plain numeric radius — not a userdata type
        "TextureKey":   "any",   # internal render key — not exposed as userdata
        "Tint":         "any",   # plain color tint — not a userdata type
        # Struct-name → L-prefix where casing or suffix differs
        "AiFlowField":  "LAIFlowField",  # LuaAiFlowField struct but type() returns LAIFlowField
        "Camera2D":     "LCamera",       # LuaCamera2D struct but type() returns LCamera
        "Edge":         "LGraphEdge",    # LuaEdge shorthand → full graph type
        "Node":         "LGraphNode",    # LuaNode shorthand → full graph type
        "Step":         "LPipelineStep", # LuaStep shorthand → full pipeline type
        "ThreadHandle": "LThread",       # LuaThreadHandle → LThread
    }
    # Auto-derive: if a referenced type "Foo" has a declared counterpart "LFoo" (exact match),
    # alias it.  Case-insensitive fallback for minor capitalisation differences.
    _l_declared_lower = {("l" + n[1:]).lower(): n for n in declared_types if n.startswith("L")}
    for type_name in opaque_types:
        if type_name in _OPAQUE_ALIASES:
            continue
        lname = "L" + type_name
        if lname in declared_types:
            _OPAQUE_ALIASES[type_name] = lname
        else:
            candidate = ("l" + type_name).lower()
            if candidate in _l_declared_lower:
                _OPAQUE_ALIASES[type_name] = _l_declared_lower[candidate]

    for type_name in opaque_types:
        if type_name in _OPAQUE_ALIASES:
            out.append(f"---@alias {type_name} {_OPAQUE_ALIASES[type_name]}")
            out.append("")
        else:
            out.append(f"---@class {type_name}")
            out.append(f"{type_name} = {{}}")
            out.append("")

    # Module-level constants that the Rust parser cannot auto-discover.
    _MODULE_CONSTANTS = {
        "physics": [
            ("CELL_AIR",   "integer", "empty air cell (0)"),
            ("CELL_SAND",  "integer", "sand cell (1)"),
            ("CELL_WATER", "integer", "water cell (2)"),
            ("CELL_ROCK",  "integer", "rock cell (3)"),
            ("CELL_FIRE",  "integer", "fire cell (4)"),
            ("CELL_GAS",   "integer", "gas cell (5)"),
        ],
    }

    for mod_name in sorted(lua_api.keys()):
        lua_ns = _LUA_NAMESPACE.get(mod_name, mod_name)
        mod_data = lua_api[mod_name]
        out.append(f"---@class lurek.{lua_ns}")
        for const_name, const_type, const_desc in _MODULE_CONSTANTS.get(mod_name, []):
            out.append(f"---@field {const_name} {const_type}  {const_desc}")
        out.append(f"lurek.{lua_ns} = {{}}")
        out.append("")

        classes = mod_data.get("classes", {})
        for class_name in sorted(classes.keys()):
            class_data = classes[class_name]
            desc = class_data.get("description", "").strip()
            if desc:
                for line in desc.splitlines():
                    out.append(f"--- {line}")
            out.append(f"---@class {class_name}")
            out.append(f"{class_name} = {{}}")
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
            name = func.get("lua_name", f"lurek.{lua_ns}.{func['name']}")
            if ":" in name:
                continue
            # Remap stored lua_name if it uses the old module-folder namespace
            if name.startswith(f"lurek.{mod_name}."):
                name = f"lurek.{lua_ns}.{func['name']}"
            write_function_doc(out, func, name)

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(out))

    print(f"Generated {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
