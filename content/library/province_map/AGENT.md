# `province_map` — Agent Reference (Lunasome)

| Property | Value |
|----------|-------|
| **Tier** | Tier 3 — Lunasome (pure Lua, no Rust dependencies) |
| **Source** | `library/province_map/init.lua` |
| **Lua Tests** | `tests/lua/library/test_library_province_map.lua` |
| **Depends on** | `luna.*` public API only |
| **Test count** | 85 (all passing) |

## Summary

Province-map engine for grand-strategy and campaign games. `Province`
represents one region on the map: it stores a display name, optional faction
owner, a numeric defence rating, a building set, and a resource table. The
`setAdjacent(p1, p2, opts?)` helper registers a bidirectional `AdjacencyEdge`
between two provinces; the edge carries optional gameplay tags, a passable flag,
and a movement cost, enabling road/sea distinctions without coupling to a
specific game genre.

`ProvinceMap` is the top-level container. It provides BFS-based route finding
(`findRoute(start_id, end_id, passable_fn)`), faction queries
(`getProvincesByFaction`, `totalResourceForFaction`, `getUncontrolledProvinces`),
and graph-analysis utilities (`findIsolatedProvinces`, `getConnectedComponents`,
`totalEdgeCount`). An `EventBus` covers the full province-map lifecycle —
loading, adjacency detection, border extraction, map mode changes, position
calculation, and interaction events.

Colour helpers (`applyGradientColor`, `applyCategoryColor`, `resolveProvinceColors`)
map numeric or category values over a province list. `allFactions()` returns
the deduplicated set of faction identifiers across all provinces. No GPU, audio,
or engine state is required; all types are safe to use in headless Lua VMs.

## Architecture

```
ProvinceMap (top-level container)
  │
  ├── provinces: { id → Province }
  │     ├── name, faction, defence_rating
  │     ├── buildings: { building_id → true }
  │     └── resources: { resource_id → amount }
  │
  ├── adjacency: { "a:b" → AdjacencyEdge }
  │     ├── province_a, province_b
  │     ├── border_length, border_segments
  │     ├── tags: { tag → true }
  │     ├── passable: bool
  │     └── movement_cost: number
  │
  ├── pixel_lookup: flat 1-based array (row-major, width × height)
  │
  └── Query / analysis methods
        ├── findRoute(start, end, passable_fn) → id list | nil   (BFS)
        ├── getProvincesByFaction(faction)
        ├── totalResourceForFaction(faction, resource)
        ├── getUncontrolledProvinces()
        ├── findIsolatedProvinces()
        └── getConnectedComponents() → { component_id[] }

Free functions (parity with src/province_map/)
  ├── colorToId(r, g, b)                     — RGB → province ID
  ├── loadFromDefinitions(defs, w, h)         — build map from definition tables
  ├── detectAdjacency(map)                    — single-pass O(w×h) adjacency scan
  ├── detectAdjacencyWithTags(map, tag_colors)— adjacency scan + tag-pixel tagging
  ├── extractAllBorders(map)                  — all border segments
  ├── extractBordersWithTag(map, tag)         — tag-filtered border segments
  ├── extractBordersByProperty(map, prop_fn)  — property-predicate border filter
  ├── calculateCapital(map, id)               — province centroid as capital point
  ├── calculateAllPositions(map)              — sync all center fields to centroid
  ├── resolveProvinceColors(map, mode)        — per-province RGBA colour table
  ├── adjacencyToGraph(map)                   — {nodes, edges} graph table
  ├── allFactions(map)                        — sorted faction name list
  ├── totalEdgeCount(map)                     — total adjacency count
  ├── applyGradientColor(fn, id)              — gradient colour for one province
  └── applyCategoryColor(fn, id)              — category colour for one province
```

## Source Files

| File | Purpose |
|------|---------|
| `library/province_map/init.lua` | Full implementation — Province, AdjacencyEdge, ProvinceMap, EventBus, map modes, colour helpers |

## Key Types

| Type | Constructor | Purpose |
|------|-------------|---------|
| `Province` | `M.newProvince(id, color)` | Map region with faction, buildings, and resources |
| `AdjacencyEdge` | `M.newAdjacencyEdge(province_a, province_b)` | Typed link between two provinces with tags, passable flag, and movement cost |
| `ProvinceMap` | `M.newProvinceMap(width, height)` | Top-level container with routing, faction queries, and graph analysis |
| `EventBus` | `M.newEventBus()` | Province-map lifecycle event queue |
| `MapMode` | `M.newMapMode(name, color_fn)` | Named map visualisation mode with a colour function |
| `BorderSegment` | `M.newBorderSegment(a, b)` | Polyline border segment between two provinces |
| `BorderStyle` | `M.newBorderStyle()` | Width / colour / dashed style descriptor |
| `ProvinceDefinition` | `M.newProvinceDefinition(id, color, center)` | Lightweight descriptor for `loadFromDefinitions` |

## Parity with `src/province_map/`

Full coverage of the Rust public API:

| Rust | Lua |
|------|-----|
| `Province` struct | `M.newProvince` + `Province` methods |
| `AdjacencyEdge` struct | `M.newAdjacencyEdge` |
| `ProvinceMap` struct | `M.newProvinceMap` + `ProvinceMap` methods |
| `color_to_id` | `M.colorToId` |
| `detect_adjacency` | `M.detectAdjacency` |
| `detect_adjacency_with_tags` | `M.detectAdjacencyWithTags` (pixel-scan + tag tagging) |
| `extract_all_borders` | `M.extractAllBorders` |
| `extract_borders_with_tag` | `M.extractBordersWithTag` |
| `extract_borders_by_property` | `M.extractBordersByProperty` |
| `BorderSegment` | `M.newBorderSegment` |
| `BorderStyle` | `M.newBorderStyle` |
| `calculate_all_positions` | `M.calculateAllPositions` |
| `calculate_capital` | `M.calculateCapital` |
| `resolve_colors` (pixel buf) | `M.resolveProvinceColors` (per-province RGBA table) |
| `MapMode` / `MapModeColorFn` | `M.newMapMode`, `M.newFixedColorFn`, `M.newGradientColorFn`, `M.newCategoryColorFn` |
| `ProvinceMapEventBus` | `M.newEventBus` |
| `load_from_definitions` | `M.loadFromDefinitions` |
| `ProvinceDefinition` | `M.newProvinceDefinition` |
| `adjacency_to_graph` | `M.adjacencyToGraph` |
