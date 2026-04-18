"""Append a canonical Commit step to agents that still lack the
`git add <paths>` / `type(scope): description` pattern in their Workflow."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
AGENTS = ROOT / ".github" / "agents"

TARGETS = ["hacker", "planner", "player", "research", "reviewer", "security", "solver"]
COMMIT_LINE = (
    "**Commit changes**: stage only the specific files (`git add <paths>` — never `git add .`) "
    "and commit using `type(scope): description` (types: feat / fix / refactor / test / docs / chore)."
)


def patch(name: str) -> bool:
    path = AGENTS / f"{name}.agent.md"
    text = path.read_text(encoding="utf-8")
    m = re.search(r"^(##\s+Workflow\s*\n)(.*?)(?=^##\s+|\Z)", text, re.M | re.S)
    if not m:
        return False
    body = m.group(2)
    nums = [int(n) for n in re.findall(r"^(\d+)\.\s", body, re.M)]
    next_n = (max(nums) if nums else 0) + 1
    body_stripped = body.rstrip() + "\n"
    new_body = body_stripped + f"{next_n}. {COMMIT_LINE}\n\n"
    new_text = text[: m.start()] + m.group(1) + new_body + text[m.end():]
    path.write_text(new_text, encoding="utf-8")
    return True


for name in TARGETS:
    print(name, "patched" if patch(name) else "skipped")
