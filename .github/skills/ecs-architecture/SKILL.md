---
name: ecs-architecture
description: "Load this skill when working with Luna2D's entity system: Universe, entity spawning/recycling, bitmap tags, blueprints, layer-based organization, or system dispatch. Skip it for rendering pipeline, physics algorithms, or AI decision-making."
---

# Entity Architecture — Luna2D Engine

## Load When

- Spawning or destroying entities via `luna.entity.*`
- Designing entity composition with tags and layers
- Building blueprint prefabs for reusable entity templates
- Implementing system dispatch callbacks
- Managing entity lifecycles (create, update, destroy, recycle)

## Owns

- `src/entity/mod.rs` — Universe, entity storage, ID recycling
- `src/lua_api/entity_api.rs` — `luna.entity.*` Lua bindings
- Entity lifecycle patterns (spawn → alive → kill → recycle)
- Blueprint pattern for entity templates
- Layer-based entity organization
- System dispatch via callbacks

## Does Not Cover

- Physics body management → use `physics-engine` skill
- AI agent decision models → use `ai-systems` skill
- Rendering/sprites → use `software-rendering` skill
- Scene management → use `scene-management` skill

## Live Repository Contracts

- `src/entity/mod.rs` — `Universe` struct with full entity lifecycle
- `src/lua_api/entity_api.rs` — Lua bindings for `luna.entity.*`
- `tests/entity_tests.rs` — entity spawn, recycling, lifecycle tests

## Decision Rules

- **Universe is the entity container** — all entities live in `Universe`, accessed via `SharedState`
- **IDs are recycled LIFO** — killed entity IDs are reused in last-in-first-out order
- **Sequential IDs on first spawn** — new entities get incrementing IDs (1, 2, 3, ...)
- **Bitmap tags for classification** — fast set membership checks without string comparison
- **Layers organize entities spatially** — entities belong to named layers for grouped operations
- **Blueprints are entity templates** — define reusable entity configurations (prefabs)
- **System dispatch via callbacks** — register update functions that process entity groups

## Dual State Architecture

Luna2D has two state systems that serve different purposes:

| System | Container | Purpose | Access |
|---|---|---|---|
| **SharedState** | `Rc<RefCell<SharedState>>` | Engine-level state (graphics, audio, physics, input) | Shared between Lua closures and engine loop |
| **Universe** | `SharedState.entity_universe` | Game-level entities (spawned objects, components, tags) | Accessed through `luna.entity.*` API |

- SharedState holds *engine subsystem* state (renderer, mixer, physics world)
- Universe holds *game object* state (entities with tags, layers, blueprints)
- Use Universe when you need entity composition and lifecycle — use raw Lua tables for simple data

## Best Practices

- Use blueprints for repeated entity types — don't manually configure each spawn
- Tag entities for fast group queries — avoid iterating all entities to find a subset
- Kill entities during `luna.update()` — never during `luna.draw()`
- Check `is_alive()` before accessing entity data — IDs may be recycled
- Use layers to organize entities by game function (enemies, bullets, pickups)

## Anti-Patterns

- **Stale ID reference**: Holding an entity ID after kill without checking `is_alive()` — the ID may be recycled
- **Manual ID tracking**: Maintaining separate entity lists instead of using Universe tags/layers
- **Kill during draw**: Destroying entities in `luna.draw()` — mutations belong in `luna.update()`
- **Ignoring recycling**: Assuming entity IDs are always unique — killed IDs get reused
