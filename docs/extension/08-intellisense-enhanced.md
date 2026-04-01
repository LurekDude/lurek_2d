# Luna Toolkit — Enhanced IntelliSense Design

> Expands the baseline IntelliSense design (02-intellisense-design.md) with deeper
> intelligence specifically for LuaJIT game development with Luna2D.

---

## 1. LuaJIT-Specific Intelligence

### 1.1 LuaJIT Built-in Library Completions

Luna2D targets LuaJIT. The extension must cover namespaces that exist in LuaJIT
but not in standard Lua 5.4:

**`bit.*` namespace** (LuaJIT bit operations, highly useful for game flags/masks):
```lua
bit.band(a, b)    -- bitwise AND         → completion + hover
bit.bor(a, b)     -- bitwise OR
bit.bxor(a, b)    -- bitwise XOR
bit.bnot(a)       -- bitwise NOT
bit.lshift(a, n)  -- left shift
bit.rshift(a, n)  -- logical right shift
bit.arshift(a, n) -- arithmetic right shift
bit.tobit(n)      -- normalize to int32
bit.tohex(n)      -- format as hex string
bit.rol(a, n)     -- rotate left
bit.ror(a, n)     -- rotate right
```

**`jit.*` namespace** (JIT compiler control):
```lua
jit.on([func])    -- enable JIT for function or globally
jit.off([func])   -- disable JIT (useful for debugging)
jit.flush([func]) -- flush JIT cache
jit.status()      -- returns engine, version, host, etc.
```

### 1.2 LuaJIT Performance Hint Diagnostics

New diagnostic rule category: `luna.luajit` (severity: Hint).

| Rule ID | Pattern | Hint Message |
|---|---|---|
| `luajit.newTableHotPath` | `{}` or `table.create` in `luna.update`/`luna.draw` | "Table allocation in hot path prevents JIT compilation. Consider caching or using an object pool." |
| `luajit.newImageHotPath` | `luna.graphics.newImage()` in `update`/`draw` | "Resource creation in hot path is expensive. Move to luna.load()." |
| `luajit.floatToInt` | `math.floor(x)` in computation chain | "Consider bit.tobit() for integer conversion — up to 4× faster on LuaJIT." |
| `luajit.globalAccess` | Reading global variable repeatedly in loop | "Cache global in local: 'local draw = luna.graphics.draw' is ~2× faster." |
| `luajit.stringConcat` | `..` in loop body | "String concatenation in loops creates many temporaries. Use table.concat() instead." |
| `luajit.pcallTrace` | `pcall` in hot path | "pcall interrupts trace compilation. Move error handling outside the inner loop." |
| `luajit.mixedTypes` | Variable assigned both number and string | "Mixed types prevent optimal JIT trace. Keep variables single-typed." |
| `luajit.mathRandom` | `math.random()` | "luna.math.random() is a separate state from the Lua VM random — prefer it for reproducible games." |

### 1.3 LuaJIT vs Lua 5.4 Feature Warnings

When running in LuaJIT mode, warn if user writes Lua 5.4-only features:
- Integer / float subtypes (`1.0 == 1 -- differently typed in 5.4`)
- `<const>` and `<close>` annotations
- `utf8.*` library (not in LuaJIT)
- `table.move` differences

---

## 2. Type Inference Engine

### 2.1 Return Type Tracking

All `luna.*` factory functions have known return types. The extension tracks these
through variable assignments and propagates completions:

```lua
local img = luna.graphics.newImage("player.png")
--    ^^^
--    inferred: Image type
--    enables: img:getDimensions(), img:getWidth(), img:getHeight(),
--             img:getFilter(), img:setFilter(), img:release()

local world = luna.physics.newWorld(0, 200)
--    ^^^^^
--    inferred: World type
--    enables: world:step(), world:queryAABB(), world:setGravity(), etc.

local body = world:createBody({type="dynamic", x=100, y=100})
--    ^^^^
--    inferred: Body type
--    enables: body:getPosition(), body:setLinearVelocity(), etc.

local src = luna.audio.newSource("music.ogg", "stream")
--    ^^^
--    inferred: AudioSource type
--    enables: src:play(), src:stop(), src:setVolume(), src:isPlaying()
```

**Implementation**: Single-pass type propagation. Assignments are registered in
a per-document symbol table. No full type inference graph — just direct assignments
from known-typed factory functions.

### 2.2 Object Method Completion

When the inferred type is known, `:` completions show the correct method set:

| Type | Methods available via `:` |
|---|---|
| `Image` | `getDimensions`, `getWidth`, `getHeight`, `getFilter`, `setFilter`, `release` |
| `Canvas` | `getDimensions`, `getWidth`, `getHeight`, `renderTo`, `getImageData`, `release` |
| `Font` | `getWidth`, `getHeight`, `getAscent`, `getDescent`, `hasGlyphs`, `release` |
| `AudioSource` | `play`, `stop`, `pause`, `resume`, `isPlaying`, `setVolume`, `getVolume`, `setLooping`, `getLooping`, `setPosition`, `release` |
| `World` | `step`, `createBody`, `queryAABB`, `setGravity`, `getGravity`, `destroy` |
| `Body` | `getPosition`, `setPosition`, `getLinearVelocity`, `setLinearVelocity`, `applyForce`, `applyImpulse`, `isActive`, `setType`, `destroy` |
| `Shader` | `send`, `sendColor`, `hasUniform`, `release` |

### 2.3 Callback Parameter Types

When the user assigns a Luna2D callback, parameters are automatically typed:

```lua
function luna.keypressed(key, scancode, isrepeat)
--                       ^^^  ^^^^^^^^  ^^^^^^^^^
--                  string  string    boolean
-- key hover shows: "Key name string, e.g. 'space', 'a', 'left'"
-- Completion inside body: key == "|" → key name completions
```

```lua
function luna.mousepressed(x, y, button, istouch, presses)
--                         ^  ^  ^^^^^^  ^^^^^^^  ^^^^^^^
--                    number,number,number, boolean, number
-- button hover: "1=left, 2=right, 3=middle"
```

### 2.4 OOP Class Pattern Detection

Detect and track common Lua OOP patterns, enabling method completions on instances:

**Pattern 1: Simple metatable pattern**
```lua
local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, hp)
    return setmetatable({x=x, y=y, hp=hp}, Enemy)
end

function Enemy:update(dt) ... end
function Enemy:draw() ... end
-- After detection: local e = Enemy.new(...)
--                  e:  → suggests update, draw, + any method defined on Enemy
```

**Pattern 2: Class-with-inheritance**
```lua
local Base = {}
Base.__index = Base
local Enemy = setmetatable({}, {__index = Base})
Enemy.__index = Enemy
-- Inherits Base methods in completion list
```

**Detection heuristic**: `setmetatable({}, Class)` or `Class.__index = Class` triggers class tracking. No AST required — regex-based pattern matching on declaration lines is sufficient.

---

## 3. Contextual String Completions

When the user is inside a string argument to specific API functions, completion
provides a curated list of valid values:

### 3.1 Key Names (`luna.input.isDown`, `luna.keypressed`)
```lua
luna.input.isDown("|")
-- Suggests: "space", "return", "escape", "tab", "backspace",
--           "delete", "insert", "home", "end", "pageup", "pagedown",
--           "up", "down", "left", "right",
--           "a".."z", "0".."9",
--           "f1".."f12",
--           "lshift", "rshift", "lctrl", "rctrl", "lalt", "ralt",
--           "numpad0".."numpad9", "kp_enter", "kp_period"
```

### 3.2 Blend Modes
```lua
luna.graphics.setBlendMode("|")
-- Suggests: "alpha", "add", "subtract", "multiply",
--            "premultiplied", "replace", "screen", "darken", "lighten"
```

### 3.3 Body Types
```lua
luna.physics.newBody(world, x, y, "|")
-- Suggests: "static", "dynamic", "kinematic"
```

### 3.4 Audio Source Types
```lua
luna.audio.newSource("file.ogg", "|")
-- Suggests: "static" (fully loaded), "stream" (streamed, large files)
```

### 3.5 Easing Functions
```lua
luna.math.lerp(a, b, t, "|")    -- or luna.tween.to(obj, dur, target, "|")
-- Suggests: "linear", "quad", "cubic", "quart", "quint",
--            "sine", "expo", "circ", "back", "bounce", "elastic"
-- Hover shows: MINI CURVE CHART as ASCII or SVG
```

### 3.6 Filter Modes
```lua
img:setFilter("|", "|")
-- Suggests: "nearest" (pixel art), "linear" (smooth)
```

### 3.7 Wrap Modes
```lua
img:setWrap("|", "|")
-- Suggests: "clamp", "clampzero", "repeat", "mirroredrepeat"
```

### 3.8 Line Cap / Join
```lua
luna.graphics.setLineCap("|")    -- "none", "butt", "square", "round"
luna.graphics.setLineJoin("|")   -- "miter", "bevel", "none"
luna.graphics.setLineStyle("|")  -- "rough", "smooth"
```

---

## 4. Easing Function Hover Visualization

When hovering over an easing function name string or `luna.math.easing.*` call,
show a mini ASCII curve diagram in the hover popup:

```
luna.math.easing.easeInBounce

┐ • • • • •
│           ●
│         ●
│       ●
│     ●
│    ●      ●
│  ● ●      ●
│●          ●●●●
└──────────────► t
Starts slow, bounces at end
```

This is generated from pre-computed sample points — no runtime math needed.

---

## 5. Pattern Library (Snippets + LuaCATS)

A curated set of idiomatic game programming patterns, provided as:
1. **Snippets** — quickly insert the full pattern
2. **LuaCATS-annotated module stubs** — type-checked library files

### 5.1 Available Patterns

| Pattern | Prefix | Description |
|---|---|---|
| **Class** | `luna.class` | Metatble-based OOP with `new()`, `__index`, inheritance |
| **State Machine** | `luna.states` | State table with `enter`/`exit`/`update`/`draw` callbacks |
| **Event Bus** | `luna.events` | Pub/sub: `on(event, handler)`, `emit(event, ...)` |
| **Object Pool** | `luna.pool` | Pre-allocated table, `acquire()` / `release()` → zero alloc in hot path |
| **Component System** | `luna.components` | Entities as IDs, components as tables, systems as loops |
| **Timer** | `luna.timer` | Delay/repeat without coroutines: `after(seconds, fn)`, `every(interval, fn)` |
| **Tween** | `luna.tween` | Smooth value animation: `to(target, secs, {x=100}, "ease_out_quad")` |
| **Finite State Machine** | `luna.fsm` | Strict FSM: states, transitions, guards |
| **Signal** | `luna.signal` | Observer: `signal:connect(fn)`, `signal:emit(...)` |
| **Grid** | `luna.grid` | 2D grid with get/set/iterate/neighbours |
| **Stack** | `luna.stack` | Push/pop scene stack |
| **Camera** | `luna.camera` | World-space camera with lerp follow + screenshake |

### 5.2 Pattern Snippet Example

```lua
-- Snippet prefix: luna.statemachine
---@class State
---@field enter fun(self: State, prev: string)?
---@field exit  fun(self: State, next: string)?
---@field update fun(self: State, dt: number)?
---@field draw  fun(self: State)?

---@class StateMachine
local StateMachine = {}
StateMachine.__index = StateMachine

---@param states table<string, State>
---@param initial string
---@return StateMachine
function StateMachine.new(states, initial)
    local sm = setmetatable({}, StateMachine)
    sm.states  = states
    sm.current = initial
    if states[initial].enter then states[initial]:enter(nil) end
    return sm
end

---@param name string
function StateMachine:change(name)
    local prev = self.current
    if self.states[prev].exit  then self.states[prev]:exit(name)  end
    self.current = name
    if self.states[name].enter then self.states[name]:enter(prev) end
end

function StateMachine:update(dt) if self.states[self.current].update then self.states[self.current]:update(dt) end end
function StateMachine:draw()     if self.states[self.current].draw   then self.states[self.current]:draw()     end end
```

### 5.3 Deployment

When a pattern snippet is inserted:
1. The snippet body is inserted at cursor
2. A prompt appears: "Add typed library stub to `lib/patterns/`?" → Yes/No
3. If Yes: the corresponding annotated `.lua` is written to `lib/patterns/`, enabling full type checking

---

## 6. Workspace-Level Intelligence

### 6.1 Require Graph & Circular Dependency Detection

The extension builds a cached require graph at activation and updates it on file save:

```
Diagnostic: luna.circularRequire
  main.lua → require("player")
  player.lua → require("weapons")
  weapons.lua → require("player")  ← ERROR: circular dependency

  Warning: "Circular require detected: player → weapons → player"
  Code action: "Break cycle by using late-binding require()"
```

### 6.2 Global Variable Tracking

Track global assignments across the workspace. If the same global is written in
two different files, warn:

```lua
-- in enemy.lua
HP = 100        -- ⚠ Global write: 'HP' also written in player.lua
                -- "Avoid implicit globals. Use local or pass as parameter."
```

### 6.3 Asset Reference Validation (Enhanced)

Build an asset index at activation. Paths found in `luna.graphics.newImage()`,
`luna.audio.newSource()`, and `luna.filesystem.read()` are validated against the real
filesystem. Results cached and updated on file save.

Additional: detect **unused assets** — files in `assets/` that are never referenced.

### 6.4 Symbol Index for Find All References

A persistent workspace index maps every symbol to its definition site and all
reference locations. Updated incrementally on file change. Enables:
- `Shift+F12` (Find All References) — workspace-wide in < 50ms
- Rename symbol (`F2`) — renames across all `.lua` files
- Unused symbol detection (functions defined but never called)

---

## 7. Code Actions (Extended)

| Trigger | Code Action | Kind |
|---|---|---|
| Unused require | Remove unused `local x = require(...)` | `quickfix` |
| Missing callbacks | Generate `luna.load/update/draw` stubs | `quickfix` |
| 0-255 color | Convert to 0-1 float range | `quickfix` |
| `luna.*` API call | Migrate to `luna.*` equivalent | `quickfix` |
| Pattern snippet inserted | Copy typed stub to `lib/` | `refactor` |
| Global variable | Convert to `local` | `refactor.rewrite` |
| Function body | Extract to local function | `refactor.extract` |
| Function body | Extract to new file module | `refactor.extract` |
| Variable | Inline single-use variable | `refactor.inline` |
| `if/elseif` chain | Convert to state-map pattern | `refactor.rewrite` |
| `table.create` in hot path | Wrap in object pool | `refactor.rewrite` |
| Unprotected `require()` | Wrap in pcall | `quickfix` |
| Missing `---@type` | Add LuaCATS type annotation | `refactor.rewrite` |
| Multiple-file class | Generate `__tostring` metamethod | `quickfix` |
| `luna.*` callback name | Add migration note | `quickfix` |

---

## 8. Hover Enhancements

### 8.1 Hover on Color Values

When hovering over `{0.2, 0.8, 1.0, 1.0}` or `luna.graphics.setColor(r, g, b)`:
- Show an inline color swatch
- Show both 0-1 and 0-255 representations
- Suggest named palette color if close match is found

### 8.2 Hover on Math Constants
```lua
math.pi   -- Shows: "3.141592653589793 (π)" + note about luna.math.pi
math.huge -- Shows: "+infinity overflow sentinel"
```

### 8.3 Hover on Physics Values
```lua
-- When hovering a number in physics context:
luna.physics.newWorld(0, 200)
--                       ^^^
-- Hover: "Gravity Y = 200 px/s². Earth = ~980 px/s² (at 1px=1cm scale)"
```

### 8.4 Hover on Deprecated API
```lua
luna.graphics.drawImage(img, x, y)
-- ⚠ Deprecated since v0.3.0
-- Use: luna.graphics.draw(img, x, y) instead
-- See: migration guide
```

---

## 9. IntelliSense Settings

Additional configuration properties for the enhanced IntelliSense layer:

```jsonc
"luna.intellisense.luajitHints": {
  "type": "boolean", "default": true,
  "description": "Show LuaJIT performance optimization hints"
},
"luna.intellisense.patternLibrary": {
  "type": "boolean", "default": true,
  "description": "Offer pattern library snippets (state machine, pool, etc.)"
},
"luna.intellisense.keyNameCompletion": {
  "type": "boolean", "default": true,
  "description": "Show key name completions inside input API string arguments"
},
"luna.intellisense.easingHoverChart": {
  "type": "boolean", "default": true,
  "description": "Show easing curve ASCII chart on hover"
},
"luna.intellisense.typeInference": {
  "type": "boolean", "default": true,
  "description": "Track return types from luna.* factories for method completion"
},
"luna.intellisense.globalWarnings": {
  "type": "boolean", "default": true,
  "description": "Warn on implicit global variable writes"
},
"luna.intellisense.unusedAssets": {
  "type": "boolean", "default": false,
  "description": "Detect asset files that are never referenced (slow on large projects)"
},
"luna.intellisense.classPatternDetection": {
  "type": "boolean", "default": true,
  "description": "Detect OOP class patterns and enable method completion on instances"
}
```

---

## 10. New Provider: `providers/luajitHints.ts`

Dedicated provider for LuaJIT-specific warnings. Only active when `luna.intellisense.luajitHints` is true.

Runs as a diagnostics provider with source `luajit` and severity `Hint`.
Uses a simple AST walk (no full parser) to detect:
- Table allocations inside `luna.update`/`luna.draw` function bodies
- String concat in loops
- Global variable reads inside loops (suggest local cache)
- The `pcall` trace-interruption pattern

These hints are suppressed with `---@luajit-ok` inline comment, similar to
ESLint's `eslint-disable-line`.

---

## Summary: Provider Count Expansion

| Provider | Status | Sub-systems |
|---|---|---|
| completion | Enhanced | + contextual string values, + type-inferred methods |
| hover | Enhanced | + color swatch, + easing chart, + physics hints |
| signature | Unchanged | — |
| definition | Enhanced | + symbol index, + OOP method definitions |
| references | Enhanced | + workspace index, + rename support |
| diagnostics | Enhanced | + luajit rules, + global writes, + circular deps |
| symbols | Enhanced | + class methods in outline |
| color | Unchanged | — |
| assetPath | Enhanced | + unused asset detection |
| inlayHints | Enhanced | + callback param types |
| codeActions | Massively expanded | + 12 new actions |
| **luajitHints** | **NEW** | LuaJIT performance & correctness |
| **typeInference** | **NEW** | Return type tracking, OOP pattern detection |
| **requireGraph** | **NEW** | Workspace-level require analysis |
