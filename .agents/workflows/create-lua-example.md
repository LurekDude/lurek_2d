---
description: "Create or update a Lua game script example demonstrating one lurek.* API area."
---

# Create Lua Example

## Goal
- Produce a clear, runnable Lua example for one API area.

## Inputs
- Target lurek.* namespace or feature.
- Output location (content/examples/ or content/games/).

## Steps
1. Load lua-scripting before acting.
2. Read docs/api/lurek.md and content/examples/ for the target namespace before writing.
3. Write the example using lurek.* only. Keep state in locals, separate init/process/render/input/teardown, and multiply time-based values by dt.
4. Confirm the script runs under lurek or the test harness without errors.
5. If adding a new example to content/examples/, update the relevant index or README if one exists.

## Success Criteria
- [ ] Script runs without error.
- [ ] Uses only lurek.* — no bare globals.
- [ ] Callback roles are clearly separated.
- [ ] dt is used for all time-based values.

## Example Invocation
- /create-lua-example target=lurek.sprite output=content/examples/sprite.lua
