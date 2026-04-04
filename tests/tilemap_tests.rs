//! Integration tests for `luna2d::tilemap` module.

use std::f32::consts::PI;

use luna2d::math::Rect;
use luna2d::tilemap::*;

// ===================================================================
// Helper factories
// ===================================================================

/// Creates a simple 4×4 tileset with 32×32 tiles, no spacing, no margin.
fn make_tileset() -> TileSet {
    TileSet::new(1, 16, 4, 32, 32, 0, 0)
}

/// Creates a tileset with spacing=2, margin=4, simulating a padded atlas.
fn make_spaced_tileset() -> TileSet {
    TileSet::new(1, 16, 4, 32, 32, 2, 4)
}

/// Creates a 10×10 tilemap with one tileset (first_gid=1, 16 tiles) and one layer.
fn make_map() -> TileMap {
    let mut map = TileMap::new(32, 32, 8);
    let mut ts = make_tileset();
    ts.set_solid(0, true); // local tile 0 (GID 1) is solid
    map.add_tileset(ts);
    map.add_layer("ground", 10, 10);
    map
}

// ===================================================================
// TileSet tests
// ===================================================================

#[test]
fn test_tileset_new_field_values() {
    let ts = TileSet::new(5, 64, 8, 16, 24, 1, 2);
    assert_eq!(ts.get_first_gid(), 5);
    assert_eq!(ts.get_tile_count(), 64);
    assert_eq!(ts.get_columns(), 8);
    assert_eq!(ts.get_tile_width(), 16);
    assert_eq!(ts.get_tile_height(), 24);
    assert_eq!(ts.get_tile_dimensions(), (16, 24));
    assert_eq!(ts.get_spacing(), 1);
    assert_eq!(ts.get_margin(), 2);
}

#[test]
fn test_tileset_get_quad_no_spacing() {
    let ts = make_tileset();
    // Tile 0: top-left corner
    let q0 = ts.get_quad(0);
    assert!((q0.x).abs() < 1e-5);
    assert!((q0.y).abs() < 1e-5);
    assert!((q0.width - 32.0).abs() < 1e-5);
    assert!((q0.height - 32.0).abs() < 1e-5);

    // Tile 1: col=1, row=0
    let q1 = ts.get_quad(1);
    assert!((q1.x - 32.0).abs() < 1e-5);
    assert!((q1.y).abs() < 1e-5);

    // Tile 5: col=1, row=1
    let q5 = ts.get_quad(5);
    assert!((q5.x - 32.0).abs() < 1e-5);
    assert!((q5.y - 32.0).abs() < 1e-5);
}

#[test]
fn test_tileset_get_quad_with_spacing_and_margin() {
    let ts = make_spaced_tileset(); // spacing=2, margin=4, 32×32 tiles, 4 columns
                                    // Tile 0: x = margin, y = margin → (4, 4)
    let q0 = ts.get_quad(0);
    assert!((q0.x - 4.0).abs() < 1e-5);
    assert!((q0.y - 4.0).abs() < 1e-5);
    assert!((q0.width - 32.0).abs() < 1e-5);

    // Tile 1: col=1, row=0 → x = 4 + 1*(32+2) = 38
    let q1 = ts.get_quad(1);
    assert!((q1.x - 38.0).abs() < 1e-5);
    assert!((q1.y - 4.0).abs() < 1e-5);

    // Tile 4: col=0, row=1 → y = 4 + 1*(32+2) = 38
    let q4 = ts.get_quad(4);
    assert!((q4.x - 4.0).abs() < 1e-5);
    assert!((q4.y - 38.0).abs() < 1e-5);

    // Tile 5: col=1, row=1 → x=38, y=38
    let q5 = ts.get_quad(5);
    assert!((q5.x - 38.0).abs() < 1e-5);
    assert!((q5.y - 38.0).abs() < 1e-5);
}

#[test]
fn test_tileset_solid_default_false() {
    let ts = make_tileset();
    assert!(!ts.is_solid(0));
    assert!(!ts.is_solid(15));
    // Out-of-bounds returns false
    assert!(!ts.is_solid(999));
}

#[test]
fn test_tileset_set_solid_toggle() {
    let mut ts = make_tileset();
    ts.set_solid(3, true);
    assert!(ts.is_solid(3));
    assert!(!ts.is_solid(2)); // neighbors unaffected

    ts.set_solid(3, false);
    assert!(!ts.is_solid(3));
}

#[test]
fn test_tileset_set_solid_expands_vector() {
    let mut ts = make_tileset();
    // Setting solid on a high index should auto-expand
    ts.set_solid(100, true);
    assert!(ts.is_solid(100));
    assert!(!ts.is_solid(99)); // intermediate values default to false
}

#[test]
fn test_tileset_animation_none_by_default() {
    let ts = make_tileset();
    assert!(ts.get_animation(0).is_none());
    assert!(ts.get_animation(15).is_none());
}

#[test]
fn test_tileset_set_get_animation() {
    let mut ts = make_tileset();
    let frames = vec![
        TileAnimFrame {
            tile_id: 0,
            duration_ms: 100.0,
        },
        TileAnimFrame {
            tile_id: 1,
            duration_ms: 200.0,
        },
        TileAnimFrame {
            tile_id: 2,
            duration_ms: 150.0,
        },
    ];
    ts.set_animation(5, frames);

    let anim = ts.get_animation(5).unwrap();
    assert_eq!(anim.len(), 3);
    assert_eq!(anim[0].tile_id, 0);
    assert!((anim[0].duration_ms - 100.0).abs() < 1e-5);
    assert_eq!(anim[2].tile_id, 2);
    assert!((anim[2].duration_ms - 150.0).abs() < 1e-5);

    // Other tiles are unaffected
    assert!(ts.get_animation(4).is_none());
}

#[test]
fn test_tileset_autotile_rule_4bit() {
    let mut ts = make_tileset();
    // N+S = 0b0101 = 5 → local tile 10
    ts.set_auto_tile_rule("wall", 5, 10);
    assert_eq!(ts.get_auto_tile_id("wall", 5), Some(10));

    // Different bitmask → None
    assert_eq!(ts.get_auto_tile_id("wall", 0), None);

    // Different type name → None
    assert_eq!(ts.get_auto_tile_id("floor", 5), None);
}

#[test]
fn test_tileset_autotile_rule_8bit() {
    let mut ts = make_tileset();
    // N+E+NE = 0b0001_0011 = 19
    ts.set_auto_tile_rule_8("stone", 19, 7);
    assert_eq!(ts.get_auto_tile_id_8("stone", 19), Some(7));
    assert_eq!(ts.get_auto_tile_id_8("stone", 0), None);
    assert_eq!(ts.get_auto_tile_id_8("dirt", 19), None);
}

#[test]
fn test_tileset_autotile_multiple_types() {
    let mut ts = make_tileset();
    ts.set_auto_tile_rule("wall", 0b1111, 42);
    ts.set_auto_tile_rule("water", 0b1111, 7);
    assert_eq!(ts.get_auto_tile_id("wall", 0b1111), Some(42));
    assert_eq!(ts.get_auto_tile_id("water", 0b1111), Some(7));
}

// ===================================================================
// TileMap — construction and tileset management
// ===================================================================

#[test]
fn test_tilemap_new_dimensions() {
    let map = TileMap::new(16, 24, 4);
    assert_eq!(map.get_tile_width(), 16);
    assert_eq!(map.get_tile_height(), 24);
    assert_eq!(map.get_tile_dimensions(), (16, 24));
    assert_eq!(map.get_chunk_size(), 4);
}

#[test]
fn test_tilemap_add_get_tileset() {
    let mut map = TileMap::new(32, 32, 8);
    assert_eq!(map.get_tileset_count(), 0);
    assert!(map.get_tileset(0).is_none());

    map.add_tileset(make_tileset());
    assert_eq!(map.get_tileset_count(), 1);

    let ts = map.get_tileset(0).unwrap();
    assert_eq!(ts.get_first_gid(), 1);
    assert_eq!(ts.get_tile_count(), 16);

    assert!(map.get_tileset(1).is_none());
}

#[test]
fn test_tilemap_multiple_tilesets() {
    let mut map = TileMap::new(32, 32, 8);
    map.add_tileset(TileSet::new(1, 16, 4, 32, 32, 0, 0));
    map.add_tileset(TileSet::new(17, 32, 8, 16, 16, 0, 0));
    assert_eq!(map.get_tileset_count(), 2);
    assert_eq!(map.get_tileset(1).unwrap().get_first_gid(), 17);
}

// ===================================================================
// TileMap — layer management
// ===================================================================

#[test]
fn test_tilemap_add_layer_returns_index() {
    let mut map = TileMap::new(32, 32, 8);
    let idx0 = map.add_layer("background", 20, 15);
    let idx1 = map.add_layer("foreground", 20, 15);
    assert_eq!(idx0, 0);
    assert_eq!(idx1, 1);
    assert_eq!(map.get_layer_count(), 2);
}

#[test]
fn test_tilemap_get_layer_name() {
    let mut map = TileMap::new(32, 32, 8);
    map.add_layer("ground", 10, 10);
    map.add_layer("objects", 10, 10);
    assert_eq!(map.get_layer_name(0), Some("ground"));
    assert_eq!(map.get_layer_name(1), Some("objects"));
    assert_eq!(map.get_layer_name(99), None);
}

#[test]
fn test_tilemap_layer_visible_default_true() {
    let map = make_map();
    assert!(map.get_layer_visible(0));
    // Invalid index returns false
    assert!(!map.get_layer_visible(99));
}

#[test]
fn test_tilemap_set_layer_visible() {
    let mut map = make_map();
    map.set_layer_visible(0, false);
    assert!(!map.get_layer_visible(0));
    map.set_layer_visible(0, true);
    assert!(map.get_layer_visible(0));
}

#[test]
fn test_tilemap_layer_color() {
    let mut map = make_map();
    // Default tint is white (1,1,1,1)
    let c = map.get_layer_color(0);
    assert!((c[0] - 1.0).abs() < 1e-5);
    assert!((c[3] - 1.0).abs() < 1e-5);

    map.set_layer_color(0, 0.5, 0.25, 0.75, 0.8);
    let c2 = map.get_layer_color(0);
    assert!((c2[0] - 0.5).abs() < 1e-5);
    assert!((c2[1] - 0.25).abs() < 1e-5);
    assert!((c2[2] - 0.75).abs() < 1e-5);
    assert!((c2[3] - 0.8).abs() < 1e-5);

    // Invalid layer returns [0,0,0,0]
    let bad = map.get_layer_color(99);
    assert!((bad[0]).abs() < 1e-5);
}

#[test]
fn test_tilemap_layer_offset() {
    let mut map = make_map();
    // Default offset is zero
    let o = map.get_layer_offset(0);
    assert!((o.x).abs() < 1e-5);
    assert!((o.y).abs() < 1e-5);

    map.set_layer_offset(0, 10.5, -20.0);
    let o2 = map.get_layer_offset(0);
    assert!((o2.x - 10.5).abs() < 1e-5);
    assert!((o2.y - (-20.0)).abs() < 1e-5);
}

#[test]
fn test_tilemap_layer_parallax() {
    let mut map = make_map();
    // Default parallax is (1, 1)
    let p = map.get_layer_parallax(0);
    assert!((p.x - 1.0).abs() < 1e-5);
    assert!((p.y - 1.0).abs() < 1e-5);

    map.set_layer_parallax(0, 0.5, 0.75);
    let p2 = map.get_layer_parallax(0);
    assert!((p2.x - 0.5).abs() < 1e-5);
    assert!((p2.y - 0.75).abs() < 1e-5);
}

// ===================================================================
// TileMap — tile access
// ===================================================================

#[test]
fn test_tilemap_set_get_tile() {
    let mut map = make_map();
    assert_eq!(map.get_tile(0, 0, 0), 0); // default empty
    map.set_tile(0, 3, 4, 5);
    assert_eq!(map.get_tile(0, 3, 4), 5);
}

#[test]
fn test_tilemap_get_tile_out_of_bounds_returns_zero() {
    let map = make_map();
    assert_eq!(map.get_tile(0, 100, 100), 0);
    assert_eq!(map.get_tile(99, 0, 0), 0); // invalid layer
}

#[test]
fn test_tilemap_clear_tile() {
    let mut map = make_map();
    map.set_tile(0, 2, 2, 7);
    assert_eq!(map.get_tile(0, 2, 2), 7);
    map.clear_tile(0, 2, 2);
    assert_eq!(map.get_tile(0, 2, 2), 0);
}

#[test]
fn test_tilemap_fill() {
    let mut map = make_map();
    map.fill(0, 3);
    for y in 0..10 {
        for x in 0..10 {
            assert_eq!(map.get_tile(0, x, y), 3);
        }
    }
    // Fill with 0 effectively clears
    map.fill(0, 0);
    assert_eq!(map.get_tile(0, 5, 5), 0);
}

// ===================================================================
// TileMap — coordinate conversion
// ===================================================================

#[test]
fn test_tilemap_tile_to_world() {
    let map = make_map(); // 32×32 tiles
    let (wx, wy) = map.tile_to_world(0, 0);
    assert!((wx).abs() < 1e-5);
    assert!((wy).abs() < 1e-5);

    let (wx3, wy5) = map.tile_to_world(3, 5);
    assert!((wx3 - 96.0).abs() < 1e-5); // 3 * 32
    assert!((wy5 - 160.0).abs() < 1e-5); // 5 * 32
}

#[test]
fn test_tilemap_world_to_tile() {
    let map = make_map();
    let (tx, ty) = map.world_to_tile(96.0, 160.0);
    assert_eq!(tx, 3);
    assert_eq!(ty, 5);

    // Mid-tile position rounds down
    let (tx2, ty2) = map.world_to_tile(50.0, 50.0);
    assert_eq!(tx2, 1); // 50/32 = 1.5625 → 1
    assert_eq!(ty2, 1);
}

#[test]
fn test_tilemap_world_to_tile_negative_clamps_to_zero() {
    let map = make_map();
    let (tx, ty) = map.world_to_tile(-10.0, -100.0);
    assert_eq!(tx, 0);
    assert_eq!(ty, 0);
}

#[test]
fn test_tilemap_world_tile_roundtrip() {
    let map = make_map();
    for tx in 0..10 {
        for ty in 0..10 {
            let (wx, wy) = map.tile_to_world(tx, ty);
            let (rtx, rty) = map.world_to_tile(wx, wy);
            assert_eq!(rtx, tx);
            assert_eq!(rty, ty);
        }
    }
}

// ===================================================================
// TileMap — viewport
// ===================================================================

#[test]
fn test_tilemap_viewport_none_by_default() {
    let map = make_map();
    assert!(map.get_viewport().is_none());
}

#[test]
fn test_tilemap_set_get_viewport() {
    let mut map = make_map();
    map.set_viewport(10.0, 20.0, 640.0, 480.0);
    let vp = map.get_viewport().unwrap();
    assert!((vp.0 - 10.0).abs() < 1e-5);
    assert!((vp.1 - 20.0).abs() < 1e-5);
    assert!((vp.2 - 640.0).abs() < 1e-5);
    assert!((vp.3 - 480.0).abs() < 1e-5);
}

// ===================================================================
// TileMap — collision (is_solid, rect_overlaps_solid, sweep_rect)
// ===================================================================

#[test]
fn test_tilemap_is_solid_empty_tile() {
    let map = make_map();
    // GID 0 (empty) is never solid
    assert!(!map.is_solid(0, 0, 0));
}

#[test]
fn test_tilemap_is_solid_with_solid_gid() {
    let mut map = make_map();
    // GID 1 → tileset first_gid=1, local=0 → solid
    map.set_tile(0, 5, 5, 1);
    assert!(map.is_solid(0, 5, 5));
}

#[test]
fn test_tilemap_is_solid_with_non_solid_gid() {
    let mut map = make_map();
    // GID 2 → tileset first_gid=1, local=1 → not solid (only local 0 is solid)
    map.set_tile(0, 6, 6, 2);
    assert!(!map.is_solid(0, 6, 6));
}

#[test]
fn test_tilemap_rect_overlaps_solid_hit() {
    let mut map = make_map();
    // Place solid tile at (3,3) → world rect (96,96)-(128,128)
    map.set_tile(0, 3, 3, 1);
    // Rect that overlaps the solid tile
    assert!(map.rect_overlaps_solid(0, Rect::new(90.0, 90.0, 20.0, 20.0)));
}

#[test]
fn test_tilemap_rect_overlaps_solid_miss() {
    let mut map = make_map();
    map.set_tile(0, 3, 3, 1);
    // Rect far from the solid tile
    assert!(!map.rect_overlaps_solid(0, Rect::new(0.0, 0.0, 10.0, 10.0)));
}

#[test]
fn test_tilemap_rect_overlaps_solid_no_solid_tiles() {
    let map = make_map();
    // No solid tiles placed → always false
    assert!(!map.rect_overlaps_solid(0, Rect::new(0.0, 0.0, 320.0, 320.0)));
}

#[test]
fn test_tilemap_sweep_rect_hits_solid() {
    let mut map = make_map();
    // Solid tile at col 5 → world x=[160, 192)
    map.set_tile(0, 5, 0, 1);

    // Sweep a 16×16 rect rightward from x=0
    let result = map.sweep_rect(0, Rect::new(0.0, 0.0, 16.0, 16.0), 200.0, 0.0);
    assert!(result.is_some());
    let r = result.unwrap();
    assert!(r.t > 0.0 && r.t < 1.0);
    // Normal should point left (opposing movement direction)
    assert!((r.normal.x - (-1.0)).abs() < 1e-5);
    assert!((r.normal.y).abs() < 1e-5);
    assert_eq!(r.tile_x, 5);
    assert_eq!(r.tile_y, 0);
}

#[test]
fn test_tilemap_sweep_rect_no_collision() {
    let map = make_map(); // no solid tiles placed
    let result = map.sweep_rect(0, Rect::new(0.0, 0.0, 16.0, 16.0), 100.0, 0.0);
    assert!(result.is_none());
}

#[test]
fn test_tilemap_sweep_rect_zero_velocity_returns_none() {
    let mut map = make_map();
    map.set_tile(0, 0, 0, 1);
    let result = map.sweep_rect(0, Rect::new(0.0, 0.0, 16.0, 16.0), 0.0, 0.0);
    assert!(result.is_none());
}

#[test]
fn test_tilemap_sweep_rect_vertical_collision() {
    let mut map = make_map();
    // Solid tile at row 5 → world y=[160, 192)
    map.set_tile(0, 0, 5, 1);

    // Sweep downward
    let result = map.sweep_rect(0, Rect::new(0.0, 0.0, 16.0, 16.0), 0.0, 200.0);
    assert!(result.is_some());
    let r = result.unwrap();
    assert!((r.normal.y - (-1.0)).abs() < 1e-5);
    assert_eq!(r.tile_y, 5);
}

// ===================================================================
// AutoTileSheet tests
// ===================================================================

#[test]
fn test_autotilesheet_blob47_creation() {
    let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Blob47);
    assert_eq!(sheet.get_layout(), AutoTileLayout::Blob47);
    assert_eq!(sheet.get_tile_count(), 47);
    assert_eq!(sheet.get_tile_width(), 32);
    assert_eq!(sheet.get_tile_height(), 32);
}

#[test]
fn test_autotilesheet_composite48_creation() {
    let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Composite48);
    assert_eq!(sheet.get_layout(), AutoTileLayout::Composite48);
    assert_eq!(sheet.get_tile_count(), 48);
    assert_eq!(sheet.get_tile_width(), 16);
    assert_eq!(sheet.get_tile_height(), 16);
}

#[test]
fn test_autotilesheet_minimal16_creation() {
    let sheet = AutoTileSheet::new(24, 24, AutoTileLayout::Minimal16);
    assert_eq!(sheet.get_layout(), AutoTileLayout::Minimal16);
    assert_eq!(sheet.get_tile_count(), 16);
    assert_eq!(sheet.get_tile_width(), 24);
    assert_eq!(sheet.get_tile_height(), 24);
}

#[test]
fn test_autotilesheet_minimal16_bitmask_roundtrip() {
    let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16);
    for i in 0u32..16 {
        let bm = sheet.get_bitmask_for_tile(i);
        assert_eq!(bm, i as u16);
        let tile = sheet.get_tile_for_bitmask(bm);
        assert_eq!(tile, Some(i));
    }
}

#[test]
fn test_autotilesheet_blob47_bitmask_roundtrip() {
    let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Blob47);
    // Each of the 47 tiles should round-trip through bitmask lookup
    for i in 0u32..47 {
        let bm = sheet.get_bitmask_for_tile(i);
        let tile = sheet.get_tile_for_bitmask(bm);
        assert_eq!(tile, Some(i), "round-trip failed for tile index {i}");
    }
}

#[test]
fn test_autotilesheet_bitmask_out_of_bounds_returns_zero() {
    let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Blob47);
    assert_eq!(sheet.get_bitmask_for_tile(100), 0);
    assert_eq!(sheet.get_bitmask_for_tile(47), 0);
}

#[test]
fn test_autotilesheet_apply_to_tileset_minimal16() {
    let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16);
    let mut ts = TileSet::new(1, 16, 4, 16, 16, 0, 0);
    sheet.apply_to_tileset(&mut ts, "grass", None);

    // 4-bit rules: bitmask 0 → tile 0, bitmask 15 → tile 15
    assert_eq!(ts.get_auto_tile_id("grass", 0), Some(0));
    assert_eq!(ts.get_auto_tile_id("grass", 15), Some(15));
    // All 16 bitmasks should be populated
    for bm in 0u8..16 {
        assert!(ts.get_auto_tile_id("grass", bm).is_some());
    }
}

#[test]
fn test_autotilesheet_apply_to_tileset_with_offset() {
    let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16);
    let mut ts = TileSet::new(1, 32, 4, 16, 16, 0, 0);
    sheet.apply_to_tileset(&mut ts, "wall", Some(10));

    // Bitmask 0 → tile 10 (0 + offset)
    assert_eq!(ts.get_auto_tile_id("wall", 0), Some(10));
    // Bitmask 15 → tile 25 (15 + offset)
    assert_eq!(ts.get_auto_tile_id("wall", 15), Some(25));
}

#[test]
fn test_autotilesheet_apply_to_tileset_blob47_uses_8bit_rules() {
    let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Blob47);
    let mut ts = TileSet::new(1, 64, 8, 16, 16, 0, 0);
    sheet.apply_to_tileset(&mut ts, "stone", None);

    // Tile 0's bitmask should be registered as an 8-bit rule
    let bm0 = sheet.get_bitmask_for_tile(0);
    assert_eq!(ts.get_auto_tile_id_8("stone", bm0), Some(0));
}

#[test]
fn test_autotilesheet_layout_equality() {
    assert_eq!(AutoTileLayout::Blob47, AutoTileLayout::Blob47);
    assert_eq!(AutoTileLayout::Minimal16, AutoTileLayout::Minimal16);
    assert_ne!(AutoTileLayout::Blob47, AutoTileLayout::Composite48);
    assert_ne!(AutoTileLayout::Composite48, AutoTileLayout::Minimal16);
}

#[test]
fn test_autotilesheet_get_quad_first_tile() {
    let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Blob47);
    let q = sheet.get_quad(0);
    assert!((q.x - 0.0).abs() < 1e-5);
    assert!((q.y - 0.0).abs() < 1e-5);
    assert!((q.width - 32.0).abs() < 1e-5);
    assert!((q.height - 32.0).abs() < 1e-5);
}

#[test]
fn test_autotilesheet_get_quad_sequential_tiles() {
    let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Blob47);
    // Tiles are single-row: tile 5 → x = 5*32 = 160
    let q = sheet.get_quad(5);
    assert!((q.x - 160.0).abs() < 1e-5);
    assert!((q.y - 0.0).abs() < 1e-5);
}

#[test]
fn test_autotilesheet_get_quad_out_of_bounds_zero_size() {
    let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Minimal16);
    let q = sheet.get_quad(100);
    assert!((q.width - 0.0).abs() < 1e-5);
    assert!((q.height - 0.0).abs() < 1e-5);
}

// ===================================================================
// TileMap — autotile integration
// ===================================================================

#[test]
fn test_tilemap_apply_autotile_4bit_column() {
    let mut tm = TileMap::new(32, 32, 16);
    tm.add_layer("main", 3, 3);
    let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
    ts.set_auto_tile_rule("ground", 0, 0); // isolated
    ts.set_auto_tile_rule("ground", 5, 5); // N=1 + S=4
    ts.set_auto_tile_rule("ground", 4, 4); // S only
    ts.set_auto_tile_rule("ground", 1, 1); // N only
    tm.add_tileset(ts);

    // Vertical column in the center
    tm.set_tile(0, 1, 0, 1);
    tm.set_tile(0, 1, 1, 1);
    tm.set_tile(0, 1, 2, 1);

    tm.apply_autotile(0, "ground");

    // Top tile (1,0): S neighbor → mask=4 → gid = 1+4 = 5
    assert_eq!(tm.get_tile(0, 1, 0), 5);
    // Middle (1,1): N+S → mask=5 → gid = 1+5 = 6
    assert_eq!(tm.get_tile(0, 1, 1), 6);
    // Bottom (1,2): N neighbor → mask=1 → gid = 1+1 = 2
    assert_eq!(tm.get_tile(0, 1, 2), 2);
}

#[test]
fn test_tilemap_apply_autotile_8bit_center() {
    let mut tm = TileMap::new(32, 32, 16);
    tm.add_layer("main", 3, 3);
    let mut ts = TileSet::new(1, 256, 16, 32, 32, 0, 0);
    // Fully surrounded: N+E+S+W+NE+SE+SW+NW = 255
    ts.set_auto_tile_rule_8("terrain", 255, 100);
    tm.add_tileset(ts);

    for y in 0..3 {
        for x in 0..3 {
            tm.set_tile(0, x, y, 1);
        }
    }

    tm.apply_autotile_8(0, "terrain");

    // Center (1,1) is fully surrounded → gid = 1 + 100 = 101
    assert_eq!(tm.get_tile(0, 1, 1), 101);
}

#[test]
fn test_tilemap_update_no_crash_no_animations() {
    let mut tm = TileMap::new(32, 32, 16);
    tm.add_layer("main", 10, 10);
    let ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
    tm.add_tileset(ts);
    tm.update(0.016); // no panic
}

#[test]
fn test_tilemap_update_advances_animation_timer() {
    let mut tm = TileMap::new(32, 32, 16);
    tm.add_layer("main", 10, 10);
    let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
    ts.set_animation(
        0,
        vec![
            TileAnimFrame {
                tile_id: 0,
                duration_ms: 100.0,
            },
            TileAnimFrame {
                tile_id: 1,
                duration_ms: 100.0,
            },
        ],
    );
    tm.add_tileset(ts);
    // Run 10 updates of 50ms each → should cycle through frames
    for _ in 0..10 {
        tm.update(0.05);
    }
    // Should not panic and cover the animation advancing logic
}

#[test]
fn test_tilemap_multiple_layers_independent_tiles() {
    let mut tm = TileMap::new(32, 32, 16);
    tm.add_layer("bg", 5, 5);
    tm.add_layer("fg", 5, 5);
    tm.set_tile(0, 2, 2, 10);
    tm.set_tile(1, 2, 2, 20);
    assert_eq!(tm.get_tile(0, 2, 2), 10);
    assert_eq!(tm.get_tile(1, 2, 2), 20);
}

#[test]
fn test_tilemap_fill_then_clear_individual_tile() {
    let mut map = make_map();
    map.fill(0, 5);
    map.clear_tile(0, 0, 0);
    assert_eq!(map.get_tile(0, 0, 0), 0);
    assert_eq!(map.get_tile(0, 1, 0), 5);
}

// ===================================================================
// MapBlock tests
// ===================================================================

#[test]
fn test_mapblock_new_dimensions() {
    let block = MapBlock::new(8, 6, 2, 4);
    assert_eq!(block.get_width(), 8);
    assert_eq!(block.get_height(), 6);
    assert_eq!(block.get_dimensions(), (8, 6));
    assert_eq!(block.get_layer_count(), 2);
    assert_eq!(block.get_segment_size(), 4);
}

#[test]
fn test_mapblock_set_get_tile_roundtrip() {
    let mut block = MapBlock::new(4, 4, 1, 2);
    assert_eq!(block.get_tile(0, 0, 0), 0);
    block.set_tile(0, 2, 3, 42);
    assert_eq!(block.get_tile(0, 2, 3), 42);
}

#[test]
fn test_mapblock_set_get_tile_multiple_layers() {
    let mut block = MapBlock::new(4, 4, 3, 2);
    block.set_tile(0, 0, 0, 10);
    block.set_tile(1, 0, 0, 20);
    block.set_tile(2, 0, 0, 30);
    assert_eq!(block.get_tile(0, 0, 0), 10);
    assert_eq!(block.get_tile(1, 0, 0), 20);
    assert_eq!(block.get_tile(2, 0, 0), 30);
}

#[test]
fn test_mapblock_get_tile_out_of_bounds_returns_zero() {
    let block = MapBlock::new(4, 4, 1, 2);
    assert_eq!(block.get_tile(0, 99, 99), 0);
    assert_eq!(block.get_tile(5, 0, 0), 0);
}

#[test]
fn test_mapblock_set_get_side_all_edges() {
    let mut block = MapBlock::new(8, 8, 1, 4);
    block.set_side(Edge::North, 0, 1);
    block.set_side(Edge::East, 0, 2);
    block.set_side(Edge::South, 0, 3);
    block.set_side(Edge::West, 0, 4);
    assert_eq!(block.get_side(Edge::North, 0), 1);
    assert_eq!(block.get_side(Edge::East, 0), 2);
    assert_eq!(block.get_side(Edge::South, 0), 3);
    assert_eq!(block.get_side(Edge::West, 0), 4);
}

#[test]
fn test_mapblock_get_side_unset_returns_zero() {
    let block = MapBlock::new(4, 4, 1, 2);
    assert_eq!(block.get_side(Edge::North, 0), 0);
    assert_eq!(block.get_side(Edge::West, 99), 0);
}

#[test]
fn test_mapblock_segment_counts_per_edge() {
    let block = MapBlock::new(8, 6, 1, 2);
    assert_eq!(block.get_width_in_segments(), 4);
    assert_eq!(block.get_height_in_segments(), 3);
    assert_eq!(block.get_segment_count(Edge::North), 4);
    assert_eq!(block.get_segment_count(Edge::South), 4);
    assert_eq!(block.get_segment_count(Edge::East), 3);
    assert_eq!(block.get_segment_count(Edge::West), 3);
}

#[test]
fn test_mapblock_set_get_name() {
    let mut block = MapBlock::new(4, 4, 1, 2);
    assert_eq!(block.get_name(), "");
    block.set_name("room_a");
    assert_eq!(block.get_name(), "room_a");
}

#[test]
fn test_mapblock_set_get_weight() {
    let mut block = MapBlock::new(4, 4, 1, 2);
    assert!((block.get_weight() - 1.0).abs() < 1e-5);
    block.set_weight(2.5);
    assert!((block.get_weight() - 2.5).abs() < 1e-5);
}

#[test]
fn test_mapblock_set_side_multiple_segments() {
    let mut block = MapBlock::new(8, 4, 1, 4);
    block.set_side(Edge::North, 0, 10);
    block.set_side(Edge::North, 1, 20);
    assert_eq!(block.get_side(Edge::North, 0), 10);
    assert_eq!(block.get_side(Edge::North, 1), 20);
}

#[test]
fn test_mapblock_overwrite_tile() {
    let mut block = MapBlock::new(4, 4, 1, 2);
    block.set_tile(0, 1, 1, 5);
    block.set_tile(0, 1, 1, 99);
    assert_eq!(block.get_tile(0, 1, 1), 99);
}

#[test]
fn test_mapblock_initial_tiles_all_zero() {
    let block = MapBlock::new(4, 4, 2, 2);
    for layer in 0..2 {
        for y in 0..4 {
            for x in 0..4 {
                assert_eq!(block.get_tile(layer, x, y), 0);
            }
        }
    }
}

// ===================================================================
// MapGroup tests
// ===================================================================

#[test]
fn test_mapgroup_new_name() {
    let group = MapGroup::new("forest");
    assert_eq!(group.get_name(), "forest");
    assert_eq!(group.get_block_count(), 0);
    assert_eq!(group.get_script_count(), 0);
}

#[test]
fn test_mapgroup_add_get_block() {
    let mut group = MapGroup::new("cave");
    let block = MapBlock::new(4, 4, 1, 2);
    group.add_block(block);
    assert_eq!(group.get_block_count(), 1);
    assert!(group.get_block(0).is_some());
    assert!(group.get_block(1).is_none());
}

#[test]
fn test_mapgroup_remove_block() {
    let mut group = MapGroup::new("test");
    group.add_block(MapBlock::new(4, 4, 1, 2));
    group.add_block(MapBlock::new(8, 8, 1, 4));
    assert_eq!(group.get_block_count(), 2);
    group.remove_block(0);
    assert_eq!(group.get_block_count(), 1);
}

#[test]
fn test_mapgroup_remove_block_out_of_bounds_no_panic() {
    let mut group = MapGroup::new("safe");
    group.remove_block(99);
    assert_eq!(group.get_block_count(), 0);
}

#[test]
fn test_mapgroup_add_get_script() {
    let mut group = MapGroup::new("dungeon");
    let script = MapScript::new("gen_rooms");
    group.add_script(script);
    assert_eq!(group.get_script_count(), 1);
    let s = group.get_script(0).unwrap();
    assert_eq!(s.get_name(), "gen_rooms");
}

#[test]
fn test_mapgroup_get_script_out_of_bounds() {
    let group = MapGroup::new("empty");
    assert!(group.get_script(0).is_none());
}

#[test]
fn test_mapgroup_set_get_name() {
    let mut group = MapGroup::new("original");
    group.set_name("renamed");
    assert_eq!(group.get_name(), "renamed");
}

#[test]
fn test_mapgroup_multiple_blocks_and_scripts() {
    let mut group = MapGroup::new("mixed");
    group.add_block(MapBlock::new(4, 4, 1, 2));
    group.add_block(MapBlock::new(8, 8, 1, 4));
    group.add_script(MapScript::new("a"));
    group.add_script(MapScript::new("b"));
    assert_eq!(group.get_block_count(), 2);
    assert_eq!(group.get_script_count(), 2);
}

// ===================================================================
// MapScript tests
// ===================================================================

#[test]
fn test_mapscript_new_name() {
    let script = MapScript::new("generate_dungeon");
    assert_eq!(script.get_name(), "generate_dungeon");
    assert_eq!(script.get_step_count(), 0);
}

#[test]
fn test_mapscript_add_get_step() {
    let mut script = MapScript::new("test");
    script.add_step(ScriptStep {
        step_type: StepType::FillRandom,
        ..Default::default()
    });
    assert_eq!(script.get_step_count(), 1);
    assert_eq!(script.get_step(0).unwrap().step_type, StepType::FillRandom);
}

#[test]
fn test_mapscript_get_step_out_of_bounds() {
    let script = MapScript::new("empty");
    assert!(script.get_step(0).is_none());
}

#[test]
fn test_mapscript_remove_step_shifts_remaining() {
    let mut script = MapScript::new("test");
    script.add_step(ScriptStep {
        step_type: StepType::FillRandom,
        ..Default::default()
    });
    script.add_step(ScriptStep {
        step_type: StepType::PlaceBlock,
        ..Default::default()
    });
    script.remove_step(0);
    assert_eq!(script.get_step_count(), 1);
    assert_eq!(script.get_step(0).unwrap().step_type, StepType::PlaceBlock);
}

#[test]
fn test_mapscript_remove_step_out_of_bounds_no_panic() {
    let mut script = MapScript::new("safe");
    script.remove_step(99);
}

#[test]
fn test_mapscript_clear_steps() {
    let mut script = MapScript::new("test");
    script.add_step(ScriptStep::default());
    script.add_step(ScriptStep::default());
    script.add_step(ScriptStep::default());
    assert_eq!(script.get_step_count(), 3);
    script.clear_steps();
    assert_eq!(script.get_step_count(), 0);
}

#[test]
fn test_mapscript_set_get_name() {
    let mut script = MapScript::new("original");
    script.set_name("updated");
    assert_eq!(script.get_name(), "updated");
}

#[test]
fn test_script_step_default_values() {
    let step = ScriptStep::default();
    assert_eq!(step.step_type, StepType::FillRandom);
    assert_eq!(step.group_index, -1);
    assert_eq!(step.block_index, -1);
    assert_eq!(step.x, 0);
    assert_eq!(step.y, 0);
    assert_eq!(step.width, 0);
    assert_eq!(step.height, 0);
    assert_eq!(step.count, 1);
    assert_eq!(step.rotation, 0);
    assert!(!step.mirror);
    assert!(!step.random_rotation);
    assert!(!step.random_mirror);
    assert_eq!(step.direction, 0);
    assert!(step.match_sides);
    assert_eq!(step.condition_step, -1);
    assert!(step.condition_success);
    assert!((step.chance - 1.0).abs() < 1e-5);
    assert_eq!(step.repeat_count, 1);
    assert_eq!(step.min_count, -1);
    assert_eq!(step.max_count, -1);
    assert_eq!(step.size_filter_w, -1);
    assert_eq!(step.size_filter_h, -1);
    assert_eq!(step.tile_id, 0);
    assert_eq!(step.path_width, 1);
    assert_eq!(step.tile_layer, 0);
    assert_eq!(step.zone_start_y, -1);
    assert_eq!(step.zone_end_y, -1);
}

// ===================================================================
// Edge / StepType enum tests
// ===================================================================

#[test]
fn test_edge_from_str_all_valid() {
    assert_eq!(Edge::from_str("north"), Some(Edge::North));
    assert_eq!(Edge::from_str("east"), Some(Edge::East));
    assert_eq!(Edge::from_str("south"), Some(Edge::South));
    assert_eq!(Edge::from_str("west"), Some(Edge::West));
}

#[test]
fn test_edge_from_str_invalid() {
    assert_eq!(Edge::from_str("up"), None);
    assert_eq!(Edge::from_str(""), None);
}

#[test]
fn test_edge_as_str_roundtrip() {
    let edges = [Edge::North, Edge::East, Edge::South, Edge::West];
    for e in &edges {
        assert_eq!(Edge::from_str(e.as_str()), Some(*e));
    }
}

#[test]
fn test_steptype_from_str_all_valid() {
    assert_eq!(
        StepType::from_str("fill_random"),
        Some(StepType::FillRandom)
    );
    assert_eq!(
        StepType::from_str("place_block"),
        Some(StepType::PlaceBlock)
    );
    assert_eq!(
        StepType::from_str("place_random"),
        Some(StepType::PlaceRandom)
    );
    assert_eq!(StepType::from_str("place_line"), Some(StepType::PlaceLine));
    assert_eq!(StepType::from_str("flood_fill"), Some(StepType::FloodFill));
    assert_eq!(StepType::from_str("fill_area"), Some(StepType::FillArea));
    assert_eq!(StepType::from_str("draw_path"), Some(StepType::DrawPath));
    assert_eq!(StepType::from_str("fill_rect"), Some(StepType::FillRect));
}

#[test]
fn test_steptype_from_str_invalid() {
    assert_eq!(StepType::from_str("invalid"), None);
    assert_eq!(StepType::from_str(""), None);
}

#[test]
fn test_steptype_as_str_roundtrip() {
    let variants = [
        StepType::FillRandom,
        StepType::PlaceBlock,
        StepType::PlaceRandom,
        StepType::PlaceLine,
        StepType::FloodFill,
        StepType::FillArea,
        StepType::DrawPath,
        StepType::FillRect,
    ];
    for v in &variants {
        assert_eq!(StepType::from_str(v.as_str()), Some(*v));
    }
}

// ===================================================================
// MapGen tests
// ===================================================================

#[test]
fn test_mapgen_new_small() {
    let gen = MapGen::new(MapSize::Small, 4);
    assert_eq!(gen.get_grid_dimensions(), (3, 3));
    assert_eq!(gen.get_grid_width(), 3);
    assert_eq!(gen.get_grid_height(), 3);
    assert_eq!(gen.get_segment_size(), 4);
}

#[test]
fn test_mapgen_new_medium() {
    let gen = MapGen::new(MapSize::Medium, 4);
    assert_eq!(gen.get_grid_dimensions(), (5, 5));
}

#[test]
fn test_mapgen_new_large() {
    let gen = MapGen::new(MapSize::Large, 8);
    assert_eq!(gen.get_grid_dimensions(), (6, 6));
}

#[test]
fn test_mapgen_new_custom() {
    let gen = MapGen::new(MapSize::Custom(10, 7), 4);
    assert_eq!(gen.get_grid_dimensions(), (10, 7));
    assert_eq!(gen.get_grid_width(), 10);
    assert_eq!(gen.get_grid_height(), 7);
}

#[test]
fn test_mapgen_set_get_tile_size() {
    let mut gen = MapGen::new(MapSize::Small, 4);
    assert_eq!(gen.get_tile_pixel_width(), 32);
    assert_eq!(gen.get_tile_pixel_height(), 32);
    gen.set_tile_size(16, 24);
    assert_eq!(gen.get_tile_pixel_width(), 16);
    assert_eq!(gen.get_tile_pixel_height(), 24);
}

#[test]
fn test_mapgen_set_get_orientation() {
    let mut gen = MapGen::new(MapSize::Small, 4);
    assert_eq!(gen.get_orientation(), MapOrientation::TopDown);
    gen.set_orientation(MapOrientation::SideView);
    assert_eq!(gen.get_orientation(), MapOrientation::SideView);
}

#[test]
fn test_mapgen_add_get_clear_zones() {
    let mut gen = MapGen::new(MapSize::Small, 4);
    assert_eq!(gen.get_zone_count(), 0);
    gen.add_zone("sky", 0, 3);
    gen.add_zone("ground", 3, 5);
    assert_eq!(gen.get_zone_count(), 2);
    let z = gen.get_zone(0).unwrap();
    assert_eq!(z.name, "sky");
    assert_eq!(z.start_row, 0);
    assert_eq!(z.height, 3);
    gen.clear_zones();
    assert_eq!(gen.get_zone_count(), 0);
}

#[test]
fn test_mapgen_get_zone_out_of_bounds() {
    let gen = MapGen::new(MapSize::Small, 4);
    assert!(gen.get_zone(0).is_none());
}

#[test]
fn test_mapgen_set_get_layer_mode() {
    let mut gen = MapGen::new(MapSize::Small, 4);
    assert_eq!(gen.get_layer_mode(), LayerMode::Unified);
    gen.set_layer_mode(LayerMode::Independent);
    assert_eq!(gen.get_layer_mode(), LayerMode::Independent);
}

#[test]
fn test_mapgen_generate_produces_tilemap_with_correct_structure() {
    let mut gen = MapGen::new(MapSize::Small, 4);
    let group = MapGroup::new("empty");
    let tilemap = gen.generate(&group, None, Some(42));
    assert_eq!(tilemap.get_layer_count(), 1);
    assert_eq!(tilemap.get_tileset_count(), 1);
    assert_eq!(tilemap.get_tile_dimensions(), (32, 32));
}

#[test]
fn test_mapgen_generate_with_fill_random_script() {
    let mut gen = MapGen::new(MapSize::Small, 4);
    let mut group = MapGroup::new("test");

    let mut block = MapBlock::new(2, 2, 1, 2);
    block.set_tile(0, 0, 0, 1);
    block.set_tile(0, 1, 0, 2);
    block.set_tile(0, 0, 1, 3);
    block.set_tile(0, 1, 1, 4);
    group.add_block(block);

    let mut script = MapScript::new("fill");
    script.add_step(ScriptStep {
        step_type: StepType::FillRandom,
        ..Default::default()
    });
    group.add_script(script);

    let tilemap = gen.generate(&group, Some(0), Some(123));
    // Should have some non-zero tiles from fill_random
    let map_size = 3 * 4; // grid_w * segment_size
    let mut has_nonzero = false;
    for y in 0..map_size {
        for x in 0..map_size {
            if tilemap.get_tile(0, x, y) != 0 {
                has_nonzero = true;
                break;
            }
        }
    }
    assert!(has_nonzero);
}

#[test]
fn test_mapgen_generate_world_produces_tilemap() {
    let mut gen = MapGen::new(MapSize::Small, 4);
    let group = MapGroup::new("test");
    let world = gen.generate_world(&group, 2, 2, None, Some(99));
    assert_eq!(world.get_layer_count(), 1);
    assert_eq!(world.get_tile_dimensions(), (32, 32));
}

#[test]
fn test_mapgen_placement_count_zero_without_script() {
    let mut gen = MapGen::new(MapSize::Small, 4);
    let group = MapGroup::new("empty");
    let _tilemap = gen.generate(&group, None, Some(1));
    assert_eq!(gen.get_placement_count(), 0);
}

#[test]
fn test_mapsize_grid_dimensions_all_variants() {
    assert_eq!(MapSize::Small.grid_dimensions(), (3, 3));
    assert_eq!(MapSize::Medium.grid_dimensions(), (5, 5));
    assert_eq!(MapSize::Large.grid_dimensions(), (6, 6));
    assert_eq!(MapSize::Custom(4, 7).grid_dimensions(), (4, 7));
    assert_eq!(MapSize::Custom(1, 1).grid_dimensions(), (1, 1));
}

#[test]
fn test_mapgen_generate_with_fill_rect_script() {
    let mut gen = MapGen::new(MapSize::Small, 4);
    let mut group = MapGroup::new("rect_test");
    group.add_block(MapBlock::new(2, 2, 1, 2));

    let mut script = MapScript::new("fill_rect");
    script.add_step(ScriptStep {
        step_type: StepType::FillRect,
        x: 1,
        y: 1,
        width: 3,
        height: 3,
        tile_id: 42,
        ..Default::default()
    });
    group.add_script(script);

    let tilemap = gen.generate(&group, Some(0), Some(0));
    // Tiles in the filled rect should be 42
    assert_eq!(tilemap.get_tile(0, 1, 1), 42);
    assert_eq!(tilemap.get_tile(0, 2, 2), 42);
    assert_eq!(tilemap.get_tile(0, 3, 3), 42);
    // Tile outside the rect should be 0
    assert_eq!(tilemap.get_tile(0, 0, 0), 0);
}

// ===================================================================
// Coords — Isometric tests
// ===================================================================

#[test]
fn test_coords_to_screen_iso_origin() {
    let v = to_screen_iso(0.0, 0.0, 64.0, 32.0);
    assert!((v.x - 0.0).abs() < 1e-5);
    assert!((v.y - 0.0).abs() < 1e-5);
}

#[test]
fn test_coords_to_from_screen_iso_roundtrip() {
    let tile_w = 64.0;
    let tile_h = 32.0;
    let screen = to_screen_iso(3.0, 2.0, tile_w, tile_h);
    let back = from_screen_iso(screen.x, screen.y, tile_w, tile_h);
    assert!((back.x - 3.0).abs() < 1e-5);
    assert!((back.y - 2.0).abs() < 1e-5);
}

#[test]
fn test_coords_to_from_screen_iso_negative_coords() {
    let tile_w = 64.0;
    let tile_h = 32.0;
    let screen = to_screen_iso(-1.0, 4.0, tile_w, tile_h);
    let back = from_screen_iso(screen.x, screen.y, tile_w, tile_h);
    assert!((back.x - (-1.0)).abs() < 1e-5);
    assert!((back.y - 4.0).abs() < 1e-5);
}

#[test]
fn test_coords_iso_rotate_identity() {
    for d in 1..=4 {
        assert_eq!(iso_rotate(d, 0), d);
    }
}

#[test]
fn test_coords_iso_rotate_clockwise_all() {
    assert_eq!(iso_rotate(1, 1), 2);
    assert_eq!(iso_rotate(2, 1), 3);
    assert_eq!(iso_rotate(3, 1), 4);
    assert_eq!(iso_rotate(4, 1), 1);
}

#[test]
fn test_coords_iso_rotate_counter_clockwise() {
    assert_eq!(iso_rotate(1, -1), 4);
    assert_eq!(iso_rotate(2, -1), 1);
    assert_eq!(iso_rotate(3, -1), 2);
    assert_eq!(iso_rotate(4, -1), 3);
}

#[test]
fn test_coords_iso_rotate_full_circle() {
    assert_eq!(iso_rotate(1, 4), 1);
    assert_eq!(iso_rotate(3, 8), 3);
}

#[test]
fn test_coords_iso_direction_name_valid() {
    assert_eq!(iso_direction_name(1), "south");
    assert_eq!(iso_direction_name(2), "west");
    assert_eq!(iso_direction_name(3), "north");
    assert_eq!(iso_direction_name(4), "east");
}

#[test]
fn test_coords_iso_direction_name_invalid_returns_unknown() {
    assert_eq!(iso_direction_name(0), "unknown");
    assert_eq!(iso_direction_name(5), "unknown");
    assert_eq!(iso_direction_name(-1), "unknown");
}

#[test]
fn test_coords_iso_direction_from_angle_cardinals() {
    assert_eq!(iso_direction_from_angle(0.0), 4); // east
    assert_eq!(iso_direction_from_angle(PI / 2.0), 1); // south
    assert_eq!(iso_direction_from_angle(PI), 2); // west
    assert_eq!(iso_direction_from_angle(-PI / 2.0), 3); // north
}

// ===================================================================
// Coords — Hexagonal tests
// ===================================================================

#[test]
fn test_coords_to_screen_hex_origin() {
    let v = to_screen_hex(0, 0, 20.0);
    assert!((v.x - 0.0).abs() < 1e-5);
    assert!((v.y - 0.0).abs() < 1e-5);
}

#[test]
fn test_coords_to_from_screen_hex_roundtrip() {
    let size = 20.0;
    let screen = to_screen_hex(3, -2, size);
    let (rq, rr) = from_screen_hex(screen.x, screen.y, size);
    assert_eq!((rq, rr), (3, -2));
}

#[test]
fn test_coords_to_from_screen_hex_roundtrip_negative() {
    let size = 15.0;
    let screen = to_screen_hex(-2, 5, size);
    let (rq, rr) = from_screen_hex(screen.x, screen.y, size);
    assert_eq!((rq, rr), (-2, 5));
}

#[test]
fn test_coords_hex_neighbors_six_at_distance_one() {
    let n = hex_neighbors(0, 0);
    assert_eq!(n.len(), 6);
    for (q, r) in &n {
        assert_eq!(hex_distance(0, 0, *q, *r), 1);
    }
}

#[test]
fn test_coords_hex_neighbors_offset_center() {
    let n = hex_neighbors(2, -1);
    for (q, r) in &n {
        assert_eq!(hex_distance(2, -1, *q, *r), 1);
    }
}

#[test]
fn test_coords_hex_distance_zero_same_cell() {
    assert_eq!(hex_distance(0, 0, 0, 0), 0);
    assert_eq!(hex_distance(3, -2, 3, -2), 0);
}

#[test]
fn test_coords_hex_distance_adjacent() {
    assert_eq!(hex_distance(0, 0, 1, 0), 1);
    assert_eq!(hex_distance(0, 0, 0, 1), 1);
    assert_eq!(hex_distance(0, 0, -1, 1), 1);
}

#[test]
fn test_coords_hex_distance_farther() {
    assert_eq!(hex_distance(0, 0, 2, -1), 2);
    assert_eq!(hex_distance(0, 0, 3, -3), 3);
}

#[test]
fn test_coords_hex_round_exact_values() {
    assert_eq!(hex_round(1.0, 2.0), (1, 2));
    assert_eq!(hex_round(0.0, 0.0), (0, 0));
    assert_eq!(hex_round(-3.0, 2.0), (-3, 2));
}

#[test]
fn test_coords_hex_round_fractional() {
    assert_eq!(hex_round(0.1, -0.1), (0, 0));
    assert_eq!(hex_round(0.9, 0.1), (1, 0));
}

#[test]
fn test_coords_hex_line_same_point() {
    let line = hex_line(2, 3, 2, 3);
    assert_eq!(line.len(), 1);
    assert_eq!(line[0], (2, 3));
}

#[test]
fn test_coords_hex_line_straight() {
    let line = hex_line(0, 0, 3, 0);
    assert_eq!(line.len(), 4);
    assert_eq!(line[0], (0, 0));
    assert_eq!(line[3], (3, 0));
}

#[test]
fn test_coords_hex_line_endpoints() {
    let line = hex_line(1, -2, 4, 1);
    assert_eq!(*line.first().unwrap(), (1, -2));
    assert_eq!(*line.last().unwrap(), (4, 1));
}

#[test]
fn test_coords_hex_ring_radius_zero_center_only() {
    let ring = hex_ring(2, 3, 0);
    assert_eq!(ring, vec![(2, 3)]);
}

#[test]
fn test_coords_hex_ring_radius_one_six_cells() {
    let ring = hex_ring(0, 0, 1);
    assert_eq!(ring.len(), 6);
    for (q, r) in &ring {
        assert_eq!(hex_distance(0, 0, *q, *r), 1);
    }
}

#[test]
fn test_coords_hex_ring_radius_two_twelve_cells() {
    let ring = hex_ring(0, 0, 2);
    assert_eq!(ring.len(), 12);
    for (q, r) in &ring {
        assert_eq!(hex_distance(0, 0, *q, *r), 2);
    }
}

#[test]
fn test_coords_hex_spiral_count() {
    assert_eq!(hex_spiral(0, 0, 0).len(), 1);
    assert_eq!(hex_spiral(0, 0, 1).len(), 7);
    assert_eq!(hex_spiral(0, 0, 2).len(), 19);
}

#[test]
fn test_coords_hex_spiral_includes_center() {
    let spiral = hex_spiral(1, 1, 1);
    assert!(spiral.contains(&(1, 1)));
}

#[test]
fn test_coords_hex_area_radius_zero() {
    let area = hex_area(0, 0, 0);
    assert_eq!(area, vec![(0, 0)]);
}

#[test]
fn test_coords_hex_area_counts() {
    // Area of radius r = 3r^2 + 3r + 1
    assert_eq!(hex_area(0, 0, 1).len(), 7);
    assert_eq!(hex_area(0, 0, 2).len(), 19);
    assert_eq!(hex_area(0, 0, 3).len(), 37);
}

#[test]
fn test_coords_hex_area_superset_of_ring() {
    let area = hex_area(0, 0, 2);
    let ring = hex_ring(0, 0, 2);
    for cell in &ring {
        assert!(area.contains(cell));
    }
}

#[test]
fn test_coords_hex_rotate_one_step() {
    let (rq, rr) = hex_rotate(1, 0, 0, 0, 1);
    assert_eq!((rq, rr), (0, 1));
}

#[test]
fn test_coords_hex_rotate_full_circle_identity() {
    let (rq, rr) = hex_rotate(2, -1, 0, 0, 6);
    assert_eq!((rq, rr), (2, -1));
}

#[test]
fn test_coords_hex_rotate_negative_steps_equals_positive() {
    let (rq1, rr1) = hex_rotate(1, 0, 0, 0, -1);
    let (rq2, rr2) = hex_rotate(1, 0, 0, 0, 5);
    assert_eq!((rq1, rr1), (rq2, rr2));
}

#[test]
fn test_coords_hex_reflect_q_axis() {
    let (rq, rr) = hex_reflect(1, 2, 0, 0, "q");
    assert_eq!((rq, rr), (1, -3));
}

#[test]
fn test_coords_hex_reflect_r_axis() {
    let (rq, rr) = hex_reflect(1, 2, 0, 0, "r");
    assert_eq!((rq, rr), (-3, 2));
}

#[test]
fn test_coords_hex_reflect_s_axis() {
    let (rq, rr) = hex_reflect(1, 2, 0, 0, "s");
    assert_eq!((rq, rr), (2, 1));
}

#[test]
fn test_coords_hex_reflect_unknown_axis_identity() {
    let (rq, rr) = hex_reflect(3, -1, 0, 0, "invalid");
    assert_eq!((rq, rr), (3, -1));
}

#[test]
fn test_coords_hex_reflect_double_is_identity() {
    let (rq, rr) = hex_reflect(2, -3, 0, 0, "q");
    let (rq2, rr2) = hex_reflect(rq, rr, 0, 0, "q");
    assert_eq!((rq2, rr2), (2, -3));
}

// ===================================================================
// IsoMap tests
// ===================================================================

/// A 10×10 map with 64×32 tiles, 24-pixel level height, and 2 pre-added levels.
fn make_iso_map() -> IsoMap {
    let mut m = IsoMap::new(10, 10, 64, 32, 24);
    m.add_level();
    m.add_level();
    m
}

#[test]
fn test_isomap_construction() {
    let m = IsoMap::new(10, 10, 64, 32, 24);
    assert_eq!(m.width, 10);
    assert_eq!(m.height, 10);
    assert_eq!(m.tile_w, 64);
    assert_eq!(m.tile_h, 32);
    assert_eq!(m.level_height, 24);
    assert_eq!(m.get_level_count(), 0);
}

#[test]
fn test_isomap_add_level() {
    let mut m = make_iso_map();
    // make_iso_map adds 2 levels; 0-based indices 0 and 1
    assert_eq!(m.get_level_count(), 2);
    let idx = m.add_level();
    assert_eq!(idx, 2); // 0-based
    assert_eq!(m.get_level_count(), 3);
}

#[test]
fn test_isomap_tile_part_get_set() {
    let mut m = make_iso_map();
    // floor (part 0)
    m.set_tile_part(0, 3, 4, 0, 99);
    assert_eq!(m.get_tile_part(0, 3, 4, 0), 99);
    // other parts untouched
    assert_eq!(m.get_tile_part(0, 3, 4, 1), 0);
    // north wall (part 1) on level 1
    m.set_tile_part(1, 1, 1, 1, 42);
    assert_eq!(m.get_tile_part(1, 1, 1, 1), 42);
}

#[test]
fn test_isomap_tile_part_oob() {
    let m = make_iso_map();
    // x/y out of bounds
    assert_eq!(m.get_tile_part(0, 99, 99, 0), 0);
    // level OOB
    assert_eq!(m.get_tile_part(5, 0, 0, 0), 0);
    // part OOB
    assert_eq!(m.get_tile_part(0, 0, 0, 4), 0);
}

#[test]
fn test_isomap_fill_level() {
    let mut m = make_iso_map();
    m.fill_level(0, 0, 7); // fill level 0 floor with GID 7
    for y in 0..10 {
        for x in 0..10 {
            assert_eq!(m.get_tile_part(0, x, y, 0), 7);
            assert_eq!(m.get_tile_part(0, x, y, 1), 0); // north-wall untouched
        }
    }
    // Level 1 unchanged
    assert_eq!(m.get_tile_part(1, 0, 0, 0), 0);
}

#[test]
fn test_isomap_tile_to_screen() {
    let mut m = IsoMap::new(10, 10, 64, 32, 24);
    m.set_origin(400.0, 50.0);

    // (0,0) Z=0: sx=400, sy=50
    let (sx, sy) = m.tile_to_screen(0.0, 0.0, 0.0);
    assert!((sx - 400.0).abs() < 1e-4, "sx={}", sx);
    assert!((sy - 50.0).abs() < 1e-4, "sy={}", sy);

    // (1,0) Z=0: sx = 400 + 32 = 432, sy = 50 + 16 = 66
    let (sx, sy) = m.tile_to_screen(1.0, 0.0, 0.0);
    assert!((sx - 432.0).abs() < 1e-4, "sx={}", sx);
    assert!((sy - 66.0).abs() < 1e-4, "sy={}", sy);

    // Z-level offset: Z=1 subtracts 24 from sy
    let (_, sy2) = m.tile_to_screen(1.0, 0.0, 1.0);
    assert!((sy2 - (66.0 - 24.0)).abs() < 1e-4, "sy2={}", sy2);
}

#[test]
fn test_isomap_screen_to_tile() {
    let mut m = IsoMap::new(10, 10, 64, 32, 24);
    m.set_origin(200.0, 100.0);

    let (sx, sy) = m.tile_to_screen(3.0, 2.0, 0.0);
    let (tx, ty) = m.screen_to_tile(sx, sy);
    assert!((tx - 3.0).abs() < 1e-4, "tx={}", tx);
    assert!((ty - 2.0).abs() < 1e-4, "ty={}", ty);
}

#[test]
fn test_isomap_draw_iter_order() {
    let mut m = IsoMap::new(2, 2, 64, 32, 24);
    m.add_level();
    let items = m.draw_iter(0);
    // 4 cells × 4 parts = 16 items
    assert_eq!(items.len(), 16);

    // Diagonal 0: (0,0)
    assert_eq!((items[0].tile_x, items[0].tile_y, items[0].part), (0, 0, 0));

    // Diagonal 1 first tile: (0,1)
    assert_eq!((items[4].tile_x, items[4].tile_y), (0, 1));

    // Diagonal 1 second tile: (1,0)
    assert_eq!((items[8].tile_x, items[8].tile_y), (1, 0));

    // Diagonal 2: (1,1)
    assert_eq!((items[12].tile_x, items[12].tile_y), (1, 1));
}

#[test]
fn test_isomap_draw_iter_skips_empty() {
    // gid=0 items ARE yielded; callers decide to skip them
    let mut m = IsoMap::new(1, 1, 64, 32, 24);
    m.add_level();
    let items = m.draw_iter(0);
    // All 4 parts are returned even though all GIDs are 0
    assert_eq!(items.len(), 4);
    assert!(items.iter().all(|i| i.gid == 0));
}

#[test]
fn test_isomap_level_visible() {
    let mut m = IsoMap::new(1, 1, 64, 32, 24);
    m.add_level();
    m.add_level();

    // Hide level 0
    m.set_level_visible(0, false);
    assert!(!m.get_level_visible(0));
    assert!(m.get_level_visible(1));

    let items = m.draw_iter(1);
    assert_eq!(items.len(), 4); // only level 1
    assert!(items.iter().all(|i| i.level == 1));
}

#[test]
fn test_isomap_active_z_clamp() {
    let mut m = IsoMap::new(1, 1, 64, 32, 24);
    m.add_level(); // only level 0
                   // active_z=10 clamped to 0 — should not panic
    let items = m.draw_iter(10);
    assert_eq!(items.len(), 4);
}
