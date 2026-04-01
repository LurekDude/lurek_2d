# Luna Toolkit — Webview Editor Specifications

> Design specifications for each of the 16 visual editors.
> All editors share the same base architecture and CSS theme.

---

## Shared Infrastructure

### CSS Theme (`editors/sharedCss.ts`)

```css
:root {
  --bg:         #1e1e1e;    /* Editor background */
  --surface:    #252526;    /* Panel/sidebar surfaces */
  --surface-2:  #2d2d2d;    /* Elevated surfaces */
  --border:     #3c3c3c;    /* Borders and dividers */
  --text:       #cccccc;    /* Primary text */
  --text-dim:   #858585;    /* Secondary text */
  --accent:     #007acc;    /* Primary accent (VS Code blue) */
  --accent-2:   #4ec9b0;    /* Secondary accent (teal) */
  --success:    #4caf50;    /* Success / positive */
  --warning:    #ff9800;    /* Warning / caution */
  --danger:     #f44336;    /* Error / destructive */
  --selection:  #264f78;    /* Selected items */
}
```

### Shared Components

- **Canvas HUD**: Zoom slider (−/+), reset button, zoom percentage display
- **Canvas interaction**: Pan (middle-click drag), zoom (scroll wheel), grid snap
- **File I/O buttons**: Export Lua, Export TOML, Save, Load
- **Property panel**: Right-side inspector with labeled fields

### Editor Layout Pattern

```
┌─────────────────────────────────────────────────────────────┐
│ TOOLBAR:  [Buttons] [Buttons]                [Export Lua]   │
├──────────┬─────────────────────────────┬────────────────────┤
│          │                             │                    │
│  LEFT    │        CANVAS               │   PROPERTIES       │
│  PANEL   │        (main workspace)     │   (inspector)      │
│          │                             │                    │
│  ~180px  │        flex: 1              │   ~220px           │
│          │                             │                    │
│          │                             │                    │
│          │                             │                    │
├──────────┴─────────────────────────────┴────────────────────┤
│ STATUS BAR: [info] [counts] [mode]          [zoom: 100%]    │
└─────────────────────────────────────────────────────────────┘
```

### Message Protocol (Extension ↔ Webview)

```typescript
// Extension → Webview
type ExtToWebview =
  | { type: "init"; data: EditorData }
  | { type: "loadFile"; content: string; filename: string }
  | { type: "saved"; success: boolean }
  | { type: "themeChanged"; colors: ThemeColors }

// Webview → Extension
type WebviewToExt =
  | { type: "ready" }
  | { type: "save"; data: EditorData; format: "lua" | "toml" | "json" }
  | { type: "requestFile"; filters: FileFilter[] }
  | { type: "dirty"; isDirty: boolean }
  | { type: "log"; level: "info" | "warn" | "error"; message: string }
```

---

## Editor Specifications

### 1. Tile Map Editor

**Command**: `luna.editor.tileMap`
**File association**: `*.tilemap.lua`, `*.tilemap.toml`

```
┌───────────────────────────────────────────────────────────────┐
│ SIZE: [20] × [15]  [Resize]  LAYER: [Ground ▼]  [+ Layer]   │
│ TILE SIZE: [32]    [Export Lua] [Export TOML]     [Clear All] │
├──────────┬─────────────────────────────────────┬──────────────┤
│ TILE     │                                     │              │
│ PALETTE  │     GRID CANVAS                     │              │
│          │     Click to paint tiles             │              │
│ ┌──┬──┐  │     Shows tile IDs as colored squares│              │
│ │0 │1 │  │                                     │              │
│ ├──┼──┤  │                                     │              │
│ │2 │3 │  │                                     │              │
│ └──┴──┘  │                                     │              │
│          │                                     │              │
│ TOOLS    │                                     │              │
│ ● Paint  │                                     │              │
│ ○ Erase  │                                     │              │
│ ○ Fill   │                                     │              │
│ ○ Pick   │                                     │              │
│ ○ Rect   │                                     │              │
│          │                                     │              │
│ VIEW     │                                     │              │
│ ☑ Grid   │                                     │              │
│ ☑ Layers │                                     │              │
├──────────┴─────────────────────────────────────┴──────────────┤
│ Pos: 5,3   Tile: 2   Layer: ground   20×15                   │
└───────────────────────────────────────────────────────────────┘
```

**Export format** (Lua):
```lua
return {
  width = 20, height = 15, tileSize = 32,
  layers = {
    ground = { 0,0,1,1,2,2, ... },
    walls  = { 0,0,0,3,3,0, ... },
  }
}
```

---

### 2. Scene Flow Editor

**Command**: `luna.editor.sceneFlow`
**File association**: `*.scene.lua`

```
┌───────────────────────────────────────────────────────────────┐
│ SCENES  [+ Add Scene]  [Delete]                              │
│ CONNECT [🔗 Connect Scenes]                  [Export Lua]     │
├──────────────────────────────────────────┬────────────────────┤
│                                          │ SCENE PROPERTIES   │
│     ┌──────────┐        ┌──────────┐    │                    │
│     │  Title   │───────►│ Gameplay │    │ Name: [Title]      │
│     │  Screen  │        │          │    │ OnEnter: [func]    │
│     └──────────┘        └────┬─────┘    │ OnExit:  [func]    │
│                              │          │ OnUpdate:[func]    │
│                              ▼          │ OnDraw:  [func]    │
│                         ┌──────────┐    │                    │
│                         │  Pause   │    │ Transitions:       │
│                         │  Menu    │    │  → Gameplay [cond] │
│                         └──────────┘    │  → Title    [cond] │
│                                          │                    │
│                                          │                    │
├──────────────────────────────────────────┴────────────────────┤
│ Scenes: 3   Transitions: 4   Mode: Select                    │
└───────────────────────────────────────────────────────────────┘
```

**Nodes**: Rectangular boxes representing scenes/states
**Edges**: Arrows with optional condition labels
**Interaction**: Click to select, drag to move, connect mode for linking

---

### 3. Entity Designer

**Command**: `luna.editor.entity`

```
┌───────────────────────────────────────────────────────────────┐
│ ENTITIES [+ New Entity] [Duplicate] [Delete]                  │
│ TEMPLATES: [Player] [Enemy] [Pickup] [Projectile]            │
│                                                    [Export]   │
├──────────┬─────────────────────────────┬──────────────────────┤
│ ENTITY   │                             │ PREVIEW              │
│ LIBRARY  │  COMPONENT EDITOR           │  ┌──────┐           │
│          │                             │  │  ▶   │           │
│ ▶ Player │  ┌─ Transform ──────── ✕┐   │  └──────┘           │
│   player │  │ X: [0]    Y: [0]    │   │                      │
│ ▶ Enemy  │  │ Rot: [0]  Scale:[1] │   │ STATS                │
│   enemy  │  └─────────────────────┘   │ Components: 6        │
│          │                             │ HP: 50/50            │
│          │  ┌─ Sprite ─────────── ✕┐   │ Body: dynamic        │
│          │  │ Image: [enemy.png]   │   │ AI: patrol           │
│          │  │ Quad: [0,0,32,32]    │   │ Sprite: enemy.png    │
│          │  │ Origin: [0.5, 0.5]   │   │ Collider: rect 32×32│
│          │  └─────────────────────┘   │                      │
│          │                             │                      │
│          │  ┌─ Physics ────────── ✕┐   │                      │
│          │  │ BodyType: [dynamic]  │   │                      │
│          │  │ Density: [1]         │   │                      │
│          │  │ Friction: [0.3]      │   │                      │
│          │  │ Restitution: [0.2]   │   │                      │
│          │  └─────────────────────┘   │                      │
├──────────┴─────────────────────────────┴──────────────────────┤
│ Entities: 4    Components: 12                                 │
└───────────────────────────────────────────────────────────────┘
```

**Components**: Transform, Sprite, Physics, Collider, AI, Health, Inventory, Custom
**Templates**: Pre-configured entity archetypes
**Export**: Generates Lua entity factory functions

---

### 4. Pixel Art Editor

**Command**: `luna.editor.pixelArt`

```
┌───────────────────────────────────────────────────────────────┐
│ SIZE: [16×16]  TOOLS: [✏️🪣🔲✂️📏]  LAYER: [0/3]  [Save]   │
├──────────┬──────────────────────────────┬─────────────────────┤
│ COLOR    │                              │ LAYERS              │
│ L: ██ R: │     PIXEL CANVAS             │ ☑ Layer 3           │
│ #FF004D  │     Large grid view          │ ☑ Layer 2           │
│          │     Click to draw pixels     │ ☑ Layer 1           │
│ PALETTE  │                              │ ☑ Background        │
│ ████████ │                              │                     │
│ ████████ │                              │ PREVIEW             │
│ ████████ │                              │ ┌────┐ 1× scale     │
│ ████████ │                              │ │    │              │
│          │                              │ └────┘              │
│ FRAMES   │                              │                     │
│ [+][📋][✕]                              │ ANIMATION           │
│ [1][2][3] │                              │ ▶ Play   FPS: [12] │
├──────────┴──────────────────────────────┴─────────────────────┤
│ Tool: Pen  Layer 0/7  Row 0/15  16×16×8  Color: #FF004D      │
└───────────────────────────────────────────────────────────────┘
```

**Tools**: Pen, Eraser, Bucket fill, Rectangle, Line, Color pick
**Layers**: Multiple layers with visibility toggle
**Frames**: Animation frame management
**Export**: PNG sprite sheet or individual frames

---

### 5. Particle Designer

**Command**: `luna.editor.particle`

```
┌───────────────────────────────────────────────────────────────┐
│ Particle Designer  [⏸ Pause] [↻ Reset] LAYERS [+ Add] [Clone]│
│                                                  [Export Lua] │
├──────────┬────────────────────────────────────────────────────┤
│ PRESETS  │                                                    │
│ 🔥Fire   │        PREVIEW CANVAS                             │
│ 💨Smoke  │                                                    │
│ ✨Sparks │        Particles render here in real-time          │
│ ❄Snow   │                                                    │
│ 🌧Rain   │                          🔥                        │
│ 💥Burst  │                         🔥🔥                       │
│ ✨Magic  │                        🔥🔥🔥                      │
│ ❤Hearts │                                                    │
│ 🎊Confetti│                                                   │
│ 🪲Firefly│                                                    │
│ 🫧Bubbles│                                                    │
│ ※ Dust   │                                                    │
│          │                                                    │
│ LAYERS   │                                                    │
│ 🔴Layer 1│                                                    │
│          │                                                    │
│ PARAMS   │                                                    │
│ Max: [200]│                                                   │
│ Rate:[50] │                                                   │
│ Speed:[15]│                                                   │
│ Life:[0.5]│                                                   │
│ Dir:[-1.5]│                                                   │
│ Spread:[0]│                                                   │
│ Size: [5] │                                                   │
│ Gravity:  │                                                   │
│  X:[0]    │                                                   │
│  Y:[-40]  │                                                   │
│ Colors:   │                                                   │
│ Start:[🟡]│                                                   │
│ Mid:  [🟠]│                                                   │
│ End:  [🔴]│                                                   │
├──────────┴────────────────────────────────────────────────────┤
│ Preset: fire  Particles: 32  Layers: 1  FPS: 60              │
└───────────────────────────────────────────────────────────────┘
```

---

### 6. AI Behavior Tree

**Command**: `luna.editor.aiBehavior`

```
┌───────────────────────────────────────────────────────────────┐
│ AI BEHAVIOR TREE  [🗑Delete] [📋Dup]                          │
│ [Layout] [Preset]                     [Lua] [TOML]           │
├──────────┬──────────────────────────────┬─────────────────────┤
│ COMPOSITE│                              │ PROPERTIES          │
│ ➡Sequence│     TREE CANVAS              │                     │
│ ❓Selector│                             │ Select a node       │
│ ⏸Parallel│   ┌─────────┐               │                     │
│ 🎲RndSel │   │Sequence │               │                     │
│          │   └────┬────┘               │                     │
│ DECORATOR│        ├────────┐            │                     │
│ !Inverter│   ┌────┴───┐ ┌──┴──────┐    │                     │
│ ↻Repeater│   │HasTarget│ │In Range │    │                     │
│ ✓Succeeder   └────────┘ └────┬────┘    │                     │
│ ⏰Cooldown│              ┌───┴────┐    │                     │
│ 🚫Guard  │              │ Attack │    │                     │
│          │              └────────┘    │                     │
│ CONDITION│                              │                     │
│ 🎯HasTarget                            │                     │
│ 📏InRange│                              │                     │
│ ❤HealthChk                             │                     │
│ ⚙Custom  │                              │                     │
│          │                              │                     │
│ ACTION   │                              │                     │
│ 🏃MoveTo │                              │                     │
│ ⚔Attack │                              │                     │
│ 🏃‍♀️Flee   │                              │                     │
│ 🛡Patrol │                              │                     │
├──────────┴──────────────────────────────┴─────────────────────┤
│ 🟢Success 🔴Failure 🟡Running ⚪Idle    Nodes: 5  Depth: 3   │
└───────────────────────────────────────────────────────────────┘
```

---

### 7. Graph / Node Editor

**Command**: `luna.editor.graph`

```
┌───────────────────────────────────────────────────────────────┐
│ GRAPH / NODE EDITOR  [+ Node] [🔗 Connect] [🗑Delete]         │
│ [Layout] [Demo]                              [Lua] [TOML]    │
├──────────┬──────────────────────────────┬─────────────────────┤
│ NODE     │                              │ PROPERTIES          │
│ TYPES    │     GRAPH CANVAS             │                     │
│  [+]     │                              │ 🔗 Select a node    │
│          │   ┌──────┐    ┌──────┐      │    or edge           │
│          │   │ Node │────│ Node │      │                     │
│ EDGE     │   │  A   │    │  B   │      │                     │
│ TYPES    │   └──────┘    └──┬───┘      │                     │
│  [+]     │                  │          │                     │
│          │              ┌───┴──┐       │                     │
│          │              │ Node │       │                     │
│ INSTANCES│              │  C   │       │                     │
│          │              └──────┘       │                     │
│          │                              │                     │
├──────────┴──────────────────────────────┴─────────────────────┤
│ Nodes: 3  Edges: 2  Types: 1                                 │
└───────────────────────────────────────────────────────────────┘
```

---

### 8. Voxel Editor

**Command**: `luna.editor.voxel`

```
┌───────────────────────────────────────────────────────────────┐
│ Voxel Editor  SIZE: [16×16×8] TOOLS: [✏️🪣🔲✂️📏]             │
│ LAYER: [▼ 0/7]  DIRS: [4 Diagonal ▼]                 [Save] │
├──────────┬──────────────────────────────┬─────────────────────┤
│ FILES    │ Top View (XY)    Layer 0/7   │ 3D Isometric Preview│
│          │ ┌────────────┐   ☑ Ghost     │ ┌─────────────────┐ │
│ [models] │ │            │               │ │    ╱──╲         │ │
│          │ │  Grid view │               │ │   ╱    ╲        │ │
│ [+New]   │ │  paint     │               │ │  ╱      ╲       │ │
│          │ │  voxels    │               │ │ ╲      ╱        │ │
│ COLOR    │ └────────────┘               │ │  ╲    ╱         │ │
│ L:██ R:██│                              │ │   ╲──╱          │ │
│ #FF004D  │ Side View (XZ)   Row 0/15   │ └─────────────────┘ │
│          │ ┌────────────┐               │                     │
│ PALETTE  │ │            │               │ Direction views:    │
│ ████████ │ │  Side cross-│               │ ◄ SE (1/4) ►      │
│ ████████ │ │  section    │               │                     │
│          │ └────────────┘               │ ☑Outline ☑Shadow   │
│ FRAMES   │                              │ ☑AO      ☑Light    │
│ [+][📋][✕]│                              │                     │
│ [1]      │                              │                     │
├──────────┴──────────────────────────────┴─────────────────────┤
│ Tool: Pen  Layer 0/7  16×16×8  Color: #FF004D  Frame 1/1     │
└───────────────────────────────────────────────────────────────┘
```

---

### 9. Dialog Editor

**Command**: `luna.editor.dialog`

Visual editor for branching dialogue trees (NPC conversations, cutscenes).

### 10. Database Browser

**Command**: `luna.editor.database`

Browse and edit game data tables (items, enemies, quests) stored as TOML/Lua.

### 11. Procedural Map Generator

**Command**: `luna.editor.procMap`

Configure and preview procedural map generation with step-based pipelines.

### 12. Quest / Tech Tree Editor

**Command**: `luna.editor.questTree`

Visual node graph for quest chains and technology trees with prerequisites.

### 13. GUI Widget Editor

**Command**: `luna.editor.guiWidget`

Drag-and-drop GUI layout builder for game UI (buttons, panels, labels, bars).

### 14. Tilemap Script Editor

**Command**: `luna.editor.tilemapScript`

Script-driven tilemap generation with blocks, steps, and preview.

### 15. Test Runner (Visual)

**Command**: `luna.editor.testRunner`

Visual test execution and results display.

### 16. API Reference Browser

**Command**: `luna.editor.apiReference`

Interactive, searchable API documentation browser powered by the generated API reference.

---

## Export Formats

All editors that produce game data support two export formats:

### Lua Export
```lua
-- Generated by Luna Toolkit — Tile Map Editor
return {
  width = 20,
  height = 15,
  tileSize = 32,
  layers = { ... }
}
```

### TOML Export
```toml
# Generated by Luna Toolkit — Tile Map Editor
width = 20
height = 15
tile_size = 32

[layers]
ground = [0, 0, 1, 1, 2, 2]
walls = [0, 0, 0, 3, 3, 0]
```

Both formats are loadable by the Luna2D engine at runtime via `luna.filesystem.read()` + `luna.data.parseToml()`.
