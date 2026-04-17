---
name: examples-management
description: "Load this skill when adding, modifying, or reviewing content in the content/examples/ or content/demos/ directories: game example scripts, demo folder structure, conf.lua, or README files. Use for ensuring examples are self-contained, well-commented, and demonstrate one API concept. Skip it for engine Rust code, tests, documentation under docs/, or CAG work."
---

# Examples Management — Lurek2D

## Load When

- Adding a new Lua example to `content/examples/` or demo to `content/demos/`
- Reviewing an existing example for correctness or code quality
- Understanding the difference between `content/examples/` and `content/demos/`
- Writing conf.toml for a demo
- Linking an example to the API documentation pipeline
- Setting up an example to work as a smoke test

## Owns

- `content/examples/` vs `content/demos/` structure and naming rules
- Example file self-contained requirement and comment style
- Demo folder layout (conf.lua, main.lua, assets, README)
- Examples ↔ API documentation pipeline integration
- Smoke test support pattern (`--smoke` flag + `lurek.signal.quit()`)
- `content/examples/README.md` and `content/demos/README.md` maintenance

## Two-Folder Model

| Folder | Purpose | Scope | Format |
|--------|---------|-------|--------|
| `content/examples/` | Minimal single-file API demonstrations | One `.lua` file per API area | ~30–100 lines, no conf.lua |
| `content/demos/` | Larger showcase games/feature demos | Full game directory (conf.toml + main.lua + assets) | 100–500+ lines, multiple files |

**Rule**: An `content/examples/` file shows one API namespace in the simplest possible way. A `content/demos/` folder is a small, complete game or feature showcase.

## content/examples/ File Structure

```
content/examples/
├── physics.lua        — lurek.physics.* API example
├── graphics.lua       — lurek.gfx.* example
├── timer.lua          — lurek.time.* example
├── audio.lua          — lurek.audio.* example
└── ...                — one .lua per API namespace
```

**Example file template:**

```lua
-- content/examples/timer.lua
-- Demonstrates lurek.time API: basic delta time, FPS, sleep.
-- Run with: cargo run -- content/examples/timer

-- ── load ──────────────────────────────────────────────────────
function lurek.init()
    elapsed = 0
    font = lurek.gfx.getDefaultFont()
end

-- ── update ────────────────────────────────────────────────────
function lurek.process(dt)
    elapsed = elapsed + dt
end

-- ── draw ──────────────────────────────────────────────────────
function lurek.render()
    lurek.gfx.print("FPS: " .. lurek.time.getFPS(), 10, 10)
    lurek.gfx.print("Elapsed: " .. string.format("%.2f", elapsed), 10, 30)
end
```

**Required elements:**
- Top comment block: file path, one-line purpose, run command
- Small section comments `-- ── section ──` before `load`, `update`, `draw`
- No `conf.toml` (uses default window settings)
- Self-contained: no external assets unless they are embedded in the engine

## content/demos/ Folder Structure

```
content/demos/<name>/
├── main.lua      — required; game entry point
├── conf.toml     — optional; custom window/module settings
├── README.md     — optional; what the demo shows
└── assets/       — optional; sprites, sounds, maps
```

**conf.toml template:**
```lua
function lurek.conf(t)
    t.window.title = "Demo Name"
    t.window.width = 800
    t.window.height = 600
end
```

## What Makes a Good Example

| Quality | Description |
|---------|-------------|
| **Scenario-driven** | Each section is a named game task ("schedule bullet despawn"), not a function name |
| **Self-contained** | Runs with `cargo run -- content/examples/<file>` without extra setup |
| **Answers WHY** | The reader understands when and why they would reach for each function |
| **Game values** | All arguments are realistic: `hp=100`, `"hero_walk.png"`, not `0`, `""`, `nil` |
| **Coverage + clarity** | `example_coverage.py` passing is the floor, not the ceiling |

### The scenario pattern — ALWAYS write this way

```lua
-- ---- Scenario: schedule bullet auto-despawn -------------------------------------
-- Bullets in a shoot-em-up should self-destruct after 3 seconds unless they hit
-- something. lurek.timer.newScheduler + after() handles this; cancel() aborts early.

local sched = lurek.timer.newScheduler()
local id = sched:after(3.0, function()
    print("bullet removed from world after 3 seconds")
end)
sched:update(1.0)
print("timers still pending: " .. sched:count())

local hit_enemy = true
if hit_enemy then
    local ok = sched:cancel(id)
    print("early despawn cancelled: " .. tostring(ok))
end
```

### FORBIDDEN patterns — never write these

```lua
-- FORBIDDEN: function-name scenario (teaches what, not why or when)
-- lurek.timer.after
-- Schedules a callback.
local id = sched:after(2.0, function() end)

-- FORBIDDEN: lone constructor with trivial method chain
local sig2 = lurek.event.newSignal()
print("type: " .. sig2:type())   -- sig2 exists only to demonstrate :type()

-- FORBIDDEN: nil / zero args for meaningful parameters
lurek.physics.newBody(nil, 0, 0)
```

The test: "if I showed this to a developer who has never heard of this engine, would they
understand what game problem this solves?" If NO, rewrite it as a scenario.

## Adding a New Example (Checklist)

**Minimal example** (one `.lua` file):
1. Create `content/examples/<module>.lua` following the template above
2. Test: `cargo run -- content/examples/<module>.lua`
3. Link in `content/examples/README.md`
4. If the example demonstrates a newly added API function, update `docs/API/lua_api_data.json`

**Full demo** (game directory):
1. Create `content/demos/<name>/` with `main.lua` (+ optional `conf.toml`, assets, README)
2. Test: `cargo run -- content/demos/<name>`
3. Link in `content/demos/README.md`
4. Verify the demo runs to completion with no errors and no stale `print` debug output

## Examples and API Documentation

The tools pipeline uses examples to validate the API surface:

```powershell
# Check that all lurek.* calls in content/examples/ are documented in api_data.json
python tools/docs/gen_lua_api.py --check

# Generate Lua API reference including usage patterns from examples
python tools/docs/gen_lua_api.py
```

When an `content/examples/` file uses an API function that lacks an `/// @param`/`/// @return` docstring, `tools/docs/gen_lua_api.py --check` will report it. Fix the docstring, not the example.

## Smoke Testing

Examples can be run as smoke tests to verify engine functionality:

```powershell
# Run example and exit immediately (headless verification)
cargo run -- content/examples/graphics.lua -- --smoke
```

If an example supports a `--smoke` flag, it calls `lurek.quit()` after one frame to allow automated verification.

Add smoke test support to a new example:

```lua
function lurek.init()
    local args = lurek.platform.getArgs()
    if args["--smoke"] then
        lurek.signal.quit()
    end
end
```

## Examples README

`content/examples/README.md` and `content/demos/README.md` must stay alphabetically sorted and must link to each file/folder with a one-line description.

Format:
```markdown
| File/Folder | Demonstrates |
|---|---|
| `audio.lua` | `lurek.audio.*` — source loading, playback, volume |
| `physics.lua` | `lurek.physics.*` — world, bodies, collision |
```

Update both README files whenever a new example or demo is added.

## Anti-Patterns

- **Assets in content/examples/**: Resources that require manual download or aren't embedded — examples must be self-contained
- **Stale demos**: Demos that use removed API functions (`lurek.old.func`) — run demos on every release to catch breakage
- **Debug-print noise**: `print("test")` or `print(val)` left in committed examples
- **Missing README entry**: Adding an example without updating `content/examples/README.md`

## Lua API Compliance

These rules apply to all files in `content/examples/` and `content/demos/`:

### Input Key Names

Key names must match the engine canonical map exactly — always lowercase, never platform names:

```lua
-- CORRECT
if lurek.keyboard.isDown("space") then
if lurek.keyboard.isDown("escape") then
if lurek.keyboard.isDown("up") then     -- "up", "down", "left", "right"
if lurek.keyboard.isDown("w") then      -- single letter, lowercase

-- WRONG
if lurek.keyboard.isDown("Space") then  -- uppercase
if lurek.keyboard.isDown("SPACE") then  -- all-caps
if lurek.keyboard.isDown("VK_SPACE") then  -- platform key name
```

Canonical set: `"space"`, `"escape"`, `"up"`, `"down"`, `"left"`, `"right"`, single letter keys `"a"`–`"z"`, `"return"`, `"tab"`, `"backspace"`.

### Color Values

Color component values must be in `[0.0, 1.0]` range — **never** `[0, 255]`:

```lua
-- CORRECT
lurek.gfx.setColor(1.0, 0.0, 0.0, 1.0)    -- red, full opacity
lurek.gfx.setColor(0.5, 0.5, 0.5, 1.0)    -- mid-gray

-- WRONG
lurek.gfx.setColor(255, 0, 0, 255)         -- byte range, not float
```

### Rectangle Draw Mode

`lurek.gfx.rectangle()` takes a string mode as its first arg — not a boolean:

```lua
-- CORRECT
lurek.gfx.rectangle("fill", x, y, w, h)
lurek.gfx.rectangle("line", x, y, w, h)

-- WRONG
lurek.gfx.rectangle(true, x, y, w, h)   -- boolean does not work
```

### Physics Body Types

```lua
-- CORRECT
world:newBody(x, y, "dynamic")
world:newBody(x, y, "static")

-- WRONG
world:newBody(x, y, 1)      -- numeric type codes
world:newBody(x, y, true)   -- boolean
```

### Folder-Specific Rules

| Rule | `content/demos/` | `content/examples/` |
|------|---------|------------|
| `require()` | ❌ No — must be single-file, self-contained | ✅ May use `require("library.*")` for shipped Lunasome modules |
| `os.*` / `io.*` system calls | ❌ Never — use `lurek.fs.*` for file access | ❌ Never |
| `conf.toml` | ✅ Required for each demo folder | ❌ Not applicable (single-file) |

## Example Coverage Workflow — 100% API Coverage Required

Every `content/examples/<module>.lua` must demonstrate **every** `lurek.*` API function and method
that the corresponding `src/lua_api/<module>_api.rs` registers.  The three-tool workflow to achieve
this:

### Step 1 — Check gaps

```powershell
# Full summary of all modules
python tools/audit/example_coverage.py

# Missing items only
python tools/audit/example_coverage.py --missing

# Single module
python tools/audit/example_coverage.py --module timer

# CI gate: exit 1 if any gaps
python tools/audit/example_coverage.py --report
```

**Exit codes**: 0 = full coverage; 1 = gaps exist.  The `--report` flag is used in CI.

### Step 2 — Append stubs for missing API

```powershell
# Dry-run first to preview what will be appended
python tools/audit/example_add_missing.py --module timer --dry-run

# Write stubs for one module
python tools/audit/example_add_missing.py --module timer

# Write stubs for all modules with gaps
python tools/audit/example_add_missing.py
```

This appends commented stub blocks at the bottom of the example file.  Each stub is a
`-- ── lurek.ns.name ──` ruler + description + placeholder call.  The example file remains
valid Lua — stubs are pure comments until the next step replaces them.

### Step 3 — Flesh out stubs with real code

Open the example file and run the prompt:

```
@workspace /file:content/examples/timer.lua
Use the flesh-out-example.prompt.md prompt to expand all stubs into real examples.
```

Or invoke via VS Code Copilot with:
```
#file:content/examples/timer.lua  #file:docs/specs/timer.md
Expand every -- ── stub section into working Lua code following the rules in
.github/prompts/flesh-out-example.prompt.md
```

### Coverage Rules

- One `.lua` file per `src/lua_api/<module>_api.rs` — exact 1:1 mapping
- Every registered function *and* every method on every userdata type must appear as a **real call**, not a comment
- Return values must be assigned or logged — `local x = lurek.time.getDelta()` not just `lurek.time.getDelta()`
- The stub header `-- STUBS: N` must be removed after all stubs in that file are filled
- `python tools/audit/example_coverage.py --report` must exit 0 before merge

### Module-to-Example File Mapping (canonical)

| JSON module key | `lurek.*` namespace | Example file |
|---|---|---|
| `ai` | `lurek.ai` | `content/examples/ai.lua` |
| `animation` | `lurek.animation` | `content/examples/animation.lua` |
| `audio` | `lurek.audio` | `content/examples/audio.lua` |
| `ecs` | `lurek.entity` | `content/examples/entity.lua` |
| `effect` | `lurek.overlay` | `content/examples/fx.lua` |
| `filesystem` | `lurek.fs` | `content/examples/filesystem.lua` |
| `i18n` | `lurek.localization` | `content/examples/localization.lua` |
| `image` | `lurek.img` | `content/examples/image.lua` |
| `input` | `lurek.keyboard` | `content/examples/input.lua` |
| `mods` | `lurek.modding` | `content/examples/modding.lua` |
| `pathfind` | `lurek.pathfinding` | `content/examples/pathfinding.lua` |
| `render` | `lurek.graphic` | `content/examples/graphics.lua` |
| `save` | `lurek.savegame` | `content/examples/savegame.lua` |
| `serial` | `lurek.codec` | `content/examples/serial.lua` |
| `system` | `lurek.platform` | `content/examples/system.lua` |
| `timer` | `lurek.time` | `content/examples/timer.lua` |
| `ui` | `lurek.ui` | `content/examples/gui.lua` |
| All others | `lurek.<module>` | `content/examples/<module>.lua` |

Full mapping is the `MODULE_TO_EXAMPLE` and `NAMESPACE_MAP` dicts in
`tools/audit/example_coverage.py` — that is the single source of truth.

### Cross-Artifact Sync

When adding a new `lurek.*` function:
1. Add the Rust binding in `src/lua_api/<module>_api.rs`
2. Run `python tools/audit/example_coverage.py --module <module>` → will show the new function as missing
3. Run `python tools/audit/example_add_missing.py --module <module>` → stub appended
4. Use the flesh-out prompt to fill in the stub
5. Commit `src/lua_api/<module>_api.rs` + `content/examples/<module>.lua` + `docs/CHANGELOG.md` together
