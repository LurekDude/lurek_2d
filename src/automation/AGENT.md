# `automation` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Engine Extension (Implemented) |
| **Lua namespace** | `luna.simulator` |
| **Source** | `src/automation/` |
| **Lua API** | `src/lua_api/automation_api.rs` |
| **Rust tests** | `tests/unit/automation_tests.rs` (49 tests) |
| **Lua BDD tests** | `tests/lua/unit/test_automation.lua` (62 tests) |
| **Example** | `examples/automation_demo/` |

## Summary

Automated input simulation via timed step scripts. The `Simulator` loads
named `Script` objects — each containing an ordered list of `Step` records —
and plays them back by injecting synthetic input events into the Luna2D event
queue on each `update(dt)` call.

A `Step` records a wall-clock offset in seconds from script start, an
`Action` variant (keypress, keyrelease, mousemove, mousepress, mouserelease,
mousewheel, textinput, or wait), and action-specific optional fields
(key, scancode, x, y, dx, dy, button, text, isRepeat, clicks).

Scripts are loaded as Lua tables or from TOML files via the `loadFile`/
`loadFromToml` helpers. Multiple scripts can be registered simultaneously;
`start(name)` selects which one plays. Step count is capped at 100,000 per
script (CSF-010 unbounded allocation guard).

Primary use-cases: headless integration tests, QA regression replay,
speedrun verification, and recorded developer input sessions.

## Architecture

```
Simulator (script playback engine)
  │
  ├── scripts: HashMap<name, Script>
  │     └── Script
  │           ├── description: Option<String>
  │           └── steps: Vec<Step>  (sorted by time, capped at 100k)
  │                 └── Step { time, action, key/x/y/button/text/... }
  │
  ├── active_script: Option<String>
  ├── elapsed: f32
  ├── next_step_idx: usize
  ├── state: PlaybackState (Idle / Running / Paused / Complete)
  │
  └── update(dt) [runs only in Running state]
        ├── elapsed += dt
        ├── while steps[next_step_idx].time <= elapsed → dispatch
        └── dispatch → push synthetic Event into EventQueue
              (event names: keypressed / keyreleased / mousemoved /
               mousepressed / mousereleased / wheelmoved / textinput)

Runtime dependencies:
  - crate::event::EventQueue  (step dispatch target)
  - luna.data.parseToml       (TOML parsing in Lua helpers)
  - luna.filesystem.read      (file reading in loadFile helper)
```

## Module Structure

| File | Type | Role |
|---|---|---|
| `mod.rs` | Rust module root | Re-exports `Action`, `Step`, `Script`, `Simulator` |
| `step.rs` | `Action` enum + `Step` struct | 8 action variants; 12-field step record |
| `script.rs` | `Script` struct | Named, sorted, capacity-capped step container |
| `simulator.rs` | `Simulator` struct | Playback engine with `PlaybackState` state machine |

## PlaybackState Transitions

| From | To | Trigger |
|---|---|---|
| `Idle` | `Running` | `start(name)` with a loaded script |
| `Running` | `Paused` | `pause()` |
| `Paused` | `Running` | `resume()` |
| `Running` | `Complete` | last step dispatched during `update(dt)` |
| Any | `Idle` | `stop()`, or active script unloaded |

## Lua API — `luna.simulator`

### Script Management

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `load` | `name: string, data: table` | `nil` | Load a script from a Lua step table. Table must have a `steps` array |
| `unload` | `name: string` | `boolean` | Remove a loaded script. Returns `true` if it existed |
| `hasScript` | `name: string` | `boolean` | Return `true` if a script is registered |
| `getScripts` | — | `table<string>` | Return an array of all registered script names |
| `loadFromToml` | `name: string, toml: string` | `nil` | Parse a TOML string and load as a script |
| `loadFile` | `path: string [, name: string]` | `nil` | Read a TOML file and load as a script. Name defaults to `meta.name` or path |

### Playback Control

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `start` | `name: string` | `nil` | Start playback from step zero. Errors if script not loaded |
| `stop` | — | `nil` | Stop playback and reset to Idle |
| `pause` | — | `nil` | Pause at the current elapsed position |
| `resume` | — | `nil` | Resume from a paused position |
| `update` | `dt: number` | `nil` | Advance clock by `dt`. Dispatches all steps with `time <= elapsed` |

### Playback State

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `isRunning` | — | `boolean` | `true` when in Running state |
| `isPaused` | — | `boolean` | `true` when in Paused state |
| `isComplete` | — | `boolean` | `true` when all steps have been dispatched |
| `getCurrentStep` | — | `number` | Index of the next step to fire (0-based) |
| `getStepCount` | — | `number` | Total steps in the active script |
| `getCurrentScript` | — | `string \| nil` | Name of the active script, or `nil` |
| `getElapsedTime` | — | `number` | Seconds elapsed since the most recent `start()` call |

## Action Variants

| String | Description | Required fields | Optional fields |
|---|---|---|---|
| `"keypress"` | Simulate `keypressed` event | — | `key`, `scancode`, `isRepeat` |
| `"keyrelease"` | Simulate `keyreleased` event | — | `key`, `scancode` |
| `"mousemove"` | Simulate `mousemoved` event | — | `x`, `y`, `dx`, `dy` |
| `"mousepress"` | Simulate `mousepressed` event | — | `x`, `y`, `button`, `clicks` |
| `"mouserelease"` | Simulate `mousereleased` event | — | `x`, `y`, `button` |
| `"mousewheel"` | Simulate `wheelmoved` event | — | `dx`, `dy` |
| `"textinput"` | Simulate `textinput` event | — | `text` |
| `"wait"` | No-op timed delay | — | — |

**Note:** `Action::parse_action()` is case-sensitive. All action strings must be lowercase.

## Step Table Format

```lua
-- All fields except `action` are optional and default as noted
{
    time     = 1.5,        -- seconds from script start (default 0.0)
    action   = "keypress", -- required: one of the 8 action strings above
    key      = "space",    -- key name (keypress/keyrelease; used as scancode fallback)
    scancode = "space",    -- scancode override (keypress/keyrelease)
    x        = 400,        -- mouse X position (mousemove/mousepress/mouserelease)
    y        = 300,        -- mouse Y position
    dx       = 10,         -- X delta (mousemove/mousewheel)
    dy       = -5,         -- Y delta (mousemove/mousewheel)
    button   = 1,          -- mouse button index 1=left, 2=right, 3=middle (default 1)
    text     = "hello",    -- text string (textinput)
    isRepeat = false,       -- key-repeat flag (keypress, default false)
    clicks   = 1            -- consecutive click count (mousepress, default 1)
}
```

## Script Table Format

```lua
{
    meta  = { description = "optional human-readable script description" },
    steps = {
        { time = 0.0, action = "keypress",    key = "space" },
        { time = 0.5, action = "mousemove",   x = 200, y = 150 },
        { time = 1.0, action = "mousepress",  x = 200, y = 150, button = 1 },
        { time = 1.1, action = "mouserelease",x = 200, y = 150, button = 1 },
        { time = 2.0, action = "wait" },
    }
}
```

## TOML Script Format

```toml
[meta]
description = "Navigate to play button and click"

[[steps]]
time   = 0.5
action = "mousemove"
x      = 200
y      = 150

[[steps]]
time   = 1.0
action = "mousepress"
x      = 200
y      = 150
button = 1
```

**Note:** Use level-1 long-string delimiters `[=[ ]=]` in Lua when embedding TOML that contains `[[steps]]` — the double-bracket would otherwise end the Lua long string.

## Usage Example

```lua
-- Load and start a script
luna.simulator.load("test_menu", {
    meta  = { description = "Click the play button" },
    steps = {
        { time = 0.1, action = "mousemove",   x = 400, y = 300 },
        { time = 0.5, action = "mousepress",  x = 400, y = 300, button = 1 },
        { time = 0.6, action = "mouserelease",x = 400, y = 300, button = 1 },
        { time = 1.0, action = "keypress",    key = "escape" },
    }
})
luna.simulator.start("test_menu")

function luna.update(dt)
    luna.simulator.update(dt)
    if luna.simulator.isComplete() then
        luna.simulator.stop()
        print("Simulation complete after", luna.simulator.getElapsedTime(), "s")
    end
end
```

### Loading from a TOML file

```lua
-- Uses luna.data.parseToml and luna.filesystem.read internally
luna.simulator.loadFile("scripts/intro.toml")
-- or with an explicit name override:
luna.simulator.loadFile("scripts/intro.toml", "intro_v2")
```

## Implementation Notes

- **`Rc<RefCell<Simulator>>`**: A single `Simulator` instance is created at `register()` time and shared across all 15 Rust closures via `Rc` clone. Borrow the `RefCell` only for the duration of each operation.
- **mlua 0.9 generics**: All `table.get` calls require both type parameters: `table.get::<_, T>("key")`.
- **Lua helpers**: `loadFromToml` and `loadFile` are implemented as Lua closures (not Rust functions) injected via `lua.load(chunk).eval::<LuaFunction>()` so they can call other `luna.*` API functions.
- **TOML parsing**: Uses `luna.data.parseToml` (NOT `decodeToml`). The actual call sequence inside `loadFromToml` is `luna.data.parseToml(toml_string)`.
- **Registration order**: `automation_api::register()` MUST appear after `data_api::register()` and `filesystem_api::register()` in `src/lua_api/mod.rs` because the Lua helpers call those APIs.
- **Event dispatch names**: "keypressed", "keyreleased", "mousemoved", "mousepressed", "mousereleased", "wheelmoved", "textinput".
- **MAX_STEPS = 100_000**: Defined in `src/automation/script.rs`. Enforced at `Script::new()` time (truncate after sort).

## Module Boundaries

**vs `luna.keyboard` / `luna.mouse`**: Those modules read real hardware input. `luna.simulator` injects synthetic events into the same `EventQueue`. Injected events are indistinguishable from real input to the game script.

**vs `luna.event`**: `luna.event` is the raw event queue. `luna.simulator.update()` pushes events *into* the queue — it does not replace or intercept real events.

**vs `luna.thread`**: Scripts run synchronously on the Lua thread. For long-running replays that should not block the game loop, wrap the simulator in a `luna.thread` worker (advanced usage).

## Quality Gates

Before merge:
1. `cargo test --test automation_tests` — all 49 Rust tests pass
2. `cargo test lua_test_automation` — all 62 Lua BDD tests pass
3. `cargo clippy -- -D warnings` — 0 warnings
4. `python tools/collect_docs.py --report-missing` — 0 undocumented public items
