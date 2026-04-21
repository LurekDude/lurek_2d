# IDEA — `src/particle/`

> **This file is forward-looking.** It records ideas, not commitments. Nothing here is
> implemented in the same session that produces it. Implementation is gated by a separate
> roadmap decision.
>
> See [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md) for filling instructions, TODO syntaxes, and
> the competitor-citation rule.

---

## 1. Header

- **Module**: `particle`
- **Owner module path**: `src/particle/`
- **Last reviewed**: 2026-04-18 (UTC)
- **Reviewer agent**: `developer` · Session: `src-module-review-20260418`
- **Plugin tier candidacy** (per [plugins.md §5](../../docs/architecture/plugins.md#5-candidate-modules)):
  `TIER-1-PLUGIN`
- **LOC (rust only)**: ~1800 · **Public Lua surface**: `lurek.particle` — ~55 fns / 2 userdata (`ParticleSystem`, `Trail`)
- **Inbound non-`lua_api` callers**: none
- **Heavy dependencies**: `fastrand` (lightweight), `crate::render`, `crate::math`, `crate::image`

## 2. Mission Summary

The `particle` module provides emitter-based 2D particle effects for GameDev and Modder
personas. It manages a bounded pool of short-lived `Particle` instances with Euler
integration, multi-stop color/size/alpha interpolation, emission shapes, attractors,
bounce bounds, and sub-emitter death bursts. It is NOT a GPU compute particle system,
and does NOT own collision detection against physics bodies.

## 3. Existing Strengths

- Rich `EmissionShape` enum with 8 variants (Point, Circle, Rectangle, Ring, Line, Cone, Star, Spiral) — covers most 2D spawn patterns.
- Multi-stop interpolation for size, color, and alpha with independent keyframe arrays — more flexible than two-stop start/end.
- 10 geometric `ParticleShape` variants including Shrapnel (deterministic via `shape_seed`) and Capsule — good untextured rendering coverage.
- `Trail` ribbon renderer with head/tail color interpolation and width tapering — useful for projectile trails and motion effects.
- Sub-emitter / death-burst system (`death_emitter` + `death_burst_count`) — enables cascading particle effects without Lua polling.
- Comprehensive test coverage in `emitter_tests.rs` (~30 tests) plus `math.rs`, `render.rs`, and `trail.rs` test modules.

## 4. Gap List

1. **[P1][GAP]** No physics-body collision — particles cannot bounce off Rapier colliders.
   - Why: sand simulation, blood splatters on floors, confetti hitting platforms all need physics awareness.
2. **[P2][GAP]** CPU-only integration — no GPU compute path for >10k particles.
   - Why: fire walls, dense rain, explosion debris want 50k+ particles at 60 FPS.
3. **[P2][GAP]** No particle-level texture atlas sub-region animation beyond flipbook — no per-particle random quad selection.
   - Why: debris fields with varied chunk sprites need random quad assignment, not just sequential flipbook.
4. **[P3][GAP]** No serialization / preset loading from TOML or JSON — all config is code-constructed.
   - Why: GameDev and Modder personas want to tweak effects in data files without recompiling.

## 5. Feature Ideas

1. **[P1][FEAT]** `setCollidesWithPhysics(world)` — register particle system with a Rapier world so particles bounce off colliders.
   - Rationale: enables platformer juice (blood, sparks hitting floors) without per-particle Lua callbacks.
   - Effort: M · Risk: med (perf cost of broadphase queries per particle per frame).
   - Competitor inspiration: `[Godot: GPUParticles2D collision with physics bodies — https://docs.godotengine.org/en/stable/classes/class_gpuparticles2d.html]`, `[LOVE2D: no built-in particle-physics; community does manual raycast per frame — https://love2d.org/wiki/ParticleSystem]`.

2. **[P2][FEAT]** TOML/JSON preset loader for `ParticleConfig` — `lurek.particle.loadPreset("fire.toml")`.
   - Rationale: data-driven particle design lets artists iterate without touching Lua.
   - Effort: S · Risk: low.

3. **[P3][FEAT]** GPU compute emitter path — wgpu compute shader updates particle positions in parallel on the GPU.
   - Rationale: unlocks >50k particles at 60 FPS for volumetric fire, dense rain, snow.
   - Effort: L · Risk: high (new pipeline, data readback, portability across wgpu backends).
   - Competitor inspiration: `[Godot: GPUParticles2D uses compute shaders — https://docs.godotengine.org/en/stable/classes/class_gpuparticles2d.html]`.

## 6. Performance / Reliability / Quality Ideas

- **[P1][PERF]** Parallel particle update via rayon — particle integration is data-parallel with no shared mutable state.
  - Hot path: `emitter.rs:update()` inner loop (~line 110–210).
  - Verification: criterion bench comparing sequential vs par_iter for 5k, 10k, 50k particles.
- **[P2][QUAL]** Extract visualization methods (`draw_to_image`, `draw_explosion_to_image`, etc.) from `emitter.rs` into a dedicated `visualization.rs` — these ~250 lines are diagnostic-only and bulk up the core simulation file.
  - File: `emitter.rs` lines 620–900.
  - Reason: separation of concerns; emitter.rs focuses on simulation, visualization.rs on debug/evidence rendering.
- **[P3][PERF]** Pre-allocate `Vec<ParticleInstance>` in `build_render_commands` using a reusable buffer instead of fresh allocation each frame.
  - Hot path: `emitter.rs:build_render_commands()`.
  - Verification: `RUST_LOG` frame-time before/after.

## 7. Test Coverage Gaps

- **[P2][TEST-LUA]** Add Lua BDD test for `lurek.particle.newSystem` with death-emitter sub-burst chain.
- **[P2][TEST-LUA]** Add Lua BDD test for `ParticleSystem:setFlipbook` sprite-sheet animation.
- **[P3][TEST-RUST]** Add Rust unit test for `emission.rs` `BorderRectangle` distribution uniformity (statistical test over many samples).
- **[P3][TEST-FUZZ]** Fuzz target candidate: `ParticleConfig` with randomized field ranges → `ParticleSystem::update(dt)` must not panic.

## 8. TODO(dedup): Cross-Module Overlap

```text
TODO(dedup): effect::ParticleEffect — particle and effect modules both manage particle-like visual effects; clarify ownership boundary (particle = point emitters, effect = full-screen post-processing?)
TODO(dedup): math::lerp — particle::math::lerp duplicates crate::math::lerp; consider re-exporting from crate::math
```

## 9. TODO(helper): Engine-Level Helper Candidates

```text
TODO(helper): particle_presets — common particle configs (fire, smoke, rain, snow, sparks) repeated across content/demos/ and content/examples/ — could be a content/library/particle_presets/ module
```

## 10. TODO(plugin): Plugin Candidacy Proposal

```text
TODO(plugin): TIER-1-PLUGIN — particle system is a self-contained feature with no inbound non-lua_api callers; extraction would remove ~1800 LOC and fastrand from the core binary for games that don't use particles
```

- **Extraction blockers**: `crate::render::renderer::RenderCommand::DrawParticleSystem` variant in the renderer enum; would need a plugin render-command extension point.
- **Heavy dep impact if extracted**: minimal (fastrand is tiny; bulk is pure Rust).
- **Lua surface stability**: evolving (death emitters and flipbook are recent additions).
- **Migration step**: M2 (feature-gate behind `particle` Cargo feature, then extract to separate crate).

## 11. References

- Module spec: [docs/specs/particle.md](../../docs/specs/particle.md)
- Lua API reference: [docs/API/lua-api.md#particle](../../docs/API/lua-api.md)
- Philosophy constraints touched: `B-03` (60 FPS target — particle count affects frame budget)
- Plugin doc tier table: [plugins.md §5](../../docs/architecture/plugins.md#5-candidate-modules)
- Competitor links cited above: Godot GPUParticles2D, LOVE2D ParticleSystem
- Authoring guide: [IDEA_AUTHORING.md](../../work/src-module-review-20260418/reports/IDEA_AUTHORING.md)
- Session plan: [PLAN.md](../../work/src-module-review-20260418/reports/PLAN.md) · Session decisions: [DECISIONS.md](../../work/src-module-review-20260418/reports/DECISIONS.md)
# IDEA.md — `particle` module

> Migrated from `ideas/features/particle.md` and `ideas/performance/03-particle-audio.md` (particle section).
> Status checked against `src/particle/` and `src/lua_api/particle_api.rs`.
> Lua namespace: `lurek.particle`.

---

## Features

### ❌ TODO — Particle Collision with Physics
**Source**: features/particle.md — Feature Gaps #6

No `setCollidesWithPhysics(world)` found. Particles can't bounce off physics bodies.
This is an advanced feature but critical for sand-simulation and satisfying
platformer juice (blood drops hitting floors).

---

### 🤔 CONSIDER — GPU Particle System
**Source**: features/particle.md — Feature Gaps #8 / performance/03-particle-audio.md

CPU-side particle update limits maximum live particle count (~50k on a modern CPU).
A GPU compute–backed emitter using wgpu compute shaders could handle millions. This is
a large engineering effort. Document capability ceiling and recommend GPU particles only
when the CPU ceiling is hit in profiling.

---

## Performance

### ❌ TODO — Parallel Particle Update (rayon)
**Source**: performance/03-particle-audio.md — Particle section

Particle integration (position, lifetime, color curves) is fully data-parallel. No rayon
found in `src/particle/emitter.rs`. Priority: **MEDIUM** (useful at ~5k+ live particles).
