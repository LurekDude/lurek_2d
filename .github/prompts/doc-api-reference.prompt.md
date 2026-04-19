---
description: "Write or update API reference documentation for lurek.* functions. Use when new Lua bindings are added or existing ones change. Produces..."
agent: Doc-Writer
---
# Doc Api Reference

## Goal

Write or update API reference documentation for lurek.* functions. Use when new Lua bindings are added or existing ones change. Produces... The prompt finishes when every Success Criteria item below is checked.

## Inputs

- `FUNCTIONS` — list of `lurek.*` functions to document (e.g., `lurek.gfx.setColor`, `lurek.audio.setLooping`)
- `SOURCE_FILES` — corresponding Rust source files in `src/lua_api/` to read for accurate signatures

## Steps

1. Load [skill: documentation](.github/skills/documentation/SKILL.md), [skill: lua-api-design](.github/skills/lua-api-design/SKILL.md) before changing any files.
2. Load skill `documentation/SKILL.md`
3. For each function to document:
4. Open `docs/API/lua-api.md`
5. Find the correct sub-section (e.g., `## lurek.gfx`)
6. Write the entry following this format:
7. `param` — type, range or valid values
8. Returns: what Lua gets back (or nothing)
9. Verify all key names are lowercase: `"space"` not `"Space"`
10. Verify color parameters are documented as `[0.0, 1.0]` float range

## Success Criteria

- [ ] Updated `docs/API/lua-api.md` with accurate, complete entries for all specified functions
- [ ] No entries for functions that don't exist in `src/lua_api/`

## Anti-patterns

- Skipping the Success Criteria check before declaring the prompt done.
- Running `git add .` instead of staging only the files this prompt produced.

## Example Invocation

> Run this prompt via VS Code Copilot Chat: `/doc-api-reference <function> <module>`

## CAG Metadata

- **Mode**: agent
- **Loads skills**: documentation, lua-api-design
- **Inputs required**: function, module
