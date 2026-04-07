---
name: examples-management
description: "Load this skill when adding, modifying, or reviewing content in the examples/ or demos/ directories: game example scripts, demo folder structure, conf.lua, or README files. Use for ensuring examples are self-contained, well-commented, and demonstrate one API concept. Skip it for engine Rust code, tests, documentation under docs/, or CAG work."
---

# Examples Management — Luna2D

## Load When

- Adding a new Lua example to `examples/` or demo to `demos/`
- Reviewing an existing example for correctness or code quality
- Understanding the difference between `examples/` and `demos/`
- Writing conf.lua for a demo
- Linking an example to the API documentation pipeline
- Setting up an example to work as a smoke test

## Owns

- `examples/` vs `demos/` structure and naming rules
- Example file self-contained requirement and comment style
- Demo folder layout (conf.lua, main.lua, assets, README)
- Examples ↔ API documentation pipeline integration
- Smoke test support pattern (`--smoke` flag + `luna.signal.quit()`)
- `examples/README.md` and `demos/README.md` maintenance

## Two-Folder Model

| Folder | Purpose | Scope | Format |
|--------|---------|-------|--------|
| `examples/` | Minimal single-file API demonstrations | One `.lua` file per API area | ~30–100 lines, no conf.lua |
| `demos/` | Larger showcase games/feature demos | Full game directory (conf.lua + main.lua + assets) | 100–500+ lines, multiple files |

**Rule**: An `examples/` file shows one API namespace in the simplest possible way. A `demos/` folder is a small, complete game or feature showcase.

## examples/ File Structure

```
examples/
├── physics.lua        — luna.physics.* API example
├── graphics.lua       — luna.gfx.* example
├── timer.lua          — luna.time.* example
├── audio.lua          — luna.audio.* example
└── ...                — one .lua per API namespace
```

**Example file template:**

```lua
-- examples/timer.lua
-- Demonstrates luna.time API: basic delta time, FPS, sleep.
-- Run with: cargo run -- examples/timer

-- ── load ──────────────────────────────────────────────────────
function luna.init()
    elapsed = 0
    font = luna.gfx.getDefaultFont()
end

-- ── update ────────────────────────────────────────────────────
function luna.process(dt)
    elapsed = elapsed + dt
end

-- ── draw ──────────────────────────────────────────────────────
function luna.render()
    luna.gfx.print("FPS: " .. luna.time.getFPS(), 10, 10)
    luna.gfx.print("Elapsed: " .. string.format("%.2f", elapsed), 10, 30)
end
```

**Required elements:**
- Top comment block: file path, one-line purpose, run command
- Small section comments `-- ── section ──` before `load`, `update`, `draw`
- No `conf.lua` (uses default window settings)
- Self-contained: no external assets unless they are embedded in the engine

## demos/ Folder Structure

```
demos/<name>/
├── main.lua      — required; game entry point
├── conf.lua      — optional; custom window/module settings
├── README.md     — optional; what the demo shows
└── assets/       — optional; sprites, sounds, maps
```

**conf.lua template:**
```lua
function luna.conf(t)
    t.window.title = "Demo Name"
    t.window.width = 800
    t.window.height = 600
end
```

## What Makes a Good Example

| Quality | Description |
|---------|-------------|
| **One concept** | Demonstrates exactly one API namespace or one gameplay pattern |
| **Self-contained** | Runs with `cargo run -- examples/<file>` without extra setup |
| **Commented** | Every section explains what it demonstrates and why |
| **Minimal** | Strip everything that isn't directly demonstrating the concept |
| **AI-readable** | An AI agent should be able to learn the full API surface from reading it |

## Adding a New Example (Checklist)

**Minimal example** (one `.lua` file):
1. Create `examples/<module>.lua` following the template above
2. Test: `cargo run -- examples/<module>.lua`
3. Link in `examples/README.md`
4. If the example demonstrates a newly added API function, update `docs/API/lua_api_data.json`

**Full demo** (game directory):
1. Create `demos/<name>/` with `main.lua` (+ optional `conf.lua`, assets, README)
2. Test: `cargo run -- demos/<name>`
3. Link in `demos/README.md`
4. Verify the demo runs to completion with no errors and no stale `print` debug output

## Examples and API Documentation

The tools pipeline uses examples to validate the API surface:

```powershell
# Check that all luna.* calls in examples/ are documented in api_data.json
python tools/docs/gen_lua_api.py --check

# Generate Lua API reference including usage patterns from examples
python tools/docs/gen_lua_api.py
```

When an `examples/` file uses an API function that lacks an `/// @param`/`/// @return` docstring, `tools/docs/gen_lua_api.py --check` will report it. Fix the docstring, not the example.

## Smoke Testing

Examples can be run as smoke tests to verify engine functionality:

```powershell
# Run example and exit immediately (headless verification)
cargo run -- examples/graphics.lua -- --smoke
```

If an example supports a `--smoke` flag, it calls `luna.quit()` after one frame to allow automated verification.

Add smoke test support to a new example:

```lua
function luna.init()
    local args = luna.platform.getArgs()
    if args["--smoke"] then
        luna.signal.quit()
    end
end
```

## Examples README

`examples/README.md` and `demos/README.md` must stay alphabetically sorted and must link to each file/folder with a one-line description.

Format:
```markdown
| File/Folder | Demonstrates |
|---|---|
| `audio.lua` | `luna.audio.*` — source loading, playback, volume |
| `physics.lua` | `luna.physics.*` — world, bodies, collision |
```

Update both README files whenever a new example or demo is added.

## Anti-Patterns

- **Assets in examples/**: Resources that require manual download or aren't embedded — examples must be self-contained
- **Stale demos**: Demos that use removed API functions (`luna.old.func`) — run demos on every release to catch breakage
- **Debug-print noise**: `print("test")` or `print(val)` left in committed examples
- **Missing README entry**: Adding an example without updating `examples/README.md`

## Lua API Compliance

These rules apply to all files in `examples/` and `demos/`:

### Input Key Names

Key names must match the engine canonical map exactly — always lowercase, never platform names:

```lua
-- CORRECT
if luna.keyboard.isDown("space") then
if luna.keyboard.isDown("escape") then
if luna.keyboard.isDown("up") then     -- "up", "down", "left", "right"
if luna.keyboard.isDown("w") then      -- single letter, lowercase

-- WRONG
if luna.keyboard.isDown("Space") then  -- uppercase
if luna.keyboard.isDown("SPACE") then  -- all-caps
if luna.keyboard.isDown("VK_SPACE") then  -- platform key name
```

Canonical set: `"space"`, `"escape"`, `"up"`, `"down"`, `"left"`, `"right"`, single letter keys `"a"`–`"z"`, `"return"`, `"tab"`, `"backspace"`.

### Color Values

Color component values must be in `[0.0, 1.0]` range — **never** `[0, 255]`:

```lua
-- CORRECT
luna.gfx.setColor(1.0, 0.0, 0.0, 1.0)    -- red, full opacity
luna.gfx.setColor(0.5, 0.5, 0.5, 1.0)    -- mid-gray

-- WRONG
luna.gfx.setColor(255, 0, 0, 255)         -- byte range, not float
```

### Rectangle Draw Mode

`luna.gfx.rectangle()` takes a string mode as its first arg — not a boolean:

```lua
-- CORRECT
luna.gfx.rectangle("fill", x, y, w, h)
luna.gfx.rectangle("line", x, y, w, h)

-- WRONG
luna.gfx.rectangle(true, x, y, w, h)   -- boolean does not work
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

| Rule | `demos/` | `examples/` |
|------|---------|------------|
| `require()` | ❌ No — must be single-file, self-contained | ✅ May use `require("library.*")` for shipped Lunasome modules |
| `os.*` / `io.*` system calls | ❌ Never — use `luna.fs.*` for file access | ❌ Never |
| `conf.lua` | ✅ Required for each demo folder | ❌ Not applicable (single-file) |
