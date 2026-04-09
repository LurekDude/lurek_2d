# `entity` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.entity`                                        |
| **Source**      | `src/entity/`                                        |
| **Rust Tests** | `tests/rust/unit/entity_tests.rs`                    |
| **Lua Tests**  | `tests/lua/unit/test_entity.lua`                     |
| **Architecture** | —                                                  |

## Purpose

The entity module provides Lurek2D's lightweight entity-component-system (ECS) built around the `Universe` struct — a self-contained ECS world that manages entity lifecycle, components, tags, layers, blueprints, parent-child hierarchies, and ordered system dispatch. Entities are identified by generational packed IDs: the upper 8 bits store a generation counter and the lower 24 bits store the slot index, so a stale entity ID from a previously destroyed entity is detected at the Rust boundary before it can access wrong data. This prevents use-after-free bugs without requiring garbage collection or `unsafe` code.

## Source Files

| File               | Purpose                                                                     |
|--------------------|-----------------------------------------------------------------------------|
| `mod.rs`           | Module root — declares submodules, re-exports `Universe`, `RelationType`, `Relationship`, `RelationshipManager`, `deep_copy_table` |
| `universe.rs`      | `Universe` struct — entity lifecycle, components, string/bitmap tags, layers, blueprints, parent-child, systems, `deep_copy_table` helper |
| `relationships.rs` | `RelationType`, `Relationship`, `RelationshipManager` — symmetric pair-based relations with numeric values and named-state levels |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/entity.md`](../../docs/specs/entity.md)

_Update both this file **and** `docs/specs/entity.md` whenever source files, public types, or Lua bindings change._
