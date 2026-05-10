#!/usr/bin/env python3
"""
mutation_report.py — run cargo-mutants for selected priority modules.

Usage:
    python tools/audit/mutation_report.py
    python tools/audit/mutation_report.py --modules data serial image physics
    python tools/audit/mutation_report.py --output logs/reports/mutation_report.md

Exit codes:
    0 - run completed (or skipped because cargo-mutants is missing)
    1 - cargo-mutants failed
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_MODULES = ["data", "serial", "image", "physics"]


def build_command(modules: list[str]) -> list[str]:
    cmd = ["cargo", "mutants", "--no-shuffle", "--timeout", "300"]
    for module in modules:
        cmd.extend(["--package", "lurek2d", "--regex", module])
    return cmd


def run_mutants(modules: list[str]) -> tuple[int, str]:
    if shutil.which("cargo-mutants") is None and shutil.which("cargo") is None:
        return 0, "SKIP: cargo or cargo-mutants not available on PATH"

    cmd = build_command(modules)
    proc = subprocess.run(
        cmd,
        cwd=WORKSPACE_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    output = (proc.stdout or "") + "\n" + (proc.stderr or "")
    return proc.returncode, output


def main() -> int:
    parser = argparse.ArgumentParser(description="Run cargo-mutants and save a report")
    parser.add_argument("--modules", nargs="*", default=DEFAULT_MODULES)
    parser.add_argument(
        "--output",
        default=str(WORKSPACE_ROOT / "logs" / "reports" / "mutation_report.md"),
    )
    args = parser.parse_args()

    code, output = run_mutants(args.modules)

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    lines = [
        "# Mutation Testing Report",
        "",
        f"Modules: {', '.join(args.modules)}",
        "",
    ]
    if code == 0 and output.startswith("SKIP:"):
        lines.append(output)
    else:
        lines.extend([
            f"Exit code: {code}",
            "",
            "```text",
            output.strip(),
            "```",
        ])

    out_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[OK] Wrote {out_path}")

    if code == 0 or output.startswith("SKIP:"):
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
