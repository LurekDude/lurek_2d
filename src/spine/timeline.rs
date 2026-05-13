use super::bone::Bone;
#[derive(Debug, Clone, PartialEq)]
pub enum EasingType {
    Linear,
    EaseIn,
    EaseOut,
    EaseInOut,
    Step,
}
impl EasingType {
    pub fn apply(&self, t: f32) -> f32 {
        let t = t.clamp(0.0, 1.0);
        match self {
            Self::Linear => t,
            Self::EaseIn => t * t,
            Self::EaseOut => 1.0 - (1.0 - t) * (1.0 - t),
            Self::EaseInOut => {
                if t < 0.5 {
                    2.0 * t * t
                } else {
                    1.0 - 2.0 * (1.0 - t) * (1.0 - t)
                }
            }
            Self::Step => 0.0,
        }
    }
}
#[derive(Debug, Clone, PartialEq)]
pub enum BoneProperty {
    X,
    Y,
    Rotation,
    ScaleX,
    ScaleY,
}
#[derive(Debug, Clone)]
pub struct Keyframe {
    pub time: f32,
    pub value: f32,
    pub easing: EasingType,
}
#[derive(Debug, Clone)]
pub struct BoneTimeline {
    pub bone_idx: usize,
    pub property: BoneProperty,
    pub keys: Vec<Keyframe>,
}
impl BoneTimeline {
    pub fn new(bone_idx: usize, property: BoneProperty) -> Self {
        Self {
            bone_idx,
            property,
            keys: Vec::new(),
        }
    }
    pub fn add_key(&mut self, time: f32, value: f32, easing: EasingType) {
        let kf = Keyframe {
            time,
            value,
            easing,
        };
        let pos = self.keys.partition_point(|k| k.time <= time);
        self.keys.insert(pos, kf);
    }
    pub fn evaluate(&self, time: f32) -> f32 {
        if self.keys.is_empty() {
            return 0.0;
        }
        if self.keys.len() == 1 || time <= self.keys[0].time {
            return self.keys[0].value;
        }
        let last = self.keys.last().unwrap();
        if time >= last.time {
            return last.value;
        }
        let next_idx = self.keys.partition_point(|k| k.time <= time);
        let prev_idx = next_idx - 1;
        let prev = &self.keys[prev_idx];
        let next = &self.keys[next_idx];
        if prev.easing == EasingType::Step {
            return prev.value;
        }
        let span = next.time - prev.time;
        if span <= 0.0 {
            return next.value;
        }
        let t = (time - prev.time) / span;
        let eased_t = prev.easing.apply(t);
        prev.value + (next.value - prev.value) * eased_t
    }
}
#[derive(Debug, Clone)]
pub struct EventKeyframe {
    pub time: f32,
    pub name: String,
    pub value: f32,
}
impl EventKeyframe {
    pub fn new(time: f32, name: impl Into<String>, value: f32) -> Self {
        Self {
            time,
            name: name.into(),
            value,
        }
    }
}
#[derive(Debug, Clone)]
pub struct SkeletonAnimation {
    pub name: String,
    pub duration: f32,
    pub timelines: Vec<BoneTimeline>,
    pub events: Vec<EventKeyframe>,
}
impl SkeletonAnimation {
    pub fn new(name: impl Into<String>, duration: f32) -> Self {
        Self {
            name: name.into(),
            duration,
            timelines: Vec::new(),
            events: Vec::new(),
        }
    }
    pub fn add_timeline(&mut self, timeline: BoneTimeline) {
        self.timelines.push(timeline);
    }
    pub fn add_event_key(&mut self, time: f32, name: impl Into<String>, value: f32) {
        self.events.push(EventKeyframe::new(time, name, value));
        self.events.sort_by(|a, b| {
            a.time
                .partial_cmp(&b.time)
                .unwrap_or(std::cmp::Ordering::Equal)
        });
    }
    pub fn collect_events(&self, from: f32, to: f32) -> Vec<(String, f32)> {
        self.events
            .iter()
            .filter(|e| e.time > from && e.time <= to)
            .map(|e| (e.name.clone(), e.value))
            .collect()
    }
    pub fn apply_to_skeleton(&self, skeleton: &mut super::skeleton::Skeleton, time: f32) {
        for tl in &self.timelines {
            let value = tl.evaluate(time);
            if let Some(bone) = skeleton.bones.get_mut(tl.bone_idx) {
                apply_bone_property(bone, &tl.property, value);
            }
        }
    }
    pub fn apply_to_skeleton_blended(
        &self,
        skeleton: &mut super::skeleton::Skeleton,
        time: f32,
        blend_weight: f32,
    ) {
        let w = blend_weight.clamp(0.0, 1.0);
        for tl in &self.timelines {
            let target = tl.evaluate(time);
            if let Some(bone) = skeleton.bones.get_mut(tl.bone_idx) {
                let current = current_bone_property(bone, &tl.property);
                let blended = current + (target - current) * w;
                apply_bone_property(bone, &tl.property, blended);
            }
        }
    }
}
fn apply_bone_property(bone: &mut Bone, prop: &BoneProperty, value: f32) {
    match prop {
        BoneProperty::X => bone.local_x = value,
        BoneProperty::Y => bone.local_y = value,
        BoneProperty::Rotation => bone.local_rotation = value,
        BoneProperty::ScaleX => bone.local_scale_x = value,
        BoneProperty::ScaleY => bone.local_scale_y = value,
    }
}
fn current_bone_property(bone: &Bone, prop: &BoneProperty) -> f32 {
    match prop {
        BoneProperty::X => bone.local_x,
        BoneProperty::Y => bone.local_y,
        BoneProperty::Rotation => bone.local_rotation,
        BoneProperty::ScaleX => bone.local_scale_x,
        BoneProperty::ScaleY => bone.local_scale_y,
    }
}
impl SkeletonAnimation {
    pub fn pose_at(&self, time: f32) -> Vec<(usize, BoneProperty, f32)> {
        self.timelines
            .iter()
            .map(|tl| (tl.bone_idx, tl.property.clone(), tl.evaluate(time)))
            .collect()
    }
    pub fn reverse(&self) -> Self {
        let dur = self.duration;
        let timelines: Vec<BoneTimeline> = self
            .timelines
            .iter()
            .map(|tl| {
                let mut flipped = BoneTimeline::new(tl.bone_idx, tl.property.clone());
                for kf in tl.keys.iter().rev() {
                    flipped.add_key(dur - kf.time, kf.value, kf.easing.clone());
                }
                flipped
            })
            .collect();
        let events: Vec<EventKeyframe> = self
            .events
            .iter()
            .map(|e| EventKeyframe::new(dur - e.time, &e.name, e.value))
            .collect();
        Self {
            name: format!("{}_reversed", self.name),
            duration: dur,
            timelines,
            events,
        }
    }
    pub fn from_json(v: &serde_json::Value) -> Option<Self> {
        let name = v.get("name")?.as_str()?.to_owned();
        let duration = v.get("duration")?.as_f64()? as f32;
        let mut anim = Self::new(name, duration);
        if let Some(timelines) = v.get("timelines").and_then(|t| t.as_array()) {
            for tl_val in timelines {
                let bone_idx = tl_val.get("bone_idx")?.as_u64()? as usize;
                let property = match tl_val.get("property")?.as_str()? {
                    "x" => BoneProperty::X,
                    "y" => BoneProperty::Y,
                    "rotation" => BoneProperty::Rotation,
                    "scale_x" => BoneProperty::ScaleX,
                    "scale_y" => BoneProperty::ScaleY,
                    _ => continue,
                };
                let mut tl = BoneTimeline::new(bone_idx, property);
                if let Some(keys) = tl_val.get("keys").and_then(|k| k.as_array()) {
                    for kf in keys {
                        let t = kf.get("time").and_then(|v| v.as_f64()).unwrap_or(0.0) as f32;
                        let val = kf.get("value").and_then(|v| v.as_f64()).unwrap_or(0.0) as f32;
                        let easing = match kf
                            .get("easing")
                            .and_then(|e| e.as_str())
                            .unwrap_or("linear")
                        {
                            "ease_in" => EasingType::EaseIn,
                            "ease_out" => EasingType::EaseOut,
                            "ease_in_out" => EasingType::EaseInOut,
                            "step" => EasingType::Step,
                            _ => EasingType::Linear,
                        };
                        tl.add_key(t, val, easing);
                    }
                }
                anim.add_timeline(tl);
            }
        }
        if let Some(events) = v.get("events").and_then(|e| e.as_array()) {
            for ev in events {
                let t = ev.get("time").and_then(|v| v.as_f64()).unwrap_or(0.0) as f32;
                let ev_name = ev
                    .get("name")
                    .and_then(|v| v.as_str())
                    .unwrap_or("")
                    .to_owned();
                let val = ev.get("value").and_then(|v| v.as_f64()).unwrap_or(0.0) as f32;
                anim.add_event_key(t, ev_name, val);
            }
        }
        Some(anim)
    }
}
