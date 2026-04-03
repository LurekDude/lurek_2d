#!/usr/bin/env python3
"""Convenience runner: regenerate the full Luna2D documentation pipeline in one command.

Steps:
    1. gen_api_data.py          -> docs/API/api_data.json         (master machine-readable JSON)
    2. gen_docs_lua.py          -> docs/API/lua-api.md            (compact Lua API reference)
    3. gen_docs_rust.py         -> docs/API/rust-api.md           (compact Rust API reference)
    4. gen_docs_tests.py        -> docs/API/test-docs.md          (test catalog)
    5. gen_wiki_api.py          -> wiki/API-Reference.md      (game-developer cheatsheet)
    6. doc_coverage.py          -> docs/API/doc_coverage.json     (docstring coverage analytics)
    7. test_coverage.py         -> docs/API/test_coverage.json    (test coverage analytics)
    8. gen_test_docs.py         -> docs/API/test_docs.md          (human-readable test docs)
    9. gen_lua_api.py           -> docs/API/lua_api_reference_generated.md  (legacy — kept for VS Code ext)

Usage:
    python tools/gen_all_docs.py          # run all steps
    python tools/gen_all_docs.py --skip-legacy   # skip step 9
"""

import subprocess
import sys
import time
from pathlib import Path

SCRIPTS = [
    ("gen_api_data.py",    "Master JSON (docs/API/api_data.json)"),
    ("gen_docs_lua.py",    "Lua API reference (docs/API/lua-api.md)"),
    ("gen_docs_rust.py",   "Rust API reference (docs/API/rust-api.md)"),
    ("gen_docs_tests.py",  "Test catalog (docs/API/test-docs.md)"),
    ("gen_wiki_api.py",    "Wiki cheatsheet (wiki/API-Reference.md)"),
    ("doc_coverage.py",    "Doc coverage analytics (docs/API/doc_coverage.json)"),
    ("test_coverage.py",   "Test coverage analytics (docs/API/test_coverage.json)"),
    ("gen_test_docs.py",   "Test documentation (docs/API/test_docs.md)"),
]

LEGACY_SCRIPT = ("gen_lua_api.py", "Legacy Lua ref (docs/API/lua_api_reference_generated.md)")

TOOLS_DIR = Path(__file__).parent


def run_script(script_name: str, label: str) -> bool:
    script = TOOLS_DIR / script_name
    print(f"  [{label}]")
    t0 = time.monotonic()
    result = subprocess.run(
        [sys.executable, str(script)],
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
    skip_legacy = "--skip-legacy" in sys.argv
    print("Luna2D doc pipeline")
    print("=" * 60)

    failed = []
    scripts = SCRIPTS + ([] if skip_legacy else [LEGACY_SCRIPT])

    for script_name, label in scripts:
        ok = run_script(script_name, label)
        if not ok:
            failed.append(script_name)

    print("=" * 60)
    if failed:
        print(f"FAILED: {', '.join(failed)}")
        sys.exit(1)
    else:
        print("All docs generated successfully.")


if __name__ == "__main__":
    main()
