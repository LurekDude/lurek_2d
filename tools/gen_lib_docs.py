#!/usr/bin/env python3
"""gen_lib_docs.py — Generate Markdown API documentation from Luna2D library Lua files.

Scans library/**/*.lua for LDoc-style docstrings and produces one Markdown
file per library module under docs/API/libs/.

LDoc tags recognised:
    --- Summary line (leading ``---`` starts a doc block)
    -- Continuation lines (leading ``--`` inside the block)
    @module   module_name   — sets the module title
    @param    name type     — function parameter
    @treturn  type          — return type
    @field    name type     — table field
    @status   stub|full     — implementation status
    @usage    ...           — code example (indented block follows)

Usage:
    python tools/gen_lib_docs.py                  # generate all
    python tools/gen_lib_docs.py --check          # report missing coverage
    python tools/gen_lib_docs.py --module dialog  # single module
"""

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Optional

# ── Configuration ─────────────────────────────────────────────────────────────

REPO_ROOT   = Path(__file__).resolve().parent.parent
LIB_DIR     = REPO_ROOT / "library"
OUT_DIR     = REPO_ROOT / "docs" / "API" / "libs"
WIKI_DIR    = REPO_ROOT / "wiki"

# ── LDoc parser ───────────────────────────────────────────────────────────────

def parse_ldoc(source: str) -> dict:
    """Extract module metadata and function docs from a Lua source string."""
    module_info = {
        "name":        "",
        "description": "",
        "status":      "unknown",
        "functions":   [],
    }

    lines = source.splitlines()
    i = 0

    def peek_block(start: int):
        """Read a consecutive doc block starting at `start`, return (lines, end_idx)."""
        block = []
        j = start
        while j < len(lines):
            stripped = lines[j].strip()
            if stripped.startswith("---"):
                block.append(stripped[3:].strip())
                j += 1
            elif stripped.startswith("--"):
                block.append(stripped[2:].strip())
                j += 1
            else:
                break
        return block, j

    while i < len(lines):
        stripped = lines[i].strip()

        # Module-level doc block
        if stripped.startswith("--- ") and i == 0 or (stripped.startswith("---") and "@module" in "".join(lines[i:i+20])):
            block, i = peek_block(i)
            desc_lines = []
            for bl in block:
                if bl.startswith("@module"):
                    module_info["name"] = bl.split(None, 1)[1].strip() if len(bl.split()) > 1 else ""
                elif bl.startswith("@status"):
                    module_info["status"] = bl.split(None, 1)[1].strip() if len(bl.split()) > 1 else ""
                elif not bl.startswith("@"):
                    desc_lines.append(bl)
            module_info["description"] = "\n".join(l for l in desc_lines if l).strip()
            continue

        # Function doc block followed by a function declaration
        if stripped.startswith("---"):
            block, next_i = peek_block(i)
            # Check if the next non-blank line is a function declaration
            func_line = lines[next_i].strip() if next_i < len(lines) else ""
            if re.match(r"^function\s+", func_line):
                func = _parse_func_block(block, func_line)
                if func:
                    module_info["functions"].append(func)
                i = next_i + 1
                continue

        i += 1

    return module_info


def _parse_func_block(block: list, func_line: str) -> Optional[dict]:
    """Parse a doc block + function declaration into a function descriptor."""
    # Extract function name from declaration
    m = re.match(r"^function\s+([\w.:]+)\s*\((.*?)\)", func_line)
    if not m:
        return None
    full_name = m.group(1)
    raw_args  = m.group(2)

    # Skip @local markers
    if any(b.strip() == "@local" for b in block):
        return None

    params   = []
    returns  = []
    desc_parts = []
    usage    = []
    in_usage = False

    for line in block:
        if line.startswith("@param"):
            parts = line.split(None, 3)
            if len(parts) >= 3:
                params.append({"name": parts[1], "type": parts[2],
                               "desc": parts[3] if len(parts) > 3 else ""})
        elif line.startswith("@treturn"):
            parts = line.split(None, 2)
            if len(parts) >= 2:
                returns.append({"type": parts[1],
                                "desc": parts[2] if len(parts) > 2 else ""})
        elif line.startswith("@usage"):
            in_usage = True
        elif in_usage:
            usage.append(line)
        elif not line.startswith("@"):
            desc_parts.append(line)

    return {
        "name":    full_name,
        "args":    raw_args,
        "desc":    " ".join(d for d in desc_parts if d).strip(),
        "params":  params,
        "returns": returns,
        "usage":   usage,
    }


# ── Markdown renderer ─────────────────────────────────────────────────────────

def render_module_md(module_name: str, info: dict) -> str:
    """Render a module's parsed info as Markdown."""
    lines = []
    display = module_name
    status_badge = ""
    if info["status"] == "stub":
        status_badge = " *(stub — not yet implemented)*"
    elif info["status"] in ("full", "proxy"):
        status_badge = ""

    lines.append(f"# library.{display}{status_badge}")
    lines.append("")
    if info["description"]:
        lines.append(info["description"])
        lines.append("")

    if info["functions"]:
        lines.append("## Functions")
        lines.append("")
        for fn in info["functions"]:
            name = fn["name"]
            # Use method syntax (remove module prefix for display)
            short = re.sub(r"^[^.:]+[.:]", "", name)
            lines.append(f"### `{short}({fn['args']})`")
            lines.append("")
            if fn["desc"]:
                lines.append(fn["desc"])
                lines.append("")
            if fn["params"]:
                lines.append("**Parameters**")
                lines.append("")
                for p in fn["params"]:
                    lines.append(f"- `{p['name']}` *{p['type']}* — {p['desc']}")
                lines.append("")
            if fn["returns"]:
                lines.append("**Returns**")
                lines.append("")
                for r in fn["returns"]:
                    desc = f" — {r['desc']}" if r["desc"] else ""
                    lines.append(f"- *{r['type']}*{desc}")
                lines.append("")
            if fn["usage"]:
                lines.append("```lua")
                for u in fn["usage"]:
                    lines.append(u)
                lines.append("```")
                lines.append("")

    return "\n".join(lines)


# ── Module scanner ────────────────────────────────────────────────────────────

def scan_library() -> dict:
    """Walk library/ and return { module_name: (path, parsed_info) }."""
    results = {}
    if not LIB_DIR.exists():
        return results
    for init_lua in sorted(LIB_DIR.glob("*/init.lua")):
        module_name = init_lua.parent.name
        source = init_lua.read_text(encoding="utf-8")
        info   = parse_ldoc(source)
        if not info["name"]:
            info["name"] = f"library.{module_name}"
        results[module_name] = (init_lua, info)
    return results


# ── Generators ────────────────────────────────────────────────────────────────

def generate_all(modules: dict, check_only: bool = False) -> int:
    """Generate docs for all modules. Returns exit code."""
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    errors = 0

    for module_name, (path, info) in modules.items():
        fn_count = len(info["functions"])
        if check_only:
            if fn_count == 0:
                print(f"MISSING  library/{module_name}/init.lua — no documented functions")
                errors += 1
            else:
                print(f"OK       library/{module_name}  ({fn_count} functions)")
            continue

        md = render_module_md(module_name, info)
        out_path = OUT_DIR / f"lib_{module_name}.md"
        out_path.write_text(md, encoding="utf-8")
        print(f"  → {out_path.relative_to(REPO_ROOT)}  ({fn_count} functions)")

        # Also write wiki page
        wiki_path = WIKI_DIR / f"Library-{module_name.replace('_','-').title()}.md"
        if WIKI_DIR.exists():
            wiki_path.write_text(md, encoding="utf-8")
            print(f"  → {wiki_path.relative_to(REPO_ROOT)}")

    return errors


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check",  action="store_true",
                        help="Report missing doc coverage (exit 1 if any)")
    parser.add_argument("--module", metavar="NAME",
                        help="Only process the named module (e.g. dialog)")
    args = parser.parse_args()

    modules = scan_library()
    if not modules:
        print(f"No library modules found under {LIB_DIR}", file=sys.stderr)
        return 1

    if args.module:
        if args.module not in modules:
            print(f"Module '{args.module}' not found in library/", file=sys.stderr)
            return 1
        modules = {args.module: modules[args.module]}

    if not args.check:
        print(f"Generating library docs → {OUT_DIR.relative_to(REPO_ROOT)}/")

    errors = generate_all(modules, check_only=args.check)
    if args.check and errors == 0:
        print(f"All {len(modules)} library modules have documented functions.")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
