//! INTERNAL ONLY: Rust-only tests for minimap render helpers that are not directly asserted
//! through `lurek.minimap.*`.
//!
//! Public minimap state and control behaviour lives in
//! `tests/lua/unit/test_minimap_unit.lua`. The remaining Rust tests keep the
//! generated render-command shape for internal overlays and ping markers.

use lurek2d::minimap::*;

mod helper_tests {
    use super::*;
    use lurek2d::camera::Camera2D;

    #[test]
    fn reveal_radius_marks_cells_visible_inside_circle() {
        let mut map = Minimap::new(8, 8, 80, 80);
        map.set_fog_enabled(true);
        map.set_fog_data(&vec![0; 64]);

        map.reveal_radius(3.5, 3.5, 1.6);

        assert_eq!(map.get_fog_level(3, 3), FogLevel::Visible);
        assert_eq!(map.get_fog_level(2, 3), FogLevel::Visible);
        assert_eq!(map.get_fog_level(0, 0), FogLevel::Hidden);
    }

    #[test]
    fn track_camera_syncs_center_and_viewport_rect() {
        let mut map = Minimap::new(64, 64, 256, 256);
        let mut camera = Camera2D::new(20.0, 10.0);
        camera.set_position(12.0, 18.0);
        camera.set_zoom(2.0);

        map.track_camera(&camera);

        assert_eq!((map.center_x(), map.center_y()), (12.0, 18.0));
        assert_eq!(map.viewport_rect(), Some((7.0, 15.5, 10.0, 5.0)));
    }
}

mod cpu_image_tests {
    use super::*;

    #[test]
    fn political_draw_to_image_uses_owner_color_for_occupied_cell() {
        let mut map = Minimap::new(4, 4, 40, 40);
        let unit_type = map.add_object_type("unit".to_string(), [0.2, 0.8, 0.2, 1.0]);
        map.set_terrain_color(1, [0.0, 0.0, 1.0, 1.0]);
        map.set_owner_color(9, [1.0, 0.0, 0.0, 1.0]);
        map.set_terrain(1, 1, 1);
        map.set_object(1, 1.2, 1.3, unit_type, 9);
        map.set_color_mode(ColorMode::Political);

        let image = map.draw_to_image(1);
        let pixel = image
            .get_pixel(18, 18)
            .expect("expected political pixel inside occupied cell");

        assert!(
            pixel.0 > 200,
            "expected owner red channel to dominate, got {pixel:?}"
        );
        assert!(
            pixel.2 < 80,
            "expected terrain blue to be replaced by owner color, got {pixel:?}"
        );
    }
}

// ── render ────────────────────────────────────────────────────────────

mod render_tests {
    use super::*;
    use lurek2d::render::renderer::{DrawMode, RenderCommand};

    #[test]
    fn empty_minimap_emits_background() {
        let map = Minimap::new(10, 10, 100, 100);
        let cmds = map.generate_render_commands(0.0, 0.0);
        assert!(!cmds.is_empty(), "expected at least a background rectangle");
        assert!(
            cmds.iter().any(|c| matches!(
                c,
                RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    ..
                }
            )),
            "expected a Fill rectangle for background"
        );
    }

    #[test]
    fn no_pings_no_circle_commands() {
        let map = Minimap::new(8, 8, 80, 80);
        let cmds = map.generate_render_commands(0.0, 0.0);
        assert!(
            !cmds
                .iter()
                .any(|c| matches!(c, RenderCommand::Circle { .. })),
            "expected no Circle commands when there are no pings"
        );
    }

    #[test]
    fn ping_produces_circle_command() {
        let mut map = Minimap::new(8, 8, 80, 80);
        map.add_ping(4.0, 4.0, 1.0, [1.0, 0.0, 0.0, 1.0]);
        let cmds = map.generate_render_commands(0.0, 0.0);
        assert!(
            cmds.iter()
                .any(|c| matches!(c, RenderCommand::Circle { .. })),
            "expected a Circle command for the ping"
        );
    }

    #[test]
    fn viewport_rect_produces_line_rectangle() {
        let mut map = Minimap::new(10, 10, 100, 100);
        map.set_viewport_rect(2.0, 2.0, 4.0, 4.0);
        let cmds = map.generate_render_commands(0.0, 0.0);
        assert!(
            cmds.iter().any(|c| matches!(
                c,
                RenderCommand::Rectangle {
                    mode: DrawMode::Line,
                    ..
                }
            )),
            "expected a Line rectangle for the viewport overlay"
        );
    }

    #[test]
    fn build_render_commands_matches_generate_render_commands() {
        let mut map = Minimap::new(12, 12, 120, 120);
        let unit_type = map.add_object_type("unit".to_string(), [0.9, 0.1, 0.1, 1.0]);
        map.set_terrain_color(1, [0.2, 0.3, 0.4, 1.0]);
        map.set_terrain(3, 4, 1);
        map.set_object(1, 3.5, 4.5, unit_type, 2);
        map.add_marker(5.0, 5.0, "poi".to_string(), [1.0, 1.0, 0.0, 1.0]);
        map.draw_line(1.0, 1.0, 6.0, 6.0, [255, 255, 255, 255]);
        map.show_path(vec![(0.0, 0.0), (2.0, 3.0), (5.0, 8.0)], [255, 0, 0, 255]);

        let generated = map.generate_render_commands(8.0, 12.0);
        let built = map.build_render_commands(8.0, 12.0);

        assert_eq!(generated.len(), built.len());
        let generated_debug: Vec<String> = generated.iter().map(|cmd| format!("{cmd:?}")).collect();
        let built_debug: Vec<String> = built.iter().map(|cmd| format!("{cmd:?}")).collect();
        assert_eq!(generated_debug, built_debug);
    }
}
