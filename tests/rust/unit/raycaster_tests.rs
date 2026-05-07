//! INTERNAL ONLY: Public `lurek.raycaster.*` behavior is covered by the Lua-first suites in
//! `tests/lua/unit/test_raycaster_unit.lua` and
//! `tests/lua/evidence/test_raycaster_evidence.lua`.
//!
//! The Rust coverage that remains here focuses on lower-level helpers not
//! exercised directly through the Lua object surface, such as polygon visibility
//! math, free-function ray casting against segments, and internal scene/render
//! command generation.

use lurek2d::math::{Color, Vec2};
use lurek2d::raycaster::*;
use lurek2d::render::renderer::RenderCommand;

// ── visibility ────────────────────────────────────────────────────────

mod visibility_tests {
    use super::*;

    #[test]
    fn test_field_of_view_produces_polygon() {
        let segs = vec![
            Segment {
                x1: -5.0,
                y1: 5.0,
                x2: 5.0,
                y2: 5.0,
            },
            Segment {
                x1: 5.0,
                y1: 5.0,
                x2: 5.0,
                y2: -5.0,
            },
            Segment {
                x1: 5.0,
                y1: -5.0,
                x2: -5.0,
                y2: -5.0,
            },
            Segment {
                x1: -5.0,
                y1: -5.0,
                x2: -5.0,
                y2: 5.0,
            },
        ];
        let poly = field_of_view(0.0, 0.0, &segs, 20.0);
        assert!(poly.len() >= 8); // at least 4 points (8 floats)
    }
}

// ── segment ───────────────────────────────────────────────────────────

mod segment_tests {
    use super::*;

    fn make_segments() -> Vec<Segment> {
        vec![
            Segment {
                x1: 5.0,
                y1: -2.0,
                x2: 5.0,
                y2: 2.0,
            }, // vertical wall at x=5
        ]
    }

    #[test]
    fn test_cast_ray_hit() {
        let segs = make_segments();
        let result = cast_ray_2d(0.0, 0.0, 1.0, 0.0, 100.0, &segs);
        assert!(result.is_some());
        let (hx, hy, idx) = result.unwrap();
        assert!((hx - 5.0).abs() < 1e-3);
        assert!((hy - 0.0).abs() < 1e-3);
        assert_eq!(idx, 0);
    }

    #[test]
    fn test_cast_ray_miss() {
        let segs = make_segments();
        // Ray going away from wall
        let result = cast_ray_2d(0.0, 0.0, -1.0, 0.0, 100.0, &segs);
        assert!(result.is_none());
    }
}

// ── scene ─────────────────────────────────────────────────────────────

mod scene_tests {
    use super::*;
    use lurek2d::raycaster::scene::{CeilingQuad, FloorQuad, WallQuad};

    fn unit_corners(x: f32, y: f32, w: f32, h: f32) -> [Vec2; 4] {
        [
            Vec2::new(x, y),
            Vec2::new(x + w, y),
            Vec2::new(x + w, y + h),
            Vec2::new(x, y + h),
        ]
    }

    fn unit_uvs() -> [Vec2; 4] {
        [
            Vec2::new(0.0, 0.0),
            Vec2::new(1.0, 0.0),
            Vec2::new(1.0, 1.0),
            Vec2::new(0.0, 1.0),
        ]
    }

    #[test]
    fn empty_scene_has_zero_quads() {
        let scene = RaycasterScene::new(800.0, 600.0);
        assert_eq!(scene.quad_count(), 0);
        assert!(scene.is_empty());
    }

    #[test]
    fn scene_counts_all_quad_types() {
        let mut scene = RaycasterScene::new(800.0, 600.0);
        scene.walls.push(WallQuad {
            corners: unit_corners(0.0, 0.0, 1.0, 100.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 2.0,
            corner_w: [1.0, 1.0, 1.0, 1.0],
            cell_value: 1,
        });
        scene.floors.push(FloorQuad {
            corners: unit_corners(0.0, 100.0, 1.0, 50.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 2.0,
            corner_w: [1.0, 1.0, 1.0, 1.0],
        });
        scene.ceilings.push(CeilingQuad {
            corners: unit_corners(0.0, 0.0, 1.0, 50.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 2.0,
            corner_w: [1.0, 1.0, 1.0, 1.0],
        });
        assert_eq!(scene.quad_count(), 3);
        assert!(!scene.is_empty());
    }
}

// ── render ────────────────────────────────────────────────────────────

mod render_tests {
    use super::*;
    use lurek2d::raycaster::scene::{CeilingQuad, FloorQuad, WallQuad};
    use lurek2d::runtime::resource_keys::TextureKey;
    use slotmap::KeyData;

    fn make_corners(x: f32, y: f32, w: f32, h: f32) -> [Vec2; 4] {
        [
            Vec2::new(x, y),
            Vec2::new(x + w, y),
            Vec2::new(x + w, y + h),
            Vec2::new(x, y + h),
        ]
    }

    fn unit_uvs() -> [Vec2; 4] {
        [
            Vec2::new(0.0, 0.0),
            Vec2::new(1.0, 0.0),
            Vec2::new(1.0, 1.0),
            Vec2::new(0.0, 1.0),
        ]
    }

    #[test]
    fn raycaster_scene_empty_gives_empty_commands() {
        // Default scene has no quads — only SetBlendMode is emitted
        let scene = RaycasterScene::default();
        let cmds = scene.generate_render_commands();
        // Only the SetBlendMode preamble, no geometry commands
        assert!(
            cmds.iter()
                .all(|c| matches!(c, RenderCommand::SetBlendMode(_))),
            "Empty scene should have no geometry commands"
        );
    }

    #[test]
    fn empty_scene_produces_minimal_commands() {
        let scene = RaycasterScene::new(320.0, 200.0);
        let cmds = scene.generate_render_commands();
        // Just SetBlendMode
        assert_eq!(cmds.len(), 1);
    }

    #[test]
    fn raycaster_scene_with_wall_gives_draw_textured_quad() {
        let tk = TextureKey::from(KeyData::from_ffi(1));

        let mut scene = RaycasterScene::new(320.0, 200.0);
        scene.walls.push(WallQuad {
            corners: make_corners(10.0, 50.0, 1.0, 100.0),
            uvs: unit_uvs(),
            texture_key: Some(tk),
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 3.0,
            corner_w: [1.0, 1.0, 1.0, 1.0],
            cell_value: 1,
        });
        let cmds = scene.generate_render_commands();
        assert!(
            cmds.iter()
                .any(|c| matches!(c, RenderCommand::DrawTexturedQuad { .. })),
            "Expected a DrawTexturedQuad command"
        );
    }

    #[test]
    fn wall_quad_untextured_emits_set_color_and_rectangle() {
        let mut scene = RaycasterScene::new(320.0, 200.0);
        scene.walls.push(WallQuad {
            corners: make_corners(10.0, 50.0, 32.0, 100.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [0.8, 0.6, 0.4, 1.0],
            depth: 3.0,
            corner_w: [1.0, 1.0, 1.0, 1.0],
            cell_value: 1,
        });
        let cmds = scene.generate_render_commands();
        // SetBlendMode + SetColor + Rectangle = 3
        assert_eq!(cmds.len(), 3);
        assert!(matches!(cmds[1], RenderCommand::SetColor(..)));
        assert!(matches!(cmds[2], RenderCommand::Rectangle { .. }));
    }

    #[test]
    fn floor_emits_draw_command() {
        let mut scene = RaycasterScene::new(320.0, 200.0);
        scene.floors.push(FloorQuad {
            corners: make_corners(0.0, 100.0, 32.0, 100.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 3.0,
            corner_w: [1.0, 1.0, 1.0, 1.0],
        });
        let cmds = scene.generate_render_commands();
        assert!(cmds.len() >= 2);
    }

    #[test]
    fn ceiling_drawn_before_walls() {
        let mut scene = RaycasterScene::new(320.0, 200.0);
        scene.ceilings.push(CeilingQuad {
            corners: make_corners(0.0, 0.0, 32.0, 50.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 3.0,
            corner_w: [1.0, 1.0, 1.0, 1.0],
        });
        scene.walls.push(WallQuad {
            corners: make_corners(0.0, 50.0, 32.0, 100.0),
            uvs: unit_uvs(),
            texture_key: None,
            light: [1.0, 1.0, 1.0, 1.0],
            depth: 3.0,
            corner_w: [1.0, 1.0, 1.0, 1.0],
            cell_value: 1,
        });
        let cmds = scene.generate_render_commands();
        // Find first Rectangle after SetBlendMode — should be the ceiling
        let first_rect_idx = cmds
            .iter()
            .position(|c| matches!(c, RenderCommand::Rectangle { .. }))
            .unwrap();
        // Ceiling rect has y=0 (top-left corner of ceiling quad)
        if let RenderCommand::Rectangle { y, .. } = &cmds[first_rect_idx] {
            assert!((*y).abs() < 1e-5, "First rectangle should be ceiling (y=0)");
        }
    }

    #[test]
    fn draw_to_image_returns_correct_dimensions() {
        let scene = RaycasterScene::default();
        let img = scene.draw_to_image(320, 200);
        assert_eq!(img.width(), 320);
        assert_eq!(img.height(), 200);
    }
}

// ── minimap_overlay ───────────────────────────────────────────────────

mod minimap_overlay_tests {
    use super::*;

    #[test]
    fn test_extract_minimap_dimensions() {
        let rc = Raycaster2D::new(16, 16);
        let (pixels, w, h) = extract_minimap(
            &rc,
            8.0,
            8.0,
            0.0,
            3,
            4,
            [255, 255, 255, 255],
            [50, 50, 50, 255],
            [255, 0, 0, 255],
        );
        // diameter = 2*3+1 = 7, pixel size = 7*4 = 28
        assert_eq!(w, 28);
        assert_eq!(h, 28);
        assert_eq!(pixels.len(), (28 * 28 * 4) as usize);
    }

    #[test]
    fn test_extract_minimap_wall_colors() {
        let mut rc = Raycaster2D::new(8, 8);
        // Fill all with walls
        for y in 0..8 {
            for x in 0..8 {
                rc.set_cell(x, y, 1);
            }
        }

        let (pixels, w, _h) = extract_minimap(
            &rc,
            4.0,
            4.0,
            0.0,
            1,
            2,
            [200, 200, 200, 255],
            [0, 0, 0, 255],
            [255, 0, 0, 255],
        );

        let idx = 0usize;
        assert!(idx + 3 < pixels.len());
        assert_eq!(pixels[idx], 200); // R
        assert_eq!(w, 6);
    }

    #[test]
    fn test_draw_player_arrow_no_panic() {
        let mut pixels = vec![0u8; 100 * 100 * 4];
        draw_player_arrow(&mut pixels, 100, 50, 50, 0.0, 8, [255, 0, 0, 255]);
        // Just verify it doesn't panic and writes some non-zero pixels
        let has_red = pixels.chunks(4).any(|c| c[0] == 255 && c[3] == 255);
        assert!(has_red);
    }
}

// ── lighting ──────────────────────────────────────────────────────────

mod lighting_tests {
    use super::*;

    #[test]
    fn test_ambient_only() {
        let result = compute_lighting(0.0, 0.0, 0.3, &[], &|_, _| false);
        assert!((result[0] - 0.3).abs() < 1e-5);
        assert!((result[1] - 0.3).abs() < 1e-5);
        assert!((result[2] - 0.3).abs() < 1e-5);
    }

    #[test]
    fn test_point_light_at_center() {
        let lights = vec![PointLight {
            x: 5.0,
            y: 5.0,
            radius: 10.0,
            intensity: 16.0,
            color: [1.0, 1.0, 1.0],
        }];
        let result = compute_lighting(5.0, 5.0, 0.0, &lights, &|_, _| false);
        // At distance 0, attenuation = 1.0 * 1.0 = 1.0
        assert!((result[0] - 1.0).abs() < 1e-5);
    }

    #[test]
    fn test_point_light_out_of_range() {
        let lights = vec![PointLight {
            x: 0.0,
            y: 0.0,
            radius: 5.0,
            intensity: 1.0,
            color: [1.0, 1.0, 1.0],
        }];
        let result = compute_lighting(10.0, 10.0, 0.1, &lights, &|_, _| false);
        assert!((result[0] - 0.1).abs() < 1e-5);
    }

    #[test]
    fn test_apply_lit_shade() {
        let result = apply_lit_shade(0.5, [1.0, 0.8, 0.6]);
        assert!((result[0] - 0.5).abs() < 1e-5);
        assert!((result[1] - 0.4).abs() < 1e-5);
        assert!((result[2] - 0.3).abs() < 1e-5);
    }
}

// ── heightmap ─────────────────────────────────────────────────────────

mod heightmap_tests {
    use super::*;

    #[test]
    fn test_out_of_bounds() {
        let hm = HeightMap::new(4, 4);
        assert!((hm.floor_at(10, 10)).abs() < 1e-5);
        assert!((hm.ceiling_at(10, 10) - 1.0).abs() < 1e-5);
    }

    #[test]
    fn test_set_rect() {
        let mut hm = HeightMap::new(8, 8);
        hm.set_floor_rect(2, 2, 3, 3, 0.25);
        assert!((hm.floor_at(3, 3) - 0.25).abs() < 1e-5);
        assert!((hm.floor_at(0, 0)).abs() < 1e-5);
    }
}

// ── draw ──────────────────────────────────────────────────────────────

mod draw_tests {
    use super::*;

    #[test]
    fn draw_to_image_empty_scene_returns_correct_dimensions() {
        let scene = RaycasterScene::default();
        let img = scene.draw_to_image(320, 200);
        assert_eq!(img.width(), 320);
        assert_eq!(img.height(), 200);
    }

    #[test]
    fn draw_to_image_nonzero_size() {
        let scene = RaycasterScene::default();
        let img = scene.draw_to_image(64, 48);
        assert_eq!(img.width(), 64);
        assert_eq!(img.height(), 48);
    }
}

// ── doors ─────────────────────────────────────────────────────────────

mod doors_tests {
    use super::*;

    #[test]
    fn test_door_not_found() {
        let mgr = DoorManager::new();
        assert!(mgr.get_door_at(0, 0).is_none());
    }
}

// ── depth_buffer ──────────────────────────────────────────────────────

mod depth_buffer_tests {
    use super::*;

    #[test]
    fn test_new_buffer() {
        let buf = DepthBuffer::new(320);
        assert_eq!(buf.width(), 320);
        assert_eq!(buf.get(0), f32::MAX);
    }

    #[test]
    fn test_set_and_get() {
        let mut buf = DepthBuffer::new(10);
        buf.set(5, 3.5);
        assert!((buf.get(5) - 3.5).abs() < 1e-5);
    }

    #[test]
    fn test_is_visible() {
        let mut buf = DepthBuffer::new(10);
        buf.set(3, 5.0);
        assert!(buf.is_visible(3, 4.0));
        assert!(!buf.is_visible(3, 6.0));
        assert!(!buf.is_visible(3, 5.0));
    }

    #[test]
    fn test_clear() {
        let mut buf = DepthBuffer::new(10);
        buf.set(0, 1.0);
        buf.clear();
        assert_eq!(buf.get(0), f32::MAX);
    }

    #[test]
    fn test_out_of_bounds() {
        let buf = DepthBuffer::new(5);
        assert_eq!(buf.get(100), f32::MAX);
    }
}

// ── column_batch ──────────────────────────────────────────────────────

mod column_batch_tests {
    use super::*;

    #[test]
    fn new_creates_correct_count() {
        let batch = ColumnBatch::new(10, 320.0, 200.0);
        assert_eq!(batch.get_column_count(), 10);
        assert_eq!(batch.get_screen_width(), 320.0);
        assert_eq!(batch.get_screen_height(), 200.0);
    }

    #[test]
    fn column_data_defaults() {
        let cd = ColumnData::default();
        assert_eq!(cd.tex_u, 0.0);
        assert_eq!(cd.shade, 1.0);
        assert_eq!(cd.cell_val, 0);
        assert_eq!(cd.depth, 0.0);
    }

    #[test]
    fn set_and_get_column() {
        let mut batch = ColumnBatch::new(4, 320.0, 200.0);
        batch.set_column(1, 0.5, 10.0, 190.0, 0.8, 3);
        let col = batch.get_column(1).unwrap();
        assert_eq!(col.tex_u, 0.5);
        assert_eq!(col.start, 10.0);
        assert_eq!(col.end, 190.0);
        assert_eq!(col.shade, 0.8);
        assert_eq!(col.cell_val, 3);
    }

    #[test]
    fn get_column_oob_returns_none() {
        let batch = ColumnBatch::new(2, 320.0, 200.0);
        assert!(batch.get_column(5).is_none());
    }

    #[test]
    fn depth_buffer_length() {
        let batch = ColumnBatch::new(8, 320.0, 200.0);
        assert_eq!(batch.get_depth_buffer().len(), 8);
    }

    #[test]
    fn update_from_ray_data_sets_columns() {
        let mut batch = ColumnBatch::new(2, 320.0, 200.0);
        // 5 floats per ray: distance, cellValue, side, texU, hit
        let rays = vec![
            2.0, 1.0, 0.0, 0.25, 1.0, // ray 0
            4.0, 2.0, 1.0, 0.75, 1.0, // ray 1
        ];
        batch.update_from_ray_data(&rays, 1.0, Some(10.0));
        let c0 = batch.get_column(0).unwrap();
        assert_eq!(c0.cell_val, 1);
        assert_eq!(c0.tex_u, 0.25);
        assert!(c0.depth > 0.0);
    }
}

// ── build_scene ───────────────────────────────────────────────────────

mod build_scene_tests {
    use super::*;
    use lurek2d::runtime::resource_keys::TextureKey;
    use slotmap::KeyData;

    fn default_params() -> SceneBuildParams {
        SceneBuildParams {
            player_x: 5.0,
            player_y: 5.0,
            player_angle: 0.0,
            fov: std::f32::consts::FRAC_PI_3,
            ray_count: 10,
            max_distance: 20.0,
            screen_width: 320.0,
            screen_height: 200.0,
            ambient_light: 0.3,
            shade_distance: 15.0,
            floor_color: Color::new(0.2, 0.2, 0.2, 1.0),
            ceiling_color: Color::new(0.1, 0.1, 0.15, 1.0),
            camera_height: 2.0 / 3.0,
            horizon_offset: 0.0,
        }
    }

    #[test]
    fn empty_grid_produces_only_floor_ceiling() {
        let rc = Raycaster2D::new(10, 10);
        let params = default_params();
        let scene = RaycasterScene::build(
            &rc,
            &params,
            &[],
            &[],
            &|_| None,
            &|_, _| None,
            &|_, _| None,
            &|_, _| None,
        );

        assert!(scene.walls.is_empty(), "No walls in empty grid");
        assert!(!scene.floors.is_empty(), "Floor quads should exist");
        assert!(!scene.ceilings.is_empty(), "Ceiling quads should exist");
    }

    #[test]
    fn wall_produces_wall_quads() {
        let mut rc = Raycaster2D::new(10, 10);
        // Place a wall directly in front of the player
        rc.set_cell(7, 5, 1);
        let params = default_params();
        let scene = RaycasterScene::build(
            &rc,
            &params,
            &[],
            &[],
            &|_| None,
            &|_, _| None,
            &|_, _| None,
            &|_, _| None,
        );

        assert!(!scene.walls.is_empty(), "Should have wall quads");
        for wall in &scene.walls {
            assert!(wall.depth > 0.0, "Wall depth should be positive");
            assert!(
                wall.uvs[0].x >= 0.0 && wall.uvs[0].x <= 1.0,
                "wall u0 should be in [0,1]"
            );
            assert!(
                wall.uvs[1].x >= 0.0 && wall.uvs[1].x <= 1.0,
                "wall u1 should be in [0,1]"
            );
            assert!(
                (wall.uvs[1].x - wall.uvs[0].x).abs() > 0.0,
                "wall UV span should not be degenerate"
            );
            // corners[3].y - corners[0].y = height
            let wall_h = wall.corners[3].y - wall.corners[0].y;
            assert!(wall_h > 0.0, "Wall height should be positive");
        }
    }

    #[test]
    fn sprites_sorted_back_to_front() {
        let rc = Raycaster2D::new(20, 20);
        let params = SceneBuildParams {
            player_x: 10.0,
            player_y: 10.0,
            player_angle: 0.0,
            fov: std::f32::consts::FRAC_PI_3,
            ray_count: 10,
            max_distance: 20.0,
            screen_width: 320.0,
            screen_height: 200.0,
            ambient_light: 0.3,
            shade_distance: 15.0,
            floor_color: Color::BLACK,
            ceiling_color: Color::BLACK,
            camera_height: 2.0 / 3.0,
            horizon_offset: 0.0,
        };

        let tk = TextureKey::from(KeyData::from_ffi(1));

        let sprites = vec![
            WorldSprite {
                world_x: 12.0,
                world_y: 10.0,
                texture_key: tk,
                size: 1.0,
            },
            WorldSprite {
                world_x: 15.0,
                world_y: 10.0,
                texture_key: tk,
                size: 1.0,
            },
        ];

        let scene = RaycasterScene::build(
            &rc,
            &params,
            &[],
            &sprites,
            &|_| None,
            &|_, _| None,
            &|_, _| None,
            &|_, _| None,
        );
        if scene.sprites.len() >= 2 {
            assert!(
                scene.sprites[0].depth >= scene.sprites[1].depth,
                "Sprites should be sorted back-to-front"
            );
        }
    }

    #[test]
    fn per_polygon_lighting_applied() {
        let mut rc = Raycaster2D::new(10, 10);
        rc.set_cell(7, 5, 1);

        let params = default_params();
        let lights = vec![PointLight {
            x: 6.0,
            y: 5.0,
            radius: 5.0,
            intensity: 1.0,
            color: [1.0, 0.5, 0.0],
        }];

        let scene = RaycasterScene::build(
            &rc,
            &params,
            &lights,
            &[],
            &|_| None,
            &|_, _| None,
            &|_, _| None,
            &|_, _| None,
        );
        if let Some(wall) = scene.walls.first() {
            // With an orange light nearby, red channel should be higher than blue
            assert!(wall.light[0] > 0.0, "Wall should receive some light");
        }
    }

    #[test]
    fn floor_and_ceiling_texture_lookup_applies_per_cell_override() {
        let mut rc = Raycaster2D::new(10, 10);
        rc.set_cell(7, 5, 1);

        let params = default_params();
        let floor_key = TextureKey::from(KeyData::from_ffi(101));
        let ceiling_key = TextureKey::from(KeyData::from_ffi(202));

        let scene = RaycasterScene::build(
            &rc,
            &params,
            &[],
            &[],
            &|_| None,
            &|_, _| Some(floor_key),
            &|_, _| Some(ceiling_key),
            &|_, _| None,
        );

        assert!(
            scene.floors.iter().any(|f| f.texture_key == Some(floor_key)),
            "Expected at least one floor quad to use floor texture override"
        );
        assert!(
            scene
                .ceilings
                .iter()
                .any(|c| c.texture_key == Some(ceiling_key)),
            "Expected at least one ceiling quad to use ceiling texture override"
        );
    }

    #[test]
    fn floor_and_ceiling_without_override_keep_color_fallback() {
        let mut rc = Raycaster2D::new(10, 10);
        rc.set_cell(7, 5, 1);

        let params = default_params();
        let scene = RaycasterScene::build(
            &rc,
            &params,
            &[],
            &[],
            &|_| None,
            &|_, _| None,
            &|_, _| None,
            &|_, _| None,
        );

        assert!(
            scene.floors.iter().any(|f| f.texture_key.is_none()),
            "Expected some floor quads to remain untextured for color fallback"
        );
        assert!(
            scene.ceilings.iter().any(|c| c.texture_key.is_none()),
            "Expected some ceiling quads to remain untextured for color fallback"
        );
    }
}

// ── generic minimap/reveal helpers ───────────────────────────────────

mod generic_minimap_tests {
    use super::*;

    #[test]
    fn compute_tile_light_returns_values_in_range() {
        let rc = Raycaster2D::new(8, 8);
        let lights = vec![PointLight {
            x: 3.5,
            y: 3.5,
            radius: 4.0,
            intensity: 8.0,
            color: [1.0, 0.8, 0.5],
        }];
        let rgb = compute_tile_light(&rc, 3, 3, 0.2, &lights);
        assert!((0.0..=1.0).contains(&rgb[0]));
        assert!((0.0..=1.0).contains(&rgb[1]));
        assert!((0.0..=1.0).contains(&rgb[2]));
    }

    #[test]
    fn build_minimap_tile_window_returns_samples() {
        let mut rc = Raycaster2D::new(10, 10);
        rc.set_cell(4, 4, 1);
        let samples = build_minimap_tile_window(&rc, 5.5, 5.5, 3, 0.2, &[]);
        assert!(!samples.is_empty());
        assert!(samples.iter().any(|s| s.blocked));
        assert!(samples.iter().all(|s| s.x < 10 && s.y < 10));
    }

    #[test]
    fn reveal_cells_from_rays_returns_unique_cells() {
        let rc = Raycaster2D::new(16, 16);
        let cells = reveal_cells_from_rays(
            &rc,
            8.5,
            8.5,
            0.0,
            std::f32::consts::FRAC_PI_3,
            16,
            8.0,
            0.25,
        );
        assert!(!cells.is_empty());
        let mut uniq = std::collections::HashSet::new();
        for c in &cells {
            uniq.insert(*c);
        }
        assert_eq!(cells.len(), uniq.len());
    }
}
