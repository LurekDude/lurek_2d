//! Bone transform node in a spine skeletal hierarchy.
//! Owns Bone: local and world-space position, rotation, and scale.
//! Does not own pose accumulation or IK — those live in skeleton.rs and ik.rs respectively.

/// Single bone in the skeleton tree with local and accumulated world-space transform.
#[derive(Debug, Clone)]
pub struct Bone {
    /// Unique name identifying this bone within the skeleton.
    pub name: String,
    /// Index of the parent bone in the skeleton bone array; None for the root bone.
    pub parent_index: Option<usize>,
    /// X translation relative to the parent bone (or world origin for root), in pixels.
    pub local_x: f32,
    /// Y translation relative to the parent bone (or world origin for root), in pixels.
    pub local_y: f32,
    /// Rotation relative to the parent, in radians counter-clockwise.
    pub local_rotation: f32,
    /// Horizontal scale relative to the parent; 1.0 = no scale.
    pub local_scale_x: f32,
    /// Vertical scale relative to the parent; 1.0 = no scale.
    pub local_scale_y: f32,
    /// Accumulated world-space X position after pose update.
    pub world_x: f32,
    /// Accumulated world-space Y position after pose update.
    pub world_y: f32,
    /// Accumulated world-space rotation in radians.
    pub world_rotation: f32,
    /// Accumulated world-space horizontal scale.
    pub world_scale_x: f32,
    /// Accumulated world-space vertical scale.
    pub world_scale_y: f32,
}

/// Constructor methods for Bone.
impl Bone {
    /// Create a root bone at world origin with identity transform.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            parent_index: None,
            local_x: 0.0,
            local_y: 0.0,
            local_rotation: 0.0,
            local_scale_x: 1.0,
            local_scale_y: 1.0,
            world_x: 0.0,
            world_y: 0.0,
            world_rotation: 0.0,
            world_scale_x: 1.0,
            world_scale_y: 1.0,
        }
    }
    /// Create a child bone with the given parent index and local (x, y) offset; rotation and scale default to identity.
    pub fn with_parent(name: impl Into<String>, parent: usize, x: f32, y: f32) -> Self {
        Self {
            name: name.into(),
            parent_index: Some(parent),
            local_x: x,
            local_y: y,
            local_rotation: 0.0,
            local_scale_x: 1.0,
            local_scale_y: 1.0,
            world_x: 0.0,
            world_y: 0.0,
            world_rotation: 0.0,
            world_scale_x: 1.0,
            world_scale_y: 1.0,
        }
    }
}
