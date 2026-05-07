#!/usr/bin/env python3
"""
gen_lua_api.py â€” Lurek2D Lua API parser library.

Parses src/lua_api/*.rs files and extracts all registered Lua functions and
userdata methods by scanning for .set() and add_method() patterns, associating
each entry with its preceding /// docstrings.

This module is a library used by other tools:
    gen_lua_api_data.py  -- builds logs/data/lua_api_data.json
    gen_rust_api_data.py -- cross-references Rust <-> Lua symbols
    gen_coverage_gaps.py -- detects missing Lua API coverage
    test_coverage.py     -- measures test coverage against the Lua API

Key exports:
    collect_all_functions(src_dir) -> Dict[str, List[LuaFunction]]
    collect_class_descriptions(api_file) -> Dict[str, str]
    extract_lua_functions(api_file) -> List[LuaFunction]
    LuaFunction (dataclass)
"""
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
    typed_params: list = field(default_factory=list)  # [(name, lua_type, is_optional, description), ...]
    inferred_return: str = field(default="")           # "bool", "Card", "table", "" etc.
    return_description: str = field(default="")        # human-readable return description


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
        elif re.match(r"^let\s+\w+\s*=\s*.+;\s*$", stripped):
            # Skip simple local bridge lines between a doc block and the final set() call,
            # e.g. `let s = state.clone();`, `let rt = real_timers;`, `let cap = history_cap;`.
            pass
        elif stripped.startswith("//") and not stripped.startswith("///"):
            # Skip plain // comments (e.g. // lurek.renders.X(â€¦) inline signature notes)
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


def _first_desc_line(docstring: str) -> str:
    """Return the first non-@param/@return description line from a /// docstring."""
    for line in docstring.split("\n"):
        stripped = line.strip()
        if stripped and not stripped.startswith("@"):
            return stripped
    return ""


def _extract_params_returns(docstring: str) -> tuple:
    """Extract legacy params_doc/returns_doc fields from a docstring.

    The JSON still carries these compatibility fields for downstream scripts.
    Prefer the explicit tagged data (`typed_params`, `inferred_return`,
    `return_description`) when available.

    Supported inputs:
    - legacy `# Parameters` / `# Returns` sections
    - current pipe-tagged `@param | ... | ... | ...` / `@return | ... | ...`
    """
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
    if params or returns:
        return params, returns

    tagged_params: List[str] = []
    tagged_return = ""
    for line in doc_lines:
        stripped = line.strip()

        param_match = re.match(
            r"@param\s*\|\s*(\w+\??|\.\.\.)\s*\|\s*(.+)\s*\|\s*(.+)",
            stripped,
        )
        if param_match:
            raw_name = param_match.group(1).strip()
            display_name = raw_name[:-1] if raw_name.endswith("?") and raw_name != "..." else raw_name
            lua_type = param_match.group(2).strip().rstrip(",.")
            desc = param_match.group(3).strip()
            tagged_params.append(f"- `{display_name}` â€” `{lua_type}`: {desc}")
            continue

        return_match = re.match(r"@return\s*\|\s*(.+)\s*\|\s*(.+)", stripped)
        if return_match and not tagged_return:
            # Keep only the type token here. The detailed prose is already stored in
            # `return_description`, and a plain type string is the safest form for
            # downstream stub generation.
            tagged_return = return_match.group(1).strip().rstrip(",.")

    if tagged_params:
        params = "\n".join(tagged_params)
    if tagged_return:
        returns = tagged_return

    return params, returns


# â”€â”€ Signature inference â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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
    """Parse ``@param`` lines from a /// docstring.

    Required format::

        /// @param | name | Type | Description text.
    """
    result = []
    for line in docstring.splitlines():
        stripped = line.strip()

        pipe_match = re.match(
            r"@param\s*\|\s*(\w+\??|\.\.\.)\s*\|\s*(.+)\s*\|\s*(.+)",
            stripped,
        )
        if pipe_match:
            name = pipe_match.group(1)
            name_optional = name.endswith("?") and name != "..."
            if name_optional:
                name = name[:-1]
            lua_type = pipe_match.group(2).strip().rstrip(",.")
            lua_type = re.sub(r"\s*\|\s*", "|", lua_type)
            description = pipe_match.group(3).strip()
            is_optional = name_optional or lua_type.endswith("?")
            result.append((name, lua_type, is_optional, description))
    return result


def _parse_tagged_return(docstring: str) -> tuple:
    """Parse ``@return`` lines from a /// docstring.

    Required format::

        /// @return | Type | Description text.
    """
    for line in docstring.splitlines():
        stripped = line.strip()

        pipe_match = re.match(r"@return\s*\|\s*(.+)\s*\|\s*(.+)", stripped)
        if pipe_match:
            return (pipe_match.group(1).strip().rstrip(",."), pipe_match.group(2).strip())
    return ("", "")


def _parse_inferred_sig_tokens(inferred_sig: str) -> List[tuple[str, bool]]:
    """Parse an inferred signature like ``(a, [b], ...)`` into name/optional tokens."""
    inner = (inferred_sig or "").strip()
    if not inner.startswith("(") or not inner.endswith(")"):
        return []

    inner = inner[1:-1].strip()
    if not inner:
        return []

    tokens: List[tuple[str, bool]] = []
    for raw in [part.strip() for part in inner.split(",") if part.strip()]:
        is_optional = raw.startswith("[") and raw.endswith("]")
        name = raw[1:-1].strip() if is_optional else raw
        tokens.append((name, is_optional))
    return tokens


def _merge_typed_params_with_inferred(typed_params: list, inferred_sig: str) -> list:
    """Preserve optional/variadic details inferred from the Rust closure signature."""
    inferred = _parse_inferred_sig_tokens(inferred_sig)
    if not typed_params and not inferred:
        return []

    if inferred == [("...", False)]:
        # If typed_params already has an explicit "..." entry, keep them as-is
        # (the docstring explicitly typed both named params and varargs).
        if any(p[0] == "..." for p in typed_params):
            return typed_params
        merged_type_parts: List[str] = []
        for typed in typed_params:
            if len(typed) > 1 and typed[1] not in merged_type_parts:
                merged_type_parts.append(typed[1])
        merged_type = "|".join(merged_type_parts) if merged_type_parts else "any"
        return [("...", merged_type, False, "")]

    if not typed_params:
        merged = []
        for name, is_optional in inferred:
            merged.append((name, "any", is_optional, ""))
        return merged

    if not inferred:
        return typed_params

    merged = []
    for index, typed in enumerate(typed_params):
        name = typed[0]
        lua_type = typed[1] if len(typed) > 1 else "any"
        is_optional = typed[2] if len(typed) > 2 else False
        description = typed[3] if len(typed) > 3 else ""

        if index < len(inferred):
            inferred_name, inferred_optional = inferred[index]
            is_optional = is_optional or inferred_optional
            if inferred_name == "...":
                name = "..."
            elif name != "..." and inferred_name and inferred_name != name:
                # Keep the docstring name when present, but prefer inferred ``...``.
                name = name

        merged.append((name, lua_type, is_optional, description))

    if len(inferred) > len(typed_params):
        for name, is_optional in inferred[len(typed_params):]:
            merged.append((name, "any", is_optional, ""))

    return merged



def collect_class_descriptions(api_file: Path) -> Dict[str, str]:
    """Return {display_class_name: first_doc_line} for all pub struct LuaXxx and impl LuaUserData for LuaXxx types.

    The display name strips the leading ``Lua`` prefix: ``LuaCard`` â†’ ``Card``.
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
            elif stripped.startswith("//") and not stripped.startswith("///"):
                pass
            else:
                break
            j -= 1
        return doc_parts[0].strip() if doc_parts else ""

    def _class_from_return(return_type: str, known_classes: set[str]) -> str:
        candidate = return_type.strip().split("|", 1)[0].strip().strip("`")
        if not candidate:
            return ""
        if candidate.startswith("L"):
            return candidate
        prefixed = "L" + candidate
        return prefixed if prefixed in known_classes else ""

    result: Dict[str, str] = {}

    userdata_impl_re = re.compile(
        r"impl(?:<[^>]*>)?\s+(?:(?:\w+::)*(?:LuaUserData|UserData))\s+for\s+(\w+)"
    )

    # Pass 0: extract canonical Lua type names from add_method("type", ...) declarations.
    # These are the authoritative names the user sees from obj:type().
    type_returns: Dict[str, str] = {}  # struct_name -> lua_type_name
    type_ret_re = re.compile(r'add_method\("type",\s*\|[^|]*\|\s*Ok\("(\w+)"(?:\.to_string\(\))?\)')
    current_struct: Optional[str] = None
    brace_depth = 0
    for line in lines:
        impl_m = userdata_impl_re.search(line)
        if impl_m and "{" in line:
            current_struct = impl_m.group(1)
            brace_depth = line.count("{") - line.count("}")
            continue
        if current_struct:
            brace_depth += line.count("{") - line.count("}")
            if brace_depth <= 0:
                current_struct = None
                brace_depth = 0
                continue
            tm = type_ret_re.search(line)
            if tm:
                type_returns[current_struct] = tm.group(1)

    def _canonical_name(struct_name: str) -> str:
        """Return the Lua-visible class name for a Rust struct."""
        if struct_name in type_returns:
            return type_returns[struct_name]
        if struct_name.startswith("Lua"):
            return "L" + struct_name[3:]
        if struct_name.startswith("L"):
            return struct_name
        return "L" + struct_name  # non-Lua-prefixed userdata gets L prefix

    # Pass 1: struct LuaXxx/LXxx or pub struct LuaXxx/LXxx
    # (highest priority: struct-level docs)
    for i, line in enumerate(lines):
        m = re.match(r"\s*(?:pub(?:\([^)]*\))?\s+)?struct ((?:Lua|L)\w+)", line)
        if not m:
            continue
        struct_name = m.group(1)
        class_name = _canonical_name(struct_name)
        desc = _collect_doc_above(lines, i)
        if desc:
            result[class_name] = desc

    # Pass 2: impl LuaUserData for Xxx (fallback for types defined in other src/ files)
    for i, line in enumerate(lines):
        m = userdata_impl_re.search(line)
        if not m:
            continue
        struct_name = m.group(1)
        class_name = _canonical_name(struct_name)
        if class_name in result:
            continue  # already found via pub struct
        desc = _collect_doc_above(lines, i)
        if desc:
            result[class_name] = desc

    known_class_names: set[str] = set(result) | set(type_returns.values())

    # Pass 3: create_widget_table( â€” shared UI base-widget table helpers
    for i, line in enumerate(lines):
        if not re.search(r"fn\s+create_widget_table\s*[<(]", line):
            continue
        desc = _collect_doc_above(lines, i)
        if desc:
            result.setdefault("LUiWidget", desc)
            known_class_names.add("LUiWidget")
        break

    # Pass 4: fn add_X_methods( â€” GUI-style widget factory functions
    for i, line in enumerate(lines):
        m = re.search(r"fn\s+add_(\w+)_methods\(", line)
        if not m:
            continue
        raw_name = m.group(1)  # e.g. "accordion", "gui_window"
        # camelCase with L prefix: "text_input" -> "LTextInput"
        class_name = "L" + "".join(p.capitalize() for p in raw_name.split("_"))
        if class_name in result:
            continue  # already found via struct or impl
        desc = _collect_doc_above(lines, i)
        if desc:
            result[class_name] = desc
            known_class_names.add(class_name)

    # Pass 5: constructor-style `set("newX", lua.create_function(...))` bindings
    set_multiline_re = re.compile(r'\.set\(\s*$')
    set_inline_re = re.compile(r'\.set\(\s*"(\w+)"\s*,\s*lua\.create_function')
    name_next_re = re.compile(r'^\s*"(\w+)"\s*,')
    for i, line in enumerate(lines):
        func_name: Optional[str] = None
        inline_m = set_inline_re.search(line)
        if inline_m:
            func_name = inline_m.group(1)
        elif set_multiline_re.search(line):
            for lookahead in range(1, 6):
                if i + lookahead >= len(lines):
                    break
                candidate_line = lines[i + lookahead].strip()
                if candidate_line == "" or candidate_line.startswith("//"):
                    continue
                name_m = name_next_re.match(candidate_line)
                if name_m:
                    func_name = name_m.group(1)
                break

        if not func_name:
            continue

        docstring = _collect_docstring_above(lines, i)
        desc = _first_desc_line(docstring)
        return_type, _ = _parse_tagged_return(docstring)
        class_name = _class_from_return(return_type, known_class_names)
        if desc and class_name and class_name not in result:
            result[class_name] = desc
            known_class_names.add(class_name)

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
            if t == "LuaMultiValue":
                parts.append("...")
                continue
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
        rust_t = scalar_m.group(2).strip()
        if rust_t.endswith("LuaMultiValue"):
            return "(...)"
        lua_t = _rust_type_to_lua(rust_t)
        if lua_t.endswith("?"):
            return f"([{name}])"
        return f"({name})"

    # (name,): (Type,) â€” single param in tuple form
    single_tuple_m = re.search(
        r"\|[^|]*?,\s*\(([a-z_][a-z0-9_]*)\s*,?\):\s*\(([^)]+)\)",
        search_text,
    )
    if single_tuple_m:
        name = single_tuple_m.group(1).lstrip("_")
        rust_t = single_tuple_m.group(2).strip()
        if rust_t.endswith("LuaMultiValue"):
            return "(...)"
        lua_t = _rust_type_to_lua(rust_t)
        if lua_t.endswith("?"):
            return f"([{name}])"
        return f"({name})"

    # No params: |_, ()| or |_, this, ()|
    no_param_m = re.search(r"\|[^|]*?,\s*(?:[a-z_]+,\s*)?\(\s*\)", search_text)
    if no_param_m:
        return "()"

    return ""


# â”€â”€ Module-level doc extraction â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€


def _collect_module_doc(api_file: Path) -> str:
    """Return the leading //! block of an api file as a plain string."""
    try:
        lines = api_file.read_text(encoding="utf-8").splitlines()
    except OSError:
        return ""
    doc_parts: List[str] = []
    for raw in lines:
        # Some files may start with UTF-8 BOM; remove it before matching //!
        stripped = raw.lstrip("\ufeff").strip()
        if stripped.startswith("//!"):
            text = stripped[3:]
            doc_parts.append(text[1:] if text.startswith(" ") else text)
        elif doc_parts:
            break
    return "\n".join(doc_parts).strip()


# Maps Rust module names (derived from src/lua_api/<name>_api.rs) to the Lua
# namespace key actually registered via lurek.set("<key>", ...).
# Only entries that DIFFER from the Rust module name are listed here.
_LUA_NAMESPACE_OVERRIDE: Dict[str, str] = {
    # system_api.rs registers as lurek.set("runtime", ...) â€” not "system"
    "system": "runtime",
}


def _determine_module_name(api_file: Path) -> str:
    stem = api_file.stem.replace("_api", "")
    return stem


def _lua_namespace(module: str) -> str:
    """Return the Lua-visible namespace key for a Rust module name."""
    return _LUA_NAMESPACE_OVERRIDE.get(module, module)


def _collect_table_namespaces(lines: List[str]) -> Dict[str, str]:
    """Return Rust table variable -> Lua namespace path.

    Examples:
    - `lurek.set("input", input_tbl)?;` -> `input_tbl = lurek.input`
    - `input_tbl.set("keyboard", keyboard)?;` -> `keyboard = lurek.input.keyboard`

    The extraction pass sees `keyboard.set("isDown", ...)` before the table is
    attached to `input_tbl`, so this map is built as a pre-pass over the file.
    """
    namespaces: Dict[str, str] = {}
    root_re = re.compile(r'\b(?:lurek|luna|lurek_table)\.set\(\s*"(\w+)"\s*,\s*(\w+)\s*\)\?;')
    child_re = re.compile(r'\b(\w+)\.set\(\s*"(\w+)"\s*,\s*(\w+)\s*\)\?;')

    changed = True
    while changed:
        changed = False
        for line in lines:
            stripped = line.strip()
            root_m = root_re.search(stripped)
            if root_m:
                namespace_key, table_var = root_m.groups()
                namespace = f"lurek.{namespace_key}"
                if namespaces.get(table_var) != namespace:
                    namespaces[table_var] = namespace
                    changed = True
                continue

            child_m = child_re.search(stripped)
            if child_m:
                parent_var, child_key, child_var = child_m.groups()
                parent_namespace = namespaces.get(parent_var)
                if parent_namespace:
                    namespace = f"{parent_namespace}.{child_key}"
                    if namespaces.get(child_var) != namespace:
                        namespaces[child_var] = namespace
                        changed = True

    return namespaces


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
    table_namespaces = _collect_table_namespaces(lines)

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

    # Build a map from Rust struct name -> Lua type name via add_method("type", ...) return values.
    # This gives the canonical L-prefix name for every userdata type, including non-Lua-prefixed structs.
    _type_ret_re2 = re.compile(r'add_method\("type",\s*\|[^|]*\|\s*Ok\("(\w+)"(?:\.to_string\(\))?\)')
    _ud_impl_re2 = re.compile(
        r"impl(?:<[^>]*>)?\s+(?:(?:\w+::)*(?:LuaUserData|UserData))\s+for\s+(\w+)"
    )
    type_returns: Dict[str, str] = {}  # struct_name -> lua_type_name (from type() method)
    _cur_s: Optional[str] = None
    _bd = 0
    for _l in lines:
        _im = _ud_impl_re2.search(_l)
        if _im and "{" in _l:
            _cur_s = _im.group(1)
            _bd = _l.count("{") - _l.count("}")
            continue
        if _cur_s:
            _bd += _l.count("{") - _l.count("}")
            if _bd <= 0:
                _cur_s = None
                _bd = 0
                continue
            _tm = _type_ret_re2.search(_l)
            if _tm:
                type_returns[_cur_s] = _tm.group(1)

    def _display_name(struct_name: str) -> str:
        """Return the canonical Lua-visible class name for a Rust struct."""
        if struct_name in type_returns:
            return type_returns[struct_name]
        if struct_name in type_names:
            return type_names[struct_name]
        if struct_name.startswith("Lua"):
            return "L" + struct_name[3:]
        if struct_name.startswith("L"):
            return struct_name
        return "L" + struct_name  # non-Lua-prefixed userdata gets L prefix

    set_multiline_re = re.compile(r'(\w+)\.set\(\s*$')
    set_inline_re = re.compile(r'(\w+)\.set\(\s*"(\w+)"\s*,\s*lua\.create_function')
    # NEW: named fn reference pattern â€” .set("luaName", lua.create_function(fn_name)?)
    set_named_fn_re = re.compile(
        r'\.set\(\s*"(\w+)"\s*,\s*lua\.create_function\(\s*(\w+)\s*\??\)'
    )
    name_next_re = re.compile(r'^\s*"(\w+)"\s*,')
    method_re = re.compile(r'methods\.add_method(?:_mut)?\(\s*"(\w+)"')
    method_function_re = re.compile(r'methods\.add_function\(\s*"(\w+)"')
    # NEW: Self:: reference pattern â€” methods.add_method("luaName", Self::fn_name)
    method_self_re = re.compile(
        r'methods\.add_method(?:_mut)?\(\s*"(\w+)"\s*,\s*Self::(\w+)'
    )
    dispatch_arith_inline_re = re.compile(r'dispatch_arith!\(\s*methods\s*,\s*"(\w+)"')
    # NEW: multi-line add_method â€” method name on next line
    # methods.add_method_mut(
    #     "methodName",  â† matched by name_next_re
    method_multiline_re = re.compile(r'methods\.add_method(?:_mut)?\(\s*$')
    method_function_multiline_re = re.compile(r'methods\.add_function\(\s*$')
    dispatch_arith_multiline_re = re.compile(r'dispatch_arith!\(\s*$')
    impl_re = re.compile(
        r'^\s*impl(?:<[^>]*>)?\s+(?:(?:(?:\w+::)*(?:LuaUserData|UserData))\s+for\s+)?(\w+)'
    )
    add_method_re = re.compile(r'fn\s+add_(\w+)_methods\(')
    create_widget_table_re = re.compile(r'fn\s+create_widget_table\s*[<(]')

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

        if create_widget_table_re.search(stripped):
            current_widget_type = "LUiWidget"

        add_m = add_method_re.search(stripped)
        if add_m:
            raw_w = add_m.group(1)  # e.g. "button", "text_input"
            # camelCase with L prefix: "text_input" -> "LTextInput"
            w_type = "L" + "".join(p.capitalize() for p in raw_w.split("_"))
            current_widget_type = w_type

        if brace_depth <= 0:
            current_impl_type = None
            brace_depth = 0

        # Multi-line set pattern
        set_m = set_multiline_re.search(stripped)
        if set_m and i + 1 < len(lines):
            table_var = set_m.group(1)
            # Look ahead past any blank lines or single-line comments to find the name
            name_m = None
            for _la in range(1, 6):
                if i + _la >= len(lines):
                    break
                _ahead = lines[i + _la].strip()
                if _ahead == "" or _ahead.startswith("//"):
                    continue  # skip blanks and non-doc comments between set( and "name"
                name_m = name_next_re.match(_ahead)
                break  # first non-blank non-comment line is decisive
            if name_m:
                func_name = name_m.group(1)
                is_func = any("create_function" in lines[k] for k in range(i + 1, min(i + 5, len(lines))))
                if is_func:
                    docstring = _collect_docstring_above(lines, i)
                    table_namespace = table_namespaces.get(table_var)
                    owner = "" if table_namespace else (current_widget_type if current_widget_type else "")
                    kind = "method" if owner else "function"
                    lua_name = (
                        f"{owner}.{func_name}"
                        if owner
                        else f"{table_namespace or f'lurek.{_lua_namespace(module)}'}.{func_name}"
                    )

                    if not docstring and owner:
                        docstring = f"/// Returns a value for {func_name} (auto-generated)."

                    desc = _first_desc_line(docstring)
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
                        typed_params=_merge_typed_params_with_inferred(
                            _parse_tagged_params(docstring), inferred
                        ),
                        inferred_return=_parse_tagged_return(docstring)[0],
                        return_description=_parse_tagged_return(docstring)[1],
                    ))

        # Single-line set pattern
        set_inline_m = set_inline_re.search(stripped)
        if set_inline_m:
            table_var = set_inline_m.group(1)
            func_name = set_inline_m.group(2)
            docstring = _collect_docstring_above(lines, i)
            table_namespace = table_namespaces.get(table_var)
            owner = "" if table_namespace else (current_widget_type if current_widget_type else "")
            kind = "method" if owner else "function"
            lua_name = (
                f"{owner}.{func_name}"
                if owner
                else f"{table_namespace or f'lurek.{_lua_namespace(module)}'}.{func_name}"
            )

            if not docstring and owner:
                docstring = f"/// Returns a value for {func_name} (auto-generated)."

            desc = _first_desc_line(docstring)
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
                typed_params=_merge_typed_params_with_inferred(
                    _parse_tagged_params(docstring), inferred
                ),
                inferred_return=_parse_tagged_return(docstring)[0],
                return_description=_parse_tagged_return(docstring)[1],
            ))

        # Userdata methods â€” existing pattern (docstring directly above the add_method line)
        method_m = method_re.search(stripped)
        if method_m and not method_self_re.search(stripped):
            func_name = method_m.group(1)
            owner = current_impl_type or "Unknown"
            display_owner = _display_name(owner)
            docstring = _collect_docstring_above(lines, i)
            desc = _first_desc_line(docstring)
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
                typed_params=_merge_typed_params_with_inferred(
                    _parse_tagged_params(docstring), inferred
                ),
                inferred_return=_parse_tagged_return(docstring)[0],
                return_description=_parse_tagged_return(docstring)[1],
            ))

        method_function_m = method_function_re.search(stripped)
        if method_function_m:
            func_name = method_function_m.group(1)
            owner = current_impl_type or "Unknown"
            display_owner = _display_name(owner)
            docstring = _collect_docstring_above(lines, i)
            desc = _first_desc_line(docstring)
            params, returns = _extract_params_returns(docstring)
            inferred = _infer_signature(lines, i)
            functions.append(LuaFunction(
                module=module, name=func_name,
                lua_name=f"{display_owner}.{func_name}",
                owner_type=display_owner, description=desc,
                full_doc=docstring, params=params,
                returns=returns, line=i + 1,
                file=rel_path, kind="method",
                inferred_sig=inferred,
                typed_params=_merge_typed_params_with_inferred(
                    _parse_tagged_params(docstring), inferred
                ),
                inferred_return=_parse_tagged_return(docstring)[0],
                return_description=_parse_tagged_return(docstring)[1],
            ))

        dispatch_arith_m = dispatch_arith_inline_re.search(stripped)
        if dispatch_arith_m:
            func_name = dispatch_arith_m.group(1)
            owner = current_impl_type or "Unknown"
            display_owner = _display_name(owner)
            docstring = _collect_docstring_above(lines, i)
            desc = _first_desc_line(docstring)
            params, returns = _extract_params_returns(docstring)
            functions.append(LuaFunction(
                module=module, name=func_name,
                lua_name=f"{display_owner}:{func_name}",
                owner_type=display_owner, description=desc,
                full_doc=docstring, params=params,
                returns=returns, line=i + 1,
                file=rel_path, kind="method",
                inferred_sig="",
                typed_params=_merge_typed_params_with_inferred(
                    _parse_tagged_params(docstring), ""
                ),
                inferred_return=_parse_tagged_return(docstring)[0],
                return_description=_parse_tagged_return(docstring)[1],
            ))

        # Multi-line add_method: method name on the next line
        if not method_m and method_multiline_re.search(stripped) and i + 1 < len(lines):
            next_stripped = lines[i + 1].strip()
            name_m = name_next_re.match(next_stripped)
            if name_m:
                func_name = name_m.group(1)
                owner = current_impl_type or "Unknown"
                display_owner = _display_name(owner)
                docstring = _collect_docstring_above(lines, i)
                desc = _first_desc_line(docstring)
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
                    typed_params=_merge_typed_params_with_inferred(
                        _parse_tagged_params(docstring), inferred
                    ),
                    inferred_return=_parse_tagged_return(docstring)[0],
                    return_description=_parse_tagged_return(docstring)[1],
                ))

        if not method_function_m and method_function_multiline_re.search(stripped) and i + 1 < len(lines):
            next_stripped = lines[i + 1].strip()
            name_m = name_next_re.match(next_stripped)
            if name_m:
                func_name = name_m.group(1)
                owner = current_impl_type or "Unknown"
                display_owner = _display_name(owner)
                docstring = _collect_docstring_above(lines, i)
                desc = _first_desc_line(docstring)
                params, returns = _extract_params_returns(docstring)
                inferred = _infer_signature(lines, i)
                functions.append(LuaFunction(
                    module=module, name=func_name,
                    lua_name=f"{display_owner}.{func_name}",
                    owner_type=display_owner, description=desc,
                    full_doc=docstring, params=params,
                    returns=returns, line=i + 1,
                    file=rel_path, kind="method",
                    inferred_sig=inferred,
                    typed_params=_merge_typed_params_with_inferred(
                        _parse_tagged_params(docstring), inferred
                    ),
                    inferred_return=_parse_tagged_return(docstring)[0],
                    return_description=_parse_tagged_return(docstring)[1],
                ))

        if dispatch_arith_multiline_re.search(stripped):
            name_m = None
            for _la in range(1, 6):
                if i + _la >= len(lines):
                    break
                next_stripped = lines[i + _la].strip()
                if not next_stripped or next_stripped.startswith("//"):
                    continue
                name_m = name_next_re.match(next_stripped)
                if name_m:
                    break
            if name_m:
                func_name = name_m.group(1)
                owner = current_impl_type or "Unknown"
                display_owner = _display_name(owner)
                docstring = _collect_docstring_above(lines, i)
                desc = _first_desc_line(docstring)
                params, returns = _extract_params_returns(docstring)
                functions.append(LuaFunction(
                    module=module, name=func_name,
                    lua_name=f"{display_owner}:{func_name}",
                    owner_type=display_owner, description=desc,
                    full_doc=docstring, params=params,
                    returns=returns, line=i + 1,
                    file=rel_path, kind="method",
                    inferred_sig="",
                    typed_params=_merge_typed_params_with_inferred(
                        _parse_tagged_params(docstring), ""
                    ),
                    inferred_return=_parse_tagged_return(docstring)[0],
                    return_description=_parse_tagged_return(docstring)[1],
                ))

        # NEW: methods.add_method("luaName", Self::fn_name) â€” named fn pattern
        method_self_m = method_self_re.search(stripped)
        if method_self_m:
            func_name = method_self_m.group(1)   # Lua name (string key)
            rust_fn   = method_self_m.group(2)   # Rust fn name after Self::
            owner = current_impl_type or "Unknown"
            display_owner = _display_name(owner)
            # Look up docstring on the named pub fn declaration
            docstring = _find_pub_fn_docstring(rust_fn) or _collect_docstring_above(lines, i)
            desc = _first_desc_line(docstring)
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
                typed_params=_merge_typed_params_with_inferred(
                    _parse_tagged_params(docstring), inferred
                ),
                inferred_return=_parse_tagged_return(docstring)[0],
                return_description=_parse_tagged_return(docstring)[1],
            ))

        # NEW: .set("luaName", lua.create_function(named_fn)?) â€” named fn reference
        set_named_m = set_named_fn_re.search(stripped)
        if set_named_m:
            func_name = set_named_m.group(1)    # Lua name (string key)
            rust_fn   = set_named_m.group(2)    # Rust fn name reference
            # Skip if already handled by set_inline_re (anonymous closure)
            if not set_inline_re.search(stripped) or rust_fn:
                owner = current_widget_type if current_widget_type else ""
                kind = "method" if owner else "function"
                lua_name = f"{owner}.{func_name}" if owner else f"lurek.{_lua_namespace(module)}.{func_name}"
                # Look up docstring from the named pub fn declaration
                docstring = _find_pub_fn_docstring(rust_fn) or _collect_docstring_above(lines, i)
                desc = _first_desc_line(docstring)
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
                    typed_params=_merge_typed_params_with_inferred(
                        _parse_tagged_params(docstring), inferred
                    ),
                    inferred_return=_parse_tagged_return(docstring)[0],
                    return_description=_parse_tagged_return(docstring)[1],
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
