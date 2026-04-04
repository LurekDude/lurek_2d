//! Integration tests for Phase 24 graphics extension types.

use luna2d::graphics::animation::{AnimEvent, Animation};
use luna2d::graphics::camera::Camera2D;
use luna2d::graphics::column_batch::ColumnBatch;
use luna2d::graphics::decal_surface::DecalSurface;
use luna2d::graphics::draw_layer::DrawLayer;
use luna2d::graphics::graph_renderer::GraphRenderer;
use luna2d::graphics::large_map_renderer::LargeMapRenderer;
use luna2d::graphics::light2d::Light2D;
use luna2d::graphics::palette_lut::PaletteLUT;
use luna2d::graphics::polygon_map::PolygonMap;
use luna2d::graphics::sprite_sheet::{DirectionLayout, SpriteSheet};
use luna2d::graphics::texture_atlas::TextureAtlas;
use luna2d::graphics::trail::Trail;
use luna2d::graphics::viewport::{ScaleMode, Viewport};
use luna2d::graphics::viewport_scale::ViewportScale;
use luna2d::graphics::Color;
use luna2d::math::Rect;

// ═════════════════════════════════════════════════════════════════════════
// 1. Light2D
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_light2d_new_defaults() {
    let l = Light2D::new(100.0, 200.0, 50.0);
    assert!((l.x - 100.0).abs() < 1e-5);
    assert!((l.y - 200.0).abs() < 1e-5);
    assert!((l.get_radius() - 50.0).abs() < 1e-5);
    assert!((l.get_intensity() - 1.0).abs() < 1e-5);
    assert!(l.is_enabled());
    assert_eq!(l.get_color(), Color::WHITE);
}

#[test]
fn test_light2d_set_position() {
    let mut l = Light2D::new(0.0, 0.0, 10.0);
    l.set_position(42.0, 99.0);
    let (px, py) = l.get_position();
    assert!((px - 42.0).abs() < 1e-5);
    assert!((py - 99.0).abs() < 1e-5);
}

#[test]
fn test_light2d_set_radius() {
    let mut l = Light2D::new(0.0, 0.0, 10.0);
    l.set_radius(200.0);
    assert!((l.get_radius() - 200.0).abs() < 1e-5);
}

#[test]
fn test_light2d_set_color() {
    let mut l = Light2D::new(0.0, 0.0, 10.0);
    l.set_color(Color::RED);
    assert_eq!(l.get_color(), Color::RED);
}

#[test]
fn test_light2d_set_intensity() {
    let mut l = Light2D::new(0.0, 0.0, 10.0);
    l.set_intensity(0.5);
    assert!((l.get_intensity() - 0.5).abs() < 1e-5);
}

#[test]
fn test_light2d_set_enabled() {
    let mut l = Light2D::new(0.0, 0.0, 10.0);
    assert!(l.is_enabled());
    l.set_enabled(false);
    assert!(!l.is_enabled());
    l.set_enabled(true);
    assert!(l.is_enabled());
}

// ═════════════════════════════════════════════════════════════════════════
// 2. TextureAtlas
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_texture_atlas_new_empty() {
    let atlas = TextureAtlas::new(256, 256, 1);
    assert_eq!(atlas.get_region_count(), 0);
    assert_eq!(atlas.get_dimensions(), (256, 256));
}

#[test]
fn test_texture_atlas_pack_single() {
    let mut atlas = TextureAtlas::new(256, 256, 1);
    assert!(atlas.pack("tile1", 32, 32));
    assert_eq!(atlas.get_region_count(), 1);
    let region = atlas.get_region("tile1");
    assert!(region.is_some());
    let r = region.unwrap();
    assert_eq!(r.w, 32);
    assert_eq!(r.h, 32);
}

#[test]
fn test_texture_atlas_pack_multiple() {
    let mut atlas = TextureAtlas::new(256, 256, 1);
    assert!(atlas.pack("a", 32, 32));
    assert!(atlas.pack("b", 32, 32));
    assert!(atlas.pack("c", 32, 32));
    assert_eq!(atlas.get_region_count(), 3);
    let regions = atlas.get_regions();
    assert_eq!(regions.len(), 3);
}

#[test]
fn test_texture_atlas_pack_overflow() {
    let mut atlas = TextureAtlas::new(64, 64, 0);
    // 64x64 atlas, 64x64 tile -> fits exactly once
    assert!(atlas.pack("big", 64, 64));
    // Second 64x64 won't fit
    assert!(!atlas.pack("too_big", 64, 64));
}

#[test]
fn test_texture_atlas_get_nonexistent_region() {
    let atlas = TextureAtlas::new(256, 256, 0);
    assert!(atlas.get_region("nope").is_none());
}

#[test]
fn test_texture_atlas_clear() {
    let mut atlas = TextureAtlas::new(256, 256, 0);
    atlas.pack("a", 32, 32);
    atlas.pack("b", 32, 32);
    assert_eq!(atlas.get_region_count(), 2);
    atlas.clear();
    assert_eq!(atlas.get_region_count(), 0);
    assert!(atlas.get_region("a").is_none());
}

// ═════════════════════════════════════════════════════════════════════════
// 3. DrawLayer
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_draw_layer_new_empty() {
    let layer = DrawLayer::new();
    assert_eq!(layer.get_count(), 0);
}

#[test]
fn test_draw_layer_queue_entries() {
    let mut layer = DrawLayer::new();
    let id0 = layer.queue(1.0);
    let id1 = layer.queue(0.5);
    assert_eq!(layer.get_count(), 2);
    assert_ne!(id0, id1);
}

#[test]
fn test_draw_layer_flush_returns_sorted() {
    let mut layer = DrawLayer::new();
    layer.queue(3.0);
    layer.queue(1.0);
    layer.queue(2.0);
    let entries = layer.flush();
    assert_eq!(entries.len(), 3);
    assert!(entries[0].z_order <= entries[1].z_order);
    assert!(entries[1].z_order <= entries[2].z_order);
    // Queue should be empty after flush
    assert_eq!(layer.get_count(), 0);
}

#[test]
fn test_draw_layer_clear() {
    let mut layer = DrawLayer::new();
    layer.queue(1.0);
    layer.queue(2.0);
    layer.clear();
    assert_eq!(layer.get_count(), 0);
}

#[test]
fn test_draw_layer_unique_ids() {
    let mut layer = DrawLayer::new();
    let ids: Vec<usize> = (0..10).map(|i| layer.queue(i as f64)).collect();
    // All IDs must be unique
    for i in 0..ids.len() {
        for j in (i + 1)..ids.len() {
            assert_ne!(ids[i], ids[j]);
        }
    }
}

// ═════════════════════════════════════════════════════════════════════════
// 4. Viewport
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_viewport_new_identity() {
    let vp = Viewport::new(800.0, 600.0, ScaleMode::Letterbox);
    let (gw, gh) = vp.get_game_dimensions();
    assert!((gw - 800.0).abs() < 1e-5);
    assert!((gh - 600.0).abs() < 1e-5);
    let (sx, sy) = vp.get_scale();
    assert!((sx - 1.0).abs() < 1e-5);
    assert!((sy - 1.0).abs() < 1e-5);
    let (ox, oy) = vp.get_offset();
    assert!((ox).abs() < 1e-5);
    assert!((oy).abs() < 1e-5);
}

#[test]
fn test_viewport_letterbox_resize() {
    let mut vp = Viewport::new(800.0, 600.0, ScaleMode::Letterbox);
    vp.resize(1600.0, 900.0);
    let (sx, sy) = vp.get_scale();
    // Letterbox: uniform scale = min(1600/800, 900/600) = min(2.0, 1.5) = 1.5
    assert!((sx - 1.5).abs() < 1e-5);
    assert!((sy - 1.5).abs() < 1e-5);
    // offset_x = (1600 - 800*1.5)/2 = (1600-1200)/2 = 200
    let (ox, _oy) = vp.get_offset();
    assert!((ox - 200.0).abs() < 1e-5);
}

#[test]
fn test_viewport_stretch_resize() {
    let mut vp = Viewport::new(800.0, 600.0, ScaleMode::Stretch);
    vp.resize(1600.0, 1200.0);
    let (sx, sy) = vp.get_scale();
    assert!((sx - 2.0).abs() < 1e-5);
    assert!((sy - 2.0).abs() < 1e-5);
    let (ox, oy) = vp.get_offset();
    assert!((ox).abs() < 1e-5);
    assert!((oy).abs() < 1e-5);
}

#[test]
fn test_viewport_pixel_perfect_resize() {
    let mut vp = Viewport::new(320.0, 240.0, ScaleMode::PixelPerfect);
    vp.resize(700.0, 500.0);
    let (sx, sy) = vp.get_scale();
    // min(700/320, 500/240) = min(2.1875, 2.0833) = 2.0833 -> floor = 2.0
    assert!((sx - 2.0).abs() < 1e-5);
    assert!((sy - 2.0).abs() < 1e-5);
}

#[test]
fn test_viewport_to_game_to_screen_roundtrip() {
    let mut vp = Viewport::new(800.0, 600.0, ScaleMode::Letterbox);
    vp.resize(1600.0, 1200.0);
    let game_x = 100.0;
    let game_y = 200.0;
    let (sx, sy) = vp.to_screen(game_x, game_y);
    let (gx, gy) = vp.to_game(sx, sy);
    assert!((gx - game_x).abs() < 1e-3);
    assert!((gy - game_y).abs() < 1e-3);
}

#[test]
fn test_viewport_set_scale_mode() {
    let mut vp = Viewport::new(800.0, 600.0, ScaleMode::Letterbox);
    assert_eq!(*vp.get_scale_mode(), ScaleMode::Letterbox);
    vp.set_scale_mode(ScaleMode::Stretch);
    assert_eq!(*vp.get_scale_mode(), ScaleMode::Stretch);
}

// ═════════════════════════════════════════════════════════════════════════
// 5. ViewportScale
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_viewport_scale_new_identity() {
    let vps = ViewportScale::new(800.0, 600.0, ScaleMode::Letterbox);
    let (gw, gh) = vps.get_game_dimensions();
    assert!((gw - 800.0).abs() < 1e-5);
    assert!((gh - 600.0).abs() < 1e-5);
    let (sw, sh) = vps.get_scaled_dimensions();
    assert!((sw - 800.0).abs() < 1e-5);
    assert!((sh - 600.0).abs() < 1e-5);
}

#[test]
fn test_viewport_scale_resize_letterbox() {
    let mut vps = ViewportScale::new(800.0, 600.0, ScaleMode::Letterbox);
    vps.resize(1600.0, 900.0);
    let (sx, sy) = vps.get_scale();
    assert!((sx - 1.5).abs() < 1e-5);
    assert!((sy - 1.5).abs() < 1e-5);
    let (sw, sh) = vps.get_scaled_dimensions();
    assert!((sw - 1200.0).abs() < 1e-5);
    assert!((sh - 900.0).abs() < 1e-5);
}

#[test]
fn test_viewport_scale_to_game_to_screen_roundtrip() {
    let mut vps = ViewportScale::new(800.0, 600.0, ScaleMode::Letterbox);
    vps.resize(1600.0, 1200.0);
    let game_x = 150.0;
    let game_y = 250.0;
    let (sx, sy) = vps.to_screen_coords(game_x, game_y);
    let (gx, gy) = vps.to_game_coords(sx, sy);
    assert!((gx - game_x).abs() < 1e-3);
    assert!((gy - game_y).abs() < 1e-3);
}

#[test]
fn test_viewport_scale_get_mode() {
    let vps = ViewportScale::new(800.0, 600.0, ScaleMode::Stretch);
    assert_eq!(*vps.get_mode(), ScaleMode::Stretch);
}

#[test]
fn test_viewport_scale_offset_stretch() {
    let mut vps = ViewportScale::new(400.0, 300.0, ScaleMode::Stretch);
    vps.resize(800.0, 600.0);
    let (ox, oy) = vps.get_offset();
    assert!((ox).abs() < 1e-5);
    assert!((oy).abs() < 1e-5);
}

// ═════════════════════════════════════════════════════════════════════════
// 6. SpriteSheet
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_sprite_sheet_frame_count() {
    let ss = SpriteSheet::new(256, 256, 32, 32);
    assert_eq!(ss.get_frame_count(), 64);
}

#[test]
fn test_sprite_sheet_grid_size() {
    let ss = SpriteSheet::new(256, 256, 32, 32);
    assert_eq!(ss.get_grid_size(), (8, 8));
}

#[test]
fn test_sprite_sheet_get_frame_first() {
    let ss = SpriteSheet::new(256, 256, 32, 32);
    let f = ss.get_frame(0).unwrap();
    assert!((f.x).abs() < 1e-5);
    assert!((f.y).abs() < 1e-5);
    assert!((f.width - 32.0).abs() < 1e-5);
    assert!((f.height - 32.0).abs() < 1e-5);
}

#[test]
fn test_sprite_sheet_get_frame_second() {
    let ss = SpriteSheet::new(256, 256, 32, 32);
    let f = ss.get_frame(1).unwrap();
    assert!((f.x - 32.0).abs() < 1e-5);
    assert!((f.y).abs() < 1e-5);
}

#[test]
fn test_sprite_sheet_get_frame_out_of_bounds() {
    let ss = SpriteSheet::new(256, 256, 32, 32);
    assert!(ss.get_frame(64).is_none());
    assert!(ss.get_frame(100).is_none());
}

#[test]
fn test_sprite_sheet_get_row() {
    let ss = SpriteSheet::new(256, 256, 32, 32);
    let row0 = ss.get_row(0);
    assert_eq!(row0.len(), 8);
    assert!((row0[0].x).abs() < 1e-5);
    assert!((row0[7].x - 224.0).abs() < 1e-5);
}

#[test]
fn test_sprite_sheet_get_column() {
    let ss = SpriteSheet::new(256, 256, 32, 32);
    let col0 = ss.get_column(0);
    assert_eq!(col0.len(), 8);
    assert!((col0[0].y).abs() < 1e-5);
    assert!((col0[7].y - 224.0).abs() < 1e-5);
}

#[test]
fn test_sprite_sheet_get_range() {
    let ss = SpriteSheet::new(256, 256, 32, 32);
    let range = ss.get_range(0, 4);
    assert_eq!(range.len(), 4);
}

#[test]
fn test_sprite_sheet_named_groups() {
    let mut ss = SpriteSheet::new(256, 256, 32, 32);
    ss.name_group("walk", 0, 4);
    let group = ss.get_group("walk");
    assert!(group.is_some());
    assert_eq!(group.unwrap().len(), 4);
    assert!(ss.get_group_names().contains(&"walk".to_string()));
}

#[test]
fn test_sprite_sheet_get_group_nonexistent() {
    let ss = SpriteSheet::new(256, 256, 32, 32);
    assert!(ss.get_group("nope").is_none());
}

#[test]
fn test_sprite_sheet_directions_rows() {
    let mut ss = SpriteSheet::new(256, 256, 32, 32);
    ss.set_directions(4, DirectionLayout::Rows);
    let dir0 = ss.get_direction_frames(0);
    assert!(dir0.is_some());
    assert_eq!(dir0.unwrap().len(), 8); // row has 8 columns
    let dir4 = ss.get_direction_frames(4);
    assert!(dir4.is_none()); // only 4 directions requested
}

#[test]
fn test_sprite_sheet_directions_columns() {
    let mut ss = SpriteSheet::new(256, 256, 32, 32);
    ss.set_directions(4, DirectionLayout::Columns);
    let dir0 = ss.get_direction_frames(0);
    assert!(dir0.is_some());
    assert_eq!(dir0.unwrap().len(), 8); // column has 8 rows
}

#[test]
fn test_sprite_sheet_frame_size() {
    let ss = SpriteSheet::new(128, 64, 16, 32);
    assert_eq!(ss.get_frame_size(), (16, 32));
    assert_eq!(ss.get_frame_count(), 16); // (128/16)*(64/32)=8*2=16
}

// ═════════════════════════════════════════════════════════════════════════
// 7. PolygonMap
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_polygon_map_new_empty() {
    let pm = PolygonMap::new();
    assert!(pm.get_region_names().is_empty());
    assert!(pm.get_bounding_box().is_none());
}

#[test]
fn test_polygon_map_add_region_and_query() {
    let mut pm = PolygonMap::new();
    pm.add_region(
        "zone1",
        vec![0.0, 0.0, 100.0, 0.0, 100.0, 100.0, 0.0, 100.0],
        Color::RED,
    );
    // Point inside polygon
    let hit = pm.get_region_at(50.0, 50.0);
    assert_eq!(hit, Some("zone1"));
    // Point outside polygon
    let miss = pm.get_region_at(200.0, 200.0);
    assert!(miss.is_none());
}

#[test]
fn test_polygon_map_region_names() {
    let mut pm = PolygonMap::new();
    pm.add_region("a", vec![0.0, 0.0, 10.0, 0.0, 10.0, 10.0], Color::WHITE);
    pm.add_region("b", vec![20.0, 0.0, 30.0, 0.0, 30.0, 10.0], Color::WHITE);
    let names = pm.get_region_names();
    assert_eq!(names.len(), 2);
    assert!(names.contains(&"a".to_string()));
    assert!(names.contains(&"b".to_string()));
}

#[test]
fn test_polygon_map_region_vertices() {
    let mut pm = PolygonMap::new();
    let verts = vec![0.0, 0.0, 100.0, 0.0, 100.0, 100.0, 0.0, 100.0];
    pm.add_region("zone1", verts.clone(), Color::WHITE);
    let got = pm.get_region_vertices("zone1").unwrap();
    assert_eq!(got, verts.as_slice());
}

#[test]
fn test_polygon_map_region_center() {
    let mut pm = PolygonMap::new();
    pm.add_region(
        "square",
        vec![0.0, 0.0, 100.0, 0.0, 100.0, 100.0, 0.0, 100.0],
        Color::WHITE,
    );
    let (cx, cy) = pm.get_region_center("square").unwrap();
    assert!((cx - 50.0).abs() < 1e-5);
    assert!((cy - 50.0).abs() < 1e-5);
}

#[test]
fn test_polygon_map_bounding_box() {
    let mut pm = PolygonMap::new();
    pm.add_region(
        "r1",
        vec![10.0, 20.0, 110.0, 20.0, 110.0, 120.0, 10.0, 120.0],
        Color::WHITE,
    );
    let (bx, by, bw, bh) = pm.get_bounding_box().unwrap();
    assert!((bx - 10.0).abs() < 1e-5);
    assert!((by - 20.0).abs() < 1e-5);
    assert!((bw - 100.0).abs() < 1e-5);
    assert!((bh - 100.0).abs() < 1e-5);
}

#[test]
fn test_polygon_map_remove_region() {
    let mut pm = PolygonMap::new();
    pm.add_region("zone1", vec![0.0, 0.0, 10.0, 0.0, 10.0, 10.0], Color::WHITE);
    assert!(pm.remove_region("zone1"));
    assert!(!pm.remove_region("zone1")); // already removed
    assert!(pm.get_region_at(5.0, 5.0).is_none());
}

#[test]
fn test_polygon_map_set_region_color() {
    let mut pm = PolygonMap::new();
    pm.add_region("z", vec![0.0, 0.0, 10.0, 0.0, 10.0, 10.0], Color::WHITE);
    assert!(pm.set_region_color("z", Color::BLUE));
    assert_eq!(pm.get_region_color("z"), Some(Color::BLUE));
    assert!(!pm.set_region_color("nope", Color::RED));
}

#[test]
fn test_polygon_map_highlight() {
    let mut pm = PolygonMap::new();
    pm.add_region("z", vec![0.0, 0.0, 10.0, 0.0, 10.0, 10.0], Color::WHITE);
    pm.highlight("z");
    assert_eq!(pm.highlighted.as_deref(), Some("z"));
    pm.clear_highlight();
    assert!(pm.highlighted.is_none());
}

#[test]
fn test_polygon_map_clear() {
    let mut pm = PolygonMap::new();
    pm.add_region("a", vec![0.0, 0.0, 10.0, 0.0, 10.0, 10.0], Color::WHITE);
    pm.add_region("b", vec![20.0, 0.0, 30.0, 0.0, 30.0, 10.0], Color::WHITE);
    pm.highlight("a");
    pm.clear();
    assert!(pm.get_region_names().is_empty());
    assert!(pm.highlighted.is_none());
}

// ═════════════════════════════════════════════════════════════════════════
// 8. GraphRenderer
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_graph_renderer_new_defaults() {
    let gr = GraphRenderer::new();
    assert_eq!(gr.get_series_names().len(), 0);
    assert!(gr.show_grid);
    assert!(gr.show_axes);
}

#[test]
fn test_graph_renderer_set_viewport() {
    let mut gr = GraphRenderer::new();
    gr.set_viewport(10.0, 20.0, 400.0, 300.0);
    let (x, y, w, h) = gr.get_viewport();
    assert!((x - 10.0).abs() < 1e-5);
    assert!((y - 20.0).abs() < 1e-5);
    assert!((w - 400.0).abs() < 1e-5);
    assert!((h - 300.0).abs() < 1e-5);
}

#[test]
fn test_graph_renderer_add_line_series() {
    let mut gr = GraphRenderer::new();
    gr.add_line_series("s1", vec![(0.0, 0.0), (1.0, 1.0)], Color::RED);
    assert_eq!(gr.get_series_names().len(), 1);
    assert!(gr.get_series_names().contains(&"s1".to_string()));
}

#[test]
fn test_graph_renderer_add_scatter_series() {
    let mut gr = GraphRenderer::new();
    gr.add_scatter_series("dots", vec![(1.0, 2.0), (3.0, 4.0)], Color::GREEN, 5.0);
    assert_eq!(gr.get_series_names().len(), 1);
}

#[test]
fn test_graph_renderer_add_bar_series() {
    let mut gr = GraphRenderer::new();
    gr.add_bar_series("bars", vec![10.0, 20.0, 30.0], Color::BLUE);
    assert_eq!(gr.get_series_names().len(), 1);
}

#[test]
fn test_graph_renderer_remove_series() {
    let mut gr = GraphRenderer::new();
    gr.add_line_series("s1", vec![(0.0, 0.0)], Color::WHITE);
    assert!(gr.remove_series("s1"));
    assert!(!gr.remove_series("s1")); // already removed
    assert_eq!(gr.get_series_names().len(), 0);
}

#[test]
fn test_graph_renderer_clear_series() {
    let mut gr = GraphRenderer::new();
    gr.add_line_series("a", vec![(0.0, 0.0)], Color::WHITE);
    gr.add_line_series("b", vec![(1.0, 1.0)], Color::RED);
    gr.clear_series();
    assert_eq!(gr.get_series_names().len(), 0);
}

#[test]
fn test_graph_renderer_auto_range() {
    let mut gr = GraphRenderer::new();
    gr.add_line_series("s1", vec![(0.0, 0.0), (10.0, 20.0)], Color::WHITE);
    gr.auto_range();
    let (x_min, x_max, y_min, y_max) = gr.get_range();
    // Data spans 0..10 in x, 0..20 in y with 10% padding
    assert!(x_min < 0.0);
    assert!(x_max > 10.0);
    assert!(y_min < 0.0);
    assert!(y_max > 20.0);
}

#[test]
fn test_graph_renderer_show_grid_axes() {
    let mut gr = GraphRenderer::new();
    gr.set_show_grid(false);
    assert!(!gr.show_grid);
    gr.set_show_axes(false);
    assert!(!gr.show_axes);
}

#[test]
fn test_graph_renderer_set_range() {
    let mut gr = GraphRenderer::new();
    gr.set_range(0.0, 100.0, -50.0, 50.0);
    let (x_min, x_max, y_min, y_max) = gr.get_range();
    assert!((x_min - 0.0).abs() < 1e-10);
    assert!((x_max - 100.0).abs() < 1e-10);
    assert!((y_min - (-50.0)).abs() < 1e-10);
    assert!((y_max - 50.0).abs() < 1e-10);
}

#[test]
fn test_graph_renderer_world_to_screen() {
    let mut gr = GraphRenderer::new();
    gr.set_viewport(0.0, 0.0, 400.0, 300.0);
    gr.set_range(0.0, 100.0, 0.0, 100.0);
    let (sx, sy) = gr.world_to_screen(50.0, 50.0);
    // x: 0 + (50/100)*400 = 200
    assert!((sx - 200.0).abs() < 1e-3);
    // y: 0 + 300 - (50/100)*300 = 150
    assert!((sy - 150.0).abs() < 1e-3);
}

// ═════════════════════════════════════════════════════════════════════════
// 9. LargeMapRenderer
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_large_map_renderer_new_empty() {
    let lmr = LargeMapRenderer::new(32, 32);
    assert_eq!(lmr.get_map_size(), (0, 0));
}

#[test]
fn test_large_map_renderer_set_map_data() {
    let mut lmr = LargeMapRenderer::new(32, 32);
    lmr.set_map_data(vec![1; 100], 10, 10);
    assert_eq!(lmr.get_map_size(), (10, 10));
    assert_eq!(lmr.get_tile(0, 0), Some(1));
    assert_eq!(lmr.get_tile(9, 9), Some(1));
}

#[test]
fn test_large_map_renderer_set_tile() {
    let mut lmr = LargeMapRenderer::new(32, 32);
    lmr.set_map_data(vec![0; 100], 10, 10);
    lmr.set_tile(0, 0, 5);
    assert_eq!(lmr.get_tile(0, 0), Some(5));
    lmr.set_tile(5, 5, 42);
    assert_eq!(lmr.get_tile(5, 5), Some(42));
}

#[test]
fn test_large_map_renderer_get_tile_out_of_bounds() {
    let mut lmr = LargeMapRenderer::new(32, 32);
    lmr.set_map_data(vec![1; 25], 5, 5);
    assert!(lmr.get_tile(5, 0).is_none());
    assert!(lmr.get_tile(0, 5).is_none());
    assert!(lmr.get_tile(10, 10).is_none());
}

#[test]
fn test_large_map_renderer_chunks_created() {
    let mut lmr = LargeMapRenderer::new(32, 32);
    lmr.set_chunk_size(5);
    lmr.set_map_data(vec![0; 100], 10, 10);
    // 10/5 = 2 chunks per axis = 4 total
    assert_eq!(lmr.get_total_chunks(), 4);
}

#[test]
fn test_large_map_renderer_set_tile_out_of_bounds_noop() {
    let mut lmr = LargeMapRenderer::new(32, 32);
    lmr.set_map_data(vec![0; 4], 2, 2);
    lmr.set_tile(10, 10, 99); // out of bounds - should do nothing
    assert_eq!(lmr.get_tile(10, 10), None);
}

#[test]
fn test_large_map_renderer_camera_and_viewport() {
    let mut lmr = LargeMapRenderer::new(32, 32);
    lmr.set_camera(100.0, 200.0, 2.0);
    assert!((lmr.camera_x - 100.0).abs() < 1e-5);
    assert!((lmr.camera_y - 200.0).abs() < 1e-5);
    assert!((lmr.camera_zoom - 2.0).abs() < 1e-5);
    lmr.set_viewport(640.0, 480.0);
    assert!((lmr.viewport_w - 640.0).abs() < 1e-5);
    assert!((lmr.viewport_h - 480.0).abs() < 1e-5);
}

#[test]
fn test_large_map_renderer_lod() {
    let mut lmr = LargeMapRenderer::new(32, 32);
    assert!(!lmr.is_lod_enabled());
    lmr.set_lod_enabled(true);
    assert!(lmr.is_lod_enabled());
}

// ═════════════════════════════════════════════════════════════════════════
// 10. ColumnBatch
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_column_batch_new() {
    let cb = ColumnBatch::new(320, 320.0, 200.0);
    assert_eq!(cb.get_column_count(), 320);
    assert!((cb.get_screen_width() - 320.0).abs() < 1e-5);
    assert!((cb.get_screen_height() - 200.0).abs() < 1e-5);
}

#[test]
fn test_column_batch_set_column() {
    let mut cb = ColumnBatch::new(320, 320.0, 200.0);
    cb.set_column(0, 0.5, 50.0, 150.0, 1.0, 3);
    let col = cb.get_column(0).unwrap();
    assert!((col.tex_u - 0.5).abs() < 1e-5);
    assert!((col.start - 50.0).abs() < 1e-5);
    assert!((col.end - 150.0).abs() < 1e-5);
    assert!((col.shade - 1.0).abs() < 1e-5);
    assert_eq!(col.cell_val, 3);
}

#[test]
fn test_column_batch_get_depth_at() {
    let cb = ColumnBatch::new(10, 100.0, 100.0);
    // Default depth = 0
    let d = cb.get_depth_at(0).unwrap();
    assert!((d).abs() < 1e-5);
}

#[test]
fn test_column_batch_depth_buffer() {
    let cb = ColumnBatch::new(5, 100.0, 100.0);
    let buf = cb.get_depth_buffer();
    assert_eq!(buf.len(), 5);
    for d in &buf {
        assert!((d).abs() < 1e-5);
    }
}

#[test]
fn test_column_batch_set_floor_ceiling_colors() {
    let mut cb = ColumnBatch::new(10, 100.0, 100.0);
    cb.set_floor_color(Color::RED);
    cb.set_ceiling_color(Color::BLUE);
    assert_eq!(cb.floor_color, Color::RED);
    assert_eq!(cb.ceiling_color, Color::BLUE);
}

#[test]
fn test_column_batch_update_from_ray_data() {
    let mut cb = ColumnBatch::new(2, 100.0, 200.0);
    // 5 floats per ray: distance, cellValue, side, texU, hit
    let rays = vec![
        2.0, 1.0, 0.0, 0.25, 1.0, // ray 0
        4.0, 2.0, 1.0, 0.75, 1.0, // ray 1
    ];
    cb.update_from_ray_data(&rays, 60.0, Some(10.0));
    // Column 0: distance=2, wall_height=200/2=100, start=(200-100)/2=50, end=150
    let c0 = cb.get_column(0).unwrap();
    assert!((c0.start - 50.0).abs() < 1e-5);
    assert!((c0.end - 150.0).abs() < 1e-5);
    assert!((c0.tex_u - 0.25).abs() < 1e-5);
    assert_eq!(c0.cell_val, 1);
    assert!((c0.depth - 2.0).abs() < 1e-5);
    // shade = 1.0 - 2.0/10.0 = 0.8
    assert!((c0.shade - 0.8).abs() < 1e-5);
}

#[test]
fn test_column_batch_get_column_out_of_bounds() {
    let cb = ColumnBatch::new(5, 100.0, 100.0);
    assert!(cb.get_column(5).is_none());
    assert!(cb.get_depth_at(10).is_none());
}

// ═════════════════════════════════════════════════════════════════════════
// 11. Camera2D
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_camera2d_new_defaults() {
    let cam = Camera2D::new(800.0, 600.0);
    let (px, py) = cam.get_position();
    assert!((px).abs() < 1e-5);
    assert!((py).abs() < 1e-5);
    assert!((cam.get_zoom() - 1.0).abs() < 1e-5);
    assert!((cam.get_rotation()).abs() < 1e-5);
}

#[test]
fn test_camera2d_set_position() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_position(100.0, 200.0);
    let (px, py) = cam.get_position();
    assert!((px - 100.0).abs() < 1e-5);
    assert!((py - 200.0).abs() < 1e-5);
}

#[test]
fn test_camera2d_set_zoom() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_zoom(2.0);
    assert!((cam.get_zoom() - 2.0).abs() < 1e-5);
}

#[test]
fn test_camera2d_move_by() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_position(10.0, 20.0);
    cam.move_by(5.0, -3.0);
    let (px, py) = cam.get_position();
    assert!((px - 15.0).abs() < 1e-5);
    assert!((py - 17.0).abs() < 1e-5);
}

#[test]
fn test_camera2d_look_at() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.look_at(500.0, 300.0);
    let (px, py) = cam.get_position();
    assert!((px - 500.0).abs() < 1e-5);
    assert!((py - 300.0).abs() < 1e-5);
}

#[test]
fn test_camera2d_to_world_to_screen_roundtrip() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_position(100.0, 200.0);
    cam.set_zoom(1.5);
    let screen_x = 300.0;
    let screen_y = 200.0;
    let (wx, wy) = cam.to_world_coords(screen_x, screen_y);
    let (sx, sy) = cam.to_screen_coords(wx, wy);
    assert!((sx - screen_x).abs() < 1e-3);
    assert!((sy - screen_y).abs() < 1e-3);
}

#[test]
fn test_camera2d_bounds_clamping() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_bounds(0.0, 0.0, 1000.0, 800.0);
    assert!(cam.has_bounds());
    // Try to move far outside bounds
    cam.set_position(-500.0, -500.0);
    cam.update(0.016);
    let (px, py) = cam.get_position();
    // Position should be clamped within bounds (considering half-viewport offset)
    assert!(px >= 0.0);
    assert!(py >= 0.0);
}

#[test]
fn test_camera2d_remove_bounds() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_bounds(0.0, 0.0, 1000.0, 800.0);
    assert!(cam.has_bounds());
    cam.remove_bounds();
    assert!(!cam.has_bounds());
}

#[test]
fn test_camera2d_dead_zone() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_dead_zone(100.0, 100.0);
    let dz = cam.get_dead_zone().unwrap();
    assert!((dz.0 - 100.0).abs() < 1e-5);
    assert!((dz.1 - 100.0).abs() < 1e-5);
}

#[test]
fn test_camera2d_follow_target() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_target(200.0, 300.0);
    let t = cam.get_target().unwrap();
    assert!((t.0 - 200.0).abs() < 1e-5);
    assert!((t.1 - 300.0).abs() < 1e-5);
    // With no smoothing, update should snap to target
    cam.update(0.016);
    let (px, py) = cam.get_position();
    assert!((px - 200.0).abs() < 1e-5);
    assert!((py - 300.0).abs() < 1e-5);
}

#[test]
fn test_camera2d_shake() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.shake(10.0, 1.0);
    cam.update(0.5);
    // After partial update, shake should be active (offset nonzero)
    // We can't assert exact offset due to sin-based pseudo-random,
    // but the camera should still be functional
    let (px, py) = cam.get_position();
    // Position doesn't change from shake (only offset does)
    assert!((px).abs() < 1e-5);
    assert!((py).abs() < 1e-5);
}

#[test]
fn test_camera2d_visible_area() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_position(400.0, 300.0);
    cam.set_zoom(1.0);
    let (vx, vy, vw, vh) = cam.get_visible_area();
    assert!((vx).abs() < 1e-5); // 400 - 800*0.5/1.0 = 0
    assert!((vy).abs() < 1e-5); // 300 - 600*0.5/1.0 = 0
    assert!((vw - 800.0).abs() < 1e-5);
    assert!((vh - 600.0).abs() < 1e-5);
}

#[test]
fn test_camera2d_viewport() {
    let mut cam = Camera2D::new(800.0, 600.0);
    cam.set_viewport(10.0, 20.0, 640.0, 480.0);
    let (x, y, w, h) = cam.get_viewport();
    assert!((x - 10.0).abs() < 1e-5);
    assert!((y - 20.0).abs() < 1e-5);
    assert!((w - 640.0).abs() < 1e-5);
    assert!((h - 480.0).abs() < 1e-5);
}

// ═════════════════════════════════════════════════════════════════════════
// 12. Animation
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_animation_new_empty() {
    let anim = Animation::new();
    assert_eq!(anim.get_frame_count(), 0);
    assert_eq!(anim.get_clip_count(), 0);
    assert!(!anim.is_playing());
}

#[test]
fn test_animation_add_frame() {
    let mut anim = Animation::new();
    let idx = anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    assert_eq!(idx, 0);
    let idx2 = anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    assert_eq!(idx2, 1);
    assert_eq!(anim.get_frame_count(), 2);
}

#[test]
fn test_animation_add_clip_and_play() {
    let mut anim = Animation::new();
    anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    anim.add_clip("walk", vec![0, 1], 10.0, true);
    assert_eq!(anim.get_clip_count(), 1);
    assert!(anim.play("walk"));
    assert!(anim.is_playing());
    assert_eq!(anim.get_current_clip(), Some("walk"));
}

#[test]
fn test_animation_play_nonexistent_clip() {
    let mut anim = Animation::new();
    assert!(!anim.play("nope"));
    assert!(!anim.is_playing());
}

#[test]
fn test_animation_update_advances_frame() {
    let mut anim = Animation::new();
    anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    anim.add_clip("walk", vec![0, 1], 10.0, true); // 10 fps = 0.1s per frame
    anim.play("walk");
    assert_eq!(anim.current_frame(), 0);
    // Advance past one frame duration
    anim.update(0.15);
    assert_eq!(anim.current_frame(), 1);
}

#[test]
fn test_animation_looping_emits_event() {
    let mut anim = Animation::new();
    anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    anim.add_clip("walk", vec![0, 1], 10.0, true);
    anim.play("walk");
    // Advance past frame 0 and frame 1, should loop
    anim.update(0.25);
    let events = anim.drain_events();
    assert!(events.contains(&AnimEvent::Looped));
}

#[test]
fn test_animation_non_looping_finishes() {
    let mut anim = Animation::new();
    anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    anim.add_clip("once", vec![0, 1], 10.0, false);
    anim.play("once");
    anim.update(0.25); // past both frames
    let events = anim.drain_events();
    assert!(events.contains(&AnimEvent::Finished));
    assert!(!anim.is_playing());
}

#[test]
fn test_animation_pause_resume() {
    let mut anim = Animation::new();
    anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    anim.add_clip("a", vec![0], 10.0, true);
    anim.play("a");
    assert!(anim.is_playing());
    anim.pause();
    assert!(!anim.is_playing());
    anim.resume();
    assert!(anim.is_playing());
}

#[test]
fn test_animation_stop_resets() {
    let mut anim = Animation::new();
    anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    anim.add_clip("walk", vec![0, 1], 10.0, true);
    anim.play("walk");
    anim.update(0.15); // advance to frame 1
    anim.stop();
    assert!(!anim.is_playing());
    assert_eq!(anim.current_frame(), 0);
}

#[test]
fn test_animation_set_speed() {
    let mut anim = Animation::new();
    anim.set_speed(2.0);
    assert!((anim.get_speed() - 2.0).abs() < 1e-5);
    anim.set_speed(-1.0); // should clamp to 0
    assert!((anim.get_speed()).abs() < 1e-5);
}

#[test]
fn test_animation_current_quad() {
    let mut anim = Animation::new();
    anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    anim.add_frame(Rect::new(32.0, 0.0, 32.0, 32.0));
    anim.add_clip("walk", vec![0, 1], 10.0, true);
    anim.play("walk");
    let quad = anim.current_quad().unwrap();
    assert!((quad.x).abs() < 1e-5);
    assert!((quad.width - 32.0).abs() < 1e-5);
}

#[test]
fn test_animation_current_quad_none_when_not_playing() {
    let anim = Animation::new();
    assert!(anim.current_quad().is_none());
}

#[test]
fn test_animation_add_frames_from_grid() {
    let mut anim = Animation::new();
    let added = anim.add_frames_from_grid(128, 64, 32, 32, 0, 8);
    assert_eq!(added, 8);
    assert_eq!(anim.get_frame_count(), 8);
}

#[test]
fn test_animation_is_looping() {
    let mut anim = Animation::new();
    anim.add_frame(Rect::new(0.0, 0.0, 32.0, 32.0));
    anim.add_clip("loop", vec![0], 10.0, true);
    anim.add_clip("noloop", vec![0], 10.0, false);
    anim.play("loop");
    assert!(anim.is_looping());
    anim.play("noloop");
    assert!(!anim.is_looping());
}

// ═════════════════════════════════════════════════════════════════════════
// 13. Trail
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_trail_new_empty() {
    let trail = Trail::new(5.0, 10.0);
    assert_eq!(trail.get_point_count(), 0);
    assert!((trail.get_lifetime() - 5.0).abs() < 1e-5);
}

#[test]
fn test_trail_push_points() {
    let mut trail = Trail::new(5.0, 10.0);
    trail.set_min_distance(0.0); // allow any distance
    trail.push_point(50.0, 100.0);
    trail.push_point(60.0, 100.0);
    assert_eq!(trail.get_point_count(), 2);
}

#[test]
fn test_trail_push_point_respects_min_distance() {
    let mut trail = Trail::new(5.0, 10.0);
    // Default min_distance = 1.0
    trail.push_point(50.0, 100.0);
    trail.push_point(50.1, 100.0); // too close
    assert_eq!(trail.get_point_count(), 1); // second point rejected
}

#[test]
fn test_trail_clear() {
    let mut trail = Trail::new(5.0, 10.0);
    trail.set_min_distance(0.0);
    trail.push_point(1.0, 2.0);
    trail.push_point(3.0, 4.0);
    assert_eq!(trail.get_point_count(), 2);
    trail.clear();
    assert_eq!(trail.get_point_count(), 0);
}

#[test]
fn test_trail_update_removes_expired() {
    let mut trail = Trail::new(1.0, 10.0);
    trail.set_min_distance(0.0);
    trail.push_point(0.0, 0.0);
    trail.push_point(10.0, 0.0);
    trail.update(1.5); // exceeds lifetime of 1.0
    assert_eq!(trail.get_point_count(), 0);
}

#[test]
fn test_trail_update_keeps_young_points() {
    let mut trail = Trail::new(2.0, 10.0);
    trail.set_min_distance(0.0);
    trail.push_point(0.0, 0.0);
    trail.push_point(10.0, 0.0);
    trail.update(0.5); // under lifetime
    assert_eq!(trail.get_point_count(), 2);
}

#[test]
fn test_trail_set_width() {
    let mut trail = Trail::new(5.0, 10.0);
    trail.set_width(20.0, Some(5.0));
    let (sw, ew) = trail.get_width();
    assert!((sw - 20.0).abs() < 1e-5);
    assert!((ew - 5.0).abs() < 1e-5);
}

#[test]
fn test_trail_set_lifetime() {
    let mut trail = Trail::new(5.0, 10.0);
    trail.set_lifetime(10.0);
    assert!((trail.get_lifetime() - 10.0).abs() < 1e-5);
}

#[test]
fn test_trail_set_colors() {
    let mut trail = Trail::new(5.0, 10.0);
    trail.set_head_color(Color::RED);
    trail.set_tail_color(Color::BLUE);
    assert_eq!(trail.head_color, Color::RED);
    assert_eq!(trail.tail_color, Color::BLUE);
}

// ═════════════════════════════════════════════════════════════════════════
// 14. DecalSurface
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_decal_surface_new() {
    let ds = DecalSurface::new(800, 600);
    assert_eq!(ds.get_width(), 800);
    assert_eq!(ds.get_height(), 600);
}

#[test]
fn test_decal_surface_dimensions() {
    let ds = DecalSurface::new(1920, 1080);
    assert_eq!(ds.get_dimensions(), (1920, 1080));
}

#[test]
fn test_decal_surface_zero_size() {
    let ds = DecalSurface::new(0, 0);
    assert_eq!(ds.get_width(), 0);
    assert_eq!(ds.get_height(), 0);
}

// ═════════════════════════════════════════════════════════════════════════
// 15. PaletteLUT
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_palette_lut_new_empty() {
    let lut = PaletteLUT::new();
    assert_eq!(lut.get_color_count(), 0);
}

#[test]
fn test_palette_lut_set_color() {
    let mut lut = PaletteLUT::new();
    lut.set_color(0, Color::RED, Color::BLUE);
    assert_eq!(lut.get_color_count(), 1);
    assert_eq!(lut.get_from_color(0), Some(Color::RED));
    assert_eq!(lut.get_to_color(0), Some(Color::BLUE));
}

#[test]
fn test_palette_lut_set_color_sparse() {
    let mut lut = PaletteLUT::new();
    // Setting index 3 should fill indices 0-2 with WHITE
    lut.set_color(3, Color::GREEN, Color::BLACK);
    assert_eq!(lut.get_color_count(), 4);
    assert_eq!(lut.get_from_color(0), Some(Color::WHITE));
    assert_eq!(lut.get_from_color(3), Some(Color::GREEN));
    assert_eq!(lut.get_to_color(3), Some(Color::BLACK));
}

#[test]
fn test_palette_lut_clear() {
    let mut lut = PaletteLUT::new();
    lut.set_color(0, Color::RED, Color::BLUE);
    lut.set_color(1, Color::GREEN, Color::BLACK);
    assert_eq!(lut.get_color_count(), 2);
    lut.clear();
    assert_eq!(lut.get_color_count(), 0);
    assert!(lut.get_from_color(0).is_none());
}

#[test]
fn test_palette_lut_get_nonexistent() {
    let lut = PaletteLUT::new();
    assert!(lut.get_from_color(0).is_none());
    assert!(lut.get_to_color(5).is_none());
}

#[test]
fn test_palette_lut_overwrite() {
    let mut lut = PaletteLUT::new();
    lut.set_color(0, Color::RED, Color::BLUE);
    lut.set_color(0, Color::GREEN, Color::BLACK);
    assert_eq!(lut.get_color_count(), 1);
    assert_eq!(lut.get_from_color(0), Some(Color::GREEN));
    assert_eq!(lut.get_to_color(0), Some(Color::BLACK));
}
