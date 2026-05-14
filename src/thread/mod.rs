//! Thread-safe concurrency primitives for the engine: typed MPMC channels,
//! a worker-thread pool, async promises, and the worker VM harness. Does not
//! own the Lua VM scheduler; that lives in `runtime`. Depends on `std::sync`
//! and `std::thread`; no external crates.

/// Typed MPMC channel built on `crossbeam`-style semantics for cross-thread messages.
pub mod channel;
/// Fixed-size thread pool for CPU-bound tasks dispatched from the game thread.
pub mod pool;
/// Single-value async result container shared between a producer thread and consumer.
pub mod promise;
/// Worker-thread harness that owns a secondary Lua VM and processes message payloads.
pub mod worker;

