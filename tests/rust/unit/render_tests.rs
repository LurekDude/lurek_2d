//! Tests for the render module.

use std::collections::HashMap;

use lurek2d::render::canvas::Canvas;
use lurek2d::render::decal_surface::DecalSurface;
use lurek2d::render::draw_layer::DrawLayer;
use lurek2d::render::font::{Font, AVAILABLE_CELL_SIZES, AVAILABLE_HEIGHTS};
use lurek2d::render::image_effect::ShaderPassDescriptor;
use lurek2d::render::mesh::{Mesh, MeshDrawMode, MeshVertex};
use lurek2d::render::postfx_pipeline::params_to_uniform;
use lurek2d::render::renderer::{
    BlendMode, DepthMode, PhysicsDebugConfig, StencilAction, StencilMode, TextSpan, TextureData,
};
use lurek2d::render::shape::{CompoundShape, ShapeCommand};
use lurek2d::render::DrawMode;

// ── canvas tests ────────────────────────────────────────────────────────────

mod canvas_tests {
    use super::*;

    #[test]
    fn new_stores_dimensions() {
        let c = Canvas::new(320, 240);
        assert_eq!(c.width, 320);
        assert_eq!(c.height, 240);
    }

    #[test]
    fn new_zero_dimensions_allowed() {
        let c = Canvas::new(0, 0);
        assert_eq!(c.width, 0);
        assert_eq!(c.height, 0);
    }

    #[test]
    fn clone_produces_independent_copy() {
        let c1 = Canvas::new(100, 200);
        let c2 = c1.clone();
        assert_eq!(c2.width, 100);
        assert_eq!(c2.height, 200);
    }
}

// ── decal_surface tests ─────────────────────────────────────────────────────

mod decal_surface_tests {
    use super::*;

    #[test]
    fn new_stores_dimensions() {
        let ds = DecalSurface::new(512, 256);
        assert_eq!(ds.width, 512);
        assert_eq!(ds.height, 256);
    }

    #[test]
    fn get_dimensions_returns_tuple() {
        let ds = DecalSurface::new(640, 480);
        assert_eq!(ds.get_dimensions(), (640, 480));
    }

    #[test]
    fn get_width_and_height_match() {
        let ds = DecalSurface::new(1920, 1080);
        assert_eq!(ds.get_width(), 1920);
        assert_eq!(ds.get_height(), 1080);
    }

    #[test]
    fn zero_dimensions_allowed() {
        let ds = DecalSurface::new(0, 0);
        assert_eq!(ds.get_dimensions(), (0, 0));
    }
}

// ── draw_layer tests ────────────────────────────────────────────────────────

mod draw_layer_tests {
    use super::*;

    #[test]
    fn new_starts_empty() {
        let dl = DrawLayer::new();
        assert_eq!(dl.get_count(), 0);
    }

    #[test]
    fn queue_returns_incrementing_ids() {
        let mut dl = DrawLayer::new();
        let id0 = dl.queue(0.0);
        let id1 = dl.queue(1.0);
        let id2 = dl.queue(2.0);
        assert_eq!(id0, 0);
        assert_eq!(id1, 1);
        assert_eq!(id2, 2);
        assert_eq!(dl.get_count(), 3);
    }

    #[test]
    fn flush_sorts_by_z_order_ascending() {
        let mut dl = DrawLayer::new();
        dl.queue(3.0);
        dl.queue(1.0);
        dl.queue(2.0);
        let entries = dl.flush();
        let z_values: Vec<f64> = entries.iter().map(|e| e.z_order).collect();
        assert_eq!(z_values, vec![1.0, 2.0, 3.0]);
    }

    #[test]
    fn flush_drains_entries() {
        let mut dl = DrawLayer::new();
        dl.queue(1.0);
        dl.queue(2.0);
        let _ = dl.flush();
        assert_eq!(dl.get_count(), 0);
    }

    #[test]
    fn clear_empties_queue() {
        let mut dl = DrawLayer::new();
        dl.queue(1.0);
        dl.queue(2.0);
        dl.clear();
        assert_eq!(dl.get_count(), 0);
    }

    #[test]
    fn flush_preserves_callback_ids() {
        let mut dl = DrawLayer::new();
        let id_high = dl.queue(10.0);
        let id_low = dl.queue(1.0);
        let entries = dl.flush();
        // After sorting, the low-z entry (id_low) comes first.
        assert_eq!(entries[0].callback_id, id_low);
        assert_eq!(entries[1].callback_id, id_high);
    }

    #[test]
    fn default_is_same_as_new() {
        let dl = DrawLayer::default();
        assert_eq!(dl.get_count(), 0);
    }

    #[test]
    fn flush_handles_nan_gracefully() {
        let mut dl = DrawLayer::new();
        dl.queue(f64::NAN);
        dl.queue(1.0);
        // Should not panic; NaN comparison falls back to Equal.
        let entries = dl.flush();
        assert_eq!(entries.len(), 2);
    }
}

// ── font tests ──────────────────────────────────────────────────────────────

mod font_tests {
    use super::*;

    #[test]
    fn nearest_size_exact_match() {
        assert_eq!(Font::nearest_size(10), 2);
        assert_eq!(Font::nearest_size(22), 5);
        assert_eq!(Font::nearest_size(5), 0);
    }

    #[test]
    fn nearest_size_rounds_to_closest() {
        assert_eq!(Font::nearest_size(8), 1);
        assert_eq!(Font::nearest_size(12), 2);
        assert_eq!(Font::nearest_size(16), 3);
    }

    #[test]
    fn nearest_size_extreme_values() {
        assert_eq!(Font::nearest_size(0), 0);
        assert_eq!(Font::nearest_size(1), 0);
        assert_eq!(Font::nearest_size(100), 5);
    }

    #[test]
    fn available_heights_and_cell_sizes_correspond() {
        assert_eq!(AVAILABLE_HEIGHTS.len(), AVAILABLE_CELL_SIZES.len());
        for (i, &h) in AVAILABLE_HEIGHTS.iter().enumerate() {
            assert_eq!(AVAILABLE_CELL_SIZES[i].1, h);
        }
    }

    #[test]
    fn load_all_sizes_returns_six_fonts() {
        let fonts = Font::load_all_sizes();
        assert_eq!(fonts.len(), 6, "expected 6 built-in font sizes");
    }

    #[test]
    fn loaded_font_glyph_lookup() {
        let fonts = Font::load_all_sizes();
        let (ref font, _, _) = fonts[0];
        let glyph = font.glyph('A');
        assert!(glyph.is_some(), "ASCII 'A' should be in the bitmap font");
        let info = glyph.unwrap();
        assert!(info.advance_width > 0.0);
    }

    #[test]
    fn glyph_returns_none_for_unsupported_chars() {
        let fonts = Font::load_all_sizes();
        let (ref font, _, _) = fonts[0];
        assert!(font.glyph('\x01').is_none());
        assert!(font.glyph('\u{FFFF}').is_none());
    }

    #[test]
    fn text_width_sums_advances() {
        let fonts = Font::load_all_sizes();
        let (ref font, _, _) = fonts[0];
        let w = font.text_width("AB");
        assert_eq!(w, 8.0);
    }

    #[test]
    fn text_width_empty_string() {
        let fonts = Font::load_all_sizes();
        let (ref font, _, _) = fonts[0];
        assert_eq!(font.text_width(""), 0.0);
    }

    #[test]
    fn line_height_default_multiplier() {
        let fonts = Font::load_all_sizes();
        let (ref font, _, ch) = fonts[0];
        assert_eq!(font.line_height(), ch as f32);
    }

    #[test]
    fn set_line_height_multiplier() {
        let fonts = Font::load_all_sizes();
        let (mut font, _, ch) = fonts.into_iter().next().unwrap();
        font.set_line_height(2.0);
        assert_eq!(font.line_height(), ch as f32 * 2.0);
    }

    #[test]
    fn dirty_flag_lifecycle() {
        let fonts = Font::load_all_sizes();
        let (mut font, _, _) = fonts.into_iter().next().unwrap();
        assert!(font.is_dirty(), "newly loaded font should be dirty");
        font.mark_clean();
        assert!(!font.is_dirty());
    }

    #[test]
    fn wrap_text_single_line_within_limit() {
        let fonts = Font::load_all_sizes();
        let (ref font, _, _) = fonts[0];
        let lines = font.wrap_text("Hello", 100.0);
        assert_eq!(lines.len(), 1);
        assert_eq!(lines[0], "Hello");
    }

    #[test]
    fn wrap_text_breaks_at_limit() {
        let fonts = Font::load_all_sizes();
        let (ref font, _, _) = fonts[0];
        let lines = font.wrap_text("AB CD", 12.0);
        assert_eq!(lines.len(), 2);
    }

    #[test]
    fn wrap_text_preserves_newlines() {
        let fonts = Font::load_all_sizes();
        let (ref font, _, _) = fonts[0];
        let lines = font.wrap_text("A\nB", 1000.0);
        assert_eq!(lines.len(), 2);
    }

    #[test]
    fn wrap_text_empty_string() {
        let fonts = Font::load_all_sizes();
        let (ref font, _, _) = fonts[0];
        let lines = font.wrap_text("", 100.0);
        assert_eq!(lines, vec![""]);
    }
}

// ── image_effect tests ──────────────────────────────────────────────────────

mod image_effect_tests {
    use super::*;

    #[test]
    fn new_sets_name_and_defaults() {
        let pass = ShaderPassDescriptor::new("blur");
        assert_eq!(pass.effect_name, "blur");
        assert!(pass.enabled);
        assert!(pass.params.is_empty());
    }

    #[test]
    fn new_accepts_string_type() {
        let pass = ShaderPassDescriptor::new(String::from("vignette"));
        assert_eq!(pass.effect_name, "vignette");
    }

    #[test]
    fn params_can_be_mutated() {
        let mut pass = ShaderPassDescriptor::new("bloom");
        pass.params.insert("strength".to_string(), 0.5);
        pass.params.insert("radius".to_string(), 3.0);
        assert_eq!(pass.params.len(), 2);
        assert_eq!(pass.params["strength"], 0.5);
    }

    #[test]
    fn clone_produces_independent_copy() {
        let mut original = ShaderPassDescriptor::new("crt");
        original.params.insert("warp".to_string(), 0.1);
        let mut cloned = original.clone();
        cloned.enabled = false;
        assert!(original.enabled);
    }
}

// ── mesh tests ──────────────────────────────────────────────────────────────

mod mesh_tests {
    use super::*;

    #[test]
    fn new_creates_default_vertices() {
        let m = Mesh::new(4, MeshDrawMode::Triangles);
        assert_eq!(m.vertex_count(), 4);
        let v = m.get_vertex(0).unwrap();
        assert_eq!(v.r, 1.0);
        assert_eq!(v.a, 1.0);
    }

    #[test]
    fn from_vertices_preserves_data() {
        let verts = vec![
            MeshVertex {
                x: 10.0,
                y: 20.0,
                ..Default::default()
            },
            MeshVertex {
                x: 30.0,
                y: 40.0,
                ..Default::default()
            },
        ];
        let m = Mesh::from_vertices(verts, MeshDrawMode::Fan);
        assert_eq!(m.vertex_count(), 2);
        assert_eq!(m.get_vertex(0).unwrap().x, 10.0);
    }

    #[test]
    fn from_vertex_rows_parses_all_fields() {
        let rows = [[1.0, 2.0, 0.5, 0.5, 0.1, 0.2, 0.3, 0.9]];
        let m = Mesh::from_vertex_rows(&rows, MeshDrawMode::Triangles);
        let v = m.get_vertex(0).unwrap();
        assert_eq!(v.x, 1.0);
        assert_eq!(v.y, 2.0);
        assert_eq!(v.u, 0.5);
        assert_eq!(v.b, 0.3);
        assert_eq!(v.a, 0.9);
    }

    #[test]
    fn set_vertex_updates_position() {
        let mut m = Mesh::new(2, MeshDrawMode::Triangles);
        m.set_vertex(
            1,
            MeshVertex {
                x: 99.0,
                y: 88.0,
                ..Default::default()
            },
        );
        assert_eq!(m.get_vertex(1).unwrap().x, 99.0);
    }

    #[test]
    fn set_vertex_out_of_bounds_is_noop() {
        let mut m = Mesh::new(1, MeshDrawMode::Triangles);
        m.set_vertex(5, MeshVertex::default());
        assert_eq!(m.vertex_count(), 1);
    }

    #[test]
    fn get_vertex_out_of_bounds_returns_none() {
        let m = Mesh::new(1, MeshDrawMode::Triangles);
        assert!(m.get_vertex(10).is_none());
    }

    #[test]
    fn set_vertex_map_sets_indices() {
        let mut m = Mesh::new(4, MeshDrawMode::Triangles);
        m.set_vertex_map(vec![0, 1, 2, 2, 3, 0]);
        assert!(m.indices.is_some());
        assert_eq!(m.indices.as_ref().unwrap().len(), 6);
    }

    #[test]
    fn triangulate_triangles_mode_passthrough() {
        let m = Mesh::new(6, MeshDrawMode::Triangles);
        let tri = m.triangulate();
        assert_eq!(tri, vec![0, 1, 2, 3, 4, 5]);
    }

    #[test]
    fn triangulate_fan_mode() {
        let m = Mesh::new(5, MeshDrawMode::Fan);
        let tri = m.triangulate();
        assert_eq!(tri, vec![0, 1, 2, 0, 2, 3, 0, 3, 4]);
    }

    #[test]
    fn triangulate_strip_mode() {
        let m = Mesh::new(4, MeshDrawMode::Strip);
        let tri = m.triangulate();
        assert_eq!(tri, vec![0, 1, 2, 2, 1, 3]);
    }

    #[test]
    fn triangulate_fan_too_few_vertices() {
        let m = Mesh::new(2, MeshDrawMode::Fan);
        assert!(m.triangulate().is_empty());
    }

    #[test]
    fn triangulate_with_index_buffer() {
        let mut m = Mesh::new(4, MeshDrawMode::Triangles);
        m.set_vertex_map(vec![3, 2, 1]);
        let tri = m.triangulate();
        assert_eq!(tri, vec![3, 2, 1]);
    }

    #[test]
    fn default_vertex_values() {
        let v = MeshVertex::default();
        assert_eq!(v.x, 0.0);
        assert_eq!(v.y, 0.0);
        assert_eq!(v.r, 1.0);
        assert_eq!(v.g, 1.0);
        assert_eq!(v.b, 1.0);
        assert_eq!(v.a, 1.0);
    }
}

// ── shape tests ─────────────────────────────────────────────────────────────

mod shape_tests {
    use super::*;

    #[test]
    fn new_starts_empty_with_defaults() {
        let s = CompoundShape::new();
        assert_eq!(s.command_count(), 0);
        assert_eq!(s.current_color, [1.0, 1.0, 1.0, 1.0]);
        assert_eq!(s.current_line_width, 1.0);
    }

    #[test]
    fn push_command_increments_count() {
        let mut s = CompoundShape::new();
        s.push_command(ShapeCommand::SetColor(1.0, 0.0, 0.0, 1.0));
        s.push_command(ShapeCommand::SetLineWidth(2.0));
        assert_eq!(s.command_count(), 2);
    }

    #[test]
    fn clear_resets_everything() {
        let mut s = CompoundShape::new();
        s.push_command(ShapeCommand::Circle {
            mode: DrawMode::Fill,
            x: 10.0,
            y: 10.0,
            r: 5.0,
        });
        s.current_color = [1.0, 0.0, 0.0, 1.0];
        s.current_line_width = 3.0;
        s.clear();
        assert_eq!(s.command_count(), 0);
        assert_eq!(s.current_color, [1.0, 1.0, 1.0, 1.0]);
        assert_eq!(s.current_line_width, 1.0);
    }

    #[test]
    fn default_is_same_as_new() {
        let s = CompoundShape::default();
        assert_eq!(s.command_count(), 0);
    }

    #[test]
    fn clone_produces_independent_copy() {
        let mut original = CompoundShape::new();
        original.push_command(ShapeCommand::Line {
            x1: 0.0,
            y1: 0.0,
            x2: 10.0,
            y2: 10.0,
        });
        let mut cloned = original.clone();
        cloned.push_command(ShapeCommand::SetColor(1.0, 0.0, 0.0, 1.0));
        assert_eq!(original.command_count(), 1);
        assert_eq!(cloned.command_count(), 2);
    }
}

// ── renderer tests (from src/render/renderer_tests.rs) ──────────────────────

mod renderer_tests {
    use super::*;

    #[test]
    fn stencil_mode_default() {
        let sm = StencilMode::default();
        assert_eq!(sm.action, StencilAction::Keep);
        assert_eq!(sm.compare, lurek2d::render::renderer::CompareMode::Always);
        assert_eq!(sm.value, 0);
    }

    #[test]
    fn depth_mode_default_is_always() {
        let dm = DepthMode::default();
        assert_eq!(dm, DepthMode::Always);
    }

    #[test]
    fn blend_mode_default_is_alpha() {
        let bm = BlendMode::default();
        assert_eq!(bm, BlendMode::Alpha);
    }

    #[test]
    fn text_span_new_stores_all_fields() {
        let span = TextSpan::new("hello", 255, 128, 64, 200, 1.5);
        assert_eq!(span.text, "hello");
        assert_eq!(span.r, 255);
        assert_eq!(span.g, 128);
        assert_eq!(span.b, 64);
        assert_eq!(span.a, 200);
        assert_eq!(span.scale, 1.5);
    }

    #[test]
    fn text_span_new_accepts_string() {
        let span = TextSpan::new(String::from("world"), 0, 0, 0, 255, 1.0);
        assert_eq!(span.text, "world");
    }

    #[test]
    fn physics_debug_config_default_values() {
        let cfg = PhysicsDebugConfig::default();
        assert_eq!(cfg.body_color[1], 1.0);
        assert_eq!(cfg.static_color[0], 0.8);
        assert_eq!(cfg.line_width, 1.0);
    }

    #[test]
    fn texture_data_clone() {
        let td = TextureData {
            pixels: vec![255, 0, 0, 255],
            width: 1,
            height: 1,
        };
        let td2 = td.clone();
        assert_eq!(td2.pixels, vec![255, 0, 0, 255]);
        assert_eq!(td2.width, 1);
    }
}

// ── postfx_pipeline tests (from src/render/postfx_pipeline_tests.rs) ────────

mod postfx_pipeline_tests {
    use super::*;

    #[test]
    fn params_to_uniform_empty_map_returns_zeros() {
        let params = HashMap::new();
        let u = params_to_uniform(&params);
        assert_eq!(u, [0.0; 16]);
    }

    #[test]
    fn params_to_uniform_maps_known_keys() {
        let mut params = HashMap::new();
        params.insert("strength".to_string(), 0.5);
        params.insert("intensity".to_string(), 1.2);
        params.insert("radius".to_string(), 3.0);
        params.insert("time".to_string(), 42.0);
        let u = params_to_uniform(&params);
        assert_eq!(u[0], 0.5);
        assert_eq!(u[1], 1.2);
        assert_eq!(u[2], 3.0);
        assert_eq!(u[11], 42.0);
    }

    #[test]
    fn params_to_uniform_unknown_keys_ignored() {
        let mut params = HashMap::new();
        params.insert("nonexistent".to_string(), 99.0);
        let u = params_to_uniform(&params);
        assert_eq!(u[0], 0.0);
    }

    #[test]
    fn params_to_uniform_all_slots_populated() {
        let mut params = HashMap::new();
        params.insert("strength".to_string(), 1.0);
        params.insert("intensity".to_string(), 2.0);
        params.insert("radius".to_string(), 3.0);
        params.insert("thickness".to_string(), 4.0);
        params.insert("focus_x".to_string(), 5.0);
        params.insert("focus_y".to_string(), 6.0);
        params.insert("density".to_string(), 7.0);
        params.insert("exposure".to_string(), 8.0);
        params.insert("color_r".to_string(), 9.0);
        params.insert("color_g".to_string(), 10.0);
        params.insert("color_b".to_string(), 11.0);
        params.insert("time".to_string(), 12.0);
        params.insert("frequency".to_string(), 13.0);
        params.insert("amplitude".to_string(), 14.0);
        params.insert("samples".to_string(), 15.0);
        params.insert("palette_size".to_string(), 16.0);
        let u = params_to_uniform(&params);
        for i in 0..16 {
            assert_eq!(u[i], (i + 1) as f32, "slot {i} mismatch");
        }
    }
}

//  dropped inline tests (per TST-02)
//
// NOTE: dropped 17 internal-only tests from src/render/shader.rs  they
// exercise private WGSL-parsing helpers (validate_wgsl, prepare_fragment_source_for_wrapper,
// split_top_level_commas, find_matching_paren, consume_attribute, strip_leading_attributes,
// build_custom_color_shader_source, build_custom_texture_shader_source). User-visible
// shader behaviour is covered by tests/lua/unit/test_effect_postfx.lua and the content/examples/
// shader examples exercised by tests/lua/content/.
//
// NOTE: dropped 9 internal-only tests from src/render/gpu_renderer.rs  they
// exercise private wgpu-pipeline helpers (normalize_scissor, color_write_mask_bits,
// parse_filter_mode, uniform_bytes, depth_stencil_state). User-visible rendering
// behaviour is covered by tests/rust/golden/ frame-capture tests and the
// lurek.render.* Lua tests in tests/lua/unit/test_render_pipeline.lua.
