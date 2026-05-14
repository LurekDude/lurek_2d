//! Widget render emit functions for `lurek.ui` — converts live `GuiContext` widget state into
//! `RenderCommand` streams and `ImageData` via `build_render_commands` and `draw_to_image`.
//! All per-widget drawing is done by private `emit_*` helpers; no GPU calls are made here.
//! Depends on `crate::render::renderer`, `crate::ui::context`, `crate::ui::theme`, and `crate::image`.

use crate::render::renderer::{DrawMode, GradientDirection, RenderCommand};
use crate::runtime::resource_keys::FontKey;
use crate::ui::context::{GuiContext, WidgetKind};
use crate::ui::theme::WidgetStyle;
use crate::ui::widget::WidgetBase;
/// Return the primary display text of text-bearing widget variants, or `None` for all others.
fn display_text(widget: &WidgetKind) -> Option<&str> {
    let text = match widget {
        WidgetKind::Button(w) => &w.text,
        WidgetKind::Label(w) => &w.text,
        WidgetKind::CheckBox(w) => &w.text,
        WidgetKind::RadioButton(w) => &w.text,
        WidgetKind::MenuItem(w) => &w.text,
        _ => return None,
    };
    if text.is_empty() {
        None
    } else {
        Some(text)
    }
}
/// Convert HSV in `[0.0, 1.0]` to 8-bit `(R, G, B)` using a six-sector conversion.
fn hsv_to_rgb(h: f32, s: f32, v: f32) -> (u8, u8, u8) {
    let h6 = (h * 6.0).rem_euclid(6.0);
    let i = h6 as u32;
    let f = h6 - i as f32;
    let p = v * (1.0 - s);
    let q = v * (1.0 - s * f);
    let t = v * (1.0 - s * (1.0 - f));
    let (r, g, b) = match i {
        0 => (v, t, p),
        1 => (q, v, p),
        2 => (p, v, t),
        3 => (p, q, v),
        4 => (t, p, v),
        _ => (v, p, q),
    };
    ((r * 255.0) as u8, (g * 255.0) as u8, (b * 255.0) as u8)
}
/// Recursively draw tree node `idx` and its expanded children into `img` as labelled rows; return next Y.
#[allow(clippy::too_many_arguments)]
fn draw_tree_nodes_cpu(
    nodes: &[crate::ui::extras::TreeNode],
    idx: usize,
    img: &mut crate::image::ImageData,
    x: i32,
    ry: i32,
    max_y: i32,
    row_h: i32,
    depth: i32,
    selected: Option<usize>,
    fg: [u8; 3],
) -> i32 {
    if ry + row_h > max_y {
        return ry;
    }
    let node = match nodes.get(idx) {
        Some(n) => n,
        None => return ry,
    };
    let indent = x + depth * 14 + 4;
    if selected == Some(idx) {
        img.draw_rect(x, ry, 9999, row_h as u32, 50, 85, 150, 180);
    }
    if !node.children.is_empty() {
        if node.expanded {
            img.draw_line(indent, ry + 4, indent + 6, ry + 4, fg[0], fg[1], fg[2], 200);
            img.draw_line(indent, ry + 4, indent + 3, ry + 8, fg[0], fg[1], fg[2], 200);
            img.draw_line(
                indent + 6,
                ry + 4,
                indent + 3,
                ry + 8,
                fg[0],
                fg[1],
                fg[2],
                200,
            );
        } else {
            img.draw_line(
                indent,
                ry + 3,
                indent,
                ry + row_h - 3,
                fg[0],
                fg[1],
                fg[2],
                200,
            );
            img.draw_line(
                indent,
                ry + 3,
                indent + 6,
                ry + row_h / 2,
                fg[0],
                fg[1],
                fg[2],
                200,
            );
            img.draw_line(
                indent,
                ry + row_h - 3,
                indent + 6,
                ry + row_h / 2,
                fg[0],
                fg[1],
                fg[2],
                200,
            );
        }
    }
    img.draw_label(
        &node.text,
        indent + 10,
        ry + (row_h - 7) / 2,
        fg[0],
        fg[1],
        fg[2],
    );
    let mut next_y = ry + row_h;
    if node.expanded {
        let children: Vec<usize> = node.children.clone();
        for child_idx in children {
            next_y = draw_tree_nodes_cpu(
                nodes,
                child_idx,
                img,
                x,
                next_y,
                max_y,
                row_h,
                depth + 1,
                selected,
                fg,
            );
        }
    }
    next_y
}
/// Emit a filled and optionally bordered background box for `base` using `style`.
fn emit_box(base: &WidgetBase, style: &WidgetStyle, cmds: &mut Vec<RenderCommand>) {
    let [br, bg, bb, ba] = style.bg_color;
    if let Some(color2) = style.gradient_end {
        if style.corner_radius <= 0.0 {
            cmds.push(RenderCommand::DrawGradientRect {
                x: base.x,
                y: base.y,
                w: base.width,
                h: base.height,
                color1: [br, bg, bb, ba],
                color2,
                direction: GradientDirection::Vertical,
            });
        } else {
            cmds.push(RenderCommand::SetColor(br, bg, bb, ba));
            cmds.push(RenderCommand::RoundedRectangle {
                mode: DrawMode::Fill,
                x: base.x,
                y: base.y,
                w: base.width,
                h: base.height,
                rx: style.corner_radius,
                ry: style.corner_radius,
            });
        }
    } else if style.corner_radius > 0.0 {
        cmds.push(RenderCommand::SetColor(br, bg, bb, ba));
        cmds.push(RenderCommand::RoundedRectangle {
            mode: DrawMode::Fill,
            x: base.x,
            y: base.y,
            w: base.width,
            h: base.height,
            rx: style.corner_radius,
            ry: style.corner_radius,
        });
    } else {
        cmds.push(RenderCommand::SetColor(br, bg, bb, ba));
        cmds.push(RenderCommand::Rectangle {
            mode: DrawMode::Fill,
            x: base.x,
            y: base.y,
            w: base.width,
            h: base.height,
        });
    }
    if style.border_width > 0.0 {
        let [cr, cg, cb, ca] = style.border_color;
        cmds.push(RenderCommand::SetColor(cr, cg, cb, ca));
        cmds.push(RenderCommand::SetLineWidth(style.border_width));
        if style.corner_radius > 0.0 {
            cmds.push(RenderCommand::RoundedRectangle {
                mode: DrawMode::Line,
                x: base.x,
                y: base.y,
                w: base.width,
                h: base.height,
                rx: style.corner_radius,
                ry: style.corner_radius,
            });
        } else {
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Line,
                x: base.x,
                y: base.y,
                w: base.width,
                h: base.height,
            });
        }
    }
}
/// Emit a centred or aligned `Print` command for `text` inside `base`.
fn emit_text(
    base: &WidgetBase,
    text: &str,
    style: &WidgetStyle,
    font_key: FontKey,
    cmds: &mut Vec<RenderCommand>,
) {
    let [fr, fg, fb, fa] = style.fg_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    let scale = style.font_size / 14.0;
    let approx_w = text.chars().count() as f32 * 6.0 * scale;
    let tx = match style.text_align.as_str() {
        "left" => base.x + base.padding[3] + 4.0,
        "right" => base.x + (base.width - approx_w - 6.0).max(0.0),
        _ => base.x + ((base.width - approx_w) * 0.5).max(2.0),
    };
    let ty = base.y + base.padding[0];
    cmds.push(RenderCommand::Print {
        font_key,
        text: text.to_string(),
        x: tx,
        y: ty,
        scale,
    });
}
/// Emit a shadow rectangle behind `base` when `style.shadow_color` alpha is non-zero.
fn emit_shadow(base: &WidgetBase, style: &WidgetStyle, cmds: &mut Vec<RenderCommand>) {
    let [sr, sg, sb, sa] = style.shadow_color;
    if sa <= 0.0 {
        return;
    }
    let [ox, oy] = style.shadow_offset;
    cmds.push(RenderCommand::SetColor(sr, sg, sb, sa));
    if style.corner_radius > 0.0 {
        cmds.push(RenderCommand::RoundedRectangle {
            mode: DrawMode::Fill,
            x: base.x + ox,
            y: base.y + oy,
            w: base.width,
            h: base.height,
            rx: style.corner_radius,
            ry: style.corner_radius,
        });
    } else {
        cmds.push(RenderCommand::Rectangle {
            mode: DrawMode::Fill,
            x: base.x + ox,
            y: base.y + oy,
            w: base.width,
            h: base.height,
        });
    }
}
/// Emit a top-edge highlight strip when `style.highlight_alpha > 0`.
fn emit_highlight(base: &WidgetBase, style: &WidgetStyle, cmds: &mut Vec<RenderCommand>) {
    if style.highlight_alpha <= 0.0 {
        return;
    }
    let a = style.highlight_alpha.clamp(0.0, 1.0);
    cmds.push(RenderCommand::SetColor(1.0, 1.0, 1.0, a));
    let strip_h = 2.0_f32.max(style.border_width);
    cmds.push(RenderCommand::Rectangle {
        mode: DrawMode::Fill,
        x: base.x + style.border_width,
        y: base.y + style.border_width,
        w: (base.width - style.border_width * 2.0).max(0.0),
        h: strip_h,
    });
}
/// Emit a filled progress track and circular thumb for a slider widget.
fn emit_slider(
    base: &WidgetBase,
    value: f64,
    min: f64,
    max: f64,
    style: &WidgetStyle,
    cmds: &mut Vec<RenderCommand>,
) {
    let range = (max - min).max(1e-6);
    let t = ((value - min) / range).clamp(0.0, 1.0) as f32;
    let fill_w = (base.width * t).max(0.0);
    let fill_color = style.gradient_end.unwrap_or(style.fg_color);
    let [fr, fg, fb, fa] = fill_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    if fill_w > 0.0 {
        cmds.push(RenderCommand::Rectangle {
            mode: DrawMode::Fill,
            x: base.x,
            y: base.y,
            w: fill_w,
            h: base.height,
        });
    }
    let thumb_cx = base.x + fill_w;
    let thumb_cy = base.y + base.height * 0.5;
    let thumb_r = (base.height * 0.5 - 1.0).max(2.0);
    cmds.push(RenderCommand::SetColor(1.0, 1.0, 1.0, 1.0));
    cmds.push(RenderCommand::Circle {
        mode: DrawMode::Fill,
        x: thumb_cx,
        y: thumb_cy,
        r: thumb_r,
    });
}
/// Emit a filled progress fill rectangle proportional to `value` in `[min, max]`.
fn emit_progress_bar(
    base: &WidgetBase,
    value: f64,
    min: f64,
    max: f64,
    style: &WidgetStyle,
    cmds: &mut Vec<RenderCommand>,
) {
    let range = (max - min).max(1e-6);
    let t = ((value - min) / range).clamp(0.0, 1.0) as f32;
    let fill_w = (base.width * t).max(0.0);
    if fill_w <= 0.0 {
        return;
    }
    let fill_color = style.gradient_end.unwrap_or(style.fg_color);
    let [fr, fg, fb, fa] = fill_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    cmds.push(RenderCommand::Rectangle {
        mode: DrawMode::Fill,
        x: base.x,
        y: base.y,
        w: fill_w,
        h: base.height,
    });
}
/// Emit a tick/check mark glyph inside the checkbox bounding box.
fn emit_checkbox(base: &WidgetBase, style: &WidgetStyle, cmds: &mut Vec<RenderCommand>) {
    let box_size = base.height.min(base.height);
    let cx = base.x + box_size * 0.5;
    let cy = base.y + box_size * 0.5;
    let s = box_size * 0.25;
    let [fr, fg, fb, fa] = style.fg_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    cmds.push(RenderCommand::SetLineWidth(2.0));
    cmds.push(RenderCommand::Line {
        x1: cx - s,
        y1: cy,
        x2: cx - s * 0.2,
        y2: cy + s,
    });
    cmds.push(RenderCommand::Line {
        x1: cx - s * 0.2,
        y1: cy + s,
        x2: cx + s,
        y2: cy - s,
    });
}
/// Emit a filled circle indicating a selected radio button.
fn emit_radio_button(base: &WidgetBase, style: &WidgetStyle, cmds: &mut Vec<RenderCommand>) {
    let r = (base.height * 0.5 - 3.0).max(2.0);
    let cx = base.x + base.height * 0.5;
    let cy = base.y + base.height * 0.5;
    let [fr, fg, fb, fa] = style.fg_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    cmds.push(RenderCommand::Circle {
        mode: DrawMode::Fill,
        x: cx,
        y: cy,
        r,
    });
}
/// Emit a downward-pointing triangle drop-arrow at the right edge of a combo box.
fn emit_combo_box_arrow(base: &WidgetBase, style: &WidgetStyle, cmds: &mut Vec<RenderCommand>) {
    let btn_w = base.height;
    let ax = base.x + base.width - btn_w * 0.5;
    let ay = base.y + base.height * 0.5;
    let s = 5.0_f32;
    let [fr, fg, fb, fa] = style.fg_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    cmds.push(RenderCommand::Triangle {
        mode: DrawMode::Fill,
        x1: ax - s,
        y1: ay - s * 0.5,
        x2: ax + s,
        y2: ay - s * 0.5,
        x3: ax,
        y3: ay + s * 0.5,
    });
}
/// Emit a proportional rounded-rect scroll thumb inside the scroll bar track.
fn emit_scroll_bar(
    base: &WidgetBase,
    position: f32,
    content_size: f32,
    view_size: f32,
    vertical: bool,
    style: &WidgetStyle,
    cmds: &mut Vec<RenderCommand>,
) {
    let safe_content = content_size.max(1.0);
    let thumb_ratio = (view_size / safe_content).clamp(0.1, 1.0);
    let scroll_ratio = (position / (safe_content - view_size).max(1.0)).clamp(0.0, 1.0);
    let [fr, fg, fb, fa] = style.fg_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    if vertical {
        let track_h = base.height;
        let thumb_h = track_h * thumb_ratio;
        let thumb_y = base.y + (track_h - thumb_h) * scroll_ratio;
        cmds.push(RenderCommand::RoundedRectangle {
            mode: DrawMode::Fill,
            x: base.x + 2.0,
            y: thumb_y,
            w: base.width - 4.0,
            h: thumb_h,
            rx: (base.width - 4.0) * 0.5,
            ry: (base.width - 4.0) * 0.5,
        });
    } else {
        let track_w = base.width;
        let thumb_w = track_w * thumb_ratio;
        let thumb_x = base.x + (track_w - thumb_w) * scroll_ratio;
        cmds.push(RenderCommand::RoundedRectangle {
            mode: DrawMode::Fill,
            x: thumb_x,
            y: base.y + 2.0,
            w: thumb_w,
            h: base.height - 4.0,
            rx: (base.height - 4.0) * 0.5,
            ry: (base.height - 4.0) * 0.5,
        });
    }
}
/// Emit up/down arrow triangles at the left and right edges of a spin box.
fn emit_spin_box(base: &WidgetBase, style: &WidgetStyle, cmds: &mut Vec<RenderCommand>) {
    let btn_w = base.height;
    let mid_y = base.y + base.height * 0.5;
    let s = 4.0_f32;
    let [fr, fg, fb, fa] = style.fg_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    cmds.push(RenderCommand::Triangle {
        mode: DrawMode::Fill,
        x1: base.x + btn_w * 0.5 - s,
        y1: mid_y - s * 0.5,
        x2: base.x + btn_w * 0.5 + s,
        y2: mid_y - s * 0.5,
        x3: base.x + btn_w * 0.5,
        y3: mid_y + s * 0.5,
    });
    let rx = base.x + base.width - btn_w * 0.5;
    cmds.push(RenderCommand::Triangle {
        mode: DrawMode::Fill,
        x1: rx - s,
        y1: mid_y + s * 0.5,
        x2: rx + s,
        y2: mid_y + s * 0.5,
        x3: rx,
        y3: mid_y - s * 0.5,
    });
}
/// Emit a rounded track and interpolated thumb for a toggle switch; `thumb_t` is the thumb position in `[0.0, 1.0]`.
fn emit_switch(
    base: &WidgetBase,
    on: bool,
    thumb_t: f32,
    style: &WidgetStyle,
    cmds: &mut Vec<RenderCommand>,
) {
    let [tr, tg, tb, ta] = if on {
        style.gradient_end.unwrap_or([0.20, 0.55, 0.30, 1.0])
    } else {
        [0.35, 0.35, 0.42, 1.0]
    };
    cmds.push(RenderCommand::SetColor(tr, tg, tb, ta));
    cmds.push(RenderCommand::RoundedRectangle {
        mode: DrawMode::Fill,
        x: base.x,
        y: base.y,
        w: base.width,
        h: base.height,
        rx: base.height * 0.5,
        ry: base.height * 0.5,
    });
    let t = thumb_t.clamp(0.0, 1.0);
    let thumb_r = (base.height * 0.5 - 2.0).max(2.0);
    let thumb_cx = base.x + thumb_r + 2.0 + (base.width - (thumb_r + 2.0) * 2.0).max(0.0) * t;
    let thumb_cy = base.y + base.height * 0.5;
    cmds.push(RenderCommand::SetColor(1.0, 1.0, 1.0, 1.0));
    cmds.push(RenderCommand::Circle {
        mode: DrawMode::Fill,
        x: thumb_cx,
        y: thumb_cy,
        r: thumb_r,
    });
}
/// Emit the display text of a badge centred inside its bounding box.
fn emit_badge(
    base: &WidgetBase,
    text: &str,
    font_key: FontKey,
    style: &WidgetStyle,
    cmds: &mut Vec<RenderCommand>,
) {
    let [fr, fg, fb, fa] = style.fg_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    let scale = style.font_size / 14.0;
    let tx = base.x + base.width * 0.5;
    let ty = base.y + (base.height - style.font_size) * 0.5;
    cmds.push(RenderCommand::Print {
        font_key,
        text: text.to_string(),
        x: tx,
        y: ty,
        scale,
    });
}
/// Emit a `Print` command at an explicit `(x, y)` position, bypassing widget padding.
fn emit_text_at(
    text: &str,
    x: f32,
    y: f32,
    font_key: FontKey,
    style: &WidgetStyle,
    cmds: &mut Vec<RenderCommand>,
) {
    let [fr, fg, fb, fa] = style.fg_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));
    cmds.push(RenderCommand::Print {
        font_key,
        text: text.to_string(),
        x,
        y,
        scale: style.font_size / 14.0,
    });
}
/// Temporary borrowed context passed through recursive `emit_tree_nodes` calls.
struct TreeCtx<'a> {
    /// Flat node list owned by the `TreeView`.
    nodes: &'a [crate::ui::extras::TreeNode],
    /// Currently selected node index, if any.
    selected: Option<usize>,
    /// Font key used to print node labels.
    font_key: FontKey,
    /// Active widget style for colour selection.
    style: &'a WidgetStyle,
    /// Output command buffer.
    cmds: &'a mut Vec<RenderCommand>,
}
/// Recursively emit tree node `idx` and its expanded children as indented rows; return next Y position.
fn emit_tree_nodes(
    ctx: &mut TreeCtx<'_>,
    idx: usize,
    x: f32,
    mut y: f32,
    row_h: f32,
    depth: usize,
) -> f32 {
    let Some(node) = ctx.nodes.get(idx) else {
        return y;
    };
    let indent = x + depth as f32 * 14.0 + 4.0;
    if ctx.selected == Some(idx) {
        ctx.cmds
            .push(RenderCommand::SetColor(0.22, 0.36, 0.60, 0.80));
        ctx.cmds.push(RenderCommand::Rectangle {
            mode: DrawMode::Fill,
            x,
            y,
            w: 9999.0,
            h: row_h,
        });
    }
    if !node.children.is_empty() {
        ctx.cmds
            .push(RenderCommand::SetColor(0.88, 0.90, 0.94, 0.90));
        if node.expanded {
            ctx.cmds.push(RenderCommand::Line {
                x1: indent,
                y1: y + 4.0,
                x2: indent + 6.0,
                y2: y + 4.0,
            });
            ctx.cmds.push(RenderCommand::Line {
                x1: indent,
                y1: y + 4.0,
                x2: indent + 3.0,
                y2: y + 8.0,
            });
            ctx.cmds.push(RenderCommand::Line {
                x1: indent + 6.0,
                y1: y + 4.0,
                x2: indent + 3.0,
                y2: y + 8.0,
            });
        } else {
            ctx.cmds.push(RenderCommand::Line {
                x1: indent,
                y1: y + 3.0,
                x2: indent,
                y2: y + row_h - 3.0,
            });
            ctx.cmds.push(RenderCommand::Line {
                x1: indent,
                y1: y + 3.0,
                x2: indent + 6.0,
                y2: y + row_h * 0.5,
            });
            ctx.cmds.push(RenderCommand::Line {
                x1: indent,
                y1: y + row_h - 3.0,
                x2: indent + 6.0,
                y2: y + row_h * 0.5,
            });
        }
    }
    emit_text_at(
        &node.text,
        indent + 10.0,
        y + (row_h - ctx.style.font_size) * 0.5,
        ctx.font_key,
        ctx.style,
        ctx.cmds,
    );
    y += row_h;
    if node.expanded {
        let children = node.children.clone();
        for child_idx in children {
            y = emit_tree_nodes(ctx, child_idx, x, y, row_h, depth + 1);
        }
    }
    y
}
/// Collect all child indices that should be rendered for `widget`, merging `children()` and type-specific slots.
fn widget_render_children(widget: &WidgetKind) -> Vec<usize> {
    let mut children = widget.children().cloned().unwrap_or_default();
    match widget {
        WidgetKind::MenuBar(w) => children.extend(w.menus.iter().copied()),
        WidgetKind::MenuItem(w) => children.extend(w.items.iter().copied()),
        WidgetKind::Dialog(w) => {
            if let Some(child) = w.content_idx {
                children.push(child);
            }
        }
        WidgetKind::Accordion(w) => {
            for section in &w.sections {
                if let Some(child) = section.content_idx {
                    children.push(child);
                }
            }
        }
        WidgetKind::SplitPanel(w) => {
            if let Some(child) = w.first_child {
                children.push(child);
            }
            if let Some(child) = w.second_child {
                children.push(child);
            }
        }
        WidgetKind::DockPanel(w) => {
            children.extend(w.docked.iter().map(|(child, _)| *child));
        }
        _ => {}
    }
    children.sort_unstable();
    children.dedup();
    children
}
/// Look up `base`'s theme style, then scale all alpha channels by `base.alpha`.
fn resolve_style_with_alpha(
    ctx: &GuiContext,
    base: &WidgetBase,
    default_style: &WidgetStyle,
) -> WidgetStyle {
    let style = ctx
        .theme
        .as_ref()
        .and_then(|t| t.get_style(base.widget_type, base.state))
        .unwrap_or(default_style);
    let mut style_with_alpha = style.clone();
    let alpha = base.alpha.clamp(0.0, 1.0);
    style_with_alpha.bg_color[3] *= alpha;
    style_with_alpha.fg_color[3] *= alpha;
    style_with_alpha.border_color[3] *= alpha;
    style_with_alpha.shadow_color[3] *= alpha;
    style_with_alpha.highlight_alpha *= alpha;
    style_with_alpha
}
/// Temporary borrow-carrier used to thread `ctx`, font, and output buffer through widget rendering.
struct WidgetRenderer<'a> {
    /// Shared GUI context providing widget list and theme.
    ctx: &'a GuiContext,
    /// Font key passed to all text-emit helpers.
    font_key: FontKey,
    /// Fallback widget style used when the theme has no entry for a widget type.
    default_style: &'a WidgetStyle,
    /// Output command buffer accumulated during a render pass.
    cmds: &'a mut Vec<RenderCommand>,
}
impl<'a> WidgetRenderer<'a> {
    /// Create a renderer borrowing `ctx`, `font_key`, `default_style`, and output `cmds`.
    fn new(
        ctx: &'a GuiContext,
        font_key: FontKey,
        default_style: &'a WidgetStyle,
        cmds: &'a mut Vec<RenderCommand>,
    ) -> Self {
        Self {
            ctx,
            font_key,
            default_style,
            cmds,
        }
    }
    /// Render the widget at `idx` by delegating to the free `render_widget` function.
    fn render_widget(&mut self, idx: usize) {
        render_widget(self.ctx, idx, self.font_key, self.default_style, self.cmds);
    }
    /// Render all immediate children of the root widget (index 0).
    fn render_root_children(&mut self) {
        if let Some(children) = self.ctx.widgets.first().and_then(|w| w.children()) {
            for &child_idx in children {
                if child_idx < self.ctx.widgets.len() {
                    self.render_widget(child_idx);
                }
            }
        }
    }
}
/// Emit all `RenderCommand`s for the widget at `idx` and its visible descendants, using `font_key` and `default_style`.
fn render_widget(
    ctx: &GuiContext,
    idx: usize,
    font_key: FontKey,
    default_style: &WidgetStyle,
    cmds: &mut Vec<RenderCommand>,
) {
    let widget = &ctx.widgets[idx];
    let base = widget.base();
    if !base.visible {
        return;
    }
    let style_with_alpha = resolve_style_with_alpha(ctx, base, default_style);
    let style = &style_with_alpha;
    emit_shadow(base, style, cmds);
    emit_box(base, style, cmds);
    if style.highlight_alpha > 0.0 {
        emit_highlight(base, style, cmds);
    }
    match widget {
        WidgetKind::Slider(w) => {
            emit_slider(base, w.value, w.min, w.max, style, cmds);
        }
        WidgetKind::SpinBox(w) => {
            emit_progress_bar(base, w.value, w.min, w.max, style, cmds);
            emit_spin_box(base, style, cmds);
            emit_text_at(
                &format!("{}", w.value),
                base.x + 8.0,
                base.y + (base.height - style.font_size) * 0.5,
                font_key,
                style,
                cmds,
            );
        }
        WidgetKind::ProgressBar(w) => {
            emit_progress_bar(base, w.value, w.min, w.max, style, cmds);
            let range = (w.max - w.min).max(1e-6);
            let pct = (((w.value - w.min) / range).clamp(0.0, 1.0) * 100.0).round() as i32;
            emit_text_at(
                &format!("{pct}%"),
                base.x + (base.width - 24.0) * 0.5,
                base.y + (base.height - style.font_size) * 0.5,
                font_key,
                style,
                cmds,
            );
        }
        WidgetKind::CheckBox(w) => {
            if w.checked {
                emit_checkbox(base, style, cmds);
            }
            if !w.text.is_empty() {
                emit_text_at(
                    &w.text,
                    base.x + base.height + 6.0,
                    base.y + (base.height - style.font_size) * 0.5,
                    font_key,
                    style,
                    cmds,
                );
            }
        }
        WidgetKind::RadioButton(w) => {
            if w.selected {
                emit_radio_button(base, style, cmds);
            }
            if !w.text.is_empty() {
                emit_text_at(
                    &w.text,
                    base.x + base.height + 6.0,
                    base.y + (base.height - style.font_size) * 0.5,
                    font_key,
                    style,
                    cmds,
                );
            }
        }
        WidgetKind::TextInput(w) => {
            let content = if w.text.is_empty() {
                w.placeholder.as_str()
            } else {
                w.text.as_str()
            };
            if !content.is_empty() {
                let [tr, tg, tb, ta] = if w.text.is_empty() {
                    [0.55, 0.57, 0.64, 1.0]
                } else {
                    style.fg_color
                };
                let mut text_style = style.clone();
                text_style.fg_color = [tr, tg, tb, ta];
                emit_text_at(
                    content,
                    base.x + base.padding[3] + 4.0,
                    base.y + (base.height - style.font_size) * 0.5,
                    font_key,
                    &text_style,
                    cmds,
                );
            }
            if w.focused {
                let cursor_x = base.x
                    + base.padding[3]
                    + 4.0
                    + w.cursor_pos.min(w.text.len()) as f32 * 6.0 * (style.font_size / 14.0);
                cmds.push(RenderCommand::SetColor(
                    style.fg_color[0],
                    style.fg_color[1],
                    style.fg_color[2],
                    0.9,
                ));
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: cursor_x,
                    y: base.y + 3.0,
                    w: 1.0,
                    h: (base.height - 6.0).max(0.0),
                });
            }
        }
        WidgetKind::ComboBox(w) => {
            emit_combo_box_arrow(base, style, cmds);
            if let Some(text) = w.selected_item() {
                emit_text_at(
                    text,
                    base.x + 6.0,
                    base.y + (base.height - style.font_size) * 0.5,
                    font_key,
                    style,
                    cmds,
                );
            }
        }
        WidgetKind::ListBox(w) => {
            let row_h = w.item_height.max(14.0);
            for (row_idx, item) in w.items.iter().enumerate() {
                let row_y = base.y + row_idx as f32 * row_h;
                if row_y + row_h > base.y + base.height {
                    break;
                }
                if w.selected_index == Some(row_idx) {
                    cmds.push(RenderCommand::SetColor(0.22, 0.36, 0.60, 0.80));
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Fill,
                        x: base.x + 1.0,
                        y: row_y,
                        w: (base.width - 2.0).max(0.0),
                        h: row_h,
                    });
                }
                emit_text_at(
                    item,
                    base.x + 6.0,
                    row_y + (row_h - style.font_size) * 0.5,
                    font_key,
                    style,
                    cmds,
                );
                cmds.push(RenderCommand::SetColor(0.22, 0.24, 0.30, 0.60));
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: base.x,
                    y: row_y + row_h - 1.0,
                    w: base.width,
                    h: 1.0,
                });
            }
        }
        WidgetKind::TabBar(w) => {
            if !w.tabs.is_empty() {
                let tab_w = (base.width / w.tabs.len() as f32).max(24.0);
                for (tab_idx, tab) in w.tabs.iter().enumerate() {
                    let tab_x = base.x + tab_idx as f32 * tab_w;
                    let active = tab_idx == w.active_tab;
                    cmds.push(RenderCommand::SetColor(
                        if active { 0.20 } else { 0.13 },
                        if active { 0.24 } else { 0.14 },
                        if active { 0.34 } else { 0.18 },
                        1.0,
                    ));
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Fill,
                        x: tab_x,
                        y: base.y,
                        w: tab_w,
                        h: base.height,
                    });
                    if active {
                        cmds.push(RenderCommand::SetColor(
                            style.fg_color[0],
                            style.fg_color[1],
                            style.fg_color[2],
                            1.0,
                        ));
                        cmds.push(RenderCommand::Rectangle {
                            mode: DrawMode::Fill,
                            x: tab_x,
                            y: base.y,
                            w: tab_w,
                            h: 2.0,
                        });
                    }
                    emit_text_at(
                        tab,
                        tab_x + (tab_w - tab.len() as f32 * 6.0 * (style.font_size / 14.0)) * 0.5,
                        base.y + (base.height - style.font_size) * 0.5,
                        font_key,
                        style,
                        cmds,
                    );
                }
            }
        }
        WidgetKind::Toast(w) => {
            cmds.push(RenderCommand::SetColor(0.39, 0.75, 1.0, 1.0));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: base.x,
                y: base.y,
                w: 4.0,
                h: base.height,
            });
            emit_text_at(
                &w.message,
                base.x + 10.0,
                base.y + (base.height - style.font_size) * 0.5,
                font_key,
                style,
                cmds,
            );
        }
        WidgetKind::Separator(w) => {
            cmds.push(RenderCommand::SetColor(
                style.fg_color[0],
                style.fg_color[1],
                style.fg_color[2],
                0.7,
            ));
            if w.vertical {
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: base.x + (base.width - w.thickness) * 0.5,
                    y: base.y,
                    w: w.thickness.max(1.0),
                    h: base.height,
                });
            } else {
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: base.x,
                    y: base.y + (base.height - w.thickness) * 0.5,
                    w: base.width,
                    h: w.thickness.max(1.0),
                });
            }
        }
        WidgetKind::TreeView(w) => {
            let mut row_y = base.y + 4.0;
            let mut ctx = TreeCtx {
                nodes: &w.nodes,
                selected: w.selected_node,
                font_key,
                style,
                cmds,
            };
            for &root_idx in &w.root_nodes {
                row_y = emit_tree_nodes(&mut ctx, root_idx, base.x + 4.0, row_y, 20.0, 0);
            }
        }
        WidgetKind::ScrollBar(w) => {
            emit_scroll_bar(
                base,
                w.position,
                w.content_size,
                w.view_size,
                w.vertical,
                style,
                cmds,
            );
        }
        WidgetKind::Switch(w) => {
            emit_switch(base, w.on, w.thumb_t, style, cmds);
        }
        WidgetKind::Badge(w) => {
            emit_badge(base, &w.display_text(), font_key, style, cmds);
        }
        WidgetKind::GUIWindow(w) => {
            cmds.push(RenderCommand::SetColor(0.18, 0.22, 0.32, 1.0));
            cmds.push(RenderCommand::RoundedRectangle {
                mode: DrawMode::Fill,
                x: base.x,
                y: base.y,
                w: base.width,
                h: 24.0,
                rx: style.corner_radius,
                ry: style.corner_radius,
            });
            emit_text_at(&w.title, base.x + 10.0, base.y + 5.0, font_key, style, cmds);
            if w.closeable {
                cmds.push(RenderCommand::SetColor(0.85, 0.35, 0.35, 1.0));
                cmds.push(RenderCommand::Line {
                    x1: base.x + base.width - 16.0,
                    y1: base.y + 7.0,
                    x2: base.x + base.width - 8.0,
                    y2: base.y + 15.0,
                });
                cmds.push(RenderCommand::Line {
                    x1: base.x + base.width - 8.0,
                    y1: base.y + 7.0,
                    x2: base.x + base.width - 16.0,
                    y2: base.y + 15.0,
                });
            }
        }
        WidgetKind::SplitPanel(w) => {
            cmds.push(RenderCommand::SetColor(0.26, 0.28, 0.34, 1.0));
            if w.orientation == "vertical" {
                let split_y = base.y + base.height * w.split_position.clamp(0.0, 1.0);
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: base.x,
                    y: split_y - 1.0,
                    w: base.width,
                    h: 3.0,
                });
            } else {
                let split_x = base.x + base.width * w.split_position.clamp(0.0, 1.0);
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: split_x - 1.0,
                    y: base.y,
                    w: 3.0,
                    h: base.height,
                });
            }
        }
        WidgetKind::Toolbar(w) => {
            let mut button_x = base.x + 4.0;
            let button_size = base.height.min(28.0);
            for button in &w.buttons {
                cmds.push(RenderCommand::SetColor(
                    if button.toggled { 0.22 } else { 0.16 },
                    if button.toggled { 0.36 } else { 0.18 },
                    if button.toggled { 0.56 } else { 0.24 },
                    1.0,
                ));
                cmds.push(RenderCommand::RoundedRectangle {
                    mode: DrawMode::Fill,
                    x: button_x,
                    y: base.y + (base.height - button_size) * 0.5,
                    w: button_size,
                    h: button_size,
                    rx: 4.0,
                    ry: 4.0,
                });
                let label = button
                    .id
                    .chars()
                    .next()
                    .unwrap_or('?')
                    .to_ascii_uppercase()
                    .to_string();
                emit_text_at(
                    &label,
                    button_x + button_size * 0.5 - 3.0,
                    base.y + (base.height - style.font_size) * 0.5,
                    font_key,
                    style,
                    cmds,
                );
                button_x += button_size + 4.0;
            }
        }
        WidgetKind::MenuBar(_) => {
            cmds.push(RenderCommand::SetColor(0.24, 0.26, 0.32, 1.0));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: base.x,
                y: base.y + base.height - 2.0,
                w: base.width,
                h: 2.0,
            });
        }
        WidgetKind::MenuItem(w) => {
            if w.checked {
                emit_text_at(
                    "v",
                    base.x + 4.0,
                    base.y + (base.height - style.font_size) * 0.5,
                    font_key,
                    style,
                    cmds,
                );
            }
            emit_text_at(
                &w.text,
                base.x + if w.checked { 18.0 } else { 6.0 },
                base.y + (base.height - style.font_size) * 0.5,
                font_key,
                style,
                cmds,
            );
            if !w.shortcut.is_empty() {
                let scale = style.font_size / 14.0;
                let shortcut_w = w.shortcut.chars().count() as f32 * 6.0 * scale;
                emit_text_at(
                    &w.shortcut,
                    base.x + (base.width - shortcut_w - 6.0).max(0.0),
                    base.y + (base.height - style.font_size) * 0.5,
                    font_key,
                    style,
                    cmds,
                );
            }
        }
        WidgetKind::Dialog(w) => {
            cmds.push(RenderCommand::SetColor(0.18, 0.22, 0.32, 1.0));
            cmds.push(RenderCommand::RoundedRectangle {
                mode: DrawMode::Fill,
                x: base.x,
                y: base.y,
                w: base.width,
                h: 28.0,
                rx: style.corner_radius,
                ry: style.corner_radius,
            });
            emit_text_at(&w.title, base.x + 10.0, base.y + 6.0, font_key, style, cmds);
            if !w.footer_buttons.is_empty() {
                let footer_y = base.y + base.height - 30.0;
                let button_w = 70.0;
                let total_w = w.footer_buttons.len() as f32 * (button_w + 6.0);
                let mut button_x = base.x + base.width - total_w;
                for label in &w.footer_buttons {
                    cmds.push(RenderCommand::SetColor(0.18, 0.22, 0.32, 1.0));
                    cmds.push(RenderCommand::RoundedRectangle {
                        mode: DrawMode::Fill,
                        x: button_x,
                        y: footer_y,
                        w: button_w,
                        h: 24.0,
                        rx: 4.0,
                        ry: 4.0,
                    });
                    emit_text_at(
                        label,
                        button_x + 14.0,
                        footer_y + 4.0,
                        font_key,
                        style,
                        cmds,
                    );
                    button_x += button_w + 6.0;
                }
            }
        }
        WidgetKind::StatusBar(w) => {
            let mut section_x = base.x;
            for (text, width) in &w.sections {
                emit_text_at(
                    text,
                    section_x + 6.0,
                    base.y + (base.height - style.font_size) * 0.5,
                    font_key,
                    style,
                    cmds,
                );
                section_x += *width;
                cmds.push(RenderCommand::SetColor(0.24, 0.26, 0.32, 1.0));
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: section_x,
                    y: base.y,
                    w: 1.0,
                    h: base.height,
                });
            }
        }
        WidgetKind::Accordion(w) => {
            let mut section_y = base.y;
            for section in &w.sections {
                cmds.push(RenderCommand::SetColor(0.18, 0.20, 0.28, 1.0));
                cmds.push(RenderCommand::RoundedRectangle {
                    mode: DrawMode::Fill,
                    x: base.x,
                    y: section_y,
                    w: base.width,
                    h: 24.0,
                    rx: 4.0,
                    ry: 4.0,
                });
                emit_text_at(
                    &section.title,
                    base.x + 18.0,
                    section_y + 5.0,
                    font_key,
                    style,
                    cmds,
                );
                cmds.push(RenderCommand::SetColor(
                    style.fg_color[0],
                    style.fg_color[1],
                    style.fg_color[2],
                    0.9,
                ));
                if section.expanded {
                    cmds.push(RenderCommand::Triangle {
                        mode: DrawMode::Fill,
                        x1: base.x + 8.0,
                        y1: section_y + 8.0,
                        x2: base.x + 14.0,
                        y2: section_y + 8.0,
                        x3: base.x + 11.0,
                        y3: section_y + 14.0,
                    });
                    section_y += 60.0;
                } else {
                    cmds.push(RenderCommand::Triangle {
                        mode: DrawMode::Fill,
                        x1: base.x + 9.0,
                        y1: section_y + 6.0,
                        x2: base.x + 9.0,
                        y2: section_y + 16.0,
                        x3: base.x + 15.0,
                        y3: section_y + 11.0,
                    });
                    section_y += 26.0;
                }
            }
        }
        WidgetKind::TooltipPanel(w) => {
            cmds.push(RenderCommand::SetColor(0.78, 0.68, 0.26, 1.0));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: base.x,
                y: base.y,
                w: base.width,
                h: 2.0,
            });
            emit_text_at(
                &w.text,
                base.x + 6.0,
                base.y + (base.height - style.font_size) * 0.5,
                font_key,
                style,
                cmds,
            );
        }
        WidgetKind::ColorPicker(w) => {
            let swatch_size = (base.height.min(base.width) - 26.0).max(12.0);
            cmds.push(RenderCommand::SetColor(w.r, w.g, w.b, w.a));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: base.x + 6.0,
                y: base.y + 6.0,
                w: swatch_size,
                h: swatch_size,
            });
            let hue_y = base.y + base.height - 18.0;
            cmds.push(RenderCommand::DrawGradientRect {
                x: base.x + 6.0,
                y: hue_y,
                w: (base.width - 12.0).max(0.0),
                h: 12.0,
                color1: [1.0, 0.0, 0.0, 1.0],
                color2: [1.0, 0.0, 1.0, 1.0],
                direction: GradientDirection::Horizontal,
            });
            emit_text_at(
                &format!(
                    "#{:02X}{:02X}{:02X}",
                    (w.r * 255.0) as u8,
                    (w.g * 255.0) as u8,
                    (w.b * 255.0) as u8
                ),
                base.x + 6.0,
                base.y + swatch_size + 10.0,
                font_key,
                style,
                cmds,
            );
        }
        WidgetKind::GUITable(w) => {
            let header_h = 22.0;
            cmds.push(RenderCommand::SetColor(0.18, 0.22, 0.32, 1.0));
            cmds.push(RenderCommand::Rectangle {
                mode: DrawMode::Fill,
                x: base.x,
                y: base.y,
                w: base.width,
                h: header_h,
            });
            let mut col_x = base.x;
            for col in &w.columns {
                emit_text_at(
                    &col.header,
                    col_x + 4.0,
                    base.y + 4.0,
                    font_key,
                    style,
                    cmds,
                );
                col_x += col.width;
                cmds.push(RenderCommand::SetColor(0.22, 0.24, 0.30, 0.8));
                cmds.push(RenderCommand::Rectangle {
                    mode: DrawMode::Fill,
                    x: col_x,
                    y: base.y,
                    w: 1.0,
                    h: base.height,
                });
            }
            let row_h = 20.0;
            for (row_idx, row) in w.rows.iter().enumerate() {
                let row_y = base.y + header_h + row_idx as f32 * row_h;
                if row_y + row_h > base.y + base.height {
                    break;
                }
                if w.selected_row == Some(row_idx) {
                    cmds.push(RenderCommand::SetColor(0.22, 0.36, 0.60, 0.80));
                    cmds.push(RenderCommand::Rectangle {
                        mode: DrawMode::Fill,
                        x: base.x,
                        y: row_y,
                        w: base.width,
                        h: row_h,
                    });
                }
                let mut cell_x = base.x;
                for (cell_idx, cell) in row.iter().enumerate() {
                    emit_text_at(cell, cell_x + 4.0, row_y + 4.0, font_key, style, cmds);
                    cell_x += w.columns.get(cell_idx).map(|c| c.width).unwrap_or(80.0);
                }
            }
        }
        WidgetKind::ImageWidget(_) => {
            cmds.push(RenderCommand::SetColor(0.30, 0.32, 0.38, 1.0));
            cmds.push(RenderCommand::Line {
                x1: base.x,
                y1: base.y,
                x2: base.x + base.width,
                y2: base.y + base.height,
            });
            cmds.push(RenderCommand::Line {
                x1: base.x + base.width,
                y1: base.y,
                x2: base.x,
                y2: base.y + base.height,
            });
            emit_text_at(
                "[image]",
                base.x + (base.width - 42.0) * 0.5,
                base.y + (base.height - style.font_size) * 0.5,
                font_key,
                style,
                cmds,
            );
        }
        _ => {}
    }
    let skip_text = matches!(
        widget,
        WidgetKind::Badge(_)
            | WidgetKind::Switch(_)
            | WidgetKind::CheckBox(_)
            | WidgetKind::RadioButton(_)
            | WidgetKind::TextInput(_)
            | WidgetKind::ComboBox(_)
            | WidgetKind::MenuItem(_)
    );
    if !skip_text {
        if let Some(text) = display_text(widget) {
            emit_text(base, text, style, font_key, cmds);
        }
    }
    for child_idx in widget_render_children(widget) {
        if child_idx < ctx.widgets.len() {
            render_widget(ctx, child_idx, font_key, default_style, cmds);
        }
    }
}
impl GuiContext {
    /// Run a layout pass then emit all render commands using `font_key`; return the command list.
    pub fn build_render_commands(&mut self, font_key: FontKey) -> Vec<RenderCommand> {
        self.run_layout_pass();
        let default_style = WidgetStyle::default();
        let mut cmds = Vec::new();
        WidgetRenderer::new(self, font_key, &default_style, &mut cmds).render_root_children();
        cmds
    }
    /// Run a layout pass and emit render commands using the default font key.
    pub fn generate_render_commands(&mut self) -> Vec<RenderCommand> {
        self.build_render_commands(FontKey::default())
    }
    /// Rasterise all visible widgets into a new `ImageData` of `width × height` pixels.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(24, 26, 34, 255);
        let mut layout_ctx = self.clone();
        layout_ctx.run_layout_pass();
        let default_style = WidgetStyle::default();
        let Some(children) = layout_ctx.widgets.first().and_then(|w| w.children()) else {
            return img;
        };
        let mut stack: Vec<usize> = children.to_vec();
        while let Some(idx) = stack.pop() {
            let Some(widget) = layout_ctx.widgets.get(idx) else {
                continue;
            };
            let base = widget.base();
            if !base.visible {
                continue;
            }
            let rect = base.computed_rect;
            let x = rect.x as i32;
            let y = rect.y as i32;
            let w = rect.width.max(1.0) as u32;
            let h = rect.height.max(1.0) as u32;
            let style_with_alpha = resolve_style_with_alpha(&layout_ctx, base, &default_style);
            let style = &style_with_alpha;
            let [sr, sg, sb, sa] = style.shadow_color;
            if sa > 0.0 {
                let sx = x + style.shadow_offset[0] as i32;
                let sy = y + style.shadow_offset[1] as i32;
                img.draw_rect(
                    sx,
                    sy,
                    w,
                    h,
                    (sr * 255.0) as u8,
                    (sg * 255.0) as u8,
                    (sb * 255.0) as u8,
                    (sa * 255.0) as u8,
                );
            }
            let [r0, g0, b0, a0] = style.bg_color;
            if let Some([r1, g1, b1, _a1]) = style.gradient_end {
                for py in 0..h {
                    let t = if h <= 1 {
                        0.0
                    } else {
                        py as f32 / (h - 1) as f32
                    };
                    let rr = r0 + (r1 - r0) * t;
                    let gg = g0 + (g1 - g0) * t;
                    let bb = b0 + (b1 - b0) * t;
                    img.draw_rect(
                        x,
                        y + py as i32,
                        w,
                        1,
                        (rr * 255.0) as u8,
                        (gg * 255.0) as u8,
                        (bb * 255.0) as u8,
                        (a0 * 255.0) as u8,
                    );
                }
            } else {
                img.draw_rect(
                    x,
                    y,
                    w,
                    h,
                    (r0 * 255.0) as u8,
                    (g0 * 255.0) as u8,
                    (b0 * 255.0) as u8,
                    (a0 * 255.0) as u8,
                );
            }
            if style.highlight_alpha > 0.0 {
                let hi = (style.highlight_alpha.clamp(0.0, 1.0) * 140.0) as u8;
                let strip_h = (style.border_width.max(2.0)) as u32;
                img.draw_rect(
                    x + 1,
                    y + 1,
                    w.saturating_sub(2),
                    strip_h,
                    255,
                    255,
                    255,
                    hi,
                );
            }
            if style.border_width > 0.0 {
                let [br, bg, bb, ba] = style.border_color;
                let br = (br * 255.0) as u8;
                let bg = (bg * 255.0) as u8;
                let bb = (bb * 255.0) as u8;
                let ba = (ba * 255.0) as u8;
                img.draw_rect(x, y, w, 1, br, bg, bb, ba);
                img.draw_rect(x, y + h as i32 - 1, w, 1, br, bg, bb, ba);
                img.draw_rect(x, y, 1, h, br, bg, bb, ba);
                img.draw_rect(x + w as i32 - 1, y, 1, h, br, bg, bb, ba);
            }
            let [frc, fgc, fbc, _fa] = style.fg_color;
            let fr = (frc * 255.0) as u8;
            let fg = (fgc * 255.0) as u8;
            let fb = (fbc * 255.0) as u8;
            let mut skip_text = false;
            match widget {
                WidgetKind::Slider(slider) => {
                    let range = (slider.max - slider.min).max(1e-6);
                    let t = ((slider.value - slider.min) / range).clamp(0.0, 1.0) as f32;
                    let fill_w = ((w as f32) * t).max(1.0) as u32;
                    img.draw_rect(
                        x,
                        y + (h as i32 / 3),
                        fill_w,
                        (h / 3).max(2),
                        fr,
                        fg,
                        fb,
                        255,
                    );
                    let knob_x = x + fill_w as i32 - 2;
                    img.draw_circle(knob_x, y + h as i32 / 2, (h / 3).max(3), 220, 230, 240, 255);
                    skip_text = true;
                }
                WidgetKind::ProgressBar(pb) => {
                    let range = (pb.max - pb.min).max(1e-6);
                    let t = ((pb.value - pb.min) / range).clamp(0.0, 1.0) as f32;
                    let fill_w = ((w as f32) * t).max(0.0) as u32;
                    if fill_w > 0 {
                        img.draw_rect(
                            x + 1,
                            y + 1,
                            fill_w.saturating_sub(2),
                            h.saturating_sub(2),
                            fr,
                            fg,
                            fb,
                            255,
                        );
                    }
                    let pct_label = format!("{}%", (t * 100.0).round() as u32);
                    let lw = (pct_label.chars().count() as i32) * 6;
                    img.draw_label(
                        &pct_label,
                        x + ((w as i32 - lw) / 2).max(1),
                        y + ((h as i32 - 7) / 2).max(1),
                        230,
                        235,
                        240,
                    );
                    skip_text = true;
                }
                WidgetKind::SpinBox(sb) => {
                    let btn_w = (h as i32).max(20);
                    img.draw_rect(
                        x + w as i32 - btn_w,
                        y,
                        btn_w as u32,
                        h / 2,
                        60,
                        65,
                        80,
                        255,
                    );
                    img.draw_rect(
                        x + w as i32 - btn_w,
                        y + (h / 2) as i32,
                        btn_w as u32,
                        h.div_ceil(2),
                        50,
                        55,
                        70,
                        255,
                    );
                    let ax = x + w as i32 - btn_w / 2;
                    let ay = y + h as i32 / 4;
                    img.draw_line(ax - 3, ay + 2, ax, ay - 2, 200, 210, 220, 255);
                    img.draw_line(ax, ay - 2, ax + 3, ay + 2, 200, 210, 220, 255);
                    let dy = y + (h as i32 * 3) / 4;
                    img.draw_line(ax - 3, dy - 2, ax, dy + 2, 200, 210, 220, 255);
                    img.draw_line(ax, dy + 2, ax + 3, dy - 2, 200, 210, 220, 255);
                    let label = format!("{}", sb.value);
                    let lw = (label.chars().count() as i32) * 6;
                    img.draw_label(
                        &label,
                        x + ((w as i32 - btn_w - lw) / 2).max(2),
                        y + ((h as i32 - 7) / 2).max(1),
                        fr,
                        fg,
                        fb,
                    );
                    skip_text = true;
                }
                WidgetKind::ScrollBar(sb) => {
                    let total = sb.content_size.max(1.0);
                    let thumb_ratio = (sb.view_size / total).clamp(0.1, 1.0);
                    let pos_ratio = (sb.position / total).clamp(0.0, 1.0 - thumb_ratio);
                    if sb.vertical {
                        let thumb_h = ((h as f32) * thumb_ratio).max(8.0) as u32;
                        let thumb_y = y + (h as f32 * pos_ratio) as i32;
                        img.draw_rect(
                            x + 2,
                            thumb_y,
                            w.saturating_sub(4),
                            thumb_h,
                            fr,
                            fg,
                            fb,
                            200,
                        );
                    } else {
                        let thumb_w = ((w as f32) * thumb_ratio).max(8.0) as u32;
                        let thumb_x = x + (w as f32 * pos_ratio) as i32;
                        img.draw_rect(
                            thumb_x,
                            y + 2,
                            thumb_w,
                            h.saturating_sub(4),
                            fr,
                            fg,
                            fb,
                            200,
                        );
                    }
                    skip_text = true;
                }
                WidgetKind::Switch(sw) => {
                    let track_h = h.min(18);
                    let ty_off = (h - track_h) / 2;
                    let (on_r, on_g, on_b) = if sw.on { (70, 170, 100) } else { (60, 65, 80) };
                    img.draw_rect(x, y + ty_off as i32, w, track_h, on_r, on_g, on_b, 255);
                    let thumb_x = x + (sw.thumb_t * (w as f32 - track_h as f32)).max(0.0) as i32;
                    img.draw_circle(
                        thumb_x + track_h as i32 / 2,
                        y + (h / 2) as i32,
                        ((track_h / 2).saturating_sub(1)).max(2),
                        220,
                        230,
                        240,
                        255,
                    );
                    skip_text = true;
                }
                WidgetKind::CheckBox(cb) => {
                    let box_sz = (h as i32).clamp(10, 14);
                    let bx = x + 3;
                    let by = y + (h as i32 - box_sz) / 2;
                    img.draw_rect(bx, by, box_sz as u32, box_sz as u32, 90, 95, 115, 255);
                    img.draw_rect(
                        bx + 1,
                        by + 1,
                        (box_sz - 2).max(0) as u32,
                        (box_sz - 2).max(0) as u32,
                        28,
                        30,
                        44,
                        255,
                    );
                    if cb.checked {
                        img.draw_line(
                            bx + 2,
                            by + box_sz / 2,
                            bx + box_sz / 2 - 1,
                            by + box_sz - 3,
                            fr,
                            fg,
                            fb,
                            255,
                        );
                        img.draw_line(
                            bx + box_sz / 2 - 1,
                            by + box_sz - 3,
                            bx + box_sz - 2,
                            by + 2,
                            fr,
                            fg,
                            fb,
                            255,
                        );
                    }
                    if !cb.text.is_empty() {
                        img.draw_label(
                            &cb.text,
                            bx + box_sz + 6,
                            y + ((h as i32 - 7) / 2).max(1),
                            fr,
                            fg,
                            fb,
                        );
                    }
                    skip_text = true;
                }
                WidgetKind::RadioButton(rb) => {
                    let r = (((h as i32) / 2 - 2).max(3)) as u32;
                    let cx = x + r as i32 + 3;
                    let cy = y + h as i32 / 2;
                    img.draw_circle(cx, cy, r, 90, 95, 115, 255);
                    img.draw_circle(cx, cy, r.saturating_sub(1).max(1), 28, 30, 44, 255);
                    if rb.selected {
                        img.draw_circle(cx, cy, (r / 2).max(2), fr, fg, fb, 255);
                    }
                    if !rb.text.is_empty() {
                        img.draw_label(
                            &rb.text,
                            cx + r as i32 + 6,
                            y + ((h as i32 - 7) / 2).max(1),
                            fr,
                            fg,
                            fb,
                        );
                    }
                    skip_text = true;
                }
                WidgetKind::TextInput(ti) => {
                    if ti.text.is_empty() && !ti.placeholder.is_empty() {
                        img.draw_label(
                            &ti.placeholder,
                            x + base.padding[3] as i32 + 4,
                            y + ((h as i32 - 7) / 2).max(1),
                            120,
                            125,
                            145,
                        );
                    } else {
                        img.draw_label(
                            &ti.text,
                            x + base.padding[3] as i32 + 4,
                            y + ((h as i32 - 7) / 2).max(1),
                            fr,
                            fg,
                            fb,
                        );
                    }
                    if ti.focused {
                        let cursor_x = x
                            + base.padding[3] as i32
                            + 4
                            + ti.cursor_pos.min(ti.text.len()) as i32 * 6;
                        img.draw_rect(cursor_x, y + 3, 1, h.saturating_sub(6), fr, fg, fb, 220);
                    }
                    skip_text = true;
                }
                WidgetKind::ComboBox(cb) => {
                    if let Some(text) = cb.selected_item() {
                        img.draw_label(
                            text,
                            x + base.padding[3] as i32 + 4,
                            y + ((h as i32 - 7) / 2).max(1),
                            fr,
                            fg,
                            fb,
                        );
                    }
                    let ax = x + w as i32 - 12;
                    let ay = y + h as i32 / 2;
                    img.draw_line(ax - 4, ay - 2, ax, ay + 3, 200, 205, 215, 255);
                    img.draw_line(ax, ay + 3, ax + 4, ay - 2, 200, 205, 215, 255);
                    skip_text = true;
                }
                WidgetKind::ListBox(lb) => {
                    let row_h = lb.item_height.max(12.0) as i32;
                    for (i, item) in lb.items.iter().enumerate() {
                        let iy = y + i as i32 * row_h;
                        if iy >= y + h as i32 {
                            break;
                        }
                        if lb.selected_index == Some(i) {
                            img.draw_rect(
                                x + 1,
                                iy,
                                w.saturating_sub(2),
                                row_h as u32,
                                55,
                                90,
                                155,
                                200,
                            );
                        }
                        img.draw_label(item, x + 6, iy + (row_h - 7) / 2, fr, fg, fb);
                        img.draw_rect(x, iy + row_h - 1, w, 1, 55, 60, 75, 120);
                    }
                    skip_text = true;
                }
                WidgetKind::TabBar(tb) => {
                    if !tb.tabs.is_empty() {
                        let tab_w = (w as i32 / tb.tabs.len() as i32).max(30);
                        for (i, tab) in tb.tabs.iter().enumerate() {
                            let tx = x + i as i32 * tab_w;
                            let (bg_r, bg_g, bg_b) = if i == tb.active_tab {
                                (48, 52, 72)
                            } else {
                                (32, 35, 50)
                            };
                            img.draw_rect(tx, y, tab_w as u32, h, bg_r, bg_g, bg_b, 255);
                            img.draw_rect(tx + tab_w - 1, y, 1, h, 28, 30, 44, 255);
                            if i == tb.active_tab {
                                img.draw_rect(tx, y, tab_w as u32, 2, fr, fg, fb, 255);
                            }
                            let lw = (tab.chars().count() as i32) * 6;
                            img.draw_label(
                                tab,
                                tx + ((tab_w - lw) / 2).max(2),
                                y + ((h as i32 - 7) / 2).max(1),
                                fr,
                                fg,
                                fb,
                            );
                        }
                    }
                    skip_text = true;
                }
                WidgetKind::Toast(t) => {
                    img.draw_rect(x, y, 4, h, 100, 190, 255, 255);
                    let fade_a = ((1.0 - t.progress()) * 200.0) as u8;
                    img.draw_rect(x + w as i32 - 6, y, 6, h, 255, 255, 255, fade_a);
                    img.draw_label(
                        &t.message,
                        x + 10,
                        y + ((h as i32 - 7) / 2).max(1),
                        fr,
                        fg,
                        fb,
                    );
                    skip_text = true;
                }
                WidgetKind::Badge(badge) => {
                    let text = badge.display_text();
                    let lw = (text.chars().count() as i32) * 6;
                    img.draw_label(
                        &text,
                        x + ((w as i32 - lw) / 2).max(1),
                        y + ((h as i32 - 7) / 2).max(1),
                        245,
                        250,
                        255,
                    );
                    skip_text = true;
                }
                WidgetKind::TooltipPanel(ttp) => {
                    img.draw_rect(x, y, w, 2, fr, fg, fb, 100);
                    if !ttp.text.is_empty() {
                        img.draw_label(
                            &ttp.text,
                            x + 6,
                            y + ((h as i32 - 7) / 2).max(1),
                            fr,
                            fg,
                            fb,
                        );
                    }
                    skip_text = true;
                }
                WidgetKind::Separator(sep) => {
                    if sep.vertical {
                        let cx = x + w as i32 / 2;
                        img.draw_rect(cx, y, sep.thickness.max(1.0) as u32, h, fr, fg, fb, 160);
                    } else {
                        let cy = y + h as i32 / 2;
                        img.draw_rect(x, cy, w, sep.thickness.max(1.0) as u32, fr, fg, fb, 160);
                    }
                    skip_text = true;
                }
                WidgetKind::Spacer(_) => {
                    skip_text = true;
                }
                WidgetKind::GUIWindow(win) => {
                    let bar_h = 24u32;
                    img.draw_rect(x, y, w, bar_h, 38, 42, 60, 255);
                    img.draw_rect(x, y + bar_h as i32, w, 1, 55, 60, 80, 255);
                    img.draw_label(&win.title, x + 10, y + 7, fr, fg, fb);
                    if win.closeable {
                        let cx = x + w as i32 - 14;
                        let cy = y + 8;
                        img.draw_line(cx, cy, cx + 8, cy + 8, 200, 80, 80, 255);
                        img.draw_line(cx + 8, cy, cx, cy + 8, 200, 80, 80, 255);
                    }
                    skip_text = true;
                }
                WidgetKind::Dialog(dlg) => {
                    let bar_h = 28u32;
                    img.draw_rect(x, y, w, bar_h, 38, 42, 60, 255);
                    img.draw_rect(x, y + bar_h as i32, w, 1, 55, 60, 80, 255);
                    img.draw_label(&dlg.title, x + 10, y + 9, fr, fg, fb);
                    if !dlg.footer_buttons.is_empty() {
                        let footer_y = y + h as i32 - 34;
                        img.draw_rect(x, footer_y, w, 1, 55, 60, 80, 255);
                        let btn_w = 70i32;
                        let total_w = dlg.footer_buttons.len() as i32 * (btn_w + 6);
                        let mut bx = x + w as i32 - total_w;
                        for label in &dlg.footer_buttons {
                            img.draw_rect(bx, footer_y + 4, btn_w as u32, 24, 48, 52, 72, 255);
                            img.draw_rect(bx, footer_y + 4, btn_w as u32, 1, 75, 80, 105, 255);
                            let lw = (label.chars().count() as i32) * 6;
                            img.draw_label(
                                label,
                                bx + ((btn_w - lw) / 2).max(2),
                                footer_y + 10,
                                fr,
                                fg,
                                fb,
                            );
                            bx += btn_w + 6;
                        }
                    }
                    skip_text = true;
                }
                WidgetKind::StatusBar(sb) => {
                    let mut sx = x;
                    for (text, sec_w) in &sb.sections {
                        let sw = sec_w.max(20.0) as i32;
                        img.draw_label(text, sx + 6, y + ((h as i32 - 7) / 2).max(1), fr, fg, fb);
                        img.draw_rect(sx + sw, y, 1, h, 55, 60, 75, 160);
                        sx += sw;
                    }
                    skip_text = true;
                }
                WidgetKind::Accordion(acc) => {
                    let hdr_h = 24i32;
                    let mut ay = y;
                    for section in &acc.sections {
                        if ay + hdr_h > y + h as i32 {
                            break;
                        }
                        img.draw_rect(x, ay, w, hdr_h as u32, 42, 46, 65, 255);
                        img.draw_rect(x, ay + hdr_h - 1, w, 1, 30, 33, 48, 255);
                        let aw = 8i32;
                        let axp = x + 10;
                        let ayp = ay + hdr_h / 2;
                        if section.expanded {
                            img.draw_line(axp, ayp - 2, axp + aw, ayp - 2, fr, fg, fb, 220);
                            img.draw_line(axp, ayp - 2, axp + aw / 2, ayp + 4, fr, fg, fb, 220);
                            img.draw_line(
                                axp + aw,
                                ayp - 2,
                                axp + aw / 2,
                                ayp + 4,
                                fr,
                                fg,
                                fb,
                                220,
                            );
                        } else {
                            img.draw_line(axp, ayp - 4, axp, ayp + 4, fr, fg, fb, 220);
                            img.draw_line(axp, ayp - 4, axp + 6, ayp, fr, fg, fb, 220);
                            img.draw_line(axp, ayp + 4, axp + 6, ayp, fr, fg, fb, 220);
                        }
                        img.draw_label(&section.title, axp + 14, ay + (hdr_h - 7) / 2, fr, fg, fb);
                        ay += hdr_h;
                        if section.expanded {
                            ay += 36;
                        }
                    }
                    skip_text = true;
                }
                WidgetKind::ColorPicker(cp) => {
                    let bar_h = 14u32;
                    let bar_y = y + h as i32 - bar_h as i32 - 6;
                    for px in 0..w {
                        let hue = px as f32 / w as f32;
                        let (hr, hg, hb) = hsv_to_rgb(hue, 1.0, 1.0);
                        img.draw_rect(x + px as i32, bar_y, 1, bar_h, hr, hg, hb, 255);
                    }
                    let sw = (h.min(w) as i32 - 28).max(10) as u32;
                    img.draw_rect(
                        x + 6,
                        y + 6,
                        sw,
                        sw,
                        (cp.r * 255.0) as u8,
                        (cp.g * 255.0) as u8,
                        (cp.b * 255.0) as u8,
                        255,
                    );
                    img.draw_rect(x + 5, y + 5, sw + 2, 1, 90, 95, 115, 255);
                    img.draw_rect(x + 5, y + 5 + sw as i32 + 1, sw + 2, 1, 90, 95, 115, 255);
                    img.draw_rect(x + 5, y + 5, 1, sw + 2, 90, 95, 115, 255);
                    img.draw_rect(x + 5 + sw as i32 + 1, y + 5, 1, sw + 2, 90, 95, 115, 255);
                    let hex = format!(
                        "#{:02X}{:02X}{:02X}",
                        (cp.r * 255.0) as u8,
                        (cp.g * 255.0) as u8,
                        (cp.b * 255.0) as u8
                    );
                    img.draw_label(&hex, x + 6, y + sw as i32 + 10, fr, fg, fb);
                    skip_text = true;
                }
                WidgetKind::GUITable(tbl) => {
                    let col_h = 22i32;
                    img.draw_rect(x, y, w, col_h as u32, 38, 42, 60, 255);
                    img.draw_rect(x, y + col_h, w, 1, 55, 60, 80, 255);
                    let mut cx = x;
                    for col in &tbl.columns {
                        let cw = col.width.max(20.0) as i32;
                        img.draw_label(&col.header, cx + 4, y + (col_h - 7) / 2, 190, 200, 220);
                        img.draw_rect(cx + cw, y, 1, col_h as u32, 55, 60, 80, 255);
                        cx += cw;
                    }
                    let row_h = 20i32;
                    for (ri, row) in tbl.rows.iter().enumerate() {
                        let ry = y + col_h + ri as i32 * row_h;
                        if ry + row_h > y + h as i32 {
                            break;
                        }
                        if tbl.selected_row == Some(ri) {
                            img.draw_rect(x, ry, w, row_h as u32, 50, 85, 150, 180);
                        } else if ri % 2 == 1 {
                            img.draw_rect(x, ry, w, row_h as u32, 30, 33, 48, 100);
                        }
                        let mut cx2 = x;
                        for (ci, cell) in row.iter().enumerate() {
                            let cw = tbl.columns.get(ci).map(|c| c.width).unwrap_or(80.0) as i32;
                            img.draw_label(cell, cx2 + 4, ry + (row_h - 7) / 2, fr, fg, fb);
                            cx2 += cw;
                        }
                        img.draw_rect(x, ry + row_h - 1, w, 1, 40, 43, 58, 140);
                    }
                    skip_text = true;
                }
                WidgetKind::TreeView(tv) => {
                    let row_h = 20i32;
                    let max_y = y + h as i32;
                    let mut ry = y;
                    let roots: Vec<usize> = tv.root_nodes.clone();
                    for ri in roots {
                        ry = draw_tree_nodes_cpu(
                            &tv.nodes,
                            ri,
                            &mut img,
                            x,
                            ry,
                            max_y,
                            row_h,
                            0,
                            tv.selected_node,
                            [fr, fg, fb],
                        );
                    }
                    skip_text = true;
                }
                WidgetKind::Toolbar(tb) => {
                    let btn_sz = h.min(28);
                    let mut bx = x + 4;
                    for btn in &tb.buttons {
                        let (br, bg2, bb2) = if btn.toggled {
                            (55, 90, 140)
                        } else {
                            (40, 44, 62)
                        };
                        img.draw_rect(
                            bx,
                            y + (h as i32 - btn_sz as i32) / 2,
                            btn_sz,
                            btn_sz,
                            br,
                            bg2,
                            bb2,
                            255,
                        );
                        img.draw_rect(
                            bx,
                            y + (h as i32 - btn_sz as i32) / 2,
                            btn_sz,
                            1,
                            65,
                            70,
                            90,
                            255,
                        );
                        img.draw_rect(
                            bx,
                            y + (h as i32 - btn_sz as i32) / 2,
                            1,
                            btn_sz,
                            65,
                            70,
                            90,
                            255,
                        );
                        if let Some(c) = btn.id.chars().next() {
                            let cs = c.to_uppercase().to_string();
                            img.draw_label(
                                &cs,
                                bx + btn_sz as i32 / 2 - 3,
                                y + (h as i32 - 7) / 2,
                                fr,
                                fg,
                                fb,
                            );
                        }
                        bx += btn_sz as i32 + 4;
                    }
                    skip_text = true;
                }
                WidgetKind::MenuBar(_) => {
                    img.draw_rect(x, y + h as i32 - 2, w, 2, fr, fg, fb, 100);
                    skip_text = true;
                }
                WidgetKind::MenuItem(mi) => {
                    if mi.checked {
                        img.draw_label("v", x + 4, y + ((h as i32 - 7) / 2).max(1), fr, fg, fb);
                    }
                    let label_x = if mi.checked { x + 18 } else { x + 6 };
                    img.draw_label(
                        &mi.text,
                        label_x,
                        y + ((h as i32 - 7) / 2).max(1),
                        fr,
                        fg,
                        fb,
                    );
                    if !mi.shortcut.is_empty() {
                        let lw = (mi.shortcut.chars().count() as i32) * 6;
                        img.draw_label(
                            &mi.shortcut,
                            x + w as i32 - lw - 6,
                            y + ((h as i32 - 7) / 2).max(1),
                            140,
                            145,
                            165,
                        );
                    }
                    skip_text = true;
                }
                WidgetKind::ImageWidget(_) => {
                    let cell = 8i32;
                    let mut row = 0;
                    let mut py = y;
                    while py < y + h as i32 {
                        let ch = cell.min(y + h as i32 - py);
                        let mut col = 0;
                        let mut px = x;
                        while px < x + w as i32 {
                            let cw = cell.min(x + w as i32 - px);
                            let c = if (row + col) % 2 == 0 { 80u8 } else { 55u8 };
                            img.draw_rect(px, py, cw as u32, ch as u32, c, c, c, 200);
                            col += 1;
                            px += cell;
                        }
                        row += 1;
                        py += cell;
                    }
                    img.draw_rect(x, y, w, 1, 90, 95, 115, 255);
                    img.draw_rect(x, y + h as i32 - 1, w, 1, 90, 95, 115, 255);
                    img.draw_rect(x, y, 1, h, 90, 95, 115, 255);
                    img.draw_rect(x + w as i32 - 1, y, 1, h, 90, 95, 115, 255);
                    img.draw_label(
                        "[image]",
                        x + ((w as i32 - 42) / 2).max(1),
                        y + ((h as i32 - 7) / 2).max(1),
                        130,
                        135,
                        155,
                    );
                    skip_text = true;
                }
                WidgetKind::SplitPanel(sp) => {
                    if sp.orientation == "vertical" {
                        let sy = y + (sp.split_position * h as f32) as i32;
                        img.draw_rect(x, sy - 1, w, 3, 55, 60, 80, 255);
                    } else {
                        let sx = x + (sp.split_position * w as f32) as i32;
                        img.draw_rect(sx - 1, y, 3, h, 55, 60, 80, 255);
                    }
                }
                WidgetKind::Panel(_)
                | WidgetKind::Layout(_)
                | WidgetKind::ScrollPanel(_)
                | WidgetKind::NinePatch(_)
                | WidgetKind::DockPanel(_)
                | WidgetKind::Button(_)
                | WidgetKind::Label(_)
                | WidgetKind::Custom(_) => {}
            }
            if !skip_text {
                if let Some(text) = display_text(widget) {
                    let approx_w = (text.chars().count() as i32) * 6;
                    let tx = match style.text_align.as_str() {
                        "left" => x + base.padding[3] as i32 + 4,
                        "right" => x + w as i32 - approx_w - 6,
                        _ => x + ((w as i32 - approx_w) / 2).max(2),
                    };
                    let ty = y + ((h as i32 - 7) / 2).max(1);
                    img.draw_label(text, tx, ty, fr, fg, fb);
                }
            }
            if let Some(ch) = widget.children() {
                stack.extend_from_slice(ch);
            }
        }
        img
    }
}
