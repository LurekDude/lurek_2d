//! - Time tracking, fixed-step accumulation, and frame-independent scheduling.
//! - Provides a high-resolution clock, scaled delta, and sleep utilities.
//! - Exposes a tick-based scheduler for deferred and repeating callbacks.

/// Exposes the accumulator module.
pub(crate) mod accumulator;
/// Game clock with delta time, elapsed time, and time-scale support.
pub mod clock;
/// Tick-based scheduler for delayed, repeating, and one-shot callbacks.
pub mod scheduler;
/// Thread-sleep utilities with platform-appropriate precision.
pub mod sleep;
pub(crate) use accumulator::accumulate_scaled_micros;
pub use clock::Clock;
pub use scheduler::Scheduler;
pub use sleep::sleep;
