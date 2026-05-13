#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WidgetState {
    Normal,
    Hovered,
    Pressed,
    Focused,
    Disabled,
}
impl WidgetState {
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
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum WidgetType {
    Button,
    Label,
    TextInput,
    CheckBox,
    Slider,
    ProgressBar,
    ComboBox,
    ListBox,
    Panel,
    Layout,
    ScrollPanel,
    NinePatch,
    TabBar,
    Toast,
    Separator,
    Spacer,
    TreeView,
    RadioButton,
    ScrollBar,
    GUIWindow,
    SplitPanel,
    DockPanel,
    Toolbar,
    MenuBar,
    MenuItem,
    Dialog,
    StatusBar,
    Accordion,
    TooltipPanel,
    ColorPicker,
    GUITable,
    ImageWidget,
    SpinBox,
    Switch,
    Badge,
    Custom,
}
impl WidgetType {
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
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum WidgetTransitionKind {
    Alpha {
        from: f32,
        to: f32,
    },
    Position {
        from_x: f32,
        from_y: f32,
        to_x: f32,
        to_y: f32,
    },
}
#[derive(Debug, Clone, Copy, PartialEq)]
pub struct WidgetTransition {
    pub kind: WidgetTransitionKind,
    pub duration: f32,
    pub elapsed: f32,
    pub hide_on_complete: bool,
}
impl WidgetTransition {
    pub fn alpha(from: f32, to: f32, duration: f32, hide_on_complete: bool) -> Self {
        Self {
            kind: WidgetTransitionKind::Alpha { from, to },
            duration: duration.max(0.0),
            elapsed: 0.0,
            hide_on_complete,
        }
    }
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
#[derive(Debug, Clone)]
pub struct WidgetBase {
    pub id: String,
    pub widget_type: WidgetType,
    pub x: f32,
    pub y: f32,
    pub width: f32,
    pub height: f32,
    pub visible: bool,
    pub enabled: bool,
    pub state: WidgetState,
    pub tooltip: String,
    pub z_order: i32,
    pub padding: [f32; 4],
    pub margin: [f32; 4],
    pub min_width: f32,
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
    pub fn contains_point(&self, px: f32, py: f32) -> bool {
        px >= self.x && px <= self.x + self.width && py >= self.y && py <= self.y + self.height
    }
    pub fn clear_anchors(&mut self) {
        self.anchor_left = None;
        self.anchor_top = None;
        self.anchor_right = None;
        self.anchor_bottom = None;
        self.anchor_center_x = None;
        self.anchor_center_y = None;
    }
}
impl Default for WidgetBase {
    fn default() -> Self {
        Self::new(WidgetType::Panel)
    }
}
