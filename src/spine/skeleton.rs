//! Skeleton container holding bones, slots, and Atlas data.

use std::collections::HashMap;

use super::bone::Bone;
use super::slot::Slot;
use super::ik::IKConstraint;
use super::timeline::SkeletonAnimation;
use crate::runtime::log_messages::SP01_SKEL_LOADED;
use crate::log_msg;

/// Parameters for creating and adding a bone in one call.
///
/// # Fields
/// - `name` â€” `String`. Bone name.
/// - `parent_index` â€” `Option<usize>`. Parent bone index, or `None` for root.
/// - `x` â€” `f32`. Local X offset.
/// - `y` â€” `f32`. Local Y offset.
/// - `rotation` â€” `f32`. Local rotation in radians.
/// - `scale_x` â€” `f32`. Local X scale.
/// - `scale_y` â€” `f32`. Local Y scale.
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
/// into earlier entries (bones must be added in topological order â€”
/// parent before child). Calling `update_world_transforms()` propagates
/// local transforms down the hierarchy to produce world-space positions.
///
/// # Fields
/// - `name` â€” `String`. Skeleton name.
/// - `bones` â€” `Vec<Bone>`. Bone array.
/// - `slots` â€” `Vec<Slot>`. Render slots bound to bones.
/// - `x`, `y` â€” `f32`. World-space root position.
/// - `scale_x`, `scale_y` â€” `f32`. Root scale.
/// - `animations` â€” `Vec<SkeletonAnimation>`. Registered animation clips.
/// - `ik_constraints` â€” `Vec<IKConstraint>`. Active IK constraints.
/// - `skins` â€” `HashMap<String, HashMap<String, String>>`. Skin slot-attachment overrides.
/// - `active_skin` â€” `Option<String>`. Currently active skin name.
/// - `current_animation` â€” `Option<String>`. Currently active animation name.
/// - `anim_time` â€” `f32`. Current playback time in seconds.
/// - `anim_playing` â€” `bool`. Whether the animation is playing.
/// - `anim_loop` â€” `bool`. Whether the current animation loops.
#[derive(Debug, Clone)]
pub struct Skeleton {
    pub name: String,
    pub bones: Vec<Bone>,
    pub slots: Vec<Slot>,
    pub x: f32,
    pub y: f32,
    pub scale_x: f32,
    pub scale_y: f32,
    /// Registered skeleton animation clips.
    pub animations: Vec<SkeletonAnimation>,
    /// Active IK constraints.
    pub ik_constraints: Vec<IKConstraint>,
    /// Skin slot-to-attachment override maps.
    pub skins: HashMap<String, HashMap<String, String>>,
    /// Currently active skin name, if any.
    pub active_skin: Option<String>,
    /// Currently active animation name, if any.
    pub current_animation: Option<String>,
    /// Current playback time of the active animation in seconds.
    pub anim_time: f32,
    /// Whether the animation is currently playing.
    pub anim_playing: bool,
    /// Whether the current animation should loop.
    pub anim_loop: bool,
}

impl Skeleton {
    /// Creates a new empty skeleton.
    ///
    /// # Parameters
    /// - `name` â€” `impl Into<String>`. Skeleton name.
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
            animations: Vec::new(),
            ik_constraints: Vec::new(),
            skins: HashMap::new(),
            active_skin: None,
            current_animation: None,
            anim_time: 0.0,
            anim_playing: false,
            anim_loop: true,
        }
    }

    /// Adds a bone to the skeleton and returns its index.
    ///
    /// Bones must be added in topological order (parent before child).
    ///
    /// # Parameters
    /// - `bone` â€” `Bone`. The bone to add.
    ///
    /// # Returns
    /// `usize` â€” index of the newly added bone.
    pub fn add_bone(&mut self, bone: Bone) -> usize {
        let idx = self.bones.len();
        self.bones.push(bone);
        idx
    }

    /// Adds a slot to the skeleton and returns its index.
    ///
    /// # Parameters
    /// - `slot` â€” `Slot`. The slot to add.
    ///
    /// # Returns
    /// `usize` â€” index of the newly added slot.
    pub fn add_slot(&mut self, slot: Slot) -> usize {
        let idx = self.slots.len();
        self.slots.push(slot);
        idx
    }

    /// Finds a bone by name and returns its index.
    ///
    /// # Parameters
    /// - `name` â€” `&str`. Bone name to search for.
    ///
    /// # Returns
    /// `Option<usize>` â€” bone index, or `None` if not found.
    pub fn find_bone(&self, name: &str) -> Option<usize> {
        self.bones.iter().position(|b| b.name == name)
    }

    /// Finds a slot by name and returns its index.
    ///
    /// # Parameters
    /// - `name` â€” `&str`. Slot name to search for.
    ///
    /// # Returns
    /// `Option<usize>` â€” slot index, or `None` if not found.
    pub fn find_slot(&self, name: &str) -> Option<usize> {
        self.slots.iter().position(|s| s.name == name)
    }

    /// Creates and adds a bone with the given local transform in one call.
    ///
    /// # Parameters
    /// - `params` â€” `BoneParams`. Bone creation parameters.
    ///
    /// # Returns
    /// `usize` â€” index of the newly added bone.
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
    /// - `name` â€” `&str`. Slot name.
    /// - `bone_index` â€” `usize`. Index of the bone this slot is bound to.
    /// - `attachment` â€” `Option<String>`. Initial attachment name.
    ///
    /// # Returns
    /// `usize` â€” index of the newly added slot.
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
    /// - `idx` â€” `usize`. Bone index.
    ///
    /// # Returns
    /// `Option<(f32, f32, f32, f32, f32)>` â€” `(x, y, rotation, scale_x, scale_y)` or `None`.
    pub fn bone_world_transform(&self, idx: usize) -> Option<(f32, f32, f32, f32, f32)> {
        self.bones.get(idx).map(|b| {
            (b.world_x, b.world_y, b.world_rotation, b.world_scale_x, b.world_scale_y)
        })
    }

    /// Sets the root bone's local position and propagates world transforms.
    ///
    /// # Parameters
    /// - `x` â€” `f32`. New local X.
    /// - `y` â€” `f32`. New local Y.
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

    // â”€â”€ Skeleton animations â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Adds a [`SkeletonAnimation`] to this skeleton's animation library.
    ///
    /// # Parameters
    /// - `anim` â€” [`SkeletonAnimation`].
    pub fn add_animation(&mut self, anim: SkeletonAnimation) {
        self.animations.push(anim);
    }

    /// Returns the index of the animation with the given name.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn find_animation(&self, name: &str) -> Option<usize> {
        self.animations.iter().position(|a| a.name == name)
    }

    /// Starts playing the named animation.
    ///
    /// # Parameters
    /// - `name` â€” `&str`. Animation name.
    /// - `looping` â€” `bool`. Whether to loop.
    ///
    /// # Returns
    /// `bool` â€” `true` if the animation was found.
    pub fn play_animation(&mut self, name: &str, looping: bool) -> bool {
        if self.find_animation(name).is_some() {
            self.current_animation = Some(name.to_string());
            self.anim_time = 0.0;
            self.anim_playing = true;
            self.anim_loop = looping;
            true
        } else {
            false
        }
    }

    /// Stops playback of the current animation.
    pub fn stop_animation(&mut self) {
        self.anim_playing = false;
    }

    /// Advances the active animation by `dt` seconds, applies keyframes, and wraps or stops at the end.
    ///
    /// # Parameters
    /// - `dt` â€” `f32`. Delta time in seconds.
    pub fn update_animation(&mut self, dt: f32) {
        if !self.anim_playing {
            return;
        }
        let anim_idx = match &self.current_animation {
            Some(n) => match self.animations.iter().position(|a| a.name == *n) {
                Some(i) => i,
                None => return,
            },
            None => return,
        };

        self.anim_time += dt;

        let (duration, looping) = {
            let anim = &self.animations[anim_idx];
            (anim.duration, self.anim_loop)
        };

        if looping && duration > 0.0 {
            self.anim_time %= duration;
        } else if self.anim_time >= duration {
            self.anim_time = duration;
            self.anim_playing = false;
        }

        let anim = self.animations[anim_idx].clone();
        let time = self.anim_time;
        anim.apply_to_skeleton(self, time);
    }

    /// Returns the current playback time in seconds.
    ///
    /// # Returns
    /// `f32`.
    pub fn get_animation_time(&self) -> f32 {
        self.anim_time
    }

    // â”€â”€ IK constraints â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Adds an IK constraint and returns its index.
    ///
    /// # Parameters
    /// - `constraint` â€” [`IKConstraint`].
    ///
    /// # Returns
    /// `usize`.
    pub fn add_ik_constraint(&mut self, constraint: IKConstraint) -> usize {
        let idx = self.ik_constraints.len();
        self.ik_constraints.push(constraint);
        idx
    }

    /// Sets the target position for the named IK constraint.
    ///
    /// # Parameters
    /// - `name` â€” `&str`. Constraint name.
    /// - `x` â€” `f32`. Target X.
    /// - `y` â€” `f32`. Target Y.
    ///
    /// # Returns
    /// `bool` â€” `true` if the constraint was found.
    pub fn set_ik_target(&mut self, name: &str, x: f32, y: f32) -> bool {
        if let Some(c) = self.ik_constraints.iter_mut().find(|c| c.name == name) {
            c.set_target(x, y);
            true
        } else {
            false
        }
    }

    /// Evaluates all IK constraints and writes resulting rotations into the bone array.
    ///
    /// Call after `update_animation` and before `update_world_transforms` for best results.
    pub fn apply_ik_constraints(&mut self) {
        for i in 0..self.ik_constraints.len() {
            let constraint = self.ik_constraints[i].clone();
            constraint.solve(&mut self.bones);
        }
    }

    // â”€â”€ Skins â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Registers a new empty skin by name.
    ///
    /// # Parameters
    /// - `name` â€” `&str`. Skin name.
    pub fn add_skin(&mut self, name: &str) {
        self.skins.entry(name.to_string()).or_default();
    }

    /// Sets the active skin, changing slot attachment lookups.
    ///
    /// # Parameters
    /// - `name` â€” `&str`. Skin name.
    ///
    /// # Returns
    /// `bool` â€” `true` if the skin exists.
    pub fn set_skin(&mut self, name: &str) -> bool {
        if self.skins.contains_key(name) {
            self.active_skin = Some(name.to_string());
            true
        } else {
            false
        }
    }

    /// Returns the name of the currently active skin.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_skin(&self) -> Option<&str> {
        self.active_skin.as_deref()
    }

    /// Registers a slot-to-attachment mapping within a named skin.
    ///
    /// # Parameters
    /// - `skin` â€” `&str`. Skin name (created automatically if not yet registered).
    /// - `slot` â€” `&str`. Slot name.
    /// - `attachment` â€” `&str`. Attachment resource name.
    pub fn set_skin_mapping(&mut self, skin: &str, slot: &str, attachment: &str) {
        self.skins
            .entry(skin.to_string())
            .or_default()
            .insert(slot.to_string(), attachment.to_string());
    }

    /// Returns the effective attachment name for a slot, consulting the active skin first.
    ///
    /// Falls back to the slot's own `attachment_name` field when no skin override exists.
    ///
    /// # Parameters
    /// - `slot_idx` â€” `usize`. Slot index.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn get_slot_attachment(&self, slot_idx: usize) -> Option<&str> {
        let slot = self.slots.get(slot_idx)?;
        // Check active skin first.
        if let Some(skin_name) = &self.active_skin {
            if let Some(skin_map) = self.skins.get(skin_name) {
                if let Some(att) = skin_map.get(&slot.name) {
                    return Some(att.as_str());
                }
            }
        }
        slot.attachment_name.as_deref()
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
    /// Iterates bones in array order (which must be topological â€” parent before child).
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

    // â”€â”€ CPU rendering â”€â”€

    /// Renders the skeleton as a stick figure to an `ImageData`.
    ///
    /// Draws bones as lines from parent to child and joint circles at
    /// each bone's world position. Call `update_world_transforms()` before
    /// this method to ensure positions are current.
    ///
    /// # Parameters
    /// - `width` â€” `u32`.
    /// - `height` â€” `u32`.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 20, 30, 255);

        // Draw bones as lines from parent to child
        for bone in &self.bones {
            if let Some(pi) = bone.parent_index {
                let parent = &self.bones[pi];
                img.draw_line(
                    parent.world_x as i32,
                    parent.world_y as i32,
                    bone.world_x as i32,
                    bone.world_y as i32,
                    200,
                    200,
                    220,
                    255,
                );
            }
        }

        // Draw joint circles at each bone
        for bone in &self.bones {
            img.draw_circle(bone.world_x as i32, bone.world_y as i32, 4, 255, 120, 80, 255);
        }

        img
    }
    /// Draw skeleton with colour-coded joints and bone labels.
    ///
    /// Each bone gets a unique colour; lines show parentâ†’child connections.
    ///
    /// # Parameters
    /// - `width` â€” `u32`. Image width.
    /// - `height` â€” `u32`. Image height.
    ///
    /// # Returns
    /// `ImageData`.
    pub fn draw_bones_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 20, 30, 255);

        // Predefined palette for up to 12 bones
        let palette: [(u8, u8, u8); 12] = [
            (255, 200, 80), (200, 100, 100), (255, 150, 100),
            (100, 150, 255), (100, 150, 255), (100, 200, 100),
            (100, 200, 100), (200, 100, 255), (200, 100, 255),
            (180, 180, 80), (80, 180, 180), (180, 80, 180),
        ];

        // Draw bone connections
        for bone in &self.bones {
            if let Some(pi) = bone.parent_index {
                let parent = &self.bones[pi];
                img.draw_line(
                    parent.world_x as i32, parent.world_y as i32,
                    bone.world_x as i32, bone.world_y as i32,
                    180, 180, 200, 255,
                );
            }
        }

        // Draw joint circles with labels
        for (i, bone) in self.bones.iter().enumerate() {
            let (r, g, b) = palette[i % palette.len()];
            img.draw_circle(bone.world_x as i32, bone.world_y as i32, 5, r, g, b, 255);
            let label = bone.name.to_uppercase();
            img.draw_label(&label, bone.world_x as i32 + 8, bone.world_y as i32 - 3, r, g, b);
        }

        let count_str = format!("{} BONES", self.bone_count());
        img.draw_label(&count_str, 10, (height - 15) as i32, 200, 200, 200);
        img.draw_label("SPINE BONES OK", (width / 3) as i32, (height - 15) as i32, 100, 255, 100);
        img
    }

}
