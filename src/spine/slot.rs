//! Slot: attachment point that links a bone to a drawable region in a spine skeleton.
//! Owns Slot with colour tint, draw order, and optional attachment name.
//! Does not own attachment texture data or skin resolution \u2014 those live in skeleton.rs and the asset pipeline.

/// Attachment point on a bone with colour tint and optional texture attachment name.
#[derive(Debug, Clone)]
pub struct Slot {
    /// Unique name identifying this slot within the skeleton.
    pub name: String,
    /// Index of the bone this slot is attached to in the skeleton bone array.
    pub bone_index: usize,
    /// Red tint component in [0, 1].
    pub color_r: f32,
    /// Green tint component in [0, 1].
    pub color_g: f32,
    /// Blue tint component in [0, 1].
    pub color_b: f32,
    /// Alpha tint component in [0, 1].
    pub color_a: f32,
    /// Default attachment name; overridden by the active skin when set.
    pub attachment_name: Option<String>,
    /// Draw order priority; lower values are drawn before higher values.
    pub draw_order: i32,
}

/// Constructor for Slot.
impl Slot {
    /// Create a slot with white opaque tint, no attachment, and draw_order 0.
    pub fn new(name: impl Into<String>, bone_index: usize) -> Self {
        Self {
            name: name.into(),
            bone_index,
            color_r: 1.0,
            color_g: 1.0,
            color_b: 1.0,
            color_a: 1.0,
            attachment_name: None,
            draw_order: 0,
        }
    }
}
