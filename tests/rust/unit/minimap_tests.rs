//! Tests for the minimap module.

use lurek2d::minimap::*;

// ── types ─────────────────────────────────────────────────────────────

mod types_tests {
    use super::*;

    #[test]
    fn color_mode_parse_terrain() {
        assert_eq!(ColorMode::parse_mode("terrain"), Some(ColorMode::Terrain));
    }

    #[test]
    fn color_mode_parse_political() {
        assert_eq!(
            ColorMode::parse_mode("political"),
            Some(ColorMode::Political)
        );
    }

    #[test]
    fn color_mode_parse_unknown() {
        assert_eq!(ColorMode::parse_mode("unknown"), None);
    }

    #[test]
    fn color_mode_roundtrip() {
        assert_eq!(
            ColorMode::parse_mode(ColorMode::Terrain.as_str()),
            Some(ColorMode::Terrain)
        );
        assert_eq!(
            ColorMode::parse_mode(ColorMode::Political.as_str()),
            Some(ColorMode::Political)
        );
    }

    #[test]
    fn fog_level_from_u8() {
        assert_eq!(FogLevel::from_u8(0), FogLevel::Hidden);
        assert_eq!(FogLevel::from_u8(1), FogLevel::Explored);
        assert_eq!(FogLevel::from_u8(2), FogLevel::Visible);
        assert_eq!(FogLevel::from_u8(255), FogLevel::Visible);
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
}

// Public minimap state and control behavior is covered in
// `tests/lua/unit/test_minimap_unit.lua`.
