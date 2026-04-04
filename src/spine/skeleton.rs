use super::bone::Bone;
use super::slot::Slot;

/// A skeletal animation rig composed of a bone hierarchy and render slots.
///
/// The skeleton owns a flat array of `Bone`s where parent indices point
/// into earlier entries (bones must be added in topological order —
/// parent before child). Calling `update_world_transforms()` propagates
/// local transforms down the hierarchy to produce world-space positions.
///
/// # Fields
/// - `name` — `String`. Skeleton name.
/// - `bones` — `Vec<Bone>`. Bone array (parent indices index into this vec).
/// - `slots` — `Vec<Slot>`. Render slots bound to bones.
/// - `x` — `f32`. World-space root X position.
/// - `y` — `f32`. World-space root Y position.
/// - `scale_x` — `f32`. Root X scale.
/// - `scale_y` — `f32`. Root Y scale.
#[derive(Debug, Clone)]
pub struct Skeleton {
    pub name: String,
    pub bones: Vec<Bone>,
    pub slots: Vec<Slot>,
    pub x: f32,
    pub y: f32,
    pub scale_x: f32,
    pub scale_y: f32,
}

impl Skeleton {
    /// Creates a new empty skeleton.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`. Skeleton name.
    ///
    /// # Returns
    /// `Skeleton` at the origin with unit scale and no bones or slots.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            bones: Vec::new(),
            slots: Vec::new(),
            x: 0.0,
            y: 0.0,
            scale_x: 1.0,
            scale_y: 1.0,
        }
    }

    /// Adds a bone to the skeleton and returns its index.
    ///
    /// Bones must be added in topological order (parent before child).
    ///
    /// # Parameters
    /// - `bone` — `Bone`. The bone to add.
    ///
    /// # Returns
    /// `usize` — index of the newly added bone.
    pub fn add_bone(&mut self, bone: Bone) -> usize {
        let idx = self.bones.len();
        self.bones.push(bone);
        idx
    }

    /// Adds a slot to the skeleton and returns its index.
    ///
    /// # Parameters
    /// - `slot` — `Slot`. The slot to add.
    ///
    /// # Returns
    /// `usize` — index of the newly added slot.
    pub fn add_slot(&mut self, slot: Slot) -> usize {
        let idx = self.slots.len();
        self.slots.push(slot);
        idx
    }

    /// Finds a bone by name and returns its index.
    ///
    /// # Parameters
    /// - `name` — `&str`. Bone name to search for.
    ///
    /// # Returns
    /// `Option<usize>` — bone index, or `None` if not found.
    pub fn find_bone(&self, name: &str) -> Option<usize> {
        self.bones.iter().position(|b| b.name == name)
    }

    /// Finds a slot by name and returns its index.
    ///
    /// # Parameters
    /// - `name` — `&str`. Slot name to search for.
    ///
    /// # Returns
    /// `Option<usize>` — slot index, or `None` if not found.
    pub fn find_slot(&self, name: &str) -> Option<usize> {
        self.slots.iter().position(|s| s.name == name)
    }

    /// Propagates local transforms down the bone hierarchy to compute world transforms.
    ///
    /// Iterates bones in array order (which must be topological — parent before child).
    /// Root bones (no parent) are transformed by the skeleton's own position and scale.
    /// Child bones compose their local transform with the parent's world transform.
    pub fn update_world_transforms(&mut self) {
        for i in 0..self.bones.len() {
            let (local_x, local_y, local_rot, local_sx, local_sy, parent_idx) = {
                let b = &self.bones[i];
                (
                    b.local_x,
                    b.local_y,
                    b.local_rotation,
                    b.local_scale_x,
                    b.local_scale_y,
                    b.parent_index,
                )
            };

            match parent_idx {
                None => {
                    // Root bone: apply skeleton root transform
                    self.bones[i].world_x = self.x + local_x * self.scale_x;
                    self.bones[i].world_y = self.y + local_y * self.scale_y;
                    self.bones[i].world_rotation = local_rot;
                    self.bones[i].world_scale_x = self.scale_x * local_sx;
                    self.bones[i].world_scale_y = self.scale_y * local_sy;
                }
                Some(pi) => {
                    // Child bone: compose with parent world transform
                    let (pw_x, pw_y, pw_rot, pw_sx, pw_sy) = {
                        let p = &self.bones[pi];
                        (
                            p.world_x,
                            p.world_y,
                            p.world_rotation,
                            p.world_scale_x,
                            p.world_scale_y,
                        )
                    };
                    let cos_r = pw_rot.cos();
                    let sin_r = pw_rot.sin();
                    let sx = local_x * pw_sx;
                    let sy = local_y * pw_sy;

                    self.bones[i].world_x = pw_x + sx * cos_r - sy * sin_r;
                    self.bones[i].world_y = pw_y + sx * sin_r + sy * cos_r;
                    self.bones[i].world_rotation = pw_rot + local_rot;
                    self.bones[i].world_scale_x = pw_sx * local_sx;
                    self.bones[i].world_scale_y = pw_sy * local_sy;
                }
            }
        }
    }
}
