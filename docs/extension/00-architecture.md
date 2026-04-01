# Luna Toolkit — VS Code Extension Architecture

> Design document for the Luna2D integrated development environment extension.
> This extension is **standalone-optional**: everything it provides can also be done
> without it (CLI, manual editing, Copilot agents). The extension makes it faster.

---

## 1. Identity

| Field | Value |
|---|---|
| **Name** | Luna Toolkit |
| **ID** | `luna2d.luna-toolkit` |
| **Display name** | Luna Toolkit |
| **Description** | Complete development toolkit for Luna2D game engine — IntelliSense, visual editors, run/test/package, debug bridge, and AI-powered game development |
| **VS Code engine** | `^1.90.0` |
| **Language** | TypeScript (esbuild-bundled) |
| **Categories** | Programming Languages, Game Development, Other |
| **License** | MIT |

---

## 2. Activation

```jsonc
"activationEvents": [
  "workspaceContains:**/main.lua",      // Game project detected
  "workspaceContains:Cargo.toml",       // Engine source detected
  "onLanguage:lua",                     // Any Lua file opened
  "onView:luna.projectTools",           // Sidebar opened
  "onCommand:luna.runGame"              // Manual command trigger
]
```

---

## 3. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Luna Toolkit Extension                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐  │
│  │  Activation  │  │  Services    │  │  API Data Pipeline     │  │
│  │  extension.ts│  │              │  │                        │  │
│  │             │→ │  apiData.ts  │  │  generated API docs    │  │
│  │  Register   │  │  lunaProc.ts │  │       ↓                │  │
│  │  all parts  │  │  debugBridge │  │  Completions / Hover   │  │
│  │             │  │  statusBar   │  │  Signatures / Snippets │  │
│  └─────────────┘  └──────────────┘  └────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Language Providers                      │  │
│  │  completion │ hover │ signature │ definition │ references │  │
│  │  diagnostics│ symbols│ color   │ inlayHints │ codeActions │  │
│  │  assetPath  │       │          │            │             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Sidebar Tree Views                      │  │
│  │  projectTools │ devTools │ aiCopilot                      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Commands                                │  │
│  │  run │ test │ scaffold │ package │ depGraph │ debugBridge │  │
│  │  gameJam │ library                                        │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Webview Editors (16)                    │  │
│  │  tileMap │ sceneFlow │ entity │ pixelArt │ dialog │       │  │
│  │  particle│ database │ procMap │ questTree│ guiWidget│      │  │
│  │  aiBehavior│ graph │ tilemapScript│ voxel │ testRunner│    │  │
│  │  apiReference                                             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    MCP Server                              │  │
│  │  stdio JSON-RPC │ tool handlers │ CAG bundling            │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    Custom Editors                          │  │
│  │  *.scene.lua  → Scene Flow Editor                         │  │
│  │  *.entity.lua → Entity Designer (future)                  │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    CAG Layer (Bundled)                     │  │
│  │  18 agents │ 33 skills │ instructions │ prompts           │  │
│  │  Installable to user workspace .github/                   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Directory Structure

```
vscode-extension/
├── package.json                    ← Extension manifest
├── tsconfig.json                   ← TypeScript config
├── esbuild.config.mjs              ← Bundle config (single file output)
├── .vscodeignore                   ← Files excluded from VSIX
├── README.md                       ← Marketplace description
├── CHANGELOG.md                    ← Version history
├── media/
│   ├── sidebar-icon.svg            ← Activity bar icon (moon/rocket)
│   ├── luna-logo.png               ← For webviews and welcome
│   └── icons/                      ← Codicon overrides if needed
├── data/
│   ├── api-completions.json        ← Generated: luna.* completion items
│   ├── api-signatures.json         ← Generated: function signatures
│   ├── api-hover.json              ← Generated: hover documentation
│   ├── api-enums.json              ← Generated: enum values
│   └── snippets.json               ← Generated: code snippets
├── cag/                            ← Bundled CAG for installation
│   ├── agents/                     ← 18 agent definitions
│   ├── skills/                     ← 33 skill definitions
│   ├── instructions/               ← Instruction files
│   └── prompts/                    ← Task prompts
├── tools/
│   ├── generate-api-data.ts        ← Build luna.* completions from docs
│   ├── generate-snippets.ts        ← Build snippet JSON
│   └── generate-luacats.ts         ← Build LuaCATS annotations
├── src/
│   ├── extension.ts                ← Activation entry point
│   ├── commands/                   ← Command implementations
│   │   ├── run.ts                  ← Run/stop game
│   │   ├── test.ts                 ← Run tests (Rust + Lua)
│   │   ├── scaffold.ts             ← New project / new file
│   │   ├── package.ts              ← Package game (single-file bundle style)
│   │   ├── depGraph.ts             ← Dependency visualization
│   │   ├── debugBridge.ts          ← Debug bridge commands
│   │   ├── gameJam.ts              ← Game jam tools
│   │   ├── library.ts              ← Library manager
│   │   ├── testGenerator.ts        ← Generate test boilerplate
│   │   └── sceneEditor.ts          ← Custom editor for .scene.lua
│   ├── editors/                    ← Webview-based visual editors
│   │   ├── sharedCss.ts            ← Shared CSS theme + utilities
│   │   ├── mapEditor.ts            ← Tile Map Editor
│   │   ├── sceneFlowEditor.ts      ← Scene Flow Editor
│   │   ├── entityDesigner.ts       ← Entity Designer
│   │   ├── pixelArtEditor.ts       ← Pixel Art Editor
│   │   ├── dialogEditor.ts         ← Dialog Editor
│   │   ├── particleEditor.ts       ← Particle Designer
│   │   ├── databaseBrowser.ts      ← Database Browser
│   │   ├── proceduralMapGen.ts     ← Procedural Map Generator
│   │   ├── questTreeEditor.ts      ← Quest / Tech Tree Editor
│   │   ├── guiWidgetEditor.ts      ← GUI Widget Editor
│   │   ├── aiBehaviorEditor.ts     ← AI Behavior Tree
│   │   ├── graphEditor.ts          ← Graph / Node Editor
│   │   ├── tilemapScriptEditor.ts  ← Tilemap Script Editor
│   │   ├── voxelEditor.ts          ← Voxel Editor
│   │   ├── testRunner.ts           ← Visual Test Runner
│   │   └── apiReference.ts         ← API Reference Browser
│   ├── providers/                  ← Language feature providers
│   │   ├── completion.ts           ← luna.* autocomplete
│   │   ├── hover.ts                ← Hover documentation
│   │   ├── signature.ts            ← Parameter hints
│   │   ├── definition.ts           ← Go to definition
│   │   ├── references.ts           ← Find all references
│   │   ├── diagnostics.ts          ← Linting & warnings
│   │   ├── symbols.ts              ← Document symbols / outline
│   │   ├── color.ts                ← Color picker (0–1 values)
│   │   ├── assetPath.ts            ← Asset path completion
│   │   ├── inlayHints.ts           ← Parameter name hints
│   │   ├── codeActions.ts          ← Quick fixes / refactoring
│   │   └── sidebar.ts              ← 3× TreeDataProvider
│   ├── services/                   ← Shared business logic
│   │   ├── apiData.ts              ← API metadata loader/cache
│   │   ├── lunaProcess.ts          ← Luna2D process management
│   │   ├── debugBridge.ts          ← TCP debug bridge protocol
│   │   └── statusBar.ts            ← Status bar management
│   └── mcp/                        ← MCP server (existing)
│       ├── server.ts               ← JSON-RPC stdio server
│       └── tools.ts                ← MCP tool handlers
└── test/
    ├── suite/                      ← Extension integration tests
    └── runTest.ts                  ← Test launcher
```

---

## 5. Data Flow

### 5.1 API Data Pipeline

```
generated API docs/metadata   ← Produced by tools/gen_lua_api.py
         │
         ▼
tools/generate-api-data.ts    ← Transform to VS Code-specific formats
         │
         ├─→ data/api-completions.json   (CompletionItem[])
         ├─→ data/api-signatures.json    (SignatureHelp map)
         ├─→ data/api-hover.json         (MarkdownString map)
         └─→ data/api-enums.json         (enum constant map)

tools/generate-snippets.ts    ← Build code patterns
         │
         └─→ data/snippets.json          (VS Code snippet format)

tools/generate-luacats.ts     ← Build type annotation stubs
         │
         └─→ data/luna2d.lua             (LuaCATS annotation file)

At activation:
  services/apiData.ts loads JSON → providers read from cache
```

### 5.2 IntelliSense Flow

```
User types "luna.gr"
         │
         ▼
  completion.ts → apiData.ts → match "luna.graphics.*" → return CompletionItems
         │
         ▼
User selects "luna.graphics.draw"
         │
         ▼
  signature.ts → apiData.ts → return SignatureHelp(image, x, y, r, sx, sy, ox, oy)
         │
         ▼
  hover.ts → apiData.ts → return MarkdownString with full docs
```

### 5.3 Webview Editor Communication

```
Extension (TypeScript)                Webview (HTML + JS)
         │                                    │
         │── createWebviewPanel() ──────────► │ (loads HTML)
         │                                    │
         │◄── postMessage({type:"ready"}) ─── │
         │                                    │
         │── postMessage({type:"init",...}) ─► │ (load data)
         │                                    │
         │◄── postMessage({type:"save",...})── │ (user saves)
         │                                    │
         │── write file to disk ──────────► │
         │                                    │
         │── postMessage({type:"saved"}) ──► │ (confirm)
```

---

## 6. Module Dependency Graph

```
extension.ts ─────────────────────────────────────────────────────
  │
  ├── services/apiData.ts          (no deps, loaded first)
  ├── services/statusBar.ts        (no deps)
  ├── services/lunaProcess.ts      (no deps)
  ├── services/debugBridge.ts      (depends on lunaProcess)
  │
  ├── providers/* ─────────────── all depend on apiData.ts
  │
  ├── commands/* ──────────────── depend on services as needed
  │   ├── run.ts                   → lunaProcess
  │   ├── test.ts                  → lunaProcess
  │   ├── debugBridge.ts           → debugBridge service
  │   └── scaffold.ts              → (filesystem only)
  │
  ├── editors/* ───────────────── depend on sharedCss.ts
  │   └── sharedCss.ts             (no deps, pure HTML/CSS generation)
  │
  └── mcp/* ───────────────────── depends on apiData, lunaProcess
```

---

## 7. Configuration Settings

```jsonc
{
  "luna.lunaPath": {
    "type": "string",
    "default": "",
    "description": "Path to luna2d executable (auto-detected if on PATH or in workspace)"
  },
  "luna.srcDir": {
    "type": "string",
    "default": "",
    "description": "Game source subdirectory (default: workspace root)"
  },
  "luna.saveOnRun": {
    "type": "boolean",
    "default": true,
    "description": "Save open files before running the game"
  },
  "luna.diagnostics.deprecationWarnings": {
    "type": "boolean",
    "default": true,
    "description": "Show warnings for deprecated luna.* API usage"
  },
  "luna.diagnostics.commonMistakes": {
    "type": "boolean",
    "default": true,
    "description": "Detect common Luna2D mistakes (0-255 colors, missing callbacks)"
  },
  "luna.diagnostics.unusedRequires": {
    "type": "boolean",
    "default": true,
    "description": "Flag unused require() statements"
  },
  "luna.diagnostics.assetValidation": {
    "type": "boolean",
    "default": true,
    "description": "Validate that asset file paths exist on disk"
  },
  "luna.inlayHints.parameterNames": {
    "type": "boolean",
    "default": true,
    "description": "Show inline parameter name hints for luna.* calls"
  },
  "luna.test.testDir": {
    "type": "string",
    "default": "tests",
    "description": "Directory containing test files"
  },
  "luna.test.luaTestDir": {
    "type": "string",
    "default": "tests/lua",
    "description": "Directory containing Lua test scripts"
  },
  "luna.cag.installOnScaffold": {
    "type": "boolean",
    "default": true,
    "description": "Auto-install AI config when scaffolding a new project"
  },
  "luna.package.outputDir": {
    "type": "string",
    "default": "dist",
    "description": "Output directory for packaged builds"
  },
  "luna.debugBridge.port": {
    "type": "number",
    "default": 19740,
    "description": "TCP port for debug bridge connection (1024-65535)"
  },
  "luna.debugBridge.autoConnect": {
    "type": "boolean",
    "default": true,
    "description": "Auto-connect debug bridge when running with debug"
  }
}
```

---

## 8. Key Design Decisions

### 8.1 Inline HTML vs Separate Webview Files

**Decision**: Inline HTML generation (same as reference extension).

**Rationale**:
- All HTML/CSS/JS in a single TypeScript file per editor
- Shared CSS via `sharedCss.ts` function import
- Avoids complex asset URI resolution for webview resources
- Easier to bundle (single esbuild output)
- Trade-off: larger TS files, but simpler deployment

### 8.2 API Data at Build Time vs Runtime

**Decision**: Pre-generate JSON at build time, load at activation.

**Rationale**:
- `tools/gen_lua_api.py` output is the source material
- Build scripts transform to VS Code-optimized formats
- Fast startup — no parsing Rust source at runtime
- CI can regenerate when API changes

### 8.3 Bundled CAG vs Reference-Only

**Decision**: Bundle full CAG layer, installable to user workspace.

**Rationale**:
- Game developers who use Copilot get pre-tuned AI config
- Extension command installs `.github/` agents/skills/instructions
- Engine contributors already have `.github/` in workspace
- No external download needed

### 8.4 Luna2D Process Management

**Decision**: Detect `luna` / `luna.exe` on PATH or `cargo run`.

**Rationale**:
- If `luna` binary installed → use directly (fast)
- If Cargo.toml in workspace → `cargo run --` (dev mode)
- Configurable via `luna.lunaPath` setting
- Process management via `child_process` with output capture

### 8.5 Debug Bridge Protocol

**Decision**: TCP socket with JSON-RPC messages.

**Rationale**:
- Matches pattern established by reference extension
- Luna2D engine opens TCP listener when `--debug` flag passed
- Extension connects and sends eval/inspect/screenshot commands
- Port configurable, default 19740

---

## 9. Technology Choices

| Component | Technology | Reason |
|---|---|---|
| Build system | esbuild | Fast bundling, tree-shaking, single output file |
| Language | TypeScript 5.x | VS Code extension standard |
| Webview rendering | Raw HTML + CSS + JS | No framework needed, lightweight, matches reference |
| Canvas interaction | HTML5 Canvas API | Hardware-accelerated 2D drawing for editors |
| IPC (webview) | `postMessage()` | VS Code built-in, secure, typed |
| IPC (debug) | TCP + JSON-RPC | Cross-process, language-agnostic |
| API data format | JSON | Fast to parse, easy to generate from Rust docstrings |
| Snippets format | VS Code native | Integrated with completion engine |
| Testing | @vscode/test-electron | Official extension test framework |
| Packaging | @vscode/vsce | Standard VSIX packaging |

---

## 10. Security Considerations

1. **Webview CSP**: All webviews set `Content-Security-Policy` restricting scripts to `nonce`-based inline
2. **Asset path validation**: `assetPath.ts` prevents path traversal outside workspace
3. **Debug bridge**: Only connects to `localhost` by default
4. **MCP tools**: Path validation on all file operations
5. **CAG installation**: Writes only to `.github/` in the workspace root
6. **Command execution**: Only runs `luna`/`cargo` executables, no arbitrary shell
7. **Webview file I/O**: All file writes go through extension host, not webview directly
