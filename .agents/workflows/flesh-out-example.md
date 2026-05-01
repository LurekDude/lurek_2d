---
description: "Expand or improve a thin or placeholder Lua example into a clear, real-API-using demonstration."
---

# Flesh Out Example

## Goal
- Expand one placeholder or thin example into a clear, real lurek.* demonstration.

## Inputs
- Target example file.
- Desired concept or coverage goal.
- Any gaps or placeholder patterns to remove.

## Steps
1. Load lua-scripting and examples-management before acting.
2. Read the target example, docs/api/lurek.md for the relevant namespace, and nearby finished examples.
3. Replace placeholder calls with realistic lurek.* usage; keep state in locals and separate callbacks.
4. Keep the example self-contained and focused on exactly one concept.
5. Update the README note if one exists for this example.
6. Confirm the script runs without errors.

## Success Criteria
- [ ] All placeholder content is replaced with real lurek.* usage.
- [ ] The example demonstrates exactly one concept.
- [ ] Script runs without Lua errors.

## Anti-patterns
- Add real game logic that obscures the API concept.
- Mix multiple API namespaces into one example.
- Leave bare globals or placeholder stubs.

## Example Invocation
- /flesh-out-example target=content/examples/tilemap.lua goal=layer_api_coverage
