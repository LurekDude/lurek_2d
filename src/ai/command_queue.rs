//! RTS-style ordered command queue for scheduling unit actions.
//!
//! A [`CommandQueue`] manages a FIFO sequence of [`Command`] entries for a single
//! unit or agent. Commands are dequeued from the front and ticked each frame via
//! their Lua callback. Three insertion modes are supported:
//!
//! - **`enqueue`** — appends a command to the back (standard queue behavior).
//! - **`push_front`** — inserts at the front, interrupting the current command
//!   without clearing the rest of the queue.
//! - **`replace`** — clears the entire queue and enqueues one new command.
//!
//! Commands carry metadata: a `kind` string (e.g., `"move"`, `"attack"`, `"patrol"`),
//! target coordinates, a priority hint, and an `interruptible` flag that controls
//! whether `cancel_current()` can remove it.
//!
//! ## Lua Callback Contract
//!
//! Each command's `callback` is a Lua function `fn(dt) → bool`:
//! - Returns `true` if the command is still running (tick again next frame).
//! - Returns `false` if the command is done (advance to next in queue).
//!
//! The AIWorld or Lua game loop is responsible for ticking the front command
//! each frame and calling `advance()` when the callback returns `false`.

use std::collections::VecDeque;

use mlua::RegistryKey;

/// A single RTS unit command with metadata and a Lua tick callback.
///
/// Commands are stored in a [`CommandQueue`] and processed one at a time,
/// front-to-back. Each frame the front command's callback is ticked with
/// the frame's delta time. When the callback signals completion, the command
/// is removed and the next one becomes active.
///
/// # Fields
/// - `kind` — `String`.
/// - `callback` — `RegistryKey`.
/// - `target_x` — `f32`.
/// - `target_y` — `f32`.
/// - `priority` — `i32`.
/// - `interruptible` — `bool`.
pub struct Command {
    /// Command type identifier (e.g., `"move"`, `"attack"`, `"patrol"`, `"build"`).
    /// Used by external code for filtering and UI display — not interpreted internally.
    pub kind: String,
    /// Lua callback ticked each frame: `fn(dt) → bool`.
    /// Returns `true` while the command is still running, `false` when done.
    pub callback: RegistryKey,
    /// Target world-space X coordinate. Semantic meaning depends on `kind`
    /// (e.g., move destination, attack target position).
    pub target_x: f32,
    /// Target world-space Y coordinate.
    pub target_y: f32,
    /// Priority hint for external sorting or display ordering.
    /// Not used internally by `CommandQueue` — provided for game logic convenience.
    pub priority: i32,
    /// Whether `cancel_current()` can remove this command. Non-interruptible
    /// commands (e.g., death animations) cannot be cancelled by the player.
    pub interruptible: bool,
}

/// A FIFO queue of [`Command`] entries for sequential unit action scheduling.
///
/// Commands are consumed from the front. The game loop ticks the front command
/// each frame and calls `advance()` to move to the next when it completes.
/// Three insertion patterns are supported:
///
/// - `enqueue()` — adds to the back (normal queue append).
/// - `push_front()` — inserts at front, pre-empting the current command.
/// - `replace()` — clears everything and enqueues a single new command.
///
/// `cancel_current()` removes the front command only if its `interruptible`
/// flag is set, providing a way for players to cancel commands while protecting
/// non-interruptible actions (like scripted animations).
///
/// # Fields
/// - `commands` — `VecDeque<Command>`.
pub struct CommandQueue {
    /// The underlying double-ended queue of commands.
    pub(crate) commands: VecDeque<Command>,
}

impl CommandQueue {
    /// Creates a new empty command queue. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            commands: VecDeque::new(),
        }
    }

    /// Appends a command to the back of the queue.
    ///
    /// # Parameters
    /// - `cmd` — `Command`.
    pub fn enqueue(&mut self, cmd: Command) {
        self.commands.push_back(cmd);
    }

    /// Inserts a command at the front (interrupts current without clearing).
    ///
    /// # Parameters
    /// - `cmd` — `Command`.
    pub fn push_front(&mut self, cmd: Command) {
        self.commands.push_front(cmd);
    }

    /// Clears the queue and enqueues one new command.
    ///
    /// # Parameters
    /// - `cmd` — `Command`.
    pub fn replace(&mut self, cmd: Command) {
        self.commands.clear();
        self.commands.push_back(cmd);
    }

    /// Cancels the current (front) command if it's interruptible.
    ///
    /// # Returns
    /// `bool`.
    pub fn cancel_current(&mut self) -> bool {
        if let Some(front) = self.commands.front() {
            if front.interruptible {
                self.commands.pop_front();
                return true;
            }
        }
        false
    }

    /// Clears all commands. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.commands.clear();
    }

    /// Returns the number of queued commands. Runs in O(1) time.
    ///
    /// # Returns
    /// `usize`.
    pub fn count(&self) -> usize {
        self.commands.len()
    }

    /// Returns whether the queue is empty. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.commands.is_empty()
    }

    /// Returns the type of the front command, if any.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn current_type(&self) -> Option<&str> {
        self.commands.front().map(|c| c.kind.as_str())
    }

    /// Returns the target coordinates of the front command.
    ///
    /// # Returns
    /// `(f32, f32)`.
    pub fn current_target(&self) -> (f32, f32) {
        self.commands
            .front()
            .map(|c| (c.target_x, c.target_y))
            .unwrap_or((0.0, 0.0))
    }

    /// Advances the queue by removing the front command.
    pub fn advance(&mut self) {
        self.commands.pop_front();
    }
}

impl Default for CommandQueue {
    fn default() -> Self {
        Self::new()
    }
}
