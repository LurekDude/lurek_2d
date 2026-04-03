# simulator — Automated Input Simulation Module

> **Lua namespace:** `luna.simulator`
> **C++ module:** `src/modules/simulator/`
> **Purpose:** Provides automated input injection via timed scripts for autonomous game testing and replay. Loads named scripts containing sequences of timed steps (key presses, mouse movements, text input, waits), then plays them back by dispatching synthetic events into the Luna2D event queue. Scripts can be defined programmatically as Lua tables or loaded from TOML files.

## Reimplementation Notes

- Scripts are collections of timed `Step` objects — each step has a `time` (seconds from script start), an `action` type, and action-specific fields
- Playback is driven by calling `update(dt)` each frame — steps are dispatched when elapsed time reaches the step's `time` value
- Steps are processed sequentially in order; the engine maps actions to synthetic SDL3 events (key presses, mouse events, etc.)
- The `load()` function accepts a pre-parsed table with `meta.description` and `steps` array — it does NOT parse TOML directly
- Two Lua-side helper functions are injected at module load: `loadFromToml(name, tomlString)` and `loadFile(path, name?)` which handle TOML parsing via `luna.data.decodeToml()`
- Multiple scripts can be loaded simultaneously — `start(name)` selects which one to play
- Step count is capped at 100,000 per script (CSF-010 unbounded allocation guard)
- Step fields: `time`, `action`, `key`, `scancode`, `x`, `y`, `dx`, `dy`, `button`, `text`, `isRepeat`, `clicks`
- If `scancode` is not set and `key` is provided, scancode defaults to the key value

## Dependencies

- `luna.data` (for TOML parsing via `decodeToml()` — only needed for `loadFromToml`/`loadFile` helpers)
- `luna.filesystem` (for `loadFile` helper)

---

## Module Functions

### Script Management

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `load` | `name: string, data: table` | — | Load a script from a pre-parsed table. Table must have a `steps` array of step tables |
| `unload` | `name: string` | — | Remove a loaded script |
| `hasScript` | `name: string` | `boolean` | Check if a script is loaded |
| `getScripts` | — | `table<string>` | Get names of all loaded scripts |

### Lua-Injected Helpers

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `loadFromToml` | `name: string, tomlString: string` | — | Parse a TOML string via `luna.data.decodeToml()` and load as a script |
| `loadFile` | `path: string, name?: string` | — | Read a TOML file from `luna.filesystem`, parse it, and load. Name defaults to `meta.name` or path |

### Playback Control

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `start` | `name: string` | — | Start playback of the named script from the beginning. Errors if not loaded |
| `stop` | — | — | Stop playback and reset |
| `pause` | — | — | Pause playback at the current step |
| `resume` | — | — | Resume paused playback |
| `update` | `dt: number` | — | Advance playback by `dt` seconds. Dispatches steps whose time has been reached |

### Playback State

| Function | Parameters | Returns | Description |
|---|---|---|---|
| `isRunning` | — | `boolean` | True if a script is actively playing (not paused, not complete) |
| `isPaused` | — | `boolean` | True if playback is paused |
| `isComplete` | — | `boolean` | True if the current script has finished all steps |
| `getCurrentStep` | — | `number` | Index of the current step being processed |
| `getStepCount` | — | `number` | Total number of steps in the active script |
| `getCurrentScript` | — | `string \| nil` | Name of the active script, or nil |
| `getElapsedTime` | — | `number` | Seconds elapsed since playback started |

---

## Step Table Format

Each step in the `steps` array is a table with these fields (all optional except `action`):

```lua
{
    time = 1.5,            -- number: seconds from script start to fire this step
    action = "keypress",   -- string: action type (see Action enum below)
    key = "space",         -- string: key name (for key actions)
    scancode = "space",    -- string: scancode (defaults to key if omitted)
    x = 400,               -- number: mouse X position
    y = 300,               -- number: mouse Y position
    dx = 10,               -- number: mouse X delta
    dy = -5,               -- number: mouse Y delta
    button = 1,            -- number: mouse button index
    text = "hello",        -- string: text to input
    isRepeat = false,      -- boolean: is this a key repeat event?
    clicks = 1             -- number: click count (for mouse press)
}
```

## Script Table Format

```lua
{
    meta = {
        description = "Test script for menu navigation"  -- optional
    },
    steps = {
        { time = 0.0, action = "keypress", key = "return" },
        { time = 0.5, action = "mousemove", x = 200, y = 150 },
        { time = 1.0, action = "mousepress", x = 200, y = 150, button = 1 },
        { time = 1.1, action = "mouserelease", x = 200, y = 150, button = 1 },
        { time = 2.0, action = "wait" }
    }
}
```

---

## Enums

### Action

| Value | String | Description |
|---|---|---|
| 0 | `"keypress"` | Simulate a key press event |
| 1 | `"keyrelease"` | Simulate a key release event |
| 2 | `"mousemove"` | Simulate mouse movement |
| 3 | `"mousepress"` | Simulate a mouse button press |
| 4 | `"mouserelease"` | Simulate a mouse button release |
| 5 | `"mousewheel"` | Simulate a mouse wheel scroll |
| 6 | `"textinput"` | Simulate text input |
| 7 | `"wait"` | Wait (no-op — just a timed delay) |

---

## Usage Example

```lua
-- Load a script from a Lua table
luna.simulator.load("test_menu", {
    meta = { description = "Navigate to play button and click" },
    steps = {
        { time = 0.0, action = "mousemove", x = 400, y = 300 },
        { time = 0.5, action = "mousepress", x = 400, y = 300, button = 1 },
        { time = 0.6, action = "mouserelease", x = 400, y = 300, button = 1 },
        { time = 1.0, action = "keypress", key = "escape" },
    }
})

-- Or load from a TOML file
luna.simulator.loadFile("scripts/test_menu.toml")

-- Start playback
luna.simulator.start("test_menu")

function luna.update(dt)
    luna.simulator.update(dt)

    if luna.simulator.isComplete() then
        print("Simulation finished!")
    end
end
```

### TOML Script Format

```toml
[meta]
description = "Navigate to play button and click"

[[steps]]
time = 0.0
action = "mousemove"
x = 400
y = 300

[[steps]]
time = 0.5
action = "mousepress"
x = 400
y = 300
button = 1
```

---

## Game Design Role

- **Regression testing**: Record an input sequence, replay it on every build to catch breakage.
- **Demo playback**: Auto-play a game demo for showcases and testing.
- **Stress testing**: Inject rapid or extreme input patterns to test edge cases.
- **CI integration**: Run automated input tests in headless/runner mode.

---

## Module Boundaries

**vs luna.keyboard / luna.mouse / luna.joystick** — Those modules read *real* hardware input. Simulator *injects* synthetic events into the same queue. Injected events are indistinguishable from real input to the game.

**vs luna.event** — Event is the raw SDL event queue. Simulator pushes events *into* the event queue. It does not replace or intercept real events.

**vs Testing framework** — The test framework (`testing/`) asserts results. Simulator provides automated input to drive the game. They work together: simulator clicks buttons, test framework checks outcomes.

---

## Recipes & Workflows

- **Regression tests**: Replay input scripts after each build to verify nothing broke.
- **Tutorial recording**: Script the input for a tutorial walkthrough and replay it as a demo.
- **Performance benchmarks**: Inject consistent input sequences for frame-time measurement.
- **Stress testing**: Rapid key mashing and mouse movement injection to find input handling bugs.

---

## Edge Cases & Pitfalls

- **Timing precision**: Step `time` values are in seconds but are rounded to the game’s dt granularity. At 60 fps, the minimum reliable delay is ~17ms. Sub-frame timing differences in expected output screenshots will cause flaky tests.
- **Event injection order**: Injected events are pushed to `luna.event` at the start of the next frame, not immediately. If your test expects an event to be processed within the same update, you need two frames — one to inject, one to process.
- **State dependency between scripts**: Scripts run in sequence within the same game session. Leftover state from a previous script step can contaminate later steps. Reset relevant game state explicitly at the start of each scenario.
- **Screenshot comparison on CI**: Simulator screenshot assertions compare pixel buffers. On headless CI without GPU, Mesa software rendering may produce slightly different pixels than hardware. Use `luna.test.compareScreenshot` with a tolerance threshold.
- **Mouse move vs click**: A `mousepress` at position (100, 200) does not implicitly move the mouse cursor there first. Some UI systems require `mousemove` before `mousepress` to trigger hover states.

---

## Planned / To Implement

- **W2**: Recorded session playback — capture real user input and replay it as a TOML script.
- **W2**: Fuzzing mode — generate random valid TOML scripts to stress-test game input handling.
- **W3**: CI integration script — run simulator tests headlessly and emit JUnit XML results.
