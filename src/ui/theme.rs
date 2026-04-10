//! Per-widget-type, per-state styling system.
//!
//! A [`Theme`] maps `(WidgetType, WidgetState)` pairs to [`WidgetStyle`]
//! records.  When the GUI context draws a widget it looks up the style for
//! the widget's type and current state, falling back to the `Normal` state
//! style if no state-specific entry exists, and finally to a hard-coded
//! default if the type has no theme entry at all.
//!
//! The Lua API exposes `lurek.ui.newTheme()`, `theme:setStyle()`, and
//! `lurek.ui.setTheme()` so game scripts can fully customise appearance
//! without touching Rust.

use std::collections::HashMap;

use crate::ui::widget::{WidgetState, WidgetType};

/// Visual style record applied to a specific widget type in a specific state.
///
/// All colour values are RGBA in `[0.0, 1.0]`.  Font size is in pixels.
/// Border width and corner radius are in pixels.
///
/// # Fields
/// - `bg_color` — `[f32; 4]`. Background fill colour (RGBA).
/// - `fg_color` — `[f32; 4]`. Foreground / text colour (RGBA).
/// - `border_color` — `[f32; 4]`. Border stroke colour (RGBA).
/// - `border_width` — `f32`. Border stroke width in pixels.
/// - `corner_radius` — `f32`. Rounded corner radius in pixels.
/// - `font_size` — `f32`. Text size in pixels.
#[derive(Debug, Clone)]
pub struct WidgetStyle {
    /// Background fill colour (RGBA).
    pub bg_color: [f32; 4],
    /// Foreground / text colour (RGBA).
    pub fg_color: [f32; 4],
    /// Border stroke colour (RGBA).
    pub border_color: [f32; 4],
    /// Border stroke width in pixels.
    pub border_width: f32,
    /// Rounded corner radius in pixels.
    pub corner_radius: f32,
    /// Text size in pixels.
    pub font_size: f32,
}

impl Default for WidgetStyle {
    fn default() -> Self {
        Self {
            bg_color: [0.2, 0.2, 0.2, 1.0],
            fg_color: [1.0, 1.0, 1.0, 1.0],
            border_color: [0.4, 0.4, 0.4, 1.0],
            border_width: 1.0,
            corner_radius: 0.0,
            font_size: 14.0,
        }
    }
}

/// Theme registry that maps `(WidgetType, WidgetState)` pairs to [`WidgetStyle`].
///
/// The lookup order when resolving a style for a widget:
/// 1. Exact `(type, state)` entry.
/// 2. Fallback to `(type, Normal)`.
/// 3. Fallback to `WidgetStyle::default()`.
///
/// # Fields
/// - `styles` — `HashMap<(WidgetType, WidgetState), WidgetStyle>`. Style store.
#[derive(Debug, Clone)]
pub struct Theme {
    /// Style store keyed by `(WidgetType, WidgetState)`.
    pub styles: HashMap<(WidgetType, WidgetState), WidgetStyle>,
}

impl Theme {
    /// Create an empty theme with no style entries.
    ///
    /// # Returns
    /// `Theme`.
    pub fn new() -> Self {
        Self {
            styles: HashMap::new(),
        }
    }

    /// Insert or replace a style entry for the given widget type and state.
    ///
    /// # Parameters
    /// - `widget_type` — `WidgetType`.
    /// - `state` — `WidgetState`.
    /// - `style` — `WidgetStyle`.
    pub fn set_style(&mut self, widget_type: WidgetType, state: WidgetState, style: WidgetStyle) {
        self.styles.insert((widget_type, state), style);
    }

    /// Look up the style for a widget type and state.
    ///
    /// Falls back to the `Normal` state entry if no state-specific entry
    /// exists.  Returns `None` only if the type has no theme entries at all.
    ///
    /// # Parameters
    /// - `widget_type` — `WidgetType`.
    /// - `state` — `WidgetState`.
    ///
    /// # Returns
    /// `Option<&WidgetStyle>`.
    pub fn get_style(&self, widget_type: WidgetType, state: WidgetState) -> Option<&WidgetStyle> {
        self.styles
            .get(&(widget_type, state))
            .or_else(|| self.styles.get(&(widget_type, WidgetState::Normal)))
    }

    /// Renders a row of button states (Normal, Hovered, Pressed, Disabled)
    /// as styled boxes to an `ImageData` for evidence testing.
    ///
    /// Uses the theme's `(Button, state)` styles when present; falls back
    /// to hard-coded defaults matching the canonical evidence appearance.
    ///
    /// # Parameters
    /// - `width` — `u32`.
    /// - `height` — `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_button_states_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(45, 45, 55, 255);

        let states: [(WidgetState, &str); 4] = [
            (WidgetState::Normal, "NORMAL"),
            (WidgetState::Hovered, "HOVER"),
            (WidgetState::Pressed, "PRESSED"),
            (WidgetState::Disabled, "DISABLED"),
        ];

        let bw = 80i32;
        let bh = 50i32;

        for (idx, (state, label)) in states.iter().enumerate() {
            let style = self.get_style(WidgetType::Button, state.clone());
            let (fr, fg, fb, br, bg, bb, tr, tg, tb) = if let Some(s) = style {
                let f = |c: [f32; 4]| ((c[0] * 255.0) as u8, (c[1] * 255.0) as u8, (c[2] * 255.0) as u8);
                let (fr, fg2, fb) = f(s.bg_color);
                let (br, bg2, bb) = f(s.border_color);
                let (tr, tg2, tb) = f(s.fg_color);
                (fr, fg2, fb, br, bg2, bb, tr, tg2, tb)
            } else {
                // Hard-coded defaults matching evidence
                match idx {
                    0 => (60, 120, 200, 40, 90, 170, 220, 230, 240),
                    1 => (80, 150, 230, 50, 110, 200, 255, 255, 255),
                    2 => (40, 80, 150, 30, 60, 120, 180, 190, 200),
                    _ => (80, 80, 90, 60, 60, 70, 120, 120, 130),
                }
            };

            let bx = 20 + idx as i32 * 95;
            let by = 60i32;

            // Shadow
            img.draw_rect(bx + 2, by + 2, bw as u32, bh as u32, 20, 20, 25, 255);
            // Body
            img.draw_rect(bx, by, bw as u32, bh as u32, fr, fg, fb, 255);
            // Top highlight
            img.draw_line(
                bx + 1,
                by + 1,
                bx + bw - 2,
                by + 1,
                fr.saturating_add(30),
                fg.saturating_add(30),
                fb.saturating_add(30),
                255,
            );
            // Border
            for i in 0..bw {
                img.set_pixel((bx + i) as u32, by as u32, br, bg, bb, 255);
                img.set_pixel((bx + i) as u32, (by + bh - 1) as u32, br, bg, bb, 255);
            }
            for i in 0..bh {
                img.set_pixel(bx as u32, (by + i) as u32, br, bg, bb, 255);
                img.set_pixel((bx + bw - 1) as u32, (by + i) as u32, br, bg, bb, 255);
            }
            // Label centred
            let lx = bx + (bw - label.len() as i32 * 4) / 2;
            let ly = by + (bh - 5) / 2;
            img.draw_label(label, lx, ly, tr, tg, tb);
            // State label below
            img.draw_label(label, bx + 5, by + bh + 8, 150, 150, 160);
        }

        img.draw_label("BUTTON STATES", 10, 10, 180, 180, 190);
        img
    }
}

impl Default for Theme {
    fn default() -> Self {
        Self::new()
    }
}
