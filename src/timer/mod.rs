//! Mod implementation for the `timer` subsystem.
//!
//! This module is part of Lurek2D's `timer` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.
//!
/// Frame-based clock providing delta time, total time, and FPS.
pub mod clock;
/// Scheduled event manager for delayed and repeating timed callbacks.
pub mod scheduler;

pub use clock::Clock;
pub use scheduler::Scheduler;

/// Suspends the current thread for the given number of seconds.
///
/// Values ≤ 0 are ignored. This is a simple convenience wrapper around
/// [`std::thread::sleep`].
///
/// # Parameters
/// - `seconds` — `f64`.
pub fn sleep(seconds: f64) {
    if seconds > 0.0 {
        std::thread::sleep(std::time::Duration::from_secs_f64(seconds));
    }
}
