#!/usr/bin/env python3
"""cag_validate.py — Lurek2D CAG layer validator.

Validates the four CAG file types against the templates defined in
``work/cag-system-overhaul-20260418/reports/standards/``:

* ``.github/copilot-instructions.md`` (system prompt)         — rules E001-E004, W005
* ``.github/agents/*.agent.md``                               — rules E101-E107, W108
* ``.github/skills/*/SKILL.md``                               — rules E201-E205, W206
* ``.github/prompts/*.prompt.md``                             — rules E301-E305, W306

Usage::

    python tools/validate/cag_validate.py
    python tools/validate/cag_validate.py --type agent
    python tools/validate/cag_validate.py --file .github/agents/developer.agent.md
    python tools/validate/cag_validate.py --baseline
    python tools/validate/cag_validate.py --write-baseline
    python tools/validate/cag_validate.py --report report.json --format json

Exit codes:
    0  — strict mode: 0 errors AND 0 warnings; baseline mode: no regressions
    1  — strict: any error/warning; baseline: new violations vs baseline
    2  — usage / setup error
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from _cag_common import (  # noqa: E402
    AGENT_REQUIRED_SECTIONS,
    GITHUB_DIR,
    PERSONAS,
    PROMPT_REQUIRED_SECTIONS,
    SKILL_REQUIRED_SECTIONS,
    SYSTEM_PROMPT,
    SYSTEM_PROMPT_POINTER,
    SYSTEM_PROMPT_REQUIRED_SECTIONS,
    Violation,
    WORKSPACE_ROOT,
    body_after_frontmatter,
    discover_agents,
    discover_prompts,
    discover_skills,
    extract_links,
    find_fenced_block_lines,
    find_sections,
    first_section_line,
    has_section,
    known_agent_names,
    known_skill_names,
    parse_cag_metadata_section,
    parse_frontmatter,
    relpath,
    safe_read,
)

BASELINE_PATH = Path(__file__).resolve().parent / "cag_validate.baseline.json"

# ─── System prompt rules ─────────────────────────────────────────────────────


def check_system_prompt(path: Path) -> list[Violation]:
    """Apply E001–E004 and W005 to the system prompt file."""
    if not path.exists():
        return [Violation(relpath(path), "E001", "error",
                          "System prompt file does not exist", 0)]
    text = safe_read(path)
    rel = relpath(path)
    out: list[Violation] = []

    for sec in SYSTEM_PROMPT_REQUIRED_SECTIONS:
        if not has_section(text, sec):
            out.append(Violation(rel, "E001", "error",
                                 f"Missing required section: '{sec}'"))
    if SYSTEM_PROMPT_POINTER not in text:
        out.append(Violation(rel, "E001", "error",
                             f"Missing pointer to '{SYSTEM_PROMPT_POINTER}'"))

    line_count = text.count("\n") + (0 if text.endswith("\n") else 1)
    if line_count > 120:
        out.append(Violation(rel, "E002", "error",
                             f"File has {line_count} lines (cap 120)"))
    size = path.stat().st_size
    if size > 8192:
        out.append(Violation(rel, "E003", "error",
                             f"File has {size} bytes (cap 8192)"))

    out.extend(_detect_inline_rosters(rel, text))

    for ref in extract_links(path, text):
        target = ref.resolved()
        if target is None:
            continue
        if not target.exists():
            out.append(Violation(rel, "W005", "warning",
                                 f"Broken reference: '{ref.target}'", ref.line))
    return out


_ROSTER_HEADINGS = (
    "agent roster", "skill catalog", "available agents",
    "available skills", "prompt list", "available prompts",
)
_ROSTER_LINE_RE = re.compile(r"^[\-\*\|]\s*[A-Za-z][a-z\-]+(?:\s|\||$)")


def _detect_inline_rosters(rel: str, text: str) -> list[Violation]:
    out: list[Violation] = []
    lines = text.splitlines()
    for i, line in enumerate(lines, start=1):
        low = line.lower().lstrip("# ").strip()
        if line.lstrip().startswith("#") and any(h in low for h in _ROSTER_HEADINGS):
            out.append(Violation(rel, "E004", "error",
                                 f"Forbidden roster heading: '{line.strip()}'", i))

    run: list[tuple[int, str]] = []

    def _flush() -> None:
        if len(run) >= 10:
            matches = sum(1 for _, ln in run if _ROSTER_LINE_RE.match(ln))
            if matches / len(run) >= 0.8:
                out.append(Violation(rel, "E004", "error",
                                     f"Forbidden inline roster ({len(run)} entries)",
                                     run[0][0]))
        run.clear()

    for i, line in enumerate(lines, start=1):
        if line.strip().startswith(("-", "*", "|")):
            run.append((i, line.strip()))
        else:
            _flush()
    _flush()
    return out


# ─── Section ordering helper ─────────────────────────────────────────────────


def _check_required_sections(
    rel: str, body: str, required: tuple[str, ...], rule: str
) -> list[Violation]:
    out: list[Violation] = []
    sections = find_sections(body)
    titles = [h for _, _, h in sections]
    last_idx = -1
    for sec in required:
        idx = next(
            (i for i, t in enumerate(titles) if sec.lower() in t.lower()), -1
        )
        if idx < 0:
            out.append(Violation(rel, rule, "error",
                                 f"Missing required section: '{sec}'"))
        elif idx < last_idx:
            out.append(Violation(rel, rule, "error",
                                 f"Section '{sec}' is out of order"))
        else:
            last_idx = idx
    return out


# ─── Agent rules ──────────────────────────────────────────────────────────────


def check_agent(path: Path, *, skills: set[str], agents: set[str]) -> list[Violation]:
    """Apply E101–E107 and W108 to an agent file."""
    rel = relpath(path)
    text = safe_read(path)
    out: list[Violation] = []
    fm = parse_frontmatter(text)

    if not fm.present:
        out.append(Violation(rel, "E101", "error",
                             "Missing or malformed YAML frontmatter"))
        return out

    body = body_after_frontmatter(text, fm)
    meta = parse_cag_metadata_section(body)

    # Personas now live in the ## CAG Metadata body section
    personas = meta.get("personas") or []
    if isinstance(personas, str):
        personas = [personas]
    invalid = [p for p in personas if p not in PERSONAS]
    if invalid:
        out.append(Violation(rel, "E102", "error",
                             f"Invalid personas: {invalid} "
                             f"(allowed: {list(PERSONAS)})"))
    if not personas:
        out.append(Violation(rel, "W108", "warning",
                             "No personas declared"))

    # primary_skills / secondary_skills now in body section
    for key in ("primary_skills", "secondary_skills"):
        skill_list = meta.get(key) or []
        if isinstance(skill_list, str):
            skill_list = [skill_list]
        for s in skill_list:
            if s not in skills:
                out.append(Violation(rel, "E103", "error",
                                     f"{key} references unknown skill: '{s}'"))

    # routes_to now in body section
    known_lower = {x.lower() for x in agents}
    routes_to = meta.get("routes_to") or []
    if isinstance(routes_to, str):
        routes_to = [routes_to]
    for a in routes_to:
        norm = a.lower().replace(" ", "-")
        if norm not in known_lower:
            out.append(Violation(rel, "E104", "error",
                                 f"routes_to references unknown agent: '{a}'"))

    # tools (formerly loads_tools) stays in frontmatter
    for t in fm.get_list("tools"):
        if not (WORKSPACE_ROOT / t).exists():
            out.append(Violation(rel, "E105", "error",
                                 f"tools references missing path: '{t}'"))

    line_count = text.count("\n") + (0 if text.endswith("\n") else 1)
    if line_count > 200:
        out.append(Violation(rel, "E106", "error",
                             f"File has {line_count} lines (cap 200)"))

    out.extend(_check_required_sections(rel, body, AGENT_REQUIRED_SECTIONS, "E107"))
    return out


# ─── Skill rules ──────────────────────────────────────────────────────────────


def check_skill(path: Path, *, skills: set[str]) -> list[Violation]:
    """Apply E201–E205 and W206 to a SKILL.md file."""
    rel = relpath(path)
    text = safe_read(path)
    out: list[Violation] = []
    fm = parse_frontmatter(text)

    if not fm.present:
        out.append(Violation(rel, "E202", "error",
                             "Missing or malformed YAML frontmatter"))
        return out

    body = body_after_frontmatter(text, fm)
    body_offset_lines = text[: fm.body_offset].count("\n")
    for fl in find_fenced_block_lines(body):
        out.append(Violation(rel, "E201", "error",
                             "Triple-backtick fence is forbidden in SKILL.md",
                             fl + body_offset_lines))

    # related_skills now lives in the ## CAG Metadata body section (optional)
    meta = parse_cag_metadata_section(body)
    related = meta.get("related_skills") or []
    if isinstance(related, str):
        related = [related]
    for s in related:
        if s not in skills:
            out.append(Violation(rel, "E204", "error",
                                 f"related_skills references unknown skill: '{s}'"))

    out.extend(_check_required_sections(rel, body, SKILL_REQUIRED_SECTIONS, "E205"))

    desc = fm.get_str("description").lower()
    if not ("load this skill when" in desc and "skip it for" in desc):
        out.append(Violation(rel, "W206", "warning",
                             "Description should contain both "
                             "'Load this skill when' and 'Skip it for' clauses"))
    return out


# ─── Prompt rules ─────────────────────────────────────────────────────────────


def check_prompt(
    path: Path, *, skills: set[str], agents: set[str]
) -> list[Violation]:
    """Apply E301–E305 and W306 to a prompt file."""
    rel = relpath(path)
    text = safe_read(path)
    out: list[Violation] = []
    fm = parse_frontmatter(text)

    if not fm.present:
        out.append(Violation(rel, "E301", "error",
                             "Missing or malformed YAML frontmatter"))
        return out

    body = body_after_frontmatter(text, fm)
    meta = parse_cag_metadata_section(body)

    # loads_skills now in ## CAG Metadata body section
    loads_skills = meta.get("loads_skills") or []
    if isinstance(loads_skills, str):
        loads_skills = [loads_skills]
    for s in loads_skills:
        if s not in skills:
            out.append(Violation(rel, "E302", "error",
                                 f"loads_skills references unknown skill: '{s}'"))

    # tools (formerly loads_tools) stays in frontmatter
    for t in fm.get_list("tools"):
        if not (WORKSPACE_ROOT / t).exists():
            out.append(Violation(rel, "E303", "error",
                                 f"tools references missing path: '{t}'"))

    # agent (formerly expected_agent) stays in frontmatter
    expected = fm.get_str("agent").strip()
    if expected:
        norm = expected.lower().replace(" ", "-")
        known_lower = {a.lower() for a in agents}
        if norm not in known_lower and expected != "Manager":
            out.append(Violation(rel, "E304", "error",
                                 f"agent does not exist: '{expected}'"))

    out.extend(_check_required_sections(rel, body, PROMPT_REQUIRED_SECTIONS, "E305"))

    sc_line = first_section_line(body, "Success Criteria")
    if sc_line is not None:
        lines = body.splitlines()
        items = 0
        for ln in lines[sc_line:]:
            if ln.lstrip().startswith("#"):
                break
            if re.match(r"^[\-\*]\s*\[[ xX]\]", ln.lstrip()):
                items += 1
        if items == 0:
            out.append(Violation(rel, "W306", "warning",
                                 "Success Criteria has no checklist items"))
    return out


# ─── Driver ───────────────────────────────────────────────────────────────────


def run_validation(
    type_filter: str | None = None, single_file: Path | None = None
) -> tuple[list[Violation], dict[str, int]]:
    """Run all validators; return ``(violations, scanned counts)``."""
    skills = known_skill_names()
    agents = known_agent_names()
    violations: list[Violation] = []
    scanned = {"system_prompt": 0, "agent": 0, "skill": 0, "prompt": 0}

    if single_file is not None:
        if single_file.name == "copilot-instructions.md":
            violations.extend(check_system_prompt(single_file))
            scanned["system_prompt"] = 1
        elif single_file.name.endswith(".agent.md"):
            violations.extend(check_agent(single_file, skills=skills, agents=agents))
            scanned["agent"] = 1
        elif single_file.name == "SKILL.md":
            violations.extend(check_skill(single_file, skills=skills))
            scanned["skill"] = 1
        elif single_file.name.endswith(".prompt.md"):
            violations.extend(check_prompt(single_file, skills=skills, agents=agents))
            scanned["prompt"] = 1
        return violations, scanned

    if type_filter in (None, "system_prompt"):
        if SYSTEM_PROMPT.exists():
            violations.extend(check_system_prompt(SYSTEM_PROMPT))
            scanned["system_prompt"] = 1
    if type_filter in (None, "agent"):
        for a in discover_agents():
            violations.extend(check_agent(a, skills=skills, agents=agents))
            scanned["agent"] += 1
    if type_filter in (None, "skill"):
        for s in discover_skills():
            violations.extend(check_skill(s, skills=skills))
            scanned["skill"] += 1
    if type_filter in (None, "prompt"):
        for p in discover_prompts():
            violations.extend(check_prompt(p, skills=skills, agents=agents))
            scanned["prompt"] += 1
    return violations, scanned


def summarise(violations: list[Violation]) -> dict[str, object]:
    by_rule: dict[str, int] = {}
    errors = warnings = 0
    for v in violations:
        by_rule[v.rule] = by_rule.get(v.rule, 0) + 1
        if v.severity == "error":
            errors += 1
        else:
            warnings += 1
    return {"errors": errors, "warnings": warnings, "by_rule": by_rule}


def report_payload(
    violations: list[Violation], scanned: dict[str, int]
) -> dict[str, object]:
    """Build the JSON report payload."""
    return {
        "scanned": scanned,
        "violations": [v.to_dict() for v in violations],
        "summary": summarise(violations),
    }


# ─── Baseline ─────────────────────────────────────────────────────────────────


def violation_key(v: Violation) -> str:
    """Stable identity for a violation across runs."""
    return f"{v.file}|{v.rule}|{v.message}"


def load_baseline() -> set[str]:
    if not BASELINE_PATH.exists():
        return set()
    data = json.loads(BASELINE_PATH.read_text(encoding="utf-8"))
    return set(data.get("keys", []))


def write_baseline(violations: list[Violation], scanned: dict[str, int]) -> None:
    """Persist current violation set as the baseline."""
    payload = {
        "captured_at": _dt.datetime.now(_dt.timezone.utc).isoformat(),
        "scanned": scanned,
        "summary": summarise(violations),
        "keys": sorted(violation_key(v) for v in violations),
    }
    BASELINE_PATH.write_text(
        json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8"
    )


def diff_against_baseline(
    violations: list[Violation], baseline: set[str]
) -> list[Violation]:
    """Return only violations not present in the baseline."""
    return [v for v in violations if violation_key(v) not in baseline]


# ─── Output ───────────────────────────────────────────────────────────────────


def format_text(violations: list[Violation], scanned: dict[str, int]) -> str:
    lines: list[str] = []
    summ = summarise(violations)
    if violations:
        for v in violations:
            loc = f":{v.line}" if v.line else ""
            lines.append(f"  {v.severity.upper():<7} {v.rule}  "
                         f"{v.file}{loc}  —  {v.message}")
        lines.append("")
    lines.append(
        f"Scanned: system_prompt={scanned.get('system_prompt', 0)} "
        f"agents={scanned.get('agent', 0)} "
        f"skills={scanned.get('skill', 0)} "
        f"prompts={scanned.get('prompt', 0)}"
    )
    lines.append(f"Summary: {summ['errors']} errors, {summ['warnings']} warnings")
    if summ["by_rule"]:
        top = sorted(summ["by_rule"].items(), key=lambda kv: -kv[1])[:8]
        lines.append("Top rules: " + ", ".join(f"{k}={v}" for k, v in top))
    return "\n".join(lines)


# ─── CLI ──────────────────────────────────────────────────────────────────────


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    p.add_argument("--type",
                   choices=["system_prompt", "agent", "skill", "prompt"])
    p.add_argument("--file", metavar="PATH",
                   help="Validate a single CAG file (relative or absolute)")
    p.add_argument("--baseline", action="store_true",
                   help="Compare against baseline; exit 0 unless regressions")
    p.add_argument("--write-baseline", action="store_true",
                   help="Capture current state into the baseline file")
    p.add_argument("--report", metavar="PATH",
                   help="Write JSON report to this path")
    p.add_argument("--format", choices=["text", "json"], default="text")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if not GITHUB_DIR.exists():
        print(f"ERROR: {GITHUB_DIR} not found", file=sys.stderr)
        return 2

    single_file: Path | None = None
    if args.file:
        candidate = WORKSPACE_ROOT / args.file
        if not candidate.exists():
            candidate = Path(args.file)
        if not candidate.exists():
            print(f"ERROR: file not found: {args.file}", file=sys.stderr)
            return 2
        single_file = candidate

    violations, scanned = run_validation(args.type, single_file)
    payload = report_payload(violations, scanned)

    if args.write_baseline:
        write_baseline(violations, scanned)
        print(f"Baseline written to {relpath(BASELINE_PATH)} "
              f"({len(violations)} violations)")
        return 0

    if args.report:
        Path(args.report).parent.mkdir(parents=True, exist_ok=True)
        Path(args.report).write_text(
            json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8"
        )

    if args.format == "json":
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(format_text(violations, scanned))

    if args.baseline:
        baseline = load_baseline()
        regressions = diff_against_baseline(violations, baseline)
        if regressions:
            print(f"\nREGRESSIONS vs baseline: {len(regressions)} new violation(s)")
            for v in regressions[:25]:
                print(f"  + {v.rule}  {v.file}  —  {v.message}")
            return 1
        print(f"\nBaseline OK: {len(violations)} violations match baseline "
              f"(0 regressions)")
        return 0

    summ = summarise(violations)
    return 1 if summ["errors"] or summ["warnings"] else 0


if __name__ == "__main__":
    sys.exit(main())
