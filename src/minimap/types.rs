#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ColorMode {
    Terrain,
    Political,
}
impl ColorMode {
    pub fn parse_mode(s: &str) -> Option<Self> {
        match s {
            "terrain" => Some(ColorMode::Terrain),
            "political" => Some(ColorMode::Political),
            _ => None,
        }
    }
    pub fn as_str(self) -> &'static str {
        match self {
            ColorMode::Terrain => "terrain",
            ColorMode::Political => "political",
        }
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum FogLevel {
    Hidden = 0,
    Explored = 1,
    Visible = 2,
}
impl FogLevel {
    pub fn from_u8(val: u8) -> Self {
        match val {
            0 => FogLevel::Hidden,
            1 => FogLevel::Explored,
            _ => FogLevel::Visible,
        }
    }
}
#[derive(Debug, Clone)]
pub struct MinimapObjectType {
    pub name: String,
    pub color: [f32; 4],
    pub visible: bool,
}
#[derive(Debug, Clone)]
pub struct MinimapObject {
    pub x: f32,
    pub y: f32,
    pub type_index: usize,
    pub owner: u32,
}
#[derive(Debug, Clone)]
pub struct MinimapPing {
    pub x: f32,
    pub y: f32,
    pub remaining: f32,
    pub duration: f32,
    pub color: [f32; 4],
}
#[derive(Debug, Clone)]
pub struct MinimapMarker {
    pub x: f32,
    pub y: f32,
    pub description: String,
    pub color: [f32; 4],
    pub animation: Option<MarkerAnimation>,
}
#[derive(Debug, Clone)]
pub enum MarkerAnimation {
    Blink { speed: f32, phase: f32 },
    Pulse { speed: f32, phase: f32 },
    Rotate { speed: f32, angle: f32 },
}
#[derive(Debug, Clone)]
pub enum OverlayShape {
    Line {
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        color: [u8; 4],
    },
    Rect {
        x: f32,
        y: f32,
        w: f32,
        h: f32,
        color: [u8; 4],
    },
}
#[derive(Debug, Clone)]
pub struct OverlayPath {
    pub id: u32,
    pub points: Vec<(f32, f32)>,
    pub color: [u8; 4],
}
#[derive(Debug, Clone)]
pub struct LayerData {
    pub cells: Vec<u8>,
    pub width: u32,
    pub height: u32,
}
