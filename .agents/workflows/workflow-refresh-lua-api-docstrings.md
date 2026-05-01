---
description: "Refresh Lua API docstrings in src/lua_api/ and regenerate all API docs."
---

# Workflow Refresh Lua API Docstrings

## Goal
- Audit and refresh Lua API docstrings, then regenerate all derived API docs.

## Inputs
- Scope (all modules or specific module).

## Steps
1. Load documentation and lua-api-design before acting.
2. Read src/lua_api/<module>_api.rs for each module in scope.
3. Check that each public function has a docstring describing behavior, params, and return types accurately.
4. Fix missing or wrong docstrings at source in the Rust file. Never touch docs/api/lurek.md directly.
5. Run python tools/docs/gen_lua_api_data.py then python tools/docs/gen_luadoc.py.
6. Confirm docs/api/lurek.md and docs/api/lurek.lua look correct.

## Success Criteria
- [ ] All public lurek.* functions have accurate docstrings.
- [ ] docs/api/lurek.md is regenerated and correct.
- [ ] docs/api/lurek.lua is regenerated and correct.
- [ ] No generated file was hand-edited.

## Example Invocation
- /workflow-refresh-lua-api-docstrings scope=all
