//! Scene management: stack-based scene lifecycle, depth sorting, transitions, and scene rendering.
//! Owns SceneStack, DepthSorter, transition types, and easing helpers.
//! Does not own rendering commands — those are assembled in render.rs and forwarded to the render pipeline.
//! Key dependencies: render (RenderCommand), math (Vec2), transition state machine.

/// Depth-sorted entity ordering for scene draw calls.
pub mod depth_sorter;
/// Internal easing curve math used by transition.rs.
pub(crate) mod easing;
/// Scene-level render assembly: collects draw commands for the active scene.
pub mod render;
/// SceneStack and SceneId: push/pop lifecycle for game scenes.
pub mod stack;
/// Transition types, active transition state, and easing type selection.
pub mod transition;
pub use depth_sorter::DepthSorter;
pub use stack::{SceneId, SceneStack};
pub use transition::{ActiveTransition, EasingType, TransitionType};
