//! INTERNAL ONLY: public `lurek.html.*` document, query, style, and layout
//! behavior is covered by the Lua-first suite in
//! `tests/lua/unit/test_html_core_unit.lua`.
//!
//! The remaining Rust coverage keeps the CSS color parser helper used inside
//! the HTML pipeline, which is not exposed as a direct Lua-callable function.

use lurek2d::html::parse_css_color_rgba;

fn assert_rgba_near(actual: [f32; 4], expected: [f32; 4]) {
    let eps = 0.0001_f32;
    assert!(
        (actual[0] - expected[0]).abs() <= eps,
        "r mismatch: {:?} vs {:?}",
        actual,
        expected
    );
    assert!(
        (actual[1] - expected[1]).abs() <= eps,
        "g mismatch: {:?} vs {:?}",
        actual,
        expected
    );
    assert!(
        (actual[2] - expected[2]).abs() <= eps,
        "b mismatch: {:?} vs {:?}",
        actual,
        expected
    );
    assert!(
        (actual[3] - expected[3]).abs() <= eps,
        "a mismatch: {:?} vs {:?}",
        actual,
        expected
    );
}

#[test]
fn test_parse_css_color_rgba_named_colors_extended() {
    assert_rgba_near(
        parse_css_color_rgba("orange").expect("orange should parse"),
        [1.0, 0.647_058_84, 0.0, 1.0],
    );
    assert_rgba_near(
        parse_css_color_rgba("teal").expect("teal should parse"),
        [0.0, 0.5, 0.5, 1.0],
    );
    assert_rgba_near(
        parse_css_color_rgba("transparent").expect("transparent should parse"),
        [0.0, 0.0, 0.0, 0.0],
    );
}

#[test]
fn test_parse_css_color_rgba_rgb_and_percent_formats() {
    assert_rgba_near(
        parse_css_color_rgba("rgb(255, 0, 128)").expect("rgb bytes should parse"),
        [1.0, 0.0, 0.501_960_8, 1.0],
    );
    assert_rgba_near(
        parse_css_color_rgba("rgb(100%, 0%, 50%)").expect("rgb percent should parse"),
        [1.0, 0.0, 0.5, 1.0],
    );
    assert_rgba_near(
        parse_css_color_rgba("rgba(255, 0, 128, 50%)").expect("rgba mixed should parse"),
        [1.0, 0.0, 0.501_960_8, 0.5],
    );
}

#[test]
fn test_parse_css_color_rgba_hsl_hsla_formats() {
    assert_rgba_near(
        parse_css_color_rgba("hsl(120, 100%, 50%)").expect("hsl should parse"),
        [0.0, 1.0, 0.0, 1.0],
    );
    assert_rgba_near(
        parse_css_color_rgba("hsla(240, 100%, 50%, 0.25)").expect("hsla should parse"),
        [0.0, 0.0, 1.0, 0.25],
    );
    assert_rgba_near(
        parse_css_color_rgba("hsl(0.5turn, 100%, 50%)").expect("hsl turn hue should parse"),
        [0.0, 1.0, 1.0, 1.0],
    );
}

#[test]
fn test_parse_css_color_rgba_invalid_returns_none() {
    assert!(parse_css_color_rgba("not-a-color").is_none());
    assert!(parse_css_color_rgba("rgb(10,20)").is_none());
    assert!(parse_css_color_rgba("hsl(10, 20, 30)").is_none());
}
