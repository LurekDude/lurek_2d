---
name: demo-creation
description: "Load this skill when creating one or more new demo projects in content/demos/. Use when: scaffolding a demo from a genre or feature description; generating conf.lua + main.lua + README.md + screen.png; registering a new demo in content/demos/README.md; using content/library/ modules alongside lurek.* API; creating batches of demos from a list of genres or specific needs. Skip it for content/examples/ single-file scripts (use examples-management skill), test writing, or engine Rust code."
---
# demo-creation

## Mission

# Demo Creation — Lurek2D

## When To Load

- Generating a new `content/demos/<name>/` project from scratch
- Scaffolding multiple demos in one pass (batch creation)
- A demo uses `content/library/` modules alongside `lurek.*`
- You need the full 4-file bundle: `conf.toml`, `main.lua`, `README.md`, `screen.png`
- Registering a newly created demo in `content/demos/README.md`

## When To Skip

- `content/examples/` single-file scripts → use `examples-management` skill
- Engine Rust changes needed by a demo → use `rust-coding` + `lua-rust-bridge` skills
- Physics simulation internals → use `lua-scripting` skill alongside this one
- Stubs and incomplete `content/library/` modules (check [library-integration](./references/library-integration.md) before picking a module)

## Domain Knowledge

### Owns
- `content/demos/<name>/` folder scaffold and 4-file bundle
- `conf.toml` resolution variants and module flag conventions
- `main.lua` canonical section order and mandatory invariants
- `README.md` 5-section template and accuracy rules
- `screen.png` generation via `tools/demos/gen_demo_screenshots.py`
- `content/demos/README.md` table entry and detail block registration
- `content/library/` module integration patterns (`dialog`, `item`, `inventory`)
- Genre-to-API mapping guidance
- Batch demo creation workflow

### Required Output — 4-File Bundle
Every demo **must** produce exactly these four artifacts (no more, no fewer unless assets folder is needed):

| File | Required | Notes |
|------|----------|-------|
| `content/demos/<name>/conf.toml` | Yes | Window config, title, resolution, modules |
| `content/demos/<name>/main.lua` | Yes | Game entry point — canonical structure below |
| `content/demos/<name>/README.md` | Yes | 5-section doc, see template |
| `content/demos/<name>/screen.png` | Yes | Auto-generated via screenshot tool |

Optional additions:
- `content/demos/<name>/assets/` — sprites, sounds, tilemaps (commit only what the demo runs)
- `content/demos/<name>/save/` — auto-created at runtime by smoke tests; never scaffold this manually

---

### Step-by-Step Procedure
### Step 1 — Derive the Demo Name

- Format: `lowercase_underscore` (e.g., `tower_defense`, `bullet_hell`)
- No spaces, no hyphens, no version numbers
- Must not duplicate an existing `content/demos/` folder — check with `Get-ChildItem content/demos/`

### Step 2 — Write `conf.toml`

See [conf-templates](./references/conf-templates.md) for TOML resolution templates and module flags.

**Minimal template** (use this unless the demo needs a non-standard size):
> See [templates/step-2-write-conf-toml.toml](templates/step-2-write-conf-toml.toml) for the example.

Acceptable non-standard resolutions (must leave a comment explaining why):
- `960 × 540` — 16:9 sidescrollers or platformers
- `800 × 640` — demos with on-screen message logs or status strips
- `1024 × 768` — strategy overviews, maps, tactical views

Add module flags only when the demo actually needs them:
> See [templates/step-2-write-conf-toml-2.toml](templates/step-2-write-conf-toml-2.toml) for the example.

### Step 3 — Write `main.lua`

**Canonical section order — never rearrange:**
> See [examples/step-3-write-main-lua.lua](examples/step-3-write-main-lua.lua) for the example.

**Mandatory invariants:**
- All state in module-level `local` variables — no globals except callbacks
- `lurek.window.setTitle()` called first in `lurek.load()`
- `lurek.gfx.setBackgroundColor()` called in `lurek.load()`
- Movement multiplied by `dt` for frame-rate independence
- `escape` → `lurek.signal.quit()` always present in `lurek.keypressed`
- All 4 callbacks defined, even if `update` is empty
- No `print()` — use `lurek.gfx.print()` for on-screen text, `lurek.log.debug()` for diagnostics


> See [snippets/extended-notes.md](snippets/extended-notes.md) for additional notes.

## Companion File Index

- [templates/step-2-write-conf-toml.toml](templates/step-2-write-conf-toml.toml) — Step 2 — Write `conf.toml`
- [templates/step-2-write-conf-toml-2.toml](templates/step-2-write-conf-toml-2.toml) — Step 2 — Write `conf.toml`
- [examples/step-3-write-main-lua.lua](examples/step-3-write-main-lua.lua) — Step 3 — Write `main.lua`
- [examples/step-4-library-modules.lua](examples/step-4-library-modules.lua) — Step 4 — Library Modules
- [examples/step-4-library-modules-2.lua](examples/step-4-library-modules-2.lua) — Step 4 — Library Modules
- [snippets/step-5-write-readme-md.md](snippets/step-5-write-readme-md.md) — Step 5 — Write `README.md`
- [snippets/notes.txt](snippets/notes.txt) — Notes
- [snippets/notes-2.ps1](snippets/notes-2.ps1) — Notes
- [snippets/step-7-register-in-content-demos.md](snippets/step-7-register-in-content-demos.md) — Step 7 — Register in `content/demos/README.md`
- [snippets/step-7-register-in-content-demos-2.md](snippets/step-7-register-in-content-demos-2.md) — Step 7 — Register in `content/demos/README.md`
- [snippets/extended-notes.md](snippets/extended-notes.md) — extended notes (overflow)

## References

- See related skills in `.github/skills/`.
