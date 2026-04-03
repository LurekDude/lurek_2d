//! Integration tests for the Luna2D graphics module.

use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use luna2d::engine::resource_keys::TextureKey;
use luna2d::graphics::renderer::{
    CompareMode, DrawCommand, DrawMode, StencilAction, TextAlign, TextureData,
};
use luna2d::graphics::sprite_batch::BatchEntry;
use luna2d::graphics::Animation;
use luna2d::graphics::Font;
use luna2d::graphics::NineSlice;
use luna2d::graphics::SpriteBatch;
use luna2d::graphics::{BlendMode, Color};
use luna2d::lua_api::{create_lua_vm, SharedState};
use slotmap::{Key, SlotMap};

#[test]
fn color_white() {
    let c = Color::WHITE;
    assert!((c.r - 1.0).abs() < f32::EPSILON);
    assert!((c.g - 1.0).abs() < f32::EPSILON);
    assert!((c.b - 1.0).abs() < f32::EPSILON);
    assert!((c.a - 1.0).abs() < f32::EPSILON);
}

#[test]
fn color_from_u8() {
    let c = Color::from_u8(255, 0, 128, 255);
    assert!((c.r - 1.0).abs() < 0.01);
    assert!((c.g).abs() < f32::EPSILON);
    assert!((c.b - 0.502).abs() < 0.01);
}

#[test]
fn color_to_u8() {
    let c = Color::new(1.0, 0.5, 0.0, 1.0);
    let (r, g, b, a) = c.to_u8();
    assert_eq!(r, 255);
    assert_eq!(b, 0);
    assert_eq!(a, 255);
    assert!(g > 100 && g < 140);
}

// ===========================================================================
// Helpers
// ===========================================================================

fn make_graphics_vm() -> (Rc<RefCell<SharedState>>, mlua::Lua) {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    let lua = create_lua_vm(state.clone()).expect("Failed to create Lua VM");
    (state, lua)
}

/// Execute `code` as the body of `luna.draw()` so it runs exactly as the engine would.
fn run_draw(lua: &mlua::Lua, code: &str) {
    let script = format!("luna.draw = function()\n{}\nend\nluna.draw()", code);
    lua.load(&script)
        .exec()
        .expect("Lua error in draw callback");
}

fn assert_lua_error_contains(result: mlua::Result<()>, expected: &str) {
    let err = result.expect_err("expected Lua script to fail");
    let message = err.to_string();
    assert!(
        message.contains(expected),
        "expected Lua error to contain '{expected}', got '{message}'"
    );
}

const VALID_WGSL_FRAGMENT_SHADER: &str = r#"
@fragment
fn fs_main(
    @location(0) color: vec4<f32>,
    @location(1) _uv: vec2<f32>,
) -> @location(0) vec4<f32> {
    return color;
}
"#;

#[test]
fn test_phase01_released_texture_handle_reuse_reports_invalid_texture() {
    let (_state, lua) = make_graphics_vm();
    let result = lua
        .load(
            r#"
            local released = luna.graphics.newImage("assets/icon.png")
            assert(type(released) == "userdata")
            assert(luna.graphics.release(released) == true)

            local replacement = luna.graphics.newImage("assets/splash.png")
            assert(type(replacement) == "userdata")
            assert(replacement:getWidth() > 0)

            luna.graphics.draw(released, 10, 20)
            "#,
        )
        .exec();

    assert_lua_error_contains(
        result,
        "luna.graphics.draw: invalid or already-released texture handle",
    );
}

#[test]
fn test_phase01_released_numeric_texture_handle_reports_invalid_texture() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        _phase01_texture = luna.graphics.newImage("assets/icon.png")
        assert(type(_phase01_texture) == "userdata")
        "#,
    )
    .exec()
    .unwrap();

    let released_texture_id = {
        let st = state.borrow();
        assert_eq!(st.textures.len(), 1);
        st.textures
            .keys()
            .next()
            .expect("expected one texture handle")
            .data()
            .as_ffi() as i64
    };

    let script = format!(
        r#"
        assert(luna.graphics.release({released_texture_id}) == true)

        local replacement = luna.graphics.newImage("assets/splash.png")
        assert(type(replacement) == "userdata")
        assert(replacement:getWidth() > 0)

        luna.graphics.draw({released_texture_id}, 10, 20)
        "#,
    );
    let result = lua.load(&script).exec();

    assert_lua_error_contains(
        result,
        "luna.graphics.draw: invalid or already-released texture handle",
    );
}

#[test]
fn test_phase01_released_font_handle_reuse_reports_invalid_font() {
    let (_state, lua) = make_graphics_vm();
    let result = lua
        .load(
            r#"
            local released = luna.graphics.newFont("assets/fonts/Roboto-Regular.ttf", 18)
            assert(type(released) == "userdata")
            assert(luna.graphics.releaseFont(released) == true)

            local replacement = luna.graphics.newFont("assets/fonts/OpenSans.ttf", 20)
            assert(type(replacement) == "userdata")
            assert(replacement:getHeight() > 0)

            luna.graphics.setFont(released)
            "#,
        )
        .exec();

    assert_lua_error_contains(
        result,
        "luna.graphics.setFont: font handle is not valid or was released",
    );
}

#[test]
fn test_phase01_released_sprite_batch_handle_reuse_reports_invalid_batch() {
    let (_state, lua) = make_graphics_vm();
    let result = lua
        .load(
            r#"
            local image = luna.graphics.newImage("assets/icon.png")
            local released = luna.graphics.newSpriteBatch(image, 4)
            assert(type(released) == "userdata")
            assert(luna.graphics.releaseBatch(released) == true)

            local replacement = luna.graphics.newSpriteBatch(image, 4)
            assert(type(replacement) == "userdata")
            assert(replacement:getCount() == 0)

            luna.graphics.spriteBatchAdd(released, 1, 2)
            "#,
        )
        .exec();

    assert_lua_error_contains(
        result,
        "luna.graphics.spriteBatchAdd: batch handle is not valid or was released",
    );
}

// ===========================================================================
// Feature 1: Transform stack
// ===========================================================================

#[test]
fn test_transform_push_queues_push_transform() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.push()");
    assert!(matches!(
        state.borrow().draw_commands.last(),
        Some(DrawCommand::PushTransform)
    ));
}

#[test]
fn test_transform_pop_queues_pop_transform() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.pop()");
    assert!(matches!(
        state.borrow().draw_commands.last(),
        Some(DrawCommand::PopTransform)
    ));
}

#[test]
fn test_transform_translate_queues_correct_values() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.translate(30, 45)");
    let st = state.borrow();
    if let Some(DrawCommand::Translate { x, y }) = st.draw_commands.last() {
        assert!((x - 30.0).abs() < 1e-5);
        assert!((y - 45.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::Translate");
    }
}

#[test]
fn test_transform_rotate_queues_angle() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.rotate(1.5707963)");
    let st = state.borrow();
    if let Some(DrawCommand::Rotate { angle }) = st.draw_commands.last() {
        assert!((angle - std::f32::consts::FRAC_PI_2).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::Rotate");
    }
}

#[test]
fn test_transform_scale_uniform_defaults_sy_to_sx() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.scale(2)");
    let st = state.borrow();
    if let Some(DrawCommand::Scale { sx, sy }) = st.draw_commands.last() {
        assert!((sx - 2.0).abs() < 1e-5);
        assert!((sy - 2.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::Scale");
    }
}

#[test]
fn test_transform_scale_nonuniform_queues_distinct_sx_sy() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.scale(3, 0.5)");
    let st = state.borrow();
    if let Some(DrawCommand::Scale { sx, sy }) = st.draw_commands.last() {
        assert!((sx - 3.0).abs() < 1e-5);
        assert!((sy - 0.5).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::Scale");
    }
}

// ===========================================================================
// Feature 2: Arc
// ===========================================================================

#[test]
fn test_arc_fill_mode_queues_arc_command_with_default_segments() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        r#"luna.graphics.arc("fill", 100, 200, 50, 0, 3.14159265)"#,
    );
    let st = state.borrow();
    if let Some(DrawCommand::Arc {
        mode,
        x,
        y,
        radius,
        angle1,
        angle2,
        segments,
    }) = st.draw_commands.last()
    {
        assert!(matches!(mode, DrawMode::Fill));
        assert!((x - 100.0).abs() < 1e-5);
        assert!((y - 200.0).abs() < 1e-5);
        assert!((radius - 50.0).abs() < 1e-5);
        assert!((angle1 - 0.0).abs() < 1e-5);
        assert!((angle2 - std::f32::consts::PI).abs() < 1e-4);
        assert_eq!(*segments, 32);
    } else {
        panic!("Expected DrawCommand::Arc");
    }
}

#[test]
fn test_arc_line_mode_queues_line_draw_mode() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, r#"luna.graphics.arc("line", 0, 0, 10, 0, 1)"#);
    let st = state.borrow();
    if let Some(DrawCommand::Arc { mode, .. }) = st.draw_commands.last() {
        assert!(matches!(mode, DrawMode::Line));
    } else {
        panic!("Expected DrawCommand::Arc");
    }
}

#[test]
fn test_arc_explicit_segments_overrides_default() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, r#"luna.graphics.arc("fill", 0, 0, 20, 0, 6.28, 16)"#);
    let st = state.borrow();
    if let Some(DrawCommand::Arc { segments, .. }) = st.draw_commands.last() {
        assert_eq!(*segments, 16);
    } else {
        panic!("Expected DrawCommand::Arc");
    }
}

// ===========================================================================
// Feature 3: Quad system
// ===========================================================================

#[test]
fn test_drawex_defaults_rotation_scale_origin_to_identity() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.drawEx(0, 100, 200)");
    let st = state.borrow();
    if let Some(DrawCommand::DrawImageEx {
        texture_key,
        x,
        y,
        rotation,
        sx,
        sy,
        ox,
        oy,
    }) = st.draw_commands.last()
    {
        let _ = texture_key;
        assert!((x - 100.0).abs() < 1e-5);
        assert!((y - 200.0).abs() < 1e-5);
        assert!((rotation - 0.0).abs() < 1e-5);
        assert!((sx - 1.0).abs() < 1e-5);
        assert!((sy - 1.0).abs() < 1e-5);
        assert!((ox - 0.0).abs() < 1e-5);
        assert!((oy - 0.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::DrawImageEx");
    }
}

#[test]
fn test_drawex_with_all_params_queues_correct_values() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        "luna.graphics.drawEx(1, 50, 60, 0.785, 2.0, 1.5, 10, 20)",
    );
    let st = state.borrow();
    if let Some(DrawCommand::DrawImageEx {
        texture_key,
        x,
        y,
        rotation,
        sx,
        sy,
        ox,
        oy,
    }) = st.draw_commands.last()
    {
        let _ = texture_key;
        assert!((x - 50.0).abs() < 1e-5);
        assert!((y - 60.0).abs() < 1e-5);
        assert!((rotation - 0.785).abs() < 1e-3);
        assert!((sx - 2.0).abs() < 1e-5);
        assert!((sy - 1.5).abs() < 1e-5);
        assert!((ox - 10.0).abs() < 1e-5);
        assert!((oy - 20.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::DrawImageEx");
    }
}

#[test]
fn test_newquad_and_drawquad_queue_draw_quad_command() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        r#"
        local q = luna.graphics.newQuad(10, 20, 64, 64, 256, 256)
        luna.graphics.drawQuad(0, q, 100, 200)
        "#,
    );
    let st = state.borrow();
    if let Some(DrawCommand::DrawQuad {
        texture_key,
        quad_x,
        quad_y,
        quad_w,
        quad_h,
        tex_w,
        tex_h,
        x,
        y,
        rotation,
        sx,
        sy,
        ox,
        oy,
    }) = st.draw_commands.last()
    {
        let _ = texture_key;
        assert!((quad_x - 10.0).abs() < 1e-5);
        assert!((quad_y - 20.0).abs() < 1e-5);
        assert!((quad_w - 64.0).abs() < 1e-5);
        assert!((quad_h - 64.0).abs() < 1e-5);
        assert!((tex_w - 256.0).abs() < 1e-5);
        assert!((tex_h - 256.0).abs() < 1e-5);
        assert!((x - 100.0).abs() < 1e-5);
        assert!((y - 200.0).abs() < 1e-5);
        assert!((rotation - 0.0).abs() < 1e-5);
        assert!((sx - 1.0).abs() < 1e-5);
        assert!((sy - 1.0).abs() < 1e-5);
        assert!((ox - 0.0).abs() < 1e-5);
        assert!((oy - 0.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::DrawQuad");
    }
}

// ===========================================================================
// Feature 4: getColor
// ===========================================================================

#[test]
fn test_get_color_returns_set_color_values() {
    let (_state, lua) = make_graphics_vm();
    lua.load(
        r#"
        luna.graphics.setColor(0.5, 0.25, 0.75, 1.0)
        _r, _g, _b, _a = luna.graphics.getColor()
        "#,
    )
    .exec()
    .unwrap();
    let r: f32 = lua.globals().get("_r").unwrap();
    let g: f32 = lua.globals().get("_g").unwrap();
    let b: f32 = lua.globals().get("_b").unwrap();
    let a: f32 = lua.globals().get("_a").unwrap();
    assert!((r - 0.5).abs() < 1e-5);
    assert!((g - 0.25).abs() < 1e-5);
    assert!((b - 0.75).abs() < 1e-5);
    assert!((a - 1.0).abs() < 1e-5);
}

#[test]
fn test_get_color_default_is_white() {
    let (_state, lua) = make_graphics_vm();
    lua.load("_r, _g, _b, _a = luna.graphics.getColor()")
        .exec()
        .unwrap();
    let r: f32 = lua.globals().get("_r").unwrap();
    let g: f32 = lua.globals().get("_g").unwrap();
    let b: f32 = lua.globals().get("_b").unwrap();
    let a: f32 = lua.globals().get("_a").unwrap();
    assert!((r - 1.0).abs() < 1e-5);
    assert!((g - 1.0).abs() < 1e-5);
    assert!((b - 1.0).abs() < 1e-5);
    assert!((a - 1.0).abs() < 1e-5);
}

// ===========================================================================
// Feature 5: Polyline
// ===========================================================================

#[test]
fn test_polyline_two_points_queues_polyline_command() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.polyline(10, 20, 30, 40)");
    let st = state.borrow();
    if let Some(DrawCommand::Polyline { points }) = st.draw_commands.last() {
        assert_eq!(points.len(), 4);
        assert!((points[0] - 10.0).abs() < 1e-5);
        assert!((points[1] - 20.0).abs() < 1e-5);
        assert!((points[2] - 30.0).abs() < 1e-5);
        assert!((points[3] - 40.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::Polyline");
    }
}

#[test]
fn test_polyline_three_points_queues_six_coordinates() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.polyline(0, 0, 50, 100, 100, 0)");
    let st = state.borrow();
    if let Some(DrawCommand::Polyline { points }) = st.draw_commands.last() {
        assert_eq!(points.len(), 6);
        assert!((points[4] - 100.0).abs() < 1e-5);
        assert!((points[5] - 0.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::Polyline");
    }
}

// ===========================================================================
// Feature 6: TTF Font Loading
// ===========================================================================

/// Helper: load the bundled test font (Roboto-Regular).
fn load_test_font() -> Font {
    let font_data = include_bytes!("../../assets/fonts/Roboto-Regular.ttf");
    Font::from_bytes(font_data, 24.0).expect("Failed to load test font")
}

#[test]
fn test_font_from_bytes_creates_font() {
    let font = load_test_font();
    // Pre-rasterizes printable ASCII — the glyph for 'A' should exist
    assert!(font.size() > 0.0);
}

#[test]
fn test_font_text_width_returns_positive() {
    let mut font = load_test_font();
    let w = font.text_width("Hello");
    assert!(
        w > 0.0,
        "text_width(\"Hello\") should be positive, got {}",
        w
    );
}

#[test]
fn test_font_line_height_positive() {
    let font = load_test_font();
    let lh = font.line_height();
    assert!(lh > 0.0, "line_height should be positive, got {}", lh);
}

#[test]
fn test_font_atlas_dimensions_valid() {
    let font = load_test_font();
    let (data, w, h) = font.atlas_data();
    assert!(w > 0, "Atlas width should be > 0");
    assert!(h > 0, "Atlas height should be > 0");
    assert_eq!(
        data.len(),
        (w * h * 4) as usize,
        "Atlas data size should match w*h*4"
    );
}

#[test]
fn test_font_glyph_info_for_ascii() {
    let mut font = load_test_font();
    let info = font.glyph('A').expect("Glyph 'A' should exist");
    assert!(info.width > 0, "Glyph 'A' width should be > 0");
    assert!(info.height > 0, "Glyph 'A' height should be > 0");
    assert!(
        info.advance_width > 0.0,
        "Glyph 'A' advance_width should be > 0"
    );
    // UV coordinates should be in 0..1 range
    assert!(info.uv_x >= 0.0 && info.uv_x <= 1.0);
    assert!(info.uv_y >= 0.0 && info.uv_y <= 1.0);
    assert!(info.uv_w > 0.0 && info.uv_w <= 1.0);
    assert!(info.uv_h > 0.0 && info.uv_h <= 1.0);
}

// ===========================================================================
// Font Lua API Bindings
// ===========================================================================

#[test]
fn test_new_font_lua_binding() {
    let (_, lua) = make_graphics_vm();
    lua.load(
        r#"
        local font = luna.graphics.newFont("assets/fonts/Roboto-Regular.ttf", 16)
        assert(font ~= nil, "newFont should return a Font object")
        assert(type(font) == "userdata", "Font should be userdata")
        "#,
    )
    .exec()
    .expect("newFont should succeed with valid TTF file");
}

#[test]
fn test_set_get_font_lua_binding() {
    let (_, lua) = make_graphics_vm();
    lua.load(
        r#"
        local font = luna.graphics.newFont("assets/fonts/Roboto-Regular.ttf", 16)
        luna.graphics.setFont(font)
        local got = luna.graphics.getFont()
        assert(got ~= nil, "getFont should return the set font")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_print_with_font_pushes_print_font_command() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        local font = luna.graphics.newFont("assets/fonts/Roboto-Regular.ttf", 16)
        luna.graphics.setFont(font)
        luna.graphics.print("Hello TTF", 10, 20)
        "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    let has_print_font = st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::PrintFont { .. }));
    assert!(
        has_print_font,
        "print() with active font should push PrintFont command"
    );
}

#[test]
fn test_get_font_width_returns_positive() {
    let (_, lua) = make_graphics_vm();
    let width: f32 = lua
        .load(
            r#"
        local font = luna.graphics.newFont("assets/fonts/Roboto-Regular.ttf", 16)
        return luna.graphics.getFontWidth(font, "Hello")
        "#,
        )
        .eval()
        .unwrap();
    assert!(
        width > 0.0,
        "Font width should be positive for non-empty text"
    );
}

#[test]
fn test_get_font_height_returns_positive() {
    let (_, lua) = make_graphics_vm();
    let height: f32 = lua
        .load(
            r#"
        local font = luna.graphics.newFont("assets/fonts/Roboto-Regular.ttf", 16)
        return luna.graphics.getFontHeight(font)
        "#,
        )
        .eval()
        .unwrap();
    assert!(height > 0.0, "Font height should be positive");
}

// ===========================================================================
// SpriteBatch unit tests
// ===========================================================================

#[test]
fn test_sprite_batch_new() {
    let mut tex_map: SlotMap<TextureKey, ()> = SlotMap::with_key();
    let tex_key = tex_map.insert(());
    let batch = SpriteBatch::new(tex_key, 100);
    assert_eq!(batch.texture_key(), tex_key);
    assert!(batch.is_empty());
    assert_eq!(batch.len(), 0);
}

#[test]
fn test_sprite_batch_add_and_clear() {
    let mut tex_map: SlotMap<TextureKey, ()> = SlotMap::with_key();
    let tex_key = tex_map.insert(());
    let mut batch = SpriteBatch::new(tex_key, 10);
    let entry = BatchEntry {
        x: 10.0,
        y: 20.0,
        quad_x: 0.0,
        quad_y: 0.0,
        quad_w: 0.0,
        quad_h: 0.0,
        rotation: 0.0,
        sx: 1.0,
        sy: 1.0,
        ox: 0.0,
        oy: 0.0,
    };
    let idx = batch.add(entry);
    assert_eq!(idx, Some(0));
    assert_eq!(batch.len(), 1);
    batch.clear();
    assert!(batch.is_empty());
}

#[test]
fn test_sprite_batch_max_entries() {
    let mut tex_map: SlotMap<TextureKey, ()> = SlotMap::with_key();
    let tex_key = tex_map.insert(());
    let mut batch = SpriteBatch::new(tex_key, 2);
    let entry = || BatchEntry {
        x: 0.0,
        y: 0.0,
        quad_x: 0.0,
        quad_y: 0.0,
        quad_w: 0.0,
        quad_h: 0.0,
        rotation: 0.0,
        sx: 1.0,
        sy: 1.0,
        ox: 0.0,
        oy: 0.0,
    };
    assert!(batch.add(entry()).is_some());
    assert!(batch.add(entry()).is_some());
    assert!(batch.add(entry()).is_none()); // full
}

#[test]
fn test_draw_batch_lua_command() {
    let (state, lua) = make_graphics_vm();
    // Create a fake texture so newSpriteBatch validates
    let tex_key = state.borrow_mut().textures.insert(TextureData {
        pixels: vec![255u8; 16],
        width: 2,
        height: 2,
    });
    lua.globals()
        .set("_tex_id", tex_key.data().as_ffi())
        .unwrap();
    lua.load(
        r#"
        local batch = luna.graphics.newSpriteBatch(_tex_id, 100)
        luna.graphics.spriteBatchAdd(batch, 10, 20)
        luna.graphics.drawBatch(batch)
        "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    let has_draw_batch = st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::DrawBatch { .. }));
    assert!(has_draw_batch, "drawBatch should push DrawBatch command");
}

// ===========================================================================
// Blend Modes
// ===========================================================================

#[test]
fn test_blend_mode_default_alpha() {
    assert_eq!(BlendMode::default(), BlendMode::Alpha);
}

#[test]
fn test_set_blend_mode_lua() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        luna.graphics.setBlendMode("add")
        assert(luna.graphics.getBlendMode() == "add")
        "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    assert!(st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::SetBlendMode(BlendMode::Add))));
}

#[test]
fn test_set_blend_mode_invalid() {
    let (_state, lua) = make_graphics_vm();
    let result = lua.load(r#"luna.graphics.setBlendMode("invalid")"#).exec();
    assert!(result.is_err(), "Invalid blend mode should error");
}

#[test]
fn test_set_blend_mode_pushes_draw_command() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        luna.graphics.setBlendMode("multiply")
        luna.graphics.rectangle("fill", 10, 20, 100, 100)
        luna.graphics.setBlendMode("alpha")
        "#,
    )
    .exec()
    .unwrap();
    let cmds = &state.borrow().draw_commands;
    let blend_cmds: Vec<_> = cmds
        .iter()
        .filter(|c| matches!(c, DrawCommand::SetBlendMode(_)))
        .collect();
    assert_eq!(blend_cmds.len(), 2, "Should have 2 SetBlendMode commands");
}

#[test]
fn test_get_blend_mode_default_is_alpha() {
    let (_state, lua) = make_graphics_vm();
    let mode: String = lua
        .load("return luna.graphics.getBlendMode()")
        .eval()
        .unwrap();
    assert_eq!(mode, "alpha");
}

#[test]
fn test_set_blend_mode_additive_alias() {
    let (state, lua) = make_graphics_vm();
    lua.load(r#"luna.graphics.setBlendMode("additive")"#)
        .exec()
        .unwrap();
    let st = state.borrow();
    assert!(st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::SetBlendMode(BlendMode::Add))));
}

#[test]
fn test_blend_mode_all_variants() {
    let (_state, lua) = make_graphics_vm();
    for mode in &["alpha", "add", "multiply", "replace", "screen"] {
        lua.load(&format!(
            r#"
            luna.graphics.setBlendMode("{}")
            assert(luna.graphics.getBlendMode() == "{}")
            "#,
            mode, mode
        ))
        .exec()
        .unwrap();
    }
}

// ===========================================================================
// Animation integration tests
// ===========================================================================

#[test]
fn test_animation_from_grid() {
    let mut anim = Animation::new();
    anim.add_clip_from_grid("walk", 128, 256, 32, 32, 0, 8, 10.0, true);
    anim.play("walk");
    assert_eq!(anim.get_frame_count(), 8);
    assert_eq!(anim.current_frame(), 0);
    assert!(anim.is_playing());
    assert!(anim.is_looping());
}

#[test]
fn test_animation_update_advances() {
    let mut anim = Animation::new();
    anim.add_clip_from_grid("walk", 128, 32, 32, 32, 0, 4, 10.0, true);
    anim.play("walk");
    anim.update(0.15);
    assert_eq!(anim.current_frame(), 1);
}

#[test]
fn test_animation_loops_correctly() {
    let mut anim = Animation::new();
    anim.add_clip_from_grid("walk", 64, 32, 32, 32, 0, 2, 10.0, true);
    anim.play("walk");
    anim.update(0.25); // past both frames, wraps
    assert!(anim.is_playing());
    assert!(anim.current_frame() < 2);
}

#[test]
fn test_animation_stops_when_not_looping() {
    let mut anim = Animation::new();
    anim.add_clip_from_grid("walk", 64, 32, 32, 32, 0, 2, 10.0, false);
    anim.play("walk");
    anim.update(0.5);
    assert!(!anim.is_playing());
    assert_eq!(anim.current_frame(), 1);
}

#[test]
fn test_animation_quad_correct() {
    let mut anim = Animation::new();
    anim.add_clip_from_grid("walk", 64, 32, 16, 16, 0, 8, 10.0, true);
    anim.play("walk");
    let q = anim.current_quad().expect("should have a quad");
    assert!((q.x).abs() < f32::EPSILON);
    assert!((q.y).abs() < f32::EPSILON);
    assert!((q.width - 16.0).abs() < f32::EPSILON);
}

#[test]
#[ignore] // animations feature not yet implemented on SharedState
fn test_animation_lua_create_and_query() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        local id = luna.graphics.newAnimation(32, 32, 4, 8, 0.1)
        assert(type(id) == "number")
        assert(luna.graphics.isAnimationPlaying(id) == true)
        assert(luna.graphics.getAnimationFrame(id) == 0)
    "#,
    )
    .exec()
    .unwrap();
    // assert_eq!(state.borrow().animations.len(), 1);
    let _ = state;
}

#[test]
#[ignore] // animations feature not yet implemented on SharedState
fn test_animation_lua_update_and_draw() {
    let (state, lua) = make_graphics_vm();
    // Create a small fake texture entry so drawAnimation has a valid texture
    {
        let mut st = state.borrow_mut();
        st.textures.insert(luna2d::graphics::renderer::TextureData {
            pixels: vec![255; 64 * 64 * 4],
            width: 64,
            height: 64,
        });
    }
    lua.load(
        r#"
        local anim = luna.graphics.newAnimation(32, 32, 2, 4, 0.1)
        luna.graphics.updateAnimation(anim, 0.15)
        assert(luna.graphics.getAnimationFrame(anim) == 1)
        luna.graphics.drawAnimation(anim, 0, 100, 200)
    "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    assert!(st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::DrawQuad { .. })));
}

#[test]
#[ignore] // animations feature not yet implemented on SharedState
fn test_animation_lua_pause_resume_reset() {
    let (_state, lua) = make_graphics_vm();
    lua.load(
        r#"
        local id = luna.graphics.newAnimation(32, 32, 4, 4, 0.1)
        luna.graphics.pauseAnimation(id)
        assert(luna.graphics.isAnimationPlaying(id) == false)
        luna.graphics.resumeAnimation(id)
        assert(luna.graphics.isAnimationPlaying(id) == true)
        luna.graphics.updateAnimation(id, 0.2)
        assert(luna.graphics.getAnimationFrame(id) > 0)
        luna.graphics.resetAnimation(id)
        assert(luna.graphics.getAnimationFrame(id) == 0)
    "#,
    )
    .exec()
    .unwrap();
}

// ===========================================================================
// Canvas tests
// ===========================================================================

#[test]
fn test_canvas_new_returns_userdata_handles() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        local c0 = luna.graphics.newCanvas(256, 128)
        local c1 = luna.graphics.newCanvas(64, 64)
        assert(type(c0) == "userdata", "canvas should return userdata")
        assert(type(c1) == "userdata", "canvas should return userdata")
        assert(c0:type() == "Canvas")
        assert(c0:typeOf("Canvas"))
        assert(c0:typeOf("Texture"))
        assert(c0 ~= c1, "different canvases should have different handles")
        assert(c0:getWidth() == 256)
        assert(c0:getHeight() == 128)
        local w, h = c1:getDimensions()
        assert(w == 64 and h == 64)
    "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    assert_eq!(st.canvases.len(), 2);
    let vals: Vec<_> = st.canvases.values().collect();
    assert!(vals.iter().any(|c| c.width == 256 && c.height == 128));
    assert!(vals.iter().any(|c| c.width == 64 && c.height == 64));
}

#[test]
fn test_canvas_get_size_accepts_canvas_userdata() {
    let (_state, lua) = make_graphics_vm();
    lua.load(
        r#"
        local canvas = luna.graphics.newCanvas(320, 240)
        local w, h = luna.graphics.getCanvasSize(canvas)
        assert(w == 320, "width should be 320")
        assert(h == 240, "height should be 240")
    "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_canvas_set_canvas_pushes_command_and_get_canvas_round_trips() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        local canvas = luna.graphics.newCanvas(100, 100)
        luna.graphics.setCanvas(canvas)
        local active = luna.graphics.getCanvas()
        assert(active ~= nil)
        assert(active:type() == "Canvas")
        assert(active:getWidth() == 100)
        assert(active:getHeight() == 100)
        luna.graphics.rectangle("fill", 0, 0, 50, 50)
        luna.graphics.setCanvas()
        assert(luna.graphics.getCanvas() == nil)
    "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    let has_set_canvas = st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::SetCanvas(Some(_))));
    let has_reset_canvas = st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::SetCanvas(None)));
    assert!(has_set_canvas, "should have SetCanvas(Some(_))");
    assert!(has_reset_canvas, "should have SetCanvas(None)");
}

#[test]
fn test_canvas_draw_pushes_command() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        local canvas = luna.graphics.newCanvas(200, 200)
        luna.graphics.drawCanvas(canvas, 10, 20)
    "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    let has_draw_canvas = st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::DrawCanvas { .. }));
    assert!(has_draw_canvas, "should have DrawCanvas command");
}

#[test]
fn test_canvas_draw_with_transform() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        local canvas = luna.graphics.newCanvas(100, 100)
        luna.graphics.drawCanvas(canvas, 50, 60, 1.57, 2.0, 3.0, 10, 20)
    "#,
    )
    .exec()
    .unwrap();
    let st = state.borrow();
    let cmd = st
        .draw_commands
        .iter()
        .find(|cmd| matches!(cmd, DrawCommand::DrawCanvas { .. }));
    if let Some(DrawCommand::DrawCanvas {
        canvas_key: _,
        x,
        y,
        rotation,
        sx,
        sy,
        ox,
        oy,
    }) = cmd
    {
        assert!((*x - 50.0).abs() < 1e-5);
        assert!((*y - 60.0).abs() < 1e-5);
        assert!((*rotation - 1.57).abs() < 1e-5);
        assert!((*sx - 2.0).abs() < 1e-5);
        assert!((*sy - 3.0).abs() < 1e-5);
        assert!((*ox - 10.0).abs() < 1e-5);
        assert!((*oy - 20.0).abs() < 1e-5);
    } else {
        panic!("DrawCanvas command not found");
    }
}

#[test]
fn test_canvas_release_active_canvas_clears_target_and_invalidates_handle() {
    let (state, lua) = make_graphics_vm();
    let result = lua
        .load(
            r#"
            local canvas = luna.graphics.newCanvas(100, 100)
            luna.graphics.setCanvas(canvas)
            assert(luna.graphics.getCanvas() ~= nil)
            assert(luna.graphics.releaseCanvas(canvas) == true)
            assert(luna.graphics.getCanvas() == nil)

            luna.graphics.drawCanvas(canvas, 1, 2)
            "#,
        )
        .exec();

    assert_lua_error_contains(
        result,
        "luna.graphics.drawCanvas: invalid or already-released canvas handle",
    );

    let st = state.borrow();
    assert_eq!(st.canvases.len(), 0);
    assert!(st.active_canvas.is_none());
    assert!(
        st.draw_commands
            .iter()
            .any(|cmd| matches!(cmd, DrawCommand::SetCanvas(Some(_)))),
        "should record the canvas activation"
    );
    assert!(
        st.draw_commands
            .iter()
            .filter(|cmd| matches!(cmd, DrawCommand::SetCanvas(None)))
            .count()
            >= 1,
        "should reset the active canvas when it is released"
    );
}

// ===========================================================================
// Phase 02 acceptance tests
// ===========================================================================

#[test]
fn test_phase02_shear_queues_command_with_expected_factors() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.shear(0.5, -0.25)");

    let st = state.borrow();
    if let Some(DrawCommand::Shear { kx, ky }) = st.draw_commands.last() {
        assert!((*kx - 0.5).abs() < 1e-5);
        assert!((*ky + 0.25).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::Shear");
    }
}

#[test]
fn test_phase02_origin_queues_origin_command() {
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, "luna.graphics.origin()");

    assert!(matches!(
        state.borrow().draw_commands.last(),
        Some(DrawCommand::Origin)
    ));
}

#[test]
fn test_phase02_get_stack_depth_tracks_push_pop_origin_and_reset() {
    let (_state, lua) = make_graphics_vm();
    lua.load(
        r#"
        assert(luna.graphics.getStackDepth() == 1)
        luna.graphics.push()
        luna.graphics.push()
        assert(luna.graphics.getStackDepth() == 3)
        luna.graphics.origin()
        assert(luna.graphics.getStackDepth() == 3)
        luna.graphics.pop()
        assert(luna.graphics.getStackDepth() == 2)
        luna.graphics.reset()
        assert(luna.graphics.getStackDepth() == 1)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_phase02_scissor_round_trips_and_intersects() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        luna.graphics.setScissor(10, 20, 100, 50)
        local x, y, w, h = luna.graphics.getScissor()
        assert(x == 10 and y == 20 and w == 100 and h == 50)

        luna.graphics.intersectScissor(50, 30, 100, 100)
        x, y, w, h = luna.graphics.getScissor()
        assert(x == 50 and y == 30 and w == 60 and h == 40)
        "#,
    )
    .exec()
    .unwrap();

    let st = state.borrow();
    if let Some(DrawCommand::SetScissor(Some((x, y, w, h)))) = st.draw_commands.last() {
        assert!((*x - 50.0).abs() < 1e-5);
        assert!((*y - 30.0).abs() < 1e-5);
        assert!((*w - 60.0).abs() < 1e-5);
        assert!((*h - 40.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::SetScissor(Some(_))");
    }
}

#[test]
fn test_phase02_color_mask_round_trips_and_resets() {
    let (_state, lua) = make_graphics_vm();
    lua.load(
        r#"
        luna.graphics.setColorMask(false, true, false, true)
        local r, g, b, a = luna.graphics.getColorMask()
        assert(r == false and g == true and b == false and a == true)

        luna.graphics.setColorMask()
        r, g, b, a = luna.graphics.getColorMask()
        assert(r == true and g == true and b == true and a == true)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_phase02_default_filter_round_trips_min_and_mag() {
    let (_state, lua) = make_graphics_vm();
    lua.load(
        r#"
        luna.graphics.setDefaultFilter("linear", "nearest")
        local min, mag = luna.graphics.getDefaultFilter()
        assert(min == "linear")
        assert(mag == "nearest")
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_phase02_default_filter_round_trips_anisotropy() {
    let (_state, lua) = make_graphics_vm();
    let result = lua
        .load(
            r#"
            luna.graphics.setDefaultFilter("linear", "nearest", 4)
            local min, mag, anisotropy = luna.graphics.getDefaultFilter()
            assert(min == "linear")
            assert(mag == "nearest")
            assert(anisotropy == 4, "anisotropy should round-trip")
            "#,
        )
        .exec();

    assert!(
        result.is_ok(),
        "setDefaultFilter/getDefaultFilter should preserve anisotropy"
    );
}

#[test]
fn test_phase02_stats_report_resource_counts_and_render_counters() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        _phase02_image = luna.graphics.newImage("assets/icon.png")
        _phase02_canvas = luna.graphics.newCanvas(32, 16)
        _phase02_font = luna.graphics.newFont("assets/fonts/Roboto-Regular.ttf", 16)
        "#,
    )
    .exec()
    .unwrap();

    {
        let mut st = state.borrow_mut();
        st.render_stats.draw_calls = 3;
        st.render_stats.canvas_switches = 2;
    }

    lua.load(
        r#"
        local stats = luna.graphics.getStats()
        assert(stats.drawcalls == 3)
        assert(stats.canvasswitches == 2)
        assert(stats.images == 1)
        assert(stats.canvases == 1)
        assert(stats.fonts == 1)
        "#,
    )
    .exec()
    .unwrap();
}

#[test]
fn test_phase02_stats_texture_memory_reflects_loaded_images() {
    let (_state, lua) = make_graphics_vm();
    let result = lua
        .load(
            r#"
            luna.graphics.newImage("assets/icon.png")
            local stats = luna.graphics.getStats()
            assert(stats.texturememory > 0, "texturememory should grow after loading an image")
            "#,
        )
        .exec();

    assert!(
        result.is_ok(),
        "getStats should report non-zero texturememory for loaded images"
    );
}

#[test]
fn test_phase02_stencil_queues_begin_geometry_end_and_test_commands() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        luna.graphics.stencil(function()
            luna.graphics.rectangle("fill", 1, 2, 3, 4)
        end, "increment", 7, true)
        luna.graphics.setStencilTest("greater", 7)
        luna.graphics.setStencilTest()
        "#,
    )
    .exec()
    .unwrap();

    let st = state.borrow();
    assert!(matches!(
        st.draw_commands.get(0),
        Some(DrawCommand::StencilBegin {
            action: StencilAction::Increment,
            value: 7
        })
    ));
    assert!(matches!(
        st.draw_commands.get(1),
        Some(DrawCommand::Rectangle { .. })
    ));
    assert!(matches!(
        st.draw_commands.get(2),
        Some(DrawCommand::StencilEnd)
    ));
    assert!(matches!(
        st.draw_commands.get(3),
        Some(DrawCommand::SetStencilTest(Some((CompareMode::Greater, 7))))
    ));
    assert!(matches!(
        st.draw_commands.get(4),
        Some(DrawCommand::SetStencilTest(None))
    ));
}

#[test]
fn test_phase02_shader_round_trips_active_shader_and_uniforms() {
    let (state, lua) = make_graphics_vm();
    let script = format!(
        r#"
        local shader = luna.graphics.newShader([=[{}]=])
        luna.graphics.setShader(shader)
        assert(luna.graphics.getShader() == shader)
        luna.graphics.sendShader(shader, "tint", {{1.0, 0.5, 0.25, 1.0}})
        assert(luna.graphics.hasShaderUniform(shader, "tint"))
        luna.graphics.setShader()
        assert(luna.graphics.getShader() == nil)
        "#,
        VALID_WGSL_FRAGMENT_SHADER
    );

    lua.load(&script).exec().unwrap();

    let st = state.borrow();
    assert_eq!(st.shaders.len(), 1);
    assert!(st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::SetShader(Some(_)))));
    assert!(st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::SetShader(None))));
}

#[test]
fn test_phase02_shader_compile_rejects_invalid_wgsl() {
    let (_state, lua) = make_graphics_vm();
    let result = lua
        .load(r#"luna.graphics.newShader("not valid wgsl")"#)
        .exec();

    assert!(result.is_err(), "invalid WGSL should fail to compile");
}

#[test]
fn test_phase02_released_mesh_handle_reports_invalid_mesh_and_skips_queueing_draw() {
    let (state, lua) = make_graphics_vm();
    let result = lua
        .load(
            r#"
            local released = luna.graphics.newMesh({
                {0, 0, 0, 0, 1, 0, 0, 1},
                {8, 0, 1, 0, 0, 1, 0, 1},
                {0, 8, 0, 1, 0, 0, 1, 1},
            })
            assert(luna.graphics.releaseMesh(released) == true)

            local replacement = luna.graphics.newMesh({
                {1, 1, 0, 0, 1, 1, 1, 1},
                {9, 1, 1, 0, 1, 1, 1, 1},
                {1, 9, 0, 1, 1, 1, 1, 1},
            })
            assert(luna.graphics.getMeshVertexCount(replacement) == 3)

            luna.graphics.drawMesh(released, 5, 6)
            "#,
        )
        .exec();

    assert_lua_error_contains(
        result,
        "luna.graphics.drawMesh: invalid or already-released mesh handle",
    );

    let st = state.borrow();
    assert!(
        st.draw_commands
            .iter()
            .all(|cmd| !matches!(cmd, DrawCommand::DrawMesh { .. })),
        "released mesh draw should fail before queueing DrawCommand::DrawMesh"
    );
}

#[test]
fn test_phase02_mesh_round_trips_vertex_state_texture_and_draw_command() {
    let (state, lua) = make_graphics_vm();
    let tex_key = state.borrow_mut().textures.insert(TextureData {
        pixels: vec![255u8; 16],
        width: 2,
        height: 2,
    });
    lua.globals()
        .set("_phase02_mesh_texture", tex_key.data().as_ffi() as i64)
        .unwrap();

    lua.load(
        r#"
        local mesh = luna.graphics.newMesh({
            {0, 0, 0, 0, 1, 0, 0, 1},
            {8, 0, 1, 0, 0, 1, 0, 1},
            {0, 8, 0, 1, 0, 0, 1, 1},
        }, "fan")

        assert(luna.graphics.getMeshVertexCount(mesh) == 3)

        luna.graphics.setMeshVertex(mesh, 2, {10, 0, 1, 0, 1, 1, 0, 1})
        local x, y, u, v, r, g, b, a = luna.graphics.getMeshVertex(mesh, 2)
        assert(x == 10 and y == 0 and u == 1 and v == 0)
        assert(r == 1 and g == 1 and b == 0 and a == 1)

        luna.graphics.setMeshTexture(mesh, _phase02_mesh_texture)
        luna.graphics.setMeshVertexMap(mesh, {1, 2, 3})
        luna.graphics.drawMesh(mesh, 5, 6, 0.5, 2, 3, 4, 5)
        "#,
    )
    .exec()
    .unwrap();

    let st = state.borrow();
    let mesh = st
        .meshes
        .values()
        .next()
        .expect("expected mesh to be stored");
    assert_eq!(mesh.vertex_count(), 3);
    assert_eq!(mesh.texture, Some(tex_key));
    assert_eq!(mesh.indices.as_ref(), Some(&vec![0, 1, 2]));
    if let Some(DrawCommand::DrawMesh {
        mesh_key,
        x,
        y,
        rotation,
        sx,
        sy,
        ox,
        oy,
    }) = st.draw_commands.last()
    {
        assert!(st.meshes.contains_key(*mesh_key));
        assert!((*x - 5.0).abs() < 1e-5);
        assert!((*y - 6.0).abs() < 1e-5);
        assert!((*rotation - 0.5).abs() < 1e-5);
        assert!((*sx - 2.0).abs() < 1e-5);
        assert!((*sy - 3.0).abs() < 1e-5);
        assert!((*ox - 4.0).abs() < 1e-5);
        assert!((*oy - 5.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::DrawMesh");
    }
}

#[test]
fn test_phase02_points_accept_table_pairs_and_queue_draw_command() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        luna.graphics.points({
            {1, 2},
            {3, 4},
            {5, 6},
        })
        "#,
    )
    .exec()
    .unwrap();

    let st = state.borrow();
    if let Some(DrawCommand::Points { points }) = st.draw_commands.last() {
        assert_eq!(points.len(), 3);
        assert_eq!(points[0], (1.0, 2.0));
        assert_eq!(points[1], (3.0, 4.0));
        assert_eq!(points[2], (5.0, 6.0));
    } else {
        panic!("Expected DrawCommand::Points");
    }
}

#[test]
fn test_phase02_printf_pushes_formatted_text_command_with_alignment() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        local font = luna.graphics.newFont("assets/fonts/Roboto-Regular.ttf", 16)
        luna.graphics.setFont(font)
        luna.graphics.printf("wrapped text", 12, 34, 56, "center")
        "#,
    )
    .exec()
    .unwrap();

    let st = state.borrow();
    if let Some(DrawCommand::PrintFormatted {
        text,
        x,
        y,
        limit,
        align,
        scale,
        ..
    }) = st.draw_commands.last()
    {
        assert_eq!(text, "wrapped text");
        assert!((*x - 12.0).abs() < 1e-5);
        assert!((*y - 34.0).abs() < 1e-5);
        assert!((*limit - 56.0).abs() < 1e-5);
        assert_eq!(*align, TextAlign::Center);
        assert!((*scale - 1.0).abs() < 1e-5);
    } else {
        panic!("Expected DrawCommand::PrintFormatted");
    }
}

// ===========================================================================
// Nine-Slice Tests
// ===========================================================================

#[test]
fn nine_slice_patches_corners_preserve_size() {
    let mut textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
    let key = textures.insert(TextureData {
        pixels: vec![255; 64 * 64 * 4],
        width: 64,
        height: 64,
    });

    let ns = NineSlice::new(key, 8.0, 8.0, 8.0, 8.0, 64.0, 64.0);
    let patches = ns.patches(100.0, 200.0, 200.0, 150.0);

    // Top-left corner: fixed 8x8 at (100, 200)
    let (sx, sy, sw, sh, dx, dy, dw, dh) = patches[0];
    assert!((sx).abs() < 1e-5);
    assert!((sy).abs() < 1e-5);
    assert!((sw - 8.0).abs() < 1e-5);
    assert!((sh - 8.0).abs() < 1e-5);
    assert!((dx - 100.0).abs() < 1e-5);
    assert!((dy - 200.0).abs() < 1e-5);
    assert!((dw - 8.0).abs() < 1e-5);
    assert!((dh - 8.0).abs() < 1e-5);

    // Top-right corner: fixed 8x8 at (100+8+184, 200) = (292, 200)
    let (_, _, sw, sh, dx, dy, dw, dh) = patches[2];
    assert!((sw - 8.0).abs() < 1e-5);
    assert!((sh - 8.0).abs() < 1e-5);
    assert!((dx - 292.0).abs() < 1e-5);
    assert!((dy - 200.0).abs() < 1e-5);
    assert!((dw - 8.0).abs() < 1e-5);
    assert!((dh - 8.0).abs() < 1e-5);

    // Bottom-left corner
    let (_, _, sw, sh, dx, dy, dw, dh) = patches[6];
    assert!((sw - 8.0).abs() < 1e-5);
    assert!((sh - 8.0).abs() < 1e-5);
    assert!((dx - 100.0).abs() < 1e-5);
    assert!((dy - 342.0).abs() < 1e-5);
    assert!((dw - 8.0).abs() < 1e-5);
    assert!((dh - 8.0).abs() < 1e-5);

    // Bottom-right corner
    let (_, _, sw, sh, dx, dy, dw, dh) = patches[8];
    assert!((sw - 8.0).abs() < 1e-5);
    assert!((sh - 8.0).abs() < 1e-5);
    assert!((dx - 292.0).abs() < 1e-5);
    assert!((dy - 342.0).abs() < 1e-5);
    assert!((dw - 8.0).abs() < 1e-5);
    assert!((dh - 8.0).abs() < 1e-5);
}

#[test]
fn nine_slice_patches_center_stretches() {
    let mut textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
    let key = textures.insert(TextureData {
        pixels: vec![255; 64 * 64 * 4],
        width: 64,
        height: 64,
    });

    let ns = NineSlice::new(key, 8.0, 8.0, 8.0, 8.0, 64.0, 64.0);
    let patches = ns.patches(0.0, 0.0, 200.0, 150.0);

    // Center patch: src=(8,8,48,48), dst=(8,8,184,134)
    let (sx, sy, sw, sh, dx, dy, dw, dh) = patches[4];
    assert!((sx - 8.0).abs() < 1e-5);
    assert!((sy - 8.0).abs() < 1e-5);
    assert!((sw - 48.0).abs() < 1e-5);
    assert!((sh - 48.0).abs() < 1e-5);
    assert!((dx - 8.0).abs() < 1e-5);
    assert!((dy - 8.0).abs() < 1e-5);
    assert!((dw - 184.0).abs() < 1e-5);
    assert!((dh - 134.0).abs() < 1e-5);
}

#[test]
fn nine_slice_patches_edges_stretch_one_axis() {
    let mut textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
    let key = textures.insert(TextureData {
        pixels: vec![255; 64 * 64 * 4],
        width: 64,
        height: 64,
    });

    let ns = NineSlice::new(key, 8.0, 8.0, 8.0, 8.0, 64.0, 64.0);
    let patches = ns.patches(0.0, 0.0, 200.0, 150.0);

    // Top edge: dst_w stretches to 184, dst_h fixed at 8
    let (_, _, _, _, _, _, dw, dh) = patches[1];
    assert!((dw - 184.0).abs() < 1e-5);
    assert!((dh - 8.0).abs() < 1e-5);

    // Left edge: dst_w fixed at 8, dst_h stretches to 134
    let (_, _, _, _, _, _, dw, dh) = patches[3];
    assert!((dw - 8.0).abs() < 1e-5);
    assert!((dh - 134.0).abs() < 1e-5);

    // Right edge: dst_w fixed at 8, dst_h stretches to 134
    let (_, _, _, _, _, _, dw, dh) = patches[5];
    assert!((dw - 8.0).abs() < 1e-5);
    assert!((dh - 134.0).abs() < 1e-5);

    // Bottom edge: dst_w stretches to 184, dst_h fixed at 8
    let (_, _, _, _, _, _, dw, dh) = patches[7];
    assert!((dw - 184.0).abs() < 1e-5);
    assert!((dh - 8.0).abs() < 1e-5);
}

#[test]
fn nine_slice_asymmetric_borders() {
    let mut textures: SlotMap<TextureKey, TextureData> = SlotMap::with_key();
    let key = textures.insert(TextureData {
        pixels: vec![255; 100 * 80 * 4],
        width: 100,
        height: 80,
    });

    // Asymmetric: top=10, right=20, bottom=15, left=5
    let ns = NineSlice::new(key, 10.0, 20.0, 15.0, 5.0, 100.0, 80.0);
    let patches = ns.patches(50.0, 60.0, 300.0, 200.0);

    // Top-left: 5x10
    let (_, _, sw, sh, _, _, dw, dh) = patches[0];
    assert!((sw - 5.0).abs() < 1e-5);
    assert!((sh - 10.0).abs() < 1e-5);
    assert!((dw - 5.0).abs() < 1e-5);
    assert!((dh - 10.0).abs() < 1e-5);

    // Top-right: 20x10
    let (_, _, sw, sh, _, _, dw, dh) = patches[2];
    assert!((sw - 20.0).abs() < 1e-5);
    assert!((sh - 10.0).abs() < 1e-5);
    assert!((dw - 20.0).abs() < 1e-5);
    assert!((dh - 10.0).abs() < 1e-5);

    // Center: dst_w = 300-5-20 = 275, dst_h = 200-10-15 = 175
    let (_, _, _, _, _, _, dw, dh) = patches[4];
    assert!((dw - 275.0).abs() < 1e-5);
    assert!((dh - 175.0).abs() < 1e-5);
}

#[test]
fn nine_slice_lua_api_creates_and_draws() {
    let (state, lua) = make_graphics_vm();

    lua.load(
        r#"
        local img = luna.graphics.newImage("assets/icon.png")
        local ns = luna.graphics.newNineSlice(img, 10, 10, 10, 10)
        luna.graphics.drawNineSlice(ns, 50, 50, 300, 200)
        "#,
    )
    .exec()
    .unwrap();

    let st = state.borrow();
    let found = st.draw_commands.iter().any(|cmd| {
        matches!(cmd, DrawCommand::DrawNineSlice { x, y, w, h, .. }
            if (*x - 50.0).abs() < 1e-5
            && (*y - 50.0).abs() < 1e-5
            && (*w - 300.0).abs() < 1e-5
            && (*h - 200.0).abs() < 1e-5
        )
    });
    assert!(found, "Expected DrawCommand::DrawNineSlice in draw commands");
}

#[test]
fn nine_slice_lua_method_draw() {
    let (state, lua) = make_graphics_vm();

    lua.load(
        r#"
        local img = luna.graphics.newImage("assets/icon.png")
        local ns = luna.graphics.newNineSlice(img, 5, 5, 5, 5)
        ns:draw(10, 20, 400, 300)
        "#,
    )
    .exec()
    .unwrap();

    let st = state.borrow();
    let found = st.draw_commands.iter().any(|cmd| {
        matches!(cmd, DrawCommand::DrawNineSlice { x, y, w, h, .. }
            if (*x - 10.0).abs() < 1e-5
            && (*y - 20.0).abs() < 1e-5
            && (*w - 400.0).abs() < 1e-5
            && (*h - 300.0).abs() < 1e-5
        )
    });
    assert!(found, "Expected DrawCommand::DrawNineSlice from method call");
}

#[test]
fn nine_slice_lua_get_insets() {
    let (_state, lua) = make_graphics_vm();

    let result: (f32, f32, f32, f32) = lua
        .load(
            r#"
            local img = luna.graphics.newImage("assets/icon.png")
            local ns = luna.graphics.newNineSlice(img, 12, 8, 15, 6)
            return ns:getInsets()
            "#,
        )
        .eval()
        .unwrap();

    assert!((result.0 - 12.0).abs() < 1e-5);
    assert!((result.1 - 8.0).abs() < 1e-5);
    assert!((result.2 - 15.0).abs() < 1e-5);
    assert!((result.3 - 6.0).abs() < 1e-5);
}

#[test]
fn nine_slice_lua_negative_insets_error() {
    let (_state, lua) = make_graphics_vm();

    let result = lua
        .load(
            r#"
            local img = luna.graphics.newImage("assets/icon.png")
            local ns = luna.graphics.newNineSlice(img, -5, 10, 10, 10)
            "#,
        )
        .exec();

    assert_lua_error_contains(result, "non-negative");
}

#[test]
fn nine_slice_lua_excessive_insets_error() {
    let (_state, lua) = make_graphics_vm();

    let result = lua
        .load(
            r#"
            local img = luna.graphics.newImage("assets/icon.png")
            local ns = luna.graphics.newNineSlice(img, 500, 500, 500, 500)
            "#,
        )
        .exec();

    assert_lua_error_contains(result, "exceed texture dimensions");
}

#[test]
fn test_phase02_reset_restores_phase02_state_defaults() {
    let (_state, lua) = make_graphics_vm();
    let setup = format!(
        r#"
        local shader = luna.graphics.newShader([=[{}]=])
        local canvas = luna.graphics.newCanvas(8, 8)

        luna.graphics.push()
        luna.graphics.push()
        luna.graphics.setScissor(1, 2, 3, 4)
        luna.graphics.setColorMask(false, true, false, true)
        luna.graphics.setPointSize(5)
        luna.graphics.setShader(shader)
        luna.graphics.setCanvas(canvas)
        luna.graphics.reset()
        "#,
        VALID_WGSL_FRAGMENT_SHADER
    );
    lua.load(&setup).exec().unwrap();

    let scissor_arity: i64 = lua
        .load("return select('#', luna.graphics.getScissor())")
        .eval()
        .unwrap();
    let color_mask: (bool, bool, bool, bool) = lua
        .load("return luna.graphics.getColorMask()")
        .eval()
        .unwrap();
    let point_size: f32 = lua
        .load("return luna.graphics.getPointSize()")
        .eval()
        .unwrap();
    let shader_value: mlua::Value = lua.load("return luna.graphics.getShader()").eval().unwrap();
    let canvas_value: mlua::Value = lua.load("return luna.graphics.getCanvas()").eval().unwrap();

    assert_eq!(scissor_arity, 0, "reset should disable scissor");
    assert_eq!(
        color_mask,
        (true, true, true, true),
        "reset should restore the color mask to all channels enabled"
    );
    assert!(
        (point_size - 1.0).abs() < 1e-5,
        "reset should restore point size to 1"
    );
    assert!(
        matches!(shader_value, mlua::Value::Nil),
        "reset should clear the active shader"
    );
    assert!(
        matches!(canvas_value, mlua::Value::Nil),
        "reset should restore the screen canvas"
    );
}

#[test]
fn test_phase02_wireframe_round_trips_and_queues_command() {
    let (state, lua) = make_graphics_vm();
    lua.load(
        r#"
        assert(luna.graphics.isWireframe() == false)
        luna.graphics.setWireframe(true)
        assert(luna.graphics.isWireframe() == true)
        luna.graphics.setWireframe(false)
        assert(luna.graphics.isWireframe() == false)
        "#,
    )
    .exec()
    .unwrap();

    let st = state.borrow();
    assert!(
        st.draw_commands
            .iter()
            .any(|c| matches!(c, DrawCommand::SetWireframe(true))),
        "setWireframe(true) should push SetWireframe(true) command"
    );
    assert!(
        st.draw_commands
            .iter()
            .any(|c| matches!(c, DrawCommand::SetWireframe(false))),
        "setWireframe(false) should push SetWireframe(false) command"
    );
}

// ===========================================================================
// Font metric tests
// ===========================================================================

#[test]
fn test_font_ascent_descent() {
    let font = load_test_font();
    let ascent = font.ascent();
    let descent = font.descent();
    // Ascent should be positive (above baseline)
    assert!(ascent > 0.0, "ascent should be positive, got {}", ascent);
    // Descent should be negative or zero (below baseline)
    assert!(descent <= 0.0, "descent should be <= 0, got {}", descent);
}

#[test]
fn test_font_set_line_height() {
    let mut font = load_test_font();
    let original = font.line_height();
    font.set_line_height(2.0);
    assert!((font.line_height() - 2.0).abs() < f32::EPSILON);
    // Restore
    font.set_line_height(original);
    assert!((font.line_height() - original).abs() < f32::EPSILON);
}

// ===========================================================================
// SpriteBatch buffer_size tests
// ===========================================================================

#[test]
fn test_sprite_batch_buffer_size() {
    let mut tex_map: SlotMap<TextureKey, ()> = SlotMap::with_key();
    let tex_key = tex_map.insert(());
    let batch = SpriteBatch::new(tex_key, 42);
    assert_eq!(batch.buffer_size(), 42);
}

// ===========================================================================
// Phase 3: Polymorphic draw() dispatch
// ===========================================================================

#[test]
fn graphics_draw_dispatch_image_userdata_pushes_draw_image() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        r#"
        local img = luna.graphics.newImage("assets/icon.png")
        luna.graphics.draw(img, 10, 20)
        "#,
    );
    let st = state.borrow();
    let found = st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::DrawImage { x, y, .. } if (*x - 10.0).abs() < 1e-5 && (*y - 20.0).abs() < 1e-5));
    assert!(found, "Expected DrawCommand::DrawImage after draw(img, 10, 20)");
}

#[test]
fn graphics_draw_dispatch_image_with_rotation_pushes_draw_image_ex() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        r#"
        local img = luna.graphics.newImage("assets/icon.png")
        luna.graphics.draw(img, 5, 10, 1.57)
        "#,
    );
    let st = state.borrow();
    let found = st.draw_commands.iter().any(|cmd| {
        matches!(cmd, DrawCommand::DrawImageEx { rotation, .. } if (*rotation - 1.57).abs() < 0.01)
    });
    assert!(
        found,
        "Expected DrawCommand::DrawImageEx with rotation after draw(img, x, y, r)"
    );
}

#[test]
fn graphics_draw_dispatch_canvas_userdata_pushes_draw_canvas() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        r#"
        local canvas = luna.graphics.newCanvas(64, 64)
        luna.graphics.draw(canvas, 30, 40)
        "#,
    );
    let st = state.borrow();
    let found = st.draw_commands.iter().any(|cmd| {
        matches!(cmd, DrawCommand::DrawCanvas { x, y, .. } if (*x - 30.0).abs() < 1e-5 && (*y - 40.0).abs() < 1e-5)
    });
    assert!(
        found,
        "Expected DrawCommand::DrawCanvas after draw(canvas, 30, 40)"
    );
}

#[test]
fn graphics_draw_dispatch_sprite_batch_userdata_pushes_draw_batch() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        r#"
        local img = luna.graphics.newImage("assets/icon.png")
        local batch = luna.graphics.newSpriteBatch(img, 10)
        luna.graphics.draw(batch, 0, 0)
        "#,
    );
    let st = state.borrow();
    let found = st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::DrawBatch { .. }));
    assert!(
        found,
        "Expected DrawCommand::DrawBatch after draw(batch, 0, 0)"
    );
}

#[test]
fn graphics_draw_dispatch_nil_returns_error() {
    let (_state, lua) = make_graphics_vm();
    let result = lua.load("luna.graphics.draw(nil, 0, 0)").exec();
    assert_lua_error_contains(result, "nil");
}

#[test]
fn graphics_draw_dispatch_string_returns_error() {
    let (_state, lua) = make_graphics_vm();
    let result = lua.load("luna.graphics.draw('not_drawable', 0, 0)").exec();
    assert_lua_error_contains(result, "drawable");
}

#[test]
fn graphics_draw_ex_dispatch_image_userdata_pushes_draw_image_ex() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        r#"
        local img = luna.graphics.newImage("assets/icon.png")
        luna.graphics.drawEx(img, 15, 25, 0.5, 2.0, 2.0, 0, 0)
        "#,
    );
    let st = state.borrow();
    let found = st.draw_commands.iter().any(|cmd| {
        matches!(cmd, DrawCommand::DrawImageEx { x, y, rotation, sx, .. }
            if (*x - 15.0).abs() < 1e-5
            && (*y - 25.0).abs() < 1e-5
            && (*rotation - 0.5).abs() < 0.01
            && (*sx - 2.0).abs() < 1e-5)
    });
    assert!(
        found,
        "Expected DrawCommand::DrawImageEx after drawEx(img, ...)"
    );
}

#[test]
fn graphics_draw_ex_dispatch_canvas_userdata_pushes_draw_canvas() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        r#"
        local canvas = luna.graphics.newCanvas(32, 32)
        luna.graphics.drawEx(canvas, 5, 10, 0, 1, 1, 0, 0)
        "#,
    );
    let st = state.borrow();
    let found = st
        .draw_commands
        .iter()
        .any(|cmd| matches!(cmd, DrawCommand::DrawCanvas { .. }));
    assert!(
        found,
        "Expected DrawCommand::DrawCanvas after drawEx(canvas, ...)"
    );
}

#[test]
fn graphics_draw_ex_sy_defaults_to_sx() {
    let (state, lua) = make_graphics_vm();
    run_draw(
        &lua,
        r#"
        local img = luna.graphics.newImage("assets/icon.png")
        luna.graphics.drawEx(img, 0, 0, 0, 3.0)
        "#,
    );
    let st = state.borrow();
    // sy should equal sx (3.0) when not provided
    let found = st.draw_commands.iter().any(|cmd| {
        matches!(cmd, DrawCommand::DrawImageEx { sx, sy, .. }
            if (*sx - 3.0).abs() < 1e-5 && (*sy - 3.0).abs() < 1e-5)
    });
    assert!(
        found,
        "drawEx sy should default to sx when omitted"
    );
}

// ===========================================================================
// Feature: captureScreenshot
// ===========================================================================

#[test]
fn graphics_capture_screenshot_stores_callback() {
    // Verify that captureScreenshot does not panic and calls the callback synchronously.
    // Actual GPU pixel readback is not testable headlessly; the stub creates a blank ImageData.
    let (_state, lua) = make_graphics_vm();
    let result = lua
        .load(
            r#"
        local fired = false
        luna.graphics.captureScreenshot(function(img)
            fired = true
            assert(type(img) == "userdata", "expected ImageData userdata")
        end)
        assert(fired, "callback must fire synchronously in stub mode")
        "#,
        )
        .exec();
    assert!(
        result.is_ok(),
        "captureScreenshot should not error: {:?}",
        result
    );
}


// ===========================================================================
// Phase 3: DrawCommand image and canvas variants
// ===========================================================================

#[test]
fn graphics_draw_command_image_variant() {
    // Verify DrawCommand::DrawImage is pushed when drawing an Image at default transform.
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, r#"
        local img = luna.graphics.newImage("assets/icon.png")
        luna.graphics.draw(img, 10, 20)
    "#);
    let st = state.borrow();
    let found = st.draw_commands.iter().any(|cmd| {
        matches!(cmd, DrawCommand::DrawImage { x, y, .. } if (*x - 10.0).abs() < 1e-4 && (*y - 20.0).abs() < 1e-4)
    });
    assert!(found, "Expected DrawCommand::DrawImage to be queued");
}

#[test]
fn graphics_draw_command_canvas_variant() {
    // Verify DrawCommand::DrawCanvas is pushed when drawing a Canvas.
    let (state, lua) = make_graphics_vm();
    run_draw(&lua, r#"
        local c = luna.graphics.newCanvas(64, 64)
        luna.graphics.draw(c, 5, 15)
    "#);
    let st = state.borrow();
    let found = st.draw_commands.iter().any(|cmd| {
        matches!(cmd, DrawCommand::DrawCanvas { x, y, .. } if (*x - 5.0).abs() < 1e-4 && (*y - 15.0).abs() < 1e-4)
    });
    assert!(found, "Expected DrawCommand::DrawCanvas to be queued");
}

// ===========================================================================
// Phase 5: GpuRenderer::request_screenshot
// ===========================================================================

#[test]
fn graphics_screenshot_request_queued_without_panic() {
    // Headless stub: captureScreenshot must not panic and must call the callback.
    let (_state, lua) = make_graphics_vm();
    let result = lua
        .load(r#"
        local fired = false
        luna.graphics.captureScreenshot(function(img)
            fired = true
        end)
        assert(fired, "captureScreenshot callback must be invoked")
        "#)
        .exec();
    assert!(
        result.is_ok(),
        "graphics_screenshot_request_queued_without_panic failed: {:?}",
        result
    );
}
