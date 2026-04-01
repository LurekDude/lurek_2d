# src/tilemap/

Tilemap engine for tile-based game worlds.

## What This Module Contains

TileSet (tile definitions with properties). TileMap (2D grid of tile IDs with multiple layers). AutoTileSheet (Wang-style autotiling). IsoMap (isometric coordinate projection). ChunkMap (streaming large maps). TMX loader (Tiled editor format via roxmltree). TileWalker for neighbor iteration. Procedural map generation utilities.

## Files

| File | Purpose |
|------|---------|
| `autotile_sheet.rs` | `AutotileSheet` implementation |
| `chunk.rs` | `Chunk` implementation |
| `coords.rs` | `Coords` implementation |
| `isomap.rs` | `Isomap` implementation |
| `mapgen.rs` | `Mapgen` implementation |
| `mod.rs` | Module root — re-exports and module-level docs |
| `tile_walker.rs` | `TileWalker` implementation |
| `tilemap.rs` | `Tilemap` implementation |
| `tileset.rs` | `Tileset` implementation |
| `tmx.rs` | `Tmx` implementation |

## Navigation

- **Owner agent**: `Developer`
- **Tests**: `tests/tilemap_tests.rs`
- **Lua API bindings**: `src/lua_api/tilemap_api.rs`
- **Architecture docs**: `docs/architecture.md`

## Dependencies

- This module may depend on `math/` for foundational types (Vec2, Mat3, Rect)
- This module must NOT depend on other domain modules directly
- `engine/` and `lua_api/` may depend on this module
