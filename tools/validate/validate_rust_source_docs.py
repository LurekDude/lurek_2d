#!/usr/bin/env python3
"""Validate file-level and public-item Rust documentation under src/.

Rules enforced:
1. Every Rust file under src/**/*.rs must have a file-level //! header.
2. Phase-1 public items must have a preceding /// summary line.
3. The first summary line must contain at least 25 visible characters.

Phase-1 public item scope:
- pub fn
- pub struct
- pub enum
- pub trait
- pub type
- pub const
- pub static
- pub mod

Out of scope for this validator:
- private items
- public struct fields
- enum variants

Usage:
    python tools/validate/validate_rust_source_docs.py
    python tools/validate/validate_rust_source_docs.py src/lib.rs
    python tools/validate/validate_rust_source_docs.py src/math/
    python tools/validate/validate_rust_source_docs.py --format json

Exit codes:
    0 if all checks pass, 1 otherwise.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC_DIR = ROOT / "src"
MIN_SUMMARY_VISIBLE_CHARS = 25

# Keep scope aligned with the existing public-item doc scanners used by the docs tools.
PUB_ITEM_RE = re.compile(
    r"^pub(?:\([^)]*\))?\s+"
    r"(?:unsafe\s+|async\s+|const\s+|extern\s+\"[^\"]*\"\s+)?"
    r"(fn|struct|enum|trait|type|const|static|mod)"
    r"\s+([A-Za-z_][A-Za-z0-9_]*)"
)


@dataclass
class Finding:
    file: str
    line: int
    kind: str
    message: str


def _visible_len(text: str) -> int:
    return len(re.sub(r"\s+", "", text))


def _relative(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def _collect_rs_files(targets: list[str]) -> list[Path]:
    if not targets:
        return sorted(SRC_DIR.rglob("*.rs"))

    files: list[Path] = []
    for raw in targets:
        path = (ROOT / raw).resolve() if not Path(raw).is_absolute() else Path(raw)
        if path.is_file() and path.suffix == ".rs":
            files.append(path)
            continue
        if path.is_dir():
            files.extend(sorted(path.rglob("*.rs")))
            continue
        raise FileNotFoundError(f"Path does not exist or is not a Rust file/directory: {raw}")

    unique: list[Path] = []
    seen: set[Path] = set()
    for path in files:
        resolved = path.resolve()
        if resolved not in seen:
            seen.add(resolved)
            unique.append(resolved)
    return unique


def _find_file_header(lines: list[str]) -> tuple[int | None, str]:
    start_line: int | None = None
    parts: list[str] = []

    for index, raw in enumerate(lines):
        stripped = raw.strip()

        if stripped == "" or stripped.startswith("#!["):
            continue

        if stripped.startswith("//!"):
            if start_line is None:
                start_line = index + 1
            parts.append(stripped[3:].lstrip(" "))
            continue

        if start_line is not None:
            break

        if stripped.startswith("//"):
            continue

        break

    return start_line, " ".join(part for part in parts if part).strip()


def _collect_doc_lines_above(lines: list[str], item_index: int) -> list[tuple[int, str]]:
    doc_lines: list[tuple[int, str]] = []
    index = item_index - 1

    while index >= 0:
        stripped = lines[index].strip()
        if stripped.startswith("///"):
            doc_lines.insert(0, (index + 1, stripped[3:].lstrip(" ")))
            index -= 1
            continue

        if stripped.startswith("#[") or stripped == "":
            index -= 1
            continue

        break

    return doc_lines


def _first_summary_line(doc_lines: list[tuple[int, str]]) -> tuple[int | None, str]:
    for line_no, text in doc_lines:
        stripped = text.strip()
        if stripped:
            return line_no, stripped
    return None, ""


def validate_file(path: Path) -> list[Finding]:
    findings: list[Finding] = []

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except OSError as exc:
        return [Finding(_relative(path), 1, "error", f"cannot read file: {exc}")]

    header_line, _ = _find_file_header(lines)
    if header_line is None:
        findings.append(
            Finding(
                file=_relative(path),
                line=1,
                kind="missing-file-doc",
                message="missing file-level //! doc header before the first code item",
            )
        )

    for index, raw in enumerate(lines):
        match = PUB_ITEM_RE.match(raw.strip())
        if not match:
            continue

        item_kind = match.group(1)
        item_name = match.group(2)
        doc_lines = _collect_doc_lines_above(lines, index)
        summary_line, summary_text = _first_summary_line(doc_lines)

        if summary_line is None:
            findings.append(
                Finding(
                    file=_relative(path),
                    line=index + 1,
                    kind="missing-item-doc",
                    message=(
                        f"{item_kind} {item_name} is missing a preceding /// summary line "
                        f"with at least {MIN_SUMMARY_VISIBLE_CHARS} visible characters"
                    ),
                )
            )
            continue

        visible_len = _visible_len(summary_text)
        if visible_len < MIN_SUMMARY_VISIBLE_CHARS:
            findings.append(
                Finding(
                    file=_relative(path),
                    line=summary_line,
                    kind="short-item-doc",
                    message=(
                        f"{item_kind} {item_name} summary is too short: "
                        f"{visible_len} visible chars < {MIN_SUMMARY_VISIBLE_CHARS}"
                    ),
                )
            )

    return findings


def validate(targets: list[str]) -> dict:
    files = _collect_rs_files(targets)
    findings: list[Finding] = []
    for path in files:
        findings.extend(validate_file(path))

    return {
        "ok": len(findings) == 0,
        "scanned_files": len(files),
        "finding_count": len(findings),
        "findings": [asdict(finding) for finding in findings],
    }


def _print_text(result: dict) -> None:
    if result["ok"]:
        print(f"PASS - validated {result['scanned_files']} Rust source file(s)")
        return

    for finding in result["findings"]:
        print(f"{finding['file']}:{finding['line']}: {finding['kind']}: {finding['message']}")

    print()
    print(
        f"FAIL - {result['finding_count']} finding(s) across "
        f"{result['scanned_files']} Rust source file(s)"
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate Rust source documentation rules.")
    parser.add_argument("targets", nargs="*", help="Optional Rust file(s) or directories to scan")
    parser.add_argument("--format", choices=["text", "json"], default="text")
    args = parser.parse_args()

    try:
        result = validate(args.targets)
    except FileNotFoundError as exc:
        result = {
            "ok": False,
            "scanned_files": 0,
            "finding_count": 1,
            "findings": [{"file": "", "line": 1, "kind": "error", "message": str(exc)}],
        }

    if args.format == "json":
        print(json.dumps(result, indent=2))
    else:
        _print_text(result)

    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())