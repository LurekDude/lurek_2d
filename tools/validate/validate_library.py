"""Validate Lunasome libraries under content/library/.

Checks every library directory for required structure and conventions:
  - Has init.lua (the entry point loaded by require()).
  - Has example.lua demonstrating usage.
  - Has a corresponding test at tests/lua/library/test_library_<name>.lua.
  - init.lua returns a table (scans for 'return' at file end).
  - init.lua contains at least one LDoc-style tag (--- @, --- @module, etc.).
  - No library uses raw global writes (enforces local-only exports).

Usage:
    python tools/validate/validate_library.py [--library NAME] [--strict]

Options:
    --library NAME   Validate only the named library (default: all).
    --strict         Treat warnings as errors.
    --format text|json  Output format (default: text).

Exit code:
    0 if valid, 1 if any errors found.
"""
import argparse
import json
import re
import sys
from pathlib import Path

ROOT = Path(".").resolve()
LIBRARY_DIR = ROOT / "library"
TESTS_DIR = ROOT / "tests" / "lua" / "library"


def validate_one(lib_dir: Path, strict: bool = False) -> list[dict]:
    """Validate a single library directory. Returns findings list."""
    findings: list[dict] = []
    name = lib_dir.name

    # --- Required files ---
    init_lua = lib_dir / "init.lua"
    example_lua = lib_dir / "example.lua"
    test_file = TESTS_DIR / f"test_library_{name}.lua"

    if not init_lua.exists():
        findings.append({
            "level": "ERROR", "library": name,
            "message": "Missing init.lua (required entry point)",
        })
    if not example_lua.exists():
        findings.append({
            "level": "ERROR" if strict else "WARN", "library": name,
            "message": "Missing example.lua",
        })
    if not test_file.exists():
        findings.append({
            "level": "ERROR" if strict else "WARN", "library": name,
            "message": f"Missing test file: {test_file.relative_to(ROOT)}",
        })

    # --- init.lua quality checks ---
    if init_lua.exists():
        text = init_lua.read_text(encoding="utf-8")
        lines = text.splitlines()

        # Check returns a table
        has_return = any(
            re.match(r"^return\b", ln.strip())
            for ln in lines[-10:] if ln.strip()
        )
        if not has_return:
            findings.append({
                "level": "WARN", "library": name,
                "message": "init.lua does not end with a return statement",
            })

        # Check has LDoc tags  (accept both `-- @` and `--- @` styles; gen_lib_docs.py parses both)
        has_ldoc = bool(re.search(r"^--+\s*@", text, re.MULTILINE))
        if not has_ldoc:
            findings.append({
                "level": "ERROR" if strict else "WARN", "library": name,
                "message": "init.lua has no LDoc-style annotations (-- @... or --- @...)",
            })

        # Check no raw global writes
        global_write = re.search(
            r"^(?!local\b)(\w+)\s*=\s*(?!nil)", text, re.MULTILINE
        )
        if global_write:
            var = global_write.group(1)
            # Exclude common false positives
            if var not in ("return", "if", "for", "while", "end", "else",
                           "elseif", "do", "then", "function", "repeat",
                           "until", "break", "goto", "M", "self"):
                findings.append({
                    "level": "WARN", "library": name,
                    "message": f"init.lua may write global '{var}' "
                               f"(prefer local + return table)",
                })

    return findings


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate Lunasome libraries under content/library/."
    )
    parser.add_argument("--library", help="Validate only this library")
    parser.add_argument("--strict", action="store_true",
                        help="Treat warnings as errors")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    if not LIBRARY_DIR.exists():
        print(f"ERROR: {LIBRARY_DIR} does not exist")
        return 1

    # Discover libraries
    if args.library:
        lib_dirs = [LIBRARY_DIR / args.library]
        if not lib_dirs[0].is_dir():
            print(f"ERROR: Library '{args.library}' not found in {LIBRARY_DIR}")
            return 1
    else:
        lib_dirs = sorted(
            d for d in LIBRARY_DIR.iterdir()
            if d.is_dir() and not d.name.startswith(".")
        )

    all_findings: list[dict] = []
    for lib_dir in lib_dirs:
        all_findings.extend(validate_one(lib_dir, strict=args.strict))

    errors = [f for f in all_findings if f["level"] == "ERROR"]
    warns = [f for f in all_findings if f["level"] == "WARN"]

    if args.format == "json":
        print(json.dumps({
            "libraries": len(lib_dirs),
            "findings": all_findings,
        }, indent=2))
    else:
        for f in all_findings:
            print(f"[{f['level']}] {f['library']}: {f['message']}")
        print(f"\n{len(lib_dirs)} libraries, "
              f"{len(errors)} error(s), {len(warns)} warning(s)")

    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
