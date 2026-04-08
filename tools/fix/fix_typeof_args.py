#!/usr/bin/env python3
"""
tools/fix/fix_typeof_args.py
Fix VAR:typeOf("name") stubs — replace "name" with the real class name
using the API JSON as ground truth.

Also fixes the matching VAR_type = VAR:type() comment to say the
actual class name.
"""
import json
import re
from pathlib import Path

ROOT     = Path(__file__).resolve().parents[2]
DATA_F   = ROOT / "docs" / "logs" / "lua_api_data.json"
EXAMPLES = ROOT / "examples"

# ── Load all class names from JSON ──────────────────────────────────────────
with open(DATA_F, encoding="utf-8") as f:
    data = json.load(f)

api_modules = data["lua_api"]["modules"]

# Build a map: lowercase_varname → ClassName (canonical)
class_names: dict[str, str] = {}
for mod_data in api_modules.values():
    for class_name in (mod_data.get("classes") or {}).keys():
        # Map lower-case of the class name to its canonical spelling
        class_names[class_name.lower()] = class_name

# ── Fix each file ────────────────────────────────────────────────────────────
def fix_file(path: Path) -> bool:
    src = path.read_text(encoding="utf-8")
    original = src

    # Pattern: VAR_is_type = VAR:typeOf("name")   -- desc
    def repl_typeof(m: re.Match) -> str:
        indent = m.group(1)
        lhs_var = m.group(2)   # e.g. "aiworld_is_type"
        obj_var = m.group(3)   # e.g. "aiworld"
        rest    = m.group(4)   # comment or end of line

        # Derive class name from obj_var
        canonical = class_names.get(obj_var.lower())
        if canonical is None:
            return m.group(0)  # unknown — leave unchanged

        # Update the typeOf arg
        return f'{indent}local {lhs_var} = {obj_var}:typeOf("{canonical}"){rest}'

    src = re.sub(
        r'^(\s*)local\s+(\w+)\s*=\s*(\w+):typeOf\("name"\)(.*)',
        repl_typeof,
        src,
        flags=re.MULTILINE,
    )

    # Pattern: VAR_type = VAR:type()  -- comment often says "object"
    # Update trailing comment to say the actual class name
    def repl_type_comment(m: re.Match) -> str:
        indent   = m.group(1)
        lhs_var  = m.group(2)
        obj_var  = m.group(3)
        old_cmnt = m.group(4)  # has leading spaces already

        canonical = class_names.get(obj_var.lower())
        if canonical is None:
            return m.group(0)

        new_cmnt = f'  -- "{canonical}"'
        return f'{indent}local {lhs_var} = {obj_var}:type(){new_cmnt}'

    src = re.sub(
        r'^(\s*)local\s+(\w+_type)\s*=\s*(\w+):type\(\)(.*)',
        repl_type_comment,
        src,
        flags=re.MULTILINE,
    )

    if src != original:
        path.write_text(src, encoding="utf-8")
        return True
    return False


def main():
    fixed = 0
    for p in sorted(EXAMPLES.glob("*.lua")):
        if fix_file(p):
            fixed += 1
            print(f"[FIX] {p.name}")
    print(f"\nFixed {fixed} file(s)")


if __name__ == "__main__":
    main()
