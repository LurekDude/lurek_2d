#!/usr/bin/env python3
"""Repository-owned cargo orchestration for build, run, test, lint, fmt, and doc.

This wrapper gives VS Code tasks, packaging scripts, and the first-party VS Code
extension one stable surface for cargo-backed operations, while still allowing
bounded process-level parallelism for multi-target Rust test runs.

Examples:
    python tools/dev/parallel_cargo.py build debug
    python tools/dev/parallel_cargo.py check
    python tools/dev/parallel_cargo.py run debug -- content/games/showcase/hello_world
    python tools/dev/parallel_cargo.py test rust --warm-build
    python tools/dev/parallel_cargo.py test target math_tests --nocapture
    python tools/dev/parallel_cargo.py clippy --deny-warnings
    python tools/dev/parallel_cargo.py fmt check
    python tools/dev/parallel_cargo.py doc --open --no-deps
"""

from __future__ import annotations

import argparse
import math
import os
import shlex
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Sequence

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - Python 3.11+ provides tomllib.
    tomllib = None


ROOT = Path(__file__).resolve().parents[2]
CARGO_TOML = ROOT / "Cargo.toml"
TESTS_DIR = ROOT / "tests"


@dataclass(frozen=True)
class CommandResult:
    label: str
    command: tuple[str, ...]
    returncode: int
    duration_s: float
    output: str = ""
    dry_run: bool = False


def logical_cpu_count() -> int:
    return max(1, os.cpu_count() or 1)


def stable_unique(items: Iterable[str]) -> list[str]:
    seen: set[str] = set()
    unique: list[str] = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        unique.append(item)
    return unique


def shell_join(command: Sequence[str]) -> str:
    if hasattr(shlex, "join"):
        return shlex.join(command)
    return " ".join(shlex.quote(part) for part in command)


def default_jobs(value: int | None) -> int:
    return value or logical_cpu_count()


def parse_cargo_test_targets() -> list[str]:
    if tomllib is not None:
        with CARGO_TOML.open("rb") as handle:
            data = tomllib.load(handle)
        test_tables = data.get("test", [])
        if isinstance(test_tables, list):
            return [
                str(table["name"])
                for table in test_tables
                if isinstance(table, dict) and isinstance(table.get("name"), str)
            ]

    names: list[str] = []
    current_name: str | None = None
    inside_test_block = False

    for raw_line in CARGO_TOML.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if line == "[[test]]":
            if current_name is not None:
                names.append(current_name)
            current_name = None
            inside_test_block = True
            continue
        if line.startswith("[[") and line.endswith("]]"):
            if inside_test_block and current_name is not None:
                names.append(current_name)
            current_name = None
            inside_test_block = False
            continue
        if not inside_test_block or not line.startswith("name"):
            continue
        _, _, value = line.partition("=")
        current_name = value.strip().strip('"')

    if inside_test_block and current_name is not None:
        names.append(current_name)

    return names


def discover_top_level_test_targets() -> list[str]:
    if not TESTS_DIR.exists():
        return []
    return sorted(path.stem for path in TESTS_DIR.glob("*.rs"))


def discover_rust_test_targets() -> list[str]:
    explicit_targets = parse_cargo_test_targets()
    top_level_targets = discover_top_level_test_targets()
    targets = stable_unique(explicit_targets + top_level_targets)
    return [target for target in targets if target != "lua_tests"]


def default_outer_jobs(cpu_count: int, target_count: int) -> int:
    if target_count <= 0:
        return 1
    capped_parallelism = min(8, math.ceil(cpu_count / 2))
    return max(1, min(target_count, capped_parallelism))


def default_inner_test_threads(cpu_count: int, outer_jobs: int) -> int:
    return max(1, cpu_count // max(1, outer_jobs))


def add_verbose_flag(command: list[str], verbose: bool) -> list[str]:
    if verbose:
        command.append("-v")
    return command


def add_jobs_flag(command: list[str], jobs: int | None) -> list[str]:
    if jobs is not None:
        command.extend(["-j", str(jobs)])
    return command


def add_test_runner_flags(
    command: list[str],
    *,
    test_threads: int | None = None,
    nocapture: bool = False,
) -> list[str]:
    tail: list[str] = []
    if test_threads is not None:
        tail.extend(["--test-threads", str(test_threads)])
    if nocapture:
        tail.append("--nocapture")
    if tail:
        command.append("--")
        command.extend(tail)
    return command


def single_command_result(label: str, command: Sequence[str], dry_run: bool) -> CommandResult:
    command_tuple = tuple(command)
    print(f"[{label}] {shell_join(command_tuple)}")

    if dry_run:
        return CommandResult(label, command_tuple, 0, 0.0, dry_run=True)

    started = time.perf_counter()
    completed = subprocess.run(command_tuple, cwd=ROOT)
    duration_s = time.perf_counter() - started
    return CommandResult(label, command_tuple, completed.returncode, duration_s)


def captured_command_result(label: str, command: Sequence[str], dry_run: bool) -> CommandResult:
    command_tuple = tuple(command)
    print(f"[{label}] {shell_join(command_tuple)}")

    if dry_run:
        return CommandResult(label, command_tuple, 0, 0.0, dry_run=True)

    started = time.perf_counter()
    completed = subprocess.run(
        command_tuple,
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    duration_s = time.perf_counter() - started
    combined_output = "".join(part for part in (completed.stdout, completed.stderr) if part)
    return CommandResult(label, command_tuple, completed.returncode, duration_s, combined_output)


def print_failure_tail(result: CommandResult, tail_lines: int) -> None:
    if not result.output.strip():
        return

    lines = result.output.rstrip().splitlines()
    excerpt = lines[-tail_lines:]
    print(f"--- {result.label} failure tail ({len(excerpt)} lines) ---")
    for line in excerpt:
        print(line)
    print(f"--- end {result.label} failure tail ---")


def print_summary(results: Sequence[CommandResult]) -> None:
    passed = 0
    failed = 0
    dry_runs = 0

    print("\nSummary:")
    for result in results:
        if result.dry_run:
            dry_runs += 1
            status = "DRY-RUN"
        elif result.returncode == 0:
            passed += 1
            status = "PASS"
        else:
            failed += 1
            status = "FAIL"

        print(
            f"  {status:<7} {result.label:<24} "
            f"{result.duration_s:>6.1f}s  {shell_join(result.command)}"
        )

    print(
        f"Totals: {passed} passed, {failed} failed, {dry_runs} dry-run, {len(results)} total"
    )


def build_mode_command(target: str, jobs: int, verbose: bool) -> list[str]:
    command = ["cargo", "build"]
    if target == "release":
        command.append("--release")
    elif target == "dist":
        command.extend(["--profile", "dist"])
    add_verbose_flag(command, verbose)
    add_jobs_flag(command, jobs)
    return command


def check_command(jobs: int, verbose: bool) -> list[str]:
    command = ["cargo", "check"]
    add_verbose_flag(command, verbose)
    add_jobs_flag(command, jobs)
    return command


def run_command(target: str, jobs: int, verbose: bool, run_args: Sequence[str]) -> list[str]:
    command = ["cargo", "run", "--bin", "lurek2d"]
    if target == "release":
        command.append("--release")
    elif target == "dist":
        command.extend(["--profile", "dist"])
    add_verbose_flag(command, verbose)
    add_jobs_flag(command, jobs)
    if run_args:
        command.append("--")
        command.extend(run_args)
    return command


def lua_test_command(jobs: int, verbose: bool, nocapture: bool) -> list[str]:
    command = ["cargo", "test", "--test", "lua_tests"]
    add_verbose_flag(command, verbose)
    add_jobs_flag(command, jobs)
    add_test_runner_flags(command, test_threads=jobs, nocapture=nocapture)
    return command


def targeted_test_command(
    target: str,
    jobs: int,
    test_threads: int | None,
    verbose: bool,
    nocapture: bool,
) -> list[str]:
    command = ["cargo", "test", "--test", target]
    add_verbose_flag(command, verbose)
    add_jobs_flag(command, jobs)
    add_test_runner_flags(command, test_threads=test_threads or jobs, nocapture=nocapture)
    return command


def rust_test_command(target: str, test_threads: int, verbose: bool, nocapture: bool) -> list[str]:
    command = ["cargo", "test", "--test", target]
    add_verbose_flag(command, verbose)
    add_jobs_flag(command, 1)
    add_test_runner_flags(command, test_threads=test_threads, nocapture=nocapture)
    return command


def clippy_command(jobs: int, verbose: bool, deny_warnings: bool) -> list[str]:
    command = ["cargo", "clippy"]
    add_verbose_flag(command, verbose)
    add_jobs_flag(command, jobs)
    if deny_warnings:
        command.extend(["--", "-D", "warnings"])
    return command


def fmt_command(check_only: bool) -> list[str]:
    command = ["cargo", "fmt"]
    if check_only:
        command.append("--check")
    return command


def doc_command(jobs: int, verbose: bool, open_docs: bool, no_deps: bool) -> list[str]:
    command = ["cargo", "doc"]
    add_verbose_flag(command, verbose)
    add_jobs_flag(command, jobs)
    if open_docs:
        command.append("--open")
    if no_deps:
        command.append("--no-deps")
    return command


def run_single(label: str, command: Sequence[str], dry_run: bool) -> int:
    result = single_command_result(label, command, dry_run)
    print_summary([result])
    return 0 if result.returncode == 0 else 1


def run_sequence(steps: Sequence[tuple[str, Sequence[str]]], dry_run: bool) -> tuple[int, list[CommandResult]]:
    results: list[CommandResult] = []
    for label, command in steps:
        result = single_command_result(label, command, dry_run)
        results.append(result)
        if not dry_run and result.returncode != 0:
            break
    print_summary(results)
    return (0 if all(result.returncode == 0 for result in results if not result.dry_run) else 1, results)


def run_build(args: argparse.Namespace) -> int:
    jobs = default_jobs(args.jobs)
    command = build_mode_command(args.profile, jobs, args.verbose)
    return run_single(f"build:{args.profile}", command, args.dry_run)


def run_check(args: argparse.Namespace) -> int:
    jobs = default_jobs(args.jobs)
    command = check_command(jobs, args.verbose)
    return run_single("check", command, args.dry_run)


def run_run(args: argparse.Namespace) -> int:
    jobs = default_jobs(args.jobs)
    command = run_command(args.profile, jobs, args.verbose, args.run_args)
    return run_single(f"run:{args.profile}", command, args.dry_run)


def run_test_lua(args: argparse.Namespace) -> int:
    jobs = default_jobs(args.jobs)
    command = lua_test_command(jobs, args.verbose, args.nocapture)
    return run_single("test:lua", command, args.dry_run)


def run_test_target(args: argparse.Namespace) -> int:
    jobs = default_jobs(args.jobs)
    command = targeted_test_command(
        args.target_name,
        jobs,
        args.test_threads,
        args.verbose,
        args.nocapture,
    )
    return run_single(f"test:{args.target_name}", command, args.dry_run)


def run_test_all(args: argparse.Namespace) -> int:
    cpu_count = logical_cpu_count()
    jobs = default_jobs(args.jobs)
    outer_jobs = max(1, args.outer_jobs or default_outer_jobs(cpu_count, len(discover_rust_test_targets())))
    inner_threads = args.test_threads or default_inner_test_threads(cpu_count, outer_jobs)
    steps: list[tuple[str, Sequence[str]]] = []
    if args.warm_build:
        warm_build = ["cargo", "test", "--tests", "--no-run"]
        add_verbose_flag(warm_build, args.verbose)
        add_jobs_flag(warm_build, cpu_count)
        steps.append(("warm-build", warm_build))
    rust_steps = [
        ("test:rust", ("__parallel_rust__",))
    ]
    lua_steps = [
        (
            "test:lua",
            tuple(lua_test_command(jobs, args.verbose, args.nocapture)),
        )
    ]

    if steps:
        status, results = run_sequence(steps, args.dry_run)
        if status != 0:
            return status
        _ = results

    rust_args = argparse.Namespace(
        dry_run=args.dry_run,
        failure_tail_lines=args.failure_tail_lines,
        nocapture=args.nocapture,
        outer_jobs=args.outer_jobs,
        test_threads=args.test_threads,
        verbose=args.verbose,
        warm_build=False,
    )
    rust_status = run_test_rust(rust_args)
    if rust_status != 0:
        return rust_status
    return run_single("test:lua", lua_steps[0][1], args.dry_run)


def run_test_rust(args: argparse.Namespace) -> int:
    cpu_count = logical_cpu_count()
    targets = discover_rust_test_targets()

    if not targets:
        print("No Rust test targets were discovered.")
        return 1

    outer_jobs = max(1, min(len(targets), args.outer_jobs or default_outer_jobs(cpu_count, len(targets))))
    inner_threads = args.test_threads or default_inner_test_threads(cpu_count, outer_jobs)

    print(f"Discovered {len(targets)} Rust test targets.")
    print(
        "Heuristic: "
        f"cpu_count={cpu_count}, outer_jobs={outer_jobs}, inner_test_threads={inner_threads}, cargo_jobs_per_process=1"
    )

    planned_results: list[CommandResult] = []

    if getattr(args, "warm_build", False):
        warm_build_command = ["cargo", "test", "--tests", "--no-run"]
        add_verbose_flag(warm_build_command, args.verbose)
        add_jobs_flag(warm_build_command, cpu_count)
        warm_build_result = single_command_result("warm-build", warm_build_command, args.dry_run)
        planned_results.append(warm_build_result)
        if not args.dry_run and warm_build_result.returncode != 0:
            print_summary(planned_results)
            return 1

    if args.dry_run:
        for target in targets:
            command = rust_test_command(target, inner_threads, args.verbose, args.nocapture)
            planned_results.append(
                CommandResult(f"test:{target}", tuple(command), 0, 0.0, dry_run=True)
            )
        print_summary(planned_results)
        return 0

    futures = {}
    ordered_results: dict[str, CommandResult] = {}

    with ThreadPoolExecutor(max_workers=outer_jobs) as executor:
        for target in targets:
            label = f"test:{target}"
            command = rust_test_command(target, inner_threads, args.verbose, args.nocapture)
            future = executor.submit(captured_command_result, label, command, args.dry_run)
            futures[future] = label

        for future in as_completed(futures):
            result = future.result()
            ordered_results[result.label] = result
            status = "PASS" if result.returncode == 0 else "FAIL"
            print(f"[{status}] {result.label} ({result.duration_s:.1f}s)")
            if result.returncode != 0:
                print_failure_tail(result, args.failure_tail_lines)

    final_results = planned_results + [ordered_results[f"test:{target}"] for target in targets]
    print_summary(final_results)
    return 0 if all(result.returncode == 0 for result in final_results if not result.dry_run) else 1


def run_clippy(args: argparse.Namespace) -> int:
    jobs = default_jobs(args.jobs)
    command = clippy_command(jobs, args.verbose, args.deny_warnings)
    label = "clippy:deny" if args.deny_warnings else "clippy"
    return run_single(label, command, args.dry_run)


def run_fmt(args: argparse.Namespace) -> int:
    command = fmt_command(check_only=args.action == "check")
    return run_single(f"fmt:{args.action}", command, args.dry_run)


def run_doc(args: argparse.Namespace) -> int:
    jobs = default_jobs(args.jobs)
    command = doc_command(jobs, args.verbose, args.open, args.no_deps)
    label = "doc:open" if args.open else "doc"
    return run_single(label, command, args.dry_run)


def add_common_flags(parser: argparse.ArgumentParser, *, jobs: bool = True, verbose: bool = True) -> None:
    parser.add_argument("--dry-run", action="store_true", help="Print planned commands without running them.")
    if jobs:
        parser.add_argument(
            "--jobs",
            type=int,
            help="Override the logical CPU count used by the command.",
        )
    if verbose:
        parser.add_argument(
            "--verbose",
            action="store_true",
            help="Pass Cargo's verbose flag (-v).",
        )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run repository-owned cargo workflows through one orchestration wrapper.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    build_parser = subparsers.add_parser("build", help="Build the workspace in debug or release mode.")
    build_parser.add_argument("profile", choices=["debug", "release", "dist"])
    add_common_flags(build_parser)
    build_parser.set_defaults(handler=run_build)

    check_parser = subparsers.add_parser("check", help="Run cargo check.")
    add_common_flags(check_parser)
    check_parser.set_defaults(handler=run_check)

    run_parser = subparsers.add_parser("run", help="Run the workspace via cargo run.")
    run_parser.add_argument("profile", choices=["debug", "release", "dist"])
    add_common_flags(run_parser)
    run_parser.add_argument("run_args", nargs="*", help="Arguments forwarded after cargo run --.")
    run_parser.set_defaults(handler=run_run)

    test_parser = subparsers.add_parser("test", help="Run Lua tests, Rust fan-out, or targeted test binaries.")
    test_subparsers = test_parser.add_subparsers(dest="test_command", required=True)

    test_lua_parser = test_subparsers.add_parser("lua", help="Run the Lua test harness.")
    add_common_flags(test_lua_parser)
    test_lua_parser.add_argument("--nocapture", action="store_true", help="Forward --nocapture to libtest.")
    test_lua_parser.set_defaults(handler=run_test_lua)

    test_rust_parser = test_subparsers.add_parser("rust", help="Fan out non-Lua Rust test binaries in parallel.")
    add_common_flags(test_rust_parser, jobs=False)
    test_rust_parser.add_argument("--nocapture", action="store_true", help="Forward --nocapture to every test binary.")
    test_rust_parser.add_argument(
        "--outer-jobs",
        type=int,
        help="Maximum number of concurrent cargo test subprocesses.",
    )
    test_rust_parser.add_argument(
        "--test-threads",
        type=int,
        help="Override libtest --test-threads for each subprocess.",
    )
    test_rust_parser.add_argument(
        "--warm-build",
        action="store_true",
        help="Run cargo test --tests --no-run before fan-out.",
    )
    test_rust_parser.add_argument(
        "--failure-tail-lines",
        type=int,
        default=40,
        help="Number of lines to print from failed subprocess output.",
    )
    test_rust_parser.set_defaults(handler=run_test_rust)

    test_target_parser = test_subparsers.add_parser("target", help="Run one explicit Rust test binary.")
    add_common_flags(test_target_parser)
    test_target_parser.add_argument("target_name", help="Explicit Cargo test target name, e.g. math_tests.")
    test_target_parser.add_argument("--nocapture", action="store_true", help="Forward --nocapture to libtest.")
    test_target_parser.add_argument(
        "--test-threads",
        type=int,
        help="Override libtest --test-threads for the target binary.",
    )
    test_target_parser.set_defaults(handler=run_test_target)

    test_all_parser = test_subparsers.add_parser("all", help="Run Rust fan-out first, then Lua tests.")
    add_common_flags(test_all_parser)
    test_all_parser.add_argument("--nocapture", action="store_true", help="Forward --nocapture to both phases.")
    test_all_parser.add_argument(
        "--outer-jobs",
        type=int,
        help="Maximum number of concurrent cargo test subprocesses for the Rust fan-out phase.",
    )
    test_all_parser.add_argument(
        "--test-threads",
        type=int,
        help="Override libtest --test-threads for Rust subprocesses and targeted test runs.",
    )
    test_all_parser.add_argument(
        "--warm-build",
        action="store_true",
        help="Run cargo test --tests --no-run before the Rust fan-out phase.",
    )
    test_all_parser.add_argument(
        "--failure-tail-lines",
        type=int,
        default=40,
        help="Number of lines to print from failed Rust subprocess output.",
    )
    test_all_parser.set_defaults(handler=run_test_all)

    clippy_parser = subparsers.add_parser("clippy", help="Run cargo clippy.")
    add_common_flags(clippy_parser)
    clippy_parser.add_argument("--deny-warnings", action="store_true", help="Append -- -D warnings.")
    clippy_parser.set_defaults(handler=run_clippy)

    fmt_parser = subparsers.add_parser("fmt", help="Run cargo fmt or cargo fmt --check.")
    add_common_flags(fmt_parser, jobs=False, verbose=False)
    fmt_parser.add_argument("action", choices=["apply", "check"])
    fmt_parser.set_defaults(handler=run_fmt)

    doc_parser = subparsers.add_parser("doc", help="Run cargo doc.")
    add_common_flags(doc_parser)
    doc_parser.add_argument("--open", action="store_true", help="Open the generated docs in the default browser.")
    doc_parser.add_argument("--no-deps", action="store_true", help="Exclude dependency docs.")
    doc_parser.set_defaults(handler=run_doc)

    args = parser.parse_args()

    for name in ("jobs", "outer_jobs", "test_threads", "failure_tail_lines"):
        value = getattr(args, name, None)
        if value is not None and value < 1:
            parser.error(f"--{name.replace('_', '-')} must be at least 1")

    return args


def main() -> int:
    args = parse_args()
    return args.handler(args)


if __name__ == "__main__":
    sys.exit(main())
