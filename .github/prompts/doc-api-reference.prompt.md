---
description: "Write or update lurek.* API reference docs."
---

# Doc Api Reference

## Goal
- Write or update API reference documentation for lurek.* functions. Use when new Lua bindings are added or existing ones change. Produces...

## Inputs
- FUNCTIONS list of lurek.* functions to document (e.g., lurek.render.setColor, lurek.audio.setLooping)
- SOURCE_FILES corresponding Rust source files in src/lua_api/ to read for accurate signatures

## Steps
- Load documentation, lua-api-design before changing any files.
- Load skill documentation/SKILL.md
- For each function to document:
- Open docs/api/lurek.md
- Find the correct sub-section (e.g., ## lurek.render)
- Write the entry following this format:
- param type, range or valid values
- Returns: what Lua gets back (or nothing)
- Verify all key names are lowercase: "space" not "Space"
- Verify color parameters are documented as [0.0, 1.0] float range

## Success Criteria
- [ ] Updated docs/api/lurek.md with accurate, complete entries for all specified functions
- [ ] No entries for functions that don't exist in src/lua_api/

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /doc-api-reference <function> <module>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: documentation, lua-api-design
- **Inputs required**: function, module
