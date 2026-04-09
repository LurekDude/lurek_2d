# Lurek2D VS Code Extension — Architecture

> Describes the architecture of the extension as it is **currently implemented** in `extensions/vscode/`.
> All content here reflects real source files; nothing described is aspirational.

---

## 1. Identity

| Field | Value |
|---|---|
| **Package name** | `lurek2d-vscode` |
| **Display name** | Lurek2D |
| **Description** | AI-first IDE support for Lurek2D game engine |
| **Version** | 0.1.0 |
| **Publisher** | lurek2d |
| **VS Code engine** | `^1.90.0` |
| **Language** | TypeScript (tsc, esbuild optional via `esbuild.config.mjs`) |
| **Source root** | `extensions/vscode/src/` |
| **Output** | `extensions/vscode/out/` (compiled JS) |
| **License** | MIT |

---

## 2. Activation

The extension activates when VS Code detects:

```jsonc
"activationEvents": [
  "workspaceContains:**/main.lua",   // game project open
  "workspaceContains:Cargo.toml"    // engine source open
]
```

On activation (`extension.ts → activate()`):
1. Creates and shows the status bar item `$(rocket) Lurek2D`.
2. Registers four contributed commands.
3. Starts the MCP server via `startMcpServer(workspaceRoot)`.
4. Shows an activation notification.

On deactivation (`deactivate()`): kills the MCP server process if running.

---

## 3. Source Layout

```
src/
├── extension.ts          Entry point — activate / deactivate, command registration, MCP start
├── extension2.ts         Alternative/experimental entry (not wired to package.json)
├── commands/             Command implementations
│   ├── cag.ts            CAG layer install command
│   ├── debugBridge.ts    Debug bridge connect/disconnect/inspect commands
│   ├── editors.ts        Open webview editor commands
│   ├── gameDevCag.ts     Game-dev CAG helper commands
│   ├── gameJam.ts        Game jam scaffold helper
│   ├── library.ts        Library management commands
│   ├── packaging.ts      Build and package commands
│   ├── reference.ts      API reference browser command
│   ├── run.ts            Run / stop / run-with-args / run-example commands
│   ├── scaffold.ts       New project / new file scaffold commands
│   ├── test.ts           Run tests command
│   └── testGenerator.ts  AI test generator command
├── debug/                Debug adapter
│   ├── luaDebugAdapter.ts  DebugAdapterDescriptorFactory + DebugConfigurationProvider
│   └── luaDebugSession.ts  Inline DAP session implementation
├── editors/              Webview panel editors
│   ├── shared.ts                 WebviewEditor base class, getNonce(), wrapHtml()
│   ├── apiReferenceEditor.ts     lurek.* API browser (reads lua_api_reference_generated.md)
│   ├── aiBehaviorEditor.ts       AI behaviour tree editor
│   ├── audioMixerEditor.ts       Audio mixer / bus editor
│   ├── colorPaletteEditor.ts     Colour palette editor
│   ├── databaseEditor.ts         Structured data / database editor
│   ├── dialogEditor.ts           Branching dialogue tree editor
│   ├── entityEditor.ts           Entity component editor
│   ├── fontPreviewEditor.ts      Font preview and metrics editor
│   ├── graphEditor.ts            Node graph editor
│   ├── guiWidgetEditor.ts        GUI widget layout editor
│   ├── inputMapperEditor.ts      Input action mapper
│   ├── localizationEditor.ts     Localisation string table editor
│   ├── particleEditor.ts         Particle system editor
│   ├── physicsMaterialsEditor.ts Physics material properties editor
│   ├── pixelArtEditor.ts         Pixel art / sprite editor
│   ├── postfxOverlayEditor.ts    Post-FX overlay preview editor
│   ├── procMapEditor.ts          Procedural map generator editor
│   ├── questTreeEditor.ts        Quest / event tree editor
│   ├── sceneFlowEditor.ts        Scene flow / state machine editor
│   ├── shaderPreviewEditor.ts    WGSL shader live preview editor
│   ├── soundDspEditor.ts         Sound DSP chain editor
│   ├── spriteAnimEditor.ts       Sprite animation editor
│   ├── testRunnerEditor.ts       Test runner webview editor
│   ├── tileMapEditor.ts          Tile map editor
│   ├── tilemapScriptEditor.ts    Tilemap scripting / rules editor
│   ├── tilesetEditor.ts          Tileset management editor
│   ├── timelineEditor.ts         Timeline / cutscene editor
│   ├── voxelEditor.ts            Voxel map editor
│   └── worldMapEditor.ts         World map / province editor
├── mcp/                  MCP (Model Context Protocol) server
│   ├── server.ts         startMcpServer() + runStdioServer() — JSON-RPC stdio handler
│   └── tools.ts          ToolDefinition registry and shell execution helpers
├── providers/            VS Code language feature providers
│   ├── apiUsage.ts       API usage analytics / statistics provider
│   ├── assetExplorer.ts  Asset explorer tree-view provider (AssetItem)
│   ├── assetPath.ts      Asset path completion provider
│   ├── codeActions.ts    Code actions (quick fixes)
│   ├── codeLens.ts       CodeLens — function ref counts + luna callback labels
│   ├── color.ts          Color picker provider for lurek.graphics.setColor calls
│   ├── completion.ts     Completion provider — lurek.* API, Lua builtins, LuaCATS
│   ├── debugWatchers.ts  Debug watch expressions provider
│   ├── definition.ts     Go-to-definition — lurek.* virtual docs + local symbols
│   ├── diagnostics.ts    Diagnostic collection — 9 rule-based checks
│   ├── folding.ts        Code folding provider for Lua files
│   ├── formatting.ts     Document formatting provider for Lua files
│   ├── hover.ts          Hover docs — lurek.* API, Lua keywords, math constants
│   ├── inlayHints.ts     Inlay hints — parameter names at lurek.* call sites
│   ├── luacatsProvider.ts LuaCATS annotation parser (---@class, @field, @param, @return)
│   ├── luajitHints.ts    LuaJIT-specific hint provider
│   ├── perfDashboard.ts  Performance dashboard webview panel
│   ├── references.ts     Find references provider
│   ├── rename.ts         Symbol rename provider
│   ├── requireGraph.ts   Require graph builder and webview visualiser
│   ├── semanticTokens.ts Semantic token provider (16 token types, 7 modifiers)
│   ├── sidebar.ts        Sidebar tree-view providers (ProjectTools, DevTools)
│   ├── signature.ts      Signature help provider for lurek.* function calls
│   ├── symbols.ts        Document + workspace symbol providers
│   ├── systemMonitor.ts  System monitor webview panel (CPU, RAM, GPU, disk, net)
│   └── typeInference.ts  Type inference engine for user-defined Lua symbols
├── services/             Shared singleton services
│   ├── apiData.ts        ApiDataService — parses lua_api_reference_generated.md, exposes ApiModule / ApiFunction / ApiEnum
│   ├── debugBridge.ts    DebugBridge — TCP socket connection to running Lurek2D engine (port 19740)
│   ├── luaParser.ts      LuaDocumentAnalyzer — tokeniser + symbol extractor for Lua files
│   ├── lunaProcess.ts    LunaProcessService — binary resolution, run/stop, terminal management
│   ├── statusBar.ts      Status bar helpers
│   └── symbolIndex.ts    SymbolIndex — workspace-wide Lua symbol index (regex-based)
└── cag/
    └── game-dev/         Bundled CAG game-dev layer (agents, skills, prompts)
```

---

## 4. Core Architecture

### 4.1 Entry Point

`extension.ts` is the sole entry point wired to `package.json → "main"`. It owns:

- Status bar item lifecycle
- Command registration (four commands exposed in `package.json`)
- MCP server startup via `startMcpServer()`

More complete command registration (run, debug, scaffold, editors, etc.) lives in `extension2.ts` and the `commands/` implementations, but is not yet wired into `package.json`.

### 4.2 Service Layer

Services are singletons or classes instantiated once and shared via dependency injection into providers and commands.

| Service | File | Responsibility |
|---|---|---|
| `ApiDataService` | `services/apiData.ts` | Parses `docs/API/lua_api_reference_generated.md` and `api_data.json`; provides `getFunction()`, `getModule()`, `getAllFunctions()`, `searchFunctions()`. Exposes built-in enum definitions for `DrawMode`, `BodyType`, `BlendMode`, `FilterMode`, and more. |
| `LuaDocumentAnalyzer` | `services/luaParser.ts` | Full Lua tokeniser producing `Token` streams. Extracts `LuaDocumentInfo`: symbols, require paths, callbacks, scopes, and comments. Cached per document version in each provider. |
| `LunaProcessService` | `services/lunaProcess.ts` | Resolves the luna binary (user setting → PATH → `cargo run`). Runs the game in an integrated terminal. Emits `onStatusChange` events. Reads `lurek.lunaPath` and `lurek.srcDir` from workspace settings. |
| `DebugBridge` | `services/debugBridge.ts` | TCP socket client connecting to the running engine on port 19740 (configurable via `lurek.debugBridge.port`). JSON request/response protocol with per-request timeouts. Shows a live stats status bar item when connected. |
| `SymbolIndex` | `services/symbolIndex.ts` | Regex-based workspace-wide Lua symbol index. Indexes all `*.lua` files for functions, methods, table classes, and constants. Updated incrementally on file change. |

### 4.3 Language Providers

All providers target `{ scheme: "file", language: "lua" }`. Providers that use `ApiDataService` or `LuaDocumentAnalyzer` accept them at registration time; each provider maintains its own per-document analysis cache keyed by `(uri, document.version)`.

#### IntelliSense Providers

| Provider | File | What it provides |
|---|---|---|
| **Completion** | `providers/completion.ts` | Multi-source completion: lurek.* API functions and methods, Lua built-in globals (25 functions), stdlib modules, key names for input functions (50+ keys), string context rules for blend modes / filter modes / wrap modes / body types / source types. LuaCATS `---@type` instance completions. |
| **Hover** | `providers/hover.ts` | Markdown hover cards for lurek.* functions and modules (from `ApiDataService`), all Lua keywords with code examples, math constant docs (`math.pi`, `math.huge`, `math.maxinteger`), LuaCATS class/field hovers. |
| **Signature Help** | `providers/signature.ts` | Parameter list help for lurek.* function calls. Tracks cursor position to highlight active parameter. |
| **Definition** | `providers/definition.ts` | Go-to-definition for lurek.* names opens a virtual `luna-api://` document; for local Lua symbols delegates to `SymbolIndex`. Implements `TextDocumentContentProvider` for the `luna-api` URI scheme. |
| **References** | `providers/references.ts` | Find-all-references for Lua symbols across the workspace. |
| **Rename** | `providers/rename.ts` | Safe symbol rename across the workspace (user-defined Lua symbols). |
| **Symbols** | `providers/symbols.ts` | Document symbol list (Outline view) and workspace symbol search. |
| **Inlay Hints** | `providers/inlayHints.ts` | Parameter name hints at lurek.* call sites with 2+ arguments. Toggled by `lurek.inlayHints.enabled` setting. |
| **Semantic Tokens** | `providers/semanticTokens.ts` | Full semantic highlighting with 16 token types: `namespace`, `function`, `method`, `parameter`, `variable`, `property`, `keyword`, `string`, `number`, `comment`, `operator`, `type`, `enumMember`, `macro`, `decorator`, `event`. Cached per document version. |
| **Code Actions** | `providers/codeActions.ts` | Quick fixes (e.g., auto-import, correct API name). |
| **Code Lens** | `providers/codeLens.ts` | Function reference count lenses on all function definitions. Luna callback functions (`lurek.load`, `lurek.update`, `lurek.draw`, etc.) get a `⚡ lurek.X callback` lens with API doc link instead. |
| **Diagnostics** | `providers/diagnostics.ts` | 9 diagnostic rules, debounced at 300 ms: deprecated API usage, color value out of 0–1 range, unused `require` variables, missing asset file, `math.random` in thread context, missing luna callback registration, wrong enum string values, unknown `lurek.*` function names, invalid `conf.lua` fields. |
| **Folding** | `providers/folding.ts` | Folding ranges for Lua `function`/`end`, `if`/`end`, comment blocks. |
| **Formatting** | `providers/formatting.ts` | Document formatter for Lua files. |
| **Color** | `providers/color.ts` | Inline colour swatch for `lurek.graphics.setColor(r, g, b)` calls. |
| **Asset Path** | `providers/assetPath.ts` | Path completion inside string arguments that resolve to workspace asset files. |
| **LuaCATS** | `providers/luacatsProvider.ts` | Parses `---@class`, `---@field`, `---@param`, `---@return`, `---@type` annotations. Builds a per-document class registry with inheritance. Powers completions and hover for user-defined class instances. |
| **LuaJIT Hints** | `providers/luajitHints.ts` | LuaJIT-specific hints (FFI, bit ops). |
| **Type Inference** | `providers/typeInference.ts` | Lightweight type inference for user Lua variables to drive smarter completion. |

#### Sidebar / Tree Views

| Provider | Contributes |
|---|---|
| `ProjectToolsProvider` (`providers/sidebar.ts`) | Sidebar section **Create** (New Project from Template, New File from Template), **Package**, **Libraries** |
| `AssetExplorerProvider` (`providers/assetExplorer.ts`) | Sidebar tree of workspace assets filtered by type: images, audio, fonts, shaders. Items display file size and open on click. |

#### Monitoring Webview Panels

| Panel | File | Content |
|---|---|---|
| **Performance Dashboard** | `providers/perfDashboard.ts` | Rolling 300-sample history of FPS, frame time, and Lua heap size. Renders an in-webview chart. Records samples via `recordSample()`. |
| **System Monitor** | `providers/systemMonitor.ts` | Rolling 120-sample history of CPU %, RAM, luna process CPU + RAM, GPU %, VRAM, disk I/O rates, and network rates. Collects via PowerShell on Windows, `ps`/`vmstat` on Unix. |
| **Require Graph** | `providers/requireGraph.ts` | Parses `require()` calls across Lua files and visualises the dependency graph as an interactive webview. Resolves module names to workspace files (dot-to-slash, `.lua` / `init.lua` variants). |
| **API Usage** | `providers/apiUsage.ts` | Analyses lurek.* API function usage frequency across the workspace. |

### 4.4 Commands

All command implementations live in `src/commands/`. The entry point `extension.ts` currently registers four commands (`lurek2d.runExample`, `lurek2d.listExamples`, `lurek2d.checkBuild`, `lurek2d.getApiDoc`). The full command set is implemented but not yet contributed in `package.json`.

| Module | Functions |
|---|---|
| `commands/run.ts` | `runGame()`, `stopGame()`, `runWithArgs()`, `runExample()` — all delegate to `LunaProcessService` |
| `commands/scaffold.ts` | New project from template (Minimal / Game Loop / Physics / …), new file from template. Writes `main.lua` + `conf.lua` to the chosen directory. |
| `commands/editors.ts` | Opens any of the webview editors by name |
| `commands/debugBridge.ts` | Connect / disconnect debug bridge; inspect Lua globals, performance, and logged errors |
| `commands/cag.ts` | Installs the bundled CAG layer to the workspace `.github/` folder |
| `commands/gameDevCag.ts` | Game-dev CAG helpers |
| `commands/gameJam.ts` | Game jam project scaffolding |
| `commands/library.ts` | Lunasome library management |
| `commands/packaging.ts` | Build and package the game for distribution |
| `commands/reference.ts` | Opens the API reference editor panel |
| `commands/test.ts` | Runs the test suite |
| `commands/testGenerator.ts` | Generates test stubs from lurek.* API usage |

### 4.5 Webview Editors

All editors inherit from `WebviewEditor` (`editors/shared.ts`), which provides:

- `vscode.WebviewPanel` creation with `enableScripts: true`
- `getNonce()` for Content Security Policy nonces
- `wrapHtml(nonce, title, css, body)` for consistent VS Code-themed HTML
- `exportLua()` and `exportToml()` helpers for writing generated files to the workspace
- Abstract `getHtml(): string` and `handleMessage(msg)` hooks

The 29 editor panels are webview-only (HTML canvas + vanilla JS inside the webview). They generate Lua or TOML output and write it to the workspace via the extension host.

| Editor | Opens when |
|---|---|
| `ApiReferenceEditor` | Command; reads `docs/API/lua_api_reference_generated.md` |
| `TileMapEditor` | Command; exports to `tilemap.lua` or `tilemap.toml` |
| `SceneFlowEditor` | Command; scene state machine editor |
| `ParticleEditor` | Command; particle system tuner |
| `DialogEditor` | Command; branching dialogue tree |
| `EntityEditor` | Command; entity component layout designer |
| `PixelArtEditor` | Command; pixel art / sprite editor |
| `GuiWidgetEditor` | Command; GUI widget layout |
| `AiBehaviorEditor` | Command; AI behaviour tree designer |
| `GraphEditor` | Command; node graph editor |
| `ProcMapEditor` | Command; procedural map generator |
| `QuestTreeEditor` | Command; quest / event tree |
| `DatabaseEditor` | Command; structured data table editor |
| `TimelíneEditor` | Command; cutscene / timeline editor |
| `SpriteAnimEditor` | Command; sprite animation frames |
| `TilesetEditor` | Command; tileset management |
| `TilemapScriptEditor` | Command; tilemap scripting / rules |
| `ShaderPreviewEditor` | Command; WGSL shader live preview |
| `AudioMixerEditor` | Command; audio bus / mixer |
| `SoundDspEditor` | Command; DSP chain editor |
| `FontPreviewEditor` | Command; font metrics preview |
| `ColorPaletteEditor` | Command; colour palette |
| `InputMapperEditor` | Command; action → key binding mapper |
| `LocalizationEditor` | Command; localisation string table |
| `PostfxOverlayEditor` | Command; post-FX overlay preview |
| `WorldMapEditor` | Command; world / province map |
| `VoxelEditor` | Command; voxel map editor |
| `PhysicsMaterialsEditor` | Command; physics material properties |
| `TestRunnerEditor` | Command; test runner UI |

### 4.6 Debug Adapter

Implemented across two files:

**`debug/luaDebugAdapter.ts`** — `LuaDebugAdapterFactory` (creates inline sessions) and `LuaDebugConfigurationProvider` (resolves and generates launch configurations). Default launch config: type `luna`, request `launch`, `program = ${workspaceFolder}`, `luaVersion = "luajit"`, `debugPort = 8172`, `stopOnEntry = false`.

**`debug/luaDebugSession.ts`** — `LuaDebugSession extends DebugSession`. Implements the DAP protocol inline. Connects to the running engine's debug socket on the configured port.

The companion **`services/debugBridge.ts`** — `DebugBridge` — provides a separate higher-level TCP channel (port 19740 by default) used by the debug-bridge commands (inspect globals, watch performance, fetch logs) independently of the DAP session.

### 4.7 MCP Server

The MCP server (`src/mcp/`) implements the [Model Context Protocol](https://modelcontextprotocol.io) to expose Lurek2D tools to AI agents (GitHub Copilot, Claude, etc.).

**`mcp/server.ts`** provides two entrypoints:
- `startMcpServer(workspaceRoot)` — called from `extension.ts`; returns a `{ kill() }` handle (currently in-process, no child process spawned).
- `runStdioServer(workspaceRoot)` — reads newline-delimited JSON-RPC from stdin, writes responses to stdout; used when the server is launched as a standalone Node.js process.

Both parse and dispatch `initialize`, `tools/list`, and `tools/call` JSON-RPC methods.

**`mcp/tools.ts`** defines six MCP tools:

| Tool | Description |
|---|---|
| `lurek2d.runExample` | Build and run a named demo project, return output |
| `lurek2d.getApiDoc` | Search the lurek.* API documentation |
| `lurek2d.listExamples` | List all demo directories |
| `lurek2d.runLuaTest` | Run a Lua test file against the debug build |
| `lurek2d.checkBuild` | Run `cargo check` and return compiler diagnostics |
| `lurek2d.getLogs` | Return the last N lines of engine log output |

Tool handlers execute shell commands in the workspace root with a configurable timeout.

### 4.8 CAG Layer

`extensions/vscode/cag/game-dev/` contains a bundled copy of game-development CAG files (agents, skills, prompts). The `commands/cag.ts` command installs them into the workspace `.github/` folder on demand.

---

## 5. Data Flow

```
Workspace Lua files
        │
        ▼
LuaDocumentAnalyzer (luaParser.ts)
  Tokeniser → LuaDocumentInfo
  (symbols, requires, callbacks, scopes)
        │
        ├──▶ completion.ts     (lurek.* + builtins + LuaCATS completions)
        ├──▶ hover.ts          (keyword + API hover cards)
        ├──▶ diagnostics.ts    (9 rule checks — debounced 300ms)
        ├──▶ semanticTokens.ts (16-type token classification)
        ├──▶ codeLens.ts       (ref counts + callback labels)
        ├──▶ inlayHints.ts     (parameter name hints)
        └──▶ definition.ts     (local symbol go-to)

docs/API/lua_api_reference_generated.md
        │
        ▼
ApiDataService (apiData.ts)
  ApiModule[] / ApiFunction[] / ApiEnum[]
        │
        ├──▶ completion.ts     (lurek.* function completions)
        ├──▶ hover.ts          (lurek.* hover docs)
        ├──▶ signature.ts      (parameter list help)
        ├──▶ diagnostics.ts    (deprecated check, unknown function check)
        ├──▶ inlayHints.ts     (param name labels at call sites)
        └──▶ apiReferenceEditor.ts (in-panel API browser)

LunaProcessService (lunaProcess.ts)
        │
        ├── findLunaBinary()   user setting → PATH → cargo run
        ├── run(gameDir)       creates integrated terminal, sends command
        └── stop()             kills process + closes terminal

DebugBridge (debugBridge.ts)
        │
        └── TCP → 127.0.0.1:19740 → running Lurek2D engine
              inspect globals, performance counters, logs

MCP Server (mcp/server.ts + tools.ts)
        │
        └── JSON-RPC stdio ← AI agent hosts (Copilot, Claude)
              6 tools: run, doc-search, list, test, build-check, logs
```

---

## 6. Key Data Types

### `ApiDataService` types (`services/apiData.ts`)

```typescript
interface ApiParam {
  name: string; type: string; description: string;
  optional: boolean; default?: string;
}
interface ApiFunction {
  module: string; name: string; fullPath: string;
  signature: string; description: string;
  parameters: ApiParam[]; returns?: string; returnType?: string;
  since?: string; deprecated?: string;
  isMethod: boolean; objectType?: string; sourceFile?: string;
}
interface ApiModule {
  name: string; fullPath: string; description: string;
  functions: ApiFunction[]; methods: ApiFunction[];
  totalEntries: number; documentedEntries: number;
}
interface ApiEnum {
  name: string; values: string[];
  descriptions: Map<string, string>;
}
```

Built-in enum stubs: `DrawMode`, `BodyType`, `SourceType`, `BlendMode`, `FilterMode`, `WrapMode`, `ShapeType`.

### `LuaParser` types (`services/luaParser.ts`)

```typescript
// Token types: Keyword | Identifier | String | Number | Comment |
//              Operator | Punctuation | Whitespace | EOF
interface LuaSymbol {
  name: string;
  kind: "function" | "local" | "global" | "table" | "method" | "parameter" | "field";
  line: number; column: number; endLine?: number;
  scope?: string; type?: string;
  parameters?: string[]; isLocal: boolean;
}
interface LuaDocumentInfo {
  symbols: LuaSymbol[];
  requires: RequireInfo[];    // module path + line
  callbacks: LuaSymbol[];    // lurek.load, lurek.update, etc.
  scopes: ScopeInfo[];       // function / if / for / while / repeat
  comments: CommentInfo[];   // text, line, isBlock, isLuaCATS
}
```

### `LuaCATS` types (`providers/luacatsProvider.ts`)

```typescript
interface CatsClass {
  name: string; parent?: string;
  fields: CatsField[]; methods: CatsMethod[];
  definedLine: number; fileUri: string;
}
```

---

## 7. Build and Packaging

| Script | Command |
|---|---|
| Compile | `npm run compile` → `tsc -p ./` → `out/` |
| Watch | `npm run watch` → `tsc -watch -p ./` |
| Bundle | `node esbuild.config.mjs` (esbuild, produces minified bundle) |
| Package | `npm run package` → `npx @vscode/vsce package` → `.vsix` |

**Dependencies**: only `@modelcontextprotocol/sdk ^1.0.0` at runtime.
**Dev dependencies**: `@types/vscode`, `@types/node`, `typescript`, `@vscode/vsce`.

The compiled extension entry is `out/extension.js` as declared in `package.json → "main"`.

---

## 8. Configuration Settings

The extension reads from the `luna` workspace configuration namespace:

| Key | Type | Default | Used by |
|---|---|---|---|
| `lurek.lunaPath` | string | `""` | `LunaProcessService.findLunaBinary()` |
| `lurek.srcDir` | string | `""` | `commands/run.ts` — game directory |
| `lurek.saveOnRun` | boolean | `true` | `LunaProcessService.run()` |
| `lurek.luaVersion` | string | `"luajit"` | `LuaDebugConfigurationProvider` |
| `lurek.inlayHints.enabled` | boolean | `true` | `providers/inlayHints.ts` |
| `lurek.debugBridge.port` | number | `19740` | `services/debugBridge.ts` |

---

## 9. Contributed Extension Points (`package.json`)

Only the following are currently contributed in `package.json`:

**Commands** (4):

| Command ID | Title |
|---|---|
| `lurek2d.runExample` | Lurek2D: Run Example |
| `lurek2d.listExamples` | Lurek2D: List Examples |
| `lurek2d.checkBuild` | Lurek2D: Check Build |
| `lurek2d.getApiDoc` | Lurek2D: Get API Documentation |

**Language configuration** (`language-configuration.json`): Lua-specific bracket matching, comment toggles, and auto-closing pairs.

---

## 10. Protocol: Debug Bridge

The `DebugBridge` service connects via raw TCP to a Lurek2D engine instance listening on port 19740. Messages are newline-delimited JSON:

```jsonc
// Request
{ "id": 1, "type": "globals" }

// Response
{ "id": 1, "type": "globals", "data": { ... } }
{ "id": 1, "type": "error", "error": "not connected" }
```

Individual requests time out after 10 seconds. Connection attempts time out after 5 seconds. A live status bar item shows FPS and memory when the bridge is connected.

---

## 11. Protocol: MCP Server

The MCP server uses newline-delimited JSON-RPC 2.0 on stdio:

```jsonc
// Client → Server
{ "jsonrpc": "2.0", "id": 1, "method": "tools/call",
  "params": { "name": "lurek2d.checkBuild", "arguments": {} } }

// Server → Client
{ "jsonrpc": "2.0", "id": 1,
  "result": { "content": [{ "type": "text", "text": "..." }] } }
```

Supported methods: `initialize`, `tools/list`, `tools/call`.
