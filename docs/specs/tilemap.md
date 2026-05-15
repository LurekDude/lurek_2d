# tilemap

## General Info

- Module group: `Feature Systems`
- Source path: `src/tilemap/`
- Lua API path(s): `src/lua_api/tilemap_api.rs`
- Primary Lua namespace: `lurek.tilemap`
- Rust test path(s): tests/rust/unit/tilemap_tests.rs
- Lua test path(s): tests/lua/unit/test_tilemap.lua, tests/lua/stress/test_tilemap_stress.lua, tests/lua/integration/test_tilemap_physics.lua, tests/lua/integration/test_tilemap_pathfind.lua, tests/lua/integration/test_tilemap_camera.lua, tests/lua/integration/test_save_tilemap.lua, tests/lua/integration/test_procgen_tilemap.lua, tests/lua/golden/test_tilemap_golden.lua, tests/lua/evidence/test_evidence_tilemap.lua

## Summary

The `tilemap` module is Lurek2D's tile-map authoring and rendering subsystem in the Feature Systems tier. It covers the full range from simple single-layer orthogonal grids to multi-layer maps with animated tiles, external format imports, automatic tile selection, isometric depth sorting, hex coordinates, and sparse infinite chunk maps.

**Core map model.** `TileMap` is the top-level container: a multi-layer grid where each `TileLayer` holds a flat row-major `Vec<u32>` of tile GIDs plus display properties — name, Z-order, opacity, visibility flag, tint colour, parallax scroll multipliers, and per-layer draw offsets. Primary CRUD: `get_tile(layer, x, y)`, `set_tile(layer, x, y, id)`, `fill_rect(layer, rect, id)`, `swap_tiles(layer, rect)`. Viewport culling: only tiles within the camera AABB are rendered. `sweep_rect(rect)` returns all non-empty GIDs intersecting a world-space AABB — used as the broad-phase collision pre-filter before rapier2d shape generation. Animation state tracks frame timers per animated tile GID across all layers.

**TileSet.** Stores the source `TextureKey`, tile dimensions, tile count, and per-tile properties: `passable` flag, optional `TileAnimFrame` sequence (local-id + duration pairs), custom `HashMap<String, String>` properties, and an optional `collision_shape` override for physics collider generation. The collision shape allows concave and non-rectangular hitboxes per tile variant.

**External format importers.** `load_tmx(path)` parses Tiled `.tmx` XML exports including object layers, tile properties, image layers, embedded and external tileset references, and base64/zlib-encoded tile payloads. `load_ldtk(path)` parses LDtk JSON exports. Both populate native `TileMap` + `TileSet` structures so all downstream code is format-agnostic.

**AutoTile.** `AutoTileSheet` precomputes bitmask-to-tile-index lookup tables for three atlas layouts: RPGMaker blob-47, composite-48, and minimal-16. Given an 8-neighbor bitmask, it selects the correct tile variant automatically — eliminating manual tile placement in procedurally generated or runtime-editable maps. `get_quarter_rects` / `get_quarter_dst_rects` support sub-tile composite rendering for RPGMaker 47-tile atlas format.

**Isometric and hex support.** `IsoMap` stores multi-level isometric grids with four `IsoTilePart` sub-slots per cell (Floor, Wall, Object, Overlay) and yields painter's-algorithm depth-sorted `IsoDrawItem` records for correct layering. `coords.rs` provides `to_screen_iso` / `from_screen_iso` (diamond isometric projection) and `to_screen_hex` / `from_screen_hex` (pointy-top axial hex) coordinate conversion helpers usable from both Rust and Lua.

**Chunk map.** `ChunkMap` is a `HashMap<(i32, i32), Vec<u32>>` sparse infinite tile map supporting negative coordinates. `load_chunk` / `unload_chunk` manage per-chunk lifecycle. `get_chunks_in_view(viewport)` returns only chunk keys intersecting the camera frustum for efficient streaming.

**Procedural generation.** `MapGen` consumes `MapBlock` prefab libraries and `MapScript` step sequences to assemble `TileMap` outputs procedurally. `PolygonMap` manages named polygon overlays with hit-testing, highlight state, and bounding-box queries for province or zone overlay use cases.

**Tile walker.** `TileWalker` implements a cardinal, cell-by-cell movement controller with directional facing, step animation readiness, and passability checks — useful for dungeon-crawler or grid-locked movement games.

**Render integration.** `render.rs` generates `RenderCommand` batches from `TileMap` layers. `large_map_renderer.rs` tracks chunk visibility, dirty state, and LOD metadata for worlds that need culling-friendly batched rendering at scale.

**Lua surface.** `lurek.tilemap.newMap(w, h, tile_w, tile_h)` creates an empty map. `lurek.tilemap.loadTMX(path)` and `lurek.tilemap.loadLDtk(path)` import external formats. The `TileMap` userdata exposes layer management, tile CRUD, fill/flood operations, animation control, physics collision mesh generation, chunk streaming, and render command retrieval. `AutoTileSheet` is exposed via `lurek.tilemap.newAutoTileSheet(tileset, layout)` with a `computeTile(map, layer, x, y)` method. `IsoMap` and coordinate helpers are exposed under the same namespace.

**Scope boundary.** Feature Systems tier. Depends on `render`, `math`, `runtime`, `image`. Lua bridge in `src/lua_api/tilemap_api.rs`.

## Files

- `autotile_sheet.rs`: Defines autotile lookup tables for blob-47, composite-48, and minimal-16 layouts and applies those rules onto a `TileSet`.
- `chunk.rs`: Implements `ChunkMap`, a sparse chunked tile store for very large or effectively infinite worlds with negative coordinate support.
- `coords.rs`: Provides standalone isometric and hex-grid conversion helpers so scripts and engine code can reason about non-orthogonal tile coordinates without embedding projection math elsewhere.
- `isomap.rs`: Stores multi-level isometric maps and yields painter-ordered draw items for floor, wall, and object parts per cell.
- `large_map_renderer.rs`: Tracks chunk visibility, dirty state, viewport, and LOD metadata for large tile worlds that need efficient culling-friendly batching.
- `ldtk.rs`: LDtk JSON map format importer.
- `mapgen.rs`: Implements prefab blocks, grouped block libraries, scripted generation steps, and map assembly logic for procedural tilemap authoring.
- `mod.rs`: Declares the tilemap submodules and re-exports the main map, tileset, generation, TMX, isometric, and utility types as the public module surface.
- `polygon_map.rs`: Manages named polygon regions with hit testing, labels, highlight state, and bounding-box queries for map overlays or province-style regions.
- `render.rs`: Adds `TileMap` render-command generation so tile layers can be turned into CPU-side draw commands without putting map traversal logic in the renderer.
- `tile_walker.rs`: Implements a cardinal, cell-by-cell movement controller for dungeon-crawler or raycast-style navigation on a tile grid.
- `tilemap.rs`: Holds the core layered `TileMap`, including tile CRUD, per-layer display state, viewport culling, animation state, and tile collision queries.
- `tileset.rs`: Defines `TileSet` atlas layout, per-tile animation frames, solid flags, and 4-bit or 8-bit autotile rule tables.
- `tmx.rs`: Parses Tiled TMX data, including tilesets, tile layers, object layers, and supported encoded tile payloads.

## Types

- `AutoTileLayout` (`enum`, `autotile_sheet.rs`): Enumerates the supported autotile sheet conventions and therefore which lookup rules apply.
- `AutoTileSheet` (`struct`, `autotile_sheet.rs`): Precomputed autotile layout helper that maps neighbor bitmasks to tile indices for common autotile atlas formats.
- `ChunkMap` (`struct`, `chunk.rs`): Sparse tile storage for streamed or massive maps where allocating one dense grid would be wasteful.
- `IsoTilePart` (`enum`, `isomap.rs`): The four sub-slots within each isometric map cell, rendered in this order.
- `IsoTile` (`struct`, `isomap.rs`): One map cell containing four GIDs, one per [`IsoTilePart`].
- `IsoLevel` (`struct`, `isomap.rs`): One Z-level within an `IsoMap`, holding the grid of `IsoTile` cells for that floor.
- `IsoDrawItem` (`struct`, `isomap.rs`): A render-ready isometric cell part with tile coordinates, level, part, gid, and projected screen position.
- `IsoMap` (`struct`, `isomap.rs`): Multi-level isometric map model that stores four tile parts per cell and yields stable painter-order iteration.
- `MapChunk` (`struct`, `large_map_renderer.rs`): The chunk record stored by `LargeMapRenderer`, including dirty state and the chunk's local tile payload.
- `LargeMapRenderer` (`struct`, `large_map_renderer.rs`): CPU-side helper for chunk visibility and LOD bookkeeping over large dense tilemaps.
- `Edge` (`enum`, `mapgen.rs`): Cardinal edge direction for block-segment connectivity.
- `MapBlock` (`struct`, `mapgen.rs`): A reusable prefab tile block with multi-layer tile data and edge metadata for procedural placement.
- `MapGroup` (`struct`, `mapgen.rs`): A named collection of blocks and generation scripts that acts like a biome or prefab library.
- `StepType` (`enum`, `mapgen.rs`): Identifies which generation action a `ScriptStep` performs.
- `ScriptStep` (`struct`, `mapgen.rs`): One procedural generation operation with parameters such as placement mode, size filters, repetition, and chance.
- `MapScript` (`struct`, `mapgen.rs`): A reusable scripted generation recipe composed of ordered `ScriptStep` values.
- `MapOrientation` (`enum`, `mapgen.rs`): Describes the intended map orientation mode used by generation and map construction code.
- `LayerMode` (`enum`, `mapgen.rs`): How layers are managed during generation.
- `MapSize` (`enum`, `mapgen.rs`): Predefined map size presets expressed in segment-grid units.
- `MapZone` (`struct`, `mapgen.rs`): A named horizontal zone within a generated map.
- `MapGen` (`struct`, `mapgen.rs`): The procedural assembly engine that consumes blocks and scripted steps to build a `TileMap`.
- `PolygonRegion` (`struct`, `polygon_map.rs`): One polygon region entry with geometry, display color, and optional label.
- `PolygonMap` (`struct`, `polygon_map.rs`): A named region overlay useful for province, zone, or area queries over a world map.
- `Facing` (`enum`, `tile_walker.rs`): Cardinal facing direction used by `TileWalker`.
- `TileWalker` (`struct`, `tile_walker.rs`): Simple first-person or grid-walk movement state with facing and interpolation support.
- `TileLayer` (`struct`, `tilemap.rs`): A single named tile layer with visibility, tint, parallax, offset, and per-tile GID storage.
- `SweepResult` (`struct`, `tilemap.rs`): The return value for swept AABB tile collision tests, carrying hit point, normal, tile coordinates, and time-of-impact.
- `TileMap` (`struct`, `tilemap.rs`): The main layered orthogonal map container. It owns tilesets, layers, animation timers, viewport state, and the map-side queries that other systems consume.
- `TileAnimFrame` (`struct`, `tileset.rs`): One frame in a tile animation sequence, pairing a local tile id with a duration.
- `TileSet` (`struct`, `tileset.rs`): Atlas metadata plus per-tile behavior such as solidity, animation, and autotile rule mappings.
- `TmxOrientation` (`enum`, `tmx.rs`): TMX map orientation enum.
- `TmxStaggerAxis` (`enum`, `tmx.rs`): The axis along which isometric / hexagonal tiles are staggered.
- `TmxTileset` (`struct`, `tmx.rs`): TMX-side tileset metadata, including atlas info and solid tile markers.
- `TmxTileLayer` (`struct`, `tmx.rs`): Parsed tile layer payload from TMX.
- `TmxObjectLayer` (`struct`, `tmx.rs`): Parsed object-layer payload from TMX.
- `TmxObject` (`struct`, `tmx.rs`): One object entry from a TMX object layer.
- `TmxLayer` (`enum`, `tmx.rs`): Tagged enum for the layer kinds parsed from a TMX file.
- `TmxMap` (`struct`, `tmx.rs`): Parsed TMX document containing map dimensions, tilesets, and loaded layers.

## Functions

- `AutoTileSheet::new` (`autotile_sheet.rs`): Create a sheet for tiles of `tile_w` × `tile_h` pixels using the given `layout`; builds bitmask tables.
- `AutoTileSheet::get_layout` (`autotile_sheet.rs`): Return the sheet's packing layout variant.
- `AutoTileSheet::get_tile_count` (`autotile_sheet.rs`): Return the number of unique tiles in this sheet.
- `AutoTileSheet::get_tile_width` (`autotile_sheet.rs`): Return the pixel width of one tile.
- `AutoTileSheet::get_tile_height` (`autotile_sheet.rs`): Return the pixel height of one tile.
- `AutoTileSheet::apply_to_tileset` (`autotile_sheet.rs`): Register each sheet bitmask as an autotile rule in `tileset` for `type_name`, offset by `start_gid`.
- `AutoTileSheet::get_bitmask_for_tile` (`autotile_sheet.rs`): Return the bitmask stored at `index` in the sheet; returns 0 for out-of-range indices.
- `AutoTileSheet::get_tile_for_bitmask` (`autotile_sheet.rs`): Return the tile index for `bitmask`; returns `None` when the bitmask has no match.
- `AutoTileSheet::get_quad` (`autotile_sheet.rs`): Return the source `Rect` for tile at `index` in a single-row horizontal strip; returns empty rect for out-of-range.
- `AutoTileSheet::get_grid_quad` (`autotile_sheet.rs`): Return the source `Rect` for tile at `index` laid out in a grid of `cols` columns; returns empty rect on invalid input.
- `AutoTileSheet::get_composite48_grid_quad` (`autotile_sheet.rs`): Return the source `Rect` for tile at `index` in a 6-column composite-48 grid.
- `AutoTileSheet::get_quarter_rects` (`autotile_sheet.rs`): Return four quarter source `Rect`s (TL, TR, BL, BR) for compositing a tile from `bitmask`.
- `AutoTileSheet::get_quarter_dst_rects` (`autotile_sheet.rs`): Return four quarter destination `Rect`s (TL, TR, BL, BR) at world position `(x, y)`.
- `ChunkMap::new` (`chunk.rs`): Create a `ChunkMap` with the given `chunk_size`; panics when `chunk_size` is zero.
- `ChunkMap::get_chunk_size` (`chunk.rs`): Return the side length in tiles of each chunk.
- `ChunkMap::get_tile` (`chunk.rs`): Return the GID at tile `(x, y)`; returns `DEFAULT_GID` when the chunk is not loaded.
- `ChunkMap::set_tile` (`chunk.rs`): Write `gid` to tile `(x, y)`, allocating the chunk if needed.
- `ChunkMap::clear_tile` (`chunk.rs`): Reset tile `(x, y)` to GID 0, allocating the chunk if needed.
- `ChunkMap::fill_rect` (`chunk.rs`): Fill all tiles in the rectangle `[x0,x1) × [y0,y1)` with `gid`.
- `ChunkMap::load_chunk` (`chunk.rs`): Ensure the chunk at `(cx, cy)` is allocated; no-op when already loaded.
- `ChunkMap::unload_chunk` (`chunk.rs`): Discard the chunk at `(cx, cy)` and free its memory.
- `ChunkMap::get_loaded_chunks` (`chunk.rs`): Return the coordinates of all currently loaded chunks.
- `ChunkMap::get_loaded_chunk_count` (`chunk.rs`): Return the number of currently loaded chunks.
- `ChunkMap::is_chunk_loaded` (`chunk.rs`): Return `true` when the chunk at `(cx, cy)` is loaded.
- `ChunkMap::tile_to_chunk` (`chunk.rs`): Convert tile coordinates `(x, y)` to their parent chunk coordinates.
- `ChunkMap::chunk_tile_range` (`chunk.rs`): Return the inclusive tile range `(min_x, min_y, max_x, max_y)` covered by chunk `(cx, cy)`.
- `ChunkMap::get_chunks_in_view` (`chunk.rs`): Return all chunk coordinates overlapping a view rectangle `(vx,vy,vw,vh)` with tile size `(tw,th)`.
- `ChunkMap::chunk_world_rect` (`chunk.rs`): Return the world-space `Rect` occupied by chunk `(cx, cy)` given tile dimensions `(tw, th)`.
- `ChunkMap::iter_chunk` (`chunk.rs`): Return the tile slice of chunk `(cx, cy)`, or `None` when the chunk is not loaded.
- `to_screen_iso` (`coords.rs`): Converts tile coordinates to screen position using diamond isometric projection.
- `from_screen_iso` (`coords.rs`): Converts screen position back to tile coordinates for diamond isometric projection.
- `iso_rotate` (`coords.rs`): Rotates an isometric direction (1–4) clockwise by `steps`.
- `iso_direction_name` (`coords.rs`): Returns the name of an isometric direction (1–4).
- `iso_direction_from_angle` (`coords.rs`): Snaps an angle (in radians) to the nearest isometric direction (1–4).
- `to_screen_hex` (`coords.rs`): Converts axial hex coordinates to screen position (pointy-top layout).
- `from_screen_hex` (`coords.rs`): Converts screen position back to axial hex coordinates (pointy-top layout).
- `hex_neighbors` (`coords.rs`): Returns the six axial neighbor offsets for pointy-top hexagonal grids.
- `hex_distance` (`coords.rs`): Returns the hex distance between two axial coordinates using cube distance.
- `hex_round` (`coords.rs`): Rounds fractional axial coordinates to the nearest hex cell using cube rounding.
- `hex_line` (`coords.rs`): Returns all hex cells along a line between two axial coordinates.
- `hex_ring` (`coords.rs`): Returns all cells at exactly `radius` distance from `(q, r)`.
- `hex_spiral` (`coords.rs`): Returns all hex cells from center outward to `radius`, ring by ring.
- `hex_area` (`coords.rs`): Returns all hex cells within `radius` distance (filled hex circle).
- `hex_rotate` (`coords.rs`): Rotates hex coordinates `(q, r)` around `(center_q, center_r)` by `steps × 60°` clockwise.
- `hex_reflect` (`coords.rs`): Reflects hex coordinates across an axis through the center.
- `IsoTilePart::from_index` (`isomap.rs`): Convert an integer `i` to an `IsoTilePart`; returns `None` for unrecognised values.
- `IsoTilePart::index` (`isomap.rs`): Return the integer index of this part variant.
- `IsoLevel::new` (`isomap.rs`): Allocate a `width`×`height` level with each tile pre-filled with `part_count` zero GIDs.
- `IsoLevel::get_tile` (`isomap.rs`): Return a shared reference to the tile at `(x, y)`, or `None` for out-of-bounds.
- `IsoLevel::get_tile_mut` (`isomap.rs`): Return a mutable reference to the tile at `(x, y)`, or `None` for out-of-bounds.
- `IsoMap::new` (`isomap.rs`): Create an empty map with the given tile dimensions and `part_count` (clamped to at least 1).
- `IsoMap::add_level` (`isomap.rs`): Append a new elevation level and return its index.
- `IsoMap::get_level_count` (`isomap.rs`): Return the number of elevation levels currently in this map.
- `IsoMap::set_level_visible` (`isomap.rs`): Set `visible` on level `z`; no-op for out-of-range indices.
- `IsoMap::get_level_visible` (`isomap.rs`): Return the visibility of level `z`; returns `true` for missing levels.
- `IsoMap::set_tile_part` (`isomap.rs`): Write `gid` to part `part` of tile `(x,y)` on level `z`; no-op for out-of-range inputs.
- `IsoMap::get_tile_part` (`isomap.rs`): Return the GID of part `part` at tile `(x,y)` on level `z`; returns 0 for missing data.
- `IsoMap::fill_level` (`isomap.rs`): Fill every tile on level `z` at part index `part` with `gid`.
- `IsoMap::set_origin` (`isomap.rs`): Set the world-space origin `(x, y)` that maps to tile `(0,0,0)` in screen space.
- `IsoMap::tile_to_screen` (`isomap.rs`): Convert tile position `(tx, ty, tz)` to screen position `(sx, sy)`.
- `IsoMap::screen_to_tile` (`isomap.rs`): Convert screen position `(sx, sy)` to fractional tile `(tx, ty)` at elevation 0.
- `IsoMap::draw_iter` (`isomap.rs`): Return draw items for all tiles up to `active_z`, sorted in painter order (diagonal strips).
- `IsoMap::get_part_count` (`isomap.rs`): Return the number of draw-layer parts per tile.
- `IsoMap::get_part_order` (`isomap.rs`): Return the current draw-order slice for parts within a tile.
- `IsoMap::set_part_order` (`isomap.rs`): Replace part draw order with `order`; returns an error if length or indices are invalid.
- `LargeMapRenderer::new` (`large_map_renderer.rs`): Create a renderer with `tile_w`×`tile_h` tile dimensions and default chunk size of 16.
- `LargeMapRenderer::set_map_data` (`large_map_renderer.rs`): Replace the map tile data and dimensions, then rebuild all chunks.
- `LargeMapRenderer::set_tile` (`large_map_renderer.rs`): Write `tile_id` at map position `(x, y)` and mark its chunk dirty; no-op for out-of-bounds.
- `LargeMapRenderer::get_tile` (`large_map_renderer.rs`): Return the tile ID at `(x, y)`, or `None` for out-of-bounds.
- `LargeMapRenderer::get_map_size` (`large_map_renderer.rs`): Return the map dimensions as `(width, height)` in tiles.
- `LargeMapRenderer::set_chunk_size` (`large_map_renderer.rs`): Set the chunk side length; clamps to 1 and rebuilds all chunks.
- `LargeMapRenderer::get_chunk_size` (`large_map_renderer.rs`): Return the current chunk side length.
- `LargeMapRenderer::invalidate_chunk` (`large_map_renderer.rs`): Mark the chunk at `(cx, cy)` dirty; no-op when not cached.
- `LargeMapRenderer::invalidate_all` (`large_map_renderer.rs`): Mark every cached chunk dirty.
- `LargeMapRenderer::get_visible_chunks` (`large_map_renderer.rs`): Return the count of cached chunks that intersect the current camera viewport.
- `LargeMapRenderer::get_total_chunks` (`large_map_renderer.rs`): Return the total number of cached chunks regardless of visibility.
- `LargeMapRenderer::chunks` (`large_map_renderer.rs`): Return the full chunk cache map.
- `LargeMapRenderer::set_camera` (`large_map_renderer.rs`): Set the camera centre `(x, y)` and `zoom` factor.
- `LargeMapRenderer::set_viewport` (`large_map_renderer.rs`): Set the viewport dimensions in pixels.
- `LargeMapRenderer::set_lod_enabled` (`large_map_renderer.rs`): Enable or disable LOD down-sampling.
- `LargeMapRenderer::is_lod_enabled` (`large_map_renderer.rs`): Return `true` when LOD is currently enabled.
- `LargeMapRenderer::set_lod_thresholds` (`large_map_renderer.rs`): Replace the LOD zoom-threshold list.
- `LargeMapRenderer::set_tileset_columns` (`large_map_renderer.rs`): Set the tileset column count; clamps to 1.
- `LargeMapRenderer::get_tileset_columns` (`large_map_renderer.rs`): Return the current tileset column count.
- `load_ldtk` (`ldtk.rs`): Parses an LDtk JSON export string and returns a [`TileMap`].
- `Edge::from_str` (`mapgen.rs`): Parse `s` ("north", "east", "south", "west") into an `Edge`; returns `None` for unknown strings.
- `Edge::as_str` (`mapgen.rs`): Return the lowercase string representation of this edge.
- `MapBlock::new` (`mapgen.rs`): Create an empty `MapBlock` with `width`×`height` tiles, `layers` layers, and the given `segment_size`.
- `MapBlock::set_tile` (`mapgen.rs`): Write `gid` at `(x, y)` in `layer`; no-op for out-of-bounds or missing layer.
- `MapBlock::get_tile` (`mapgen.rs`): Return the GID at `(x, y)` in `layer`; returns 0 for out-of-bounds or missing layer.
- `MapBlock::set_side` (`mapgen.rs`): Assign side ID `side_id` to `segment` on the given `edge`.
- `MapBlock::get_side` (`mapgen.rs`): Return the side ID for `segment` on `edge`; returns 0 when unset.
- `MapBlock::get_width` (`mapgen.rs`): Return the block width in tiles.
- `MapBlock::get_height` (`mapgen.rs`): Return the block height in tiles.
- `MapBlock::get_dimensions` (`mapgen.rs`): Return `(width, height)` in tiles.
- `MapBlock::get_layer_count` (`mapgen.rs`): Return the number of tile layers.
- `MapBlock::get_segment_size` (`mapgen.rs`): Return the segment size used for side subdivision.
- `MapBlock::get_width_in_segments` (`mapgen.rs`): Return the number of segments on the north/south edges.
- `MapBlock::get_height_in_segments` (`mapgen.rs`): Return the number of segments on the east/west edges.
- `MapBlock::get_segment_count` (`mapgen.rs`): Return the segment count for the given `edge`.
- `MapBlock::set_name` (`mapgen.rs`): Set the block name.
- `MapBlock::get_name` (`mapgen.rs`): Return the block name.
- `MapBlock::set_weight` (`mapgen.rs`): Set the random selection weight.
- `MapBlock::get_weight` (`mapgen.rs`): Return the random selection weight.
- `MapGroup::new` (`mapgen.rs`): Create an empty `MapGroup` with the given `name`.
- `MapGroup::add_block` (`mapgen.rs`): Append `block` to this group.
- `MapGroup::get_block` (`mapgen.rs`): Return a shared reference to the block at `index`, or `None`.
- `MapGroup::get_block_mut` (`mapgen.rs`): Return a mutable reference to the block at `index`, or `None`.
- `MapGroup::get_block_count` (`mapgen.rs`): Return the number of blocks in this group.
- `MapGroup::remove_block` (`mapgen.rs`): Remove the block at `index`; no-op for out-of-bounds.
- `MapGroup::add_script` (`mapgen.rs`): Append `script` to this group.
- `MapGroup::get_script` (`mapgen.rs`): Return a shared reference to the script at `index`, or `None`.
- `MapGroup::get_script_count` (`mapgen.rs`): Return the number of scripts in this group.
- `MapGroup::get_name` (`mapgen.rs`): Return the group name.
- `MapGroup::set_name` (`mapgen.rs`): Set the group name.
- `StepType::from_str` (`mapgen.rs`): Parse a step-type name string; returns `None` for unrecognised values.
- `StepType::as_str` (`mapgen.rs`): Return the string representation of this step type.
- `MapScript::new` (`mapgen.rs`): Create an empty `MapScript` with the given `name`.
- `MapScript::add_step` (`mapgen.rs`): Append `step` to this script.
- `MapScript::get_step` (`mapgen.rs`): Return a shared reference to the step at `index`, or `None`.
- `MapScript::get_step_count` (`mapgen.rs`): Return the number of steps in this script.
- `MapScript::remove_step` (`mapgen.rs`): Remove the step at `index`; no-op for out-of-bounds.
- `MapScript::clear_steps` (`mapgen.rs`): Remove all steps from this script.
- `MapScript::set_name` (`mapgen.rs`): Set the script name.
- `MapScript::get_name` (`mapgen.rs`): Return the script name.
- `MapSize::grid_dimensions` (`mapgen.rs`): Return the `(grid_w, grid_h)` segment-grid dimensions for this size preset.
- `MapGen::new` (`mapgen.rs`): Create a `MapGen` for the given `size` preset and `segment_size`.
- `MapGen::generate` (`mapgen.rs`): Generate a single-region `TileMap` from `group` using `script_index`, `seed`, and `layer_name`.
- `MapGen::generate_world` (`mapgen.rs`): Generate a `columns`×`rows` world map by tiling independently seeded regions.
- `MapGen::get_grid_width` (`mapgen.rs`): Return the grid width in segments.
- `MapGen::get_grid_height` (`mapgen.rs`): Return the grid height in segments.
- `MapGen::get_grid_dimensions` (`mapgen.rs`): Return `(grid_w, grid_h)` in segments.
- `MapGen::get_segment_size` (`mapgen.rs`): Return the segment size shared with the group blocks.
- `MapGen::set_grid_dimensions` (`mapgen.rs`): Set the grid dimensions in segments.
- `MapGen::set_tile_size` (`mapgen.rs`): Set the pixel dimensions of a single tile.
- `MapGen::get_tile_pixel_width` (`mapgen.rs`): Return the pixel width of one tile.
- `MapGen::get_tile_pixel_height` (`mapgen.rs`): Return the pixel height of one tile.
- `MapGen::get_placement_count` (`mapgen.rs`): Return the placement count from the most recent `generate` or `generate_world` call.
- `MapGen::set_orientation` (`mapgen.rs`): Set the rendering orientation tag.
- `MapGen::get_orientation` (`mapgen.rs`): Return the current rendering orientation.
- `MapGen::add_zone` (`mapgen.rs`): Append a zone band covering `[start_row, start_row + height)`.
- `MapGen::get_zone_count` (`mapgen.rs`): Return the number of defined zones.
- `MapGen::get_zone` (`mapgen.rs`): Return a shared reference to the zone at `index`, or `None`.
- `MapGen::clear_zones` (`mapgen.rs`): Remove all zones.
- `MapGen::set_layer_mode` (`mapgen.rs`): Set the layer mode.
- `MapGen::get_layer_mode` (`mapgen.rs`): Return the current layer mode.
- `PolygonMap::new` (`polygon_map.rs`): Create an empty `PolygonMap` with white outline and yellow highlight.
- `PolygonMap::add_region` (`polygon_map.rs`): Add a region with the given `name`, vertex list, and fill `color`; overwrites any existing region with the same name.
- `PolygonMap::remove_region` (`polygon_map.rs`): Remove the region named `name`; clears highlight if that region was highlighted; returns `true` when found.
- `PolygonMap::set_region_color` (`polygon_map.rs`): Set the fill color of region `name`; returns `true` when found.
- `PolygonMap::get_region_color` (`polygon_map.rs`): Return the fill color of region `name`, or `None` when not found.
- `PolygonMap::set_region_label` (`polygon_map.rs`): Set the label text and font size for region `name`; returns `true` when found.
- `PolygonMap::get_region_at` (`polygon_map.rs`): Return the name of the topmost region that contains `(x, y)`, or `None` when no region matches.
- `PolygonMap::get_region_names` (`polygon_map.rs`): Return the names of all registered regions.
- `PolygonMap::get_region_vertices` (`polygon_map.rs`): Return the vertex slice for region `name`, or `None` when not found.
- `PolygonMap::get_region_center` (`polygon_map.rs`): Return the centroid `(cx, cy)` of region `name`, or `None` when empty or missing.
- `PolygonMap::get_bounding_box` (`polygon_map.rs`): Return the bounding box `(min_x, min_y, width, height)` of all regions, or `None` when empty.
- `PolygonMap::set_outline_color` (`polygon_map.rs`): Set the global outline stroke color.
- `PolygonMap::set_outline_width` (`polygon_map.rs`): Set the global outline stroke width in pixels.
- `PolygonMap::set_highlight_color` (`polygon_map.rs`): Set the fill color used for the highlighted region.
- `PolygonMap::highlight` (`polygon_map.rs`): Mark region `name` as highlighted.
- `PolygonMap::clear_highlight` (`polygon_map.rs`): Clear the current highlight.
- `PolygonMap::clear` (`polygon_map.rs`): Remove all regions and clear the highlight.
- `TileMap::generate_render_commands` (`render.rs`): Generate camera-culled `RenderCommand` primitives for all visible layers; returns an empty vec when the map has no layers or zero tile size.
- `Facing::parse` (`tile_walker.rs`): Parse a direction string (`"north"`, `"n"`, etc.); returns `None` on unknown input.
- `Facing::to_str` (`tile_walker.rs`): Return the lowercase canonical name for this direction.
- `Facing::angle` (`tile_walker.rs`): Return the heading angle in radians: East=0, South=π/2, West=π, North=3π/2.
- `Facing::dx` (`tile_walker.rs`): Return the X grid delta for one step in this direction: East=+1, West=-1, N/S=0.
- `Facing::dy` (`tile_walker.rs`): Return the Y grid delta for one step in this direction: South=+1, North=-1, E/W=0.
- `TileWalker::new` (`tile_walker.rs`): Create a `TileWalker` at `(x, y)` facing `facing`; previous state initialised to the same values.
- `TileWalker::x` (`tile_walker.rs`): Return current grid X.
- `TileWalker::y` (`tile_walker.rs`): Return current grid Y.
- `TileWalker::facing` (`tile_walker.rs`): Return current facing direction.
- `TileWalker::set_position` (`tile_walker.rs`): Teleport to `(x, y)` without updating the previous-position snapshot.
- `TileWalker::set_facing` (`tile_walker.rs`): Set facing without updating the previous-facing snapshot.
- `TileWalker::can_move_forward` (`tile_walker.rs`): Return `true` when the tile one step forward is passable.
- `TileWalker::can_move_backward` (`tile_walker.rs`): Return `true` when the tile one step backward is passable.
- `TileWalker::can_strafe_left` (`tile_walker.rs`): Return `true` when the tile one step to the left is passable.
- `TileWalker::can_strafe_right` (`tile_walker.rs`): Return `true` when the tile one step to the right is passable.
- `TileWalker::move_forward` (`tile_walker.rs`): Move one step forward; returns `true` when movement succeeded.
- `TileWalker::move_backward` (`tile_walker.rs`): Move one step backward; returns `true` when movement succeeded.
- `TileWalker::strafe_left` (`tile_walker.rs`): Strafe one step to the left; returns `true` when movement succeeded.
- `TileWalker::strafe_right` (`tile_walker.rs`): Strafe one step to the right; returns `true` when movement succeeded.
- `TileWalker::turn_left` (`tile_walker.rs`): Rotate facing 90° counter-clockwise.
- `TileWalker::turn_right` (`tile_walker.rs`): Rotate facing 90° clockwise.
- `TileWalker::turn_around` (`tile_walker.rs`): Rotate facing 180°.
- `TileWalker::begin_move` (`tile_walker.rs`): Snapshot current position and facing into `prev_*` for interpolation; call before each discrete move.
- `TileWalker::get_interpolated_position` (`tile_walker.rs`): Linearly interpolate between `prev` and current position at blend factor `t` clamped to `[0, 1]`.
- `TileWalker::get_interpolated_angle` (`tile_walker.rs`): Interpolate heading angle between previous and current facing at `t`, handling wrap-around correctly.
- `TileWalker::get_relative_facing` (`tile_walker.rs`): Return `"front"`, `"back"`, `"left"`, or `"right"` describing where `(tx, ty)` is relative to the walker.
- `TileMap::new` (`tilemap.rs`): Create an empty `TileMap` with the given tile dimensions and chunk size.
- `TileMap::add_tileset` (`tilemap.rs`): Append a tileset and take ownership; called during map load or runtime attachment.
- `TileMap::get_tileset` (`tilemap.rs`): Return the tileset at `index`, or `None` when out of range.
- `TileMap::get_tileset_count` (`tilemap.rs`): Return the number of attached tilesets.
- `TileMap::add_layer` (`tilemap.rs`): Add a new empty layer of `width × height` tiles; return its layer index.
- `TileMap::get_layer_count` (`tilemap.rs`): Return the total number of layers.
- `TileMap::get_layer_name` (`tilemap.rs`): Return the name of layer `idx`, or `None` when out of range.
- `TileMap::set_layer_visible` (`tilemap.rs`): Set the visibility flag on layer `idx`; no-op when out of range.
- `TileMap::get_layer_visible` (`tilemap.rs`): Return `true` when layer `idx` is visible; returns `false` when out of range.
- `TileMap::set_layer_color` (`tilemap.rs`): Set the tint RGBA of layer `idx`; no-op when out of range.
- `TileMap::get_layer_color` (`tilemap.rs`): Return the tint `[r, g, b, a]` of layer `idx`; returns `[0; 4]` when out of range.
- `TileMap::set_layer_offset` (`tilemap.rs`): Set the world-space draw offset `(ox, oy)` of layer `idx`; no-op when out of range.
- `TileMap::get_layer_offset` (`tilemap.rs`): Return the draw offset of layer `idx`; returns `Vec2::ZERO` when out of range.
- `TileMap::set_layer_parallax` (`tilemap.rs`): Set the parallax factor `(px, py)` of layer `idx`; no-op when out of range.
- `TileMap::get_layer_parallax` (`tilemap.rs`): Return the parallax factor of layer `idx`; returns `(1, 1)` when out of range.
- `TileMap::get_layer_dimensions` (`tilemap.rs`): Return the `(width, height)` tile dimensions of layer `idx`, or `None` when out of range.
- `TileMap::set_tile` (`tilemap.rs`): Write GID `gid` at `(x, y)` in layer `layer`; updates the type-index cache; no-op when out of bounds.
- `TileMap::get_tile` (`tilemap.rs`): Return the GID at `(x, y)` in layer `layer`; returns `0` when out of bounds.
- `TileMap::set_tile_tint` (`tilemap.rs`): Set a per-tile RGBA tint override at `(x, y)` in `layer`; no-op when out of bounds.
- `TileMap::clear_tile` (`tilemap.rs`): Set the tile at `(x, y)` in `layer` to GID `0`; updates the type-index cache.
- `TileMap::fill` (`tilemap.rs`): Fill all tiles in `layer` with `gid`; rebuilds the type-index cache for that layer.
- `TileMap::tile_type_index` (`tilemap.rs`): Return a copy of the GID-to-positions index for `layer`; empty map when out of range.
- `TileMap::find_tiles_by_gid` (`tilemap.rs`): Return all `(x, y)` positions for tiles matching `gid` in `layer`; empty vec when not found.
- `TileMap::set_viewport` (`tilemap.rs`): Set the active camera viewport rect; enables culled render-command generation.
- `TileMap::get_viewport` (`tilemap.rs`): Return the viewport as `(x, y, w, h)`, or `None` when not set.
- `TileMap::update` (`tilemap.rs`): Advance all GID animation timers by `dt` seconds; updates frame indices for each animated tileset.
- `TileMap::world_to_tile` (`tilemap.rs`): Convert world position `(wx, wy)` to tile grid coordinates; clamps negative values to `0`.
- `TileMap::tile_to_world` (`tilemap.rs`): Convert tile grid coordinates `(tx, ty)` to world-space top-left pixel position.
- `TileMap::get_tile_width` (`tilemap.rs`): Return tile width in pixels.
- `TileMap::get_tile_height` (`tilemap.rs`): Return tile height in pixels.
- `TileMap::get_tile_dimensions` (`tilemap.rs`): Return tile dimensions as `(width, height)` in pixels.
- `TileMap::get_chunk_size` (`tilemap.rs`): Return the streaming chunk size.
- `TileMap::get_orientation` (`tilemap.rs`): Return the map orientation.
- `TileMap::set_orientation` (`tilemap.rs`): Set the map orientation.
- `TileMap::is_solid` (`tilemap.rs`): Return `true` when the tile at `(x, y)` in `layer` is marked solid in its tileset.
- `TileMap::rect_overlaps_solid` (`tilemap.rs`): Return `true` when any tile overlapped by `rect` in `layer` is solid.
- `TileMap::sweep_rect` (`tilemap.rs`): Continuous AABB sweep through solid tiles in `layer` along `(dx, dy)`; returns the earliest hit or `None`.
- `TileMap::apply_autotile` (`tilemap.rs`): Apply 4-neighbour autotile GID substitution to all non-empty tiles in `layer` matching `type_name`.
- `TileMap::apply_autotile_at` (`tilemap.rs`): Apply 4-neighbour autotile substitution to the 3×3 neighbourhood around `(x, y)` only.
- `TileMap::apply_autotile_8` (`tilemap.rs`): Apply 8-neighbour autotile GID substitution to all non-empty tiles in `layer` matching `type_name`.
- `TileMap::apply_autotile_8_at` (`tilemap.rs`): Apply 8-neighbour autotile substitution to the 3×3 neighbourhood around `(x, y)` only.
- `TileMap::draw_to_image` (`tilemap.rs`): Render all layers to an `ImageData` using the debug color palette; `tile_size` is the render pixel size per tile.
- `TileMap::build_render_commands` (`tilemap.rs`): Build a flat `RenderCommand` list for all visible layers using the debug color palette and `offset`.
- `TileMap::draw_with_highlight_to_image` (`tilemap.rs`): Render world-space highlight points and a grid overlay into an `ImageData` of `img_width × img_height`.
- `TileMap::draw_layers_to_image` (`tilemap.rs`): Render all layers side-by-side with colour-coded GIDs into an `ImageData` of `width × height` pixels.
- `TileMap::to_nav_grid` (`tilemap.rs`): Convert a layer to a boolean walkability grid; `walkable_gids` are treated as passable, GID `0` is always passable.
- `TileSet::new` (`tileset.rs`): Create a `TileSet` with the given layout parameters and empty solid, animation, and autotile tables.
- `TileSet::get_first_gid` (`tileset.rs`): Return the first global GID owned by this tileset.
- `TileSet::get_tile_count` (`tileset.rs`): Return the total tile count.
- `TileSet::get_columns` (`tileset.rs`): Return the number of tile columns in the source image.
- `TileSet::get_tile_width` (`tileset.rs`): Return tile width in pixels.
- `TileSet::get_tile_height` (`tileset.rs`): Return tile height in pixels.
- `TileSet::get_tile_dimensions` (`tileset.rs`): Return tile dimensions as `(width, height)` in pixels.
- `TileSet::get_spacing` (`tileset.rs`): Return pixel spacing between tiles in the source image.
- `TileSet::get_margin` (`tileset.rs`): Return pixel margin around the source image edge.
- `TileSet::get_quad` (`tileset.rs`): Return the source-image `Rect` (in pixels) for `local_tile_id`.
- `TileSet::set_animation` (`tileset.rs`): Register or replace the animation frame sequence for `local_tile_id`.
- `TileSet::get_animation` (`tileset.rs`): Return the animation frames for `local_tile_id`, or `None` when not animated.
- `TileSet::set_solid` (`tileset.rs`): Set or clear the solid flag for `local_tile_id`; grows the solids vec as needed.
- `TileSet::is_solid` (`tileset.rs`): Return `true` when `local_tile_id` is marked solid; returns `false` for IDs beyond the solids vec.
- `TileSet::set_auto_tile_rule` (`tileset.rs`): Register a 4-bit autotile rule mapping `(type_name, bitmask)` to `local_tile_id`.
- `TileSet::get_auto_tile_id` (`tileset.rs`): Look up the 4-bit autotile local ID for `(type_name, bitmask)`, or `None` when no rule matches.
- `TileSet::set_auto_tile_rule_8` (`tileset.rs`): Register an 8-bit autotile rule mapping `(type_name, bitmask)` to `local_tile_id`.
- `TileSet::get_auto_tile_id_8` (`tileset.rs`): Look up the 8-bit autotile local ID for `(type_name, bitmask)`, or `None` when no rule matches.
- `TmxMap::tile_layers` (`tmx.rs`): Iterate over all tile layers in declaration order.
- `TmxMap::object_layers` (`tmx.rs`): Iterate over all object layers in declaration order.
- `load_tmx` (`tmx.rs`): Parses a TMX file given its XML content as a string.

## Lua API Reference

- Binding path(s): `src/lua_api/tilemap_api.rs`
- Namespace: `lurek.tilemap`

### Module Functions
- `lurek.tilemap.newTileSet`: Creates a new tileset from atlas parameters.
- `lurek.tilemap.newTileMap`: Creates a new empty tilemap with the given tile dimensions.
- `lurek.tilemap.newAutoTileSheet`: Creates an auto-tile sheet with a given tile size and layout.
- `lurek.tilemap.newChunkMap`: Creates a new infinite chunk-based tile map.
- `lurek.tilemap.newIsoMap`: Creates a new isometric map with the given dimensions and tile geometry.
- `lurek.tilemap.newMapBlock`: Creates a new procedural map block with the given dimensions.
- `lurek.tilemap.newMapGroup`: Creates a new map group to hold blocks and generation scripts.
- `lurek.tilemap.toScreenIso`: Converts tile coordinates to screen-space position for isometric projection.
- `lurek.tilemap.fromScreenIso`: Converts screen-space coordinates back to tile coordinates for isometric projection.
- `lurek.tilemap.toScreenHex`: Converts axial hex coordinates to screen-space pixel position.
- `lurek.tilemap.fromScreenHex`: Converts screen-space pixel coordinates to axial hex coordinates.
- `lurek.tilemap.hexNeighbors`: Returns the six neighboring hex cells of a given axial coordinate.
- `lurek.tilemap.hexDistance`: Computes the hex grid distance between two axial coordinates.
- `lurek.tilemap.hexRound`: Rounds fractional axial hex coordinates to the nearest integer hex cell.
- `lurek.tilemap.hexLine`: Returns all hex cells along a line between two axial coordinates.
- `lurek.tilemap.hexRing`: Returns all hex cells forming a ring at a given radius around a center.
- `lurek.tilemap.hexSpiral`: Returns all hex cells in a spiral pattern out to a given radius.
- `lurek.tilemap.hexArea`: Returns all hex cells within a filled area of a given radius.
- `lurek.tilemap.hexRotate`: Rotates a hex cell around a center point by a number of 60-degree steps.
- `lurek.tilemap.hexReflect`: Reflects a hex cell across an axis through a center point.
- `lurek.tilemap.isoRotate`: Rotates an isometric direction index by a number of 90-degree steps.
- `lurek.tilemap.isoDirectionName`: Returns a human-readable name for an isometric direction index.
- `lurek.tilemap.isoDirectionFromAngle`: Converts an angle in degrees to the nearest isometric direction index.
- `lurek.tilemap.newMapScript`: Creates a new empty map-generation script.
- `lurek.tilemap.newMapGen`: Creates a procedural map generator from a group and either a size preset or explicit dimensions.
- `lurek.tilemap.loadTMX`: Parses a TMX (Tiled XML) string and returns a table describing the map structure.
- `lurek.tilemap.fromLDtk`: Loads a tilemap from an LDtk JSON string, optionally targeting a specific level.
- `lurek.tilemap.newLargeMapRenderer`: Creates a chunk-based large-map renderer for efficient rendering of very large maps.

### `LAutoTileSheet` Methods
- `LAutoTileSheet:getLayout`: Returns the auto-tile layout type as a string.
- `LAutoTileSheet:getTileCount`: Returns the total number of tiles in this auto-tile sheet.
- `LAutoTileSheet:getTileWidth`: Returns the width of each tile in the auto-tile sheet, in pixels.
- `LAutoTileSheet:getTileHeight`: Returns the height of each tile in the auto-tile sheet, in pixels.
- `LAutoTileSheet:applyToTileSet`: Writes the auto-tile bitmask-to-tile rules from this sheet into a tileset.
- `LAutoTileSheet:getBitmaskForTile`: Returns the bitmask associated with a tile in this auto-tile sheet.
- `LAutoTileSheet:getTileForBitmask`: Looks up which tile corresponds to a given bitmask value.
- `LAutoTileSheet:getQuad`: Returns the source rectangle for a tile in the auto-tile sheet.
- `LAutoTileSheet:type`: Returns the type name of this userdata.
- `LAutoTileSheet:typeOf`: Checks whether this object matches the given type name.

### `LChunkMap` Methods
- `LChunkMap:getTile`: Returns the tile GID at the given world-tile coordinate.
- `LChunkMap:setTile`: Sets the tile GID at the given world-tile coordinate.
- `LChunkMap:clearTile`: Removes the tile at the given world-tile coordinate.
- `LChunkMap:fillRect`: Fills a rectangular region of tiles with a given GID.
- `LChunkMap:loadChunk`: Loads a chunk into memory at the given chunk coordinates.
- `LChunkMap:unloadChunk`: Unloads a chunk from memory at the given chunk coordinates.
- `LChunkMap:getChunkSize`: Returns the size of each chunk in tiles per side.
- `LChunkMap:getLoadedChunks`: Returns a list of all currently loaded chunk coordinates.
- `LChunkMap:getChunksInView`: Returns chunk coordinates that overlap a viewport region, given tile dimensions.
- `LChunkMap:chunkTileRange`: Returns the tile-coordinate range covered by a specific chunk.
- `LChunkMap:type`: Returns the type name of this userdata.
- `LChunkMap:typeOf`: Checks whether this object matches the given type name.

### `LIsoMap` Methods
- `LIsoMap:addLevel`: Adds a new vertical level to the isometric map and returns its index.
- `LIsoMap:getLevelCount`: Returns the number of vertical levels in the isometric map.
- `LIsoMap:setLevelVisible`: Sets whether a vertical level is drawn during rendering.
- `LIsoMap:isLevelVisible`: Returns whether a vertical level is currently visible.
- `LIsoMap:setTilePart`: Sets the GID for a specific part of a tile at a given position and level.
- `LIsoMap:getTilePart`: Returns the GID for a specific part of a tile at a given position and level.
- `LIsoMap:fillLevel`: Fills all tiles on a level for a given part with a single GID.
- `LIsoMap:setOrigin`: Sets the screen-space origin (top-left anchor) for isometric rendering.
- `LIsoMap:getWidth`: Returns the map width in tiles.
- `LIsoMap:getHeight`: Returns the map height in tiles.
- `LIsoMap:getTileWidth`: Returns the width of an isometric tile in pixels.
- `LIsoMap:getTileHeight`: Returns the height of an isometric tile in pixels.
- `LIsoMap:getLevelHeight`: Returns the vertical pixel offset between levels.
- `LIsoMap:tileToScreen`: Converts tile-grid coordinates to screen-space pixel position.
- `LIsoMap:screenToTile`: Converts screen-space pixel coordinates to tile-grid coordinates (ignoring Z).
- `LIsoMap:getPartCount`: Returns the number of tile parts per cell.
- `LIsoMap:getPartOrder`: Returns the rendering order of tile parts as an array of part indices.
- `LIsoMap:setPartOrder`: Overrides the rendering order of tile parts.
- `LIsoMap:type`: Returns the type name of this userdata.
- `LIsoMap:typeOf`: Checks whether this object matches the given type name.

### `LLargeMapRenderer` Methods
- `LLargeMapRenderer:setMapData`: Replaces all tile data with a flat array of GIDs for the given dimensions.
- `LLargeMapRenderer:setTile`: Sets a single tile GID at a given position.
- `LLargeMapRenderer:getTile`: Returns the tile GID at a given position.
- `LLargeMapRenderer:getMapSize`: Returns the map dimensions in tiles.
- `LLargeMapRenderer:setChunkSize`: Sets the chunk size used for rendering subdivision.
- `LLargeMapRenderer:getChunkSize`: Returns the current chunk size.
- `LLargeMapRenderer:invalidateChunk`: Marks a specific chunk as dirty so it will be rebuilt on the next render.
- `LLargeMapRenderer:invalidateAll`: Marks all chunks as dirty, forcing a full rebuild on the next render.
- `LLargeMapRenderer:getVisibleChunks`: Returns the number of chunks currently visible in the viewport.
- `LLargeMapRenderer:getTotalChunks`: Returns the total number of chunks in the map.
- `LLargeMapRenderer:setCamera`: Sets the camera position and zoom level for determining visible chunks.
- `LLargeMapRenderer:setViewport`: Sets the viewport dimensions for visibility calculations.
- `LLargeMapRenderer:setLodEnabled`: Enables or disables level-of-detail rendering for distant chunks.
- `LLargeMapRenderer:isLodEnabled`: Returns whether LOD rendering is currently enabled.
- `LLargeMapRenderer:setLodThresholds`: Sets the zoom thresholds at which LOD levels change.
- `LLargeMapRenderer:setTilesetColumns`: Sets the column count of the associated tileset atlas for UV calculation.
- `LLargeMapRenderer:getTilesetColumns`: Returns the tileset column count used for UV calculation.
- `LLargeMapRenderer:type`: Returns the type name of this userdata.
- `LLargeMapRenderer:typeOf`: Checks whether this object matches the given type name.

### `LMapBlock` Methods
- `LMapBlock:setTile`: Sets a tile GID at a position within the block.
- `LMapBlock:getTile`: Returns the tile GID at a position within the block.
- `LMapBlock:setSide`: Sets the side ID for an edge segment, used for edge matching in map generation.
- `LMapBlock:getSide`: Returns the side ID for an edge segment.
- `LMapBlock:getWidth`: Returns the block width in tiles.
- `LMapBlock:getHeight`: Returns the block height in tiles.
- `LMapBlock:getDimensions`: Returns both width and height of the block in tiles.
- `LMapBlock:getLayerCount`: Returns the number of tile layers in this block.
- `LMapBlock:getSegmentSize`: Returns the segment size used for edge matching.
- `LMapBlock:getWidthInSegments`: Returns the block width measured in segments.
- `LMapBlock:getHeightInSegments`: Returns the block height measured in segments.
- `LMapBlock:setName`: Sets the block's name for identification during map generation.
- `LMapBlock:getName`: Returns the block's name.
- `LMapBlock:setWeight`: Sets the selection weight for this block during random placement.
- `LMapBlock:getWeight`: Returns the current selection weight.
- `LMapBlock:type`: Returns the type name of this userdata.
- `LMapBlock:typeOf`: Checks whether this object matches the given type name.

### `LMapGen` Methods
- `LMapGen:generate`: Runs the map generator, optionally using a specific script, seed, and layer name, returning a new tilemap.
- `LMapGen:type`: Returns the type name of this userdata.
- `LMapGen:typeOf`: Checks whether this object matches the given type name.

### `LMapGroup` Methods
- `LMapGroup:addBlock`: Adds a map block to this group for use in generation.
- `LMapGroup:getBlockCount`: Returns how many blocks are in this group.
- `LMapGroup:removeBlock`: Removes a block from the group by index.
- `LMapGroup:getName`: Returns the group name.
- `LMapGroup:addScript`: Attaches a map-generation script to this group.
- `LMapGroup:getScriptCount`: Returns how many scripts are attached to this group.
- `LMapGroup:type`: Returns the type name of this userdata.
- `LMapGroup:typeOf`: Checks whether this object matches the given type name.

### `LMapScript` Methods
- `LMapScript:getStepCount`: Returns the number of generation steps in this script.
- `LMapScript:addStep`: Appends a generation step. The step table must have a `type` field and optional parameters.
- `LMapScript:type`: Returns the type name of this userdata.
- `LMapScript:typeOf`: Checks whether this object matches the given type name.

### `LTileMap` Methods
- `LTileMap:addTileSet`: Attaches a tileset to this map for tile rendering.
- `LTileMap:getTileSetCount`: Returns how many tilesets are attached to this map.
- `LTileMap:getTileSet`: Returns the tileset at the given index.
- `LTileMap:addLayer`: Creates a new tile layer with the given name and dimensions.
- `LTileMap:getLayerCount`: Returns the total number of layers in this map.
- `LTileMap:getLayerName`: Returns the name of a layer by index.
- `LTileMap:setLayerVisible`: Sets whether a layer is drawn during rendering.
- `LTileMap:getLayerVisible`: Returns whether a layer is currently visible.
- `LTileMap:setLayerColor`: Sets the tint color for an entire layer.
- `LTileMap:getLayerColor`: Returns the tint color of a layer as four RGBA components.
- `LTileMap:setLayerOffset`: Sets the pixel offset for a layer, shifting all tiles during rendering.
- `LTileMap:getLayerOffset`: Returns the pixel offset of a layer.
- `LTileMap:setLayerParallax`: Sets the parallax scroll factor for a layer. Values less than 1 scroll slower than the camera.
- `LTileMap:getLayerParallax`: Returns the parallax scroll factor of a layer.
- `LTileMap:setTile`: Sets the tile GID at a specific grid position on a layer.
- `LTileMap:getTile`: Returns the tile GID at a specific grid position on a layer.
- `LTileMap:clearTile`: Removes the tile at a specific grid position, setting it to empty (GID 0).
- `LTileMap:fill`: Fills every cell of a layer with the given GID.
- `LTileMap:tileTypeIndex`: Builds an index mapping each GID present on a layer to an array of `{x, y}` positions.
- `LTileMap:findTilesByGid`: Returns all positions on a layer that contain a specific GID.
- `LTileMap:setViewport`: Sets the visible area of the map for culling during rendering.
- `LTileMap:getViewport`: Returns the current viewport rectangle, or nils if none is set.
- `LTileMap:update`: Advances tile animations by the given delta time.
- `LTileMap:worldToTile`: Converts world-space pixel coordinates to tile-grid coordinates.
- `LTileMap:tileToWorld`: Converts tile-grid coordinates to world-space pixel coordinates (top-left corner of the tile).
- `LTileMap:getTileWidth`: Returns the width of a single tile in pixels for this map.
- `LTileMap:getTileHeight`: Returns the height of a single tile in pixels for this map.
- `LTileMap:getTileDimensions`: Returns both tile width and height in pixels.
- `LTileMap:getChunkSize`: Returns the chunk size used for internal tile storage.
- `LTileMap:isSolid`: Checks whether the tile at a given position on a layer is solid.
- `LTileMap:applyAutoTile`: Runs 4-bit auto-tiling on an entire layer, replacing tiles according to registered rules.
- `LTileMap:applyAutoTileAt`: Runs 4-bit auto-tiling at a single tile position and updates it and its neighbors.
- `LTileMap:applyAutoTile8`: Runs 8-bit auto-tiling on an entire layer, considering diagonal neighbors.
- `LTileMap:applyAutoTile8At`: Runs 8-bit auto-tiling at a single tile position and updates it and its neighbors.
- `LTileMap:rectOverlapsSolid`: Tests whether a world-space rectangle overlaps any solid tile on a layer.
- `LTileMap:sweepRect`: Performs a swept AABB collision test against solid tiles on a layer, returning the contact point and normal.
- `LTileMap:getOrientation`: Returns the current map orientation as a string.
- `LTileMap:setOrientation`: Sets the map orientation, affecting coordinate transforms and rendering.
- `LTileMap:setTileTint`: Overrides the color tint for a single tile at a given position.
- `LTileMap:render`: Submits render commands for all visible tiles, optionally offset by a scroll position.
- `LTileMap:drawToImage`: Rasterizes the map into an image using the given tile size, returning an image handle.
- `LTileMap:toNavGrid`: Converts a layer into a 2D boolean grid for pathfinding. Tiles with GIDs in the given list are marked walkable.
- `LTileMap:onTileEnter`: Registers a callback invoked when an entity enters a tile with the given GID.
- `LTileMap:checkEntities`: Checks a list of entities against registered tile-enter callbacks on a layer.
- `LTileMap:onTileStep`: Registers a callback invoked each frame an entity remains on a tile with the given GID.
- `LTileMap:onTileExit`: Registers a callback invoked when an entity leaves a tile with the given GID.
- `LTileMap:fireTileStep`: Manually fires the tile-step callback for a specific GID and entity at a tile position.
- `LTileMap:fireTileExit`: Manually fires the tile-exit callback for a specific GID and entity at a tile position.
- `LTileMap:type`: Returns the type name of this userdata.
- `LTileMap:typeOf`: Checks whether this object matches the given type name.

### `LTileSet` Methods
- `LTileSet:getFirstGid`: Returns the first global tile ID (GID) of this tileset.
- `LTileSet:getTileCount`: Returns the total number of tiles defined in this tileset.
- `LTileSet:getColumns`: Returns the number of columns in the tileset atlas image.
- `LTileSet:getTileWidth`: Returns the width of a single tile in pixels.
- `LTileSet:getTileHeight`: Returns the height of a single tile in pixels.
- `LTileSet:getTileDimensions`: Returns both tile width and height in pixels.
- `LTileSet:getSpacing`: Returns the spacing between tiles in the atlas image, in pixels.
- `LTileSet:getMargin`: Returns the margin around the edge of the atlas image, in pixels.
- `LTileSet:getQuad`: Returns the source rectangle (UV quad) for a tile in the atlas.
- `LTileSet:setAnimation`: Assigns an animation sequence to a tile. Each frame references another tile ID and a duration.
- `LTileSet:getAnimation`: Returns the animation frames for a tile, or nil if none are set.
- `LTileSet:setSolid`: Marks a tile as solid or non-solid for collision queries.
- `LTileSet:isSolid`: Checks whether a tile is marked as solid.
- `LTileSet:setAutoTileRule`: Registers a 4-bit auto-tile rule mapping a bitmask to a tile ID for a named tile type.
- `LTileSet:getAutoTileId`: Looks up the tile ID for a 4-bit auto-tile bitmask and type name.
- `LTileSet:setAutoTileRule8`: Registers an 8-bit auto-tile rule mapping a bitmask to a tile ID for a named tile type.
- `LTileSet:getAutoTileId8`: Looks up the tile ID for an 8-bit auto-tile bitmask and type name.
- `LTileSet:type`: Returns the type name of this userdata.
- `LTileSet:typeOf`: Checks whether this object matches the given type name.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/tilemap/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.

### 2026-05-12 Update

- Added maintained per-layer tile-type index cache in `TileMap` (`tile_type_index_cache`) updated by `add_layer`, `set_tile`, `clear_tile`, and `fill`.
- Added `TileMap::tile_type_index(layer)` and `TileMap::find_tiles_by_gid(layer, gid)`.
- Exposed Lua methods: `LTileMap:tileTypeIndex(layer)` and `LTileMap:findTilesByGid(layer, gid)`.
