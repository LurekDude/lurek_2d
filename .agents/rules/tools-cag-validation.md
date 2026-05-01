---
description: "Load when validating, debugging, or maintaining .agents/ rules/workflows validation. Skip for engine code or game scripts."
alwaysApply: false
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
- cag_validate.py already checks frontmatter, required sections, line caps, known agents and skills, prompt wiring, and discovery phrasing; use its rules as the first explanation for a failure before guessing.
- Use --type skill, --type agent, or a single-file run for fast local isolation, and reserve the full validator pass for cross-file changes.
- cag_link_check.py, cag_coverage.py, and cag_persona_matrix.py complement validation for links, section coverage, and roster health.
- Validator output should stay relative, deterministic, and tied to real repo contracts.
- When agent or skill wiring changes, update shared docs and any discovery indexes in the same pass.
- Distinguish content defects from validator defects: a bad file should be fixed in the file, while a bad rule should be changed only when the repo contract itself has truly changed.
- Prefer read-only validation tools for diagnosis and use fixers separately.
- A full pass is still required before closing a multi-file task.

## References
- tools/validate/cag_validate.py
- tools/audit/cag_link_check.py
- tools/audit/cag_coverage.py
- tools/audit/cag_persona_matrix.py
- tools/README.md
