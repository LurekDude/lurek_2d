---
description: "Triage and label GitHub issues using mcp_github_* tools."
mode: agent
loads_skills: [github-workflow]
loads_tools: [tools/validate/cag_validate.py]
expected_agent: Manager
inputs_required: [repo, label_filter]
---

# Triage Github Issues

## Goal

Triage open GitHub issues for the Lurek2D repository — apply correct labels, milestones, and routing — without modifying issue bodies.

## Inputs

- `repo` — value supplied by the user invocation.
- `label_filter` — value supplied by the user invocation.

## Steps

1. Load [skill: github-workflow](.github/skills/github-workflow/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Manager` agent, following the workflow in the loaded skill.
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

> Run this prompt via VS Code Copilot Chat: `/triage-github-issues <repo> <label_filter>`
