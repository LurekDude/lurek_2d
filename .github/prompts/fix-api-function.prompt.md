---
description: "Fix one existing lurek.* API function at the source and resync the public contract."
agent: "Developer"
tools: [tools/docs/gen_lua_api_data.py, tools/docs/gen_luadoc.py]
---
# Fix API Function

## Goal
- Fix one Lua API function at the owner layer.

## Inputs
- Module and function.
- Observed failure.
- Expected behavior.
- Failing test or repro.

## Steps
1. Load [skill: dev-debugging](../skills/dev-debugging/SKILL.md), [skill: lua-api-design](../skills/lua-api-design/SKILL.md), [skill: rust-coding](../skills/rust-coding/SKILL.md), and [skill: lua-rust-bridge](../skills/lua-rust-bridge/SKILL.md) before acting.
2. Reproduce the failure from the smallest failing test, src/lua_api/<module>_api.rs, the matching domain code, and the accepted spec or docs.
3. Correct the owning Rust or bridge slice, keep the Lua surface consistent with the accepted contract, and update source docstrings only if the public behavior changed.
4. Rerun the same failing test first, regenerate Lua API docs from source if needed, and only then widen validation.

## Success Criteria
- [ ] The failure was reproduced or tightly localized.
- [ ] The owner slice was fixed at the source.
- [ ] The failing check now passes.
- [ ] No unrelated drift was introduced.

## Anti-patterns
- Patch the symptom in an example, doc, or generated file while leaving the real binding bug in place.
- Change the API shape casually while trying to fix a localized defect.
- Skip the original failing test before running broader checks.

## Example Invocation
- /fix-api-function module=audio function=playOnce failure=wrong_return_value

## CAG Metadata
Mode: agent
Loads skills: dev-debugging, lua-api-design, rust-coding, lua-rust-bridge
Inputs required: Module and function., Observed failure., Expected behavior., Failing test or repro.
