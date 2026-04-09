//! Property tween state: timing, easing, and interpolation helpers.
//!
//! # Purpose
//!
//! This module provides the pure-Rust numeric layer for the Lurek2D tween system.
//! It is a Tier 1 Engine Subsystem — it depends only on `crate::math` (specifically
//! `crate::math::easing`) and has no Lua or engine lifecycle dependencies.
//!
//! # Responsibilities
//!
//! - `TweenState` — tracks elapsed time, easing function, and pause state. Computes
//!   the eased interpolation factor `t` for a given playback position.
//! - `resolve_easing` — maps human-readable easing names to `fn(f32) -> f32` pointers.
//! - `builtin_easing_names` — returns the full list of built-in easing names for Lua
//!   introspection via `lurek.tween.getEasingNames()`.
//!
//! # Architecture note
//!
//! `TweenState` deliberately holds **no Lua references**. The Lua binding layer
//! (`src/lua_api/tween_api.rs`) composes `TweenState` with `LuaRegistryKey` handles
//! that point to target tables and lifecycle callbacks. This keeps the domain type
//! usable in headless Rust tests without a Lua VM.
//!
//! # Typical usage sequence
//!
//! 1. `TweenState::new(duration, easing_name)` — create.
//! 2. Call `tick(dt)` each frame; returns `true` when complete.
//! 3. Use `lerp(start, end)` to compute the current interpolated value for each field.
//! 4. On complete: call `reset()` if repeating, or release the state entirely.

pub mod engine;
pub mod handle;
pub mod state;

pub use engine::TweenEngine;
pub use handle::{LuaTween, LuaTweenParallel, LuaTweenSequence, ParallelEntry, SequenceStep};
pub use state::{builtin_easing_names, resolve_easing, TweenState};
