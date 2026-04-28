---
description: "Refresh Lua API docstrings to the standard format."
agent: developer
loads_tools:
 - tools/validate/validate_lua_api.py
 - tools/validate/cag_validate.py
 - tools/docs/gen_lua_api_data.py
 - tools/docs/gen_extension_api.py
 - tools/docs/gen_luadoc.py
 - tools/docs/gen_docs_lua.py
---
# Workflow Refresh Lua Api Docstrings

## Goal
- Refresh Lua API docstrings to the current standard without changing Rust logic.

## Inputs
- target_modules: module names or src/lua_api/*_api.rs paths.

## Steps
- Load lua-api-design, documentation, and cag-workflow.
- Read src/lua_api/mod.rs, src/lua_api/register.rs, src/lua_api/lua_types.rs, and docs/specs/lua-api-file-standard.md.
- If the standard drifted, update the standard docs and related skills first.
- Rewrite docstrings only in each target file.
- Keep logic, signatures, return behavior, tests, and control flow unchanged.
- Use one short description line, then @param lines, then @return lines.
- Use Lua-visible type names only.
- Use fixed return types only.
- Run validate_lua_api.py on touched files.
- Regenerate lua_api_data.json, lurek-api.json, docs/api/lurek.lua, and docs/api/lurek.md.
- Run cag_validate.py only if .github changed.
- Do not run cargo test or runtime checks unless Rust logic changed.

## Success Criteria
- [ ] Every touched src/lua_api/*_api.rs file uses the fixed docstring format.
- [ ] No touched Lua API file has Rust logic changes.
- [ ] validate_lua_api.py passes for touched files.
- [ ] lua_api_data.json, lurek-api.json, docs/api/lurek.lua, and docs/api/lurek.md are regenerated.
- [ ] cag_validate.py passes if .github changed.

## Anti-patterns
- Change Rust logic in a docs-only task.
- Keep legacy docstring formats.
- Use Rust wrapper names instead of Lua-visible names.
- Invent behavior that the code does not have.
- Run runtime checks for doc-only edits.

## Example Invocation
- /workflow-refresh-lua-api-docstrings event,timer,camera,window,log

## CAG Metadata
- **Mode**: agent
- **Loads skills**: lua-api-design, documentation, cag-workflow
- **Inputs required**: target_modules
