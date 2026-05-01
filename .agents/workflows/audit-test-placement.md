---
description: "Audit whether tests live in the correct Rust or Lua layer for the behavior they cover."
---

# Audit Test Placement

## Goal
- Identify misplaced tests and the smallest correct home for them.

## Inputs
- Target module or test file set.
- Behavior area.
- Any current placement concern.

## Steps
1. Load testing-rust, lua-rust-bridge, and module-architecture before acting.
2. Read tests/, src/lua_api/, docs/specs/, and the touched module paths.
3. Check whether Lua-visible behavior lives under tests/lua/, Rust-only internals live under tests/rust/unit/, and support files sit in the right harness layer.
4. Report misplaced tests, missing tests, and the exact target path each issue should move to.

## Success Criteria
- [ ] Findings are listed, or the workflow states clearly that no findings were found.
- [ ] Each finding is tied to a file, behavior, or missing proof.
- [ ] Missing validation or test coverage is called out.
- [ ] Residual risk or next owner is explicit.

## Anti-patterns
- Treat style nits as more important than behavior or contract drift.
- Declare the area clean without checking tests or missing proof.

## Example Invocation
- /audit-test-placement module=lua_api/audio
