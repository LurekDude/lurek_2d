---
description: "Parse log data and produce game telemetry analytics."
mode: agent
loads_skills: [analytics]
loads_tools: [tools/validate/cag_validate.py]
expected_agent: Research
inputs_required: [log_path, report_focus]
---

# Analyze Game Telemetry

## Goal

Analyse a Lurek2D log or session-event capture and produce a structured analytics report — frame-time histogram, crash frequency, top warning sources — that can drive balance or performance follow-up.

## Inputs

- `log_path` — value supplied by the user invocation.
- `report_focus` — value supplied by the user invocation.

## Steps

1. Load [skill: analytics](.github/skills/analytics/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Research` agent, following the workflow in the loaded skill.
4. Run `python tools/validate/cag_validate.py` and the quality gates listed in [skill: quality-pipeline](.github/skills/quality-pipeline/SKILL.md) before declaring the prompt done.
5. Add a `docs/CHANGELOG.md` entry under the current version.

## Success Criteria

- [ ] All artifacts named in Goal exist on disk.
- [ ] `python tools/validate/cag_validate.py` returns no new errors.
- [ ] `docs/CHANGELOG.md` has a new entry under the current version.

## Anti-patterns

- Skipping the skill-load step listed above.
- Running `git add .` instead of staging only files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/analyze-game-telemetry <log_path> <report_focus>`
