//! Utility widgets: toast notifications, separators, spacers, and tree views.
//!
//! These widgets serve auxiliary UI roles — visual dividers, empty spacing,
//! auto-expiring notification overlays, and collapsible hierarchical trees.

use crate::gui::widget::{WidgetBase, WidgetType};

// ── Toast ─────────────────────────────────────────────────────────────────

/// Auto-expiring notification overlay.
///
/// A toast displays a message for a configurable duration, tracking elapsed
/// time so that the GUI context can remove it once it expires.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `message` — `String`. Notification text.
/// - `duration` — `f32`. Total display time in seconds.
/// - `elapsed` — `f32`. Time elapsed since display started.
#[derive(Debug, Clone)]
pub struct Toast {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Notification text.
    pub message: String,
    /// Total display time in seconds.
    pub duration: f32,
    /// Time elapsed since display started.
    pub elapsed: f32,
}

impl Toast {
    /// Create a new toast with the given message and duration.
    ///
    /// # Parameters
    /// - `message` — `impl Into<String>`. Notification text.
    /// - `duration` — `f32`. Display duration in seconds.
    ///
    /// # Returns
    /// `Toast`.
    pub fn new(message: impl Into<String>, duration: f32) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Toast),
            message: message.into(),
            duration,
            elapsed: 0.0,
        }
    }

    /// Return the progress through the toast's lifetime as `[0.0, 1.0]`.
    ///
    /// # Returns
    /// `f32`.
    pub fn progress(&self) -> f32 {
        if self.duration <= 0.0 {
            1.0
        } else {
            (self.elapsed / self.duration).clamp(0.0, 1.0)
        }
    }

    /// Return `true` if the toast has exceeded its display duration.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_expired(&self) -> bool {
        self.elapsed >= self.duration
    }

    /// Advance the elapsed timer by `dt` seconds.
    ///
    /// # Parameters
    /// - `dt` — `f32`. Delta time in seconds.
    pub fn update(&mut self, dt: f32) {
        self.elapsed += dt;
    }
}

// ── Separator ─────────────────────────────────────────────────────────────

/// Visual divider line widget.
///
/// Draws a horizontal or vertical line with a configurable thickness.  Does
/// not accept input or hold children.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `vertical` — `bool`. `true` for a vertical line, `false` for horizontal.
/// - `thickness` — `f32`. Line thickness in pixels.
#[derive(Debug, Clone)]
pub struct Separator {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// `true` for a vertical line, `false` for horizontal.
    pub vertical: bool,
    /// Line thickness in pixels.
    pub thickness: f32,
}

impl Separator {
    /// Create a new separator.
    ///
    /// # Parameters
    /// - `vertical` — `bool`. Orientation.
    ///
    /// # Returns
    /// `Separator`.
    pub fn new(vertical: bool) -> Self {
        let mut base = WidgetBase::new(WidgetType::Separator);
        if vertical {
            base.width = 2.0;
            base.height = 30.0;
        } else {
            base.width = 100.0;
            base.height = 2.0;
        }
        Self {
            base,
            vertical,
            thickness: 1.0,
        }
    }
}

// ── Spacer ────────────────────────────────────────────────────────────────

/// Empty layout filler widget.
///
/// Takes up space in a layout without rendering anything.  Useful for pushing
/// other widgets apart.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
#[derive(Debug, Clone)]
pub struct Spacer {
    /// Shared widget properties.
    pub base: WidgetBase,
}

impl Spacer {
    /// Create a new spacer with the given dimensions.
    ///
    /// # Parameters
    /// - `width` — `f32`. Width in pixels.
    /// - `height` — `f32`. Height in pixels.
    ///
    /// # Returns
    /// `Spacer`.
    pub fn new(width: f32, height: f32) -> Self {
        let mut base = WidgetBase::new(WidgetType::Spacer);
        base.width = width;
        base.height = height;
        Self { base }
    }
}

impl Default for Spacer {
    fn default() -> Self {
        Self::new(0.0, 0.0)
    }
}

// ── TreeNode ──────────────────────────────────────────────────────────────

/// A single node in a [`TreeView`] hierarchy.
///
/// # Fields
/// - `text` — `String`. Display label.
/// - `children` — `Vec<usize>`. Indices of child nodes in the tree's flat pool.
/// - `expanded` — `bool`. Whether child nodes are visible.
/// - `parent` — `Option<usize>`. Index of the parent node (None for root-level).
#[derive(Debug, Clone)]
pub struct TreeNode {
    /// Display label.
    pub text: String,
    /// Indices of child nodes in the tree's flat pool.
    pub children: Vec<usize>,
    /// Whether child nodes are visible.
    pub expanded: bool,
    /// Index of the parent node (None for root-level).
    pub parent: Option<usize>,
}

impl TreeNode {
    /// Create a new tree node with the given label and optional parent.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`. Display label.
    /// - `parent` — `Option<usize>`. Parent node index.
    ///
    /// # Returns
    /// `TreeNode`.
    pub fn new(text: impl Into<String>, parent: Option<usize>) -> Self {
        Self {
            text: text.into(),
            children: Vec::new(),
            expanded: false,
            parent,
        }
    }
}

// ── TreeView ──────────────────────────────────────────────────────────────

/// Collapsible hierarchical tree widget.
///
/// Stores nodes in a flat `Vec` with parent/child index links.
/// Root-level nodes have `parent = None`.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `nodes` — `Vec<TreeNode>`. Flat pool of all tree nodes.
/// - `root_nodes` — `Vec<usize>`. Indices of root-level nodes.
#[derive(Debug, Clone)]
pub struct TreeView {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Flat pool of all tree nodes.
    pub nodes: Vec<TreeNode>,
    /// Indices of root-level nodes.
    pub root_nodes: Vec<usize>,
}

impl TreeView {
    /// Create a new empty tree view.
    ///
    /// # Returns
    /// `TreeView`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::TreeView),
            nodes: Vec::new(),
            root_nodes: Vec::new(),
        }
    }

    /// Add a node to the tree.
    ///
    /// If `parent_index` is `None`, the node is a root-level entry.
    /// If `parent_index` is `Some(idx)`, the node is added as a child of node
    /// at index `idx`.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`. Node label.
    /// - `parent_index` — `Option<usize>`. 0-based parent index.
    ///
    /// # Returns
    /// `usize` — the 0-based index of the new node.
    pub fn add_node(&mut self, text: impl Into<String>, parent_index: Option<usize>) -> usize {
        let idx = self.nodes.len();
        let node = TreeNode::new(text, parent_index);
        self.nodes.push(node);

        if let Some(pi) = parent_index {
            if pi < self.nodes.len() - 1 {
                self.nodes[pi].children.push(idx);
            }
        } else {
            self.root_nodes.push(idx);
        }

        idx
    }

    /// Toggle the expanded state of a node.
    ///
    /// # Parameters
    /// - `index` — `usize`. 0-based node index.
    ///
    /// # Returns
    /// `bool` — `true` if the node existed and was toggled.
    pub fn toggle_node(&mut self, index: usize) -> bool {
        if let Some(node) = self.nodes.get_mut(index) {
            node.expanded = !node.expanded;
            true
        } else {
            false
        }
    }

    /// Return the total number of nodes.
    ///
    /// # Returns
    /// `usize`.
    pub fn node_count(&self) -> usize {
        self.nodes.len()
    }
}

impl Default for TreeView {
    fn default() -> Self {
        Self::new()
    }
}


// ── Toolbar ───────────────────────────────────────────────────────────

/// A toolbar container for buttons and separators.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `orientation` — `String`. `"horizontal"` or `"vertical"`.
/// - `children` — `Vec<usize>`. Child widget indices.
#[derive(Debug, Clone)]
pub struct Toolbar {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// `"horizontal"` or `"vertical"`.
    pub orientation: String,
    /// Child widget indices.
    pub children: Vec<usize>,
}

impl Toolbar {
    /// Create a new toolbar.
    ///
    /// # Parameters
    /// - `orientation` — `impl Into<String>`. `"horizontal"` or `"vertical"`.
    ///
    /// # Returns
    /// `Toolbar`.
    pub fn new(orientation: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Toolbar),
            orientation: orientation.into(),
            children: Vec::new(),
        }
    }
}

// ── MenuBar ───────────────────────────────────────────────────────────

/// A horizontal menu bar.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `menus` — `Vec<usize>`. Top-level menu item widget indices.
#[derive(Debug, Clone)]
pub struct MenuBar {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Top-level menu item widget indices.
    pub menus: Vec<usize>,
}

impl MenuBar {
    /// Create a new menu bar.
    ///
    /// # Returns
    /// `MenuBar`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::MenuBar),
            menus: Vec::new(),
        }
    }
}

impl Default for MenuBar {
    fn default() -> Self {
        Self::new()
    }
}

// ── MenuItem ──────────────────────────────────────────────────────────

/// A menu item usable in menus and context menus.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `text` — `String`. Item display text.
/// - `shortcut` — `String`. Keyboard shortcut display text.
/// - `checked` — `bool`. Check mark state.
/// - `items` — `Vec<usize>`. Sub-item widget indices.
#[derive(Debug, Clone)]
pub struct MenuItem {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Item display text.
    pub text: String,
    /// Keyboard shortcut display text.
    pub shortcut: String,
    /// Check mark state.
    pub checked: bool,
    /// Sub-item widget indices.
    pub items: Vec<usize>,
}

impl MenuItem {
    /// Create a new menu item.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`. Item text.
    ///
    /// # Returns
    /// `MenuItem`.
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::MenuItem),
            text: text.into(),
            shortcut: String::new(),
            checked: false,
            items: Vec::new(),
        }
    }
}

// ── Dialog ────────────────────────────────────────────────────────────

/// A modal dialog window.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `title` — `String`. Dialog title.
/// - `modal` — `bool`. Whether the dialog blocks background input.
/// - `open` — `bool`. Whether the dialog is currently displayed.
#[derive(Debug, Clone)]
pub struct Dialog {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Dialog title.
    pub title: String,
    /// Whether the dialog blocks background input.
    pub modal: bool,
    /// Whether the dialog is currently displayed.
    pub open: bool,
}

impl Dialog {
    /// Create a new dialog.
    ///
    /// # Parameters
    /// - `title` — `impl Into<String>`. Dialog title.
    ///
    /// # Returns
    /// `Dialog`.
    pub fn new(title: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Dialog),
            title: title.into(),
            modal: true,
            open: false,
        }
    }
}

// ── StatusBar ─────────────────────────────────────────────────────────

/// A status bar with named sections.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `sections` — `Vec<(String, f32)>`. `(text, width)` pairs.
#[derive(Debug, Clone)]
pub struct StatusBar {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// `(text, width)` pairs.
    pub sections: Vec<(String, f32)>,
}

impl StatusBar {
    /// Create a new status bar.
    ///
    /// # Returns
    /// `StatusBar`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::StatusBar),
            sections: Vec::new(),
        }
    }
}

impl Default for StatusBar {
    fn default() -> Self {
        Self::new()
    }
}

// ── Accordion ─────────────────────────────────────────────────────────

/// A single section in an [`Accordion`].
///
/// # Fields
/// - `title` — `String`. Section header text.
/// - `content_idx` — `Option<usize>`. Content widget index.
/// - `expanded` — `bool`. Whether section is expanded.
#[derive(Debug, Clone)]
pub struct AccordionSection {
    /// Section header text.
    pub title: String,
    /// Content widget index.
    pub content_idx: Option<usize>,
    /// Whether section is expanded.
    pub expanded: bool,
}

/// A collapsible accordion container with named sections.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `sections` — `Vec<AccordionSection>`. Accordion sections.
/// - `exclusive` — `bool`. If true, only one section can be expanded at a time.
#[derive(Debug, Clone)]
pub struct Accordion {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Accordion sections.
    pub sections: Vec<AccordionSection>,
    /// If true, only one section can be expanded at a time.
    pub exclusive: bool,
}

impl Accordion {
    /// Create a new accordion.
    ///
    /// # Returns
    /// `Accordion`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::Accordion),
            sections: Vec::new(),
            exclusive: false,
        }
    }
}

impl Default for Accordion {
    fn default() -> Self {
        Self::new()
    }
}

// ── TooltipPanel ──────────────────────────────────────────────────────

/// A rich tooltip panel attached to a target widget.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `text` — `String`. Tooltip text.
/// - `delay` — `f32`. Hover delay in seconds before showing.
/// - `target_idx` — `Option<usize>`. Target widget index.
#[derive(Debug, Clone)]
pub struct TooltipPanel {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Tooltip text.
    pub text: String,
    /// Hover delay in seconds before showing.
    pub delay: f32,
    /// Target widget index.
    pub target_idx: Option<usize>,
}

impl TooltipPanel {
    /// Create a new tooltip panel.
    ///
    /// # Parameters
    /// - `text` — `impl Into<String>`. Tooltip text.
    ///
    /// # Returns
    /// `TooltipPanel`.
    pub fn new(text: impl Into<String>) -> Self {
        Self {
            base: WidgetBase::new(WidgetType::TooltipPanel),
            text: text.into(),
            delay: 0.5,
            target_idx: None,
        }
    }
}

// ── ColorPicker ───────────────────────────────────────────────────────

/// A color picker widget with RGB/HSV/HSL modes.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `r` — `f32`. Red component 0.0–1.0.
/// - `g` — `f32`. Green component 0.0–1.0.
/// - `b` — `f32`. Blue component 0.0–1.0.
/// - `a` — `f32`. Alpha component 0.0–1.0.
/// - `show_alpha` — `bool`. Whether to show the alpha slider.
/// - `color_mode` — `String`. `"rgb"`, `"hsv"`, or `"hsl"`.
#[derive(Debug, Clone)]
pub struct ColorPicker {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Red component 0.0–1.0.
    pub r: f32,
    /// Green component 0.0–1.0.
    pub g: f32,
    /// Blue component 0.0–1.0.
    pub b: f32,
    /// Alpha component 0.0–1.0.
    pub a: f32,
    /// Whether to show the alpha slider.
    pub show_alpha: bool,
    /// `"rgb"`, `"hsv"`, or `"hsl"`.
    pub color_mode: String,
}

impl ColorPicker {
    /// Create a new color picker.
    ///
    /// # Returns
    /// `ColorPicker`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ColorPicker),
            r: 1.0,
            g: 1.0,
            b: 1.0,
            a: 1.0,
            show_alpha: true,
            color_mode: "rgb".to_string(),
        }
    }
}

impl Default for ColorPicker {
    fn default() -> Self {
        Self::new()
    }
}

// ── GUITable ──────────────────────────────────────────────────────────

/// A single column in a [`GUITable`].
///
/// # Fields
/// - `header` — `String`. Column header text.
/// - `width` — `f32`. Column width in pixels.
#[derive(Debug, Clone)]
pub struct TableColumn {
    /// Column header text.
    pub header: String,
    /// Column width in pixels.
    pub width: f32,
}

/// A data table widget with sortable columns and selectable rows.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `columns` — `Vec<TableColumn>`. Column definitions.
/// - `rows` — `Vec<Vec<String>>`. Row data.
/// - `selected_row` — `Option<usize>`. Currently selected row (0-based).
/// - `sortable` — `bool`. Whether columns can be sorted by clicking headers.
#[derive(Debug, Clone)]
pub struct GUITable {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// Column definitions.
    pub columns: Vec<TableColumn>,
    /// Row data.
    pub rows: Vec<Vec<String>>,
    /// Currently selected row (0-based).
    pub selected_row: Option<usize>,
    /// Whether columns can be sorted by clicking headers.
    pub sortable: bool,
}

impl GUITable {
    /// Create a new data table.
    ///
    /// # Returns
    /// `GUITable`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::GUITable),
            columns: Vec::new(),
            rows: Vec::new(),
            selected_row: None,
            sortable: false,
        }
    }
}

impl Default for GUITable {
    fn default() -> Self {
        Self::new()
    }
}

// ── ImageWidget ───────────────────────────────────────────────────────

/// An image display widget.
///
/// # Fields
/// - `base` — `WidgetBase`. Shared widget properties.
/// - `scale_mode` — `String`. `"fit"`, `"fill"`, `"stretch"`, or `"none"`.
/// - `tint` — `(f32, f32, f32, f32)`. RGBA tint colour.
#[derive(Debug, Clone)]
pub struct ImageWidget {
    /// Shared widget properties.
    pub base: WidgetBase,
    /// `"fit"`, `"fill"`, `"stretch"`, or `"none"`.
    pub scale_mode: String,
    /// RGBA tint colour.
    pub tint: (f32, f32, f32, f32),
}

impl ImageWidget {
    /// Create a new image widget.
    ///
    /// # Returns
    /// `ImageWidget`.
    pub fn new() -> Self {
        Self {
            base: WidgetBase::new(WidgetType::ImageWidget),
            scale_mode: "fit".to_string(),
            tint: (1.0, 1.0, 1.0, 1.0),
        }
    }
}

impl Default for ImageWidget {
    fn default() -> Self {
        Self::new()
    }
}
