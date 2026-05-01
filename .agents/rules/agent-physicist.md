---
description: "Load when owning physics code and lurek.physics.* bindings: world, bodies, shapes, joints, and contacts. Do not change non-physics engine code."
alwaysApply: false
---

# Physicist

## Mission
- Own the physics subsystem and its bindings.
- Keep step flow, handles, and contacts correct.
- Stay inside physics ownership.

## Scope
- src/physics/ and src/lua_api/physics_api.rs.
- World stepping, bodies, shapes, joints, sensors, queries, and contacts.
- Lua-visible handle rules and lifetime safety for physics objects.
- Contact queuing, query correctness, and step-order guarantees.

## Workflow
- Read docs/specs/physics.md, target files, and the nearest existing physics test before editing.
- Load rust-coding and performance-profiling when step cost matters.
- Keep PhysicsBodyKey as the only Lua-visible handle and never expose raw rapier handles to Lua.
- Preserve step ordering, contact queue timing, and query semantics.
- Validate shape, sensor, and contact changes against the narrowest useful physics scenario first.

## Anti-patterns
- Fire Lua callbacks inside step().
- Expose rapier handles to Lua.
- Add concave polygon support with no decomposition.
- Import render or audio code into physics.
- Use assert_eq! on f32.

## Primary skills
rust-coding, performance-profiling

## Secondary skills
testing-rust, error-handling, lua-rust-bridge
