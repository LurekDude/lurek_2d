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
/// Border width, corner radius, and shadow offset are in pixels.
///
/// # Fields
/// - `bg_color` — `[f32; 4]`. Background fill colour (RGBA).
/// - `fg_color` — `[f32; 4]`. Foreground / text colour (RGBA).
/// - `border_color` — `[f32; 4]`. Border stroke colour (RGBA).
/// - `border_width` — `f32`. Border stroke width in pixels.
/// - `corner_radius` — `f32`. Rounded corner radius in pixels.
/// - `font_size` — `f32`. Text size in pixels.
/// - `shadow_color` — `[f32; 4]`. Drop-shadow colour (alpha 0 = no shadow).
/// - `shadow_offset` — `[f32; 2]`. Drop-shadow pixel offset `[dx, dy]`.
/// - `highlight_alpha` — `f32`. Inner top-edge highlight brightness `[0.0, 1.0]`.
/// - `gradient_end` — `Option<[f32; 4]>`. Bottom gradient colour; `None` = solid fill.
/// - `text_align` — `String`. Horizontal text alignment: `"left"`, `"center"`, `"right"`.
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
    /// Drop-shadow colour.  Alpha 0 means no shadow is drawn.
    pub shadow_color: [f32; 4],
    /// Drop-shadow pixel offset `[dx, dy]`.
    pub shadow_offset: [f32; 2],
    /// Inner top-edge highlight strip brightness in `[0.0, 1.0]`.  0 = hidden.
    pub highlight_alpha: f32,
    /// Optional bottom gradient colour for the background fill.  `None` = solid.
    pub gradient_end: Option<[f32; 4]>,
    /// Horizontal text alignment: `"left"`, `"center"`, or `"right"`.
    pub text_align: String,
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
            shadow_color: [0.0, 0.0, 0.0, 0.0],
            shadow_offset: [0.0, 0.0],
            highlight_alpha: 0.0,
            gradient_end: None,
            text_align: "center".to_string(),
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
            let style = self.get_style(WidgetType::Button, *state);
            let (fr, fg, fb, br, bg, bb, tr, tg, tb) = if let Some(s) = style {
                let f = |c: [f32; 4]| {
                    (
                        (c[0] * 255.0) as u8,
                        (c[1] * 255.0) as u8,
                        (c[2] * 255.0) as u8,
                    )
                };
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

impl Theme {
    /// Create a dark theme pre-loaded with styled entries for all standard widget types.
    ///
    /// Provides sane dark-UI defaults:
    /// - Buttons: steel-blue with rounded 4 px corners and a drop shadow.
    /// - Labels: transparent background with light text.
    /// - TextInput: deep charcoal background with a blue focus border.
    /// - CheckBox / RadioButton: transparent with a 2 px border.
    /// - Slider / ProgressBar: dark track with a blue fill indicator.
    /// - ComboBox / ListBox: dark background with right-arrow indicator.
    /// - TabBar: dark tabs, active tab uses accent colour.
    /// - Panel: semi-transparent dark background.
    /// - SpinBox: same as Slider.
    /// - Switch: matches CheckBox.
    /// - Badge: accent red with white text.
    ///
    /// # Returns
    /// `Theme`.
    pub fn default_dark() -> Self {
        let mut t = Self::new();

        // ── helpers ──────────────────────────────────────────────────────────
        let mk = |bg: [f32; 4],
                  fg: [f32; 4],
                  border: [f32; 4],
                  bw: f32,
                  cr: f32,
                  fs: f32,
                  shadow: [f32; 4],
                  offset: [f32; 2],
                  hi: f32,
                  grad: Option<[f32; 4]>,
                  align: &str| {
            WidgetStyle {
                bg_color: bg,
                fg_color: fg,
                border_color: border,
                border_width: bw,
                corner_radius: cr,
                font_size: fs,
                shadow_color: shadow,
                shadow_offset: offset,
                highlight_alpha: hi,
                gradient_end: grad,
                text_align: align.to_string(),
            }
        };
        let none_shadow = [0.0f32, 0.0, 0.0, 0.0];
        let drop_shadow = [0.0f32, 0.0, 0.0, 0.5];

        // ── Button ───────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::Button,
            WidgetState::Normal,
            mk(
                [0.24, 0.47, 0.78, 1.0],
                [0.92, 0.95, 1.0, 1.0],
                [0.16, 0.35, 0.65, 1.0],
                1.0,
                4.0,
                14.0,
                drop_shadow,
                [2.0, 2.0],
                0.15,
                Some([0.18, 0.38, 0.68, 1.0]),
                "center",
            ),
        );
        t.set_style(
            WidgetType::Button,
            WidgetState::Hovered,
            mk(
                [0.32, 0.58, 0.90, 1.0],
                [1.0, 1.0, 1.0, 1.0],
                [0.22, 0.46, 0.78, 1.0],
                1.0,
                4.0,
                14.0,
                drop_shadow,
                [2.0, 2.0],
                0.22,
                Some([0.26, 0.50, 0.82, 1.0]),
                "center",
            ),
        );
        t.set_style(
            WidgetType::Button,
            WidgetState::Pressed,
            mk(
                [0.16, 0.33, 0.62, 1.0],
                [0.78, 0.84, 0.96, 1.0],
                [0.10, 0.24, 0.50, 1.0],
                1.0,
                4.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "center",
            ),
        );
        t.set_style(
            WidgetType::Button,
            WidgetState::Disabled,
            mk(
                [0.30, 0.30, 0.35, 1.0],
                [0.50, 0.50, 0.55, 1.0],
                [0.22, 0.22, 0.27, 1.0],
                1.0,
                4.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "center",
            ),
        );

        // ── Label ────────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::Label,
            WidgetState::Normal,
            mk(
                [0.0, 0.0, 0.0, 0.0],
                [0.88, 0.90, 0.94, 1.0],
                [0.0, 0.0, 0.0, 0.0],
                0.0,
                0.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::Label,
            WidgetState::Disabled,
            mk(
                [0.0, 0.0, 0.0, 0.0],
                [0.50, 0.50, 0.52, 1.0],
                [0.0, 0.0, 0.0, 0.0],
                0.0,
                0.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── TextInput ────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::TextInput,
            WidgetState::Normal,
            mk(
                [0.14, 0.14, 0.18, 1.0],
                [0.90, 0.92, 0.96, 1.0],
                [0.35, 0.35, 0.42, 1.0],
                1.0,
                2.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::TextInput,
            WidgetState::Focused,
            mk(
                [0.12, 0.12, 0.16, 1.0],
                [1.0, 1.0, 1.0, 1.0],
                [0.24, 0.47, 0.78, 1.0],
                2.0,
                2.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::TextInput,
            WidgetState::Disabled,
            mk(
                [0.18, 0.18, 0.22, 1.0],
                [0.45, 0.45, 0.50, 1.0],
                [0.28, 0.28, 0.33, 1.0],
                1.0,
                2.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── CheckBox ─────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::CheckBox,
            WidgetState::Normal,
            mk(
                [0.0, 0.0, 0.0, 0.0],
                [0.88, 0.90, 0.94, 1.0],
                [0.50, 0.52, 0.58, 1.0],
                2.0,
                2.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::CheckBox,
            WidgetState::Hovered,
            mk(
                [0.22, 0.22, 0.28, 0.5],
                [1.0, 1.0, 1.0, 1.0],
                [0.24, 0.47, 0.78, 1.0],
                2.0,
                2.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── RadioButton ──────────────────────────────────────────────────────
        t.set_style(
            WidgetType::RadioButton,
            WidgetState::Normal,
            mk(
                [0.0, 0.0, 0.0, 0.0],
                [0.88, 0.90, 0.94, 1.0],
                [0.50, 0.52, 0.58, 1.0],
                2.0,
                0.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── Slider ───────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::Slider,
            WidgetState::Normal,
            mk(
                [0.20, 0.20, 0.26, 1.0],
                [0.92, 0.95, 1.0, 1.0],
                [0.35, 0.35, 0.42, 1.0],
                1.0,
                2.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                Some([0.24, 0.47, 0.78, 1.0]),
                "center",
            ),
        );

        // ── ProgressBar ──────────────────────────────────────────────────────
        t.set_style(
            WidgetType::ProgressBar,
            WidgetState::Normal,
            mk(
                [0.16, 0.16, 0.20, 1.0],
                [0.92, 0.95, 1.0, 1.0],
                [0.30, 0.30, 0.36, 1.0],
                1.0,
                2.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                Some([0.20, 0.55, 0.30, 1.0]),
                "center",
            ),
        );

        // ── ComboBox ─────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::ComboBox,
            WidgetState::Normal,
            mk(
                [0.16, 0.16, 0.20, 1.0],
                [0.88, 0.90, 0.94, 1.0],
                [0.35, 0.35, 0.42, 1.0],
                1.0,
                2.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── ListBox ──────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::ListBox,
            WidgetState::Normal,
            mk(
                [0.13, 0.13, 0.17, 1.0],
                [0.86, 0.88, 0.92, 1.0],
                [0.32, 0.32, 0.38, 1.0],
                1.0,
                2.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── TabBar ───────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::TabBar,
            WidgetState::Normal,
            mk(
                [0.18, 0.18, 0.24, 1.0],
                [0.72, 0.74, 0.80, 1.0],
                [0.30, 0.30, 0.38, 1.0],
                1.0,
                3.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "center",
            ),
        );
        t.set_style(
            WidgetType::TabBar,
            WidgetState::Focused,
            mk(
                [0.14, 0.14, 0.20, 1.0],
                [1.0, 1.0, 1.0, 1.0],
                [0.24, 0.47, 0.78, 1.0],
                2.0,
                3.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.12,
                None,
                "center",
            ),
        );

        // ── Panel ────────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::Panel,
            WidgetState::Normal,
            mk(
                [0.15, 0.15, 0.20, 0.92],
                [0.88, 0.90, 0.94, 1.0],
                [0.28, 0.28, 0.35, 1.0],
                1.0,
                0.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── SpinBox ──────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::SpinBox,
            WidgetState::Normal,
            mk(
                [0.14, 0.14, 0.18, 1.0],
                [0.90, 0.92, 0.96, 1.0],
                [0.35, 0.35, 0.42, 1.0],
                1.0,
                2.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "center",
            ),
        );
        t.set_style(
            WidgetType::SpinBox,
            WidgetState::Focused,
            mk(
                [0.12, 0.12, 0.16, 1.0],
                [1.0, 1.0, 1.0, 1.0],
                [0.24, 0.47, 0.78, 1.0],
                2.0,
                2.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "center",
            ),
        );

        // ── Switch ───────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::Switch,
            WidgetState::Normal,
            mk(
                [0.28, 0.28, 0.34, 1.0],
                [0.88, 0.90, 0.94, 1.0],
                [0.40, 0.40, 0.48, 1.0],
                1.0,
                12.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::Switch,
            WidgetState::Pressed,
            mk(
                [0.20, 0.55, 0.30, 1.0],
                [1.0, 1.0, 1.0, 1.0],
                [0.14, 0.42, 0.22, 1.0],
                1.0,
                12.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── Badge ────────────────────────────────────────────────────────────
        t.set_style(
            WidgetType::Badge,
            WidgetState::Normal,
            mk(
                [0.82, 0.18, 0.18, 1.0],
                [1.0, 1.0, 1.0, 1.0],
                [0.60, 0.10, 0.10, 1.0],
                0.0,
                8.0,
                11.0,
                drop_shadow,
                [1.0, 1.0],
                0.0,
                None,
                "center",
            ),
        );

        // ── ScrollPanel / NinePatch ───────────────────────────────────────
        t.set_style(
            WidgetType::ScrollPanel,
            WidgetState::Normal,
            mk(
                [0.12, 0.12, 0.16, 0.96],
                [0.86, 0.88, 0.92, 1.0],
                [0.24, 0.24, 0.30, 1.0],
                1.0,
                0.0,
                14.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::NinePatch,
            WidgetState::Normal,
            mk(
                [0.17, 0.17, 0.22, 0.96],
                [0.88, 0.90, 0.94, 1.0],
                [0.30, 0.30, 0.36, 1.0],
                1.0,
                4.0,
                14.0,
                drop_shadow,
                [1.0, 1.0],
                0.08,
                Some([0.12, 0.12, 0.18, 0.96]),
                "left",
            ),
        );

        // ── Toast / Separator / Spacer ────────────────────────────────────
        t.set_style(
            WidgetType::Toast,
            WidgetState::Normal,
            mk(
                [0.14, 0.14, 0.18, 0.98],
                [0.92, 0.94, 0.98, 1.0],
                [0.28, 0.34, 0.55, 1.0],
                1.0,
                6.0,
                14.0,
                drop_shadow,
                [2.0, 2.0],
                0.08,
                Some([0.11, 0.11, 0.16, 0.98]),
                "left",
            ),
        );
        t.set_style(
            WidgetType::Separator,
            WidgetState::Normal,
            mk(
                [0.0, 0.0, 0.0, 0.0],
                [0.30, 0.32, 0.38, 1.0],
                [0.30, 0.32, 0.38, 1.0],
                0.0,
                0.0,
                1.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::Spacer,
            WidgetState::Normal,
            mk(
                [0.0, 0.0, 0.0, 0.0],
                [0.0, 0.0, 0.0, 0.0],
                [0.0, 0.0, 0.0, 0.0],
                0.0,
                0.0,
                1.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── Tree / ScrollBar ───────────────────────────────────────────────
        t.set_style(
            WidgetType::TreeView,
            WidgetState::Normal,
            mk(
                [0.12, 0.12, 0.16, 1.0],
                [0.86, 0.88, 0.92, 1.0],
                [0.28, 0.28, 0.34, 1.0],
                1.0,
                2.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::ScrollBar,
            WidgetState::Normal,
            mk(
                [0.12, 0.12, 0.16, 1.0],
                [0.46, 0.52, 0.64, 1.0],
                [0.20, 0.20, 0.26, 1.0],
                1.0,
                6.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "center",
            ),
        );
        t.set_style(
            WidgetType::ScrollBar,
            WidgetState::Hovered,
            mk(
                [0.12, 0.12, 0.16, 1.0],
                [0.58, 0.66, 0.82, 1.0],
                [0.24, 0.30, 0.42, 1.0],
                1.0,
                6.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "center",
            ),
        );

        // ── Windows / Docking ──────────────────────────────────────────────
        t.set_style(
            WidgetType::GUIWindow,
            WidgetState::Normal,
            mk(
                [0.14, 0.15, 0.19, 0.98],
                [0.90, 0.93, 0.98, 1.0],
                [0.28, 0.30, 0.38, 1.0],
                1.0,
                6.0,
                14.0,
                drop_shadow,
                [3.0, 3.0],
                0.10,
                Some([0.10, 0.11, 0.15, 0.98]),
                "left",
            ),
        );
        t.set_style(
            WidgetType::SplitPanel,
            WidgetState::Normal,
            mk(
                [0.12, 0.12, 0.16, 0.90],
                [0.86, 0.88, 0.92, 1.0],
                [0.26, 0.28, 0.34, 1.0],
                1.0,
                0.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::DockPanel,
            WidgetState::Normal,
            mk(
                [0.13, 0.13, 0.17, 0.92],
                [0.88, 0.90, 0.94, 1.0],
                [0.26, 0.28, 0.34, 1.0],
                1.0,
                0.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::Dialog,
            WidgetState::Normal,
            mk(
                [0.15, 0.16, 0.20, 0.99],
                [0.92, 0.94, 0.98, 1.0],
                [0.30, 0.32, 0.40, 1.0],
                1.0,
                8.0,
                14.0,
                drop_shadow,
                [4.0, 4.0],
                0.10,
                Some([0.11, 0.12, 0.16, 0.99]),
                "left",
            ),
        );

        // ── Bars / Menus / Tooling ─────────────────────────────────────────
        t.set_style(
            WidgetType::Toolbar,
            WidgetState::Normal,
            mk(
                [0.16, 0.17, 0.22, 1.0],
                [0.88, 0.90, 0.94, 1.0],
                [0.26, 0.28, 0.36, 1.0],
                1.0,
                0.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.06,
                Some([0.13, 0.14, 0.18, 1.0]),
                "left",
            ),
        );
        t.set_style(
            WidgetType::MenuBar,
            WidgetState::Normal,
            mk(
                [0.16, 0.17, 0.22, 1.0],
                [0.88, 0.90, 0.94, 1.0],
                [0.24, 0.26, 0.32, 1.0],
                1.0,
                0.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.08,
                Some([0.12, 0.13, 0.17, 1.0]),
                "left",
            ),
        );
        t.set_style(
            WidgetType::MenuItem,
            WidgetState::Normal,
            mk(
                [0.0, 0.0, 0.0, 0.0],
                [0.88, 0.90, 0.94, 1.0],
                [0.0, 0.0, 0.0, 0.0],
                0.0,
                2.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::MenuItem,
            WidgetState::Hovered,
            mk(
                [0.22, 0.33, 0.52, 0.85],
                [1.0, 1.0, 1.0, 1.0],
                [0.0, 0.0, 0.0, 0.0],
                0.0,
                2.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::StatusBar,
            WidgetState::Normal,
            mk(
                [0.15, 0.16, 0.20, 1.0],
                [0.80, 0.84, 0.90, 1.0],
                [0.24, 0.26, 0.32, 1.0],
                1.0,
                0.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        // ── Accordion / Tooltip ───────────────────────────────────────────
        t.set_style(
            WidgetType::Accordion,
            WidgetState::Normal,
            mk(
                [0.13, 0.13, 0.18, 0.96],
                [0.88, 0.90, 0.94, 1.0],
                [0.26, 0.28, 0.34, 1.0],
                1.0,
                4.0,
                13.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::TooltipPanel,
            WidgetState::Normal,
            mk(
                [0.12, 0.12, 0.16, 0.98],
                [0.96, 0.94, 0.86, 1.0],
                [0.64, 0.54, 0.22, 1.0],
                1.0,
                4.0,
                12.0,
                drop_shadow,
                [1.0, 1.0],
                0.06,
                Some([0.16, 0.14, 0.10, 0.98]),
                "left",
            ),
        );

        // ── Data widgets ───────────────────────────────────────────────────
        t.set_style(
            WidgetType::ColorPicker,
            WidgetState::Normal,
            mk(
                [0.12, 0.12, 0.16, 1.0],
                [0.88, 0.90, 0.94, 1.0],
                [0.28, 0.28, 0.34, 1.0],
                1.0,
                4.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::GUITable,
            WidgetState::Normal,
            mk(
                [0.12, 0.12, 0.16, 1.0],
                [0.86, 0.88, 0.92, 1.0],
                [0.28, 0.28, 0.34, 1.0],
                1.0,
                2.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );
        t.set_style(
            WidgetType::ImageWidget,
            WidgetState::Normal,
            mk(
                [0.12, 0.12, 0.16, 1.0],
                [0.70, 0.74, 0.82, 1.0],
                [0.30, 0.32, 0.38, 1.0],
                1.0,
                2.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "center",
            ),
        );
        t.set_style(
            WidgetType::Custom,
            WidgetState::Normal,
            mk(
                [0.12, 0.12, 0.16, 0.65],
                [0.88, 0.90, 0.94, 1.0],
                [0.24, 0.26, 0.32, 1.0],
                1.0,
                2.0,
                12.0,
                none_shadow,
                [0.0, 0.0],
                0.0,
                None,
                "left",
            ),
        );

        t
    }
}
