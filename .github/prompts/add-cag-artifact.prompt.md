---
description: "Author a new agent, skill, or prompt following CAG standards."
agent: CAG-Architect
tools: [tools/validate/cag_validate.py]
---
# Add Cag Artifact

## Goal

Add a new agent, skill, or prompt under `.github/` that conforms to the CAG standards in `work/cag-system-overhaul-20260418/reports/standards/` and passes `tools/validate/cag_validate.py` with no new errors.

## Inputs

- `artifact_type` — value supplied by the user invocation.
- `name` — value supplied by the user invocation.

## Steps

1. Load [skill: cag-workflow](.github/skills/cag-workflow/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `CAG-Architect` agent, following the workflow in the loaded skill.
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

> Run this prompt via VS Code Copilot Chat: `/add-cag-artifact <artifact_type> <name>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: cag-workflow
- **Inputs required**: artifact_type, name
