# Luna Toolkit — Implementation Plan

> Phased implementation plan for building the complete Luna Toolkit extension.
> Each phase is self-contained with its own acceptance gates.

---

## Implementation Phases Overview

```
Phase 0 ─► Phase 1 ─► Phase 2a ─► Phase 2b ─► Phase 3 ─► Phase 4 ─► Phase 5a ─► Phase 5b ─► Phase 6 ─► Phase 7
Scaffold    Core       Intel-      Intel-       Editors    Debug      Engine      Game-Dev   Polish     Package
& Build     Commands   liSense v1  liSense v2   (27)       Bridge     CAG         CAG        & Test     & Publish
```

| Phase | Name | Scope | Estimated Files | Dependencies |
|---|---|---|---|---|
| 0 | Project Scaffold | Build system, package.json, esbuild | 5 | None |
| 1 | Core Commands & Sidebar | Run/stop, sidebar tree views, status bar | 8 | Phase 0 |
| 2a | IntelliSense v1 | 11 language providers (baseline) | 14 | Phase 0 |
| 2b | IntelliSense v2 | LuaJIT hints, type inference, patterns (see `08-intellisense-enhanced.md`) | 8 | Phase 2a |
| 3 | Visual Editors | All 27 webview editors (see `09-new-editors.md`) | 29 | Phase 0 |
| 4 | Testing & Debug Bridge | Test commands, debug TCP, test runner | 6 | Phase 1 |
| 5a | Engine CAG | Existing `.github/` CAG bundling for engine devs | 5 | Phase 1 |
| 5b | Game-Dev CAG | Full game-dev CAG layer (see `10-game-dev-cag.md`) | 55+ | Phase 1 |
| 6 | Polish & Testing | Extension tests, error handling, docs | 6 | All above |
| 7 | Package & Publish | VSIX packaging, marketplace, README | 3 | Phase 6 |

**Phases 2a, 3, 4, 5a are independent** — can be developed in parallel after Phase 1.
**Phase 2b depends on 2a. Phase 5b is independent of 5a.**

---

## Phase 0: Project Scaffold

**Goal**: Set up the build system, TypeScript config, and extension manifest.

### Tasks

| # | Task | File(s) | Agent |
|---|---|---|---|
| 0.1 | Rewrite `package.json` with full manifest | `package.json` | Developer |
| 0.2 | Set up esbuild config | `esbuild.config.mjs` | Developer |
| 0.3 | Update `tsconfig.json` for esbuild | `tsconfig.json` | Developer |
| 0.4 | Create `.vscodeignore` for clean VSIX | `.vscodeignore` | Developer |
| 0.5 | Add npm scripts (build, watch, package) | `package.json` | Developer |
| 0.6 | Create sidebar icon SVG | `media/sidebar-icon.svg` | Developer |
| 0.7 | Verify `npm run build` succeeds | — | Tester |

### Acceptance Gates

- [ ] `npm install` succeeds
- [ ] `npm run build` produces `dist/extension.js`
- [ ] Extension loads in Extension Development Host (F5)
- [ ] Status bar shows "Luna2D" indicator
- [ ] Activity bar shows Luna Toolkit icon (placeholder)

### Deliverables

```
package.json              ← Full contributes (commands, views, settings, keybindings)
tsconfig.json             ← Updated for esbuild
esbuild.config.mjs        ← Production build config
.vscodeignore             ← Clean packaging
media/sidebar-icon.svg    ← Activity bar icon
src/extension.ts          ← Activation shell (registers everything)
```

---

## Phase 1: Core Commands & Sidebar

**Goal**: Implement the sidebar tree views, run/stop commands, and status bar.

### Tasks

| # | Task | File(s) | Agent |
|---|---|---|---|
| 1.1 | Implement `ProjectToolsProvider` | `src/providers/sidebar.ts` | Developer |
| 1.2 | Implement `DevToolsProvider` | `src/providers/sidebar.ts` | Developer |
| 1.3 | Implement `AiToolsProvider` | `src/providers/sidebar.ts` | Developer |
| 1.4 | Implement run/stop commands | `src/commands/run.ts` | Developer |
| 1.5 | Implement Luna2D process manager | `src/services/lunaProcess.ts` | Developer |
| 1.6 | Implement status bar manager | `src/services/statusBar.ts` | Developer |
| 1.7 | Implement scaffold commands | `src/commands/scaffold.ts` | Developer |
| 1.8 | Wire up extension.ts activation | `src/extension.ts` | Developer |
| 1.9 | Write extension activation test | `test/` | Tester |

### Acceptance Gates

- [ ] Sidebar shows three view sections with all nodes
- [ ] Clicking "Run Game" launches `luna` or `cargo run` in terminal
- [ ] Clicking "Stop Game" terminates the process
- [ ] Status bar updates (Running/Stopped)
- [ ] "New Project from Template" creates files from template
- [ ] All sidebar tree nodes are clickable and trigger correct commands
- [ ] Extension activates on `main.lua` presence

### Key Design: Process Detection

```typescript
// src/services/lunaProcess.ts
class LunaProcessService {
  private process: ChildProcess | null = null;

  async findLunaBinary(): Promise<string> {
    // 1. Check luna.lunaPath setting
    // 2. Check PATH for 'luna' / 'luna.exe'
    // 3. Check workspace for Cargo.toml → use 'cargo run --'
    // 4. Fail with helpful message
  }

  async run(gameDir: string, args: string[]): Promise<void> { ... }
  stop(): void { ... }
  isRunning(): boolean { ... }
}
```

---

## Phase 2a: IntelliSense (Baseline)

**Goal**: Core Lua language intelligence for `luna.*` API.
See `02-intellisense-design.md` for the full baseline spec.

### Sub-phases

#### Phase 2a-i: API Data Pipeline

| # | Task | File(s) | Agent |
|---|---|---|---|
| 2a.1 | Create `generate-api-data.ts` | `tools/generate-api-data.ts` | Developer |
| 2a.2 | Create `generate-snippets.ts` | `tools/generate-snippets.ts` | Developer |
| 2a.3 | Create `generate-luacats.ts` | `tools/generate-luacats.ts` | Developer |
| 2a.4 | Create `ApiDataService` | `src/services/apiData.ts` | Developer |
| 2a.5 | Generate initial data files | `data/*.json` | Developer |

#### Phase 2a-ii: Language Providers

| # | Task | File(s) | Agent |
|---|---|---|---|
| 2a.6 | Completion provider | `src/providers/completion.ts` | Developer |
| 2a.7 | Hover provider | `src/providers/hover.ts` | Developer |
| 2a.8 | Signature help provider | `src/providers/signature.ts` | Developer |
| 2a.9 | Definition provider | `src/providers/definition.ts` | Developer |
| 2a.10 | References provider | `src/providers/references.ts` | Developer |
| 2a.11 | Document symbol provider | `src/providers/symbols.ts` | Developer |
| 2a.12 | Diagnostics provider | `src/providers/diagnostics.ts` | Developer |
| 2a.13 | Color provider | `src/providers/color.ts` | Developer |
| 2a.14 | Asset path provider | `src/providers/assetPath.ts` | Developer |
| 2a.15 | Inlay hints provider | `src/providers/inlayHints.ts` | Developer |
| 2a.16 | Code actions provider | `src/providers/codeActions.ts` | Developer |
| 2a.17 | Snippet contribution | `data/snippets.json` | Developer |

### Acceptance Gates (Phase 2a)

- [ ] Typing `luna.` shows module completions
- [ ] Typing `luna.gfx.` shows function list
- [ ] Hovering over `luna.gfx.draw` shows full docs with params
- [ ] Function signature help shows on `(`
- [ ] `F12` on `require("module")` jumps to file
- [ ] `Shift+F12` finds all references across workspace
- [ ] Outline view shows functions and callbacks
- [ ] Color picker works on `setColor(r, g, b, a)`
- [ ] Asset path autocomplete works in `newImage("...")`
- [ ] Inlay hints show parameter names
- [ ] Deprecated API shows warning diagnostic
- [ ] 0-255 color range shows diagnostic
- [ ] Unused `require` shows hint with quick-fix
- [ ] Snippets appear in completion (e.g., `luna.gameloop`)

---

## Phase 2b: IntelliSense Enhanced

**Goal**: LuaJIT-specific intelligence, type inference, and the pattern library.
See `08-intellisense-enhanced.md` for fullspec.

| # | Task | File(s) | Agent |
|---|---|---|---|
| 2b.1 | LuaJIT completions (bit.*, jit.*) | `src/providers/completion.ts` | Developer |
| 2b.2 | LuaJIT hints provider | `src/providers/luajitHints.ts` | Developer |
| 2b.3 | Type inference engine | `src/providers/typeInference.ts` | Developer |
| 2b.4 | OOP class pattern detection | `src/providers/typeInference.ts` | Developer |
| 2b.5 | Contextual string completions (keys, blend modes) | `src/providers/completion.ts` | Developer |
| 2b.6 | Easing hover chart generation | `src/providers/hover.ts` | Developer |
| 2b.7 | Pattern library snippets | `data/patterns/*.lua` | Developer |
| 2b.8 | Require graph provider | `src/providers/requireGraph.ts` | Developer |
| 2b.9 | Workspace symbol index | `src/services/symbolIndex.ts` | Developer |
| 2b.10 | Extended code actions (12 new) | `src/providers/codeActions.ts` | Developer |

### Acceptance Gates (Phase 2b)

- [ ] `bit.` completions show band, bor, bxor, etc.
- [ ] `jit.` completions show on, off, flush, status
- [ ] Resource creation in `luna.draw` shows Hint diagnostic
- [ ] `local img = luna.gfx.newImage(...)` enables `img:` method completions
- [ ] `luna.input.isDown("|")` shows key name completions
- [ ] `luna.gfx.setBlendMode("|")` shows blend mode completions
- [ ] Easing function hover shows ASCII curve chart
- [ ] Pattern library snippets appear under `luna.pattern.*` prefix
- [ ] Circular require shows error diagnostic
- [ ] Global variable writes show hint diagnostic

---

## Phase 3: Visual Editors

**Goal**: Implement all 16 webview-based editors.

### Sub-phases (grouped by complexity)

#### Phase 3a: Foundation + Simple Editors

| # | Task | File(s) | Agent |
|---|---|---|---|
| 3a.1 | Shared CSS + utilities | `src/editors/sharedCss.ts` | Developer |
| 3a.2 | API Reference Browser | `src/editors/apiReference.ts` | Developer |
| 3a.3 | Database Browser | `src/editors/databaseBrowser.ts` | Developer |
| 3a.4 | Test Runner | `src/editors/testRunner.ts` | Developer |

#### Phase 3b: Canvas-Based Editors

| # | Task | File(s) | Agent |
|---|---|---|---|
| 3b.1 | Tile Map Editor | `src/editors/mapEditor.ts` | Developer |
| 3b.2 | Pixel Art Editor | `src/editors/pixelArtEditor.ts` | Developer |
| 3b.3 | Voxel Editor | `src/editors/voxelEditor.ts` | Developer |

#### Phase 3c: Node Graph Editors

| # | Task | File(s) | Agent |
|---|---|---|---|
| 3c.1 | Scene Flow Editor | `src/editors/sceneFlowEditor.ts` | Developer |
| 3c.2 | AI Behavior Tree | `src/editors/aiBehaviorEditor.ts` | Developer |
| 3c.3 | Graph / Node Editor | `src/editors/graphEditor.ts` | Developer |
| 3c.4 | Quest / Tech Tree | `src/editors/questTreeEditor.ts` | Developer |

#### Phase 3d: Form-Based Editors

| # | Task | File(s) | Agent |
|---|---|---|---|
| 3d.1 | Entity Designer | `src/editors/entityDesigner.ts` | Developer |
| 3d.2 | GUI Widget Editor | `src/editors/guiWidgetEditor.ts` | Developer |
| 3d.3 | Dialog Editor | `src/editors/dialogEditor.ts` | Developer |

#### Phase 3e: Simulation Editors

| # | Task | File(s) | Agent |
|---|---|---|---|
| 3e.1 | Particle Designer | `src/editors/particleEditor.ts` | Developer |
| 3e.2 | Procedural Map Gen | `src/editors/proceduralMapGen.ts` | Developer |
| 3e.3 | Tilemap Script | `src/editors/tilemapScriptEditor.ts` | Developer |

#### Phase 3f: Custom Editor Provider

| # | Task | File(s) | Agent |
|---|---|---|---|
| 3f.1 | Scene `.scene.lua` custom editor | `src/commands/sceneEditor.ts` | Developer |

#### Phase 3g: New Editors Batch 2 (see `09-new-editors.md`)

| # | Editor | File(s) | Agent |
|---|---|---|---|
| 3g.1 | Sprite Sheet & Animation Editor | `src/editors/spriteAnimEditor.ts` | Developer |
| 3g.2 | Tileset Editor | `src/editors/tilesetEditor.ts` | Developer |
| 3g.3 | Audio Mixer | `src/editors/audioMixer.ts` | Developer |
| 3g.4 | Color Palette Editor | `src/editors/colorPaletteEditor.ts` | Developer |
| 3g.5 | Input Mapper | `src/editors/inputMapper.ts` | Developer |
| 3g.6 | Timeline / Cutscene Editor | `src/editors/timelineEditor.ts` | Developer |
| 3g.7 | Shader Preview | `src/editors/shaderPreview.ts` | Developer |
| 3g.8 | Font Preview | `src/editors/fontPreview.ts` | Developer |
| 3g.9 | Localization Editor | `src/editors/localizationEditor.ts` | Developer |
| 3g.10 | Physics Material Library | `src/editors/physicsMaterials.ts` | Developer |
| 3g.11 | World Map / Room Connector | `src/editors/worldMapEditor.ts` | Developer |

### Acceptance Gates

- [ ] Each of the 27 editors opens via command palette or sidebar click
- [ ] Shared CSS theme is consistent across all editors
- [ ] Canvas editors support pan/zoom with HUD
- [ ] Export Lua button generates valid Lua code
- [ ] Export TOML button generates valid TOML
- [ ] Editors retain state when hidden (`retainContextWhenHidden: true`)
- [ ] All message protocols work (save, load, export)
- [ ] `.scene.lua` files open in Scene Flow Editor automatically
- [ ] Batch-2 editors (3g) pass same acceptance criteria
- [ ] Sprite sheet slicer correctly handles arbitrary grid sizes
- [ ] Input mapper live-binds key presses correctly

---

## Phase 4: Testing & Debug Bridge

**Goal**: Full test integration and runtime debug bridge.

### Tasks

| # | Task | File(s) | Agent |
|---|---|---|---|
| 4.1 | Test command implementations | `src/commands/test.ts` | Developer |
| 4.2 | Test generator command | `src/commands/testGenerator.ts` | Developer |
| 4.3 | Debug bridge TCP client | `src/services/debugBridge.ts` | Developer |
| 4.4 | Debug bridge commands | `src/commands/debugBridge.ts` | Developer |
| 4.5 | Performance metrics panel | uses `debugBridge.ts` | Developer |
| 4.6 | Print history capture | uses `debugBridge.ts` | Developer |

### Acceptance Gates

- [ ] "Run All Tests" executes `cargo test` with output
- [ ] Individual module tests run correctly
- [ ] Lua tests run via `cargo test --test lua_tests`
- [ ] Debug bridge connects to running game on configured port
- [ ] `Evaluate Lua` sends expression and displays result
- [ ] Performance metrics update in real-time
- [ ] Screenshot captures and saves to workspace
- [ ] Print history shows captured output with file/line

### Engine-Side Requirements (Rust)

The debug bridge requires engine support. The engine needs:
1. `--debug-bridge` CLI flag to enable TCP listener
2. TCP server on configurable port (default 19740)
3. JSON-RPC message handler for evaluate/inspect/screenshot
4. Print capture hook (redirect `print()` output)

This is a **cross-cutting concern** — it requires both extension (Phase 4) and engine (separate task) work.

---

## Phase 5a: Engine CAG Integration

**Goal**: Bundle the existing engine-dev CAG (`.github/`) for distribution with the extension.

### Tasks

| # | Task | File(s) | Agent |
|---|---|---|---|
| 5a.1 | Bundle engine CAG files in extension | `cag/engine-dev/` | CAG-Architect |
| 5a.2 | Install CAG command | `src/commands/cag.ts` | Developer |
| 5a.3 | Agent/skill/prompt picker UI | `src/commands/cag.ts` | Developer |
| 5a.4 | Enhance MCP tool handlers | `src/mcp/tools.ts` | Developer |
| 5a.5 | Add new MCP tools | `src/mcp/tools.ts` | Developer |
| 5a.6 | Game jam commands | `src/commands/gameJam.ts` | Developer |
| 5a.7 | Library manager | `src/commands/library.ts` | Developer |

### Acceptance Gates (Phase 5a)

- [ ] "Install AI Config (Engine)" copies `.github/` engine-dev files to workspace
- [ ] Agent picker shows all engine agents with descriptions
- [ ] Skill picker shows all engine skills with descriptions
- [ ] MCP server exposes all 10 tools
- [ ] Game jam timer works with color-coded urgency

---

## Phase 5b: Game-Dev CAG Layer

**Goal**: Implement the full game-developer CAG layer for deployment into game projects.
See `10-game-dev-cag.md` for the complete specification.

### Tasks

| # | Task | File(s) | Agent |
|---|---|---|---|
| 5b.1 | 11 game-dev agent definitions | `cag/game-dev/agents/*.agent.md` | CAG-Architect |
| 5b.2 | 26 game-dev skill SKILL.md files | `cag/game-dev/skills/*/SKILL.md` | CAG-Architect |
| 5b.3 | 15 prompt playbooks | `cag/game-dev/prompts/*.prompt.md` | CAG-Architect |
| 5b.4 | 8 instruction files | `cag/game-dev/instructions/*.md` | CAG-Architect |
| 5b.5 | 12 project templates | `cag/game-dev/templates/*/` | Developer |
| 5b.6 | Deploy command (copy to .github/) | `src/commands/gameDevCag.ts` | Developer |
| 5b.7 | Project scaffold command | `src/commands/scaffold.ts` | Developer |
| 5b.8 | Validate game-dev CAG | `tools/cag_validate.py --dir cag/game-dev` | CAG-Architect |

### Acceptance Gates (Phase 5b)

- [ ] `python tools/cag_validate.py --dir vscode-extension/cag/game-dev` exits 0
- [ ] "New Game Project" dialog offers all 12 templates
- [ ] Selecting a template scaffolds correct file tree
- [ ] "Deploy Game Dev AI Layer" copies files to `[workspace]/.github/`
- [ ] Deployed instructions have correct `applyTo` patterns
- [ ] Agent descriptions accurately match their scope
- [ ] Skill files include working Lua code examples that use `luna.*`
- [ ] Prompt files correctly route to appropriate agents
- [ ] No agent references engine source files (`src/`, `Cargo.toml`)
- [ ] `game-jam` template initializes a runnable hello-world in < 5 files

---

## Phase 6: Polish & Testing

**Goal**: Comprehensive testing, error handling, documentation.

### Tasks

| # | Task | File(s) | Agent |
|---|---|---|---|
| 6.1 | Extension integration tests | `test/suite/` | Tester |
| 6.2 | Provider unit tests | `test/suite/providers/` | Tester |
| 6.3 | Error handling audit | all `src/` | Reviewer |
| 6.4 | Performance audit | all `src/` | Optimizer |
| 6.5 | Write README.md | `README.md` | Doc-Writer |
| 6.6 | Write CHANGELOG.md | `CHANGELOG.md` | Doc-Writer |

### Acceptance Gates

- [ ] All tests pass: `npm test`
- [ ] No unhandled promise rejections
- [ ] Extension activates in < 200ms
- [ ] API data loads in < 100ms
- [ ] README covers all features with screenshots
- [ ] CHANGELOG documents all additions

---

## Phase 7: Package & Publish

**Goal**: Create VSIX, publish to marketplace.

### Tasks

| # | Task | File(s) | Agent |
|---|---|---|---|
| 7.1 | Package VSIX | — | Developer |
| 7.2 | Test VSIX install | — | Tester |
| 7.3 | Publish to marketplace | — | Manager |

### Acceptance Gates

- [ ] `npm run package` creates `.vsix` file < 5MB
- [ ] VSIX installs cleanly in fresh VS Code
- [ ] All features work from installed VSIX
- [ ] Marketplace listing has icon, description, screenshots

---

## Dependency Graph

```
Phase 0 (Scaffold)
    │
    ├──► Phase 1 (Core Commands) ─────────────────────────────────────────────────────┐
    │        │                                                                          │
    │        ├──► Phase 4 (Testing & Debug)                                             │
    │        │                                                                          │
    │        ├──► Phase 5a (Engine CAG)                                                 │
    │        │                                                                          │
    │        └──► Phase 5b (Game-Dev CAG)  ← independent of 5a                       │
    │                                                                                   │
    ├──► Phase 2a (IntelliSense Baseline)                                               │
    │        │                                                                          │
    │        └──► Phase 2b (IntelliSense Enhanced)                                     │
    │                                                                                   │
    └──► Phase 3a-3f (Editors Batch 1, 16 editors)                                    │
             │                                                                          │
             └──► Phase 3g (Editors Batch 2, 11 more editors)                         │
                                                                                        │
All ──────────────────────────────────────────────────────────────► Phase 6 ─► Phase 7
```

**Parallelizable pairs**: (2a, 3a-3f), (2b, 3g), (5a, 5b)

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| API data incomplete (48% coverage) | High | Medium | Ship with what's documented; IntelliSense degrades gracefully |
| Debug bridge engine-side not ready | Medium | High | Make debug bridge commands fail gracefully; document engine requirements |
| Webview editor HTML size | Low | Low | Shared CSS reduces duplication; esbuild tree-shakes |
| LuaCATS compatibility with sumneko.lua | Medium | Medium | Test with specific sumneko.lua versions; dual-provider strategy |
| 27 editors is a large surface | High | Medium | Shared components reduce per-editor effort; ship batch 1 before batch 2 |
| VS Code API breaking changes | Low | High | Pin `@types/vscode` version; follow deprecation warnings |
| Game-dev CAG skill depth varies | Medium | Low | Quality gate: each skill must have ≥1 working example before merge |
| Type inference false positives | Medium | Low | Opt-in per setting; degrade gracefully to no-completion rather than wrong-completion |

---

## Agent Assignment Summary

| Agent | Phases | Primary Work |
|---|---|---|
| Developer | 0, 1, 2a, 2b, 3, 4, 5a, 5b | All TypeScript implementation |
| Tester | 0, 1, 4, 6 | Extension tests, validation |
| CAG-Architect | 5a, 5b | Engine CAG + game-dev CAG layer |
| Reviewer | 6 | Code review, compliance check |
| Optimizer | 6 | Performance audit |
| Doc-Writer | 6 | README, CHANGELOG, screenshots |
| Manager | 7 | Coordinate publish, verify marketplace |
| Architect | — | Consulted for module boundary questions |

---

## Design Document Index

| Document | Contents | Status |
|---|---|---|
| `00-architecture.md` | Extension architecture, module map, security | ✅ Complete |
| `01-sidebar-design.md` | 3 sidebar views, 76+ commands, keybindings | ✅ Complete |
| `02-intellisense-design.md` | 11 baseline providers, API pipeline | ✅ Complete |
| `03-editors-design.md` | 16 editor ASCII layouts (Batch 1) | ✅ Complete |
| `04-commands-features.md` | Full command reference, MCP tools, Debug Bridge | ✅ Complete |
| `05-implementation-plan.md` | This document — phased plan, dep graph | ✅ Updated |
| `06-package-json-spec.md` | Full package.json manifest spec | ✅ Complete |
| `08-intellisense-enhanced.md` | LuaJIT hints, type inference, patterns (Phase 2b) | ✅ Complete |
| `09-new-editors.md` | 11 editor ASCII layouts (Batch 2, editors 17–27) | ✅ Complete |
| `10-game-dev-cag.md` | Full game-dev CAG: agents, skills, prompts, templates | ✅ Complete |
