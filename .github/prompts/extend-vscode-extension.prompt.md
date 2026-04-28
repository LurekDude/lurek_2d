---
description: "Extend the VS Code extension."
---

# Extend Vscode Extension

## Goal
- Add a new command, completion provider, or webview panel to the first-party Lurek2D VS Code extension under extensions/vscode/ and rebuild the bundle.

## Inputs
- feature_kind
- feature_name

## Steps
- Load vscode-extension before changing any files.
- Confirm every input listed in this prompt's frontmatter is present in the user invocation.
- Carry out the work as the Developer agent, following the workflow in the loaded skill.
- Run python tools/validate/cag_validate.py and the quality gates listed in quality-pipeline before declaring the prompt done.
- Add a docs/CHANGELOG.md entry under the current version.

## Success Criteria
- [ ] All artifacts named in Goal exist on disk.
- [ ] python tools/validate/cag_validate.py returns no new errors.
- [ ] docs/CHANGELOG.md has a new entry under the current version.

## Anti-patterns
- Skipping the skill-load step listed above.
- Running git add . instead of staging only files this prompt produced.

## Example Invocation
- /extend-vscode-extension <feature_kind> <feature_name>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: vscode-extension
- **Inputs required**: feature_kind, feature_name
