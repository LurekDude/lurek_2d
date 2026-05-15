//! - Automation subsystem for deterministic input replay and visual regression testing.
//! - Script stores time-sorted steps parsed from TOML with repeat expansion.
//! - Simulator drives playback, dispatches events, evaluates conditions, and runs asserts.
//! - Step and Action types describe timed input events and control flow actions.

/// `Script`: ordered, time-sorted step sequences with TOML parsing and repeat expansion.
pub mod script;
/// `Simulator`: drives script playback, macro inlining, condition evaluation, and visual asserts.
pub mod simulator;
/// `Action` and `Step` types: timed input event descriptors for automation scripts.
pub mod step;
pub use script::Script;
pub use simulator::Simulator;
pub use step::{Action, Step};
