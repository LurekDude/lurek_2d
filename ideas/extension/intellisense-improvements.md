# IntelliSense Improvements

## Current State

The extension has 22 provider files covering a wide range of language intelligence.
This significantly exceeds the 12 providers documented in `02-intellisense-design.md`.

### Provider Inventory

| Provider | Status | Lines | Notes |
|---|---|---|---|
| completion.ts | ✅ Real | ~600 | 25+ builtins, 8 stdlib modules, context-aware |
| hover.ts | ✅ Real | ~700 | 20+ keyword docs, math constants, easing |
| signature.ts | ✅ Real | — | Function signature help |
| definition.ts | ✅ Real | — | Go-to-definition |
| references.ts | ✅ Real | — | Find references |
| symbols.ts | ✅ Real | — | Document symbols |
| diagnostics.ts | ✅ Real | ~400 | 9 diagnostic rules |
| color.ts | ✅ Real | — | Color decorators |
| assetPath.ts | ✅ Real | — | Asset path completion |
| inlayHints.ts | ✅ Real | — | Parameter name hints |
| codeActions.ts | ✅ Real | — | Quick fixes |
| luajitHints.ts | ✅ Real | — | LuaJIT-specific perf hints |
| typeInference.ts | ✅ Real | ~400 | Factory return types, method completion |
| requireGraph.ts | ✅ Real | ~280 | Cycle detection, missing module warnings |
| luacatsProvider.ts | ✅ Real | ~250 | ---@class, ---@field, ---@param parsing |
| codeLens.ts | ✅ Real | ~280 | References, tests, callback docs |
| formatting.ts | ✅ Real | ~350 | Lua formatter with indent tracking |
| folding.ts | ✅ Real | — | Custom folding ranges |
| rename.ts | ✅ Real | — | Symbol rename |
| semanticTokens.ts | ✅ Real | ~380 | Namespace/callback/deprecation coloring |
| perfDashboard.ts | — | ~200 | Webview, not a language provider |
| systemMonitor.ts | — | ~350 | Webview, not a language provider |

---

## Improvement Ideas

### 1. API Data Pipeline Completion

**Problem**: `02-intellisense-design.md` specifies a pipeline: `///` doc comments → `tools/generate-api-data.ts` → JSON files → providers. The implementation uses `apiData.ts` with hardcoded data instead of generated files.

**Improvement**: Build the planned data generation pipeline:
- Parse `src/lua_api/*.rs` files for `///` docstrings
- Generate `data/api-completions.json`, `data/api-signatures.json`, `data/api-hover.json`, `data/api-enums.json`
- Load these in `apiData.ts` at activation time
- Add a command to regenerate on demand

**Impact**: Auto-sync API completions with engine code. No more manual updates.

### 2. Deep Type Inference

**Current**: `typeInference.ts` tracks return types from 4 factory functions (Image, Canvas, Font, Shader).

**Improvement ideas**:
- Track all luna.* factory returns (Body, Shape, Source, Timer, Entity, ParticleSystem, etc.)
- Infer types from method calls (e.g. `body:getPosition()` returns Vec2)
- Track local variable types through assignments
- Support table field typing (`player = { x = 0, y = 0, speed = 200 }` → knows fields)
- Report type at cursor in status bar (like TypeScript shows type on hover)

### 3. Luna-Specific Diagnostics Expansion

**Current 9 rules**: deprecated, colorRange, unusedRequire, assetNotFound, threadSafety, callbacks, enumValues, unknownLunaFunction, confLua.

**New diagnostic ideas**:
- **Missing `luna.load()` callback** — warn if `main.lua` uses luna.* but has no `luna.load` callback
- **Per-frame allocation warning** — flag `luna.gfx.newImage()` or `luna.audio.newSource()` inside `luna.draw`/`luna.update` callbacks
- **Invalid key name** — flag `luna.keypressed` using key strings not in the valid set
- **Body type mismatch** — flag methods called on wrong body type (e.g. `setLinearVelocity` on static body)
- **Missing `test_summary()`** — flag Lua test files that don't end with `test_summary()`
- **Double borrow potential** — flag patterns that might cause Rc<RefCell> panics
- **Entity nil check** — flag entity access without nil check after `luna.entity.find()`
- **Coord system warning** — flag negative Y assumptions (Luna2D Y-axis goes down)

### 4. Contextual String Completion Enhancement

**Current**: Key names are completed when typing inside `luna.keypressed` etc.

**New contextual completions**:
- **Easing function names** when typing `luna.time.tween(_, _, _, "` → show all easing names with preview
- **Blend mode names** when typing `luna.gfx.setBlendMode("` → show modes with visual description
- **Physics body types** when typing `luna.physics.newBody(_, _, _, "` → "static", "dynamic", "kinematic"
- **Audio source types** when typing `luna.audio.newSource(_, "` → "static", "stream"
- **Filter modes** when typing `setFilter("` → "nearest", "linear" with explanation
- **Draw modes** when typing `luna.gfx.circle("` → "fill", "line" with explanation
- **Event names** when typing `luna.signal.on("` → list all engine event names

### 5. Easing Curve Visualization

**Documented in 08-intellisense-enhanced.md but not implemented.**

Show ASCII art or SVG curve on hover over an easing name:
```
linear:    ──────────────/
easeInQuad: ─────────/
easeOutQuad:     /──────────
easeInOutQuad: ────/────
```

Implementation: Generate a small embedded SVG or canvas in the hover markdown.

### 6. LuaCATS Deep Integration

**Current**: `luacatsProvider.ts` parses `---@class`, `---@field`, `---@param`, `---@return`.

**Improvements**:
- Feed parsed class types into `typeInference.ts` for unified type tracking
- Support `---@type` annotations for local variable typing
- Support `---@generic` for generic function signatures
- Validate annotations against actual function signatures
- Auto-generate `---@param` stubs from function signature (code action)
- Show class hierarchy in hover (parent → child chain)

### 7. Cross-File Symbol Resolution

**Current**: Each provider operates per-document. `symbolIndex.ts` exists but integration with completions is unclear.

**Improvements**:
- Workspace-wide `require()` resolution → jump to definition across files
- Auto-import suggestions: typing a function name from another module → suggest `require()`
- Show all references across the entire workspace, not just current file
- Support `luna.fs.load()` as a module import path

### 8. Snippet Library Expansion

**Current**: 3 snippets in library browser. `data/snippets.json` doesn't exist.

**Improvements**:
- Create `data/snippets.json` with all 12 planned patterns:
  1. Class boilerplate (metatables)
  2. State machine
  3. Event emitter
  4. Object pool
  5. Component system
  6. Timer utilities
  7. Tween chain
  8. FSM with transitions
  9. Signal/slot
  10. Grid utilities
  11. Stack/queue
  12. Camera follow
- Make snippets contextual (suggest class snippet when typing `local M = {}`)
- Add game-specific snippets: player controller, enemy spawner, level loader, save/load, HUD, menu

### 9. Performance-Sensitive Hints

**Current**: `luajitHints.ts` provides LuaJIT-specific diagnostics.

**Additional perf hints**:
- Flag string concatenation in loops (suggest `table.concat`)
- Flag `pairs()`/`ipairs()` on large tables inside `update()`
- Flag creating closures inside hot loops
- Flag `luna.gfx.newImage()` called every frame
- Suggest `local` for frequently accessed globals
- Flag deep table nesting in tight loops

### 10. Inline Documentation Generation

**New feature**: Generate `///`-style doc comments for undocumented Lua API functions.

- Code action "Generate Luna API docs" on undocumented `tbl.set()` calls
- Auto-generate `@param` and `@return` from Rust function signature
- Insert template that developer fills in
