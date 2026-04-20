//! LDtk JSON map format importer.
//!
//! Reads the LDtk project format (`.ldtk`) output by the LDtk level editor and
//! converts one or more levels into a [`TileMap`].  Only the tile-layer data is
//! imported; entity and int-grid layers are ignored.
//!
//! The importer supports LDtk auto-layer and tile-layer types.  It does **not**
//! require the LDtk editor to be installed — a plain JSON string is sufficient.

use super::tilemap::TileMap;
use super::tileset::TileSet;

// -------------------------------------------------------------------------------
// Public entry point
// -------------------------------------------------------------------------------

/// Parses an LDtk JSON export string and returns a [`TileMap`].
///
/// If `level_name` is `Some`, only that level's layers are loaded.  When
/// `None`, the first level in the `"levels"` array is used.
///
/// # Parameters
/// - `json_str` — `&str`. Raw LDtk project JSON.
/// - `level_name` — `Option<&str>`. Optional level identifier to select.
///
/// # Returns
/// `Result<TileMap, String>` — `Ok` with the populated tilemap, or `Err` with a
/// descriptive message if parsing fails.
///
/// # Notes
/// - Only `"Tiles"` and `"AutoLayer"` layer types are imported.
/// - All imported layers share the same tile size (taken from the first tile-layer).
/// - Tilesets are assigned one per layer in the order they appear.
pub fn load_ldtk(json_str: &str, level_name: Option<&str>) -> Result<TileMap, String> {
    let root: serde_json::Value =
        serde_json::from_str(json_str).map_err(|e| format!("LDtk JSON parse error: {}", e))?;

    let levels = root
        .get("levels")
        .and_then(|v| v.as_array())
        .ok_or("LDtk JSON missing 'levels' array")?;

    // Pick the requested level, defaulting to the first.
    let level = if let Some(name) = level_name {
        levels
            .iter()
            .find(|l| l.get("identifier").and_then(|v| v.as_str()) == Some(name))
            .ok_or_else(|| format!("LDtk level '{}' not found", name))?
    } else {
        levels.first().ok_or("LDtk project has no levels")?
    };

    // Collect tile-producing layers in reverse order (LDtk stores front-to-back).
    let layer_instances = level
        .get("layerInstances")
        .and_then(|v| v.as_array())
        .ok_or("LDtk level missing 'layerInstances'")?;

    // Determine map dimensions and tile size from the first tile layer.
    let tile_layer = layer_instances.iter().rev().find(|l| is_tile_layer(l));
    let (grid_size, map_width, map_height) = if let Some(tl) = tile_layer {
        (
            tl.get("__gridSize")
                .and_then(|v| v.as_u64())
                .unwrap_or(16) as u32,
            tl.get("__cWid")
                .and_then(|v| v.as_u64())
                .unwrap_or(0) as u32,
            tl.get("__cHei")
                .and_then(|v| v.as_u64())
                .unwrap_or(0) as u32,
        )
    } else {
        return Err("LDtk level contains no tile or auto-layer layers".into());
    };

    let mut map = TileMap::new(grid_size, grid_size, 16);

    // Process layers back-to-front so visual stacking is correct.
    for layer in layer_instances.iter().rev() {
        if !is_tile_layer(layer) {
            continue;
        }

        let layer_name = layer
            .get("__identifier")
            .and_then(|v| v.as_str())
            .unwrap_or("layer");

        let layer_idx = map.add_layer(layer_name, map_width, map_height);

        // Build a minimal TileSet for this layer.
        let grid_tiles = layer
            .get("gridTiles")
            .or_else(|| layer.get("autoLayerTiles"))
            .and_then(|v| v.as_array());

        // Determine how many distinct tile IDs appear in this layer to size the set.
        let max_tile_id = grid_tiles
            .map(|tiles| {
                tiles
                    .iter()
                    .filter_map(|t| t.get("t").and_then(|v| v.as_u64()))
                    .max()
                    .unwrap_or(0)
            })
            .unwrap_or(0) as u32;

        // Tileset columns derived from the LDtk tileset width if available.
        let tileset_w_px = layer
            .get("__tilesetRelPath")
            .and_then(|_| layer.get("__tilesetDefUid").and_then(|_| {
                // Try to find the tile-set definition in the project root.
                root.get("defs")
                    .and_then(|d| d.get("tilesets"))
                    .and_then(|ts| ts.as_array())
                    .and_then(|arr| {
                        let uid = layer.get("__tilesetDefUid")?.as_u64()?;
                        arr.iter().find(|ts| ts.get("uid").and_then(|v| v.as_u64()) == Some(uid))
                    })
                    .and_then(|ts| ts.get("pxWid").and_then(|v| v.as_u64()))
            }))
            .unwrap_or((max_tile_id + 1) as u64 * grid_size as u64) as u32;

        let columns = if grid_size > 0 { (tileset_w_px / grid_size).max(1) } else { 1 };
        let tile_count = max_tile_id + 1;

        let tileset = TileSet::new(1, tile_count.max(1), columns, grid_size, grid_size, 0, 0);
        map.add_tileset(tileset);

        // Fill tiles into this layer.
        if let Some(tiles) = grid_tiles {
            for tile in tiles {
                let px = tile.get("px").and_then(|v| v.as_array());
                let tile_id = tile.get("t").and_then(|v| v.as_u64()).unwrap_or(0) as u32;
                if let Some(px) = px {
                    let px_x = px.first().and_then(|v| v.as_u64()).unwrap_or(0) as u32;
                    let px_y = px.get(1).and_then(|v| v.as_u64()).unwrap_or(0) as u32;
                    let tx = if grid_size > 0 { px_x / grid_size } else { 0 };
                    let ty = if grid_size > 0 { px_y / grid_size } else { 0 };
                    // GID 0 means empty; LDtk tile IDs start at 0, so we offset by 1.
                    map.set_tile(layer_idx, tx, ty, tile_id + 1);
                }
            }
        }
    }

    Ok(map)
}

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Returns `true` if the LDtk layer value represents a tile-producing layer.
fn is_tile_layer(layer: &serde_json::Value) -> bool {
    matches!(
        layer.get("__type").and_then(|v| v.as_str()),
        Some("Tiles") | Some("AutoLayer")
    )
}

// -------------------------------------------------------------------------------
// Tests
// -------------------------------------------------------------------------------
