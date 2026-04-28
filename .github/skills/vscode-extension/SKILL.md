---
name: vscode-extension
description: "Load this skill when building, debugging, or extending the VS Code extension in extensions/vscode/. Skip it for engine Rust, game scripts, or non-extension docs."
---
# vscode-extension

## Mission
- Own extension-side commands, data flow, and editor integration behavior.

## When To Load
- Add extension commands.
- Change completion or language features.
- Build a webview or extension UI feature.
- Debug extension behavior.

## When To Skip
- Engine Rust code.
- Game scripts.
- Docs outside the extension scope.

## Domain Knowledge
- Keep extension logic inside extensions/vscode/.
- Match extension data formats to the generated engine-side docs or API data.
- Keep commands and contributions consistent with package.json.
- Prefer small, explicit extension features over broad hidden behavior.
- Regenerate extension API data when extension features depend on generated engine data.
- Validate the extension flow with the repo tooling already in place.

## Companion File Index
- None.

## References
- extensions/vscode/
- extensions/vscode/package.json
- tools/docs/gen_extension_api.py