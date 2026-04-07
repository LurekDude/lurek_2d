#!/usr/bin/env python3
"""Convenience runner: regenerate the full Luna2D documentation pipeline in one command.

Steps:
    1. gen_rust_api_data.py     -> docs/logs/rust_api_data.json    (Rust master JSON)
    2. gen_lua_api_data.py      -> docs/logs/lua_api_data.json     (Lua master JSON)
    3. gen_luadoc.py            -> docs/API/luna.lua              (LuaCATS stubs)
    4. gen_docs_lua.py          -> docs/API/lua-api.md            (compact Lua API reference)
    5. gen_docs_rust.py         -> docs/API/rust-api.md           (compact Rust API reference)
    6. gen_wiki_api.py          -> wiki/API-Reference.md          (game-developer cheatsheet)
    7. doc_coverage.py          -> docs/logs/doc_coverage.json    (docstring coverage analytics)
    8. test_coverage.py         -> docs/logs/test_coverage.json   (test coverage analytics)
    9. gen_test_docs.py --mode rust  -> docs/tests/test_docs_rust.md
   10. gen_test_docs.py --mode lua   -> docs/tests/test_docs_lua.md
   11. gen_coverage_gaps.py     -> docs/API/coverage_gaps.md      (API gap report)

Usage:
    python tools/gen_all_docs.py          # run all steps
"""

import subprocess
import sys
import time
from pathlib import Path

SCRIPTS = [
    ("docs/gen_rust_api_data.py", "Rust JSON (docs/logs/rust_api_data.json)"),
    ("docs/gen_lua_api_data.py",  "Lua JSON (docs/logs/lua_api_data.json)"),
    ("docs/gen_luadoc.py",        "LuaCATS Stubs (docs/API/luna.lua)"),
    ("docs/gen_docs_lua.py",      "Lua API reference (docs/API/lua-api.md)"),
    ("docs/gen_docs_rust.py",     "Rust API reference (docs/API/rust-api.md)"),
    ("docs/gen_wiki_api.py",      "Wiki cheatsheet (wiki/API-Reference.md)"),
    ("audit/doc_coverage.py",      "Doc coverage analytics (docs/logs/doc_coverage.json)"),
    ("audit/test_coverage.py",     "Test coverage analytics (docs/logs/test_coverage.json)"),
]

# Scripts that need extra arguments (script_name, args_list, label)
SCRIPTS_WITH_ARGS = [
    ("docs/gen_test_docs.py", ["--mode", "rust", "--output", "docs/tests/test_docs_rust.md"],
     "Rust test docs (docs/tests/test_docs_rust.md)"),
    ("docs/gen_test_docs.py", ["--mode", "lua",  "--output", "docs/tests/test_docs_lua.md"],
     "Lua test docs (docs/tests/test_docs_lua.md)"),
    ("audit/gen_coverage_gaps.py", [],
     "Coverage gaps (docs/API/coverage_gaps.md)"),
]


TOOLS_DIR = Path(__file__).parent


def run_script(script_name: str, extra_args: list, label: str) -> bool:
    script = TOOLS_DIR / script_name
    print(f"  [{label}]")
    t0 = time.monotonic()
    result = subprocess.run(
        [sys.executable, str(script)] + extra_args,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    elapsed = time.monotonic() - t0
    if result.returncode != 0:
        print(f"    FAILED ({elapsed:.1f}s)")
        if result.stderr:
            for line in result.stderr.strip().split("\n")[-5:]:
                print(f"    stderr: {line}")
        return False
    # Print the last line of stdout (usually the [OK] summary)
    lines = [l for l in result.stdout.strip().split("\n") if l.strip()]
    if lines:
        print(f"    {lines[-1]}")
    print(f"    done in {elapsed:.1f}s")
    return True


def main() -> None:
    print("Luna2D doc pipeline")
    print("=" * 60)

    failed = []

    for script_name, label in SCRIPTS:
        ok = run_script(script_name, [], label)
        if not ok:
            failed.append(script_name)

    for script_name, extra_args, label in SCRIPTS_WITH_ARGS:
        ok = run_script(script_name, extra_args, label)
        if not ok:
            failed.append(f"{script_name} {' '.join(extra_args)}")

    print("=" * 60)
    if failed:
        print(f"FAILED: {', '.join(failed)}")
        sys.exit(1)
    else:
        print("All docs generated successfully.")


if __name__ == "__main__":
    main()
