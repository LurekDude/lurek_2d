#!/usr/bin/env python3
"""
gen_demo_screenshots.py — Capture a screen.png for every Lurek2D game demo.

Scans ``content/games/<category>/<name>/`` for any folder containing ``main.lua``
and launches the engine binary in screenshot mode.  Up to ``--workers`` (default 6)
games are captured in parallel, each window placed in its own grid slot so they
do not overlap on the desktop.

Usage:
    python tools/demos/gen_demo_screenshots.py [options]

Options:
    --binary PATH            Path to the lurek2d binary (auto-detects build/release or build/debug)
    --games-dir PATH         Root games directory (default: content/games/)
    --screenshot-time SECS   Wall-clock seconds after game start before capture (default: 2.0)
    --workers N              Parallel capture slots (default: 6)
    --slot-width PX          Window width per slot in pixels (default: 640)
    --slot-height PX         Window height per slot in pixels (default: 480)
    --demo NAME              Only capture this named demo; can repeat
    --overwrite              Overwrite existing screen.png files (default: skip)
    --timeout SECS           Kill process if it has not exited within this many seconds (default: 30)
    --rebuild                Run 'cargo build --release' before capturing
    --dry-run                Print what would run; do not execute
    --log PATH               Write per-demo logs here (default: work/demo-screenshots/logs/)
    --no-log                 Disable per-demo log files

Each demo is launched as:
    lurek2d <demo_dir> --screenshot=<abs_path> --screenshot-time=<t>
                       --window-x=<x> --window-y=<y>

The engine waits ``screenshot_time`` wall-clock seconds, saves screen.png, and exits.
RUST_LOG=lurek2d=error is set to suppress verbose output during batch capture.
"""

import argparse
import os
import platform
import queue
import subprocess
import sys
import threading
import time
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from datetime import datetime, timezone

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

# Grid layout: slots numbered left-to-right, top-to-bottom.
# slot_index -> (col, row), column count taken from --workers / 3 rounded up.
_GRID_COLS = 3


def _slot_position(slot_index: int, slot_width: int, slot_height: int) -> tuple:
    """Return (x, y) screen position for the given 0-based slot index."""
    col = slot_index % _GRID_COLS
    row = slot_index // _GRID_COLS
    return col * slot_width, row * slot_height


def find_binary(repo_root: Path) -> Path:
    """Auto-detect the lurek2d binary; prefers release over debug."""
    ext = ".exe" if platform.system() == "Windows" else ""
    candidates = [
        repo_root / "build" / "release" / f"lurek2d{ext}",
        repo_root / "build" / "debug"   / f"lurek2d{ext}",
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
    """Run a release build and abort on failure."""
    print("[build] cargo build --release ...")
    result = subprocess.run(["cargo", "build", "--release"], cwd=repo_root, timeout=600)
    if result.returncode != 0:
        print("[build] FAILED — aborting.", file=sys.stderr)
        sys.exit(1)
    print("[build] OK")


def discover_demos(games_root: Path, filter_names: list) -> list:
    """
    Walk ``games_root/<category>/<name>/`` and return a sorted list of demo
    directories that contain a ``main.lua``.

    If ``filter_names`` is non-empty only demos whose basename is in the set
    are returned.
    """
    demos = []
    if not games_root.is_dir():
        return demos
    for category_dir in sorted(games_root.iterdir()):
        if not category_dir.is_dir():
            continue
        for demo_dir in sorted(category_dir.iterdir()):
            if demo_dir.is_dir() and (demo_dir / "main.lua").exists():
                demos.append(demo_dir)

    if filter_names:
        wanted = set(filter_names)
        demos = [d for d in demos if d.name in wanted]
    return demos


def capture_demo(
    *,
    binary: Path,
    demo_dir: Path,
    screenshot_time: float,
    slot_index: int,
    slot_width: int,
    slot_height: int,
    timeout: float,
    overwrite: bool,
    dry_run: bool,
    log_dir,
    print_lock: threading.Lock,
    index: int,
    total: int,
) -> tuple:
    """
    Launch the engine for one demo and wait for it to capture screen.png.

    Returns ``(status, error_detail)`` where *status* is one of
    ``'ok'``, ``'skip'``, ``'timeout'``, or ``'error'``.
    """
    screen_path = demo_dir / "screen.png"
    label = demo_dir.name
    prefix = "[{:3d}/{}] {:<32}".format(index, total, label)

    if screen_path.exists() and not overwrite:
        with print_lock:
            print("{}  SKIP    (exists, use --overwrite)".format(prefix), flush=True)
        return "skip", ""

    wx, wy = _slot_position(slot_index, slot_width, slot_height)
    cmd = [
        str(binary),
        str(demo_dir.resolve()),
        "--screenshot="       + str(screen_path.resolve()),
        "--screenshot-time="  + str(screenshot_time),
        "--window-x="         + str(wx),
        "--window-y="         + str(wy),
    ]

    if dry_run:
        with print_lock:
            print("[dry-run] {}".format(" ".join(cmd)), flush=True)
        return "ok", ""

    env = {**os.environ, "RUST_LOG": "lurek2d=error"}

    t0 = time.monotonic()
    try:
        result = subprocess.run(
            cmd,
            timeout=timeout,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            env=env,
        )
    except subprocess.TimeoutExpired as exc:
        combined = (exc.stdout or b"") + (exc.stderr or b"")
        log_text = combined.decode(errors="replace")
        _write_log(log_dir, label, log_text)
        elapsed = time.monotonic() - t0
        with print_lock:
            print("{}  TIMEOUT ({:.0f}s)".format(prefix, elapsed), flush=True)
        return "timeout", "Process did not exit within {}s".format(timeout)
    except Exception as exc:
        with print_lock:
            print("{}  ERROR   {}".format(prefix, str(exc)[:80]), flush=True)
        return "error", str(exc)

    elapsed = time.monotonic() - t0
    combined = (result.stdout or b"") + (result.stderr or b"")
    log_text = combined.decode(errors="replace")
    _write_log(log_dir, label, log_text)

    if screen_path.exists():
        size_kb = screen_path.stat().st_size // 1024
        with print_lock:
            print("{}  OK      ({:.1f}s)  {}KB".format(prefix, elapsed, size_kb), flush=True)
        return "ok", ""

    # Screenshot file was not created — extract useful error lines.
    error_lines = [
        line for line in log_text.splitlines()
        if any(kw in line.lower() for kw in ("error", "panic", "lua", "failed", "not found"))
    ]
    detail = "\n".join(error_lines[-8:]) if error_lines else log_text[-400:].strip()
    first_err = (detail.split("\n")[0][:100] if detail else "no output")
    with print_lock:
        print("{}  ERROR   {}".format(prefix, first_err), flush=True)
    return "error", detail


def _write_log(log_dir, name: str, text: str) -> None:
    """Write per-demo log if a log directory is configured."""
    if log_dir is None:
        return
    log_dir.mkdir(parents=True, exist_ok=True)
    (log_dir / "{}.log".format(name)).write_text(text, encoding="utf-8")


def main():  # noqa: C901 — intentional length; argument parsing + orchestration
    parser = argparse.ArgumentParser(
        description="Capture screen.png for every Lurek2D game demo.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--binary",          default=None,
                        help="Path to the lurek2d binary (auto-detected if omitted)")
    parser.add_argument("--games-dir",       default=None,
                        help="Root game directory (default: content/games/)")
    parser.add_argument("--screenshot-time", type=float, default=2.0,
                        help="Wall-clock seconds after game start before capturing (default: 2.0)")
    parser.add_argument("--workers",         type=int, default=6,
                        help="Number of parallel capture slots (default: 6)")
    parser.add_argument("--slot-width",      type=int, default=640,
                        help="Window width per slot in pixels (default: 640)")
    parser.add_argument("--slot-height",     type=int, default=480,
                        help="Window height per slot in pixels (default: 480)")
    parser.add_argument("--demo",            action="append", dest="demos", metavar="NAME",
                        help="Capture only this demo name (repeatable)")
    parser.add_argument("--overwrite",       action="store_true",
                        help="Overwrite existing screen.png files")
    parser.add_argument("--timeout",         type=float, default=30.0,
                        help="Kill process after this many seconds if it has not exited (default: 30)")
    parser.add_argument("--rebuild",         action="store_true",
                        help="Run 'cargo build --release' before capturing")
    parser.add_argument("--dry-run",         action="store_true",
                        help="Print commands without executing")
    parser.add_argument("--log",             default=str(REPO_ROOT / "work" / "demo-screenshots" / "logs"),
                        help="Folder for per-demo log files")
    parser.add_argument("--no-log",          action="store_true",
                        help="Disable per-demo log files")
    args = parser.parse_args()

    repo_root = REPO_ROOT

    if args.rebuild:
        rebuild(repo_root)

    binary = Path(args.binary) if args.binary else find_binary(repo_root)
    if not binary.exists():
        print("ERROR: Binary not found: {}".format(binary), file=sys.stderr)
        sys.exit(1)
    print("[binary] {}".format(binary))

    games_root = Path(args.games_dir) if args.games_dir else repo_root / "content" / "games"
    all_demos = discover_demos(games_root, args.demos or [])

    if args.demos:
        missing = set(args.demos) - {d.name for d in all_demos}
        if missing:
            print("WARNING: Demos not found: {}".format(", ".join(sorted(missing))), file=sys.stderr)

    if not all_demos:
        print("No demos found under: {}".format(games_root), file=sys.stderr)
        sys.exit(1)

    log_dir = None
    if not args.no_log and not args.dry_run:
        log_dir = Path(args.log)
        log_dir.mkdir(parents=True, exist_ok=True)

    workers = max(1, args.workers)
    print(
        "[demos]  {:d} to process  |  workers={:d}  |  screenshot-time={:.1f}s  |  timeout={:.0f}s".format(
            len(all_demos), workers, args.screenshot_time, args.timeout
        )
    )
    print(
        "[layout] {:d} cols x {:d} rows  |  slot {}x{}px".format(
            _GRID_COLS, (workers + _GRID_COLS - 1) // _GRID_COLS,
            args.slot_width, args.slot_height,
        )
    )
    print()

    # Slot pool: workers slots numbered 0..workers-1.  A slot is returned to
    # the pool as soon as its demo finishes, so the next queued demo can reuse it.
    slot_pool: queue.SimpleQueue = queue.SimpleQueue()
    for i in range(workers):
        slot_pool.put(i)

    print_lock = threading.Lock()
    stats = {"ok": 0, "skip": 0, "timeout": 0, "error": 0}
    failures = []
    stats_lock = threading.Lock()

    def run_one(index_demo):
        index, demo_dir = index_demo
        slot = slot_pool.get()
        try:
            status, detail = capture_demo(
                binary=binary,
                demo_dir=demo_dir,
                screenshot_time=args.screenshot_time,
                slot_index=slot,
                slot_width=args.slot_width,
                slot_height=args.slot_height,
                timeout=args.timeout,
                overwrite=args.overwrite,
                dry_run=args.dry_run,
                log_dir=log_dir,
                print_lock=print_lock,
                index=index,
                total=len(all_demos),
            )
        finally:
            slot_pool.put(slot)
        return demo_dir.name, status, detail

    indexed = list(enumerate(all_demos, 1))

    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {executor.submit(run_one, item): item for item in indexed}
        for future in as_completed(futures):
            name, status, detail = future.result()
            with stats_lock:
                stats[status] += 1
                if status in ("timeout", "error"):
                    failures.append({"name": name, "status": status, "detail": detail})

    print()
    print("Results: {} ok  |  {} skipped  |  {} timeout  |  {} error".format(
        stats["ok"], stats["skip"], stats["timeout"], stats["error"]))

    if failures:
        failures.sort(key=lambda f: f["name"])
        summary_path = (log_dir or Path(".")) / "failures.json"
        summary_path.write_text(
            json.dumps(
                {"timestamp": datetime.now(timezone.utc).isoformat(), "failures": failures},
                indent=2,
            ),
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

