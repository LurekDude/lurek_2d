---
description: "Fix one Lua-side error in content or examples using the current API surface."
agent: "Content-Maker"
---
# Fix Lua Error

## Goal
- Fix one Lua-side content error at the source.

## Inputs
- Lua error message.
- Target file.
- Repro path.
- Expected behavior.

## Steps
1. Load [skill: dev-debugging](../skills/dev-debugging/SKILL.md) and [skill: lua-scripting](../skills/lua-scripting/SKILL.md) before acting.
2. Reproduce the failure from the failing Lua file, the smallest repro path, nearby examples, and the current API docs for the calls involved.
3. Correct the Lua content, usage pattern, or local wiring that caused the error, and only escalate to engine owners if the API itself is broken.
4. Rerun the same content path or failing Lua test first, then widen validation only if the local fix passed.

## Success Criteria
- [ ] The failure was reproduced or tightly localized.
- [ ] The owner slice was fixed at the source.
- [ ] The failing check now passes.
- [ ] No unrelated drift was introduced.

## Anti-patterns
- Patch symptoms in a different layer from the one that owns the failure.
- Skip the smallest reproducer and guess at the fix.
- Keep editing after the first change instead of rerunning the failing check.

## Example Invocation
- /fix-lua-error file=content/examples/ui.lua error='attempt to call nil value'

## CAG Metadata
Mode: agent
Loads skills: dev-debugging, lua-scripting
Inputs required: Lua error message., Target file., Repro path., Expected behavior.
