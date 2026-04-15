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

### ✅ DONE — Lightweight Collision Helper (No World)
**Source**: features/physics.md — Feature Gaps #5 / Suggestions #5

New namespace `lurek.collision` registered in `src/lua_api/collision_api.rs`.
Domain logic in `src/physics/collision_helpers.rs`.
Four helpers: `testAABB`, `testCircles`, `testPoint`, `testCircleAABB`.
Lua tests: `tests/lua/unit/test_collision_helpers.lua`.
Example: `content/examples/collision.lua`.

---

### ✅ DONE — Trigger Volume Data Attachment
**Source**: features/physics.md — Feature Gaps #4

`body_data: Rc<RefCell<HashMap<usize, LuaRegistryKey>>>` added to `LuaPhysicsWorld` in
`src/lua_api/physics_api.rs`. Methods `setBodyData(id, data)`, `getBodyData(id)`,
`clearBodyData(id)` registered on the `LuaWorld` userdata.
Lua tests: `tests/lua/unit/test_physics_body_data.lua`.

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
