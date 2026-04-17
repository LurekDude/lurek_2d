//! UI layout definition loading and headless image rendering for Lurek2D.
//!
//! This module provides the data types and pure-Rust functions that back the
//! `lurek.ui.loadLayout`, `lurek.ui.loadLayoutFile`, and
//! `lurek.ui.renderToImage` Lua API calls.
//!
//! ## Responsibility
//!
//! - **`WidgetDef`** — A Serde-deserializable tree node describing a single
//!   widget and its children. Instances are built from TOML files or from Lua
//!   tables via the bridge in `src/lua_api/ui_api.rs`.
//! - **`LayoutDef`** — Top-level TOML container wrapping the root `WidgetDef`.
//! - **`load_layout_def`** — Recursively populates a `GuiContext` from a
//!   `WidgetDef` tree and returns the pool index of the created root widget.
//! - **`load_layout_toml`** — Convenience wrapper that parses TOML source text
//!   and delegates to `load_layout_def`.
//! - **`render_to_image`** — Headless software rasteriser that runs the layout
//!   pass, draws each widget's computed bounding rectangle as a coloured
//!   filled quad, and saves the result as a PNG file using the `image` crate.
//!   No GPU or windowing dependency.
//!
//! ## Sub-system membership
//!
//! Part of the **Feature Systems** tier (`ui` module). Imports only
//! `crate::ui::context`, and the third-party crates `serde`, `toml`, and
//! `image`. No `mlua` imports — all Lua integration lives in
//! `src/lua_api/ui_api.rs`.
//!
//! ## Typical usage sequence
//!
//! ```text
//! 1. Obtain a WidgetDef (from TOML source or the Lua bridge).
//! 2. Call load_layout_def(ctx, &def)  →  root widget pool index.
//! 3. Call ctx.add_child(0, root_idx) to attach the tree to the UI root.
//! 4. Optionally call render_to_image(ctx, width, height, path) for tests.
//! ```

use crate::ui::context::{GuiContext, WidgetKind};
use serde::Deserialize;

// ── Public data types ─────────────────────────────────────────────────────────

/// Tree node describing a single widget and its optional children.
///
/// All fields except `widget_type` are optional. When absent the engine
/// default for that widget type is used. The `widget_type` field is
/// case-insensitive and must match one of the recognised type strings listed
/// in its doc comment.
///
/// # Fields
///
/// - `widget_type` — `String`. Case-insensitive widget kind. Recognised
///   values: `"button"`, `"label"`, `"panel"`, `"textinput"`, `"checkbox"`,
///   `"slider"`, `"progressbar"`, `"combobox"`, `"listbox"`, `"layout"`,
///   `"scrollpanel"`, `"tabbar"`, `"separator"`, `"spacer"`,
///   `"imagewidget"`, `"ninepatch"`, `"splitpanel"`, `"dockpanel"`,
///   `"accordion"`, `"treeview"`, `"radiobutton"`, `"spinbox"`,
///   `"switch"`, `"colorpicker"`, `"guitable"`, `"guiwindow"`,
///   `"dialog"`, `"menubar"`, `"menuitem"`, `"statusbar"`, `"toolbar"`,
///   `"scrollbar"`, `"badge"`, `"tooltippanel"`.
/// - `id` — `String`. Optional identifier for `find_by_id` / `lurek.ui.findById`.
/// - `x`, `y` — `f32`. Position relative to the parent. Defaults to `0.0`.
/// - `w`, `h` — `f32`. Pixel size. `0.0` = auto-size from the parent.
/// - `text` — `String`. Display or label text (Button, Label, CheckBox, …).
/// - `min`, `max` — `f64`. Numeric range (Slider, ProgressBar, SpinBox).
/// - `value` — `f64`. Initial numeric value (Slider, ProgressBar, SpinBox, Badge count).
/// - `checked` — `bool`. Initial check state (CheckBox).
/// - `on` — `bool`. Initial on/off state (Switch). Defaults to `false`.
/// - `visible` — `bool`. Initial visibility. Defaults to `true`.
/// - `enabled` — `bool`. Initial enabled state. Defaults to `true`.
/// - `placeholder` — `String`. Placeholder text for TextInput.
/// - `tooltip` — `String`. Tooltip text shown on hover.
/// - `direction` — `String`. `"horizontal"` or `"vertical"` for Layout widgets.
/// - `spacing` — `f32`. Child spacing for Layout widgets.
/// - `orientation` — `String`. `"horizontal"` or `"vertical"` for SplitPanel,
///   Toolbar, ScrollBar, and Separator.
/// - `group` — `String`. Radio button group name for RadioButton widgets.
/// - `children` — `Vec<WidgetDef>`. Nested child widget descriptors.
#[derive(Debug, Clone, Deserialize, Default)]
pub struct WidgetDef {
    /// Case-insensitive widget kind identifier.
    pub widget_type: String,
    /// Optional identifier for `find_by_id`.
    pub id: Option<String>,
    /// X position relative to the parent in pixels.
    pub x: Option<f32>,
    /// Y position relative to the parent in pixels.
    pub y: Option<f32>,
    /// Widget width in pixels. `0.0` = auto.
    pub w: Option<f32>,
    /// Widget height in pixels. `0.0` = auto.
    pub h: Option<f32>,
    /// Display or label text.
    pub text: Option<String>,
    /// Minimum numeric value (Slider, ProgressBar, SpinBox).
    pub min: Option<f64>,
    /// Maximum numeric value (Slider, ProgressBar, SpinBox).
    pub max: Option<f64>,
    /// Initial numeric value (Slider, ProgressBar, SpinBox, Badge count).
    pub value: Option<f64>,
    /// Initial check state (CheckBox).
    pub checked: Option<bool>,
    /// Initial on/off state for Switch.
    pub on: Option<bool>,
    /// Initial visibility. `true` when absent.
    pub visible: Option<bool>,
    /// Initial enabled state. `true` when absent.
    pub enabled: Option<bool>,
    /// Placeholder hint text for TextInput.
    pub placeholder: Option<String>,
    /// Tooltip text shown on hover.
    pub tooltip: Option<String>,
    /// Layout direction for Layout widgets: `"horizontal"` or `"vertical"`.
    pub direction: Option<String>,
    /// Child spacing in pixels for Layout widgets.
    pub spacing: Option<f32>,
    /// Orientation for SplitPanel, Toolbar, ScrollBar, Separator.
    pub orientation: Option<String>,
    /// Radio button group name for RadioButton widgets.
    pub group: Option<String>,
    /// Nested child widget descriptors.
    pub children: Option<Vec<WidgetDef>>,
}

/// Top-level TOML layout descriptor.
///
/// A TOML layout file must contain a `[root]` section holding a `WidgetDef`.
/// The optional `resolution` key declares the canvas size as `[width, height]`.
/// When absent the canvas defaults to `root.w` × `root.h`, then falls back to
/// 1280 × 720. The `resolution` field is used by the headless PNG renderer
/// (`tools/ui/render_layout.py`) to set the output image size.
///
/// # Example
///
/// ```toml
/// resolution = [1280, 720]
///
/// [root]
/// widget_type = "panel"
/// w = 1280.0
/// h = 720.0
///
/// [[root.children]]
/// widget_type = "label"
/// text = "Score: 0"
/// id = "score_label"
/// x = 10.0
/// y = 10.0
/// w = 200.0
/// h = 30.0
///
/// [[root.children]]
/// widget_type = "button"
/// text = "Play"
/// id = "play_btn"
/// x = 10.0
/// y = 50.0
/// w = 100.0
/// h = 32.0
/// ```
///
/// # Fields
///
/// - `resolution` — `[u32; 2]`. Optional `[width, height]` canvas size in pixels.
///   Overrides `root.w` / `root.h` for the PNG render pass.
/// - `root` — `WidgetDef`. Root widget definition.
#[derive(Debug, Deserialize)]
pub struct LayoutDef {
    /// Optional explicit canvas resolution `[width, height]` in pixels.
    /// Used by `tools/ui/render_layout.py` and `render_to_image`.
    pub resolution: Option<[u32; 2]>,
    /// Root widget definition for the layout.
    pub root: WidgetDef,
}

// ── Public functions ──────────────────────────────────────────────────────────

/// Recursively build a widget tree inside `ctx` from a `WidgetDef` descriptor.
///
/// Creates a widget of the type given by `def.widget_type`, applies all
/// specified properties, then recurses into `def.children`, attaching each
/// child to the newly created parent widget.
///
/// The created root widget is **not** automatically attached to the global
/// root (pool index 0); the caller must call `ctx.add_child(0, root_idx)`
/// when the widget should be part of the rendered tree.
///
/// # Parameters
///
/// - `ctx` — `&mut GuiContext`. UI context to populate.
/// - `def` — `&WidgetDef`. Widget descriptor to evaluate.
///
/// # Returns
///
/// Pool index of the newly created root widget on success, or `Err(String)`
/// if `def.widget_type` is not a recognised type string.
pub fn load_layout_def(ctx: &mut GuiContext, def: &WidgetDef) -> Result<usize, String> {
    let idx = create_from_def(ctx, def)?;

    if let Some(children) = &def.children {
        for child_def in children {
            let child_idx = load_layout_def(ctx, child_def)?;
            ctx.add_child(idx, child_idx);
        }
    }

    Ok(idx)
}

/// Parse TOML source text conforming to the `LayoutDef` schema and build the
/// described widget tree in `ctx`.
///
/// Convenience wrapper combining `toml::from_str::<LayoutDef>` and
/// [`load_layout_def`].
///
/// # Parameters
///
/// - `ctx` — `&mut GuiContext`. UI context to populate.
/// - `toml_src` — `&str`. UTF-8 TOML source text.
///
/// # Returns
///
/// Pool index of the root widget on success, or `Err(String)` on a TOML
/// parse error or an unknown widget type.
pub fn load_layout_toml(ctx: &mut GuiContext, toml_src: &str) -> Result<usize, String> {
    let layout_def: LayoutDef =
        toml::from_str(toml_src).map_err(|e| format!("TOML parse error: {e}"))?;
    load_layout_def(ctx, &layout_def.root)
}

/// Software-render the widget tree in `ctx` to a PNG file.
///
/// Runs the layout pass to compute `computed_rect` values for all widgets,
/// then draws each visible widget's bounding rectangle onto an RGBA pixel
/// buffer using a per-widget-type representative fill colour. The result is
/// saved as a PNG file at `path` via the `image` crate.
///
/// This function is **headless-safe** — it has no dependency on wgpu, winit,
/// or any GPU resource, making it suitable for evidence and golden tests.
///
/// Text is not rendered; only filled widget bounding boxes are drawn. Use the
/// output to verify that the layout tree was built and positioned correctly.
///
/// # Parameters
///
/// - `ctx` — `&mut GuiContext`. UI context whose widget tree is rendered.
/// - `width` — `u32`. Output image width in pixels.
/// - `height` — `u32`. Output image height in pixels.
/// - `path` — `&str`. Destination file path for the PNG.
///
/// # Returns
///
/// `Ok(())` on success, or `Err(String)` if the PNG file could not be written.
pub fn render_to_image(
    ctx: &mut GuiContext,
    width: u32,
    height: u32,
    path: &str,
) -> Result<(), String> {
    ctx.set_viewport(width as f32, height as f32);
    ctx.run_layout_pass();

    // Initialise RGBA buffer to dark charcoal background.
    let pixel_count = (width * height) as usize;
    let mut pixels: Vec<u8> = Vec::with_capacity(pixel_count * 4);
    for _ in 0..pixel_count {
        pixels.extend_from_slice(&[30u8, 30u8, 30u8, 255u8]);
    }

    // Draw each visible widget. Index 0 is the invisible root — skip it.
    for idx in 1..ctx.widgets.len() {
        let base = ctx.widgets[idx].base();
        if !base.is_visible {
            continue;
        }
        let rect = base.computed_rect;
        if rect.width <= 0.0 || rect.height <= 0.0 {
            continue;
        }
        let color = widget_kind_color(&ctx.widgets[idx]);
        fill_rect(&mut pixels, width, height, &rect, color);
    }

    image::save_buffer(path, &pixels, width, height, image::ColorType::Rgba8)
        .map_err(|e| format!("render_to_image: failed to save '{path}': {e}"))
}

// ── Private helpers ───────────────────────────────────────────────────────────

/// Create a single widget in `ctx` from `def` and apply all specified base
/// properties. Does **not** process children.
///
/// # Parameters
///
/// - `ctx` — `&mut GuiContext`.
/// - `def` — `&WidgetDef`.
///
/// # Returns
///
/// Pool index of the new widget, or `Err(String)` for an unknown type.
fn create_from_def(ctx: &mut GuiContext, def: &WidgetDef) -> Result<usize, String> {
    let widget_type = def.widget_type.to_lowercase();

    let idx = match widget_type.as_str() {
        "button" => ctx.add_button(def.text.clone().unwrap_or_default()),
        "label" => ctx.add_label(def.text.clone().unwrap_or_default()),
        "textinput" => ctx.add_text_input(),
        "checkbox" => ctx.add_checkbox(def.text.clone().unwrap_or_default()),
        "slider" => ctx.add_slider(def.min.unwrap_or(0.0), def.max.unwrap_or(1.0)),
        "progressbar" => ctx.add_progress_bar(def.min.unwrap_or(0.0), def.max.unwrap_or(1.0)),
        "combobox" => ctx.add_combo_box(),
        "listbox" => ctx.add_list_box(),
        "panel" => ctx.add_panel(),
        "layout" => {
            let dir = def
                .direction
                .as_deref()
                .and_then(crate::ui::LayoutDirection::parse_str)
                .unwrap_or(crate::ui::LayoutDirection::Vertical);
            ctx.add_layout(dir)
        }
        "scrollpanel" => ctx.add_scroll_panel(),
        "ninepatch" => ctx.add_nine_patch(),
        "tabbar" => ctx.add_tab_bar(),
        "separator" => {
            let vertical = def
                .orientation
                .as_deref()
                .map(|s| s.eq_ignore_ascii_case("vertical"))
                .unwrap_or(false);
            ctx.add_separator(vertical)
        }
        "spacer" => ctx.add_spacer(def.w.unwrap_or(0.0), def.h.unwrap_or(0.0)),
        "treeview" => ctx.add_tree_view(),
        "radiobutton" => ctx.add_radio_button(
            def.text.clone().unwrap_or_default(),
            def.group.clone().unwrap_or_default(),
        ),
        "scrollbar" => {
            let vertical = def
                .orientation
                .as_deref()
                .map(|s| !s.eq_ignore_ascii_case("horizontal"))
                .unwrap_or(true);
            ctx.add_scroll_bar(vertical)
        }
        "guiwindow" => ctx.add_gui_window(def.text.clone().unwrap_or_default()),
        "splitpanel" => ctx.add_split_panel(
            def.orientation
                .clone()
                .unwrap_or_else(|| "horizontal".to_string()),
        ),
        "dockpanel" => ctx.add_dock_panel(),
        "toolbar" => ctx.add_toolbar(
            def.orientation
                .clone()
                .unwrap_or_else(|| "horizontal".to_string()),
        ),
        "menubar" => ctx.add_menu_bar(),
        "menuitem" => ctx.add_menu_item(def.text.clone().unwrap_or_default()),
        "dialog" => ctx.add_dialog(def.text.clone().unwrap_or_default()),
        "statusbar" => ctx.add_status_bar(),
        "accordion" => ctx.add_accordion(),
        "tooltippanel" => ctx.add_tooltip_panel(def.text.clone().unwrap_or_default()),
        "colorpicker" => ctx.add_color_picker(),
        "guitable" => ctx.add_gui_table(),
        "imagewidget" => ctx.add_image_widget(),
        "spinbox" => ctx.add_spin_box(def.min.unwrap_or(0.0), def.max.unwrap_or(100.0)),
        "switch" => ctx.add_switch(def.on.unwrap_or(false)),
        "badge" => ctx.add_badge(def.value.map(|v| v as u32).unwrap_or(0)),
        unknown => return Err(format!("Unknown widget type: \"{unknown}\"")),
    };

    apply_base_props(ctx, idx, def);
    Ok(idx)
}

/// Apply shared base properties from `def` to the widget at pool index `idx`.
///
/// Writes to `WidgetBase` fields (position, size, id, visibility, tooltip)
/// and to any widget-type-specific fields (value, checked state, placeholder).
///
/// # Parameters
///
/// - `ctx` — `&mut GuiContext`.
/// - `idx` — `usize`. Widget pool index.
/// - `def` — `&WidgetDef`. Source of property values.
fn apply_base_props(ctx: &mut GuiContext, idx: usize, def: &WidgetDef) {
    // ── WidgetBase ─────────────────────────────────────────────────────
    if let Some(w) = ctx.widgets.get_mut(idx) {
        let base = w.base_mut();
        if let Some(x) = def.x {
            base.x = x;
        }
        if let Some(y) = def.y {
            base.y = y;
        }
        if let Some(wv) = def.w {
            base.width = wv;
        }
        if let Some(h) = def.h {
            base.height = h;
        }
        if let Some(ref id) = def.id {
            base.id = id.clone();
        }
        if let Some(vis) = def.visible {
            base.visible = vis;
        }
        if let Some(en) = def.enabled {
            base.enabled = en;
        }
        if let Some(ref tt) = def.tooltip {
            base.tooltip = tt.clone();
        }
    }

    // ── Widget-type-specific fields ────────────────────────────────────
    match ctx.widgets.get_mut(idx) {
        Some(WidgetKind::Slider(sl)) => {
            if let Some(v) = def.value {
                sl.value = v as f32;
            }
        }
        Some(WidgetKind::ProgressBar(pb)) => {
            if let Some(v) = def.value {
                pb.value = v as f32;
            }
        }
        Some(WidgetKind::SpinBox(sb)) => {
            if let Some(v) = def.value {
                sb.value = v;
            }
        }
        Some(WidgetKind::CheckBox(cb)) => {
            if let Some(c) = def.checked {
                cb.checked = c;
            }
        }
        Some(WidgetKind::Switch(sw)) => {
            if let Some(o) = def.on {
                sw.on = o;
            }
        }
        Some(WidgetKind::TextInput(ti)) => {
            if let Some(ref p) = def.placeholder {
                ti.placeholder = p.clone();
            }
            if let Some(ref t) = def.text {
                ti.text = t.clone();
            }
        }
        Some(WidgetKind::Layout(lay)) => {
            if let Some(sp) = def.spacing {
                lay.spacing = sp;
            }
        }
        _ => {}
    }
}

/// Map a `WidgetKind` variant to a representative RGBA fill colour.
///
/// Used by the headless software rasteriser in [`render_to_image`] to colour
/// widget bounding boxes according to their type.
///
/// # Parameters
///
/// - `kind` — `&WidgetKind`. Variant to look up.
///
/// # Returns
///
/// `[u8; 4]` — RGBA colour bytes.
fn widget_kind_color(kind: &WidgetKind) -> [u8; 4] {
    match kind {
        WidgetKind::Panel(_) => [60, 60, 70, 200],
        WidgetKind::Button(_) => [70, 120, 200, 255],
        WidgetKind::Label(_) => [200, 200, 200, 180],
        WidgetKind::TextInput(_) => [240, 240, 240, 255],
        WidgetKind::CheckBox(_) => [180, 140, 60, 255],
        WidgetKind::Slider(_) => [80, 160, 80, 255],
        WidgetKind::ProgressBar(_) => [60, 160, 100, 255],
        WidgetKind::ComboBox(_) => [140, 100, 180, 255],
        WidgetKind::ListBox(_) => [100, 130, 160, 255],
        WidgetKind::Layout(_) => [50, 50, 80, 120],
        WidgetKind::ScrollPanel(_) => [70, 80, 90, 200],
        WidgetKind::TabBar(_) => [90, 90, 140, 255],
        WidgetKind::Separator(_) => [120, 120, 120, 255],
        WidgetKind::Spacer(_) => [30, 30, 30, 0],
        WidgetKind::ImageWidget(_) => [100, 140, 180, 255],
        WidgetKind::NinePatch(_) => [80, 120, 140, 255],
        WidgetKind::SplitPanel(_) => [55, 65, 75, 200],
        WidgetKind::DockPanel(_) => [50, 60, 80, 200],
        WidgetKind::Accordion(_) => [110, 80, 140, 255],
        WidgetKind::TreeView(_) => [70, 130, 100, 255],
        WidgetKind::RadioButton(_) => [180, 90, 90, 255],
        WidgetKind::SpinBox(_) => [160, 120, 80, 255],
        WidgetKind::Switch(_) => [80, 160, 140, 255],
        WidgetKind::ColorPicker(_) => [200, 100, 100, 255],
        WidgetKind::GUITable(_) => [90, 110, 130, 255],
        WidgetKind::GUIWindow(_) => [60, 70, 100, 230],
        WidgetKind::Dialog(_) => [70, 80, 120, 240],
        WidgetKind::MenuBar(_) => [50, 50, 60, 255],
        WidgetKind::StatusBar(_) => [50, 50, 60, 255],
        WidgetKind::Toolbar(_) => [55, 55, 70, 255],
        WidgetKind::ScrollBar(_) => [90, 90, 110, 255],
        WidgetKind::Badge(_) => [220, 60, 60, 255],
        WidgetKind::TooltipPanel(_) => [200, 200, 150, 220],
        WidgetKind::MenuItem(_) => [80, 90, 100, 255],
        WidgetKind::Toast(_) => [160, 120, 60, 220],
    }
}

/// Alpha-blend a filled rectangle onto the RGBA pixel buffer.
///
/// Pixels outside the image boundaries are silently skipped. The blend
/// formula is: `out = (src * alpha + dst * (255 - alpha)) / 255`.
///
/// # Parameters
///
/// - `pixels` — `&mut Vec<u8>`. RGBA pixel buffer in row-major order.
/// - `img_w` — `u32`. Image width in pixels.
/// - `img_h` — `u32`. Image height in pixels.
/// - `rect` — `&crate::math::Rect`. Rectangle in image-space pixels.
/// - `color` — `[u8; 4]`. RGBA fill colour.
fn fill_rect(
    pixels: &mut Vec<u8>,
    img_w: u32,
    img_h: u32,
    rect: &crate::math::Rect,
    color: [u8; 4],
) {
    let src_a = color[3] as u32;
    if src_a == 0 {
        return;
    }
    let x0 = rect.x.max(0.0) as u32;
    let y0 = rect.y.max(0.0) as u32;
    let x1 = (rect.x + rect.width).min(img_w as f32) as u32;
    let y1 = (rect.y + rect.height).min(img_h as f32) as u32;

    for y in y0..y1 {
        for x in x0..x1 {
            let off = ((y * img_w + x) * 4) as usize;
            if off + 3 >= pixels.len() {
                continue;
            }
            let dst_a = 255u32 - src_a;
            pixels[off] =
                ((color[0] as u32 * src_a + pixels[off] as u32 * dst_a) / 255) as u8;
            pixels[off + 1] =
                ((color[1] as u32 * src_a + pixels[off + 1] as u32 * dst_a) / 255) as u8;
            pixels[off + 2] =
                ((color[2] as u32 * src_a + pixels[off + 2] as u32 * dst_a) / 255) as u8;
            pixels[off + 3] = 255;
        }
    }
}
