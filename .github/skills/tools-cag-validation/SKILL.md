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
- cag_validate.py already checks frontmatter, required sections, line caps, known agents and skills, prompt wiring, and discovery phrasing, so use its rules as the first explanation for a CAG failure before guessing.
- Use --type skill, --type agent, or a single-file run for fast local isolation, and reserve the full validator pass for cross-file or cross-layer changes that can affect the whole graph.
- cag_link_check.py, cag_coverage.py, and cag_persona_matrix.py complement validation for links, section coverage, and roster health; together they define the broader CAG quality surface.
- In this repo, SKILL.md files should stay code-block free and example-free, so validator work should reinforce that constraint rather than allow special-case exceptions.
- Validator output should stay relative, deterministic, and tied to real repo contracts rather than hypothetical style opinions or environment-specific paths.
- When agent or skill wiring changes, update shared docs and any discovery indexes in the same pass so validators and human guidance remain aligned.
- Distinguish content defects from validator defects: a bad file should be fixed in the file, while a bad rule should be changed only when the repo contract itself has truly changed.
- Validation in this repo is broader than cag_validate.py alone; link, coverage, and persona audits matter whenever relationships, docs, or role boundaries move.
- Prefer read-only validation tools for diagnosis and use fixers separately; mixing correction and checking too early makes rule debugging harder.
- Type-filtered runs are the fastest loop for iterative authoring, but a full pass is still required before closing a multi-file CAG task.
## Companion File Index
- None.

## References
- tools/validate/cag_validate.py
- tools/audit/cag_link_check.py
- tools/audit/cag_coverage.py
- tools/audit/cag_persona_matrix.py
- tools/README.md
