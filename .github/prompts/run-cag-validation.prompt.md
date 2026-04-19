---
description: "Run CAG validation to check all agents, skills, prompts, and instructions for compliance."
agent: Developer
tools: [tools/validate/cag_validate.py]
---
# Run Cag Validation

## Goal

Validate the entire CAG layer using `tools/validate/cag_validate.py`.

## Inputs

- (none) — this prompt takes no required arguments.

## Steps

1. Load [skill: tools-cag-validation](.github/skills/tools-cag-validation/SKILL.md) before changing any files.
2. Run `python tools/validate/cag_validate.py` for full validation
3. Review any errors or warnings
4. Fix non-compliant files
5. Re-run validation until clean

## Success Criteria

- [ ] Validation report with errors, warnings, and info
- [ ] List of files that need fixing

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/run-cag-validation`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: tools-cag-validation
