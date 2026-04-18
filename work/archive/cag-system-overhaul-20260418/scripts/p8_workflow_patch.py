"""P8 patcher: append canonical universal workflow steps to each agent.

For each .github/agents/<name>.agent.md:
  1. Locate the `## Workflow` section.
  2. Find the highest-numbered step ("N. ...").
  3. Append five canonical steps (branch / artifacts / commit / changelog /
     handoff) starting at N+1, immediately before the next "## " heading.

For manager/planner/cag-architect, also splice in the special items.

Idempotent: if any of the canonical key phrases is already present in the
Workflow section, that line is skipped.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
AGENTS = ROOT / ".github" / "agents"

UNIVERSAL_LINES = [
    ("Confirm branch", "**Confirm branch**: run `git rev-parse --abbrev-ref HEAD` and verify it matches the working branch before staging anything."),
    ("Persist artifacts", "**Persist artifacts**: write deliverables under `work/<session>/{reports,data,scripts,handovers}/` and append a JSONL log entry per phase to `work/<session>/logs/agent_log.jsonl`."),
    ("Commit", "**Commit**: stage only the specific files (`git add <paths>` — never `git add .`) and commit using `type(scope): description` (types: feat / fix / refactor / test / docs / chore)."),
    ("Update CHANGELOG", "**Update CHANGELOG**: add one bullet under the current version in `docs/CHANGELOG.md` describing what changed."),
    ("End-of-session handoff", "**End-of-session handoff**: route to `Manager` (or your `routes_to` agent); for sessions touching `.github/`, ensure `CAG-Architect` performs an End-of-Session CAG Sweep (see [docs/architecture/cag-system.md § 7](../../docs/architecture/cag-system.md#7-end-of-session-cag-sweep-contract))."),
]

SPECIAL_EXTRA = {
    "manager": [
        ("Planner routing", "**Planner routing**: if the request spans 3+ agents OR 5+ files, route to `Planner` immediately before any specialist work begins."),
        ("Final CAG sweep", "**Final CAG sweep**: as the closing phase, route to `CAG-Architect` for the End-of-Session CAG Sweep ([docs/architecture/cag-system.md § 7](../../docs/architecture/cag-system.md#7-end-of-session-cag-sweep-contract))."),
    ],
    "planner": [
        ("Persona coverage", "**Persona coverage**: when decomposing the task, evaluate impact on each Persona — EngDev / GameDev / Modder / Player / GameTest / EngTest — and assign agents whose `personas` cover the affected set."),
    ],
    "cag-architect": [
        ("Sweep checks", "**End-of-Session Sweep checks**: verify (a) frontmatter on any new artifacts, (b) `cag_validate.py --baseline` exits 0, (c) no missing skills/prompts surfaced during the session, and (d) persona coverage unchanged or improved."),
    ],
}


def patch_agent(path: Path) -> tuple[bool, list[str]]:
    name = path.stem.replace(".agent", "")
    text = path.read_text(encoding="utf-8")
    m = re.search(r"^(##\s+Workflow\s*\n)(.*?)(?=^##\s+|\Z)", text, re.M | re.S)
    if not m:
        return False, ["no Workflow section"]
    header, body = m.group(1), m.group(2)

    # Find highest numbered step in body.
    nums = [int(n) for n in re.findall(r"^(\d+)\.\s", body, re.M)]
    next_n = (max(nums) if nums else 0) + 1

    additions: list[str] = []
    appended_keys: list[str] = []

    items = list(UNIVERSAL_LINES)
    if name in SPECIAL_EXTRA:
        items += SPECIAL_EXTRA[name]

    for key, line in items:
        # Skip if a clear marker for this item already exists in body.
        marker = key.split(":")[0].strip()
        if marker.lower() in body.lower():
            continue
        additions.append(f"{next_n}. {line}")
        appended_keys.append(marker)
        next_n += 1

    if not additions:
        return False, []

    # Strip trailing blank lines from body, append new steps + one blank line.
    body_stripped = body.rstrip() + "\n"
    new_body = body_stripped + "\n".join(additions) + "\n\n"
    new_text = text[: m.start()] + header + new_body + text[m.end():]
    path.write_text(new_text, encoding="utf-8")
    return True, appended_keys


def main() -> int:
    changed = 0
    for path in sorted(AGENTS.glob("*.agent.md")):
        ok, keys = patch_agent(path)
        if ok:
            changed += 1
            print(f"patched {path.name}: +{len(keys)} step(s) [{', '.join(keys)}]")
    print(f"done. {changed} agent file(s) patched.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
