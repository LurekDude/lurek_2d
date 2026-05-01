---
description: "Fix a broken or inconsistent dependency between Cargo crates or internal modules."
---

# Fix Dependency Issue

## Goal
- Fix one bad dependency or import direction with no new cycles.

## Inputs
- Affected module or crate.
- Nature of the problem (cycle, wrong tier, missing dep).
- Acceptance gate.

## Steps
1. Load module-architecture and rust-coding before acting.
2. Read Cargo.toml and the relevant mod.rs files to map current edges.
3. Identify the narrowest boundary that controls the problem without redrawing the whole subsystem.
4. Make the smallest change that fixes the direction: move types, split a module, or adjust visibility.
5. Verify with cargo check and cargo clippy -- -D warnings.

## Success Criteria
- [ ] The dependency direction is correct and acyclic.
- [ ] cargo check passes.
- [ ] No unrelated drift was introduced.

## Example Invocation
- /fix-dependency-issue module=event problem=cycle-with-runtime
