# `scene` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.scene`                                         |
| **Source**      | `src/scene/`                                         |
| **Rust Tests** | `tests/rust/unit/scene_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_scene.lua`                      |

## Summary

The scene module implements a push-down automaton for game state management — the
industry-standard pattern for navigating between a game's distinct modes (title
screen, main gameplay, pause menu, inventory screen, game-over). Scenes are
pushed onto a LIFO stack; the top scene receives `process(dt)` calls each frame;
`render()` dispatches to every scene bottom-to-top so that overlay scenes (pause
menus, HUDs) render on top of their parent. Popping a scene returns control to
the one below it, with its full state intact.

Ten lifecycle callbacks are supported per scene table: `enter`, `leave`, `pause`,
`resume`, `ready`, `update` (legacy), `draw` (legacy), `process`, `process_physics`,
`process_late`, `render`, and `render_ui`. `ready` fires exactly once after `enter`,
on the first `lurek.scene.process()` tick — tracked per-scene by
`SceneState.scene_ready_pending`. The stack automatically calls `pause` on the
outgoing top scene when a new scene is pushed, and `resume` when it is revealed
again by a pop. `enter` and `leave` bookend the entire lifetime of a scene on the
stack. Both `push` and `switchTo` accept an optional `params` argument that is
forwarded to the incoming scene's `enter(self, params)` callback, enabling
data flow between scenes without globals. All callbacks are optional — scenes
may implement only the methods they need; missing methods are silently skipped.

Animated visual transitions (fade, slide-left, slide-right, slide-up, slide-down)
bridge between states so scene changes feel intentional. Transition progress is
exposed via `getTransitionProgress()` for custom rendering effects.

A named registry allows scenes to be registered at startup and later pushed by
name via `popTo`, supporting reusable scene definitions. An inter-scene key-value
data store (`setData`/`getData`/`hasData`/`removeData`) lets scenes share
arbitrary Lua values without polluting globals.

The `DepthSorter` is a standalone per-frame draw batcher that collects draw
callbacks with numeric depth values, stable-sorts them ascending, and flushes
them in order. It supports both plain function callbacks and object tables with a
`:drawSorted()` method, enabling z-ordered rendering within a single scene's draw
pass without manual sort logic.

The module intentionally does NOT own rendering, input handling, or physics — it
is purely a lifecycle and ordering coordinator. Scenes are Lua tables with
optional method keys; the module imposes no base class or inheritance hierarchy.

## Architecture

```
lurek.scene (Lua API — scene_api.rs)
  │
  ├── SceneState (API-layer internal state)
  │     ├── stack: SceneStack          ← Rust-side LIFO stack
  │     ├── scene_refs: HashMap<SceneId, RegistryKey>
  │     │     └── maps Rust IDs → Lua tables stored in registry
  │     ├── data_refs: HashMap<String, RegistryKey>
  │     │     └── maps data keys → Lua values in registry
  │     └── scene_ready_pending: HashSet<SceneId>
  │           └── scenes whose `ready` callback has not yet fired
  │
  ├── SceneStack (src/scene/stack.rs)
  │     ├── stack: Vec<SceneId>        ← ordered bottom-to-top
  │     ├── registry: HashMap<String, SceneId>
  │     ├── data_keys: HashMap<String, SceneId>
  │     ├── transition: Option<ActiveTransition>
  │     └── next_id: u64               ← monotonic ID generator
  │
  ├── ActiveTransition (src/scene/transition.rs)
  │     ├── transition_type: TransitionType
  │     ├── duration: f32
  │     └── elapsed: f32
  │
  ├── TransitionType (src/scene/transition.rs)
  │     └── None | Fade | SlideLeft | SlideRight | SlideUp | SlideDown
  │
  └── DepthSorter (src/scene/depth_sorter.rs)
        ├── entries: Vec<DepthEntry>
        └── DepthEntry { depth, callback_index, is_object }
```

### Lifecycle Call Flow

```
push(scene_b)           pop()                   switchTo(scene_c)
  │                       │                       │
  ├─ prev.pause()         ├─ top.leave()          ├─ top.leave()
  ├─ stack.push(b)        ├─ stack.pop()          ├─ stack.pop() + push(c)
  ├─ b.enter(params)      └─ revealed.resume()    └─ c.enter(params)
  └─ b added to ready_pending

First lurek.scene.process(dt) after enter:
  ready_pending.remove(b) → b:ready()   [only once per push]
  → b:process(dt)

Subsequent lurek.scene.process(dt) calls:
  → b:process(dt)          [ready is NOT called again]
```

### Per-Frame Pipeline Callbacks

```
lurek.scene.processPhysics(fixed_dt)  → top scene:process_physics(fixed_dt)
lurek.scene.process(dt)               → [first tick: ready()] then top scene:process(dt)
lurek.scene.processLate(dt)           → top scene:process_late(dt)
lurek.scene.render()                  → ALL scenes (bottom→top): scene:render()
lurek.scene.renderUi()                → ALL scenes (bottom→top): scene:render_ui()
```

## Source Files

| File              | Purpose                                                        |
|-------------------|----------------------------------------------------------------|
| `mod.rs`          | Module declaration, re-exports `SceneStack`, `ActiveTransition`, `TransitionType`, `DepthSorter` |
| `stack.rs`        | LIFO scene stack with named registry, inter-scene data store, and transition integration |
| `transition.rs`   | `TransitionType` enum with Lua string parsing, `ActiveTransition` timer with progress tracking |
| `depth_sorter.rs` | Per-frame depth-sorted draw batcher with function and object callback support |

## Submodules

### `scene::stack`

LIFO scene stack with registry and inter-scene data store.

- **`SceneId`** (type alias): `u64` — unique identifier for a scene in the stack, allocated monotonically by `next_scene_id()`.
- **`SceneStack`** (struct): The core push-down automaton. Manages a `Vec<SceneId>` stack, a `HashMap<String, SceneId>` named registry, a `HashMap<String, SceneId>` data store, and an `Option<ActiveTransition>` for visual transitions. Provides `push`, `pop`, `switch_to`, `clear`, `pop_to`, `pop_until`, registry CRUD, data CRUD, and transition query/update methods.

### `scene::transition`

Visual transition types and active transition state for scene changes.

- **`TransitionType`** (enum): Six variants controlling how scenes visually transition — `None` (instant), `Fade` (crossfade), `SlideLeft`, `SlideRight`, `SlideUp`, `SlideDown`. Parsed from Lua strings via `from_lua_str`.
- **`ActiveTransition`** (struct): Tracks an in-progress transition with `transition_type`, `duration`, and `elapsed` fields. Provides `progress()` (normalized 0–1, clamped), `is_complete()`, and `update(dt)`.

### `scene::depth_sorter`

Per-frame depth-sorted draw batcher.

- **`DepthEntry`** (struct): A single entry with `depth: f32`, `callback_index: usize`, and `is_object: bool`. Lower depth values draw first.
- **`DepthSorter`** (struct): Collects `DepthEntry` items, stable-sorts by ascending depth, and provides `sorted_entries()` for external processing. Supports both plain callbacks (`add`) and object tables with `:drawSorted()` methods (`add_object`).

## Key Types

### Structs

#### `scene::stack::SceneStack`

The core scene management structure. Maintains a LIFO stack of `SceneId` values,
a named registry mapping string names to scene IDs, an inter-scene data store,
and an optional active transition. The Lua API layer maps each `SceneId` to a Lua
table stored in the mlua registry. All stack operations return the affected scene
IDs so the API layer can invoke the correct lifecycle callbacks.

**Key methods**: `new()`, `next_scene_id()`, `push()`, `pop()`, `switch_to()`,
`clear()`, `pop_to()`, `pop_until()`, `get_stack_size()`, `is_empty()`,
`get_current()`, `get_all()`, `is_transitioning()`, `get_transition_progress()`,
`update_transition()`, `register_scene()`, `get_registered()`, `has_registered()`,
`unregister_scene()`, `get_registered_names()`, `set_data()`, `get_data()`,
`has_data()`, `remove_data()`.

#### `scene::transition::ActiveTransition`

Tracks a visual transition in progress. Stores the transition type, total
duration, and elapsed time. `progress()` returns a normalized value clamped
to [0, 1]. `is_complete()` returns true once elapsed >= duration. `update(dt)`
advances the timer by delta seconds.

#### `scene::depth_sorter::DepthEntry`

A single draw entry in the depth queue. Fields: `depth` (sort key, lower = first),
`callback_index` (index into an external callback storage managed by the Lua API
layer), `is_object` (if true, the callback is a table with a `:drawSorted()` method
rather than a plain function).

#### `scene::depth_sorter::DepthSorter`

Per-frame draw batcher. Collects entries via `add()` and `add_object()`,
stable-sorts them by ascending depth via `sort()` or `sorted_entries()`,
and exposes the sorted slice for the Lua API layer to invoke callbacks.
`clear()` resets for the next frame. Implements `Default`.

### Enums

#### `scene::transition::TransitionType`

Visual transition types between scenes. Derives `Debug`, `Clone`, `Copy`, `PartialEq`.

| Variant      | Description                             |
|--------------|-----------------------------------------|
| `None`       | Instant switch, no animation            |
| `Fade`       | Crossfade between outgoing and incoming |
| `SlideLeft`  | New scene slides in from the right      |
| `SlideRight` | New scene slides in from the left       |
| `SlideUp`    | New scene slides in from the bottom     |
| `SlideDown`  | New scene slides in from the top        |

Parsed from Lua strings via `from_lua_str()`: `"fade"`, `"slideleft"`, `"slideright"`, `"slideup"`, `"slidedown"`. Unknown strings map to `None`.

## Lua API

Registered in `src/lua_api/scene_api.rs`. The module creates a private `SceneState`
(not part of `SharedState`) containing a `SceneStack`, a `scene_refs` map of
`SceneId → LuaRegistryKey` (Lua scene tables), and a `data_refs` map of
`String → LuaRegistryKey` (inter-scene data values). The `LuaDepthSorter` UserData
wraps a `DepthSorter` plus a `Vec<LuaRegistryKey>` for callback storage.

### Scene Factory

Two convenience helpers let you define scenes without manual `__index` boilerplate:

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.scene.new` | `(def: table) → table` | Create a scene **instance** directly from a methods table — equivalent to `setmetatable({}, {__index = def})` |
| `lurek.scene.define` | `(def: table) → function` | Create a reusable scene **class** — returns a zero-argument constructor that produces fresh instances sharing `def` as their metatable |

**`lurek.scene.define` pattern (recommended for reusable scenes):**

```lua
-- Define a class once
local GameScene = lurek.scene.define({})

function GameScene:ready()   self.score = 0 end
function GameScene:process(dt) ... end
function GameScene:render()    ... end

-- Instantiate with ()
lurek.scene.push(GameScene())
lurek.scene.switchTo(GameScene(), nil, 0.5, nil)
```

**`lurek.scene.new` pattern (for one-off or inline scenes):**

```lua
lurek.scene.push(lurek.scene.new({
    ready   = function(self) ... end,
    process = function(self, dt) ... end,
    render  = function(self) ... end,
}))
```

### Stack Operations

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.scene.push` | `(scene, transition?, duration?, params?)` | Push a scene table; calls `prev:pause()` then `scene:enter(params)`; marks scene for `ready` on next `process` |
| `lurek.scene.pop` | `(transition?, duration?)` | Pop top scene; calls `top:leave()` then `revealed:resume()` |
| `lurek.scene.switchTo` | `(scene, transition?, duration?, params?)` | Replace top scene; calls `old:leave()` then `scene:enter(params)`; marks new scene for `ready` |
| `lurek.scene.clear` | `()` | Remove all scenes, calling `leave()` on each |
| `lurek.scene.popTo` | `(name) → boolean` | Pop until named registered scene is on top; returns false if not found |
| `lurek.scene.update` | `(dt)` | Update transition timer and call `top:update(dt)` *(legacy — prefer `process`)* |
| `lurek.scene.draw` | `()` | Call `draw()` on every scene bottom-to-top *(legacy — prefer `render`)* |

### Pipeline Dispatch

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.scene.process` | `(dt: number)` | Fire `scene:ready(self)` once on first tick after push/switchTo, then call `scene:process(dt)` on the top scene |
| `lurek.scene.processPhysics` | `(dt: number)` | Call `scene:process_physics(dt)` on the top scene (fixed timestep) |
| `lurek.scene.processLate` | `(dt: number)` | Call `scene:process_late(dt)` on the top scene (after `process`, before `render`) |
| `lurek.scene.render` | `()` | Call `scene:render(self)` on **all** scenes bottom-to-top |
| `lurek.scene.renderUi` | `()` | Call `scene:render_ui(self)` on **all** scenes bottom-to-top (UI/HUD overlay) |

### Stack Query

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.scene.getStackSize` | `() → integer` | Number of scenes on the stack |
| `lurek.scene.isEmpty` | `() → boolean` | Whether the stack has no scenes |
| `lurek.scene.getCurrent` | `() → table?` | Top scene table, or nil if empty |

### Transitions

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.scene.isTransitioning` | `() → boolean` | Whether a transition is active |
| `lurek.scene.getTransitionProgress` | `() → number` | Progress from 0.0 to 1.0 |

### Registry

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.scene.registerScene` | `(name, scene)` | Register a scene table by name |
| `lurek.scene.getRegistered` | `(name) → table?` | Get a registered scene by name |
| `lurek.scene.hasRegistered` | `(name) → boolean` | Check if a name is registered |
| `lurek.scene.unregisterScene` | `(name)` | Remove a scene from the registry |
| `lurek.scene.getRegisteredNames` | `() → table` | List all registered scene names |

### Data Store

| Function | Signature | Description |
|----------|-----------|-------------|
| `lurek.scene.setData` | `(key, value)` | Store a value by string key |
| `lurek.scene.getData` | `(key) → any?` | Retrieve a value by key, or nil |
| `lurek.scene.hasData` | `(key) → boolean` | Check if a key exists |
| `lurek.scene.removeData` | `(key)` | Delete a key-value pair |

### Scene Callback Contract

A scene is any Lua table. All methods below are **optional** — missing methods
are silently skipped. Implement only what your scene needs.

| Method | Called when |
|--------|-------------|
| `scene:enter(params)` | Scene is pushed or switched to (params may be nil) |
| `scene:leave()` | Scene is popped or replaced by switchTo |
| `scene:pause()` | A new scene is pushed on top of this one |
| `scene:resume()` | The scene above this one is popped |
| `scene:ready()` | First `lurek.scene.process()` tick after enter (once per push) |
| `scene:process(dt)` | Every frame via `lurek.scene.process(dt)` |
| `scene:process_physics(dt)` | Fixed timestep via `lurek.scene.processPhysics(dt)` |
| `scene:process_late(dt)` | After process, before render via `lurek.scene.processLate(dt)` |
| `scene:render()` | Every frame via `lurek.scene.render()` — all scenes |
| `scene:render_ui()` | Every frame via `lurek.scene.renderUi()` — UI overlay, all scenes |
| `scene:update(dt)` | Legacy; via `lurek.scene.update(dt)` — top scene only |
| `scene:draw()` | Legacy; via `lurek.scene.draw()` — all scenes |

### Factory

| Function | Signature | Description |
|--------|-----------|-------------|
| `lurek.scene.newDepthSorter` | `() → DepthSorter` | Create a new depth-sorted draw batcher |

| Method | Signature | Description |
|--------|-----------|-------------|
| `sorter:add` | `(callback, depth)` | Register a draw callback at a depth layer |
| `sorter:addObject` | `(obj)` | Register a table with `:drawSorted()` at `obj.depth` |
| `sorter:sort` | `()` | Sort all entries by ascending depth |
| `sorter:flush` | `()` | Sort, invoke all callbacks in order, then clear |
| `sorter:clear` | `()` | Remove all entries without invoking them |
| `sorter:getCount` | `() → integer` | Number of queued entries |

## Lua Examples

### Basic scene stack with lifecycle callbacks

```lua
local menu = {
    enter  = function(self, params)
        print("Menu entered")
    end,
    leave  = function(self) print("Menu left") end,
    ready  = function(self) print("Menu ready — one-time setup") end,
    process = function(self, dt) end,
    render  = function(self)
        lurek.gfx.print("Main Menu - Press Enter", 100, 100)
    end,
    render_ui = function(self)
        lurek.gfx.print("[Press Enter to start]", 100, 130)
    end,
}

local game = {
    enter  = function(self, params)
        self.level = params and params.level or 1
    end,
    pause  = function(self) print("Game paused") end,
    resume = function(self) print("Game resumed") end,
    leave  = function(self) print("Game over") end,
    ready  = function(self)
        -- called once after enter, before first process tick
        print("Game ready — spawning entities")
    end,
    process            = function(self, dt) end,
    process_physics    = function(self, dt) end,
    process_late       = function(self, dt) end,
    render             = function(self)
        lurek.gfx.print("Level " .. self.level, 100, 100)
    end,
    render_ui          = function(self)
        lurek.gfx.print("HUD", 10, 10)
    end,
}

function lurek.init()
    lurek.scene.push(menu)
end

function lurek.process_physics(dt)
    lurek.scene.processPhysics(dt)
end

function lurek.process(dt)
    lurek.scene.process(dt)
end

function lurek.process_late(dt)
    lurek.scene.processLate(dt)
end

function lurek.render()
    lurek.scene.render()
end

function lurek.render_ui()
    lurek.scene.renderUi()
end

function lurek.keypressed(key)
    if key == "return" then
        lurek.scene.switchTo(game, "fade", 0.5, { level = 1 })
    elseif key == "escape" then
        lurek.scene.pop("slideleft", 0.3)
    end
end
```

### Depth-sorted rendering

```lua
local sorter = lurek.scene.newDepthSorter()

function lurek.render()
    -- Add draw calls at different depths (lower = drawn first)
    sorter:add(function() lurek.gfx.print("Background", 0, 0) end, 0)
    sorter:add(function() lurek.gfx.print("Player", 100, 100) end, 50)
    sorter:add(function() lurek.gfx.print("UI", 200, 10) end, 100)

    -- Flush invokes them in depth order: 0, 50, 100
    sorter:flush()
end
```

### Named registry and inter-scene data

```lua
function lurek.init()
    lurek.scene.registerScene("menu", {
        enter = function(self) end,
        draw  = function(self)
            lurek.gfx.print("Menu", 10, 10)
        end,
    })

    -- Share data between scenes
    lurek.scene.setData("highscore", 0)

    -- Push by reference (popTo uses registry names)
    lurek.scene.push(lurek.scene.getRegistered("menu"))
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `type`     | 1     |
| `struct`   | 4     |
| `enum`     | 1     |
| `fn`       | 36    |
| **Total**  | **42**|

## References

| Module       | Relationship | Notes                                                    |
|--------------|--------------|----------------------------------------------------------|
| `engine`     | Imports from | Uses `log_messages` constants for structured logging     |
| `lua_api`    | Imported by  | `scene_api.rs` binds `SceneStack`, `DepthSorter`, `TransitionType` to Lua |
| `math`       | None         | No direct dependency — scene module is logic-only        |
| `graphics`   | None         | Scenes call draw functions via Lua callbacks, not Rust imports |
| `particle`   | Similar      | Both are Tier 2; particle owns visual effects, scene owns state lifecycle |
| `tilemap`    | Similar      | Both are Tier 2; tilemap owns map data, scene owns navigation between game states |

## Notes

- **No SharedState dependency**: Unlike most modules, the scene API maintains its own private `SceneState` via `Rc<RefCell<SceneState>>` rather than using `SharedState`. This is because scene data (Lua table registry keys) is tightly coupled to the Lua VM lifetime and would add unnecessary complexity to `SharedState`.
- **Scene tables are Lua-owned**: The Rust `SceneStack` only stores `SceneId` integers. Actual Lua scene tables are held in the mlua registry via `LuaRegistryKey`. This means scene state survives garbage collection as long as the scene is on the stack or in the registry.
- **Lifecycle callback invocation order**: `push` calls `prev:pause()` before `new:enter(params)`. `pop` calls `top:leave()` before `revealed:resume()`. `switchTo` calls `old:leave()` before `new:enter(params)`. `clear` calls `leave()` on every scene. All callbacks are optional — missing methods are silently skipped.
- **Transition types are string-matched**: `from_lua_str` is case-sensitive and maps unknown strings to `TransitionType::None`. Valid strings: `"fade"`, `"slideleft"`, `"slideright"`, `"slideup"`, `"slidedown"`.
- **DepthSorter is per-frame**: The sorter is designed to be populated during `draw()`, flushed once, and cleared. Callbacks are stored as `LuaRegistryKey` values and released after flush. Do not carry entries across frames.
- **draw() dispatches to all scenes**: Unlike `update()` which only calls the top scene, `draw()` iterates every scene in the stack bottom-to-top. This enables overlay patterns (e.g., a pause menu drawn over gameplay).
- **Data store values are Lua-typed**: `setData`/`getData` accept any Lua value (number, string, table, boolean, nil). The Rust side stores only `SceneId` references; actual values live in the mlua registry.
- **Transition rendering is the caller's responsibility**: The module tracks transition progress but does not render transition effects itself. Games should read `getTransitionProgress()` and apply their own visual effects (alpha fade, position offset, etc.).
