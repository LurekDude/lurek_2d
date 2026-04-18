# P0 Summary — CAG Audit

_Generated: 2026-04-18 06:43 UTC_

## Top 10 Findings (severity-ranked)

1. System prompt is **297 lines / 24.9 KB** — 177 lines over the 120-line target.
2. **0 orphan skills** with no inbound reference (skills nobody loads).
3. **0 orphan agents** with no inbound reference.
4. **9 broken link targets** across all CAG files.
5. **224 fenced code blocks** spread across **22 SKILL.md files** — must extract to companion files in P3.
6. **11 skills** are not referenced by any prompt — candidate prompt gaps.
7. Frontmatter inconsistency: agents 0/21, skills 0/32, prompts 26/45 have YAML frontmatter.
8. **3 tool paths** referenced in CAG do not exist on disk; **40 tool scripts** on disk are never mentioned by any CAG file.
9. Prompts cluster heavily under prefixes: create(14), fix(7), review(6), analyze(5), workflow(3)
10. Total CAG link graph: **388 edges** across **99 files**; by type: agent-name-ref=135, skill-name-ref=118, tool-mention=90, doc-mention=22, skill-link=8

## Concrete Numbers

- Files: 1 system prompt + 21 agent files (20 agents + README) + 32 skills + 45 prompts.
- Orphan skills: **0**
- Orphan agents: **0**
- Broken link targets: **9**
- Fenced code blocks across SKILL.md files: **224**
- Total link-graph edges: **388**

## Recommendation for P1

- Prioritise the **SKILL.md schema** first (frontmatter `name`/`description`, no fenced code, companion-file rule) — this unblocks the largest single mechanical refactor (P3).
- Co-author the **prompt schema** in the same pass (verb-noun naming, frontmatter `description`/`mode`/`tools`, no inline skill enumeration) so the 45-prompt rewrite in the later phase is mechanical.
- Defer agent schema until skills + prompts are stable (agents reference both).
- Build `tools/validate/cag_link_check.py` early in P2 — broken-link count is the gating metric for every later phase.
