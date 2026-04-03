# `province_map` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Gameplay Systems |
| **Lua API** | `luna.province_map` |
| **Source** | `src/province_map/` |
| **Tests** | `tests/province_map_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_province_map.lua` |

## Summary

The province_map module represents a game world as a set of named, coloured
provinces derived from a colour-coded PNG image.  Each pixel in the source
image belongs to one province identified by its RGB colour; the loader assigns
a unique integer ID to each distinct colour, computes the pixel-counted area
and approximate centroid, and builds the adjacency graph by scanning
horizontally and vertically adjacent pixel pairs for colour changes.  This
makes it straightforward to create strategy-game style political maps, region
ownership systems, or territory-based progression mechanics entirely from an
artist's painted bitmap with no manual data entry.

The module deliberately holds only spatial data: province IDs, pixel areas,
centroids, and adjacency edges.  All game-specific meaning (owner, terrain
type, resource output, political alignment) lives elsewhere — in `stats/`,
`entity/`, or Lua tables — attached to the integer province IDs.  This keeps
the core map data pure and reusable across multiple game contexts from the same
source image.

Import from definitions (`definition_loader`) supports logic-only province maps
with no pixel data: a table of province names, neighbour lists, and colours
builds the same `ProvinceMap` structure for procedurally generated or
hand-authored province topologies.  Border extraction (`borders`) converts
adjacency pixel lists into ordered polylines for rendering province outlines at
arbitrary thicknesses.  The `graph_bridge` module converts the province
adjacency into a `crate::graph::Graph` so Dijkstra pathfinding and flow
simulation over the province network can be used without re-implementing graph
algorithms.

## Architecture

```
ProvinceMap (main data container)
  │
  ├── provinces: HashMap<u32, Province>
  │     ├── id: u32 (unique, derived from RGB)
  │     ├── color: (u8, u8, u8) (original pixel colour)
  │     ├── name: String
  │     ├── pixel_count: u32 (area in pixels)
  │     ├── center_x/y: f32 (centroid)
  │     └── extra: HashMap<String, String> (user metadata)
  │
  ├── adjacency: Vec<AdjacencyEdge>
  │     ├── province_a, province_b (u32 IDs)
  │     ├── touch_count (shared pixel boundary length)
  │     ├── border_pixels: Vec<(u32,u32)> (pixel coordinates)
  │     └── tags: Vec<String> (semantic labels, e.g. "river")
  │
  ├── Loaders
  │     ├── loader.rs ── parse PNG into ProvinceMap
  │     └── definition_loader.rs ── build from hand-authored tables
  │
  ├── Geometry / Rendering helpers
  │     ├── borders.rs ── extract ordered polylines for province outlines
  │     ├── positions.rs ── auto-compute centroid positions
  │     └── map_mode.rs ── colour resolution for rendering passes
  │
  └── Integration
        ├── graph_bridge.rs ── build Graph from adjacency (Dijkstra support)
        └── events.rs ── ProvinceMapEventBus for lifecycle events
```

## Source Files

| File | Purpose |
|------|---------|
| `adjacency.rs` | Adjacency detection between provinces from the pixel grid |
| `borders.rs` | Border segment extraction for province rendering |
| `core.rs` | Core province map data structures: [`Province`], [`AdjacencyEdge`], and... |
| `definition_loader.rs` | Province definition loader — build a [`ProvinceMap`] from structured data |
| `events.rs` | Event bus for province map lifecycle events |
| `graph_bridge.rs` | Bridge between province map adjacency and the [`crate::graph`] module |
| `loader.rs` | Province map loader: parses colour-coded PNG images into [`ProvinceMap`] |
| `map_mode.rs` | Map mode colour resolution for province map rendering |
| `positions.rs` | Auto-position calculation for province centers |

## Submodules

### `province_map::adjacency`

Adjacency detection between provinces from the pixel grid.

- **`detect_adjacency`** (fn): Detect province adjacencies from the pixel grid using a single-pass scan.  For every pixel, the right `(x+1, y)` and...
- **`detect_adjacency_with_tags`** (fn): Detect province adjacencies with optional tagged-pixel detection.  Operates identically to [`detect_adjacency`], but...

### `province_map::borders`

Border segment extraction for province rendering.

- **`BorderStyle`** (struct): Visual style for a border line. Consult the module-level documentation for the broader usage context and preconditions.
- **`BorderSegment`** (struct): A border segment as a list of pixel coordinates forming a polyline.
- **`extract_all_borders`** (fn): Convert all adjacency edge border segments into ordered polylines.  Each adjacency edge with border pixel data produces...
- **`extract_borders_with_tag`** (fn): Extract only borders that have a specific tag.  Use this to get e.g. all river borders, wall borders, etc.
- **`extract_borders_by_property`** (fn): Extract borders where the two provinces have different group values.  The caller supplies a function that maps province...

### `province_map::core`

Core province map data structures: [`Province`], [`AdjacencyEdge`], and [`ProvinceMap`].

- **`ProvinceError`** (enum): Error type for province map operations. Consult the module-level documentation for the broader usage context and...
- **`Province`** (struct): A single province in a province map. Consult the module-level documentation for the broader usage context and...
- **`AdjacencyEdge`** (struct): An edge between two adjacent provinces. Consult the module-level documentation for the broader usage context and...
- **`ProvinceMap`** (struct): The complete province map — contains all provinces and their relationships.  Provinces are indexed by their...

### `province_map::definition_loader`

Province definition loader — build a [`ProvinceMap`] from structured data.

- **`ProvinceDefinition`** (struct): A single province definition with metadata and neighbour list.
- **`load_from_definitions`** (fn): Build a [`ProvinceMap`] from a list of province definitions.  Creates a logical-only province map (no pixel data) from...

### `province_map::events`

Event bus for province map lifecycle events.

- **`ProvinceMapEventBus`** (struct): Event bus for province map events. Consult the module-level documentation for the broader usage context and...

### `province_map::graph_bridge`

Bridge between province map adjacency and the [`crate::graph`] module.

- **`adjacency_to_graph`** (fn): Convert province map adjacency into a [`Graph`].  Each province becomes a node (type `"province"`, capacity 0). Each...

### `province_map::loader`

Province map loader: parses colour-coded PNG images into [`ProvinceMap`].

- **`color_to_id`** (fn): Convert an RGB colour triple to a province ID.  The encoding is `(r << 16) | (g << 8) | b`, giving up to ~16 M unique...

### `province_map::map_mode`

Map mode colour resolution for province map rendering.

- **`MapMode`** (struct): A named map mode with its colour assignment function.
- **`MapModeColorFn`** (enum): How colours are assigned to provinces. Consult the module-level documentation for the broader usage context and...
- **`resolve_colors`** (fn): Resolve colours for every pixel in the map, producing an RGBA pixel buffer.  Pixels that belong to province ID 0...

### `province_map::positions`

Auto-position calculation for province centers.

- **`calculate_capital`** (fn): Find a good interior position for a province center.  Uses an approximate distance-from-edge approach: samples points...
- **`calculate_all_positions`** (fn): Compute and set the `center` field for all provinces.  Finds the best interior point for each province using...

## Key Types

### Structs

#### `province_map::core::AdjacencyEdge`

An edge between two adjacent provinces. Consult the module-level documentation for the broader usage context and...

#### `province_map::borders::BorderSegment`

A border segment as a list of pixel coordinates forming a polyline.

#### `province_map::borders::BorderStyle`

Visual style for a border line. Consult the module-level documentation for the broader usage context and preconditions.

#### `province_map::map_mode::MapMode`

A named map mode with its colour assignment function.

#### `province_map::core::Province`

A single province in a province map. Consult the module-level documentation for the broader usage context and...

#### `province_map::definition_loader::ProvinceDefinition`

A single province definition with metadata and neighbour list.

#### `province_map::core::ProvinceMap`

The complete province map — contains all provinces and their relationships.  Provinces are indexed by their...

#### `province_map::events::ProvinceMapEventBus`

Event bus for province map events. Consult the module-level documentation for the broader usage context and...

### Enums

#### `province_map::map_mode::MapModeColorFn`

How colours are assigned to provinces. Consult the module-level documentation for the broader usage context and...

#### `province_map::core::ProvinceError`

Error type for province map operations. Consult the module-level documentation for the broader usage context and...

## Public Functions

- **`adjacency_to_graph()`** `graph_bridge::` — Convert province map adjacency into a [`Graph`].  Each province becomes a node (type `"province"`, capacity 0). Each...
- **`calculate_all_positions()`** `positions::` — Compute and set the `center` field for all provinces.  Finds the best interior point for each province using...
- **`calculate_capital()`** `positions::` — Find a good interior position for a province center.  Uses an approximate distance-from-edge approach: samples points...
- **`color_to_id()`** `loader::` — Convert an RGB colour triple to a province ID.  The encoding is `(r << 16) | (g << 8) | b`, giving up to ~16 M unique...
- **`detect_adjacency()`** `adjacency::` — Detect province adjacencies from the pixel grid using a single-pass scan.  For every pixel, the right `(x+1, y)` and...
- **`detect_adjacency_with_tags()`** `adjacency::` — Detect province adjacencies with optional tagged-pixel detection.  Operates identically to [`detect_adjacency`], but...
- **`extract_all_borders()`** `borders::` — Convert all adjacency edge border segments into ordered polylines.  Each adjacency edge with border pixel data produces...
- **`extract_borders_by_property()`** `borders::` — Extract borders where the two provinces have different group values.  The caller supplies a function that maps province...
- **`extract_borders_with_tag()`** `borders::` — Extract only borders that have a specific tag.  Use this to get e.g. all river borders, wall borders, etc.
- **`load_from_definitions()`** `definition_loader::` — Build a [`ProvinceMap`] from a list of province definitions.  Creates a logical-only province map (no pixel data) from...
- **`resolve_colors()`** `map_mode::` — Resolve colours for every pixel in the map, producing an RGBA pixel buffer.  Pixels that belong to province ID 0...

## Lua API

Exposed under `luna.province_map.*` by `src/lua_api/province_map_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 2 |
| `fn` | 11 |
| `mod` | 9 |
| `struct` | 8 |
| **Total** | **30** |

