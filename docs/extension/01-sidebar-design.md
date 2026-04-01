# Luna Toolkit — Sidebar Tree View Design

> Defines the three sidebar tree view sections and all nodes within them.

---

## Activity Bar Entry

```
Icon: 🌙 (custom SVG moon icon)
Title: "Luna Toolkit"
Container ID: "luna-sidebar"
```

---

## View 1: PROJECT

**View ID**: `luna.projectTools`

```
▼ PROJECT
  ├─ 📁 Create
  │   ├─ ⚡ New Project from Template
  │   └─ 📄 New File from Template
  │
  ├─ 📦 Package
  │   ├─ 📦 Package Game (.zip)
  │   ├─ 🪟 Package for Windows (.exe)
  │   └─ 🐧 Package for Linux
  │
  └─ 📚 Libraries
      ├─ 📥 Install Library
      └─ 📋 List Installed
```

### Commands

| Node | Command ID | Action |
|---|---|---|
| New Project from Template | `luna.scaffold.project` | Quick-pick template → scaffold directory |
| New File from Template | `luna.scaffold.file` | Quick-pick file type → create file |
| Package Game (.zip) | `luna.package.zip` | Create distributable archive |
| Package for Windows | `luna.package.windows` | Fuse with luna.exe for standalone |
| Package for Linux | `luna.package.linux` | Create Linux distribution |
| Install Library | `luna.library.install` | Pick from curated library list |
| List Installed | `luna.library.list` | Show installed libs in `lib/` |

### Project Templates

| Template | Description | Files Created |
|---|---|---|
| Minimal | Bare `main.lua` with load/update/draw | `main.lua` |
| Game Loop | Full callback structure | `main.lua`, `conf.lua` |
| Physics | Physics world with bodies | `main.lua`, `conf.lua` |
| Platformer | Tile-based platformer starter | `main.lua`, `conf.lua`, `assets/` |
| Top-Down | Top-down RPG starter | `main.lua`, `conf.lua`, `assets/` |
| ECS | Entity-component pattern | `main.lua`, `conf.lua`, `entities/` |

---

## View 2: DEV TOOLS

**View ID**: `luna.devTools`

```
▼ DEV TOOLS
  ├─ 🚀 Run
  │   ├─ ▶️ Run Game                          (Alt+L)
  │   ├─ ⏹ Stop Game                         (Shift+Alt+L)
  │   ├─ ▶️ Run with Arguments
  │   └─ ▶️ Run Example...                    (pick from list)
  │
  ├─ 🧪 Testing
  │   ├─ ▶️ Run All Tests                     (cargo test)
  │   ├─ ▶️ Run Rust Tests
  │   │   ├─ 📐 Math Tests
  │   │   ├─ ⚛️ Physics Tests
  │   │   ├─ 🎨 Graphics Tests
  │   │   ├─ 🔊 Audio Tests
  │   │   ├─ 🎮 Input Tests
  │   │   ├─ ⏱ Timer Tests
  │   │   ├─ 📁 Filesystem Tests
  │   │   ├─ 🗺 Tilemap Tests
  │   │   ├─ 🎬 Scene Tests
  │   │   ├─ 🤖 AI Tests
  │   │   ├─ 🔢 Compute Tests
  │   │   ├─ 📊 Data Tests
  │   │   ├─ 📈 DataFrame Tests
  │   │   ├─ 🏗 Entity Tests
  │   │   ├─ 📡 Event Tests
  │   │   ├─ 🕸 Graph Tests
  │   │   ├─ 🖼 Image Tests
  │   │   ├─ 🔧 Modding Tests
  │   │   ├─ ✨ Particle Tests
  │   │   ├─ 💾 Save Game Tests
  │   │   ├─ 🔊 Sound Tests
  │   │   └─ ⚙️ System Tests
  │   ├─ ▶️ Run Lua Tests
  │   │   ├─ 📜 All Lua Tests
  │   │   ├─ 📦 Lua API Tests
  │   │   ├─ 🔬 Lua Stress Tests
  │   │   └─ 📋 Lua Golden Tests
  │   ├─ 📄 Generate Tests for File
  │   └─ 📊 Open Test Runner
  │
  ├─ ✏️ Editors
  │   ├─ 🗺 Tile Map Editor
  │   ├─ 🎬 Scene Flow Editor
  │   ├─ 🏗 Entity Designer
  │   ├─ 🎨 Pixel Art Editor
  │   ├─ 💬 Dialog Editor
  │   ├─ ✨ Particle Designer
  │   ├─ 🗄 Database Browser
  │   ├─ 🌍 Procedural Map Generator
  │   ├─ 🏆 Quest / Tech Tree Editor
  │   ├─ 🖼 GUI Widget Editor
  │   ├─ 🤖 AI Behavior Tree
  │   ├─ 🕸 Graph / Node Editor
  │   ├─ 📜 Tilemap Script Editor
  │   └─ 🧊 Voxel Editor
  │
  ├─ 🔧 Tools
  │   ├─ 📖 API Reference (Local)
  │   ├─ 📊 Test Runner (Visual)
  │   ├─ 🔗 Dependency Graph
  │   └─ 📋 Dependency List
  │
  ├─ 📚 Reference
  │   ├─ 🔍 Browse API (Quick Pick)
  │   ├─ 📖 Open Lua API Docs
  │   └─ 🌐 Open Wiki
  │
  └─ 🐛 Debug Bridge
      ├─ 🔌 Connect to Game
      ├─ 🔌 Disconnect
      ├─ ▶️ Run + Auto-Connect
      ├─ 📊 Performance Metrics
      ├─ 🖨 Print History
      ├─ 💻 Evaluate Lua
      ├─ 📸 Screenshot
      ├─ 📚 Call Stack
      └─ ℹ️ Status Overview
```

### Test Commands (Expanded)

| Command ID | Action | Terminal Command |
|---|---|---|
| `luna.test.all` | Run all tests | `cargo test` |
| `luna.test.rust.math` | Math module | `cargo test math_tests` |
| `luna.test.rust.physics` | Physics module | `cargo test physics_tests` |
| `luna.test.rust.graphics` | Graphics module | `cargo test graphics_tests` |
| `luna.test.rust.audio` | Audio module | `cargo test audio_tests` |
| `luna.test.rust.input` | Input module | `cargo test input_tests` |
| `luna.test.rust.timer` | Timer module | `cargo test timer_tests` |
| `luna.test.rust.filesystem` | Filesystem module | `cargo test filesystem_tests` |
| `luna.test.rust.tilemap` | Tilemap module | `cargo test tilemap_tests` |
| `luna.test.rust.scene` | Scene module | `cargo test scene_tests` |
| `luna.test.rust.ai` | AI module | `cargo test ai_tests` |
| `luna.test.rust.compute` | Compute module | `cargo test compute_tests` |
| `luna.test.rust.data` | Data module | `cargo test data_tests` |
| `luna.test.rust.dataframe` | DataFrame module | `cargo test dataframe_tests` |
| `luna.test.rust.entity` | Entity module | `cargo test entity_tests` |
| `luna.test.rust.event` | Event module | `cargo test event_tests` |
| `luna.test.rust.graph` | Graph module | `cargo test graph_tests` |
| `luna.test.rust.image` | Image module | `cargo test image_tests` |
| `luna.test.rust.modding` | Modding module | `cargo test modding_tests` |
| `luna.test.rust.particle` | Particle module | `cargo test particle_tests` |
| `luna.test.rust.savegame` | SaveGame module | `cargo test savegame_tests` |
| `luna.test.rust.sound` | Sound module | `cargo test sound_tests` |
| `luna.test.rust.system` | System module | `cargo test system_tests` |
| `luna.test.lua.all` | All Lua tests | `cargo test --test lua_tests` |
| `luna.test.lua.api` | Lua API tests | `cargo test --test lua_tests lua_test_` |
| `luna.test.lua.stress` | Lua stress tests | `cargo test --test lua_tests lua_stress_` |
| `luna.test.lua.golden` | Golden tests | `cargo test --test golden_tests` |

---

## View 3: AI & COPILOT

**View ID**: `luna.aiCopilot`

```
▼ AI & COPILOT
  ├─ 🔧 MCP Tools
  │   ├─ 📡 Install Game Dev MCP Server
  │   └─ ℹ️ MCP Server Status
  │
  ├─ 🤖 CAG Layer
  │   ├─ 📦 Install AI Config
  │   ├─ 🤖 Select Agent...
  │   ├─ 🎯 Select Skill...
  │   ├─ 📝 Select Prompt...
  │   └─ 🔄 Update CAG Files
  │
  ├─ 🎮 Game Jam
  │   ├─ ⏱ Game Jam Timer
  │   ├─ ⚡ Quick Build
  │   └─ ✅ Submission Checklist
  │
  └─ 📊 Analytics
      ├─ 📈 API Coverage Report
      └─ 🔍 Undocumented Functions
```

### CAG Commands

| Command ID | Action |
|---|---|
| `luna.cag.install` | Copy bundled `.github/` agents/skills/instructions to workspace |
| `luna.cag.selectAgent` | Quick-pick from 18 available agents → open with `@agent` |
| `luna.cag.selectSkill` | Quick-pick from 33 skills → show skill description |
| `luna.cag.selectPrompt` | Quick-pick from available prompts → insert into chat |
| `luna.cag.update` | Re-copy CAG files (update to latest bundled version) |

---

## TreeDataProvider Implementation Pattern

```typescript
// providers/sidebar.ts

type SidebarNode = SectionItem | ToolItem;

class ToolItem extends vscode.TreeItem {
  constructor(
    label: string,
    commandId: string,
    icon: string,           // ThemeIcon name
    contextValue?: string
  ) {
    super(label, vscode.TreeItemCollapsibleState.None);
    this.command = { command: commandId, title: label };
    this.iconPath = new vscode.ThemeIcon(icon);
    this.contextValue = contextValue;
  }
}

class SectionItem extends vscode.TreeItem {
  children: SidebarNode[];

  constructor(label: string, icon: string, children: SidebarNode[]) {
    super(label, vscode.TreeItemCollapsibleState.Expanded);
    this.iconPath = new vscode.ThemeIcon(icon);
    this.children = children;
  }
}

// Three provider classes:
export class ProjectToolsProvider implements vscode.TreeDataProvider<SidebarNode> { ... }
export class DevToolsProvider implements vscode.TreeDataProvider<SidebarNode> { ... }
export class AiToolsProvider implements vscode.TreeDataProvider<SidebarNode> { ... }
```

---

## Keybindings

| Key | Command | When |
|---|---|---|
| `Alt+L` | `luna.runGame` | `editorTextFocus && resourceLangId == lua` |
| `Shift+Alt+L` | `luna.stopGame` | `luna.gameRunning` |
| `F2` | `luna.openWiki` | `editorTextFocus && resourceLangId == lua` |
| `Ctrl+Shift+T` | `luna.test.all` | `workspaceFolderCount > 0` |
