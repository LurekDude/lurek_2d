# IDEA.md — `physics` module

> Migrated from `ideas/features/physics.md` and `ideas/performance/01-physics-threading.md`.
> Status checked against `src/physics/` and `src/lua_api/physics_api.rs`.
> Lua namespace: `lurek.physics`. Backed by rapier2d 0.32.

---

## Features

### ✅ DONE — One-Way Platforms
**Source**: features/physics.md — Feature Gaps #1 (was HIGH priority)

`setBodyOneWay(id, nx, ny)` and `clearBodyOneWay(id)` implemented in `physics_api.rs`
(lines ~982–991). Direction vector (nx, ny) defines the pass-through side.

---

### ✅ DONE — Collision Callbacks (`onCollisionBegin`)
**Source**: features/physics.md — Feature Gaps #2

`begin_contact_key` registry key stored in `LuaPhysicsWorld` (line ~97).
`setBeginContact(fn)` / `clearBeginContact()` implemented (lines ~926, ~934).
Callbacks fire via post-step event processing (line ~128).

Note: Verify `onCollisionEnd` callback also exists.

---

### ✅ DONE — Physics Debug Draw
**Source**: features/physics.md — Feature Gaps #7

`debugDraw(enable)` implemented at module level (line ~2531). Toggles
`state.physics_debug_draw` flag; render pass draws collider wireframes when enabled.

---

### ✅ DONE — Continuous Collision Detection (CCD)
**Source**: features/physics.md — Feature Gaps #3

`setBodyCCD(id, enabled)` and `getBodyCCD(id)` implemented in `physics_api.rs`
(lines ~961, ~970). Prevents tunneling for fast-moving bodies.

---

### ✅ DONE — Breakable Joints
**Source**: features/physics.md — Feature Gaps #9

`setJointBreakForce(jid, f)` and `getJointBreakForce(jid)` implemented (lines ~1011, ~1020).

---

### ❌ TODO — Lightweight Collision Helper (No World)
**Source**: features/physics.md — Feature Gaps #5 / Suggestions #5

No `lurek.collision.testAABB(a, b)` / `testCircles(...)` without requiring a full
`PhysicsWorld`. Many games (RPG, puzzle, visual novel) only need simple overlap detection,
not rigid-body simulation. Creating a PhysicsWorld when you just need AABB checks is heavy.

---

### ❌ TODO — Trigger Volume Data Attachment
**Source**: features/physics.md — Feature Gaps #4

Sensor bodies exist but no way to attach arbitrary Lua data to a body that surfaces with
collision events. Pattern `event.data = myData` must be emulated via a side table currently.

---

### 🔇 LOW — Buoyancy Forces
**Source**: features/physics.md — Feature Gaps #8

No fluid buoyancy. Can be simulated manually with per-frame upward forces proportional to
submerged area. Document as a pattern in examples rather than building native support.

---

## Performance

### ❌ TODO — Physics Step on Separate Thread
**Source**: performance/01-physics-threading.md

PhysicsWorld::step() runs on the main thread every frame. For worlds with 500+ bodies
this consumes significant frame budget. The step could run on a dedicated rayon thread pool
with double-buffered state. Rapier2d supports this pattern. Priority: **MEDIUM** for
simulation-heavy games, **LOW** for typical arcade/platformer loads.
