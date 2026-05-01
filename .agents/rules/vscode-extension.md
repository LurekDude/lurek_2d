---
description: "Load when building, debugging, or extending the VS Code extension in extensions/vscode/. Skip for engine Rust, game scripts, or non-extension docs."
alwaysApply: false
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
- The extension lives under extensions/vscode with commands/, providers/, editors/, services/, generated/, mcp/, and related slices.
- package.json is the contract for commands, views, editors, activation, and contributions; code and manifest must move together.
- Generated extension data depends on engine-side generators like gen_extension_api.py.
- Webview and panel work should respect the current editor and sidebar inventory already declared in package.json.
- Validate build and packaging against tsconfig.json, esbuild.config.mjs, and the current extension scripts.
- Do not move engine logic into TypeScript; the extension should orchestrate, present, and integrate.
- New features should reuse existing contribution and service patterns where possible.
- Activation paths and contribution points should stay explicit and minimal.

## References
- extensions/vscode/src/
- extensions/vscode/package.json
- extensions/vscode/esbuild.config.mjs
- tools/docs/gen_extension_api.py
