#!/usr/bin/env python3
"""
gen_luadoc.py â€” Generate LuaCATS type-annotation stubs for the Lurek2D VS Code extension.

Reads logs/data/lua_api_data.json and emits docs/api/lurek.lua â€” a LuaCATS
stub file that gives the VS Code Lua language server full type information
for the lurek.* API. Consumed by the vscode-extension IntelliSense provider.

Usage:
    python tools/docs/gen_luadoc.py                 # -> docs/api/lurek.lua
"""
import json
import os
import re

from gen_extension_api import BUILTIN_ENUMS, CALLBACKS

# Lua reserved keywords â€” cannot be used as parameter names in stub declarations.
LUA_KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for",
    "function", "goto", "if", "in", "local", "nil", "not", "or",
    "repeat", "return", "then", "true", "until", "while",
}

WORKSPACE_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INPUT_FILE = os.path.join(WORKSPACE_ROOT, "logs", "data", "lua_api_data.json")
OUTPUT_FILE = os.path.join(WORKSPACE_ROOT, "docs", "api", "lurek.lua")

BUILTIN_TYPES = {
    "any", "nil", "boolean", "number", "string", "table",
    "function", "userdata", "thread", "unknown", "self", "LuaValue",
}

UNKNOWN_SENTINEL = "unknown"
DYNAMIC_LUA_TYPE = "LuaValue"

TYPE_NORMALIZATIONS = {
    "any": "any",
    "bool": "boolean",
    "int": "number",
    "u8": "number",
    "u16": "number",
    "u32": "number",
    "u64": "number",
    "usize": "number",
    "isize": "number",
    "f32": "number",
    "f64": "number",
    "index": "number",
    "count": "number",
    "integer": "number",
    "Thread": "ThreadHandle",
    "unknown": DYNAMIC_LUA_TYPE,
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
        return DYNAMIC_LUA_TYPE

    type_name = type_name.strip()
    type_name = re.sub(r"\s*([<>|,{}()\[\]])\s*", r"\1", type_name)

    for old, new in TYPE_NORMALIZATIONS.items():
        type_name = re.sub(rf"\b{re.escape(old)}\b", new, type_name)

    return type_name or DYNAMIC_LUA_TYPE


def extract_return_from_full_doc(full_doc):
    """Extract @return type(s) from a full docstring.

    When multiple ``@return`` lines are present (e.g. one per return value), collect all
    type tokens and join them as a comma-separated list so that write_function_doc can
    emit one ``---@return`` annotation per value.
    """
    types = []
    for line in full_doc.splitlines():
        stripped = line.strip()
        pipe_match = re.match(r"^@return\s*\|\s*([^|]+?)\s*\|\s*(.+)$", stripped)
        if pipe_match:
            types.append(pipe_match.group(1).strip())
    if not types:
        return ""
    if len(types) == 1:
        return types[0]
    # Multiple @return lines â†’ join as comma-separated so parse_returns can split them.
    return ", ".join(types)


def extract_return_entries_from_full_doc(full_doc):
    """Extract typed @return entries with their descriptions from a full docstring."""
    entries = []
    for line in full_doc.splitlines():
        stripped = line.strip()
        pipe_match = re.match(r"^@return\s*\|\s*([^|]+?)\s*\|\s*(.+)$", stripped)
        if not pipe_match:
            continue
        raw_types = pipe_match.group(1).strip()
        description = pipe_match.group(2).strip()
        for part in split_top_level_types(raw_types):
            entries.append((normalize_type(part.strip()), description))
    return entries


def extract_field_entries_from_full_doc(full_doc):
    """Extract @field entries from a full docstring for table return shapes."""
    if not full_doc:
        return []
    entries = []
    for line in full_doc.splitlines():
        stripped = line.strip()
        m = re.match(r"^@field\s*\|\s*(\w+)\s*\|\s*([^|]+?)\s*\|\s*(.+)$", stripped)
        if m:
            entries.append({"name": m.group(1), "type": m.group(2).strip(), "description": m.group(3).strip()})
    return entries


def _derive_class_name(fn_name):
    """Derive a PascalCase class name from a stub function name."""
    if ":" in fn_name:
        owner, method = fn_name.split(":", 1)
        return owner + method[0].upper() + method[1:] + "Result"
    if "." in fn_name:
        parts = fn_name.split(".")
        tail = parts[-2:] if len(parts) >= 2 else parts
        return "".join(p[0].upper() + p[1:] for p in tail) + "Result"
    return fn_name[0].upper() + fn_name[1:] + "Result"


def get_return_entries(fn):
    full_doc_entries = extract_return_entries_from_full_doc(fn.get("full_doc", ""))
    if full_doc_entries:
        return full_doc_entries, True

    ret = parse_returns(fn)
    ret_desc = fn.get("return_description", "").strip()
    if not ret:
        return [], False

    return [(part.strip(), ret_desc) for part in split_top_level_types(ret)], False


def normalize_param_type(type_name, is_optional=False):
    normalized = normalize_type(type_name)
    if normalized.endswith("?"):
        normalized = normalized[:-1] or DYNAMIC_LUA_TYPE
    return normalized


def _normalize_return_text(text):
    normalized = text.strip().lower()
    normalized = re.sub(r"^returns?\s*:?\s*", "", normalized)
    normalized = re.sub(r"\b(a|an|the)\b", " ", normalized)
    normalized = re.sub(r"[^a-z0-9]+", " ", normalized)
    return re.sub(r"\s+", " ", normalized).strip()


def is_redundant_nil_return(ret_type, ret_desc):
    if normalize_type(ret_type) != "nil":
        return False
    normalized = _normalize_return_text(ret_desc)
    return normalized in {
        "no return",
        "no returns",
        "no return value",
        "no return values",
        "no value",
        "no values",
        "no value is returned",
        "no values are returned",
        "nothing",
        "nothing is returned",
        "nothing returned",
        "nil",
    }


def format_return_description(ret_desc):
    cleaned = ret_desc.strip()
    cleaned = re.sub(r"^returns?\s*:?\s*", "", cleaned, flags=re.IGNORECASE)
    return cleaned


def sanitize_return_name(name, fallback):
    cleaned = name.strip().lower()
    cleaned = re.sub(r"[^a-z0-9]+", "_", cleaned)
    cleaned = cleaned.strip("_")
    if not cleaned:
        cleaned = fallback
    if cleaned[0].isdigit():
        cleaned = f"value_{cleaned}"
    if cleaned in LUA_KEYWORDS:
        cleaned = f"{cleaned}_"
    return cleaned


def infer_return_name_candidates(ret_desc):
    normalized = format_return_description(ret_desc).strip().lower()
    if not normalized:
        return []

    pattern_candidates = [
        (r"\bsuccess flag,\s*event name,\s*and\s*payload array\b", ["success", "event_name", "payload"]),
        (r"\bvalidation result flag and array of error records\b", ["ok", "errors"]),
        (r"\bdocumented entry count and live entry count\b", ["documented_count", "live_count"]),
        (r"\bstatus and payload\b", ["status", "payload"]),
        (r"\blatitude,\s*longitude,\s*and\s*zoom\b", ["latitude", "longitude", "zoom"]),
        (r"\bred,\s*green,\s*blue,\s*and\s*alpha\b", ["red", "green", "blue", "alpha"]),
        (r"\bhue,\s*saturation,\s*and\s*lightness\b", ["hue", "saturation", "lightness"]),
        (r"\bconstant,\s*linear,\s*and\s*quadratic\b", ["constant", "linear", "quadratic"]),
        (r"\bwidth and height\b", ["width", "height"]),
        (r"\bspeed and strength\b", ["speed", "strength"]),
        (r"\bx,\s*y,\s*width,\s*and\s*height\b", ["x", "y", "width", "height"]),
        (r"\bminimum x,\s*minimum y,\s*maximum x,\s*and\s*maximum y\b", ["min_x", "min_y", "max_x", "max_y"]),
        (r"\btranslation x,\s*translation y,\s*angle,\s*scale x,\s*and\s*scale y\b", ["translation_x", "translation_y", "angle", "scale_x", "scale_y"]),
        (r"\bx and y\b", ["x", "y"]),
        (r"\bx,\s*y,\s*and\s*z\b", ["x", "y", "z"]),
    ]

    for pattern, candidates in pattern_candidates:
        if re.search(pattern, normalized):
            return candidates

    return []


def infer_single_return_name_candidate(ret_desc):
    normalized = format_return_description(ret_desc).strip().lower()
    if not normalized:
        return None

    phrase_patterns = [
        r"\b(?:the same|new|started|returned|created|updated|current|standalone|requested|registered)\s+([a-z][a-z0-9 /_-]*?)\s+handle\b",
        r"\b([a-z][a-z0-9 /_-]*?)\s+handle\b",
        r"\b(?:the same|new|started|created|current|standalone)\s+([a-z][a-z0-9 /_-]*?)\s+state\b",
        r"\bcopy of (?:the )?([a-z][a-z0-9 /_-]*?)\b(?: at call time)?$",
    ]
    for pattern in phrase_patterns:
        match = re.search(pattern, normalized)
        if match:
            phrase = match.group(1).strip()
            phrase = re.sub(r"\b(?:this|that|current|requested|registered|provided|same|new|started|standalone|active|named|literal|lua-visible|world|agent)\b", " ", phrase)
            phrase = re.sub(r"\b(?:for|of|to|at|the|a|an)\b", " ", phrase)
            phrase = re.sub(r"\s+", " ", phrase).strip()
            if phrase:
                return sanitize_return_name(phrase, "value")

    single_return_patterns = [
        (r"\bcontrol point count\b", "count"),
        (r"\bnoise value\b", "noise"),
        (r"\bangle\b", "angle"),
        (r"\bwidth\b", "width"),
        (r"\bheight\b", "height"),
        (r"\blatitude\b", "latitude"),
        (r"\blongitude\b", "longitude"),
        (r"\bzoom\b", "zoom"),
        (r"\bx(?: |-)?coordinate\b", "x"),
        (r"\by(?: |-)?coordinate\b", "y"),
        (r"\bz(?: |-)?coordinate\b", "z"),
        (r"\bx(?: |-)?position\b", "x"),
        (r"\by(?: |-)?position\b", "y"),
        (r"\bz(?: |-)?position\b", "z"),
        (r"\bx(?: |-)?component\b", "x"),
        (r"\by(?: |-)?component\b", "y"),
        (r"\bz(?: |-)?component\b", "z"),
        (r"\bx(?: |-)?value\b", "x"),
        (r"\by(?: |-)?value\b", "y"),
        (r"\bz(?: |-)?value\b", "z"),
        (r"\bx axis\b", "x"),
        (r"\by axis\b", "y"),
        (r"\bz axis\b", "z"),
        (r"\bred component\b", "r"),
        (r"\bgreen component\b", "g"),
        (r"\bblue component\b", "b"),
        (r"\balpha component\b", "a"),
        (r"\bred channel\b", "r"),
        (r"\bgreen channel\b", "g"),
        (r"\bblue channel\b", "b"),
        (r"\balpha channel\b", "a"),
        (r"\bhorizontal\b", "x"),
        (r"\bvertical\b", "y"),
        (r"\btype name\b", "type_name"),
        (r"\bblackboard\b", "blackboard"),
        (r"\beasing names\b", "easing_names"),
        (r"\bevent tables\b", "events"),
        (r"\bframe count\b", "frame_count"),
        (r"\bclip name\b", "clip_name"),
        (r"\bprogress\b", "progress"),
        (r"\bresult\b", "result"),
        (r"\bexists\b", "exists"),
        (r"\bmatches\b", "matches"),
        (r"\bcontains\b", "contains"),
        (r"\boverlaps\b", "overlaps"),
        (r"\bintersects\b", "intersects"),
        (r"\bis empty\b", "is_empty"),
    ]

    for pattern, candidate in single_return_patterns:
        if re.search(pattern, normalized):
            return candidate

    return None


def infer_return_name(ret_type, ret_desc, index, total, fn_name=None):
    candidates = infer_return_name_candidates(ret_desc)
    if len(candidates) == total:
        return sanitize_return_name(candidates[index], f"value{index + 1}")

    normalized_ret_type = normalize_type(ret_type)
    normalized_ret_desc = format_return_description(ret_desc).strip().lower()

    if total == 1 and normalized_ret_type == "boolean":
        predicate_patterns = [
            (r"\bmatches\b", "matches"),
            (r"\bexists\b", "exists"),
            (r"\bcontains\b", "contains"),
            (r"\boverlaps\b", "overlaps"),
            (r"\bintersects\b", "intersects"),
            (r"\bis empty\b", "is_empty"),
        ]
        for pattern, candidate in predicate_patterns:
            if re.search(pattern, normalized_ret_desc):
                return candidate

    single_candidate = infer_single_return_name_candidate(ret_desc)
    if single_candidate:
        return sanitize_return_name(single_candidate, f"value{index + 1}")

    if total == 1:
        if fn_name:
            bare_name = fn_name.split(":")[-1].split(".")[-1]
            if re.match(r"^(is|has|can)[A-Z_]", bare_name):
                snake = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", bare_name).lower()
                return sanitize_return_name(snake, "result")
            if bare_name in {"contains", "exists", "matches", "intersects", "overlaps"}:
                return sanitize_return_name(bare_name, "result")
        if normalized_ret_type == "table":
            return "result"
        if re.match(r"^L[A-Z]", normalized_ret_type):
            stripped = normalized_ret_type[1:]
            stripped = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", stripped).lower()
            stripped = re.sub(r"^ai_", "", stripped)
            return sanitize_return_name(stripped, "value")
        return None

    return None


def should_emit_return_description(desc, ret_desc):
    if not ret_desc:
        return False
    if not desc:
        return True

    normalized_desc = _normalize_return_text(desc)
    normalized_ret = _normalize_return_text(ret_desc)
    if not normalized_desc or not normalized_ret:
        return True

    return normalized_desc != normalized_ret


def is_low_signal_return_description(ret_desc):
    normalized = _normalize_return_text(ret_desc)
    if normalized in {
        "literal type name",
        "lua visible type name",
        "type name for this userdata",
        "current type name",
    }:
        return True

    if re.match(r"^(same|new|started|current|created|returned|requested|registered)\s+.+\s+(handle|state|widget|object)$", normalized):
        return True

    return False


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
    return UNKNOWN_SENTINEL

def parse_params(fn):
    pkeys = []
    ptype_map = {}
    pdesc_map = {}
    popt_map = {}

    typed = fn.get("typed_params", [])
    if typed:
        for p in typed:
            pname = p[0].strip()
            ptype = p[1].strip() if len(p) > 1 else UNKNOWN_SENTINEL
            is_opt = p[2] if len(p) > 2 else False
            param_desc = p[3].strip() if len(p) > 3 else ""
            pname_clean = pname if pname == "..." else re.sub(r'[^a-zA-Z0-9_]', '', pname.replace(' ', '_'))
            if pname_clean and pname_clean not in pkeys:
                pkeys.append(pname_clean)
                ptype_map[pname_clean] = normalize_param_type(ptype, is_opt)
                popt_map[pname_clean] = is_opt
                if param_desc:
                    pdesc_map[pname_clean] = param_desc
                elif is_opt:
                    pdesc_map[pname_clean] = "(optional)"
                else:
                    pdesc_map[pname_clean] = ""
        return pkeys, ptype_map, pdesc_map, popt_map

    # 1. Start with params_doc
    params_doc = fn.get("params_doc", "")
    for line in params_doc.splitlines():
        # Match lines like `- \`name\`` or `- \`n1\`, \`n2\`` followed by weird characters or typical separators
        m = re.match(r'^-\s+`([^`]+)`(?:,\s*`([^`]+)`)?\s*(?:[-:â€”\u2014]+|Ä‚.Ä‚.Ä‚.|\xef\xbf\xbd.+)?\s*(.*)$', line.strip())
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
                desc = re.sub(r'^(?:[-:â€”\u2014]+|Ä‚.Ä‚.Ä‚.|\xef\xbf\xbd.+)?\s*', '', rest)

            for n in names:
                n_clean = n if n == "..." else re.sub(r'[^a-zA-Z0-9_]', '', n.replace(' ', '_'))
                if n_clean and n_clean not in pkeys:
                    pkeys.append(n_clean)
                    ptype_map[n_clean] = normalize_param_type(guess_type(desc))
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
                        ptype_map[name_clean] = normalize_param_type(UNKNOWN_SENTINEL, is_opt)
                        popt_map[name_clean] = is_opt
                        pdesc_map[name_clean] = "(optional)" if is_opt else ""

    return pkeys, ptype_map, pdesc_map, popt_map


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
        # e.g. "table  {x, y, width, height}" â†’ "table" to avoid heuristic
        # false-matches on description words (e.g. "width, height" â†’ "number, number").
        type_token = re.split(r'\s{2,}', ret_doc)[0].strip()
        # Handle comma-separated primitive type lists, e.g. "@return number, number, number".
        # Without this, guess_type collapses "number, number" to just "number".
        if ',' in type_token and re.match(r'^[a-z][a-z0-9_?|]*(?:,\s*[a-z][a-z0-9_?|]*)*$', type_token):
            return type_token
        res = guess_type(type_token, is_return=True)
        if res != UNKNOWN_SENTINEL:
            return normalize_type(res)
        if re.match(r'^[A-Za-z_][A-Za-z0-9_<>{}, |?]*$', ret_doc):
            return normalize_type(ret_doc)

    inferred = fn.get('inferred_return', '').strip()
    if inferred:
        if inferred == "()":
            return None
        return normalize_type(inferred)
    if ret_doc:
        return DYNAMIC_LUA_TYPE
    return None

def write_function_doc(out, fn, name):
    block_start = len(out)

    desc = fn.get("description", "").strip()
    if desc:
        for line in desc.splitlines():
            out.append(f"--- {line}")

    pkeys, ptyp, pdesc, popt = parse_params(fn)

    # For colon-notation methods, self is implicit in LuaLS — skip it from
    # both annotations and the signature parameter list.
    if ':' in name and pkeys and pkeys[0] == "self":
        pkeys = pkeys[1:]

    param_names = []

    for k in pkeys:
        pd = pdesc.get(k, "")
        t = ptyp.get(k, DYNAMIC_LUA_TYPE)
        k = k.replace("?", "")

        is_optional = popt.get(k, False)

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
                clean_parts = [part.strip() for part in t.split('|') if part.strip() and part.strip() != 'nil']
                clean_t = '|'.join(clean_parts) or DYNAMIC_LUA_TYPE
                if pd and pd != "(optional)":
                    out.append(f"---@param {safe_k}? {clean_t} {pd}".strip())
                else:
                    out.append(f"---@param {safe_k}? {clean_t}".strip())
            elif pd:
                out.append(f"---@param {safe_k} {t} {pd}".strip())
            else:
                out.append(f"---@param {safe_k} {t}".strip())
            param_names.append(safe_k)

    # --- @field → @class generation for table returns ---
    field_entries = extract_field_entries_from_full_doc(fn.get("full_doc", ""))
    generated_class_name = None
    if field_entries:
        generated_class_name = _derive_class_name(name)
        class_block = [f"---@class {generated_class_name}"]
        for fe in field_entries:
            ft = normalize_type(fe["type"])
            fd = fe.get("description", "")
            if fd:
                class_block.append(f"---@field {fe['name']} {ft} {fd}")
            else:
                class_block.append(f"---@field {fe['name']} {ft}")
        class_block.append("")  # blank separator
        for ci, cl in enumerate(class_block):
            out.insert(block_start + ci, cl)

    ret_entries, has_explicit_return_entries = get_return_entries(fn)
    for i, (ret_type, ret_desc) in enumerate(ret_entries):
        if generated_class_name and normalize_type(ret_type) == "table":
            ret_type = generated_class_name
        raw_ret_desc = ret_desc.strip()
        if raw_ret_desc:
            if len(ret_entries) > 1:
                # For multi-return functions, insert a positional single-letter name
                # so that commas in the description are not misinterpreted by LuaLS as
                # additional return type entries (e.g. "X, Y, and Z" would be parsed as
                # types X, Y, Z without an explicit name token separating type from desc).
                pos_name = chr(ord("a") + i) if i < 26 else f"ret{i + 1}"
                out.append(f"---@return {ret_type} {pos_name} {raw_ret_desc}")
            else:
                out.append(f"---@return {ret_type} {raw_ret_desc}")
        else:
            out.append(f"---@return {ret_type}")

    signature = ', '.join(param_names)
    if ':' in name:
        out.append(f"function {name}({signature}) end")
    else:
        out.append(f"{name} = function({signature}) end")
    out.append("")


def write_callback_doc(out, callback):
    desc = callback.get("description", "").strip()
    if desc:
        for line in desc.splitlines():
            out.append(f"--- {line}")

    params = callback.get("parameters", [])
    arg_names = []
    for param in params:
        raw_name = str(param.get("name", "arg")).strip() or "arg"
        safe_name = (raw_name + "_") if raw_name in LUA_KEYWORDS else raw_name
        param_type = normalize_param_type(str(param.get("type", UNKNOWN_SENTINEL)), bool(param.get("optional", False)))
        param_desc = str(param.get("description", "")).strip()
        if param.get("optional", False):
            clean_type = re.sub(r"\|nil$", "", param_type) or DYNAMIC_LUA_TYPE
            if param_desc:
                out.append(f"---@param {safe_name}? {clean_type} {param_desc}".strip())
            else:
                out.append(f"---@param {safe_name}? {clean_type}".strip())
        elif param_desc:
            out.append(f"---@param {safe_name} {param_type} {param_desc}".strip())
        else:
            out.append(f"---@param {safe_name} {param_type}".strip())
        arg_names.append(safe_name)

    signature = ", ".join(arg_names)
    out.append(f"function lurek.{callback['name']}({signature}) end")
    out.append("")

def main():
    if not os.path.exists(INPUT_FILE):
        print(f"API data not found at {INPUT_FILE}")
        return

    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    lua_api = data.get("lua_api", {}).get("modules", {})

    # Maps internal json key â†’ actual Lua namespace (for modules that register under a different name)
    _LUA_NAMESPACE = {}

    source_enums = data.get("lua_api", {}).get("enums") or BUILTIN_ENUMS

    out = []
    out.append("---@meta")
    out.append("--- Auto-generated Lurek2D API documentation for LuaCATS.")
    out.append("")
    out.append("lurek = {}")
    out.append("")
    out.append("---@alias LuaValue nil|boolean|number|string|table|function|userdata|thread")
    out.append("")

    declared_types, referenced_types = collect_declared_and_referenced_types(lua_api)
    opaque_types = sorted(
        token for token in referenced_types
        if token not in declared_types and (token[0].isupper() or token in {"Lua", "LuaValue", "Thread"})
    )

    # Dynamic mlua carrier types normalize to `LuaValue`, a real project alias for
    # unconstrained Lua runtime values.
    # Old-name â†’ L-prefix aliases: if a referenced type "Foo" has a declared counterpart "LFoo",
    # emit an alias instead of a duplicate stub class.  This happens when docstring @return tags
    # still use the pre-L-prefix name.
    #
    # Manual overrides for types whose canonical L-prefix name cannot be derived automatically
    # (casing mismatches, suffix changes, or genuinely internal/non-userdata types).
    _OPAQUE_ALIASES: dict[str, str] = {
        "MultiValue":   DYNAMIC_LUA_TYPE,   # mlua multi-return carrier
        "Environment":  DYNAMIC_LUA_TYPE,   # OS/Lua environment table
        "GID":          "number",  # tilemap global tile ID â€” integer alias
        "ID":           "number",  # generic ID â€” integer alias
        "Radius":       "number",   # plain numeric radius â€” not a userdata type
        "TextureKey":   DYNAMIC_LUA_TYPE,   # internal render key â€” not exposed as userdata
        "Tint":         DYNAMIC_LUA_TYPE,   # plain color tint â€” not a userdata type
        # Struct-name â†’ L-prefix where casing or suffix differs
        "AiFlowField":    "LAIFlowField",    # LuaAiFlowField struct but type() returns LAIFlowField
        "Camera2D":       "LCamera",         # LuaCamera2D struct but type() returns LCamera
        "Edge":           "LGraphEdge",      # LuaEdge shorthand â†’ full graph type
        "Node":           "LGraphNode",      # LuaNode shorthand â†’ full graph type
        "Step":           "LPipelineStep",   # LuaStep shorthand â†’ full pipeline type
        "ThreadHandle":   "LThread",         # LuaThreadHandle â†’ LThread
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

    # Types defined as @class in docs/api/library.lua â€” skip generating aliases for them
    # to avoid 'duplicate-doc-alias' warnings from the Lua language server.
    _SKIP_ALIAS = {"EventBus", "Scheduler", "Stack"}

    # UI widget types that appear only as return types (no class-specific methods)
    # but should still inherit from LUiWidget in the generated stub.
    _UI_OPAQUE_WIDGETS = {"LSpacer"}

    for type_name in opaque_types:
        if type_name in _SKIP_ALIAS:
            continue
        if type_name in _OPAQUE_ALIASES:
            out.append(f"---@alias {type_name} {_OPAQUE_ALIASES[type_name]}")
            out.append("")
        else:
            parent = " : LUiWidget" if type_name in _UI_OPAQUE_WIDGETS else ""
            out.append(f"---@class {type_name}{parent}")
            out.append(f"{type_name} = {{}}")
            out.append("")

    for enum_name in sorted(source_enums.keys()):
        values = source_enums[enum_name]
        if not values:
            continue
        union = "|".join(json.dumps(value) for value in values)
        out.append(f"---@alias {enum_name} {union}")
        out.append("")

    for callback in CALLBACKS:
        write_callback_doc(out, callback)

    # Module-level constants that the Rust parser cannot auto-discover.
    _MODULE_CONSTANTS = {
        "physics": [
            ("CELL_AIR",   "number", "empty air cell (0)"),
            ("CELL_SAND",  "number", "sand cell (1)"),
            ("CELL_WATER", "number", "water cell (2)"),
            ("CELL_ROCK",  "number", "rock cell (3)"),
            ("CELL_FIRE",  "number", "fire cell (4)"),
            ("CELL_GAS",   "number", "gas cell (5)"),
        ],
        "math": [
            ("pi",  "number", "\u03c0 \u2248 3.14159265358979"),
            ("tau", "number", "\u03c4 = 2\u03c0 \u2248 6.28318530717959"),
        ],
        "tilemap": [
            ("FLOOR",      "number", "solid floor tile type (1)"),
            ("NORTH_WALL", "number", "north-facing wall tile type (2)"),
            ("WEST_WALL",  "number", "west-facing wall tile type (3)"),
            ("OBJECT",     "number", "object tile type (4)"),
        ],
        "globe": [
            ("MAX_PROVINCES", "number", "Maximum number of provinces the globe supports."),
            ("LOD_FAR",       "string",  'LOD tier constant "far" â€” zoomed-out view (zoom < 1.5).'),
            ("LOD_MID",       "string",  'LOD tier constant "mid" â€” medium zoom (1.5 \u2264 zoom < 4.0).'),
            ("LOD_NEAR",      "string",  'LOD tier constant "near" â€” close-zoom view (zoom \u2265 4.0).'),
        ],

    }

    # Modules that register functions under nested sub-namespaces.
    # These sub-tables must be declared before their functions are emitted so
    # the Lua language server can resolve lurek.input.keyboard.isDown etc.
    _NESTED_NAMESPACES: dict[str, list[str]] = {
        "input": ["keyboard", "mouse", "gamepad", "touch"],
        "scene": ["transitions"],
    }

    _UI_NON_WIDGET_CLASSES = {
        "LTheme",
        "LLineChart",
        "LBarChart",
        "LScatterPlot",
        "LPieChart",
        "LAreaChart",
        "LUiWidget",
    }

    for mod_name in sorted(lua_api.keys()):
        lua_ns = _LUA_NAMESPACE.get(mod_name, mod_name)
        mod_data = lua_api[mod_name]
        out.append(f"---@class lurek.{lua_ns}")
        for const_name, const_type, const_desc in _MODULE_CONSTANTS.get(mod_name, []):
            out.append(f"---@field {const_name} {normalize_type(const_type)}  {const_desc}")
        out.append(f"lurek.{lua_ns} = {{}}")
        out.append("")
        # Emit declarations for nested sub-namespaces (e.g. lurek.input.keyboard).
        for sub_ns in _NESTED_NAMESPACES.get(mod_name, []):
            out.append(f"---@class lurek.{lua_ns}.{sub_ns}")
            out.append(f"lurek.{lua_ns}.{sub_ns} = {{}}")
            out.append("")

        classes = mod_data.get("classes", {})
        for class_name in sorted(classes.keys()):
            class_data = classes[class_name]
            desc = class_data.get("description", "").strip()
            if desc:
                for line in desc.splitlines():
                    out.append(f"--- {line}")
            class_decl = class_name
            if mod_name == "ui" and class_name not in _UI_NON_WIDGET_CLASSES:
                class_decl = f"{class_name} : LUiWidget"
            out.append(f"---@class {class_decl}")
            # Hardcoded field annotations for types whose fields are Rust struct members
            # not visible to the Rust parser (registered via add_field_method_get).
            if class_name == "LUiWidget":
                out.append("---@field _idx integer  Internal widget pool index.")
            if class_name == "LVec2":
                out.append("---@field x number  x component")
                out.append("---@field y number  y component")
            elif class_name == "LVec3":
                out.append("---@field x number  x component")
                out.append("---@field y number  y component")
                out.append("---@field z number  z component")
            elif class_name == "LTweenState":
                out.append("---@field paused boolean  whether the tween is currently paused")
            out.append(f"{class_name} = {{}}")
            out.append("")

            methods = class_data.get("methods", [])
            methods.sort(key=lambda x: x.get("name", ""))

            for method in methods:
                name = method.get("lua_name", f"{class_name}:{method['name']}")
                # fallback for missing lua_name:
                if ":" not in name and ("." not in name):
                    name = f"{class_name}:{method['name']}"
                # Class methods must use : notation so LuaLS treats self as implicit.
                # Some lua_name values use ClassName.method (dot) instead of ClassName:method.
                elif "." in name and ":" not in name:
                    last_dot = name.rfind(".")
                    name = name[:last_dot] + ":" + name[last_dot + 1:]
                write_function_doc(out, method, name)

        functions = mod_data.get("functions", [])
        functions.sort(key=lambda x: (x.get("kind", "function"), x.get("name", "")))

        for func in functions:
            name = func.get("lua_name", f"lurek.{lua_ns}.{func['name']}")
            if ":" in name:
                continue
            # Remap stored lua_name only when the module folder name differs from
            # the Lua namespace (e.g. timerâ†’time, eventâ†’signal).  When mod_name==lua_ns
            # the lua_name is already correct â€” preserve nested paths (keyboard.isDown etc.).
            if mod_name != lua_ns and name.startswith(f"lurek.{mod_name}."):
                name = f"lurek.{lua_ns}." + name[len(f"lurek.{mod_name}."):]
            write_function_doc(out, func, name)

        # â”€â”€ Particle flat-forwarding wrappers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        # particle_api.rs registers every LParticleSystem method *also* as a module-level
        # function  lurek.particle.METHOD(ps, ...)  via its flat_methods list.  These have
        # no Rust docstrings so they don't appear in the JSON.  Emit type assignments here
        # so LuaLS can resolve  lurek.particle.stop(ps)  without an undefined-field error.
        if mod_name == "particle" and "LParticleSystem" in classes:
            out.append("-- Flat forwarding: lurek.particle.METHOD(ps,...) == ps:METHOD(...)")
            emitted_fns = {f.get("name", "") for f in functions}
            for m in sorted(classes["LParticleSystem"]["methods"], key=lambda x: x.get("name", "")):
                mname = m.get("name", "")
                if mname and mname not in emitted_fns:
                    out.append(f"lurek.particle.{mname} = LParticleSystem.{mname}")
            out.append("")

    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(out))

    print(f"Generated {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
