//! Mod implementation for the `timer` subsystem.
//!
//! This module is part of Luna2D's `timer` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.
//!
/// Frame-based clock providing delta time, total time, and FPS.
pub mod clock;
/// Scheduled event manager for delayed and repeating timed callbacks.
pub mod scheduler;

pub use clock::Clock;
pub use scheduler::Scheduler;
