#!/usr/bin/env python3
"""
cag_validate.py — Luna2D CAG (Copilot Agent Guidance) layer validator.

Usage:
    python tools/cag_validate.py                              # Validate everything
    python tools/cag_validate.py --type agent                 # Agents only
    python tools/cag_validate.py --type skill                 # Skills only
    python tools/cag_validate.py --type prompt                # Prompts only
    python tools/cag_validate.py --type instruction           # Instructions only
    python tools/cag_validate.py --file .github/agents/developer.agent.md
    python tools/cag_validate.py --help

Exit codes:
    0 — all validations passed (or only warnings/info)
    1 — one or more ERROR-level findings
    2 — usage / setup error

Severity levels
    ERROR   — required field or section missing; file will malfunction
    WARN    — field present but suspicious (empty, very short, wrong format)
    INFO    — style suggestion, non-blocking
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterator

# ── Configuration ─────────────────────────────────────────────────────────────

WORKSPACE_ROOT = Path(__file__).resolve().parent.parent
GITHUB_DIR = WORKSPACE_ROOT / ".github"

# Known valid tool names referenced in agent files
KNOWN_TOOLS = {
    "read", "edit", "execute", "search", "browser", "new",
    "run_in_terminal", "file_search", "grep_search", "semantic_search",
}

# ── Findings ──────────────────────────────────────────────────────────────────


@dataclass
class Finding:
    severity: str   # ERROR | WARN | INFO
    file: Path
    message: str

    def __str__(self) -> str:
        colors = {"ERROR": "\033[31m", "WARN": "\033[33m", "INFO": "\033[36m"}
        reset = "\033[0m"
        c = colors.get(self.severity, "")
        rel = self.file.relative_to(WORKSPACE_ROOT)
        return f"  {c}{self.severity:<5}{reset}  {rel}  —  {self.message}"


# ── YAML frontmatter parser ───────────────────────────────────────────────────

_FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def parse_frontmatter(text: str) -> dict[str, str]:
    """
    Minimal YAML frontmatter parser. Supports:
      key: value          (string)
      key: [a, b, c]      (list → stored as comma-separated string)
    """
    match = _FM_RE.match(text)
    if not match:
        return {}
    fm: dict[str, str] = {}
    for line in match.group(1).splitlines():
        if ":" not in line:
            continue
        key, _, rest = line.partition(":")
        value = rest.strip().strip('"').strip("'")
        fm[key.strip()] = value
    return fm


def has_frontmatter(text: str) -> bool:
    return bool(_FM_RE.match(text))


def body_after_frontmatter(text: str) -> str:
    m = _FM_RE.match(text)
    return text[m.end():] if m else text


# ── Per-type validators ───────────────────────────────────────────────────────


def _check_agent(path: Path, text: str, fm: dict[str, str]) -> list[Finding]:
    findings: list[Finding] = []

    # Required frontmatter fields
    for key in ("description", "tools", "name"):
        if key not in fm:
            findings.append(Finding("ERROR", path, f"Missing required frontmatter field: `{key}`"))
        elif not fm[key].strip():
            findings.append(Finding("WARN", path, f"Frontmatter field `{key}` is empty"))

    # description should not be very short
    desc = fm.get("description", "")
    if desc and len(desc) < 20:
        findings.append(Finding("WARN", path, f"frontmatter `description` is very short ({len(desc)} chars)"))

    # tools should look like a list
    tools_raw = fm.get("tools", "")
    if tools_raw and not (tools_raw.startswith("[") and tools_raw.endswith("]")):
        findings.append(Finding("WARN", path, "`tools` value should be a YAML list: [read, edit, ...]"))

    # Required Markdown sections
    body = body_after_frontmatter(text)
    for section in ("## SCOPE", "## CORE SKILLS", "## OUTPUT CONTRACT"):
        if section not in body:
            findings.append(Finding("WARN", path, f"Missing recommended section: `{section}`"))

    return findings


def _check_instruction(path: Path, text: str, fm: dict[str, str]) -> list[Finding]:
    findings: list[Finding] = []

    if "applyTo" not in fm:
        findings.append(Finding("ERROR", path, "Missing required frontmatter field: `applyTo`"))
    else:
        apply = fm["applyTo"]
        if not apply.strip():
            findings.append(Finding("WARN", path, "`applyTo` glob is empty"))
        # Warn only if applyTo value looks genuinely wrong (not a path and not a glob)
        looks_like_path = "/" in apply or "\\" in apply or "*" in apply or "." in apply
        if apply and not looks_like_path:
            findings.append(Finding("WARN", path, f"`applyTo` value '{apply}' doesn't look like a glob or file path"))

    body = body_after_frontmatter(text)
    if len(body.strip()) < 50:
        findings.append(Finding("WARN", path, "Instruction body is very short (< 50 chars) — may have no effect"))

    return findings


def _check_prompt(path: Path, text: str, fm: dict[str, str]) -> list[Finding]:
    findings: list[Finding] = []

    if "description" not in fm:
        findings.append(Finding("ERROR", path, "Missing required frontmatter field: `description`"))
    elif not fm["description"].strip():
        findings.append(Finding("WARN", path, "Frontmatter `description` is empty"))
    elif len(fm["description"]) < 10:
        findings.append(Finding("WARN", path, f"Frontmatter `description` is very short ({len(fm['description'])} chars)"))

    body = body_after_frontmatter(text)
    if len(body.strip()) < 30:
        findings.append(Finding("WARN", path, "Prompt body is very short — likely incomplete"))

    return findings


def _check_skill(path: Path, text: str, fm: dict[str, str]) -> list[Finding]:
    findings: list[Finding] = []

    for key in ("name", "description"):
        if key not in fm:
            findings.append(Finding("ERROR", path, f"Missing required frontmatter field: `{key}`"))
        elif not fm[key].strip():
            findings.append(Finding("WARN", path, f"Frontmatter field `{key}` is empty"))

    # name should match the directory name
    expected_name = path.parent.name
    actual_name = fm.get("name", "")
    if actual_name and actual_name != expected_name:
        findings.append(Finding("WARN", path,
            f"Skill `name` ('{actual_name}') does not match folder name ('{expected_name}')"))

    body = body_after_frontmatter(text)
    for section in ("## Load When", "## Owns"):
        if section not in body:
            findings.append(Finding("INFO", path, f"Missing recommended section: `{section}`"))

    return findings


# ── File discovery ────────────────────────────────────────────────────────────


def _file_type(path: Path) -> str | None:
    """Return the CAG type for a file, or None if not a CAG file."""
    name = path.name
    if name.endswith(".agent.md"):
        return "agent"
    if name.endswith(".instructions.md"):
        return "instruction"
    if name.endswith(".prompt.md"):
        return "prompt"
    if name == "SKILL.md":
        return "skill"
    return None


def discover_files(type_filter: str | None = None) -> Iterator[tuple[Path, str]]:
    """Yield (path, cag_type) for all CAG files under .github."""
    for md in sorted(GITHUB_DIR.rglob("*.md")):
        t = _file_type(md)
        if t is None:
            continue
        if type_filter is not None and t != type_filter:
            continue
        yield md, t


# ── Main validator ────────────────────────────────────────────────────────────


def validate_file(path: Path, cag_type: str) -> list[Finding]:
    findings: list[Finding] = []

    try:
        text = path.read_text(encoding="utf-8-sig")  # utf-8-sig strips BOM if present
    except OSError as exc:
        findings.append(Finding("ERROR", path, f"Cannot read file: {exc}"))
        return findings

    if not has_frontmatter(text):
        findings.append(Finding("ERROR", path, "Missing YAML frontmatter (file must start with ---)"))
        return findings

    fm = parse_frontmatter(text)

    dispatch = {
        "agent": _check_agent,
        "instruction": _check_instruction,
        "prompt": _check_prompt,
        "skill": _check_skill,
    }
    checker = dispatch.get(cag_type)
    if checker:
        findings.extend(checker(path, text, fm))

    return findings


def validate(type_filter: str | None = None, single_file: Path | None = None) -> list[Finding]:
    all_findings: list[Finding] = []

    if single_file is not None:
        cag_type = _file_type(single_file)
        if cag_type is None:
            all_findings.append(Finding("WARN", single_file, "File does not match any known CAG type — skipping"))
            return all_findings
        return validate_file(single_file, cag_type)

    files = list(discover_files(type_filter))
    if not files:
        print(f"No CAG files found (type={type_filter or 'all'}).")
        return []

    for path, cag_type in files:
        all_findings.extend(validate_file(path, cag_type))

    return all_findings


# ── CLI ───────────────────────────────────────────────────────────────────────


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument(
        "--type",
        choices=["agent", "skill", "prompt", "instruction"],
        metavar="TYPE",
        help="Validate only this type: agent | skill | prompt | instruction",
    )
    p.add_argument(
        "--file",
        metavar="PATH",
        help="Validate a single CAG file.",
    )
    p.add_argument(
        "--errors-only",
        action="store_true",
        help="Print only ERROR-level findings (suppress WARN and INFO).",
    )
    return p


def main() -> int:
    args = build_parser().parse_args()

    if not GITHUB_DIR.exists():
        print(f"ERROR: .github/ directory not found at {GITHUB_DIR}", file=sys.stderr)
        return 2

    single_file: Path | None = None
    if args.file:
        single_file = WORKSPACE_ROOT / args.file
        if not single_file.exists():
            single_file = Path(args.file)
        if not single_file.exists():
            print(f"ERROR: File not found: {args.file}", file=sys.stderr)
            return 2

    findings = validate(type_filter=getattr(args, "type", None), single_file=single_file)

    # Filter if requested
    if args.errors_only:
        findings = [f for f in findings if f.severity == "ERROR"]

    # Count by type
    counts = {"ERROR": 0, "WARN": 0, "INFO": 0}
    for f in findings:
        counts[f.severity] = counts.get(f.severity, 0) + 1

    # Print grouped output
    if findings:
        print()
        for f in findings:
            print(f)
        print()
    else:
        print("\n  All CAG files passed validation.\n")

    # Summary line
    total = sum(counts.values())
    print(
        f"  Summary: {total} finding(s) — "
        f"\033[31m{counts['ERROR']} errors\033[0m, "
        f"\033[33m{counts['WARN']} warnings\033[0m, "
        f"\033[36m{counts['INFO']} info\033[0m"
    )

    return 1 if counts["ERROR"] > 0 else 0


if __name__ == "__main__":
    sys.exit(main())
