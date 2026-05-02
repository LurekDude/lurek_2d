#!/usr/bin/env python3
"""Audit @covers markers against docs/api/lurek.lua.

Rules:
- @covers must reference a real API symbol from docs/api/lurek.lua
- Duplicate @covers lines in the same block (above one it()) are flagged

Accepted marker forms:
- -- @covers lurek.module.func
- -- @covers Type:method

Type:method is resolved through aliases from docs/api/lurek.lua:
  ---@alias Type LType
and direct class declarations:
  function LType:method(...)

Usage:
  python tools/audit/lua_covers_lurek_api_audit.py
  python tools/audit/lua_covers_lurek_api_audit.py --path tests/lua/unit
  python tools/audit/lua_covers_lurek_api_audit.py --fix
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Set, Tuple

ROOT = Path(__file__).resolve().parents[2]
API_STUB = ROOT / "docs" / "api" / "lurek.lua"
TESTS_ROOT = ROOT / "tests" / "lua"

BLOCK_RE = re.compile(r'^(?P<indent>\s*)it\s*\(\s*["\'](?P<label>.*?)["\']\s*,\s*function\s*\(')
COVERS_RE = re.compile(r'^(?P<indent>\s*)--\s*@covers\s+(?P<sym>\S+)\s*$')
ALIAS_RE = re.compile(r'^---@alias\s+(?P<alias>[A-Za-z][A-Za-z0-9_]*)\s+(?P<target>L[A-Za-z][A-Za-z0-9_]*)\s*$')
FUNC_LUREK_RE = re.compile(r'^function\s+(?P<name>lurek\.[A-Za-z0-9_\.]+)\s*\(')
MODULE_RE = re.compile(r'^(?P<name>lurek\.[A-Za-z0-9_]+)\s*=\s*\{\}\s*$')
FUNC_CLASS_RE = re.compile(r'^function\s+(?P<class>L[A-Za-z][A-Za-z0-9_]*)[:\.]' + r'(?P<method>[A-Za-z][A-Za-z0-9_]*)\s*\(')


@dataclass
class Finding:
    path: Path
    line: int
    code: str
    message: str


def iter_lua_files(path_filter: str | None) -> List[Path]:
    if path_filter:
        p = (ROOT / path_filter).resolve()
        if p.is_file():
            return [p]
        if p.is_dir():
            return sorted(p.rglob("*.lua"))
        raise FileNotFoundError(path_filter)
    return sorted(TESTS_ROOT.rglob("*.lua"))


def parse_api_stub(path: Path) -> Tuple[Set[str], Set[str], Set[str], Dict[str, str]]:
    text = path.read_text(encoding="utf-8")
    lurek_funcs: Set[str] = set()
    lurek_modules: Set[str] = set()
    class_methods: Set[str] = set()  # LType:method canonical
    alias_to_ltype: Dict[str, str] = {}

    for line in text.splitlines():
        m = ALIAS_RE.match(line.strip())
        if m:
            alias_to_ltype[m.group("alias")] = m.group("target")
            continue

        m = FUNC_LUREK_RE.match(line.strip())
        if m:
            lurek_funcs.add(m.group("name"))
            continue

        m = MODULE_RE.match(line.strip())
        if m:
            lurek_modules.add(m.group("name"))
            continue

        m = FUNC_CLASS_RE.match(line.strip())
        if m:
            class_methods.add(f"{m.group('class')}:{m.group('method')}")
            continue

    return lurek_funcs, lurek_modules, class_methods, alias_to_ltype


def normalize_method_symbol(sym: str, alias_to_ltype: Dict[str, str]) -> str:
    if ":" not in sym:
        return sym
    typ, meth = sym.split(":", 1)
    if typ.startswith("L"):
        return f"{typ}:{meth}"
    ltype = alias_to_ltype.get(typ)
    if ltype:
        return f"{ltype}:{meth}"
    # fallback: assume L prefix
    return f"L{typ}:{meth}"


def collect_cover_block(lines: List[str], it_idx: int) -> List[Tuple[int, str, str]]:
    """Return list of (line_no_1based, indent, symbol) for @covers above an it()."""
    out: List[Tuple[int, str, str]] = []
    cur = it_idx - 1
    while cur >= 0:
        line = lines[cur]
        if not line.strip():
            cur -= 1
            continue
        m = COVERS_RE.match(line)
        if m:
            out.insert(0, (cur + 1, m.group("indent"), m.group("sym")))
            cur -= 1
            continue
        if line.lstrip().startswith("--"):
            cur -= 1
            continue
        break
    return out


def audit_file(path: Path, lurek_funcs: Set[str], lurek_modules: Set[str], class_methods: Set[str], alias_to_ltype: Dict[str, str]) -> List[Finding]:
    findings: List[Finding] = []
    lines = path.read_text(encoding="utf-8").splitlines()

    for i, line in enumerate(lines):
        m = BLOCK_RE.match(line)
        if not m:
            continue
        block = collect_cover_block(lines, i)
        if not block:
            continue

        seen: Set[str] = set()
        for line_no, _indent, sym in block:
            key = sym
            if key in seen:
                findings.append(Finding(path, line_no, "duplicate-covers", f"Duplicate @covers '{sym}' in the same it() block."))
            else:
                seen.add(key)

            if sym.startswith("lurek."):
                if sym not in lurek_funcs and sym not in lurek_modules:
                    findings.append(Finding(path, line_no, "unknown-covers-symbol", f"Unknown lurek API in @covers: '{sym}' (not found in docs/api/lurek.lua)."))
            elif ":" in sym:
                canon = normalize_method_symbol(sym, alias_to_ltype)
                if canon not in class_methods:
                    findings.append(Finding(path, line_no, "unknown-covers-symbol", f"Unknown method API in @covers: '{sym}' (resolved '{canon}') not found in docs/api/lurek.lua."))
            else:
                findings.append(Finding(path, line_no, "invalid-covers-format", f"Unsupported @covers symbol format: '{sym}'."))

    return findings


def is_valid_symbol(sym: str, lurek_funcs: Set[str], lurek_modules: Set[str], class_methods: Set[str], alias_to_ltype: Dict[str, str]) -> bool:
    if sym.startswith("lurek."):
        return sym in lurek_funcs or sym in lurek_modules
    if ":" in sym:
        canon = normalize_method_symbol(sym, alias_to_ltype)
        return canon in class_methods
    return False


def fix_file(
    path: Path,
    lurek_funcs: Set[str],
    lurek_modules: Set[str],
    class_methods: Set[str],
    alias_to_ltype: Dict[str, str],
    prune_unknown: bool,
) -> bool:
    lines = path.read_text(encoding="utf-8").splitlines()
    changed = False

    i = 0
    while i < len(lines):
        if not BLOCK_RE.match(lines[i]):
            i += 1
            continue

        # find cover block above it
        start = i
        cur = i - 1
        while cur >= 0:
            if not lines[cur].strip() or lines[cur].lstrip().startswith("--"):
                cur -= 1
                continue
            break
        block_start = cur + 1
        block = lines[block_start:i]

        # dedupe and optionally remove invalid @covers in this attached comment block
        seen: Set[str] = set()
        new_block: List[str] = []
        for b in block:
            m = COVERS_RE.match(b)
            if m:
                sym = m.group("sym")
                if prune_unknown and not is_valid_symbol(sym, lurek_funcs, lurek_modules, class_methods, alias_to_ltype):
                    changed = True
                    continue
                key = sym
                if key in seen:
                    changed = True
                    continue
                seen.add(key)
                new_block.append(b)
            else:
                new_block.append(b)

        if new_block != block:
            lines[block_start:i] = new_block
            i = block_start + len(new_block)
            continue

        i += 1

    if changed:
        path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return changed


def main() -> int:
    ap = argparse.ArgumentParser(description="Audit @covers markers against docs/api/lurek.lua")
    ap.add_argument("--path", help="File or directory relative to repo root")
    ap.add_argument("--fix", action="store_true", help="Remove duplicate @covers markers in a block")
    ap.add_argument("--prune-unknown", action="store_true", help="When used with --fix, also remove @covers symbols not found in docs/api/lurek.lua")
    ap.add_argument("--json", action="store_true", help="JSON output")
    args = ap.parse_args()

    if not API_STUB.exists():
        print(f"ERROR: missing API stub: {API_STUB}", file=sys.stderr)
        return 2

    try:
        files = iter_lua_files(args.path)
    except FileNotFoundError as exc:
        print(f"ERROR: path not found: {exc}", file=sys.stderr)
        return 2

    lurek_funcs, lurek_modules, class_methods, alias_to_ltype = parse_api_stub(API_STUB)

    changed = 0
    if args.fix:
        for p in files:
            if p.name == "init.lua":
                continue
            if fix_file(p, lurek_funcs, lurek_modules, class_methods, alias_to_ltype, prune_unknown=args.prune_unknown):
                changed += 1

    findings: List[Finding] = []
    for p in files:
        if p.name == "init.lua":
            continue
        findings.extend(audit_file(p, lurek_funcs, lurek_modules, class_methods, alias_to_ltype))

    if args.json:
        payload = {
            "changed_files": changed,
            "issue_count": len(findings),
            "issues": [
                {
                    "path": f.path.as_posix(),
                    "line": f.line,
                    "code": f.code,
                    "message": f.message,
                }
                for f in findings
            ],
        }
        print(json.dumps(payload, indent=2))
    else:
        if args.fix:
            print(f"Fixed {changed} file(s)")
        if not findings:
            print("PASS: no @covers symbol issues against docs/api/lurek.lua")
        else:
            print("FAIL: @covers issues found")
            by_code: Dict[str, int] = {}
            for f in findings:
                by_code[f.code] = by_code.get(f.code, 0) + 1
            for code, count in sorted(by_code.items()):
                print(f"  {code}: {count}")
            for f in findings:
                rel = f.path.relative_to(ROOT).as_posix()
                print(f"{rel}:{f.line}: {f.code}: {f.message}")

    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
