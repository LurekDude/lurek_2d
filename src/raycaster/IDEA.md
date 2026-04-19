# IDEA — raycaster

| Field  | Value          |
| ------ | -------------- |
| Module | raycaster      |
| Path   | src/raycaster/ |
| Date   | 2026-04-18     |
| Tier   | TIER-2-PLUGIN  |

## Mission

Provide a complete grid-based 2D raycaster engine for Wolfenstein/Doom-style FPS and dungeon-crawler games, including DDA traversal, textured-quad scene building, lighting, doors, heightmaps, billboard sprites, visibility polygons, minimap extraction, and CPU/GPU render command generation.

## Strengths

- **Feature-complete raycaster pipeline**: DDA traversal → projection → scene building → render commands / CPU draw — covers the full chain from grid data to rendered output.
- **Per-polygon lighting**: `build_scene.rs` integrates point-light illumination into every quad, not just distance shading — a step beyond classic Wolfenstein engines.
- **Translucent wall support**: `cast_ray_multi` with per-tile alpha enables stained-glass and grated-wall effects that most 2D raycasters lack.
- **Rich visualization helpers**: `draw_top_down_to_image`, `draw_view_to_image`, `draw_textured_view_to_image`, `draw_camera_sweep_to_image`, `draw_line_of_sight_to_image` give headless testing and debug tooling without a GPU.
- **Strong test coverage**: All 16 logic files have inline `#[cfg(test)]` modules; only pure data structs (`ray_hit.rs`, `sprite_projection.rs`) lack tests.

## Gaps

- **No floor/ceiling texture rendering in `build_scene`**: `cast_floor_row` exists in `dda.rs` but `build_scene.rs` only emits solid-colour floor/ceiling quads — floor UV texturing is unused.
- **No thin-wall or angled-wall support**: DDA traversal is axis-aligned grid only; angled walls require the separate `segment.rs` path which is disconnected from the scene builder.
- **No portal/sector rendering**: Cannot render non-rectangular rooms or room-over-room without heightmap workarounds.
- **`dda.rs` is oversized (~1150 lines)**: Visualization helpers (`draw_*_to_image`, `procedural_texture_color`) bloat the core DDA module.
- **Rust-internal types undocumented**: `ColumnBatch`, `Segment`, and `DepthBuffer` have no Lua binding — should be explicitly documented as Rust internals or exposed.

## Features — Competitor Cites

1. **Godot `RayCast2D` node** — Godot exposes raycasting as a scene-tree node with collision mask filtering and real-time debug visualization in the editor viewport. Lurek2D's `Raycaster2D` is lower-level (no scene integration) but more composable for retro FPS use.
2. **LÖVE `bump` / `windfield` community libs** — LÖVE lacks a built-in raycaster; community solutions (`bump.lua`, `windfield`) use AABB or Box2D queries. Lurek2D ships a first-party DDA raycaster with translucent-wall multi-hit, which these libraries do not provide.
3. **Bevy `bevy_rapier` ray casting** — Bevy delegates raycasting to Rapier physics queries (`RapierContext::cast_ray`), coupling ray results to the ECS. Lurek2D keeps raycasting decoupled from physics, which is lighter for pure retro rendering but lacks physics-aware collision filtering.

## Perf / Quality

- DDA inner loop is allocation-free; `cast_rays` pre-allocates the result vector.
- `ColumnBatch` and `DepthBuffer` accessors are documented as allocation-free for hot-path usage.
- CPU draw (`draw.rs`) iterates pixels with bounds-clamped loops — safe but not SIMD-optimized.
- `build_scene.rs` pre-reserves wall/floor/ceiling vectors, reducing mid-frame reallocation.
- Procedural texture generation in `dda.rs` is branchful per-pixel — acceptable for debug images only.
- DDA raycaster is near-optimal for 2D grid traversal; bottleneck is GPU draw call count for wall columns and sprite batching, not the DDA logic.

## Test Gaps

- `cast_ray_multi` (translucent walls) has no dedicated unit test — coverage relies on integration through Lua tests.
- `cast_floor_row` has no unit test.
- `project_sprite` only tests the behind-camera case; no test for visible in-FOV sprites.
- `set_cells` bulk setter has no unit test.
- `draw_*_to_image` visualization helpers have no tests (only called from Lua evidence tests).
- `set_wall_alpha` / `get_wall_alpha` have no dedicated tests.

## TODO(dedup)

- [ ] Extract `draw_*_to_image` and `procedural_texture_color` from `dda.rs` into a `visualization.rs` sibling module (~300 lines).
- [ ] `WorldSprite` is defined in both `build_scene.rs` and `sprite_manager.rs` with different fields — unify or rename to avoid confusion (mod.rs already aliases with `ManagedSprite`).

## TODO(helper)

- [ ] Wire `cast_floor_row` into `build_scene.rs` so floor/ceiling quads receive proper texture UVs.
- [ ] Add `project_sprite` test for the visible-in-FOV case.
- [ ] Add unit tests for `cast_ray_multi`, `set_cells`, `set_wall_alpha`, `get_wall_alpha`, `cast_floor_row`.

## TODO(plugin)

- [ ] Extract `src/raycaster/` into a Cargo feature-gated plugin per constraint A-05 / `docs/architecture/plugins.md`.
- [ ] Gate `lurek.raycaster` Lua namespace registration behind the feature flag in `src/lua_api/mod.rs`.
- [ ] Move render-command dependency (`src/render/renderer.rs` types) behind a trait so the raycaster can compile without the full render stack.

## References

- `docs/specs/raycaster.md` — module spec
- `src/lua_api/raycaster_api.rs` — Lua bridge
- `tests/lua/unit/test_raycaster.lua` — Lua unit tests
- `tests/lua/evidence/test_evidence_raycaster.lua` — Lua evidence tests
- `docs/architecture/plugins.md` — plugin tier design
