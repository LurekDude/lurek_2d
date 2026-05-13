pub mod facade;
pub mod sinks;
pub use facade::{enabled_for, get_level, log_structured, set_level, LogFields};
pub use sinks::{MemoryEntry, RotatingFileSink, Sink, SinkLevel, SinkRegistry};
