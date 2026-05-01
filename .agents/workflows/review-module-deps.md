---
description: "Review module dependency direction and import correctness for one src/ module."
---

# Review Module Deps

## Goal
- Audit one module for dependency direction violations and import correctness.

## Inputs
- Module name.
- Any known dependency concern.

## Steps
1. Load module-architecture and rust-coding before acting.
2. Read Cargo.toml and the target src/<module>/mod.rs and source files.
3. Map current import edges and check against the five-group architecture dependency direction.
4. Identify any violations: upward imports, cycles, or leaking types across group boundaries.
5. Return the list of violations with file references and the smallest fix for each.

## Success Criteria
- [ ] Import direction is correct and acyclic.
- [ ] Violations are listed with file and line.
- [ ] Smallest fix per violation is proposed.

## Example Invocation
- /review-module-deps module=event
