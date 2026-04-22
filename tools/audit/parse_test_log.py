#!/usr/bin/env python3
"""
tools/audit/parse_test_log.py — Parse `cargo test` output into a structured summary.

Usage (pipe mode):
    cargo test --test lua_tests -- --nocapture 2>&1 | python tools/audit/parse_test_log.py

Usage (file mode):
    python tools/audit/parse_test_log.py --file work/session/logs/test_out.txt

Usage (run mode — runs the test for you):
    python tools/audit/parse_test_log.py --run "--test lua_tests -- library"

Exit code: 0 if all tests pass, 1 if any fail, 2 on parse error.

Output format:
    PASSED: N  FAILED: M  IGNORED: K
    [then each failing test with its error block]

The tool understands both Rust test output ("test foo ... ok/FAILED") and the
Lurek2D Lua BDD output ("FAIL [suite] test: message").
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from typing import Optional


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class TestResult:
    name: str
    status: str        # "ok", "FAILED", "ignored"
    lua_file: str = ""
    lua_passed: int = 0
    lua_failed: int = 0
    lua_total: int = 0
    fail_details: list[str] = field(default_factory=list)
    error_block: list[str] = field(default_factory=list)


@dataclass
class ParseSummary:
    results: list[TestResult] = field(default_factory=list)
    total_passed: int = 0
    total_failed: int = 0
    total_ignored: int = 0

    @property
    def failing(self) -> list[TestResult]:
        return [r for r in self.results if r.status == "FAILED"]


# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

# Regex patterns
RE_TEST_RESULT   = re.compile(r'^test (\S+) \.\.\. (ok|FAILED|ignored)')
RE_FINAL_RESULT  = re.compile(r'^test result: (\w+)\. (\d+) passed; (\d+) failed; (\d+) ignored')
RE_LUA_SUMMARY   = re.compile(r'^(\S+\.lua): (\d+)/(\d+) passed, (\d+) failed')
RE_LUA_FAIL_FLAT = re.compile(r'^  FAIL(?: \[([^\]]+)\])? (.+?): (.+)$')
RE_LUA_FAIL_BDD  = re.compile(r'^  FAIL: \[([^\]]+)\] (.+?) - (.+)$')
RE_FAIL_HEADER   = re.compile(r'^failures:')
RE_PANIC         = re.compile(r"thread '(.+?)' .* panicked at (.+?):(\d+):\d+:\s*$")


def parse(text: str) -> ParseSummary:
    summary = ParseSummary()
    test_map: dict[str, TestResult] = {}
    current_fail_test: Optional[str] = None
    in_failures_section = False
    lines = text.splitlines()
    i = 0

    while i < len(lines):
        line = lines[i]

        # "test foo ... ok/FAILED/ignored"
        m = RE_TEST_RESULT.match(line.strip())
        if m:
            name, status = m.group(1), m.group(2)
            result = TestResult(name=name, status=status)
            summary.results.append(result)
            test_map[name] = result
            i += 1
            continue

        # "foo.lua: 10/12 passed, 2 failed"
        m = RE_LUA_SUMMARY.match(line.strip())
        if m:
            lua_file = m.group(1)
            passed, total, failed = int(m.group(2)), int(m.group(3)), int(m.group(4))
            # Attach to the most recently seen FAILED test (by file name hint)
            for r in reversed(summary.results):
                if r.status == "FAILED" and not r.lua_file:
                    r.lua_file = lua_file
                    r.lua_passed = passed
                    r.lua_total = total
                    r.lua_failed = failed
                    break
            i += 1
            continue

        # BDD-style: "  FAIL: [suite] testname - message"
        stripped = line.strip()
        m = RE_LUA_FAIL_BDD.match(stripped)
        if m:
            suite, test, msg = m.group(1), m.group(2), m.group(3)
            detail = f"  [{suite}] {test}: {msg}"
            for r in reversed(summary.results):
                if r.status == "FAILED":
                    r.fail_details.append(detail)
                    break
            i += 1
            continue

        # Flat-style: "  FAIL [suite] test: message"
        m = RE_LUA_FAIL_FLAT.match(stripped)
        if m:
            suite = m.group(1) or ""
            test, msg = m.group(2), m.group(3)
            detail = f"  [{suite}] {test}: {msg}" if suite else f"  {test}: {msg}"
            for r in reversed(summary.results):
                if r.status == "FAILED":
                    r.fail_details.append(detail)
                    break
            i += 1
            continue

        # Final summary line
        m = RE_FINAL_RESULT.match(line.strip())
        if m:
            summary.total_passed = int(m.group(2))
            summary.total_failed = int(m.group(3))
            summary.total_ignored = int(m.group(4))
            i += 1
            continue

        i += 1

    return summary


# ---------------------------------------------------------------------------
# Renderer
# ---------------------------------------------------------------------------

PASS_COLOUR  = "\033[32m"
FAIL_COLOUR  = "\033[31m"
WARN_COLOUR  = "\033[33m"
DIM_COLOUR   = "\033[90m"
RESET_COLOUR = "\033[0m"


def _c(colour: str, text: str, use_colour: bool) -> str:
    return f"{colour}{text}{RESET_COLOUR}" if use_colour else text


def render(summary: ParseSummary, *, colour: bool = True, verbose: bool = False) -> str:
    lines: list[str] = []

    # Header
    total = summary.total_passed + summary.total_failed + summary.total_ignored
    header = (
        f"PASSED: {summary.total_passed}  "
        f"FAILED: {summary.total_failed}  "
        f"IGNORED: {summary.total_ignored}  "
        f"TOTAL: {total}"
    )
    if summary.total_failed == 0:
        lines.append(_c(PASS_COLOUR, "✓ " + header, colour))
    else:
        lines.append(_c(FAIL_COLOUR, "✗ " + header, colour))

    if summary.total_failed == 0:
        return "\n".join(lines)

    # Group failures by module prefix
    groups: dict[str, list[TestResult]] = defaultdict(list)
    for r in summary.failing:
        # e.g. lua_test_math → "math", lua_integration_ai_physics → "integration/ai_physics"
        name = r.name
        if name.startswith("lua_test_library_"):
            grp = "library/" + name[len("lua_test_library_"):]
        elif name.startswith("lua_integration_"):
            grp = "integration/" + name[len("lua_integration_"):]
        elif name.startswith("lua_stress_"):
            grp = "stress/" + name[len("lua_stress_"):]
        elif name.startswith("lua_golden_"):
            grp = "golden/" + name[len("lua_golden_"):]
        elif name.startswith("lua_validation_"):
            grp = "security/" + name[len("lua_validation_"):]
        elif name.startswith("lua_unit_"):
            grp = "unit_old/" + name[len("lua_unit_"):]
        elif name.startswith("lua_test_"):
            grp = name[len("lua_test_"):]
        else:
            grp = name
        groups[grp].append(r)

    lines.append("")
    lines.append(_c(FAIL_COLOUR, f"━━ FAILED TESTS ({summary.total_failed}) ━━", colour))

    for grp in sorted(groups.keys()):
        results = groups[grp]
        lines.append("")
        lines.append(_c(WARN_COLOUR, f"  ▸ {grp}", colour))
        for r in results:
            # Lua file summary
            if r.lua_file:
                ratio = f"{r.lua_passed}/{r.lua_total}"
                lines.append(_c(DIM_COLOUR, f"    {r.lua_file}: {ratio} passed", colour))
            # Fail details (first 10)
            shown = r.fail_details[:10]
            for d in shown:
                lines.append(_c(FAIL_COLOUR, "    " + d.strip(), colour))
            if len(r.fail_details) > 10:
                more = len(r.fail_details) - 10
                lines.append(_c(DIM_COLOUR, f"    ... and {more} more failures", colour))

    # Common failure patterns
    patterns: dict[str, int] = defaultdict(int)
    for r in summary.failing:
        for d in r.fail_details:
            m = re.search(r"attempt to (?:call|index) (?:field|method|global) '(\w+)'", d)
            if m:
                patterns[f"nil '{m.group(1)}'"] += 1

    if patterns:
        lines.append("")
        lines.append(_c(WARN_COLOUR, "  ▸ Most common nil-access patterns:", colour))
        for pat, count in sorted(patterns.items(), key=lambda x: -x[1])[:15]:
            lines.append(f"      {count:3d}×  {pat}")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description="Parse cargo test output into a structured summary.")
    ap.add_argument("--file", metavar="PATH", help="Read from file instead of stdin")
    ap.add_argument("--run", metavar="ARGS",
                    help='Run `cargo test <ARGS>` and parse the output. '
                         'Example: --run "--test lua_tests"')
    ap.add_argument("--no-colour", action="store_true", help="Disable ANSI colour output")
    ap.add_argument("--verbose", "-v", action="store_true", help="Show all test names, not just failures")
    ap.add_argument("--json", action="store_true", help="Output JSON instead of human text")
    args = ap.parse_args()

    if args.run:
        cmd = ["cargo", "test"] + args.run.split()
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
        raw = proc.stdout + proc.stderr
    elif args.file:
        try:
            with open(args.file, encoding="utf-8", errors="replace") as f:
                raw = f.read()
        except OSError as e:
            print(f"Error reading {args.file}: {e}", file=sys.stderr)
            return 2
    else:
        raw = sys.stdin.read()

    summary = parse(raw)

    if args.json:
        import json
        out = {
            "passed": summary.total_passed,
            "failed": summary.total_failed,
            "ignored": summary.total_ignored,
            "failing_tests": [
                {
                    "name": r.name,
                    "lua_file": r.lua_file,
                    "lua_passed": r.lua_passed,
                    "lua_total": r.lua_total,
                    "lua_failed": r.lua_failed,
                    "details": r.fail_details[:20],
                }
                for r in summary.failing
            ],
        }
        print(json.dumps(out, indent=2))
    else:
        use_colour = not args.no_colour and sys.stdout.isatty()
        print(render(summary, colour=use_colour, verbose=args.verbose))

    return 0 if summary.total_failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
