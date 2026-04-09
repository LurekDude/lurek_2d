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

use crate::gui::widget::{WidgetState, WidgetType};

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
}

impl Default for Theme {
    fn default() -> Self {
        Self::new()
    }
}
