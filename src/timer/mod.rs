//! Timer subsystem — fixed-step accumulator, frame clock, scheduled callbacks,
//! and cross-platform sleep. Does not own rendering or physics stepping; those
//! modules consume `Clock` and `Scheduler` directly. Key dependencies: `std::time`.

pub(crate) mod accumulator;
pub mod clock;
pub mod scheduler;
pub mod sleep;
pub(crate) use accumulator::accumulate_scaled_micros;
pub use clock::Clock;
pub use scheduler::Scheduler;
pub use sleep::sleep;
