//! Camera and viewport types for 2D rendering.
//!
//! This is a Tier 1 engine module. Imports only from `crate::math`.
//!
//! ## Subsystem inventory
//! - [`camera`] — [`Camera`] and [`Camera2D`] transform types
//! - [`viewport`] — [`Viewport`] virtual-resolution mapping with [`ScaleMode`]
//! - [`viewport_scale`] — [`ViewportScale`] with automatic scaled-dimension tracking
//!
//! ## Architecture note (Tier 1)
//! `camera` is a Tier 1 engine module. It was extracted from `src/graphics/` during the
//! graphics-module-split session. `SharedState` holds a `Camera` field; see
//! `work/graphics-module-split/reports/camera-decision.md` for the CPD-1 Option C rationale.
//!
//! ## Typical usage sequence
//! 1. Construct a [`Camera`] or [`Camera2D`] via `new()`.
//! 2. Call `view_matrix()` to obtain the transform applied to draw calls.
//! 3. Use [`Viewport`] or [`ViewportScale`] to map the fixed game resolution onto the window.

/// Camera types: [`Camera`] (flat API) and [`Camera2D`] (smooth follow, shake, bounds).
pub mod types;
/// Cinematic camera effects: zoom pulse, sway, and breathing.
pub mod effects;
/// Virtual-resolution viewport with letterbox / stretch / pixel-perfect scaling.
pub mod viewport;
/// Virtual-resolution viewport that also exposes scaled content dimensions for transform-stack integration.
pub mod viewport_scale;
/// Render-command generation for camera transforms.
pub mod render;
/// Camera path follower and smooth-zoom tween helpers for `LuaCamera2D`.
pub mod path;

pub use types::{Camera, Camera2D};
pub use effects::{CameraBreathing, CameraSway, ZoomPulse};
pub use path::{CameraPath, ZoomTween};
pub use viewport::{ScaleMode, Viewport};
pub use viewport_scale::ViewportScale;
