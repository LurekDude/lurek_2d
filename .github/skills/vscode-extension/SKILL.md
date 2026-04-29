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
- The extension lives under extensions/vscode with commands/, providers/, editors/, services/, generated/, and mcp/ slices.
- package.json is the contract for commands, views, editors, activation, and contributions; code and manifest must move together.
- Generated extension data depends on engine-side generators like gen_extension_api.py and related API artifacts.
- Webview and panel work should respect the current editor and sidebar inventory already declared in package.json.
- Validate build and packaging against tsconfig.json, esbuild.config.mjs, and current extension scripts.
- Do not move engine logic into TypeScript just because the UI lives there.
- The extension already has a large command and panel surface declared in package.json, so feature work should reuse those patterns instead of inventing hidden editor behavior.
- generated/ and mcp/ integration means extension features must stay in sync with engine-side API generation and agent-support tooling.
- This skill owns extension-side TypeScript, manifests, and editor UX, not engine Rust or generic docs.
## Companion File Index
- None.

## References
- extensions/vscode/src/
- extensions/vscode/package.json
- extensions/vscode/esbuild.config.mjs
- tools/docs/gen_extension_api.py
