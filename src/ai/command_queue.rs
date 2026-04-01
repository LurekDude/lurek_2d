//! RTS-style ordered command queue for a single unit.

use std::collections::VecDeque;

use mlua::RegistryKey;

/// A single RTS unit command with metadata.
///
/// # Fields
/// - `kind` — `String`.
/// - `callback` — `RegistryKey`.
/// - `target_x` — `f32`.
/// - `target_y` — `f32`.
/// - `priority` — `i32`.
/// - `interruptible` — `bool`.
pub struct Command {
    /// Command type identifier (e.g., "move", "attack", "patrol").
    pub kind: String,
    /// Lua callback ticked each frame: `fn(dt) → bool` (true = still running, false = done).
    pub callback: RegistryKey,
    /// Target world-space X coordinate.
    pub target_x: f32,
    /// Target world-space Y coordinate.
    pub target_y: f32,
    /// Priority hint for external sorting (not used internally).
    pub priority: i32,
    /// Whether this command can be interrupted by `cancelCurrent()`.
    pub interruptible: bool,
}

/// RTS-style ordered command queue.
///
/// # Fields
/// - `commands` — `VecDeque<Command>`.
///
/// Commands are dequeued from the front. Three insertion modes:
/// `enqueue` (append), `push_front` (interrupt), `replace` (clear + enqueue).
pub struct CommandQueue {
    /// The command queue.
    pub(crate) commands: VecDeque<Command>,
}

impl CommandQueue {
    /// Creates a new empty command queue.
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

    /// Clears all commands.
    pub fn clear(&mut self) {
        self.commands.clear();
    }

    /// Returns the number of queued commands.
    ///
    /// # Returns
    /// `usize`.
    pub fn count(&self) -> usize {
        self.commands.len()
    }

    /// Returns whether the queue is empty.
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
