#!/usr/bin/env python3
"""
gen_lua_api_skeleton.py — Generate src/lua_api/<module>_api.rs skeleton files
from existing Rust module docstrings.

Scans src/<module>/*.rs for public structs and functions that have
# Parameters / # Returns rustdoc sections. Produces skeleton files in
src/lua_api/ where every function is a named pub fn with:
  - Rustdoc summary + # Parameters + # Returns sections (from source)
  - @param name : Type and @return Type tags (for gen_lua_api.py)
  - todo!() placeholder body

Usage:
    python tools/gen_lua_api_skeleton.py                    # list scannable modules
    python tools/gen_lua_api_skeleton.py --module graphics  # generate graphics_api.rs skeleton
    python tools/gen_lua_api_skeleton.py --module audio     # generate audio_api.rs skeleton
    python tools/gen_lua_api_skeleton.py --all              # generate all modules
    python tools/gen_lua_api_skeleton.py --module graphics --dry-run  # preview only
    python tools/gen_lua_api_skeleton.py --module graphics --output PATH  # custom output

Exit codes:
    0 — success
    1 — fatal error
    2 — bad arguments
"""

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = WORKSPACE_ROOT / "src"
LUA_API_DIR = SRC_DIR / "lua_api"

# ── Lua type aliases ─────────────────────────────────────────────────────────

_RUST_TO_LUA: Dict[str, str] = {
    "f32": "number", "f64": "number",
    "i32": "integer", "i64": "integer",
    "u32": "integer", "u64": "integer",
    "usize": "integer", "isize": "integer",
    "String": "string", "&str": "string", "&String": "string",
    "bool": "boolean",
    "LuaTable": "table",
    "LuaValue": "any",
    "LuaFunction": "function",
    "()": "nil",
    "Vec2": "Vec2",
    "Vec3": "Vec3",
    "Color": "Color",
    "Rect": "Rect",
}


def rust_to_lua_type(rust_type: str) -> str:
    rust_type = rust_type.strip()
    # Option<T> → T?
    m = re.match(r"Option<(.+)>$", rust_type)
    if m:
        inner = rust_to_lua_type(m.group(1))
        return f"{inner}?"
    # Vec<T> → table
    if re.match(r"Vec<.+>$", rust_type):
        return "table"
    # &T → T (strip reference)
    if rust_type.startswith("&"):
        return rust_to_lua_type(rust_type[1:])
    return _RUST_TO_LUA.get(rust_type, rust_type)


def snake_to_camel(name: str) -> str:
    """Convert snake_case to camelCase for Lua key names."""
    parts = name.split("_")
    if not parts:
        return name
    return parts[0] + "".join(p.capitalize() for p in parts[1:])


# ── Docstring extraction ──────────────────────────────────────────────────────

@dataclass
class ParsedSection:
    """Parsed # Parameters or # Returns section from a Rust docstring."""
    raw_params: List[Tuple[str, str]] = field(default_factory=list)  # [(name, type)]
    raw_returns: str = ""
    summary: str = ""
    extra_lines: List[str] = field(default_factory=list)


def collect_doc_above(lines: List[str], idx: int) -> str:
    """Collect all /// docstring lines above the line at idx."""
    doc_parts: List[str] = []
    j = idx - 1
    while j >= 0:
        stripped = lines[j].strip()
        if stripped.startswith("///"):
            text = stripped[3:]
            doc_parts.insert(0, text[1:] if text.startswith(" ") else text)
        elif stripped.startswith("#[") or stripped == "":
            pass
        elif re.match(r"^let\s+\w+\s*=\s*\w+\.clone\(\)\s*;$", stripped):
            pass
        elif stripped.startswith("//") and not stripped.startswith("///"):
            pass
        else:
            break
        j -= 1
    return "\n".join(doc_parts).strip()


def parse_rustdoc(docstring: str) -> ParsedSection:
    """Parse a Rust docstring into summary, params list, and return type."""
    result = ParsedSection()
    if not docstring:
        return result

    lines = docstring.split("\n")
    current_section: Optional[str] = None
    pre_section_lines: List[str] = []
    section_content: Dict[str, List[str]] = {}

    for line in lines:
        h = re.match(r"^#\s+(.+)$", line)
        if h:
            current_section = h.group(1).lower().strip()
            section_content[current_section] = []
        elif current_section is not None:
            section_content[current_section].append(line)
        else:
            pre_section_lines.append(line)

    # Summary: first non-empty line before any section
    result.summary = ""
    result.extra_lines = []
    found_summary = False
    for line in pre_section_lines:
        if not found_summary and line.strip():
            result.summary = line.strip()
            found_summary = True
        elif found_summary:
            result.extra_lines.append(line)

    # Parse # Parameters: lines like `- `name` — `Type` Description.`
    param_lines = section_content.get("parameters", [])
    for pline in param_lines:
        # Match: - `name` — `Type` ...  or  - `name` — Type ...
        m = re.match(r"\s*[-*]\s*`(\w+)`\s*[—–-]+\s*(?:`([^`]+)`|(\S+))", pline)
        if m:
            pname = m.group(1)
            ptype = m.group(2) or m.group(3)
            result.raw_params.append((pname, ptype.strip("`")))

    # Parse # Returns: first non-empty token
    return_lines = section_content.get("returns", [])
    for rline in return_lines:
        rline = rline.strip()
        if not rline:
            continue
        # Match: `Type` Description  or  Ok(Type) —  or  Type Description
        m = re.match(r"`?([A-Za-z][A-Za-z0-9_<>()]+)`?", rline)
        if m:
            result.raw_returns = m.group(1).strip("`")
            break

    return result


# ── Source scanning ───────────────────────────────────────────────────────────

@dataclass
class FoundFn:
    rust_name: str
    lua_name: str
    doc: ParsedSection
    is_method: bool  # True → instance method on a UserData type
    owner_type: Optional[str]  # e.g. "Texture" for methods
    rust_params: List[str]  # raw Rust param types from signature
    rust_return: str  # raw Rust return type


def _extract_fn_params(sig_line: str) -> List[str]:
    """Very rough extractor: pull param types from a pub fn signature line."""
    # Match the part in parentheses after the function name
    m = re.search(r"\(([^)]*)\)", sig_line)
    if not m:
        return []
    raw = m.group(1)
    # Split on commas, grab type part (after `:`)
    parts = []
    for segment in raw.split(","):
        segment = segment.strip()
        if ":" in segment:
            t = segment.split(":", 1)[1].strip()
            # Strip generic bounds like `T: AsRef<Path>`
            t = re.sub(r":\s*\w+.*$", "", t)
            parts.append(t.strip())
    return parts


def scan_module_for_public_fns(module_dir: Path) -> List[FoundFn]:
    """Scan all .rs files in a module directory for documented pub fn items."""
    results: List[FoundFn] = []
    rs_files = list(module_dir.rglob("*.rs"))

    for rs_file in sorted(rs_files):
        try:
            text = rs_file.read_text(encoding="utf-8")
        except OSError:
            continue
        lines = text.splitlines()

        # Track current impl block context to identify methods
        impl_type: Optional[str] = None

        for idx, line in enumerate(lines):
            stripped = line.strip()

            # Track impl blocks
            impl_m = re.match(r"impl(?:<[^>]+>)?\s+(\w+)", stripped)
            if impl_m and not stripped.startswith("//"):
                impl_type = impl_m.group(1)
            if stripped == "}" and impl_type:
                # Crude: reset when we see a closing brace at same indentation
                if not line.startswith("    "):
                    impl_type = None

            # Match pub fn
            fn_m = re.match(r"pub fn (\w+)\s*(?:<[^>]+>)?\s*\(", stripped)
            if not fn_m:
                continue

            rust_name = fn_m.group(1)

            # Skip registration functions and test helpers
            if rust_name in ("register", "new", "main", "run"):
                continue

            # Collect docstring above
            docstring = collect_doc_above(lines, idx)
            if not docstring:
                continue  # skip undocumented fns

            parsed = parse_rustdoc(docstring)
            if not parsed.summary:
                continue  # need at least a summary

            # Only include fns that have # Parameters or # Returns (or both)
            has_params = bool(parsed.raw_params)
            has_returns = bool(parsed.raw_returns)
            if not has_params and not has_returns:
                continue

            is_method = bool(impl_type) and "&self" in line
            owner_type = impl_type if is_method else None

            lua_name = snake_to_camel(rust_name)
            rust_params = _extract_fn_params(line)

            results.append(FoundFn(
                rust_name=rust_name,
                lua_name=lua_name,
                doc=parsed,
                is_method=is_method,
                owner_type=owner_type,
                rust_params=rust_params,
                rust_return=parsed.raw_returns,
            ))

    return results


# ── Code generation ───────────────────────────────────────────────────────────

def _make_param_doc_line(name: str, lua_type: str) -> str:
    return f"/// - `{name}` — `{lua_type}` ..."


def _make_tag_param(name: str, lua_type: str) -> str:
    return f"/// @param {name} : {lua_type}"


def _make_tag_return(lua_type: str) -> str:
    return f"/// @return {lua_type}"


def generate_fn_block(fn: FoundFn, module_name: str) -> str:
    """Generate a complete named pub fn skeleton block."""
    lines: List[str] = []

    # Docstring header
    lines.append(f"/// {fn.doc.summary}")
    for extra in fn.doc.extra_lines:
        if extra.strip():
            lines.append(f"/// {extra}")
        else:
            lines.append("///")

    # @param / @return tags (for gen_lua_api.py)
    lines.append("///")
    for pname, ptype in fn.doc.raw_params:
        lua_type = rust_to_lua_type(ptype)
        lines.append(_make_tag_param(pname, lua_type))
    if fn.doc.raw_returns:
        lua_ret = rust_to_lua_type(fn.doc.raw_returns)
        lines.append(_make_tag_return(lua_ret))

    # Function signature
    if fn.is_method:
        # Method: &self receiver
        if fn.doc.raw_params:
            param_block = ", ".join(
                f"{n}: {rust_to_lua_type(t)}" for n, t in fn.doc.raw_params
            )
            lines.append(
                f"pub fn {fn.rust_name}(&self, _lua: &Lua, _args: LuaMultiValue) -> LuaResult<()> {{"  
            )
        else:
            lines.append(
                f"pub fn {fn.rust_name}(&self, _lua: &Lua, _: ()) -> LuaResult<()> {{"
            )
    else:
        # Module function
        if fn.doc.raw_params:
            lines.append(
                f"pub fn {fn.rust_name}(_lua: &Lua, _args: LuaMultiValue) -> LuaResult<LuaValue> {{"
            )
        else:
            lines.append(
                f"pub fn {fn.rust_name}(_lua: &Lua, _: ()) -> LuaResult<LuaValue> {{"
            )
    lines.append("    todo!()")
    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def generate_userdata_impl(type_name: str, methods: List[FoundFn]) -> str:
    """Generate the impl UserData for Lua<TypeName> block."""
    lines: List[str] = []
    struct_name = f"Lua{type_name}"

    lines.append(f"impl UserData for {struct_name} {{")
    lines.append("    fn add_methods<M: UserDataMethods<Self>>(methods: &mut M) {")
    for m in methods:
        lines.append(f'        methods.add_method("{m.lua_name}", Self::{m.rust_name});')
    lines.append("    }")
    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def generate_register_fn(module_name: str, module_fns: List[FoundFn]) -> str:
    """Generate the pub fn register(...) block."""
    lines: List[str] = []
    lines.append("/// Registers the `luna.{module_name}` API table.".replace("{module_name}", module_name))
    lines.append("///")
    lines.append("/// @param lua : &Lua")
    lines.append("/// @param luna : &LuaTable")
    lines.append("/// @param state : Rc<RefCell<SharedState>>")
    lines.append("/// @return LuaResult<()>")
    lines.append("pub fn register(")
    lines.append("    lua: &Lua,")
    lines.append("    luna: &mlua::Table,")
    lines.append("    _state: Rc<RefCell<SharedState>>,")
    lines.append(") -> LuaResult<()> {")
    lines.append(f'    let tbl = lua.create_table()?;')
    for fn_item in module_fns:
        if not fn_item.is_method:
            lines.append(
                f'    tbl.set("{fn_item.lua_name}", lua.create_function({fn_item.rust_name})?)?;'
            )
    lines.append(f'    luna.set("{module_name}", tbl)?;')
    lines.append("    Ok(())")
    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def generate_api_file(module_name: str, fns: List[FoundFn]) -> str:
    """Generate the full content of a _api.rs skeleton file."""
    header_lines: List[str] = [
        f"//! `luna.{module_name}` Lua API bindings.",
        "//!",
        f"//! Auto-generated skeleton from `src/{module_name}/` Rust docstrings.",
        "//! Fill in the `todo!()` bodies with actual implementation.",
        "//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.",
        "//!",
        "use std::cell::RefCell;",
        "use std::rc::Rc;",
        "",
        "use mlua::prelude::*;",
        "",
        "use crate::engine::SharedState;",
        "",
    ]

    sections: List[str] = ["\n".join(header_lines)]

    # Group methods by owner type
    methods_by_type: Dict[str, List[FoundFn]] = {}
    module_fns: List[FoundFn] = []

    for fn_item in fns:
        if fn_item.is_method and fn_item.owner_type:
            methods_by_type.setdefault(fn_item.owner_type, []).append(fn_item)
        else:
            module_fns.append(fn_item)

    # Emit UserData structs and their method impls
    for type_name, methods in sorted(methods_by_type.items()):
        struct_name = f"Lua{type_name}"
        sections.append(f"// ── {struct_name} ────────────────────────────────────────────────────────────\n")
        sections.append(f"pub struct {struct_name}(/* TODO: add key + state fields */);\n")
        sections.append("")

        sections.append(f"impl {struct_name} {{")
        for m in methods:
            sections.append("    " + generate_fn_block(m, module_name).replace("\n", "\n    ").rstrip())
        sections.append("}\n")

        sections.append(generate_userdata_impl(type_name, methods))

    # Emit standalone module functions
    if module_fns:
        sections.append(f"// ── luna.{module_name}.* functions ──────────────────────────────────────────\n")
        for fn_item in module_fns:
            sections.append(generate_fn_block(fn_item, module_name))

    # Emit register() at the end
    sections.append(generate_register_fn(module_name, module_fns))

    return "\n".join(sections)


# ── Main ──────────────────────────────────────────────────────────────────────

def list_modules() -> List[str]:
    """List all src/ directories that have Rust files with documented pub fns."""
    modules = []
    for d in sorted(SRC_DIR.iterdir()):
        if d.is_dir() and d.name not in ("lua_api", "engine", "bin"):
            rs_files = list(d.rglob("*.rs"))
            if rs_files:
                modules.append(d.name)
    return modules


def run(module_name: str, output: Optional[Path], dry_run: bool) -> int:
    module_dir = SRC_DIR / module_name
    if not module_dir.exists():
        print(f"ERROR: src/{module_name}/ does not exist", file=sys.stderr)
        return 1

    print(f"Scanning src/{module_name}/ ...")
    fns = scan_module_for_public_fns(module_dir)

    if not fns:
        print(f"  No documented pub fn found in src/{module_name}/")
        return 0

    print(f"  Found {len(fns)} documented pub fn items:")
    for fn in fns:
        tag = "method" if fn.is_method else "fn"
        print(f"    [{tag}] {fn.owner_type or module_name}.{fn.rust_name} → lua: {fn.lua_name!r}")

    content = generate_api_file(module_name, fns)

    if dry_run:
        print("\n── DRY RUN OUTPUT ─────────────────────────────────────────────────────────")
        print(content)
        return 0

    if output is None:
        LUA_API_DIR.mkdir(parents=True, exist_ok=True)
        output = LUA_API_DIR / f"{module_name}_api.rs"

    if output.exists():
        print(f"  WARNING: {output} already exists — will NOT overwrite.")
        print(f"  Use --force to overwrite, or --dry-run to preview.")
        return 0

    output.write_text(content, encoding="utf-8")
    print(f"  Written → {output}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate src/lua_api/*_api.rs skeleton from Rust module docstrings."
    )
    parser.add_argument("--module", metavar="NAME",
                        help="Module name to generate (e.g. graphics, audio, physics)")
    parser.add_argument("--all", action="store_true",
                        help="Generate skeletons for all src/ modules")
    parser.add_argument("--output", metavar="FILE",
                        help="Custom output path (only valid with --module)")
    parser.add_argument("--dry-run", action="store_true",
                        help="Print generated content without writing files")
    parser.add_argument("--force", action="store_true",
                        help="Overwrite existing files")
    parser.add_argument("--list", action="store_true",
                        help="List all scannable module names and exit")
    args = parser.parse_args()

    if args.list or (not args.module and not args.all):
        modules = list_modules()
        print("Scannable modules:")
        for m in modules:
            api_exists = (LUA_API_DIR / f"{m}_api.rs").exists()
            status = " [api exists]" if api_exists else " [no api yet]"
            print(f"  {m}{status}")
        return 0

    output = Path(args.output) if args.output else None

    if args.force:
        # Monkey-patch: remove existence check
        global _FORCE_OVERWRITE
        _FORCE_OVERWRITE = True

    if args.all:
        modules = list_modules()
        errors = 0
        for m in modules:
            api_path = LUA_API_DIR / f"{m}_api.rs"
            if api_path.exists() and not args.force:
                print(f"  SKIP {m} — {api_path} already exists (use --force to overwrite)")
                continue
            rc = run(m, None, args.dry_run)
            if rc != 0:
                errors += 1
        return 1 if errors else 0

    # Single module
    if output and not args.module:
        print("ERROR: --output requires --module", file=sys.stderr)
        return 2

    # Handle --force for single module
    if args.force and output is None and args.module:
        out_path = LUA_API_DIR / f"{args.module}_api.rs"
        if out_path.exists():
            out_path.unlink()

    return run(args.module, output, args.dry_run)


_FORCE_OVERWRITE = False

if __name__ == "__main__":
    sys.exit(main())
