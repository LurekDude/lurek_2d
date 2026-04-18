---
description: "Review Lua API consistency: naming patterns, parameter conventions, return types across all lurek.* modules."
mode: agent
loads_skills: [lua-api-design]
loads_tools: []
expected_agent: Lua-Designer
inputs_required: [module, verb]
---

# Review Api Consistency

## Goal

Audit the `lurek.*` API surface for naming and convention consistency.

## Inputs

- `module` — value supplied by the user invocation.
- `verb` — value supplied by the user invocation.

## Steps

1. Load [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md) before changing any files.
2. Read all `src/lua_api/*_api.rs` files
3. Check function naming: `lurek.<module>.<verb>()` pattern
4. Check parameter conventions: `dt`, `x, y`, `key`, `btn`
5. Check return types: all return `LuaResult<T>`
6. Check key name conventions: lowercase strings
7. Compare against `docs/API/lua-api.md` for accuracy
8. Report inconsistencies

## Success Criteria

- [ ] All functions follow naming pattern
- [ ] Parameters consistent across modules
- [ ] API reference matches code
- [ ] Key names are lowercase

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/review-api-consistency <module> <verb>`
