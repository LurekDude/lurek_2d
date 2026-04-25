#!/usr/bin/env python3
"""
docstring_fix.py -- Auto-inject missing @param/@return tags into Lua API docstrings.

Reads logs/data/docstring_audit.json (produced by docstring_audit.py) and patches
the corresponding src/lua_api/*.rs files by inserting the missing /// lines directly
above each registered function.

Strategy per violation type:
  missing_description  → insert a bare name-based description if truly absent
  missing_param        → insert ``/// @param name : type`` using the Rust signature
  missing_return       → insert ``/// @return type`` using body-scan heuristics

The patching is done per-file, bottom-up (highest line first) so that line
numbers from the audit report remain valid as we insert text.

Usage:
    python tools/docstring_fix.py                  # use logs/data/docstring_audit.json
    python tools/docstring_fix.py --dry-run        # print patches, do not write
    python tools/docstring_fix.py --file RS_FILE   # patch one file only
    python tools/docstring_fix.py --no-description # skip description injection

Exit codes:
    0  all patches applied (or --dry-run)
    1  some patches could not be applied
    2  fatal error
"""

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
AUDIT_JSON = WORKSPACE_ROOT / "logs" / "data" / "docstring_audit.json"

# ── Rust → Lua type map ─────────────────────────────────────────────────────

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


def _rust_to_lua(t: str) -> str:
    t = t.strip()
    m = re.match(r"Option<(.+)>", t)
    if m:
        inner = _rust_to_lua(m.group(1))
        return inner + "?" if inner else "any?"
    m = re.match(r"Vec<.+>", t)
    if m:
        return "table"
    result = _RUST_TO_LUA.get(t, "")
    if not result:
        # LuaXxx userdata → strip Lua prefix → class name
        if t.startswith("Lua") and t[3:4].isupper():
            return t[3:]
        return t
    return result


def _lua_name_to_class(snake: str) -> str:
    return "".join(p.capitalize() for p in snake.split("_"))


# ── Rust signature extraction (duplicated from docstring_audit.py) ──────────

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


def _extract_rust_params(lines: List[str], decl_line: int) -> List[Tuple[str, str]]:
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

    m = re.search(r"\|[^|]*?,\s*\(([^)]+)\):\s*\(([^)]+)\)", text)
    if m:
        names = [n.strip().lstrip("_") for n in m.group(1).split(",")]
        types = [t.strip() for t in m.group(2).split(",")]
        return [(n, t) for n, t in zip(names, types) if t and t != "()"]

    m = re.search(r"\|[^|]*?,\s*\(([a-z_]\w*)\s*,?\):\s*\(([^,)]+),?\)", text)
    if m:
        name = m.group(1).lstrip("_")
        rtype = m.group(2).strip()
        if rtype and rtype != "()":
            return [(name, rtype)]
        return []

    m = re.search(
        r"\|[^|]*?,\s*(?:[a-z_]\w*,\s*)?([a-z_]\w*):\s*([A-Za-z][A-Za-z0-9_<>& ]*?)\s*[|{]",
        text,
    )
    if m:
        name = m.group(1).lstrip("_")
        rtype = m.group(2).strip()
        if rtype and rtype != "()":
            return [(name, rtype)]
        return []

    return []


def _extract_rust_return(lines: List[str], decl_line: int) -> str:
    end = _method_body_end(lines, decl_line)
    body = "\n".join(lines[decl_line: end + 1])

    m = re.search(r"Ok\(Some\(lua_(\w+)_new\(", body)
    if m:
        return _lua_name_to_class(m.group(1)) + "?"

    m = re.search(r"Ok\(lua_(\w+)_new\(", body)
    if m:
        return _lua_name_to_class(m.group(1))

    if "create_table()" in body and re.search(r"Ok\(tbl\b", body):
        return "table"

    if re.search(r"Ok\(.+\.(is_empty|is_full|is_some|is_none)\(\)", body):
        return "boolean"

    if re.search(r"Ok\(.+\.(size|len|count)\(\)", body):
        return "integer"

    if re.search(r"Ok\((true|false)\b", body):
        return "boolean"

    if re.search(r"Ok\(\w+ as u(?:size|32|64|8)\)", body):
        return "integer"

    if re.search(r"Ok\s*\(\s*\(\s*\)", body):
        return ""

    if re.search(r"Ok\(\w+\.clone\(\)\)", body) or re.search(r"Ok\(\w+\.to_string\(\)\)", body):
        return "string"

    m = re.search(r"Ok\(([^)]+)\)", body)
    if m and m.group(1).strip() not in ("", "()", "None"):
        # Try to detect borrow type for userdata returns
        mb = re.search(r"borrow::<(Lua\w+)>", m.group(1))
        if mb:
            return mb.group(1)[3:]
        return "any"

    return ""


def _name_to_description(method_name: str) -> str:
    """Convert camelCase method name to a short sentence description."""
    # Insert space before uppercase run: getCard → get Card
    spaced = re.sub(r"([a-z])([A-Z])", r"\1 \2", method_name)
    spaced = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1 \2", spaced)
    words = spaced.lower().split()
    if not words:
        return method_name + "."
    # Common verb mapping
    if words[0] in ("get", "fetch", "retrieve"):
        rest = " ".join(words[1:])
        return f"Returns the {rest}." if rest else "Returns a value."
    if words[0] in ("set", "put", "assign"):
        rest = " ".join(words[1:])
        return f"Sets the {rest}." if rest else "Sets a value."
    if words[0] in ("is", "has", "can", "checks"):
        rest = " ".join(words[1:])
        return f"Returns true if {rest}." if rest else "Returns true or false."
    if words[0] in ("add", "push", "insert", "append"):
        rest = " ".join(words[1:])
        return f"Adds {rest}." if rest else "Adds an item."
    if words[0] in ("remove", "delete", "pop"):
        rest = " ".join(words[1:])
        return f"Removes {rest}." if rest else "Removes an item."
    if words[0] in ("clear", "reset"):
        rest = " ".join(words[1:])
        return f"Clears {rest}." if rest else "Clears the state."
    if words[0] in ("count", "size", "length", "len"):
        return "Returns the number of items."
    return " ".join(words).capitalize() + "."


# ── Patch logic ─────────────────────────────────────────────────────────────

def _find_doc_block_end(lines: List[str], decl_line: int) -> int:
    """Return the index of the last /// line immediately above decl_line.

    If there are no /// lines above, returns decl_line - 1 (insert before decl_line).
    Skips blank lines and attribute lines (#[...]).
    """
    j = decl_line - 1
    last_doc_line = decl_line - 1
    while j >= 0:
        s = lines[j].strip()
        if s.startswith("///"):
            last_doc_line = j
            j -= 1
            continue
        if s.startswith("#[") or s == "":
            j -= 1
            continue
        break
    return last_doc_line


def _get_indent(lines: List[str], decl_line: int) -> str:
    """Return the leading whitespace of the declaration line."""
    line = lines[decl_line] if decl_line < len(lines) else ""
    return re.match(r"^(\s*)", line).group(1)


def _build_param_lines(
    method_name: str,
    lines: List[str],
    decl_line: int,
    existing_params: List[str],
    indent: str,
) -> List[str]:
    """Build ``/// @param name : type`` lines for params not yet documented."""
    rust_params = _extract_rust_params(lines, decl_line)
    if not rust_params:
        return []

    # Also scan body for borrow:<LuaXxx>() to resolve userdata types
    end = _method_body_end(lines, decl_line)
    body_lines = lines[decl_line: end + 1]
    userdata_map: Dict[str, str] = {}
    for bl in body_lines:
        bm = re.search(r"(\w+)\.borrow::<(Lua\w+)>\(\)", bl)
        if bm:
            pname = bm.group(1)
            struct = bm.group(2)
            userdata_map[pname] = struct[3:] if struct.startswith("Lua") else struct

    result = []
    for name, rtype in rust_params:
        if name in existing_params:
            continue
        lua_type = userdata_map.get(name) or _rust_to_lua(rtype) or "any"
        result.append(f"{indent}/// @param {name} : {lua_type}")
    return result


def _build_return_line(
    lines: List[str], decl_line: int, indent: str
) -> Optional[str]:
    """Build a ``/// @return type`` line for this method, or None if void."""
    lua_ret = _extract_rust_return(lines, decl_line)
    if not lua_ret:
        return None
    return f"{indent}/// @return {lua_ret}"


def patch_file(
    rs_file: Path,
    violations_for_file: List[dict],
    dry_run: bool = False,
    skip_description: bool = False,
) -> int:
    """Apply all patches for one file. Returns number of patches applied."""
    try:
        content = rs_file.read_text(encoding="utf-8")
    except Exception as e:
        print(f"ERROR reading {rs_file}: {e}", file=sys.stderr)
        return 0

    lines = content.splitlines(keepends=True)

    # Group violations by (line, name) so we don't double-patch the same site.
    # Use the reported 1-based line from audit.
    # Sort descending by line so later-in-file patches don't shift earlier ones.
    sites: Dict[int, dict] = {}
    for v in violations_for_file:
        ln = v.get("line", 0)
        if ln not in sites:
            sites[ln] = {"line": ln, "name": v["name"], "violations": []}
        sites[ln]["violations"].append(v["violation"])

    ordered = sorted(sites.values(), key=lambda x: x["line"], reverse=True)

    patches_applied = 0
    for site in ordered:
        decl_line = site["line"] - 1  # convert to 0-based
        if decl_line < 0 or decl_line >= len(lines):
            continue

        viol_types = set(site["violations"])
        method_name = site["name"]
        indent = _get_indent(lines, decl_line)

        # Collect existing @param names from current docstring
        existing_doc_lines = []
        j = decl_line - 1
        while j >= 0:
            s = lines[j].strip()
            if s.startswith("///"):
                existing_doc_lines.insert(0, s[3:].strip())
                j -= 1
            elif s.startswith("#[") or s == "":
                j -= 1
            else:
                break

        existing_doc = "\n".join(existing_doc_lines)
        existing_params = re.findall(r"^@param\s+(\w+)", existing_doc, re.MULTILINE)

        inject: List[str] = []

        # ── Description ──────────────────────────────────────────────────
        if "missing_description" in viol_types and not skip_description:
            desc = _name_to_description(method_name)
            inject.append(f"{indent}/// {desc}")
            inject.append(f"{indent}///")

        # ── @param tags ───────────────────────────────────────────────────
        if "missing_param" in viol_types:
            param_lines = _build_param_lines(
                method_name,
                [l.rstrip("\n") for l in lines],
                decl_line,
                existing_params,
                indent,
            )
            inject.extend(param_lines)

        # ── @return tag ───────────────────────────────────────────────────
        if "missing_return" in viol_types:
            ret_line = _build_return_line(
                [l.rstrip("\n") for l in lines],
                decl_line,
                indent,
            )
            if ret_line:
                inject.append(ret_line)

        if not inject:
            continue

        # Find where to insert — after the last existing /// line above decl
        insert_pos = _find_doc_block_end(
            [l.rstrip("\n") for l in lines], decl_line
        )
        # insert_pos is the last existing doc line (or decl_line-1 if no doc)
        # We insert AFTER insert_pos, i.e., at insert_pos + 1
        insert_at = insert_pos + 1

        if dry_run:
            print(f"\n  [{rs_file.name}:{decl_line + 1}] {method_name}")
            for line in inject:
                print(f"    + {line}")
        else:
            injected = [l + "\n" for l in inject]
            lines[insert_at:insert_at] = injected

        patches_applied += 1

    if not dry_run and patches_applied > 0:
        with open(rs_file, "w", encoding="utf-8") as f:
            f.writelines(lines)
        print(f"  Patched {rs_file.name}: {patches_applied} site(s) updated")

    return patches_applied


# ── CLI ──────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(description="Auto-inject missing @param/@return docstring tags.")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be injected without writing files")
    parser.add_argument("--file", metavar="RS_FILE", help="Patch only this .rs file")
    parser.add_argument("--no-description", action="store_true", help="Skip injecting description lines")
    parser.add_argument("--audit-json", metavar="FILE", default=str(AUDIT_JSON), help="Path to docstring_audit.json")
    args = parser.parse_args()

    audit_path = Path(args.audit_json)
    if not audit_path.exists():
        print(f"ERROR: audit file not found: {audit_path}", file=sys.stderr)
        print("Run:  python tools/docstring_audit.py  first", file=sys.stderr)
        return 2

    try:
        report = json.loads(audit_path.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"ERROR parsing audit JSON: {e}", file=sys.stderr)
        return 2

    violations = report.get("violations", [])
    if not violations:
        print("No violations in audit report — nothing to do.")
        return 0

    # Group by file
    by_file: Dict[str, List[dict]] = {}
    for v in violations:
        by_file.setdefault(v["file"], []).append(v)

    if args.file:
        target = Path(args.file).resolve()
        rel = str(target.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
        if rel not in by_file:
            print(f"No violations for {rel}")
            return 0
        by_file = {rel: by_file[rel]}

    total_patches = 0
    for rel_path, file_violations in sorted(by_file.items()):
        rs_file = WORKSPACE_ROOT / rel_path.replace("/", "\\")
        if not rs_file.exists():
            print(f"SKIP (not found): {rel_path}")
            continue
        count = patch_file(
            rs_file,
            file_violations,
            dry_run=args.dry_run,
            skip_description=args.no_description,
        )
        total_patches += count

    mode = "(dry-run)" if args.dry_run else ""
    print(f"\nTotal sites patched {mode}: {total_patches}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
