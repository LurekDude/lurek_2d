//! Frame timing and scheduled event system.
//!
//! Provides two complementary types: [`Clock`] for per-frame delta-time tracking and FPS
//! measurement, and [`Scheduler`] for deferred and repeating Lua callback execution.
//!
//! ## Subsystem inventory
//! - [`clock`] — [`Clock`]: `tick()` updates `dt`, smoothed FPS, elapsed time, frame count
//! - [`scheduler`] — [`Scheduler`]: `schedule(delay, fn)`, `every(interval, fn)`,
//!   `after_frames(n, fn)` with cancellation handles
//!
//! ## Threading constraint
//! `Scheduler` callbacks run synchronously on the main thread. Errors from callbacks are
//! caught and forwarded through the engine error channel rather than panicking. The `sleep()`
//! helper is intended only for worker VM threads — calling it from the main VM stalls
//! the engine frame loop.
//!
//! All public items are documented. Lua bridge: `src/lua_api/timer_api.rs`.

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
