//! Spine-compatible 2D skeletal animation runtime.
//! Owns Skeleton, Bone, Slot, IKConstraint, BoneTimeline, and SkeletonAnimation.
//! Does not own asset loading or rendering commands — render.rs bridges to the render pipeline.
//! Key dependencies: math (Vec2, Mat3), render (RenderCommand).

/// Bone transform hierarchy and parent-relative pose computation.
pub mod bone;
/// Inverse-kinematics constraint resolving 2-bone IK chains.
pub mod ik;
/// Skeleton-level render assembly: converts posed bones/slots to RenderCommands.
pub mod render;
/// Skeleton: bone tree, slot list, pose accumulation, and animation playback.
pub mod skeleton;
/// Slot: attachment point linking a bone to a drawable region.
pub mod slot;
/// Timeline, keyframe, easing, and animation clip data for skeletal animation.
pub mod timeline;
pub use bone::Bone;
pub use ik::IKConstraint;
pub use skeleton::{BoneParams, Skeleton};
pub use slot::Slot;
pub use timeline::{BoneProperty, BoneTimeline, EasingType, Keyframe, SkeletonAnimation};
