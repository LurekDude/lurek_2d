//! Developer-tools subsystem for Lurek2D.
//!
//! Provides four collaborating facilities exposed to Lua games via
//! `lurek.devtools.*`:
//!
//! | Facility | Type | Purpose |
//! |---|---|---|
//! | Logger | [`Logger`] | Level-filtered, categorised in-process log with rolling history |
//! | Profiler | [`Profiler`] | Hierarchical zone-based frame profiler |
//! | Frame stats | [`FrameStats`] | Rolling FPS / frame-time statistics and percentiles |
//! | File watcher | [`FileWatcher`] | Polling mtime watcher for hot-reload detection |
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

pub mod frame_stats;
pub mod logger;
pub mod profiler;
pub mod watcher;

pub use frame_stats::{FrameSnapshot, FrameStats};
pub use logger::{LogEntry, LogLevel, Logger};
pub use profiler::{ProfileZone, Profiler};
pub use watcher::FileWatcher;
