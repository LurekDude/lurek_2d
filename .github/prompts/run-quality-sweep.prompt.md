---
description: "Execute the audit-fix-verify quality sweep across the repo."
mode: agent
loads_skills: [quality-pipeline]
loads_tools: [tools/validate/cag_validate.py]
expected_agent: Reviewer
inputs_required: [scope]
---

# Run Quality Sweep

## Goal

Run the audit-fix-verify quality sweep over the named scope — modules, docs, tests, examples — and produce a report listing remaining defects and the agents that own them.

## Inputs

- `scope` — value supplied by the user invocation.

## Steps

1. Load [skill: quality-pipeline](.github/skills/quality-pipeline/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Reviewer` agent, following the workflow in the loaded skill.
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

> Run this prompt via VS Code Copilot Chat: `/run-quality-sweep <scope>`
