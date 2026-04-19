# IDEA.md — `minimap`

| Field  | Value           |
| ------ | --------------- |
| Module | `minimap`       |
| Path   | `src/minimap/`  |
| Date   | 2026-04-18      |
| Tier   | Feature Systems |

## Mission

Grid-based overhead minimap with terrain coloring, fog of war, tracked objects, pings, persistent markers with animations, viewport rectangle overlay, geometry overlays, path display, multi-layer support, and coordinate transforms. Pure CPU data model that emits `RenderCommand` lists for the GPU.

## Strengths

- Comprehensive feature set: terrain, fog, objects, pings, markers, overlays, paths, layers — covers RTS, RPG, and strategy needs.
- Clean separation: `minimap.rs` (data), `types.rs` (enums/structs), `render.rs` (command generation) — no cross-concerns.
- Fog of war with three levels (Hidden / Explored / Visible) and configurable fog tint.
- Marker animations (Blink / Pulse / Rotate) with per-frame phase advance.
- Zoom/pan with screen↔grid coordinate conversions and hover tooltip support.
- Two render paths: `generate_render_commands` (zoom-aware) and `build_render_commands` (simple cell-based) plus CPU `draw_to_image`.

## Gaps

- No GPU-accelerated fog of war — CPU per-cell iteration at 500×500+ grids will be expensive. **Godot** uses shader-based fog reveal; **Unity** URP has GPU fog compute; **Factorio** uses GPU texture blit for minimap fog.
- Fog of war is bundled inside the minimap — cannot be reused by the game world. **Godot** TileMap visibility can operate independently of minimap; **StarCraft II** fog is a world-level system feeding both minimap and main viewport; **LÖVE** fog is a separate mask texture.
- No icon/texture rendering for markers and objects — only geometric primitives. **Godot** minimap tutorials use `TextureRect` for icons; **Unity** minimap packages render sprite icons; **Factorio** draws entity icons on the map.

## Features (Competitor Cites)

1. **GPU fog of war compute** — Godot shader-based fog, Unity URP compute fog, Factorio GPU minimap blit. Needed for large maps (500×500+).
2. **Standalone fog of war system** — Godot TileMap visibility, StarCraft II world-level fog, LÖVE mask textures. Enables fog on the main viewport, not just the minimap.
3. **Icon/texture markers** — Godot TextureRect minimap icons, Unity minimap sprite icons, Factorio entity icons. Required for readable minimaps in games with many object types.

## Perf / Quality

- Terrain rendering iterates every visible cell per frame, emitting 2 `RenderCommand`s each — O(cells_visible) which is fine for typical minimap sizes (< 100×100 visible cells).
- `update()` uses `retain_mut` for pings — no allocation.
- `build_render_commands` iterates ALL grid cells regardless of zoom — could be optimized with visible-range culling (like `generate_render_commands` does).
- Political color mode in `draw_to_image` has O(objects × cells) scan — should use a per-cell owner map.

## Test Gaps

- `minimap.rs` had no inline tests — added sibling `minimap_tests.rs` (30 tests): construction, terrain, fog, objects, markers, pings, overlays, paths, layers, coordinate transforms, hover.
- `mod.rs` has no tests (re-exports only — acceptable).
- No test for `draw_to_image` pixel output correctness.
- No test for `build_render_commands` vs `generate_render_commands` consistency.
- No performance benchmark for large grids (500×500).

## TODO(dedup)

- `build_render_commands` and `generate_render_commands` both generate terrain cell rectangles with slightly different zoom/culling logic. Unify into a single configurable path.
- `draw_to_image` duplicates fog-multiplier logic from `generate_render_commands`. Extract a shared `fog_multiplier(gx, gy) -> f32` helper.

## TODO(helper)

- `Minimap::from_tilemap(tilemap)` — auto-populate terrain grid from a `Tilemap` instance.
- `Minimap::track_camera(camera)` — auto-update viewport rect from the current Camera.
- `Minimap::reveal_radius(cx, cy, radius)` — batch fog reveal around a point.

## TODO(plugin)

- **Plugin candidacy: TIER-2-PLUGIN.** Minimap is Feature Systems with no core-engine consumers. Could be gated behind a `minimap` Cargo feature flag. The Lua surface `lurek.minimap.*` would remain optional.
- Fog of war extraction into a standalone `fow` module/plugin is a prerequisite for world-level fog.

## References

- `docs/specs/minimap.md` — module spec (canonical).
- `src/lua_api/minimap_api.rs` — Lua binding.
- `src/render/renderer.rs` — `RenderCommand` types used by `render.rs`.
- `src/image/` — `ImageData` used by `draw_to_image`.
