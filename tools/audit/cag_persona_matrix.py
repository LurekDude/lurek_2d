#!/usr/bin/env python3
"""cag_persona_matrix.py — persona ↔ agent value matrix.

Reads the ``personas`` field from every agent file's YAML frontmatter and
builds a 6 × N matrix (closed persona vocabulary × agents). Each cell is
``true`` when the agent declares that persona, ``false`` otherwise.

Reports per-persona coverage (warns on <3 agents, errors on 0 agents) and
per-agent persona count (warns when an agent declares 0 personas — the same
condition as W108 in ``cag_validate.py``).

Usage::

    python tools/audit/cag_persona_matrix.py
    python tools/audit/cag_persona_matrix.py --format markdown
    python tools/audit/cag_persona_matrix.py --report matrix.json --format json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "validate"))

from _cag_common import (  # noqa: E402
    GITHUB_DIR,
    PERSONAS,
    body_after_frontmatter,
    discover_agents,
    parse_cag_metadata_section,
    parse_frontmatter,
    relpath,
    safe_read,
)


def scan() -> dict[str, object]:
    """Build persona/agent matrix and the per-row diagnostics."""
    matrix: dict[str, dict[str, bool]] = {}
    invalid_personas: dict[str, list[str]] = {}
    for path in discover_agents():
        agent_name = path.name.removesuffix(".agent.md")
        text = safe_read(path)
        fm = parse_frontmatter(text)
        body = body_after_frontmatter(text, fm) if fm.present else text
        meta = parse_cag_metadata_section(body)
        # Personas now live in ## CAG Metadata body section; fall back to
        # frontmatter for files not yet transformed.
        declared = meta.get("personas") or (fm.get_list("personas") if fm.present else [])
        if isinstance(declared, str):
            declared = [declared]
        invalid = [p for p in declared if p not in PERSONAS]
        if invalid:
            invalid_personas[agent_name] = invalid
        matrix[agent_name] = {p: (p in declared) for p in PERSONAS}

    persona_counts = {
        p: sum(1 for cells in matrix.values() if cells[p]) for p in PERSONAS
    }
    agent_counts = {
        a: sum(1 for v in cells.values() if v) for a, cells in matrix.items()
    }

    persona_warnings = {p: c for p, c in persona_counts.items() if 0 < c < 3}
    persona_errors = {p: c for p, c in persona_counts.items() if c == 0}
    agent_warnings = [a for a, c in agent_counts.items() if c == 0]

    return {
        "personas": list(PERSONAS),
        "agents": sorted(matrix.keys()),
        "matrix": matrix,
        "persona_counts": persona_counts,
        "agent_counts": agent_counts,
        "warnings": {
            "low_coverage_personas": persona_warnings,
            "agents_with_zero_personas": agent_warnings,
            "invalid_personas": invalid_personas,
        },
        "errors": {"unmapped_personas": persona_errors},
    }


def _format_markdown(r: dict[str, object]) -> str:
    personas: list[str] = r["personas"]  # type: ignore[assignment]
    agents: list[str] = r["agents"]      # type: ignore[assignment]
    matrix: dict[str, dict[str, bool]] = r["matrix"]  # type: ignore[assignment]
    out: list[str] = ["# CAG Persona Matrix", ""]
    out.append("| Agent | " + " | ".join(personas) + " | total |")
    out.append("|-------|" + "|".join([":---:"] * len(personas)) + "|------:|")
    for a in agents:
        cells = " | ".join("✅" if matrix[a][p] else "❌" for p in personas)
        total = r["agent_counts"][a]  # type: ignore[index]
        out.append(f"| `{a}` | {cells} | {total} |")
    out.append("")
    out.append("## Persona coverage")
    out.append("| Persona | Agents |")
    out.append("|---------|------:|")
    for p in personas:
        out.append(f"| `{p}` | {r['persona_counts'][p]} |")  # type: ignore[index]
    out.append("")
    err = r["errors"]["unmapped_personas"]      # type: ignore[index]
    warn = r["warnings"]["low_coverage_personas"]  # type: ignore[index]
    zero = r["warnings"]["agents_with_zero_personas"]  # type: ignore[index]
    if err:
        out.append("**ERROR — unmapped personas (0 agents):** "
                   + ", ".join(err.keys()))
    if warn:
        out.append("**WARN — low coverage (<3 agents):** "
                   + ", ".join(f"{k}={v}" for k, v in warn.items()))
    if zero:
        out.append("**WARN — agents with no personas:** " + ", ".join(zero))
    return "\n".join(out)


def _format_text(r: dict[str, object]) -> str:
    out: list[str] = []
    out.append("Persona counts:")
    for p, c in r["persona_counts"].items():  # type: ignore[union-attr]
        out.append(f"  {c:>3}  {p}")
    out.append("")
    out.append("Agents declaring 0 personas:")
    zero = r["warnings"]["agents_with_zero_personas"]  # type: ignore[index]
    if zero:
        out.append("  " + ", ".join(zero))
    else:
        out.append("  (none)")
    err = r["errors"]["unmapped_personas"]  # type: ignore[index]
    if err:
        out.append("ERRORS — personas with 0 agents: " + ", ".join(err.keys()))
    inv = r["warnings"]["invalid_personas"]  # type: ignore[index]
    if inv:
        out.append("Invalid personas declared:")
        for a, p in inv.items():
            out.append(f"  {a}: {p}")
    return "\n".join(out)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--report", metavar="PATH")
    p.add_argument("--format", choices=["text", "markdown", "json"], default="text")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if not GITHUB_DIR.exists():
        print(f"ERROR: {GITHUB_DIR} not found", file=sys.stderr)
        return 2
    report = scan()
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
