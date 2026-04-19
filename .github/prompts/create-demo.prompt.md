---
description: "Create one or more new Lurek2D demo projects in content/demos/. Generates conf.toml, main.lua, README.md, and screen.png for each demo. U..."
agent: Developer
tools: [tools/screenshots/gen_demo_screenshots.py]
---
# Create Demo

## Goal

Create one or more new Lurek2D demo projects in content/demos/. Generates conf.toml, main.lua, README.md, and screen.png for each demo. U... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `n1` — value supplied by the user invocation.
- `n2` — value supplied by the user invocation.
- `name` — value supplied by the user invocation.

## Steps

1. Load [skill: demo-creation](.github/skills/demo-creation/SKILL.md), [skill: lua-scripting](.github/skills/lua-scripting/SKILL.md) before changing any files.
2. Read this prompt's Inputs and confirm every required argument is present.
3. Load any skill listed in `loads_skills` of this prompt's frontmatter.
4. Execute the work as the `Developer` agent.
5. Run the relevant quality gates from the [skill: quality-pipeline](.github/skills/quality-pipeline/SKILL.md) before declaring done.
6. Consult the actual `lurek.*` API surface via [docs/API/lua-api.md](docs/API/lua-api.md), [content/examples/](content/examples/), and [docs/specs/](docs/specs/). Do NOT invent APIs.

## Success Criteria

- [ ] `cargo run -- content/demos/<name>` runs without errors
- [ ] All 4 callbacks are defined in `main.lua`
- [ ] `escape` quits via `lurek.signal.quit()`
- [ ] No undeclared globals, no bare `print()` calls
- [ ] `screen.png` exists and is non-empty
- [ ] `content/demos/README.md` table row and detail block both added
- [ ] Only ✅ Full library modules are required (if any)
- [ ] `cargo check` passes with no new errors

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

```
/create-demo platformer with camera shake and coin collection
/create-demo roguelike, 2 demos, one with inventory items
/create-demo card game, complex, use library.item and library.inventory
/create-demo bullet hell shooter, minimal complexity, 960x540
/create-demo dialog-driven mystery, use library.dialog
```

---

## CAG Metadata

- **Mode**: agent
- **Loads skills**: demo-creation, lua-scripting
- **Inputs required**: n1, n2, name
