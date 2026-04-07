---
description: "Create one or more new Luna2D demo projects in demos/. Generates conf.lua, main.lua, README.md, and screen.png for each demo. Use when: scaffolding demos from genre descriptions; creating batch demos from a list; adding demos that use library/ modules. Inputs: genre, count, specific luna.* features, library modules, resolution, complexity."
name: "Create Demo"
argument-hint: "genre(s), count, features, library modules, resolution, complexity"
agent: agent
---

# Create Luna2D Demo Project(s)

## Instructions for the Agent

Load skill `demo-creation` before generating any files.
Also load skill `lua-scripting` for Lua coding patterns and API conventions.

---

## Inputs

Collect the following from the user's request. All inputs except `GENRE` are optional.

| Input | Description | Default |
|-------|-------------|---------|
| `GENRE` | Game genre(s) — e.g. "platformer", "roguelike", "card game and deck builder" | Required |
| `COUNT` | Number of demos to create | 1 |
| `FEATURES` | Specific `luna.*` API calls or game mechanics to showcase — e.g. "physics stacking, camera shake" | Infer from genre |
| `LIBRARY_MODULES` | `library/` modules to use — e.g. "dialog", "item + inventory" | None |
| `RESOLUTION` | Window size — e.g. "960×540", "widescreen", "tall for log" | Infer from genre using [genre-patterns](../skills/demo-creation/references/genre-patterns.md) |
| `COMPLEXITY` | `minimal` / `standard` / `complex` | `standard` |
| `EXTRA_NOTES` | Any specific needs, mechanics, themes, or constraints stated by the user | — |

---

## What to Produce

For each demo requested, produce the **complete 4-file bundle**:

1. `demos/<name>/conf.lua`
2. `demos/<name>/main.lua`
3. `demos/<name>/README.md`
4. `demos/<name>/screen.png` — via screenshot tool (see Step 6 in skill)

Then for **all demos in this run**, update:
5. `demos/README.md` — add table entry + detail block for each new demo

---

## Procedure

### 1. Derive Demo Name(s)
- Format: `lowercase_underscore` (e.g. `tile_puzzle`, `rogue_shooter`)
- If `COUNT` > 1, derive `COUNT` distinct name variants from the provided genre(s)
- Confirm no name already exists: check `demos/` folder listing

### 2. Choose API Surface
- Consult [genre-patterns](../skills/demo-creation/references/genre-patterns.md)
  for the recommended `luna.*` namespaces and library modules per genre
- If `FEATURES` explicitly specifies APIs, those take priority over the genre default
- If `LIBRARY_MODULES` is requested, verify each is ✅ Full status in
  [library-integration](../skills/demo-creation/references/library-integration.md)
  — **never scaffold a demo that requires a 🔧 Stub module**

### 3. Write `conf.lua`
- Pick the right resolution template from [conf-templates](../skills/demo-creation/references/conf-templates.md)
  matching the genre and `RESOLUTION` input
- Add module flags only when the demo requires a non-default module state

### 4. Write `main.lua`
- Follow the canonical section order from the `demo-creation` skill exactly:
  header comment → state locals → helpers → `luna.load` → `luna.update` → `luna.draw` → `luna.keypressed`
- Complexity sizing:
  - `minimal` → 50–100 lines
  - `standard` → 100–300 lines
  - `complex` → 300–400 lines (hard cap)
- Library modules: add `require()` calls immediately after the header comment block
- Implement at least the core mechanic loop and one win/fail/progress state
- Controls: `escape` always quits, plus at least 2 meaningful interactions
- No `print()` statements — use `luna.gfx.print()` for on-screen text

### 5. Write `README.md`
- Template from `demo-creation` skill: 4 required sections + optional `## Notes`
- `## What It Demonstrates` must match the `luna.*` calls actually in `main.lua`
- Controls table must match the `luna.keypressed` handler exactly

### 6. Generate `screen.png`
Run the following after Lua files are written:
```powershell
python tools/screenshots/gen_demo_screenshots.py --demo <name> --overwrite --frames 3
```
For multiple demos:
```powershell
python tools/screenshots/gen_demo_screenshots.py --demo <n1> --demo <n2> --overwrite --frames 3
```
If the binary is missing, add `--rebuild` to trigger a release build first.

### 7. Register in `demos/README.md`
- Append table row to the `## Demo Index` table (preserve alphabetical order within genre group)
- Append full detail block at end of the per-demo sections

---

## Acceptance Gates

Each demo is complete when:

- [ ] `cargo run -- demos/<name>` runs without errors
- [ ] All 4 callbacks are defined in `main.lua`
- [ ] `escape` quits via `luna.signal.quit()`
- [ ] No undeclared globals, no bare `print()` calls
- [ ] `screen.png` exists and is non-empty
- [ ] `demos/README.md` table row and detail block both added
- [ ] Only ✅ Full library modules are required (if any)
- [ ] `cargo check` passes with no new errors

---

## Examples of Invocation

```
/create-demo platformer with camera shake and coin collection
/create-demo roguelike, 2 demos, one with inventory items
/create-demo card game, complex, use library.item and library.inventory
/create-demo bullet hell shooter, minimal complexity, 960x540
/create-demo dialog-driven mystery, use library.dialog
```

---

## References

**Skills (load before working)**:
- [demo-creation skill](../skills/demo-creation/SKILL.md) — full procedure
- [lua-scripting skill](../skills/lua-scripting/SKILL.md) — API and Lua patterns

**API reference**:
- [docs/API/lua-api.md](../../docs/API/lua-api.md) — full `luna.*` reference
- [examples/](../../examples/) — single-file API illustrations for any namespace

**Existing demos**:
- [demos/hello_world/main.lua](../../demos/hello_world/main.lua) — minimal pattern
- [demos/platformer/main.lua](../../demos/platformer/main.lua) — physics + camera pattern
- [demos/roguelike/main.lua](../../demos/roguelike/main.lua) — turn-based + procedural pattern
- [demos/dialog_demo/main.lua](../../demos/dialog_demo/main.lua) — library.dialog pattern
- [demos/loot_rpg_demo/main.lua](../../demos/loot_rpg_demo/main.lua) — library.item + inventory pattern

**Screenshot tool**:
```powershell
python tools/screenshots/gen_demo_screenshots.py --help
```
