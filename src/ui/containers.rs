use crate::ui::widget::{WidgetBase, WidgetType};
#[derive(Debug, Clone)]
pub struct Panel {
    pub base: WidgetBase,
    pub children: Vec<usize>,
    pub title: String,
    pub scrollable: bool,
}
impl Panel {
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
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum LayoutDirection {
    Vertical,
    Horizontal,
    Grid,
}
impl LayoutDirection {
    pub fn parse_str(s: &str) -> Option<Self> {
        match s {
            "vertical" => Some(Self::Vertical),
            "horizontal" => Some(Self::Horizontal),
            "grid" => Some(Self::Grid),
            _ => None,
        }
    }
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Vertical => "vertical",
            Self::Horizontal => "horizontal",
            Self::Grid => "grid",
        }
    }
}
#[derive(Debug, Clone)]
pub struct Layout {
    pub base: WidgetBase,
    pub children: Vec<usize>,
    pub direction: LayoutDirection,
    pub spacing: f32,
    pub columns: usize,
    pub wrap: bool,
    pub align: String,
    pub justify: String,
}
impl Layout {
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
    pub fn perform_layout(&self, bases: &mut [WidgetBase]) {
        let pad = &self.base.padding;
        let mut cx = self.base.x + pad[3];
        let mut cy = self.base.y + pad[0];
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
                    let col = self
                        .children
                        .iter()
                        .position(|&i| i == child_idx)
                        .unwrap_or(0);
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
#[derive(Debug, Clone)]
pub struct ScrollPanel {
    pub base: WidgetBase,
    pub children: Vec<usize>,
    pub content_width: f32,
    pub content_height: f32,
    pub scroll_x: f32,
    pub scroll_y: f32,
    pub scroll_speed: f32,
}
impl ScrollPanel {
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
    pub fn max_scroll(&self) -> (f32, f32) {
        let mx = (self.content_width - self.base.width).max(0.0);
        let my = (self.content_height - self.base.height).max(0.0);
        (mx, my)
    }
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
pub type NineSlice = (f32, f32, f32, f32, f32, f32, f32, f32);
#[derive(Debug, Clone)]
pub struct NinePatch {
    pub base: WidgetBase,
    pub inset_left: u32,
    pub inset_top: u32,
    pub inset_right: u32,
    pub inset_bottom: u32,
    pub image_width: u32,
    pub image_height: u32,
}
impl NinePatch {
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
        let sm = iw - il - ir;
        let smh = ih - it - ib;
        let dm = dw - il - ir;
        let dmh = dh - it - ib;
        vec![
            (0.0, 0.0, il, it, dx, dy, il, it),
            (il, 0.0, sm, it, dx + il, dy, dm, it),
            (iw - ir, 0.0, ir, it, dx + dw - ir, dy, ir, it),
            (0.0, it, il, smh, dx, dy + it, il, dmh),
            (il, it, sm, smh, dx + il, dy + it, dm, dmh),
            (iw - ir, it, ir, smh, dx + dw - ir, dy + it, ir, dmh),
            (0.0, ih - ib, il, ib, dx, dy + dh - ib, il, ib),
            (il, ih - ib, sm, ib, dx + il, dy + dh - ib, dm, ib),
            (iw - ir, ih - ib, ir, ib, dx + dw - ir, dy + dh - ib, ir, ib),
        ]
    }
}
impl Default for NinePatch {
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone)]
pub struct GUIWindow {
    pub base: WidgetBase,
    pub title: String,
    pub closeable: bool,
    pub draggable: bool,
    pub resizable: bool,
    pub children: Vec<usize>,
}
impl GUIWindow {
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
#[derive(Debug, Clone)]
pub struct SplitPanel {
    pub base: WidgetBase,
    pub orientation: String,
    pub split_position: f32,
    pub min_panel_size: f32,
    pub first_child: Option<usize>,
    pub second_child: Option<usize>,
}
impl SplitPanel {
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
#[derive(Debug, Clone)]
pub struct DockPanel {
    pub base: WidgetBase,
    pub docked: Vec<(usize, String)>,
    pub split_sizes: Vec<(String, f32)>,
}
impl DockPanel {
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
