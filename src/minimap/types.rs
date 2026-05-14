
/// Whether minimap cells are coloured by terrain type or by political owner.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ColorMode {
    /// Colour each cell by its terrain type's registered colour.
    Terrain,
    /// Colour each cell by the owning player's registered colour.
    Political,
}

impl ColorMode {
    /// Parse `"terrain"` or `"political"` to a `ColorMode`; returns `None` on unknown strings.
    pub fn parse_mode(s: &str) -> Option<Self> {
        match s {
            "terrain" => Some(ColorMode::Terrain),
            "political" => Some(ColorMode::Political),
            _ => None,
        }
    }

    /// Return the canonical string name for this colour mode.
    pub fn as_str(self) -> &'static str {
        match self {
            ColorMode::Terrain => "terrain",
            ColorMode::Political => "political",
        }
    }
}

/// Fog-of-war visibility level for a single minimap cell.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum FogLevel {
    /// Cell has never been seen; rendered with full fog tint.
    Hidden = 0,
    /// Cell was seen in a past turn; rendered at reduced brightness.
    Explored = 1,
    /// Cell is currently visible; rendered at full brightness.
    Visible = 2,
}

impl FogLevel {
    /// Convert a raw `u8` byte to a `FogLevel`; values >= 2 map to `Visible`.
    pub fn from_u8(val: u8) -> Self {
        match val {
            0 => FogLevel::Hidden,
            1 => FogLevel::Explored,
            _ => FogLevel::Visible,
        }
    }
}

/// Descriptor for a category of minimap objects (units, buildings, etc.).
#[derive(Debug, Clone)]
pub struct MinimapObjectType {
    /// Human-readable name of this object type.
    pub name: String,
    /// Default RGBA colour used when no custom icon is set.
    pub color: [f32; 4],
    /// Whether objects of this type are shown on the minimap.
    pub visible: bool,
}

/// A single live minimap object placed at a world-space grid position.
#[derive(Debug, Clone)]
pub struct MinimapObject {
    /// World-space X position in grid units.
    pub x: f32,
    /// World-space Y position in grid units.
    pub y: f32,
    /// Index into the `object_types` list on `Minimap`.
    pub type_index: usize,
    /// Owner id used for political colour mode.
    pub owner: u32,
}

/// A timed visual indicator that fades over its `duration`.
#[derive(Debug, Clone)]
pub struct MinimapPing {
    /// World-space X position in grid units.
    pub x: f32,
    /// World-space Y position in grid units.
    pub y: f32,
    /// Seconds remaining before the ping is removed.
    pub remaining: f32,
    /// Total duration in seconds; used to compute fade ratio.
    pub duration: f32,
    /// RGBA colour of the ping circle.
    pub color: [f32; 4],
}

/// A persistent named marker placed at a world-space grid position.
#[derive(Debug, Clone)]
pub struct MinimapMarker {
    /// World-space X position in grid units.
    pub x: f32,
    /// World-space Y position in grid units.
    pub y: f32,
    /// Tooltip or label text for hover and Lua queries.
    pub description: String,
    /// RGBA colour when drawn without a custom icon.
    pub color: [f32; 4],
    /// Optional animation applied to the marker each frame.
    pub animation: Option<MarkerAnimation>,
}

/// Per-frame animation state for a minimap marker.
#[derive(Debug, Clone)]
pub enum MarkerAnimation {
    /// Blink at `speed` Hz; `phase` is the current oscillation phase in [0, 1).
    Blink { speed: f32, phase: f32 },
    /// Pulse-scale at `speed` Hz; `phase` is the current oscillation phase in [0, 1).
    Pulse { speed: f32, phase: f32 },
    /// Spin at `speed` radians/second; `angle` is the current angle in [0, TAU).
    Rotate { speed: f32, angle: f32 },
}

/// A vector overlay shape drawn on top of the terrain grid.
#[derive(Debug, Clone)]
pub enum OverlayShape {
    /// A line segment from `(x1, y1)` to `(x2, y2)` in grid coordinates.
    Line {
        /// Start X in grid units.
        x1: f32,
        /// Start Y in grid units.
        y1: f32,
        /// End X in grid units.
        x2: f32,
        /// End Y in grid units.
        y2: f32,
        /// RGBA colour as bytes.
        color: [u8; 4],
    },
    /// An axis-aligned rectangle outline at `(x, y)` with size `(w, h)` in grid units.
    Rect {
        /// Left edge in grid units.
        x: f32,
        /// Top edge in grid units.
        y: f32,
        /// Width in grid units.
        w: f32,
        /// Height in grid units.
        h: f32,
        /// RGBA colour as bytes.
        color: [u8; 4],
    },
}

/// A named polyline path drawn over the terrain.
#[derive(Debug, Clone)]
pub struct OverlayPath {
    /// Auto-assigned path id used for removal.
    pub id: u32,
    /// Ordered list of `(x, y)` grid-coordinate waypoints.
    pub points: Vec<(f32, f32)>,
    /// RGBA colour as bytes.
    pub color: [u8; 4],
}

/// Raw cell data for one named minimap layer.
#[derive(Debug, Clone)]
pub struct LayerData {
    /// Flat byte array of cell values indexed by `y * width + x`.
    pub cells: Vec<u8>,
    /// Number of columns in this layer grid.
    pub width: u32,
    /// Number of rows in this layer grid.
    pub height: u32,
}

