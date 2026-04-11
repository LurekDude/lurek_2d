---
name: demo-creation
description: "Load this skill when creating one or more new demo projects in content/demos/. Use when: scaffolding a demo from a genre or feature description; generating conf.lua + main.lua + README.md + screen.png; registering a new demo in content/demos/README.md; using content/library/ modules alongside lurek.* API; creating batches of demos from a list of genres or specific needs. Skip it for content/examples/ single-file scripts (use examples-management skill), test writing, or engine Rust code."
argument-hint: "genre, count, features, library modules, resolution, complexity"
---

# Demo Creation — Lurek2D

## Load When

- Generating a new `content/demos/<name>/` project from scratch
- Scaffolding multiple demos in one pass (batch creation)
- A demo uses `content/library/` modules alongside `lurek.*`
- You need the full 4-file bundle: `conf.lua`, `main.lua`, `README.md`, `screen.png`
- Registering a newly created demo in `content/demos/README.md`

## Owns

- `content/demos/<name>/` folder scaffold and 4-file bundle
- `conf.lua` resolution variants and module flag conventions
- `main.lua` canonical section order and mandatory invariants
- `README.md` 5-section template and accuracy rules
- `screen.png` generation via `tools/screenshots/gen_demo_screenshots.py`
- `content/demos/README.md` table entry and detail block registration
- `content/library/` module integration patterns (`dialog`, `item`, `inventory`)
- Genre-to-API mapping guidance
- Batch demo creation workflow

## Does Not Cover

- `content/examples/` single-file scripts → use `examples-management` skill
- Engine Rust changes needed by a demo → use `rust-coding` + `lua-rust-bridge` skills
- Physics simulation internals → use `lua-scripting` skill alongside this one
- Stubs and incomplete `content/library/` modules (check [library-integration](./references/library-integration.md) before picking a module)

## Required Output — 4-File Bundle

Every demo **must** produce exactly these four artifacts (no more, no fewer unless assets folder is needed):

| File | Required | Notes |
|------|----------|-------|
| `content/demos/<name>/conf.lua` | Yes | Window config, title, resolution, modules |
| `content/demos/<name>/main.lua` | Yes | Game entry point — canonical structure below |
| `content/demos/<name>/README.md` | Yes | 5-section doc, see template |
| `content/demos/<name>/screen.png` | Yes | Auto-generated via screenshot tool |

Optional additions:
- `content/demos/<name>/assets/` — sprites, sounds, tilemaps (commit only what the demo runs)
- `content/demos/<name>/save/` — auto-created at runtime by smoke tests; never scaffold this manually

---

## Step-by-Step Procedure

### Step 1 — Derive the Demo Name

- Format: `lowercase_underscore` (e.g., `tower_defense`, `bullet_hell`)
- No spaces, no hyphens, no version numbers
- Must not duplicate an existing `content/demos/` folder — check with `Get-ChildItem content/demos/`

### Step 2 — Write `conf.lua`

See [conf-templates](./references/conf-templates.md) for resolution variants and module flags.

**Minimal template** (use this unless the demo needs a non-standard size):
```lua
function lurek.conf(t)
    t.window.title  = "<Demo Title>"
    t.window.width  = 800
    t.window.height = 600
    t.performance.target_fps = 60
end
```

Acceptable non-standard resolutions (must leave a comment explaining why):
- `960 × 540` — 16:9 sidescrollers or platformers
- `800 × 640` — demos with on-screen message logs or status strips
- `1024 × 768` — strategy overviews, maps, tactical views

Add module flags only when the demo actually needs them:
```lua
    t.modules.physics  = true   -- only if lurek.physics.* is used
    t.modules.audio    = false  -- suppress audio init if demo is silent
```

### Step 3 — Write `main.lua`

**Canonical section order — never rearrange:**
```lua
-- content/demos/<name>/main.lua
-- <Demo Title> — <one-sentence description of what it demonstrates>
-- Controls: <brief key list>
-- Run with: cargo run -- content/demos/<name>

-- ── state ─────────────────────────────────────────────────────
-- (module-level locals: tables, IDs, constants)

-- ── helpers ───────────────────────────────────────────────────
-- (utility functions: generators, collision, math helpers)

-- ── load ──────────────────────────────────────────────────────
function lurek.init()
    lurek.window.setTitle("<Demo Title>")
    lurek.gfx.setBackgroundColor(0.08, 0.08, 0.12)
    -- resource creation, world setup, initial state
end

-- ── update ────────────────────────────────────────────────────
function lurek.process(dt)
    -- input polling, simulation step, game logic
    -- always present, even if body is empty
end

-- ── draw ──────────────────────────────────────────────────────
function lurek.render()
    -- all rendering; HUD drawn last, unaffected by camera transforms
end

-- ── keypressed ────────────────────────────────────────────────
function lurek.keypressed(key)
    if key == "escape" then lurek.signal.quit() end
    -- discrete events: jump, restart, action
end
```

**Mandatory invariants:**
- All state in module-level `local` variables — no globals except callbacks
- `lurek.window.setTitle()` called first in `lurek.load()`
- `lurek.gfx.setBackgroundColor()` called in `lurek.load()`
- Movement multiplied by `dt` for frame-rate independence
- `escape` → `lurek.signal.quit()` always present in `lurek.keypressed`
- All 4 callbacks defined, even if `update` is empty
- No `print()` — use `lurek.gfx.print()` for on-screen text, `lurek.log.debug()` for diagnostics

**Size guidelines:**

| Complexity | Lines | Examples |
|------------|-------|---------|
| Minimal | 50–100 | `hello_world` |
| Simple | 100–160 | `sprites`, `physics_demo` |
| Standard | 160–300 | `platformer`, `card_game` |
| Complex | 300–400 | `roguelike`, `deckbuilder` |

Never exceed 400 lines — if logic grows larger, extract helpers or split into multiple demos.

### Step 4 — Library Modules

When the prompt requests `content/library/` modules, see [library-integration](./references/library-integration.md) for full patterns. Quick reference:

**Import pattern** (always at top of file, after header comment):
```lua
local dialog    = require("library.dialog")
local item      = require("library.item")
local inventory = require("library.inventory")
```

**Only use modules with ✅ Full status** (stub modules are unusable):

| Module | Status | What It Provides |
|--------|--------|-----------------|
| `library.dialog` | ✅ Full | Typewriter sequencer, branching choices, event callbacks |
| `library.item` | ✅ Full | Item type definitions, instance creation, stat lookup |
| `library.inventory` | ✅ Full | Slot-based inventory management |
| `library.province_map` | ✅ Proxy | Province/region map (wraps `lurek.province`) |
| `library.battle`, `.stats`, `.economy`, `.crafting`, `.cardgame`, `.combat`, `.quest` | 🔧 Stub | Do NOT use — causes runtime errors |

Call library functions at the top of `lurek.load()` before any `lurek.*` drawing setup:
```lua
function lurek.init()
    -- library init first
    item.clearTypes()
    item.defineType("sword", { category = "weapon", base_stats = { attack = 10 } })
    inv = inventory.new(20)
    -- then window + graphics setup
    lurek.window.setTitle("Loot Demo")
    lurek.gfx.setBackgroundColor(0.05, 0.05, 0.1)
end
```

### Step 5 — Write `README.md`

```markdown
# <Demo Title>

<One-sentence summary of what this demo shows.>

## What It Demonstrates

- `lurek.<namespace>.<function>()` — brief note on how it's used
- `lurek.<namespace>.<function>()` — brief note
- `library.<module>` — if applicable

## How to Run

```bash
cargo run -- content/demos/<name>
```

## Controls

| Key | Action |
|-----|--------|
| Escape | Quit |
| <Key> | <Action> |

## Notes

- <Optional: 2–4 bullets on non-obvious design choices or limitations>
```

**Rules:**
- `## What It Demonstrates` must list `lurek.*` calls actually present in `main.lua`
- Controls table must match `lurek.keypressed` handler exactly
- `## Notes` section is optional — omit if nothing non-obvious to say

### Step 6 — Generate `screen.png`

After writing all Lua files, generate `screen.png` with the screenshot tool:

```powershell
# Single demo
python tools/screenshots/gen_demo_screenshots.py --demo <name> --overwrite --frames 3

# Multiple demos at once
python tools/screenshots/gen_demo_screenshots.py --demo <name1> --demo <name2> --overwrite --frames 3

# All demos missing a screen.png
python tools/screenshots/gen_demo_screenshots.py --frames 3
```

Requirements: the release binary must exist (`cargo build --release` or use `--rebuild` flag).

If the binary is fresh:
```powershell
python tools/screenshots/gen_demo_screenshots.py --demo <name> --overwrite --frames 3 --rebuild
```

### Step 7 — Register in `content/demos/README.md`

Append to the `## Demo Index` table:
```markdown
| [<name>](#<name>) | <4–8 word description> | `<ns1>`, `<ns2>`, `<ns3>` |
```

Then append a detail block at the end of the per-demo sections:
```markdown
## <name>

<One paragraph (2–3 sentences) describing what the demo shows and why it's interesting.>

**Key APIs**: `lurek.<ns>.<fn>`, `lurek.<ns>.<fn>`, optionally `library.<module>`

| Key | Action |
|-----|--------|
| Escape | Quit |

```bash
cargo run -- content/demos/<name>
```

---
```

---

## Batch Creation Workflow

When generating N > 1 demos from a list of genres:

1. Derive names for all demos first — confirm no name collisions
2. Generate `conf.lua` + `main.lua` for each in order
3. Generate all `README.md` files
4. Run screenshot tool for all at once:
   ```powershell
   python tools/screenshots/gen_demo_screenshots.py --demo <n1> --demo <n2> ... --overwrite --frames 3
   ```
5. Register all demos in `content/demos/README.md` in one edit (alphabetical order)

---

## Genre → API Mapping Reference

See [genre-patterns](./references/genre-patterns.md) for a pre-mapped table of common genres and their recommended `lurek.*` API namespaces, library modules, and structural patterns.

---

## Quality Checklist

Before marking a demo complete:

- [ ] `conf.lua` — title matches demo name, valid resolution, target_fps = 60
- [ ] `main.lua` — all 4 callbacks present; `escape` quits; no globals; dt used for movement
- [ ] `main.lua` — only `lurek.*` API calls and optionally approved `library.*` requires
- [ ] `main.lua` — no `print()` statements; debug output via `lurek.log.debug()`
- [ ] `README.md` — 4 required sections present; `What It Demonstrates` matches actual code
- [ ] `screen.png` — generated and present (non-zero file size)
- [ ] `content/demos/README.md` — table entry added; detail block added
- [ ] `cargo run -- content/demos/<name>` — runs without errors or unhandled exceptions
- [ ] `cargo check` — no type errors introduced
