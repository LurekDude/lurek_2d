//! LDtk JSON level format import. Parses a single level from an LDtk project string
//! and constructs a `TileMap` with one layer per tile or auto-layer.
//! Does not own map storage or rendering after the import completes.
//! Depends on `tilemap`, `tileset`, and `serde_json`.

use super::tilemap::TileMap;
use super::tileset::TileSet;

/// Parse `json_str` as an LDtk project, import the level named `level_name` (or the first level when `None`), and return a `TileMap`.
pub fn load_ldtk(json_str: &str, level_name: Option<&str>) -> Result<TileMap, String> {
    let root: serde_json::Value =
        serde_json::from_str(json_str).map_err(|e| format!("LDtk JSON parse error: {}", e))?;
    let levels = root
        .get("levels")
        .and_then(|v| v.as_array())
        .ok_or("LDtk JSON missing 'levels' array")?;
    let level = if let Some(name) = level_name {
        levels
            .iter()
            .find(|l| l.get("identifier").and_then(|v| v.as_str()) == Some(name))
            .ok_or_else(|| format!("LDtk level '{}' not found", name))?
    } else {
        levels.first().ok_or("LDtk project has no levels")?
    };
    let layer_instances = level
        .get("layerInstances")
        .and_then(|v| v.as_array())
        .ok_or("LDtk level missing 'layerInstances'")?;
    let tile_layer = layer_instances.iter().rev().find(|l| is_tile_layer(l));
    let (grid_size, map_width, map_height) = if let Some(tl) = tile_layer {
        (
            tl.get("__gridSize").and_then(|v| v.as_u64()).unwrap_or(16) as u32,
            tl.get("__cWid").and_then(|v| v.as_u64()).unwrap_or(0) as u32,
            tl.get("__cHei").and_then(|v| v.as_u64()).unwrap_or(0) as u32,
        )
    } else {
        return Err("LDtk level contains no tile or auto-layer layers".into());
    };
    let mut map = TileMap::new(grid_size, grid_size, 16);
    for layer in layer_instances.iter().rev() {
        if !is_tile_layer(layer) {
            continue;
        }
        let layer_name = layer
            .get("__identifier")
            .and_then(|v| v.as_str())
            .unwrap_or("layer");
        let layer_idx = map.add_layer(layer_name, map_width, map_height);
        let grid_tiles = layer
            .get("gridTiles")
            .or_else(|| layer.get("autoLayerTiles"))
            .and_then(|v| v.as_array());
        let max_tile_id = grid_tiles
            .map(|tiles| {
                tiles
                    .iter()
                    .filter_map(|t| t.get("t").and_then(|v| v.as_u64()))
                    .max()
                    .unwrap_or(0)
            })
            .unwrap_or(0) as u32;
        let tileset_w_px = layer
            .get("__tilesetRelPath")
            .and_then(|_| {
                layer.get("__tilesetDefUid").and_then(|_| {
                    root.get("defs")
                        .and_then(|d| d.get("tilesets"))
                        .and_then(|ts| ts.as_array())
                        .and_then(|arr| {
                            let uid = layer.get("__tilesetDefUid")?.as_u64()?;
                            arr.iter()
                                .find(|ts| ts.get("uid").and_then(|v| v.as_u64()) == Some(uid))
                        })
                        .and_then(|ts| ts.get("pxWid").and_then(|v| v.as_u64()))
                })
            })
            .unwrap_or((max_tile_id + 1) as u64 * grid_size as u64)
            as u32;
        let columns = if grid_size > 0 {
            (tileset_w_px / grid_size).max(1)
        } else {
            1
        };
        let tile_count = max_tile_id + 1;
        let tileset = TileSet::new(1, tile_count.max(1), columns, grid_size, grid_size, 0, 0);
        map.add_tileset(tileset);
        if let Some(tiles) = grid_tiles {
            for tile in tiles {
                let px = tile.get("px").and_then(|v| v.as_array());
                let tile_id = tile.get("t").and_then(|v| v.as_u64()).unwrap_or(0) as u32;
                if let Some(px) = px {
                    let px_x = px.first().and_then(|v| v.as_u64()).unwrap_or(0) as u32;
                    let px_y = px.get(1).and_then(|v| v.as_u64()).unwrap_or(0) as u32;
                    let tx = if grid_size > 0 { px_x / grid_size } else { 0 };
                    let ty = if grid_size > 0 { px_y / grid_size } else { 0 };
                    map.set_tile(layer_idx, tx, ty, tile_id + 1);
                }
            }
        }
    }
    Ok(map)
}
/// Return `true` when `layer` is a `"Tiles"` or `"AutoLayer"` layer type.
fn is_tile_layer(layer: &serde_json::Value) -> bool {
    matches!(
        layer.get("__type").and_then(|v| v.as_str()),
        Some("Tiles") | Some("AutoLayer")
    )
}
