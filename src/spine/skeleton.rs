use super::bone::Bone;
use super::ik::IKConstraint;
use super::slot::Slot;
use super::timeline::SkeletonAnimation;
use crate::log_msg;
use crate::runtime::log_messages::SP01_SKEL_LOADED;
use std::collections::HashMap;
pub struct BoneParams {
    pub name: String,
    pub parent_index: Option<usize>,
    pub x: f32,
    pub y: f32,
    pub rotation: f32,
    pub scale_x: f32,
    pub scale_y: f32,
}
#[derive(Debug, Clone)]
pub struct Skeleton {
    pub name: String,
    pub bones: Vec<Bone>,
    pub slots: Vec<Slot>,
    pub x: f32,
    pub y: f32,
    pub scale_x: f32,
    pub scale_y: f32,
    pub animations: Vec<SkeletonAnimation>,
    pub ik_constraints: Vec<IKConstraint>,
    pub skins: HashMap<String, HashMap<String, String>>,
    pub active_skin: Option<String>,
    pub current_animation: Option<String>,
    pub anim_time: f32,
    pub anim_playing: bool,
    pub anim_loop: bool,
}
impl Skeleton {
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
    pub fn add_bone(&mut self, bone: Bone) -> usize {
        let idx = self.bones.len();
        self.bones.push(bone);
        idx
    }
    pub fn add_slot(&mut self, slot: Slot) -> usize {
        let idx = self.slots.len();
        self.slots.push(slot);
        idx
    }
    pub fn find_bone(&self, name: &str) -> Option<usize> {
        self.bones.iter().position(|b| b.name == name)
    }
    pub fn find_slot(&self, name: &str) -> Option<usize> {
        self.slots.iter().position(|s| s.name == name)
    }
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
    pub fn bone_world_transform(&self, idx: usize) -> Option<(f32, f32, f32, f32, f32)> {
        self.bones.get(idx).map(|b| {
            (
                b.world_x,
                b.world_y,
                b.world_rotation,
                b.world_scale_x,
                b.world_scale_y,
            )
        })
    }
    pub fn set_root_position(&mut self, x: f32, y: f32) {
        if let Some(root) = self.bones.first_mut() {
            root.local_x = x;
            root.local_y = y;
        }
        self.update_world_transforms();
    }
    pub fn bone_count(&self) -> usize {
        self.bones.len()
    }
    pub fn add_animation(&mut self, anim: SkeletonAnimation) {
        self.animations.push(anim);
    }
    pub fn find_animation(&self, name: &str) -> Option<usize> {
        self.animations.iter().position(|a| a.name == name)
    }
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
    pub fn stop_animation(&mut self) {
        self.anim_playing = false;
    }
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
    pub fn get_animation_time(&self) -> f32 {
        self.anim_time
    }
    pub fn add_ik_constraint(&mut self, constraint: IKConstraint) -> usize {
        let idx = self.ik_constraints.len();
        self.ik_constraints.push(constraint);
        idx
    }
    pub fn set_ik_target(&mut self, name: &str, x: f32, y: f32) -> bool {
        if let Some(c) = self.ik_constraints.iter_mut().find(|c| c.name == name) {
            c.set_target(x, y);
            true
        } else {
            false
        }
    }
    pub fn apply_ik_constraints(&mut self) {
        for i in 0..self.ik_constraints.len() {
            let constraint = self.ik_constraints[i].clone();
            constraint.solve(&mut self.bones);
        }
    }
    pub fn add_skin(&mut self, name: &str) {
        self.skins.entry(name.to_string()).or_default();
    }
    pub fn set_skin(&mut self, name: &str) -> bool {
        if self.skins.contains_key(name) {
            self.active_skin = Some(name.to_string());
            true
        } else {
            false
        }
    }
    pub fn get_skin(&self) -> Option<&str> {
        self.active_skin.as_deref()
    }
    pub fn set_skin_mapping(&mut self, skin: &str, slot: &str, attachment: &str) {
        self.skins
            .entry(skin.to_string())
            .or_default()
            .insert(slot.to_string(), attachment.to_string());
    }
    pub fn get_slot_attachment(&self, slot_idx: usize) -> Option<&str> {
        let slot = self.slots.get(slot_idx)?;
        if let Some(skin_name) = &self.active_skin {
            if let Some(skin_map) = self.skins.get(skin_name) {
                if let Some(att) = skin_map.get(&slot.name) {
                    return Some(att.as_str());
                }
            }
        }
        slot.attachment_name.as_deref()
    }
    pub fn slot_count(&self) -> usize {
        self.slots.len()
    }
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
                    self.bones[i].world_x = self.x + local_x * self.scale_x;
                    self.bones[i].world_y = self.y + local_y * self.scale_y;
                    self.bones[i].world_rotation = local_rot;
                    self.bones[i].world_scale_x = self.scale_x * local_sx;
                    self.bones[i].world_scale_y = self.scale_y * local_sy;
                }
                Some(pi) => {
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
    pub fn draw_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 20, 30, 255);
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
        for bone in &self.bones {
            img.draw_circle(
                bone.world_x as i32,
                bone.world_y as i32,
                4,
                255,
                120,
                80,
                255,
            );
        }
        img
    }
    pub fn draw_bones_to_image(&self, width: u32, height: u32) -> crate::image::ImageData {
        let mut img = crate::image::ImageData::new(width, height);
        img.fill(20, 20, 30, 255);
        let palette: [(u8, u8, u8); 12] = [
            (255, 200, 80),
            (200, 100, 100),
            (255, 150, 100),
            (100, 150, 255),
            (100, 150, 255),
            (100, 200, 100),
            (100, 200, 100),
            (200, 100, 255),
            (200, 100, 255),
            (180, 180, 80),
            (80, 180, 180),
            (180, 80, 180),
        ];
        for bone in &self.bones {
            if let Some(pi) = bone.parent_index {
                let parent = &self.bones[pi];
                img.draw_line(
                    parent.world_x as i32,
                    parent.world_y as i32,
                    bone.world_x as i32,
                    bone.world_y as i32,
                    180,
                    180,
                    200,
                    255,
                );
            }
        }
        for (i, bone) in self.bones.iter().enumerate() {
            let (r, g, b) = palette[i % palette.len()];
            img.draw_circle(bone.world_x as i32, bone.world_y as i32, 5, r, g, b, 255);
            let label = bone.name.to_uppercase();
            img.draw_label(
                &label,
                bone.world_x as i32 + 8,
                bone.world_y as i32 - 3,
                r,
                g,
                b,
            );
        }
        let count_str = format!("{} BONES", self.bone_count());
        img.draw_label(&count_str, 10, (height - 15) as i32, 200, 200, 200);
        img.draw_label(
            "SPINE BONES OK",
            (width / 3) as i32,
            (height - 15) as i32,
            100,
            255,
            100,
        );
        img
    }
}
