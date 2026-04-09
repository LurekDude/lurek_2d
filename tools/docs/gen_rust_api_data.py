#!/usr/bin/env python3
"""
gen_rust_api_data.py — Generate Lurek2D master API data file.

Scans ALL src/ Rust files (public items + Lua API bindings) and tests/*.rs,
producing a single machine-readable JSON used as the source for all other
doc generators. Not intended for direct human reading.

Usage:
    python tools/gen_rust_api_data.py                  # -> docs/logs/rust_api_data.json
    python tools/gen_rust_api_data.py --output FILE    # custom output path
    python tools/gen_rust_api_data.py --verbose        # print per-module stats

Exit codes:
    0 — success
    1 — fatal error
"""

import argparse
import importlib.util
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
TOOLS_DIR = WORKSPACE_ROOT / "tools"
SRC_DIR = WORKSPACE_ROOT / "src"
TESTS_DIR = WORKSPACE_ROOT / "tests"
OUTPUT_FILE = WORKSPACE_ROOT / "docs" / "logs" / "rust_api_data.json"


# ── Load gen_lua_api as a module (avoids duplicating parser logic) ─────────────

def _load_gen_lua_api():
    spec = importlib.util.spec_from_file_location(
        "gen_lua_api", TOOLS_DIR / "docs" / "gen_lua_api.py"
    )
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# ── Lua API extraction ─────────────────────────────────────────────────────────

def extract_lua_api(gen_lua_api, verbose: bool = False) -> dict:
    """Extract all Lua API data using gen_lua_api module."""
    src_dir = SRC_DIR / "lua_api"
    all_fns = gen_lua_api.collect_all_functions(src_dir)

    total = sum(len(f) for f in all_fns.values())
    documented = sum(1 for funcs in all_fns.values() for f in funcs if f.description)

    modules = {}
    for mod_name, funcs in sorted(all_fns.items()):
        api_file = src_dir / f"{mod_name}_api.rs"
        module_doc = (
            gen_lua_api._collect_module_doc(api_file) if api_file.exists() else ""
        )
        class_descs = (
            gen_lua_api.collect_class_descriptions(api_file) if api_file.exists() else {}
        )

        module_fns = []
        classes: dict = {}

        for f in funcs:
            entry = {
                "name": f.name,
                "lua_name": f.lua_name,
                "kind": f.kind,
                "owner_type": f.owner_type,
                "description": f.description,
                "full_doc": f.full_doc,
                "params_doc": f.params,
                "returns_doc": f.returns,
                "inferred_sig": f.inferred_sig,
                "typed_params": f.typed_params,
                "inferred_return": f.inferred_return,
                "line": f.line,
                "file": f.file,
            }

            if f.kind == "function":
                module_fns.append(entry)
            elif f.kind == "method":
                owner = f.owner_type or "Unknown"
                if owner not in classes:
                    classes[owner] = {
                        "description": class_descs.get(owner, ""),
                        "methods": [],
                    }
                classes[owner]["methods"].append(entry)

        # Fill in any class descriptions that weren't set during method iteration
        for owner, cls_data in classes.items():
            if not cls_data["description"] and owner in class_descs:
                cls_data["description"] = class_descs[owner]

        modules[mod_name] = {
            "description": module_doc,
            "source_file": f"src/lua_api/{mod_name}_api.rs",
            "functions": module_fns,
            "classes": classes,
        }

        if verbose:
            n_fns = len(module_fns)
            n_methods = sum(len(c["methods"]) for c in classes.values())
            print(f"  {mod_name:20s} functions={n_fns:3d}  classes={len(classes):2d}  methods={n_methods:3d}")

    return {
        "summary": {
            "total_functions": total,
            "documented": documented,
            "coverage_pct": round(documented / total * 100, 1) if total else 0,
            "modules": len(all_fns),
        },
        "modules": modules,
    }


# ── Rust public item extraction ────────────────────────────────────────────────

_TOP_PUB_RE = re.compile(
    r"^pub(?:\([^)]*\))?\s+"
    r"(?:unsafe\s+|async\s+|const\s+|extern\s+\"[^\"]*\"\s+)?"
    r"(struct|enum|fn|trait|type|const|static|mod)"
    r"\s+([A-Za-z_][A-Za-z0-9_]*)"
)


def _collect_doc_above(lines: list, idx: int) -> str:
    """Collect /// doc comments immediately above line idx."""
    parts = []
    j = idx - 1
    while j >= 0:
        s = lines[j].strip()
        if s.startswith("///"):
            text = s[3:]
            parts.insert(0, text[1:] if text.startswith(" ") else text)
        elif s.startswith("#[") or s == "":
            pass
        else:
            break
        j -= 1
    return " ".join(parts).strip()


def _collect_module_doc_rs(path: Path) -> str:
    """Collect //! module-level doc from a Rust file."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except Exception:
        return ""
    parts = []
    for raw in lines:
        s = raw.strip()
        if s.startswith("//!"):
            text = s[3:]
            parts.append(text[1:] if text.startswith(" ") else text)
        elif parts:
            break
    return " ".join(parts).strip()


def extract_rust_api(verbose: bool = False) -> dict:
    """Scan src/**/*.rs for public items and their /// doc comments."""
    modules: dict = {}

    for rs_file in sorted(SRC_DIR.rglob("*.rs")):
        rel = rs_file.relative_to(WORKSPACE_ROOT)
        parts = list(rel.with_suffix("").parts)
        if parts and parts[0] == "src":
            parts = parts[1:]
        if parts and parts[0] == "lua_api":
            continue
        if parts and parts[-1] in ("mod", "lib", "main"):
            parts = parts[:-1]
        mod_path = "::".join(parts) if parts else "root"

        try:
            lines = rs_file.read_text(encoding="utf-8").splitlines()
        except Exception:
            continue

        module_doc = _collect_module_doc_rs(rs_file)
        items = []

        for i, line in enumerate(lines):
            m = _TOP_PUB_RE.match(line)
            if m:
                kind = m.group(1)
                name = m.group(2)
                if name in ("main",):
                    continue
                doc = _collect_doc_above(lines, i)
                items.append(
                    {
                        "name": name,
                        "kind": kind,
                        "description": doc,
                        "file": str(rel).replace("\\", "/"),
                        "line": i + 1,
                    }
                )

        if items or module_doc:
            modules[mod_path] = {
                "module_doc": module_doc,
                "source_file": str(rel).replace("\\", "/"),
                "items": items,
            }

    total = sum(len(m["items"]) for m in modules.values())
    documented = sum(
        1 for m in modules.values() for item in m["items"] if item["description"]
    )

    if verbose:
        print(f"  {total} public items across {len(modules)} modules ({documented} documented)")

    return {
        "summary": {
            "total_items": total,
            "documented": documented,
            "modules": len(modules),
        },
        "modules": modules,
    }


# ── Test function extraction ───────────────────────────────────────────────────

_FN_RE = re.compile(r"^\s*(?:pub\s+)?(?:async\s+)?fn\s+(\w+)\s*\(")
_TEST_ATTR_RE = re.compile(r"^\s*#\[(?:tokio::)?test(?:\s*\([^)]*\))?\]")


def extract_tests(verbose: bool = False) -> list:
    """Scan tests/*.rs for #[test] functions and their /// doc comments."""
    tests = []

    for rs_file in sorted(TESTS_DIR.glob("*.rs")):
        module = rs_file.stem
        for suffix in ("_tests", "_test"):
            if module.endswith(suffix):
                module = module[: -len(suffix)]
                break

        try:
            lines = rs_file.read_text(encoding="utf-8").splitlines()
        except Exception:
            continue

        i = 0
        while i < len(lines):
            if _TEST_ATTR_RE.match(lines[i]):
                # Collect doc comments above this #[test] line
                doc = _collect_doc_above(lines, i)
                # Find the fn declaration (skip any additional attributes)
                j = i + 1
                fn_name = None
                while j < len(lines) and j < i + 5:
                    fn_m = _FN_RE.match(lines[j])
                    if fn_m:
                        fn_name = fn_m.group(1)
                        break
                    if not lines[j].strip().startswith("#[") and lines[j].strip():
                        break
                    j += 1

                if fn_name:
                    tests.append(
                        {
                            "file": f"tests/{rs_file.name}",
                            "module": module,
                            "name": fn_name,
                            "description": doc,
                            "line": j + 1,
                        }
                    )
                i = j + 1
            else:
                i += 1

    if verbose:
        by_module: dict = {}
        for t in tests:
            by_module.setdefault(t["module"], 0)
            by_module[t["module"]] += 1
        for mod, count in sorted(by_module.items()):
            print(f"  {mod:25s} {count:4d} tests")

    return tests


# ── Lua integration tests (tests/lua/) ─────────────────────────────────────────

def extract_lua_tests() -> list:
    """Scan tests/lua/**/*.lua for test scripts."""
    lua_tests = []
    lua_dir = TESTS_DIR / "lua"
    if not lua_dir.exists():
        return lua_tests

    for lua_file in sorted(lua_dir.rglob("*.lua")):
        rel = str(lua_file.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
        try:
            content = lua_file.read_text(encoding="utf-8")
        except Exception:
            continue

        # Extract first block comment or -- comment at top
        desc = ""
        lines = content.splitlines()
        for ln in lines[:10]:
            s = ln.strip()
            if s.startswith("--") and not s.startswith("---"):
                desc = s.lstrip("- ").strip()
                break

        lua_tests.append(
            {
                "file": rel,
                "module": lua_file.stem,
                "name": lua_file.stem,
                "description": desc,
                "kind": "lua",
            }
        )

    return lua_tests


# ── Main ───────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate Lurek2D master API data JSON.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--output", default=str(OUTPUT_FILE), help="Output JSON path (default: docs/logs/rust_api_data.json)"
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Print per-module stats")
    args = parser.parse_args()

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    print("--- Scanning Rust API ---")
    rust_api = extract_rust_api(verbose=args.verbose)
    s = rust_api["summary"]
    print(f"   {s['total_items']} public items | {s['modules']} modules | {s['documented']} documented")

    print("--- Scanning Rust tests ---")
    rs_tests = extract_tests(verbose=args.verbose)
    print(f"   {len(rs_tests)} Rust test functions in tests/*.rs")

    print("--- Scanning Lua tests ---")
    lua_tests = extract_lua_tests()
    print(f"   {len(lua_tests)} Lua test scripts in tests/lua/")

    # Read version from Cargo.toml
    version = "unknown"
    try:
        cargo_toml = (WORKSPACE_ROOT / "Cargo.toml").read_text(encoding="utf-8")
        vm = re.search(r'^version\s*=\s*"([^"]+)"', cargo_toml, re.MULTILINE)
        if vm:
            version = vm.group(1)
    except Exception:
        pass

    data = {
        "meta": {
            "generated": datetime.now(timezone.utc).isoformat(),
            "generator": "tools/gen_rust_api_data.py",
            "version": version,
            "stats": {
                "rust_items": rust_api["summary"]["total_items"],
                "rust_modules": rust_api["summary"]["modules"],
                "rust_tests": len(rs_tests),
                "lua_tests": len(lua_tests),
            },
        },
        "rust_api": rust_api,
        "tests": {
            "rust": rs_tests,
            "lua": lua_tests,
        },
    }

    output_path.write_text(
        json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    size_kb = output_path.stat().st_size // 1024
    print(f"\n[OK] Generated {output_path} ({size_kb} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
