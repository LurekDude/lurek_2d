# `ecs` — Agent Reference

## Module Info

- Module name: `ecs`
- Module group: Feature Systems
- Spec path: `docs/specs/ecs.md`
- Lua API path(s): `src/lua_api/ecs_api.rs`
- Rust test path(s): none found under `tests/` with `ecs` in the path
- Lua test path(s): none found under `tests/` with `ecs` in the path

## Module Purpose

The `ecs` module owns Lurek2D's lightweight entity world and related relationship utilities. Its main job is to create and destroy entities safely, store arbitrary component data in Lua-owned tables, track tags and layers, manage parent-child hierarchies, define blueprints, and dispatch registered systems in a controlled order.

This module exists to give Lua game code a flexible property-bag ECS rather than a rigid Rust archetype ECS. `Universe` handles identity, lifecycle, and indexing concerns while leaving component schemas dynamic. That makes it suitable for script-heavy gameplay code where components and systems evolve quickly and where entity data needs to remain easy to inspect and modify from Lua.

The module intentionally does not own rendering, physics simulation, scene transitions, or specialized gameplay logic. It can store data for those systems and dispatch systems that act on that data, but it does not define how a sprite, collider, or scene should behave. The separate relationship types also do not model gameplay semantics by themselves; they only provide a reusable container for pairwise relation values and named levels.

## Files

- `mod.rs`: Declares the ECS submodules and re-exports the main world and relationship types.
- `universe.rs`: Defines `Universe`, including generational entity IDs, component storage via Lua registry tables, tags, layers, blueprints, hierarchy management, and ordered system dispatch.
- `relationships.rs`: Defines reusable relationship types and the `RelationshipManager` for symmetric pairwise values and named relation levels.

## Key Types

- `Universe`: The main ECS world object that owns entity lifecycle, component storage, tags, layers, blueprints, parent-child links, and registered systems.
- `RelationshipManager`: A standalone manager for pairwise entity relationships that is separate from `Universe` but often complements ECS-driven gameplay.
- `Relationship`: The stored record for one normalized entity pair, including a numeric value and per-type named levels.
- `RelationType`: The definition of one named relationship category and its allowed level strings.