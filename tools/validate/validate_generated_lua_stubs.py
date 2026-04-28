#!/usr/bin/env python3
"""Validate committed generated Lua API artifacts against fresh generator output.

Checks:
  - logs/data/lua_api_data.json matches a fresh gen_lua_api_data.py run
    (ignoring volatile top-level metadata like timestamps).
  - docs/api/lurek.lua matches a fresh gen_luadoc.py run.
  - docs/api/library.lua matches a fresh gen_lib_docs.py LuaCATS render.

Advisory-only JSON output also includes current source/json/stub drift counts,
but those do not affect the validator exit code.

Usage:
    python tools/validate/validate_generated_lua_stubs.py
    python tools/validate/validate_generated_lua_stubs.py --format json

Exit code:
    0 if all checks pass, 1 otherwise.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC_LUA_API_DIR = ROOT / "src" / "lua_api"
LUA_API_JSON_PATH = ROOT / "logs" / "data" / "lua_api_data.json"
LUREK_STUB_PATH = ROOT / "docs" / "api" / "lurek.lua"
LIBRARY_STUB_PATH = ROOT / "docs" / "api" / "library.lua"
EXTENSION_API_PATH = ROOT / "extensions" / "vscode" / "data" / "lurek-api.json"

METHOD_CALL_START = re.compile(r"\bmethods\.add_(?:method|method_mut|function|function_mut)\s*\(")
SET_CALL_START = re.compile(r"\b\w+\s*\.\s*set\s*\(")
NAME_IN_WINDOW = re.compile(r'\(\s*"([^"]+)"')

LUREK_TOP_FUNCTION_RE = re.compile(
    r"^(lurek\.[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+)\s*=\s*function\(",
    re.MULTILINE,
)
LIBRARY_TOP_FUNCTION_RE = re.compile(
    r"^function\s+(library\.[A-Za-z_][A-Za-z0-9_.]*)\s*\(",
    re.MULTILINE,
)
METHOD_RE = re.compile(
    r"^function\s+([A-Za-z_][A-Za-z0-9_]*)[:.]([A-Za-z_][A-Za-z0-9_]*)\s*\(",
    re.MULTILINE,
)
METHOD_ASSIGN_RE = re.compile(
    r"^([A-Za-z_][A-Za-z0-9_]*)[:.]([A-Za-z_][A-Za-z0-9_]*)\s*=\s*function\(",
    re.MULTILINE,
)
ALIAS_RE = re.compile(r"^---@alias\s+(\w+)\s+(\w+)\s*$", re.MULTILINE)
CLASS_RE = re.compile(r"^---@class\s+([A-Za-z_][A-Za-z0-9_]*)\s*$", re.MULTILINE)
GENERIC_ALIAS_RE = re.compile(r"^---@alias\s+(\w+)\s+(.+)$", re.MULTILINE)


def _load_module(module_name: str, module_path: Path):
    spec = importlib.util.spec_from_file_location(module_name, module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load module spec for {module_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _run_python(command: list[str]) -> None:
    completed = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if completed.returncode != 0:
        stderr = completed.stderr.strip()
        stdout = completed.stdout.strip()
        details = stderr or stdout or "generator returned no output"
        raise RuntimeError(details)


def _collect_lua_api_source_entries() -> list[tuple[str, int, str]]:
    source_entries: list[tuple[str, int, str]] = []

    for path in sorted(SRC_LUA_API_DIR.glob("*_api.rs")):
        rel = path.relative_to(ROOT).as_posix()
        lines = path.read_text(encoding="utf-8").splitlines()
        seen: set[tuple[str, int, str]] = set()

        for idx, line in enumerate(lines):
            name = None
            window = "\n".join(lines[idx : min(len(lines), idx + 4)])

            if METHOD_CALL_START.search(line):
                match = NAME_IN_WINDOW.search(window)
                if match:
                    name = match.group(1)
            elif SET_CALL_START.search(line):
                match = NAME_IN_WINDOW.search(window)
                if match and "create_function" in window:
                    name = match.group(1)

            if not name or name.startswith("__"):
                continue

            key = (rel, idx + 1, name)
            if key in seen:
                continue

            seen.add(key)
            source_entries.append(key)

    return source_entries


def _extract_json_entries(
    fresh_data: dict,
) -> tuple[list[tuple[str, int, str]], set[str], list[tuple[str, str]]]:
    modules = fresh_data["lua_api"]["modules"]
    json_entries: list[tuple[str, int, str]] = []
    json_top_functions: set[str] = set()
    json_methods: list[tuple[str, str]] = []

    for module_data in modules.values():
        for fn in module_data.get("functions", []):
            json_entries.append((fn["file"].replace("\\", "/"), fn["line"], fn["name"]))
            json_top_functions.add(fn["lua_name"])

        for class_name, class_data in module_data.get("classes", {}).items():
            for method in class_data.get("methods", []):
                json_entries.append(
                    (method["file"].replace("\\", "/"), method["line"], method["name"])
                )
                json_methods.append((class_name, method["name"]))

    return json_entries, json_top_functions, json_methods


def _extract_expected_classes_and_enums(fresh_data: dict) -> tuple[set[str], dict[str, list[str]]]:
    modules = fresh_data["lua_api"]["modules"]
    class_names: set[str] = set()

    for module_data in modules.values():
        class_names.update(module_data.get("classes", {}).keys())

    enums = {
        name: list(values)
        for name, values in (fresh_data["lua_api"].get("enums") or {}).items()
    }
    return class_names, enums


def _extract_lurek_stub_classes(stub_text: str) -> set[str]:
    return set(CLASS_RE.findall(stub_text))


def _extract_lurek_stub_enums(stub_text: str, expected_names: set[str]) -> dict[str, list[str]]:
    enums: dict[str, list[str]] = {}
    for name, rhs in GENERIC_ALIAS_RE.findall(stub_text):
        if name not in expected_names:
            continue
        enums[name] = re.findall(r'"([^"]+)"', rhs)
    return enums


def _extract_extension_classes_and_enums(extension_data: dict) -> tuple[set[str], dict[str, list[str]]]:
    classes = {
        entry.get("name")
        for entry in extension_data.get("classes", [])
        if isinstance(entry, dict) and entry.get("name")
    }
    enums = {
        name: list(values)
        for name, values in (extension_data.get("enums") or {}).items()
    }
    return classes, enums


def _extract_library_expectations(gen_lib_docs, library_modules: dict) -> tuple[set[str], set[tuple[str, str]]]:
    top_functions: set[str] = set()
    methods: set[tuple[str, str]] = set()

    for module_name in sorted(library_modules.keys()):
        _, info = library_modules[module_name]
        display = info["name"] or f"library.{module_name}"

        for fn in info["functions"]:
            raw_name = fn["name"]
            if ":" in raw_name:
                class_name, method_name = raw_name.split(":", 1)
                methods.add((class_name, method_name))
            else:
                short_name = gen_lib_docs._strip_module_prefix(raw_name)
                top_functions.add(f"{display}.{short_name}")

    return top_functions, methods


def _generate_fresh_artifacts() -> tuple[dict, str, str, dict, dict]:
    gen_luadoc = _load_module("gen_luadoc", ROOT / "tools" / "docs" / "gen_luadoc.py")
    gen_lib_docs = _load_module("gen_lib_docs", ROOT / "tools" / "docs" / "gen_lib_docs.py")
    gen_extension_api = _load_module("gen_extension_api", ROOT / "tools" / "docs" / "gen_extension_api.py")

    with tempfile.TemporaryDirectory() as tmp_dir_name:
        tmp_dir = Path(tmp_dir_name)
        tmp_json = tmp_dir / "lua_api_data.json"
        tmp_stub = tmp_dir / "lurek.lua"

        _run_python(
            [
                sys.executable,
                str(ROOT / "tools" / "docs" / "gen_lua_api_data.py"),
                "--output",
                str(tmp_json),
            ]
        )

        gen_luadoc.INPUT_FILE = str(tmp_json)
        gen_luadoc.OUTPUT_FILE = str(tmp_stub)
        gen_luadoc.main()

        fresh_data = json.loads(tmp_json.read_text(encoding="utf-8"))
        fresh_lurek_stub = tmp_stub.read_text(encoding="utf-8")
        fresh_extension_api = gen_extension_api.convert(fresh_data)

    library_modules = gen_lib_docs.scan_library()
    fresh_library_stub = gen_lib_docs.render_luacats(library_modules)
    return fresh_data, fresh_lurek_stub, fresh_library_stub, fresh_extension_api, library_modules


def validate_generated_lua_stubs() -> dict:
    fresh_data, fresh_lurek_stub, fresh_library_stub, fresh_extension_api, library_modules = _generate_fresh_artifacts()

    current_data = json.loads(LUA_API_JSON_PATH.read_text(encoding="utf-8"))
    current_lurek_stub = LUREK_STUB_PATH.read_text(encoding="utf-8")
    current_library_stub = LIBRARY_STUB_PATH.read_text(encoding="utf-8")
    current_extension_api = json.loads(EXTENSION_API_PATH.read_text(encoding="utf-8"))

    source_entries = _collect_lua_api_source_entries()
    json_entries, json_top_functions, json_methods = _extract_json_entries(fresh_data)
    expected_classes, expected_enums = _extract_expected_classes_and_enums(fresh_data)

    source_set = set(source_entries)
    json_set = set(json_entries)
    source_vs_json_missing = sorted(source_set - json_set)
    source_vs_json_extra = sorted(json_set - source_set)

    alias_map = dict(ALIAS_RE.findall(fresh_lurek_stub))
    lurek_top_functions = set(LUREK_TOP_FUNCTION_RE.findall(fresh_lurek_stub))
    lurek_methods = set(METHOD_RE.findall(fresh_lurek_stub)) | set(METHOD_ASSIGN_RE.findall(fresh_lurek_stub))
    lurek_classes = _extract_lurek_stub_classes(fresh_lurek_stub)
    lurek_enums = _extract_lurek_stub_enums(fresh_lurek_stub, set(expected_enums.keys()))
    expected_lurek_methods = {
        (alias_map.get(class_name, class_name), method_name)
        for class_name, method_name in json_methods
    }
    lurek_missing_top_stubs = sorted(json_top_functions - lurek_top_functions)
    lurek_missing_method_stubs = sorted(expected_lurek_methods - lurek_methods)
    lurek_missing_class_stubs = sorted(expected_classes - lurek_classes)
    lurek_missing_enum_stubs = sorted(set(expected_enums.keys()) - set(lurek_enums.keys()))
    lurek_enum_value_mismatches = sorted(
        name for name, values in expected_enums.items() if lurek_enums.get(name) != values
    )

    extension_classes, extension_enums = _extract_extension_classes_and_enums(fresh_extension_api)
    extension_missing_classes = sorted(expected_classes - extension_classes)
    extension_missing_enums = sorted(set(expected_enums.keys()) - set(extension_enums.keys()))
    extension_enum_value_mismatches = sorted(
        name for name, values in expected_enums.items() if extension_enums.get(name) != values
    )

    gen_lib_docs = _load_module("gen_lib_docs_expectations", ROOT / "tools" / "docs" / "gen_lib_docs.py")
    expected_library_top_functions, expected_library_methods = _extract_library_expectations(
        gen_lib_docs,
        library_modules,
    )
    library_top_functions = set(LIBRARY_TOP_FUNCTION_RE.findall(fresh_library_stub))
    library_methods = set(METHOD_RE.findall(fresh_library_stub))
    library_missing_top_stubs = sorted(expected_library_top_functions - library_top_functions)
    library_missing_method_stubs = sorted(expected_library_methods - library_methods)

    result = {
        "ok": False,
        "artifacts": {
            "json_payload_identical_to_committed": current_data.get("lua_api") == fresh_data.get("lua_api"),
            "lurek_stub_identical_to_committed": current_lurek_stub == fresh_lurek_stub,
            "library_stub_identical_to_committed": current_library_stub == fresh_library_stub,
            "extension_api_identical_to_committed": current_extension_api == fresh_extension_api,
        },
        "advisory": {
            "source_proof": {
                "source_registration_count": len(source_entries),
                "json_entry_count": len(json_entries),
                "source_vs_json_missing_count": len(source_vs_json_missing),
                "source_vs_json_missing_sample": source_vs_json_missing[:20],
                "source_vs_json_extra_count": len(source_vs_json_extra),
                "source_vs_json_extra_sample": source_vs_json_extra[:20],
            },
            "lurek_stub_proof": {
                "json_top_function_count": len(json_top_functions),
                "stub_top_function_count": len(lurek_top_functions),
                "missing_top_stub_count": len(lurek_missing_top_stubs),
                "missing_top_stub_sample": lurek_missing_top_stubs[:20],
                "json_method_count": len(expected_lurek_methods),
                "stub_method_count": len(lurek_methods),
                "missing_method_stub_count": len(lurek_missing_method_stubs),
                "missing_method_stub_sample": lurek_missing_method_stubs[:20],
                "json_class_count": len(expected_classes),
                "stub_class_count": len(lurek_classes),
                "missing_class_stub_count": len(lurek_missing_class_stubs),
                "missing_class_stub_sample": lurek_missing_class_stubs[:20],
                "json_enum_count": len(expected_enums),
                "stub_enum_count": len(lurek_enums),
                "missing_enum_stub_count": len(lurek_missing_enum_stubs),
                "missing_enum_stub_sample": lurek_missing_enum_stubs[:20],
                "enum_value_mismatch_count": len(lurek_enum_value_mismatches),
                "enum_value_mismatch_sample": lurek_enum_value_mismatches[:20],
            },
            "extension_proof": {
                "json_class_count": len(expected_classes),
                "extension_class_count": len(extension_classes),
                "missing_class_count": len(extension_missing_classes),
                "missing_class_sample": extension_missing_classes[:20],
                "json_enum_count": len(expected_enums),
                "extension_enum_count": len(extension_enums),
                "missing_enum_count": len(extension_missing_enums),
                "missing_enum_sample": extension_missing_enums[:20],
                "enum_value_mismatch_count": len(extension_enum_value_mismatches),
                "enum_value_mismatch_sample": extension_enum_value_mismatches[:20],
            },
            "library_stub_proof": {
                "expected_top_function_count": len(expected_library_top_functions),
                "stub_top_function_count": len(library_top_functions),
                "missing_top_stub_count": len(library_missing_top_stubs),
                "missing_top_stub_sample": library_missing_top_stubs[:20],
                "expected_method_count": len(expected_library_methods),
                "stub_method_count": len(library_methods),
                "missing_method_stub_count": len(library_missing_method_stubs),
                "missing_method_stub_sample": library_missing_method_stubs[:20],
            },
        },
    }

    source_proof = result["advisory"]["source_proof"]
    lurek_stub_proof = result["advisory"]["lurek_stub_proof"]
    extension_proof = result["advisory"]["extension_proof"]
    library_stub_proof = result["advisory"]["library_stub_proof"]

    result["ok"] = all(result["artifacts"].values()) and not any(
        (
            source_proof["source_vs_json_missing_count"] > 0,
            source_proof["source_vs_json_extra_count"] > 0,
            lurek_stub_proof["missing_top_stub_count"] > 0,
            lurek_stub_proof["missing_method_stub_count"] > 0,
            lurek_stub_proof["missing_class_stub_count"] > 0,
            lurek_stub_proof["missing_enum_stub_count"] > 0,
            lurek_stub_proof["enum_value_mismatch_count"] > 0,
            extension_proof["missing_class_count"] > 0,
            extension_proof["missing_enum_count"] > 0,
            extension_proof["enum_value_mismatch_count"] > 0,
            library_stub_proof["missing_top_stub_count"] > 0,
            library_stub_proof["missing_method_stub_count"] > 0,
        )
    )

    return result


def _print_samples(label: str, samples: list) -> None:
    if not samples:
        return
    print(f"       {label}:")
    for sample in samples:
        print(f"         - {sample}")


def _print_text_report(result: dict) -> None:
    if "error" in result:
        print(f"[FAIL] Validator crashed: {result['error']}")
        return

    artifacts = result["artifacts"]
    advisory = result["advisory"]
    source_proof = advisory["source_proof"]
    lurek_stub_proof = advisory["lurek_stub_proof"]
    extension_proof = advisory["extension_proof"]
    library_stub_proof = advisory["library_stub_proof"]

    print(
        "[OK]" if artifacts["json_payload_identical_to_committed"] else "[FAIL]",
        "logs/data/lua_api_data.json matches fresh lua_api payload",
    )
    print(
        "[OK]" if artifacts["lurek_stub_identical_to_committed"] else "[FAIL]",
        "docs/api/lurek.lua matches fresh generator output",
    )
    print(
        "[OK]" if artifacts["library_stub_identical_to_committed"] else "[FAIL]",
        "docs/api/library.lua matches fresh generator output",
    )
    print(
        "[OK]" if artifacts["extension_api_identical_to_committed"] else "[FAIL]",
        "extensions/vscode/data/lurek-api.json matches fresh generator output",
    )
    print(
        "[OK]" if lurek_stub_proof["missing_class_stub_count"] == 0 else "[FAIL]",
        "docs/api/lurek.lua contains every source JSON class",
    )
    print(
        "[OK]"
        if lurek_stub_proof["missing_enum_stub_count"] == 0 and lurek_stub_proof["enum_value_mismatch_count"] == 0
        else "[FAIL]",
        "docs/api/lurek.lua contains every source JSON enum with matching values",
    )
    print(
        "[OK]" if extension_proof["missing_class_count"] == 0 else "[FAIL]",
        "extensions/vscode/data/lurek-api.json contains every source JSON class",
    )
    print(
        "[OK]"
        if extension_proof["missing_enum_count"] == 0 and extension_proof["enum_value_mismatch_count"] == 0
        else "[FAIL]",
        "extensions/vscode/data/lurek-api.json contains every source JSON enum with matching values",
    )

    advisory_has_drift = any(
        (
            source_proof["source_vs_json_missing_count"] > 0,
            source_proof["source_vs_json_extra_count"] > 0,
            lurek_stub_proof["missing_top_stub_count"] > 0,
            lurek_stub_proof["missing_method_stub_count"] > 0,
            lurek_stub_proof["missing_class_stub_count"] > 0,
            lurek_stub_proof["missing_enum_stub_count"] > 0,
            lurek_stub_proof["enum_value_mismatch_count"] > 0,
            extension_proof["missing_class_count"] > 0,
            extension_proof["missing_enum_count"] > 0,
            extension_proof["enum_value_mismatch_count"] > 0,
            library_stub_proof["missing_top_stub_count"] > 0,
            library_stub_proof["missing_method_stub_count"] > 0,
        )
    )
    if advisory_has_drift:
        print(
            "[INFO] Source/artifact drift details are available with --format json; "
            "coverage mismatches now fail validation."
        )

    print()
    print("PASS" if result["ok"] else "FAIL")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate committed generated Lua API artifacts against fresh generator output."
    )
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    try:
        result = validate_generated_lua_stubs()
    except Exception as exc:  # pragma: no cover - failure path only
        result = {"ok": False, "error": str(exc)}

    if args.format == "json":
        print(json.dumps(result, indent=2))
    else:
        _print_text_report(result)

    return 0 if result.get("ok") else 1


if __name__ == "__main__":
    sys.exit(main())
