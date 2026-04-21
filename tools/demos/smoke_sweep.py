#!/usr/bin/env python3
"""Smoke-sweep every playable project under content/games/ and every single-file
content/examples/*.lua.

For each target the tool runs the Lurek2D engine binary with the existing
`--screenshot` / `--screenshot-frames` flags, which capture a PNG from the GPU
read-back path and then exit cleanly. A run is graded:

* PASS     - process exited 0 AND the PNG file is present and non-empty.
* CRASH    - process exited non-zero.
* TIMEOUT  - process was killed because it exceeded the per-target wall clock.
* NO_IMAGE - process exited 0 but no PNG was produced.

Results are written to two files in the session work folder:

* <report>.json - one object per target with full stderr tail, exit code,
                  elapsed time, and a coarse error bucket.
* <report>.md   - human summary grouped by bucket.

The tool is stdlib-only (subprocess, json, pathlib, argparse) so it runs on any
Python 3.9+ without extra setup. It is safe to run against a repo where many
demos are broken: crashes are captured, not propagated.

Typical usage (PowerShell, from repo root):

    python tools/demos/smoke_sweep.py

Advanced:

    python tools/demos/smoke_sweep.py --frames 60 --timeout 20 --jobs 1 \
        --report work/smoke.json

The engine binary defaults to ``build/debug/lurek2d.exe`` on Windows (the
``build/debug/lurek2d`` layout elsewhere) - override with ``--binary`` if
a release build should be used instead.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Iterable

REPO_ROOT = Path(__file__).resolve().parents[2]

DEFAULT_FRAMES = 120  # ~2s at 60fps, matches user's mandate in phase 8.
DEFAULT_TIMEOUT = 30.0
DEFAULT_BINARY = REPO_ROOT / "build" / "debug" / (
    "lurek2d.exe" if os.name == "nt" else "lurek2d"
)
DEFAULT_REPORT = (
    REPO_ROOT / "work" / "engine-recovery-20260421" / "reports" / "smoke_results.json"
)


@dataclass
class Target:
    """One runnable unit (game project or single-file example)."""

    kind: str  # 'game' | 'example'
    label: str  # short id used in report, e.g. 'games/showcase/hello_world'
    path: Path  # arg passed to the engine (dir for games, .lua file for examples)
    screenshot: Path  # where the engine should write the PNG


@dataclass
class Result:
    label: str
    kind: str
    path: str
    screenshot: str
    exit_code: int | None
    elapsed_s: float
    produced_image: bool
    timed_out: bool
    bucket: str  # PASS | CRASH | TIMEOUT | NO_IMAGE
    error_head: str = ""  # first meaningful line of stderr/stdout
    stderr_tail: list[str] = field(default_factory=list)


# Regexes used to bucket crash reasons for the human-readable summary.
_ERROR_BUCKETS: list[tuple[str, re.Pattern[str]]] = [
    ("LUA_API_DRIFT", re.compile(r"attempt to call a (nil|table) value", re.I)),
    ("LUA_API_DRIFT", re.compile(r"bad argument #\d+", re.I)),
    ("LUA_API_MISSING", re.compile(r"attempt to index.*\bnil\b", re.I)),
    ("LUA_SYNTAX", re.compile(r"syntax error", re.I)),
    ("ASSET_MISSING", re.compile(r"(failed to load|no such file|cannot find)", re.I)),
    ("PANIC", re.compile(r"thread '.*' panicked", re.I)),
    ("WGPU", re.compile(r"(wgpu|surface|validation error)", re.I)),
]


def _bucket_from_stderr(lines: list[str]) -> tuple[str, str]:
    """Return (category, head_line) for the first interesting stderr line."""
    for ln in lines:
        stripped = ln.strip()
        if not stripped:
            continue
        for name, rx in _ERROR_BUCKETS:
            if rx.search(stripped):
                return name, stripped
    # fall back to first non-empty line
    for ln in lines:
        if ln.strip():
            return "UNKNOWN", ln.strip()
    return "UNKNOWN", ""


def discover(games_root: Path, examples_root: Path) -> list[Target]:
    """Enumerate game projects (content/games/<cat>/<demo>/main.lua) and
    single-file examples (content/examples/*.lua)."""
    out: list[Target] = []
    if games_root.is_dir():
        for main_lua in sorted(games_root.glob("*/*/main.lua")):
            project_dir = main_lua.parent
            rel = project_dir.relative_to(REPO_ROOT).as_posix()
            out.append(
                Target(
                    kind="game",
                    label=rel,
                    path=project_dir,
                    screenshot=project_dir / "screen.png",
                )
            )
    if examples_root.is_dir():
        for ex in sorted(examples_root.glob("*.lua")):
            rel = ex.relative_to(REPO_ROOT).as_posix()
            shot = ex.with_suffix(".png")
            out.append(
                Target(
                    kind="example",
                    label=rel,
                    path=ex,
                    screenshot=shot,
                )
            )
    return out


def run_target(binary: Path, target: Target, frames: int, timeout: float) -> Result:
    cmd = [
        str(binary),
        str(target.path),
        "--screenshot",
        str(target.screenshot),
        "--screenshot-frames",
        str(frames),
    ]
    start = time.monotonic()
    # Clear any stale screenshot so we don't misread an old file as PASS.
    if target.screenshot.exists():
        try:
            target.screenshot.unlink()
        except OSError:
            pass

    try:
        proc = subprocess.run(
            cmd,
            cwd=REPO_ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            errors="replace",
        )
        timed_out = False
        exit_code: int | None = proc.returncode
        stderr = proc.stderr or ""
        stdout = proc.stdout or ""
    except subprocess.TimeoutExpired as exc:
        timed_out = True
        exit_code = None
        stderr = exc.stderr or ""
        stdout = exc.stdout or ""
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")

    elapsed = time.monotonic() - start
    stderr_lines = stderr.splitlines()
    tail = stderr_lines[-15:] if stderr_lines else stdout.splitlines()[-15:]

    produced_image = target.screenshot.exists() and target.screenshot.stat().st_size > 0

    if timed_out:
        bucket = "TIMEOUT"
        head = f"timeout after {timeout:.1f}s"
    elif exit_code not in (0, None):
        bucket, head = _bucket_from_stderr(stderr_lines or stdout.splitlines())
        if bucket == "UNKNOWN":
            bucket = "CRASH"
        head = head or f"exit {exit_code}"
    elif not produced_image:
        bucket = "NO_IMAGE"
        head = "exited cleanly but no PNG written"
    else:
        bucket = "PASS"
        head = ""

    return Result(
        label=target.label,
        kind=target.kind,
        path=str(target.path),
        screenshot=str(target.screenshot),
        exit_code=exit_code,
        elapsed_s=round(elapsed, 3),
        produced_image=produced_image,
        timed_out=timed_out,
        bucket=bucket,
        error_head=head,
        stderr_tail=tail,
    )


def write_reports(results: list[Result], report_path: Path) -> None:
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(
        json.dumps([asdict(r) for r in results], indent=2), encoding="utf-8"
    )

    md_path = report_path.with_suffix(".md")
    buckets: dict[str, list[Result]] = {}
    for r in results:
        buckets.setdefault(r.bucket, []).append(r)

    lines: list[str] = []
    lines.append("# smoke_sweep results")
    lines.append("")
    lines.append(f"Total targets: **{len(results)}**")
    for name in ("PASS", "CRASH", "TIMEOUT", "NO_IMAGE"):
        lines.append(f"- {name}: {len(buckets.get(name, []))}")
    # sub-buckets (LUA_API_DRIFT, etc)
    sub_counts: dict[str, int] = {}
    for r in results:
        if r.bucket in {"PASS", "TIMEOUT", "NO_IMAGE"}:
            continue
        sub_counts[r.bucket] = sub_counts.get(r.bucket, 0) + 1
    if sub_counts:
        lines.append("")
        lines.append("## Crash buckets")
        for name, count in sorted(sub_counts.items(), key=lambda kv: -kv[1]):
            lines.append(f"- {name}: {count}")

    for bucket in ("CRASH", "LUA_API_DRIFT", "LUA_API_MISSING", "PANIC", "WGPU",
                   "ASSET_MISSING", "LUA_SYNTAX", "UNKNOWN", "TIMEOUT", "NO_IMAGE"):
        entries = buckets.get(bucket, [])
        if not entries:
            continue
        lines.append("")
        lines.append(f"## {bucket} ({len(entries)})")
        lines.append("")
        for r in sorted(entries, key=lambda r: r.label):
            head = r.error_head or "(no stderr captured)"
            lines.append(f"- `{r.label}` - exit={r.exit_code} elapsed={r.elapsed_s}s - {head}")
    md_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--binary", type=Path, default=DEFAULT_BINARY,
                   help=f"Engine binary (default {DEFAULT_BINARY})")
    p.add_argument("--games-root", type=Path, default=REPO_ROOT / "content" / "games")
    p.add_argument("--examples-root", type=Path, default=REPO_ROOT / "content" / "examples")
    p.add_argument("--frames", type=int, default=DEFAULT_FRAMES,
                   help=f"--screenshot-frames value passed to engine (default {DEFAULT_FRAMES})")
    p.add_argument("--timeout", type=float, default=DEFAULT_TIMEOUT,
                   help=f"Per-target wall-clock timeout in seconds (default {DEFAULT_TIMEOUT})")
    p.add_argument("--report", type=Path, default=DEFAULT_REPORT,
                   help=f"Output JSON report path (default {DEFAULT_REPORT})")
    p.add_argument("--only", type=str, default=None,
                   help="Run only targets whose label contains this substring")
    p.add_argument("--kind", choices=("game", "example", "all"), default="all")
    p.add_argument("--limit", type=int, default=0,
                   help="Run at most N targets (0 = all)")
    p.add_argument("--dry-run", action="store_true",
                   help="List targets and exit without running anything")
    return p.parse_args(argv)


def filter_targets(targets: list[Target], args: argparse.Namespace) -> list[Target]:
    out = targets
    if args.kind != "all":
        out = [t for t in out if t.kind == args.kind]
    if args.only:
        out = [t for t in out if args.only in t.label]
    if args.limit and args.limit > 0:
        out = out[: args.limit]
    return out


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if not args.binary.exists():
        print(f"ERROR: engine binary not found: {args.binary}", file=sys.stderr)
        print("Build first with `cargo build` or pass --binary.", file=sys.stderr)
        return 2

    targets = filter_targets(discover(args.games_root, args.examples_root), args)
    if not targets:
        print("No targets found.", file=sys.stderr)
        return 1

    print(f"Running {len(targets)} target(s) with frames={args.frames} timeout={args.timeout}s ...")
    if args.dry_run:
        for t in targets:
            print(f"  [{t.kind}] {t.label}")
        return 0

    results: list[Result] = []
    for i, t in enumerate(targets, 1):
        r = run_target(args.binary, t, args.frames, args.timeout)
        status = r.bucket
        print(f"[{i:3d}/{len(targets)}] {status:<9} {t.label}  ({r.elapsed_s:.1f}s)")
        if r.error_head and status != "PASS":
            print(f"           {r.error_head}")
        results.append(r)

    write_reports(results, args.report)
    pass_n = sum(1 for r in results if r.bucket == "PASS")
    print("")
    print(f"PASS {pass_n}/{len(results)}  -->  report: {args.report}")
    # non-zero exit if anything failed, so callers can gate on it
    return 0 if pass_n == len(results) else 1


if __name__ == "__main__":
    # Ensure stdout isn't buffered when piped (helps live log tailing).
    try:
        sys.stdout.reconfigure(line_buffering=True)  # type: ignore[attr-defined]
    except Exception:
        pass
    # shutil import exists only to validate Python version + future extension
    _ = shutil
    sys.exit(main())
