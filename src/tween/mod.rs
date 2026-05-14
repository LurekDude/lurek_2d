//! Tween and spring animation subsystem for `lurek.tween`.
//! Owns the tween engine, Lua-visible tween handles, spring simulation, and
//! easing state. Does not own rendering or the game clock; consumers call
//! `TweenEngine::update` each frame with the current delta time.

pub mod engine;
pub mod handle;
pub mod spring;
pub mod state;
pub use engine::TweenEngine;
pub use handle::{LuaTween, LuaTweenParallel, LuaTweenSequence, ParallelEntry, SequenceStep};
pub use spring::{SpringAxis, SpringSystem};
pub use state::{builtin_easing_names, resolve_easing, TweenState};
