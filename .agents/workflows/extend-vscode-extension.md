---
description: "Extend the VS Code extension with one new command, panel, language feature, or data integration."
---

# Extend VSCode Extension

## Goal
- Add one well-scoped extension feature without breaking existing editor integration.

## Inputs
- Feature goal.
- Target component (command, provider, editor, webview, MCP).
- Required package.json contribution.
- Acceptance gate.

## Steps
1. Load vscode-extension before acting.
2. Read extensions/vscode/src/, package.json, and the nearest existing component before editing.
3. Add the command or contribution point in package.json first, then implement the TypeScript side.
4. Refresh generated extension data if the feature depends on engine-generated artifacts.
5. Run the narrowest extension build or test flow.

## Success Criteria
- [ ] package.json and implementation are in sync.
- [ ] Generated extension data is refreshed or verified.
- [ ] The changed UX has narrow build or test proof.
- [ ] No engine Rust was touched.

## Anti-patterns
- Add hidden extension behavior with no command or contribution contract.
- Let package.json and implementation drift apart.
- Move engine logic into TypeScript.

## Example Invocation
- /extend-vscode-extension goal=run_demo_command component=command
