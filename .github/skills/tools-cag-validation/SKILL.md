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
- Validate after every .github change.
- Aim for 0 errors and 0 warnings.
- Use python tools/validate/cag_validate.py --type agent|skill|prompt|system_prompt.
- Use --file for one file.
- Full run checks the whole CAG layer.
- Validators should be read-only.
- Tools should support --help.
- Use exit code 0 on success and 1 on failure.
- Prefer relative paths in output.
- Do not hardcode repo paths.
- Target Python 3.10+ and standard library only unless tools/README.md says otherwise.
- Do not ignore parse errors silently.

## Companion File Index
- None.

## References
- tools/validate/cag_validate.py
- tools/README.md
