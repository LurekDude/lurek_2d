//! Group camera state, effect helpers, and viewport scaling primitives.
//! Re-export the module surface used by runtime state and render command builders.
//! Keep camera-domain logic independent from Lua binding code.

/// Define runtime camera effect states.
pub mod effects;
/// Define multi-camera layout orchestration.
pub mod multi;
/// Define camera-local path and zoom tweens.
pub mod path;
/// Build render commands from camera transforms.
pub mod render;
/// Define `Camera`, `Camera2D`, and follow easing types.
pub mod types;
/// Define fixed-resolution viewport mapping.
pub mod viewport;
/// Define viewport mapping with cached scaled dimensions.
pub mod viewport_scale;

pub use effects::{CameraBreathing, CameraSway, ZoomPulse};
pub use multi::CameraRig2D;
pub use path::{CameraPath, CameraTweenEasing, CameraZoomTween, ZoomTween};
pub use types::{Camera, Camera2D, CameraFollowEasing};
pub use viewport::{ScaleMode, Viewport};
pub use viewport_scale::ViewportScale;

