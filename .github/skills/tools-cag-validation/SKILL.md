---
name: tools-cag-validation
description: "Load this skill when validating, debugging, or maintaining the CAG layer files. It owns the cag_validate.py script usage, validation rules, severity model, and CAG quality standards. Skip it for engine code or game scripts."
---

# CAG Validation Tools — Luna2D Engine

## Load When

- Running `tools/cag_validate.py` to check CAG file compliance
- Debugging validation errors in agents, skills, prompts, or instructions
- Adding new validation rules
- Auditing CAG layer quality

## Owns

- `tools/cag_validate.py` usage and CLI interface
- CAG validation rules and severity model
- Frontmatter format validation
- Required section checking
- Naming convention enforcement

## Does Not Cover

- Engine code quality → use `rust-coding` skill
- CAG content authoring → use `CAG-Architect` agent
- CI/CD pipeline for validation → use `ci-cd-pipeline` skill

## Live Repository Contracts

- `tools/cag_validate.py` — validation script with `--help` documentation
- `.github/agents/*.agent.md` — agent files to validate
- `.github/skills/*/SKILL.md` — skill files to validate
- `.github/prompts/*.prompt.md` — prompt files to validate
- `.github/instructions/*.instructions.md` — instruction files to validate

## Decision Rules

- **Run before commit**: Always validate after editing any `.github/` file
- **Zero errors required**: All CAG files must pass validation with 0 errors
- **Severity model**: ERROR (must fix), WARNING (should fix), INFO (suggestion)
- **Agent validation**: Check frontmatter (description required), required sections present
- **Skill validation**: Check `name` matches folder name, `description` present, sections exist
- **Prompt validation**: Check verb-noun naming, `description` frontmatter present
- **Instruction validation**: Check `applyTo` glob present, `description` present
- **CLI usage**: `python tools/cag_validate.py --type <agent|skill|prompt|instruction>` or `--file <path>`
- **Full validation**: `python tools/cag_validate.py` checks everything
