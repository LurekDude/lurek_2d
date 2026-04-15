//! Supporting types for the minimap module: enums and plain data structs.

/// How cells are colored on the minimap.
///
/// # Variants
/// - `Terrain` — Color cells by terrain type colors.
/// - `Political` — Color cells by owner/faction colors.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ColorMode {
    /// Color cells by terrain type.
    Terrain,
    /// Color cells by owning faction/player.
    Political,
}

impl ColorMode {
    /// Parse a color mode from its string name.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Option<Self>`.
    pub fn parse_mode(s: &str) -> Option<Self> {
        match s {
            "terrain" => Some(ColorMode::Terrain),
            "political" => Some(ColorMode::Political),
            _ => None,
        }
    }

    /// Return the string name of this color mode.
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(self) -> &'static str {
        match self {
            ColorMode::Terrain => "terrain",
            ColorMode::Political => "political",
        }
    }
}

/// Fog-of-war visibility level for a cell.
///
/// # Variants
/// - `Hidden` — Cell is completely hidden (never seen).
/// - `Explored` — Cell was previously seen but is not currently visible.
/// - `Visible` — Cell is currently fully visible.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
pub enum FogLevel {
    /// Cell is completely hidden.
    Hidden = 0,
    /// Cell was previously seen but is not currently visible.
    Explored = 1,
    /// Cell is currently visible.
    Visible = 2,
}

impl FogLevel {
    /// Convert a raw `u8` value (0/1/2) into a `FogLevel`.
    ///
    /// # Parameters
    /// - `val` — `u8`.
    ///
    /// # Returns
    /// `Self`.
    pub fn from_u8(val: u8) -> Self {
        match val {
            0 => FogLevel::Hidden,
            1 => FogLevel::Explored,
            _ => FogLevel::Visible,
        }
    }
}

/// A registered object type with a display color and visibility toggle.
///
/// # Fields
/// - `name` — `String`.
/// - `color` — `[f32; 4]`.
/// - `visible` — `bool`.
#[derive(Debug, Clone)]
pub struct MinimapObjectType {
    /// Human-readable name of this object type.
    pub name: String,
    /// Display color (RGBA).
    pub color: [f32; 4],
    /// Whether objects of this type are shown on the minimap.
    pub visible: bool,
}

/// A tracked object on the minimap.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `type_index` — `usize`.
/// - `owner` — `u32`.
#[derive(Debug, Clone)]
pub struct MinimapObject {
    /// Grid X position (can be fractional).
    pub x: f32,
    /// Grid Y position (can be fractional).
    pub y: f32,
    /// Index into the object types array.
    pub type_index: usize,
    /// Owner/faction identifier (0 = neutral).
    pub owner: u32,
}

/// A temporary animated ping on the minimap.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `remaining` — `f32`.
/// - `duration` — `f32`.
/// - `color` — `[f32; 4]`.
#[derive(Debug, Clone)]
pub struct MinimapPing {
    /// Grid X position.
    pub x: f32,
    /// Grid Y position.
    pub y: f32,
    /// Time remaining before expiry (seconds).
    pub remaining: f32,
    /// Total duration of this ping (seconds).
    pub duration: f32,
    /// Display color (RGBA).
    pub color: [f32; 4],
}

/// A persistent labeled marker on the minimap.
///
/// # Fields
/// - `x` — `f32`.
/// - `y` — `f32`.
/// - `description` — `String`.
/// - `color` — `[f32; 4]`.
/// - `animation` — `Option<MarkerAnimation>`.
#[derive(Debug, Clone)]
pub struct MinimapMarker {
    /// Grid X position.
    pub x: f32,
    /// Grid Y position.
    pub y: f32,
    /// Optional description text shown on hover.
    pub description: String,
    /// Display color (RGBA).
    pub color: [f32; 4],
    /// Optional animation applied to this marker each frame.
    pub animation: Option<MarkerAnimation>,
}

/// Animation applied to a minimap marker icon.
///
/// # Variants
/// - `Blink` — Alternates between visible and hidden at `speed` cycles per second.
/// - `Pulse` — Scales up and down at `speed` cycles per second.
/// - `Rotate` — Spins continuously at `speed` radians per second.
#[derive(Debug, Clone)]
pub enum MarkerAnimation {
    /// Blinking visibility animation.
    Blink {
        /// Cycles per second.
        speed: f32,
        /// Current phase in `[0.0, 1.0)`, advanced each `update(dt)` call.
        phase: f32,
    },
    /// Pulsing scale animation.
    Pulse {
        /// Cycles per second.
        speed: f32,
        /// Current phase in `[0.0, 1.0)`, advanced each `update(dt)` call.
        phase: f32,
    },
    /// Continuous rotation animation.
    Rotate {
        /// Rotation speed in radians per second.
        speed: f32,
        /// Current rotation angle in radians, advanced each `update(dt)` call.
        angle: f32,
    },
}

/// A custom geometric shape drawn on top of the minimap in grid space.
///
/// # Variants
/// - `Line` — A line segment between two grid-space coordinates.
/// - `Rect` — An axis-aligned rectangle in grid-space coordinates.
#[derive(Debug, Clone)]
pub enum OverlayShape {
    /// A line segment from `(x1, y1)` to `(x2, y2)`.
    Line {
        /// Start X in grid coordinates.
        x1: f32,
        /// Start Y in grid coordinates.
        y1: f32,
        /// End X in grid coordinates.
        x2: f32,
        /// End Y in grid coordinates.
        y2: f32,
        /// RGBA color (0–255 per channel).
        color: [u8; 4],
    },
    /// An axis-aligned rectangle in grid coordinates.
    Rect {
        /// Left edge in grid coordinates.
        x: f32,
        /// Top edge in grid coordinates.
        y: f32,
        /// Width in grid cells.
        w: f32,
        /// Height in grid cells.
        h: f32,
        /// RGBA color (0–255 per channel).
        color: [u8; 4],
    },
}

/// A pathfinding route overlay displayed on the minimap.
///
/// # Fields
/// - `id` — `u32`.
/// - `points` — `Vec<(f32, f32)>`.
/// - `color` — `[u8; 4]`.
#[derive(Debug, Clone)]
pub struct OverlayPath {
    /// Unique identifier for this path (used to remove it later).
    pub id: u32,
    /// Ordered list of grid-space waypoints forming the route.
    pub points: Vec<(f32, f32)>,
    /// RGBA color (0–255 per channel).
    pub color: [u8; 4],
}

/// Per-layer terrain data for multi-layer minimap rendering.
///
/// # Fields
/// - `cells` — `Vec<u8>`.
/// - `width` — `u32`.
/// - `height` — `u32`.
#[derive(Debug, Clone)]
pub struct LayerData {
    /// Flat row-major array of terrain type IDs for this layer.
    pub cells: Vec<u8>,
    /// Layer grid width in cells.
    pub width: u32,
    /// Layer grid height in cells.
    pub height: u32,
}
