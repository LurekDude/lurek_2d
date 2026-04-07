# Gaps: Documentation vs Implementation

## Overview

The extension documentation (`docs/extension/`) describes a comprehensive "Luna Toolkit" extension.
The implementation (`vscode-extension/`) contains **substantially more than expected** — but it lives across
**two competing versions** of the entry-point files that are never reconciled.

## Critical Finding: Two Extension Versions

| File | v1 (active) | v2 (unused) |
|---|---|---|
| Entry point | `extension.ts` — 4 commands, MCP only | `extension2.ts` — 90+ commands, all providers, editors, debug, sidebar |
| Manifest | `package.json` — 4 commands, no views | `package2.json` — 100+ commands, sidebar, keybindings, menus, settings |
| Readme | `README.md` | `README2.md` |
| Vscodeignore | `.vscodeignore` | `.vscodeignore2` |

**Impact**: v2 is the production-grade implementation. v1 is a minimal stub that ships nothing useful.
The docs describe nearly everything in v2, but v2 is NOT the wired-up version (package.json ≠ package2.json).

### Recommendation

Retire v1 files. Rename v2 → canonical. This is the single highest-impact action for the extension.

---

## Gap Matrix: Documentation vs v2 Implementation

### Features Present in Both (Aligned)

| Feature Area | Doc Ref | Impl Files | Status |
|---|---|---|---|
| 3 sidebar views | 01-sidebar | providers/sidebar.ts | ✅ Aligned (v2 adds Assets view) |
| Run/Stop commands | 04-commands | commands/run.ts | ✅ Aligned |
| Test commands (Rust + Lua) | 01-sidebar, 04-commands | commands/test.ts + testGenerator.ts | ✅ Aligned |
| Scaffold commands | 04-commands | commands/scaffold.ts | ✅ Aligned (3 templates vs 6 planned) |
| Package commands | 04-commands | commands/packaging.ts | ✅ Aligned |
| 16 original editors | 03-editors | 16 matching editor .ts files | ✅ Aligned |
| 11 batch-2 editors | 09-new-editors | 11 matching editor .ts files | ✅ Aligned |
| MCP server | 04-commands | mcp/server.ts, mcp/tools.ts | ✅ Aligned (4 tools vs 10 planned) |
| Debug Bridge | 04-commands | services/debugBridge.ts, commands/debugBridge.ts | ✅ Aligned |
| CAG layer | 04-commands, 10-game-dev-cag | commands/cag.ts, commands/gameDevCag.ts | ✅ Aligned |
| Game Jam commands | 04-commands | commands/gameJam.ts | ✅ Aligned |
| Library browser | 04-commands | commands/library.ts | ✅ Aligned |
| 11 language providers | 02-intellisense | 11 matching provider .ts files | ✅ Aligned |
| Diagnostic rules | 02-intellisense | providers/diagnostics.ts (9 rules) | ✅ Exceeds (9 vs 6 planned) |
| Status bar | 04-commands | services/statusBar.ts | ✅ Aligned |
| Keybindings (4) | 06-package-json | package2.json | ✅ Aligned |
| Custom editor (*.scene.lua) | 06-package-json | package2.json | ✅ Aligned |
| Configuration (13 settings) | 06-package-json | package2.json | ✅ Aligned (15 settings) |
| Context menus | 06-package-json | package2.json | ✅ Aligned |

### Features in Implementation But NOT in Documentation

| Feature | Impl Files | Impact |
|---|---|---|
| **Lua Debug Adapter (DAP)** | debug/luaDebugAdapter.ts, luaDebugSession.ts | Full VS Code debugger integration (launch + attach). Docs only mention TCP Debug Bridge. |
| **LuaCATS annotation support** | providers/luacatsProvider.ts | Parses `---@class`, `---@field`, `---@param` for user-defined types. Undocumented feature. |
| **Code Lens** | providers/codeLens.ts | Function references, test detection, callback docs. Not in any design doc. |
| **Formatting provider** | providers/formatting.ts | Lua code formatter with indent tracking. Not documented. |
| **Folding provider** | providers/folding.ts | Custom folding ranges. Not documented. |
| **Rename provider** | providers/rename.ts | Symbol rename support. Not documented. |
| **Semantic Tokens** | providers/semanticTokens.ts | Namespace, callback, deprecation coloring. Not documented. |
| **LuaJIT hints** | providers/luajitHints.ts | LuaJIT-specific perf diagnostics. Mentioned in 08-intellisense-enhanced but not in main provider list. |
| **Type inference** | providers/typeInference.ts | Return type tracking from factories. Same — in enhanced doc but not main list. |
| **Require graph** | providers/requireGraph.ts | Cycle detection, missing module warnings. Not documented. |
| **Symbol index** | services/symbolIndex.ts | Workspace-wide symbol indexing. Not documented. |
| **Lua parser** | services/luaParser.ts (~1100 lines) | Complete tokenizer + analyzer. Not documented as standalone service. |
| **Performance dashboard** | providers/perfDashboard.ts | Webview with FPS/frame graphs. Not in design docs. |
| **System monitor** | providers/systemMonitor.ts | CPU/RAM/disk/network. Windows PowerShell + Unix. Not documented. |
| **Debug watchers** | providers/debugWatchers.ts | Watch expression panel. Not documented. |
| **API usage report** | providers/apiUsage.ts | Luna API coverage analysis. Not documented. |
| **Asset explorer** | providers/assetExplorer.ts | Tree view for game assets. Not documented. |
| **Hot-reload watcher** | inline in extension2.ts | File system watcher for *.lua changes. Not documented. |
| **Circular dep finder** | inline in extension2.ts | Tarjan's SCC on src/ module imports. Not documented. |
| **Orphan module finder** | inline in extension2.ts | Finds unreferenced modules. Not documented. |
| **Variable inspector** | inline in extension2.ts | Debug expression evaluator webview. Not documented. |
| **PostFX & Overlay editor** | editors/postfxOverlayEditor.ts | Combined VFX editor. Not in docs. |
| **Sound DSP editor** | editors/soundDspEditor.ts | Audio effects editor. Not in docs. |
| **Extract to Module refactor** | inline in extension2.ts | Extract selection → new module. Not documented. |

### Features in Documentation But NOT in Implementation

| Feature | Doc Ref | Notes |
|---|---|---|
| **Visual scripting** | visual_scripting.md | Block-based DAG editor with graph→Lua compiler. No impl files. |
| **Data pipeline / generated JSON** | 00-architecture, 02-intellisense | Docs specify api-completions.json, api-signatures.json, api-hover.json, api-enums.json generated from `///` doc comments. No `data/` folder exists. `apiData.ts` loads data differently. |
| **tools/generate-api-data.ts** | 00-architecture | No tools/ folder in extension directory. API data generation happens via Python scripts in repo root tools/. |
| **esbuild bundler** | 00-architecture | Docs say `dist/extension.js` via esbuild. Actual build uses `tsc` → `out/`. |
| **6 project templates** | 01-sidebar | Scaffold has 3 templates (Minimal, Game Loop, Physics) vs 6 planned (adds Platformer, Top-Down, ECS). |
| **10 MCP tools** | 04-commands | Only 4 MCP tools implemented (runExample, getApiDoc, listExamples, runLuaTest). Missing: getModuleInfo, inspectLuaFile, generateTest, getTestCoverage, scaffoldProject, runDiagnostics. |
| **Easing ASCII curve hover** | 08-intellisense-enhanced | Not visible in hover.ts (has easing descriptions but no ASCII art). |
| **12 pattern library snippets** | 08-intellisense-enhanced | Library browser has ~3 snippets. Snippets file (`data/snippets.json`) doesn't exist. |
| **Extension test suite** | 05-implementation-plan | No test/ folder in extension. |
| **media/ folder** | 06-package-json | Icons referenced but folder not present. |

---

## Gap Severity Assessment

### Critical (Blocks Publishing)

1. **v1/v2 file split** — Cannot publish with extension.ts that registers only 4 commands while extension2.ts has the real implementation. This must be resolved first.
2. **Missing data/ folder** — Several providers reference API data files that don't exist. Runtime errors likely.
3. **Missing media/ folder** — Sidebar icon and extension icon referenced in package.json but files don't exist.
4. **No build script works** — `tsc` is configured but `package2.json` references `./dist/extension.js` (esbuild output path) while actual tsconfig outputs to `./out/`.

### High (Degrades Experience)

5. **No snippets.json** — package2.json contributes snippets from `./data/snippets.json` but file doesn't exist.
6. **No extension tests** — Zero test coverage for the extension.
7. **10 MCP tools planned, 4 implemented** — 60% of MCP tools missing.
8. **Documentation drift** — 20+ features exist in implementation that have zero documentation.

### Medium (Improvement Area)

9. **Template gap** — 3 of 6 project templates implemented.
10. **Visual scripting** — Entire module documented but no implementation. Either scope-cut or implement.
11. **Easing curve visualization** — Documented in enhanced IntelliSense but not implemented.
