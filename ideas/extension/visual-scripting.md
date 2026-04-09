# Visual Scripting Integration

## Documentation (visual_scripting.md)

The spec describes a full visual scripting system:

- **Architecture**: DAG (Directed Acyclic Graph) of blocks with typed ports
- **Port types**: flow, number, string, boolean, any, table
- **Block categories**: 36+ built-in block types across:
  - Flow Control (if, for, while, sequence)
  - Math (add, subtract, multiply, clamp, lerp, random)
  - Graphics (draw rect, draw circle, draw line, draw image, set color)
  - Physics (apply force, apply impulse, get velocity, set position)
  - Input (key pressed, mouse position, mouse button)
  - Audio (play sound, stop sound, set volume)
  - Entity (create, destroy, get component, set component)
  - Logic (and, or, not, compare, select)
  - String (concat, format, length, substring)
  - Timer (delay, every, after)
  - Events (on event, emit event)
  - Variables (get, set, local scope)
- **Compiler**: Graph → Lua source code compiler
- **Recommendation**: Pure Lua reimplementation over Rust engine module

---

## Current Implementation: None

No visual scripting files exist in vscode-extension/. No `lurek.scripting.*` API in the engine.

---

## Analysis

### Should This Be Built?

**Arguments for**:
- Unlocks non-programmer game designers
- Visual debugging is easier than text debugging
- Popular in competitor engines (Engine C VisualScript, Engine G Visual Scripting, Engine H Blueprints)
- Already fully specified in documentation

**Arguments against**:
- Massive implementation effort (editor + compiler + runtime)
- Lua is already beginner-friendly — the gap isn't as big as C#/C++
- Visual scripts can become unreadable at scale ("spaghetti graphs")
- Maintenance burden for both text and visual APIs
- A-01 (runtime only, no editor) partially conflicts with building a full visual editor

**Recommendation**: **Phase this into a separate extension** or a late-phase feature. The core Luna Toolkit provides enough value without it.

---

## If Built: Implementation Path

### Phase 1: Minimal Block Editor (VS Code Webview)

1. Create `editors/visualScriptEditor.ts` with canvas-based block editor
2. Support 10 core block types: If, ForEach, SetVariable, GetVariable, Print, Add, Subtract, Compare, OnUpdate, OnDraw
3. Graph serialization to JSON
4. Simple graph → Lua compiler (one-pass, no optimization)
5. "Export to Lua" button that generates a `.lua` file

### Phase 2: Engine API Blocks

6. Add blocks for lurek.gfx.* (rectangle, circle, image, text)
7. Add blocks for lurek.input.* (keypressed, mousepressed)
8. Add blocks for lurek.time.* (after, every)
9. Add blocks for lurek.entity.* (create, find, destroy)
10. Auto-generate blocks from api_data.json

### Phase 3: Debugging & Polish

11. Step-through execution in the block editor
12. Value display on ports during execution
13. Breakpoints on blocks
14. Block search and palette organization
15. Copy/paste block groups
16. Undo/redo

### Phase 4: Pure Lua Runtime (per spec recommendation)

17. Implement `lurek.scripting.*` as a pure-Lua library/ module
18. Load compiled Lua from visual scripts at runtime
19. Hot-reload visual script changes
20. No Rust engine changes needed

---

## Feature Ideas for Visual Scripting

### 1. Hybrid Mode

Allow mixing visual scripts and hand-written Lua:
- Visual script can call Lua functions (via "Call Function" block)
- Lua code can trigger visual script execution
- Visual script exports to Lua → developer can "eject" and edit text

### 2. Custom Block Definitions

- Let developers create custom blocks from Lua functions
- Define inputs/outputs/flow
- Share blocks as reusable libraries
- Block palette organized by project and engine

### 3. Template Graphs

Pre-built visual script templates:
- Player controller (WASD movement)
- Enemy patrol (waypoint following)
- Collectible pickup (overlap → score)
- Menu navigation (button → scene change)
- Dialog trigger (proximity → dialog start)

### 4. Graph Validation

Before compiling:
- Check for disconnected blocks (unreachable code)
- Check for type mismatches (number port → string port)
- Check for infinite loops
- Check for missing inputs
- Show errors directly on the graph

### 5. Performance Annotations

Show performance hints on blocks:
- "This block runs every frame" → highlight in yellow
- "This block allocates memory" → highlight in orange
- Estimated ms per block from profiling data
