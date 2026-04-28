---
description: "Create a new physics feature."
---

# Create Physics Feature

## Goal
- Add a new physics feature: body type, collision shape, force type, or constraint.

## Inputs
- **Feature**: What physics capability to add
- **Body types affected**: Static, Dynamic, Kinematic, or new type
- **Collision behavior**: How it interacts with existing bodies

## Steps
- Read current physics code in src/physics/
- Design the feature respecting module isolation (physics depends only on math)
- Implement in appropriate file (body.rs, collision.rs, or world.rs)
- Add Lua binding in src/lua_api/physics_api.rs
- Write physics tests with float tolerance assertions
- Run cargo test and cargo clippy
- Consult the actual lurek.* API surface via docs/api/lurek.md, content/examples/, and docs/specs/. Do NOT invent APIs.

## Success Criteria
- [ ] Physics module depends only on math
- [ ] Float comparisons use tolerance
- [ ] Body IDs remain stable
- [ ] Tests cover edge cases
- [ ] cargo test passes

## Anti-patterns
- Skipping the Success Criteria check before declaring the prompt done.
- Running git add . instead of staging only the files this prompt produced.

## Example Invocation
- /create-physics-feature

## CAG Metadata
- **Mode**: agent
