//! Input-playback automation for timed synthetic event injection.
//! Owns Script (named step container), Simulator (playback engine),
//! Step (timed event record), and Action (12 input event variants).
//! Injects events into crate::event::EventQueue; does not own render or audio output.

/// Timed step record and Action enum consumed by Script and Simulator.
pub mod step;
/// Named, time-sorted step container with TOML parsing and repeat expansion.
pub mod script;
/// Playback engine driving step dispatch into EventQueue per update call.
pub mod simulator;

pub use script::Script;
pub use simulator::Simulator;
pub use step::{Action, Step};
