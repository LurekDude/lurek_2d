# `src/physics/` — 2D Physics Engine (Rapier2D Integration)

## Purpose

The physics module wraps rapier2d — a production-quality 2D rigid-body
simulation engine — behind a Luna2D-native API surface optimised for the most
common 2D game physics needs.  It manages a `World` that owns all `RigidBody`
and `Collider` rapier resources, steps the simulation at a fixed timestep, and
maps rapier's opaque internal handles to stable integer IDs that Lua scripts
can store in variables and serialise to save files without worrying about
handle invalidation.

Three body types cover the standard patterns: `Dynamic` bodies respond to
forces and collisions (players, enemies, projectiles); `Static` bodies are
immovable collision geometry with effectively infinite mass (tiles, walls, floors);
`Kinematic` bodies are moved by script position but still collide and push
dynamic bodies (moving platforms, kinematic character controllers);
and `Sensor` bodies detect overlap without generating contact forces (trigger
zones, pick-up areas).  Ten joint types — revolute, distance, prismatic, weld,
rope, wheel, friction, motor, and stubs for pulley and gear — cover the
mechanical needs of most 2D games without requiring direct rapier knowledge.

The module deliberately exposes a simplified subset of rapier2d.  Complex
solver configuration, soft bodies, multi-body constraints, and custom
integration callbacks are intentionally not bound — the design goal is to cover
95% of 2D game physics needs with a small, learnable surface rather than
providing a complete 1:1 rapier binding that game developers would still need
to consult rapier documentation to use.

## Architecture

```
World (physics simulation)
  │
  ├── Body sync buffer ── Vec<Body> mirrors rapier state
  │     ├── User-facing integer IDs (stable, Lua-friendly)
  │     ├── Internal rapier RigidBodyHandle + ColliderHandle mappings
  │     └── Change detection: cached shapes/restitutions/layers/frictions
  │
  ├── Body types
  │     ├── Dynamic ── full physics simulation
  │     ├── Static ── immovable, infinite mass
  │     ├── Kinematic ── user-controlled position
  │     └── Sensor ── collision detection only, no forces
  │
  ├── Shapes
  │     ├── Rect { width, height }
  │     ├── Circle { radius }
  │     ├── Polygon { vertices } ── convex only
  │     ├── Edge { v1, v2 } ── line segment
  │     └── Chain { vertices, closed } ── connected edges
  │
  ├── Joints (10 types)
  │     ├── Revolute ── rotation around a point
  │     ├── Distance ── fixed-length connection
  │     ├── Prismatic ── sliding along an axis
  │     ├── Weld ── rigid attachment
  │     ├── Rope ── max-distance constraint
  │     ├── Wheel ── spring + damper
  │     ├── Friction ── velocity damping
  │     ├── Motor ── force/torque driven
  │     ├── Mouse ── follow target (spring)
  │     └── Pulley / Gear ── stubs (not implemented)
  │
  ├── Queries
  │     ├── raycast / raycast_closest / raycast_all
  │     ├── query_aabb ── bodies in rectangle
  │     └── getContacts ── active contact info
  │
  ├── Collision events ── LocalEventCollector
  │     ├── rapier EventHandler impl
  │     ├── Mutex<Vec<CollisionEvent>>
  │     └── Maps rapier events → BodyContact { body_a, body_b }
  │
  └── Step pipeline (per frame)
        ├── Phase 1: Rebuild colliders for changed shapes
        ├── Phase 2: Sync Body properties → rapier
        ├── Phase 3: rapier physics step
        ├── Phase 4: Read back positions/velocities from rapier
        └── Phase 5: Map collision events to stable IDs
```

### How It Works

The sync-buffer architecture exists because rapier uses opaque
`RigidBodyHandle` and `ColliderHandle` values that cannot be stored as Lua
integers.  The `Body` struct holds both the stable `u32` ID and the internal
rapier handle.  A `Vec<Body>` in the `World` serves as the stable-ID→handle
lookup table; destroyed body slots are marked dead and may be recycled with a
generation check.

The five-phase step pipeline is essential for correctness.  Shape changes made
from Lua (e.g. switching a body from Rect to Circle between frames) must
trigger collider rebuilds before the physics step runs; property writes
(velocity changes, position teleports) must be applied to rapier before the
step and not synced back afterwards; and collision events from the rapier
`EventHandler` must be captured during the step itself in a
`CollisionEventCollector` and only mapped to stable IDs after the step completes,
since rapier handles remain valid only for the duration of the step.

Collision filtering uses rapier's `InteractionGroups` bitmask.  Luna2D maps
this to 16 named category bits (0–15) set from Lua.  A body only generates
contact with another if `(body_a.membership & body_b.filter) != 0`, enabling
standard game archetypes (player collides with enemies and walls but not
with other players) without manual collision matrix management.

### Dependency Direction

```
physics/ ──────► math (Vec2, Rect)
```

Depends only on math types. Uses `rapier2d` externally.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports `Body`, `BodyShape`, `BodyType`, `CollisionInfo`, `Shape`,
`BodyContact` (as `CollisionEvent`), `ContactInfo`, `RaycastHit`, `World`.

**~16 lines** — re-exports.

---

### `body.rs` — `Body` (Physics Object)

**~300+ lines** | Represents a physical object in the simulation.

#### Enum: `BodyType`

`Static | Dynamic | Kinematic | Sensor`

#### Enum: `BodyShape`

```
Rect { width: f32, height: f32 }
Circle { radius: f32 }
```

#### Struct: `Body`

```rust
pub struct Body {
    pub position: Vec2,
    pub velocity: Vec2,
    pub mass: f32,
    pub body_type: BodyType,
    pub shape: BodyShape,
    pub restitution: f32,
    pub layer: u32,
    pub mask: u32,
    pub width: f32,
    pub height: f32,
    pub friction: f32,
    pub angle: f32,
    pub angular_velocity: f32,
    pub shape_ext: Option<Shape>,
}
```

Constructors: `new`, `new_circle`, `new_polygon`, `new_edge`, `new_chain`.

Methods: `bounding_box() → Rect`, `collides_with_layer(other_layer) → bool`.

**Layer/mask system**: `layer` is this body's layer bits; `mask` is which layers
it collides with. `collides_with_layer()` checks `self.mask & other_layer != 0`.

---

### `collision.rs` — `CollisionInfo` (Deprecated)

**~11 lines** | Legacy collision result type.

```rust
pub struct CollisionInfo {
    pub penetration: f32,
    pub normal: Vec2,
}
```

Retained for backward compatibility. Current collision info uses rapier's
contact system through `ContactInfo`.

---

### `shape.rs` — `Shape` (Extended Shapes)

**~150+ lines** | Polygon, edge, and chain shapes with rapier conversion.

#### Enum: `Shape`

```
Rect
Circle
Polygon { vertices: Vec<Vec2> }
Edge { v1: Vec2, v2: Vec2 }
Chain { vertices: Vec<Vec2>, closed: bool }
```

#### Methods

| Method | Purpose |
|--------|---------|
| `to_rapier_collider()` | Convert to rapier2d `ColliderBuilder` |
| `regular_polygon(sides, radius)` | Generate regular polygon (3–8 sides) |

---

### `world.rs` — `World` (Physics Simulation)

**~2400 lines** | The central physics simulation with rapier2d integration.

#### Struct: `World`

```rust
pub struct World {
    // Sync buffer
    bodies: Vec<Body>,
    body_handles: Vec<Option<RigidBodyHandle>>,
    collider_handles: Vec<Vec<ColliderHandle>>,
    
    // Change detection caches
    cached_shapes: Vec<Option<BodyShape>>,
    cached_restitutions: Vec<f32>,
    cached_layers: Vec<u32>,
    cached_frictions: Vec<f32>,
    
    // Rapier pipeline
    rigid_body_set: RigidBodySet,
    collider_set: ColliderSet,
    gravity: Vector<f32>,
    integration_parameters: IntegrationParameters,
    physics_pipeline: PhysicsPipeline,
    island_manager: IslandManager,
    broad_phase: DefaultBroadPhase,
    narrow_phase: NarrowPhase,
    impulse_joint_set: ImpulseJointSet,
    multibody_joint_set: MultibodyJointSet,
    ccd_solver: CCDSolver,
    
    // Event collection
    event_collector: Arc<LocalEventCollector>,
    
    // Scale
    meter: f32,   // pixels per meter
}
```

#### Body Management

| Method | Purpose |
|--------|---------|
| `add_body(body)` → `usize` | Add body, returns stable ID |
| `add_fixture(body_id, shape)` | Add extra collider to existing body |
| `fixture_count(body_id)` | Number of colliders on body |
| `get_body(id)` / `get_body_mut(id)` | Access by stable ID |
| `destroy_body(id)` | Remove body and all colliders |
| `body_count()` | Total bodies |
| `clear()` | Remove everything |

#### Joint Types (10)

| Method | Joint Type |
|--------|-----------|
| `add_revolute_joint(a, b, anchor)` | Hinge |
| `add_distance_joint(a, b, dist)` | Fixed distance |
| `add_prismatic_joint(a, b, axis)` | Slider |
| `add_weld_joint(a, b)` | Rigid attach |
| `add_rope_joint(a, b, max_dist)` | Max distance |
| `add_wheel_joint(a, b, axis)` | Spring + damper |
| `add_friction_joint(a, b)` | Velocity damping |
| `add_motor_joint(a, b)` | Force driven |
| `add_mouse_joint(a, target)` | Spring-follow target |
| `destroy_joint(id)` | Remove joint |

#### Queries

| Method | Returns |
|--------|---------|
| `raycast(origin, dir, max_dist)` | `Option<RaycastHit>` |
| `raycast_closest(origin, dir, max_dist)` | `Option<RaycastHit>` |
| `raycast_all(origin, dir, max_dist)` | `Vec<RaycastHit>` |
| `query_aabb(x, y, w, h)` | `Vec<usize>` body IDs |

#### Step Pipeline (5 phases)

1. **Rebuild colliders** — detect shape/size changes via cached values
2. **Sync to rapier** — write position/velocity/properties from Body → rapier
3. **Step rapier** — `physics_pipeline.step()` with integration parameters
4. **Read back** — copy position/velocity from rapier → Body
5. **Map events** — convert rapier collision events → `BodyContact { body_a, body_b }`

**Design**: The sync buffer pattern keeps simple integer IDs (array indices) for Lua
while rapier uses opaque generational handles internally. Change detection caches
avoid unnecessary collider rebuilds — only shapes/properties that actually changed
trigger rapier updates.

#### World Properties

| Method | Purpose |
|--------|---------|
| `set/get_gravity(x, y)` | World gravity vector |
| `set/get_meter(m)` | Pixels-per-meter scale |

---

## Cross-Cutting Concerns

### Error Handling

Invalid body IDs return `None` or are silently ignored. The physics world does not
panic on invalid operations — this allows Lua scripts to safely experiment.

### Thread Safety

`World` is single-threaded from the Lua side. The `LocalEventCollector` uses
`Mutex<Vec<>>` because rapier's `EventHandler` requires thread safety, but in
practice all access is from the main thread.

### Lua Integration

The Lua bridge lives in `src/lua_api/physics_api.rs` (~1650 lines), exposing
70+ functions under `luna.physics.*`.

### Usage from Lua

```lua
-- Create world with gravity
local world = luna.physics.newWorld(0, 9.81 * 64)

-- Add bodies
local ground = luna.physics.newBody(world, 400, 550, "static")
luna.physics.newRectangleShape(ground, 800, 100)

local ball = luna.physics.newBody(world, 400, 100, "dynamic")
luna.physics.newCircleShape(ball, 20)

-- Step simulation
function luna.update(dt)
    luna.physics.step(world, dt)
end

-- Draw
function luna.draw()
    local x, y = luna.physics.getPosition(ball)
    luna.graphics.circle("fill", x, y, 20)
end
```
