---
description: "Create a new self-contained Lua example."
---

# Create Lua Example

## Goal
- Create a new self-contained Lua example game in content/examples/. Use when demonstrating a Lurek2D API feature or workflow. Produces a r...

## Inputs
- EXAMPLE_NAME directory name, lowercase with hyphens (e.g., particle-demo, audio-demo)
- CONCEPT what API feature or game mechanic this demonstrates (e.g., "keyboard-controlled movement", "physics stacking")
- COMPLEXITY simple (< 50 lines) or full (< 100 lines)

## Steps
- Load lua-scripting before changing any files.
- Load skill lua-scripting/SKILL.md
- Create directory content/examples/<EXAMPLE_NAME>/
- Write content/examples/<EXAMPLE_NAME>/main.lua with:
- local variables for all state
- function lurek.init() initialization
- function lurek.process(dt) frame logic
- function lurek.draw() rendering only
- Optionally: lurek.keypressed, lurek.input.mousepressed callbacks
- Check all API calls against docs/api/lurek.md:
- Colors: [0.0, 1.0] float range
- Shapes: ("fill"/"line", x, y, ...)

## Success Criteria
- [ ] content/examples/<EXAMPLE_NAME>/main.lua working, commented Lua script
- [ ] Any required assets in content/examples/<EXAMPLE_NAME>/ (images, audio)
- [ ] Verified: cargo run -- content/examples/<EXAMPLE_NAME> opens a window without errors

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /create-lua-example <EXAMPLE_NAME>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: lua-scripting
- **Inputs required**: EXAMPLE_NAME
