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
- Layer ownership in extensions/vscode/src/: `commands/` handles VS Code command registration and entry points; `providers/` implements language providers (completion, hover, diagnostics); `editors/` implements custom editors and webviews; `services/` holds extension-side business logic and state; `generated/` holds files produced by engine-side generators; `mcp/` holds MCP server integration. Do not mix responsibilities across layers.
- `package.json` is the contract between the extension and VS Code. Every command, view, editor type, activation event, and contribution point must be declared there. Code that registers a command not in `package.json` is invisible to users and discoverable only by accident.
- Build and test commands: `npm run build` (esbuild bundle), `npm run watch` (incremental), `npm test` (extension test harness). Run these from `extensions/vscode/`. The root `tools/dev/parallel_cargo.py` does not manage the extension.
- Generated data under `extensions/vscode/src/generated/` comes from `python tools/docs/gen_extension_api.py`. Never hand-edit generated files — fix the generator or its data source. If generated data seems stale, regenerate and commit both.
- MCP integration in `mcp/` expects specific message shapes defined in `src/debugbridge/`. Changes to debugbridge message types require synchronized updates to the MCP handler. Check `docs/specs/debugbridge.md` for the wire format before changing either side.
- Activation cost rule: extensions/vscode must activate lazily. Contribution points with `onCommand:` activation are preferred. `*` activation (activate on any VS Code start) is a performance defect. Check `activationEvents` in `package.json` after any activation change.
- Webview content security policy: all webview HTML must include a CSP `<meta>` tag. No inline scripts. No external resource loads. Use `vscode-resource:` URIs for local assets. A webview without a CSP header is a security defect.
- Extension-Rust boundary: the extension communicates with the engine exclusively through the debug bridge protocol over stdio or a local socket — never by importing Rust types directly into TypeScript or vice versa. If data needs to cross this boundary, define a message type in the protocol spec.
- After any `package.json` contribution point change, run `vsce package` to validate the manifest schema and confirm the extension packages without errors before committing.
- `A-01` applies here: the extension is a developer-experience layer, not part of the engine binary. Engine behavior must not depend on extension presence. Test engine functionality without the extension loaded.
## Companion File Index
- None.

## References
- extensions/vscode/src/
- extensions/vscode/package.json
- extensions/vscode/esbuild.config.mjs
- tools/docs/gen_extension_api.py
