//! Rust unit tests for private UI internals not reachable through the `lurek.*` Lua API.
//!
//! **Rule**: If behaviour can be observed via `lurek.ui.*` it MUST be tested in
//! `tests/lua/unit/test_gui.lua` instead. Only struct-field defaults, non-public
//! helpers, and pure-Rust invariants that cannot survive the Lua call boundary
//! belong here.
//!
//! Naming convention: `<subject>_<scenario>_<expected>` — no `test_` prefix.
//! Float comparisons use `(a - b).abs() < 1e-5` — never `assert_eq!` on floats.

use lurek2d::ui::context::GuiContext;
use lurek2d::ui::controls::Switch;
use lurek2d::ui::theme::{Theme, WidgetStyle};
use lurek2d::ui::widget::{WidgetBase, WidgetType};

// ─── WidgetStyle field defaults ───────────────────────────────────────────────
// WidgetStyle is an internal struct with no Lua getter; its default values are
// invisible to the script layer and must be confirmed here.

#[test]
fn widget_style_default_shadow_alpha_is_zero() {
    let s = WidgetStyle::default();
    assert!((s.shadow_color[3]).abs() < 1e-5, "default shadow alpha must be zero");
}

#[test]
fn widget_style_default_highlight_alpha_is_zero() {
    let s = WidgetStyle::default();
    assert!((s.highlight_alpha).abs() < 1e-5, "default highlight_alpha must be zero");
}

#[test]
fn widget_style_default_gradient_end_is_none() {
    assert!(WidgetStyle::default().gradient_end.is_none());
}

#[test]
fn widget_style_default_text_align_is_center() {
    assert_eq!(WidgetStyle::default().text_align, "center");
}

#[test]
fn widget_style_default_shadow_offset_is_zero() {
    let s = WidgetStyle::default();
    assert!((s.shadow_offset[0]).abs() < 1e-5);
    assert!((s.shadow_offset[1]).abs() < 1e-5);
}

// ─── WidgetType::default_size ─────────────────────────────────────────────────
// default_size() is not exposed as a Lua function; it only drives WidgetBase::new().

#[test]
fn widget_type_button_default_size_is_16px_aligned() {
    let (w, h) = WidgetType::Button.default_size();
    assert_eq!(w % 16.0, 0.0, "Button width must be 16px aligned");
    assert_eq!(h % 16.0, 0.0, "Button height must be 16px aligned");
}

#[test]
fn widget_type_spin_box_default_size_is_positive() {
    let (w, h) = WidgetType::SpinBox.default_size();
    assert!(w > 0.0 && h > 0.0);
}

#[test]
fn widget_type_switch_default_size_is_positive() {
    let (w, h) = WidgetType::Switch.default_size();
    assert!(w > 0.0 && h > 0.0);
}

#[test]
fn widget_type_badge_default_size_is_positive() {
    let (w, h) = WidgetType::Badge.default_size();
    assert!(w > 0.0 && h > 0.0);
}

// ─── WidgetBase::new sizing ───────────────────────────────────────────────────
// The fact that WidgetBase uses default_size (not a 100×30 hardcode) is a
// pure-Rust invariant — Lua cannot observe the raw width/height before any
// geometry call.

#[test]
fn widget_base_new_width_matches_type_default_size() {
    let (expected_w, _) = WidgetType::Button.default_size();
    let base = WidgetBase::new(WidgetType::Button);
    assert!((base.width - expected_w).abs() < 1e-5);
}

#[test]
fn widget_base_new_height_matches_type_default_size() {
    let (_, expected_h) = WidgetType::Button.default_size();
    let base = WidgetBase::new(WidgetType::Button);
    assert!((base.height - expected_h).abs() < 1e-5);
}

// ─── Switch::thumb_t ─────────────────────────────────────────────────────────
// `thumb_t` is a private animation field not exposed via the Lua `Switch`
// userdata — it drives the thumb animation only inside Rust.

#[test]
fn switch_new_off_has_thumb_t_zero() {
    let sw = Switch::new(false);
    assert!((sw.thumb_t).abs() < 1e-5, "thumb_t must be 0 when off");
}

#[test]
fn switch_new_on_has_thumb_t_one() {
    let sw = Switch::new(true);
    assert!((sw.thumb_t - 1.0).abs() < 1e-5, "thumb_t must be 1.0 when on");
}

// ─── Theme::default_dark ──────────────────────────────────────────────────────
// The Theme struct's style map is not surfaced through any `lurek.ui.*` getter;
// its content can only be inspected at the Rust level.

#[test]
fn theme_default_dark_has_button_style() {
    use lurek2d::ui::widget::{WidgetState, WidgetType};
    let theme = Theme::default_dark();
    let style = theme.get_style(WidgetType::Button, WidgetState::Normal);
    assert!(style.is_some(), "default_dark must include a style for Button/Normal");
}

#[test]
fn theme_default_dark_button_has_nonzero_corner_radius() {
    use lurek2d::ui::widget::{WidgetState, WidgetType};
    let theme = Theme::default_dark();
    let style = theme
        .get_style(WidgetType::Button, WidgetState::Normal)
        .unwrap();
    assert!(style.corner_radius > 0.0, "Button in default_dark must have corner_radius > 0");
}

// ─── GuiContext private internals ─────────────────────────────────────────────
// GuiContext fields (dirty, viewport_w/h, theme, widget pool) are not exposed
// via `lurek.ui.*`; only the effects of mutation are observable from Lua.

#[test]
fn gui_context_new_is_dirty() {
    let ctx = GuiContext::new();
    assert!(ctx.dirty, "GuiContext must start dirty");
}

#[test]
fn gui_context_add_spin_box_marks_dirty() {
    let mut ctx = GuiContext::new();
    ctx.flush_cache();
    ctx.add_spin_box(0.0, 10.0);
    assert!(ctx.dirty, "add_spin_box must set dirty = true");
}

#[test]
fn gui_context_add_switch_marks_dirty() {
    let mut ctx = GuiContext::new();
    ctx.flush_cache();
    ctx.add_switch(false);
    assert!(ctx.dirty, "add_switch must set dirty = true");
}

#[test]
fn gui_context_add_badge_marks_dirty() {
    let mut ctx = GuiContext::new();
    ctx.flush_cache();
    ctx.add_badge(0);
    assert!(ctx.dirty, "add_badge must set dirty = true");
}

#[test]
fn gui_context_set_viewport_stores_dimensions() {
    let mut ctx = GuiContext::new();
    ctx.set_viewport(1280.0, 720.0);
    assert!((ctx.viewport_w - 1280.0).abs() < 1e-5);
    assert!((ctx.viewport_h - 720.0).abs() < 1e-5);
}

#[test]
fn gui_context_set_default_theme_installs_theme() {
    let mut ctx = GuiContext::new();
    ctx.set_default_theme();
    assert!(ctx.theme.is_some(), "set_default_theme must install a non-None theme");
}

#[test]
fn gui_context_add_spin_box_returns_valid_index() {
    let mut ctx = GuiContext::new();
    let idx = ctx.add_spin_box(0.0, 10.0);
    assert!(idx < ctx.widgets.len(), "returned index must be within widgets pool");
}
