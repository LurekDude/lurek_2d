//! Input replay and deterministic test automation.
//! Owns `Script` (ordered step list), `Simulator` (playback engine), and `Step`/`Action`
//! (timed event descriptors). Does not own event dispatch internals or game logic.
//! Depends on `event::EventQueue`, input constants, and `timer::accumulate_scaled_micros`.

/// `Script`: ordered, time-sorted step sequences with TOML parsing and repeat expansion.
pub mod script;
/// `Simulator`: drives script playback, macro inlining, condition evaluation, and visual asserts.
pub mod simulator;
/// `Action` and `Step` types: timed input event descriptors for automation scripts.
pub mod step;
pub use script::Script;
pub use simulator::Simulator;
pub use step::{Action, Step};
