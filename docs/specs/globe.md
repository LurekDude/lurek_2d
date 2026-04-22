# globe

## General Info

- Module group: `Feature Systems`
- Source path: `src/globe/`
- Lua API path(s): `src/lua_api/globe_api.rs`
- Primary Lua namespace: `lurek.globe`
- Rust test path(s): None found in the workspace
- Lua test path(s): None found in the workspace

## Summary

The `globe` module provides an XCOM Geoscape-style 2D strategic globe view —
a projection-correct rendering of a unit sphere divided into navigable named
provinces. It is a Feature Systems tier module that works entirely through the
engine's existing 2D `RenderCommand` variants (`DrawConvexFan`, `Polyline`,
`Circle`, `Print`), adding no new wgpu pipeline or 3D draw calls (consistent
with binding constraint A-03).

**Province topology**: `ProvinceGraph` stores adjacency lists keyed by
`ProvinceId` (u32). Each `Province` carries a vertex polygon in lat/lon
degrees, centroid coordinates, neighbor list, free-form attribute `HashMap`,
per-edge tag sets, optional texture name, and base RGBA color. Up to
`MAX_PROVINCES` (8192) provinces are supported per globe instance.
`ProvinceGraph` supports A\* pathfinding between provinces, reachability
analysis with configurable edge-tag filtering, and nearest-province queries
for click-to-select interactions.

**Orbit camera**: `OrbitCamera` tracks lat/lon look-at position, zoom
multiplier, and screen centre offset. `build_view_matrix` converts orbital
parameters to a 2D projection matrix used by the draw pass. `project_province`
and `project_point` map lat/lon to screen coordinates under the current
projection. `LodTier` (Far / Mid / Near) derives from zoom and gates border
detail, province labels, and marker rendering at three LOD levels.

**Day/night lighting**: The sun direction derives from `GlobeSpec.time_of_day`
(0–24 h) and an `axial_tilt_deg` field. Each province receives a scalar
intensity value with a soft terminator band. The `ambient` floor prevents
night-side provinces from becoming invisible.

**Fog of war**: `FogMask` is a compact 128 × u64 bit-vector giving O(1)
reveal/hide per province. `FogStore` manages one `FogMask` per viewer entity,
enabling multi-faction fog-of-war without per-frame heap allocation.

**Markers, labels, and overlay layers**: `MarkerStore` and `LabelStore` manage
point-of-interest and text overlays with lifecycle tracking. `LayerStore` holds
thematic overlay layers (political, terrain, heat-map) and computes a blended
`effective_color` for each province at draw time from base color, overlay
contributions, and fog intensity.

**Arc rendering**: `Arc` records great-circle routes or range-ring annotations;
the draw module converts arcs to polyline sequences in screen space.

**Loaders**: `loader.rs` parses TOML province-map files (province polygon
lists, adjacency tables, attribute maps) and stub PNG province rasters. Both
populate native `Globe` structures through `GlobeRegistry`.

**Scope boundary**: Feature Systems tier. Depends on `render`, `math`,
`runtime`, `image`. Lua bridge in `src/lua_api/globe_api.rs`.

## Files

- `draw.rs`: Frame emission for the globe module.
- `fog.rs`: Per-faction fog-of-war for the globe module.
- `label.rs`: Generic label store for the globe module.
- `layer.rs`: Named layer registry for the globe module.
- `lighting.rs`: Day/night lighting for the globe module.
- `loader.rs`: Province data loaders for the globe module.
- `marker.rs`: Generic marker store for the globe module.
- `mod.rs`: Globe module — XCOM-style Geoscape / Europa Universalis sphere.
- `picking.rs`: Screen-to-province hit-test for the globe module.
- `projection.rs`: Orthographic sphere projection and orbit camera for the globe module.
- `registry.rs`: Globe registry — per-named-globe container and multi-globe manager.
- `topology.rs`: Province adjacency graph for the globe module.
- `types.rs`: Core value types for the globe module.

## Types

- `FogMask` (`struct`, `fog.rs`): Per-faction visibility bit-vector.
- `FogStore` (`struct`, `fog.rs`): Store of fog masks keyed by viewer ID.
- `LabelStore` (`struct`, `label.rs`): Store and lifecycle manager for globe labels.
- `LayerStore` (`struct`, `layer.rs`): Registry and lifecycle manager for globe layers.
- `MarkerStore` (`struct`, `marker.rs`): Store and lifecycle manager for globe markers.
- `PickResult` (`struct`, `picking.rs`): Result of a successful province pick operation.
- `OrbitCamera` (`struct`, `projection.rs`): Orbit camera controlling the viewpoint onto the globe.
- `Globe` (`struct`, `registry.rs`): Owns all domain stores for one named globe simulation.
- `GlobeRegistry` (`struct`, `registry.rs`): Named multi-globe manager.
- `ProvinceGraph` (`struct`, `topology.rs`): Complete province topology for one globe instance.
- `ProvinceId` (`type`, `types.rs`): Unique identifier for a province within a single globe instance.
- `Province` (`struct`, `types.rs`): A convex (or near-convex) polygon on the unit sphere, representing a province or region.
- `GlobeSpec` (`struct`, `types.rs`): Top-level configuration for one globe instance.
- `Marker` (`struct`, `types.rs`): A point of interest placed on the globe at a specific latitude/longitude.
- `MarkerStyle` (`struct`, `types.rs`): Visual style for a [`Marker`].
- `MarkerShape` (`enum`, `types.rs`): Primitive fallback shape for an icon-less marker.
- `Label` (`struct`, `types.rs`): A text annotation placed on the globe.
- `LabelStyle` (`struct`, `types.rs`): Visual style for a [`Label`].
- `Layer` (`struct`, `types.rs`): A named rendering layer that sits above the base province map.
- `LodTier` (`enum`, `types.rs`): Level-of-detail tier, selected based on camera zoom.
- `ProjectedProvince` (`struct`, `types.rs`): A province projected to screen space, ready for draw calls.
- `Arc` (`struct`, `types.rs`): A great-circle travel arc, projected to screen space.
- `GlobeError` (`enum`, `types.rs`): Errors returned by globe operations.

## Functions

- `emit_globe_frame` (`draw.rs`): Emit all render commands for one globe frame.
- `project_arc` (`draw.rs`): Pre-project a great-circle arc into a flat screenspace point list.
- `FogMask::all_hidden` (`fog.rs`): Create a new fog mask with all provinces hidden.
- `FogMask::all_visible` (`fog.rs`): Create a new fog mask with all provinces visible.
- `FogMask::is_visible` (`fog.rs`): Return whether province `id` is visible.
- `FogMask::reveal` (`fog.rs`): Mark province `id` as visible.
- `FogMask::hide` (`fog.rs`): Hide province `id`.
- `FogMask::toggle` (`fog.rs`): Toggle province `id`.
- `FogMask::reveal_batch` (`fog.rs`): Reveal all provinces in the iterator.
- `FogMask::visible_ids` (`fog.rs`): Return all currently-visible province IDs.
- `FogMask::from_visible_ids` (`fog.rs`): Deserialize from a list of visible province IDs (for `lurek.save.*` integration).
- `FogMask::count_visible` (`fog.rs`): Count visible provinces.
- `FogStore::new` (`fog.rs`): Create an empty store.
- `FogStore::get_or_insert` (`fog.rs`): Get or create the fog mask for a viewer.
- `FogStore::get` (`fog.rs`): Get an immutable fog mask for a viewer.
- `FogStore::is_visible` (`fog.rs`): Check if province `id` is visible to viewer `viewer`.
- `FogStore::reveal` (`fog.rs`): Reveal province `id` for viewer.
- `FogStore::hide` (`fog.rs`): Hide province `id` for viewer.
- `FogStore::visible_ids` (`fog.rs`): Return visible province IDs for viewer, or `None` if viewer has no mask.
- `FogStore::load` (`fog.rs`): Load visible IDs from save data.
- `FogStore::remove` (`fog.rs`): Remove a viewer's fog mask.
- `FogStore::viewers` (`fog.rs`): List all registered viewer IDs.
- `LabelStore::new` (`label.rs`): Create an empty store.
- `LabelStore::add` (`label.rs`): Add a label.
- `LabelStore::remove` (`label.rs`): Remove a label by ID.
- `LabelStore::get` (`label.rs`): Get an immutable reference.
- `LabelStore::get_mut` (`label.rs`): Get a mutable reference.
- `LabelStore::set_visible` (`label.rs`): Set label visibility.
- `LabelStore::set_text` (`label.rs`): Update label text.
- `LabelStore::move_to` (`label.rs`): Move label to a new position.
- `LabelStore::iter` (`label.rs`): Iterate over all labels.
- `LabelStore::iter_visible` (`label.rs`): Iterate over visible labels at or above the given LOD tier.
- `LabelStore::len` (`label.rs`): Number of labels.
- `LabelStore::is_empty` (`label.rs`): True if empty.
- `LayerStore::new` (`layer.rs`): Create an empty store.
- `LayerStore::add` (`layer.rs`): Add or replace a layer.
- `LayerStore::remove` (`layer.rs`): Remove a layer by name.
- `LayerStore::get` (`layer.rs`): Get an immutable reference to a layer.
- `LayerStore::get_mut` (`layer.rs`): Get a mutable reference to a layer.
- `LayerStore::set_province_color` (`layer.rs`): Set province color override in a layer.
- `LayerStore::clear_province_colors` (`layer.rs`): Clear all province color overrides from a layer.
- `LayerStore::set_visible` (`layer.rs`): Set layer visibility.
- `LayerStore::set_alpha` (`layer.rs`): Set layer opacity.
- `LayerStore::effective_color` (`layer.rs`): Get the effective color for a province across all visible layers.
- `LayerStore::visible_sorted` (`layer.rs`): Return all visible layers sorted by z_order.
- `LayerStore::len` (`layer.rs`): Number of layers.
- `LayerStore::is_empty` (`layer.rs`): True if empty.
- `sun_direction` (`lighting.rs`): Compute the sun direction as a world-space unit vector.
- `province_intensity` (`lighting.rs`): Compute the lighting intensity for a province centroid.
- `compute_intensities` (`lighting.rs`): Batch-compute light intensities for all provinces.
- `terminator_alpha` (`lighting.rs`): Compute a day/night terminator alpha for a province for a soft edge.
- `load_from_toml_str` (`loader.rs`): Parse a TOML province file from a string.
- `load_from_toml_file` (`loader.rs`): Load province data from the filesystem (synchronous).
- `load_from_png_file` (`loader.rs`): Load provinces from a color-indexed PNG.
- `MarkerStore::new` (`marker.rs`): Create an empty store.
- `MarkerStore::add` (`marker.rs`): Add a marker, assigning the next available ID.
- `MarkerStore::remove` (`marker.rs`): Remove a marker by ID.
- `MarkerStore::get` (`marker.rs`): Get an immutable reference to a marker.
- `MarkerStore::get_mut` (`marker.rs`): Get a mutable reference to a marker.
- `MarkerStore::move_to` (`marker.rs`): Move a marker to a new lat/lon.
- `MarkerStore::set_visible` (`marker.rs`): Set marker visibility.
- `MarkerStore::set_attr` (`marker.rs`): Set a user attribute on a marker.
- `MarkerStore::get_attr` (`marker.rs`): Get a user attribute from a marker.
- `MarkerStore::iter` (`marker.rs`): Iterate over all markers.
- `MarkerStore::iter_visible` (`marker.rs`): Iterate over visible markers only.
- `MarkerStore::by_type` (`marker.rs`): All markers of a given type.
- `MarkerStore::len` (`marker.rs`): Number of markers.
- `MarkerStore::is_empty` (`marker.rs`): True if no markers are stored.
- `pick` (`picking.rs`): Pick the province at screen coordinate `(sx, sy)`.
- `OrbitCamera::clamp` (`projection.rs`): Clamp and normalise camera angles.
- `OrbitCamera::pan` (`projection.rs`): Pan by `delta_lat_deg` and `delta_lon_deg` (unscaled).
- `OrbitCamera::zoom_by` (`projection.rs`): Zoom by `factor` (multiplicative).
- `OrbitCamera::lod` (`projection.rs`): Select LOD tier based on zoom level.
- `build_view_matrix` (`projection.rs`): Build the composite rotation matrix for a frame.
- `project_point` (`projection.rs`): Project a single unit-sphere point through the view matrix to screen space.
- `project_province` (`projection.rs`): Project a province's boundary vertices.
- `project_point_with_z` (`projection.rs`): Project a lat/lon point to screen and also return the camera-space Z (for picking).
- `screen_delta_to_pan` (`projection.rs`): Convert a screen delta `(dx, dy)` in pixels to a globe pan `(delta_lat, delta_lon)`.
- `normalize_v3` (`projection.rs`): Normalize a `Vec3` (returns zero vector if near-zero length).
- `Globe::new` (`registry.rs`): Create a new globe with the given name and spec.
- `Globe::add_province` (`registry.rs`): Add a province.
- `Globe::remove_province` (`registry.rs`): Remove a province by ID.
- `Globe::get_province` (`registry.rs`): Get a shared reference to a province.
- `Globe::get_province_mut` (`registry.rs`): Get a mutable reference to a province.
- `Globe::province_count` (`registry.rs`): Number of provinces.
- `Globe::add_arc` (`registry.rs`): Add an arc (great-circle route).
- `Globe::remove_arc` (`registry.rs`): Remove an arc.
- `Globe::update` (`registry.rs`): Advance globe simulation by `dt` seconds (rotates the planet).
- `Globe::pick_screen` (`registry.rs`): Pick the province under a screen coordinate.
- `Globe::emit_frame` (`registry.rs`): Emit all render commands for this globe frame.
- `GlobeRegistry::new` (`registry.rs`): Create an empty registry.
- `GlobeRegistry::create` (`registry.rs`): Create a new globe and store it.
- `GlobeRegistry::get` (`registry.rs`): Get an immutable reference to a globe.
- `GlobeRegistry::get_mut` (`registry.rs`): Get a mutable reference to a globe.
- `GlobeRegistry::remove` (`registry.rs`): Remove and return a globe.
- `GlobeRegistry::names` (`registry.rs`): List all globe names.
- `GlobeRegistry::len` (`registry.rs`): Number of globes.
- `GlobeRegistry::is_empty` (`registry.rs`): True if no globes are registered.
- `ProvinceGraph::new` (`topology.rs`): Create an empty graph.
- `ProvinceGraph::insert` (`topology.rs`): Insert a province.
- `ProvinceGraph::remove` (`topology.rs`): Remove a province by ID.
- `ProvinceGraph::get` (`topology.rs`): Get an immutable reference to a province.
- `ProvinceGraph::get_mut` (`topology.rs`): Get a mutable reference to a province.
- `ProvinceGraph::iter` (`topology.rs`): Iterate over all provinces.
- `ProvinceGraph::len` (`topology.rs`): Number of provinces.
- `ProvinceGraph::is_empty` (`topology.rs`): True if the graph is empty.
- `ProvinceGraph::find_path` (`topology.rs`): Find the shortest path between two provinces.
- `ProvinceGraph::reachable` (`topology.rs`): Find all provinces reachable from `start` within `max_cost`.
- `ProvinceGraph::neighbors_of` (`topology.rs`): Return the direct neighbors of a province.
- `ProvinceGraph::set_attr` (`topology.rs`): Set a user attribute on a province.
- `ProvinceGraph::get_attr` (`topology.rs`): Get a user attribute from a province.
- `ProvinceGraph::find_path_default` (`topology.rs`): Convenience: find path using the default cost function (uniform cost 1.0).
- `ProvinceGraph::reachable_default` (`topology.rs`): Convenience: find reachable provinces using the default cost function.
- `ProvinceGraph::rebuild_caches` (`topology.rs`): Rebuild the neighbor + centroid caches from the current province set.
- `Province::new` (`types.rs`): Create a minimal province for unit tests.
- `Province::with_data` (`types.rs`): Create a province with explicit centroid, neighbors, and base color.
- `Layer::new` (`types.rs`): Construct a visible layer with full opacity.

## Lua API Reference

- Binding path(s): `src/lua_api/globe_api.rs`
- Namespace: `lurek.globe`

### Module Functions
- `lurek.globe.new`: Creates a new globe instance with default settings and empty collections.
- `lurek.globe.get`: Get an existing globe by name, or nil.
- `lurek.globe.loadFromTOML`: Load provinces from a TOML string and create a globe.
- `lurek.globe.greatCircleDistance`: Great-circle distance between two lat/lon points (in unit-sphere radians).
- `lurek.globe.greatCirclePath`: Great-circle path as a table of {lat, lon} pairs.
- `lurek.globe.latLonToUnit`: Convert lat/lon (degrees) to a unit-sphere Cartesian vector {x, y, z}.

### `Globe` Methods
- `Globe:addProvince`: Adds a province from a table {id, centroid={lat,lon}, vertices={{lat,lon},...},
- `Globe:removeProvince`: Removes a province by ID. Returns true if it existed.
- `Globe:provinceCount`: Returns the number of provinces.
- `Globe:getNeighbors`: Returns the neighbor IDs of a province.
- `Globe:getProvinceAttr`: Gets a string attribute from a province.
- `Globe:pan`: Pan the orbit camera by delta-latitude and delta-longitude (degrees).
- `Globe:zoom`: Zoom the camera by a multiplier (>1 zooms in, <1 zooms out).
- `Globe:setCamera`: Set the camera position directly.
- `Globe:getCamera`: Get the current camera (lat, lon, zoom).
- `Globe:getLod`: Returns the current LOD tier as a string: "far", "mid", or "near".
- `Globe:pick`: Returns the province ID under screen coordinates, or nil.
- `Globe:pickLatLon`: Returns (lat, lon) of the screen point on the globe surface, or nil.
- `Globe:setActiveViewer`: Set the faction/viewer whose fog mask filters rendering.
- `Globe:revealProvince`: Reveal a province for a viewer.
- `Globe:hideProvince`: Hide a province for a viewer.
- `Globe:isVisible`: Returns true if the province is visible to the viewer.
- `Globe:revealAll`: Reveal all provinces for a viewer.
- `Globe:removeMarker`: Removes a marker from the globe map by its unique string identifier.
- `Globe:moveMarker`: Move a marker to a new lat/lon.
- `Globe:setMarkerVisible`: Sets whether this specific marker is visible on the globe.
- `Globe:getMarkerAttr`: Get a string attribute from a marker.
- `Globe:setLabelText`: Updates the visible text content of an existing globe label.
- `Globe:setLabelVisible`: Sets whether this specific label is visible on the globe.
- `Globe:removeLabel`: Removes a text label from the globe map by its unique string identifier.
- `Globe:removeLayer`: Removes a texture layer from the globe map by its unique string identifier.
- `Globe:setLayerVisible`: Sets whether this specific texture layer is visible on the globe.
- `Globe:setLayerAlpha`: Set layer opacity (0.0–1.0).
- `Globe:setTimeOfDay`: Set time of day (0.0–24.0 hours).
- `Globe:getTimeOfDay`: Gets the current simulated time of day for daylight computation.
- `Globe:setRotation`: Set planet rotation (degrees).
- `Globe:update`: Advance globe simulation by dt seconds.
- `Globe:setBorders`: Enable or disable province border rendering.
- `Globe:findPath`: Find the shortest province path from `from_id` to `to_id`.
- `Globe:removeArc`: Removes an arc from the globe map by its unique string identifier.
- `Globe:getName`: Returns the string identifier name assigned to this globe instance.

### `GlobeRegistry` Methods
- `GlobeRegistry:get`: Get an existing globe by name, or nil.
- `GlobeRegistry:remove`: Removes a globe from the central registry by its string name.
- `GlobeRegistry:names`: Returns a table of all globe names.

## References

- `math`: Imports or references `src/math/`. Cross-group dependency from `Edge/Integration` into `Foundations`.
- `pathfind`: Imports or references `src/pathfind/`. Cross-group dependency from `Edge/Integration` into `Feature Systems`.
- `render`: Imports or references `src/render/`. Cross-group dependency from `Edge/Integration` into `Platform Services`.
- `runtime`: Imports or references `src/runtime/`. Cross-group dependency from `Edge/Integration` into `Core Runtime`.

## Notes

- **A-03**: All rendering is 2D. `DrawConvexFan` + `Polyline` + `Circle`. No new wgpu pipeline.
- **B-05**: Province maps use TOML (`[[province]]` arrays). JSON is acceptable for external map-editor interop.
- **MAX_PROVINCES = 8192**: Soft cap. Increase `FogMask::WORD_COUNT` and `MAX_PROVINCES` together.
- **Fog serialization**: `FogMask::visible_ids()` + `from_visible_ids()` pair is the recommended pattern for `lurek.save.*` integration.
- **Multi-globe**: `GlobeRegistry` stores `HashMap<String, Globe>`. Multiple globes are independent.
- **Font keys**: `emit_frame(default_font)` requires a `FontKey` from the engine's resource cache. Pass `None` to suppress all text.
