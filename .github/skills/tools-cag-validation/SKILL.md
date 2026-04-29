---
name: tools-cag-validation
description: "Load this skill when validating, debugging, or maintaining CAG files and cag_validate.py rules. Skip it for engine code or game scripts."
---
# tools-cag-validation

## Mission
- Own cag_validate.py usage, rule meaning, and CAG validation standards.

## When To Load
- Run cag_validate.py.
- Debug agent, skill, prompt, or system-prompt validation errors.
- Review CAG file quality.

## When To Skip
- Engine code quality.
- General CAG authoring only.
- CI/CD workflow setup.

## Domain Knowledge
- cag_validate.py already checks frontmatter, required sections, line caps, known agents/skills, and prompt wiring.
- Use --type skill for fast skill-only passes and a full run after cross-file or cross-layer changes.
- cag_link_check.py, cag_coverage.py, and cag_persona_matrix.py complement validation for links, section coverage, and roster health.
- In this repo, SKILL.md files should stay code-block free and example-free.
- Validator output should stay relative, deterministic, and tied to real repo contracts rather than hypothetical policy.
- When agent or skill wiring changes, update shared docs as part of the same validation pass.
- Validation in this repo is broader than cag_validate.py alone; link, coverage, and persona audits matter whenever the graph or docs move.
- The skill should keep validators deterministic, read-only, and aligned with actual repo rules rather than one-off style opinions.
- It owns the validation surface for CAG files, not generic project quality tooling.
## Companion File Index
- None.

## References
- tools/validate/cag_validate.py
- tools/audit/cag_link_check.py
- tools/audit/cag_coverage.py
- tools/audit/cag_persona_matrix.py
- tools/README.md
