#!/usr/bin/env python3
"""cag_coverage.py — required-section coverage analytics for CAG files.

For each CAG file type, computes the share of files that contain each
required section or live-schema metadata field described in
``docs/architecture/cag-system.md``.

Useful as a contributor-facing "what's still missing" view while CAG files
are being migrated to the new templates.

Usage::

    python tools/audit/cag_coverage.py
    python tools/audit/cag_coverage.py --type agent --format markdown
    python tools/audit/cag_coverage.py --report coverage.json --format json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "validate"))

from _cag_common import (  # noqa: E402
    AGENT_REQUIRED_SECTIONS,
    GITHUB_DIR,
    PROMPT_REQUIRED_SECTIONS,
    SKILL_REQUIRED_SECTIONS,
    SYSTEM_PROMPT,
    SYSTEM_PROMPT_REQUIRED_SECTIONS,
    body_after_frontmatter,
    discover_agents,
    discover_prompts,
    discover_skills,
    has_section,
    parse_cag_metadata_section,
    parse_frontmatter,
    relpath,
    safe_read,
)

AGENT_FRONTMATTER_FIELDS = ("name", "description")
AGENT_METADATA_FIELDS = ("communication", "personas", "primary_skills", "secondary_skills")
SKILL_FRONTMATTER_FIELDS = ("name", "description")
PROMPT_FRONTMATTER_FIELDS = ("description", "agent")
PROMPT_METADATA_FIELDS = ("mode", "loads_skills", "inputs_required")


def _row(name: str, fields: list[tuple[str, bool]]) -> dict[str, object]:
    return {"file": name, "fields": {k: v for k, v in fields}}


def _coverage_pct(rows: list[dict[str, object]]) -> dict[str, float]:
    if not rows:
        return {}
    out: dict[str, float] = {}
    for k in rows[0]["fields"].keys():  # type: ignore[union-attr]
        present = sum(1 for r in rows if r["fields"][k])  # type: ignore[index]
        out[k] = round(100.0 * present / len(rows), 1)
    return out


def scan_system_prompt() -> dict[str, object]:
    if not SYSTEM_PROMPT.exists():
        return {"rows": [], "coverage": {}, "count": 0}
    text = safe_read(SYSTEM_PROMPT)
    fields = [(s, has_section(text, s)) for s in SYSTEM_PROMPT_REQUIRED_SECTIONS]
    rows = [_row(relpath(SYSTEM_PROMPT), fields)]
    return {"rows": rows, "coverage": _coverage_pct(rows), "count": 1}


def scan_agents() -> dict[str, object]:
    rows: list[dict[str, object]] = []
    for p in discover_agents():
        text = safe_read(p)
        fm = parse_frontmatter(text)
        body = body_after_frontmatter(text, fm)
        meta = parse_cag_metadata_section(body)
        fields: list[tuple[str, bool]] = []
        for field in AGENT_FRONTMATTER_FIELDS:
            fields.append((f"fm:{field}", field in fm.data and bool(fm.data.get(field))))
        for field in AGENT_METADATA_FIELDS:
            value = meta.get(field)
            fields.append((f"meta:{field}", bool(value)))
        for sec in AGENT_REQUIRED_SECTIONS:
            fields.append((f"sec:{sec}", has_section(body, sec)))
        rows.append(_row(relpath(p), fields))
    return {"rows": rows, "coverage": _coverage_pct(rows), "count": len(rows)}


def scan_skills() -> dict[str, object]:
    rows: list[dict[str, object]] = []
    for p in discover_skills():
        text = safe_read(p)
        fm = parse_frontmatter(text)
        body = body_after_frontmatter(text, fm)
        fields: list[tuple[str, bool]] = []
        for field in SKILL_FRONTMATTER_FIELDS:
            fields.append((f"fm:{field}", field in fm.data and bool(fm.data.get(field))))
        for sec in SKILL_REQUIRED_SECTIONS:
            fields.append((f"sec:{sec}", has_section(body, sec)))
        rows.append(_row(relpath(p), fields))
    return {"rows": rows, "coverage": _coverage_pct(rows), "count": len(rows)}


def scan_prompts() -> dict[str, object]:
    rows: list[dict[str, object]] = []
    for p in discover_prompts():
        text = safe_read(p)
        fm = parse_frontmatter(text)
        body = body_after_frontmatter(text, fm)
        meta = parse_cag_metadata_section(body)
        fields: list[tuple[str, bool]] = []
        for field in PROMPT_FRONTMATTER_FIELDS:
            fields.append((f"fm:{field}", field in fm.data and bool(fm.data.get(field))))
        for field in PROMPT_METADATA_FIELDS:
            value = meta.get(field)
            fields.append((f"meta:{field}", bool(value)))
        for sec in PROMPT_REQUIRED_SECTIONS:
            fields.append((f"sec:{sec}", has_section(body, sec)))
        rows.append(_row(relpath(p), fields))
    return {"rows": rows, "coverage": _coverage_pct(rows), "count": len(rows)}


def scan(filter_type: str) -> dict[str, object]:
    """Return coverage data for one or all CAG types."""
    out: dict[str, object] = {}
    if filter_type in ("all", "system_prompt"):
        out["system_prompt"] = scan_system_prompt()
    if filter_type in ("all", "agent"):
        out["agent"] = scan_agents()
    if filter_type in ("all", "skill"):
        out["skill"] = scan_skills()
    if filter_type in ("all", "prompt"):
        out["prompt"] = scan_prompts()
    return out


def _format_markdown(report: dict[str, object]) -> str:
    parts: list[str] = ["# CAG Required-Section Coverage", ""]
    for kind, data in report.items():
        d: dict[str, object] = data  # type: ignore[assignment]
        parts.append(f"## {kind}  (n={d['count']})")
        cov: dict[str, float] = d["coverage"]  # type: ignore[assignment]
        if not cov:
            parts.append("_No files scanned._\n")
            continue
        parts.append("")
        parts.append("| Field | Coverage |")
        parts.append("|-------|---------:|")
        for k, v in cov.items():
            parts.append(f"| `{k}` | {v:>5.1f}% |")
        parts.append("")
    return "\n".join(parts)


def _format_text(report: dict[str, object]) -> str:
    parts: list[str] = []
    for kind, data in report.items():
        d: dict[str, object] = data  # type: ignore[assignment]
        parts.append(f"[{kind}]  files={d['count']}")
        cov: dict[str, float] = d["coverage"]  # type: ignore[assignment]
        for k, v in cov.items():
            parts.append(f"  {v:>5.1f}%  {k}")
    return "\n".join(parts)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--type",
                   choices=["all", "system_prompt", "agent", "skill", "prompt"],
                   default="all")
    p.add_argument("--report", metavar="PATH")
    p.add_argument("--format", choices=["text", "markdown", "json"], default="text")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if not GITHUB_DIR.exists():
        print(f"ERROR: {GITHUB_DIR} not found", file=sys.stderr)
        return 2

    report = scan(args.type)

    if args.format == "json":
        out = json.dumps(report, indent=2, sort_keys=True)
    elif args.format == "markdown":
        out = _format_markdown(report)
    else:
        out = _format_text(report)

    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        if args.report.endswith(".json"):
            Path(args.report).write_text(
                json.dumps(report, indent=2, sort_keys=True), encoding="utf-8"
            )
        else:
            Path(args.report).write_text(out, encoding="utf-8")

    print(out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
