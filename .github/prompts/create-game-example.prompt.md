---
description: Create a new Lua game example in the content/examples/ directory with main.lua and all required assets.
agent: Developer
---
# Create Game Example

## Goal

Create a new Lua game example that demonstrates specific Lurek2D features.

## Inputs

- **Example name**: directory name (lowercase, underscore-separated)
- **Features demonstrated**: which `lurek.*` APIs to showcase
- **Complexity level**: minimal / intermediate / advanced

## Steps

1. Load [skill: documentation](.github/skills/documentation/SKILL.md), [skill: lua-scripting](.github/skills/lua-scripting/SKILL.md) before changing any files.
2. Create directory `content/examples/<name>/`
3. Write `content/examples/<name>/main.lua` with `lurek.load()`, `lurek.update(dt)`, `lurek.draw()`
4. Use only `lurek.*` API functions (never external engine prefixes)
5. Use `local` for all variables (no globals except luna callbacks)
6. Multiply movement by `dt` for frame-rate independence
7. Add comments explaining key concepts
8. Test with `cargo run -- content/examples/<name>`

## Success Criteria

- [ ] `content/examples/<name>/main.lua` — working game script
- [ ] Optional asset files (images, sounds) in the example directory

## Anti-patterns

- Modifying an existing example
- Writing documentation without code

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/create-game-example <name>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: documentation, lua-scripting
- **Inputs required**: name
