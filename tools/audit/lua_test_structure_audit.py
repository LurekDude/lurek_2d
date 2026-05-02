#!/usr/bin/env python3
"""Audit and normalize Lua BDD test structure under tests/lua.

This tool standardizes the repository rules for Lua test file headers,
suite/case descriptions, and test_summary placement.

Audited rules:
- Every Lua test file must start with a plain prose header comment block.
- Every describe() must have a preceding -- @describe line.
- Every describe() docstring block may contain only -- @describe.
- Every it() that executes lurek API calls must have a preceding -- @covers line.
- Each -- @covers line must be indented to the same level as the it() it precedes.
  Example: if it() is indented 4 spaces, the @covers must also be indented 4 spaces.
- -- @covers must only list API symbols actually called inside the it() body.
- -- @tests is a forbidden marker; remove it (use @covers only).
- Legacy -- @description and -- @description: syntax is forbidden; use -- @describe <text>.
- Legacy -- @category: markers are forbidden.
- test_summary() must appear exactly once and be the last non-empty line.
- return test_summary() is forbidden; use a bare test_summary() call.

Safe auto-fixes provided by --fix:
- Normalize -- @description: -> -- @describe
- Remove -- @category: lines
- Remove -- @tests lines
- Fix indentation of -- @covers lines to match the following it() call
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
FACTORY_ASSIGN_RE = re.compile(r'\blocal\s+(?P<var>[a-z_][A-Za-z0-9_]*)\s*=\s*lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+\s*\(')
ALIAS_RE = re.compile(r'^---@alias\s+(?P<alias>[A-Za-z][A-Za-z0-9_]*)\s+(?P<target>L[A-Za-z][A-Za-z0-9_]*)\s*$')
FUNC_LUREK_RE = re.compile(r'^function\s+(?P<name>lurek\.[A-Za-z0-9_\.]+)\s*\(')
MODULE_RE = re.compile(r'^(?P<name>lurek\.[A-Za-z0-9_]+)\s*=\s*\{\}\s*$')
FUNC_CLASS_RE = re.compile(r'^function\s+(?P<class>L[A-Za-z][A-Za-z0-9_]*)[:\.]' + r'(?P<method>[A-Za-z][A-Za-z0-9_]*)\s*\(')


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

    var_alias: dict[str, str] = {}

    def scan_line(code_line: str) -> None:
        for m in LUREK_CALL_RE.finditer(code_line):
            symbol = m.group(0)
            required.add(symbol)

        # Capture local var assignments from lurek factories.
        # Example: local fsm = lurek.animation.newStateMachine(a, "idle")
        for assign in re.finditer(
            r'\blocal\s+(?P<var>[a-z_][A-Za-z0-9_]*)\s*=\s*(?P<call>lurek\.[A-Za-z0-9_]+\.[A-Za-z0-9_]+)\s*\(',
            code_line,
        ):
            call_symbol = assign.group("call")
            alias = infer_factory_alias_from_call(call_symbol)
            if alias:
                var_alias[assign.group("var")] = alias

        for mm in OBJECT_METHOD_RE.finditer(code_line):
            var = mm.group(1)
            method = mm.group(3)
            alias = var_alias.get(var)
            if alias:
                required.add(f"{alias}:{method}")
                continue

            # Fallback: if method maps uniquely to one API type, use it.
            aliases = METHOD_TO_ALIASES.get(method)
            if aliases and len(aliases) == 1:
                only = next(iter(aliases))
                required.add(f"{only}:{method}")

    scan_line(line0)
    cursor = index + 1
    while cursor < len(lines):
        raw_line = lines[cursor]
        code_line = strip_lua_comments_and_strings(raw_line)
        stripped = code_line.lstrip()
        cur_indent = len(code_line) - len(stripped)

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

        for m in OBJECT_METHOD_RE.finditer(line):
            var = m.group(1)
            if var in lurek_vars:
                method = m.group(3)
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
            method = m.group(3)
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


def audit_file(path: Path, strict_describe_docstrings: bool = True) -> List[Finding]:
    findings: List[Finding] = []
    raw = path.read_bytes()
    lines = raw.decode("utf-8-sig").splitlines()

    if path.name == "init.lua":
        return findings

    if raw.startswith(UTF8_BOM):
        findings.append(Finding(path, 1, "utf8-bom", "Remove the UTF-8 BOM; Lua test files must be plain UTF-8."))

    if any("\ufeff" in line for line in lines):
        first_inline_bom = next(i for i, line in enumerate(lines, start=1) if "\ufeff" in line)
        findings.append(Finding(path, first_inline_bom, "inline-bom", "Remove stray inline UTF-8 BOM characters from the file header or comments."))

    if not has_plain_file_header(lines):
        findings.append(Finding(path, 1, "missing-file-header", "Add a plain prose file-level header comment before any @covers, @description, or test blocks."))

    summary_lines: List[int] = []

    for index, line in enumerate(lines, start=1):
        if CATEGORY_RE.match(line):
            findings.append(Finding(path, index, "legacy-category", "Remove legacy -- @category markers."))

        if DESCRIPTION_COLON_RE.match(line):
            findings.append(Finding(path, index, "legacy-description-colon", "Use '-- @describe <text>' without a colon."))

        if LEGACY_DESCRIPTION_RE.match(line):
            findings.append(Finding(path, index, "legacy-description", "Use '-- @describe <text>' instead of legacy '-- @description'."))

        if TESTS_MARKER_RE.match(line):
            findings.append(Finding(path, index, "forbidden-tests-marker", "Remove '-- @tests' marker; use '-- @covers <lurek.module.method>' only."))

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

        if kind == "it" and it_block_uses_lurek(lines, index) and not has_covers_before(lines, index):
            findings.append(
                Finding(
                    path,
                    index + 1,
                    "missing-it-covers",
                    f"Add -- @covers directly above it(\"{label}\", ...) because this case calls lurek.* API.",
                )
            )

        if kind == "it":
            cover_symbols = get_preceding_cover_symbols(lines, index)
            required_symbols = collect_it_required_symbols(lines, index)

            cover_by_canonical: dict[str, set[str]] = {}
            for sym in cover_symbols:
                can = canonicalize_symbol(sym)
                cover_by_canonical.setdefault(can, set()).add(sym)

            required_by_canonical: dict[str, set[str]] = {}
            for sym in required_symbols:
                can = canonicalize_symbol(sym)
                required_by_canonical.setdefault(can, set()).add(sym)

            it_indent = len(block.group("indent"))
            # Walk backwards to find any @covers markers preceding this it()
            cursor = index - 1
            while cursor >= 0:
                prev = lines[cursor]
                if not prev.strip():
                    cursor -= 1
                    continue
                cov_match = COVERS_LINE_RE.match(prev)
                if cov_match:
                    covers_indent = len(cov_match.group("indent"))
                    if covers_indent != it_indent:
                        findings.append(
                            Finding(
                                path,
                                cursor + 1,
                                "covers-indent-mismatch",
                                f"-- @covers must be indented {it_indent} spaces (same as it()); found {covers_indent} spaces.",
                            )
                        )
                    cursor -= 1
                    continue
                if prev.lstrip().startswith("--"):
                    cursor -= 1
                    continue
                break

            if required_symbols:
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

    # Build a map: for each @covers line index -> expected indentation
    # Walk each it() backwards to find its preceding @covers block
    covers_target_indent: dict[int, int] = {}
    for it_idx, it_ind in it_indent_map.items():
        cursor = it_idx - 1
        while cursor >= 0:
            prev = original[cursor]
            if not prev.strip():
                cursor -= 1
                continue
            if COVERS_LINE_RE.match(prev):
                covers_target_indent[cursor] = it_ind
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
        # Fix @covers indentation if needed
        if i in covers_target_indent:
            cov_match = COVERS_LINE_RE.match(line)
            if cov_match:
                target_ind = covers_target_indent[i]
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
        findings.extend(audit_file(path, strict_describe_docstrings=not args.allow_legacy_describe_markers))

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
