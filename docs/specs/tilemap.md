# tilemap

## General Info

- Module group: `Feature Systems`
- Source path: `src/tilemap/`
- Lua API path(s): `src/lua_api/tilemap_api.rs`
- Primary Lua namespace: `lurek.tilemap`
- Rust test path(s): tests/rust/unit/tilemap_tests.rs
- Lua test path(s): tests/lua/unit/test_tilemap.lua, tests/lua/stress/test_tilemap_stress.lua, tests/lua/integration/test_tilemap_physics.lua, tests/lua/integration/test_tilemap_pathfinding.lua, tests/lua/integration/test_tilemap_camera.lua, tests/lua/integration/test_savegame_tilemap.lua, tests/lua/integration/test_procgen_tilemap.lua, tests/lua/golden/test_tilemap_golden.lua, tests/lua/evidence/test_evidence_tilemap.lua

## Summary

The `tilemap` module is Lurek2D's tile-map authoring and rendering subsystem. It handles everything from simple single-layer grids to complex multi-layer maps with animated tiles, external format imports, automatic tile selection, isometric sorting, and sparse infinite map support.

`TileMap` is the top-level container: a multi-layer grid where each `TileLayer` holds a flat row-major array of tile IDs, a name, Z-order, opacity, visibility flag, and per-layer scroll offsets. Tile CRUD: `get_tile(layer, x, y)`, `set_tile(layer, x, y, id)`, `fill_rect(layer, rect, id)`. `sweep_rect(rect)` returns all non-empty tile IDs within a world AABB for broad-phase collision pre-filtering before physics.

`TileSet` stores the source `TextureKey`, tile dimensions (width/height in pixels), tile count, and per-tile properties: `passable` flag, optional animation frames list, custom property `HashMap`, and optional collision shape override. `TileProperties::collision_shape` selects the shape used for physics collider generation.

External format parsers: `load_tmx(path)` parses Tiled `.tmx` XML exports with object layers, tile properties, image layers, and tileset references; `load_ldtk(path)` parses LDtk JSON exports. Both populate native `TileMap` + `TileSet` structures.

`AutoTileSheet` implements bitmask-based automatic tile selection (RPGMaker or 48-tile atlas layouts) where the displayed tile is chosen based on which of the eight cardinal and diagonal neighbors are the same terrain type. `IsoMap` adds painter's-algorithm isometric depth sorting. `ChunkMap` provides a `HashMap<(i32,i32), Vec<u8>>` sparse infinite map with async chunk loading callbacks.

The new `iso.rs` source file introduces `IsoRenderer`, a dedicated isometric rendering type that handles depth-sorted painter's-algorithm draw calls for isometric tile maps. Lua scripts construct isometric renderers via `lurek.tilemap.newIsoRenderer()` and drive rendering through its method set, replacing manual draw-call sorting for isometric scenes. This complements the existing `IsoMap` data container and `coords.rs` coordinate helpers with a complete rendering pipeline that integrates with the same `RenderCommand` queue as the rest of the engine.

**Scope boundary**: Feature Systems tier. Depends on `render`, `math`, `runtime`, `image`. Lua bridge in `src/lua_api/tilemap_api.rs`.

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

- `AutoTileSheet::new` (`autotile_sheet.rs`): Creates a new autotile sheet with the given tile dimensions and layout.
- `AutoTileSheet::get_layout` (`autotile_sheet.rs`): Returns the layout variant.
- `AutoTileSheet::get_tile_count` (`autotile_sheet.rs`): Returns the number of tiles in this sheet.
- `AutoTileSheet::get_tile_width` (`autotile_sheet.rs`): Returns the tile width in pixels.
- `AutoTileSheet::get_tile_height` (`autotile_sheet.rs`): Returns the tile height in pixels.
- `AutoTileSheet::apply_to_tileset` (`autotile_sheet.rs`): Applies autotile rules from this sheet to a [`TileSet`].
- `AutoTileSheet::get_bitmask_for_tile` (`autotile_sheet.rs`): Returns the bitmask value associated with a tile index, or 0 if out of bounds.
- `AutoTileSheet::get_tile_for_bitmask` (`autotile_sheet.rs`): Returns the tile index for a given bitmask, if one exists.
- `AutoTileSheet::get_quad` (`autotile_sheet.rs`): Returns the atlas region rectangle for the tile at the given index.
- `AutoTileSheet::get_grid_quad` (`autotile_sheet.rs`): Returns the atlas region for a tile stored in a **grid-layout** atlas.
- `AutoTileSheet::get_composite48_grid_quad` (`autotile_sheet.rs`): Returns the atlas region for a pre-composed 48-tile layout using the
- `AutoTileSheet::get_quarter_rects` (`autotile_sheet.rs`): Returns the four quarter-tile source [`Rect`]s for the given raw 8-bit neighbour bitmask.
- `AutoTileSheet::get_quarter_dst_rects` (`autotile_sheet.rs`): Returns the four **destination** sub-rects within a tile at world position `(x, y)`.
- `ChunkMap::new` (`chunk.rs`): Creates a new empty chunk map.
- `ChunkMap::get_chunk_size` (`chunk.rs`): Returns the chunk size (tiles per side).
- `ChunkMap::get_tile` (`chunk.rs`): Returns the GID at tile coordinate `(x, y)`.
- `ChunkMap::set_tile` (`chunk.rs`): Sets the GID at tile coordinate `(x, y)`.
- `ChunkMap::clear_tile` (`chunk.rs`): Clears the tile at `(x, y)` by setting its GID to 0.
- `ChunkMap::fill_rect` (`chunk.rs`): Fills the rectangular tile region `[x0, x1) × [y0, y1)` with `gid`.
- `ChunkMap::load_chunk` (`chunk.rs`): Pre-allocates the chunk at chunk coordinates `(cx, cy)`.
- `ChunkMap::unload_chunk` (`chunk.rs`): Removes the chunk at chunk coordinates `(cx, cy)` from memory.
- `ChunkMap::get_loaded_chunks` (`chunk.rs`): Returns a list of all currently loaded chunk coordinates.
- `ChunkMap::get_loaded_chunk_count` (`chunk.rs`): Returns the number of currently loaded chunks.
- `ChunkMap::is_chunk_loaded` (`chunk.rs`): Returns whether the chunk at `(cx, cy)` is currently loaded.
- `ChunkMap::tile_to_chunk` (`chunk.rs`): Converts tile `(x, y)` to chunk coordinates `(cx, cy)`.
- `ChunkMap::chunk_tile_range` (`chunk.rs`): Returns the inclusive tile coordinate range for chunk `(cx, cy)` as `(x0, y0, x1, y1)`.
- `ChunkMap::get_chunks_in_view` (`chunk.rs`): Returns chunk coordinates whose world-pixel footprint overlaps the given viewport.
- `ChunkMap::chunk_world_rect` (`chunk.rs`): Returns the world-pixel bounding rectangle of chunk `(cx, cy)`.
- `ChunkMap::iter_chunk` (`chunk.rs`): Provides read-only access to the raw GID slice for chunk `(cx, cy)`.
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
- `IsoTilePart::from_index` (`isomap.rs`): Converts a 0-based index to an [`IsoTilePart`].
- `IsoTilePart::index` (`isomap.rs`): Returns the 0-based index of this part.
- `IsoLevel::new` (`isomap.rs`): Creates a new level filled with empty tiles (all GIDs = 0).
- `IsoLevel::get_tile` (`isomap.rs`): Returns the [`IsoTile`] at `(x, y)`, or `None` if out of bounds.
- `IsoLevel::get_tile_mut` (`isomap.rs`): Returns mutable access to the [`IsoTile`] at `(x, y)`, or `None` if OOB.
- `IsoMap::new` (`isomap.rs`): Creates an [`IsoMap`] with no levels.
- `IsoMap::add_level` (`isomap.rs`): Appends a new empty Z-level and returns its 0-based index.
- `IsoMap::get_level_count` (`isomap.rs`): Returns the number of Z-levels currently in the map.
- `IsoMap::set_level_visible` (`isomap.rs`): Sets the visibility of level `z`.
- `IsoMap::get_level_visible` (`isomap.rs`): Returns the visibility of level `z`, or `true` if `z` is out of range.
- `IsoMap::set_tile_part` (`isomap.rs`): Writes `gid` into the `part` slot of tile `(x, y)` on level `z`.
- `IsoMap::get_tile_part` (`isomap.rs`): Reads the GID in the `part` slot of tile `(x, y)` on level `z`.
- `IsoMap::fill_level` (`isomap.rs`): Fills every cell in level `z` with `gid` for the given `part`.
- `IsoMap::set_origin` (`isomap.rs`): Sets the screen pixel origin — the position where tile `(0, 0)` at level `0` projects.
- `IsoMap::tile_to_screen` (`isomap.rs`): Projects isometric tile coordinates `(tx, ty, tz)` to screen pixels.
- `IsoMap::screen_to_tile` (`isomap.rs`): Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
- `IsoMap::draw_iter` (`isomap.rs`): Returns all draw items in painter's algorithm order for rendering up to
- `IsoMap::get_part_count` (`isomap.rs`): Returns the number of GID slots per tile.
- `IsoMap::get_part_order` (`isomap.rs`): Returns the current draw order as a slice of part slot indices.
- `IsoMap::set_part_order` (`isomap.rs`): Sets the draw order for tile parts.
- `LargeMapRenderer::new` (`large_map_renderer.rs`): Creates a new `LargeMapRenderer` with the given tile dimensions.
- `LargeMapRenderer::set_map_data` (`large_map_renderer.rs`): Sets the entire map tile data and rebuilds all chunks.
- `LargeMapRenderer::set_tile` (`large_map_renderer.rs`): Sets a single tile at `(x, y)` (0-based) and marks the enclosing chunk dirty.
- `LargeMapRenderer::get_tile` (`large_map_renderer.rs`): Returns the tile ID at `(x, y)` (0-based), or `None` if out of bounds.
- `LargeMapRenderer::get_map_size` (`large_map_renderer.rs`): Returns the map size as `(width, height)` in tiles.
- `LargeMapRenderer::set_chunk_size` (`large_map_renderer.rs`): Changes the chunk size (tiles per side) and rebuilds all chunks.
- `LargeMapRenderer::get_chunk_size` (`large_map_renderer.rs`): Returns the current chunk size (tiles per side).
- `LargeMapRenderer::invalidate_chunk` (`large_map_renderer.rs`): Marks a specific chunk as dirty (needs rebuild).
- `LargeMapRenderer::invalidate_all` (`large_map_renderer.rs`): Marks all chunks as dirty.
- `LargeMapRenderer::get_visible_chunks` (`large_map_renderer.rs`): Returns the number of chunks currently visible given the camera
- `LargeMapRenderer::get_total_chunks` (`large_map_renderer.rs`): Returns the total number of chunks.
- `LargeMapRenderer::chunks` (`large_map_renderer.rs`): Returns a reference to the chunk map for rendering.
- `LargeMapRenderer::set_camera` (`large_map_renderer.rs`): Sets the camera position and zoom.
- `LargeMapRenderer::set_viewport` (`large_map_renderer.rs`): Sets the viewport size in screen pixels.
- `LargeMapRenderer::set_lod_enabled` (`large_map_renderer.rs`): Enables or disables level-of-detail rendering.
- `LargeMapRenderer::is_lod_enabled` (`large_map_renderer.rs`): Returns whether LOD is enabled.
- `LargeMapRenderer::set_lod_thresholds` (`large_map_renderer.rs`): Sets the zoom thresholds at which LOD levels change.
- `LargeMapRenderer::set_tileset_columns` (`large_map_renderer.rs`): Sets the number of columns in the tileset image.
- `LargeMapRenderer::get_tileset_columns` (`large_map_renderer.rs`): Returns the number of tileset columns.
- `load_ldtk` (`ldtk.rs`): Parses an LDtk JSON export string and returns a [`TileMap`].
- `Edge::from_str` (`mapgen.rs`): Parses an edge from a lowercase string (`"north"`, `"east"`, `"south"`, `"west"`).
- `Edge::as_str` (`mapgen.rs`): Returns the lowercase string representation of this edge.
- `MapBlock::new` (`mapgen.rs`): Creates a new map block with the given dimensions.
- `MapBlock::set_tile` (`mapgen.rs`): Sets the GID of a tile at `(x, y)` on the given layer (0-based).
- `MapBlock::get_tile` (`mapgen.rs`): Returns the GID of the tile at `(x, y)` on the given layer.
- `MapBlock::set_side` (`mapgen.rs`): Sets the side connection ID for a segment on a given edge.
- `MapBlock::get_side` (`mapgen.rs`): Returns the side connection ID for a segment on a given edge, or 0 if not set.
- `MapBlock::get_width` (`mapgen.rs`): Returns the block width in tiles.
- `MapBlock::get_height` (`mapgen.rs`): Returns the block height in tiles.
- `MapBlock::get_dimensions` (`mapgen.rs`): Returns the block dimensions as `(width, height)` in tiles.
- `MapBlock::get_layer_count` (`mapgen.rs`): Returns the number of layers in this block.
- `MapBlock::get_segment_size` (`mapgen.rs`): Returns the segment size in tiles.
- `MapBlock::get_width_in_segments` (`mapgen.rs`): Returns the number of segments along the width.
- `MapBlock::get_height_in_segments` (`mapgen.rs`): Returns the number of segments along the height.
- `MapBlock::get_segment_count` (`mapgen.rs`): Returns the segment count for a given edge direction.
- `MapBlock::set_name` (`mapgen.rs`): Sets the human-readable name of this block.
- `MapBlock::get_name` (`mapgen.rs`): Returns the name of this block.
- `MapBlock::set_weight` (`mapgen.rs`): Sets the placement weight (default 1.0).
- `MapBlock::get_weight` (`mapgen.rs`): Returns the placement weight.
- `MapGroup::new` (`mapgen.rs`): Creates a new empty map group.
- `MapGroup::add_block` (`mapgen.rs`): Adds a block to this group.
- `MapGroup::get_block` (`mapgen.rs`): Returns a reference to a block by index.
- `MapGroup::get_block_mut` (`mapgen.rs`): Returns a mutable reference to a block by index.
- `MapGroup::get_block_count` (`mapgen.rs`): Returns the number of blocks in this group.
- `MapGroup::remove_block` (`mapgen.rs`): Removes a block by index if in bounds.
- `MapGroup::add_script` (`mapgen.rs`): Adds a script to this group.
- `MapGroup::get_script` (`mapgen.rs`): Returns a reference to a script by index.
- `MapGroup::get_script_count` (`mapgen.rs`): Returns the number of scripts in this group.
- `MapGroup::get_name` (`mapgen.rs`): Returns the name of this group.
- `MapGroup::set_name` (`mapgen.rs`): Sets the name of this group.
- `StepType::from_str` (`mapgen.rs`): Parses a step type from a string identifier.
- `StepType::as_str` (`mapgen.rs`): Returns the string identifier for this step type.
- `MapScript::new` (`mapgen.rs`): Creates a new empty map script.
- `MapScript::add_step` (`mapgen.rs`): Appends a step to this script.
- `MapScript::get_step` (`mapgen.rs`): Returns a reference to a step by index.
- `MapScript::get_step_count` (`mapgen.rs`): Returns the number of steps.
- `MapScript::remove_step` (`mapgen.rs`): Removes a step by index if in bounds.
- `MapScript::clear_steps` (`mapgen.rs`): Removes all steps.
- `MapScript::set_name` (`mapgen.rs`): Sets the name of this script.
- `MapScript::get_name` (`mapgen.rs`): Returns the name of this script.
- `MapSize::grid_dimensions` (`mapgen.rs`): Returns the `(columns, rows)` grid dimensions.
- `MapGen::new` (`mapgen.rs`): Creates a new map generator from a size preset and segment size.
- `MapGen::generate` (`mapgen.rs`): Generates a [`TileMap`] from a [`MapGroup`] using an optional script and seed.
- `MapGen::generate_world` (`mapgen.rs`): Generates a larger map by tiling multiple generation regions.
- `MapGen::get_grid_width` (`mapgen.rs`): Returns the grid width in segments.
- `MapGen::get_grid_height` (`mapgen.rs`): Returns the grid height in segments.
- `MapGen::get_grid_dimensions` (`mapgen.rs`): Returns the grid dimensions as `(width, height)` in segments.
- `MapGen::get_segment_size` (`mapgen.rs`): Returns the segment size in tiles.
- `MapGen::set_grid_dimensions` (`mapgen.rs`): Sets the grid dimensions (width and height in segments).
- `MapGen::set_tile_size` (`mapgen.rs`): Sets the tile pixel dimensions.
- `MapGen::get_tile_pixel_width` (`mapgen.rs`): Returns the tile pixel width.
- `MapGen::get_tile_pixel_height` (`mapgen.rs`): Returns the tile pixel height.
- `MapGen::get_placement_count` (`mapgen.rs`): Returns the number of placements made during the last generation.
- `MapGen::set_orientation` (`mapgen.rs`): Sets the map orientation.
- `MapGen::get_orientation` (`mapgen.rs`): Returns the current map orientation.
- `MapGen::add_zone` (`mapgen.rs`): Adds a named horizontal zone.
- `MapGen::get_zone_count` (`mapgen.rs`): Returns the number of zones.
- `MapGen::get_zone` (`mapgen.rs`): Returns a zone by index.
- `MapGen::clear_zones` (`mapgen.rs`): Removes all zones.
- `MapGen::set_layer_mode` (`mapgen.rs`): Sets the layer mode.
- `MapGen::get_layer_mode` (`mapgen.rs`): Returns the current layer mode.
- `PolygonMap::new` (`polygon_map.rs`): Create an empty polygon map with default styling.
- `PolygonMap::add_region` (`polygon_map.rs`): Add a named polygon region with the given flat vertex data and color.
- `PolygonMap::remove_region` (`polygon_map.rs`): Remove a region by name.
- `PolygonMap::set_region_color` (`polygon_map.rs`): Set the fill color of a region.
- `PolygonMap::get_region_color` (`polygon_map.rs`): Get the fill color of a region.
- `PolygonMap::set_region_label` (`polygon_map.rs`): Set the label text and font size for a region.
- `PolygonMap::get_region_at` (`polygon_map.rs`): Return the name of the first region containing the point `(x, y)`.
- `PolygonMap::get_region_names` (`polygon_map.rs`): Names of all regions.
- `PolygonMap::get_region_vertices` (`polygon_map.rs`): Flat vertex slice for a region.
- `PolygonMap::get_region_center` (`polygon_map.rs`): Centroid of a region (average of its vertices).
- `PolygonMap::get_bounding_box` (`polygon_map.rs`): Axis-aligned bounding box of all regions: `(min_x, min_y, width, height)`.
- `PolygonMap::set_outline_color` (`polygon_map.rs`): Set the outline color for all regions.
- `PolygonMap::set_outline_width` (`polygon_map.rs`): Set the outline stroke width.
- `PolygonMap::set_highlight_color` (`polygon_map.rs`): Set the highlight color.
- `PolygonMap::highlight` (`polygon_map.rs`): Highlight a region by name.
- `PolygonMap::clear_highlight` (`polygon_map.rs`): Clear any active highlight.
- `PolygonMap::clear` (`polygon_map.rs`): Remove all regions and clear the highlight.
- `TileMap::generate_render_commands` (`render.rs`): Generate render commands for the tile map at the given screen offset.
- `Facing::parse` (`tile_walker.rs`): Parses a facing direction from a string (case-insensitive).
- `Facing::to_str` (`tile_walker.rs`): Returns the direction as a lowercase string.
- `Facing::angle` (`tile_walker.rs`): Returns the angle in radians.
- `Facing::dx` (`tile_walker.rs`): Returns the X delta for one step in this direction.
- `Facing::dy` (`tile_walker.rs`): Returns the Y delta for one step in this direction.
- `TileWalker::new` (`tile_walker.rs`): Creates a new tile walker at (x, y) facing the given direction.
- `TileWalker::x` (`tile_walker.rs`): Returns the current X coordinate.
- `TileWalker::y` (`tile_walker.rs`): Returns the current Y coordinate.
- `TileWalker::facing` (`tile_walker.rs`): Returns the current facing direction.
- `TileWalker::set_position` (`tile_walker.rs`): Sets the position.
- `TileWalker::set_facing` (`tile_walker.rs`): Sets the facing direction.
- `TileWalker::can_move_forward` (`tile_walker.rs`): Returns true if the walker can move forward without actually moving.
- `TileWalker::can_move_backward` (`tile_walker.rs`): Returns true if the walker can move backward without actually moving.
- `TileWalker::can_strafe_left` (`tile_walker.rs`): Returns true if the walker can strafe left without actually moving.
- `TileWalker::can_strafe_right` (`tile_walker.rs`): Returns true if the walker can strafe right without actually moving.
- `TileWalker::move_forward` (`tile_walker.rs`): Moves forward one tile.
- `TileWalker::move_backward` (`tile_walker.rs`): Moves backward one tile.
- `TileWalker::strafe_left` (`tile_walker.rs`): Strafes left one tile.
- `TileWalker::strafe_right` (`tile_walker.rs`): Strafes right one tile.
- `TileWalker::turn_left` (`tile_walker.rs`): Turns left (counter-clockwise).
- `TileWalker::turn_right` (`tile_walker.rs`): Turns right (clockwise).
- `TileWalker::turn_around` (`tile_walker.rs`): Turns around (180 degrees).
- `TileWalker::begin_move` (`tile_walker.rs`): Snapshots the current state as the previous state for interpolation.
- `TileWalker::get_interpolated_position` (`tile_walker.rs`): Returns the interpolated position between previous and current at time `t` in [0, 1].
- `TileWalker::get_interpolated_angle` (`tile_walker.rs`): Returns the interpolated angle between previous and current facing at time `t` in [0, 1].
- `TileWalker::get_relative_facing` (`tile_walker.rs`): Returns the relative direction from the walker to a target tile.
- `TileMap::new` (`tilemap.rs`): Creates a new tile map with the given tile size and chunk size.
- `TileMap::add_tileset` (`tilemap.rs`): Adds a tileset to this map.
- `TileMap::get_tileset` (`tilemap.rs`): Returns a reference to a tileset by index.
- `TileMap::get_tileset_count` (`tilemap.rs`): Returns the number of tilesets attached to this map.
- `TileMap::add_layer` (`tilemap.rs`): Adds a new empty layer and returns its 0-based index.
- `TileMap::get_layer_count` (`tilemap.rs`): Returns the number of layers.
- `TileMap::get_layer_name` (`tilemap.rs`): Returns the name of a layer by index.
- `TileMap::set_layer_visible` (`tilemap.rs`): Sets layer visibility.
- `TileMap::get_layer_visible` (`tilemap.rs`): Returns layer visibility.
- `TileMap::set_layer_color` (`tilemap.rs`): Sets the RGBA tint color for a layer.
- `TileMap::get_layer_color` (`tilemap.rs`): Returns the RGBA tint color of a layer.
- `TileMap::set_layer_offset` (`tilemap.rs`): Sets the pixel offset for a layer.
- `TileMap::get_layer_offset` (`tilemap.rs`): Returns the pixel offset of a layer.
- `TileMap::set_layer_parallax` (`tilemap.rs`): Sets the parallax scrolling factor for a layer.
- `TileMap::get_layer_parallax` (`tilemap.rs`): Returns the parallax factor of a layer.
- `TileMap::get_layer_dimensions` (`tilemap.rs`): Returns the (width, height) of a layer in tiles, or `None` if out of range.
- `TileMap::set_tile` (`tilemap.rs`): Sets the GID of a tile at `(x, y)` on the given layer.
- `TileMap::get_tile` (`tilemap.rs`): Returns the GID at `(x, y)` on the given layer.
- `TileMap::set_tile_tint` (`tilemap.rs`): Sets a per-tile RGBA tint override.
- `TileMap::clear_tile` (`tilemap.rs`): Clears a tile (sets GID to 0) at `(x, y)` on the given layer.
- `TileMap::fill` (`tilemap.rs`): Fills an entire layer with the given GID.
- `TileMap::set_viewport` (`tilemap.rs`): Sets the viewport rectangle for rendering culling.
- `TileMap::get_viewport` (`tilemap.rs`): Returns the viewport as `(x, y, w, h)`, if set.
- `TileMap::update` (`tilemap.rs`): Advances tile animation timers by `dt` seconds.
- `TileMap::world_to_tile` (`tilemap.rs`): Converts world pixel coordinates to tile coordinates.
- `TileMap::tile_to_world` (`tilemap.rs`): Converts tile coordinates to world pixel coordinates (top-left of tile).
- `TileMap::get_tile_width` (`tilemap.rs`): Returns the tile width in pixels.
- `TileMap::get_tile_height` (`tilemap.rs`): Returns the tile height in pixels.
- `TileMap::get_tile_dimensions` (`tilemap.rs`): Returns tile dimensions as `(width, height)`.
- `TileMap::get_chunk_size` (`tilemap.rs`): Returns the chunk size used for spatial partitioning.
- `TileMap::get_orientation` (`tilemap.rs`): Returns the map orientation (top-down or side-view).
- `TileMap::set_orientation` (`tilemap.rs`): Sets the map orientation.
- `TileMap::is_solid` (`tilemap.rs`): Returns `true` if the tile at `(x, y)` on `layer` is solid.
- `TileMap::rect_overlaps_solid` (`tilemap.rs`): Returns `true` if any solid tile overlaps the given world-space rectangle on `layer`.
- `TileMap::sweep_rect` (`tilemap.rs`): Performs a swept AABB collision test against solid tiles on `layer`.
- `TileMap::apply_autotile` (`tilemap.rs`): Applies 4-bit cardinal autotile rules to every tile on `layer`.
- `TileMap::apply_autotile_at` (`tilemap.rs`): Applies 4-bit cardinal autotile at a single cell and its 3×3 neighborhood.
- `TileMap::apply_autotile_8` (`tilemap.rs`): Applies 8-bit directional autotile rules to every tile on `layer`.
- `TileMap::apply_autotile_8_at` (`tilemap.rs`): Applies 8-bit directional autotile at a single cell and its 3×3 neighborhood.
- `TileMap::draw_to_image` (`tilemap.rs`): Render all layers to an image using default colors per tile GID.
- `TileMap::build_render_commands` (`tilemap.rs`): Generates GPU `RenderCommand`s for the tile map at the given screen offset.
- `TileMap::draw_with_highlight_to_image` (`tilemap.rs`): Render a coordinate-mapping diagram: draws the tile grid at the given image size with world points marked as coloured circles and highlighted cells.
- `TileMap::draw_layers_to_image` (`tilemap.rs`): Draw all layers merged with colour-coding per layer.
- `TileMap::to_nav_grid` (`tilemap.rs`): Converts the given layer into a 2-D navigation grid.
- `TileSet::new` (`tileset.rs`): Creates a new tile set with the given atlas layout parameters.
- `TileSet::get_first_gid` (`tileset.rs`): Returns the first global ID assigned to this tileset.
- `TileSet::get_tile_count` (`tileset.rs`): Returns the total number of tiles in this tileset.
- `TileSet::get_columns` (`tileset.rs`): Returns the number of tile columns in the atlas texture.
- `TileSet::get_tile_width` (`tileset.rs`): Returns the width of a single tile in pixels.
- `TileSet::get_tile_height` (`tileset.rs`): Returns the height of a single tile in pixels.
- `TileSet::get_tile_dimensions` (`tileset.rs`): Returns the tile dimensions as `(width, height)`.
- `TileSet::get_spacing` (`tileset.rs`): Returns the spacing in pixels between tiles in the atlas.
- `TileSet::get_margin` (`tileset.rs`): Returns the margin in pixels around the edges of the atlas.
- `TileSet::get_quad` (`tileset.rs`): Computes the atlas source rectangle for a 0-based local tile ID.
- `TileSet::set_animation` (`tileset.rs`): Sets the animation frames for a local tile ID.
- `TileSet::get_animation` (`tileset.rs`): Returns the animation frames for a local tile ID, if any.
- `TileSet::set_solid` (`tileset.rs`): Sets whether a local tile ID is solid for collision purposes.
- `TileSet::is_solid` (`tileset.rs`): Returns whether a local tile ID is solid.
- `TileSet::set_auto_tile_rule` (`tileset.rs`): Registers a 4-bit cardinal autotile rule mapping a bitmask to a local tile ID.
- `TileSet::get_auto_tile_id` (`tileset.rs`): Looks up the local tile ID for a 4-bit cardinal autotile bitmask.
- `TileSet::set_auto_tile_rule_8` (`tileset.rs`): Registers an 8-bit directional autotile rule mapping a bitmask to a local tile ID.
- `TileSet::get_auto_tile_id_8` (`tileset.rs`): Looks up the local tile ID for an 8-bit directional autotile bitmask.
- `TmxMap::tile_layers` (`tmx.rs`): Returns only the tile layers, ignoring object / image layers.
- `TmxMap::object_layers` (`tmx.rs`): Returns only the object layers.
- `load_tmx` (`tmx.rs`): Parses a TMX file given its XML content as a string.

## Lua API Reference

- Binding path(s): `src/lua_api/tilemap_api.rs`
- Namespace: `lurek.tilemap`

### Module Functions
- `lurek.tilemap.newTileSet`: Creates a new TileSet with the given atlas layout parameters.
- `lurek.tilemap.newTileMap`: Creates a new TileMap with the given tile size and chunk size.
- `lurek.tilemap.newAutoTileSheet`: Creates a new AutoTileSheet with the given tile dimensions and layout.
- `lurek.tilemap.newChunkMap`: Creates a new ChunkMap with the given chunk size.
- `lurek.tilemap.newIsoMap`: Creates a new IsoMap with no levels.
- `lurek.tilemap.newMapBlock`: Creates a new MapBlock with the given dimensions.
- `lurek.tilemap.newMapGroup`: Creates a new empty MapGroup with the given name.
- `lurek.tilemap.toScreenIso`: Converts tile coordinates to screen position using diamond isometric projection.
- `lurek.tilemap.fromScreenIso`: Converts screen position back to tile coordinates for diamond isometric projection.
- `lurek.tilemap.toScreenHex`: Converts axial hex coordinates to screen position (pointy-top layout).
- `lurek.tilemap.fromScreenHex`: Converts screen position back to axial hex coordinates (pointy-top layout).
- `lurek.tilemap.hexNeighbors`: Returns the six axial neighbor coordinates as a table of {q, r} pairs.
- `lurek.tilemap.hexDistance`: Returns the hex distance between two axial coordinates.
- `lurek.tilemap.hexRound`: Rounds fractional axial coordinates to the nearest hex cell.
- `lurek.tilemap.hexLine`: Returns all hex cells along a line between two axial coordinates as a table.
- `lurek.tilemap.hexRing`: Returns all cells at exactly radius distance from (q, r) as a table.
- `lurek.tilemap.hexSpiral`: Returns all hex cells from center outward to radius, ring by ring, as a table.
- `lurek.tilemap.hexArea`: Returns all hex cells within radius distance (filled hex circle) as a table.
- `lurek.tilemap.hexRotate`: Rotates hex coordinates around a center by steps x 60 degrees clockwise.
- `lurek.tilemap.hexReflect`: Reflects hex coordinates across an axis through the center.
- `lurek.tilemap.isoRotate`: Rotates an isometric direction (1-4) clockwise by steps.
- `lurek.tilemap.isoDirectionName`: Returns the name of an isometric direction (1-4).
- `lurek.tilemap.isoDirectionFromAngle`: Snaps an angle (in radians) to the nearest isometric direction (1-4).
- `lurek.tilemap.newMapScript`: Creates a new empty MapScript procedural generation script.
- `lurek.tilemap.newMapGen`: Creates a MapGen from a MapGroup, a preset name or dimensions, and a segment size.
- `lurek.tilemap.loadTMX`: Parses a TMX XML string and returns a table with map metadata and layers.
- `lurek.tilemap.fromLDtk`: Parses an LDtk JSON export string and returns a TileMap.
- `lurek.tilemap.newLargeMapRenderer`: Creates a LargeMapRenderer for chunk-level occlusion culling on maps > 200×200 tiles.

### `AutoTileSheet` Methods
- `AutoTileSheet:getLayout`: Returns the layout variant as a string.
- `AutoTileSheet:getTileCount`: Returns the number of tiles in this sheet.
- `AutoTileSheet:getTileWidth`: Returns the tile width in pixels.
- `AutoTileSheet:getTileHeight`: Returns the tile height in pixels.
- `AutoTileSheet:getBitmaskForTile`: Returns the bitmask value associated with a 1-based local tile ID.
- `AutoTileSheet:getTileForBitmask`: Returns the 1-based tile ID for a given bitmask, or nil.
- `AutoTileSheet:getQuad`: Returns the atlas region rectangle for the 1-based tile ID.

### `ChunkMap` Methods
- `ChunkMap:getTile`: Returns the GID at tile coordinate (x, y).
- `ChunkMap:setTile`: Sets the GID at tile coordinate (x, y).
- `ChunkMap:clearTile`: Clears the tile at (x, y) by setting its GID to 0.
- `ChunkMap:loadChunk`: Pre-allocates the chunk at chunk coordinates (cx, cy).
- `ChunkMap:unloadChunk`: Removes the chunk at chunk coordinates (cx, cy) from memory.
- `ChunkMap:getChunkSize`: Returns the chunk size (tiles per side).
- `ChunkMap:getLoadedChunks`: Returns a table of all currently loaded chunk coordinates as {{cx, cy}, ...}.
- `ChunkMap:chunkTileRange`: Returns the tile coordinate range for chunk (cx, cy) as (x0, y0, x1, y1).

### `IsoMap` Methods
- `IsoMap:addLevel`: Appends a new empty Z-level and returns its 1-based index.
- `IsoMap:getLevelCount`: Returns the number of Z-levels currently in the map.
- `IsoMap:setLevelVisible`: Sets the visibility of a level (1-based z).
- `IsoMap:isLevelVisible`: Returns the visibility of a level (1-based z).
- `IsoMap:fillLevel`: Fills every cell in level z with gid for the given part (1-based z; 0-based part).
- `IsoMap:setOrigin`: Sets the screen pixel origin.
- `IsoMap:getWidth`: Returns the map width in tiles.
- `IsoMap:getHeight`: Returns the map height in tiles.
- `IsoMap:getTileWidth`: Returns the tile footprint width in pixels.
- `IsoMap:getTileHeight`: Returns the tile footprint height in pixels.
- `IsoMap:getLevelHeight`: Returns the vertical pixel offset between consecutive Z-levels.
- `IsoMap:tileToScreen`: Projects isometric tile coordinates (tx, ty, tz) to screen pixels.
- `IsoMap:screenToTile`: Converts screen pixel coordinates to isometric tile coordinates at Z-level 0.
- `IsoMap:getPartCount`: Returns the number of GID slots per tile.
- `IsoMap:getPartOrder`: Returns the current draw-order array (0-based part slot indices).
- `IsoMap:setPartOrder`: Overrides the draw order for this IsoMap. Length must equal partCount.

### `LargeMapRenderer` Methods
- `LargeMapRenderer:setTile`: Sets a single tile ID at (x, y).  Coordinates are 0-based.
- `LargeMapRenderer:getTile`: Returns the tile ID at (x, y), or nil if out of bounds.
- `LargeMapRenderer:getMapSize`: Returns the map dimensions as (width, height) in tiles.
- `LargeMapRenderer:setChunkSize`: Sets the chunk size used for culling (default 16).
- `LargeMapRenderer:getChunkSize`: Returns the current chunk size.
- `LargeMapRenderer:invalidateChunk`: Marks a chunk at chunk-grid coordinates (cx, cy) as dirty,
- `LargeMapRenderer:invalidateAll`: Marks every chunk as dirty.
- `LargeMapRenderer:getVisibleChunks`: Returns the number of chunks currently within the camera viewport.
- `LargeMapRenderer:getTotalChunks`: Returns the total number of chunks that cover the loaded map.
- `LargeMapRenderer:setCamera`: Updates the camera position and zoom used for visibility culling.
- `LargeMapRenderer:setViewport`: Sets the viewport dimensions in pixels used for visibility culling.
- `LargeMapRenderer:setLodEnabled`: Enables or disables level-of-detail rendering for distant chunks.
- `LargeMapRenderer:isLodEnabled`: Returns whether LOD rendering is currently enabled.
- `LargeMapRenderer:setLodThresholds`: Sets the distance thresholds (in tile units) at which each LOD level activates.
- `LargeMapRenderer:setTilesetColumns`: Sets the number of tile columns in the atlas texture used for UV calculation.
- `LargeMapRenderer:getTilesetColumns`: Returns the number of tileset atlas columns.

### `MapBlock` Methods
- `MapBlock:getTile`: Returns the GID of the tile at (x, y) on the given layer (1-based).
- `MapBlock:getSide`: Returns the side connection ID for a segment on a given edge.
- `MapBlock:getWidth`: Returns the block width in tiles.
- `MapBlock:getHeight`: Returns the block height in tiles.
- `MapBlock:getDimensions`: Returns the block dimensions as (width, height) in tiles.
- `MapBlock:getLayerCount`: Returns the number of layers in this block.
- `MapBlock:getSegmentSize`: Returns the segment size in tiles.
- `MapBlock:getWidthInSegments`: Returns the number of segments along the width.
- `MapBlock:getHeightInSegments`: Returns the number of segments along the height.
- `MapBlock:setName`: Sets the human-readable name of this block.
- `MapBlock:getName`: Returns the name of this block.
- `MapBlock:setWeight`: Sets the placement weight.
- `MapBlock:getWeight`: Returns the placement weight.

### `MapGroup` Methods
- `MapGroup:addBlock`: Adds a block to this group.
- `MapGroup:getBlockCount`: Returns the number of blocks in this group.
- `MapGroup:removeBlock`: Removes a block by 1-based index.
- `MapGroup:getName`: Returns the name of this group.
- `MapGroup:addScript`: Adds a MapScript to this group.
- `MapGroup:getScriptCount`: Returns the number of scripts in this group.

### `MapScript` Methods
- `MapScript:getStepCount`: Returns the number of steps in this script.
- `MapScript:addStep`: Appends a generation step from a step-definition table.

### `TileMap` Methods
- `TileMap:addTileSet`: Adds a tileset to this map.
- `TileMap:getTileSetCount`: Returns the number of tilesets attached to this map.
- `TileMap:getTileSet`: Returns a tileset by 1-based index, or nil if out of range.
- `TileMap:addLayer`: Adds a new empty layer and returns its 1-based index.
- `TileMap:getLayerCount`: Returns the number of layers.
- `TileMap:getLayerName`: Returns the name of a layer by 1-based index.
- `TileMap:getLayerVisible`: Returns layer visibility.
- `TileMap:getLayerColor`: Returns the RGBA tint color of a layer.
- `TileMap:getLayerOffset`: Returns the pixel offset of a layer.
- `TileMap:getLayerParallax`: Returns the parallax factor of a layer.
- `TileMap:getTile`: Returns the GID at (x, y) on the given layer (1-based).
- `TileMap:clearTile`: Clears a tile (sets GID to 0) at (x, y) on the given layer (1-based).
- `TileMap:fill`: Fills an entire layer with the given GID (1-based layer).
- `TileMap:getViewport`: Returns the viewport as (x, y, w, h) or nil if not set.
- `TileMap:update`: Advances tile animation timers by dt seconds.
- `TileMap:worldToTile`: Converts world pixel coordinates to tile coordinates.
- `TileMap:tileToWorld`: Converts tile coordinates to world pixel coordinates (1-based input).
- `TileMap:getTileWidth`: Returns the tile width in pixels.
- `TileMap:getTileHeight`: Returns the tile height in pixels.
- `TileMap:getTileDimensions`: Returns tile dimensions as (width, height).
- `TileMap:getChunkSize`: Returns the chunk size used for spatial partitioning.
- `TileMap:isSolid`: Returns true if the tile at (x, y) on layer is solid (1-based).
- `TileMap:getOrientation`: Returns the map orientation as a string ("topdown", "sideview", "isometric", or "hexagonal").
- `TileMap:setOrientation`: Sets the map orientation from a string ("topdown", "sideview", "isometric", or "hexagonal").
- `TileMap:render`: Renders the tile map to the screen at the given offset.
- `TileMap:drawToImage`: Renders the tile map to a CPU ImageData using the given tile pixel size.
- `TileMap:toNavGrid`: Converts the given layer into a 2D navigation grid.

### `TileSet` Methods
- `TileSet:getFirstGid`: Returns the first global ID assigned to this tileset.
- `TileSet:getTileCount`: Returns the total number of tiles in this tileset.
- `TileSet:getColumns`: Returns the number of tile columns in the atlas texture.
- `TileSet:getTileWidth`: Returns the width of a single tile in pixels.
- `TileSet:getTileHeight`: Returns the height of a single tile in pixels.
- `TileSet:getTileDimensions`: Returns the tile dimensions as (width, height).
- `TileSet:getSpacing`: Returns the spacing in pixels between tiles in the atlas.
- `TileSet:getMargin`: Returns the margin in pixels around the edges of the atlas.
- `TileSet:getQuad`: Computes the atlas source rectangle for a 1-based local tile ID.
- `TileSet:getAnimation`: Returns the animation frames for a 1-based local tile ID as a table of {tileid, duration}, or nil.
- `TileSet:setSolid`: Sets whether a 1-based local tile ID is solid for collision purposes.
- `TileSet:isSolid`: Returns whether a 1-based local tile ID is solid.

## References

- `image`: Imports or references `image` from `src/image/`.
- `math`: Imports or references `math` from `src/math/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/tilemap/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
