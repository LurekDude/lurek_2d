# src/province_map/

Province spatial data — colour-coded PNG loading, adjacency, borders.

## What This Module Contains

ProvinceMap indexes Province values by integer ID derived from unique pixel
colours in a PNG source image. Adjacency detection scans pixel neighbours.
Border segments support polygon rendering. GraphBridge exports adjacency as
a Graph for pathfinding.

## Files

| File | Purpose |
|------|---------|
| `core.rs` | Province, AdjacencyEdge, ProvinceMap, ProvinceError |
| `loader.rs` | PNG colour-to-ID loading (color_to_id) |
| `adjacency.rs` | detect_adjacency, detect_adjacency_with_tags |
| `borders.rs` | Border segment extraction |
| `positions.rs` | Province centre calculation |
| `map_mode.rs` | Map-mode colour assignment |
| `events.rs` | Province event bus |
| `definition_loader.rs` | TOML/Lua table loader |
| `graph_bridge.rs` | Adjacency to Graph bridge |

## Navigation

- **Owner agent**: `Developer`
- **Lua API bindings**: `src/lua_api/province_api.rs` (if present)
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- Uses `math` and `graph` modules
- Must NOT import from other Tier 3 modules directly
