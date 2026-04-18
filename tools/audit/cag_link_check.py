#!/usr/bin/env python3
"""cag_link_check.py — broken-link checker for the CAG layer.

Walks every ``.github/**/*.md`` file, extracts markdown links and backtick-
quoted path-like tokens, and reports any target that does not resolve to an
existing file under the repository root.

Categories: ``cag`` (paths under ``.github/``), ``docs``, ``tools``, ``src``,
``content``, ``tests``, ``extensions``, ``other``. URLs (http/https/mailto)
are skipped, as are paths inside fenced code blocks.

Usage::

    python tools/audit/cag_link_check.py
    python tools/audit/cag_link_check.py --strict
    python tools/audit/cag_link_check.py --report links.json --format json
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "validate"))

from _cag_common import (  # noqa: E402
    GITHUB_DIR,
    WORKSPACE_ROOT,
    extract_links,
    relpath,
    safe_read,
)


def _categorise(target: str) -> str:
    if target.startswith(".github/"):
        return "cag"
    if target.startswith("docs/"):
        return "docs"
    if target.startswith("tools/"):
        return "tools"
    if target.startswith("src/"):
        return "src"
    if target.startswith("content/"):
        return "content"
    if target.startswith("tests/"):
        return "tests"
    if target.startswith("extensions/"):
        return "extensions"
    return "other"


def scan() -> dict[str, object]:
    """Walk .github/, return a structured report payload."""
    md_files = sorted(GITHUB_DIR.rglob("*.md"))
    broken: list[dict[str, object]] = []
    by_cat: Counter[str] = Counter()
    broken_by_cat: Counter[str] = Counter()
    total = 0

    for md in md_files:
        text = safe_read(md)
        for ref in extract_links(md, text):
            target = ref.resolved()
            if target is None:
                continue
            total += 1
            try:
                rel_target = str(target.relative_to(WORKSPACE_ROOT)).replace("\\", "/")
            except ValueError:
                rel_target = str(target).replace("\\", "/")
            cat = _categorise(rel_target)
            by_cat[cat] += 1
            if not target.exists():
                broken_by_cat[cat] += 1
                broken.append({
                    "file": relpath(md),
                    "line": ref.line,
                    "kind": ref.kind,
                    "target": ref.target,
                    "resolved": rel_target,
                    "category": cat,
                })

    return {
        "files_scanned": len(md_files),
        "links_total": total,
        "links_by_category": dict(by_cat),
        "broken_total": len(broken),
        "broken_by_category": dict(broken_by_cat),
        "broken": broken,
    }


def format_text(report: dict[str, object]) -> str:
    lines: list[str] = []
    for b in report["broken"]:  # type: ignore[index]
        lines.append(f"  BROKEN  {b['file']}:{b['line']}  [{b['category']}]  "  # type: ignore[index]
                     f"-> {b['target']}")
    if report["broken"]:
        lines.append("")
    lines.append(
        f"Files scanned: {report['files_scanned']}, "
        f"links: {report['links_total']}, "
        f"broken: {report['broken_total']}"
    )
    if report["broken_by_category"]:
        lines.append(
            "Broken by category: "
            + ", ".join(f"{k}={v}" for k, v in
                        sorted(report["broken_by_category"].items()))  # type: ignore[union-attr]
        )
    return "\n".join(lines)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--report", metavar="PATH",
                   help="Write JSON report to this path")
    p.add_argument("--format", choices=["text", "json"], default="text")
    p.add_argument("--strict", action="store_true",
                   help="Exit non-zero if any broken link is found")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if not GITHUB_DIR.exists():
        print(f"ERROR: {GITHUB_DIR} not found", file=sys.stderr)
        return 2

    report = scan()
    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(
            json.dumps(report, indent=2, sort_keys=True), encoding="utf-8"
        )
    if args.format == "json":
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(format_text(report))

    if args.strict and report["broken_total"]:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
