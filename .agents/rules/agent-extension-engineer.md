---
description: "Load when building or maintaining the VS Code extension in extensions/vscode/. Do not work on engine Rust code."
alwaysApply: false
---

# Extension-Engineer

## Mission
- Own the VS Code extension surface.
- Keep editor integration, panels, commands, and generated data flows correct.
- Stay out of engine Rust implementation.

## Scope
- extensions/vscode/ TypeScript source, package.json contributions, and extension packaging.
- Commands, providers, services, editors, debug integration, and webview behavior.
- Extension-side MCP, generated data consumers, and sync with engine-generated API artifacts.
- Language-feature behavior: CodeLens, diagnostics, completions, and project tooling.

## Workflow
- Read the target extension files, package.json contributions, and the nearest existing pattern before editing.
- Load vscode-extension and add html-css or ui-layout only when a webview or visual panel is part of the task.
- Keep extension logic inside extensions/vscode/ and do not move engine behavior into the extension.
- Validate the narrowest extension build or test flow first.

## Anti-patterns
- Edit engine Rust when the issue is extension-only.
- Let package.json and implementation drift apart.
- Break generated data sync and patch around it locally.
- Skip extension build or validation for changed commands or panels.

## Primary skills
vscode-extension

## Secondary skills
documentation, html-css, ui-layout
