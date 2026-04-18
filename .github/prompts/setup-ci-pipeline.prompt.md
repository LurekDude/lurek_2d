---
description: "Add or modify a GitHub Actions workflow for Lurek2D."
mode: agent
loads_skills: [ci-cd-pipeline]
loads_tools: [tools/validate/cag_validate.py]
expected_agent: Developer
inputs_required: [workflow_name, trigger]
---

# Setup Ci Pipeline

## Goal

Add or update a `.github/workflows/*.yml` pipeline that runs the requested job — tests, clippy, dist, docs — on the named trigger.

## Inputs

- `workflow_name` — value supplied by the user invocation.
- `trigger` — value supplied by the user invocation.

## Steps

1. Load [skill: ci-cd-pipeline](.github/skills/ci-cd-pipeline/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Developer` agent, following the workflow in the loaded skill.
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

> Run this prompt via VS Code Copilot Chat: `/setup-ci-pipeline <workflow_name> <trigger>`
