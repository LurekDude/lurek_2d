# Luna Toolkit — Commands & Features Reference

> Complete list of all commands, keybindings, and features.

---

## 1. Full Command Table

### Run & Debug

| Command ID | Title | Keybinding | Description |
|---|---|---|---|
| `luna.runGame` | Luna: Run Game | `Alt+L` | Run the game (auto-detect binary) |
| `luna.stopGame` | Luna: Stop Game | `Shift+Alt+L` | Stop running game process |
| `luna.runWithArgs` | Luna: Run with Arguments | — | Run with custom CLI flags |
| `luna.runExample` | Luna: Run Example | — | Pick and run an example |

### Testing

| Command ID | Title | Keybinding | Description |
|---|---|---|---|
| `luna.test.all` | Luna: Run All Tests | `Ctrl+Shift+T` | `cargo test` |
| `luna.test.rust.math` | Luna: Test Math | — | `cargo test math_tests` |
| `luna.test.rust.physics` | Luna: Test Physics | — | `cargo test physics_tests` |
| `luna.test.rust.graphics` | Luna: Test Graphics | — | `cargo test graphics_tests` |
| `luna.test.rust.audio` | Luna: Test Audio | — | `cargo test audio_tests` |
| `luna.test.rust.input` | Luna: Test Input | — | `cargo test input_tests` |
| `luna.test.rust.timer` | Luna: Test Timer | — | `cargo test timer_tests` |
| `luna.test.rust.filesystem` | Luna: Test Filesystem | — | `cargo test filesystem_tests` |
| `luna.test.rust.tilemap` | Luna: Test Tilemap | — | `cargo test tilemap_tests` |
| `luna.test.rust.scene` | Luna: Test Scene | — | `cargo test scene_tests` |
| `luna.test.rust.ai` | Luna: Test AI | — | `cargo test ai_tests` |
| `luna.test.rust.compute` | Luna: Test Compute | — | `cargo test compute_tests` |
| `luna.test.rust.data` | Luna: Test Data | — | `cargo test data_tests` |
| `luna.test.rust.dataframe` | Luna: Test DataFrame | — | `cargo test dataframe_tests` |
| `luna.test.rust.entity` | Luna: Test Entity | — | `cargo test entity_tests` |
| `luna.test.rust.event` | Luna: Test Event | — | `cargo test event_tests` |
| `luna.test.rust.graph` | Luna: Test Graph | — | `cargo test graph_tests` |
| `luna.test.rust.image` | Luna: Test Image | — | `cargo test image_tests` |
| `luna.test.rust.modding` | Luna: Test Modding | — | `cargo test modding_tests` |
| `luna.test.rust.particle` | Luna: Test Particle | — | `cargo test particle_tests` |
| `luna.test.rust.savegame` | Luna: Test SaveGame | — | `cargo test savegame_tests` |
| `luna.test.rust.sound` | Luna: Test Sound | — | `cargo test sound_tests` |
| `luna.test.rust.system` | Luna: Test System | — | `cargo test system_tests` |
| `luna.test.lua.all` | Luna: Run All Lua Tests | — | `cargo test --test lua_tests` |
| `luna.test.lua.golden` | Luna: Run Golden Tests | — | `cargo test --test golden_tests` |
| `luna.test.generateForFile` | Luna: Generate Tests for File | — | Generate test boilerplate |

### Scaffolding

| Command ID | Title | Description |
|---|---|---|
| `luna.scaffold.project` | Luna: New Project | Scaffold from template |
| `luna.scaffold.file` | Luna: New File | Add file from template |

### Packaging

| Command ID | Title | Description |
|---|---|---|
| `luna.package.zip` | Luna: Package Game (.zip) | Create distributable archive |
| `luna.package.windows` | Luna: Package for Windows | Fused .exe distribution |
| `luna.package.linux` | Luna: Package for Linux | Linux binary distribution |

### Editors

| Command ID | Title | Description |
|---|---|---|
| `luna.editor.tileMap` | Luna: Tile Map Editor | Open tile map visual editor |
| `luna.editor.sceneFlow` | Luna: Scene Flow Editor | Open scene state machine editor |
| `luna.editor.entity` | Luna: Entity Designer | Open entity component editor |
| `luna.editor.pixelArt` | Luna: Pixel Art Editor | Open pixel art drawing tool |
| `luna.editor.dialog` | Luna: Dialog Editor | Open dialog tree editor |
| `luna.editor.particle` | Luna: Particle Designer | Open particle effect designer |
| `luna.editor.database` | Luna: Database Browser | Open data table browser |
| `luna.editor.procMap` | Luna: Procedural Map Generator | Open procedural map tool |
| `luna.editor.questTree` | Luna: Quest / Tech Tree Editor | Open quest chain editor |
| `luna.editor.guiWidget` | Luna: GUI Widget Editor | Open GUI layout builder |
| `luna.editor.aiBehavior` | Luna: AI Behavior Tree | Open behavior tree editor |
| `luna.editor.graph` | Luna: Graph / Node Editor | Open generic node graph |
| `luna.editor.tilemapScript` | Luna: Tilemap Script Editor | Open tilemap scripting |
| `luna.editor.voxel` | Luna: Voxel Editor | Open voxel model editor |
| `luna.editor.testRunner` | Luna: Test Runner | Open visual test runner |
| `luna.editor.apiReference` | Luna: API Reference | Open API documentation browser |

### Reference & Docs

| Command ID | Title | Keybinding | Description |
|---|---|---|---|
| `luna.browseApi` | Luna: Browse API | — | Quick-pick API search |
| `luna.openApiDocs` | Luna: Open Lua API Docs | — | Open generated markdown |
| `luna.openWiki` | Luna: Open Wiki | `F2` | Open wiki for symbol at cursor |

### Debug Bridge

| Command ID | Title | Description |
|---|---|---|
| `luna.debug.connect` | Luna: Debug Connect | Connect to running game |
| `luna.debug.disconnect` | Luna: Debug Disconnect | Disconnect from game |
| `luna.debug.runAndConnect` | Luna: Debug Run + Connect | Launch with auto-connect |
| `luna.debug.performance` | Luna: Debug Performance | Show FPS, memory stats |
| `luna.debug.printHistory` | Luna: Debug Print History | View captured output |
| `luna.debug.evaluate` | Luna: Debug Evaluate Lua | Execute expression in game |
| `luna.debug.screenshot` | Luna: Debug Screenshot | Capture game screenshot |
| `luna.debug.callStack` | Luna: Debug Call Stack | View Lua call stack |
| `luna.debug.status` | Luna: Debug Status | Full game status overview |

### Analysis

| Command ID | Title | Description |
|---|---|---|
| `luna.depGraph` | Luna: Dependency Graph | Interactive require() graph |
| `luna.depList` | Luna: Dependency List | Text dependency tree |
| `luna.apiCoverage` | Luna: API Coverage | Report documented vs undocumented |

### AI & CAG

| Command ID | Title | Description |
|---|---|---|
| `luna.cag.install` | Luna: Install AI Config | Install .github/ CAG files |
| `luna.cag.selectAgent` | Luna: Select Agent | Quick-pick AI agent |
| `luna.cag.selectSkill` | Luna: Select Skill | Quick-pick AI skill |
| `luna.cag.selectPrompt` | Luna: Select Prompt | Quick-pick task prompt |
| `luna.cag.update` | Luna: Update CAG Files | Update to latest bundled |
| `luna.mcp.install` | Luna: Install MCP Server | Install MCP server config |
| `luna.mcp.status` | Luna: MCP Status | Show MCP server status |

### Game Jam

| Command ID | Title | Description |
|---|---|---|
| `luna.jam.timer` | Luna: Game Jam Timer | Countdown timer in status bar |
| `luna.jam.quickBuild` | Luna: Quick Build | Fast packaging for submission |
| `luna.jam.checklist` | Luna: Submission Checklist | Pre-flight checks |

### Libraries

| Command ID | Title | Description |
|---|---|---|
| `luna.library.install` | Luna: Install Library | Download game library |
| `luna.library.list` | Luna: List Libraries | Show installed libraries |

---

## 2. Status Bar Items

```
┌─────────────────────────────────────────────────────────────────────┐
│ 🌙 Luna2D │ ▶ Running │ 🐛 Debug: Connected │ ⏱ 23:45:00 │ FPS:60│
└─────────────────────────────────────────────────────────────────────┘
```

| Item | Alignment | Shown when | Click action |
|---|---|---|---|
| 🌙 Luna2D | Left | Always (extension active) | Open command palette filtered |
| ▶ Running / ⏹ Stopped | Left | Game launched | Toggle run/stop |
| 🐛 Connected / Disconnected | Left | Debug bridge used | Toggle connect |
| ⏱ Game Jam Timer | Right | Timer started | Open timer settings |
| FPS: 60 | Right | Debug bridge connected | Open performance panel |

---

## 3. Context Menu Contributions

### Lua Editor Context Menu

| Menu item | Condition | Command |
|---|---|---|
| Luna: Run Game | `resourceLangId == lua` | `luna.runGame` |
| Luna: Open API Docs | `resourceLangId == lua` | `luna.openApiDocs` |
| Luna: Generate Tests | `resourceLangId == lua` | `luna.test.generateForFile` |

### Explorer Context Menu

| Menu item | Condition | Command |
|---|---|---|
| Luna: Run as Game | Folder with `main.lua` | `luna.runGame` |
| Luna: Open in Editor | `.tilemap.lua`, `.scene.lua` | Open matching editor |

---

## 4. MCP Tools (for Copilot Agents)

| Tool ID | Description | Parameters |
|---|---|---|
| `luna2d.runExample` | Build and run an example | `name: string` |
| `luna2d.getApiDoc` | Search API documentation | `query: string` |
| `luna2d.listExamples` | List available examples | — |
| `luna2d.runLuaTest` | Run a Lua test file | `file: string` |
| `luna2d.checkBuild` | Run `cargo check` | — |
| `luna2d.getLogs` | Get engine log tail | `lines?: number` |
| `luna2d.runRustTest` | Run a Rust test module | `module: string` |
| `luna2d.getApiCoverage` | Get API documentation coverage | — |
| `luna2d.searchCode` | Search codebase for pattern | `query: string, ext?: string` |
| `luna2d.listModules` | List engine modules | — |

---

## 5. Debug Bridge Protocol

### Connection Flow

```
1. User clicks "Run + Auto-Connect"
2. Extension launches: luna --debug-bridge --port 19740 path/to/game
3. Engine opens TCP listener on port 19740
4. Extension connects via TCP socket
5. JSON-RPC messages flow bidirectionally
6. On game exit, socket closes automatically
```

### Debug Bridge Commands (JSON-RPC)

| Method | Params | Returns | Description |
|---|---|---|---|
| `evaluate` | `{ expr: string }` | `{ result: string }` | Execute Lua expression |
| `getPerformance` | — | `{ fps, frameTime, memory, drawCalls, textureMemory }` | Performance metrics |
| `getPrintHistory` | `{ limit?: number }` | `{ prints: [{text, file, line, time}] }` | Captured print output |
| `getCallStack` | — | `{ frames: [{func, file, line}] }` | Current call stack |
| `screenshot` | `{ format?: "png" }` | `{ data: base64 }` | Capture screenshot |
| `getStatus` | — | `{ version, modules, memory, uptime }` | Full status |
| `setWatchpoint` | `{ expr: string }` | `{ id: number }` | Watch expression value |
| `removeWatchpoint` | `{ id: number }` | — | Remove watch |
| `getGlobals` | `{ pattern?: string }` | `{ globals: [{name, type, value}] }` | List Lua globals |
