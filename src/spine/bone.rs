/// A single bone in a skeletal hierarchy.
///
/// Each bone stores a local transform relative to its parent (or to the skeleton
/// root if `parent_index` is `None`). After `Skeleton::update_world_transforms()`,
/// the `world_*` fields contain the final world-space transform.
///
/// # Fields
/// - `name` — `String`. Unique bone name.
/// - `parent_index` — `Option<usize>`. Index of parent bone, or `None` for root.
/// - `local_x` — `f32`. Local X offset from parent.
/// - `local_y` — `f32`. Local Y offset from parent.
/// - `local_rotation` — `f32`. Local rotation in radians.
/// - `local_scale_x` — `f32`. Local X scale factor.
/// - `local_scale_y` — `f32`. Local Y scale factor.
/// - `world_x` — `f32`. Computed world-space X (updated by `update_world_transforms`).
/// - `world_y` — `f32`. Computed world-space Y.
/// - `world_rotation` — `f32`. Computed world-space rotation.
/// - `world_scale_x` — `f32`. Computed world-space X scale.
/// - `world_scale_y` — `f32`. Computed world-space Y scale.
#[derive(Debug, Clone)]
pub struct Bone {
    pub name: String,
    pub parent_index: Option<usize>,
    pub local_x: f32,
    pub local_y: f32,
    pub local_rotation: f32,
    pub local_scale_x: f32,
    pub local_scale_y: f32,
    pub world_x: f32,
    pub world_y: f32,
    pub world_rotation: f32,
    pub world_scale_x: f32,
    pub world_scale_y: f32,
}

impl Bone {
    /// Creates a new bone with identity local transform and no parent.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`. Unique bone name.
    ///
    /// # Returns
    /// `Bone` with zero local offset, zero rotation, and unit scale.
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

    /// Creates a bone with a parent index and local offset.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`. Unique bone name.
    /// - `parent` — `usize`. Index of the parent bone in the skeleton's bone array.
    /// - `x` — `f32`. Local X offset from parent.
    /// - `y` — `f32`. Local Y offset from parent.
    ///
    /// # Returns
    /// `Bone` with the given parent and offset, zero rotation, unit scale.
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
