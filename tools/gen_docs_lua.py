#!/usr/bin/env python3
"""
gen_docs_lua.py — Generate compact Lua API developer reference from docs/api_data.json.

Reads the master data file produced by gen_api_data.py and writes a compact
Markdown reference for Luna2D Lua scripting. Covers all modules, classes, and
their functions/methods with signatures, descriptions, and parameter tables.

Usage:
    python tools/gen_docs_lua.py                   # -> docs/lua-api.md
    python tools/gen_docs_lua.py --output FILE     # custom output path
    python tools/gen_docs_lua.py --input FILE      # custom input path
    python tools/gen_docs_lua.py --check           # coverage report only (exit 1 if <80%)

Exit codes:
    0 — success
    1 — coverage below threshold (--check) or fatal error
"""

import argparse
import json
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
INPUT_FILE = WORKSPACE_ROOT / "docs" / "api_data.json"
OUTPUT_FILE = WORKSPACE_ROOT / "docs" / "lua-api.md"

# Canonical module display order (matches existing convention in gen_lua_api.py)
_MODULE_ORDER = [
    "graphics", "graphics_ext", "window", "input",
    "timer", "math", "math_ext",
    "audio", "physics", "filesystem", "particle",
    "event", "system", "thread",
    "ai", "compute", "dataframe",
    "data", "image", "sound", "graph", "tilemap",
    "dialog", "entity", "scene", "pathfinding", "postfx",
    "minimap", "savegame", "modding", "localization",
    "stats", "inventory", "crafting", "cardgame", "combat",
    "log", "debug",
]


# ── Return type extraction ─────────────────────────────────────────────────────

def _extract_return_type(returns_doc: str) -> str:
    """Extract the bare type name from a # Returns section."""
    if not returns_doc:
        return ""
    first_line = returns_doc.strip().split("\n")[0].strip().lstrip("- ").strip()
    # Match: "TypeName — description" or "TypeName: description" or just "TypeName"
    m = re.match(r"^([A-Za-z][A-Za-z0-9_?*]*)(?:\s|$|[—–:-])", first_line)
    if m:
        t = m.group(1)
        # Skip common non-type words
        if t.lower() not in ("the", "a", "an", "this", "true", "false", "nil", "none"):
            return t
    return ""


def _fmt_sig(fn: dict) -> str:
    """Build a Lua call signature string for a function entry."""
    sig = fn.get("inferred_sig") or ""
    # If we have a params_doc, try to rebuild nicer typed params
    params_doc = fn.get("params_doc", "")
    if params_doc:
        # Parse "- name — type: desc" lines
        typed_params = []
        for line in params_doc.split("\n"):
            line = line.strip().lstrip("- ").strip()
            # Match: `name` — type or name — type
            m = re.match(r"`?([a-zA-Z_]\w*)`?\s*[—–-]+\s*([A-Za-z][A-Za-z0-9_?]*)", line)
            if m:
                pname = m.group(1)
                ptype = m.group(2)
                # Optional param wrapped in []
                if "[" in line[:line.find(m.group(1))] or ptype.endswith("?"):
                    typed_params.append(f"[{pname}: {ptype.rstrip('?')}]")
                else:
                    typed_params.append(f"{pname}: {ptype}")
        if typed_params:
            return "( " + ", ".join(typed_params) + " )"
    # Fall back to inferred_sig
    if sig and sig != "()":
        inner = sig.strip("()")
        if inner:
            return "( " + inner + " )"
    return "()"


# ── Rendering helpers ──────────────────────────────────────────────────────────

def _render_fn_row(fn: dict, call_prefix: str) -> str:
    """Render a single function/method as a compact table row."""
    name = fn["name"]
    sig = _fmt_sig(fn)
    ret = _extract_return_type(fn.get("returns_doc", ""))
    desc = fn.get("description", "") or "*(undocumented)*"
    # Truncate desc to ~90 chars for table
    if len(desc) > 90:
        desc = desc[:87] + "..."
    ret_col = f"`{ret}`" if ret else ""
    call = f"`{call_prefix}.{name}{sig}`"
    return f"| {call} | {ret_col} | {desc} |"


def _render_method_row(fn: dict, class_name: str) -> str:
    """Render a method as a compact table row."""
    name = fn["name"]
    sig = _fmt_sig(fn)
    ret = _extract_return_type(fn.get("returns_doc", ""))
    desc = fn.get("description", "") or "*(undocumented)*"
    if len(desc) > 90:
        desc = desc[:87] + "..."
    ret_col = f"`{ret}`" if ret else ""
    call = f"`{class_name}:{name}{sig}`"
    return f"| {call} | {ret_col} | {desc} |"


def _render_fn_detail(fn: dict, call_expr: str) -> list:
    """Render a full detail block for a function (used in expandable sections)."""
    lines = []
    desc = fn.get("description", "")
    full_doc = fn.get("full_doc", "")
    params_doc = fn.get("params_doc", "")
    returns_doc = fn.get("returns_doc", "")

    lines.append(f"#### `{call_expr}`")
    lines.append("")
    if desc:
        lines.append(desc)
        # Additional paragraphs
        if full_doc and "\n" in full_doc:
            extra = full_doc[len(desc):].strip()
            # Remove section headers (# Parameters, # Returns) — rendered below
            extra = re.sub(r"\n#[^#].*", "", extra).strip()
            if extra:
                lines.append("")
                lines.append(extra)
    else:
        lines.append("*(undocumented)*")
    lines.append("")

    if params_doc:
        lines.append("**Parameters:**")
        lines.append("")
        for pl in params_doc.split("\n"):
            if pl.strip():
                lines.append(pl.strip())
        lines.append("")

    if returns_doc:
        ret_type = _extract_return_type(returns_doc)
        first_line = returns_doc.strip().split("\n")[0].strip()
        if ret_type:
            lines.append(f"**Returns:** `{ret_type}` — {first_line}")
        else:
            lines.append(f"**Returns:** {first_line}")
        lines.append("")

    return lines


def render_module(mod_name: str, mod_data: dict, detail: bool = False) -> list:
    """Render one module section including any classes."""
    out = []
    anchor = mod_name.replace("_", "-")
    out.append(f"## `luna.{mod_name}` {{#{anchor}}}")
    out.append("")

    desc = mod_data.get("description", "")
    if desc:
        first_line = desc.split("\n")[0]
        out.append(f"> {first_line}")
        out.append("")

    fn_list = mod_data.get("functions", [])
    classes = mod_data.get("classes", {})

    if fn_list:
        out.append("### Module functions")
        out.append("")
        out.append("| Function | Returns | Description |")
        out.append("|----------|---------|-------------|")
        for fn in sorted(fn_list, key=lambda f: f["name"]):
            out.append(_render_fn_row(fn, f"luna.{mod_name}"))
        out.append("")

    for cls_name, cls_data in sorted(classes.items()):
        out.append(f"### `{cls_name}` methods")
        out.append("")
        cls_desc = cls_data.get("description", "")
        if cls_desc:
            out.append(f"> {cls_desc.split(chr(10))[0]}")
            out.append("")
        methods = cls_data.get("methods", [])
        if methods:
            out.append("| Method | Returns | Description |")
            out.append("|--------|---------|-------------|")
            for fn in sorted(methods, key=lambda f: f["name"]):
                out.append(_render_method_row(fn, cls_name))
            out.append("")

    return out


def generate_lua_docs(data: dict) -> str:
    """Generate the full compact Lua API Markdown document."""
    lua_api = data["lua_api"]
    modules = lua_api["modules"]
    s = lua_api["summary"]
    generated = data["meta"]["generated"][:10]
    version = data["meta"]["version"]

    out = []
    out.append("# Luna2D Lua API Reference")
    out.append("")
    out.append(
        f"> Auto-generated by `tools/gen_docs_lua.py` from `docs/api_data.json`."
    )
    out.append(f"> Source: `tools/gen_api_data.py` | Version: `{version}` | Generated: {generated}")
    out.append(
        f"> **Coverage:** {s['documented']}/{s['total_functions']} functions documented ({s['coverage_pct']}%)"
    )
    out.append("")

    # Table of Contents
    out.append("## Contents")
    out.append("")
    out.append("| Module | Fn | Classes | Link |")
    out.append("|--------|----|---------|------|")

    seen: set = set()
    ordered: list = []
    for mod in _MODULE_ORDER:
        if mod in modules:
            seen.add(mod)
            ordered.append(mod)
    for mod in sorted(modules.keys()):
        if mod not in seen:
            ordered.append(mod)

    for mod in ordered:
        mod_data = modules[mod]
        n_fns = len(mod_data.get("functions", []))
        n_classes = len(mod_data.get("classes", {}))
        anchor = mod.replace("_", "-")
        out.append(f"| `luna.{mod}` | {n_fns} | {n_classes} | [#{anchor}](#{anchor}) |")
    out.append("")

    # Callbacks section
    out.append("## Callbacks")
    out.append("")
    out.append(
        "Define any of these functions in `main.lua`. All are optional — "
        "the engine calls them automatically."
    )
    out.append("")
    out.append("| Callback | Parameters | Description |")
    out.append("|----------|------------|-------------|")
    out.append("| `luna.load()` | — | Called once after script is loaded |")
    out.append("| `luna.update(dt)` | `dt: number` | Called every frame; dt = elapsed seconds |")
    out.append("| `luna.draw()` | — | Called every frame for rendering |")
    out.append("| `luna.keypressed(key, scancode, isrepeat)` | `key: string` | Key press event |")
    out.append("| `luna.keyreleased(key, scancode)` | `key: string` | Key release event |")
    out.append("| `luna.textinput(text)` | `text: string` | Unicode character typed |")
    out.append("| `luna.mousepressed(x, y, button)` | `button: 1/2/3` | Mouse button press |")
    out.append("| `luna.mousereleased(x, y, button)` | `button: number` | Mouse button release |")
    out.append("| `luna.wheelmoved(x, y)` | scroll delta | Mouse wheel |")
    out.append("| `luna.gamepadpressed(id, button)` | `id: number` | Gamepad button press |")
    out.append("| `luna.gamepadreleased(id, button)` | `id: number` | Gamepad button release |")
    out.append("| `luna.gamepadaxis(id, axis, value)` | `value: -1..1` | Gamepad axis |")
    out.append("| `luna.joystickadded(id)` | `id: number` | Gamepad connected |")
    out.append("| `luna.joystickremoved(id)` | `id: number` | Gamepad disconnected |")
    out.append("| `luna.touchpressed(id, x, y, dx, dy, pressure)` | — | Touch begin |")
    out.append("| `luna.touchmoved(id, x, y, dx, dy, pressure)` | — | Touch move |")
    out.append("| `luna.touchreleased(id, x, y, dx, dy, pressure)` | — | Touch end |")
    out.append("| `luna.focus(focused)` | `focused: bool` | Window focus change |")
    out.append("| `luna.visible(visible)` | `visible: bool` | Window show/hide |")
    out.append("| `luna.resize(w, h)` | `w, h: number` | Window resized |")
    out.append("| `luna.quit()` | — | Return `true` to cancel quit |")
    out.append("| `luna.errorhandler(msg)` | `msg: string` | Unhandled Lua error |")
    out.append("")

    # Per-module sections
    for mod in ordered:
        section = render_module(mod, modules[mod])
        out.extend(section)

    out.append("")
    out.append("---")
    out.append(f"*Generated by `tools/gen_docs_lua.py`. Do not edit by hand.*")

    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Luna2D compact Lua API docs.")
    parser.add_argument("--input", default=str(INPUT_FILE), help="Input api_data.json path")
    parser.add_argument("--output", default=str(OUTPUT_FILE), help="Output .md path")
    parser.add_argument(
        "--check", action="store_true", help="Coverage check only (exit 1 if <80%%)"
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"[ERROR] Input file not found: {input_path}", file=sys.stderr)
        print("Run 'python tools/gen_api_data.py' first.", file=sys.stderr)
        return 1

    data = json.loads(input_path.read_text(encoding="utf-8"))

    if args.check:
        s = data["lua_api"]["summary"]
        pct = s["coverage_pct"]
        print(f"Lua API coverage: {s['documented']}/{s['total_functions']} ({pct}%)")
        return 0 if pct >= 80 else 1

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    content = generate_lua_docs(data)
    output_path.write_text(content, encoding="utf-8")

    lines = content.count("\n")
    print(f"[OK] Generated {output_path} ({lines} lines)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
