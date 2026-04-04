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
}
