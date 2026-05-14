//! Core widget primitive types for `lurek.ui` — `WidgetState`, `WidgetType`, `WidgetTransitionKind`,
//! `WidgetTransition`, and `WidgetBase`.
//! `WidgetBase` is embedded in every concrete widget struct as the common layout and state carrier.
//! Depends on `crate::math::Rect`.

/// Interaction state of a widget used as a theme lookup key.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WidgetState {
    /// Idle, no interaction.
    Normal,
    /// Cursor is over the widget.
    Hovered,
    /// Widget is held down / actively interacted with.
    Pressed,
    /// Widget has keyboard focus.
    Focused,
    /// Widget does not respond to interaction.
    Disabled,
}
impl WidgetState {
    /// Parse a lowercase state name to a variant, or return `None` if unrecognised.
    pub fn parse_str(s: &str) -> Option<Self> {
        match s {
            "normal" => Some(Self::Normal),
            "hovered" => Some(Self::Hovered),
            "pressed" => Some(Self::Pressed),
            "focused" => Some(Self::Focused),
            "disabled" => Some(Self::Disabled),
            _ => None,
        }
    }
    /// Return the canonical lowercase name string for this state.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Normal => "normal",
            Self::Hovered => "hovered",
            Self::Pressed => "pressed",
            Self::Focused => "focused",
            Self::Disabled => "disabled",
        }
    }
}
/// Discriminated widget class used as the second key in `Theme` style lookups and for dispatch.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WidgetType {
    /// Push-button.
    Button,
    /// Read-only text display.
    Label,
    /// Editable single-line text field.
    TextInput,
    /// Toggle tick-box.
    CheckBox,
    /// Draggable value slider.
    Slider,
    /// Read-only fill bar.
    ProgressBar,
    /// Drop-down selection list.
    ComboBox,
    /// Scrollable item list.
    ListBox,
    /// Plain rectangular container.
    Panel,
    /// Flow-layout container.
    Layout,
    /// Overflow container with a scroll offset.
    ScrollPanel,
    /// 9-slice stretchable image frame.
    NinePatch,
    /// Tab strip switching between panes.
    TabBar,
    /// Auto-expiring overlay notification.
    Toast,
    /// Visual divider line.
    Separator,
    /// Blank space filler.
    Spacer,
    /// Collapsible hierarchical list.
    TreeView,
    /// Single-select group option.
    RadioButton,
    /// Standalone scroll track + thumb.
    ScrollBar,
    /// Draggable window pane.
    GUIWindow,
    /// Two-pane adjustable divider container.
    SplitPanel,
    /// Dock-zone container.
    DockPanel,
    /// Icon button strip.
    Toolbar,
    /// Application-level menu bar.
    MenuBar,
    /// Single menu item, possibly with sub-items.
    MenuItem,
    /// Modal or non-modal overlay dialog.
    Dialog,
    /// Application footer info bar.
    StatusBar,
    /// Stacked collapsible section list.
    Accordion,
    /// Hover overlay for target widget.
    TooltipPanel,
    /// RGBA/HSV colour selector.
    ColorPicker,
    /// Column-row data grid.
    GUITable,
    /// Static image display.
    ImageWidget,
    /// Numeric step input.
    SpinBox,
    /// On/off toggle with animated thumb.
    Switch,
    /// Numeric count overlay.
    Badge,
    /// Fully caller-drawn widget.
    Custom,
}
impl WidgetType {
    /// Return the canonical lowercase name string for this type.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Button => "button",
            Self::Label => "label",
            Self::TextInput => "textinput",
            Self::CheckBox => "checkbox",
            Self::Slider => "slider",
            Self::ProgressBar => "progressbar",
            Self::ComboBox => "combobox",
            Self::ListBox => "listbox",
            Self::Panel => "panel",
            Self::Layout => "layout",
            Self::ScrollPanel => "scrollpanel",
            Self::NinePatch => "ninepatch",
            Self::TabBar => "tabbar",
            Self::Toast => "toast",
            Self::Separator => "separator",
            Self::Spacer => "spacer",
            Self::TreeView => "treeview",
            Self::RadioButton => "radiobutton",
            Self::ScrollBar => "scrollbar",
            Self::GUIWindow => "guiwindow",
            Self::SplitPanel => "splitpanel",
            Self::DockPanel => "dockpanel",
            Self::Toolbar => "toolbar",
            Self::MenuBar => "menubar",
            Self::MenuItem => "menuitem",
            Self::Dialog => "dialog",
            Self::StatusBar => "statusbar",
            Self::Accordion => "accordion",
            Self::TooltipPanel => "tooltippanel",
            Self::ColorPicker => "colorpicker",
            Self::GUITable => "guitable",
            Self::ImageWidget => "imagewidget",
            Self::SpinBox => "spinbox",
            Self::Switch => "switch",
            Self::Badge => "badge",
            Self::Custom => "custom",
        }
    }
    pub fn parse_str(s: &str) -> Option<Self> {
        match s {
            "button" => Some(Self::Button),
            "label" => Some(Self::Label),
            "textinput" => Some(Self::TextInput),
            "checkbox" => Some(Self::CheckBox),
            "slider" => Some(Self::Slider),
            "progressbar" => Some(Self::ProgressBar),
            "combobox" => Some(Self::ComboBox),
            "listbox" => Some(Self::ListBox),
            "panel" => Some(Self::Panel),
            "layout" => Some(Self::Layout),
            "scrollpanel" => Some(Self::ScrollPanel),
            "ninepatch" => Some(Self::NinePatch),
            "tabbar" => Some(Self::TabBar),
            "toast" => Some(Self::Toast),
            "separator" => Some(Self::Separator),
            "spacer" => Some(Self::Spacer),
            "treeview" => Some(Self::TreeView),
            "radiobutton" => Some(Self::RadioButton),
            "scrollbar" => Some(Self::ScrollBar),
            "guiwindow" => Some(Self::GUIWindow),
            "splitpanel" => Some(Self::SplitPanel),
            "dockpanel" => Some(Self::DockPanel),
            "toolbar" => Some(Self::Toolbar),
            "menubar" => Some(Self::MenuBar),
            "menuitem" => Some(Self::MenuItem),
            "dialog" => Some(Self::Dialog),
            "statusbar" => Some(Self::StatusBar),
            "accordion" => Some(Self::Accordion),
            "tooltippanel" => Some(Self::TooltipPanel),
            "colorpicker" => Some(Self::ColorPicker),
            "guitable" => Some(Self::GUITable),
            "imagewidget" => Some(Self::ImageWidget),
            "spinbox" => Some(Self::SpinBox),
            "switch" => Some(Self::Switch),
            "badge" => Some(Self::Badge),
            "custom" => Some(Self::Custom),
            _ => None,
        }
    }
    /// Return the default `(width, height)` size in pixels for this widget type.
    pub fn default_size(self) -> (f32, f32) {
        match self {
            Self::Button => (128.0, 32.0),
            Self::Label => (128.0, 16.0),
            Self::TextInput => (192.0, 32.0),
            Self::CheckBox => (128.0, 16.0),
            Self::Slider => (192.0, 16.0),
            Self::ProgressBar => (192.0, 16.0),
            Self::ComboBox => (192.0, 32.0),
            Self::ListBox => (192.0, 128.0),
            Self::Panel => (256.0, 192.0),
            Self::Layout => (256.0, 192.0),
            Self::ScrollPanel => (256.0, 192.0),
            Self::NinePatch => (256.0, 192.0),
            Self::TabBar => (256.0, 32.0),
            Self::Toast => (240.0, 48.0),
            Self::Separator => (256.0, 2.0),
            Self::Spacer => (16.0, 16.0),
            Self::TreeView => (192.0, 192.0),
            Self::RadioButton => (128.0, 16.0),
            Self::ScrollBar => (16.0, 128.0),
            Self::GUIWindow => (320.0, 240.0),
            Self::SplitPanel => (320.0, 240.0),
            Self::DockPanel => (320.0, 240.0),
            Self::Toolbar => (256.0, 32.0),
            Self::MenuBar => (256.0, 32.0),
            Self::MenuItem => (128.0, 32.0),
            Self::Dialog => (320.0, 240.0),
            Self::StatusBar => (320.0, 16.0),
            Self::Accordion => (256.0, 128.0),
            Self::TooltipPanel => (192.0, 64.0),
            Self::ColorPicker => (256.0, 256.0),
            Self::GUITable => (320.0, 256.0),
            Self::ImageWidget => (128.0, 128.0),
            Self::SpinBox => (128.0, 32.0),
            Self::Switch => (64.0, 32.0),
            Self::Badge => (32.0, 16.0),
            Self::Custom => (128.0, 128.0),
        }
    }
}
/// Which property a `WidgetTransition` animates.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum WidgetTransitionKind {
    /// Fade the widget's `alpha` from `from` to `to`.
    Alpha {
        /// Starting alpha value in `[0.0, 1.0]`.
        from: f32,
        /// Target alpha value in `[0.0, 1.0]`.
        to: f32,
    },
    /// Slide the widget from one screen position to another.
    Position {
        /// Starting X pixel position.
        from_x: f32,
        /// Starting Y pixel position.
        from_y: f32,
        /// Target X pixel position.
        to_x: f32,
        /// Target Y pixel position.
        to_y: f32,
    },
}
/// Active animation on a `WidgetBase`; evaluated each frame by `GuiContext::update`.
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct WidgetTransition {
    /// Discriminator selecting which property is animated.
    pub kind: WidgetTransitionKind,
    /// Total animation duration in seconds.
    pub duration: f32,
    /// Elapsed time since the transition started; reaches `duration` when complete.
    pub elapsed: f32,
    /// When `true`, hide the widget after the transition completes.
    pub hide_on_complete: bool,
}
impl WidgetTransition {
    /// Create an alpha fade from `from` to `to` over `duration` seconds; optionally hide when done.
    pub fn alpha(from: f32, to: f32, duration: f32, hide_on_complete: bool) -> Self {
        Self {
            kind: WidgetTransitionKind::Alpha { from, to },
            duration: duration.max(0.0),
            elapsed: 0.0,
            hide_on_complete,
        }
    }
    /// Create a position slide from `(from_x, from_y)` to `(to_x, to_y)` over `duration` seconds.
    pub fn position(from_x: f32, from_y: f32, to_x: f32, to_y: f32, duration: f32) -> Self {
        Self {
            kind: WidgetTransitionKind::Position {
                from_x,
                from_y,
                to_x,
                to_y,
            },
            duration: duration.max(0.0),
            elapsed: 0.0,
            hide_on_complete: false,
        }
    }
}
/// Shared layout, identity, and state fields embedded in every concrete widget struct.
#[derive(Debug, Clone)]
pub struct WidgetBase {
    /// Unique identifier string; may be empty when not addressed by id.
    pub id: String,
    /// Widget class; drives dispatch and default sizing.
    pub widget_type: WidgetType,
    /// Left edge X position in pixels (parent-relative).
    pub x: f32,
    /// Top edge Y position in pixels (parent-relative).
    pub y: f32,
    /// Pixel width of the widget bounding box.
    pub width: f32,
    /// Pixel height of the widget bounding box.
    pub height: f32,
    /// Whether the widget is included in layout and render passes.
    pub visible: bool,
    /// Whether the widget accepts input.
    pub enabled: bool,
    /// Current interaction state; used for theme lookups.
    pub state: WidgetState,
    /// Hover tooltip text; empty string disables the tooltip.
    pub tooltip: String,
    /// Paint order: higher values appear on top.
    pub z_order: i32,
    /// Inner padding `[top, right, bottom, left]` in pixels.
    pub padding: [f32; 4],
    /// Outer margin `[top, right, bottom, left]` in pixels used by layout containers.
    pub margin: [f32; 4],
    /// Minimum pixel width enforced during layout.
    pub min_width: f32,
    /// Minimum pixel height enforced during layout.
    pub min_height: f32,
    /// Maximum pixel width enforced during layout; `f32::INFINITY` = unconstrained.
    pub max_width: f32,
    /// Maximum pixel height enforced during layout; `f32::INFINITY` = unconstrained.
    pub max_height: f32,
    /// Optional pixel offset from the left edge of the parent for anchor layout.
    pub anchor_left: Option<f32>,
    /// Optional pixel offset from the top edge of the parent for anchor layout.
    pub anchor_top: Option<f32>,
    /// Optional pixel inset from the right edge of the parent for anchor layout.
    pub anchor_right: Option<f32>,
    /// Optional pixel inset from the bottom edge of the parent for anchor layout.
    pub anchor_bottom: Option<f32>,
    /// Optional fraction (0.0–1.0) controlling horizontal centering in anchor layout.
    pub anchor_center_x: Option<f32>,
    /// Optional fraction (0.0–1.0) controlling vertical centering in anchor layout.
    pub anchor_center_y: Option<f32>,
    /// Flex growth factor for flex containers; 0.0 = no growth.
    pub flex_grow: f32,
    /// Flex shrink factor for flex containers; 0.0 = no shrink.
    pub flex_shrink: f32,
    /// Overall opacity multiplier applied by the renderer; 1.0 = fully opaque.
    pub alpha: f32,
    /// Optional entity ID linking this widget to a game entity.
    pub entity_attachment: Option<u64>,
    /// Optional data-binding key for `GuiContext::apply_bindings`.
    pub bind_key: Option<String>,
    /// Active animations evaluated each frame by `GuiContext::update`.
    pub transitions: Vec<WidgetTransition>,
    /// Pixel rect computed by the last layout pass.
    pub computed_rect: crate::math::Rect,
    /// Effective visibility after layout and parent visibility propagation.
    pub is_visible: bool,
}
    pub min_height: f32,
    pub max_width: f32,
    pub max_height: f32,
    pub anchor_left: Option<f32>,
    pub anchor_top: Option<f32>,
    pub anchor_right: Option<f32>,
    pub anchor_bottom: Option<f32>,
    pub anchor_center_x: Option<f32>,
    pub anchor_center_y: Option<f32>,
    pub flex_grow: f32,
    pub flex_shrink: f32,
    pub alpha: f32,
    pub entity_attachment: Option<u64>,
    pub bind_key: Option<String>,
    pub transitions: Vec<WidgetTransition>,
    pub computed_rect: crate::math::Rect,
    pub is_visible: bool,
}
impl WidgetBase {
    /// Create a `WidgetBase` with `widget_type` defaults from `WidgetType::default_size`, visible, enabled, alpha 1.
    pub fn new(widget_type: WidgetType) -> Self {
        let (width, height) = widget_type.default_size();
        Self {
            id: String::new(),
            widget_type,
            x: 0.0,
            y: 0.0,
            width,
            height,
            visible: true,
            enabled: true,
            state: WidgetState::Normal,
            tooltip: String::new(),
            z_order: 0,
            padding: [0.0; 4],
            margin: [0.0; 4],
            min_width: 0.0,
            min_height: 0.0,
            max_width: f32::INFINITY,
            max_height: f32::INFINITY,
            anchor_left: None,
            anchor_top: None,
            anchor_right: None,
            anchor_bottom: None,
            anchor_center_x: None,
            anchor_center_y: None,
            flex_grow: 0.0,
            flex_shrink: 0.0,
            alpha: 1.0,
            entity_attachment: None,
            bind_key: None,
            transitions: Vec::new(),
            computed_rect: crate::math::Rect::new(0.0, 0.0, 0.0, 0.0),
            is_visible: true,
        }
    }
    /// Return `true` if `(px, py)` lies within the widget's `x/y/width/height` rectangle.
    pub fn contains_point(&self, px: f32, py: f32) -> bool {
        px >= self.x && px <= self.x + self.width && py >= self.y && py <= self.y + self.height
    }
    /// Clear all six anchor fields (`anchor_left`, `anchor_top`, `anchor_right`, `anchor_bottom`, `anchor_center_x`, `anchor_center_y`).
    pub fn clear_anchors(&mut self) {
        self.anchor_left = None;
        self.anchor_top = None;
        self.anchor_right = None;
        self.anchor_bottom = None;
        self.anchor_center_x = None;
        self.anchor_center_y = None;
    }
}
/// Provide a default `WidgetBase` via `Self::new(WidgetType::Panel)`.
impl Default for WidgetBase {
    fn default() -> Self {
        Self::new(WidgetType::Panel)
    }
}
