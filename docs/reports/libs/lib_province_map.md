# `library.province_map`

*81 functions, 0 module fields documented.*

## Functions

### `newProvince(id, color)`

Create a new province.

**Parameters**

- `id` *number* — Unique province ID (from RGB colour).
- `color` *table* — {r, g, b} colour table.

**Returns**

- *Province*

### `setFaction(f)`

Set the faction that controls this province.

**Parameters**

- `f` *string|nil*

### `getFaction()`

Get the controlling faction.

**Returns**

- *string|nil*

### `setDefenseRating(v)`

Set the defense rating (0–100).

**Parameters**

- `v` *number*

### `getDefenseRating()`

Get the defense rating.

**Returns**

- *number*

### `addBuilding(b)`

Add a building to this province.

**Parameters**

- `building` *string*

### `getBuildings()`

Get all buildings.

**Returns**

- *table*

### `hasBuilding(b)`

Return true if the province has the given building.

**Parameters**

- `b` *string*

**Returns**

- *boolean*

### `removeBuilding(b)`

Remove a building by name. Returns true if removed.

**Parameters**

- `b` *string*

**Returns**

- *boolean*

### `setResource(res, amount)`

Set a produced resource amount.

**Parameters**

- `res` *string*
- `amount` *number*

### `getResource(res)`

Get a produced resource amount (0 if not set).

**Parameters**

- `res` *string*

**Returns**

- *number*

### `getResources()`

Get the full resource table.

**Returns**

- *table*

### `newAdjacencyEdge(province_a, province_b)`

Create a new adjacency edge between two provinces.

**Parameters**

- `province_a` *number*
- `province_b` *number*

**Returns**

- *table*

### `addEdgeTag(edge, tag)`

Add a tag to an adjacency edge.

**Parameters**

- `edge` *table*
- `tag` *string*

### `removeEdgeTag(edge, tag)`

Remove a tag from an adjacency edge.

**Parameters**

- `edge` *table*
- `tag` *string*

### `hasEdgeTag(edge, tag)`

Check if an adjacency edge has a tag.

**Parameters**

- `edge` *table*
- `tag` *string*

**Returns**

- *boolean*

### `newProvinceDefinition(id, color, center)`

Create a province definition (lightweight descriptor for map building).

**Parameters**

- `id` *number*
- `color` *table*
- `center` *table* — {x, y}

**Returns**

- *table*

### `newBorderSegment(province_a, province_b)`

Create a border segment between two provinces.

**Parameters**

- `province_a` *number*
- `province_b` *number*

**Returns**

- *table*

### `newBorderStyle()`

Create a border style descriptor.

**Returns**

- *table*

### `newFixedColorFn(province_colors)`

Create a fixed colour map mode (each province has a fixed colour).

**Parameters**

- `province_colors` *table* — {[id] = {r, g, b}}

**Returns**

- *table*

### `newGradientColorFn(values, min_color, max_color, min_val, max_val)`

Create a gradient colour map mode.

**Parameters**

- `values` *table* — {[id] = number}
- `min_color` *table* — {r, g, b}
- `max_color` *table* — {r, g, b}
- `min_val` *number*
- `max_val` *number*

**Returns**

- *table*

### `applyGradientColor(fn, id)`

Apply a gradient colour function to a province, returning a {r,g,b} colour.

**Parameters**

- `fn` *table* — gradient colour function
- `id` *number* — province id

**Returns**

- *table* — {r, g, b}

### `newCategoryColorFn(categories, colors, default_color)`

Create a category colour map mode.

**Parameters**

- `categories` *table* — {[id] = category_string}
- `colors` *table* — {[category_string] = {r, g, b}}
- `default_color` *table* — {r, g, b}

**Returns**

- *table*

### `applyCategoryColor(fn, id)`

Apply a category colour function to a province.

**Parameters**

- `fn` *table* — category colour function
- `id` *number* — province id

**Returns**

- *table* — {r, g, b}

### `newMapMode(name, color_fn)`

Create a named map mode.

**Parameters**

- `name` *string*
- `color_fn` *table|string*

**Returns**

- *table*

### `newProvinceMap(width, height)`

Create a new empty province map.

**Parameters**

- `width` *number* — pixel width
- `height` *number* — pixel height

**Returns**

- *ProvinceMap*

### `width()`

Return the map width in pixels.

**Returns**

- *number*

### `height()`

Return the map height in pixels.

**Returns**

- *number*

### `insertProvince(province)`

Insert or replace a province.

**Parameters**

- `province` *Province*

### `removeProvince(id)`

Remove a province by ID. Returns true if it existed.

**Parameters**

- `id` *number*

**Returns**

- *boolean*

### `getProvince(id)`

Look up a province by ID.

**Parameters**

- `id` *number*

**Returns**

- *Province|nil*

### `provinceCount()`

Return the total number of provinces.

**Returns**

- *number*

### `provinceIds()`

Return a sorted list of all province IDs.

**Returns**

- *table*

### `setPixel(x, y, province_id)`

Set pixel at (x, y) to the given province ID. Coordinates are 0-based.  Internally stored in `pixel_lookup` at 1-based index `y * width + x + 1` (standard Lua array convention). After writing the pixel, adjacency edges are updated bidirectionally by checking all four cardinal neighbours.

**Parameters**

- `x` *number* — 0-based pixel column.
- `y` *number* — 0-based pixel row.
- `province_id` *number* — Province ID to assign to this pixel.

### `getProvinceAt(x, y)`

Return the province ID at pixel (x, y). Coordinates are 0-based.  Returns nil for out-of-bounds queries.

**Parameters**

- `x` *number* — 0-based pixel column.
- `y` *number* — 0-based pixel row.

**Returns**

- *number|nil* — Province ID or nil.

### `insertAdjacency(edge)`

Insert an adjacency edge. Edge fields `province_a` / `province_b` are normalised on insertion so that `province_a <= province_b`, matching `adj_key` sort order.

**Parameters**

- `edge` *table* — AdjacencyEdge.

### `removeAdjacency(a, b)`

Remove an adjacency edge. Returns true if removed.

**Parameters**

- `a` *number*
- `b` *number*

**Returns**

- *boolean*

### `getAdjacency(a, b)`

Get the adjacency edge between two provinces.

**Parameters**

- `a` *number*
- `b` *number*

**Returns**

- *table|nil*

### `adjacencyCount()`

Return the total number of adjacency edges.

**Returns**

- *number*

### `getNeighbors(id)`

Return a sorted list of neighbour province IDs for the given province.

**Parameters**

- `id` *number*

**Returns**

- *table*

### `setAdjacent(a, b, tags)`

Set adjacency between two provinces (creates or updates edge). The edge is stored with normalised province IDs (`province_a <= province_b`). Neighbours can always be queried via `getNeighbors(id)` which scans the adjacency table — there is no separate neighbours list to keep in sync.

**Parameters**

- `a` *number* — First province ID.
- `b` *number* — Second province ID.
- `tags` *table* — Optional {tag=true, ...} to merge into the edge.

**Returns**

- *table* — The created or updated AdjacencyEdge.

### `distance(a, b)`

Euclidean centroid distance between two provinces.

**Parameters**

- `a` *number*
- `b` *number*

**Returns**

- *number*

### `pixelLookup()`

Return the raw pixel-lookup table.

**Returns**

- *table*

### `findRoute(from_id, to_id, passable_fn)`

BFS route from province `from_id` to `to_id`. Returns an ordered list of province IDs forming the path, or nil if unreachable. Passable edges (passable == true) and optional cost filter are respected.

**Parameters**

- `from_id` *number*
- `to_id` *number*
- `passable_fn` *function|nil* — passable_fn(edge) → boolean (nil = all passable)

**Returns**

- *table|nil* — ordered province ID list including from_id and to_id

### `getProvincesByFaction(faction)`

Return all province IDs controlled by the given faction.

**Parameters**

- `faction` *string*

**Returns**

- *table* — sorted list of province IDs

### `totalResourceForFaction(faction, resource)`

Sum a resource across all provinces belonging to a faction.

**Parameters**

- `faction` *string*
- `resource` *string*

**Returns**

- *number*

### `getUncontrolledProvinces()`

Get all provinces whose faction field is nil (uncontrolled).

**Returns**

- *table* — sorted list of province IDs

### `findIsolatedProvinces()`

Get all provinces with no adjacency edges (isolated islands).

**Returns**

- *table* — sorted list of province IDs

### `getConnectedComponents()`

Get connected components (list of lists of province IDs).

**Returns**

- *table* — list of component tables (sorted IDs inside each)

### `newEventBus()`

Create a new event bus for province map events.

**Returns**

- *EventBus*

### `emitMapLoaded(count)`

Emit a map-loaded event with province count.

**Parameters**

- `count` *number*

### `emitProvinceAdded(id)`

Emit a province-added event.

**Parameters**

- `id` *number*

### `emitProvinceRemoved(id)`

Emit a province-removed event.

**Parameters**

- `id` *number*

### `emitAdjacencyDetected(edge_count)`

Emit adjacency-detected with edge count.

**Parameters**

- `edge_count` *number*

### `emitAdjacencyChanged(a, b)`

Emit adjacency-changed for two provinces.

**Parameters**

- `a` *number*
- `b` *number*

### `emitAdjacencyRemoved(a, b)`

Emit adjacency-removed for two provinces.

**Parameters**

- `a` *number*
- `b` *number*

### `emitBordersExtracted(count)`

Emit borders-extracted with segment count.

**Parameters**

- `count` *number*

### `emitMapModeApplied(name)`

Emit map-mode-applied with mode name.

**Parameters**

- `name` *string*

### `emitPositionsCalculated(count)`

Emit positions-calculated with province count.

**Parameters**

- `count` *number*

### `emitProvinceSelected(id, x, y)`

Emit province-selected at map position.

**Parameters**

- `id` *number*
- `x` *number*
- `y` *number*

### `emitProvinceDeselected(id)`

Emit province-deselected.

**Parameters**

- `id` *number*

### `emitProvinceHovered(id, x, y)`

Emit province-hovered at map position.

**Parameters**

- `id` *number*
- `x` *number*
- `y` *number*

### `emitFactionChanged(id, old_faction, new_faction)`

Emit faction-changed for a province.

**Parameters**

- `id` *number*
- `old_faction` *string|nil*
- `new_faction` *string|nil*

### `poll()`

Poll one event from the queue. Returns nil when empty.

**Returns**

- *table|nil* — {name, data}

### `isEmpty()`

Return true if no events are queued.

**Returns**

- *boolean*

### `drain()`

Drain and return all queued events.

**Returns**

- *table*

### `size()`

Return the number of queued events.

**Returns**

- *number*

### `colorToId(r, g, b)`

Derive a province ID from an RGB colour.

**Parameters**

- `r` *number* — 0–255
- `g` *number* — 0–255
- `b` *number* — 0–255

**Returns**

- *number*

### `loadFromDefinitions(defs, width, height)`

Build a ProvinceMap from a list of province definitions.

**Parameters**

- `defs` *table* — list of definition tables
- `width` *number*
- `height` *number*

**Returns**

- *ProvinceMap*

### `detectAdjacency(map)`

Detect province adjacencies from a pixel-lookup grid (single-pass O(w*h)).

**Parameters**

- `map` *ProvinceMap*

### `extractAllBorders(map)`

Extract border segments for all adjacency edges.

**Parameters**

- `map` *ProvinceMap*

**Returns**

- *table* — list of BorderSegment

### `extractBordersWithTag(map, tag)`

Extract border segments for edges that have a specific tag.

**Parameters**

- `map` *ProvinceMap*
- `tag` *string*

**Returns**

- *table* — list of BorderSegment

### `calculateCapital(map, id)`

Get the centroid position of the province as the capital point.

**Parameters**

- `map` *ProvinceMap*
- `id` *number*

**Returns**

- *table|nil* — {x, y}

### `calculateAllPositions(map)`

Set all province center positions to their centroid.

**Parameters**

- `map` *ProvinceMap*

### `totalEdgeCount(map)`

Count total adjacency edges across all provinces in the map.

**Parameters**

- `map` *ProvinceMap*

**Returns**

- *number*

### `allFactions(map)`

Get all unique faction names present in the map.

**Parameters**

- `map` *ProvinceMap*

**Returns**

- *table* — sorted list of faction strings

### `extractBordersByProperty(map, prop_fn)`

Return all border segments where the two bordering provinces have different values according to prop_fn.

**Parameters**

- `map` *ProvinceMap*
- `prop_fn` *function* — fn(province) -> value

**Returns**

- *table* — list of BorderSegment tables

### `detectAdjacencyWithTags(map, tag_pixel_colors)`

Detect province adjacencies from a pixel-lookup grid and tag the resulting edges based on special tag-pixel IDs. `tag_pixel_colors` maps province IDs that act as tag pixels to their tag string.  When a tag pixel is adjacent to two distinct non-tag provinces, those provinces' shared edge is created (if absent) and tagged.

**Parameters**

- `map` *ProvinceMap*
- `tag_pixel_colors` *table* — {[province_id] = tag_string}

### `adjacencyToGraph(map)`

Convert a province map's adjacency structure to a generic graph table. Each unique province that appears in at least one edge becomes a node. Each adjacency edge becomes one undirected entry in the edges list.

**Parameters**

- `map` *ProvinceMap*

**Returns**

- *table* — { nodes = {province_id,...}, edges = {{a, b},...} }

### `resolveProvinceColors(map, mode)`

Resolve a colour for each province using the given map mode. Returns a table mapping province ID to a normalised {r, g, b, a} float colour (each component in the 0–1 range).

**Parameters**

- `map` *ProvinceMap*
- `mode` *table* — MapMode created with M.newMapMode

**Returns**

- *table* — {[province_id] = {r, g, b, a}}

### `newFromPng(png_path, defs)`

Build a ProvinceMap from a PNG province-colour map using the Rust engine. This replaces the Lua `setPixel` loop + `detectAdjacency` pass with a single Rust O(w×h) scan. For a 2400×1200 map with 3000 provinces the typical speedup is 100×–300× vs the pure-Lua path (from ~2–8 s down to ~15–30 ms). Each unique non-black RGB pixel in the PNG is automatically assigned a sequential province ID starting at 1. Pure-black pixels (0, 0, 0) become background (ID 0). The returned ProvinceMap has its `pixel_lookup` field replaced by the engine grid (so `getProvinceAt` delegates to it), and all adjacency edges are pre-populated from the single Rust scan. Requires `lurek.image` to be available (Platform Services tier). by `M.loadFromDefinitions` — used to attach names, factions, and other metadata. Pass nil to skip.

**Parameters**

- `png_path` *string* — path relative to the game folder (e.g. "maps/europe.png")
- `defs` *table* — optional list of province definition tables as accepted

**Returns**

- *ProvinceMap*
