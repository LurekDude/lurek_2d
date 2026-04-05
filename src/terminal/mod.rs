//! Grid-based character-cell terminal emulator and widget toolkit.
//!
//! The `terminal` module provides a 2D grid of [`TCell`] records together
//! with a lightweight widget system for text-mode UIs such as roguelikes,
//! debug consoles, and retro adventure interfaces.
//!
//! Grid dimensions are capped at 512 columns by 256 rows. All public
//! coordinate parameters are 1-based while internal storage is 0-based.
//!
//! ## Tier
//!
//! `terminal` is a Tier 2 engine extension. It may depend on `math`,
//! `engine`, and Tier 1 modules. It must not import other Tier 2 modules.

mod cell;
mod terminal_state;
mod widget;

pub use cell::TCell;
pub use terminal_state::Terminal;
pub(crate) use terminal_state::TerminalEvent;
pub use widget::{BorderStyle, Widget, WidgetBase, WidgetKind};
