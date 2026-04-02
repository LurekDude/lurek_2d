# `src/province_map/` — Province Map System

## Purpose

Spatial province data from colour-coded PNG images or definition tables.
Pure spatial data structure analogous to a tilemap. Game-specific data (owner,
terrain, politics) lives externally in `stats` or `entity` modules.

## Files

| File | Purpose |
|------|---------|
| `core.rs` | `Province`, `AdjacencyEdge`, `ProvinceMap`, `ProvinceError` |
| `loader.rs` | PNG colour to province ID loader (`color_to_id`) |
| `adjacency.rs` | `detect_adjacency`, `detect_adjacency_with_tags` |
| `borders.rs` | Border segment extraction for province rendering |
| `positions.rs` | Province centre-point calculation |
| `map_mode.rs` | Map-mode colour assignment |
| `events.rs` | Province map event bus |
| `definition_loader.rs` | Load provinces from TOML/Lua definition tables |
| `graph_bridge.rs` | Convert adjacency data to `crate::graph::Graph` |

## Tier

**Tier 3** (strategy-genre-specific). Must not be imported by Tier 1 or Tier 2 modules.
