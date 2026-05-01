# Lurek2D — VS Code Extension Architecture

Architecture for the `extensions/vscode/` extension. All content reflects the real source files.

Companion documents: [engine-architecture.md](engine-architecture.md) · [cag-system.md](cag-system.md)

**Constraint A-01 reminder:** The VS Code extension is an opt-in developer experience layer — not part of the engine binary. The engine works without it.

---

## Table of Contents

1. [Identity and Activation](#identity-and-activation)
2. [Source Layout](#source-layout)
3. [Core Architecture](#core-architecture)
4. [Service Layer](#service-layer)
5. [Language Providers](#language-providers)
6. [Sidebar and Monitoring](#sidebar-and-monitoring)
7. [Commands](#commands)
8. [Webview Editors](#webview-editors)
9. [Debug Adapter](#debug-adapter)
10. [MCP Server](#mcp-server)
11. [Data Flow](#data-flow)
12. [Key Data Types](#key-data-types)
13. [Build and Packaging](#build-and-packaging)
14. [Configuration Settings](#configuration-settings)
15. [Protocols](#protocols)

---

## Identity and Activation

| Field | Value |
|-------|-------|
| Package name | `lurek2d-toolkit` |
| Display name | Lurek2D |
| Description | AI-first IDE support for Lurek2D game engine |
| Version | 0.9.0 |
| VS Code engine | `^1.90.0` |
| Language | TypeScript (esbuild bundled) |
| Source root | `extensions/vscode/src/` |
| Output | `extensions/vscode/dist/extension.js` |

The extension activates when VS Code detects:

```jsonc
"activationEvents": [
  "workspaceContains:**/main.lua",  // game project open
  "workspaceContains:Cargo.toml"   // engine source open
]
```

On activation (`extension2.ts → activate()`):
1. Creates status bar item `$(rocket) Lurek2D`
2. Registers commands, providers, sidebar tree views, debug adapter
3. Starts the MCP server via `startMcpServer(workspaceRoot)`

On deactivation: kills the MCP server process if running.

**Active entry point:** `extension2.ts` (full provider + command registration). `extension.ts` is a legacy entry point with limited commands.

---

## Source Layout

```
extensions/vscode/src/
├── extension.ts           Legacy entry point (4 commands only)
├── extension2.ts          Active entry point — full registration
├── commands/              Command implementations (12 modules)
│   ├── cag.ts             CAG layer install command
│   ├── debugBridge.ts     Debug bridge connect/disconnect/inspect
│   ├── editors.ts         Open webview editor commands
│   ├── run.ts             Run/stop/runWithArgs/runExample
│   ├── scaffold.ts        New project / new file scaffold
│   ├── test.ts            Run tests command
│   └── ...
├── debug/                 Debug adapter (DAP)
│   ├── luaDebugAdapter.ts   Factory + ConfigProvider
│   └── luaDebugSession.ts   Inline DAP session
├── editors/               Webview panel editors (29 editors)
│   ├── shared.ts            WebviewEditor base class
│   ├── tileMapEditor.ts
│   ├── particleEditor.ts
│   └── ...
├── mcp/                   MCP server
│   ├── server.ts            startMcpServer() / runStdioServer()
│   └── tools.ts             6 MCP tool definitions
├── providers/             VS Code language feature providers (26 providers)
│   ├── apiData.ts, completion.ts, hover.ts, diagnostics.ts, ...
│   └── ...
├── services/              Shared singleton services
│   ├── apiData.ts           ApiDataService
│   ├── debugBridge.ts       DebugBridge (TCP to engine port 19740)
│   ├── luaParser.ts         LuaDocumentAnalyzer
│   ├── lunaProcess.ts       LunaProcessService
│   ├── statusBar.ts         Status bar helpers
│   └── symbolIndex.ts       Workspace-wide Lua symbol index
├── test/                  Extension test infrastructure
│   ├── mocks/vscode.ts      Mock VS Code API objects
│   └── unit/                TypeScript unit tests
└── cag/game-dev/          Bundled game-dev CAG layer
```

---

## Core Architecture

```
extension2.ts
  │
  ├── Services (singletons)
  │   ApiDataService · LuaDocumentAnalyzer · LunaProcessService
  │   DebugBridge · SymbolIndex
  │
  ├── 26 Language Providers
  │   IntelliSense: Completion · Hover · Signature · Definition
  │                 References · Rename · Symbols · InlayHints
  │                 SemanticTokens · CodeActions · CodeLens
  │                 Diagnostics · Folding · Formatting · Color
  │                 AssetPath · LuaCATS · LuaJIT · TypeInference
  │   Sidebar: ProjectTools · DevTools · AssetExplorer
  │   Monitoring: PerfDashboard · SystemMonitor · RequireGraph
  │               ApiUsage
  │
  ├── 12 Command Modules
  │   run · scaffold · editors · debugBridge · cag · library
  │   packaging · reference · test · testGenerator · gameJam · gameDevCag
  │
  ├── Debug Adapter (DAP)
  │   LuaDebugAdapterFactory · LuaDebugSession
  │
  └── MCP Server
      JSON-RPC stdio → 6 tools exposed to AI agents
```

---

## Service Layer

| Service | File | Responsibility |
|---------|------|---------------|
| `ApiDataService` | `services/apiData.ts` | Parses `docs/lua-api.md` and `api_data.json`. Provides `getFunction()`, `getModule()`, `getAllFunctions()`, `searchFunctions()`. Exposes built-in enum stubs for `DrawMode`, `BodyType`, `BlendMode`, `FilterMode`, etc. |
| `LuaDocumentAnalyzer` | `services/luaParser.ts` | Full Lua tokeniser → `LuaDocumentInfo` (symbols, requires, callbacks, scopes, comments). Cached per document version. |
| `LunaProcessService` | `services/lunaProcess.ts` | Resolves `lurek2d` binary (user setting → PATH → `cargo run`). Runs game in integrated terminal. Emits `onStatusChange` events. |
| `DebugBridge` | `services/debugBridge.ts` | TCP socket client → running engine on port 19740. JSON request/response with per-request timeouts. Live stats in status bar when connected. |
| `SymbolIndex` | `services/symbolIndex.ts` | Regex-based workspace-wide Lua symbol index. Indexes `*.lua` files for functions, methods, table classes, constants. Updated incrementally on file change. |

---

## Language Providers

All providers target `{ scheme: "file", language: "lua" }`.

### IntelliSense

| Provider | Contributes |
|----------|------------|
| **Completion** | `lurek.*` API functions, Lua built-ins (25), stdlib modules, key names (50+), string context enums (blend modes, body types, etc.), LuaCATS `@type` instances |
| **Hover** | Markdown cards for `lurek.*` functions and modules, all Lua keywords with examples, math constants, LuaCATS class/field hover |
| **Signature Help** | Parameter list for `lurek.*` calls, cursor-tracking to highlight active param |
| **Definition** | `lurek.*` names → virtual `lurek-api://` document; local Lua symbols → `SymbolIndex` |
| **References** | Find-all-references for Lua symbols across workspace |
| **Rename** | Safe symbol rename across workspace |
| **Symbols** | Document outline + workspace symbol search |
| **Inlay Hints** | Parameter name hints at `lurek.*` call sites (≥2 args); toggled by `lurek.inlayHints.enabled` |
| **Semantic Tokens** | 16 token types: `namespace`, `function`, `method`, `parameter`, `variable`, `property`, `keyword`, `string`, `number`, `comment`, `operator`, `type`, `enumMember`, `macro`, `decorator`, `event`. Cached per document version. |
| **Code Actions** | Quick fixes (auto-import, correct API name) |
| **Code Lens** | Function reference count; lurek callback functions get `⚡ lurek.X callback` lens |
| **Diagnostics** | 13 rules, debounced 300ms: deprecated API, color out-of-range, unused require, missing asset, `math.random` in thread, missing callback, wrong enum string, unknown `lurek.*` name, invalid conf.lua field, per-frame allocation, missing `test_summary()`, nil entity access, colon-vs-dot suggestion |
| **Folding** | `function/end`, `if/end`, comment blocks |
| **Formatting** | Document formatter for Lua files |
| **Color** | Inline colour swatch for `lurek.renders.setColor(r, g, b)` calls |
| **Asset Path** | Path completion inside string arguments resolving to workspace assets |
| **LuaCATS** | Parses `---@class`, `---@field`, `---@param`, `---@return`, `---@type`. Builds per-document class registry with inheritance. Powers completions and hover for user-defined class instances. |
| **LuaJIT Hints** | LuaJIT-specific hints (FFI, bit ops) |
| **Type Inference** | Tracks 25+ factory return types (`Image`, `Canvas`, `Font`, `Shader`, `Entity`, `Timer`, `Tween`, `World`, `Body`, `ParticleSystem`, etc.), OOP instances via `setmetatable`, module aliases (`local gfx = lurek.renders`). Provides dot/colon access completions and hover with type origin. |

---

## Sidebar and Monitoring

### Sidebar Tree Views

| Provider | Sidebar sections |
|----------|-----------------|
| `ProjectToolsProvider` | Project Health (main.lua detection, file count); Create (New Project, New File); Package; Libraries |
| `DevToolsProvider` | Run (game status, run/stop/run-with-args); Debug (connect/disconnect/inspect); Testing (last result, run all) |
| `AssetExplorerProvider` | Workspace assets filtered by type (images, audio, fonts, shaders); items show file size and open on click |

### Monitoring Webview Panels

| Panel | Content |
|-------|---------|
| **Performance Dashboard** | Rolling 300-sample FPS, frame time, Lua heap size chart |
| **System Monitor** | Rolling 120-sample CPU%, RAM, lurek process CPU+RAM, GPU%, VRAM, disk I/O, network rates |
| **Require Graph** | Interactive `require()` dependency graph across Lua files |
| **API Usage** | `lurek.*` function usage frequency across workspace |

---

## Commands

| Module | Functions |
|--------|----------|
| `commands/run.ts` | `runGame()`, `stopGame()`, `runWithArgs()`, `runExample()` — delegate to `LunaProcessService` |
| `commands/scaffold.ts` | New project from template (Minimal / Game Loop / Physics / …); new file from template |
| `commands/editors.ts` | Opens any webview editor by name |
| `commands/debugBridge.ts` | Connect/disconnect bridge; inspect globals, performance, logs |
| `commands/cag.ts` | Installs bundled CAG layer to workspace `.github/` |
| `commands/library.ts` | Lunasome library management |
| `commands/packaging.ts` | Build and package for distribution |
| `commands/reference.ts` | Opens API reference editor panel |
| `commands/test.ts` | Runs test suite |
| `commands/testGenerator.ts` | Generates test stubs from `lurek.*` API usage |
| `commands/gameJam.ts` | Game jam project scaffold |
| `commands/gameDevCag.ts` | Game-dev CAG helper commands |

**Currently contributed in `package.json`** (4 commands):

| Command ID | Title |
|------------|-------|
| `lurek2d.runExample` | Lurek2D: Run Example |
| `lurek2d.listExamples` | Lurek2D: List Examples |
| `lurek2d.checkBuild` | Lurek2D: Check Build |
| `lurek2d.getApiDoc` | Lurek2D: Get API Documentation |

The full command set is implemented but not yet all contributed in `package.json`.

---

## Webview Editors

All 29 editors inherit from `WebviewEditor` (`editors/shared.ts`), which provides:
- `vscode.WebviewPanel` creation with `enableScripts: true`
- `getNonce()` for CSP nonces
- `wrapHtml(nonce, title, css, body)` for VS Code-themed HTML
- `exportLua()` / `exportToml()` helpers for writing generated files to workspace
- Abstract `getHtml(): string` and `handleMessage(msg)` hooks

Editors are webview-only (HTML canvas + vanilla JS). They generate Lua or TOML output written to the workspace via the extension host.

| Editor | Exports |
|--------|---------|
| `TileMapEditor` | `tilemap.lua` or `tilemap.toml` |
| `ParticleEditor` | Particle system config |
| `DialogEditor` | Branching dialogue tree |
| `EntityEditor` | Entity component layout |
| `PixelArtEditor` | Sprite / pixel art |
| `SceneFlowEditor` | Scene state machine |
| `AiBehaviorEditor` | AI behaviour tree |
| `SpriteAnimEditor` | Sprite animation frames |
| `ShaderPreviewEditor` | WGSL shader (live preview) |
| `ApiReferenceEditor` | Reads `docs/lua-api.md` |
| `TimelineEditor` | Cutscene / timeline |
| `QuestTreeEditor` | Quest / event tree |
| + 17 more | (see source layout above) |

---

## Debug Adapter

**`debug/luaDebugAdapter.ts`** — `LuaDebugAdapterFactory` (creates inline sessions) + `LuaDebugConfigurationProvider`. Provides 4 launch configurations:
- Debug Game
- Debug Current Demo
- Debug with Stop on Entry
- Attach to Running

Auto-detects game path (nearest `main.lua`), auto-detects engine binary from `build/debug/` and `build/release/`. Default: type `lurek`, request `launch`, `luaVersion = "luajit"`, `debugPort = 8172`, `stopOnEntry = false`.

**`debug/luaDebugSession.ts`** — `LuaDebugSession extends DebugSession`. Implements DAP protocol inline. Connects to engine debug socket on configured port.

**`services/debugBridge.ts`** — separate higher-level TCP channel (port 19740) for non-DAP debug commands (inspect globals, watch performance, fetch logs).

---

## MCP Server

`src/mcp/` implements the [Model Context Protocol](https://modelcontextprotocol.io) to expose Lurek2D tools to AI agents (GitHub Copilot, Claude, etc.).

`mcp/server.ts` has two entrypoints:
- `startMcpServer(workspaceRoot)` — called from `extension.ts`; returns `{ kill() }` handle.
- `runStdioServer(workspaceRoot)` — reads newline-delimited JSON-RPC from stdin, writes to stdout; used when launched as a standalone Node.js process.

Both dispatch `initialize`, `tools/list`, and `tools/call` JSON-RPC methods.

`mcp/tools.ts` defines 6 MCP tools:

| Tool | Description |
|------|-------------|
| `lurek2d.runExample` | Build and run a named demo, return output |
| `lurek2d.getApiDoc` | Search `lurek.*` API documentation |
| `lurek2d.listExamples` | List all demo directories |
| `lurek2d.runLuaTest` | Run a Lua test file against the debug build |
| `lurek2d.checkBuild` | Run `cargo check`, return compiler diagnostics |
| `lurek2d.getLogs` | Return last N lines of engine log output |

---

## Data Flow

```
Workspace Lua files
  │
  ├──▶ LuaDocumentAnalyzer (luaParser.ts)
  │       Tokeniser → LuaDocumentInfo (symbols, requires, callbacks, scopes)
  │         ├── completion.ts      (lurek.* + builtins + LuaCATS)
  │         ├── hover.ts           (keyword + API hover cards)
  │         ├── diagnostics.ts     (13 rules, debounced 300ms)
  │         ├── semanticTokens.ts  (16-type token classification)
  │         ├── codeLens.ts        (ref counts + callback labels)
  │         ├── inlayHints.ts      (parameter name hints)
  │         └── definition.ts     (local symbol go-to)
  │
  ├──▶ typeInference.ts
  │       VarType[] + ClassInfo[] + ModuleAlias[]
  │         ├── dot-access completions
  │         ├── colon-access completions
  │         └── hover (type + factory origin)
  │
  ├──▶ ApiDataService (apiData.ts — from docs/lua-api.md)
  │       ApiModule[] / ApiFunction[] / ApiEnum[]
  │         ├── completion, hover, signature, diagnostics
  │         ├── inlayHints, apiReferenceEditor
  │
  ├──▶ LunaProcessService (lunaProcess.ts)
  │       findLunaBinary() → user setting → PATH → cargo run
  │       run(gameDir) → integrated terminal
  │
  ├──▶ DebugBridge (debugBridge.ts)
  │       TCP → 127.0.0.1:19740 → running engine
  │       inspect globals, performance counters, logs
  │
  └──▶ MCP Server (mcp/)
        JSON-RPC stdio ← AI agent hosts (Copilot, Claude)
        6 tools: run, doc-search, list, test, build-check, logs
```

---

## Key Data Types

```typescript
// ApiDataService types (services/apiData.ts)
interface ApiParam {
  name: string; type: string; description: string;
  optional: boolean; default?: string;
}
interface ApiFunction {
  module: string; name: string; fullPath: string;
  signature: string; description: string;
  parameters: ApiParam[]; returns?: string; returnType?: string;
  since?: string; deprecated?: string;
  isMethod: boolean; objectType?: string;
}

// LuaParser types (services/luaParser.ts)
interface LuaSymbol {
  name: string;
  kind: "function" | "local" | "global" | "table" | "method" | "parameter" | "field";
  line: number; column: number; endLine?: number;
  scope?: string; type?: string;
  parameters?: string[]; isLocal: boolean;
}
interface LuaDocumentInfo {
  symbols: LuaSymbol[];
  requires: RequireInfo[];   // module path + line
  callbacks: LuaSymbol[];   // lurek.load, lurek.update, etc.
  scopes: ScopeInfo[];      // function / if / for / while / repeat
  comments: CommentInfo[];  // text, line, isBlock, isLuaCATS
}
```

---

## Build and Packaging

| Script | Command |
|--------|---------|
| Bundle | `node esbuild.config.mjs` → `dist/extension.js` |
| Watch | `node esbuild.config.mjs --watch` |
| Package | `npm run package` → `npx @vscode/vsce package --no-dependencies` → `.vsix` |
| Test | `npm run test` → builds test bundle + launches VS Code test electron |

**Runtime dependency:** `@modelcontextprotocol/sdk ^1.0.0` only.

### Test Infrastructure

- **Unit tests** (`src/test/unit/`): Pure TypeScript with mock VS Code objects (`src/test/mocks/vscode.ts`). Test `typeInference`, `luaParser`.
- **Integration tests** (`src/test/suite/`): Run via `@vscode/test-electron` in a real VS Code instance.

---

## Configuration Settings

| Key | Type | Default | Used by |
|-----|------|---------|---------|
| `lurek.lunaPath` | string | `""` | `LunaProcessService.findLunaBinary()` |
| `lurek.srcDir` | string | `""` | `commands/run.ts` |
| `lurek.saveOnRun` | boolean | `true` | `LunaProcessService.run()` |
| `lurek.luaVersion` | string | `"luajit"` | `LuaDebugConfigurationProvider` |
| `lurek.inlayHints.enabled` | boolean | `true` | `providers/inlayHints.ts` |
| `lurek.debugBridge.port` | number | `19740` | `services/debugBridge.ts` |

---

## Protocols

### Debug Bridge (TCP port 19740)

Newline-delimited JSON between extension and running engine:

```jsonc
// Request
{ "id": 1, "type": "globals" }

// Response
{ "id": 1, "type": "globals", "data": { ... } }
{ "id": 1, "type": "error", "error": "not connected" }
```

Request timeout: 10 s. Connection timeout: 5 s.

### MCP Server (JSON-RPC 2.0 stdio)

```jsonc
// Client → Server
{ "jsonrpc": "2.0", "id": 1, "method": "tools/call",
  "params": { "name": "lurek2d.checkBuild", "arguments": {} } }

// Server → Client
{ "jsonrpc": "2.0", "id": 1,
  "result": { "content": [{ "type": "text", "text": "..." }] } }
```

Supported methods: `initialize`, `tools/list`, `tools/call`.
