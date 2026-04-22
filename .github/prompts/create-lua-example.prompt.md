---
description: Create a new self-contained Lua example game in content/examples/. Use when demonstrating a Lurek2D API feature or workflow. Produces a r...
---
# Create Lua Example

## Goal

Create a new self-contained Lua example game in content/examples/. Use when demonstrating a Lurek2D API feature or workflow. Produces a r... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `EXAMPLE_NAME` — directory name, lowercase with hyphens (e.g., `particle-demo`, `audio-demo`)
- `CONCEPT` — what API feature or game mechanic this demonstrates (e.g., "keyboard-controlled movement", "physics stacking")
- `COMPLEXITY` — `simple` (< 50 lines) or `full` (< 100 lines)

## Steps

1. Load [skill: lua-scripting](.github/skills/lua-scripting/SKILL.md) before changing any files.
2. Load skill `lua-scripting/SKILL.md`
3. Create directory `content/examples/<EXAMPLE_NAME>/`
4. Write `content/examples/<EXAMPLE_NAME>/main.lua` with:
5. `local` variables for all state
6. `function lurek.init()` — initialization
7. `function lurek.process(dt)` — frame logic
8. `function lurek.render()` — rendering only
9. Optionally: `lurek.keypressed`, `lurek.input.mousepressed` callbacks
10. Check all API calls against `docs/lua-api.md`:
11. Colors: `[0.0, 1.0]` float range
12. Shapes: `("fill"/"line", x, y, ...)`

## Success Criteria

- [ ] `content/examples/<EXAMPLE_NAME>/main.lua` — working, commented Lua script
- [ ] Any required assets in `content/examples/<EXAMPLE_NAME>/` (images, audio)
- [ ] Verified: `cargo run -- content/examples/<EXAMPLE_NAME>` opens a window without errors

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-lua-example <EXAMPLE_NAME>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: lua-scripting
- **Inputs required**: EXAMPLE_NAME
