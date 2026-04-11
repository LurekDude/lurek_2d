# `physics` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 1 — Core Engine Subsystems                      |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `lurek.physics`                                       |
| **Source**      | `src/physics/`                                       |
| **Rust Tests** | `tests/unit/physics_tests.rs`                        |
| **Lua Tests**  | `tests/lua/unit/test_physics.lua`                    |
| **Architecture** | —                                                  |

## Purpose

The physics module provides 2D rigid-body simulation backed by rapier2d 0.32. It wraps the rapier2d pipeline behind a Lurek2D-native API surface that exposes stable integer body and joint IDs suitable for Lua storage and serialization, hiding rapier's opaque internal handles entirely.

## Source Files

| File           | Purpose                                                      |
|----------------|--------------------------------------------------------------|
| `mod.rs`       | Module entry point — re-exports public types and declares submodules |
| `body.rs`      | `Body` struct, `BodyType`/`BodyShape` enums, constructors, coordinate transforms, bounding box |
| `collision.rs` | `CollisionInfo` struct — legacy penetration/normal data (retained for backward compatibility) |
| `render.rs`    | `World::generate_render_commands` and `World::draw_to_image` — debug overlay (pure CPU, no wgpu) |
| `shape.rs`     | Extended `Shape` enum (polygon, edge, chain), `StandaloneShape` value type, rapier collider conversion |
| `world.rs`     | `World` simulation manager, body/joint CRUD, step pipeline, raycasting, spatial queries, collision events |

## Key Types

| Type | Description |
|------|-------------|
| `BodyType` | Principal type for the `physics` module. |
| `BodyShape` | Principal type for the `physics` module. |
| `Body` | Principal type for the `physics` module. |
| `CollisionInfo` | Principal type for the `physics` module. |
| `Shape` | Principal type for the `physics` module. |
| `StandaloneShape` | Principal type for the `physics` module. |
| `BodyContact` | Principal type for the `physics` module. |
| `RaycastHit` | Principal type for the `physics` module. |
| `ContactInfo` | Principal type for the `physics` module. |
| `World` | Principal type for the `physics` module. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/physics.md`](../../docs/specs/physics.md)

_Update both this file **and** `docs/specs/physics.md` whenever source files, public types, or Lua bindings change._
