---
name: module-architecture
description: "Load this skill when planning module boundaries, dependency direction, or crate layout. Skip it for implementation or API naming."
---
# module-architecture

## Mission
- Own module boundaries, dependency direction, and visibility rules.

## When To Load
- Plan a new module.
- Review module boundaries.
- Fix bad dependency direction.
- Check crate or folder layout.

## When To Skip
- Implementation work.
- API naming.

## Domain Knowledge
- Keep dependencies acyclic.
- Keep responsibilities narrow.
- Put business logic in the owning module.
- Keep thin wrappers thin.
- Keep public surface small and clear.
- Use docs/specs/<module>.md as the contract.
- Route large multi-module work through Manager and Planner.
- Prefer one clear owner per module area.

## Companion File Index
- None.

## References
- docs/specs/
- src/lib.rs
- Cargo.toml
