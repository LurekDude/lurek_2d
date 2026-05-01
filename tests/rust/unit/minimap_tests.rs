//! INTERNAL ONLY: Rust-only tests for minimap render helpers that are not directly asserted
//! through `lurek.minimap.*`.
//!
//! Public minimap state and control behaviour lives in
//! `tests/lua/unit/test_minimap_unit.lua`. The remaining Rust tests keep the
//! generated render-command shape for internal overlays and ping markers.

use lurek2d::minimap::*;

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

