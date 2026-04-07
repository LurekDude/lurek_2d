---
description: "Run CAG validation to check all agents, skills, prompts, and instructions for compliance."
---

# Run CAG Validation

## Purpose

Validate the entire CAG layer using `tools/validate/cag_validate.py`.

## Steps

1. Run `python tools/validate/cag_validate.py` for full validation
2. Review any errors or warnings
3. Fix non-compliant files
4. Re-run validation until clean

## Outputs

- Validation report with errors, warnings, and info
- List of files that need fixing

## Acceptance

- [ ] `python tools/validate/cag_validate.py` reports 0 errors
- [ ] All agents have required frontmatter and sections
- [ ] All skills have matching name/folder
- [ ] All prompts follow verb-noun naming

## References

- `tools-cag-validation` skill
- `CAG-Architect` agent
