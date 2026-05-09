#!/usr/bin/env python3
"""Audit and normalize Lua BDD test structure under tests/lua.

This tool standardizes the repository rules for Lua test file headers,
suite/case descriptions, and test_summary placement.

Audited rules:
- Every Lua test file must start with a plain prose header comment block.
- Every describe() must have a preceding -- @describe line.
- Every describe() docstring block may contain only -- @describe.
- Primary marker is folder-specific and must be used above each it() block:
    - tests/lua/unit -> -- @covers
    - tests/lua/security -> -- @security
    - tests/lua/integration -> -- @integration
    - tests/lua/stress -> -- @stress
    - tests/lua/evidence -> -- @evidence
- Primary marker lines must be indented to the same level as the it() they precede.
    Example: if it() is indented 4 spaces, the marker must also be indented 4 spaces.
- For unit tests only, -- @covers symbols may be validated against calls inside it().
- -- @tests is a forbidden marker; remove it.
- Legacy -- @description and -- @description: syntax is forbidden; use -- @describe <text>.
- Legacy -- @category: markers are forbidden.
- test_summary() must appear exactly once and be the last non-empty line.
- return test_summary() is forbidden; use a bare test_summary() call.

Safe auto-fixes provided by --fix:
- Normalize -- @description: -> -- @describe
- Remove -- @category: lines
- Remove -- @tests lines
- Fix indentation of the primary marker line to match the following it() call
- Remove stray inline UTF-8 BOM characters
- Normalize / dedupe / move test_summary() to the file end

This tool deliberately does NOT auto-generate missing descriptions. Those must
be written by hand.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
import re
from typing import Iterable, List


ROOT = Path(__file__).resolve().parents[2]
TESTS_ROOT = ROOT / "tests" / "lua"
API_STUB = ROOT / "docs" / "api" / "lurek.lua"
API_JSON = ROOT / "logs" / "data" / "lua_api_data.json"
UTF8_BOM = b"\xef\xbb\xbf"

BLOCK_RE = re.compile(r'^(?P<indent>\s*)(?P<kind>describe|it)\(\s*["\'](?P<label>.*?)["\']\s*,\s*function\s*\(')
DESCRIBE_RE = re.compile(r'^\s*--\s*@describe\b')
LEGACY_DESCRIPTION_RE = re.compile(r'^\s*--\s*@description\b')
DESCRIPTION_COLON_RE = re.compile(r'^(?P<indent>\s*)--\s*@description:\s*(?P<text>.*)$')
CATEGORY_RE = re.compile(r'^\s*--\s*@category:\s*\w+\s*$')
TESTS_MARKER_RE = re.compile(r'^\s*--\s*@tests\b')
COVERS_LINE_RE = re.compile(r'^(?P<indent>\s*)--\s*@covers\b')
COVERS_SYMBOL_RE = re.compile(r'^\s*--\s*@covers\s+(?P<symbol>[^\s]+)\s*$')
SUMMARY_RE = re.compile(r'^\s*test_summary\(\)\s*$')
RETURN_SUMMARY_RE = re.compile(r'^\s*return\s+test_summary\(\)\s*$')
MARKER_RE = re.compile(r'^\s*--\s*@(?P<name>\w+)\b')
LUREK_CALL_RE = re.compile(r'\blurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+\b')
LUREK_NAMESPACE_RE = re.compile(r'\blurek\.[A-Za-z0-9_]+\b')
# Matches method calls on local variables returned from lurek factories, e.g. seq:load(), hero:setHp()
# We capture <var>:<method> but cannot statically know the type, so we report the raw call form
OBJECT_METHOD_RE = re.compile(r'\b([a-z_][A-Za-z0-9_]*):([ \t]*)([A-Za-z][A-Za-z0-9_]*)\s*\(')
OBJECT_METHOD_DOT_RE = re.compile(r'\b([a-z_][A-Za-z0-9_]*)\.([A-Za-z][A-Za-z0-9_]*)\s*\(')
OBJECT_METHOD_INDEX_RE = re.compile(r'\b([a-z_][A-Za-z0-9_]*)\[\s*["\']([A-Za-z][A-Za-z0-9_]*)["\']\s*\]\s*\(')
FACTORY_ASSIGN_RE = re.compile(r'\blocal\s+(?P<var>[a-z_][A-Za-z0-9_]*)\s*=\s*lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+\s*\(')
ALIAS_RE = re.compile(r'^---@alias\s+(?P<alias>[A-Za-z][A-Za-z0-9_]*)\s+(?P<target>L[A-Za-z][A-Za-z0-9_]*)\s*$')
FUNC_LUREK_RE = re.compile(r'^function\s+(?P<name>lurek\.[A-Za-z0-9_\.]+)\s*\(')
MODULE_RE = re.compile(r'^(?P<name>lurek\.[A-Za-z0-9_]+)\s*=\s*\{\}\s*$')
FUNC_CLASS_RE = re.compile(r'^function\s+(?P<class>L[A-Za-z][A-Za-z0-9_]*)[:\.]' + r'(?P<method>[A-Za-z][A-Za-z0-9_]*)\s*\(')

PRIMARY_MARKERS_BY_FOLDER = {
    "unit": "covers",
    "security": "security",
    "integration": "integration",
    "stress": "stress",
    "evidence": "evidence",
}

FAMILY_MARKERS = set(PRIMARY_MARKERS_BY_FOLDER.values())


def parse_api_stub() -> tuple[set[str], dict[str, str], set[str]]:
    """Load canonical lurek symbols from docs/api/lurek.lua.

    Returns:
      known_lurek_symbols: lurek.module and lurek.module.fn
      alias_to_ltype: Sequencer -> LSequencer
      class_methods: canonical LType:method set
    """
    known_lurek_symbols: set[str] = set()
    alias_to_ltype: dict[str, str] = {}
    class_methods: set[str] = set()

    if not API_STUB.exists():
        return known_lurek_symbols, alias_to_ltype, class_methods

    for raw in API_STUB.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        m = ALIAS_RE.match(line)
        if m:
            alias_to_ltype[m.group("alias")] = m.group("target")
            continue
        m = FUNC_LUREK_RE.match(line)
        if m:
            known_lurek_symbols.add(m.group("name"))
            continue
        m = MODULE_RE.match(line)
        if m:
            known_lurek_symbols.add(m.group("name"))
            continue
        m = FUNC_CLASS_RE.match(line)
        if m:
            class_methods.add(f"{m.group('class')}:{m.group('method')}")
            continue

    return known_lurek_symbols, alias_to_ltype, class_methods


KNOWN_LUREK_SYMBOLS, ALIAS_TO_LTYPE, KNOWN_CLASS_METHODS = parse_api_stub()

LTYPE_TO_ALIASES: dict[str, set[str]] = {}
for alias, ltype in ALIAS_TO_LTYPE.items():
    LTYPE_TO_ALIASES.setdefault(ltype, set()).add(alias)

METHOD_TO_ALIASES: dict[str, set[str]] = {}
for class_method in KNOWN_CLASS_METHODS:
    ltype, method = class_method.split(":", 1)
    aliases = LTYPE_TO_ALIASES.get(ltype)
    if aliases:
        METHOD_TO_ALIASES.setdefault(method, set()).update(aliases)

METHOD_TO_LTYPES: dict[str, set[str]] = {}
for class_method in KNOWN_CLASS_METHODS:
    ltype, method = class_method.split(":", 1)
    METHOD_TO_LTYPES.setdefault(method, set()).add(ltype)


def normalize_return_to_ltype(ret: str | None) -> str | None:
    if not ret:
        return None

    # Most generated values are single-type strings, but keep this robust.
    for token in re.split(r"[|, /]+", ret):
        t = token.strip().rstrip("?")
        if not t:
            continue
        if t in ALIAS_TO_LTYPE:
            return ALIAS_TO_LTYPE[t]
        if t.startswith("L") and any(cm.startswith(t + ":") for cm in KNOWN_CLASS_METHODS):
            return t
    return None


def parse_function_return_types() -> dict[str, str]:
    """Map lurek.module.function -> canonical LType return, when available."""
    result: dict[str, str] = {}

    if not API_JSON.exists():
        return result

    try:
        data = json.loads(API_JSON.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return result

    modules = data.get("lua_api", {}).get("modules", {})
    for _mod_name, mod_data in modules.items():
        for fn in mod_data.get("functions", []):
            lua_name = fn.get("lua_name")
            if not lua_name:
                continue
            ret = fn.get("inferred_return") or fn.get("returns_doc")
            ltype = normalize_return_to_ltype(ret)
            if ltype:
                result[lua_name] = ltype

    return result


FUNCTION_RETURN_LTYPES = parse_function_return_types()


def resolve_type_to_ltype(type_name: str) -> str | None:
    if type_name.startswith("L") and any(cm.startswith(type_name + ":") for cm in KNOWN_CLASS_METHODS):
        return type_name

    direct = ALIAS_TO_LTYPE.get(type_name)
    if direct:
        return direct

    # Accept prefixed variants used in tests, e.g. AnimCurve -> Curve, AnimSyncGroup -> SyncGroup.
    for alias, ltype in ALIAS_TO_LTYPE.items():
        if type_name.endswith(alias):
            return ltype

    return None


def canonicalize_symbol(symbol: str) -> str:
    if symbol.startswith("lurek."):
        return symbol
    if ":" in symbol:
        typ, method = symbol.split(":", 1)
        ltype = resolve_type_to_ltype(typ)
        if ltype:
            return f"{ltype}:{method}"
    return symbol


def strip_lua_comments_and_strings(line: str) -> str:
    """Return a code-only approximation by removing trailing comments and string literals.

    This is a lightweight heuristic, not a full Lua parser, but it avoids most
    false positives from mentions like "does not call lurek.render.rectangle".
    """
    # Remove trailing line comment if present.
    comment_pos = line.find("--")
    if comment_pos != -1:
        line = line[:comment_pos]

    # Remove simple single/double-quoted string literals.
    line = re.sub(r'"[^"\\]*(?:\\.[^"\\]*)*"', '""', line)
    line = re.sub(r"'[^'\\]*(?:\\.[^'\\]*)*'", "''", line)
    return line


@dataclass
class Finding:
    path: Path
    line: int
    code: str
    message: str

    def as_dict(self) -> dict[str, object]:
        return {
            "path": self.path.as_posix(),
            "line": self.line,
            "code": self.code,
            "message": self.message,
        }


def iter_lua_test_files(path_filter: str | None) -> Iterable[Path]:
    if path_filter:
        target = (ROOT / path_filter).resolve()
        if target.is_file():
            yield target
            return
        if target.is_dir():
            yield from sorted(target.rglob("*.lua"))
            return
        raise FileNotFoundError(path_filter)

    yield from sorted(TESTS_ROOT.rglob("*.lua"))


def has_describe_before(lines: List[str], index: int) -> bool:
    cursor = index - 1
    while cursor >= 0:
        line = lines[cursor]
        if not line.strip():
            cursor -= 1
            continue
        if line.lstrip().startswith("--"):
            if DESCRIBE_RE.search(line):
                return True
            cursor -= 1
            continue
        break
    return False


def has_covers_before(lines: List[str], index: int) -> bool:
    cursor = index - 1
    while cursor >= 0:
        line = lines[cursor]
        if not line.strip():
            cursor -= 1
            continue
        if line.lstrip().startswith("--"):
            marker = MARKER_RE.match(line)
            if marker and marker.group("name") == "covers":
                return True
            cursor -= 1
            continue
        break
    return False


def marker_line_regex(marker_name: str) -> re.Pattern[str]:
    return re.compile(rf'^(?P<indent>\s*)--\s*@{re.escape(marker_name)}\b')


def has_marker_before(lines: List[str], index: int, marker_name: str) -> bool:
    marker_re = marker_line_regex(marker_name)
    cursor = index - 1
    while cursor >= 0:
        line = lines[cursor]
        if not line.strip():
            cursor -= 1
            continue
        if line.lstrip().startswith("--"):
            if marker_re.search(line):
                return True
            cursor -= 1
            continue
        break
    return False


def get_preceding_cover_symbols(lines: List[str], index: int) -> set[str]:
    symbols: set[str] = set()
    cursor = index - 1
    while cursor >= 0:
        line = lines[cursor]
        if not line.strip():
            cursor -= 1
            continue
        if line.lstrip().startswith("--"):
            marker = MARKER_RE.match(line)
            if marker and marker.group("name") == "covers":
                sm = COVERS_SYMBOL_RE.match(line)
                if sm:
                    symbols.add(sm.group("symbol"))
            cursor -= 1
            continue
        break
    return symbols


def detect_primary_marker(path: Path) -> str | None:
    for folder, marker in PRIMARY_MARKERS_BY_FOLDER.items():
        if (TESTS_ROOT / folder) in path.parents:
            return marker
    return None


def infer_factory_alias_from_call(call_symbol: str) -> str | None:
    # e.g. lurek.animation.newStateMachine -> StateMachine
    m = re.search(r'\.new([A-Za-z][A-Za-z0-9_]*)$', call_symbol)
    if not m:
        return None
    return m.group(1)


def collect_it_required_symbols(lines: List[str], index: int) -> set[str]:
    """Collect canonical symbols that must be covered for this it() block.

    Includes direct lurek calls and object methods on variables where the type can
    be inferred from a lurek factory assignment (or uniquely inferred by method name).
    """
    required: set[str] = set()
    line0 = strip_lua_comments_and_strings(lines[index])
    indent = len(line0) - len(line0.lstrip())

    var_ltype: dict[str, str] = {}
    active_chain_ltype: str | None = None

    def add_method_symbol(ltype: str, method: str) -> None:
        if f"{ltype}:{method}" in KNOWN_CLASS_METHODS:
            required.add(f"{ltype}:{method}")

    def scan_line(code_line: str) -> None:
        call_matches = list(LUREK_CALL_RE.finditer(code_line))
        for m in call_matches:
            symbol = m.group(0)
            required.add(symbol)

            # Handle chained calls on the same line, e.g. lurek.tween.sequence():start()
            ret_ltype = FUNCTION_RETURN_LTYPES.get(symbol)
            if ret_ltype:
                tail = code_line[m.end():]
                for chain in re.finditer(r':\s*([A-Za-z][A-Za-z0-9_]*)\s*\(', tail):
                    add_method_symbol(ret_ltype, chain.group(1))

        # Capture local var assignments from lurek factories.
        # Example: local fsm = lurek.animation.newStateMachine(a, "idle")
        for assign in re.finditer(
            r'\blocal\s+(?P<var>[a-z_][A-Za-z0-9_]*)\s*=\s*(?P<call>lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+)\s*\(',
            code_line,
        ):
            call_symbol = assign.group("call")
            ltype = FUNCTION_RETURN_LTYPES.get(call_symbol)
            if not ltype:
                alias = infer_factory_alias_from_call(call_symbol)
                if alias:
                    ltype = resolve_type_to_ltype(alias)
            if ltype:
                var_ltype[assign.group("var")] = ltype

        # Track chain context for the next line(s), e.g.
        # lurek.tween.sequence()
        #   :delay(...)
        if call_matches:
            last_call_symbol = call_matches[-1].group(0)
            active_chain_ltype = FUNCTION_RETURN_LTYPES.get(last_call_symbol)

        method_calls: list[tuple[str, str]] = []
        for mm in OBJECT_METHOD_RE.finditer(code_line):
            method_calls.append((mm.group(1), mm.group(3)))
        for mm in OBJECT_METHOD_DOT_RE.finditer(code_line):
            method_calls.append((mm.group(1), mm.group(2)))
        for mm in OBJECT_METHOD_INDEX_RE.finditer(code_line):
            method_calls.append((mm.group(1), mm.group(2)))

        for var, method in method_calls:
            ltype = var_ltype.get(var)
            if ltype:
                add_method_symbol(ltype, method)
                continue

            # Fallback: if method maps uniquely to one API type, use it.
            ltypes = METHOD_TO_LTYPES.get(method)
            if ltypes and len(ltypes) == 1:
                only = next(iter(ltypes))
                add_method_symbol(only, method)

    scan_line(line0)
    cursor = index + 1
    while cursor < len(lines):
        raw_line = lines[cursor]
        code_line = strip_lua_comments_and_strings(raw_line)
        stripped = code_line.lstrip()
        cur_indent = len(code_line) - len(stripped)

        if active_chain_ltype and stripped.startswith(":"):
            for chain in re.finditer(r':\s*([A-Za-z][A-Za-z0-9_]*)\s*\(', stripped):
                add_method_symbol(active_chain_ltype, chain.group(1))
        elif stripped and not stripped.startswith("--"):
            active_chain_ltype = None

        scan_line(code_line)

        if cur_indent <= indent and stripped.startswith("end)"):
            break
        cursor += 1

    return required


def it_block_uses_lurek(lines: List[str], index: int) -> bool:
    """Return True if it() uses lurek.* directly or methods on lurek-created objects.

    We only treat obj:method() as lurek-relevant when obj is a local variable
    assigned from a lurek factory in the same it() block.
    """
    start_line = strip_lua_comments_and_strings(lines[index])
    for m in LUREK_CALL_RE.finditer(start_line):
        return True

    indent = len(start_line) - len(start_line.lstrip())
    cursor = index + 1
    lurek_vars: set[str] = set()

    while cursor < len(lines):
        raw_line = lines[cursor]
        line = strip_lua_comments_and_strings(raw_line)
        stripped = line.lstrip()
        cur_indent = len(line) - len(stripped)

        for m in LUREK_CALL_RE.finditer(line):
            return True

        assign = FACTORY_ASSIGN_RE.search(line)
        if assign:
            lurek_vars.add(assign.group("var"))

        method_calls: list[tuple[str, str]] = []
        for m in OBJECT_METHOD_RE.finditer(line):
            method_calls.append((m.group(1), m.group(3)))
        for m in OBJECT_METHOD_DOT_RE.finditer(line):
            method_calls.append((m.group(1), m.group(2)))
        for m in OBJECT_METHOD_INDEX_RE.finditer(line):
            method_calls.append((m.group(1), m.group(2)))

        for var, method in method_calls:
            if var in lurek_vars:
                # if we can infer the type from factory assignment, validate against canonical methods
                assign_line = next((ln for ln in lines[max(index, cursor - 6):cursor + 1] if FACTORY_ASSIGN_RE.search(strip_lua_comments_and_strings(ln))), None)
                if assign_line:
                    am = FACTORY_ASSIGN_RE.search(strip_lua_comments_and_strings(assign_line))
                    if am:
                        factory = am.group(0)
                        # derive alias from ...newType(
                        nm = re.search(r'new([A-Za-z][A-Za-z0-9_]*)\s*\(', factory)
                        if nm:
                            alias = nm.group(1)
                            ltype = ALIAS_TO_LTYPE.get(alias, f"L{alias}")
                            if f"{ltype}:{method}" in KNOWN_CLASS_METHODS:
                                return True
                            continue
                # fallback: if unsure, treat as lurek-relevant to avoid underreporting
                return True
            # Also treat known API object methods as lurek-relevant even when
            # the variable was created by a helper (e.g., make_anim()).
            if method in METHOD_TO_ALIASES:
                return True

        if cur_indent <= indent and stripped.startswith("end)"):
            break
        cursor += 1

    return False


def get_preceding_markers(lines: List[str], index: int) -> List[tuple[int, str]]:
    markers: List[tuple[int, str]] = []
    cursor = index - 1
    while cursor >= 0:
        line = lines[cursor]
        if not line.strip():
            cursor -= 1
            continue
        if line.lstrip().startswith("--"):
            marker = MARKER_RE.match(line)
            if marker:
                markers.insert(0, (cursor + 1, marker.group("name")))
            cursor -= 1
            continue
        break
    return markers


def has_plain_file_header(lines: List[str]) -> bool:
    cursor = 0
    total = len(lines)

    while cursor < total and not lines[cursor].strip():
        cursor += 1

    if cursor >= total:
        return False

    line = lines[cursor]
    if DESCRIBE_RE.search(line) or LEGACY_DESCRIPTION_RE.search(line) or line.lstrip().startswith("-- @"):
        return False

    if line.lstrip().startswith("--"):
        return True

    return False


def audit_file(
    path: Path,
    strict_describe_docstrings: bool = True,
    validate_cover_symbols: bool = False,
) -> List[Finding]:
    findings: List[Finding] = []
    raw = path.read_bytes()
    lines = raw.decode("utf-8-sig").splitlines()

    if path.name == "init.lua":
        return findings

    primary_marker = detect_primary_marker(path)
    is_unit_test = primary_marker == "covers"

    if raw.startswith(UTF8_BOM):
        findings.append(Finding(path, 1, "utf8-bom", "Remove the UTF-8 BOM; Lua test files must be plain UTF-8."))

    if any("\ufeff" in line for line in lines):
        first_inline_bom = next(i for i, line in enumerate(lines, start=1) if "\ufeff" in line)
        findings.append(Finding(path, first_inline_bom, "inline-bom", "Remove stray inline UTF-8 BOM characters from the file header or comments."))

    if not has_plain_file_header(lines):
        findings.append(Finding(path, 1, "missing-file-header", "Add a plain prose file-level header comment before markers or test blocks."))

    summary_lines: List[int] = []

    for index, line in enumerate(lines, start=1):
        if CATEGORY_RE.match(line):
            findings.append(Finding(path, index, "legacy-category", "Remove legacy -- @category markers."))

        if DESCRIPTION_COLON_RE.match(line):
            findings.append(Finding(path, index, "legacy-description-colon", "Use '-- @describe <text>' without a colon."))

        if LEGACY_DESCRIPTION_RE.match(line):
            findings.append(Finding(path, index, "legacy-description", "Use '-- @describe <text>' instead of legacy '-- @description'."))

        if TESTS_MARKER_RE.match(line):
            if primary_marker:
                findings.append(Finding(path, index, "forbidden-tests-marker", f"Remove '-- @tests' marker; use '-- @{primary_marker} ...' for this suite."))
            else:
                findings.append(Finding(path, index, "forbidden-tests-marker", "Remove '-- @tests' marker; use the suite primary marker."))

        if SUMMARY_RE.match(line) or RETURN_SUMMARY_RE.match(line):
            summary_lines.append(index)

    for index, line in enumerate(lines):
        block = BLOCK_RE.match(line)
        if not block:
            continue

        kind = block.group("kind")
        label = block.group("label")
        if kind == "describe" and not has_describe_before(lines, index):
            findings.append(
                Finding(
                    path,
                    index + 1,
                    "missing-describe-marker",
                    f"Add -- @describe directly above describe(\"{label}\", ...).",
                )
            )

        if kind == "it" and primary_marker and not has_marker_before(lines, index, primary_marker):
            findings.append(
                Finding(
                    path,
                    index + 1,
                    "missing-it-primary-marker",
                    f"Add -- @{primary_marker} directly above it(\"{label}\", ...) for this suite.",
                )
            )

        if kind == "it":
            cover_symbols = get_preceding_cover_symbols(lines, index) if is_unit_test else set()
            required_symbols = collect_it_required_symbols(lines, index) if (validate_cover_symbols and is_unit_test) else set()

            cover_by_canonical: dict[str, set[str]] = {}
            for sym in cover_symbols:
                can = canonicalize_symbol(sym)
                cover_by_canonical.setdefault(can, set()).add(sym)

            required_by_canonical: dict[str, set[str]] = {}
            for sym in required_symbols:
                can = canonicalize_symbol(sym)
                required_by_canonical.setdefault(can, set()).add(sym)

            it_indent = len(block.group("indent"))
            # Walk backwards to find any primary marker lines preceding this it()
            primary_marker_re = marker_line_regex(primary_marker) if primary_marker else None
            cursor = index - 1
            while cursor >= 0:
                prev = lines[cursor]
                if not prev.strip():
                    cursor -= 1
                    continue
                marker_match = primary_marker_re.match(prev) if primary_marker_re else None
                if marker_match:
                    marker_indent = len(marker_match.group("indent"))
                    if marker_indent != it_indent:
                        findings.append(
                            Finding(
                                path,
                                cursor + 1,
                                "marker-indent-mismatch",
                                f"-- @{primary_marker} must be indented {it_indent} spaces (same as it()); found {marker_indent} spaces.",
                            )
                        )
                    cursor -= 1
                    continue
                if prev.lstrip().startswith("--"):
                    cursor -= 1
                    continue
                break

            if validate_cover_symbols and is_unit_test and required_symbols:
                missing_canonicals = sorted(set(required_by_canonical.keys()) - set(cover_by_canonical.keys()))
                for canonical in missing_canonicals:
                    symbol = sorted(required_by_canonical[canonical])[0]
                    findings.append(
                        Finding(
                            path,
                            index + 1,
                            "missing-it-cover-symbol",
                            f"Add -- @covers {symbol} directly above it(\"{label}\", ...) because this symbol is called in this test.",
                        )
                    )

                extra_canonicals = sorted(set(cover_by_canonical.keys()) - set(required_by_canonical.keys()))
                for canonical in extra_canonicals:
                    symbol = sorted(cover_by_canonical[canonical])[0]
                    findings.append(
                        Finding(
                            path,
                            index + 1,
                            "extra-it-cover-symbol",
                            f"Remove -- @covers {symbol} from this it() block because the symbol is not called here.",
                        )
                    )

            if primary_marker:
                markers = get_preceding_markers(lines, index)
                wrong_markers = [
                    (line_no, marker_name)
                    for line_no, marker_name in markers
                    if marker_name in FAMILY_MARKERS and marker_name != primary_marker
                ]
                for line_no, marker_name in wrong_markers:
                    findings.append(
                        Finding(
                            path,
                            line_no,
                            "wrong-family-marker",
                            f"Use -- @{primary_marker} in this suite; -- @{marker_name} belongs to a different test family.",
                        )
                    )

        if strict_describe_docstrings and kind == "describe":
            markers = get_preceding_markers(lines, index)
            non_describe = [(line_no, name) for line_no, name in markers if name != "describe"]
            if non_describe:
                first_line, _ = non_describe[0]
                marker_names = ", ".join(sorted({name for _, name in non_describe}))
                findings.append(
                    Finding(
                        path,
                        first_line,
                        "describe-non-describe-marker",
                        f"describe() docstrings may only contain @describe; move {marker_names} markers to the owning it() block.",
                    )
                )

    if not summary_lines:
        findings.append(Finding(path, len(lines), "missing-test-summary", "Add test_summary() as the last non-empty line."))
    else:
        if len(summary_lines) > 1:
            findings.append(Finding(path, summary_lines[1], "multiple-test-summary", "Keep exactly one test_summary() call at file end."))

        last_non_empty_index = None
        for idx in range(len(lines) - 1, -1, -1):
            if lines[idx].strip():
                last_non_empty_index = idx + 1
                break

        if last_non_empty_index is not None:
            last_line = lines[last_non_empty_index - 1].strip()
            if last_line != "test_summary()":
                findings.append(
                    Finding(
                        path,
                        last_non_empty_index,
                        "test-summary-not-last",
                        "The last non-empty line must be a bare test_summary() call.",
                    )
                )
        if any(RETURN_SUMMARY_RE.match(lines[idx - 1]) for idx in summary_lines):
            first_return = next(idx for idx in summary_lines if RETURN_SUMMARY_RE.match(lines[idx - 1]))
            findings.append(Finding(path, first_return, "return-test-summary", "Use 'test_summary()' without return."))

    return findings


def fix_file(path: Path) -> bool:
    if path.name == "init.lua":
        return False

    raw = path.read_bytes()
    original_text = raw.decode("utf-8-sig")
    original = [line.replace("\ufeff", "") for line in original_text.splitlines()]
    fixed: List[str] = []

    # First pass: collect it() indentation levels indexed by line number
    it_indent_map: dict[int, int] = {}
    for i, line in enumerate(original):
        m = BLOCK_RE.match(line)
        if m and m.group("kind") == "it":
            it_indent_map[i] = len(m.group("indent"))

    primary_marker = detect_primary_marker(path)
    primary_marker_re = marker_line_regex(primary_marker) if primary_marker else None

    # Build a map: for each primary marker line index -> expected indentation.
    marker_target_indent: dict[int, int] = {}
    for it_idx, it_ind in it_indent_map.items():
        cursor = it_idx - 1
        while cursor >= 0:
            prev = original[cursor]
            if not prev.strip():
                cursor -= 1
                continue
            if primary_marker_re and primary_marker_re.match(prev):
                marker_target_indent[cursor] = it_ind
                cursor -= 1
                continue
            if prev.lstrip().startswith("--"):
                cursor -= 1
                continue
            break

    for i, line in enumerate(original):
        if CATEGORY_RE.match(line):
            continue
        if TESTS_MARKER_RE.match(line):
            continue
        colon = DESCRIPTION_COLON_RE.match(line)
        if colon:
            text = colon.group("text").strip()
            if text:
                fixed.append(f"{colon.group('indent')}-- @describe {text}")
            else:
                fixed.append(f"{colon.group('indent')}-- @describe")
            continue
        if LEGACY_DESCRIPTION_RE.match(line):
            fixed.append(LEGACY_DESCRIPTION_RE.sub("-- @describe", line, count=1))
            continue
        if RETURN_SUMMARY_RE.match(line) or SUMMARY_RE.match(line):
            continue
        # Fix primary marker indentation if needed.
        if i in marker_target_indent and primary_marker_re and primary_marker_re.match(line):
            target_ind = marker_target_indent[i]
            rest = line.lstrip()
            fixed.append(" " * target_ind + rest)
            continue
        fixed.append(line)

    while fixed and not fixed[-1].strip():
        fixed.pop()
    fixed.append("test_summary()")

    new_text = "\n".join(fixed) + "\n"
    if new_text == original_text and not raw.startswith(UTF8_BOM):
        return False

    path.write_text(new_text, encoding="utf-8")
    return True


def print_human(findings: List[Finding]) -> None:
    if not findings:
        print("PASS: no Lua test structure issues found")
        return

    counts = Counter(f.code for f in findings)
    print("FAIL: Lua test structure issues found")
    for code, count in sorted(counts.items()):
        print(f"  {code}: {count}")
    print()
    for finding in findings:
        rel = finding.path.relative_to(ROOT).as_posix()
        print(f"{rel}:{finding.line}: {finding.code}: {finding.message}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit and optionally fix Lua BDD test structure.")
    parser.add_argument("--path", help="File or directory to audit relative to repo root.")
    parser.add_argument("--fix", action="store_true", help="Apply safe structural fixes (category markers, description colon form, test_summary placement).")
    parser.add_argument("--allow-legacy-describe-markers", action="store_true", help="Temporarily relax the default rule that describe() docstring blocks may contain only @describe.")
    parser.add_argument("--validate-cover-symbols", action="store_true", help="Enable strict per-symbol @covers validation for unit tests only (may report false positives on dynamic calls).")
    parser.add_argument("--json", action="store_true", help="Print findings as JSON.")
    args = parser.parse_args()

    try:
        files = list(iter_lua_test_files(args.path))
    except FileNotFoundError as exc:
        print(f"ERROR: path not found: {exc}", file=sys.stderr)
        return 2

    changed = 0
    if args.fix:
        for path in files:
            if fix_file(path):
                changed += 1

    findings: List[Finding] = []
    for path in files:
        findings.extend(
            audit_file(
                path,
                strict_describe_docstrings=not args.allow_legacy_describe_markers,
                validate_cover_symbols=args.validate_cover_symbols,
            )
        )

    if args.json:
        payload = {
            "changed_files": changed,
            "issue_count": len(findings),
            "issues": [finding.as_dict() for finding in findings],
        }
        print(json.dumps(payload, indent=2))
    else:
        if args.fix:
            print(f"Fixed {changed} file(s)")
        print_human(findings)

    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
