# Sidebar & UX Analysis

## Current State

### Sidebar Design (package2.json)

The v2 manifest defines a "Luna Toolkit" sidebar container with 4 views:

| View ID | Name | Provider |
|---|---|---|
| lurek.projectTools | Project | ProjectToolsProvider |
| lurek.devTools | Dev Tools | DevToolsProvider |
| lurek.assetExplorer | Assets | AssetExplorerProvider |
| lurek.aiCopilot | AI & Copilot | AiToolsProvider |

**Docs** (01-sidebar-design.md) planned 3 views: PROJECT, DEV TOOLS, AI & COPILOT.
**Implementation** adds a 4th: **Assets** (asset explorer tree view).

### Welcome View
```
No Lurek2D project detected.
[Create New Project]
[Open Folder with main.lua]
```

---

## Improvement Ideas

### 1. Project View Enhancements

**Current**: Create, Package, Libraries.

**Additions**:
- **Recent Projects** — list of recently opened Lurek2D games
- **Project Health** — quick status indicators:
  - ✅ conf.lua exists
  - ✅ main.lua exists
  - ⚠️ No tests detected
  - ❌ Missing assets referenced in code
- **Quick Actions** — contextual buttons based on project state
- **Project Size** — file count, total Lua LOC, asset count

### 2. Dev Tools View Enhancements

**Current**: Run, Testing, Editors, Tools, Reference, Debug Bridge.

**Additions**:
- **Run Section**: Show game status (Running/Stopped/Crashed) with colored indicator
- **Testing Section**: Show pass/fail counts from last test run
- **Performance Section**: Mini FPS gauge, last measured frame time
- **Debug Section**: Connection status with port number

### 3. Asset Explorer Improvements

**Current**: Tree view listing game assets.

**Improvements**:
- **Thumbnail previews** for images/sprites
- **Audio waveform** preview for sound files
- **Search/filter** within asset tree
- **Drag-and-drop** assets into editor to insert `lurek.gfx.newImage("path")`
- **Missing asset highlighting** — red marker on referenced-but-missing assets
- **Asset usage count** — show how many Lua files reference each asset
- **Asset size** — file size and dimensions for images
- **Bulk operations** — batch rename, move, organize

### 4. AI & Copilot View Enhancements

**Current**: MCP Tools, CAG Layer, Game Jam.

**Improvements**:
- **Active Agent** indicator — show which CAG agent mode is active
- **Suggestion Feed** — AI-generated improvement suggestions for current code
- **Template Gallery** — visual grid of available project templates
- **Agent Chat History** — link to recent agent conversations

### 5. Status Bar Improvements

**Current**: "$(rocket) Lurek2D" status bar item, running/stopped states.

**Additional status bar items**:
- **FPS/frame time** when game is running (from debug bridge)
- **Lua VM memory** usage indicator
- **Active scene** name from running game
- **Entity count** from running game
- **Test status** — last test result (✅ 47/47, ❌ 2 failed)
- **Hot-reload indicator** — flash when a file is hot-reloaded
- **Build status** — show if last build passed/failed

### 6. Command Palette Organization

**Problem**: 90+ commands all prefixed with "Luna:" may be overwhelming.

**Improvements**:
- Group commands into categories with separator labels
- Most-used commands appear first (show frequency-based ordering)
- Recently used Luna commands section
- Add keyboard shortcut hints in command palette descriptions

### 7. Context Menu Integration

**Current**: 3 context menu items (Run Game, Open Wiki, Generate Tests).

**Additional context menu items**:
- **"Open in Luna Editor"** — for .tilemap.lua, .particle.lua, .scene.lua files
- **"Run This File"** — for standalone Lua scripts
- **"Generate Docs"** — for undocumented Lua functions
- **"Find References in Game"** — for lurek.* API calls
- **"Add Watch"** — for variable names under cursor (when debugging)
- **"Preview Asset"** — for image/audio file paths under cursor

### 8. Onboarding Flow

**New feature**: First-time user experience.

**Flow**:
1. Detect first activation (no `conf.lua` in workspace)
2. Show welcome walkthrough (VS Code walkthrough API)
3. Steps: Install Lurek2D → Create Project → Write First Script → Run Game → Open Editor
4. Interactive code snippets in walkthrough
5. Link to tutorial docs

### 9. Keybinding Improvements

**Current 4 keybindings**: Alt+L (run), Shift+Alt+L (stop), F2 (wiki), Ctrl+Shift+T (test all).

**Additional keybindings**:
- F5 — Debug launch (via DAP)
- Ctrl+Shift+P, then "luna" — already works via command palette
- Ctrl+Shift+E → focus asset explorer
- Ctrl+Shift+D → open debug bridge
- F6 — hot-reload current file
- F8 — run current Lua test file

### 10. Theme Integration

**shared.ts** defines theme variables mapping to VS Code tokens. This is good.

**Improvements**:
- Test editors with multiple VS Code themes (dark, light, high contrast)
- Add a "Luna" color theme that matches the engine's branding
- Support custom accent colors per project (configurable in conf.lua or settings)
