---
description: "Create a new Lua game example in the examples/ directory with main.lua and all required assets."
---

# Create Game Example

## Purpose

Create a new Lua game example that demonstrates specific Luna2D features.

## Use When

- Demonstrating a new engine feature
- Creating a tutorial example
- Adding a showcase game

## Do Not Use When

- Modifying an existing example
- Writing documentation without code

## Inputs

- **Example name**: directory name (lowercase, underscore-separated)
- **Features demonstrated**: which `luna.*` APIs to showcase
- **Complexity level**: minimal / intermediate / advanced

## Steps

1. Create directory `examples/<name>/`
2. Write `examples/<name>/main.lua` with `luna.load()`, `luna.update(dt)`, `luna.draw()`
3. Use only `luna.*` API functions (never external engine prefixes)
4. Use `local` for all variables (no globals except luna callbacks)
5. Multiply movement by `dt` for frame-rate independence
6. Add comments explaining key concepts
7. Test with `cargo run -- examples/<name>`

## Outputs

- `examples/<name>/main.lua` — working game script
- Optional asset files (images, sounds) in the example directory

## Acceptance

- [ ] Runs with `cargo run -- examples/<name>` without errors
- [ ] Uses only `luna.*` API
- [ ] All variables are `local`
- [ ] Movement uses `dt` for frame independence
- [ ] Code is commented for learning

## References

- `lua-scripting` skill
- `docs/lua_api_reference.md`
- Existing examples in `examples/`
