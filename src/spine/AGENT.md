# Spine Module

**Tier**: 2 — Engine Extension
**Status**: Design-stage skeleton
**Path**: `src/spine/`

## Responsibility

Skeletal animation: bone hierarchies, parent-child transform propagation,
named slots, and attachment binding. The module provides the data structures
and transform math; rendering and physics are delegated to other modules.

## Key Types

| Type | File | Purpose |
|---|---|---|
| `Bone` | `bone.rs` | Single bone with local and world transforms |
| `Skeleton` | `skeleton.rs` | Bone hierarchy + slots + world-transform propagation |
| `Slot` | `slot.rs` | Render slot bound to a bone (attachment, color, draw order) |

## Dependencies

- `crate::math` (foundation — no direct use yet, available for future Vec2 integration)
- No other module imports

## Tests

- `tests/unit/spine_tests.rs` — Rust unit tests for bone defaults, skeleton CRUD, world-transform propagation
