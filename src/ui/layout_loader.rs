use crate::ui::context::{GuiContext, WidgetKind};
use serde::Deserialize;
#[derive(Debug, Clone, Deserialize, Default)]
pub struct WidgetDef {
    pub widget_type: String,
    pub id: Option<String>,
    pub x: Option<f32>,
    pub y: Option<f32>,
    pub w: Option<f32>,
    pub h: Option<f32>,
    pub text: Option<String>,
    pub min: Option<f64>,
    pub max: Option<f64>,
    pub value: Option<f64>,
    pub checked: Option<bool>,
    pub on: Option<bool>,
    pub visible: Option<bool>,
    pub enabled: Option<bool>,
    pub placeholder: Option<String>,
    pub tooltip: Option<String>,
    pub direction: Option<String>,
    pub spacing: Option<f32>,
    pub orientation: Option<String>,
    pub group: Option<String>,
    pub children: Option<Vec<WidgetDef>>,
}
#[derive(Debug, Deserialize)]
pub struct LayoutDef {
    pub resolution: Option<[u32; 2]>,
    pub root: WidgetDef,
}
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
pub fn load_layout_toml(ctx: &mut GuiContext, toml_src: &str) -> Result<usize, String> {
    let layout_def: LayoutDef =
        toml::from_str(toml_src).map_err(|e| format!("TOML parse error: {e}"))?;
    load_layout_def(ctx, &layout_def.root)
}
pub fn render_to_image(
    ctx: &mut GuiContext,
    width: u32,
    height: u32,
    path: &str,
) -> Result<(), String> {
    ctx.set_viewport(width as f32, height as f32);
    ctx.run_layout_pass();
    let pixel_count = (width * height) as usize;
    let mut pixels: Vec<u8> = Vec::with_capacity(pixel_count * 4);
    for _ in 0..pixel_count {
        pixels.extend_from_slice(&[30u8, 30u8, 30u8, 255u8]);
    }
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
        "listbox" | "list" => ctx.add_list_box(),
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
        "guiwindow" | "window" => ctx.add_gui_window(def.text.clone().unwrap_or_default()),
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
        "imagewidget" | "image" => ctx.add_image_widget(),
        "spinbox" => ctx.add_spin_box(def.min.unwrap_or(0.0), def.max.unwrap_or(100.0)),
        "switch" => ctx.add_switch(def.on.unwrap_or(false)),
        "badge" => ctx.add_badge(def.value.map(|v| v as u32).unwrap_or(0)),
        "custom" => ctx.add_custom_widget(),
        unknown => return Err(format!("Unknown widget type: \"{unknown}\"")),
    };
    apply_base_props(ctx, idx, def);
    Ok(idx)
}
fn apply_base_props(ctx: &mut GuiContext, idx: usize, def: &WidgetDef) {
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
    match ctx.widgets.get_mut(idx) {
        Some(WidgetKind::Slider(sl)) => {
            if let Some(v) = def.value {
                sl.value = v;
            }
        }
        Some(WidgetKind::ProgressBar(pb)) => {
            if let Some(v) = def.value {
                pb.value = v;
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
        WidgetKind::Custom(_) => [255, 200, 100, 200],
    }
}
#[allow(clippy::ptr_arg)]
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
            pixels[off] = ((color[0] as u32 * src_a + pixels[off] as u32 * dst_a) / 255) as u8;
            pixels[off + 1] =
                ((color[1] as u32 * src_a + pixels[off + 1] as u32 * dst_a) / 255) as u8;
            pixels[off + 2] =
                ((color[2] as u32 * src_a + pixels[off + 2] as u32 * dst_a) / 255) as u8;
            pixels[off + 3] = 255;
        }
    }
}
