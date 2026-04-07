# Physics Threading — rapier2d Parallelism

## Current State

Luna2D uses rapier2d 0.32 for rigid-body physics simulation. The physics
pipeline runs **entirely on the main thread** in `src/physics/world.rs`:

```rust
rapier2d::PhysicsPipeline::step(
    gravity, params, islands, broad_phase, narrow_phase,
    bodies, colliders, joints, ...
)
```

### Per-Frame Cost (main thread)
1. **Broad phase** — sweep-and-prune, O(n log n) for n bodies
2. **Narrow phase** — AABB/circle contacts, O(contact_pairs)
3. **Solver** — iterative impulse, O(bodies × solver_iterations)
4. **Collision event recording** — `Vec<CollisionInfo>` collection

### Current Cargo.toml
```toml
rapier2d = { version = "0.32", features = ["..."] }
# "parallel" feature is NOT enabled
```

## Opportunity 1: Enable `parallel` Feature (Effort: Trivial)

rapier2d supports rayon-based parallelism via a Cargo feature flag:

```toml
rapier2d = { version = "0.32", features = ["parallel"] }
```

### What It Parallelizes
- **Island-based solver**: Independent collision islands solved in parallel
- **Broad phase**: Sweep-and-prune can use work-stealing
- **Contact generation**: Multiple contact pairs processed concurrently

### Expected Speedup
- **< 50 bodies**: Negligible (thread overhead > work)
- **50–200 bodies**: 1.5–2× speedup
- **200+ bodies**: 2–4× speedup
- **Best case**: Many independent islands (e.g., ragdoll + particles + platforms)

### Risks
- Adds ~200KB to binary (rayon runtime)
- rayon is already a transitive dependency (via slotmap) — may add zero binary cost
- Non-deterministic frame ordering (island solve order varies) — acceptable for most games

### Implementation
1. Change one line in `Cargo.toml`
2. Run `cargo test --test physics_tests` to verify
3. No source code changes required

## Opportunity 2: Background Physics Stepping (Effort: Medium)

For games with heavy physics (200+ bodies), step physics on a background
thread and interpolate positions on the main thread.

### Architecture
```
Main Thread                    Physics Thread
─────────────                  ──────────────
luna.update(dt)
  ├─ snapshot body positions
  ├─ send dt to physics thread ─→ receive dt
  ├─ interpolate visuals            step(dt)
  │   (using prev + current)        collect events
  │                                 send results ─→
  ├─ receive results
  └─ apply new positions
```

### Required Changes
- `PhysicsWorld` needs `Send + Sync` wrapper (rapier types are `Send`)
- Body positions need double-buffering: `prev_state` and `curr_state`
- Collision events sent via `mpsc::channel`
- Lua-side physics queries (`rayCast`, `getContacts`) must read from the
  interpolated state, not the mid-step state

### Risks
- One-frame physics lag (positions are from previous step)
- Collision callbacks delayed by one frame
- Complex state synchronization if Lua mutates bodies mid-step

### When to Use
Only beneficial when physics consumes > 2ms/frame. Profile first with
`RUST_LOG=debug` to measure `world.step()` duration.

## Opportunity 3: Sub-Stepping on Background Thread (Effort: High)

Fixed-timestep physics with sub-steps (e.g., 4 sub-steps per frame at
1/240s) can be parallelized: while the main thread renders frame N, the
physics thread runs sub-steps for frame N+1.

### Implementation
Same as Opportunity 2, but the physics thread runs multiple `step()` calls
per frame with a fixed dt (e.g., 1/240). This produces smoother physics at
the cost of additional CPU work distributed across threads.

## Recommendation

**Phase 1**: Enable `parallel` feature — trivial, immediate benefit for 50+ bodies.
**Phase 2**: Profile real games. If physics > 2ms/frame, implement background stepping.
**Phase 3**: Sub-stepping only needed for physics-heavy simulation games.

## Reference: How Other Engines Handle This

| Engine | Physics Threading |
|--------|-------------------|
| Love2D | Box2D on main thread (no parallel) |
| Godot 4 | Jolt Physics on background thread |
| Unity | PhysX on worker threads (job system) |
| Bevy | rapier2d with `parallel` + ECS schedule |
| macroquad | No built-in physics |

Luna2D's opportunity to enable rapier2d `parallel` puts it ahead of Love2D
with almost zero effort.
