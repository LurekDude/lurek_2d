# `automation` — Agent Reference

| Property       | Value                                        |
|----------------|----------------------------------------------|
| **Tier**       | Tier 2 — Engine Extensions                   |
| **Status**     | Implemented — Full                           |
| **Lua API**    | `luna.simulator`                             |
| **Source**      | `src/automation/`                            |
| **Rust Tests** | `tests/rust/unit/automation_tests.rs`        |
| **Lua Tests**  | `tests/lua/unit/test_automation.lua`         |
| **Architecture** | —                                          |

## Summary

The `automation` module provides automated input simulation through timed step scripts. It is a Tier 2 Engine Extension that depends on `crate::engine` (Baseline) and `crate::event` (Tier 1). It does not depend on `crate::math`.

A `Script` contains an ordered list of `Step` records, each pairing a wall-clock offset (seconds from script start) with an `Action` variant — one of eight kinds: `KeyPress`, `KeyRelease`, `TextInput`, `MouseMove`, `MousePress`, `MouseRelease`, `MouseWheel`, and `Wait`. The `Simulator` plays back a loaded script by comparing elapsed game time against each step's timestamp and injecting the corresponding synthetic event into the engine's `EventQueue`. Injected events are indistinguishable from real hardware input as far as the game is concerned.

Primary use-cases are headless integration tests, QA regression replay, speedrun verification, and recorded developer input sessions. Scripts are loaded from Lua tables via `luna.simulator.load` and can be replayed multiple times. The `Simulator` owns a named registry of scripts; loading a script with an existing name replaces the previous one. Steps beyond `MAX_STEPS` (100 000) are silently truncated to cap memory at roughly 12 MB per script (CSF-010 allocation guard).

The `Simulator` follows a strict playback lifecycle: `Idle → Running → Complete`, with optional `Paused` transitions. Stopping resets elapsed time and step index. The module only injects events into the `EventQueue`; it does not consume them. Actual input handling remains in `src/input/`. The `Simulator` is not `Send` or `Sync` — it is owned by the main Lua thread via `Rc<RefCell<Simulator>>`.

## Architecture

```
                        Lua game script
                              │
                 luna.simulator.load("demo", data)
                 luna.simulator.start("demo")
                              │
                              ▼
                   ┌──────────────────┐
                   │  automation_api  │  (bridge — src/lua_api/)
                   │  parse_steps()   │
                   └────────┬─────────┘
                            │ constructs Script from Lua tables
                            ▼
              ┌──────────────────────────┐
              │       Simulator          │  (simulator.rs)
              │  ┌────────────────────┐  │
              │  │ scripts: HashMap   │  │  named script registry
              │  │ active_script      │  │  currently playing name
              │  │ state: Playback    │  │  Idle/Running/Paused/Complete
              │  │ elapsed / step_idx │  │  playback position
              │  └────────────────────┘  │
              │        │                 │
              │   update(dt, eq)         │
              │        │                 │
              │        ▼                 │
              │  ┌───────────┐           │
              │  │  Script   │           │  (script.rs)
              │  │  name     │           │  named, time-sorted, capped
              │  │  steps[]  │───────┐   │
              │  └───────────┘       │   │
              └──────────────────────│───┘
                                     │
                          ┌──────────▼──────────┐
                          │   Step (step.rs)     │
                          │  time: f32           │
                          │  action: Action      │
                          │  key/scancode/x/y/…  │
                          └──────────┬──────────┘
                                     │
                          dispatch_step()
                                     │
                                     ▼
                          ┌─────────────────┐
                          │   EventQueue    │  (crate::event)
                          │  push(Event)    │  synthetic input events
                          └─────────────────┘
```

## Source Files

| File           | Purpose                                                                                |
|----------------|----------------------------------------------------------------------------------------|
| `mod.rs`       | Module root — re-exports `Script`, `Simulator`, `Step`, `Action`; module-level docs    |
| `script.rs`    | `Script` struct — named, time-sorted, `MAX_STEPS`-capped container of `Step` objects   |
| `simulator.rs` | `Simulator` struct — playback engine with named script registry and `PlaybackState` FSM |
| `step.rs`      | `Step` struct and `Action` enum — timed action records with 12 optional fields          |

## Submodules

### `automation::script`

Named, time-sorted, capacity-capped collection of `Step` objects. Scripts are indexed by name in the `Simulator` and selected for playback via `Simulator::start`. The step cap of `MAX_STEPS` (100 000) guards against unbounded memory allocation.

- **`Script`** (struct): A named simulation script containing an ordered sequence of timed steps.

### `automation::simulator`

Playback engine that holds a `HashMap<String, Script>` registry and advances an elapsed-time cursor each frame, dispatching steps whose timestamps have been reached into the `EventQueue`. Manages a four-state FSM: Idle → Running → Paused/Complete.

- **`Simulator`** (struct): Automated input simulation engine with script registry and playback state.

### `automation::step`

Building blocks of a simulation script. Each `Step` pairs a wall-clock offset with an `Action` variant and optional action-specific parameters (key name, mouse coordinates, button index, text, click count, repeat flag).

- **`Step`** (struct): A single timed step in a simulation script with 12 fields.
- **`Action`** (enum): The action type for a simulation step — 8 variants mapping to synthetic input events.

## Key Types

### Structs

#### `automation::script::Script`

A named simulation script containing an ordered sequence of timed steps. On construction, steps are sorted by `time` ascending and truncated to `MAX_STEPS` (100 000). Scripts are stored in the `Simulator` indexed by name; loading a script with an existing name replaces the previous one.

**Fields**: `name: String`, `description: Option<String>`, `steps: Vec<Step>`.

**Key methods**:
- `Script::new(name, steps)` — Create a script; sorts steps by time, truncates to cap.
- `Script::with_description(name, description, steps)` — Create with explicit description.
- `Script::step_count()` — Return the number of steps.

#### `automation::simulator::Simulator`

Automated input simulation engine. Holds a named registry of `Script` objects and plays back the active script by injecting synthetic input events into the provided `EventQueue` on each `update` call. Not `Send` or `Sync` — owned via `Rc<RefCell<Simulator>>`.

**Fields**: `scripts: HashMap<String, Script>`, `active_script: Option<String>`, `elapsed: f32`, `next_step_idx: usize`, `state: PlaybackState` (private enum).

**Key methods**:
- `Simulator::new()` — Create with empty registry in Idle state.
- `Simulator::load(script)` — Register a script by name (replaces existing).
- `Simulator::unload(name)` — Remove a script; auto-stops if active.
- `Simulator::has_script(name)` — Check if a script name is registered.
- `Simulator::get_scripts()` — Return all registered script names.
- `Simulator::start(name)` — Begin playback from the start; returns `Err` if not loaded.
- `Simulator::stop()` — Reset to Idle; clear active script and elapsed time.
- `Simulator::pause()` — Freeze playback at current position.
- `Simulator::resume()` — Continue from paused position.
- `Simulator::update(dt, event_queue)` — Advance clock, dispatch due steps into EventQueue.
- `Simulator::is_running()` / `is_paused()` / `is_complete()` — State queries.
- `Simulator::current_step()` — Index of next step to dispatch.
- `Simulator::step_count()` — Total steps in active script.
- `Simulator::current_script()` — Name of active script or `None`.
- `Simulator::elapsed_time()` — Seconds since playback started.

#### `automation::step::Step`

A single timed step in a simulation script. Pairs a wall-clock offset (`time`) with an `Action` and optional action-specific fields. Only `time` and `action` are required; all other fields default to `None`/`false`.

**Fields**: `time: f32`, `action: Action`, `key: Option<String>`, `scancode: Option<String>`, `x: Option<f64>`, `y: Option<f64>`, `dx: Option<f64>`, `dy: Option<f64>`, `button: Option<u32>`, `text: Option<String>`, `is_repeat: bool`, `clicks: Option<u32>`.

**Key methods**:
- `Step::new(time, action)` — Create with defaults for all optional fields.
- `Step::effective_scancode()` — Return `scancode` if set, else fall back to `key`.

### Enums

#### `automation::step::Action`

The action type for a simulation step. Each variant maps to a synthetic input event injected into the `EventQueue` during playback. Parse from string with `Action::parse_action`; convert back with `Action::as_str`.

**Variants**: `KeyPress`, `KeyRelease`, `MouseMove`, `MousePress`, `MouseRelease`, `MouseWheel`, `TextInput`, `Wait`.

**Key methods**:
- `Action::parse_action(s)` — Parse lowercase string (`"keypress"`, `"wait"`, etc.) into variant.
- `Action::as_str()` — Return canonical lowercase string representation.

## Lua API

Exposed under `luna.simulator.*` by `src/lua_api/automation_api.rs`. The API provides 16 functions for loading, controlling, and querying script playback. Scripts are loaded from Lua tables containing a `steps` array and optional `meta` table. The bridge function `parse_steps` converts Lua step tables into `Vec<Step>`.

| Function | Signature | Description |
|----------|-----------|-------------|
| `luna.simulator.load` | `(name: string, data: table)` | Load a named script from a table with `steps` array and optional `meta.description` |
| `luna.simulator.unload` | `(name: string) → boolean` | Remove a loaded script; returns true if it existed |
| `luna.simulator.hasScript` | `(name: string) → boolean` | Check if a script name is registered |
| `luna.simulator.getScripts` | `() → table` | Return array of all registered script names |
| `luna.simulator.start` | `(name: string)` | Start playback of named script from the beginning |
| `luna.simulator.stop` | `()` | Stop playback, reset to idle |
| `luna.simulator.pause` | `()` | Pause playback at current position |
| `luna.simulator.resume` | `()` | Resume from paused position |
| `luna.simulator.update` | `(dt: number)` | Advance clock by dt seconds, dispatch due steps |
| `luna.simulator.isRunning` | `() → boolean` | True if actively playing a script |
| `luna.simulator.isPaused` | `() → boolean` | True if paused |
| `luna.simulator.isComplete` | `() → boolean` | True if all steps in active script dispatched |
| `luna.simulator.getCurrentStep` | `() → integer` | Index of next step to dispatch |
| `luna.simulator.getStepCount` | `() → integer` | Total steps in active script |
| `luna.simulator.getCurrentScript` | `() → string?` | Name of active script, or nil if idle |
| `luna.simulator.getElapsedTime` | `() → number` | Seconds elapsed since playback started |

### Step Table Format

Each entry in the `steps` array is a table with these fields:

| Field | Type | Required | Default | Used by |
|-------|------|----------|---------|---------|
| `action` | string | yes | — | all |
| `time` | number | no | `0.0` | all |
| `key` | string | no | `nil` | keypress, keyrelease |
| `scancode` | string | no | `key` | keypress, keyrelease |
| `x` | number | no | `0.0` | mousemove, mousepress, mouserelease, mousewheel |
| `y` | number | no | `0.0` | mousemove, mousepress, mouserelease, mousewheel |
| `dx` | number | no | `0.0` | mousemove |
| `dy` | number | no | `0.0` | mousemove |
| `button` | integer | no | `1` | mousepress, mouserelease |
| `text` | string | no | `""` | textinput |
| `isRepeat` | boolean | no | `false` | keypress |
| `clicks` | integer | no | `1` | mousepress |

## Lua Examples

```lua
-- Load a script with keyboard and mouse steps
function luna.init()
    luna.simulator.load("test_input", {
        steps = {
            { time = 0.1, action = "keypress",    key = "space" },
            { time = 0.3, action = "keyrelease",  key = "space" },
            { time = 0.5, action = "mousemove",   x = 400, y = 300, dx = 10, dy = 5 },
            { time = 0.7, action = "mousepress",  x = 400, y = 300, button = 1 },
            { time = 0.8, action = "mouserelease", x = 400, y = 300, button = 1 },
            { time = 1.0, action = "textinput",   text = "hello" },
            { time = 1.5, action = "wait" },
        },
        meta = { description = "Integration test: basic input sequence" },
    })
    luna.simulator.start("test_input")
end

function luna.process(dt)
    luna.simulator.update(dt)

    if luna.simulator.isComplete() then
        print("Script finished after " .. luna.simulator.getElapsedTime() .. "s")
        luna.simulator.stop()
    end
end
```

```lua
-- Pause/resume and introspection
function luna.process(dt)
    luna.simulator.update(dt)

    -- Pause on a specific step
    if luna.simulator.getCurrentStep() >= 3 and luna.simulator.isRunning() then
        luna.simulator.pause()
    end

    -- Report progress
    local step = luna.simulator.getCurrentStep()
    local total = luna.simulator.getStepCount()
    local name = luna.simulator.getCurrentScript() or "none"
    print(string.format("Script '%s': step %d/%d", name, step, total))
end
```

## Item Summary

| Kind      | Count |
|-----------|-------|
| `struct`  | 3     |
| `enum`    | 1     |
| `fn`      | 24    |
| **Total** | **28** |

## References

| Module    | Relationship | Notes                                                        |
|-----------|-------------|--------------------------------------------------------------|
| `engine`  | Imports from | Log messages (`log_msg!`, `AT01_SIM_INIT`, `AT02_SCRIPT_LOAD`) |
| `event`   | Imports from | `Event`, `EventArg`, `EventQueue` — step dispatch target     |
| `lua_api` | Imported by  | Registers `luna.simulator.*` via `automation_api.rs`          |
| `input`   | Related      | Automation injects events that the input module consumes; the two modules do not import each other |

## Notes

- **Tier classification**: The module is Tier 2 (not Tier 1) because it imports `crate::event`, which is Tier 1. The Tier 1 no-cross-import rule prohibits this at the same tier.
- **Lua namespace**: The API is `luna.simulator.*`, not `luna.automation.*`. The table is registered via `luna.set("simulator", tbl)`.
- **Simulator ownership**: `Simulator` is `Rc<RefCell<Simulator>>` in the Lua API — separate from `SharedState`. It is not stored in `SharedState`; the automation API creates and owns its own instance during registration.
- **Event injection only**: The module pushes synthetic `Event` objects into the `EventQueue`. It never reads or consumes events. The input module (`src/input/`) handles actual input state.
- **Memory cap**: `MAX_STEPS = 100_000` per script (~12 MB at ~120 bytes/step). Steps beyond this are silently truncated during `Script::new`. This is a security guard (CSF-010).
- **PlaybackState is private**: The four-state FSM (`Idle`, `Running`, `Paused`, `Complete`) is private to `simulator.rs`. External code queries state via `is_running()`, `is_paused()`, `is_complete()`.
- **No persistence**: Scripts exist only in memory. There is no built-in save/load to disk — scripts are constructed from Lua tables each time.
- **Thread safety**: `Simulator` is not `Send` or `Sync`. It must remain on the main thread.
- **Breaking change surface**: Renaming step action strings (`"keypress"`, `"mousemove"`, etc.) or the `luna.simulator.*` function names would break all existing automation scripts.

## See Also

| Module | Relationship |
|---|---|
| `timer::Scheduler` | For timed Lua callbacks (`after(delay)` / `every(interval)`), use `luna.time.newScheduler()`. `automation.Simulator` is for replaying **recorded input scripts**, not general timed callbacks. |
| `patterns::StateMachine` | `Simulator` contains an internal 4-state FSM (`Idle/Running/Paused/Complete`). For **game-level** FSM needs (menus, NPC states, combat phases), use `luna.patterns.newStateMachine()` instead. |
