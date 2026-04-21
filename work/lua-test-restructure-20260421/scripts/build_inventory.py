"""Build a JSON inventory of every Lua test file under ``tests/lua/``.

Phase 0 of the lua-test-restructure session. Pure stdlib, Windows-friendly.
Re-runnable: later phases can diff case counts to prove no loss.

Usage:
    python work/lua-test-restructure-20260421/scripts/build_inventory.py

Output: work/lua-test-restructure-20260421/data/inventory.json
"""

from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
TESTS_LUA = REPO_ROOT / "tests" / "lua"
OUT_PATH = REPO_ROOT / "work" / "lua-test-restructure-20260421" / "data" / "inventory.json"

LAYERS = ("config", "evidence", "golden", "integration", "library", "security", "stress", "unit")

# describe("name", fn)  |  describe('name', fn)
RE_DESCRIBE = re.compile(r"""\bdescribe\s*\(\s*(['"])(.+?)\1""")
# it("name", fn)  |  test("name", fn)
RE_IT = re.compile(r"""\b(it|test)\s*\(\s*(['"])(.+?)\2""")

# Output path heuristics (evidence files): string literals with image/audio/text extensions
# and filesystem write calls.
RE_OUTPUT_STRING = re.compile(
    r"""(['"])([^'"\n]*?\.(?:png|jpg|jpeg|bmp|tga|wav|ogg|mp3|txt|json|csv|toml|bin|dat|svg))\1""",
    re.IGNORECASE,
)
RE_WRITE_CALLS = re.compile(
    r"""\b(?:savePNG|saveImage|save|writeFile|write_file|fs\.write|filesystem\.write|lurek\.filesystem\.write|io\.open)\s*\(""",
)
# Sample read heuristics (golden files): references to samples/ paths and read calls.
RE_SAMPLE_STRING = re.compile(r"""(['"])([^'"\n]*?samples/[^'"\n]+)\1""")
RE_READ_CALLS = re.compile(
    r"""\b(?:readFile|read_file|fs\.read|filesystem\.read|lurek\.filesystem\.read|loadImage|load_image)\s*\(""",
)

# init.lua helper usage (symbols defined by tests/lua/init.lua).
INIT_HELPERS = (
    "evidence_output_dir",
    "golden_sample_dir",
    "expect_near",
    "expect_equal",
    "expect_true",
    "expect_false",
    "describe",
    "it",
    "test",
    "before",
    "after",
    "test_summary",
    "ensure_dir",
    "read_file",
    "write_file",
    "load_sample",
)


def classify_layer(path: Path) -> str:
    rel = path.relative_to(TESTS_LUA).as_posix()
    head = rel.split("/", 1)[0]
    return head if head in LAYERS else "other"


def guess_module(path: Path) -> str:
    name = path.stem
    # Strip standard suffixes / prefixes.
    for suf in ("_evidence", "_golden", "_stress", "_security", "_unit", "_integration", "_library"):
        if name.endswith(suf):
            name = name[: -len(suf)]
            break
    if name.startswith("test_"):
        name = name[len("test_"):]
    return name or path.stem


def extract_cases(text: str) -> list[dict]:
    cases: list[dict] = []
    # Track current describe block by nesting heuristic: the most recent describe before an it.
    describes: list[tuple[int, str]] = []  # (line, name)
    for m in RE_DESCRIBE.finditer(text):
        line = text.count("\n", 0, m.start()) + 1
        describes.append((line, m.group(2)))

    def find_enclosing_describe(line: int) -> str:
        best = ""
        for dline, dname in describes:
            if dline <= line:
                best = dname
            else:
                break
        return best

    for m in RE_IT.finditer(text):
        line = text.count("\n", 0, m.start()) + 1
        cases.append(
            {
                "describe": find_enclosing_describe(line),
                "it": m.group(3),
                "line": line,
            }
        )
    return cases


def extract_paths(text: str, pattern: re.Pattern[str]) -> list[str]:
    seen: list[str] = []
    for m in pattern.finditer(text):
        val = m.group(2)
        if val not in seen:
            seen.append(val)
    return seen


def extract_helpers(text: str) -> list[str]:
    found = []
    for h in INIT_HELPERS:
        if re.search(r"\b" + re.escape(h) + r"\b", text):
            found.append(h)
    return found


def inventory_file(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")
    layer = classify_layer(path)
    module = guess_module(path)

    cases = extract_cases(text)
    output_paths: list[str] = []
    sample_paths: list[str] = []
    if layer == "evidence":
        output_paths = extract_paths(text, RE_OUTPUT_STRING)
    if layer == "golden":
        sample_paths = extract_paths(text, RE_SAMPLE_STRING)

    rel = path.relative_to(REPO_ROOT).as_posix()
    return {
        "path": rel,
        "layer": layer,
        "current_module_guess": module,
        "test_cases": cases,
        "test_case_count": len(cases),
        "output_paths_written": output_paths,
        "has_write_calls": bool(RE_WRITE_CALLS.search(text)),
        "sample_paths_read": sample_paths,
        "has_read_calls": bool(RE_READ_CALLS.search(text)),
        "line_count": text.count("\n") + (0 if text.endswith("\n") else 1),
        "lua_includes": extract_helpers(text),
    }


def main() -> int:
    if not TESTS_LUA.is_dir():
        print(f"ERROR: {TESTS_LUA} not found", file=sys.stderr)
        return 2

    files: list[dict] = []
    for layer in LAYERS:
        base = TESTS_LUA / layer
        if not base.is_dir():
            continue
        for p in sorted(base.rglob("*.lua")):
            files.append(inventory_file(p))

    payload = {
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "repo_root": str(REPO_ROOT).replace("\\", "/"),
        "tests_lua_root": "tests/lua",
        "layers": list(LAYERS),
        "file_count": len(files),
        "total_test_cases": sum(f["test_case_count"] for f in files),
        "files": files,
    }

    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT_PATH.relative_to(REPO_ROOT).as_posix()}")
    print(f"  files: {payload['file_count']}")
    print(f"  cases: {payload['total_test_cases']}")

    # Per-layer summary to stdout.
    per_layer: dict[str, int] = {l: 0 for l in LAYERS}
    per_layer_cases: dict[str, int] = {l: 0 for l in LAYERS}
    for f in files:
        per_layer[f["layer"]] = per_layer.get(f["layer"], 0) + 1
        per_layer_cases[f["layer"]] = per_layer_cases.get(f["layer"], 0) + f["test_case_count"]
    for l in LAYERS:
        print(f"  {l}: {per_layer[l]} files / {per_layer_cases[l]} cases")
    return 0


if __name__ == "__main__":
    sys.exit(main())
