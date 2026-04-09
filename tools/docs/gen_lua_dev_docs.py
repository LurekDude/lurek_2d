#!/usr/bin/env python3
"""
gen_lua_dev_docs.py — Generate Lua developer documentation from lua_api *.rs files.

Parses the lurek2d lua_api docstring format (defined in .github/skills/lua-api-design/SKILL.md):

    //! `lurek.<module>` — description          module header
    pub struct LuaFoo { ... }                  UserData type definition
    // -- methodName --                         section header
    /// One-sentence description.               description
    /// @param name : type                      parameter (type may end with ? for optional)
    /// @return type                            return type
    methods.add_method("name", ...)            UserData method (immutable)
    methods.add_method_mut("name", ...)        UserData method (mutates wrapper)
    methods.add_function("name", ...)          UserData static / factory
    methods.add_meta_method(LuaMetaMethod::X)  metamethod (__tostring, __index, etc.)
    tbl.set("name", ...)                       module-level function

Outputs one Markdown file per lurek.* module to docs/API/lua/.
Target audience: Lua game developers (not Rust engine contributors).

Usage:
    python tools/gen_lua_dev_docs.py                         # all *_api.rs in src/lua_api/
    python tools/gen_lua_dev_docs.py --module timer          # single module
    python tools/gen_lua_dev_docs.py --src PATH              # custom dir or single .rs file
    python tools/gen_lua_dev_docs.py --output DIR            # custom output dir
    python tools/gen_lua_dev_docs.py --dry-run               # print to stdout, write nothing
    python tools/gen_lua_dev_docs.py --check                 # report undocumented, exit 1 if any

Exit codes:
    0 — success
    1 — missing docs found (--check only)
    2 — fatal error (bad arguments, no source files)
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_SRC = _ROOT / "src" / "lua_api"
DEFAULT_OUT = _ROOT / "docs" / "API" / "lua"

# ---------------------------------------------------------------------------
# Regex patterns
# ---------------------------------------------------------------------------

# // -- name --   (section header inside impl or register)
_SEC_RE = re.compile(r"^\s*//\s*--\s*(\w+)\s*--\s*$")

# methods.add_method("name",   or   methods.add_method_mut("name",
_ADD_METHOD_RE = re.compile(r'methods\.add_method(?P<mut>_mut)?\s*\(\s*"(?P<name>\w+)"')

# methods.add_function("name",
_ADD_FUNC_RE = re.compile(r'methods\.add_function\s*\(\s*"(?P<name>\w+)"')

# methods.add_meta_method(LuaMetaMethod::ToString,
_ADD_META_RE = re.compile(r'methods\.add_meta_method\s*\(\s*LuaMetaMethod::(?P<meta>\w+)')

# tbl.set("name",   (module-level registration)
_TBL_SET_RE = re.compile(r'tbl\.set\s*\(\s*"(?P<name>\w+)"')

# pub struct LuaFoo {   (UserData type definition)
_STRUCT_RE = re.compile(r"^\s*pub\s+struct\s+(Lua\w+)")

# impl LuaUserData for LuaFoo   (opens a UserData method block)
_IMPL_RE = re.compile(r"^\s*impl(?:<[^>]+>)?\s+LuaUserData\s+for\s+(Lua\w+)")

# //! `lurek.timer` — description   (module header)
_MOD_HEADER_RE = re.compile(r"^//!\s*`luna\.(\w+)`\s*[-\u2013\u2014]\s*(.+)", re.UNICODE)

# /// @param name : type
_PARAM_RE = re.compile(r"@param\s+(\w+)\s*:\s*(\S+)")

# /// @return type
_RETURN_RE = re.compile(r"@return\s+(\S+)")

# let s = state.clone();  (bridge boilerplate line — skip during doc collection)
_BRIDGE_RE = re.compile(r"^\s*let\s+\w+\s*=\s*\w+\.clone\(\)\s*;")

# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------


@dataclass
class Param:
    name: str
    lua_type: str

    @property
    def is_optional(self) -> bool:
        return self.lua_type.endswith("?")


@dataclass
class ApiEntry:
    """One documented API item: a module function or a UserData method."""

    name: str                        # Lua-visible name  e.g. "getDelta", "after"
    kind: str                        # module_fn | method | method_mut | function | meta
    owner: Optional[str]             # UserData display name ("Scheduler") or None for module fns
    desc: str                        # one-line human description
    params: List[Param]
    returns: str                     # "" means nothing documented; "nil" means explicit void


@dataclass
class UserDataType:
    struct_name: str                 # e.g. "LuaScheduler"
    display_name: str                # e.g. "Scheduler"
    desc: str                        # from /// above pub struct


@dataclass
class LuaModule:
    name: str                        # e.g. "timer"
    desc: str                        # from //! header
    source_file: Path
    userdata_types: List[UserDataType] = field(default_factory=list)
    entries: List[ApiEntry] = field(default_factory=list)

    @property
    def module_fns(self) -> List[ApiEntry]:
        return [e for e in self.entries if e.kind == "module_fn"]

    def methods_for(self, display_name: str) -> List[ApiEntry]:
        return [e for e in self.entries if e.owner == display_name]


# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------


def _collect_doc_above(lines: List[str], idx: int) -> str:
    """Collect consecutive /// lines immediately above idx into a description string."""
    parts: List[str] = []
    j = idx - 1
    while j >= 0:
        s = lines[j].strip()
        if s.startswith("///"):
            text = s[3:].strip()
            if not text.startswith("@"):  # skip @param / @return
                parts.insert(0, text)
        else:
            break
        j -= 1
    return " ".join(p for p in parts if p).strip()


def _collect_section_doc(
    lines: List[str], start: int
) -> Tuple[str, List[Param], str]:
    """
    Collect the docstring block starting at `start` (the line after // -- name --).
    Returns (description, params, returns).
    """
    desc_parts: List[str] = []
    params: List[Param] = []
    returns = ""
    j = start
    limit = min(start + 25, len(lines))

    while j < limit:
        s = lines[j].strip()

        if s.startswith("///"):
            text = s[3:].strip()
            m_p = _PARAM_RE.match(text)
            m_r = _RETURN_RE.match(text)
            if m_p:
                params.append(Param(m_p.group(1), m_p.group(2).rstrip(",.")))
            elif m_r:
                returns = m_r.group(1).rstrip(",.")
            elif text:
                desc_parts.append(text)

        elif s.startswith("//") and not s.startswith("///"):
            # Another comment block or separator — stop looking
            break

        elif s == "" or _BRIDGE_RE.match(s):
            # Skip blank lines and bridge boilerplate (let s = state.clone();)
            pass

        else:
            # Non-doc, non-blank line — docstring block ended
            break

        j += 1

    return " ".join(desc_parts).strip(), params, returns


def _find_registration(
    lines: List[str], start: int, lookahead: int = 35
) -> Tuple[Optional[str], Optional[str]]:
    """
    Scan forward from `start` to find the first registration call.
    Returns (kind, name) where kind is one of:
        method, method_mut, function, meta, module_fn
    Returns (None, None) if no registration found within lookahead.

    Handles both single-line and two-line registrations, e.g.:
        methods.add_method_mut("name", ...)          ← single line
        methods.add_method_mut(                      ← two lines
            "name",
    """
    end = min(start + lookahead, len(lines))
    for i in range(start, end):
        s = lines[i].strip()
        # Join with the next line to catch multi-line registration patterns:
        #   tbl.set(
        #       "name",
        s_next = lines[i + 1].strip() if i + 1 < end else ""
        text = s + " " + s_next

        # methods.add_method_mut MUST come before add_method (shared prefix)
        m = re.search(r'methods\.add_method_mut\s*\(\s*"(\w+)"', text)
        if m:
            return "method_mut", m.group(1)

        m = re.search(r'methods\.add_method\s*\(\s*"(\w+)"', text)
        if m:
            return "method", m.group(1)

        m = _ADD_FUNC_RE.search(text)
        if m:
            return "function", m.group("name")

        m = _ADD_META_RE.search(text)
        if m:
            meta = m.group("meta")
            return "meta", f"__{meta.lower()}__"

        m = _TBL_SET_RE.search(text)
        if m:
            return "module_fn", m.group("name")

    return None, None


def _build_owner_map(lines: List[str]) -> Dict[int, Optional[str]]:
    """
    For each line index, return the display_name of the UserData impl block
    the line sits in, or None if outside any impl LuaUserData block.

    Uses brace depth to determine impl block boundaries.
    """
    owner_at: Dict[int, Optional[str]] = {}
    current_owner: Optional[str] = None
    entry_depth: int = 0  # brace depth when the impl { opened
    brace_depth: int = 0

    for i, line in enumerate(lines):
        s = line.strip()

        # Detect impl LuaUserData for LuaXxx BEFORE counting braces
        if current_owner is None:
            m = _IMPL_RE.match(s)
            if m:
                sname = m.group(1)
                current_owner = sname[3:] if sname.startswith("Lua") else sname
                entry_depth = brace_depth   # depth before the opening {

        # Count braces in this line
        brace_depth += s.count("{") - s.count("}")

        # Record owner for this line
        owner_at[i] = current_owner

        # Exit impl block when depth returns to entry_depth
        if current_owner is not None and brace_depth <= entry_depth:
            current_owner = None

    return owner_at


def parse_file(path: Path) -> Optional[LuaModule]:
    """Parse a single lua_api .rs file and return a populated LuaModule."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        print(f"ERROR: cannot read {path}: {e}", file=sys.stderr)
        return None

    lines = text.splitlines()

    # --- Module header ---
    module_name = path.stem.removesuffix("_api")
    module_desc = ""
    for line in lines[:10]:
        m = _MOD_HEADER_RE.match(line)
        if m:
            module_name = m.group(1)
            module_desc = m.group(2).strip()
            break

    mod = LuaModule(name=module_name, desc=module_desc, source_file=path)

    # --- UserData types (pub struct LuaXxx) ---
    userdata_map: Dict[str, UserDataType] = {}
    for i, line in enumerate(lines):
        m = _STRUCT_RE.match(line)
        if m:
            sname = m.group(1)
            display = sname[3:] if sname.startswith("Lua") else sname
            desc = _collect_doc_above(lines, i)
            ut = UserDataType(struct_name=sname, display_name=display, desc=desc)
            userdata_map[sname] = ut
            mod.userdata_types.append(ut)

    # --- Owner map: line -> display_name or None ---
    owner_at = _build_owner_map(lines)

    # --- Section headers: // -- name -- ---
    for i, line in enumerate(lines):
        m = _SEC_RE.match(line)
        if not m:
            continue

        section_name = m.group(1)

        # Collect docstring from lines after the header
        desc, params, returns = _collect_section_doc(lines, i + 1)

        # Find the actual registration call
        kind, reg_name = _find_registration(lines, i + 1)
        if kind is None:
            # Section without a matching registration — skip (may be a helper comment)
            continue

        # Determine ownership
        if kind in ("method", "method_mut", "function", "meta"):
            owner = owner_at.get(i)  # display_name from impl context
        else:
            owner = None  # module_fn — no owner

        entry = ApiEntry(
            name=reg_name or section_name,
            kind=kind,
            owner=owner,
            desc=desc,
            params=params,
            returns=returns,
        )
        mod.entries.append(entry)

    return mod


# ---------------------------------------------------------------------------
# Markdown rendering
# ---------------------------------------------------------------------------


def _lua_signature(
    name: str,
    params: List[Param],
    returns: str,
    owner: Optional[str],
    kind: str,
    module_name: str,
) -> str:
    """Return a Lua call signature string for display in headings."""
    param_str = ", ".join(
        (f"{p.name}: {p.lua_type}" if p.lua_type else p.name) for p in params
    )

    if kind in ("method", "method_mut"):
        # obj:method(args) → type
        caller = (owner[0].lower() + owner[1:]) if owner else "self"
        sig = f"{caller}:{name}({param_str})"
    elif kind == "function":
        # Type.factory(args) → type
        caller = owner or "obj"
        sig = f"{caller}.{name}({param_str})"
    elif kind == "meta":
        sig = name  # __tostring__, etc.
    else:
        # module_fn: lurek.timer.getDelta() → type
        sig = f"lurek.{module_name}.{name}({param_str})"

    if returns and returns not in ("nil", ""):
        sig += f" → {returns}"

    return sig


def _params_table(params: List[Param]) -> str:
    if not params:
        return ""
    rows = ["", "| Parameter | Type |", "|---|---|"]
    for p in params:
        rows.append(f"| `{p.name}` | `{p.lua_type}` |")
    return "\n".join(rows)


def render_module(mod: LuaModule) -> str:
    """Render a LuaModule to Markdown."""
    out: List[str] = []

    out.append(f"# lurek.{mod.name}\n")
    if mod.desc:
        out.append(f"{mod.desc}\n")
    out.append("")

    # --- Module-level functions ---
    fns = mod.module_fns
    if fns:
        out.append("## Module Functions\n")
        for e in fns:
            sig = _lua_signature(e.name, e.params, e.returns, None, "module_fn", mod.name)
            out.append(f"### `{sig}`\n")
            if e.desc:
                out.append(f"{e.desc}\n")
            tbl = _params_table(e.params)
            if tbl:
                out.append(tbl + "\n")
            if e.returns and e.returns not in ("nil", ""):
                out.append(f"\n**Returns** `{e.returns}`\n")
            out.append("---\n")

    # --- UserData types ---
    for ut in mod.userdata_types:
        entries = mod.methods_for(ut.display_name)
        if not entries:
            continue

        out.append(f"## {ut.display_name}\n")
        if ut.desc:
            out.append(f"{ut.desc}\n")
        out.append("")
        out.append("### Methods\n")

        for e in entries:
            sig = _lua_signature(e.name, e.params, e.returns, ut.display_name, e.kind, mod.name)
            out.append(f"#### `{sig}`\n")
            if e.desc:
                out.append(f"{e.desc}\n")
            tbl = _params_table(e.params)
            if tbl:
                out.append(tbl + "\n")
            if e.returns and e.returns not in ("nil", ""):
                out.append(f"\n**Returns** `{e.returns}`\n")
            out.append("---\n")

    return "\n".join(out)


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def _collect_files(src: Path, module_filter: Optional[str]) -> List[Path]:
    if src.is_file():
        return [src]
    files = sorted(src.glob("*_api.rs"))
    if module_filter:
        files = [
            f
            for f in files
            if f.stem in (f"{module_filter}_api", module_filter)
        ]
    return files


def _ensure_utf8_stdout() -> None:
    """Reconfigure stdout/stderr to UTF-8 on Windows for Unicode doc output."""
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")


def main(argv=None) -> int:
    _ensure_utf8_stdout()
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument(
        "--src", type=Path, default=DEFAULT_SRC,
        help="Source directory or single .rs file (default: src/lua_api/)",
    )
    ap.add_argument(
        "--output", "-o", type=Path, default=DEFAULT_OUT,
        help="Output directory (default: docs/API/lua/)",
    )
    ap.add_argument("--module", "-m", help="Process only this module name (e.g. timer)")
    ap.add_argument("--dry-run", action="store_true", help="Print to stdout, write no files")
    ap.add_argument(
        "--check", action="store_true",
        help="Report undocumented entries; exit 1 if any found",
    )
    args = ap.parse_args(argv)

    files = _collect_files(args.src, args.module)
    if not files:
        print(f"No *_api.rs files found in {args.src}", file=sys.stderr)
        return 2

    missing = 0
    written = 0

    for path in files:
        mod = parse_file(path)
        if mod is None:
            continue

        if args.check:
            for e in mod.entries:
                if not e.desc:
                    print(f"  MISSING desc  {mod.name}.{e.name}   ({path.name})")
                    missing += 1
                if e.kind not in ("meta",) and not e.params and not e.returns:
                    # Only flag if the function clearly should have docs
                    pass
            continue

        md = render_module(mod)

        if args.dry_run:
            print(f"\n{'=' * 64}")
            print(f"  SOURCE : {path}")
            print(f"  MODULE : lurek.{mod.name}")
            print("=" * 64)
            print(md)
        else:
            args.output.mkdir(parents=True, exist_ok=True)
            out_file = args.output / f"{mod.name}.md"
            out_file.write_text(md, encoding="utf-8")
            print(f"  wrote  {out_file.relative_to(_ROOT)}")
            written += 1

    if args.check:
        if missing:
            print(f"\n{missing} undocumented entry/entries found.")
            return 1
        print("All entries documented.")
        return 0

    if not args.dry_run:
        print(f"\nGenerated {written} module doc(s) → {args.output}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
