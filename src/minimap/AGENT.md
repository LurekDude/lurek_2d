# minimap

## Module Info
- Module name: `minimap`
- Module group: `Feature Systems`
- Spec path: `docs/specs/minimap.md`
- Lua API path(s): `src/lua_api/minimap_api.rs`
- Rust test path(s): `tests/rust/game/minimap_tests.rs`
- Lua test path(s): `tests/lua/unit/test_minimap.lua`, `tests/lua/evidence/test_evidence_minimap.lua`

## Module Purpose
The `minimap` module provides a compact overhead representation of a larger game world. It stores terrain cells, fog-of-war state, tracked objects, temporary pings, persistent markers, and the current viewport rectangle so scripts can present navigational context without rebuilding that logic every frame.

It exists to centralize minimap state and coordinate conversion in one CPU-side system. That keeps world-to-minimap math, visibility bookkeeping, and ping or marker lifecycle out of UI code and out of unrelated gameplay modules.

It intentionally does not own input handling, camera control, or texture-backed rendering. The module produces draw-ready data and render commands, but the actual UI composition and event routing stay elsewhere.

## Files
- `mod.rs` - Declares the minimap submodules and re-exports the core minimap and support types.
- `minimap.rs` - Implements the main `Minimap` state container, including terrain cells, fog, tracked objects, markers, pings, zoom, pan, and coordinate transforms.
- `render.rs` - Generates render commands for the minimap background, cells, viewport rectangle, and animated pings.
- `types.rs` - Defines shared enums and data records such as fog levels, color modes, objects, pings, and markers.

## Key Types
- `Minimap` - The main grid-based minimap model. It owns terrain, visibility, tracked entities, overlays, and minimap-space conversions.
- `ColorMode` - Chooses how minimap cells are colored, such as terrain-driven versus owner-driven display.
- `FogLevel` - Encodes whether a minimap cell is hidden, explored, or currently visible.
- `MinimapObject` - A tracked world object projected onto the minimap with position, type, and owner metadata.
- `MinimapPing` - A temporary animated alert marker used for events or attention cues.
- `MinimapMarker` - A persistent named marker with descriptive text for locations of interest.