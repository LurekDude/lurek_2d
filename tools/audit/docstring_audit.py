#!/usr/bin/env python3
"""
docstring_audit.py -- Audit Lurek2D Lua API docstrings for missing content.

For every registered Lua function/method in src/lua_api/*.rs, checks whether
the preceding /// docstring contains:
  1. A description (at least one non-blank /// line before any @tag)
  2. @param name : type  for each non-trivial Rust parameter
  3. @return type        for methods that return a non-unit value

Writes:
  logs/data/docstring_audit.json  -- machine-readable report for docstring_fix.py
  stdout                         -- human-readable summary with counts per file

Usage:
    python tools/docstring_audit.py                    # full audit
    python tools/docstring_audit.py --file RUST_FILE   # single file
    python tools/docstring_audit.py --json             # JSON only to stdout
    python tools/docstring_audit.py --check            # exit 1 if violations found

Exit codes:
    0  - no violations (or --json/default output)
    1  - violations found (--check only)
    2  - fatal error
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
SRC_LUA_API_DIR = WORKSPACE_ROOT / "src" / "lua_api"
OUTPUT_JSON = WORKSPACE_ROOT / "logs" / "docstring_audit.json"

# ---------------------------------------------------------------------------
# Rust-type → Lua-type mapping (used only to determine if a param is typed)
# ---------------------------------------------------------------------------
_RUST_TO_LUA: Dict[str, str] = {
    "f32": "number",    "f64": "number",
    "i32": "integer",   "i64": "integer",
    "u32": "integer",   "u64": "integer",
    "usize": "integer", "isize": "integer",
    "String": "string", "&str": "string", "LuaString": "string",
    "bool": "boolean",
    "LuaTable": "table",
    "LuaValue": "any",
    "LuaFunction": "function",
    "()": "",
    "LuaAnyUserData": "userdata",
}

def _rust_to_lua_simple(t: str) -> str:
    t = t.strip()
    m = re.match(r"Option<(.+)>", t)
    if m:
        inner = _rust_to_lua_simple(m.group(1))
        return inner + "?" if inner else ""
    m = re.match(r"Vec<.+>", t)
    if m:
        return "table"
    return _RUST_TO_LUA.get(t, t)

# ---------------------------------------------------------------------------
# Docstring collection
# ---------------------------------------------------------------------------

def _collect_docstring_above(lines: List[str], line_idx: int) -> str:
    """Collect /// lines above line_idx (stopping at blank/non-comment/non-attr)."""
    doc_parts: List[str] = []
    j = line_idx - 1
    while j >= 0:
        s = lines[j].strip()
        if s.startswith("///"):
            text = s[3:]
            doc_parts.insert(0, text[1:] if text.startswith(" ") else text)
        elif s.startswith("#[") or s == "":
            pass
        elif re.match(r"^let\s+\w+\s*=\s*\w+\.clone\(\)\s*;$", s):
            pass
        elif s.startswith("//") and not s.startswith("///"):
            pass
        else:
            break
        j -= 1
    return "\n".join(doc_parts).strip()

def _has_description(docstring: str) -> bool:
    """True if docstring has at least one non-blank, non-tag, non-section line first."""
    if not docstring:
        return False
    for line in docstring.split("\n"):
        stripped = line.strip()
        if not stripped:
            continue
        if stripped.startswith("@") or stripped.startswith("#"):
            break
        return True
    return False

def _has_param_tags(docstring: str) -> bool:
    return bool(re.search(r"^@param\b", docstring, re.MULTILINE))

def _has_return_tag(docstring: str) -> bool:
    return bool(re.search(r"^@return\b", docstring, re.MULTILINE))

def _get_param_tag_names(docstring: str) -> List[str]:
    return re.findall(r"^@param\s+(\w+)", docstring, re.MULTILINE)

# ---------------------------------------------------------------------------
# Closure body bounding (to avoid scanning past method end)
# ---------------------------------------------------------------------------

def _method_body_end(lines: List[str], decl_line: int) -> int:
    first = lines[decl_line].rstrip() if decl_line < len(lines) else ""
    if re.search(r"\|\s*Ok\s*\(", first) and first.strip().endswith(");"):
        return decl_line
    depth = 0
    found_open = False
    limit = min(decl_line + 80, len(lines))
    for j in range(decl_line, limit):
        s = lines[j].strip()
        if s.startswith("//"):
            continue
        for ch in s:
            if ch == "{":
                depth += 1
                found_open = True
            elif ch == "}":
                depth -= 1
        if found_open and depth <= 0:
            return j
    return min(decl_line + 40, len(lines) - 1)

# ---------------------------------------------------------------------------
# Rust signature scanning (to detect what SHOULD be documented)
# ---------------------------------------------------------------------------

def _extract_rust_params(lines: List[str], decl_line: int) -> List[Tuple[str, str]]:
    """Return [(param_name, rust_type)] for non-trivial closure params.

    Only detects:
      |_, (a,b): (T1,T2)|           -- multi-param tuple
      |_, this, name: Type|         -- single scalar with type
      |_, this, (name,): (Type,)|   -- single-element tuple
    Returns [] for no-param closures |_, ()| or |_, this, ()|.
    """
    parts: List[str] = []
    found_pipe = False
    pipe_count = 0
    for line in lines[decl_line: decl_line + 6]:
        s = line.strip()
        if not found_pipe:
            if "|" not in s:
                continue
            found_pipe = True
        parts.append(s)
        pipe_count += s.count("|")
        if pipe_count >= 2:
            break
    text = " ".join(parts)
    if not text:
        return []

    # Multi-param tuple: (a, b): (T1, T2)
    m = re.search(r"\|[^|]*?,\s*\(([^)]+)\):\s*\(([^)]+)\)", text)
    if m:
        names = [n.strip().lstrip("_") for n in m.group(1).split(",")]
        types = [t.strip() for t in m.group(2).split(",")]
        return [(n, t) for n, t in zip(names, types) if t and t != "()"]

    # Single-element tuple: (name,): (Type,)
    m = re.search(r"\|[^|]*?,\s*\(([a-z_]\w*)\s*,?\):\s*\(([^,)]+),?\)", text)
    if m:
        name = m.group(1).lstrip("_")
        rtype = m.group(2).strip()
        if rtype and rtype != "()":
            return [(name, rtype)]
        return []

    # Single scalar: |_, this, name: Type|  or |_, name: Type|
    m = re.search(
        r"\|[^|]*?,\s*(?:[a-z_]\w*,\s*)?([a-z_]\w*):\s*([A-Za-z][A-Za-z0-9_<>& ]*?)\s*[|{]",
        text
    )
    if m:
        name = m.group(1).lstrip("_")
        rtype = m.group(2).strip()
        if rtype and rtype != "()":
            return [(name, rtype)]
        return []

    # No-param: |_, ()| or |_, this, ()|
    if re.search(r"\|[^|]*?,\s*(?:[a-z_]\w*,\s*)?\(\s*\)", text):
        return []

    return []


def _extract_rust_return(lines: List[str], decl_line: int) -> str:
    """Return a Lua type hint for the return value by scanning the method body.

    Empty string = unit/void (Ok(())), unreachable, or unknown.
    """
    end = _method_body_end(lines, decl_line)
    body = "\n".join(lines[decl_line: end + 1])

    # Ok(Some(lua_xxx_new(...))) → Xxx?
    m = re.search(r"Ok\(Some\(lua_(\w+)_new\(", body)
    if m:
        return _lua_name_to_type(m.group(1)) + "?"

    # Ok(lua_xxx_new(...)) → Xxx
    m = re.search(r"Ok\(lua_(\w+)_new\(", body)
    if m:
        return _lua_name_to_type(m.group(1))

    # create_table + Ok(tbl) → table
    if "create_table()" in body and re.search(r"Ok\(tbl\b", body):
        return "table"

    # Common bool patterns
    if re.search(r"Ok\(.+\.(is_empty|is_full|is_some|is_none)\(\)", body):
        return "boolean"

    # Common integer patterns
    if re.search(r"Ok\(.+\.(size|len|count)\(\)", body):
        return "integer"

    # Explicit bool wrap
    if re.search(r"Ok\((true|false)\b", body):
        return "boolean"

    # Ok(n) where n is a known Rust integer expression
    if re.search(r"Ok\(\w+ as u(?:size|32|64|8)\)", body):
        return "integer"

    # Ok(()) — unit, no return tag needed
    if re.search(r"Ok\s*\(\s*\(\s*\)", body):
        return ""

    # Detect explicit string return
    if re.search(r"Ok\(\w+\.clone\(\)\)", body) or re.search(r"Ok\(\w+\.to_string\(\)\)", body):
        return "string"

    # Fallback: if body has a non-trivial Ok(...) that is not Ok(())
    # detect something was returned but type unknown
    m = re.search(r"Ok\(([^)]+)\)", body)
    if m and m.group(1).strip() not in ("", "()", "None"):
        return "?"  # unknown non-unit return

    return ""

def _lua_name_to_type(snake: str) -> str:
    return "".join(p.capitalize() for p in snake.split("_"))

# ---------------------------------------------------------------------------
# Main audit logic
# ---------------------------------------------------------------------------

class Violation:
    MISSING_DESCRIPTION = "missing_description"
    MISSING_PARAM = "missing_param"
    MISSING_RETURN = "missing_return"
    EXTRA_PARAM = "extra_param_tag"  # @param tag but no such Rust param (typo risk)


def _audit_file(rs_file: Path) -> List[dict]:
    """Audit one Rust file and return a list of violation dicts."""
    try:
        content = rs_file.read_text(encoding="utf-8")
    except Exception as e:
        print(f"ERROR reading {rs_file}: {e}", file=sys.stderr)
        return []

    lines = content.splitlines()
    module = rs_file.stem.replace("_api", "")
    rel = str(rs_file.relative_to(WORKSPACE_ROOT)).replace("\\", "/")

    violations: List[dict] = []

    method_re = re.compile(r'methods\.add_method(?:_mut)?\(\s*"(\w+)"')
    set_inline_re = re.compile(r'\.set\(\s*"(\w+)"\s*,\s*lua\.create_function')
    set_multiline_re = re.compile(r'\.set\(\s*$')
    name_next_re = re.compile(r'^\s*"(\w+)"\s*,')

    current_impl: Optional[str] = None
    brace_depth = 0
    impl_re = re.compile(r'^\s*impl(?:<[^>]*>)?\s+(?:LuaUserData\s+for\s+)?(\w+)')

    def record(line_num: int, kind: str, name: str, owner: str, violations_list: list,
               violation_type: str, detail: str = "") -> None:
        violations_list.append({
            "file": rel,
            "line": line_num,
            "module": module,
            "owner": owner,
            "name": name,
            "kind": kind,       # "function" | "method"
            "violation": violation_type,
            "detail": detail,
        })

    def check(line_num: int, name: str, kind: str, owner: str) -> None:
        docstring = _collect_docstring_above(lines, line_num - 1)

        # 1. Description
        if not _has_description(docstring):
            record(line_num, kind, name, owner, violations, Violation.MISSING_DESCRIPTION)

        # 2. @param coverage
        rust_params = _extract_rust_params(lines, line_num - 1)
        non_trivial = [(n, t) for n, t in rust_params if t not in ("()", "")]
        if non_trivial and not _has_param_tags(docstring):
            param_hints = ", ".join(
                f"{n} : {_rust_to_lua_simple(t) or t}" for n, t in non_trivial
            )
            record(line_num, kind, name, owner, violations, Violation.MISSING_PARAM,
                   f"Rust params: {param_hints}")

        # 3. @return coverage
        if not _has_return_tag(docstring):
            ret = _extract_rust_return(lines, line_num - 1)
            if ret and ret != "":
                record(line_num, kind, name, owner, violations, Violation.MISSING_RETURN,
                       f"Rust return: {ret}")

    i = 0
    while i < len(lines):
        stripped = lines[i].strip()

        if not stripped.startswith("//"):
            brace_depth += stripped.count("{") - stripped.count("}")

        m = impl_re.match(stripped)
        if m:
            current_impl = m.group(1)

        if brace_depth <= 0:
            current_impl = None
            brace_depth = 0

        # methods.add_method(...)
        mm = method_re.search(stripped)
        if mm:
            owner = current_impl or "Unknown"
            display_owner = owner[3:] if owner.startswith("Lua") else owner
            check(i + 1, mm.group(1), "method", display_owner)

        # lurek.set("name", lua.create_function(...))  single line
        sm = set_inline_re.search(stripped)
        if sm:
            check(i + 1, sm.group(1), "function", "")

        # Multi-line set(
        elif set_multiline_re.search(stripped) and i + 1 < len(lines):
            nxt = lines[i + 1].strip()
            nm = name_next_re.match(nxt)
            if nm:
                is_func = any("create_function" in lines[k]
                              for k in range(i + 1, min(i + 5, len(lines))))
                if is_func:
                    check(i + 1, nm.group(1), "function", "")

        i += 1

    return violations


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit Lurek2D Lua API docstrings for missing content.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--file", metavar="RUST_FILE",
                        help="Audit a single Rust file only")
    parser.add_argument("--json", action="store_true",
                        help="Print full JSON report to stdout instead of summary")
    parser.add_argument("--check", action="store_true",
                        help="Exit 1 if any violations are found")
    parser.add_argument("--src", metavar="DIR", default=str(SRC_LUA_API_DIR),
                        help="Path to src/lua_api/ directory")
    args = parser.parse_args(argv)

    src_dir = Path(args.src)
    if not src_dir.is_dir():
        print(f"ERROR: source dir not found: {src_dir}", file=sys.stderr)
        return 2

    if args.file:
        files = [Path(args.file)]
    else:
        files = sorted(src_dir.glob("*_api.rs"))

    all_violations: List[dict] = []
    for f in files:
        all_violations.extend(_audit_file(f))

    # Group by violation type and file for the summary
    by_type: Dict[str, int] = {}
    by_file: Dict[str, List[dict]] = {}
    for v in all_violations:
        by_type[v["violation"]] = by_type.get(v["violation"], 0) + 1
        by_file.setdefault(v["file"], []).append(v)

    # Write JSON report
    report = {
        "total_violations": len(all_violations),
        "by_type": by_type,
        "files_with_violations": len(by_file),
        "violations": all_violations,
    }

    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_JSON.write_text(
        json.dumps(report, indent=2, ensure_ascii=False), encoding="utf-8"
    )

    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return 0

    # ── Human-readable summary ────────────────────────────────────────────────
    total = len(all_violations)
    print(f"\n=== Lurek2D Docstring Audit ===")
    print(f"Total violations: {total}")
    for vtype, count in sorted(by_type.items(), key=lambda x: -x[1]):
        label = {
            Violation.MISSING_DESCRIPTION: "Missing description",
            Violation.MISSING_PARAM:       "Missing @param tag(s)",
            Violation.MISSING_RETURN:      "Missing @return tag",
        }.get(vtype, vtype)
        print(f"  {label}: {count}")
    print()

    if by_file:
        print("By file:")
        for fpath, vs in sorted(by_file.items()):
            counts = {}
            for v in vs:
                counts[v["violation"]] = counts.get(v["violation"], 0) + 1
            detail = "  ".join(f"{k}:{counts[k]}" for k in sorted(counts))
            print(f"  {fpath}  ({detail})")

    print(f"\nReport written: {OUTPUT_JSON}")

    if total == 0:
        print("[OK] No violations found.")
    else:
        print(f"\n[!] {total} violations. Run tools/docstring_fix.py to auto-fix.")

    return 1 if (args.check and total > 0) else 0


if __name__ == "__main__":
    sys.exit(main())
