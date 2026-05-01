---
description: "Fix a Lua-side runtime error from a game script or test."
---

# Fix Lua Error

## Goal
- Fix one Lua error at the script or binding source.

## Inputs
- Error message and stack trace.
- Failing script path.
- Repro or failing test.

## Steps
1. Load lua-scripting, error-handling, and dev-debugging before acting.
2. Read the error message, identify whether it is a script bug or a binding contract failure.
3. Fix at the correct layer: script logic if it is a content error, binding if it is a contract mismatch.
4. Rerun the failing script or test and confirm the error is gone.

## Success Criteria
- [ ] The Lua error no longer appears on rerun.
- [ ] The fix is at the correct owner layer.
- [ ] No unrelated script behavior changed.

## Example Invocation
- /fix-lua-error script=content/games/demo.lua error="attempt to index nil value"
