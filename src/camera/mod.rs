//! Camera subsystem for 2D world-view control, framing, and viewport scaling.
//! Owns camera state types, render transform command builders, and helper effects.
//! Keeps logic local to camera behavior and does not own renderer execution.
//! Depends on math primitives and render command enums from core subsystems.

/// Exposes camera effect primitives for sway, breathing, and pulse behavior.
pub mod effects;
/// Exposes multi-camera rig management for split and overlay layouts.
pub mod multi;
/// Exposes camera path and zoom tween helpers for timed interpolation.
pub mod path;
/// Exposes render-command generation from camera state.
pub mod render;
/// Exposes core camera state containers and follow logic.
pub mod types;
/// Exposes viewport scaling strategies and screen/game transforms.
pub mod viewport;
/// Exposes viewport scaling state object used by resize flows.
pub mod viewport_scale;
pub use effects::{CameraBreathing, CameraSway, ZoomPulse};
pub use multi::CameraRig2D;
pub use path::{CameraPath, CameraTweenEasing, CameraZoomTween, ZoomTween};
pub use types::{Camera, Camera2D, CameraFollowEasing};
pub use viewport::{ScaleMode, Viewport};
pub use viewport_scale::ViewportScale;
