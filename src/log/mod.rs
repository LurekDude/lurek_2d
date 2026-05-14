//! Structured logging subsystem: level filtering, sink dispatch, and in-memory ring buffer.
//! Owns the log facade (global level, `log_structured`, `enabled_for`) and sink registry (file, memory, custom sinks).
//! Does not own the `log_msg!` macro definition — that lives in `src/runtime/`.
//! Key dependencies: `src/log/facade.rs` and `src/log/sinks.rs`.

/// Structured log facade: global level, enabled checks, and dispatch to sink registry.
pub mod facade;
/// Log sink types: rotating file sink, in-memory ring buffer, and sink registry.
pub mod sinks;
/// Structured log dispatch and level configuration API.
pub use facade::{enabled_for, get_level, log_structured, set_level, LogFields};
/// Sink types for routing structured log output to files and in-memory buffers.
pub use sinks::{MemoryEntry, RotatingFileSink, Sink, SinkLevel, SinkRegistry};
