use super::bone::Bone;
#[derive(Debug, Clone)]
pub struct IKConstraint {
    pub name: String,
    pub bone_chain: Vec<usize>,
    pub target_x: f32,
    pub target_y: f32,
    pub bend_positive: bool,
}
impl IKConstraint {
    pub fn new(name: impl Into<String>, bone_chain: Vec<usize>, bend_positive: bool) -> Self {
        Self {
            name: name.into(),
            bone_chain,
            target_x: 0.0,
            target_y: 0.0,
            bend_positive,
        }
    }
    pub fn set_target(&mut self, x: f32, y: f32) {
        self.target_x = x;
        self.target_y = y;
    }
    #[allow(clippy::ptr_arg)]
    pub fn solve(&self, bones: &mut Vec<Bone>) {
        if self.bone_chain.len() < 2 {
            return;
        }
        let root_idx = self.bone_chain[0];
        let elbow_idx = self.bone_chain[1];
        if root_idx >= bones.len() || elbow_idx >= bones.len() {
            return;
        }
        let (root_wx, root_wy) = {
            let r = &bones[root_idx];
            (r.world_x, r.world_y)
        };
        let (elbow_wx, elbow_wy) = {
            let e = &bones[elbow_idx];
            (e.world_x, e.world_y)
        };
        let upper_len = {
            let dx = elbow_wx - root_wx;
            let dy = elbow_wy - root_wy;
            (dx * dx + dy * dy).sqrt()
        };
        let lower_len = {
            let e = &bones[elbow_idx];
            let dx = e.local_x;
            let dy = e.local_y;
            (dx * dx + dy * dy).sqrt().max(1.0)
        };
        let upper_len = upper_len.max(1.0);
        let dx = self.target_x - root_wx;
        let dy = self.target_y - root_wy;
        let dist = (dx * dx + dy * dy).sqrt();
        let angle_to_target = dy.atan2(dx);
        let cos_a = {
            let num = dist * dist + upper_len * upper_len - lower_len * lower_len;
            let den = 2.0 * dist * upper_len;
            if den.abs() < f32::EPSILON {
                1.0f32
            } else {
                (num / den).clamp(-1.0, 1.0)
            }
        };
        let angle_a = cos_a.acos();
        let root_rotation = if self.bend_positive {
            angle_to_target - angle_a
        } else {
            angle_to_target + angle_a
        };
        let cos_b = {
            let num = upper_len * upper_len + lower_len * lower_len - dist * dist;
            let den = 2.0 * upper_len * lower_len;
            if den.abs() < f32::EPSILON {
                1.0f32
            } else {
                (num / den).clamp(-1.0, 1.0)
            }
        };
        let angle_b = cos_b.acos();
        let elbow_rotation = if self.bend_positive {
            std::f32::consts::PI - angle_b
        } else {
            -(std::f32::consts::PI - angle_b)
        };
        bones[root_idx].local_rotation = root_rotation;
        bones[elbow_idx].local_rotation = elbow_rotation;
    }
}
