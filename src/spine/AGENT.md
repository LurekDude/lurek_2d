# `spine` — Agent Reference

| Property       | Value                                          |
|----------------|------------------------------------------------|
| **Tier**       | Tier 2 — Engine Extension                      |
| **Status**     | Implemented — Full                             |
| **Lua API**    | `lurek.spine`                                   |
| **Source**     | `src/spine/`                                   |
| **Rust Tests** | `tests/rust/unit/spine_tests.rs`               |
| **Lua Tests**  | `tests/lua/unit/test_spine.lua`                |
| **Architecture** | —                                            |

## Purpose

The `spine` module implements skeletal 2D animation through bone hierarchies, slots, and world-transform propagation. It is a Tier 2 Engine Extension that provides the data model for hierarchical bone rigs without any GPU, audio, or windowing dependency. The module is purely computational — it owns bone graph construction, local-to-world transform propagation, and slot-based attachment binding but delegates all rendering to the `lua_api` bridge layer.

## Source Files

| File          | Purpose                                                                  |
|---------------|--------------------------------------------------------------------------|
| `bone.rs`     | `Bone` struct — local and world transform fields, constructors           |
| `skeleton.rs` | `Skeleton` and `BoneParams` — bone/slot management, world-transform propagation |
| `slot.rs`     | `Slot` struct — bone attachment binding with tint colour and draw order   |

## Key Types

| Type | Description |
|------|-------------|
| `Bone` | Principal type for the `spine` module. |
| `BoneParams` | Principal type for the `spine` module. |
| `Skeleton` | Principal type for the `spine` module. |
| `Slot` | Principal type for the `spine` module. |

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.spine.newSkeleton()` | See `docs/specs/spine.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/spine.md`](../../docs/specs/spine.md)

_Update both this file **and** `docs/specs/spine.md` whenever source files, public types, or Lua bindings change._
