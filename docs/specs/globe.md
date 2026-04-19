# Module Spec: `globe`

## General Information

| Field        | Value |
|---|---|
| Module path  | `src/globe/` |
| Lua API      | `lurek.globe.*` |
| Spec version | 0.20.0 |
| Binding constraint | A-03 (2D draw calls only) |
| Plugin candidacy | No — core strategy simulation feature |

---

## Summary

`globe` is an XCOM UFO Defense 1994 Geoscape–style strategy globe — a projection-correct 2D rendering of a unit sphere divided into named, navigable provinces. It provides:

- Province topology (adjacency graph with A* path-finding and reachability analysis)
- Orbit camera (lat/lon pan, zoom, LOD tier)
- Day/night lighting with a soft terminator band
- Per-faction fog-of-war (bit-vector, zero-copy serialization)
- Named markers (cities, units, events) and text labels
- Thematic layers (political, terrain, heat-map color overlays)
- Arc rendering (great-circle routes, range rings)
- TOML province-map loader + PNG stub
- A thin `lurek.globe.*` Lua API

All rendering uses existing 2D `RenderCommand` variants (`DrawConvexFan`, `Polyline`, `Circle`, `Print`) — no new wgpu pipeline.

---

## Files

| File | Role |
|---|---|
| `src/globe/mod.rs` | Module declarations and re-exports |
| `src/globe/types.rs` | Core types: `Province`, `GlobeSpec`, `Marker`, `Label`, `Layer`, `LodTier`, `GlobeError`, `Arc`, `MAX_PROVINCES` |
| `src/globe/topology.rs` | `ProvinceGraph` — adjacency, A\* path-finding, reachability |
| `src/globe/projection.rs` | `OrbitCamera`, `build_view_matrix`, `project_province`, `project_point` |
| `src/globe/picking.rs` | Screen → province hit-test |
| `src/globe/lighting.rs` | Sun direction, per-province intensity, terminator |
| `src/globe/fog.rs` | `FogMask` (bit-vector) and `FogStore` (per-viewer) |
| `src/globe/loader.rs` | TOML and PNG province map loaders |
| `src/globe/marker.rs` | `MarkerStore` lifecycle manager |
| `src/globe/label.rs` | `LabelStore` lifecycle manager |
| `src/globe/layer.rs` | `LayerStore` with `effective_color` blending |
| `src/globe/draw.rs` | `emit_globe_frame` — produces `Vec<RenderCommand>` |
| `src/globe/registry.rs` | `Globe` (owns all sub-stores) + `GlobeRegistry` (named map) |
| `src/globe/IDEA.md` | Design notes and backlog |
| `src/lua_api/globe_api.rs` | Thin Lua wrapper, all `impl LuaUserData` |

---

## Types

### `Province`

```rust
pub struct Province {
    pub id: ProvinceId,          // u32
    pub vertices: Vec<(f32, f32)>, // (lat_deg, lon_deg) polygon
    pub centroid: (f32, f32),
    pub neighbors: Vec<ProvinceId>,
    pub attrs: HashMap<String, String>,
    pub edge_tags: HashMap<(ProvinceId, ProvinceId), HashSet<String>>,
    pub texture: Option<String>,
    pub base_color: [f32; 4],
}
```

### `GlobeSpec`

| Field | Type | Default | Description |
|---|---|---|---|
| `radius` | `f32` | `100.0` | Unit-sphere display radius (screen units) |
| `axial_tilt_deg` | `f32` | `23.5` | Planet axis tilt |
| `rotation_deg` | `f32` | `0.0` | Longitude rotation offset |
| `time_of_day` | `f32` | `12.0` | Hour (0–24), drives sun position |
| `render_borders` | `bool` | `true` | Draw province borders |
| `border_color` | `[f32;4]` | `[0.1, 0.1, 0.1, 0.8]` | Border line RGBA |
| `border_width` | `f32` | `1.0` | Border line width |
| `ambient` | `f32` | `0.15` | Minimum lighting level |

### `OrbitCamera`

| Field | Type | Default | Description |
|---|---|---|---|
| `lat_deg` | `f32` | `30.0` | Camera latitude (look-at) |
| `lon_deg` | `f32` | `0.0` | Camera longitude (look-at) |
| `zoom` | `f32` | `1.0` | Zoom multiplier (1.0 = standard) |
| `screen_cx` | `f32` | `640.0` | Screen centre X |
| `screen_cy` | `f32` | `360.0` | Screen centre Y |

### `LodTier`

| Value | Zoom threshold | Description |
|---|---|---|
| `Far` | zoom < 1.5 | Low detail — no borders, no labels |
| `Mid` | 1.5 ≤ zoom < 4.0 | Medium detail — borders + labels |
| `Near` | zoom ≥ 4.0 | High detail — full labels + markers |

### `FogMask`

Bit-vector for `MAX_PROVINCES` (8192) entries. 128 `u64` words. Per-province reveal/hide in O(1).

### `GlobeError`

```rust
pub enum GlobeError {
    ProvinceNotFound(u32),
    TooManyProvinces,
    LoadError(String),
    GlobeNotFound(String),
    NoPath(u32, u32),
}
```

---

## Functions

### Rust public API

#### `Globe`

| Method | Signature | Description |
|---|---|---|
| `new` | `(name, spec) → Globe` | Create a globe |
| `add_province` | `(&mut self, Province) → Result<(), GlobeError>` | Add province (cap: MAX_PROVINCES) |
| `remove_province` | `(&mut self, ProvinceId) → Option<Province>` | Remove province |
| `get_province` / `get_province_mut` | `(ProvinceId) → Option<&Province>` | Province access |
| `province_count` | `() → usize` | Number of provinces |
| `add_arc` / `remove_arc` | Arc lifecycle | Great-circle arc management |
| `update` | `(dt: f32)` | Advance time_of_day + rotation |
| `pick_screen` | `(sx, sy) → Option<PickResult>` | Screen-to-province hit test |
| `emit_frame` | `(Option<FontKey>) → Vec<RenderCommand>` | Produce render commands |

#### `ProvinceGraph`

| Method | Description |
|---|---|
| `insert(Province)` | Add province and rebuild caches |
| `remove(id) → Option<Province>` | Remove province |
| `find_path(from, to, cost_fn) → Result<ProvincePath, GlobeError>` | A* path |
| `find_path_default(from, to) → Option<ProvincePath>` | A* with uniform cost |
| `reachable(start, max_cost, cost_fn) → HashMap<u32, f64>` | Dijkstra flood fill |
| `reachable_default(start, max_cost) → HashMap<u32, f64>` | Flood fill with uniform cost |
| `rebuild_caches()` | Rebuild neighbor/centroid maps from province data |

#### `FogMask`

| Method | Description |
|---|---|
| `reveal(id)` / `hide(id)` | Single province |
| `reveal_batch(&[ProvinceId])` | Bulk reveal |
| `is_visible(id) → bool` | Visibility query |
| `visible_ids() → Vec<ProvinceId>` | All visible IDs |
| `from_visible_ids(&[ProvinceId]) → FogMask` | Reconstruct from list |

#### `draw::emit_globe_frame`

```rust
pub fn emit_globe_frame(
    spec: &GlobeSpec,
    camera: &OrbitCamera,
    graph: &ProvinceGraph,
    fog: &FogStore,
    markers: &MarkerStore,
    labels: &LabelStore,
    layers: &LayerStore,
    arcs: &HashMap<u32, Arc>,
    active_viewer: Option<&str>,
    default_font: Option<FontKey>,
) -> Vec<RenderCommand>
```

Render order: provinces → arcs → markers → labels.

---

## Lua API Reference

All functions and methods live under `lurek.globe`.

### Module-level

| Function | Returns | Description |
|---|---|---|
| `lurek.globe.new(name, spec?)` | `Globe` | Create a globe |
| `lurek.globe.get(name)` | `Globe?` | Retrieve existing globe |
| `lurek.globe.loadFromTOML(name, src, spec?)` | `Globe` | Create globe from TOML province map |
| `lurek.globe.greatCircleDistance(lat1, lon1, lat2, lon2)` | `number` | Radians |
| `lurek.globe.greatCirclePath(lat1, lon1, lat2, lon2, steps)` | `table` | `{lat, lon}` pairs |
| `lurek.globe.latLonToUnit(lat, lon)` | `{x, y, z}` | Unit sphere Cartesian |
| `lurek.globe.MAX_PROVINCES` | `number` | 8192 |
| `lurek.globe.LOD_FAR` / `LOD_MID` / `LOD_NEAR` | `string` | LOD tier constants |

### Globe instance methods

#### Province management
| Method | Description |
|---|---|
| `g:addProvince(t)` | Add province from table `{id, centroid, vertices, neighbors, base_color}` |
| `g:removeProvince(id)` | Remove province, returns `boolean` |
| `g:provinceCount()` | Number of provinces |
| `g:getNeighbors(id)` | Returns `table<integer>` |
| `g:setProvinceAttr(id, key, val)` | Set string attribute |
| `g:getProvinceAttr(id, key)` | Get string attribute, or `nil` |

#### Camera
| Method | Description |
|---|---|
| `g:setCamera(lat, lon, zoom)` | Set camera directly |
| `g:getCamera()` | Returns `lat, lon, zoom` |
| `g:pan(dlat, dlon)` | Delta-pan in degrees |
| `g:zoom(factor)` | Multiply zoom |
| `g:getLod()` | Returns `"far"`, `"mid"`, or `"near"` |

#### Picking
| Method | Description |
|---|---|
| `g:pick(sx, sy)` | Province ID at screen point, or `nil` |
| `g:pickLatLon(sx, sy)` | `lat, lon` at screen point, or `nil` |

#### Fog of war
| Method | Description |
|---|---|
| `g:setActiveViewer(viewer?)` | Set fog mask filter for rendering |
| `g:revealProvince(viewer, id)` | Reveal province |
| `g:hideProvince(viewer, id)` | Hide province |
| `g:isVisible(viewer, id)` | `boolean` |
| `g:revealAll(viewer)` | Reveal all provinces |

#### Markers
| Method | Description |
|---|---|
| `g:addMarker(type, lat, lon, label?)` | Returns marker ID |
| `g:removeMarker(id)` | Returns `boolean` |
| `g:moveMarker(id, lat, lon)` | Returns `boolean` |
| `g:setMarkerVisible(id, visible)` | Returns `boolean` |
| `g:setMarkerAttr(id, key, val)` | Set string attribute |
| `g:getMarkerAttr(id, key)` | Get string attribute, or `nil` |

#### Labels
| Method | Description |
|---|---|
| `g:addLabel(type, lat, lon, text)` | Returns label ID |
| `g:setLabelText(id, text)` | Returns `boolean` |
| `g:setLabelVisible(id, visible)` | Returns `boolean` |
| `g:removeLabel(id)` | Returns `boolean` |

#### Layers
| Method | Description |
|---|---|
| `g:addLayer(name, z_order?)` | `true` if replaced existing |
| `g:removeLayer(name)` | Returns `boolean` |
| `g:setLayerColor(layer, id, r, g, b, a)` | Per-province color override |
| `g:setLayerVisible(name, visible)` | Returns `boolean` |
| `g:setLayerAlpha(name, alpha)` | Returns `boolean` |

#### Arcs
| Method | Description |
|---|---|
| `g:addArc(lat1, lon1, lat2, lon2, steps?)` | Returns arc ID |
| `g:removeArc(id)` | Returns `boolean` |

#### Path finding
| Method | Description |
|---|---|
| `g:findPath(from_id, to_id)` | Returns `table<integer>` (ordered IDs) or `nil` |
| `g:reachable(start_id, max_cost)` | Returns `table<id, cost>` |

#### Simulation
| Method | Description |
|---|---|
| `g:update(dt)` | Advance simulation by `dt` seconds |
| `g:setTimeOfDay(t)` | Set hours (0–24) |
| `g:getTimeOfDay()` | Returns `number` |
| `g:setRotation(deg)` | Set planet rotation |
| `g:setBorders(show)` | Toggle border rendering |
| `g:getName()` | Returns globe name |

---

## References

- [Lua API Reference](../API/lua-api.md)
- [Render Command Architecture](../architecture/render-command-architecture.md)
- [Pathfind Spec](pathfind.md)
- [Math Spec](math.md)
- [Save Spec](save.md) — `FogMask::visible_ids` / `from_visible_ids` for serialization

---

## Notes

- **A-03**: All rendering is 2D. `DrawConvexFan` + `Polyline` + `Circle`. No new wgpu pipeline.
- **B-05**: Province maps use TOML (`[[province]]` arrays). JSON is acceptable for external map-editor interop.
- **MAX_PROVINCES = 8192**: Soft cap. Increase `FogMask::WORD_COUNT` and `MAX_PROVINCES` together.
- **Fog serialization**: `FogMask::visible_ids()` + `from_visible_ids()` pair is the recommended pattern for `lurek.save.*` integration.
- **Multi-globe**: `GlobeRegistry` stores `HashMap<String, Globe>`. Multiple globes are independent.
- **Font keys**: `emit_frame(default_font)` requires a `FontKey` from the engine's resource cache. Pass `None` to suppress all text.
