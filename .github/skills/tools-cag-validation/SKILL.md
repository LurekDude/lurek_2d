---
name: tools-cag-validation
description: "Load this skill when validating, debugging, or maintaining the CAG layer files. It owns the cag_validate.py script usage, validation rules, severity model, and CAG quality standards. Skip it for engine code or game scripts."
---

# CAG Validation Tools — Luna2D Engine

## Load When

- Running `tools/validate/cag_validate.py` to check CAG file compliance
- Debugging validation errors in agents, skills, prompts, or instructions
- Adding new validation rules
- Auditing CAG layer quality

## Owns

- `tools/validate/cag_validate.py` usage and CLI interface
- CAG validation rules and severity model
- Frontmatter format validation
- Required section checking
- Naming convention enforcement

## Does Not Cover

- Engine code quality → use `rust-coding` skill
- CAG content authoring → use `CAG-Architect` agent
- CI/CD pipeline for validation → use `ci-cd-pipeline` skill

## Live Repository Contracts

- `tools/validate/cag_validate.py` — validation script with `--help` documentation
- `.github/agents/*.agent.md` — agent files to validate
- `.github/skills/*/SKILL.md` — skill files to validate
- `.github/prompts/*.prompt.md` — prompt files to validate

## Decision Rules

- **Run before commit**: Always validate after editing any `.github/` file
- **Zero errors required**: All CAG files must pass validation with 0 errors
- **Severity model**: ERROR (must fix), WARNING (should fix), INFO (suggestion)
- **Agent validation**: Check frontmatter (description required), required sections present
- **Skill validation**: Check `name` matches folder name, `description` present, sections exist
- **Prompt validation**: Check verb-noun naming, `description` frontmatter present
- **CLI usage**: `python tools/validate/cag_validate.py --type <agent|skill|prompt>` or `--file <path>`
- **Full validation**: `python tools/validate/cag_validate.py` checks everything

## Tools Script Requirements

These rules apply to all scripts in `tools/` — new scripts must follow them:

### Required Interface

- Every `tools/*.py` script must support `--help` and print a concise usage summary
- Exit code `0` on success, exit code `1` on any failure or validation error
- All user-facing output must be prefixed:

| Prefix | Meaning |
|--------|---------|
| `[OK]` | Validation passed / operation succeeded |
| `[WARN]` | Non-fatal issue (check manually) |
| `[ERROR]` | Failure — script exits 1 |
| `[INFO]` | Informational message |

### Script Design Rules

- **Idempotent**: Same input must always produce the same output and same exit code
- **Read-only validators**: Validator scripts must never modify files in `src/` or `.github/` — they emit reports only
- **Repo root detection**: Use `git rev-parse --show-toplevel` or locate `Cargo.toml` to find the repo root. Never hardcode absolute paths
- **Relative paths in output**: Print paths relative to repo root — not absolute paths — so output is portable

### Python Environment

- Target Python **3.10+** — use `match`, `pathlib`, `argparse`
- Standard library only — no third-party packages unless listed in `requirements.txt`
- Avoid importing virtualenv, `setuptools`, or any package not bundled with CPython

### Avoid

- Absolute paths (`C:/Users/...`, `/home/...`) anywhere in scripts
- Requiring a virtualenv or `pip install` step not documented in `tools/README.md`
- Writing to `src/` or `.github/` from a validator
- Silently ignoring parse errors — parse errors should emit `[WARN]` or `[ERROR]` and exit 1
