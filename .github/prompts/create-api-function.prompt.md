---
description: "Add one new lurek.* API function with tests and synced docs."
agent: "Developer"
tools: [tools/docs/gen_lua_api_data.py, tools/docs/gen_luadoc.py]
---
# Create API Function

## Goal
- Add one new Lua API function without widening scope.

## Inputs
- Module.
- Function name.
- Lua-visible behavior.
- Parameters and return shape.

## Steps
1. Load [skill: lua-api-design](../skills/lua-api-design/SKILL.md), [skill: rust-coding](../skills/rust-coding/SKILL.md), [skill: lua-rust-bridge](../skills/lua-rust-bridge/SKILL.md), and [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read src/lua_api/<module>_api.rs, the matching src/<module>/ code, docs/specs/<module>.md, and nearby tests or examples before editing.
3. Implement the binding in the thinnest API layer, keep business logic out of src/lua_api/, and update source docstrings instead of hand-editing generated API docs.
4. Run the narrowest Lua or Rust test for the new function, regenerate Lua API docs from source if the public API changed, and finish with the required broader gate.

## Success Criteria
- [ ] The prompt goal was completed: Add one new Lua API function without widening scope.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Hand-edit docs/api/lurek.md or docs/api/lurek.lua instead of changing the source docstrings and generators.
- Put business logic into src/lua_api/ when the domain module should own it.
- Add a new public API shape without checking nearby lurek.* naming and return conventions.

## Example Invocation
- /create-api-function module=graphics function=drawGrid

## CAG Metadata
Mode: agent
Loads skills: lua-api-design, rust-coding, lua-rust-bridge, testing-rust
Inputs required: Module., Function name., Lua-visible behavior., Parameters and return shape.
