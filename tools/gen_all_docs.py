#!/usr/bin/env python3
"""Convenience runner: regenerate the full Lurek2D documentation pipeline in one command.

Steps:
    1.  gen_rust_api_data.py         -> logs/data/rust_api_data.json           (Rust master JSON)
    2.  gen_lua_api_data.py          -> logs/data/lua_api_data.json            (Lua master JSON)
    3.  gen_luadoc.py                -> docs/api/lurek.lua                (LuaCATS stubs)
    4.  gen_docs_lua.py              -> docs/api/lurek.md                 (Lua API reference)
    5.  gen_docs_rust.py             -> docs/api/rust.md                  (Rust API reference)
    6.  gen_wiki_api.py              -> wiki/API-Reference.md        (game-dev cheatsheet)
    7.  doc_coverage.py              -> logs/data/doc_coverage.json            (docstring coverage JSON)
    8.  test_coverage.py             -> logs/data/test_coverage.json           (test coverage JSON)
    9.  gen_test_docs.py --mode rust -> logs/reports/test_docs_rust.md
   10.  gen_test_docs.py --mode lua  -> logs/reports/test_docs_lua.md
   11.  gen_coverage_gaps.py         -> logs/reports/coverage_gaps.md     (API gap report)
   12.  example_coverage.py          -> logs/reports/example_coverage.md  (example coverage)
   13.  test_coverage.py             -> logs/reports/test_coverage.md     (test coverage report)
   14.  lua_api_test_coverage.py     -> logs/reports/lua_test_coverage.md (Lua test coverage)

Usage:
    python tools/gen_all_docs.py          # run all steps
"""

import os
import subprocess
import sys
import time
from pathlib import Path

# Ensure stdout can handle UTF-8 arrow characters on Windows consoles.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPTS = [
    ("docs/gen_rust_api_data.py", "Rust JSON (logs/data/rust_api_data.json)"),
    ("docs/gen_lua_api_data.py",  "Lua JSON (logs/data/lua_api_data.json)"),
    ("docs/gen_luadoc.py",        "LuaCATS Stubs (docs/api/lurek.lua)"),
    ("docs/gen_docs_lua.py",      "Lua API reference (docs/api/lurek.md)"),
    ("docs/gen_docs_rust.py",     "Rust API reference (docs/api/rust.md)"),
    ("docs/gen_wiki_api.py",      "Wiki cheatsheet (wiki/API-Reference.md)"),
    ("audit/doc_coverage.py",      "Doc coverage analytics (logs/data/doc_coverage.json)"),
    ("audit/test_coverage.py",     "Test coverage analytics (logs/data/test_coverage.json)"),
]

# Scripts that need extra arguments (script_name, args_list, label)
SCRIPTS_WITH_ARGS = [
    ("docs/gen_test_docs.py", ["--mode", "rust", "--output", "logs/reports/test_docs_rust.md"],
     "Rust test docs (logs/reports/test_docs_rust.md)"),
    ("docs/gen_test_docs.py", ["--mode", "lua",  "--output", "logs/reports/test_docs_lua.md"],
     "Lua test docs (logs/reports/test_docs_lua.md)"),
    ("audit/example_coverage.py", ["--markdown", "logs/reports/example_coverage.md"],
     "Example coverage (logs/reports/example_coverage.md)"),
    ("audit/gen_coverage_gaps.py", [],
     "Coverage gaps (logs/reports/coverage_gaps.md)"),
    ("audit/test_coverage.py", ["--output", "logs/reports/test_coverage.md"],
     "Test coverage report (logs/reports/test_coverage.md)"),
    ("audit/lua_api_test_coverage.py", ["--report", "--output", "logs/reports/lua_test_coverage.md"],
     "Lua API test coverage (logs/reports/lua_test_coverage.md)"),
]


TOOLS_DIR = Path(__file__).parent


def run_script(script_name: str, extra_args: list, label: str) -> bool:
    script = TOOLS_DIR / script_name
    print(f"  [{label}]")
    t0 = time.monotonic()
    env = {**os.environ, "PYTHONIOENCODING": "utf-8"}
    result = subprocess.run(
        [sys.executable, str(script)] + extra_args,
        capture_output=True,
        text=True,
        encoding="utf-8",
        env=env,
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
    print("Lurek2D doc pipeline")
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


