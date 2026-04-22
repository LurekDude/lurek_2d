---
name: vscode-extension
description: "Load this skill when building, debugging, or extending the Lurek2D VS Code extension in extensions/vscode/. Use for: adding IntelliSense completions, MCP server endpoints, webview panels, new commands, extension configuration, or publishing. Skip it for engine Rust code, game scripting, or documentation outside the extension."
---
# vscode-extension

## Mission

# VS Code Extension — Lurek2D

## When To Load

- Adding IntelliSense completions for `lurek.*` API functions
- Implementing new MCP server endpoints or tools
- Creating or modifying webview panels
- Adding VS Code commands (`lurek2d.*`)
- Debugging extension activation or provider errors
- Publishing the extension or updating the manifest

## When To Skip

- Skip it for engine Rust code, game scripting, or documentation outside the extension.

## Domain Knowledge

### Owns
- VS Code extension activation and command registration
- IntelliSense provider architecture (`completionProvider`, `hoverProvider`, `luacatsProvider`)
- MCP server implementation (`extensions/vscode/src/mcp/server.ts`)
- Extension packaging, testing, and publishing workflow

### Extension Layout
> See [snippets/extension-layout.txt](snippets/extension-layout.txt) for the example.

### IntelliSense Architecture
- **User-defined class completions**: parsed from LuaCATS annotations (`---@class`, `---@param`, `---@return`, `---@field`) in game Lua files via `luacatsProvider.ts`

### Development Loop
> See [snippets/development-loop.ps1](snippets/development-loop.ps1) for the example.

### Build and Package
> See [snippets/build-and-package.ps1](snippets/build-and-package.ps1) for the example.

### MCP Server
The MCP server exposes Lurek2D engine capabilities to AI agents:

- Defined in `extensions/vscode/src/mcp/server.ts`
- Methods follow JSON-RPC 2.0 over stdio
- Add new MCP tools by registering handler functions in `extensions/vscode/src/mcp/server.ts`
- Reference `docs/` and `logs/lua_api_data.json` for available API surface

### Adding a New Command
1. Register in `package.json` under `contributes.commands`
2. Add activation in `activationEvents` if needed
3. Implement handler in `extension.ts` — `vscode.commands.registerCommand("lurek2d.yourCmd", () => { ... })`
4. Test in Extension Development Host (F5)

### Adding a New Completion Source
1. Parse source data in `services/apiData.ts`
2. Return `vscode.CompletionItem[]` from `completionProvider.ts`
3. Register the provider in `extension.ts` with correct trigger characters and language selector (`lua`)

### Testing the Extension
> See [snippets/testing-the-extension.ps1](snippets/testing-the-extension.ps1) for the example.

- Tests run via `npm run test` (vscode test runner)
- Use `@vscode/test-electron` for integration tests against real VS Code API

### Anti-Patterns
- **Hard-coding lurek.* lists**: Always derive completions from `logs/lua_api_data.json` — never maintain a hand-written list alongside the generated source
- **Blocking the main thread**: Use `async/await` for file I/O in providers — VS Code providers are called synchronously but can return `Promise`
- **Skipping activation guards**: Check `context.subscriptions` and dispose providers on deactivation to prevent memory leaks

## Companion File Index

- [snippets/extension-layout.txt](snippets/extension-layout.txt) — Extension Layout
- [snippets/development-loop.ps1](snippets/development-loop.ps1) — Development Loop
- [snippets/build-and-package.ps1](snippets/build-and-package.ps1) — Build and Package
- [snippets/testing-the-extension.ps1](snippets/testing-the-extension.ps1) — Testing the Extension

## References

- See related skills in `.github/skills/`.
