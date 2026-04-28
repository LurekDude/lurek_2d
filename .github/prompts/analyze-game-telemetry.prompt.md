---
description: "Analyze game telemetry from logs."
---

# Analyze Game Telemetry

## Goal
- Analyse a Lurek2D log or session-event capture and produce a structured analytics report frame-time histogram, crash frequency, top warning sources that can drive balance or performance follow-up.

## Inputs
- log_path
- report_focus

## Steps
- Load analytics before changing any files.
- Confirm every input listed in this prompt's frontmatter is present in the user invocation.
- Carry out the work as the Research agent, following the workflow in the loaded skill.
- Run python tools/validate/cag_validate.py and the quality gates listed in quality-pipeline before declaring the prompt done.
- Add a docs/CHANGELOG.md entry under the current version.

## Success Criteria
- [ ] All artifacts named in Goal exist on disk.
- [ ] python tools/validate/cag_validate.py returns no new errors.
- [ ] docs/CHANGELOG.md has a new entry under the current version.

## Anti-patterns
- Skipping the skill-load step listed above.
- Running git add . instead of staging only files this prompt produced.

## Example Invocation
- /analyze-game-telemetry <log_path> <report_focus>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: analytics
- **Inputs required**: log_path, report_focus
