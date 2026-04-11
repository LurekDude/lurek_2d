#!/usr/bin/env python3
"""
gen_demo_screenshots.py — Capture a screen.png for every Lurek2D demo.

Usage:
    python tools/screenshots/gen_demo_screenshots.py [options]

Options:
    --binary PATH          Path to the lurek2d binary (default: auto-detect build/release / build/debug)
    --frames N             Rendered game frames to wait before capturing (default: 3, fastest)
    --demo NAME            Only run the named demo (can be repeated)
    --overwrite            Overwrite existing screen.png files (default: skip)
    --timeout SECS         Kill the process after this many seconds if it hasn't quit (default: 20)
    --demos-dir PATH       Path to the demos directory (default: content/demos/)
    --rebuild              Run 'cargo build --release' before capturing
    --dry-run              Print what would run without executing
    --log PATH             Write per-demo logs to this folder (default: work/demo-screenshots/logs/)
    --no-log               Disable per-demo log files

Each demo that has a main.lua will be launched with:
    lurek2d <demo_dir> --screenshot=<abs_path> --screenshot-frames=<n>

The engine renders N frames of the game, saves screen.png, and exits automatically.
RUST_LOG=lurek2d=debug is set so errors surface in the log.
"""

import argparse
import os
import platform
import subprocess
import sys
import time
import json
from pathlib import Path
from datetime import datetime

REPO_ROOT = Path(__file__).resolve().parent.parent.parent


def find_binary(repo_root: Path) -> Path:
    candidates = [
        repo_root / "build" / "release" / ("lurek2d.exe" if platform.system() == "Windows" else "lurek2d"),
        repo_root / "build" / "debug"   / ("lurek2d.exe" if platform.system() == "Windows" else "lurek2d"),
    ]
    for c in candidates:
        if c.exists():
            return c
    raise FileNotFoundError(
        "Could not find lurek2d binary. Build first with:\n"
        "  cargo build --release\n"
        "or pass --binary <path>."
    )


def rebuild(repo_root: Path) -> None:
    print("[build] cargo build --release ...")
    result = subprocess.run(["cargo", "build", "--release"], cwd=repo_root, timeout=600)
    if result.returncode != 0:
        print("[build] FAILED — aborting.", file=sys.stderr)
        sys.exit(1)
    print("[build] OK")


def capture_demo(
    binary: Path,
    demo_dir: Path,
    frames: int,
    timeout: float,
    overwrite: bool,
    dry_run: bool,
    log_dir,
) -> tuple:
    """
    Run the demo and capture screen.png.
    Returns (status, error_detail) where status is 'ok', 'skip', 'timeout', or 'error'.
    """
    screen_path = demo_dir / "screen.png"
    if screen_path.exists() and not overwrite:
        return "skip", ""

    cmd = [
        str(binary),
        str(demo_dir.resolve()),
        "--screenshot=" + str(screen_path.resolve()),
        "--screenshot-frames=" + str(frames),
    ]

    if dry_run:
        print(f"[dry-run] {' '.join(cmd)}")
        return "ok", ""

    env = {**os.environ, "RUST_LOG": "lurek2d=debug"}

    try:
        result = subprocess.run(
            cmd,
            timeout=timeout,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )
    except subprocess.TimeoutExpired as exc:
        # Save whatever output was produced before the timeout.
        combined = (exc.stdout or b"") + (exc.stderr or b"")
        log_text = combined.decode(errors="replace")
        if log_dir is not None:
            log_dir.mkdir(parents=True, exist_ok=True)
            (log_dir / "{}.log".format(demo_dir.name)).write_text(log_text, encoding="utf-8")
        return "timeout", "Process did not exit within {}s".format(timeout)
    except Exception as exc:
        return "error", str(exc)

    combined = (result.stdout or b"") + (result.stderr or b"")
    log_text = combined.decode(errors="replace")
    if log_dir is not None:
        log_dir.mkdir(parents=True, exist_ok=True)
        (log_dir / "{}.log".format(demo_dir.name)).write_text(log_text, encoding="utf-8")

    if screen_path.exists():
        return "ok", ""

    error_lines = [
        line for line in log_text.splitlines()
        if any(kw in line.lower() for kw in ("error", "panic", "lua", "failed", "not found"))
    ]
    detail = "\n".join(error_lines[-8:]) if error_lines else log_text[-400:].strip()
    return "error", detail


def main():
    parser = argparse.ArgumentParser(description="Capture screen.png for every Lurek2D demo.")
    parser.add_argument("--binary",    default=None)
    parser.add_argument("--frames",    type=int, default=3,
                        help="Rendered frames before screenshot (default: 3)")
    parser.add_argument("--demo",      action="append", dest="demos", metavar="NAME")
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--timeout",   type=float, default=20.0)
    parser.add_argument("--demos-dir", default=None)
    parser.add_argument("--rebuild",   action="store_true")
    parser.add_argument("--dry-run",   action="store_true")
    parser.add_argument("--log", default=str(REPO_ROOT / "work" / "demo-screenshots" / "logs"))
    parser.add_argument("--no-log",    action="store_true")
    args = parser.parse_args()

    repo_root = REPO_ROOT

    if args.rebuild:
        rebuild(repo_root)

    binary = Path(args.binary) if args.binary else find_binary(repo_root)
    if not binary.exists():
        print("ERROR: Binary not found: {}".format(binary), file=sys.stderr)
        sys.exit(1)
    print("[binary] {}".format(binary))

    demos_root = Path(args.demos_dir) if args.demos_dir else repo_root / "content" / "demos"
    if not demos_root.is_dir():
        print("ERROR: demos directory not found: {}".format(demos_root), file=sys.stderr)
        sys.exit(1)

    all_demos = sorted(
        d for d in demos_root.iterdir()
        if d.is_dir() and (d / "main.lua").exists()
    )

    if args.demos:
        requested = set(args.demos)
        all_demos = [d for d in all_demos if d.name in requested]
        missing = requested - {d.name for d in all_demos}
        if missing:
            print("WARNING: Demos not found: {}".format(", ".join(sorted(missing))), file=sys.stderr)

    if not all_demos:
        print("No demos to process.", file=sys.stderr)
        sys.exit(1)

    log_dir = None
    if not args.no_log and not args.dry_run:
        log_dir = Path(args.log)
        log_dir.mkdir(parents=True, exist_ok=True)

    print("[demos]  {} to process  |  frames={}  |  timeout={}s".format(
        len(all_demos), args.frames, args.timeout))
    print()

    stats = {"ok": 0, "skip": 0, "timeout": 0, "error": 0}
    failures = []

    for i, demo_dir in enumerate(all_demos, 1):
        label = demo_dir.name
        prefix = "[{:3d}/{}] {:<32}".format(i, len(all_demos), label)
        t0 = time.monotonic()
        status, detail = capture_demo(
            binary=binary,
            demo_dir=demo_dir,
            frames=args.frames,
            timeout=args.timeout,
            overwrite=args.overwrite,
            dry_run=args.dry_run,
            log_dir=log_dir,
        )
        elapsed = time.monotonic() - t0
        stats[status] += 1

        if status == "ok":
            screen = demo_dir / "screen.png"
            size_str = "  {}KB".format(screen.stat().st_size // 1024) if screen.exists() else ""
            print("{}  OK      ({:.1f}s){}".format(prefix, elapsed, size_str))
        elif status == "skip":
            print("{}  SKIP    (exists, use --overwrite)".format(prefix))
        elif status == "timeout":
            print("{}  TIMEOUT ({:.0f}s)".format(prefix, elapsed))
            failures.append({"name": label, "status": "timeout", "detail": detail})
        else:
            first_err = (detail.split("\n")[0][:100] if detail else "")
            print("{}  ERROR   {}".format(prefix, first_err))
            failures.append({"name": label, "status": "error", "detail": detail})

    print()
    print("Results: {} ok  |  {} skipped  |  {} timeout  |  {} error".format(
        stats["ok"], stats["skip"], stats["timeout"], stats["error"]))

    if failures:
        summary_path = (log_dir or Path(".")) / "failures.json"
        summary_path.write_text(
            json.dumps({"timestamp": datetime.utcnow().isoformat(), "failures": failures}, indent=2),
            encoding="utf-8",
        )
        print("\nFailure summary written to: {}".format(summary_path))
        print("\nFailed demos ({}):\n".format(len(failures)))
        for f in failures:
            print("  [{}] {}".format(f["status"], f["name"]))
            if f["detail"]:
                for line in f["detail"].split("\n")[:4]:
                    print("         {}".format(line))
        sys.exit(1)


if __name__ == "__main__":
    main()

