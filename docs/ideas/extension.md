# Luna2D VS Code Extension — Technical Specification

> **Version**: 0.8.2
> **Engine**: Luna2D (LuaJIT, Rust)
> **Extension Language**: TypeScript (Node 18, esbuild bundler)
> **Purpose**: Complete game development toolkit as a VS Code extension — IntelliSense, visual editors, process management, packaging, library ecosystem, and AI-powered Copilot integration
> **Portability Guide**: Section 10 explains how to recreate this extension for **any** game engine (a similar JS game engine, a similar game engine, a major game engine, etc.)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Extension Manifest (package.json)](#2-extension-manifest)
3. [Activation & Entry Point](#3-activation--entry-point)
4. [Services Layer](#4-services-layer)
5. [Language Providers](#5-language-providers)
6. [Commands](#6-commands)
7. [Visual Editors (Webview Panels)](#7-visual-editors)
8. [Data Pipeline (TOML → JSON → IntelliSense)](#8-data-pipeline)
9. [CAG Plugin System (AI Game Dev)](#9-cag-plugin-system)
10. [Portability Guide — Recreating for a similar JS game engine / Other Engines](#10-portability-guide)
11. [Build & Package](#11-build--package)
12. [Testing](#12-testing)
13. [MCP Server Integration](#13-mcp-server-integration)
14. [Configuration Reference](#14-configuration-reference)

---

## 1. Architecture Overview

The extension follows a layered architecture with strict separation between data, services, providers, commands, and visual editors.

```
┌──────────────────────────────────────────────────────────────────┐
│                     VS Code Extension Host                        │
│                                                                    │
│  ┌─────────────┐   ┌──────────────────────────────────────────┐  │
│  │  package.json│   │  extension.ts (activate)                 │  │
│  │  (manifest)  │   │    ├── Services (apiData, loveProcess,   │  │
│  │              │   │    │             debugBridge, statusBar)  │  │
│  │  commands    │   │    ├── Providers (12 language providers)  │  │
│  │  settings    │   │    ├── Commands  (10 command groups)      │  │
│  │  activation  │   │    ├── Editors   (17 webview editors)    │  │
│  │  views       │   │    └── Inline    (wiki, API browser)     │  │
│  └─────────────┘   └──────────────────────────────────────────┘  │
│                                                                    │
│  ┌─────────────────┐  ┌─────────────────┐  ┌────────────────┐   │
│  │  data/api/*.json │  │  data/snippets/ │  │ data/templates │   │
│  │  (generated)     │  │  (generated)    │  │ (static)       │   │
│  └────────┬────────┘  └────────┬────────┘  └────────────────┘   │
│           │                    │                                   │
│  ┌────────┴────────────────────┴───────────────────────────────┐  │
│  │  tools/generate-api-data.ts    (build-time data generation) │  │
│  │  tools/generate-snippets.ts                                 │  │
│  │  tools/generate-luacats.ts                                  │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  cag/   (Copilot AI Configuration — installed to .github/)  │  │
│  │    ├── agents/         (24 game dev agents)                 │  │
│  │    ├── skills/         (27 domain skill guides)             │  │
│  │    ├── prompts/        (21 task playbooks)                  │  │
│  │    ├── instructions/   (8 coding instruction files)         │  │
│  │    └── copilot-instructions.md (system prompt)              │  │
│  └─────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │  mcp/game_mcp_server.py (12-tool JSON-RPC 2.0 MCP server)  │  │
│  └─────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### Directory Layout

```
extension/
├── package.json          ← VS Code manifest (commands, settings, keybindings, activation)
├── tsconfig.json         ← TypeScript config (strict, ES2022 target)
├── esbuild.config.mjs    ← Build config (CJS bundle → dist/extension.js)
├── src/
│   ├── extension.ts      ← Entry point: activate(), service creation, registration
│   ├── commands/          ← 10 command group files
│   │   ├── run.ts         ← Run/stop game via child process
│   │   ├── scaffold.ts    ← New project/file from templates
│   │   ├── package.ts     ← bundle, .exe, .zip packaging
│   │   ├── test.ts        ← Test runner integration
│   │   ├── depGraph.ts    ← require() dependency graph analysis
│   │   ├── gameJam.ts     ← Game jam tools (timer, checklist)
│   │   ├── library.ts     ← Library catalog (150+ libs, 22 categories)
│   │   ├── debugBridge.ts ← TCP debug bridge commands
│   │   ├── sceneEditor.ts ← Scene editor commands + custom editor provider
│   │   └── testGenerator.ts ← AI-powered test generation
│   ├── providers/         ← 12 language providers for Lua files
│   │   ├── completion.ts  ← CompletionItemProvider (luna.X.Y, Type:method)
│   │   ├── hover.ts       ← HoverProvider (rich API docs on hover)
│   │   ├── signature.ts   ← SignatureHelpProvider (param hints)
│   │   ├── diagnostics.ts ← DiagnosticCollection (deprecation, common mistakes, assets)
│   │   ├── symbols.ts     ← DocumentSymbolProvider (outline, breadcrumbs)
│   │   ├── color.ts       ← DocumentColorProvider (color picker for 0-1 range)
│   │   ├── assetPath.ts   ← CompletionItemProvider (file path autocomplete)
│   │   ├── definition.ts  ← DefinitionProvider (require → file, function defs)
│   │   ├── references.ts  ← ReferenceProvider (workspace-wide search)
│   │   ├── inlayHints.ts  ← InlayHintsProvider (parameter name hints)
│   │   ├── codeActions.ts ← CodeActionProvider (quick fixes, refactoring)
│   │   └── sidebar.ts     ← TreeDataProvider (activity bar sidebar views)
│   ├── editors/           ← 17 webview-based visual editors
│   │   ├── mapEditor.ts           ← 🗺️ Tile map editor with multi-layer support
│   │   ├── sceneFlowEditor.ts     ← 🎬 Scene flow / state machine designer
│   │   ├── entityDesigner.ts      ← 🧩 ECS entity/component designer
│   │   ├── pixelArtEditor.ts      ← 🎨 Pixel art drawing tool
│   │   ├── dialogEditor.ts        ← 💬 Dialog tree / branching conversation editor
│   │   ├── particleEditor.ts      ← ✨ Particle system designer
│   │   ├── testRunner.ts          ← 🧪 Visual test runner panel
│   │   ├── databaseBrowser.ts     ← 🗃️ DataFrame/database browser
│   │   ├── proceduralMapGen.ts    ← 🌍 Procedural map generator
│   │   ├── questTreeEditor.ts     ← 📜 Quest/mission tree editor
│   │   ├── guiWidgetEditor.ts     ← 🖼️ GUI widget layout designer
│   │   ├── aiBehaviorEditor.ts    ← 🤖 AI behavior tree editor
│   │   ├── graphEditor.ts         ← 📊 Graph / node editor
│   │   ├── tilemapScriptEditor.ts ← 🏗️ Tilemap script editor
│   │   ├── voxelEditor.ts         ← 🧊 Voxel editor
│   │   ├── apiReference.ts        ← 📚 Local API reference browser
│   │   └── sharedCss.ts           ← Shared styles, canvas interaction JS, zoom HUD
│   └── services/          ← 4 backend services
│       ├── apiData.ts     ← Loads + queries JSON API data (completions, hover, enums, sigs)
│       ├── loveProcess.ts ← Child process lifecycle (spawn, kill, output capture)
│       ├── debugBridge.ts ← TCP client for live game introspection (JSON-RPC over TCP)
│       └── statusBar.ts   ← Run/stop buttons in the status bar
├── data/
│   ├── api/               ← Generated JSON files consumed by providers
│   │   ├── completions.json (816+ items)
│   │   ├── signatures.json  (721+ items)
│   │   ├── hover.json       (225+ items)
│   │   └── enums.json
│   ├── luacats/            ← Generated LuaCATS annotations for Lua Language Server
│   │   └── library/
│   ├── snippets/
│   │   └── luna.json       ← Generated code snippets
│   ├── templates/          ← Project scaffolding templates
│   │   ├── minimal/        ← Bare minimum (main.lua + conf.lua)
│   │   ├── game-loop/      ← Standard game loop pattern
│   │   ├── ecs/            ← Entity Component System starter
│   │   ├── physics/        ← physics simulation libraries physics demo
│   │   ├── gui/            ← GUI widget demo
│   │   └── shader/         ← GLSL shader demo
│   └── libraries.json      ← 150+ library catalog (22 categories)
├── cag/                    ← AI game dev configuration (see Section 9)
├── mcp/                    ← MCP server for game dev tools
├── tests/                  ← Test suite
└── tools/                  ← Build-time data generators
```

### Key Design Principles

1. **Data-driven**: All API knowledge lives in JSON files generated from authoritative TOML sources — providers simply query these files
2. **Engine-agnostic pattern**: The architecture separates engine-specific data from generic VS Code patterns, making it portable
3. **Service-based**: Shared state (API data, process lifecycle, debug connection) lives in singleton services passed to providers/commands
4. **Webview editors**: Complex visual tools use VS Code's Webview API with HTML/CSS/JS — no framework dependency
5. **CAG distribution**: AI configuration is bundled in the extension and installed to user projects on demand

---

## 2. Extension Manifest

The `package.json` is the VS Code extension manifest. It declares everything the extension contributes.

### Core Fields

```jsonc
{
  "name": "ilove-toolkit",
  "displayName": "Luna2D Toolkit",
  "version": "0.8.2",
  "engines": { "vscode": "^1.85.0" },
  "main": "./dist/extension.js",       // esbuild output
  "activationEvents": [
    "workspaceContains:**/main.lua",    // Activate when Luna2D project detected
    "onLanguage:lua"                    // Activate when any Lua file opens
  ]
}
```

### Contribution Points

| Category | Count | Description |
|----------|-------|-------------|
| `commands` | 50+ | All prefixed with `luna2d.*`, categorized as "Luna2D" |
| `configuration` | 15+ | Settings under `luna2d.*` namespace |
| `views` | 3 | Sidebar views: Project, Dev Tools, AI & Copilot |
| `viewsContainers` | 1 | Activity bar entry for the sidebar |
| `viewsWelcome` | 1 | Welcome content when no project is detected |
| `snippets` | 1 | `data/snippets/luna.json` for Lua |
| `keybindings` | 2 | `Alt+L` (run), `Shift+Alt+L` (stop) |

### Activation Events Explained

```
workspaceContains:**/main.lua   →  Luna2D projects always have main.lua at root
onLanguage:lua                  →  Provide IntelliSense for any Lua file
```

**a similar JS game engine equivalent**: Use `workspaceContains:**/index.html` or `onLanguage:javascript` / `onLanguage:typescript`.

---

## 3. Activation & Entry Point

File: `src/extension.ts`

The `activate()` function is called once when any activation event fires. It creates services, then registers all providers, commands, and editors.

### Activation Sequence

```typescript
export function activate(context: vscode.ExtensionContext) {
  // 1. Create shared services (singletons)
  const apiData = new ApiDataService(context);          // API data loader
  const processService = new LoveProcessService();      // Process lifecycle
  const debugBridge = new DebugBridgeService();          // TCP debug client

  // 2. Register language providers (12 providers)
  registerCompletionProvider(context, apiData);
  registerHoverProvider(context, apiData);
  registerSignatureProvider(context, apiData);
  registerDiagnostics(context, apiData);
  registerDocumentSymbolProvider(context, apiData);
  registerColorProvider(context);
  registerAssetPathProvider(context);
  registerDefinitionProvider(context);
  registerReferenceProvider(context);
  registerInlayHintsProvider(context, apiData);
  registerCodeActionsProvider(context);

  // 3. Register commands (10 groups)
  registerRunCommands(context, processService);
  registerScaffoldCommands(context);
  registerPackageCommands(context);
  registerTestCommands(context, processService);
  registerDependencyCommands(context);
  registerGameJamCommands(context);
  registerLibraryCommands(context);
  registerDebugBridgeCommands(context, debugBridge, processService);
  registerSceneEditorCommands(context);
  registerTestGeneratorCommand(context);

  // 4. Register sidebar tree views
  registerSidebarProviders(context);

  // 5. Register visual editors (17 webview panels)
  registerMapEditor(context);
  registerSceneFlowEditor(context);
  registerEntityDesigner(context);
  // ... 14 more editors

  // 6. Register inline commands (wiki, API browser, CAG)
  // (implemented directly in activate)
}
```

### Registration Pattern

Every provider/command group follows the same pattern:

```typescript
// src/providers/myProvider.ts
export function registerMyProvider(
  context: vscode.ExtensionContext,
  apiData: ApiDataService    // injected dependency
) {
  const provider = vscode.languages.registerXxxProvider(
    { language: "lua", scheme: "file" },  // document selector
    { provideXxx(document, position) { ... } }
  );
  context.subscriptions.push(provider);  // auto-dispose on deactivation
}
```

---

## 4. Services Layer

### 4.1 ApiDataService (`services/apiData.ts`)

**Purpose**: Loads and queries the embedded JSON API data files at activation time.

**Data files loaded**:
- `data/api/completions.json` — 816+ items (functions, methods, enum values)
- `data/api/hover.json` — 225+ keyed documentation strings
- `data/api/enums.json` — enum names → value arrays
- `data/api/signatures.json` — 721+ function signatures with parameter lists

**Interface**:

```typescript
class ApiDataService {
  constructor(context: vscode.ExtensionContext)  // loads JSON on construction

  // Queries
  getCompletions(): CompletionItem[]
  getCompletionsForModule(moduleName: string): CompletionItem[]
  getFunctionsForModule(moduleName: string): { label, detail }[]
  getMethodsForType(typeName: string): CompletionItem[]
  getHoverDoc(key: string): string | undefined
  getEnumValues(enumName: string): string[]
  getAllEnumNames(): string[]
  getModuleNames(): string[]
  getSignature(fullName: string): SignatureItem | undefined
}

interface CompletionItem {
  label: string        // e.g., "newImage"
  kind: string         // "function" | "method" | "enum" | "value" | "class"
  module: string       // e.g., "graphics"
  detail: string       // e.g., "luna.graphics.newImage(filename)"
  insertText: string   // snippet: "newImage(${1:filename})"
  documentation?: string
  parent?: string      // for methods: the type name (e.g., "Image")
}

interface SignatureItem {
  label: string        // e.g., "luna.graphics.newImage"
  module: string
  parameters: string[] // ["filename: string", "settings?: table"]
  documentation?: string
}
```

**Key design**: Data is loaded once and queried synchronously. No filesystem access during provider callbacks.

### 4.2 LoveProcessService (`services/loveProcess.ts`)

**Purpose**: Manages the Luna2D game process lifecycle — finding the executable, spawning, capturing output, and killing.

**Key methods**:

```typescript
class LoveProcessService {
  get isRunning(): boolean
  async resolveLovePath(): Promise<string>   // config → PATH → error
  async run(gameDir: string, args?: string[]): Promise<void>
  stop(): void
  readonly onStatusChange: vscode.Event<boolean>
}
```

**Process resolution**: Checks `luna2d.lovePath` setting first, then auto-detects from PATH using `where` (Windows) or `which` (Unix).

**Output capture**: stdout and stderr are piped to a dedicated VS Code output channel named "Luna2D".

### 4.3 DebugBridgeService (`services/debugBridge.ts`)

**Purpose**: TCP client that connects to a Luna2D game's DebugBridge module for live introspection.

**Protocol**: Newline-delimited JSON over TCP on `localhost:19740`.

```
Request:  {"id": N, "method": "...", "params": {...}}\n
Response: {"id": N, "result": {...}}\n
Event:    {"event": "...", "data": {...}}\n
```

**Key methods**:

```typescript
class DebugBridgeService {
  get isConnected(): boolean
  async connect(port?: number, host?: string): Promise<boolean>
  disconnect(): void
  async call(method: string, params?: object): Promise<any>
  readonly onEvent: vscode.Event<{ event: string; data: any }>
  readonly onPrint: vscode.Event<{ timestamp, message, source, line }>
}
```

**Features**: Call stack inspection, Lua eval, print capture, performance metrics, screenshot retrieval.

### 4.4 StatusBar (`services/statusBar.ts`)

**Purpose**: Creates run/stop buttons in the VS Code status bar.

**Behavior**:
- Default state: `$(play) Luna2D` → triggers `luna2d.run`
- Running state: `$(debug-stop) Luna2D` → triggers `luna2d.stop` + spinning indicator

---

## 5. Language Providers

All providers register for `{ language: "lua", scheme: "file" }`.

### 5.1 Completion Provider

**Trigger characters**: `.`, `:`

**Three completion contexts**:

| Context | Trigger | Example | What it returns |
|---------|---------|---------|-----------------|
| Module functions | `luna.graphics.` | typing after `luna.graphics.` | All functions in `graphics` module |
| Type methods | `image:` | typing after a variable with `:` | All methods for the type |
| Module names | `luna.` | typing after `luna.` | All module names |

**Implementation pattern**:
```typescript
const moduleMatch = lineText.match(/luna\.(\w+)\.$/);
if (moduleMatch) {
  return apiData.getCompletionsForModule(moduleMatch[1]).map(c => {
    const item = new vscode.CompletionItem(c.label, vscode.CompletionItemKind.Function);
    item.insertText = new vscode.SnippetString(c.insertText);  // tabstops
    item.documentation = new vscode.MarkdownString(c.documentation);
    return item;
  });
}
```

### 5.2 Hover Provider

**Pattern matching**: `luna\.\w+\.\w+` for module functions, `\w+:\w+` for type methods.

Looks up the matched symbol in `apiData.getHoverDoc(key)` and returns a `MarkdownString` with bold title + documentation body.

### 5.3 Signature Help Provider

**Trigger characters**: `(`, `,`

Matches function calls like `luna.graphics.newImage(` and counts commas to determine the active parameter index. Returns `vscode.SignatureHelp` with parameter info from `apiData.getSignature()`.

### 5.4 Diagnostics Provider

**Real-time analysis** run on every document change via `onDidChangeTextDocument` and `onDidOpenTextDocument`.

**Five diagnostic checks**:

| Check | Severity | Example |
|-------|----------|---------|
| Deprecated API calls | Warning/Error | `luna.window.setMode` → "Deprecated in Luna2D 12.0" |
| Color range mistake | Warning | `setColor(255, 0, 0)` → "Use 0-1 range since 11.0" |
| `math.random` usage | Hint | → "Prefer luna.math.random() for thread safety" |
| Missing `luna.event.pump()` | Warning | Custom `luna.run()` without pump → "window will freeze" |
| Unused `require()` | Hint | `local x = require("y")` where `x` is never used |
| Wrong callback signature | Warning | `function luna.update()` without `dt` parameter |
| Asset path validation | Warning | `newImage("missing.png")` when file doesn't exist |

**Toggle settings**: Each check has a `luna2d.diagnostics.*` boolean setting.

### 5.5 Document Symbol Provider

Parses Lua source with regex patterns to find:
- Function declarations: `function name()`, `local function name()`
- Engine callbacks: `function luna.update(dt)` → `SymbolKind.Event`
- Variable-assigned functions: `local name = function()`
- Table declarations: `local MyTable = {}`

Populates the VS Code Outline view and breadcrumb bar.

### 5.6 Color Provider

Detects Luna2D color API calls (`setColor`, `setBackgroundColor`, `clear`) with numeric literal arguments in the 0-1 range. Provides:
- Color swatches in the gutter
- Interactive color picker that writes values in Luna2D's 0-1 range format

### 5.7 Asset Path Provider

Auto-completes file paths inside string arguments of asset loading functions:
- `luna.graphics.newImage("` → suggests `.png`, `.jpg` files
- `luna.audio.newSource("` → suggests `.ogg`, `.mp3`, `.wav` files
- `luna.graphics.newFont("` → suggests `.ttf`, `.otf` files

Scans the workspace filesystem filtered by appropriate extensions.

### 5.8 Definition Provider

Two navigation modes:
1. **require resolution**: `require("module.path")` → resolves to `module/path.lua` or `module/path/init.lua`
2. **Function definition**: Searches current file then workspace for function declaration patterns

### 5.9 Reference Provider

Workspace-wide search for symbol references using regex patterns across all `.lua` files.

### 5.10 Inlay Hints Provider

Shows inline parameter name hints at call sites for Luna2D API functions:
```lua
luna.graphics.setColor(1, 0, 0, 1)
--                     ^r ^g ^b ^a   ← inlay hints
```

### 5.11 Code Actions Provider

Provides quick-fix actions for diagnostics:
- Remove unused `require()` statements
- Fix color range (0-255 → 0-1 conversion)
- Add missing `dt` parameter to `luna.update()`

### 5.12 Sidebar Provider

TreeDataProvider for three sidebar views:
- **Project**: Run, package, scaffold, test actions
- **Dev Tools**: Dependency graph, debug bridge, scene editor
- **AI & Copilot**: Agent selection, skill browser, CAG install

---

## 6. Commands

### 6.1 Run Commands (`commands/run.ts`)

| Command | ID | Shortcut | Behavior |
|---------|-----|----------|----------|
| Run Game | `luna2d.run` | `Alt+L` | Save all → resolve luna.exe → spawn process |
| Run with Args | `luna2d.runWithArgs` | — | Prompt for CLI args → run |
| Stop Game | `luna2d.stop` | `Shift+Alt+L` | Kill child process |

**Game directory resolution**: Workspace root + `luna2d.srcDir` config offset.

### 6.2 Scaffold Commands (`commands/scaffold.ts`)

| Command | ID | Behavior |
|---------|-----|----------|
| New Project | `luna2d.newProject` | Template picker → folder picker → name input → copy template + optional CAG install → open folder |
| New File | `luna2d.newFile` | File type picker → generate from template |

**6 project templates**: minimal, game-loop, ecs, physics, gui, shader.

### 6.3 Package Commands (`commands/package.ts`)

| Command | ID | Behavior |
|---------|-----|----------|
| Package Bundle | `luna2d.package.bundle` | ZIP game directory (excluding patterns) → single-file bundle |
| Package Windows | `luna2d.package.windows` | Fuse `luna.exe + game.bundle` → standalone `.exe` |
| Package ZIP | `luna2d.package.zip` | Create distribution ZIP |

**Exclude patterns**: Configured via `luna2d.package.excludePatterns` (default: `.git`, `.github`, `.vscode`, `dist`, `*.md`).

### 6.4 Test Commands (`commands/test.ts`)

Run Luna2D test suite via the process service with test-specific arguments.

### 6.5 Dependency Graph (`commands/depGraph.ts`)

Analyzes all `require()` calls in the workspace, builds a dependency graph, and renders it as:
- **Mermaid diagram** in a webview panel (interactive)
- **Text tree** in a new editor tab

### 6.6 Game Jam Commands (`commands/gameJam.ts`)

| Command | Behavior |
|---------|----------|
| Game Jam Timer | Countdown timer in status bar |
| Quick Build Bundle | Fast packaging optimized for jam submissions |
| Submission Checklist | Pre-submission sanity checks |

### 6.7 Library Manager (`commands/library.ts`)

Full library ecosystem with a 150+ library catalog across 22 categories:

**Data source**: `data/libraries.json` — static catalog with GitHub repo URLs.

**Registry**: `libs/.registry.json` — tracks installed libraries with version info.

**Download mechanism**: HTTPS GET from GitHub raw URLs or archive downloads.

| Command | Behavior |
|---------|----------|
| Install Library | Category picker → multi-select → download from GitHub |
| Browse Catalog | Category picker → detail view (install/remove/GitHub) |
| List Installed | Show `libs/` contents with management actions |
| Remove Library | Multi-select → confirm → delete folders |
| Update Libraries | Re-download latest from GitHub |

### 6.8 Debug Bridge Commands (`commands/debugBridge.ts`)

| Command | Behavior |
|---------|----------|
| Connect | TCP connection to `localhost:19740` |
| Disconnect | Close socket |
| Run Game (Debug) | Auto-start game + connect debug bridge |
| Show Performance | Live FPS/memory stats via `call("performance")` |
| Show Prints | In-game `print()` capture → output channel |
| Evaluate Expression | Prompt → `call("eval", { code })` → show result |
| Capture Screenshot | `call("screenshot")` → save to file |
| Show Call Stack | `call("callStack")` → display in panel |

---

## 7. Visual Editors

All visual editors use VS Code's Webview API. Each editor:
1. Creates a `WebviewPanel` with `enableScripts: true` and `retainContextWhenHidden: true`
2. Renders a self-contained HTML/CSS/JS page
3. Communicates with the extension via `postMessage` / `onDidReceiveMessage`
4. Exports to Lua source files (game-ready code generation)

### Shared Infrastructure (`editors/sharedCss.ts`)

Provides:
- `getSharedCss()` — consistent dark theme styling matching VS Code
- `getCanvasInteractionJs()` — pan/zoom/drag logic for canvas-based editors
- `getZoomHudHtml()` — zoom controls overlay

### 7.1 Tile Map Editor

**Features**: Multi-layer tile painting, 16 tile types, configurable grid size, flood fill, export to Lua table or TOML.

**Data model**:
```typescript
{
  width: number,
  height: number,
  layers: Record<string, number[][]>,  // layer name → 2D grid
  tileNames: Record<number, string>    // tile ID → display name
}
```

**Export**: Generates a Lua file with `return { width=N, height=M, layers={...} }` format.

### 7.2 Scene Flow Editor

**Features**: Visual state machine designer — create scenes as nodes, connect with transition arrows, define transition events, export to Lua SceneManager class.

**Export**: Generates a complete `SceneManager` class with `init()`, scene registration, and transition methods.

### 7.3 Entity Designer

**Features**: ECS entity/component visual designer — define component schemas, create entity archetypes, export to Luna2D entity system format.

### 7.4 Pixel Art Editor

**Features**: Canvas-based pixel art drawing tool with color palette, brush sizes, layers, and Lua image data export.

### 7.5 Dialog Editor

**Features**: Branching conversation tree editor — nodes with text, choices with conditions, export to Lua dialog data.

### 7.6 Particle Designer

**Features**: Visual particle system tweaking — emitter properties, real-time preview, presets (fire, smoke, snow, etc.), export to `luna.particle.newParticleSystem()` Lua code.

### 7.7 Additional Editors

| Editor | Purpose | Export Format |
|--------|---------|---------------|
| Test Runner | Visual test execution panel | Test results display |
| Database Browser | DataFrame/database inspector | - |
| Procedural Map Gen | Random map generation with seeds | Lua map data |
| Quest Tree Editor | Quest/mission dependency tree | Lua quest data |
| GUI Widget Editor | Visual GUI layout designer | Lua widget code |
| AI Behavior Editor | Behavior tree / state machine | Lua AI code |
| Graph Editor | Generic node graph editor | Lua graph data |
| Tilemap Script Editor | Script-driven tilemap generation | Lua tilemap code |
| Voxel Editor | 3D voxel object editor | Lua voxel data |
| API Reference | Local API documentation browser | - |

---

## 8. Data Pipeline

### Pipeline Overview

```
docs/api/*.toml  ──────────────┐
         (TOML API catalog)    │
                               ▼
docs/api-reference/*.md  ──→  tools/generate-api-data.ts  ──→  data/api/completions.json
   (Markdown reference)        │                               data/api/hover.json
                               │                               data/api/signatures.json
                               │                               data/api/enums.json
                               │
docs/api/*.toml  ──────────→  tools/generate-snippets.ts  ──→  data/snippets/luna.json
                               │
docs/api/*.toml  ──────────→  tools/generate-luacats.ts   ──→  data/luacats/library/*.lua
```

### 8.1 Source of Truth

The authoritative API data lives in `docs/api-reference/*.md` (generated from `docs/api/*.toml` via `tools/regen-api-reference.ps1`).

The TOML is scanned from C++ source:
```
src/modules/*/wrap_*.cpp  →  tools/scan-api.ps1  →  docs/api/*.toml
```

### 8.2 generate-api-data.ts

**Input**: `docs/api-reference/*.md` — one Markdown file per module.

**Parsing logic**:
1. Split by `## Functions` / `## Types` / `## Enums` sections
2. For each `### functionName` heading: extract signature, description, parameters, returns
3. Build `CompletionItem[]`, `SignatureItem[]`, hover docs, and enum values

**Output files**:

| File | Content | Usage |
|------|---------|-------|
| `completions.json` | `{ label, kind, module, detail, insertText, documentation, parent }[]` | CompletionProvider |
| `signatures.json` | `{ label, module, parameters, documentation }[]` | SignatureHelpProvider |
| `hover.json` | `{ [key: string]: string }` — full name → doc body | HoverProvider |
| `enums.json` | `{ [enumName: string]: string[] }` — values | CompletionProvider (enum context) |

### 8.3 generate-snippets.ts

**Input**: `docs/api/*.toml` — parsed with `smol-toml`.

**Output**: `data/snippets/luna.json` — VS Code snippet format with tabstops.

Includes both:
- **Static patterns**: `luna-load`, `luna-update`, `luna-draw`, `luna-conf`, `luna-main` (hardcoded)
- **API-generated**: One snippet per function with parameter tabstops

### 8.4 generate-luacats.ts

**Input**: `docs/api/*.toml`

**Output**: LuaCATS annotation files for the [Lua Language Server](https://github.com/LuaLS/lua-language-server):
- `data/luacats/library/luna.lua` — root `luna` class with module fields
- `data/luacats/library/luna/{module}.lua` — per-module function stubs
- `data/luacats/library/types/{TypeName}.lua` — per-type class + method stubs

---

## 9. CAG Plugin System

The extension ships a complete **Copilot AI Game-Dev Configuration** (CAG) that can be installed into any Luna2D project's `.github/` directory.

### What Gets Installed

```
.github/
├── copilot-instructions.md    ← System prompt for every Copilot session
├── instructions/              ← 8 auto-loading instruction files
│   ├── lua-game.instructions.md
│   ├── main.instructions.md
│   ├── conf.instructions.md
│   ├── entities.instructions.md
│   ├── systems.instructions.md
│   ├── assets.instructions.md
│   ├── shader.instructions.md
│   └── saves.instructions.md
├── skills/                    ← 27 domain skill guides
│   ├── game-architecture/
│   ├── entity-system/
│   ├── physics-gameplay/
│   ├── combat-system/
│   ├── inventory-system/
│   ├── dialogue-system/
│   ├── quest-system/
│   ├── tilemap/
│   ├── particle-system/
│   ├── camera-system/
│   ├── save-load/
│   ├── ai-behaviors/
│   ├── input-handling/
│   ├── audio-design/
│   ├── graphics-effects/
│   ├── weather-system/
│   ├── fog-of-war/
│   ├── world-generation/
│   ├── crafting-system/
│   ├── animation/
│   ├── ui-hud/
│   ├── scene-transition/
│   ├── pathfinding/
│   ├── math-gameplay/
│   ├── event-bus/
│   ├── game-performance/
│   └── distribution/
├── prompts/                   ← 21 task playbooks
│   ├── new-game.prompt.md
│   ├── add-entity.prompt.md
│   ├── add-ai.prompt.md
│   ├── add-camera.prompt.md
│   ├── new-enemy.prompt.md
│   ├── new-quest.prompt.md
│   └── ... (16 more)
└── agents/                    ← 24 game dev agents
    ├── game-dev.agent.md
    ├── game-architect.agent.md
    ├── game-designer.agent.md
    ├── game-artist.agent.md
    ├── game-tester.agent.md
    ├── game-debugger.agent.md
    └── ... (18 more)
```

### Installation Mechanism

The `luna2d.cag.install` command copies the entire `cag/` directory from the extension bundle to the workspace's `.github/` folder. If `.github/` already exists, the user is prompted to confirm overwrite.

### Auto-Install on Scaffold

When `luna2d.cag.installOnScaffold` is `true` (default), creating a new project via `luna2d.newProject` automatically installs the CAG configuration.

---

## 10. Portability Guide — Recreating for a similar JS game engine / Other Engines

This section explains how to recreate the Luna2D Toolkit for a different game engine. We use **a similar JS game engine** (HTML5/JavaScript) as the primary example, with notes for other engines.

### 10.1 Project Initialization

**Create the extension scaffold:**

```bash
# Install VS Code extension generator
npm install -g yo generator-code

# Generate extension
yo code
#   Type: TypeScript
#   Name: engine-toolkit
#   Identifier: engine-toolkit
#   Description: a similar JS game engine game development toolkit
#   Bundler: esbuild
```

**Result**: A working extension skeleton with `package.json`, `src/extension.ts`, `tsconfig.json`, and `esbuild.config.mjs`.

### 10.2 Manifest Adaptation

Map every Luna2D Extension manifest section to your engine:

```jsonc
// package.json for a similar JS game engine
{
  "name": "engine-toolkit",
  "displayName": "a similar JS game engine Toolkit",
  "activationEvents": [
    "workspaceContains:**/engine.min.js",     // a similar game engine lib in project
    "workspaceContains:**/package.json",       // npm project
    "onLanguage:javascript",
    "onLanguage:typescript"
  ],
  "contributes": {
    "commands": [
      { "command": "engine.run",      "title": "a similar game engine: Start Dev Server" },
      { "command": "engine.stop",     "title": "a similar game engine: Stop Dev Server" },
      { "command": "engine.newProject", "title": "a similar game engine: New Project" },
      { "command": "engine.package",  "title": "a similar game engine: Build for Production" }
    ],
    "configuration": {
      "title": "a similar game engine Toolkit",
      "properties": {
        "engine.serverPort":     { "type": "number",  "default": 8080 },
        "engine.srcDir":         { "type": "string",  "default": "src" },
        "engine.bundler":        { "type": "string",  "default": "a dev server", "enum": ["a dev server", "webpack", "parcel"] },
        "engine.version":        { "type": "string",  "default": "3.80" }
      }
    }
  }
}
```

**Engine-specific activation mapping:**

| Luna2D | a similar JS game engine | a similar game engine | a major game engine |
|-----------------|----------|-------|-------|
| `workspaceContains:**/main.lua` | `workspaceContains:**/engine.min.js` or `package.json` with `engine` dep | `workspaceContains:**/project.engine` | `workspaceContains:**/*.sln` |
| `onLanguage:lua` | `onLanguage:javascript`, `onLanguage:typescript` | `onLanguage:engine-script` | `onLanguage:csharp` |

### 10.3 Services Layer — What to Recreate

#### API Data Service

The core pattern is identical for any engine — load API data from JSON into memory at activation:

```typescript
// a similar JS game engine equivalent of ApiDataService
export class a similar game engineApiDataService {
  private completions: CompletionItem[] = [];
  private hover: Record<string, string> = {};

  constructor(context: vscode.ExtensionContext) {
    // Load pre-generated API data
    const dataDir = path.join(context.extensionPath, "data", "api");
    this.completions = JSON.parse(fs.readFileSync(
      path.join(dataDir, "completions.json"), "utf-8"
    ));
    this.hover = JSON.parse(fs.readFileSync(
      path.join(dataDir, "hover.json"), "utf-8"
    ));
  }

  // Query methods — identical pattern
  getCompletionsForNamespace(ns: string): CompletionItem[] {
    return this.completions.filter(c => c.namespace === ns);
  }
}
```

**Where to get a similar game engine API data**:
1. Parse the official a similar JS game engine TypeScript definitions (`engine-api.d.ts` — ~80,000 lines)
2. Use the a similar JS game engine documentation JSON from https://newdocs.engine.io/
3. Write a `generate-api-data.ts` that reads `.d.ts` → outputs `completions.json`, `hover.json`, `signatures.json`

**Data generation script (a similar JS game engine example):**

```typescript
// tools/generate-engine-api.ts
import * as ts from "typescript";

// Parse engine-api.d.ts using TypeScript compiler API
const program = ts.createProgram(["node_modules/engine/types/engine-api.d.ts"], {});
const checker = program.getTypeChecker();

// Walk all declarations in the a similar game engine namespace
// Extract: class names, method signatures, property types, JSDoc comments
// Output: data/api/completions.json, hover.json, signatures.json, enums.json
```

#### Process Service

| Luna2D | a similar JS game engine Equivalent |
|-------|---------------------|
| `LoveProcessService` spawns `luna.exe <dir>` | `a similar game engineDevServerService` spawns `npx a dev server` or `npm run dev` |
| Detect `luna.exe` in PATH | Detect `node_modules/.bin/a dev server` or configured bundler |
| Output → "Luna2D" channel | Output → "a similar game engine Dev Server" channel |
| `process.kill()` to stop | `process.kill()` to stop dev server |

```typescript
// a similar JS game engine process service
export class a similar game engineDevServerService {
  private process: cp.ChildProcess | null = null;
  private outputChannel: vscode.OutputChannel;

  async run(projectDir: string): Promise<void> {
    const config = vscode.workspace.getConfiguration("engine");
    const bundler = config.get<string>("bundler", "a dev server");
    const port = config.get<number>("serverPort", 8080);

    let cmd: string, args: string[];
    switch (bundler) {
      case "a dev server":
        cmd = "npx"; args = ["a dev server", "--port", String(port)];
        break;
      case "webpack":
        cmd = "npx"; args = ["webpack", "serve", "--port", String(port)];
        break;
      case "parcel":
        cmd = "npx"; args = ["parcel", "index.html", "--port", String(port)];
        break;
    }

    this.process = cp.spawn(cmd, args, { cwd: projectDir, shell: true });
    // ... output capture, status events (same pattern as LoveProcessService)

    // Auto-open browser
    vscode.env.openExternal(vscode.Uri.parse(`http://localhost:${port}`));
  }
}
```

#### Debug Bridge

| Luna2D | a similar JS game engine Equivalent |
|-------|---------------------|
| Custom TCP JSON-RPC | browser devtools Protocol (CDP) via `chrome-remote-interface` |
| `call("eval", { code })` | `Runtime.evaluate({ expression })` via CDP |
| `call("performance")` | `Performance.getMetrics()` via CDP |
| `call("screenshot")` | `Page.captureScreenshot()` via CDP |

```typescript
// a similar JS game engine debug bridge using browser devtools Protocol
import CDP from "chrome-remote-interface";

export class a similar game engineDebugBridge {
  private client: CDP.Client | null = null;

  async connect(port = 9222): Promise<boolean> {
    this.client = await CDP({ port });
    await this.client.Runtime.enable();
    await this.client.Debugger.enable();
    return true;
  }

  async eval(expression: string): Promise<any> {
    const result = await this.client!.Runtime.evaluate({
      expression,
      returnByValue: true
    });
    return result.result.value;
  }

  async getFPS(): Promise<number> {
    return this.eval("game.loop.actualFps");
  }

  async getSceneList(): Promise<string[]> {
    return this.eval("game.scene.scenes.map(s => s.sys.settings.key)");
  }
}
```

### 10.4 Language Providers — Engine-Specific Adaptations

#### Completion Provider

| Pattern | Luna2D (Lua) | a similar JS game engine (JS/TS) |
|---------|-------------|-------------------|
| Trigger | `luna.graphics.` | `this.add.`, `this.physics.`, `a similar game engine.` |
| Module prefix regex | `/luna\.(\w+)\.$/` | `/this\.(\w+)\.$/` or `/a similar game engine\.(\w+)\.$/` |
| Type methods | `Image:getWidth()` | `this.sprite.setScale()` |
| Enum values | `luna.graphics.FilterMode` | `a similar game engine.BlendModes`, `a similar game engine.Physics.Arcade` |

```typescript
// a similar JS game engine completion provider
registerCompletionProvider(context, apiData) {
  vscode.languages.registerCompletionItemProvider(
    [{ language: "javascript" }, { language: "typescript" }],
    {
      provideCompletionItems(document, position) {
        const line = document.lineAt(position).text.substring(0, position.character);

        // this.add. → a similar game engine.GameObjects.GameObjectFactory methods
        const addMatch = line.match(/this\.add\.$/);
        if (addMatch) {
          return apiData.getCompletionsForClass("GameObjectFactory");
        }

        // this.physics. → a similar game engine.Physics.Arcade methods
        const physicsMatch = line.match(/this\.physics\.$/);
        if (physicsMatch) {
          return apiData.getCompletionsForClass("ArcadePhysics");
        }

        // a similar game engine.Scene → class-level completions
        const nsMatch = line.match(/a similar game engine\.(\w+)\.$/);
        if (nsMatch) {
          return apiData.getCompletionsForNamespace(nsMatch[1]);
        }
      }
    },
    "."
  );
}
```

#### Diagnostics Provider

Map Luna2D Extension diagnostics to a similar JS game engine equivalents:

| Luna2D Diagnostic | a similar JS game engine Equivalent |
|-------------------|---------------------|
| Color range 0-255 vs 0-1 | Hex color without `0x` prefix: `setTint(ff0000)` → should be `setTint(0xff0000)` |
| Deprecated API calls | `game.add.sprite()` → "Use `this.add.sprite()` inside a Scene" |
| Missing `luna.event.pump()` | Missing `super()` call in Scene's `create()` method |
| `math.random` vs `luna.math.random` | `Math.random()` vs `a similar game engine.Math.Between()` for reproducibility |
| Unused `require()` | Unused `import` statements |
| Asset validation | Check that preloaded asset keys match `this.load.*()` calls |

```typescript
// a similar JS game engine diagnostic: detect common mistakes
const PHASER_DIAGNOSTICS = {
  // Detect this.add.* outside of Scene class
  "game.add.": {
    message: "Use 'this.add.*' inside a Scene class, not 'game.add.*'",
    severity: vscode.DiagnosticSeverity.Error
  },
  // Detect old a similar game engine 2 API
  "game.state.": {
    message: "a similar game engine 2 API detected. Use Scene system in a similar JS game engine.",
    severity: vscode.DiagnosticSeverity.Error
  }
};
```

#### Color Provider

| Luna2D | a similar JS game engine |
|-------|----------|
| `setColor(r, g, b, a)` with 0-1 floats | `setTint(0xRRGGBB)` with hex integers |
| Regex: `setColor\s*\(\s*([0-9.]+)` | Regex: `setTint\s*\(\s*0x([0-9a-fA-F]{6})` |

```typescript
// a similar JS game engine color provider
const tintPattern = /setTint\s*\(\s*0x([0-9a-fA-F]{6})\s*\)/g;
while ((match = tintPattern.exec(text)) !== null) {
  const hex = match[1];
  const r = parseInt(hex.substring(0, 2), 16) / 255;
  const g = parseInt(hex.substring(2, 4), 16) / 255;
  const b = parseInt(hex.substring(4, 6), 16) / 255;
  // Return vscode.ColorInformation with range
}
```

### 10.5 Commands — Engine-Specific Mapping

| Luna2D Command | a similar JS game engine Command | Implementation |
|---------------|-------------------|----------------|
| Run Game (`luna.exe dir`) | Start Dev Server (`a dev server` / `webpack serve`) | Spawn bundler process |
| Stop Game (`process.kill()`) | Stop Dev Server (`process.kill()`) | Same |
| Package Bundle (ZIP) | Build for Production (`a dev server build`) | Spawn bundler build |
| Package Windows (fuse exe) | Deploy to itch.io / GitHub Pages | Upload build output |
| New Project (template copy) | New Project (`npm create a dev server@latest`) | Template + deps install |
| Install Library (GitHub download) | Install Library (`npm install <pkg>`) | Run npm/yarn |
| Dependency Graph (require analysis) | Dependency Graph (import analysis) | Parse `import` statements |
| Run Tests (`luna testing --all`) | Run Tests (`npm test`) | Spawn test runner |

#### Scaffold Commands (a similar JS game engine)

```typescript
const PHASER_TEMPLATES = {
  "minimal": "Bare a similar JS game engine scene with preload/create/update",
  "platformer": "Side-scrolling platformer with Arcade physics",
  "top-down": "Top-down game with tilemap and camera follow",
  "multiplayer": "Socket.io multiplayer starter",
  "typescript": "TypeScript + Vite a similar JS game engine project",
};

// Template structure for "platformer":
// engine-platformer/
// ├── index.html
// ├── package.json        (engine dependency)
// ├── a dev server.config.js
// ├── src/
// │   ├── main.js         (a similar game engine.Game config)
// │   ├── scenes/
// │   │   ├── Boot.js
// │   │   ├── Preloader.js
// │   │   ├── Game.js
// │   │   └── GameOver.js
// │   └── objects/
// │       └── Player.js
// └── public/
//     └── assets/
```

#### Package Commands (a similar JS game engine)

```typescript
async function buildForProduction(projectDir: string): Promise<void> {
  const config = vscode.workspace.getConfiguration("engine");
  const bundler = config.get<string>("bundler", "a dev server");

  let cmd: string;
  switch (bundler) {
    case "a dev server": cmd = "npx a dev server build"; break;
    case "webpack": cmd = "npx webpack --mode production"; break;
    case "parcel": cmd = "npx parcel build index.html"; break;
  }

  // Execute build → output to dist/
  await runCommand(cmd, projectDir);

  // Offer deployment options
  const choice = await vscode.window.showQuickPick([
    { label: "Open dist/ folder", action: "open" },
    { label: "Deploy to itch.io", action: "itch" },
    { label: "Deploy to GitHub Pages", action: "ghpages" },
    { label: "Create ZIP", action: "zip" },
  ]);
}
```

### 10.6 Visual Editors — Fully Reusable

The webview editors are **90% engine-agnostic**. Only the Lua export format changes.

**What to change per engine:**

| Editor | Luna2D Export | a similar JS game engine Export |
|--------|-------------|-----------------|
| Tile Map Editor | Lua table: `return { layers={...} }` | JSON Tiled format or JS module: `export default { layers: [...] }` |
| Scene Flow Editor | Lua SceneManager class | JS Scene registry: `game.scene.add('key', SceneClass)` |
| Entity Designer | Luna2D ECS components | a similar game engine `Sprite`/`Group` with components |
| Particle Editor | `luna.particle.newParticleSystem()` calls | `this.add.particles()` a similar JS game engine config |
| Dialog Editor | Lua dialog tables | JSON dialog data or JS module |
| Pixel Art Editor | `luna.image.newImageData()` pixel writes | Canvas → PNG data URL → save as file |

**Reusable without changes:**
- All HTML/CSS/JS for the editor UI
- Canvas interaction (pan, zoom, drag)
- Shared CSS theming
- Property panels and toolbars

**Example — Tile Map Editor export for a similar JS game engine:**

```typescript
function exporta similar game engineTilemap(data: MapData): string {
  // Export as Tiled-compatible JSON (a similar game engine's native tilemap format)
  return JSON.stringify({
    width: data.width,
    height: data.height,
    tilewidth: 32,
    tileheight: 32,
    layers: Object.entries(data.layers).map(([name, grid]) => ({
      name,
      type: "tilelayer",
      data: grid.flat(),
      width: data.width,
      height: data.height,
    })),
    tilesets: [{
      firstgid: 1,
      name: "tiles",
      tilewidth: 32,
      tileheight: 32,
    }],
  }, null, 2);
}
```

### 10.7 Data Pipeline — The Critical Adaptation

This is the most engine-specific part. You need a pipeline that extracts API data from your engine's source/types and generates JSON files.

**Luna2D pipeline:**
```
C++ wrap_*.cpp → scan-api.ps1 → docs/api/*.toml → api-reference/*.md → generate-api-data.ts → data/api/*.json
```

**a similar JS game engine pipeline:**
```
engine-api.d.ts → generate-engine-api.ts → data/api/*.json
```

**Detailed a similar JS game engine data generation:**

```typescript
// tools/generate-engine-api.ts
import * as ts from "typescript";
import * as fs from "fs";

const PHASER_DTS = "node_modules/engine/types/engine-api.d.ts";

interface a similar game engineCompletion {
  label: string;
  kind: "function" | "method" | "property" | "class" | "enum";
  namespace: string;      // e.g., "GameObjects" | "Physics.Arcade"
  className?: string;     // e.g., "Sprite" | "Scene"
  detail: string;         // signature string
  insertText: string;     // snippet with tabstops
  documentation?: string; // JSDoc
}

function generatea similar game engineData() {
  const program = ts.createProgram([PHASER_DTS], { target: ts.ScriptTarget.ES2022 });
  const sourceFile = program.getSourceFile(PHASER_DTS)!;
  const checker = program.getTypeChecker();

  const completions: a similar game engineCompletion[] = [];
  const hover: Record<string, string> = {};
  const signatures: any[] = [];

  function visit(node: ts.Node, namespace: string = "a similar game engine") {
    if (ts.isModuleDeclaration(node) && node.name) {
      const ns = `${namespace}.${node.name.text}`;
      ts.forEachChild(node, child => visit(child, ns));
    }

    if (ts.isClassDeclaration(node) && node.name) {
      const className = node.name.text;

      // Extract methods
      for (const member of node.members) {
        if (ts.isMethodDeclaration(member) && member.name) {
          const name = (member.name as ts.Identifier).text;
          const sig = checker.getSignatureFromDeclaration(member);
          if (!sig) continue;

          const params = sig.parameters.map(p => {
            const type = checker.typeToString(checker.getTypeOfSymbolAtLocation(p, member));
            return `${p.name}: ${type}`;
          });

          completions.push({
            label: name,
            kind: "method",
            namespace,
            className,
            detail: `${className}.${name}(${params.join(", ")})`,
            insertText: `${name}(${params.map((p, i) => `\${${i + 1}:${p.split(":")[0]}}`).join(", ")})`,
            documentation: ts.displayPartsToString(sig.getDocumentationComment(checker)),
          });

          hover[`${className}:${name}`] = `**${className}.${name}**(${params.join(", ")})\n\n${
            ts.displayPartsToString(sig.getDocumentationComment(checker))
          }`;
        }
      }
    }
  }

  visit(sourceFile);

  // Write output files
  fs.writeFileSync("data/api/completions.json", JSON.stringify(completions, null, 2));
  fs.writeFileSync("data/api/hover.json", JSON.stringify(hover, null, 2));
  fs.writeFileSync("data/api/signatures.json", JSON.stringify(signatures, null, 2));
}

generatea similar game engineData();
```

### 10.8 CAG Plugin — Engine-Specific AI Configuration

The CAG system is fully portable — only the **content** of the files changes.

**Directory structure (identical):**
```
cag/
├── copilot-instructions.md     ← System prompt (rewrite for your engine)
├── instructions/               ← File-type specific rules
├── skills/                     ← Domain knowledge guides
├── prompts/                    ← Task playbooks
└── agents/                     ← Specialist agent definitions
```

**a similar JS game engine system prompt example:**

```markdown
# a similar JS game engine Game Development — System Prompt

- **Tech baseline**: a similar JS game engine.80 | JavaScript ES2022 / TypeScript 5.x | Vite | Arcade/Matter.js Physics
- **Primary docs**: https://newdocs.engine.io | https://example-engine-docs.invalid

## Coding Style
- Use ES6 classes extending `a similar game engine.Scene`
- Prefer `this.add.*` over `game.add.*`
- Load assets in `preload()`, create objects in `create()`, game logic in `update()`
- Use `a similar game engine.Math.Between()` instead of `Math.random()`
- Group related game objects with `this.add.group()`

## Project Structure
```
my-game/
├── src/
│   ├── main.js         — Game config + boot
│   ├── scenes/         — One file per scene
│   ├── objects/         — Game objects (Player, Enemy, etc.)
│   ├── systems/         — Game systems (Combat, Inventory)
│   └── utils/           — Helper functions
├── public/assets/       — Images, audio, tilemaps
├── index.html
├── package.json
└── a dev server.config.js
```
```

**a similar JS game engine instructions example:**

```markdown
<!-- instructions/scenes.instructions.md -->
# applyTo: src/scenes/**

- Every scene class extends `a similar game engine.Scene`
- Call `super({ key: 'SceneName' })` in constructor
- Use `this.scene.start('OtherScene')` for transitions
- Preload assets in `preload()` — never in `create()`
- Use `this.cameras.main.fadeIn()` for smooth transitions
```

**a similar JS game engine skill example (physics-gameplay):**

```markdown
<!-- skills/physics-gameplay/SKILL.md -->
# Physics Gameplay Skill

## Arcade Physics
- Enable per-scene: `this.physics.add.existing(sprite)`
- Collision: `this.physics.add.collider(player, platforms)`
- Overlap: `this.physics.add.overlap(player, coins, collectCoin)`
- Set velocity: `sprite.body.setVelocityX(160)`
- Gravity: `this.physics.world.gravity.y = 300`

## Matter.js Physics
- Enable in config: `physics: { default: 'matter' }`
- Create body: `this.matter.add.rectangle(x, y, w, h)`
- Collision events: `this.matter.world.on('collisionstart', callback)`
```

### 10.9 Library Manager — Ecosystem Adaptation

| Aspect | Luna2D | a similar JS game engine |
|--------|-------|----------|
| Catalog source | Static `libraries.json` (GitHub repos) | npm registry + curated list |
| Install mechanism | Download from GitHub, extract to `libs/` | `npm install <package>` |
| Registry | `libs/.registry.json` | `package.json` dependencies |
| Categories | 22 game-dev categories | Same categories, different libraries |

**a similar JS game engine library catalog example:**

```json
{
  "categories": ["Physics", "Animation", "UI", "Networking", "AI", "Audio"],
  "libraries": [
    {
      "id": "engine3-rex-plugins",
      "name": "Rex Plugins",
      "description": "200+ plugins for a similar JS game engine",
      "category": "Helpers",
      "npm": "engine3-rex-plugins",
      "repo": "rexrainbow/engine3-rex-notes"
    },
    {
      "id": "navmesh",
      "name": "NavMesh",
      "description": "Navigation mesh pathfinding",
      "category": "AI",
      "npm": "navmesh",
      "repo": "mikewesthad/navmesh"
    }
  ]
}
```

### 10.10 MCP Server — Protocol-Level Reuse

The MCP server pattern is completely engine-agnostic. Only tool implementations change.

**Luna2D MCP tools → a similar JS game engine equivalents:**

| Luna2D Tool | a similar JS game engine Tool |
|-------------|---------------|
| `run_game` (spawn luna.exe) | `start_dev_server` (start a dev server) |
| `list_scenes` (parse Lua) | `list_scenes` (parse JS Scene classes) |
| `analyze_performance` (parse engine metrics) | `analyze_performance` (browser performance tooling / browser devtools) |
| `validate_assets` (check engine filesystem) | `validate_assets` (check `public/assets/` dir) |
| `generate_entity` (emit Lua entity code) | `generate_scene` (emit JS Scene class) |

### 10.11 Full Checklist — What to Build for Any Engine

Below is a complete checklist for recreating this extension for a new engine. Items marked with ♻️ are directly reusable from Luna2D Extension; items marked with 🔧 need engine-specific adaptation.

#### Phase 1 — Foundation (Week 1)

- [ ] 🔧 **package.json manifest** — activation events, commands, settings for your engine
- [ ] ♻️ **extension.ts entry point** — same service→provider→command→editor pattern
- [ ] 🔧 **ApiDataService** — load JSON; change data shape for your engine's API surface
- [ ] 🔧 **ProcessService** — adapt executable resolution and spawn for your engine's runtime
- [ ] ♻️ **StatusBar** — run/stop buttons (fully reusable)
- [ ] 🔧 **Data pipeline** — write a generator that extracts API data from your engine's type definitions/docs

#### Phase 2 — Language Providers (Week 2)

- [ ] 🔧 **CompletionProvider** — change trigger patterns and API namespace structure
- [ ] 🔧 **HoverProvider** — change symbol regex patterns
- [ ] 🔧 **SignatureHelpProvider** — adapt to your language's function call syntax
- [ ] 🔧 **DiagnosticsProvider** — write engine-specific diagnostic rules
- [ ] ♻️ **DocumentSymbolProvider** — adapt regex for your language's function declaration syntax
- [ ] 🔧 **ColorProvider** — adapt to your engine's color representation (hex, RGB, HSL)
- [ ] ♻️ **AssetPathProvider** — change file extension filters for your engine's asset types
- [ ] ♻️ **DefinitionProvider** — adapt import/require resolution for your language
- [ ] ♻️ **ReferenceProvider** — mostly reusable; change word boundary regex
- [ ] ♻️ **InlayHintsProvider** — same pattern; different API data
- [ ] ♻️ **CodeActionsProvider** — same pattern; different quick-fix rules

#### Phase 3 — Commands (Week 3)

- [ ] 🔧 **Run commands** — engine-specific executable/server launch
- [ ] 🔧 **Scaffold commands** — engine-specific project templates
- [ ] 🔧 **Package commands** — engine-specific build/distribution
- [ ] 🔧 **Test commands** — engine-specific test runner integration
- [ ] ♻️ **Dependency graph** — change `require` → `import` parsing
- [ ] ♻️ **Game jam tools** — fully reusable (timer, checklist are engine-agnostic)
- [ ] 🔧 **Library manager** — change download mechanism (npm vs GitHub raw)

#### Phase 4 — Visual Editors (Week 4-5)

- [ ] ♻️ **Tile Map Editor** — reuse UI; change export format (JSON/JS instead of Lua)
- [ ] ♻️ **Scene Flow Editor** — reuse UI; change export format
- [ ] ♻️ **Entity Designer** — reuse UI; change export format
- [ ] ♻️ **Pixel Art Editor** — fully reusable (exports PNG)
- [ ] ♻️ **Dialog Editor** — reuse UI; change export format (JSON/JS)
- [ ] ♻️ **Particle Editor** — reuse UI; change export to engine's particle config format
- [ ] ♻️ **All other editors** — same pattern: reuse UI, adapt export

#### Phase 5 — AI Integration (Week 6)

- [ ] 🔧 **copilot-instructions.md** — rewrite system prompt for your engine
- [ ] 🔧 **instructions/*.instructions.md** — rewrite file-type rules
- [ ] 🔧 **skills/*/SKILL.md** — rewrite domain skills with your engine's patterns
- [ ] 🔧 **prompts/*.prompt.md** — rewrite task playbooks
- [ ] 🔧 **agents/*.agent.md** — adapt agent roles (mostly same roles, different tools)
- [ ] 🔧 **MCP server** — rewrite tool implementations for your engine

#### Phase 6 — Testing & Polish (Week 7)

- [ ] ♻️ **Test framework** — same zero-dep test runner pattern
- [ ] 🔧 **Test cases** — engine-specific test scenarios
- [ ] ♻️ **esbuild config** — fully reusable
- [ ] ♻️ **CI/CD pipeline** — same pattern; change test commands

### 10.12 Architecture Decision Matrix

When making decisions for your port, use this matrix:

| Decision | Option A | Option B | Recommendation |
|----------|----------|----------|----------------|
| API data source | Parse engine source code | Use existing type definitions | **Type definitions** — TypeScript `.d.ts` files are already structured |
| Data format | TOML → JSON pipeline | Direct JSON generation | **Direct JSON** — skip TOML unless you have an existing doc pipeline |
| Language support | Single language (JS/TS) | Polyglot (that engine's scripting language + C#) | **Single first** — add more languages in v2 |
| Visual editors | Framework (React/Vue) | Vanilla HTML/JS | **Vanilla** — no framework dependencies to bundle |
| Debug protocol | Custom TCP | browser devtools Protocol | **CDP** for web engines; custom for native engines |
| Library manager | npm integration | Custom catalog | **npm** for Node.js engines; custom for others |
| Process management | Direct spawn | VS Code Task API | **Direct spawn** — more control over lifecycle |

---

## 11. Build & Package

### Build Configuration

```javascript
// esbuild.config.mjs
const config = {
  entryPoints: ["src/extension.ts"],
  bundle: true,
  outfile: "dist/extension.js",
  external: ["vscode"],           // VS Code API provided by host
  format: "cjs",                  // CommonJS (required by VS Code)
  platform: "node",
  target: "node18",
  sourcemap: !production,
  minify: production,
  loader: { ".json": "json" },   // Inline JSON imports
};
```

### Build Commands

```bash
# Development build (with sourcemaps)
npm run build

# Production build (minified, no sourcemaps)
npm run build -- --production

# Watch mode
npm run watch

# Generate API data (run before build if TOML changed)
npx tsx tools/generate-api-data.ts
npx tsx tools/generate-snippets.ts
npx tsx tools/generate-luacats.ts

# Package as VSIX
npx @vscode/vsce package
```

### VSIX Contents

The packaged `.vsix` file includes:
- `dist/extension.js` — bundled TypeScript (single file)
- `data/` — all JSON data files, templates, snippets
- `cag/` — AI configuration files
- `mcp/` — MCP server Python script
- `media/` — icons and assets
- `package.json` — manifest

Files excluded (via `.vscodeignore`): `src/`, `tests/`, `tools/`, `node_modules/`, `*.ts`.

---

## 12. Testing

### Test Framework

Zero-dependency test runner in `tests/runner.js`:

```javascript
// tests/runner.js — discovers and runs *.test.js files
// Pattern: describe() → it() → assert.*()
// Output: TAP-like format with pass/fail counts
```

### Test Files

- `tests/providers.test.js` — tests for all 12 language providers
- `tests/commands.test.js` — tests for command registration and execution
- `tests/services.test.js` — tests for API data loading and process management
- `tests/editors.test.js` — tests for webview editor content generation

### Running Tests

```bash
cd extension
npm test                    # Run all tests
npm test -- --verbose       # Verbose output
```

---

## 13. MCP Server Integration

The extension includes a Python-based MCP server (`mcp/game_mcp_server.py`) that provides 12 game development tools via JSON-RPC 2.0 over stdio.

### Installation

The `luna2d.mcp.installGameServer` command writes MCP server configuration to the user's VS Code settings.

### Tools

| Tool | Purpose |
|------|---------|
| `run_game` | Start Luna2D with the game project |
| `list_scenes` | Parse Lua files for scene/state definitions |
| `list_entities` | Find entity/class definitions |
| `analyze_deps` | Build dependency graph from `require()` |
| `validate_assets` | Check that referenced asset files exist |
| `generate_entity` | Generate entity boilerplate from schema |
| `check_performance` | Run performance analysis |
| `search_api` | Search the Luna2D API catalog |
| `get_api_docs` | Get documentation for a specific API function |
| `list_libraries` | List available community libraries |
| `validate_project` | Check project structure and conf.lua |
| `generate_tests` | Generate test stubs for game code |

### Security

- CSF-002: Path traversal prevention on all file operations
- CSF-006: Shell metacharacter stripping on all subprocess arguments
- All paths resolved within `LOVE_GAME_ROOT` boundary

---

## 14. Configuration Reference

All settings live under the `luna2d.*` namespace.

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `luna2d.lovePath` | string | `""` | Luna2D executable path (empty = auto-detect) |
| `luna2d.srcDir` | string | `""` | Game source subdirectory |
| `luna2d.saveOnRun` | boolean | `true` | Auto-save before run |
| `luna2d.version` | enum | `"12.0"` | Target Luna2D API version |
| `luna2d.package.outputDir` | string | `"dist"` | Package output directory |
| `luna2d.package.excludePatterns` | string[] | `[".git",".github",".vscode","dist","*.md",".gitignore"]` | Package exclusions |
| `luna2d.package.icon` | string | `""` | Windows .ico path |
| `luna2d.package.windowsRuntime` | string | `""` | Luna2D Windows runtime directory |
| `luna2d.diagnostics.deprecationWarnings` | boolean | `true` | Deprecated API warnings |
| `luna2d.diagnostics.commonMistakes` | boolean | `true` | Common mistake detection |
| `luna2d.diagnostics.unusedRequires` | boolean | `true` | Unused require detection |
| `luna2d.diagnostics.assetValidation` | boolean | `true` | Asset path validation |
| `luna2d.inlayHints.parameterNames` | boolean | `true` | Parameter name inlay hints |
| `luna2d.test.testDir` | string | `"tests"` | Test directory |
| `luna2d.cag.installOnScaffold` | boolean | `true` | Install AI config on project creation |

---

## Appendix A — File Count Summary

| Component | Files | Description |
|-----------|-------|-------------|
| Providers | 12 | Language intelligence providers |
| Commands | 10 | Command group files |
| Visual Editors | 17 | Webview-based editors |
| Services | 4 | Backend service classes |
| Data generators | 3 | Build-time TypeScript scripts |
| API data files | 4 | Generated JSON (completions, hover, signatures, enums) |
| Project templates | 6 | Scaffolding templates |
| CAG instructions | 8 | Auto-loading file-type rules |
| CAG skills | 27 | Domain knowledge guides |
| CAG prompts | 21 | Task playbooks |
| CAG agents | 24 | Specialist agent definitions |

## Appendix B — a similar JS game engine Quick-Start Skeleton

For those starting a a similar JS game engine port immediately, here is the minimal file set:

```
engine-toolkit/
├── package.json              ← Extension manifest
├── tsconfig.json
├── esbuild.config.mjs
├── src/
│   ├── extension.ts          ← activate(), register all
│   ├── services/
│   │   ├── apiData.ts        ← Load a similar game engine API data
│   │   ├── devServer.ts      ← Vite/webpack process management
│   │   └── statusBar.ts      ← Run/stop buttons
│   ├── providers/
│   │   ├── completion.ts     ← a similar game engine.* and this.* completions
│   │   ├── hover.ts          ← JSDoc-based hover
│   │   ├── diagnostics.ts    ← a similar game engine 2→3 migration warnings
│   │   └── signature.ts      ← Parameter hints
│   └── commands/
│       ├── run.ts            ← Start/stop dev server
│       ├── scaffold.ts       ← Project templates
│       └── package.ts        ← Production build
├── data/
│   └── api/                  ← Generated from engine-api.d.ts
├── tools/
│   └── generate-engine-api.ts ← Parse .d.ts → JSON
└── cag/                      ← a similar JS game engine AI game dev config
```

---

*Source: Extension source code at `extension/src/`, data pipeline at `extension/tools/`, manifest at `extension/package.json`. All code citations verified against v0.8.2.*
