//! Keyframe timelines and skeleton animation playback for the spine module.
//!
//! A [`SkeletonAnimation`] contains one or more [`BoneTimeline`]s. Each timeline
//! animates a single property of a single bone over time. Call
//! [`SkeletonAnimation::apply_to_skeleton`] each frame to evaluate all timelines
//! at the current playback time and write bone local transforms.

use super::bone::Bone;

// â”€â”€ Easing â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Interpolation curve type for keyframe blending.
///
/// # Variants
/// - `Linear` â€” uniform lerp.
/// - `EaseIn` â€” accelerates from zero.
/// - `EaseOut` â€” decelerates to zero.
/// - `EaseInOut` â€” S-curve.
/// - `Step` â€” jumps to end value at the next frame.
#[derive(Debug, Clone, PartialEq)]
pub enum EasingType {
    /// Uniform linear interpolation.
    Linear,
    /// Quadratic ease-in (tÂ˛).
    EaseIn,
    /// Quadratic ease-out (1-(1-t)Â˛).
    EaseOut,
    /// Hermite S-curve ease-in-out.
    EaseInOut,
    /// Instant jump â€” holds previous value until the next keyframe.
    Step,
}

impl EasingType {
    /// Applies the easing curve to a normalised time value `t â [0, 1]`.
    ///
    /// # Parameters
    /// - `t` â€” `f32`. Normalised time (0 = start, 1 = end).
    ///
    /// # Returns
    /// `f32` â€” eased value in `[0, 1]`.
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
            Self::Step => 0.0, // holds â€” caller handles by returning previous value
        }
    }
}

// â”€â”€ Bone property â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Bone local-transform property that a timeline can animate.
///
/// # Variants
/// - `X`, `Y`, `Rotation`, `ScaleX`, `ScaleY`.
#[derive(Debug, Clone, PartialEq)]
pub enum BoneProperty {
    /// Local X translation.
    X,
    /// Local Y translation.
    Y,
    /// Local rotation in radians.
    Rotation,
    /// Local X scale.
    ScaleX,
    /// Local Y scale.
    ScaleY,
}

// â”€â”€ Keyframe â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// A single timed value sample on a bone timeline.
///
/// # Fields
/// - `time` â€” `f32`. Time in seconds from animation start.
/// - `value` â€” `f32`. Target value of the bone property.
/// - `easing` â€” [`EasingType`]. Interpolation curve to the next keyframe.
#[derive(Debug, Clone)]
pub struct Keyframe {
    /// Time offset from animation start in seconds.
    pub time: f32,
    /// Target value of the bone property at this keyframe.
    pub value: f32,
    /// Easing curve used when blending from this keyframe to the next.
    pub easing: EasingType,
}

// â”€â”€ BoneTimeline â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Sequence of keyframes that animate a single property of a single bone.
///
/// # Fields
/// - `bone_idx` â€” `usize`. Index of the target bone in the skeleton's bone array.
/// - `property` â€” [`BoneProperty`]. Which local transform property to animate.
/// - `keys` â€” `Vec<Keyframe>`. Keyframes sorted by ascending time.
#[derive(Debug, Clone)]
pub struct BoneTimeline {
    /// Index of the target bone in the skeleton's bone array.
    pub bone_idx: usize,
    /// Local transform property this timeline animates.
    pub property: BoneProperty,
    /// Keyframes sorted by ascending time.
    pub keys: Vec<Keyframe>,
}

impl BoneTimeline {
    /// Creates a new empty timeline for the given bone and property.
    ///
    /// # Parameters
    /// - `bone_idx` â€” `usize`. Bone index.
    /// - `property` â€” [`BoneProperty`]. Transform property.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(bone_idx: usize, property: BoneProperty) -> Self {
        Self { bone_idx, property, keys: Vec::new() }
    }

    /// Appends a keyframe at `time` with `value` and the given easing.
    ///
    /// Keyframes are kept in ascending time order.
    ///
    /// # Parameters
    /// - `time` â€” `f32`. Time in seconds.
    /// - `value` â€” `f32`. Target value.
    /// - `easing` â€” [`EasingType`].
    pub fn add_key(&mut self, time: f32, value: f32, easing: EasingType) {
        let kf = Keyframe { time, value, easing };
        // Insert in sorted position
        let pos = self.keys.partition_point(|k| k.time <= time);
        self.keys.insert(pos, kf);
    }

    /// Evaluates the timeline at `time`, interpolating between surrounding keyframes.
    ///
    /// Returns the value from the first or last keyframe when `time` is outside the
    /// timeline range. Uses the easing of the earlier keyframe for blending.
    ///
    /// # Parameters
    /// - `time` â€” `f32`. Playback time in seconds.
    ///
    /// # Returns
    /// `f32`.
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

        // Find the two surrounding keyframes.
        let next_idx = self.keys.partition_point(|k| k.time <= time);
        let prev_idx = next_idx - 1;

        let prev = &self.keys[prev_idx];
        let next = &self.keys[next_idx];

        // Step easing: hold prev value until next keyframe.
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

// â”€â”€ EventKeyframe â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// A timed event marker inside a [`SkeletonAnimation`].
///
/// Event keyframes fire a named event when the animation's playhead crosses
/// their timestamp.  Listeners can react to events (e.g. play a footstep sound
/// at a precise animation frame) without polling the playback time.
///
/// # Fields
/// - `time` â€” `f32`.  Position on the timeline in seconds (0.0 â€¦ clip duration).
/// - `name` â€” `String`.  Logical event label (e.g. `"footstep"`, `"attack"`).
/// - `value` â€” `f32`.  Optional numeric payload (default `0.0`).
#[derive(Debug, Clone)]
pub struct EventKeyframe {
    /// Timestamp in seconds at which the event fires.
    pub time: f32,
    /// Logical event label, e.g. `"footstep"`.
    pub name: String,
    /// Optional numeric payload carried by the event (default `0.0`).
    pub value: f32,
}

impl EventKeyframe {
    /// Creates a new event keyframe.
    ///
    /// # Parameters
    /// - `time` â€” `f32`. Timestamp in seconds.
    /// - `name` â€” `impl Into<String>`. Event label.
    /// - `value` â€” `f32`. Numeric payload.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(time: f32, name: impl Into<String>, value: f32) -> Self {
        Self { time, name: name.into(), value }
    }
}

// â”€â”€ SkeletonAnimation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

/// Named animation clip for a skeleton: contains timelines for multiple bones
/// and optional event keyframes.
///
/// # Fields
/// - `name` â€” `String`. Clip name.
/// - `duration` â€” `f32`. Total duration in seconds.
/// - `timelines` â€” `Vec<BoneTimeline>`.
/// - `events` â€” `Vec<EventKeyframe>`.  Timed event markers in the clip.
#[derive(Debug, Clone)]
pub struct SkeletonAnimation {
    /// Human-readable animation name.
    pub name: String,
    /// Total animation duration in seconds.
    pub duration: f32,
    /// Timelines for individual bone properties.
    pub timelines: Vec<BoneTimeline>,
    /// Timed event markers (fire-and-forget callbacks).
    pub events: Vec<EventKeyframe>,
}

impl SkeletonAnimation {
    /// Creates a new empty skeleton animation clip.
    ///
    /// # Parameters
    /// - `name` â€” `impl Into<String>`. Clip name.
    /// - `duration` â€” `f32`. Duration in seconds.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>, duration: f32) -> Self {
        Self { name: name.into(), duration, timelines: Vec::new(), events: Vec::new() }
    }

    /// Appends a bone timeline.
    ///
    /// # Parameters
    /// - `timeline` â€” [`BoneTimeline`].
    pub fn add_timeline(&mut self, timeline: BoneTimeline) {
        self.timelines.push(timeline);
    }

    /// Adds an event keyframe to the clip.
    ///
    /// Events are sorted by time automatically so their insertion order does
    /// not matter â€” `collect_events` always returns them in chronological order.
    ///
    /// # Parameters
    /// - `time` â€” `f32`. Timestamp in seconds.
    /// - `name` â€” `impl Into<String>`. Event label.
    /// - `value` â€” `f32`. Numeric payload (pass `0.0` if unused).
    pub fn add_event_key(&mut self, time: f32, name: impl Into<String>, value: f32) {
        self.events.push(EventKeyframe::new(time, name, value));
        self.events.sort_by(|a, b| a.time.partial_cmp(&b.time).unwrap_or(std::cmp::Ordering::Equal));
    }

    /// Returns the names of all events whose timestamps fall in `(from, to]`.
    ///
    /// Used each frame to detect which events were crossed since the last update.
    ///
    /// # Parameters
    /// - `from` â€” `f32`. Exclusive lower bound (previous playback time).
    /// - `to` â€” `f32`. Inclusive upper bound (current playback time).
    ///
    /// # Returns
    /// `Vec<(String, f32)>` â€” (event name, payload value) pairs in chronological order.
    pub fn collect_events(&self, from: f32, to: f32) -> Vec<(String, f32)> {
        self.events
            .iter()
            .filter(|e| e.time > from && e.time <= to)
            .map(|e| (e.name.clone(), e.value))
            .collect()
    }

    /// Evaluates all timelines at `time` and writes results into the skeleton's bones.
    ///
    /// Only writes to bone indices that are in-range for the provided bone slice.
    ///
    /// # Parameters
    /// - `skeleton` â€” `&mut super::skeleton::Skeleton`. Skeleton to modify.
    /// - `time` â€” `f32`. Playback time in seconds.
    pub fn apply_to_skeleton(&self, skeleton: &mut super::skeleton::Skeleton, time: f32) {
        for tl in &self.timelines {
            let value = tl.evaluate(time);
            if let Some(bone) = skeleton.bones.get_mut(tl.bone_idx) {
                apply_bone_property(bone, &tl.property, value);
            }
        }
    }

    /// Evaluates all timelines at `time` and **blends** the results with the
    /// skeleton's current bone values using `blend_weight`.
    ///
    /// A `blend_weight` of `1.0` is equivalent to [`apply_to_skeleton`].
    /// A value of `0.0` leaves the skeleton unchanged.
    /// Intermediate values linearly interpolate between the current pose and
    /// the clip pose, enabling smooth cross-fades between animations.
    ///
    /// # Parameters
    /// - `skeleton` â€” `&mut super::skeleton::Skeleton`. Skeleton to modify.
    /// - `time` â€” `f32`. Playback time in seconds.
    /// - `blend_weight` â€” `f32`. Blend factor in `[0.0, 1.0]`.  Clamped to that range.
    ///
    /// [`apply_to_skeleton`]: Self::apply_to_skeleton
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

/// Writes `value` to the named local property of a bone.
fn apply_bone_property(bone: &mut Bone, prop: &BoneProperty, value: f32) {
    match prop {
        BoneProperty::X => bone.local_x = value,
        BoneProperty::Y => bone.local_y = value,
        BoneProperty::Rotation => bone.local_rotation = value,
        BoneProperty::ScaleX => bone.local_scale_x = value,
        BoneProperty::ScaleY => bone.local_scale_y = value,
    }
}

/// Reads the current local property value of a bone.
///
/// Used by the blend path to fetch the starting value for interpolation.
fn current_bone_property(bone: &Bone, prop: &BoneProperty) -> f32 {
    match prop {
        BoneProperty::X => bone.local_x,
        BoneProperty::Y => bone.local_y,
        BoneProperty::Rotation => bone.local_rotation,
        BoneProperty::ScaleX => bone.local_scale_x,
        BoneProperty::ScaleY => bone.local_scale_y,
    }
}
