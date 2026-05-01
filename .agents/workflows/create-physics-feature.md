---
description: "Add one physics feature to the engine: body, shape, joint, sensor, query, or contact behavior."
---

# Create Physics Feature

## Goal
- Implement one bounded physics feature in src/physics/ and its Lua binding.

## Inputs
- Feature goal.
- Accepted lurek.physics.* shape when public API changes.
- Correctness or determinism concern.
- Test scenario.

## Steps
1. Load rust-coding, testing-rust, and lua-rust-bridge before acting.
2. Read docs/specs/physics.md, src/physics/, src/lua_api/physics_api.rs, and the nearest physics test before editing.
3. Keep PhysicsBodyKey as the only Lua-visible handle; never expose rapier handles.
4. Preserve step ordering, contact queue timing, and query semantics.
5. Run the narrowest physics test first.
6. Update docs/specs/physics.md when the contract changes.

## Success Criteria
- [ ] The feature is implemented with correct step ordering and handle safety.
- [ ] PhysicsBodyKey is the only Lua-visible handle.
- [ ] A test covers the new behavior.
- [ ] docs/specs/physics.md is updated if the contract changed.

## Anti-patterns
- Fire Lua callbacks inside step().
- Expose rapier handles to Lua.
- Use assert_eq! on f32.

## Example Invocation
- /create-physics-feature goal=joint_hinge body_count=2
