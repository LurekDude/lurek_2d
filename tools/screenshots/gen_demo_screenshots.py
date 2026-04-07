#!/usr/bin/env python3
"""
gen_demo_screenshots.py — Capture a screen.png for every Luna2D demo.

Usage:
    python tools/screenshots/gen_demo_screenshots.py [options]

Options:
    --binary PATH        Path to the luna2d binary (default: auto-detect build/release or build/debug)
    --delay SECS         Seconds to wait after game start before capturing (default: 1.5)
    --demo NAME          Only run the named demo (can be repeated)
    --overwrite          Overwrite existing screen.png files (default: skip)
    --timeout SECS       Kill the process after this many seconds if it hasn't quit (default: 15)
    --demos-dir PATH     Path to the demos directory (default: demos/)
    --rebuild            Run 'cargo build --release' before capturing
    --dry-run            Print what would run without executing

Each demo that has a main.lua will be launched with:
    luna2d <demo_dir> --screenshot=<abs_path_to_screen.png> --screenshot-delay=<delay>

The engine will render <delay> seconds of the game, save screen.png, and exit automatically.
"""

import argparse
import os
import platform
import subprocess
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def find_binary(repo_root: Path) -> Path:
    """Return the best available luna2d binary under build/."""
    candidates = [
        repo_root / "build" / "release" / ("luna2d.exe" if platform.system() == "Windows" else "luna2d"),
        repo_root / "build" / "debug"   / ("luna2d.exe" if platform.system() == "Windows" else "luna2d"),
    ]
    for c in candidates:
        if c.exists():
            return c
    raise FileNotFoundError(
        "Could not find luna2d binary. Build the project first with:\n"
        "  cargo build --release\n"
        "or pass --binary <path>."
    )


def rebuild(repo_root: Path) -> None:
    print("[build] Running: cargo build --release")
    result = subprocess.run(
        ["cargo", "build", "--release"],
        cwd=repo_root,
        timeout=600,
    )
    if result.returncode != 0:
        print("[build] FAILED — aborting.", file=sys.stderr)
        sys.exit(1)
    print("[build] OK")


def capture_demo(
    binary: Path,
    demo_dir: Path,
    delay: float,
    timeout: float,
    overwrite: bool,
    dry_run: bool,
) -> str:
    """
    Run the demo and capture screen.png.
    Returns 'ok', 'skip', 'timeout', or 'error'.
    """
    screen_path = demo_dir / "screen.png"
    if screen_path.exists() and not overwrite:
        return "skip"

    cmd = [
        str(binary),
        str(demo_dir),
        f"--screenshot={screen_path.resolve()}",
        f"--screenshot-delay={delay}",
    ]

    if dry_run:
        print(f"[dry-run] {' '.join(cmd)}")
        return "ok"

    try:
        result = subprocess.run(
            cmd,
            timeout=timeout,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.TimeoutExpired:
        return "timeout"
    except Exception as exc:
        print(f"  [exception] {exc}")
        return "error"

    if screen_path.exists():
        return "ok"

    # Process exited but no file — log stderr hint
    stderr_tail = (result.stderr or b"").decode(errors="replace")[-300:]
    if stderr_tail:
        print(f"  [stderr] {stderr_tail.strip()}")
    return "error"


def main() -> None:
    parser = argparse.ArgumentParser(description="Capture screen.png for every Luna2D demo.")
    parser.add_argument("--binary", default=None, help="Path to the luna2d binary")
    parser.add_argument("--delay", type=float, default=1.5, help="Screenshot delay in seconds")
    parser.add_argument("--demo", action="append", dest="demos", metavar="NAME",
                        help="Only process this demo (can repeat)")
    parser.add_argument("--overwrite", action="store_true", help="Overwrite existing screen.png")
    parser.add_argument("--timeout", type=float, default=15.0,
                        help="Kill the process after this many seconds")
    parser.add_argument("--demos-dir", default=None, help="Path to the demos directory")
    parser.add_argument("--rebuild", action="store_true", help="cargo build --release before capturing")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without running")
    args = parser.parse_args()

    repo_root = REPO_ROOT

    if args.rebuild:
        rebuild(repo_root)

    binary = Path(args.binary) if args.binary else find_binary(repo_root)
    if not binary.exists():
        print(f"ERROR: Binary not found: {binary}", file=sys.stderr)
        sys.exit(1)
    print(f"[binary] {binary}")

    demos_root = Path(args.demos_dir) if args.demos_dir else repo_root / "demos"
    if not demos_root.is_dir():
        print(f"ERROR: demos directory not found: {demos_root}", file=sys.stderr)
        sys.exit(1)

    # Collect demo directories that have a main.lua
    all_demos = sorted(
        d for d in demos_root.iterdir()
        if d.is_dir() and (d / "main.lua").exists()
    )

    if args.demos:
        requested = set(args.demos)
        all_demos = [d for d in all_demos if d.name in requested]
        missing = requested - {d.name for d in all_demos}
        if missing:
            print(f"WARNING: Demos not found: {', '.join(sorted(missing))}", file=sys.stderr)

    if not all_demos:
        print("No demos to process.", file=sys.stderr)
        sys.exit(1)

    print(f"[demos] {len(all_demos)} demos to process")
    print()

    stats = {"ok": 0, "skip": 0, "timeout": 0, "error": 0}
    errors = []

    for i, demo_dir in enumerate(all_demos, 1):
        label = demo_dir.name
        prefix = f"[{i:3d}/{len(all_demos)}] {label:<30}"
        t0 = time.monotonic()
        status = capture_demo(
            binary=binary,
            demo_dir=demo_dir,
            delay=args.delay,
            timeout=args.timeout,
            overwrite=args.overwrite,
            dry_run=args.dry_run,
        )
        elapsed = time.monotonic() - t0
        stats[status] += 1

        if status == "ok":
            size_kb = ""
            screen = demo_dir / "screen.png"
            if screen.exists():
                size_kb = f"  {screen.stat().st_size // 1024}KB"
            print(f"{prefix}  OK   ({elapsed:.1f}s){size_kb}")
        elif status == "skip":
            print(f"{prefix}  SKIP (screen.png exists, use --overwrite)")
        elif status == "timeout":
            print(f"{prefix}  TIMEOUT ({elapsed:.0f}s)")
            errors.append(label)
        else:
            print(f"{prefix}  ERROR")
            errors.append(label)

    print()
    print(f"Results: {stats['ok']} ok  |  {stats['skip']} skipped  |  "
          f"{stats['timeout']} timeout  |  {stats['error']} error")

    if errors:
        print(f"\nFailed demos ({len(errors)}):")
        for name in errors:
            print(f"  {name}")
        sys.exit(1)


if __name__ == "__main__":
    main()
