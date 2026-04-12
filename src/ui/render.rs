//! Render command generation for the GUI widget tree.
//!
//! Converts a [`GuiContext`] widget tree into a flat list of
//! [`RenderCommand`]s that the GPU renderer can execute.  Walks the tree
//! depth-first from the root panel, emitting background rectangles, borders,
//! and text labels for each visible widget according to the active
//! [`Theme`](super::Theme).

use crate::render::renderer::{DrawMode, RenderCommand};
use crate::runtime::resource_keys::FontKey;
use crate::ui::context::{GuiContext, WidgetKind};
use crate::ui::theme::WidgetStyle;
use crate::ui::widget::WidgetBase;

/// Return the display text for widgets that have a text field.
///
/// # Parameters
/// - `widget` — `&WidgetKind`.
///
/// # Returns
/// `Option<&str>`.
fn display_text(widget: &WidgetKind) -> Option<&str> {
    let text = match widget {
        WidgetKind::Button(w) => &w.text,
        WidgetKind::Label(w) => &w.text,
        WidgetKind::TextInput(w) => &w.text,
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

/// Emit render commands for a single widget's background and border.
///
/// Uses rounded rectangles when `corner_radius > 0`, plain rectangles
/// otherwise.
///
/// # Parameters
/// - `base` — `&WidgetBase`.
/// - `style` — `&WidgetStyle`.
/// - `cmds` — `&mut Vec<RenderCommand>`.
fn emit_box(base: &WidgetBase, style: &WidgetStyle, cmds: &mut Vec<RenderCommand>) {
    let [br, bg, bb, ba] = style.bg_color;
    cmds.push(RenderCommand::SetColor(br, bg, bb, ba));

    if style.corner_radius > 0.0 {
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

/// Emit a `Print` command for the widget's text, centred inside padding.
///
/// # Parameters
/// - `base` — `&WidgetBase`.
/// - `text` — `&str`.
/// - `style` — `&WidgetStyle`.
/// - `font_key` — `FontKey`.
/// - `cmds` — `&mut Vec<RenderCommand>`.
fn emit_text(
    base: &WidgetBase,
    text: &str,
    style: &WidgetStyle,
    font_key: FontKey,
    cmds: &mut Vec<RenderCommand>,
) {
    let [fr, fg, fb, fa] = style.fg_color;
    cmds.push(RenderCommand::SetColor(fr, fg, fb, fa));

    let tx = base.x + base.padding[3]; // left padding
    let ty = base.y + base.padding[0]; // top padding
    let scale = style.font_size / 14.0; // normalise against 14 px baseline

    cmds.push(RenderCommand::Print {
        font_key,
        text: text.to_string(),
        x: tx,
        y: ty,
        scale,
    });
}

/// Recursively walk a widget and its children, emitting render commands.
///
/// # Parameters
/// - `ctx` — `&GuiContext`.
/// - `idx` — `usize`. Widget index in the pool.
/// - `font_key` — `FontKey`.
/// - `default_style` — `&WidgetStyle`. Fallback when no theme is set.
/// - `cmds` — `&mut Vec<RenderCommand>`.
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

    let style = ctx
        .theme
        .as_ref()
        .and_then(|t| t.get_style(base.widget_type, base.state))
        .unwrap_or(default_style);

    // Background + border
    emit_box(base, style, cmds);

    // Text label (if any)
    if let Some(text) = display_text(widget) {
        emit_text(base, text, style, font_key, cmds);
    }

    // Recurse into children
    if let Some(children) = widget.children() {
        for &child_idx in children {
            if child_idx < ctx.widgets.len() {
                render_widget(ctx, child_idx, font_key, default_style, cmds);
            }
        }
    }
}

impl GuiContext {
    /// Generate a flat list of [`RenderCommand`]s for the entire widget tree.
    ///
    /// Walks the root panel's children depth-first, emitting styled
    /// rectangles and text for every visible widget.
    ///
    /// # Parameters
    /// - `font_key` — `FontKey`. Font used for all widget text.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn build_render_commands(&mut self, font_key: FontKey) -> Vec<RenderCommand> {
        self.run_layout_pass();
        let default_style = WidgetStyle::default();
        let mut cmds = Vec::new();

        // Root is always index 0 (invisible panel)
        if let Some(children) = self.widgets.first().and_then(|w| w.children()) {
            for &child_idx in children {
                if child_idx < self.widgets.len() {
                    render_widget(self, child_idx, font_key, &default_style, &mut cmds);
                }
            }
        }

        cmds
    }

    /// Generate render commands using the default font key.
    ///
    /// Convenience alias for [`build_render_commands`](Self::build_render_commands)
    /// that passes [`FontKey::default()`], satisfying the standard
    /// `generate_render_commands()` contract used across engine modules.
    ///
    /// # Returns
    /// `Vec<RenderCommand>`.
    pub fn generate_render_commands(&mut self) -> Vec<RenderCommand> {
        self.build_render_commands(FontKey::default())
    }

    /// Render the widget tree to a CPU image for headless layout testing.
    ///
    /// Draws a dark background and fills a coloured rectangle for each
    /// visible widget at its declared bounds. Text content is not rasterised
    /// (no font atlas available CPU-side).
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `crate::image::ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(30, 30, 40, 255);

        let default_style = WidgetStyle::default();
        let Some(children) = self.widgets.first().and_then(|w| w.children()) else {
            return img;
        };

        let mut stack: Vec<usize> = children.to_vec();
        while let Some(idx) = stack.pop() {
            let Some(widget) = self.widgets.get(idx) else {
                continue;
            };
            let base = widget.base();
            if !base.visible {
                continue;
            }
            let style = self
                .theme
                .as_ref()
                .and_then(|t| t.get_style(base.widget_type, base.state))
                .unwrap_or(&default_style);
            let [r, g, b, a] = style.bg_color;
            let alpha = (a * 255.0) as u8;
            img.draw_rect(
                base.x as i32,
                base.y as i32,
                base.width as u32,
                base.height as u32,
                (r * 255.0) as u8,
                (g * 255.0) as u8,
                (b * 255.0) as u8,
                alpha,
            );
            if let Some(ch) = widget.children() {
                stack.extend_from_slice(ch);
            }
        }
        img
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ui::context::GuiContext;

    #[test]
    fn empty_context_no_commands() {
        let mut ctx = GuiContext::new();
        let cmds = ctx.build_render_commands(FontKey::default());
        assert!(cmds.is_empty());
    }

    #[test]
    fn button_emits_box_and_text() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_button("Click");
        ctx.add_child(0, idx);
        let cmds = ctx.build_render_commands(FontKey::default());
        // At minimum: SetColor + Rectangle (bg) + SetColor + SetLineWidth + Rectangle (border) + SetColor + Print (text)
        assert!(
            cmds.len() >= 5,
            "expected at least 5 commands, got {}",
            cmds.len()
        );
        let has_print = cmds
            .iter()
            .any(|c| matches!(c, RenderCommand::Print { text, .. } if text == "Click"));
        assert!(has_print, "expected a Print command with 'Click'");
    }

    #[test]
    fn invisible_widget_no_commands() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_label("Hidden");
        ctx.add_child(0, idx);
        // Make the label invisible
        ctx.widgets[idx].base_mut().visible = false;
        let cmds = ctx.build_render_commands(FontKey::default());
        assert!(cmds.is_empty());
    }

    #[test]
    fn label_emits_text() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_label("Hello");
        ctx.add_child(0, idx);
        let cmds = ctx.build_render_commands(FontKey::default());
        let has_print = cmds
            .iter()
            .any(|c| matches!(c, RenderCommand::Print { text, .. } if text == "Hello"));
        assert!(has_print, "expected a Print command with 'Hello'");
    }

    #[test]
    fn generate_render_commands_matches_build() {
        let mut ctx = GuiContext::new();
        let idx = ctx.add_button("Ok");
        ctx.add_child(0, idx);
        let a = ctx.generate_render_commands();
        let b = ctx.build_render_commands(FontKey::default());
        assert_eq!(
            a.len(),
            b.len(),
            "generate_render_commands must produce same count as build_render_commands"
        );
    }

    #[test]
    fn draw_to_image_returns_correct_size() {
        let ctx = GuiContext::new();
        let img = ctx.draw_to_image(64, 48);
        assert_eq!(img.width(), 64);
        assert_eq!(img.height(), 48);
    }
}
