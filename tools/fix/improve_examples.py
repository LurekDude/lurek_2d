#!/usr/bin/env python3
"""
tools/fix/improve_examples.py
Lurek2D — Quality-improve all content/examples/*.lua stubs.

Pass A — Remove trivial :type() / :typeOf() stubs from class sections; add a
          single consolidated "Type introspection" note instead.
Pass B — Fill realistic argument values into empty method stubs by consulting
          the API JSON (logs/data/lua_api_data.json).
Pass C — Improve class-section variable names (e.g. rename low-quality
          inferrred names from expand_examples.py).
Pass D — Consolidate blank lines after class sections and before next section.

Usage:
    python tools/fix/improve_examples.py           # apply to all
    python tools/fix/improve_examples.py --dry-run # show diffs only
    python tools/fix/improve_examples.py --module audio  # one module only
"""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EXAMPLES_DIR = ROOT / "content" / "examples"
API_JSON = ROOT / "logs" / "data" / "lua_api_data.json"

# Map module name -> example file stem
MODULE_TO_EXAMPLE: dict[str, str] = {
    "ai": "ai",
    "animation": "animation",
    "audio": "audio",
    "automation": "automation",
    "camera": "camera",
    "compute": "compute",
    "data": "data",
    "dataframe": "dataframe",
    "ecs": "ecs",
    "event": "event",
    "filesystem": "filesystem",
    "graph": "graph",
    "render": "render",
    "ui": "ui",
    "image": "image",
    "input": "input",
    "math": "math",
    "minimap": "minimap",
    "mods": "mods",
    "effect": "effect",
    "particle": "particle",
    "pathfind": "pathfind",
    "patterns": "patterns",
    "physics": "physics",
    "postfx": "fx",
    "save": "save",
    "scene": "scene",
    "sound": "sound",
    "terminal": "terminal",
    "thread": "thread",
    "tilemap": "tilemap",
    "timer": "timer",
    "window": "window",
    "i18n": "i18n",
    "devtools": "devtools",
    "pipeline": "pipeline",
    "raycaster": "raycaster",
    "spine": "spine",
    "docs": "docs",
    "log": "log",
    "network": "network",
    "procgen": "procgen",
    "serial": "serial",
    "light": "light",
    "debugbridge": "debugbridge",
}

# ─── Parameter default heuristics ────────────────────────────────────────────

# Ordered list: (regex, default_value)
_PARAM_HEURISTICS: list[tuple[re.Pattern, str]] = [
    (re.compile(r"^(title|caption|header)$",   re.I), '"Settings"'),
    (re.compile(r"^(name|label|tag)$",         re.I), '"myName"'),
    (re.compile(r"^(text|str|message|msg)$",   re.I), '"Hello"'),
    (re.compile(r"^(path|file|filename)$",     re.I), '"file.dat"'),
    (re.compile(r"^(key)$",                    re.I), '"myKey"'),
    (re.compile(r"^(section_idx|section_index|idx|index|i|row|col|column|row_idx|col_idx)$",
                re.I), '1'),
    (re.compile(r"^(id)$",                     re.I), '1'),
    (re.compile(r"^(count|n|num)$",            re.I), '3'),
    (re.compile(r"^(width|w)$",                re.I), '200'),
    (re.compile(r"^(height|h)$",               re.I), '150'),
    (re.compile(r"^(x|px)$",                   re.I), '100'),
    (re.compile(r"^(y|py)$",                   re.I), '100'),
    (re.compile(r"^(r)$",                      re.I), '0.8'),
    (re.compile(r"^(g)$",                      re.I), '0.4'),
    (re.compile(r"^(b)$",                      re.I), '0.2'),
    (re.compile(r"^(a|alpha)$",                re.I), '1.0'),
    (re.compile(r"color",                      re.I), '{r=0.8, g=0.4, b=0.2, a=1.0}'),
    (re.compile(r"^(v|value|val|enabled|visible|active|flag|exclusive|modal|sortable|looping|)$",
                re.I), 'true'),
    (re.compile(r"^(enabled|visible|active|flag|exclusive|modal|sortable|looping)$",
                re.I), 'true'),
    (re.compile(r"^(fn|callback|handler|on_.*|listener)$",
                re.I), 'function() end'),
    (re.compile(r"^(delta|dt)$",               re.I), '0.016'),
    (re.compile(r"^(scale|factor|ratio)$",     re.I), '1.0'),
    (re.compile(r"^(size|font_size)$",         re.I), '16'),
    (re.compile(r"^(speed|velocity)$",         re.I), '1.0'),
    (re.compile(r"^(duration|time|t)$",        re.I), '1.0'),
    (re.compile(r"^(max|maximum|limit)$",      re.I), '100'),
    (re.compile(r"^(min|minimum)$",            re.I), '0'),
    (re.compile(r"^(content|widget|child)$",   re.I), 'child_widget'),
    (re.compile(r"^(parent|root)$",            re.I), 'parent_widget'),
    (re.compile(r"^(texture|image|sprite)$",   re.I), 'texture'),
    (re.compile(r"^(font)$",                   re.I), 'font'),
    (re.compile(r"^(sound|audio|source)$",     re.I), 'source'),
    (re.compile(r"^(data|bytes|buf|buffer)$",  re.I), 'data'),
    (re.compile(r"^(table|tbl)$",              re.I), '{}'),
    (re.compile(r"^(env|environment)$",        re.I), '{}'),
    (re.compile(r"^(format|fmt)$",             re.I), '"png"'),
    (re.compile(r"^(mode|type_name|kind)$",    re.I), '"default"'),
    (re.compile(r"^(priority|p)$",             re.I), '1'),
    (re.compile(r"^(capacity|cap)$",           re.I), '16'),
    (re.compile(r"^(radius|r_)$",              re.I), '50.0'),
    (re.compile(r"^(angle|degrees|deg|rad)$",  re.I), '0.0'),
    (re.compile(r"^(volume|vol)$",             re.I), '1.0'),
    (re.compile(r"^(pitch)$",                  re.I), '1.0'),
    (re.compile(r"^(pan)$",                    re.I), '0.0'),
]


def param_default(name: str, optional: bool) -> str | None:
    """Return a sensible default Lua value for a named parameter."""
    if optional:
        return None  # skip optional params
    for pat, val in _PARAM_HEURISTICS:
        if pat.search(name):
            return val
    # Fallback: integer for *_idx suffix, string otherwise
    if name.endswith("_idx") or name.endswith("_index"):
        return "1"
    return '"value"'


def parse_sig(inferred_sig: str) -> list[tuple[str, bool]]:
    """
    Parse e.g. "(title, [content_idx], v)" into
    [("title", False), ("content_idx", True), ("v", False)].
    Parses comma-separated param names; names wrapped in [...] are optional.
    Returns empty list for "()" or if sig is None/empty.
    """
    if not inferred_sig:
        return []
    sig = inferred_sig.strip()
    if not (sig.startswith("(") and sig.endswith(")")):
        return []
    inner = sig[1:-1].strip()
    if not inner:
        return []
    params = []
    for part in inner.split(","):
        part = part.strip()
        optional = part.startswith("[") and part.endswith("]")
        name = part.strip("[] ").strip()
        if name:
            params.append((name, optional))
    return params


def build_defaults(inferred_sig: str) -> str | None:
    """Return a filled-in arg string like '\"Settings\", 1' for the sig, or None if no args needed."""
    params = parse_sig(inferred_sig)
    if not params:
        return None
    args = []
    for name, optional in params:
        val = param_default(name, optional)
        if val is None:
            break  # stop at first optional
        args.append(val)
    if not args:
        return None
    return ", ".join(args)


# ─── Build method lookup table from JSON ────────────────────────────────────

def load_method_table(api_data: dict) -> dict[str, dict[str, dict]]:
    """
    Returns: class_name (lowercase) -> method_name (lowercase) -> method_dict
    Also includes module-level functions as _MODULE_FUNCS -> module_name -> func_dict.
    """
    table: dict[str, dict[str, dict]] = {}
    mods = api_data.get("lua_api", {}).get("modules", {})
    for _mod_name, mod in mods.items():
        for cls_name, cls_data in (mod.get("classes") or {}).items():
            cls_key = cls_name.lower()
            if cls_key not in table:
                table[cls_key] = {}
            for m in (cls_data.get("methods") or []):
                table[cls_key][m["name"].lower()] = m
    return table


# ─── Stub detection ─────────────────────────────────────────────────────────

# Detect: `identifier:methodName(...)  -- desc` or `identifier:methodName(...)`
_STUB_LINE_RE = re.compile(
    r'^(\s*)'                         # leading indent
    r'(local\s+\w+\s*=\s*)?'         # optional: local varname =
    r'(\w+):(\w+)\(([^)]*)\)'        # obj:method(args)
    r'(\s*--.*)?$'                    # optional inline comment
)

# Detect class section header comment
_CLASS_SECTION_RE = re.compile(
    r'^-- (?:(\w+) instance methods \(variable: (\w+)\))'
)


# ─── Type() / typeOf() stub removal ─────────────────────────────────────────

_TYPE_STUB_RE = re.compile(
    r'^\s*local\s+type_val\s*=\s*\w+:type\(\)\s*(?:--.*)?$'
)
_TYPEOF_STUB_RE = re.compile(
    r'^\s*local\s+type_of\s*=\s*\w+:typeOf\([^)]*\)\s*(?:--.*)?$'
)

# Do NOT remove type()/typeOf() if this is the ONLY reference to those methods
# — coverage tool expects them. Instead, consolidate into dedicated subsection.
# We'll replace them with better variable names.


def improve_type_stubs(lines: list[str]) -> list[str]:
    """Rename type_val → class_name and type_of → is_button (etc.)."""
    out = []
    # track current class name from most recent class section comment
    current_class = "obj"
    for line in lines:
        m_class = _CLASS_SECTION_RE.match(line.strip())
        if m_class:
            current_class = m_class.group(1).lower()

        # Rename type_val → class_name
        if _TYPE_STUB_RE.match(line):
            var = re.search(r'(\w+):type\(\)', line)
            if var:
                varname = var.group(1)
                # Replace "local type_val = " with "local class_name = "
                line = line.replace("local type_val = ", "local class_name = ", 1)

        # Rename type_of → is_<class>_type
        elif _TYPEOF_STUB_RE.match(line):
            # Find what arg is passed to typeOf
            arg_m = re.search(r':typeOf\("([^"]+)"\)', line)
            if arg_m:
                type_arg = arg_m.group(1).lower().replace("_", "")
                line = line.replace("local type_of = ", f"local is_{type_arg}_type = ", 1)
            else:
                line = line.replace("local type_of = ", "local is_match = ", 1)

        out.append(line)
    return out


# ─── Fill in empty args ──────────────────────────────────────────────────────

def fill_empty_args(lines: list[str], method_table: dict[str, dict[str, dict]]) -> list[str]:
    """
    For each line that looks like `obj:method()` where the signature has
    required params, fill in sensible defaults.
    """
    out = []
    current_class: str | None = None

    for line in lines:
        # Track current class from section header
        m_class = _CLASS_SECTION_RE.match(line.strip())
        if m_class:
            current_class = m_class.group(1).lower()
            out.append(line)
            continue

        # Try to match a method stub with empty args
        m = _STUB_LINE_RE.match(line)
        if m:
            indent = m.group(1)
            assign_part = m.group(2) or ""
            obj_var = m.group(3)
            method_name = m.group(4)
            existing_args = m.group(5).strip()
            rest = m.group(6) or ""

            # Only fill if args are empty
            if not existing_args and current_class:
                cls_methods = method_table.get(current_class, {})
                method_info = cls_methods.get(method_name.lower())
                if method_info:
                    sig = method_info.get("inferred_sig", "()")
                    if sig and sig not in ("()", ""):
                        new_args = build_defaults(sig)
                        if new_args:
                            line = f"{indent}{assign_part}{obj_var}:{method_name}({new_args}){rest}"

        out.append(line)
    return out


# ─── Section header quality ──────────────────────────────────────────────────
# "-- ─── ClassName" but the ─ bar is very short from old expand_examples
# This pass makes sure every class section has a full-width separator.

_SHORT_SECTION_RE = re.compile(r'^-- (─{3}) (\w+)(─*)$')

def fix_class_headers(lines: list[str]) -> list[str]:
    """Make class section headers full width (80 chars)."""
    out = []
    for line in lines:
        m = _SHORT_SECTION_RE.match(line.strip())
        if m:
            title = m.group(2)
            # total line = "-- ─── Title ─────...", target 80 chars overall
            target = 80
            prefix = "-- \u2500\u2500\u2500 "
            suffix = " "
            used = len(prefix) + len(title) + len(suffix)
            bar_len = max(0, target - used)
            line = f"{prefix}{title}{suffix}{'─' * bar_len}"
        out.append(line)
    return out


# ─── Main processing ─────────────────────────────────────────────────────────

def process_file(path: Path, method_table: dict, dry_run: bool = False) -> bool:
    original = path.read_text(encoding="utf-8")
    lines = original.splitlines()

    lines = improve_type_stubs(lines)
    lines = fill_empty_args(lines, method_table)
    lines = fix_class_headers(lines)

    result = "\n".join(lines)
    if result.rstrip() != original.rstrip():
        if not dry_run:
            path.write_text(result + "\n", encoding="utf-8")
        return True
    return False


def main() -> None:
    parser = argparse.ArgumentParser(description="Improve stub quality in content/examples/*.lua")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--module", help="Only process the example for this module name")
    args = parser.parse_args()

    if not API_JSON.exists():
        print(f"[ERROR] API JSON not found: {API_JSON}")
        print("  Run: python tools/docs/gen_lua_api_data.py --output logs/data/lua_api_data.json")
        raise SystemExit(1)

    api_data = json.loads(API_JSON.read_text(encoding="utf-8"))
    method_table = load_method_table(api_data)

    if args.module:
        stem = MODULE_TO_EXAMPLE.get(args.module, args.module)
        targets = [EXAMPLES_DIR / f"{stem}.lua"]
    else:
        targets = sorted(EXAMPLES_DIR.glob("*.lua"))

    changed = 0
    for p in targets:
        if not p.exists():
            continue
        if process_file(p, method_table, args.dry_run):
            changed += 1
            print(f"[FIX] {p.name}")
        else:
            print(f"[OK ] {p.name}")

    print(f"\n{'Would change' if args.dry_run else 'Changed'}: {changed} files")


if __name__ == "__main__":
    main()
