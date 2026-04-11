#!/usr/bin/env python3
"""
tools/scripts/test_fix_loop.py — Agent-friendly test-run / fix / re-run loop.

Designed to be called by AI agents or developers iterating on test fixes.
Runs `cargo test`, parses the output, shows the most actionable failures,
saves a log, and optionally loops until clean.

Usage:
    # Run all Lua tests once and print summary
    python tools/scripts/test_fix_loop.py

    # Run a specific test binary and filter
    python tools/scripts/test_fix_loop.py --test lua_tests --filter library

    # Run in loop mode (re-runs until all pass or max iterations reached)
    python tools/scripts/test_fix_loop.py --test lua_tests --loop --max-iterations 5

    # Change thread count (default is cargo's default)
    python tools/scripts/test_fix_loop.py --threads 4

    # Run a quick cargo check before testing
    python tools/scripts/test_fix_loop.py --check-first

Exit codes:
    0 — all tests pass
    1 — test failures remain
    2 — cargo compilation error
    3 — max iterations reached without full green
"""

from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

# Add parent tools/ to sys.path so we can import parse_test_log
HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent / "audit"))
try:
    import parse_test_log as ptl
except ImportError:
    ptl = None  # type: ignore


ROOT = Path(__file__).parent.parent.parent

# ANSI colours
RED    = "\033[31m"
GREEN  = "\033[32m"
YELLOW = "\033[33m"
CYAN   = "\033[36m"
DIM    = "\033[90m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

USE_COLOUR = sys.stdout.isatty()


def clr(colour: str, text: str) -> str:
    return f"{colour}{text}{RESET}" if USE_COLOUR else text


def banner(text: str) -> None:
    line = "━" * min(60, len(text) + 4)
    print(clr(CYAN, f"\n{line}"))
    print(clr(CYAN, f"  {text}"))
    print(clr(CYAN, line))


def run_cargo_check() -> bool:
    print(clr(DIM, "  Running cargo check..."))
    r = subprocess.run(
        ["cargo", "check"],
        cwd=ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace",
    )
    if r.returncode != 0:
        print(clr(RED, "  cargo check FAILED:"))
        print(r.stderr[-3000:])
        return False
    print(clr(GREEN, "  cargo check OK"))
    return True


def run_tests(test_binary: str, filter_str: str, threads: int | None, nocapture: bool) -> tuple[str, int]:
    """Run `cargo test` and return (combined_output, returncode)."""
    cmd = ["cargo", "test"]
    if test_binary:
        cmd += ["--test", test_binary]
    cmd += ["--"]
    if filter_str:
        cmd.append(filter_str)
    if nocapture:
        cmd.append("--nocapture")
    if threads is not None:
        cmd += ["--test-threads", str(threads)]

    env = os.environ.copy()
    # Force colour off in subprocess output so we parse clean text
    env.pop("CARGO_TERM_COLOR", None)

    r = subprocess.run(
        cmd, cwd=ROOT, capture_output=True, text=True,
        encoding="utf-8", errors="replace", env=env,
    )
    combined = r.stdout + r.stderr
    return combined, r.returncode


def save_log(output: str, iteration: int, log_dir: Path) -> Path:
    log_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    path = log_dir / f"test_run_{iteration:02d}_{ts}.txt"
    path.write_text(output, encoding="utf-8")
    return path


def show_top_failures(summary: "ptl.ParseSummary", max_tests: int = 10, max_details: int = 5) -> None:
    """Print the most actionable failures with grouped context."""
    failing = summary.failing[:max_tests]
    if not failing:
        return

    print(clr(RED, f"\n  ═══ TOP FAILURES ({len(summary.failing)} total) ═══"))

    # Group by common error pattern
    nil_counts: dict[str, int] = {}
    for r in summary.failing:
        for d in r.fail_details:
            m = re.search(r"attempt to (?:call|index) (?:field|method|global) '(\w+)'", d)
            if m:
                nil_counts[m.group(1)] = nil_counts.get(m.group(1), 0) + 1

    if nil_counts:
        print(clr(YELLOW, "\n  Most common nil-access errors (root causes to fix first):"))
        for name, count in sorted(nil_counts.items(), key=lambda x: -x[1])[:8]:
            print(f"    {clr(RED, f'{count:3d}×')}  lurek.*.{name}  is nil → add to Rust API or fix test")

    print()
    for r in failing:
        label = r.lua_file or r.name
        ratio = f"{r.lua_passed}/{r.lua_total}" if r.lua_total else "?"
        header_line = f"  ▸ {clr(YELLOW, r.name)}"
        if r.lua_file:
            header_line += clr(DIM, f"  ({label}: {ratio} passed)")
        print(header_line)
        for d in r.fail_details[:max_details]:
            print(clr(RED, "      " + d.strip()))
        if len(r.fail_details) > max_details:
            print(clr(DIM, f"      ... +{len(r.fail_details) - max_details} more"))
        print()


def show_agent_hints(summary: "ptl.ParseSummary") -> None:
    """Print actionable hints for an AI agent to fix failures."""
    if not summary.failing:
        return

    patterns: dict[str, list[str]] = {}
    for r in summary.failing:
        for d in r.fail_details:
            # nil field/method/global
            m = re.search(r"attempt to (?:call|index) (?:field|method|global) '(\w+)'.*nil value", d)
            if m:
                key = f"nil_access:{m.group(1)}"
                patterns.setdefault(key, []).append(r.name)
            # module not found
            m2 = re.search(r"module '([^']+)' not found", d)
            if m2:
                key = f"require_missing:{m2.group(1)}"
                patterns.setdefault(key, []).append(r.name)

    if not patterns:
        return

    print(clr(CYAN, "\n  ═══ AGENT FIX HINTS ═══"))
    print(clr(DIM, "  (Ordered by frequency — fix high-count issues first)"))
    for key, tests in sorted(patterns.items(), key=lambda x: -len(x[1]))[:12]:
        kind, name = key.split(":", 1)
        tests_str = ", ".join(tests[:3]) + (f"  +{len(tests)-3} more" if len(tests) > 3 else "")
        if kind == "nil_access":
            print(f"\n  [{clr(RED, f'{len(tests):d}×')}] API missing: '{clr(YELLOW, name)}'")
            print(f"       Affects: {clr(DIM, tests_str)}")
            print(f"       Fix: add tbl.set(\"{name}\", ...) to the relevant *_api.rs")
        elif kind == "require_missing":
            print(f"\n  [{clr(RED, f'{len(tests):d}×')}] require missing: '{clr(YELLOW, name)}'")
            print(f"       Affects: {clr(DIM, tests_str)}")
            print(f"       Fix: check content/library/{name.replace('.','/')} or use correct path")


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Lurek2D test-run / fix loop — run tests, show top failures, iterate.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("--test", metavar="BINARY",
                    help="Test binary name e.g. lua_tests, rust_unit_tests (default: all)")
    ap.add_argument("--filter", metavar="FILTER",
                    help="Filter string passed to cargo test (e.g. 'library', 'unit')")
    ap.add_argument("--threads", type=int, metavar="N",
                    help="test-threads (default: cargo default, usually CPU count)")
    ap.add_argument("--nocapture", action="store_true", default=True,
                    help="Pass --nocapture to cargo test (default: on)")
    ap.add_argument("--capture", dest="nocapture", action="store_false",
                    help="Disable --nocapture")
    ap.add_argument("--loop", action="store_true",
                    help="Re-run tests automatically after a pause (useful when fixing in parallel)")
    ap.add_argument("--max-iterations", type=int, default=10, metavar="N",
                    help="Maximum loop iterations (default: 10)")
    ap.add_argument("--pause", type=float, default=5.0, metavar="SECONDS",
                    help="Pause between loop iterations (default: 5s)")
    ap.add_argument("--check-first", action="store_true",
                    help="Run cargo check before tests; abort if it fails")
    ap.add_argument("--log-dir", metavar="PATH",
                    default="work/test-framework-parallel/logs",
                    help="Directory to save run logs (default: work/test-framework-parallel/logs)")
    ap.add_argument("--no-colour", action="store_true",
                    help="Disable ANSI colours")
    ap.add_argument("--once", action="store_true",
                    help="Run once and exit (equivalent to no --loop)")
    args = ap.parse_args()

    global USE_COLOUR
    if args.no_colour:
        USE_COLOUR = False

    if ptl is None:
        print(clr(RED, "ERROR: Cannot import parse_test_log from tools/audit/parse_test_log.py"))
        print("Make sure you run this script from the repo root with:")
        print("  python tools/scripts/test_fix_loop.py")
        return 2

    loop_mode = args.loop and not args.once
    max_iter = args.max_iterations
    log_dir = ROOT / args.log_dir

    iteration = 0
    while True:
        iteration += 1
        banner(f"Test Run #{iteration}" + (f" / {max_iter}" if loop_mode else ""))

        # Optional cargo check
        if args.check_first and iteration == 1:
            if not run_cargo_check():
                return 2

        # Run tests
        ts_start = time.monotonic()
        print(clr(DIM, f"  Running: cargo test{' --test ' + args.test if args.test else ''}"
                        f"{' -- ' + args.filter if args.filter else ''}"
                        f"{'  --nocapture' if args.nocapture else ''}"
                        f"{'  --test-threads=' + str(args.threads) if args.threads else ''}"))

        raw, returncode = run_tests(
            args.test or "",
            args.filter or "",
            args.threads,
            args.nocapture,
        )
        elapsed = time.monotonic() - ts_start

        # Save log
        log_path = save_log(raw, iteration, log_dir)
        print(clr(DIM, f"  Log saved: {log_path.relative_to(ROOT)}  ({elapsed:.1f}s)"))

        # Parse
        summary = ptl.parse(raw)

        # Print short summary
        if summary.total_failed == 0 and summary.total_passed > 0:
            print(clr(GREEN, f"\n  ✓ ALL TESTS PASS  ({summary.total_passed} passed, {summary.total_ignored} ignored)"))
            return 0
        elif returncode != 0 and summary.total_passed == 0 and summary.total_failed == 0:
            print(clr(RED, "\n  ✗ Compile error — no tests ran. Fix compilation first."))
            print(raw[-3000:])
            return 2
        else:
            p, f, ig = summary.total_passed, summary.total_failed, summary.total_ignored
            print(clr(RED if f else GREEN, f"\n  {'✗' if f else '✓'} {p} passed  {f} failed  {ig} ignored"))

        if summary.total_failed > 0:
            show_top_failures(summary, max_tests=8, max_details=4)
            show_agent_hints(summary)

        # Also dump JSON for agent consumption
        json_path = log_dir / f"test_run_{iteration:02d}_summary.json"
        json_path.write_text(
            json.dumps({
                "iteration": iteration,
                "passed": summary.total_passed,
                "failed": summary.total_failed,
                "ignored": summary.total_ignored,
                "failing_tests": [
                    {
                        "name": r.name,
                        "lua_file": r.lua_file,
                        "lua_passed": r.lua_passed,
                        "lua_total": r.lua_total,
                        "details": r.fail_details[:20],
                    }
                    for r in summary.failing
                ],
            }, indent=2),
            encoding="utf-8",
        )

        if not loop_mode:
            return 0 if summary.total_failed == 0 else 1

        if iteration >= max_iter:
            print(clr(RED, f"\n  Reached max iterations ({max_iter}). {summary.total_failed} tests still failing."))
            return 3

        print(clr(YELLOW, f"\n  Waiting {args.pause:.0f}s before next run (Ctrl+C to stop)..."))
        try:
            time.sleep(args.pause)
        except KeyboardInterrupt:
            print("\n  Aborted by user.")
            return 1


if __name__ == "__main__":
    sys.exit(main())
