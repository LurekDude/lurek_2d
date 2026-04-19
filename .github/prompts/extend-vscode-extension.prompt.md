---
description: "Add a command, completion, or webview to extensions/vscode/."
agent: Developer
tools: [tools/validate/cag_validate.py]
---
# Extend Vscode Extension

## Goal

Add a new command, completion provider, or webview panel to the first-party Lurek2D VS Code extension under `extensions/vscode/` and rebuild the bundle.

## Inputs

- `feature_kind` — value supplied by the user invocation.
- `feature_name` — value supplied by the user invocation.

## Steps

1. Load [skill: vscode-extension](.github/skills/vscode-extension/SKILL.md) before changing any files.
2. Confirm every input listed in this prompt's frontmatter is present in the user invocation.
3. Carry out the work as the `Developer` agent, following the workflow in the loaded skill.
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

> Run this prompt via VS Code Copilot Chat: `/extend-vscode-extension <feature_kind> <feature_name>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: vscode-extension
- **Inputs required**: feature_kind, feature_name
