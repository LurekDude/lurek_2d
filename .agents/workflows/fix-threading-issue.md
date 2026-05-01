---
description: "Fix a threading or borrow issue in Rust engine code involving SharedState, RefCell, or channel boundaries."
---

# Fix Threading Issue

## Goal
- Fix one threading or borrow bug at the controlling boundary.

## Inputs
- Symptom (panic, deadlock, or data race).
- Suspected module.
- Repro or test output.

## Steps
1. Load rust-coding, error-handling, and dev-debugging before acting.
2. Read the SharedState usage, RefCell borrow sites, and callback closures in the suspected module.
3. Identify where a borrow_mut is held across a Lua callback or a SharedState is accessed from multiple threads unsafely.
4. Fix the narrowest borrow scope, move the clone or drop before the callback, or replace with a correct channel boundary.
5. Rerun the failing test or repro and confirm no borrow panic appears.

## Success Criteria
- [ ] The borrow panic or threading error is gone.
- [ ] No borrow_mut is held across a Lua callback.
- [ ] cargo clippy -- -D warnings passes.

## Example Invocation
- /fix-threading-issue module=event symptom=borrow_mut_panic_in_callback
