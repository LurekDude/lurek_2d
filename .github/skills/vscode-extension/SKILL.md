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
- The extension lives under extensions/vscode with commands/, providers/, editors/, services/, generated/, mcp/, and related slices, so changes should land in the owning layer rather than one oversized utility module.
- package.json is the contract for commands, views, editors, activation, and contributions; code and manifest must move together or the feature does not really exist for users.
- Generated extension data depends on engine-side generators like gen_extension_api.py and related API artifacts, so extension work often has cross-repo sync requirements.
- Webview and panel work should respect the current editor and sidebar inventory already declared in package.json instead of inventing hidden surfaces or duplicate entry points.
- Validate build and packaging against tsconfig.json, esbuild.config.mjs, and the current extension scripts so changes remain compatible with the actual toolchain.
- Do not move engine logic into TypeScript just because the UI lives there; the extension should orchestrate, present, and integrate, not reimplement engine behavior.
- The extension already has a wide command and panel surface, so new features should reuse existing contribution and service patterns where possible.
- generated/ and mcp/ integration means extension features must stay in sync with engine-side API generation, debugbridge assumptions, and agent-support tooling.
- Activation paths and contribution points should stay explicit and minimal; unnecessary startup work in an extension hurts editor responsiveness quickly.
- Good extension work here keeps TypeScript responsibilities narrow, UI behavior discoverable from package.json, and service wiring readable.
## Companion File Index
- None.

## References
- extensions/vscode/src/
- extensions/vscode/package.json
- extensions/vscode/esbuild.config.mjs
- tools/docs/gen_extension_api.py
