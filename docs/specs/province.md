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
- `ProvinceGeometryCache::from_registry` (`cache.rs`): Builds cache from a registry snapshot.
- `ProvinceGeometryCache::encode` (`cache.rs`): Encodes cache to a compact little-endian blob.
- `ProvinceGeometryCache::decode` (`cache.rs`): Decodes cache from bytes.
- `build_gpu_records` (`gpu_bridge.rs`): Builds a sorted GPU record table from registry contents.
- `centroids_from_spans` (`labels.rs`): Computes centroid candidates from fill spans.
- `ProvinceMapMode::as_str` (`map_modes.rs`): Maps mode to stable API token.
- `ProvinceMapMode::parse_str` (`map_modes.rs`): Parses mode from API token.
- `resolve_color` (`map_modes.rs`): Resolves output color for one province style in selected map mode.
- `ProvinceRegistry::new` (`registry.rs`): Creates an empty registry.
- `ProvinceRegistry::from_grid` (`registry.rs`): Builds a registry from a precomputed [`ProvinceGrid`].
- `ProvinceRegistry::from_png` (`registry.rs`): Loads a registry by reading a PNG and scanning it into a `ProvinceGrid`.
- `ProvinceRegistry::width` (`registry.rs`): Returns map width in pixels.
- `ProvinceRegistry::height` (`registry.rs`): Returns map height in pixels.
- `ProvinceRegistry::get_at` (`registry.rs`): Returns province id at map pixel `(x, y)` (0 when outside map).
- `ProvinceRegistry::revision` (`registry.rs`): Returns current monotonic revision.
- `ProvinceRegistry::province_ids` (`registry.rs`): Returns sorted province ids known to this registry.
- `ProvinceRegistry::province_count` (`registry.rs`): Returns number of provinces.
- `ProvinceRegistry::get_province` (`registry.rs`): Returns a read-only province snapshot.
- `ProvinceRegistry::get_neighbors` (`registry.rs`): Returns province neighbors.
- `ProvinceRegistry::adjacency_pairs` (`registry.rs`): Returns sorted adjacency pairs.
- `ProvinceRegistry::spans` (`registry.rs`): Returns cached fill spans `(id, y, x0, x1)`.
- `ProvinceRegistry::border_segments` (`registry.rs`): Returns cached merged border segments `(a,b,x0,y0,x1,y1)`.
- `ProvinceRegistry::spans_for` (`registry.rs`): Returns grouped fill spans for one province as `(y, x0, x1)` rows.
- `ProvinceRegistry::bbox_for` (`registry.rs`): Returns province bbox as `(min_x, min_y, max_x, max_y)` in map pixels.
- `ProvinceRegistry::style_for` (`registry.rs`): Returns an immutable reference to a province style.
- `ProvinceRegistry::set_capital` (`registry.rs`): Sets province capital marker in map-space coordinates.
- `ProvinceRegistry::capital_for` (`registry.rs`): Returns province capital marker, if present.
- `ProvinceRegistry::set_label_line` (`registry.rs`): Sets province label guide line in map-space coordinates.
- `ProvinceRegistry::label_line_for` (`registry.rs`): Returns province label guide line, if present.
- `ProvinceRegistry::set_label_text` (`registry.rs`): Sets province label text.
- `ProvinceRegistry::label_text_for` (`registry.rs`): Returns province label text.
- `ProvinceRegistry::get_changes_since` (`registry.rs`): Returns all changes with `revision > since_revision`.
- `ProvinceRegistry::set_political_color` (`registry.rs`): Updates political color for one province.
- `ProvinceRegistry::set_terrain_type` (`registry.rs`): Updates terrain type for one province.
- `ProvinceRegistry::set_border_style` (`registry.rs`): Updates border style for one province.
- `ProvinceRegistry::set_fog_state` (`registry.rs`): Updates fog state for one province.
- `ProvinceRegistry::set_visibility_state` (`registry.rs`): Updates visibility state for one province.
- `ProvinceRegistry::set_border_class` (`registry.rs`): Sets explicit border class between two provinces.
- `ProvinceRegistry::get_border_class` (`registry.rs`): Returns border class between provinces.
- `ProvinceRegistry::set_attr` (`registry.rs`): Sets/overwrites freeform string attribute.
- `generate_render_commands` (`render.rs`): Generates render commands for one province map frame.
- `ProvinceGraph::new` (`topology.rs`): Creates an empty province graph.
- `ProvinceGraph::rebuild_from_pairs` (`topology.rs`): Rebuilds graph from sorted/unsorted adjacency pairs.
- `ProvinceGraph::neighbors_of` (`topology.rs`): Returns neighbor ids for one province.
- `ProvinceGraph::is_adjacent` (`topology.rs`): Returns true if two provinces share an adjacency edge.
- `ProvinceGraph::province_ids` (`topology.rs`): Returns sorted province ids present in topology.
- `ProvinceGraph::adjacency_pairs` (`topology.rs`): Returns normalized unique adjacency pairs (a<b).
- `BorderClass::as_str` (`types.rs`): Converts this border class to a stable string token for Lua/docs.
- `BorderClass::parse_str` (`types.rs`): Parses a border class token from Lua-facing API strings.
- `fit_camera_to_screen` (`view_transform.rs`): Computes camera transform that fits the full province map inside the screen.
- `screen_to_map` (`view_transform.rs`): Converts a screen-space position to map-space pixel coordinates.
- `map_to_cell` (`view_transform.rs`): Converts map-space coordinates to a 0-based integer cell when inside bounds.
- `zoom_camera_at` (`view_transform.rs`): Recomputes camera origin so zooming keeps a screen anchor fixed.

## Lua API Reference

- Binding path(s): `src/lua_api/province_api.rs`
- Namespace: `lurek.province`

### Module Functions
- `lurek.province.newFromPng`: Creates and stores a named province registry from a PNG map.
- `lurek.province.get`: Gets a named province registry handle.
- `lurek.province.exists`: Checks whether a named registry exists.
- `lurek.province.remove`: Removes a named registry.
- `lurek.province.setActive`: Sets active registry name.
- `lurek.province.getActive`: Returns active registry handle.
- `lurek.province.zoomCameraAt`: Recomputes camera x/y so zooming stays anchored under the same screen point.

### `LProvinceRegistry` Methods
- `LProvinceRegistry:getName`: Returns registry name.
- `LProvinceRegistry:getWidth`: Returns source map width in pixels.
- `LProvinceRegistry:getHeight`: Returns source map height in pixels.
- `LProvinceRegistry:getAt`: Returns province id at pixel coordinate.
- `LProvinceRegistry:fitCamera`: Computes camera x/y/zoom that fits the full map in the given screen.
- `LProvinceRegistry:screenToMap`: Converts screen-space coordinates to map-space coordinates.
- `LProvinceRegistry:screenToProvince`: Returns province id under a screen-space position.
- `LProvinceRegistry:provinceCount`: Returns number of provinces.
- `LProvinceRegistry:provinceIds`: Returns sorted province ids.
- `LProvinceRegistry:adjacencies`: Returns adjacency pairs as records `{ province_a, province_b }`.
- `LProvinceRegistry:provinceSpans`: Returns span geometry records `{ province_id, y, x0, x1 }`.
- `LProvinceRegistry:borderSegments`: Returns border segment geometry records `{ province_a, province_b, x0, y0, x1, y1 }`.
- `LProvinceRegistry:getRevision`: Returns registry revision counter.
- `LProvinceRegistry:getProvince`: Returns province snapshot table or nil.
- `LProvinceRegistry:getNeighbors`: Returns neighbor ids for a province.
- `LProvinceRegistry:getBorderClass`: Returns border class token between provinces or nil.
- `LProvinceRegistry:setBorderClass`: Sets border class between provinces.
- `LProvinceRegistry:setPoliticalColor`: Sets political color for one province.
- `LProvinceRegistry:setTerrainType`: Sets terrain type for one province.
- `LProvinceRegistry:setBorderStyle`: Sets border style id for one province.
- `LProvinceRegistry:setFogState`: Sets fog state byte for one province.
- `LProvinceRegistry:setVisibilityState`: Sets visibility byte for one province.
- `LProvinceRegistry:setAttr`: Sets freeform attribute on a province.
- `LProvinceRegistry:setCapital`: Sets province capital marker position.
- `LProvinceRegistry:setLabelLine`: Sets province label guide line from two points.
- `LProvinceRegistry:setLabelText`: Sets province display label text.
- `LProvinceRegistry:render`: Enqueues Rust-generated GPU draw commands for province rendering.
- `LProvinceRegistry:getChangesSince`: Returns revisioned change records for incremental sync.
- `LProvinceRegistry:type`: Returns Lua type name.
- `LProvinceRegistry:typeOf`: Returns true when type token matches this userdata.

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
