"""P8 workflow-enforcement audit for .github/agents/*.agent.md.

For each agent, extract the `## Workflow` section and check for the five
universal items required by docs/architecture/cag-system.md:
  1. branch confirmation (git rev-parse / --abbrev-ref / "confirm branch")
  2. work-folder reference (work/<session>/{scripts,handovers,reports,...})
  3. JSONL log (agent_log.jsonl or "JSONL")
  4. commit step (git add ... git commit / type(scope): description)
  5. CHANGELOG mention (docs/CHANGELOG.md or "CHANGELOG")

Special checks:
  - manager: routes to Planner when ≥3 agents OR ≥5 files; routes to
    CAG-Architect for End-of-Session Sweep.
  - planner: lists Personas (EngDev/GameDev/Modder/Player/GameTest/EngTest).
  - cag-architect: describes End-of-Session Sweep checks (frontmatter, validator,
    missing skills/prompts, persona impact).

Outputs work/cag-system-overhaul-20260418/reports/P8_workflow_audit.md.
Exits 0 always; the report carries pass/fail.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
AGENTS = ROOT / ".github" / "agents"
REPORT = ROOT / "work/cag-system-overhaul-20260418/reports/P8_workflow_audit.md"

UNIVERSAL = {
    "branch": re.compile(r"git rev-parse|--abbrev-ref|confirm.*branch", re.I),
    "workfolder": re.compile(
        r"work/[<{][^>}\s]+[>}]"
        r"|work/[\w\-./{}<>]+/(scripts|handovers|reports|data|logs|examples|other|temp)",
        re.I,
    ),
    "jsonl": re.compile(r"agent_log\.jsonl|JSONL", re.I),
    "commit": re.compile(
        r"git add[^\n]*git commit|git commit -m[^\n]*type\(scope\)|type\(scope\):\s*description",
        re.I | re.S,
    ),
    "changelog": re.compile(r"docs/CHANGELOG\.md|CHANGELOG", re.I),
}

SPECIAL = {
    "manager": [
        (
            "planner_route",
            re.compile(
                r"(?:3\+|three|≥\s*3|>=\s*3).*agents?.*Planner"
                r"|Planner.*(?:3\+|three|≥\s*3|>=\s*3).*agents?"
                r"|(?:5\+|five|≥\s*5|>=\s*5).*files?.*Planner"
                r"|Planner.*(?:5\+|five|≥\s*5|>=\s*5).*files?",
                re.I | re.S,
            ),
        ),
        (
            "sweep_route",
            re.compile(r"CAG-Architect.*(?:End-of-Session|Sweep|§\s*7|cag-system\.md)", re.I | re.S),
        ),
    ],
    "planner": [
        (
            "personas",
            re.compile(r"Personas?.*(EngDev|GameDev|Modder|Player|GameTest|EngTest)", re.I | re.S),
        ),
    ],
    "cag-architect": [
        (
            "sweep_checks",
            re.compile(
                r"(End-of-Session|Sweep).*(frontmatter|validator|missing|persona)",
                re.I | re.S,
            ),
        ),
    ],
}


def extract_workflow(text: str) -> str:
    m = re.search(r"^##\s+Workflow\s*\n(.*?)(?=^##\s+|\Z)", text, re.M | re.S)
    return m.group(1) if m else ""


def audit_agent(path: Path) -> dict:
    name = path.stem.replace(".agent", "")
    text = path.read_text(encoding="utf-8")
    wf = extract_workflow(text)
    universal = {k: bool(rx.search(wf)) for k, rx in UNIVERSAL.items()}
    special = {}
    if name in SPECIAL:
        for key, rx in SPECIAL[name]:
            special[key] = bool(rx.search(wf))
    line_count = len(text.splitlines())
    return {
        "name": name,
        "lines": line_count,
        "workflow_present": bool(wf.strip()),
        "universal": universal,
        "special": special,
    }


def main() -> int:
    results = sorted(
        (audit_agent(p) for p in AGENTS.glob("*.agent.md")),
        key=lambda r: r["name"],
    )

    lines = ["# P8 Workflow Enforcement Audit", ""]
    lines.append(f"Agents scanned: **{len(results)}**")
    lines.append("")
    lines.append("## Universal Checks")
    lines.append("")
    lines.append("| Agent | Lines | Branch | WorkFolder | JSONL | Commit | CHANGELOG | All Pass |")
    lines.append("|---|---:|:---:|:---:|:---:|:---:|:---:|:---:|")

    full_pass = 0
    failing: list[str] = []
    for r in results:
        u = r["universal"]
        all_ok = all(u.values())
        if all_ok:
            full_pass += 1
        else:
            failing.append(r["name"])
        cells = [
            r["name"],
            str(r["lines"]),
            "✅" if u["branch"] else "❌",
            "✅" if u["workfolder"] else "❌",
            "✅" if u["jsonl"] else "❌",
            "✅" if u["commit"] else "❌",
            "✅" if u["changelog"] else "❌",
            "✅" if all_ok else "❌",
        ]
        lines.append("| " + " | ".join(cells) + " |")

    lines += ["", f"**Universal pass:** {full_pass}/{len(results)}", ""]
    if failing:
        lines.append("**Failing universal:** " + ", ".join(failing))
        lines.append("")

    lines.append("## Special Checks (manager / planner / cag-architect)")
    lines.append("")
    for r in results:
        if not r["special"]:
            continue
        lines.append(f"- `{r['name']}`:")
        for k, v in r["special"].items():
            lines.append(f"  - {k}: {'✅' if v else '❌'}")

    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {REPORT.relative_to(ROOT)}")
    print(f"universal pass: {full_pass}/{len(results)}")
    if failing:
        print("failing:", ", ".join(failing))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
