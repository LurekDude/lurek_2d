# tilemap — Feature Analysis

**Tier**: 2 (Extension)
**Spec**: `specs/tilemap.md`
**Files**: Grid maps, tilesets, auto-tile, map generation

## Purpose

Tile-based map system: grid storage, tilesets with UV regions, auto-tiling (Wang/blob), multiple layers, map generation algorithms.

## Current Feature Summary

- `Tilemap`: 2D grid of tile IDs with named layers
- `Tileset`: image + grid dimensions for tile UV lookup
- Auto-tile: 4-bit and 8-bit (blob) auto-tiling with bitmask matching
- Map layers: multiple named layers with independent tile grids
- Tile properties: per-tile custom data (walkable, damage, etc.)
- Map generation: cellular automata, random fill
- Tile animation (basic frame cycling)
- World↔tile coordinate conversion
- Frustum culling: only draw visible tiles
- Collision layer: generate physics colliders from tile data

## Feature Gaps

1. **No Tiled/LDtk import**: Cannot load standard tilemap editor formats. Every serious 2D game with tiles uses Tiled or LDtk. This is the #1 missing tilemap feature.
2. **No infinite/chunked maps**: Fixed-size grids only. Can't stream chunks for large open worlds.
3. **No isometric rendering**: Only orthogonal grids. Isometric and hex grids are major 2D game styles.
4. **No hex grids**: No hexagonal tile support.
5. **No tile animation from spritesheet**: Basic frame cycling exists but can't load animation data from sprite sheet imports (Aseprite, Tiled).
6. **No parallax layers**: Multiple layers exist but no parallax scroll factor per layer.
7. **No tile entities**: Can't place entity spawners or trigger zones as tile properties.
8. **No pathfinding integration**: Tilemap has grid data that pathfinding needs, but there's no direct bridge.

## Structural Issues

- **Map generation overlap with procgen**: Tilemap has cellular automata generation, procgen module also has cellular automata. Duplication.
- **Collision generation is half-implemented**: Can generate collider data from tiles but the bridge to physics is unclear.
- **No direct pathfinding bridge**: Tilemap grid → pathfinding NavGrid conversion should be seamless.

## Suggestions

1. **Add Tiled JSON import** (high priority): `luna.tilemap.fromTiled(jsonPath)` — parse Tiled `.json` export. Import layers, tilesets, objects, properties. This alone would make Luna2D competitive for tile-based games.
2. **Add LDtk import**: `luna.tilemap.fromLDtk(jsonPath)` — LDtk is increasingly popular with indie devs.
3. **Add isometric rendering mode**: `tilemap:setProjection("isometric", tileWidth, tileHeight)` — draw tiles with diamond projection.
4. **Add hex grid mode**: `tilemap:setProjection("hex", tileSize)` — hexagonal grid with offset/cube coordinate systems.
5. **Add pathfinding bridge**: `tilemap:toNavGrid(walkableCheck)` → returns NavGrid for pathfinding module.
6. **Remove cellular automata**: Defer to `procgen` module for map generation. Tilemap should be map storage + rendering, not generation.
7. **Add tile entity spawners**: `tilemap:setTileCallback(tileId, fn)` — trigger function when entity enters tile. Enables traps, pickups, triggers.

## Competitor Comparison

| Feature | Luna2D | Love2D | Solar2D | Gideros |
|---|---|---|---|---|
| Grid tilemap | ✅ | ❌ (STI lib) | ❌ | ✅ |
| Auto-tile | ✅ (4+8 bit) | ❌ | ❌ | ❌ |
| Tiled import | ❌ | ✅ (STI) | ❌ | ✅ |
| Isometric | ❌ | ✅ (STI) | ❌ | ✅ |
| Hex grid | ❌ | ❌ | ❌ | ❌ |
| Parallax layers | ❌ | ❌ | ✅ | ✅ |
| Frustum culling | ✅ | ❌ | ❌ | ✅ |
| Collision gen | ✅ (partial) | ✅ (STI) | ❌ | ❌ |

## Priority

**HIGH** — Tiled import is critical. Isometric and hex grids unlock major game genres. Pathfinding bridge eliminates boilerplate.
