---
description: "Implement one lurek.* Lua API module with the required bindings, tests, and doc sync."
agent: "Developer"
tools: [tools/docs/gen_lua_api_data.py, tools/docs/gen_luadoc.py]
---
# Implement Lua API Module

## Goal
- Implement one bounded Lua API module from an accepted contract.

## Inputs
- Module.
- Accepted API contract.
- Target source paths.
- Required validation path.

## Steps
1. Load [skill: lua-api-design](../skills/lua-api-design/SKILL.md), [skill: lua-rust-bridge](../skills/lua-rust-bridge/SKILL.md), [skill: rust-coding](../skills/rust-coding/SKILL.md), and [skill: testing-rust](../skills/testing-rust/SKILL.md) before acting.
2. Read src/lua_api/<module>_api.rs, the matching src/<module>/ code, docs/specs/<module>.md, tests/lua/, and nearby examples before editing.
3. Keep bindings thin, move domain behavior into src/<module>/, sync only the accepted public surface, and update source docstrings rather than generated files.
4. Run the narrowest Lua API tests, regenerate Lua API docs from source if the module changed publicly, and finish with the required broader gate.

## Success Criteria
- [ ] The prompt goal was completed: Implement one bounded Lua API module from an accepted contract.
- [ ] Required sync files were updated for the touched slice.
- [ ] The narrowest relevant validation passed.
- [ ] The change stayed inside the intended scope.

## Anti-patterns
- Widen the change into adjacent layers with no new decision.
- Edit generated artifacts by hand when the source should change instead.
- Skip the first narrow validation and jump straight to a broad sweep.

## Example Invocation
- /implement-lua-api-module module=minimap contract=docs/specs/minimap.md

## CAG Metadata
Mode: agent
Loads skills: lua-api-design, lua-rust-bridge, rust-coding, testing-rust
Inputs required: Module., Accepted API contract., Target source paths., Required validation path.
