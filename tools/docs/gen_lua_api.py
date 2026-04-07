#!/usr/bin/env python3
"""
gen_lua_api.py — Generate Luna2D Lua API reference from Rust source code.

Parses src/lua_api/*.rs files, extracts all registered Lua functions and
userdata methods by scanning for .set("name", lua.create_function(...))
and methods.add_method("name", ...) patterns. Associates each function
with preceding /// docstrings.

Usage:
    python tools/gen_lua_api.py                     # -> docs/API/lua_api_reference_generated.md
    python tools/gen_lua_api.py --output FILE       # custom output path
    python tools/gen_lua_api.py --src DIR           # custom source directory
    python tools/gen_lua_api.py --check             # validate docstring coverage
    python tools/gen_lua_api.py --json              # structured JSON output
    python tools/gen_lua_api.py --help              # show this help

Exit codes:
    0  - success
    1  - missing docstrings (--check only)
    2  - fatal error (bad arguments, missing source directory)
"""

import argparse
import json
import re
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import Dict, List, Optional

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
SRC_LUA_API_DIR = WORKSPACE_ROOT / "src" / "lua_api"
OUTPUT_FILE = WORKSPACE_ROOT / "docs" / "API" / "lua_api_reference_generated.md"


@dataclass
class LuaFunction:
    """Represents one Lua-callable function or method."""
    module: str
    name: str
    lua_name: str
    owner_type: str
    description: str
    full_doc: str
    params: str
    returns: str
    line: int
    file: str
    kind: str  # "function" or "method"
    inferred_sig: str = field(default="")  # parameter signature inferred from Rust closure
    typed_params: list = field(default_factory=list)  # [(name, lua_type, is_optional), ...]
    inferred_return: str = field(default="")           # "bool", "Card", "table", "" etc.


def _collect_docstring_above(lines: List[str], line_idx: int) -> str:
    """Collect /// docstring lines above a given line index."""
    doc_parts: List[str] = []
    j = line_idx - 1
    while j >= 0:
        stripped = lines[j].strip()
        if stripped.startswith("///"):
            text = stripped[3:]
            doc_parts.insert(0, text[1:] if text.startswith(" ") else text)
        elif stripped.startswith("#[") or stripped == "":
            pass
        elif re.match(r"^let\s+\w+\s*=\s*\w+\.clone\(\)\s*;$", stripped):
            # Skip the `let s = state.clone();` bridge lines common in luna2d API files
            pass
        elif stripped.startswith("//") and not stripped.startswith("///"):
            # Skip plain // comments (e.g. // luna.graphics.X(…) inline signature notes)
            pass
        else:
            break
        j -= 1
    # De-duplicate: keep only the last (closest to the set() call) copy of each line,
    # in case the tooling previously inserted triple-duplicate docstrings
    seen: set = set()
    deduped: List[str] = []
    for line in doc_parts:
        if line not in seen:
            seen.add(line)
            deduped.append(line)
    return "\n".join(deduped).strip()


def _extract_params_returns(docstring: str) -> tuple:
    """Extract # Parameters and # Returns sections from a docstring."""
    params = ""
    returns = ""
    if not docstring:
        return params, returns
    doc_lines = docstring.split("\n")
    current_section = None
    section_lines: Dict[str, List[str]] = {}
    for line in doc_lines:
        m = re.match(r'^#\s+(.+)$', line)
        if m:
            current_section = m.group(1).lower()
            section_lines[current_section] = []
        elif current_section:
            section_lines[current_section].append(line)
    if "parameters" in section_lines:
        params = "\n".join(section_lines["parameters"]).strip()
    if "returns" in section_lines:
        returns = "\n".join(section_lines["returns"]).strip()
    return params, returns


# ── Signature inference ──────────────────────────────────────────────────────

# Rust -> Lua type map
_RUST_TO_LUA: Dict[str, str] = {
    "f32": "number", "f64": "number",
    "i32": "integer", "i64": "integer", "u32": "integer", "u64": "integer",
    "usize": "integer", "isize": "integer",
    "String": "string", "&str": "string", "LuaString": "string",
    "bool": "boolean",
    "LuaTable": "table",
    "LuaValue": "any",
    "LuaFunction": "function",
    "()": "nil",
}


def _rust_type_to_lua(rust_type: str) -> str:
    """Convert a Rust type string to a brief Lua type hint."""
    rust_type = rust_type.strip()
    # Handle Option<T>
    opt_m = re.match(r"Option<(.+)>", rust_type)
    if opt_m:
        inner = _rust_type_to_lua(opt_m.group(1))
        return f"{inner}?"
    # Handle Vec<T>
    vec_m = re.match(r"Vec<(.+)>", rust_type)
    if vec_m:
        return "table"
    return _RUST_TO_LUA.get(rust_type, rust_type)







def _parse_tagged_params(docstring: str) -> list:
    """Parse ``@param name : type`` lines from a /// docstring.

    Returns a list of ``(name, lua_type, is_optional)`` tuples where
    ``is_optional`` is ``True`` when the type ends with ``?`` (e.g. ``Card?``).

    Expected format in Rust ///::

        /// @param name : Type  Optional description.
    """
    result = []
    for line in docstring.splitlines():
        m = re.match(r"@param\s+(\w+)\s*:\s*(\S+)", line.strip())
        if m:
            name = m.group(1)
            lua_type = m.group(2).rstrip(",.")
            is_optional = lua_type.endswith("?")
            result.append((name, lua_type, is_optional))
    return result


def _parse_tagged_return(docstring: str) -> str:
    """Parse ``@return type`` from a /// docstring.

    Returns the type string (e.g. ``"bool"``, ``"Card?"``, ``"string"``) or
    ``""`` when no ``@return`` tag is present.

    Expected format in Rust ///::

        /// @return Type  Optional description.
    """
    for line in docstring.splitlines():
        m = re.match(r"@return\s+(\S+)", line.strip())
        if m:
            return m.group(1).rstrip(",.")
    return ""



def collect_class_descriptions(api_file: Path) -> Dict[str, str]:
    """Return {display_class_name: first_doc_line} for all pub struct LuaXxx and impl LuaUserData for LuaXxx types.

    The display name strips the leading ``Lua`` prefix: ``LuaCard`` → ``Card``.
    Checks ``pub struct LuaXxx`` first; then falls back to ``impl LuaUserData for LuaXxx``
    so that UserData types defined elsewhere (e.g. src/ai/) get descriptions too.
    """
    try:
        lines = api_file.read_text(encoding="utf-8").splitlines()
    except OSError:
        return {}

    def _collect_doc_above(lines, i):
        """Collect first /// description line from directly above line i."""
        j = i - 1
        doc_parts: List[str] = []
        while j >= 0:
            stripped = lines[j].strip()
            if stripped.startswith("///"):
                text = stripped[3:].lstrip(" ")
                doc_parts.insert(0, text)
            elif stripped.startswith("#[") or stripped == "":
                pass
            else:
                break
            j -= 1
        return doc_parts[0].strip() if doc_parts else ""

    result: Dict[str, str] = {}

    # Pass 1: pub struct LuaXxx (highest priority — struct-level docs)
    for i, line in enumerate(lines):
        m = re.match(r"\s*pub struct (Lua\w+)", line)
        if not m:
            continue
        struct_name = m.group(1)
        class_name = struct_name[3:] if struct_name.startswith("Lua") else struct_name
        desc = _collect_doc_above(lines, i)
        if desc:
            result[class_name] = desc

    # Pass 2: impl LuaUserData for LuaXxx (fallback for types defined in other src/ files)
    for i, line in enumerate(lines):
        m = re.search(r"impl\s+LuaUserData\s+for\s+(Lua\w+)", line)
        if not m:
            continue
        struct_name = m.group(1)
        class_name = struct_name[3:] if struct_name.startswith("Lua") else struct_name
        if class_name in result:
            continue  # already found via pub struct
        desc = _collect_doc_above(lines, i)
        if desc:
            result[class_name] = desc

    return result


def _infer_signature(lines: List[str], decl_line: int) -> str:
    """
    Attempt to infer a Lua-style parameter signature from the Rust closure
    definition that starts at or near decl_line (0-based).

    Returns a string like "(x, y, width, height)" or "" if not parseable.
    """
    # Search only the current closure header. Scanning arbitrary following lines
    # causes zero-arg methods like getName() to inherit params from the next
    # declaration, which produces stale or invented signatures in the docs.
    search_parts: List[str] = []
    found_pipe = False
    pipe_count = 0
    for line in lines[decl_line : decl_line + 6]:
        stripped = line.strip()
        if not found_pipe:
            if "|" not in stripped:
                continue
            found_pipe = True
        search_parts.append(stripped)
        pipe_count += stripped.count("|")
        if pipe_count >= 2:
            break

    search_text = " ".join(search_parts)
    if not search_text:
        return ""

    # Pattern: |_, (a, b): (TypeA, TypeB)| or |_, this, (a, b): (TypeA, TypeB)|
    structured_m = re.search(
        r"\|[^|]*?,\s*\(([^)]+)\):\s*\(([^)]+)\)",
        search_text,
    )
    if structured_m:
        names = [n.strip().lstrip("_") for n in structured_m.group(1).split(",")]
        types_raw = [t.strip() for t in structured_m.group(2).split(",")]
        parts = []
        for name, t in zip(names, types_raw):
            lua_t = _rust_type_to_lua(t)
            if lua_t.endswith("?"):
                parts.append(f"[{name}]")
            else:
                parts.append(name)
        return "(" + ", ".join(parts) + ")"

    # Scalar param: |_, a: TypeA|
    scalar_m = re.search(
        r"\|[^|]*?,\s*([a-z_][a-z0-9_]*):\s*([A-Za-z][A-Za-z0-9_<>, ]+?)\|",
        search_text,
    )
    if scalar_m:
        name = scalar_m.group(1).lstrip("_")
        lua_t = _rust_type_to_lua(scalar_m.group(2))
        if lua_t.endswith("?"):
            return f"([{name}])"
        return f"({name})"

    # (name,): (Type,) — single param in tuple form
    single_tuple_m = re.search(
        r"\|[^|]*?,\s*\(([a-z_][a-z0-9_]*)\s*,?\):\s*\(([^)]+)\)",
        search_text,
    )
    if single_tuple_m:
        name = single_tuple_m.group(1).lstrip("_")
        lua_t = _rust_type_to_lua(single_tuple_m.group(2))
        if lua_t.endswith("?"):
            return f"([{name}])"
        return f"({name})"

    # No params: |_, ()| or |_, this, ()|
    no_param_m = re.search(r"\|[^|]*?,\s*(?:[a-z_]+,\s*)?\(\s*\)", search_text)
    if no_param_m:
        return "()"

    return ""


# ── Module-level doc extraction ────────────────────────────────────────────────


def _collect_module_doc(api_file: Path) -> str:
    """Return the leading //! block of an api file as a plain string."""
    try:
        lines = api_file.read_text(encoding="utf-8").splitlines()
    except OSError:
        return ""
    doc_parts: List[str] = []
    for raw in lines:
        stripped = raw.strip()
        if stripped.startswith("//!"):
            text = stripped[3:]
            doc_parts.append(text[1:] if text.startswith(" ") else text)
        elif doc_parts:
            break
    return "\n".join(doc_parts).strip()


def _determine_module_name(api_file: Path) -> str:
    stem = api_file.stem.replace("_api", "")
    return stem


def extract_lua_functions(api_file: Path) -> List[LuaFunction]:
    """Parse a lua_api/*.rs file and extract all registered Lua functions."""
    try:
        content = api_file.read_text(encoding="utf-8")
    except Exception as e:
        print(f"Error reading {api_file}: {e}", file=sys.stderr)
        return []

    lines = content.splitlines()
    module = _determine_module_name(api_file)
    rel_path = str(api_file.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
    functions: List[LuaFunction] = []
    current_impl_type: Optional[str] = None
    current_widget_type: Optional[str] = None
    brace_depth = 0

    type_names = {}
    c_struct = None
    for l in lines:
        if "impl" in l and "LunaType for" in l:
            m = re.search(r'impl(?:<[^>]*>)?\s+(?:LunaType\s+for\s+)?(\w+)', l)
            if m: c_struct = m.group(1)
        if c_struct and 'const TYPE_NAME' in l:
            m2 = re.search(r'const\s+TYPE_NAME.*?=\s*"([^"]+)"', l)
            if m2:
                type_names[c_struct] = m2.group(1)
                c_struct = None

    set_multiline_re = re.compile(r'(\w+)\.set\(\s*$')
    set_inline_re = re.compile(r'(\w+)\.set\(\s*"(\w+)"\s*,\s*lua\.create_function')
    # NEW: named fn reference pattern — .set("luaName", lua.create_function(fn_name)?)
    set_named_fn_re = re.compile(
        r'\.set\(\s*"(\w+)"\s*,\s*lua\.create_function\(\s*(\w+)\s*\??\)'
    )
    name_next_re = re.compile(r'^\s*"(\w+)"\s*,')
    method_re = re.compile(r'methods\.add_method(?:_mut)?\(\s*"(\w+)"')
    # NEW: Self:: reference pattern — methods.add_method("luaName", Self::fn_name)
    method_self_re = re.compile(
        r'methods\.add_method(?:_mut)?\(\s*"(\w+)"\s*,\s*Self::(\w+)'
    )
    impl_re = re.compile(r'^\s*impl(?:<[^>]*>)?\s+(?:LuaUserData\s+for\s+)?(\w+)')
    add_method_re = re.compile(r'fn\s+add_(\w+)_methods\(')

    def _find_pub_fn_docstring(fn_name: str) -> Optional[str]:
        """Find `pub fn fn_name(` in the file and return its docstring."""
        pub_fn_pat = re.compile(r'pub fn ' + re.escape(fn_name) + r'\s*[<(]')
        for idx2, ln2 in enumerate(lines):
            if pub_fn_pat.search(ln2):
                return _collect_docstring_above(lines, idx2)
        return None

    i = 0
    while i < len(lines):
        stripped = lines[i].strip()

        if not stripped.startswith("//"):
            brace_depth += stripped.count("{") - stripped.count("}")

        impl_m = impl_re.match(stripped)
        if impl_m:
            current_impl_type = impl_m.group(1)

        add_m = add_method_re.search(stripped)
        if add_m:
            w_type = add_m.group(1).title()     # e.g. "button" -> "Button"
            current_widget_type = w_type

        add_m = add_method_re.search(stripped)
        if add_m:
            w_type = add_m.group(1).title()     # e.g. "button" -> "Button"
            current_widget_type = w_type

        if brace_depth <= 0:
            current_impl_type = None
            brace_depth = 0

        # Multi-line set pattern
        set_m = set_multiline_re.search(stripped)
        if set_m and i + 1 < len(lines):
            next_stripped = lines[i + 1].strip()
            name_m = name_next_re.match(next_stripped)
            if name_m:
                func_name = name_m.group(1)
                is_func = any("create_function" in lines[k] for k in range(i + 1, min(i + 5, len(lines))))
                if is_func:
                    docstring = _collect_docstring_above(lines, i)
                    owner = current_widget_type if current_widget_type else ""
                    kind = "method" if owner else "function"
                    lua_name = f"{owner}:{func_name}" if owner else f"luna.{module}.{func_name}"

                    if not docstring and owner:
                        docstring = f"/// Returns a value for {func_name} (auto-generated)."

                    desc = docstring.split("\n")[0] if docstring else ""
                    params, returns = _extract_params_returns(docstring)
                    inferred = _infer_signature(lines, i)

                    functions.append(LuaFunction(
                        module=module, name=func_name,
                        lua_name=lua_name,
                        owner_type=owner, description=desc,
                        full_doc=docstring, params=params,
                        returns=returns, line=i + 1,
                        file=rel_path, kind=kind,
                        inferred_sig=inferred,
                        typed_params=_parse_tagged_params(docstring),
                        inferred_return=_parse_tagged_return(docstring),
                    ))

        # Single-line set pattern
        set_inline_m = set_inline_re.search(stripped)
        if set_inline_m:
            func_name = set_inline_m.group(2)
            docstring = _collect_docstring_above(lines, i)
            owner = current_widget_type if current_widget_type else ""
            kind = "method" if owner else "function"
            lua_name = f"{owner}:{func_name}" if owner else f"luna.{module}.{func_name}"

            if not docstring and owner:
                docstring = f"/// Returns a value for {func_name} (auto-generated)."

            desc = docstring.split("\n")[0] if docstring else ""
            params, returns = _extract_params_returns(docstring)
            inferred = _infer_signature(lines, i)

            functions.append(LuaFunction(
                module=module, name=func_name,
                lua_name=lua_name,
                owner_type=owner, description=desc,
                full_doc=docstring, params=params,
                returns=returns, line=i + 1,
                file=rel_path, kind=kind,
                inferred_sig=inferred,
                typed_params=_parse_tagged_params(docstring),
                inferred_return=_parse_tagged_return(docstring),
            ))

        # Userdata methods — existing pattern (docstring directly above the add_method line)
        method_m = method_re.search(stripped)
        if method_m and not method_self_re.search(stripped):
            func_name = method_m.group(1)
            owner = current_impl_type or "Unknown"
            display_owner = type_names.get(owner, owner.replace("Lua", "") if owner.startswith("Lua") else owner)
            docstring = _collect_docstring_above(lines, i)
            desc = docstring.split("\n")[0] if docstring else ""
            params, returns = _extract_params_returns(docstring)
            inferred = _infer_signature(lines, i)
            functions.append(LuaFunction(
                module=module, name=func_name,
                lua_name=f"{display_owner}:{func_name}",
                owner_type=display_owner, description=desc,
                full_doc=docstring, params=params,
                returns=returns, line=i + 1,
                file=rel_path, kind="method",
                inferred_sig=inferred,
                typed_params=_parse_tagged_params(docstring),
                inferred_return=_parse_tagged_return(docstring),
            ))

        # NEW: methods.add_method("luaName", Self::fn_name) — named fn pattern
        method_self_m = method_self_re.search(stripped)
        if method_self_m:
            func_name = method_self_m.group(1)   # Lua name (string key)
            rust_fn   = method_self_m.group(2)   # Rust fn name after Self::
            owner = current_impl_type or "Unknown"
            display_owner = type_names.get(owner, owner.replace("Lua", "") if owner.startswith("Lua") else owner)
            # Look up docstring on the named pub fn declaration
            docstring = _find_pub_fn_docstring(rust_fn) or _collect_docstring_above(lines, i)
            desc = docstring.split("\n")[0] if docstring else ""
            params, returns = _extract_params_returns(docstring)
            inferred = _infer_signature(lines, i)
            functions.append(LuaFunction(
                module=module, name=func_name,
                lua_name=f"{display_owner}:{func_name}",
                owner_type=display_owner, description=desc,
                full_doc=docstring, params=params,
                returns=returns, line=i + 1,
                file=rel_path, kind="method",
                inferred_sig=inferred,
                typed_params=_parse_tagged_params(docstring),
                inferred_return=_parse_tagged_return(docstring),
            ))

        # NEW: .set("luaName", lua.create_function(named_fn)?) — named fn reference
        set_named_m = set_named_fn_re.search(stripped)
        if set_named_m:
            func_name = set_named_m.group(1)    # Lua name (string key)
            rust_fn   = set_named_m.group(2)    # Rust fn name reference
            # Skip if already handled by set_inline_re (anonymous closure)
            if not set_inline_re.search(stripped) or rust_fn:
                owner = current_widget_type if current_widget_type else ""
                kind = "method" if owner else "function"
                lua_name = f"{owner}:{func_name}" if owner else f"luna.{module}.{func_name}"
                # Look up docstring from the named pub fn declaration
                docstring = _find_pub_fn_docstring(rust_fn) or _collect_docstring_above(lines, i)
                desc = docstring.split("\n")[0] if docstring else ""
                params, returns = _extract_params_returns(docstring)
                inferred = _infer_signature(lines, i)
                functions.append(LuaFunction(
                    module=module, name=func_name,
                    lua_name=lua_name,
                    owner_type=owner, description=desc,
                    full_doc=docstring, params=params,
                    returns=returns, line=i + 1,
                    file=rel_path, kind=kind,
                    inferred_sig=inferred,
                    typed_params=_parse_tagged_params(docstring),
                    inferred_return=_parse_tagged_return(docstring),
                ))

        i += 1
    return functions


def collect_all_functions(src_dir: Path) -> Dict[str, List[LuaFunction]]:
    all_functions: Dict[str, List[LuaFunction]] = {}
    for rs_file in sorted(src_dir.rglob("*_api.rs")):
        functions = extract_lua_functions(rs_file)
        for func in functions:
            all_functions.setdefault(func.module, []).append(func)
    return all_functions


def render_json(all_functions: Dict[str, List[LuaFunction]]) -> str:
    items = []
    for module, funcs in sorted(all_functions.items()):
        for func in sorted(funcs, key=lambda f: (f.owner_type, f.name)):
            items.append({
                "module": func.module, "name": func.name,
                "lua_name": func.lua_name, "owner_type": func.owner_type,
                "kind": func.kind, "description": func.description,
                "full_doc": func.full_doc, "params": func.params,
                "returns": func.returns, "line": func.line,
                "file": func.file,
            })
    summary = {}
    for module, funcs in all_functions.items():
        mf = [f for f in funcs if f.kind == "function"]
        mm = [f for f in funcs if f.kind == "method"]
        documented = sum(1 for f in funcs if f.description)
        summary[module] = {
            "functions": len(mf), "methods": len(mm),
            "total": len(funcs), "documented": documented,
            "undocumented": len(funcs) - documented,
        }
    return json.dumps({"summary": summary, "functions": items}, indent=2, ensure_ascii=False)


# Canonical module display order
_MODULE_ORDER = [
    "graphics", "graphics_ext", "window", "input",
    "timer", "math", "math_ext",
    "audio", "physics", "filesystem", "particle",
    "event", "system", "thread",
    "ai", "compute", "dataframe",
    "data", "image", "sound", "graph", "tilemap",
]


def generate_markdown(all_functions: Dict[str, List[LuaFunction]], src_dir: Path = SRC_LUA_API_DIR) -> str:
    output = []
    # Build a lookup: module_name -> api_file Path (supports subdirectories)
    api_file_map: Dict[str, Path] = {}
    for rs_file in src_dir.rglob("*_api.rs"):
        mod_name = rs_file.stem.replace("_api", "")
        api_file_map[mod_name] = rs_file
    output.append("# Luna2D Lua API Reference")
    output.append("")
    output.append("> Auto-generated by `tools/gen_lua_api.py`. Do not edit by hand.")
    output.append("> Re-run the script after changing `///` docstrings in `src/lua_api/*.rs`.")
    output.append("")

    # ── Coverage summary ─────────────────────────────────────────────────────
    total_funcs = sum(len(f) for f in all_functions.values())
    total_docs = sum(1 for funcs in all_functions.values() for f in funcs if f.description)
    pct = (total_docs / total_funcs * 100) if total_funcs else 0
    output.append(f"> **Coverage:** {total_docs}/{total_funcs} functions documented ({pct:.0f}%)")
    output.append("")

    # ── Table of Contents ────────────────────────────────────────────────────
    output.append("## Contents")
    output.append("")
    output.append("| Module | Functions | Methods | Documented |")
    output.append("|--------|-----------|---------|------------|")

    seen: set = set()
    ordered_modules: List[str] = []
    for mod in _MODULE_ORDER:
        if mod in all_functions:
            seen.add(mod)
            ordered_modules.append(mod)
    for mod in sorted(all_functions.keys()):
        if mod not in seen:
            ordered_modules.append(mod)

    for mod in ordered_modules:
        funcs = all_functions[mod]
        n_funcs = sum(1 for f in funcs if f.kind == "function")
        n_methods = sum(1 for f in funcs if f.kind == "method")
        n_docs = sum(1 for f in funcs if f.description)
        anchor = mod.replace("_", "-")
        output.append(f"| [`luna.{mod}`](#{anchor}) | {n_funcs} | {n_methods} | {n_docs}/{len(funcs)} |")
    output.append("")

    # ── Callbacks ────────────────────────────────────────────────────────────
    output.append("## Callbacks")
    output.append("")
    output.append("These functions are called by the engine automatically:")
    output.append("")
    output.append("| Callback | Description |")
    output.append("|----------|-------------|")
    output.append("| `luna.load()` | Called once after the script is loaded |")
    output.append("| `luna.update(dt)` | Called every frame; `dt` is elapsed seconds |")
    output.append("| `luna.draw()` | Called every frame for rendering |")
    output.append("| `luna.keypressed(key)` | Called when a keyboard key is pressed |")
    output.append("| `luna.keyreleased(key)` | Called when a keyboard key is released |")
    output.append("| `luna.mousepressed(x, y, button)` | Called when a mouse button is pressed |")
    output.append("| `luna.mousereleased(x, y, button)` | Called when a mouse button is released |")
    output.append("| `luna.touchpressed(id, x, y, dx, dy, pressure)` | Called on touch start |")
    output.append("| `luna.touchmoved(id, x, y, dx, dy, pressure)` | Called on touch move |")
    output.append("| `luna.touchreleased(id, x, y, dx, dy, pressure)` | Called on touch end |")
    output.append("| `luna.resize(w, h)` | Called when window is resized |")
    output.append("| `luna.focus(focused)` | Called when window gains/loses focus |")
    output.append("| `luna.quit()` | Called when the window is closed |")
    output.append("| `luna.gamepadpressed(id, button)` | Called on gamepad button press |")
    output.append("| `luna.gamepadreleased(id, button)` | Called on gamepad button release |")
    output.append("| `luna.gamepadaxis(id, axis, value)` | Called on gamepad axis change |")
    output.append("")

    for mod in ordered_modules:
        api_file = api_file_map.get(mod, src_dir / f"{mod}_api.rs")
        module_doc = _collect_module_doc(api_file) if api_file.exists() else ""
        _render_module(output, mod, all_functions[mod], module_doc)

    return "\n".join(output)


def _render_function_entry(
    output: list, heading: str, func: LuaFunction, src_base: str = ""
) -> None:
    """Render a single function or method entry."""
    # Determine display signature
    if func.params:
        # Docstring has explicit params — parse first line to see if it's a sig
        first_param_line = func.params.split("\n")[0].strip()
        display_sig = func.inferred_sig or ""
    else:
        display_sig = func.inferred_sig

    output.append(f"#### `{heading}{display_sig}`")
    output.append("")

    if func.description:
        output.append(func.description)
        if func.full_doc.count("\n") > 0:
            # Additional paragraphs from the full doc beyond the first line
            extra_lines = func.full_doc.split("\n")[1:]
            extra_paragraphs: List[str] = []
            buf: List[str] = []
            for ln in extra_lines:
                ln_stripped = ln.strip()
                if re.match(r"^#\s+", ln_stripped):
                    break  # stop before sections; rendered below
                if ln_stripped:
                    buf.append(ln_stripped)
                elif buf:
                    extra_paragraphs.append(" ".join(buf))
                    buf = []
            if buf:
                extra_paragraphs.append(" ".join(buf))
            for para in extra_paragraphs:
                output.append("")
                output.append(para)
        output.append("")
    else:
        output.append("*(undocumented)*")
        output.append("")

    if func.params:
        output.append("**Parameters:**")
        output.append("")
        for pl in func.params.split("\n"):
            if pl.strip():
                output.append(pl)
        output.append("")
    elif display_sig and display_sig not in ("()", ""):
        # Show inferred params as a lightweight note
        param_names = [p.strip().strip("[]") for p in display_sig.strip("()").split(",") if p.strip()]
        output.append("**Parameters:** " + ", ".join(f"`{p}`" for p in param_names))
        output.append("")

    if func.returns:
        output.append(f"**Returns:** {func.returns}")
        output.append("")

    # Source link
    fwd = func.file.replace("\\", "/")
    output.append(f"*Source: [{fwd}]({fwd}#L{func.line})*")
    output.append("")
    output.append("---")
    output.append("")


def _render_module(output: list, module: str, funcs: List[LuaFunction], module_doc: str = "") -> None:
    anchor = module.replace("_", "-")
    output.append(f"## luna.{module}")
    output.append("")

    if module_doc:
        # First line summary
        first_line = module_doc.split("\n")[0]
        output.append(first_line)
        rest = module_doc[len(first_line):].strip()
        if rest:
            output.append("")
            output.append(rest)
        output.append("")

    module_funcs = sorted([f for f in funcs if f.kind == "function"], key=lambda f: f.name)
    methods_by_type: Dict[str, List[LuaFunction]] = {}
    for f in funcs:
        if f.kind == "method":
            methods_by_type.setdefault(f.owner_type, []).append(f)

    n_docs = sum(1 for f in funcs if f.description)
    output.append(f"*{len(funcs)} entries | {n_docs} documented*")
    output.append("")

    if module_funcs:
        output.append("### Functions")
        output.append("")
        for func in module_funcs:
            heading = f"luna.{module}.{func.name}"
            _render_function_entry(output, heading, func)

    for type_name in sorted(methods_by_type.keys()):
        type_methods = sorted(methods_by_type[type_name], key=lambda f: f.name)
        output.append(f"### {type_name} Methods")
        output.append("")
        for func in type_methods:
            heading = func.lua_name
            _render_function_entry(output, heading, func)
    output.append("")


def main():
    parser = argparse.ArgumentParser(
        description="Generate Luna2D Lua API reference from Rust docstrings",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--output", type=Path, default=OUTPUT_FILE,
                        help="Output file path")
    parser.add_argument("--src", type=Path, default=SRC_LUA_API_DIR,
                        help="Source directory")
    parser.add_argument("--check", action="store_true",
                        help="Check for missing docstrings")
    parser.add_argument("--json", action="store_true",
                        help="Output structured JSON instead of Markdown")
    args = parser.parse_args()

    if not args.src.is_dir():
        print(f"Error: Source directory not found: {args.src}", file=sys.stderr)
        return 2

    all_functions = collect_all_functions(args.src)
    total = sum(len(f) for f in all_functions.values())

    if args.check:
        missing = 0
        for module, funcs in sorted(all_functions.items()):
            for func in funcs:
                if not func.description:
                    print(f"Missing docstring: {func.lua_name} ({func.file}:{func.line})")
                    missing += 1
        documented = total - missing
        pct = (documented / total * 100) if total else 100
        print(f"\nLua API coverage: {documented}/{total} ({pct:.1f}%)")
        if missing > 0:
            print(f"Total missing docstrings: {missing}", file=sys.stderr)
            return 1
        print(f"[OK] All {total} Lua functions have docstrings")
        return 0

    if args.json:
        j = render_json(all_functions)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(j, encoding="utf-8")
        try:
            out_display = args.output.relative_to(WORKSPACE_ROOT)
        except ValueError:
            out_display = args.output
        print(f"[OK] Generated JSON for {total} Lua functions -> {out_display}")
        return 0

    markdown = generate_markdown(all_functions, args.src)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(markdown, encoding="utf-8")
    try:
        out_display = args.output.relative_to(WORKSPACE_ROOT)
    except ValueError:
        out_display = args.output
    total_docs = sum(1 for funcs in all_functions.values() for f in funcs if f.description)
    pct = (total_docs / total * 100) if total else 0
    print(f"[OK] Generated API reference: {out_display}")
    print(f"  {total} functions across {len(all_functions)} modules | {total_docs} documented ({pct:.0f}%)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
