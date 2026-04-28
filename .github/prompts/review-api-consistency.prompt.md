---
description: "Review lurek.* API consistency."
---

# Review Api Consistency

## Goal
- Audit the lurek.* API surface for naming and convention consistency.

## Inputs
- module
- verb

## Steps
- Load lua-api-design before changing any files.
- Read all src/lua_api/*_api.rs files
- Check function naming: lurek.<module>.<verb>() pattern
- Check parameter conventions: dt, x, y, key, btn
- Check return types: all return LuaResult<T>
- Check key name conventions: lowercase strings
- Compare against docs/api/lurek.md for accuracy
- Report inconsistencies

## Success Criteria
- [ ] All functions follow naming pattern
- [ ] Parameters consistent across modules
- [ ] API reference matches code
- [ ] Key names are lowercase

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /review-api-consistency <module> <verb>

## CAG Metadata
- **Mode**: agent
- **Loads skills**: lua-api-design
- **Inputs required**: module, verb
