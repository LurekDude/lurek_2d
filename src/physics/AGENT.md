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

## Lua API Summary

| Function | Description |
|----------|-------------|
| `lurek.physics.bodyId()` | See `docs/specs/physics.md`. |
| `lurek.physics.x()` | See `docs/specs/physics.md`. |
| `lurek.physics.y()` | See `docs/specs/physics.md`. |
| `lurek.physics.normalX()` | See `docs/specs/physics.md`. |
| `lurek.physics.normalY()` | See `docs/specs/physics.md`. |
| `lurek.physics.toi()` | See `docs/specs/physics.md`. |
| `lurek.physics.bodyA()` | See `docs/specs/physics.md`. |
| `lurek.physics.bodyB()` | See `docs/specs/physics.md`. |
| `lurek.physics.isTouching()` | See `docs/specs/physics.md`. |
| `lurek.physics.newWorld()` | See `docs/specs/physics.md`. |
| `lurek.physics.step()` | See `docs/specs/physics.md`. |
| `lurek.physics.destroyWorld()` | See `docs/specs/physics.md`. |
| `lurek.physics.newBody()` | See `docs/specs/physics.md`. |
| `lurek.physics.getBody()` | See `docs/specs/physics.md`. |
| `lurek.physics.setBodyVelocity()` | See `docs/specs/physics.md`. |
| `lurek.physics.isSleepingAllowed()` | See `docs/specs/physics.md`. |
| `lurek.physics.setSleepingAllowed()` | See `docs/specs/physics.md`. |
| `lurek.physics.newRectangleShape()` | See `docs/specs/physics.md`. |
| `lurek.physics.newCircleShape()` | See `docs/specs/physics.md`. |
| `lurek.physics.newEdgeShape()` | See `docs/specs/physics.md`. |

## Full Specification

All architecture diagrams, detailed type documentation, Lua API reference, examples, and cross-module references live in the consolidated spec:

→ [`docs/specs/physics.md`](../../docs/specs/physics.md)

_Update both this file **and** `docs/specs/physics.md` whenever source files, public types, or Lua bindings change._
