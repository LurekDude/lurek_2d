# Visual Editors Analysis

## Current State

The implementation contains **29 editor files** in `vscode-extension/src/editors/` — exceeding the 27 planned in the design docs (16 original + 11 batch-2). All sampled editors are **fully implemented webviews**, not stubs.

### Editor Inventory

| Editor | Source Doc | Impl File | Implementation Depth |
|---|---|---|---|
| **Batch 1 (03-editors-design.md)** | | | |
| Tile Map | ✅ 03-editors | tileMapEditor.ts | Full: 3-column layout, layer system, 5 tools, export |
| Scene Flow | ✅ 03-editors | sceneFlowEditor.ts | Full: node graph, transitions, properties, export |
| Entity Designer | ✅ 03-editors | entityEditor.ts | Full: component-based design |
| Pixel Art | ✅ 03-editors | pixelArtEditor.ts | Full: PICO-8 palette, layers, frames, 5 tools |
| Dialog | ✅ 03-editors | dialogEditor.ts | Full: NPC/Choice/Condition/Action nodes |
| Particle | ✅ 03-editors | particleEditor.ts | Full: 8 presets, live preview, parameter sliders |
| Database Browser | ✅ 03-editors | databaseEditor.ts | Full webview |
| Procedural Map | ✅ 03-editors | procMapEditor.ts | Full webview |
| Quest / Tech Tree | ✅ 03-editors | questTreeEditor.ts | Full webview |
| GUI Widget | ✅ 03-editors | guiWidgetEditor.ts | Full webview |
| AI Behavior Tree | ✅ 03-editors | aiBehaviorEditor.ts | Full: canvas tree, node palette, simulation |
| Graph / Node | ✅ 03-editors | graphEditor.ts | Full webview |
| Tilemap Script | ✅ 03-editors | tilemapScriptEditor.ts | Full webview |
| Voxel | ✅ 03-editors | voxelEditor.ts | Full webview |
| Test Runner | ✅ 03-editors | testRunnerEditor.ts | Full webview |
| API Reference | ✅ 03-editors | apiReferenceEditor.ts | Full webview |
| **Batch 2 (09-new-editors.md)** | | | |
| Sprite Animation | ✅ 09-new-editors | spriteAnimEditor.ts | Full webview |
| Tileset | ✅ 09-new-editors | tilesetEditor.ts | Full webview |
| Audio Mixer | ✅ 09-new-editors | audioMixerEditor.ts | Full webview |
| Color Palette | ✅ 09-new-editors | colorPaletteEditor.ts | Full webview |
| Input Mapper | ✅ 09-new-editors | inputMapperEditor.ts | Full webview |
| Timeline | ✅ 09-new-editors | timelineEditor.ts | Full webview |
| Shader Preview | ✅ 09-new-editors | shaderPreviewEditor.ts | Full webview |
| Font Preview | ✅ 09-new-editors | fontPreviewEditor.ts | Full webview |
| Localization | ✅ 09-new-editors | localizationEditor.ts | Full webview |
| Physics Materials | ✅ 09-new-editors | physicsMaterialsEditor.ts | Full webview |
| World Map | ✅ 09-new-editors | worldMapEditor.ts | Full: rooms, connections, minimap, zoom/pan |
| **Extras (not in docs)** | | | |
| PostFX & Overlay | ❌ Not documented | postfxOverlayEditor.ts | Full webview |
| Sound DSP | ❌ Not documented | soundDspEditor.ts | Full webview |

### Shared Infrastructure

`shared.ts` (~200 lines) provides:
- `getNonce()` for CSP headers
- Complete CSS theme variables (maps to VS Code theme tokens)
- Component styles (buttons, inputs, panels, lists, status bars)
- `wrapHtml()` factory for consistent webview creation

---

## Improvement Ideas

### 1. Editor State Persistence

**Problem**: Webview panels lose state when hidden. If a user opens the Particle Editor, switches tabs, and comes back, the editor reloads from scratch.

**Improvement**:
- Use `retainContextWhenHidden: true` in panel options (some editors already do this)
- Persist editor state to `workspaceState` or a `.luna/` folder
- Restore last-used settings when reopening an editor
- Save undo history across panel lifecycle

### 2. Editor ↔ Engine Live Preview

**Problem**: Editors generate Lua code but can't preview results in the running game.

**Improvement**:
- When Debug Bridge is connected, editors push updates to the running game
- Particle Editor: live-preview particle effect in-game
- Tile Map Editor: hot-reload tilemap changes
- Color Palette Editor: apply palette swap in real-time
- Add "Preview in Engine" button to each editor toolbar

### 3. Undo/Redo System

**Problem**: Webview editors likely lack robust undo/redo.

**Improvement**:
- Add a shared undo/redo stack to `shared.ts`
- Each editor action pushes an undo entry
- Ctrl+Z / Ctrl+Shift+Z keybindings inside webview
- Undo history shown in a panel sidebar

### 4. File Sync (Two-Way)

**Problem**: Editors export Lua code, but changes to the Lua file aren't reflected back in the editor.

**Improvement**:
- Parse existing Lua/TOML files to populate editor state
- Watch the source file for external changes
- Merge external edits into the editor view
- Conflict resolution when both editor and text were modified

### 5. Missing Editors from Spec

Some editors from the `visual_scripting.md` spec are not implemented:

- **Visual Script Editor** — The biggest missing editor. Block-based DAG with typed ports, graph compiler. This is a standalone major feature that could be a separate extension or a dedicated phase.

### 6. Editor Discoverability

**Problem**: 29 editors are registered as commands but may be hard to find.

**Improvements**:
- Add editor icons to the sidebar Dev Tools tree
- Group editors by category in the command palette (Game Design, Assets, Audio, Debug)
- Add "Open in Editor" context menu items for relevant file types (.tilemap.lua, .particle.lua, etc.)
- Show editor thumbnails in the sidebar

### 7. Cross-Editor References

**Improvement ideas for editor interconnection**:
- Tile Map Editor references tiles from Tileset Editor
- Scene Flow Editor references entities from Entity Designer
- Dialog Editor references quest nodes from Quest Tree Editor
- World Map Editor links to Scene Flow scenes
- Particle Editor presets used by PostFX & Overlay Editor

### 8. Export Format Standardization

**Current**: Each editor generates Lua code independently.

**Improvement**:
- Define a standard export format for each editor type
- Generated Lua should use consistent patterns (local table, return at end)
- Add TOML export as alternative (per B-05 constraint)
- Add JSON export for external tool interop
- All exports should include a header comment: `-- Generated by Luna Toolkit [EditorName] v[version]`

### 9. Mobile/Responsive Layouts

**Problem**: Webview editors may not work well at narrow widths.

**Improvement**:
- Add responsive breakpoints to shared.ts CSS
- Collapse side panels at narrow width
- Add panel toggle buttons
- Support floating panels (detach properties panel)

### 10. Editor Templates/Presets

**Current**: Particle Editor has 8 presets. Other editors likely have fewer.

**Improvement**:
- Add presets/templates to every editor:
  - Tile Map: dungeon, overworld, platformer, puzzle
  - Entity: player, enemy, NPC, projectile, pickup
  - Dialog: tutorial, shop, quest-giver, branching-story
  - AI Behavior: patrol, guard, chase-flee, search
  - Scene Flow: linear, hub-and-spoke, branching
- Allow users to save custom presets
- Share presets as `.luna-preset` files

### 11. Performance: Lazy Editor Loading

**Consideration**: 29 editor command registrations at activation time may slow startup.

**Improvement**:
- Lazy-load editor modules (dynamic import on first use)
- Only register the command, defer module loading until invoked
- Pre-cache commonly used editors (Tile Map, Particle, Entity) in background
