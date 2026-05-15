# province

## General Info

- Module group: `Edge/Integration`
- Source path: `src/province/`
- Lua API path(s): `src/lua_api/province_api.rs`
- Primary Lua namespace: `lurek.province`
- Rust test path(s): None found in the workspace
- Lua test path(s): None found in the workspace

## Summary

`province` is the engine-native province runtime module for large strategy maps.
It stores province topology, style state (political colors, terrain, borders, fog,
visibility), geometry caches (spans/segments), and revisioned change streams used
by render frontends and adapters.

The module is intentionally independent from `globe` and `minimap`. Integration
is done through optional adapter files:

- `src/globe/province_adapter.rs`
- `src/minimap/province_adapter.rs`

Lua controls this module through `lurek.province.*`, while heavy data processing
stays in Rust.

The module also provides a standardized map-import pipeline for strategy content:

- marker sanitization (`lurek.province.sanitizeMarkedPng`) that rewrites special
  marker pixels into owner colors for deterministic color-id mapping,
- bulk metadata import (`LProvinceRegistry:importMetadataFromFiles`) that applies
  CSV/TOML-driven terrain, labels, capitals, and political colors in one Rust pass.

## Files

- `borders.rs`: Border classification helpers.
- `cache.rs`: Cache serialization for province geometry.
- `events.rs`: Province runtime events and change records.
- `gpu_bridge.rs`: GPU bridge helpers for province data buffers.
- `import.rs`: - Province metadata import pipeline: colour-map PNG + RGB CSV + optional TOML → registry.
- `labels.rs`: Province centroid/label anchor helpers.
- `map_modes.rs`: Province map-mode utilities.
- `mod.rs`: Province engine module.
- `registry.rs`: Province runtime registry.
- `render.rs`: Province render command generation.
- `topology.rs`: Province topology graph and adjacency helpers.
- `types.rs`: Core value types for the province engine.
- `view_transform.rs`: Province map view transform helpers shared by strategy-style map scripts.

## Types

- `ProvinceGeometryCache` (`struct`, `cache.rs`): Cache blob of precomputed province geometry.
- `ProvinceChange` (`enum`, `events.rs`): Fine-grained field updates emitted by the province registry.
- `ProvinceEvent` (`enum`, `events.rs`): High-level province events for subscribers.
- `ProvinceGpuRecord` (`struct`, `gpu_bridge.rs`): GPU packed province row (std430-friendly 32-byte payload).
- `MarkerSanitizeOptions` (`struct`, `import.rs`): Thresholds for detecting capital and label marker pixels in a marker PNG.
- `MarkerSanitizeSummary` (`struct`, `import.rs`): Result counters returned by sanitize_marked_png.
- `ProvinceMetadataImportOptions` (`struct`, `import.rs`): Options for the full metadata import pipeline run by import_metadata_from_files.
- `ProvinceMetadataImportSummary` (`struct`, `import.rs`): Result counters returned by import_metadata_from_files.
- `ProvinceMapMode` (`enum`, `map_modes.rs`): Built-in map modes supported by the province engine.
- `ProvinceRecord` (`struct`, `registry.rs`): Runtime state for one province row.
- `ProvinceRegistry` (`struct`, `registry.rs`): Full province dataset with revisioned change history.
- `ProvinceRenderOptions` (`struct`, `render.rs`): Render options for one province map pass.
- `ProvinceGraph` (`struct`, `topology.rs`): Undirected adjacency graph between provinces.
- `ProvinceId` (`type`, `types.rs`): Province identifier used across province/globe/minimap modules.
- `BorderClass` (`enum`, `types.rs`): Visual/semantic class for borders between two provinces.
- `ProvinceStyle` (`struct`, `types.rs`): Mutable style/state attached to one province.
- `ProvinceSnapshot` (`struct`, `types.rs`): Immutable read model consumed by other modules.

## Functions

- `classify_border` (`borders.rs`): Classifies border class from two province styles.
- `ProvinceGeometryCache::from_registry` (`cache.rs`): Build a cache by copying spans and border_segments from the given registry.
- `ProvinceGeometryCache::encode` (`cache.rs`): Serialise to a versioned little-endian byte buffer; always succeeds.
- `ProvinceGeometryCache::decode` (`cache.rs`): Deserialise from a byte buffer produced by encode; return None on magic mismatch or truncation.
- `build_gpu_records` (`gpu_bridge.rs`): Builds a sorted GPU record table from registry contents.
- `sanitize_marked_png` (`import.rs`): Replace capital and label marker pixels with their nearest non-marker neighbour and write the result to output_png_path; return pixel counts or an error string.
- `import_metadata_from_files` (`import.rs`): Import province metadata from colour-map PNG, RGB CSV, and optional TOML/marker files into registry; return counts or an error string.
- `centroids_from_spans` (`labels.rs`): Computes centroid candidates from fill spans.
- `ProvinceMapMode::as_str` (`map_modes.rs`): Return the canonical lowercase string token for this mode.
- `ProvinceMapMode::parse_str` (`map_modes.rs`): Parse a string token to a variant; return None on unknown input.
- `resolve_color` (`map_modes.rs`): Resolves output color for one province style in selected map mode.
- `ProvinceRegistry::new` (`registry.rs`): Return a new empty registry with zero dimensions and no provinces.
- `ProvinceRegistry::from_grid` (`registry.rs`): Build a registry from a pre-parsed ProvinceGrid, computing spans, adjacency, and centroids.
- `ProvinceRegistry::from_png` (`registry.rs`): Build a registry by loading a province colour-map PNG from path; return error on I/O or decode failure.
- `ProvinceRegistry::width` (`registry.rs`): Return the width of the source map in pixels.
- `ProvinceRegistry::height` (`registry.rs`): Return the height of the source map in pixels.
- `ProvinceRegistry::get_at` (`registry.rs`): Return the province id at pixel (x, y); returns 0 if coordinates are out of bounds.
- `ProvinceRegistry::revision` (`registry.rs`): Return the current revision counter; increases by one on each mutation.
- `ProvinceRegistry::province_ids` (`registry.rs`): Return all known province ids sorted ascending.
- `ProvinceRegistry::province_count` (`registry.rs`): Return the number of provinces currently in the registry.
- `ProvinceRegistry::get_province` (`registry.rs`): Return a snapshot of the province's style and metadata, or None if id is unknown.
- `ProvinceRegistry::get_neighbors` (`registry.rs`): Return the sorted neighbour list for id as a Vec; returns empty Vec if id has no adjacencies.
- `ProvinceRegistry::adjacency_pairs` (`registry.rs`): Return all unique adjacency pairs (a < b) sorted ascending.
- `ProvinceRegistry::spans` (`registry.rs`): Return all span runs as a slice: (id, row_y, x_start, x_end_exclusive).
- `ProvinceRegistry::border_segments` (`registry.rs`): Return all border segments as a slice: (id_a, id_b, x0, y0, x1, y1).
- `ProvinceRegistry::spans_for` (`registry.rs`): Return the span runs for a single province as (row_y, x_start, x_end_exclusive), or None if unknown.
- `ProvinceRegistry::bbox_for` (`registry.rs`): Return the axis-aligned bounding box (min_x, min_y, max_x, max_y) for id, or None if unknown.
- `ProvinceRegistry::style_for` (`registry.rs`): Return a reference to the style for id, or None if id is unknown.
- `ProvinceRegistry::set_capital` (`registry.rs`): Set the capital position for id; return false if id is unknown.
- `ProvinceRegistry::capital_for` (`registry.rs`): Return the capital position for id, or None if not set or id is unknown.
- `ProvinceRegistry::set_label_line` (`registry.rs`): Set the label anchor line for id from (ax, ay) to (bx, by); return false if id is unknown.
- `ProvinceRegistry::label_line_for` (`registry.rs`): Return the label line for id as ((x0,y0),(x1,y1)), or None if not set or id is unknown.
- `ProvinceRegistry::set_label_text` (`registry.rs`): Set the display label text for id; return false if id is unknown.
- `ProvinceRegistry::label_text_for` (`registry.rs`): Return the label text for id as a str slice, or None if not set or id is unknown.
- `ProvinceRegistry::get_changes_since` (`registry.rs`): Return all change log entries with revision > since_revision.
- `ProvinceRegistry::set_political_color` (`registry.rs`): Set the political fill colour for id and record a PoliticalColor change; return false if id is unknown.
- `ProvinceRegistry::set_terrain_type` (`registry.rs`): Set the terrain type index for id and record a TerrainType change; return false if id is unknown.
- `ProvinceRegistry::set_border_style` (`registry.rs`): Set the border style index for id and record a BorderStyle change; return false if id is unknown.
- `ProvinceRegistry::set_fog_state` (`registry.rs`): Set the fog state byte for id and record a FogState change; return false if id is unknown.
- `ProvinceRegistry::set_visibility_state` (`registry.rs`): Set the visibility state byte for id and record a VisibilityState change; return false if id is unknown.
- `ProvinceRegistry::set_border_class` (`registry.rs`): Set the border class for the (a, b) pair and record a BorderClass change.
- `ProvinceRegistry::get_border_class` (`registry.rs`): Return the stored border class for the (a, b) pair, or None if not explicitly set.
- `ProvinceRegistry::set_attr` (`registry.rs`): Insert a key-value string attribute for id; return false if id is unknown.
- `generate_render_commands` (`render.rs`): Generates render commands for one province map frame.
- `ProvinceGraph::new` (`topology.rs`): Return a new empty graph.
- `ProvinceGraph::rebuild_from_pairs` (`topology.rs`): Rebuild the graph from a slice of adjacent id pairs; clears previous data.
- `ProvinceGraph::neighbors_of` (`topology.rs`): Return the sorted neighbour slice for id; returns an empty slice if id has no entry.
- `ProvinceGraph::is_adjacent` (`topology.rs`): Return true if a and b share a border in the graph.
- `ProvinceGraph::province_ids` (`topology.rs`): Return all province ids present in the graph, sorted ascending.
- `ProvinceGraph::adjacency_pairs` (`topology.rs`): Return all unique adjacency pairs (a < b) sorted ascending.
- `BorderClass::as_str` (`types.rs`): Return the canonical string token used in TOML and CSV exports.
- `BorderClass::parse_str` (`types.rs`): Parse a string token back to a variant; return None on unknown input.
- `fit_camera_to_screen` (`view_transform.rs`): Computes camera transform that fits the full province map inside the screen.
- `screen_to_map` (`view_transform.rs`): Converts a screen-space position to map-space pixel coordinates.
- `map_to_cell` (`view_transform.rs`): Converts map-space coordinates to a 0-based integer cell when inside bounds.
- `zoom_camera_at` (`view_transform.rs`): Recomputes camera origin so zooming keeps a screen anchor fixed.

## Lua API Reference

- Binding path(s): `src/lua_api/province_api.rs`
- Namespace: `lurek.province`

### Module Functions
- `lurek.province.newFromPng`: Creates a new province registry by loading a color-coded PNG where each unique color represents a distinct province. The PNG is parsed into a grid and adjacencies are computed automatically.
- `lurek.province.sanitizeMarkedPng`: Pre-processes a marker PNG by replacing capital and label marker pixels with the surrounding province color. Outputs a cleaned PNG suitable for `newFromPng`. Returns a summary of pixel replacements.
- `lurek.province.get`: Retrieves an existing province registry by name. Returns nil if no registry with that name has been created.
- `lurek.province.exists`: Checks whether a province registry with the given name exists.
- `lurek.province.remove`: Removes a province registry by name and clears the active registry if it was the one removed. Returns true if a registry was actually removed.
- `lurek.province.setActive`: Sets the named registry as the active province registry. Returns false if no registry with that name exists.
- `lurek.province.getActive`: Returns the currently active province registry, or nil if none is set.
- `lurek.province.zoomCameraAt`: Computes new camera position after zooming centered on an anchor point. Keeps the anchor point visually stationary on screen while the zoom level changes.

### `LProvinceRegistry` Methods
- `LProvinceRegistry:getName`: Returns the string name used to identify this registry in the province system.
- `LProvinceRegistry:getWidth`: Returns the width of the province grid in cells (pixels of the source PNG).
- `LProvinceRegistry:getHeight`: Returns the height of the province grid in cells (pixels of the source PNG).
- `LProvinceRegistry:getAt`: Returns the province ID at the given grid cell coordinates. Returns 0 if the cell is unowned (sea, wasteland, etc.).
- `LProvinceRegistry:fitCamera`: Computes camera position and zoom so the entire province map fits within the given screen dimensions.
- `LProvinceRegistry:screenToMap`: Converts screen-space pixel coordinates to map-space floating-point coordinates using the current camera transform.
- `LProvinceRegistry:screenToProvince`: Converts screen-space coordinates directly to a province ID. Returns nil if the cursor is outside the map or over an unowned cell.
- `LProvinceRegistry:provinceCount`: Returns the total number of distinct provinces in this registry (excluding ID 0).
- `LProvinceRegistry:provinceIds`: Returns a sequential table of all province IDs in this registry.
- `LProvinceRegistry:adjacencies`: Returns all adjacency pairs in the registry. Each entry has `province_a` and `province_b` fields representing two neighboring provinces.
- `LProvinceRegistry:provinceSpans`: Returns the raw span data for all provinces. Each span is a horizontal run of cells belonging to one province, useful for custom rendering or spatial analysis.
- `LProvinceRegistry:borderSegments`: Returns all border line segments between adjacent provinces. Each segment is a line from (x0,y0) to (x1,y1) separating province_a from province_b.
- `LProvinceRegistry:getRevision`: Returns the current change revision counter. Incremented on every mutation (color, terrain, border, fog changes). Use with `getChangesSince` for incremental updates.
- `LProvinceRegistry:getProvince`: Returns a snapshot table describing a single province: its ID, revision, style (political_color, terrain_type, border_style, fog_state, visibility_state), centroid, and custom attributes.
- `LProvinceRegistry:getNeighbors`: Returns a table of province IDs that share a border with the given province.
- `LProvinceRegistry:getBorderClass`: Returns the border classification string between two adjacent provinces (e.g. "river", "mountain", "sea"), or nil if no class is set.
- `LProvinceRegistry:setBorderClass`: Sets the border classification between two adjacent provinces. Used to control border rendering style (e.g. rivers drawn as blue lines).
- `LProvinceRegistry:setPoliticalColor`: Sets the political map color for a province. Used in political map mode rendering and change tracking.
- `LProvinceRegistry:setTerrainType`: Sets the terrain type index for a province. Terrain type controls which fill color or texture is used in terrain map mode.
- `LProvinceRegistry:setBorderStyle`: Sets the border rendering style index for a province. Controls line thickness, color, or pattern when borders are drawn.
- `LProvinceRegistry:setFogState`: Sets the fog-of-war state for a province. Typically 0 = revealed, 1 = fogged, 2 = hidden. Controls rendering opacity or overlay.
- `LProvinceRegistry:setVisibilityState`: Sets the visibility state for a province. Used for strategic visibility layers separate from fog (e.g. scouted vs. unscouted).
- `LProvinceRegistry:setAttr`: Sets a custom string attribute on a province. Attributes are returned in the `attrs` table of `getProvince` and can store arbitrary game metadata.
- `LProvinceRegistry:setCapital`: Sets the capital marker position for a province. The capital is drawn as a small icon during `render` when `draw_capitals` is enabled.
- `LProvinceRegistry:setLabelLine`: Sets the label baseline for a province. The label text is rendered along the line from (ax,ay) to (bx,by), allowing curved or angled province names.
- `LProvinceRegistry:setLabelText`: Sets the display name text for a province. Rendered on the map when `draw_labels` is enabled in `render` options.
- `LProvinceRegistry:importMetadataFromFiles`: Bulk-imports province metadata (colors, capitals, labels, terrain) from external files (PNG color map, CSV color table, TOML province definitions, marker PNG). Returns a summary of how many provinces were mapped.
- `LProvinceRegistry:render`: Renders the province map to the screen using the current camera and style settings. Generates draw commands for fills, borders, labels, and capitals based on the provided options.
- `LProvinceRegistry:getChangesSince`: Returns all province changes that occurred after the given revision. Each entry contains the revision number and a change record describing what was modified (political_color, terrain_type, border_style, fog_state, visibility_state, or border_class).
- `LProvinceRegistry:type`: Returns the type name string for this userdata object.
- `LProvinceRegistry:typeOf`: Checks whether this object matches the given type name. Returns true for "LProvinceRegistry" and "Object".

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from `Edge/Integration` into `Platform Services`.
- `render`: Imports or references `src/render/`. Cross-group dependency from `Edge/Integration` into `Platform Services`.
- `runtime`: Imports or references `src/runtime/`. Cross-group dependency from `Edge/Integration` into `Core Runtime`.

## Notes

- `library/province_map/init.lua` uses engine-backed mode through `lurek.province`
  when available and falls back to `lurek.image.newProvinceGrid` otherwise.
- The module is prepared for GPU compositing pipelines via `province::gpu_bridge`.
- `province::render` generates `RenderCommand` batches in Rust (fills, borders,
  capitals, labels, hover/selection outlines) so Lua does not need per-pixel
  or per-span render loops.
