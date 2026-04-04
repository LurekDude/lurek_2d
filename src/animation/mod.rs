//! Sprite animation system: named clips, frame pools, speed control, and frame-level events.
//!
//! This is a Tier 1 engine module. It imports only from `crate::math`.
//!
//! An [`Animation`] stores a pool of [`AnimFrame`] entries (each defining a source
//! rectangle and optional per-frame duration) and any number of named [`AnimClip`]s
//! that reference those frames by index. Call [`Animation::update`] each tick and
//! inspect [`Animation::drain_events`] for playback notifications.

/// Single animation frame: source quad and optional per-frame duration.
pub mod frame;
/// Named clip: frame index list, FPS, and looping flag.
pub mod clip;
/// Playback events emitted by [`Animation::update`].
pub mod event;
/// [`Animation`] controller: frame pool, clip management, and update logic.
pub mod controller;

pub use controller::Animation;
pub use clip::AnimClip;
pub use event::AnimEvent;
pub use frame::{AnimFrame, AnimationFrame};
