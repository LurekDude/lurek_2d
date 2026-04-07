# `physics` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.physics`                                       |
| **Source**      | `src/physics/`                                       |
| **Rust Tests** | `tests/unit/physics_tests.rs`                        |
| **Lua Tests**  | `tests/lua/unit/test_physics.lua`                    |
| **Architecture** | —                                                  |

## Purpose

The physics module provides 2D rigid-body simulation backed by rapier2d 0.32. It wraps the rapier2d pipeline behind a Luna2D-native API surface that exposes stable integer body and joint IDs suitable for Lua storage and serialization, hiding rapier's opaque internal handles entirely.

## Source Files

| File           | Purpose                                                      |
|----------------|--------------------------------------------------------------|
| `body.rs`      | `Body` struct, `BodyType`/`BodyShape` enums, constructors, coordinate transforms, bounding box |
| `collision.rs` | `CollisionInfo` struct — legacy penetration/normal data (retained for backward compatibility) |
| `shape.rs`     | Extended `Shape` enum (polygon, edge, chain), `StandaloneShape` value type, rapier collider conversion |
| `world.rs`     | `World` simulation manager, body/joint CRUD, step pipeline, raycasting, spatial queries, collision events |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`specs/physics.md`](../../specs/physics.md)

_Update both this file **and** `specs/physics.md` whenever source files, public types, or Lua bindings change._
