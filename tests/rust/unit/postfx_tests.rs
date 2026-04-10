//! Integration tests for the PostFX (post-processing effects) module.

use lurek2d::effect::{PostFxEffect, PostFxEffectType, PostFxStack};
use std::cell::RefCell;
use std::path::PathBuf;
use std::rc::Rc;

use lurek2d::engine::config::Config;
use lurek2d::lua_api::{create_lua_vm, SharedState};

fn make_vm() -> mlua::Lua {
    let state = Rc::new(RefCell::new(SharedState::new(
        800,
        600,
        "Test",
        PathBuf::from("."),
    )));
    create_lua_vm(state, &Config::default().modules).expect("Failed to create Lua VM")
}

// ═════════════════════════════════════════════════════════════════════════
// 1. PostFxEffectType
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_effect_type_from_name_valid() {
    assert_eq!(
        PostFxEffectType::from_name("bloom"),
        Some(PostFxEffectType::Bloom)
    );
    assert_eq!(
        PostFxEffectType::from_name("blur"),
        Some(PostFxEffectType::Blur)
    );
    assert_eq!(
        PostFxEffectType::from_name("crt"),
        Some(PostFxEffectType::Crt)
    );
    assert_eq!(
        PostFxEffectType::from_name("godrays"),
        Some(PostFxEffectType::Godrays)
    );
    assert_eq!(
        PostFxEffectType::from_name("vignette"),
        Some(PostFxEffectType::Vignette)
    );
    assert_eq!(
        PostFxEffectType::from_name("colourgrade"),
        Some(PostFxEffectType::ColourGrade)
    );
    assert_eq!(
        PostFxEffectType::from_name("chromatic"),
        Some(PostFxEffectType::Chromatic)
    );
}

#[test]
fn test_effect_type_from_name_invalid() {
    assert_eq!(PostFxEffectType::from_name("bloom2"), None);
    assert_eq!(PostFxEffectType::from_name(""), None);
    assert_eq!(PostFxEffectType::from_name("BLOOM"), None);
}

#[test]
fn test_effect_type_name_roundtrip() {
    let types = [
        PostFxEffectType::Bloom,
        PostFxEffectType::Blur,
        PostFxEffectType::Crt,
        PostFxEffectType::Godrays,
        PostFxEffectType::Vignette,
        PostFxEffectType::ColourGrade,
        PostFxEffectType::Chromatic,
        PostFxEffectType::Custom,
    ];
    for t in &types {
        let name = t.name();
        if *t != PostFxEffectType::Custom {
            assert_eq!(PostFxEffectType::from_name(name), Some(*t));
        }
    }
}

#[test]
fn test_effect_type_default_params() {
    let bloom_params = PostFxEffectType::Bloom.default_params();
    assert!(bloom_params.contains_key("threshold"));
    assert!(bloom_params.contains_key("intensity"));
    assert!((bloom_params["threshold"] - 0.7).abs() < 1e-5);
    assert!((bloom_params["intensity"] - 1.0).abs() < 1e-5);

    let blur_params = PostFxEffectType::Blur.default_params();
    assert!(blur_params.contains_key("radius"));

    let custom_params = PostFxEffectType::Custom.default_params();
    assert!(custom_params.is_empty());
}

// ═════════════════════════════════════════════════════════════════════════
// 2. PostFxEffect
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_effect_new_bloom() {
    let effect = PostFxEffect::new(PostFxEffectType::Bloom);
    assert_eq!(effect.get_type_name(), "bloom");
    assert!(effect.is_built_in());
    assert!(effect.enabled);
    assert!(effect.has_parameter("threshold"));
    assert!(effect.has_parameter("intensity"));
    assert!((effect.get_parameter("threshold", 0.0) - 0.7).abs() < 1e-5);
}

#[test]
fn test_effect_new_custom() {
    let effect = PostFxEffect::new_custom(42);
    assert_eq!(effect.get_type_name(), "custom");
    assert!(!effect.is_built_in());
    assert_eq!(effect.shader_id, Some(42));
    assert!(effect.enabled);
}

#[test]
fn test_effect_set_get_parameter() {
    let mut effect = PostFxEffect::new(PostFxEffectType::Bloom);
    effect.set_parameter("threshold", 0.5);
    assert!((effect.get_parameter("threshold", 0.0) - 0.5).abs() < 1e-5);
}

#[test]
fn test_effect_get_parameter_default() {
    let effect = PostFxEffect::new(PostFxEffectType::Bloom);
    assert!((effect.get_parameter("nonexistent", 99.0) - 99.0).abs() < 1e-5);
}

#[test]
fn test_effect_has_parameter() {
    let mut effect = PostFxEffect::new(PostFxEffectType::Custom);
    assert!(!effect.has_parameter("foo"));
    effect.set_parameter("foo", 1.0);
    assert!(effect.has_parameter("foo"));
}

#[test]
fn test_effect_get_parameter_names() {
    let effect = PostFxEffect::new(PostFxEffectType::Bloom);
    let names = effect.get_parameter_names();
    assert!(names.contains(&"threshold".to_string()));
    assert!(names.contains(&"intensity".to_string()));
    // Should be sorted
    for i in 1..names.len() {
        assert!(names[i - 1] <= names[i]);
    }
}

#[test]
fn test_effect_all_builtin_types_have_defaults() {
    let types = [
        PostFxEffectType::Bloom,
        PostFxEffectType::Blur,
        PostFxEffectType::Crt,
        PostFxEffectType::Godrays,
        PostFxEffectType::Vignette,
        PostFxEffectType::ColourGrade,
        PostFxEffectType::Chromatic,
    ];
    for t in &types {
        let effect = PostFxEffect::new(*t);
        assert!(
            !effect.get_parameter_names().is_empty(),
            "Built-in effect {:?} has no default parameters",
            t
        );
    }
}

// ═════════════════════════════════════════════════════════════════════════
// 3. PostFxStack
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_stack_new() {
    let stack = PostFxStack::new(800, 600);
    assert_eq!(stack.get_width(), 800);
    assert_eq!(stack.get_height(), 600);
    assert_eq!(stack.get_dimensions(), (800, 600));
    assert_eq!(stack.get_effect_count(), 0);
    assert!(!stack.capturing);
}

#[test]
fn test_stack_add_effects() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    assert_eq!(stack.get_effect_count(), 2);
    assert_eq!(stack.get_effect(1), Some(0));
    assert_eq!(stack.get_effect(2), Some(1));
}

#[test]
fn test_stack_remove_effect() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    assert!(stack.remove(0));
    assert_eq!(stack.get_effect_count(), 1);
    assert_eq!(stack.get_effect(1), Some(1));
    assert!(!stack.remove(99)); // nonexistent
}

#[test]
fn test_stack_insert_effect() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    stack.insert(1, 2); // insert at position 1 (beginning)
    assert_eq!(stack.get_effect_count(), 3);
    assert_eq!(stack.get_effect(1), Some(2));
    assert_eq!(stack.get_effect(2), Some(0));
    assert_eq!(stack.get_effect(3), Some(1));
}

#[test]
fn test_stack_insert_clamp() {
    let mut stack = PostFxStack::new(800, 600);
    stack.insert(99, 0); // out of range — should clamp to end
    assert_eq!(stack.get_effect_count(), 1);
    assert_eq!(stack.get_effect(1), Some(0));
}

#[test]
fn test_stack_enable_disable() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    assert!(stack.is_enabled(0));
    assert!(stack.is_enabled(1));

    stack.set_enabled(0, false);
    assert!(!stack.is_enabled(0));
    assert!(stack.is_enabled(1));
}

#[test]
fn test_stack_enabled_effects() {
    let mut stack = PostFxStack::new(800, 600);
    stack.add(0);
    stack.add(1);
    stack.add(2);
    stack.set_enabled(1, false);
    let enabled = stack.enabled_effects();
    assert_eq!(enabled, vec![0, 2]);
}

#[test]
fn test_stack_get_effect_out_of_range() {
    let stack = PostFxStack::new(800, 600);
    assert_eq!(stack.get_effect(0), None); // 0 is out of 1-based range
    assert_eq!(stack.get_effect(1), None); // empty stack
}

#[test]
fn test_stack_resize() {
    let mut stack = PostFxStack::new(800, 600);
    stack.resize(1920, 1080);
    assert_eq!(stack.get_width(), 1920);
    assert_eq!(stack.get_height(), 1080);
}

#[test]
fn test_stack_is_enabled_nonexistent() {
    let stack = PostFxStack::new(800, 600);
    assert!(!stack.is_enabled(99));
}

// ═════════════════════════════════════════════════════════════════════════
// 4. Lua VM integration
// ═════════════════════════════════════════════════════════════════════════

#[test]
fn test_lua_postfx_new_effect() {
    let lua = make_vm();
    let result: String = lua
        .load(
            r#"
            local bloom = lurek.postfx.newEffect("bloom")
            return bloom:getEffectType()
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert_eq!(result, "bloom");
}

#[test]
fn test_lua_postfx_invalid_effect_type() {
    let lua = make_vm();
    let result: Result<mlua::Value, _> =
        lua.load(r#"lurek.postfx.newEffect("invalid_type")"#).eval();
    assert!(result.is_err());
}

#[test]
fn test_lua_postfx_effect_parameters() {
    let lua = make_vm();
    let result: (f32, f32, bool) = lua
        .load(
            r#"
            local bloom = lurek.postfx.newEffect("bloom")
            bloom:setThreshold(0.5)
            local t = bloom:getParameter("threshold")
            local i = bloom:getParameter("intensity")
            local h = bloom:hasParameter("threshold")
            return t, i, h
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert!((result.0 - 0.5).abs() < 1e-5);
    assert!((result.1 - 1.0).abs() < 1e-5);
    assert!(result.2);
}

#[test]
fn test_lua_postfx_stack_add_remove() {
    let lua = make_vm();
    let count: i32 = lua
        .load(
            r#"
            local stack = lurek.postfx.newStack(800, 600)
            local bloom = lurek.postfx.newEffect("bloom")
            local blur = lurek.postfx.newEffect("blur")
            stack:add(bloom)
            stack:add(blur)
            local c1 = stack:getEffectCount()
            stack:remove(bloom)
            local c2 = stack:getEffectCount()
            return c1 * 10 + c2
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert_eq!(count, 21); // c1=2, c2=1 -> 21
}

#[test]
fn test_lua_postfx_stack_dimensions() {
    let lua = make_vm();
    let (w, h): (u32, u32) = lua
        .load(
            r#"
            local stack = lurek.postfx.newStack(1920, 1080)
            return stack:getWidth(), stack:getHeight()
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert_eq!(w, 1920);
    assert_eq!(h, 1080);
}

#[test]
fn test_lua_postfx_get_effect_types() {
    let lua = make_vm();
    let count: i32 = lua
        .load(
            r#"
            local types = lurek.postfx.getEffectTypes()
            return #types
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert_eq!(count, 15); // 7 original + 8 new: pixelate,sepia,grayscale,invert,scanlines,edgedetect,hueshift,noise
}

#[test]
fn test_lua_postfx_new_pass() {
    let lua = make_vm();
    let (t, built_in): (String, bool) = lua
        .load(
            r#"
            local pass = lurek.postfx.newPass(1)
            return pass:getEffectType(), pass:isBuiltIn()
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert_eq!(t, "custom");
    assert!(!built_in);
}

#[test]
fn test_lua_postfx_effect_type_method() {
    let lua = make_vm();
    let t: String = lua
        .load(
            r#"
            local bloom = lurek.postfx.newEffect("bloom")
            return bloom:type()
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert_eq!(t, "PostFxEffect");
}

// ── New effect type Rust tests ─────────────────────────────────────────────

#[test]
fn pixelate_default_params_has_block_size() {
    let e = PostFxEffect::new(PostFxEffectType::Pixelate);
    assert!((e.get_parameter("block_size", 0.0) - 4.0).abs() < 1e-5);
}

#[test]
fn sepia_default_params_has_strength() {
    let e = PostFxEffect::new(PostFxEffectType::Sepia);
    assert!((e.get_parameter("strength", 0.0) - 1.0).abs() < 1e-5);
}

#[test]
fn grayscale_default_params_has_strength() {
    let e = PostFxEffect::new(PostFxEffectType::Grayscale);
    assert!((e.get_parameter("strength", 0.0) - 1.0).abs() < 1e-5);
}

#[test]
fn invert_default_params_has_strength() {
    let e = PostFxEffect::new(PostFxEffectType::Invert);
    assert!((e.get_parameter("strength", 0.0) - 1.0).abs() < 1e-5);
}

#[test]
fn scanlines_default_params_has_strength_and_spacing() {
    let e = PostFxEffect::new(PostFxEffectType::Scanlines);
    assert!((e.get_parameter("strength", 0.0) - 0.5).abs() < 1e-5);
    assert!((e.get_parameter("spacing", 0.0) - 4.0).abs() < 1e-5);
}

#[test]
fn edge_detect_default_params_has_strength() {
    let e = PostFxEffect::new(PostFxEffectType::EdgeDetect);
    assert!((e.get_parameter("strength", 0.0) - 1.0).abs() < 1e-5);
}

#[test]
fn hue_shift_default_params_has_angle() {
    let e = PostFxEffect::new(PostFxEffectType::HueShift);
    assert!((e.get_parameter("angle", 999.0) - 0.0).abs() < 1e-5);
}

#[test]
fn noise_default_params_has_strength() {
    let e = PostFxEffect::new(PostFxEffectType::Noise);
    assert!((e.get_parameter("strength", 0.0) - 0.1).abs() < 1e-5);
}

#[test]
fn all_new_effect_types_are_built_in() {
    let new_types = [
        PostFxEffectType::Pixelate,
        PostFxEffectType::Sepia,
        PostFxEffectType::Grayscale,
        PostFxEffectType::Invert,
        PostFxEffectType::Scanlines,
        PostFxEffectType::EdgeDetect,
        PostFxEffectType::HueShift,
        PostFxEffectType::Noise,
    ];
    for t in &new_types {
        assert!(
            PostFxEffect::new(t.clone()).is_built_in(),
            "{:?} should be built-in",
            t
        );
    }
}

#[test]
fn all_new_effect_types_round_trip_name() {
    let new_names = [
        "pixelate",
        "sepia",
        "grayscale",
        "invert",
        "scanlines",
        "edgedetect",
        "hueshift",
        "noise",
    ];
    for name in &new_names {
        let t = PostFxEffectType::from_name(name);
        assert!(t.is_some(), "from_name({}) returned None", name);
        assert_eq!(
            t.unwrap().name(),
            *name,
            "name() round-trip failed for {}",
            name
        );
    }
}

// ── New effect types via Lua API ───────────────────────────────────────────

#[test]
fn lua_pixelate_effect_has_block_size_param() {
    let lua = make_vm();
    let v: f32 = lua
        .load(
            r#"
            local e = lurek.postfx.newEffect("pixelate")
            return e:getParameter("block_size")
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert!((v - 4.0).abs() < 1e-5);
}

#[test]
fn lua_sepia_effect_built_in() {
    let lua = make_vm();
    let ok: bool = lua
        .load(
            r#"
            local e = lurek.postfx.newEffect("sepia")
            return e:isBuiltIn()
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert!(ok);
}

#[test]
fn lua_scanlines_effect_has_spacing_param() {
    let lua = make_vm();
    let v: f32 = lua
        .load(
            r#"
            local e = lurek.postfx.newEffect("scanlines")
            return e:getParameter("spacing")
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert!((v - 4.0).abs() < 1e-5);
}

#[test]
fn lua_new_effects_stack_add_remove() {
    let lua = make_vm();
    let count: i32 = lua
        .load(
            r#"
            local stack = lurek.postfx.newStack(800, 600)
            local pixelate = lurek.postfx.newEffect("pixelate")
            local sepia     = lurek.postfx.newEffect("sepia")
            local grayscale = lurek.postfx.newEffect("grayscale")
            stack:add(pixelate)
            stack:add(sepia)
            stack:add(grayscale)
            return stack:getEffectCount()
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert_eq!(count, 3);
}

#[test]
fn lua_hueshift_effect_name_roundtrip() {
    let lua = make_vm();
    let name: String = lua
        .load(
            r#"
            local e = lurek.postfx.newEffect("hueshift")
            return e:getEffectType()
        "#,
        )
        .eval()
        .expect("Lua eval failed");
    assert_eq!(name, "hueshift");
}

