/// A slot binding a visual attachment to a bone in the skeleton.
///
/// Slots determine which bone drives an attachment's position and define
/// the draw order and tint colour for that attachment.
///
/// # Fields
/// - `name` — `String`. Unique slot name.
/// - `bone_index` — `usize`. Index of the bone this slot is bound to.
/// - `color_r` — `f32`. Red tint (0–1).
/// - `color_g` — `f32`. Green tint (0–1).
/// - `color_b` — `f32`. Blue tint (0–1).
/// - `color_a` — `f32`. Alpha (0–1).
/// - `attachment_name` — `Option<String>`. Name of the current attachment, or `None`.
/// - `draw_order` — `i32`. Z-sort key for rendering.
#[derive(Debug, Clone)]
pub struct Slot {
    pub name: String,
    pub bone_index: usize,
    pub color_r: f32,
    pub color_g: f32,
    pub color_b: f32,
    pub color_a: f32,
    pub attachment_name: Option<String>,
    pub draw_order: i32,
}

impl Slot {
    /// Creates a new slot bound to a bone with default white colour and no attachment.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`. Unique slot name.
    /// - `bone_index` — `usize`. Index of the bone this slot is bound to.
    ///
    /// # Returns
    /// `Slot` with white colour, no attachment, draw order 0.
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
