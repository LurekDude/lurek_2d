//! INTERNAL ONLY: public `lurek.tilemap.*` behavior is covered primarily by
//! `tests/lua/unit/test_tilemap_unit.lua` plus matching evidence/golden and
//! integration suites.
//!
//! The Rust coverage that remains here focuses on helper-level rendering,
//! TileWalker internals, and tileset/mapgen behavior not yet asserted as
//! strongly through Lua.

use lurek2d::tilemap::*;
use lurek2d::tilemap::tilemap::TileMap;
use lurek2d::tilemap::tileset::TileSet;
use lurek2d::tilemap::polygon_map::PolygonMap;
use lurek2d::tilemap::ldtk::load_ldtk;
use lurek2d::tilemap::tile_walker::{TileWalker, Facing};
use lurek2d::render::renderer::{DrawMode, RenderCommand};
use lurek2d::math::Color;
use lurek2d::math::rect::Rect;

// ── tmx ───────────────────────────────────────────────────────────────────────

// Public TMX loader behavior is covered in `tests/lua/unit/test_tilemap_unit.lua`.

// ── tile_walker ───────────────────────────────────────────────────────────────

mod tile_walker_tests {
    use super::*;

    #[test]
    fn basic_movement() {
        let mut walker = TileWalker::new(3, 3, Facing::North);
        assert!(walker.move_forward());
        assert_eq!(walker.x(), 3);
        assert_eq!(walker.y(), 2);
    }

    #[test]
    fn turn_and_move() {
        let mut walker = TileWalker::new(3, 3, Facing::North);
        walker.turn_right();
        assert_eq!(walker.facing(), Facing::East);
        assert!(walker.move_forward());
        assert_eq!(walker.x(), 4);
        assert_eq!(walker.y(), 3);
    }

    #[test]
    fn interpolation() {
        let mut walker = TileWalker::new(2, 2, Facing::East);
        walker.begin_move();
        walker.move_forward();
        let (ix, iy) = walker.get_interpolated_position(0.5);
        assert!((ix - 2.5).abs() < 1e-5);
        assert!((iy - 2.0).abs() < 1e-5);
    }

    #[test]
    fn facing_from_str() {
        assert_eq!(Facing::parse("north"), Some(Facing::North));
        assert_eq!(Facing::parse("E"), Some(Facing::East));
        assert_eq!(Facing::parse("SOUTH"), Some(Facing::South));
        assert_eq!(Facing::parse("invalid"), None);
    }

    #[test]
    fn strafe() {
        let mut walker = TileWalker::new(3, 3, Facing::North);
        assert!(walker.strafe_left());
        assert_eq!(walker.x(), 2);
        assert_eq!(walker.y(), 3);
    }

    #[test]
    fn turn_around() {
        let mut walker = TileWalker::new(1, 1, Facing::North);
        walker.turn_around();
        assert_eq!(walker.facing(), Facing::South);
    }

    #[test]
    fn relative_facing() {
        let walker = TileWalker::new(3, 3, Facing::North);
        assert_eq!(walker.get_relative_facing(3, 2), "front");
        assert_eq!(walker.get_relative_facing(3, 4), "back");
        assert_eq!(walker.get_relative_facing(2, 3), "left");
        assert_eq!(walker.get_relative_facing(4, 3), "right");
    }
}

// ── tileset ───────────────────────────────────────────────────────────────────

mod tileset_tests {
    use super::*;

    #[test]
    fn animation_get_set() {
        let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        assert!(ts.get_animation(0).is_none());

        let frames = vec![
            TileAnimFrame { tile_id: 0, duration_ms: 100.0 },
            TileAnimFrame { tile_id: 1, duration_ms: 200.0 },
        ];
        ts.set_animation(0, frames);
        let anim = ts.get_animation(0).expect("animation 0 exists");
        assert_eq!(anim.len(), 2);
        assert_eq!(anim[0].tile_id, 0);
        assert!((anim[1].duration_ms - 200.0).abs() < 1e-5);
    }

    #[test]
    fn autotile_rule_4bit() {
        let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        ts.set_auto_tile_rule("wall", 0b0101, 3);
        assert_eq!(ts.get_auto_tile_id("wall", 0b0101), Some(3));
        assert_eq!(ts.get_auto_tile_id("wall", 0b0000), None);
        assert_eq!(ts.get_auto_tile_id("floor", 0b0101), None);
    }

    #[test]
    fn autotile_rule_8bit() {
        let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        ts.set_auto_tile_rule_8("wall", 0b10101010, 7);
        assert_eq!(ts.get_auto_tile_id_8("wall", 0b10101010), Some(7));
        assert_eq!(ts.get_auto_tile_id_8("wall", 0b00000000), None);
    }

}

// ── render ────────────────────────────────────────────────────────────────────

mod render_tests {
    use super::*;

    fn make_simple_map() -> TileMap {
        let mut m = TileMap::new(16, 16, 8);
        m.add_layer("base", 4, 4);
        m.set_tile(0, 0, 0, 1);
        m.set_tile(0, 1, 0, 2);
        m
    }

    #[test]
    fn empty_tilemap_gives_no_commands() {
        let m = TileMap::new(16, 16, 8);
        let cmds = m.generate_render_commands(0.0, 0.0, 0.0, 0.0, f32::MAX, f32::MAX);
        assert!(cmds.is_empty());
    }

    #[test]
    fn filled_layer_produces_rectangle_commands() {
        let m = make_simple_map();
        let cmds = m.generate_render_commands(0.0, 0.0, 0.0, 0.0, f32::MAX, f32::MAX);
        let rects = cmds
            .iter()
            .filter(|c| matches!(c, RenderCommand::Rectangle { mode: DrawMode::Fill, .. }))
            .count();
        assert!(rects >= 2, "expected at least 2 fill rectangles, got {rects}");
    }

    #[test]
    fn hidden_layer_produces_no_commands() {
        let mut m = make_simple_map();
        m.set_layer_visible(0, false);
        let cmds = m.generate_render_commands(0.0, 0.0, 0.0, 0.0, f32::MAX, f32::MAX);
        let rects = cmds
            .iter()
            .filter(|c| matches!(c, RenderCommand::Rectangle { .. }))
            .count();
        assert_eq!(rects, 0, "hidden layer should produce no rectangle commands");
    }

    #[test]
    fn culled_tile_outside_camera_is_excluded() {
        let m = make_simple_map();
        let cmds = m.generate_render_commands(0.0, 0.0, 200.0, 0.0, 100.0, 100.0);
        let rects = cmds
            .iter()
            .filter(|c| matches!(c, RenderCommand::Rectangle { .. }))
            .count();
        assert_eq!(rects, 0, "tiles outside camera should be culled");
    }
}

// ── mapgen ────────────────────────────────────────────────────────────────────

mod mapgen_tests {
    use super::*;

    #[test]
    fn edge_from_str() {
        assert_eq!(Edge::from_str("north"), Some(Edge::North));
        assert_eq!(Edge::from_str("east"), Some(Edge::East));
        assert_eq!(Edge::from_str("south"), Some(Edge::South));
        assert_eq!(Edge::from_str("west"), Some(Edge::West));
        assert_eq!(Edge::from_str("invalid"), None);
    }

    #[test]
    fn edge_as_str() {
        assert_eq!(Edge::North.as_str(), "north");
        assert_eq!(Edge::East.as_str(), "east");
        assert_eq!(Edge::South.as_str(), "south");
        assert_eq!(Edge::West.as_str(), "west");
    }

    #[test]
    fn map_block_segment_dimensions() {
        let block = MapBlock::new(8, 6, 2, 2);
        assert_eq!(block.get_width(), 8);
        assert_eq!(block.get_height(), 6);
        assert_eq!(block.get_dimensions(), (8, 6));
        assert_eq!(block.get_layer_count(), 2);
        assert_eq!(block.get_segment_size(), 2);
        assert_eq!(block.get_width_in_segments(), 4);
        assert_eq!(block.get_height_in_segments(), 3);
        assert_eq!(block.get_segment_count(Edge::North), 4);
        assert_eq!(block.get_segment_count(Edge::South), 4);
        assert_eq!(block.get_segment_count(Edge::East), 3);
        assert_eq!(block.get_segment_count(Edge::West), 3);
    }

    #[test]
    fn map_block_tile_access() {
        let mut block = MapBlock::new(4, 4, 1, 2);
        block.set_tile(0, 1, 2, 42);
        assert_eq!(block.get_tile(0, 1, 2), 42);
        assert_eq!(block.get_tile(0, 0, 0), 0);
        assert_eq!(block.get_tile(1, 0, 0), 0);
    }

    #[test]
    fn map_block_sides() {
        let mut block = MapBlock::new(4, 4, 1, 2);
        block.set_side(Edge::North, 0, 5);
        block.set_side(Edge::North, 1, 7);
        assert_eq!(block.get_side(Edge::North, 0), 5);
        assert_eq!(block.get_side(Edge::North, 1), 7);
        assert_eq!(block.get_side(Edge::South, 0), 0);
    }

    #[test]
    fn map_block_name_weight() {
        let mut block = MapBlock::new(4, 4, 1, 2);
        assert!((block.get_weight() - 1.0).abs() < 1e-5);
        block.set_name("room");
        assert_eq!(block.get_name(), "room");
        block.set_weight(2.5);
        assert!((block.get_weight() - 2.5).abs() < 1e-5);
    }

    #[test]
    fn map_group_add_remove() {
        let mut group = MapGroup::new("biome1");
        assert_eq!(group.get_name(), "biome1");
        assert_eq!(group.get_block_count(), 0);

        group.add_block(MapBlock::new(4, 4, 1, 2));
        group.add_block(MapBlock::new(6, 6, 1, 3));
        assert_eq!(group.get_block_count(), 2);

        group.remove_block(0);
        assert_eq!(group.get_block_count(), 1);

        group.remove_block(99);
        assert_eq!(group.get_block_count(), 1);
    }

    #[test]
    fn map_group_scripts() {
        let mut group = MapGroup::new("test");
        group.add_script(MapScript::new("gen1"));
        assert_eq!(group.get_script_count(), 1);
        assert_eq!(group.get_script(0).expect("script 0 exists").get_name(), "gen1");
    }

    #[test]
    fn map_group_set_name() {
        let mut group = MapGroup::new("old");
        group.set_name("new");
        assert_eq!(group.get_name(), "new");
    }

    #[test]
    fn step_type_roundtrip() {
        let types = [
            StepType::FillRandom, StepType::PlaceBlock, StepType::PlaceRandom,
            StepType::PlaceLine, StepType::FloodFill, StepType::FillArea,
            StepType::DrawPath, StepType::FillRect,
        ];
        for st in &types {
            let s = st.as_str();
            assert_eq!(StepType::from_str(s), Some(*st));
        }
        assert_eq!(StepType::from_str("invalid"), None);
    }

    #[test]
    fn script_step_default() {
        let step = ScriptStep::default();
        assert_eq!(step.step_type, StepType::FillRandom);
        assert!(step.match_sides);
        assert!((step.chance - 1.0).abs() < 1e-5);
        assert_eq!(step.repeat_count, 1);
        assert_eq!(step.condition_step, -1);
        assert_eq!(step.group_index, -1);
        assert_eq!(step.block_index, -1);
    }

    #[test]
    fn map_script_step_management() {
        let mut script = MapScript::new("test_script");
        assert_eq!(script.get_name(), "test_script");
        assert_eq!(script.get_step_count(), 0);

        script.add_step(ScriptStep::default());
        script.add_step(ScriptStep {
            step_type: StepType::PlaceBlock,
            ..ScriptStep::default()
        });
        assert_eq!(script.get_step_count(), 2);
        assert_eq!(script.get_step(0).expect("step 0 exists").step_type, StepType::FillRandom);
        assert_eq!(script.get_step(1).expect("step 1 exists").step_type, StepType::PlaceBlock);

        script.remove_step(0);
        assert_eq!(script.get_step_count(), 1);
        assert_eq!(script.get_step(0).expect("step 0 exists").step_type, StepType::PlaceBlock);

        script.clear_steps();
        assert_eq!(script.get_step_count(), 0);
    }

    #[test]
    fn map_script_set_name() {
        let mut script = MapScript::new("old");
        script.set_name("new");
        assert_eq!(script.get_name(), "new");
    }

    #[test]
    fn map_size_presets() {
        assert_eq!(MapSize::Small.grid_dimensions(), (3, 3));
        assert_eq!(MapSize::Medium.grid_dimensions(), (5, 5));
        assert_eq!(MapSize::Large.grid_dimensions(), (6, 6));
        assert_eq!(MapSize::Custom(10, 20).grid_dimensions(), (10, 20));
    }

    #[test]
    fn map_gen_creation() {
        let gen = MapGen::new(MapSize::Small, 4);
        assert_eq!(gen.get_grid_width(), 3);
        assert_eq!(gen.get_grid_height(), 3);
        assert_eq!(gen.get_grid_dimensions(), (3, 3));
        assert_eq!(gen.get_segment_size(), 4);
        assert_eq!(gen.get_tile_pixel_width(), 32);
        assert_eq!(gen.get_tile_pixel_height(), 32);
        assert_eq!(gen.get_orientation(), MapOrientation::TopDown);
        assert_eq!(gen.get_layer_mode(), LayerMode::Unified);
    }

    #[test]
    fn map_gen_medium_large() {
        let med = MapGen::new(MapSize::Medium, 4);
        assert_eq!(med.get_grid_dimensions(), (5, 5));
        let large = MapGen::new(MapSize::Large, 4);
        assert_eq!(large.get_grid_dimensions(), (6, 6));
    }

    #[test]
    fn map_gen_tile_size() {
        let mut gen = MapGen::new(MapSize::Small, 4);
        gen.set_tile_size(16, 16);
        assert_eq!(gen.get_tile_pixel_width(), 16);
        assert_eq!(gen.get_tile_pixel_height(), 16);
    }

    #[test]
    fn orientation_eq() {
        assert_eq!(MapOrientation::TopDown, MapOrientation::TopDown);
        assert_ne!(MapOrientation::TopDown, MapOrientation::SideView);
    }

    #[test]
    fn layer_mode_eq() {
        assert_eq!(LayerMode::Unified, LayerMode::Unified);
        assert_ne!(LayerMode::Unified, LayerMode::Independent);
    }
}

// ── ldtk ──────────────────────────────────────────────────────────────────────

mod ldtk_tests {
    use super::*;

    const MINIMAL_LDTK: &str = r#"{
        "levels": [{
            "identifier": "Level_0",
            "layerInstances": [{
                "__identifier": "Ground",
                "__type": "Tiles",
                "__gridSize": 16,
                "__cWid": 4,
                "__cHei": 4,
                "gridTiles": [
                    {"px":[0,0],"src":[0,0],"t":0},
                    {"px":[16,0],"src":[16,0],"t":1}
                ],
                "autoLayerTiles": []
            }]
        }]
    }"#;

    #[test]
    fn ldtk_load_first_level_parses_correctly() {
        let map = load_ldtk(MINIMAL_LDTK, None).unwrap();
        let gid = map.get_tile(0, 0, 0);
        assert_eq!(gid, 1, "first tile must have gid=1");
        let gid2 = map.get_tile(0, 1, 0);
        assert_eq!(gid2, 2, "second tile must have gid=2");
    }

    #[test]
    fn ldtk_named_level_selection_works() {
        let result = load_ldtk(MINIMAL_LDTK, Some("Level_0"));
        assert!(result.is_ok());
    }

    #[test]
    fn ldtk_missing_level_returns_error() {
        let result = load_ldtk(MINIMAL_LDTK, Some("Missing_Level"));
        assert!(result.is_err());
    }

    #[test]
    fn ldtk_invalid_json_returns_error() {
        let result = load_ldtk("not json", None);
        assert!(result.is_err());
    }
}

// ── isomap ────────────────────────────────────────────────────────────────────

mod isomap_tests {
    use super::*;

    fn make_map() -> IsoMap {
        IsoMap::new(4, 4, 64, 32, 24, 4)
    }

    #[test]
    fn add_level_returns_index() {
        let mut m = make_map();
        assert_eq!(m.add_level(), 0);
        assert_eq!(m.add_level(), 1);
        assert_eq!(m.get_level_count(), 2);
    }

    #[test]
    fn tile_part_round_trip() {
        let mut m = make_map();
        m.add_level();
        m.set_tile_part(0, 1, 2, 0, 42);
        assert_eq!(m.get_tile_part(0, 1, 2, 0), 42);
        assert_eq!(m.get_tile_part(0, 1, 2, 1), 0);
    }

    #[test]
    fn tile_part_oob_returns_zero() {
        let mut m = make_map();
        m.add_level();
        assert_eq!(m.get_tile_part(0, 99, 99, 0), 0);
        assert_eq!(m.get_tile_part(5, 0, 0, 0), 0);
        assert_eq!(m.get_tile_part(0, 0, 0, 4), 0);
    }

    #[test]
    fn fill_level() {
        let mut m = make_map();
        m.add_level();
        m.fill_level(0, 0, 7);
        for y in 0..4 {
            for x in 0..4 {
                assert_eq!(m.get_tile_part(0, x, y, 0), 7);
                assert_eq!(m.get_tile_part(0, x, y, 1), 0);
            }
        }
    }

    #[test]
    fn tile_to_screen() {
        let mut m = IsoMap::new(10, 10, 64, 32, 24, 4);
        m.origin_x = 400.0;
        m.origin_y = 50.0;
        let (sx, sy) = m.tile_to_screen(0.0, 0.0, 0.0);
        assert!((sx - 400.0).abs() < 1e-4);
        assert!((sy - 50.0).abs() < 1e-4);
        let (sx, sy) = m.tile_to_screen(1.0, 0.0, 0.0);
        assert!((sx - 432.0).abs() < 1e-4);
        assert!((sy - 66.0).abs() < 1e-4);
        let (_, sy2) = m.tile_to_screen(1.0, 0.0, 1.0);
        assert!((sy2 - (66.0 - 24.0)).abs() < 1e-4);
    }

    #[test]
    fn screen_to_tile_inverse() {
        let mut m = IsoMap::new(10, 10, 64, 32, 24, 4);
        m.origin_x = 200.0;
        m.origin_y = 100.0;
        let (sx, sy) = m.tile_to_screen(3.0, 2.0, 0.0);
        let (tx, ty) = m.screen_to_tile(sx, sy);
        assert!((tx - 3.0).abs() < 1e-4);
        assert!((ty - 2.0).abs() < 1e-4);
    }

    #[test]
    fn draw_iter_order() {
        let mut m = IsoMap::new(2, 2, 64, 32, 24, 4);
        m.add_level();
        let items = m.draw_iter(0);
        assert_eq!(items.len(), 16);
        let first = &items[0];
        assert_eq!((first.tile_x, first.tile_y, first.part), (0, 0, 0));
        let second_group = &items[4];
        assert_eq!((second_group.tile_x, second_group.tile_y), (0, 1));
        let third_group = &items[8];
        assert_eq!((third_group.tile_x, third_group.tile_y), (1, 0));
        let last = &items[12];
        assert_eq!((last.tile_x, last.tile_y), (1, 1));
    }

    #[test]
    fn draw_iter_multi_z_order() {
        let mut m = IsoMap::new(1, 1, 64, 32, 24, 4);
        m.add_level();
        m.add_level();
        m.set_tile_part(0, 0, 0, 0, 10);
        m.set_tile_part(1, 0, 0, 0, 20);

        let items = m.draw_iter(1);
        assert_eq!(items.len(), 8);
        assert_eq!(items[0].level, 0);
        assert_eq!(items[0].gid, 10);
        assert_eq!(items[4].level, 1);
        assert_eq!(items[4].gid, 20);
    }

    #[test]
    fn level_visible_skip() {
        let mut m = IsoMap::new(1, 1, 64, 32, 24, 4);
        m.add_level();
        m.add_level();
        m.set_level_visible(0, false);

        let items = m.draw_iter(1);
        assert_eq!(items.len(), 4);
        assert_eq!(items[0].level, 1);
    }

    #[test]
    fn active_z_clamped() {
        let mut m = IsoMap::new(1, 1, 64, 32, 24, 4);
        m.add_level();
        let items = m.draw_iter(10);
        assert_eq!(items.len(), 4);
    }

    #[test]
    fn draw_iter_empty() {
        let m = IsoMap::new(4, 4, 64, 32, 24, 4);
        assert!(m.draw_iter(0).is_empty());
    }
}

// ── coords ────────────────────────────────────────────────────────────────────

mod coords_tests {
    use super::*;
    use std::f32::consts::PI;

    #[test]
    fn iso_roundtrip() {
        let tile_w = 64.0;
        let tile_h = 32.0;
        let screen = to_screen_iso(3.0, 2.0, tile_w, tile_h);
        let back = from_screen_iso(screen.x, screen.y, tile_w, tile_h);
        assert!((back.x - 3.0).abs() < 1e-5);
        assert!((back.y - 2.0).abs() < 1e-5);
    }

    #[test]
    fn iso_rotate_wraps() {
        assert_eq!(iso_rotate(1, 0), 1);
        assert_eq!(iso_rotate(1, 1), 2);
        assert_eq!(iso_rotate(1, 4), 1);
        assert_eq!(iso_rotate(4, 1), 1);
        assert_eq!(iso_rotate(3, -1), 2);
    }

    #[test]
    fn iso_direction_name_all_four() {
        assert_eq!(iso_direction_name(1), "south");
        assert_eq!(iso_direction_name(2), "west");
        assert_eq!(iso_direction_name(3), "north");
        assert_eq!(iso_direction_name(4), "east");
        assert_eq!(iso_direction_name(0), "unknown");
    }

    #[test]
    fn iso_direction_from_angle_cardinals() {
        assert_eq!(iso_direction_from_angle(0.0), 4);
        assert_eq!(iso_direction_from_angle(PI / 2.0), 1);
        assert_eq!(iso_direction_from_angle(PI), 2);
        assert_eq!(iso_direction_from_angle(-PI / 2.0), 3);
    }

    #[test]
    fn hex_distance_cases() {
        assert_eq!(hex_distance(0, 0, 0, 0), 0);
        assert_eq!(hex_distance(0, 0, 1, 0), 1);
        assert_eq!(hex_distance(0, 0, 2, -1), 2);
        assert_eq!(hex_distance(0, 0, 3, -3), 3);
    }

    #[test]
    fn hex_round_exact() {
        assert_eq!(hex_round(1.0, 2.0), (1, 2));
        assert_eq!(hex_round(0.1, -0.1), (0, 0));
        assert_eq!(hex_round(0.9, 0.1), (1, 0));
    }

    #[test]
    fn hex_neighbors_count() {
        let n = hex_neighbors(0, 0);
        assert_eq!(n.len(), 6);
        for (q, r) in &n {
            assert_eq!(hex_distance(0, 0, *q, *r), 1);
        }
    }

    #[test]
    fn hex_line_length() {
        let line = hex_line(0, 0, 3, 0);
        assert_eq!(line.len(), 4);
        assert_eq!(line[0], (0, 0));
        assert_eq!(line[3], (3, 0));
    }

    #[test]
    fn hex_ring_radius_0_returns_center() {
        let ring = hex_ring(2, 3, 0);
        assert_eq!(ring, vec![(2, 3)]);
    }

    #[test]
    fn hex_ring_radius_1_returns_6() {
        let ring = hex_ring(0, 0, 1);
        assert_eq!(ring.len(), 6);
        for (q, r) in &ring {
            assert_eq!(hex_distance(0, 0, *q, *r), 1);
        }
    }

    #[test]
    fn hex_ring_radius_2_returns_12() {
        let ring = hex_ring(0, 0, 2);
        assert_eq!(ring.len(), 12);
        for (q, r) in &ring {
            assert_eq!(hex_distance(0, 0, *q, *r), 2);
        }
    }

    #[test]
    fn hex_spiral_includes_center() {
        let spiral = hex_spiral(1, 1, 1);
        assert!(spiral.contains(&(1, 1)));
        assert_eq!(spiral.len(), 7);
    }

    #[test]
    fn hex_area_superset_of_ring() {
        let area = hex_area(0, 0, 2);
        let ring = hex_ring(0, 0, 2);
        for cell in &ring {
            assert!(area.contains(cell));
        }
        assert_eq!(area.len(), 19);
    }

    #[test]
    fn hex_rotate_60_degrees() {
        let (rq, rr) = hex_rotate(1, 0, 0, 0, 1);
        assert_eq!((rq, rr), (0, 1));
    }

    #[test]
    fn hex_rotate_full_circle() {
        let (rq, rr) = hex_rotate(2, -1, 0, 0, 6);
        assert_eq!((rq, rr), (2, -1));
    }

    #[test]
    fn hex_reflect_q_axis() {
        let (rq, rr) = hex_reflect(1, 2, 0, 0, "q");
        assert_eq!((rq, rr), (1, -3));
    }

    #[test]
    fn hex_screen_roundtrip() {
        let size = 20.0;
        let screen = to_screen_hex(3, -2, size);
        let (rq, rr) = from_screen_hex(screen.x, screen.y, size);
        assert_eq!((rq, rr), (3, -2));
    }
}

// ── chunk ─────────────────────────────────────────────────────────────────────

mod chunk_tests {
    use super::*;

    #[test]
    fn new_chunk_reads_zero() {
        let m = ChunkMap::new(16);
        assert_eq!(m.get_tile(0, 0), 0);
        assert_eq!(m.get_tile(-5, 3), 0);
        assert_eq!(m.get_tile(1000, 1000), 0);
    }

    #[test]
    fn set_and_get_tile() {
        let mut m = ChunkMap::new(16);
        m.set_tile(0, 0, 42);
        assert_eq!(m.get_tile(0, 0), 42);
        m.set_tile(-1, -1, 99);
        assert_eq!(m.get_tile(-1, -1), 99);
    }

    #[test]
    fn clear_tile_sets_zero() {
        let mut m = ChunkMap::new(8);
        m.set_tile(3, 3, 7);
        m.clear_tile(3, 3);
        assert_eq!(m.get_tile(3, 3), 0);
    }

    #[test]
    fn fill_rect_writes_all() {
        let mut m = ChunkMap::new(16);
        m.fill_rect(0, 0, 4, 4, 1);
        for y in 0..4 {
            for x in 0..4 {
                assert_eq!(m.get_tile(x, y), 1, "({x},{y}) should be 1");
            }
        }
        assert_eq!(m.get_tile(4, 0), 0);
    }

    #[test]
    fn chunk_allocated_on_write() {
        let mut m = ChunkMap::new(16);
        assert_eq!(m.get_loaded_chunk_count(), 0);
        m.set_tile(0, 0, 1);
        assert_eq!(m.get_loaded_chunk_count(), 1);
        m.set_tile(16, 0, 2);
        assert_eq!(m.get_loaded_chunk_count(), 2);
    }

    #[test]
    fn load_and_unload_chunk() {
        let mut m = ChunkMap::new(16);
        m.load_chunk(0, 0);
        assert!(m.is_chunk_loaded(0, 0));
        m.set_tile(5, 5, 3);
        m.unload_chunk(0, 0);
        assert!(!m.is_chunk_loaded(0, 0));
        assert_eq!(m.get_tile(5, 5), 0);
    }

    #[test]
    fn tile_to_chunk_negative_coords() {
        let m = ChunkMap::new(16);
        assert_eq!(m.tile_to_chunk(-1, -1), (-1, -1));
        assert_eq!(m.tile_to_chunk(-16, -16), (-1, -1));
        assert_eq!(m.tile_to_chunk(-17, -1), (-2, -1));
    }

    #[test]
    fn chunk_tile_range() {
        let m = ChunkMap::new(8);
        let (x0, y0, x1, y1) = m.chunk_tile_range(2, -1);
        assert_eq!((x0, y0, x1, y1), (16, -8, 24, 0));
    }

    #[test]
    fn chunks_in_view() {
        let m = ChunkMap::new(16);
        let chunks = m.get_chunks_in_view(0.0, 0.0, 511.0, 511.0, 32.0, 32.0);
        assert!(chunks.contains(&(0, 0)));
    }

    #[test]
    fn iter_chunk_returns_slice() {
        let mut m = ChunkMap::new(4);
        m.set_tile(1, 2, 5);
        let (cx, cy) = m.tile_to_chunk(1, 2);
        let slice = m.iter_chunk(cx, cy).expect("cx/cy in bounds for chunk iteration");
        assert_eq!(slice.len(), 16);
    }

    #[test]
    fn iter_chunk_unloaded_returns_none() {
        let m = ChunkMap::new(8);
        assert!(m.iter_chunk(99, 99).is_none());
    }
}

// ── autotile_sheet ────────────────────────────────────────────────────────────

mod autotile_sheet_tests {
    use super::*;
    use lurek2d::tilemap::autotile_sheet::{AutoTileSheet, AutoTileLayout};

    #[test]
    fn creation_blob47() {
        let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Blob47);
        assert_eq!(sheet.get_layout(), AutoTileLayout::Blob47);
        assert_eq!(sheet.get_tile_count(), 47);
        assert_eq!(sheet.get_tile_width(), 32);
        assert_eq!(sheet.get_tile_height(), 32);
    }

    #[test]
    fn creation_composite48() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Composite48);
        assert_eq!(sheet.get_layout(), AutoTileLayout::Composite48);
        assert_eq!(sheet.get_tile_count(), 48);
    }

    #[test]
    fn creation_minimal16() {
        let sheet = AutoTileSheet::new(24, 24, AutoTileLayout::Minimal16);
        assert_eq!(sheet.get_layout(), AutoTileLayout::Minimal16);
        assert_eq!(sheet.get_tile_count(), 16);
    }

    #[test]
    fn tile_count_per_layout() {
        assert_eq!(AutoTileSheet::new(16, 16, AutoTileLayout::Blob47).get_tile_count(), 47);
        assert_eq!(AutoTileSheet::new(16, 16, AutoTileLayout::Composite48).get_tile_count(), 48);
        assert_eq!(AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16).get_tile_count(), 16);
    }

    #[test]
    fn get_quad_bounds() {
        let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Blob47);
        let q0 = sheet.get_quad(0);
        assert!((q0.x - 0.0).abs() < 1e-5);
        assert!((q0.y - 0.0).abs() < 1e-5);
        assert!((q0.width - 32.0).abs() < 1e-5);
        assert!((q0.height - 32.0).abs() < 1e-5);
        let q5 = sheet.get_quad(5);
        assert!((q5.x - 160.0).abs() < 1e-5);
        assert!((q5.y - 0.0).abs() < 1e-5);
    }

    #[test]
    fn get_quad_out_of_bounds() {
        let sheet = AutoTileSheet::new(32, 32, AutoTileLayout::Minimal16);
        let q = sheet.get_quad(100);
        assert!((q.width - 0.0).abs() < 1e-5);
        assert!((q.height - 0.0).abs() < 1e-5);
    }

    #[test]
    fn bitmask_roundtrip_minimal16() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16);
        for i in 0u32..16 {
            let bm = sheet.get_bitmask_for_tile(i);
            assert_eq!(bm, i as u16);
            let tile = sheet.get_tile_for_bitmask(bm);
            assert_eq!(tile, Some(i));
        }
    }

    #[test]
    fn bitmask_roundtrip_blob47() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Blob47);
        for i in 0u32..47 {
            let bm = sheet.get_bitmask_for_tile(i);
            let tile = sheet.get_tile_for_bitmask(bm);
            assert_eq!(tile, Some(i));
        }
    }

    #[test]
    fn bitmask_out_of_bounds() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Blob47);
        assert_eq!(sheet.get_bitmask_for_tile(100), 0);
    }

    #[test]
    fn apply_to_tileset_minimal16() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16);
        let mut ts = TileSet::new(1, 16, 4, 16, 16, 0, 0);
        sheet.apply_to_tileset(&mut ts, "grass", None);
        assert_eq!(ts.get_auto_tile_id("grass", 0), Some(0));
        assert_eq!(ts.get_auto_tile_id("grass", 15), Some(15));
    }

    #[test]
    fn apply_to_tileset_with_offset() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Minimal16);
        let mut ts = TileSet::new(1, 32, 4, 16, 16, 0, 0);
        sheet.apply_to_tileset(&mut ts, "wall", Some(10));
        assert_eq!(ts.get_auto_tile_id("wall", 0), Some(10));
    }

    #[test]
    fn apply_to_tileset_blob47() {
        let sheet = AutoTileSheet::new(16, 16, AutoTileLayout::Blob47);
        let mut ts = TileSet::new(1, 64, 8, 16, 16, 0, 0);
        sheet.apply_to_tileset(&mut ts, "stone", None);
        let bm0 = sheet.get_bitmask_for_tile(0);
        assert_eq!(ts.get_auto_tile_id_8("stone", bm0), Some(0));
    }

    #[test]
    fn layout_equality() {
        assert_ne!(AutoTileLayout::Blob47, AutoTileLayout::Composite48);
        assert_ne!(AutoTileLayout::Composite48, AutoTileLayout::Minimal16);
        assert_eq!(AutoTileLayout::Blob47, AutoTileLayout::Blob47);
    }

    #[test]
    #[ignore = "reduce_8bit is pub(crate)"]
    fn reduce_8bit_masks_out_irrelevant_diagonals() {
        let _raw = 0b0001_0000;
        let _raw2 = 0b0001_0011;
    }
}

// ── polygon_map ───────────────────────────────────────────────────────────────

mod polygon_map_tests {
    use super::*;

    fn square_verts() -> Vec<f32> {
        vec![0.0, 0.0, 10.0, 0.0, 10.0, 10.0, 0.0, 10.0]
    }

    #[test]
    #[ignore = "point_in_polygon is pub(crate)"]
    fn point_in_polygon_inside() {
        assert!(true); // placeholder
    }

    #[test]
    #[ignore = "point_in_polygon is pub(crate)"]
    fn point_in_polygon_outside() {
        assert!(true); // placeholder
    }

    #[test]
    #[ignore = "point_in_polygon is pub(crate)"]
    fn point_in_polygon_degenerate() {
        assert!(true); // placeholder
    }

    #[test]
    fn new_polygon_map_empty() {
        let m = PolygonMap::new();
        assert!(m.get_region_names().is_empty());
        assert!(m.get_bounding_box().is_none());
    }

    #[test]
    fn add_and_remove_region() {
        let mut m = PolygonMap::new();
        m.add_region("a", square_verts(), Color::RED);
        assert_eq!(m.get_region_names().len(), 1);
        assert!(m.remove_region("a"));
        assert!(!m.remove_region("a"));
    }

    #[test]
    fn get_region_at_hit() {
        let mut m = PolygonMap::new();
        m.add_region("sq", square_verts(), Color::RED);
        assert_eq!(m.get_region_at(5.0, 5.0), Some("sq"));
        assert_eq!(m.get_region_at(50.0, 50.0), None);
    }

    #[test]
    fn set_and_get_region_color() {
        let mut m = PolygonMap::new();
        m.add_region("sq", square_verts(), Color::RED);
        assert!(m.set_region_color("sq", Color::BLUE));
        let c = m.get_region_color("sq").unwrap();
        assert!((c.b - 1.0).abs() < 1e-6);
        assert!(!m.set_region_color("missing", Color::RED));
    }

    #[test]
    fn set_region_label() {
        let mut m = PolygonMap::new();
        m.add_region("sq", square_verts(), Color::RED);
        assert!(m.set_region_label("sq", "hello", 20.0));
        assert!(!m.set_region_label("nope", "x", 10.0));
    }

    #[test]
    fn get_region_center() {
        let mut m = PolygonMap::new();
        m.add_region("sq", square_verts(), Color::RED);
        let (cx, cy) = m.get_region_center("sq").unwrap();
        assert!((cx - 5.0).abs() < 1e-4);
        assert!((cy - 5.0).abs() < 1e-4);
    }

    #[test]
    fn bounding_box_single_region() {
        let mut m = PolygonMap::new();
        m.add_region("sq", square_verts(), Color::RED);
        let (x, y, w, h) = m.get_bounding_box().unwrap();
        assert!((x - 0.0).abs() < 1e-4);
        assert!((y - 0.0).abs() < 1e-4);
        assert!((w - 10.0).abs() < 1e-4);
        assert!((h - 10.0).abs() < 1e-4);
    }

    #[test]
    fn highlight_and_clear() {
        let mut m = PolygonMap::new();
        m.highlight("sq");
        assert_eq!(m.highlighted.as_deref(), Some("sq"));
        m.clear_highlight();
        assert!(m.highlighted.is_none());
    }

    #[test]
    fn clear_removes_all() {
        let mut m = PolygonMap::new();
        m.add_region("a", square_verts(), Color::RED);
        m.add_region("b", square_verts(), Color::BLUE);
        m.highlight("a");
        m.clear();
        assert!(m.get_region_names().is_empty());
        assert!(m.highlighted.is_none());
    }

    #[test]
    fn remove_highlighted_region_clears_highlight() {
        let mut m = PolygonMap::new();
        m.add_region("h", square_verts(), Color::RED);
        m.highlight("h");
        m.remove_region("h");
        assert!(m.highlighted.is_none());
    }
}

// ── tilemap (from sibling) ────────────────────────────────────────────────────

mod tilemap_core_tests {
    use super::*;

    fn make_test_tileset() -> TileSet {
        let mut ts = TileSet::new(1, 16, 4, 32, 32, 0, 0);
        ts.set_solid(0, true);
        ts
    }

    fn make_test_map() -> TileMap {
        let mut map = TileMap::new(32, 32, 8);
        map.add_tileset(make_test_tileset());
        map.add_layer("ground", 10, 10);
        map
    }

    #[test]
    fn layer_add_and_get() {
        let mut map = TileMap::new(32, 32, 8);
        let idx = map.add_layer("bg", 20, 15);
        assert_eq!(idx, 0);
        assert_eq!(map.get_layer_count(), 1);
        assert_eq!(map.get_layer_name(0), Some("bg"));
        assert!(map.get_layer_visible(0));
    }

    #[test]
    fn tile_set_get() {
        let mut map = make_test_map();
        map.set_tile(0, 3, 4, 5);
        assert_eq!(map.get_tile(0, 3, 4), 5);
        assert_eq!(map.get_tile(0, 0, 0), 0);
        assert_eq!(map.get_tile(0, 100, 100), 0);
    }

    #[test]
    fn fill_layer() {
        let mut map = make_test_map();
        map.fill(0, 3);
        for y in 0..10 {
            for x in 0..10 {
                assert_eq!(map.get_tile(0, x, y), 3);
            }
        }
    }

    #[test]
    fn clear_tile_sets_zero() {
        let mut map = make_test_map();
        map.set_tile(0, 2, 2, 7);
        assert_eq!(map.get_tile(0, 2, 2), 7);
        map.clear_tile(0, 2, 2);
        assert_eq!(map.get_tile(0, 2, 2), 0);
    }

    #[test]
    fn viewport_set_get() {
        let mut map = make_test_map();
        assert!(map.get_viewport().is_none());
        map.set_viewport(10.0, 20.0, 640.0, 480.0);
        let vp = map.get_viewport().expect("viewport set before use");
        assert!((vp.0 - 10.0).abs() < 1e-5);
        assert!((vp.1 - 20.0).abs() < 1e-5);
        assert!((vp.2 - 640.0).abs() < 1e-5);
        assert!((vp.3 - 480.0).abs() < 1e-5);
    }

    #[test]
    fn world_to_tile_roundtrip() {
        let map = make_test_map();
        let (wx, wy) = map.tile_to_world(3, 5);
        assert!((wx - 96.0).abs() < 1e-5);
        assert!((wy - 160.0).abs() < 1e-5);
        let (tx, ty) = map.world_to_tile(wx, wy);
        assert_eq!(tx, 3);
        assert_eq!(ty, 5);
    }

    #[test]
    fn autotile_4bit_basic() {
        let mut ts = TileSet::new(1, 256, 16, 32, 32, 0, 0);
        ts.set_auto_tile_rule("wall", 15, 42);
        ts.set_auto_tile_rule("wall", 5, 10);

        let mut map = TileMap::new(32, 32, 8);
        map.add_tileset(ts);
        map.add_layer("ground", 3, 3);
        map.fill(0, 1);
        map.apply_autotile(0, "wall");
        assert_eq!(map.get_tile(0, 1, 1), 43);
    }

    #[test]
    fn is_solid_with_tileset() {
        let mut map = make_test_map();
        map.set_tile(0, 5, 5, 1);
        assert!(map.is_solid(0, 5, 5));
        map.set_tile(0, 6, 6, 2);
        assert!(!map.is_solid(0, 6, 6));
        assert!(!map.is_solid(0, 0, 0));
    }

    #[test]
    fn rect_overlaps_solid_test() {
        let mut map = make_test_map();
        map.set_tile(0, 3, 3, 1);
        assert!(map.rect_overlaps_solid(0, Rect::new(90.0, 90.0, 20.0, 20.0)));
        assert!(!map.rect_overlaps_solid(0, Rect::new(0.0, 0.0, 10.0, 10.0)));
    }

    #[test]
    fn sweep_rect_basic() {
        let mut map = make_test_map();
        map.set_tile(0, 5, 0, 1);
        let result = map.sweep_rect(0, Rect::new(0.0, 0.0, 16.0, 16.0), 200.0, 0.0);
        assert!(result.is_some());
        let r = result.expect("sweep result is Some");
        assert!(r.t > 0.0 && r.t < 1.0);
        assert!((r.normal.x - (-1.0)).abs() < 1e-5);
        assert_eq!(r.tile_x, 5);
    }

    #[test]
    fn sweep_rect_no_collision() {
        let map = make_test_map();
        let result = map.sweep_rect(0, Rect::new(0.0, 0.0, 16.0, 16.0), 100.0, 0.0);
        assert!(result.is_none());
    }

    #[test]
    fn layer_color_offset_parallax() {
        let mut map = make_test_map();
        map.set_layer_color(0, 1.0, 0.5, 0.25, 0.8);
        let c = map.get_layer_color(0);
        assert!((c[0] - 1.0).abs() < 1e-5);
        assert!((c[1] - 0.5).abs() < 1e-5);
        assert!((c[2] - 0.25).abs() < 1e-5);
        assert!((c[3] - 0.8).abs() < 1e-5);

        map.set_layer_offset(0, 10.0, 20.0);
        let o = map.get_layer_offset(0);
        assert!((o.x - 10.0).abs() < 1e-5);
        assert!((o.y - 20.0).abs() < 1e-5);

        map.set_layer_parallax(0, 0.5, 0.75);
        let p = map.get_layer_parallax(0);
        assert!((p.x - 0.5).abs() < 1e-5);
        assert!((p.y - 0.75).abs() < 1e-5);
    }

    #[test]
    fn tileset_management() {
        let mut map = TileMap::new(32, 32, 8);
        assert_eq!(map.get_tileset_count(), 0);
        map.add_tileset(TileSet::new(1, 16, 4, 32, 32, 0, 0));
        assert_eq!(map.get_tileset_count(), 1);
        assert!(map.get_tileset(0).is_some());
        assert!(map.get_tileset(1).is_none());
    }

    #[test]
    fn dimensions() {
        let map = TileMap::new(16, 24, 4);
        assert_eq!(map.get_tile_width(), 16);
        assert_eq!(map.get_tile_height(), 24);
        assert_eq!(map.get_tile_dimensions(), (16, 24));
        assert_eq!(map.get_chunk_size(), 4);
    }

    #[test]
    fn layer_visibility() {
        let mut map = make_test_map();
        assert!(map.get_layer_visible(0));
        map.set_layer_visible(0, false);
        assert!(!map.get_layer_visible(0));
    }

    #[test]
    fn world_to_tile_negative_clamps() {
        let map = make_test_map();
        let (tx, ty) = map.world_to_tile(-10.0, -5.0);
        assert_eq!(tx, 0);
        assert_eq!(ty, 0);
    }
}
