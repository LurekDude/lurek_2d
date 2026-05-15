# globe

## General Info

- Module group: `Feature Systems`
- Source path: `src/globe/`
- Lua API path(s): `src/lua_api/globe_api.rs`
- Primary Lua namespace: `lurek.globe`
- Rust test path(s): None found in the workspace
- Lua test path(s): None found in the workspace

## Summary

The `globe` module provides an XCOM Geoscape-style 2D strategic globe view — a projection-correct rendering of a unit sphere divided into navigable named provinces. It is a Feature Systems tier module that works entirely through the engine's existing 2D `RenderCommand` variants (`DrawConvexFan`, `Polyline`, `Circle`, `Print`), adding no new wgpu pipeline or 3D draw calls (consistent with binding constraint A-03).

**Province topology.** `ProvinceGraph` stores adjacency lists keyed by `ProvinceId` (u32). Each `Province` carries a vertex polygon in lat/lon degrees, centroid coordinates, a neighbour list, a free-form attribute `HashMap`, per-edge tag sets, optional texture metadata, and a base RGBA colour. Up to `MAX_PROVINCES` (8192) provinces are supported per globe instance. `ProvinceGraph` supports A\* pathfinding between provinces, reachability analysis with configurable edge-tag filtering, and nearest-province queries for click-to-select interactions.

**Orbit camera.** `OrbitCamera` tracks lat/lon look-at position, zoom multiplier, and screen-centre offset. `build_view_matrix()` converts orbital parameters to the 2D projection matrix used by the draw pass. `project_province(id)` and `project_point(lat, lon)` map lat/lon coordinates to screen space under the current projection. `LodTier` (Far / Mid / Near) derives from zoom level and gates border detail, province label rendering, and marker rendering at three LOD levels so distant views stay uncluttered.

**Day/night lighting.** The sun direction derives from `GlobeSpec.time_of_day` (0–24 h) and an `axial_tilt_deg` field. Each province receives a scalar intensity value with a soft terminator band computed in `lighting.rs`. The `ambient` floor prevents night-side provinces from going fully dark. The intensity value is applied as a brightness multiplier to the province's effective colour at draw time.

**Fog of war.** `FogMask` now supports three states per province (`hidden`, `explored`, `visible`) and compact base64 serialization helpers for save/network transport. `FogStore` manages one `FogMask` per viewer entity, enabling multi-faction fog-of-war without per-frame heap allocation. Fog intensity modulates province colour independently of the day/night lighting multiplier.

**Markers, labels, and overlay layers.** `MarkerStore` and `LabelStore` manage point-of-interest and text overlays with lifecycle tracking: `add(id, lat, lon, data)`, `remove(id)`, `update(id, data)`. Marker styles include pulse and rotation animation fields. `LayerStore` plus `HeatLayer` overlays compute blended province colours from base colour, overlay contributions, fog intensity, and day/night multiplier.

**Texture + atmosphere rendering.** Province draw commands emit atlas-backed UVs (no empty UV payload) and optional per-province texture keys. Atmosphere halo commands are emitted around the visible hemisphere using 2D draw calls only.

**Procedural + tooling support.** `loader.rs` includes a real PNG province loader (ProvinceGrid-backed) plus Voronoi province generation helper. `export.rs` exports province polygons as OBJ text for procedural tools.

**Strategic hooks and grouping.** `Globe` supports sector grouping (`set_province_sector`), cached faction reachability maps, split-screen multi-globe composition helpers (`composition.rs`), and channel-based snapshot sync (`sync.rs`).

**Arc rendering.** `Arc` records great-circle routes or range-ring annotations between two lat/lon points. The draw module converts arcs to polyline sequences in screen space and emits `RenderCommand::Polyline` entries. Useful for trade routes, missile arcs, and influence boundaries.

**Province picking.** `picking.rs` provides screen-to-province hit-testing: `pick(screen_x, screen_y)` → `Option<ProvinceId>` using a convex-fan point-in-polygon test under the current projection. Used by click-to-select and hover-highlight interactions in Lua scripts.

**Loaders.** `loader.rs` parses TOML province-map files (province polygon lists, adjacency tables, attribute maps) and stub PNG province rasters. Both populate native `Globe` structures through `GlobeRegistry`. Provinces can also be constructed programmatically via the Lua API for procedurally generated maps.

**Registry.** `GlobeRegistry` manages multiple named globe instances (`create(name, spec)`, `get(name)`, `destroy(name)`). This allows games to maintain separate strategic maps (world map, regional view, star chart) as distinct instances.

**Lua surface.** `lurek.globe.create(name, spec)`, `destroy(name)`, `get(name)` → `Globe` userdata. `Globe` methods: `addProvince(def)`, `removeProvince(id)`, `setAdjacent(a, b)`, `findPath(a, b)`, `reachable(start, max_steps)`, `pickProvince(x, y)`, `setCamera(lat, lon, zoom)`, `setTime(hours)`, `setFog(faction, province, revealed)`, `addMarker(id, lat, lon, data)`, `addLabel(id, lat, lon, text)`, `addLayer(name)`, `setLayerColor(layer, province, color)`, `draw()`.

**Scope boundary.** Feature Systems tier. Depends on `render`, `math`, `runtime`, `image`. Lua bridge in `src/lua_api/globe_api.rs`.

## Files

- `composition.rs`: Split-screen composition across multiple globes.
- `draw.rs`: Frame emission for the globe module.
- `export.rs`: Province mesh export helpers (OBJ).
- `fog.rs`: Per-faction fog-of-war for the globe module.
- `label.rs`: Generic label store for the globe module.
- `layer.rs`: Named layer registry for the globe module.
- `lighting.rs`: Day/night lighting for the globe module.
- `loader.rs`: Province data loaders for the globe module.
- `marker.rs`: Generic marker store for the globe module.
- `mod.rs`: Globe module — XCOM-style Geoscape / Europa Universalis sphere.
- `picking.rs`: Screen-to-province hit-test for the globe module.
- `projection.rs`: Orthographic sphere projection and orbit camera for the globe module.
- `province_adapter.rs`: Globe ↔ province adapter (optional coupling layer).
- `registry.rs`: Globe registry — per-named-globe container and multi-globe manager.
- `sync.rs`: Channel-based globe snapshot synchronization.
- `topology.rs`: Province adjacency graph for the globe module.
- `types.rs`: Core value types for the globe module.

## Types

- `SplitViewport` (`struct`, `composition.rs`): Screen center override for one split viewport.
- `FogMask` (`struct`, `fog.rs`): Per-faction visibility bit-vector.
- `FogStore` (`struct`, `fog.rs`): Store of fog masks keyed by viewer ID.
- `LabelStore` (`struct`, `label.rs`): Store and lifecycle manager for globe labels.
- `LayerStore` (`struct`, `layer.rs`): Registry and lifecycle manager for globe layers.
- `MarkerStore` (`struct`, `marker.rs`): Store and lifecycle manager for globe markers.
- `PickResult` (`struct`, `picking.rs`): Result of a successful province pick operation.
- `OrbitCamera` (`struct`, `projection.rs`): Orbit camera controlling the viewpoint onto the globe.
- `Globe` (`struct`, `registry.rs`): Owns all domain stores for one named globe simulation.
- `GlobeRegistry` (`struct`, `registry.rs`): Named multi-globe manager.
- `GlobeSyncSnapshot` (`struct`, `sync.rs`): Serializable globe state used for snapshot transfer.
- `GlobeSyncChannel` (`struct`, `sync.rs`): Channel pair used to send and receive globe snapshots.
- `ProvinceGraph` (`struct`, `topology.rs`): Complete province topology for one globe instance.
- `ProvinceId` (`type`, `types.rs`): Unique identifier for a province within a single globe instance.
- `Province` (`struct`, `types.rs`): A convex (or near-convex) polygon on the unit sphere, representing a province or region.
- `FogState` (`enum`, `types.rs`): Fog-of-war state for a province.
- `HeatLayer` (`struct`, `types.rs`): Heat overlay parameters used by globe color mapping.
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

- `emit_split_frame` (`composition.rs`): Emit render commands for several globes with per-entry viewport centers.
- `emit_globe_frame` (`draw.rs`): Emit all render commands for one globe frame.
- `project_arc` (`draw.rs`): Pre-project a great-circle arc into a flat screenspace point list.
- `export_provinces_to_obj` (`export.rs`): Export province polygons as a flat OBJ string with one object per province.
- `FogMask::all_hidden` (`fog.rs`): Create a mask with every province hidden.
- `FogMask::all_visible` (`fog.rs`): Create a mask with every province visible.
- `FogMask::is_visible` (`fog.rs`): Return true when the province is visible.
- `FogMask::state` (`fog.rs`): Return the stored fog state for a province id.
- `FogMask::set_state` (`fog.rs`): Set the fog state for a province id when it is in range.
- `FogMask::reveal` (`fog.rs`): Mark a province as visible.
- `FogMask::hide` (`fog.rs`): Mark a province as hidden.
- `FogMask::explore` (`fog.rs`): Mark a province as explored.
- `FogMask::toggle` (`fog.rs`): Toggle a province between visible and hidden.
- `FogMask::reveal_batch` (`fog.rs`): Reveal every province in the supplied iterator.
- `FogMask::visible_ids` (`fog.rs`): Return all visible province ids in ascending order.
- `FogMask::explored_ids` (`fog.rs`): Return all explored province ids in ascending order.
- `FogMask::from_visible_ids` (`fog.rs`): Build a mask that reveals the supplied province ids.
- `FogMask::count_visible` (`fog.rs`): Count visible provinces in the mask.
- `FogMask::count_explored` (`fog.rs`): Count explored provinces in the mask.
- `FogMask::to_base64` (`fog.rs`): Encode the fog mask as base64 packed two-bit states.
- `FogMask::from_base64` (`fog.rs`): Decode a base64 encoded fog mask or return an error on invalid input.
- `FogStore::new` (`fog.rs`): Create an empty fog store.
- `FogStore::get_or_insert` (`fog.rs`): Return the mask for a viewer, inserting a hidden mask when absent.
- `FogStore::get` (`fog.rs`): Return the mask for a viewer when it exists.
- `FogStore::is_visible` (`fog.rs`): Return true when the viewer can see the province.
- `FogStore::reveal` (`fog.rs`): Reveal a province for a viewer.
- `FogStore::explore` (`fog.rs`): Mark a province as explored for a viewer.
- `FogStore::hide` (`fog.rs`): Hide a province for a viewer.
- `FogStore::visible_ids` (`fog.rs`): Return the visible province ids for a viewer when the viewer exists.
- `FogStore::explored_ids` (`fog.rs`): Return the explored province ids for a viewer when the viewer exists.
- `FogStore::state` (`fog.rs`): Return the state for a viewer or visible when the viewer has no mask.
- `FogStore::set_state` (`fog.rs`): Set the fog state for a viewer and province.
- `FogStore::to_base64` (`fog.rs`): Serialize a viewer mask to base64 when it exists.
- `FogStore::load_base64` (`fog.rs`): Load a viewer mask from base64 or return an error on invalid input.
- `FogStore::load` (`fog.rs`): Replace a viewer mask with one built from visible province ids.
- `FogStore::remove` (`fog.rs`): Remove the viewer mask if it exists.
- `FogStore::viewers` (`fog.rs`): Return all viewer names in arbitrary order.
- `LabelStore::new` (`label.rs`): Create an empty label store.
- `LabelStore::add` (`label.rs`): Insert a label and return its assigned id.
- `LabelStore::remove` (`label.rs`): Remove a label by id and return it when found.
- `LabelStore::get` (`label.rs`): Return a shared label reference when the id exists.
- `LabelStore::get_mut` (`label.rs`): Return a mutable label reference when the id exists.
- `LabelStore::set_visible` (`label.rs`): Set label visibility and return true when the id exists.
- `LabelStore::set_text` (`label.rs`): Replace label text and return true when the id exists.
- `LabelStore::move_to` (`label.rs`): Move a label to a new latitude and longitude and return true when it exists.
- `LabelStore::iter` (`label.rs`): Iterate over all stored labels.
- `LabelStore::iter_visible` (`label.rs`): Iterate over visible labels whose minimum LOD fits the supplied tier.
- `LabelStore::len` (`label.rs`): Return the number of stored labels.
- `LabelStore::is_empty` (`label.rs`): Return true when no labels are stored.
- `LayerStore::new` (`layer.rs`): Create an empty layer store.
- `LayerStore::add` (`layer.rs`): Insert a layer and return true when a layer with the same name was replaced.
- `LayerStore::remove` (`layer.rs`): Remove a layer by name and return it when found.
- `LayerStore::get` (`layer.rs`): Return a shared layer reference when the name exists.
- `LayerStore::get_mut` (`layer.rs`): Return a mutable layer reference when the name exists.
- `LayerStore::set_province_color` (`layer.rs`): Set a province color override for a layer and return true when the layer exists.
- `LayerStore::clear_province_colors` (`layer.rs`): Clear all province color overrides from a layer.
- `LayerStore::set_visible` (`layer.rs`): Set layer visibility and return true when the layer exists.
- `LayerStore::set_alpha` (`layer.rs`): Set layer alpha and clamp it to the 0..=1 range.
- `LayerStore::effective_color` (`layer.rs`): Resolve the effective province color by applying visible layers in z-order.
- `LayerStore::visible_sorted` (`layer.rs`): Return visible layers sorted by z-order.
- `LayerStore::len` (`layer.rs`): Return the number of stored layers.
- `LayerStore::is_empty` (`layer.rs`): Return true when no layers are stored.
- `sun_direction` (`lighting.rs`): Compute the sun direction as a world-space unit vector.
- `province_intensity` (`lighting.rs`): Compute the lighting intensity for a province centroid.
- `compute_intensities` (`lighting.rs`): Batch-compute light intensities for all provinces.
- `terminator_alpha` (`lighting.rs`): Compute a day/night terminator alpha for a province for a soft edge.
- `load_from_toml_str` (`loader.rs`): Parse a TOML province file from a string.
- `load_from_toml_file` (`loader.rs`): Load province data from the filesystem (synchronous).
- `load_from_png_file` (`loader.rs`): Load provinces from a color-indexed PNG.
- `generate_voronoi_provinces` (`loader.rs`): Generate approximate provinces from Voronoi input points.
- `MarkerStore::new` (`marker.rs`): Create an empty marker store.
- `MarkerStore::add` (`marker.rs`): Insert a marker and return its assigned id.
- `MarkerStore::remove` (`marker.rs`): Remove a marker by id and return it when found.
- `MarkerStore::get` (`marker.rs`): Return a shared marker reference when the id exists.
- `MarkerStore::get_mut` (`marker.rs`): Return a mutable marker reference when the id exists.
- `MarkerStore::move_to` (`marker.rs`): Move a marker and return true when the id exists.
- `MarkerStore::set_visible` (`marker.rs`): Set marker visibility and return true when the id exists.
- `MarkerStore::set_attr` (`marker.rs`): Set a string attribute and return true when the id exists.
- `MarkerStore::get_attr` (`marker.rs`): Return a string attribute for a marker when it exists.
- `MarkerStore::iter` (`marker.rs`): Iterate over all stored markers.
- `MarkerStore::iter_visible` (`marker.rs`): Iterate over visible markers only.
- `MarkerStore::by_type` (`marker.rs`): Return all markers whose type matches the supplied string.
- `MarkerStore::len` (`marker.rs`): Return the number of stored markers.
- `MarkerStore::is_empty` (`marker.rs`): Return true when no markers are stored.
- `pick` (`picking.rs`): Pick the province at screen coordinate `(sx, sy)`.
- `OrbitCamera::clamp` (`projection.rs`): Clamp camera latitude, longitude, and zoom into the supported range.
- `OrbitCamera::pan` (`projection.rs`): Pan the camera by latitude and longitude deltas.
- `OrbitCamera::zoom_by` (`projection.rs`): Multiply zoom by a factor and clamp the result.
- `OrbitCamera::lod` (`projection.rs`): Return the current level-of-detail tier for the zoom level.
- `build_view_matrix` (`projection.rs`): Build the composite rotation matrix for a frame.
- `project_point` (`projection.rs`): Project a single unit-sphere point through the view matrix to screen space.
- `project_province` (`projection.rs`): Project a province's boundary vertices.
- `project_point_with_z` (`projection.rs`): Project a lat/lon point to screen and also return the camera-space Z (for picking).
- `screen_delta_to_pan` (`projection.rs`): Convert a screen delta `(dx, dy)` in pixels to a globe pan `(delta_lat, delta_lon)`.
- `normalize_v3` (`projection.rs`): Normalize a `Vec3` (returns zero vector if near-zero length).
- `apply_political_colors` (`province_adapter.rs`): Applies political colors from a province registry onto matching globe provinces.
- `apply_visibility_to_viewer` (`province_adapter.rs`): Applies fog visibility from province registry to one globe viewer mask.
- `Globe::new` (`registry.rs`): Create a globe with the supplied name and spec.
- `Globe::add_province` (`registry.rs`): Insert a province or return TooManyProvinces when the graph is full.
- `Globe::remove_province` (`registry.rs`): Remove a province by id and return it when present.
- `Globe::get_province` (`registry.rs`): Return a shared province reference when the id exists.
- `Globe::get_province_mut` (`registry.rs`): Return a mutable province reference when the id exists.
- `Globe::province_count` (`registry.rs`): Return the number of stored provinces.
- `Globe::add_arc` (`registry.rs`): Insert an arc and return its assigned id.
- `Globe::remove_arc` (`registry.rs`): Remove an arc by id and return true when it existed.
- `Globe::update` (`registry.rs`): Advance simulation time and update the globe clock and rotation.
- `Globe::pick_screen` (`registry.rs`): Pick a province at screen coordinates or return None when no province matches.
- `Globe::emit_frame` (`registry.rs`): Emit render commands for the current globe state.
- `Globe::set_heat_layer` (`registry.rs`): Add or replace a heat layer by name.
- `Globe::remove_heat_layer` (`registry.rs`): Remove a heat layer by name and return true when one was removed.
- `Globe::set_province_sector` (`registry.rs`): Assign a province to a named sector.
- `Globe::province_sector` (`registry.rs`): Return the sector name that contains a province when one exists.
- `Globe::sector_provinces` (`registry.rs`): Return all province ids for a named sector.
- `Globe::cache_reachability_default` (`registry.rs`): Cache default reachability for a faction name.
- `Globe::cached_reachability` (`registry.rs`): Return cached reachability for a faction when present.
- `GlobeRegistry::new` (`registry.rs`): Create an empty globe registry.
- `GlobeRegistry::create` (`registry.rs`): Create or replace a globe and return a mutable reference to it.
- `GlobeRegistry::get` (`registry.rs`): Return a shared globe reference when the name exists.
- `GlobeRegistry::get_mut` (`registry.rs`): Return a mutable globe reference when the name exists.
- `GlobeRegistry::remove` (`registry.rs`): Remove a globe by name and return it when found.
- `GlobeRegistry::names` (`registry.rs`): Return all globe names in arbitrary order.
- `GlobeRegistry::len` (`registry.rs`): Return the number of stored globes.
- `GlobeRegistry::is_empty` (`registry.rs`): Return true when no globes are stored.
- `GlobeSyncChannel::new` (`sync.rs`): Create a new snapshot channel pair.
- `build_snapshot` (`sync.rs`): Build a snapshot from the current globe state.
- `apply_snapshot` (`sync.rs`): Apply a snapshot to a mutable globe instance.
- `ProvinceGraph::new` (`topology.rs`): Create an empty province graph.
- `ProvinceGraph::insert` (`topology.rs`): Insert a province and update the cached adjacency data.
- `ProvinceGraph::remove` (`topology.rs`): Remove a province and its cached data, returning the removed province when present.
- `ProvinceGraph::get` (`topology.rs`): Return a shared province reference when the id exists.
- `ProvinceGraph::get_mut` (`topology.rs`): Return a mutable province reference when the id exists.
- `ProvinceGraph::iter` (`topology.rs`): Iterate over all stored provinces.
- `ProvinceGraph::len` (`topology.rs`): Return the number of stored provinces.
- `ProvinceGraph::is_empty` (`topology.rs`): Return true when no provinces are stored.
- `ProvinceGraph::find_path` (`topology.rs`): Find a province path or return NoPath when no route exists.
- `ProvinceGraph::reachable` (`topology.rs`): Return provinces reachable within the supplied maximum cost.
- `ProvinceGraph::neighbors_of` (`topology.rs`): Return the cached neighbor slice for a province or an empty slice when missing.
- `ProvinceGraph::set_attr` (`topology.rs`): Set a province attribute or return ProvinceNotFound when the id is missing.
- `ProvinceGraph::get_attr` (`topology.rs`): Return a province attribute as a string slice when it exists.
- `ProvinceGraph::find_path_default` (`topology.rs`): Find a province path with the default cost function.
- `ProvinceGraph::reachable_default` (`topology.rs`): Return reachable provinces with the default cost function.
- `ProvinceGraph::rebuild_caches` (`topology.rs`): Rebuild all cached adjacency and edge-tag data from the stored provinces.
- `Province::new` (`types.rs`): Create a province from vertices and derive a centroid from them.
- `Province::with_data` (`types.rs`): Create a province from explicit cached data.
- `Layer::new` (`types.rs`): Create a visible overlay layer with the supplied name, kind, and z-order.

## Lua API Reference

- Binding path(s): `src/lua_api/globe_api.rs`
- Namespace: `lurek.globe`

### Module Functions
- `lurek.globe.new`: Creates a named globe with optional specification fields in the module registry.
- `lurek.globe.get`: Returns a globe from the module registry by name.
- `lurek.globe.loadFromTOML`: Creates a globe and populates provinces from TOML source text.
- `lurek.globe.loadFromPNG`: Creates a globe and populates provinces from a PNG file.
- `lurek.globe.generateVoronoi`: Creates a globe and populates provinces from latitude-longitude seed points.
- `lurek.globe.greatCircleDistance`: Computes great-circle distance between two latitude-longitude points.
- `lurek.globe.greatCirclePath`: Computes sampled latitude-longitude points along a great-circle path.
- `lurek.globe.latLonToUnit`: Converts latitude and longitude to a unit-sphere 3D vector table.

### `LGlobe` Methods
- `LGlobe:addProvince`: Adds a province described by id, centroid, vertices, neighbors, and optional base color.
- `LGlobe:removeProvince`: Removes a province by id.
- `LGlobe:provinceCount`: Returns the number of provinces in this globe.
- `LGlobe:getNeighbors`: Returns neighboring province ids for a province.
- `LGlobe:setProvinceAttr`: Sets a string attribute on a province.
- `LGlobe:getProvinceAttr`: Reads a string attribute from a province.
- `LGlobe:setProvinceTexture`: Assigns a raw texture handle and UV rectangle to a province.
- `LGlobe:clearProvinceTexture`: Removes texture metadata from a province.
- `LGlobe:setProvinceSector`: Assigns a province to a named sector.
- `LGlobe:getProvinceSector`: Returns the sector name assigned to a province.
- `LGlobe:getSectorProvinces`: Returns province ids assigned to a sector.
- `LGlobe:setHeatLayer`: Creates or replaces a heat layer that maps province attributes into colors.
- `LGlobe:removeHeatLayer`: Removes a heat layer by name.
- `LGlobe:pan`: Pans the globe camera by latitude and longitude deltas.
- `LGlobe:zoom`: Multiplies the globe camera zoom by a factor.
- `LGlobe:setCamera`: Sets camera latitude, longitude, and zoom.
- `LGlobe:getCamera`: Returns camera latitude, longitude, and zoom.
- `LGlobe:getLod`: Returns the camera-derived level-of-detail tier name.
- `LGlobe:pick`: Picks a province at screen coordinates.
- `LGlobe:pickRaycast`: Samples along a screen ray from the camera center and returns the first hit province.
- `LGlobe:pickLatLon`: Picks at screen coordinates and returns the hit province centroid screen coordinates.
- `LGlobe:setActiveViewer`: Sets the active fog-of-war viewer name or clears it.
- `LGlobe:setFogState`: Sets fog-of-war state for one viewer and province.
- `LGlobe:getFogState`: Returns fog-of-war state for one viewer and province.
- `LGlobe:encodeFogBase64`: Serializes one viewer's fog state to a base64 string.
- `LGlobe:decodeFogBase64`: Loads one viewer's fog state from a base64 string.
- `LGlobe:revealProvince`: Reveals a province for one fog-of-war viewer.
- `LGlobe:hideProvince`: Hides a province for one fog-of-war viewer.
- `LGlobe:isVisible`: Returns whether a province is visible for one fog-of-war viewer.
- `LGlobe:revealAll`: Reveals every province for one fog-of-war viewer.
- `LGlobe:addMarker`: Adds a marker at latitude and longitude with an optional label.
- `LGlobe:removeMarker`: Removes a marker by id.
- `LGlobe:moveMarker`: Moves a marker to latitude and longitude coordinates.
- `LGlobe:setMarkerVisible`: Shows or hides a marker.
- `LGlobe:setMarkerPulse`: Sets marker pulse frequency and amplitude.
- `LGlobe:setMarkerRotation`: Sets marker rotation speed.
- `LGlobe:setMarkerAttr`: Sets a string attribute on a marker.
- `LGlobe:getMarkerAttr`: Reads a string attribute from a marker.
- `LGlobe:addLabel`: Adds a text label at latitude and longitude.
- `LGlobe:setLabelText`: Changes text for an existing label.
- `LGlobe:setLabelVisible`: Shows or hides a label.
- `LGlobe:removeLabel`: Removes a label by id.
- `LGlobe:addLayer`: Adds a render layer with optional z-order.
- `LGlobe:removeLayer`: Removes a render layer by name.
- `LGlobe:setLayerColor`: Sets a province color override inside a render layer.
- `LGlobe:setLayerVisible`: Shows or hides a render layer.
- `LGlobe:setLayerAlpha`: Sets render layer alpha.
- `LGlobe:setTimeOfDay`: Sets globe time of day modulo 24 hours.
- `LGlobe:getTimeOfDay`: Returns globe time of day.
- `LGlobe:setRotation`: Sets globe rotation angle.
- `LGlobe:setAutoRotationSpeed`: Sets automatic globe rotation speed.
- `LGlobe:update`: Advances globe simulation timers and animated state.
- `LGlobe:setBorders`: Enables or disables province border rendering.
- `LGlobe:findPath`: Finds a default-cost province path between two province ids.
- `LGlobe:reachable`: Returns provinces reachable from a start province within a cost budget.
- `LGlobe:cacheReachability`: Caches default-cost reachability for a named faction.
- `LGlobe:getCachedReachability`: Returns cached reachability costs for a faction.
- `LGlobe:exportProvinceMeshOBJ`: Exports province geometry as Wavefront OBJ text.
- `LGlobe:addArc`: Adds a visible route arc between two latitude and longitude points.
- `LGlobe:removeArc`: Removes an arc by id.
- `LGlobe:getName`: Returns the registry name of this globe.
- `LGlobe:type`: Returns the Lua-visible type name for this globe handle.
- `LGlobe:typeOf`: Returns whether this globe handle matches a supported type name.

### `LGlobeRegistry` Methods
- `LGlobeRegistry:new`: Creates a named globe with optional specification fields.
- `LGlobeRegistry:get`: Returns a globe handle by registry name.
- `LGlobeRegistry:remove`: Removes a globe from the registry by name.
- `LGlobeRegistry:names`: Returns all globe names currently stored in this registry.
- `LGlobeRegistry:type`: Returns the Lua-visible type name for this globe registry handle.
- `LGlobeRegistry:typeOf`: Returns whether this registry handle matches a supported type name.

## References

- `image`: Imports or references `src/image/`. Cross-group dependency from `Feature Systems` into `Platform Services`.
- `math`: Imports or references `src/math/`. Cross-group dependency from `Edge/Integration` into `Foundations`.
- `pathfind`: Imports or references `src/pathfind/`. Cross-group dependency from `Edge/Integration` into `Feature Systems`.
- `province`: Imports or references `src/province/`. Cross-group dependency from `Feature Systems` into `Edge/Integration`.
- `render`: Imports or references `src/render/`. Cross-group dependency from `Edge/Integration` into `Platform Services`.
- `runtime`: Imports or references `src/runtime/`. Cross-group dependency from `Edge/Integration` into `Core Runtime`.

## Notes

- **A-03**: All rendering is 2D. `DrawConvexFan` + `Polyline` + `Circle`. No new wgpu pipeline.
- **B-05**: Province maps use TOML (`[[province]]` arrays). JSON is acceptable for external map-editor interop.
- **MAX_PROVINCES = 8192**: Soft cap. Increase `FogMask::WORD_COUNT` and `MAX_PROVINCES` together.
- **Fog serialization**: `FogMask::visible_ids()` + `from_visible_ids()` pair is the recommended pattern for `lurek.save.*` integration.
- **Multi-globe**: `GlobeRegistry` stores `HashMap<String, Globe>`. Multiple globes are independent.
- **Font keys**: `emit_frame(default_font)` requires a `FontKey` from the engine's resource cache. Pass `None` to suppress all text.
