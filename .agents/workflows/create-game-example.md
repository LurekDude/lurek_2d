---
description: "Create a new focused Lua game example in content/examples/ demonstrating one API concept."
---

# Create Game Example

## Goal
- Create one runnable, self-contained Lua example for a specific API concept.

## Inputs
- Target lurek.* namespace or feature.
- Output path (content/examples/).
- Concept to demonstrate.

## Steps
1. Load lua-scripting and examples-management before acting.
2. Read docs/api/lurek.md and content/examples/ for the target namespace.
3. Write a focused example using only lurek.* calls; keep state in locals, separate callbacks.
4. Add or update a README note for the example if one exists.
5. Confirm the script runs without Lua errors.

## Success Criteria
- [ ] Script runs without error.
- [ ] Uses only lurek.* — no bare globals.
- [ ] Demonstrates exactly one API concept.
- [ ] Fits the existing content/examples/ structure.

## Example Invocation
- /create-game-example target=lurek.sprite concept=animation_frames
