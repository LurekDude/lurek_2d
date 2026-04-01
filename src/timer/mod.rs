/// Frame-based clock providing delta time, total time, and FPS.
pub mod clock;
/// Scheduled event manager for delayed and repeating timed callbacks.
pub mod scheduler;

pub use clock::Clock;
pub use scheduler::Scheduler;
