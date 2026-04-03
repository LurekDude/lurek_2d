//! Container and layout widgets: Panel, Layout, ScrollPanel, NinePatch.
//!
//! Containers hold child widgets and optionally apply layout rules to them.
//! [`Panel`] is the simplest container.  [`Layout`] adds flexbox-inspired
//! positioning (horizontal, vertical, grid).  [`ScrollPanel`] provides a
//! scrollable viewport.  [`NinePatch`] computes nine-slice rectangles for
//! scalable panel borders.

use crate::gui::widget::{WidgetBase, WidgetType};

// ── Panel ─────────────────────────────────────────────────────────────────

/// Generic container widget that holds an ordered list of children.
///
/// The invisible root of the GUI widget tree is a `Panel`.  Panels can have
/// a title and optional scrolling behaviour.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `children` — `Vec<usize>`. Indices of child widgets in the context's pool.
/// - `title` — `String`. Optional panel title.
/// - `scrollable` — `bool`. Whether the panel clips and scrolls overflow.
#[derive(Debug, Clone)]
pub struct Panel {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Indices of child widgets in the context's pool.
    pub children: Vec<usize>,
    /// Optional panel title.
    pub title: String,
    /// Whether the panel clips and scrolls overflow.
    pub scrollable: bool,
}

impl Panel {
    /// Create a new empty panel.
    ///
    /// # Returns
    /// `Panel`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Panel),
            children: Vec::new(),
            title: String::new(),
            scrollable: false,
        }
    }
}

impl Default for Panel {
    fn default() -> Self {
        Self::new()
    }
}

// ── LayoutDirection ───────────────────────────────────────────────────────

/// Direction in which a [`Layout`] positions its children.
///
/// # Variants
/// - `Vertical` — Children stack top-to-bottom.
/// - `Horizontal` — Children flow left-to-right.
/// - `Grid` — Children placed in a fixed-column grid.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LayoutDirection {
    /// Children stack top-to-bottom.
    Vertical,
    /// Children flow left-to-right.
    Horizontal,
    /// Children placed in a fixed-column grid.
    Grid,
}

impl LayoutDirection {
    /// Parse a direction string.  Accepted: `"vertical"`, `"horizontal"`, `"grid"`.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<LayoutDirection>`.
    pub fn parse_str(s: &str) -> Option<Self> {
        match s {
            "vertical" => Some(Self::Vertical),
            "horizontal" => Some(Self::Horizontal),
            "grid" => Some(Self::Grid),
            _ => None,
        }
    }

    /// Return the lowercase string name.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Vertical => "vertical",
            Self::Horizontal => "horizontal",
            Self::Grid => "grid",
        }
    }
}

// ── Layout ────────────────────────────────────────────────────────────────

/// Flexbox-inspired layout container.
///
/// Arranges child widgets along a main axis (vertical, horizontal, or grid)
/// with configurable spacing, wrapping, cross-axis alignment, and main-axis
/// justification.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `children` — `Vec<usize>`. Child widget indices.
/// - `direction` — `LayoutDirection`. Main axis direction.
/// - `spacing` — `f32`. Gap between children in pixels.
/// - `columns` — `usize`. Column count for grid mode.
/// - `wrap` — `bool`. Whether children wrap to the next line.
/// - `align` — `String`. Cross-axis alignment: `"start"`, `"center"`, `"end"`, `"stretch"`.
/// - `justify` — `String`. Main-axis justification: `"start"`, `"center"`, `"end"`, `"space-between"`, `"space-around"`, `"space-evenly"`.
#[derive(Debug, Clone)]
pub struct Layout {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Child widget indices.
    pub children: Vec<usize>,
    /// Main axis direction.
    pub direction: LayoutDirection,
    /// Gap between children in pixels.
    pub spacing: f32,
    /// Column count for grid mode.
    pub columns: usize,
    /// Whether children wrap to the next line.
    pub wrap: bool,
    /// Cross-axis alignment.
    pub align: String,
    /// Main-axis justification.
    pub justify: String,
}

impl Layout {
    /// Create a new layout with the given direction, defaulting to zero
    /// spacing, no wrapping, `"start"` alignment and justification.
    ///
    /// # Parameters
    /// - `direction` — `LayoutDirection`.
    ///
    /// # Returns
    /// `Layout`.
    pub fn new(direction: LayoutDirection) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Layout),
            children: Vec::new(),
            direction,
            spacing: 0.0,
            columns: 1,
            wrap: false,
            align: "start".to_string(),
            justify: "start".to_string(),
        }
    }

    /// Recalculate child positions based on direction, spacing, alignment,
    /// and justification.
    ///
    /// This method updates the `x` / `y` fields of each child's `WidgetBase`
    /// in the provided mutable slice.  Children are referenced by index in
    /// `self.children`.
    ///
    /// # Parameters
    /// - `bases` — `&mut [WidgetBase]`. All widget bases, indexed by widget ID.
    pub fn perform_layout(&self, bases: &mut [WidgetBase]) {
        let pad = &self.base.padding;
        let mut cx = self.base.x + pad[3]; // left padding
        let mut cy = self.base.y + pad[0]; // top padding

        for &child_idx in &self.children {
            if child_idx >= bases.len() {
                continue;
            }
            let child = &mut bases[child_idx];
            if !child.visible {
                continue;
            }
            child.x = cx + child.margin[3];
            child.y = cy + child.margin[0];

            match self.direction {
                LayoutDirection::Vertical => {
                    cy += child.height + child.margin[0] + child.margin[2] + self.spacing;
                }
                LayoutDirection::Horizontal => {
                    cx += child.width + child.margin[1] + child.margin[3] + self.spacing;
                }
                LayoutDirection::Grid => {
                    // Simple grid: advance columns, then wrap
                    let col = self.children.iter().position(|&i| i == child_idx).unwrap_or(0);
                    let col_in_row = col % self.columns;
                    if col_in_row == self.columns - 1 {
                        cx = self.base.x + pad[3];
                        cy += child.height + child.margin[0] + child.margin[2] + self.spacing;
                    } else {
                        cx += child.width + child.margin[1] + child.margin[3] + self.spacing;
                    }
                }
            }
        }
    }
}

impl Default for Layout {
    fn default() -> Self {
        Self::new(LayoutDirection::Vertical)
    }
}

// ── ScrollPanel ───────────────────────────────────────────────────────────

/// Scrollable viewport container.
///
/// Clips child content to its own bounds and offsets children by a scroll
/// position.  Scroll speed controls how fast wheel events translate into
/// scroll offset changes.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `children` — `Vec<usize>`. Child widget indices.
/// - `content_width` — `f32`. Total scrollable content width.
/// - `content_height` — `f32`. Total scrollable content height.
/// - `scroll_x` — `f32`. Current horizontal scroll offset.
/// - `scroll_y` — `f32`. Current vertical scroll offset.
/// - `scroll_speed` — `f32`. Wheel-to-scroll multiplier.
#[derive(Debug, Clone)]
pub struct ScrollPanel {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Child widget indices.
    pub children: Vec<usize>,
    /// Total scrollable content width.
    pub content_width: f32,
    /// Total scrollable content height.
    pub content_height: f32,
    /// Current horizontal scroll offset.
    pub scroll_x: f32,
    /// Current vertical scroll offset.
    pub scroll_y: f32,
    /// Wheel-to-scroll multiplier.
    pub scroll_speed: f32,
}

impl ScrollPanel {
    /// Create a new scroll panel with default content size matching widget size.
    ///
    /// # Returns
    /// `ScrollPanel`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ScrollPanel),
            children: Vec::new(),
            content_width: 100.0,
            content_height: 100.0,
            scroll_x: 0.0,
            scroll_y: 0.0,
            scroll_speed: 20.0,
        }
    }

    /// Return the maximum scroll offset for each axis, clamped to zero.
    ///
    /// # Returns
    /// `(f32, f32)` — `(max_scroll_x, max_scroll_y)`.
    pub fn max_scroll(&self) -> (f32, f32) {
        let mx = (self.content_width - self.base.width).max(0.0);
        let my = (self.content_height - self.base.height).max(0.0);
        (mx, my)
    }

    /// Clamp scroll position to valid range.
    pub fn clamp_scroll(&mut self) {
        let (mx, my) = self.max_scroll();
        self.scroll_x = self.scroll_x.clamp(0.0, mx);
        self.scroll_y = self.scroll_y.clamp(0.0, my);
    }
}

impl Default for ScrollPanel {
    fn default() -> Self {
        Self::new()
    }
}

// ── NinePatch ─────────────────────────────────────────────────────────────

/// A nine-slice rectangle: `(sx, sy, sw, sh, dx, dy, dw, dh)`.
pub type NineSlice = (f32, f32, f32, f32, f32, f32, f32, f32);

/// Nine-slice data for scalable panel border rendering.
///
/// Given the source image dimensions and inset offsets from each edge, the
/// `get_slices` method computes nine `(sx, sy, sw, sh, dx, dy, dw, dh)`
/// rectangles that tile the source image onto the destination widget bounds
/// without distorting corners.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `inset_left` — `u32`. Left inset in source image pixels.
/// - `inset_top` — `u32`. Top inset in source image pixels.
/// - `inset_right` — `u32`. Right inset in source image pixels.
/// - `inset_bottom` — `u32`. Bottom inset in source image pixels.
/// - `image_width` — `u32`. Source image width.
/// - `image_height` — `u32`. Source image height.
#[derive(Debug, Clone)]
pub struct NinePatch {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Left inset in source image pixels.
    pub inset_left: u32,
    /// Top inset in source image pixels.
    pub inset_top: u32,
    /// Right inset in source image pixels.
    pub inset_right: u32,
    /// Bottom inset in source image pixels.
    pub inset_bottom: u32,
    /// Source image width.
    pub image_width: u32,
    /// Source image height.
    pub image_height: u32,
}

impl NinePatch {
    /// Create a new nine-patch with zero insets and zero image dimensions.
    ///
    /// # Returns
    /// `NinePatch`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::NinePatch),
            inset_left: 0,
            inset_top: 0,
            inset_right: 0,
            inset_bottom: 0,
            image_width: 0,
            image_height: 0,
        }
    }

    /// Compute the nine slice rectangles.
    ///
    /// Each returned element is `(sx, sy, sw, sh, dx, dy, dw, dh)` where
    /// `s*` are source coordinates and `d*` are destination coordinates on
    /// the widget.
    ///
    /// # Returns
    /// `Vec<(f32, f32, f32, f32, f32, f32, f32, f32)>`.
    pub fn get_slices(&self) -> Vec<NineSlice> {
        let il = self.inset_left as f32;
        let it = self.inset_top as f32;
        let ir = self.inset_right as f32;
        let ib = self.inset_bottom as f32;
        let iw = self.image_width as f32;
        let ih = self.image_height as f32;
        let dw = self.base.width;
        let dh = self.base.height;
        let dx = self.base.x;
        let dy = self.base.y;

        let sm = iw - il - ir; // source middle width
        let smh = ih - it - ib; // source middle height
        let dm = dw - il - ir; // dest middle width
        let dmh = dh - it - ib; // dest middle height

        vec![
            // Top-left corner
            (0.0, 0.0, il, it, dx, dy, il, it),
            // Top-center
            (il, 0.0, sm, it, dx + il, dy, dm, it),
            // Top-right corner
            (iw - ir, 0.0, ir, it, dx + dw - ir, dy, ir, it),
            // Middle-left
            (0.0, it, il, smh, dx, dy + it, il, dmh),
            // Middle-center
            (il, it, sm, smh, dx + il, dy + it, dm, dmh),
            // Middle-right
            (iw - ir, it, ir, smh, dx + dw - ir, dy + it, ir, dmh),
            // Bottom-left corner
            (0.0, ih - ib, il, ib, dx, dy + dh - ib, il, ib),
            // Bottom-center
            (il, ih - ib, sm, ib, dx + il, dy + dh - ib, dm, ib),
            // Bottom-right corner
            (iw - ir, ih - ib, ir, ib, dx + dw - ir, dy + dh - ib, ir, ib),
        ]
    }
}

impl Default for NinePatch {
    fn default() -> Self {
        Self::new()
    }
}


// ── GUIWindow ─────────────────────────────────────────────────────────

/// A draggable, closeable window container.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `title` — `String`. Window title bar text.
/// - `closeable` — `bool`. Whether the close button is shown.
/// - `draggable` — `bool`. Whether the window can be dragged.
/// - `resizable` — `bool`. Whether the window can be resized.
/// - `children` — `Vec<usize>`. Child widget indices.
#[derive(Debug, Clone)]
pub struct GUIWindow {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Window title bar text.
    pub title: String,
    /// Whether the close button is shown.
    pub closeable: bool,
    /// Whether the window can be dragged.
    pub draggable: bool,
    /// Whether the window can be resized.
    pub resizable: bool,
    /// Child widget indices.
    pub children: Vec<usize>,
}

impl GUIWindow {
    /// Create a new GUI window.
    ///
    /// # Parameters
    /// - `title` — `impl Into<String>`. Window title.
    ///
    /// # Returns
    /// `GUIWindow`.
    pub fn new(title: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::GUIWindow),
            title: title.into(),
            closeable: true,
            draggable: true,
            resizable: false,
            children: Vec::new(),
        }
    }
}

// ── SplitPanel ────────────────────────────────────────────────────────

/// A resizable split panel with two child regions.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `orientation` — `String`. `"horizontal"` or `"vertical"`.
/// - `split_position` — `f32`. Split ratio 0.0–1.0.
/// - `min_panel_size` — `f32`. Minimum panel size in pixels.
/// - `first_child` — `Option<usize>`. First panel widget index.
/// - `second_child` — `Option<usize>`. Second panel widget index.
#[derive(Debug, Clone)]
pub struct SplitPanel {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// `"horizontal"` or `"vertical"`.
    pub orientation: String,
    /// Split ratio 0.0–1.0.
    pub split_position: f32,
    /// Minimum panel size in pixels.
    pub min_panel_size: f32,
    /// First panel widget index.
    pub first_child: Option<usize>,
    /// Second panel widget index.
    pub second_child: Option<usize>,
}

impl SplitPanel {
    /// Create a new split panel.
    ///
    /// # Parameters
    /// - `orientation` — `impl Into<String>`. `"horizontal"` or `"vertical"`.
    ///
    /// # Returns
    /// `SplitPanel`.
    pub fn new(orientation: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::SplitPanel),
            orientation: orientation.into(),
            split_position: 0.5,
            min_panel_size: 50.0,
            first_child: None,
            second_child: None,
        }
    }
}

// ── DockPanel ─────────────────────────────────────────────────────────

/// A dock-based layout container with left/right/top/bottom/center regions.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `docked` — `Vec<(usize, String)>`. Pairs of `(widget_index, side)`.
/// - `split_sizes` — `Vec<(String, f32)>`. Per-side size overrides.
#[derive(Debug, Clone)]
pub struct DockPanel {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Pairs of `(widget_index, side)`.
    pub docked: Vec<(usize, String)>,
    /// Per-side size overrides.
    pub split_sizes: Vec<(String, f32)>,
}

impl DockPanel {
    /// Create a new dock panel.
    ///
    /// # Returns
    /// `DockPanel`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::DockPanel),
            docked: Vec::new(),
            split_sizes: Vec::new(),
        }
    }
}

impl Default for DockPanel {
    fn default() -> Self {
        Self::new()
    }
}
