//! Developer-tools subsystem for Lurek2D.
//!
//! Provides five collaborating facilities exposed to Lua games via
//! `lurek.devtools.*`:
//!
//! | Facility | Type | Purpose |
//! |---|---|---|
//! | Logger | [`Logger`] | Level-filtered, categorised in-process log with rolling history |
//! | Profiler | [`Profiler`] | Hierarchical zone-based frame profiler |
//! | Frame stats | [`FrameStats`] | Rolling FPS / frame-time statistics and percentiles |
//! | File watcher | [`FileWatcher`] | Polling mtime watcher for hot-reload detection |
//! | REPL console | [`ReplConsole`] | Interactive Lua evaluation with bounded history |
//!
//! This module is a **Tier 2** Engine Extension and may import from any
//! Tier-1 module or the Baseline, but must never import from `lua_api`.
//!
//! ## Source files
//! | File | Contents |
//! |---|---|
//! | `logger.rs` | [`Logger`], [`LogLevel`], [`LogEntry`] |
//! | `profiler.rs` | [`Profiler`], [`ProfileZone`] |
//! | `frame_stats.rs` | [`FrameStats`], [`FrameSnapshot`] |
//! | `watcher.rs` | [`FileWatcher`] |
//! | `repl.rs` | [`ReplConsole`] |

/// Rolling FPS and frame-time statistics with percentile reporting.
pub mod frame_stats;
/// Shared helpers for converting Lua runtime values to text.
pub mod lua_display;
/// Level-filtered, categorised in-process log with rolling history.
pub mod logger;
/// Hierarchical zone-based frame profiler.
pub mod profiler;
/// Interactive Lua REPL console with bounded input history.
pub mod repl;
/// Shared elapsed-time anchor used by logger/profiler internals.
pub mod time_anchor;
/// Polling mtime watcher for hot-reload detection.
pub mod watcher;

pub use frame_stats::{FrameSnapshot, FrameStats};
pub use logger::{LogEntry, LogLevel, Logger};
pub use profiler::{ProfileZone, Profiler};
pub use repl::ReplConsole;
pub use watcher::FileWatcher;
