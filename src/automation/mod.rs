//! Automated input simulation via timed step scripts.
//!
//! The `automation` module provides the [`Simulator`] engine for loading and
//! playing back named [`Script`] objects. Each script contains an ordered
//! sequence of timed [`Step`] records that inject synthetic input events
//! (key presses, mouse movements, text input, etc.) into the Lurek2D
//! [`EventQueue`](crate::event::EventQueue) during game updates.
//!
//! Primary use-cases are headless integration tests, QA regression replay,
//! speedrun verification, and recorded developer input sessions.
//!
//! ## Module structure
//!
//! | Sub-module | Exported types | Purpose |
//! |---|---|---|
//! | `step` | [`Action`], [`Step`] | Enum of 8 action kinds; per-step record with 12 fields |
//! | `script` | [`Script`] | Named, time-sorted, MAX_STEPS-capped step container |
//! | `simulator` | [`Simulator`] | Playback engine driven by the `lurek.simulator.*` Lua API |
//!
//! ## Quick-start (Lua)
//!
//! ```lua
//! -- Load and start a script
//! local steps = {
//!     { time = 0.1, action = "keypress", key = "space" },
//!     { time = 0.5, action = "mousepress", x = 100, y = 200 },
//! }
//! lurek.simulator.load("demo", steps)
//! lurek.simulator.start("demo")
//!
//! -- Advance playback each frame
//! function lurek.update(dt)
//!     lurek.simulator.update(dt)
//!     if lurek.simulator.isComplete() then
//!         lurek.simulator.stop()
//!     end
//! end
//! ```
//!
//! ## Tier
//!
//! `automation` is a **Tier 2 — Engine Extension** module. It may import
//! `math`, `engine`, and all Tier 1 modules (`event`, `input`, etc.). It
//! must not import other Tier 2 modules.

mod script;
mod simulator;
mod step;

pub use script::Script;
pub use simulator::Simulator;
pub use step::{Action, Step};
