use super::bone::Bone;
use super::slot::Slot;
use crate::engine::log_messages::SP01_SKEL_LOADED;
use crate::log_msg;

/// Parameters for creating and adding a bone in one call.
///
/// # Fields
/// - `name` — `String`. Bone name.
/// - `parent_index` — `Option<usize>`. Parent bone index, or `None` for root.
/// - `x` — `f32`. Local X offset.
/// - `y` — `f32`. Local Y offset.
/// - `rotation` — `f32`. Local rotation in radians.
/// - `scale_x` — `f32`. Local X scale.
/// - `scale_y` — `f32`. Local Y scale.
pub struct BoneParams {
    pub name: String,
    pub parent_index: Option<usize>,
    pub x: f32,
    pub y: f32,
    pub rotation: f32,
    pub scale_x: f32,
    pub scale_y: f32,
}

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
        log_msg!(info, SP01_SKEL_LOADED);
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

    /// Creates and adds a bone with the given local transform in one call.
    ///
    /// # Parameters
    /// - `params` — `BoneParams`. Bone creation parameters.
    ///
    /// # Returns
    /// `usize` — index of the newly added bone.
    pub fn add_bone_full(&mut self, params: BoneParams) -> usize {
        let mut bone = match params.parent_index {
            None => Bone::new(&params.name),
            Some(pi) => Bone::with_parent(&params.name, pi, params.x, params.y),
        };
        bone.local_x = params.x;
        bone.local_y = params.y;
        bone.local_rotation = params.rotation;
        bone.local_scale_x = params.scale_x;
        bone.local_scale_y = params.scale_y;
        self.add_bone(bone)
    }

    /// Creates and adds a slot with an optional attachment name in one call.
    ///
    /// # Parameters
    /// - `name` — `&str`. Slot name.
    /// - `bone_index` — `usize`. Index of the bone this slot is bound to.
    /// - `attachment` — `Option<String>`. Initial attachment name.
    ///
    /// # Returns
    /// `usize` — index of the newly added slot.
    pub fn add_slot_full(
        &mut self,
        name: &str,
        bone_index: usize,
        attachment: Option<String>,
    ) -> usize {
        let mut slot = Slot::new(name, bone_index);
        slot.attachment_name = attachment;
        self.add_slot(slot)
    }

    /// Returns the world-space transform of the bone at the given index.
    ///
    /// # Parameters
    /// - `idx` — `usize`. Bone index.
    ///
    /// # Returns
    /// `Option<(f32, f32, f32, f32, f32)>` — `(x, y, rotation, scale_x, scale_y)` or `None`.
    pub fn bone_world_transform(&self, idx: usize) -> Option<(f32, f32, f32, f32, f32)> {
        self.bones.get(idx).map(|b| {
            (b.world_x, b.world_y, b.world_rotation, b.world_scale_x, b.world_scale_y)
        })
    }

    /// Sets the root bone's local position and propagates world transforms.
    ///
    /// # Parameters
    /// - `x` — `f32`. New local X.
    /// - `y` — `f32`. New local Y.
    pub fn set_root_position(&mut self, x: f32, y: f32) {
        if let Some(root) = self.bones.first_mut() {
            root.local_x = x;
            root.local_y = y;
        }
        self.update_world_transforms();
    }

    /// Returns the number of bones in this skeleton.
    ///
    /// # Returns
    /// `usize`.
    pub fn bone_count(&self) -> usize {
        self.bones.len()
    }

    /// Returns the number of slots in this skeleton.
    ///
    /// # Returns
    /// `usize`.
    pub fn slot_count(&self) -> usize {
        self.slots.len()
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
