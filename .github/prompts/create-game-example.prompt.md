---
description: "Create a new Lua game example in content/examples/."
---

# Create Game Example

## Goal
- Create a new Lua game example that demonstrates specific Lurek2D features.

## Inputs
- **Example name**: directory name (lowercase, underscore-separated)
- **Features demonstrated**: which lurek.* APIs to showcase
- **Complexity level**: minimal / intermediate / advanced

## Steps
- Load documentation, lua-scripting before changing any files.
- Create directory content/examples/<name>/
- Write content/examples/<name>/main.lua with lurek.load(), lurek.update(dt), lurek.draw()
- Use only lurek.* API functions (never external engine prefixes)
- Use local for all variables (no globals except lurek callbacks)
- Multiply movement by dt for frame-rate independence
- Add comments explaining key concepts
- Test with cargo run -- content/examples/<name>

## Success Criteria
- [ ] content/examples/<name>/main.lua working game script
- [ ] Optional asset files (images, sounds) in the example directory

## Anti-patterns
- Modifying an existing example
- Writing documentation without code

## Example Invocation
- /create-game-example <name>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: documentation, lua-scripting
- **Inputs required**: name
