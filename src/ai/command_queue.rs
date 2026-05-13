//! Scope: ordered command queue for AI action sequencing and interruption.
//! This file defines command records and queue operations for enqueue, front-insert interrupt, pop, and cancellation.
//! It owns deterministic command ordering semantics used by high-level planners and low-level action execution.
use std::collections::VecDeque;

use crate::log_msg;
use crate::runtime::log_messages::{CQ01, CQ02, CQ03};

use mlua::RegistryKey;

/// A single RTS unit command with metadata and a Lua tick callback.
pub struct Command {
    /// Command type identifier (e.g., `"move"`, `"attack"`, `"patrol"`, `"build"`).
    pub kind: String,
    /// Lua callback ticked each frame: `fn(dt) -> bool`.
    pub callback: RegistryKey,
    /// Target world-space X coordinate. Semantic meaning depends on `kind`
    pub target_x: f32,
    /// Target world-space Y coordinate.
    pub target_y: f32,
    /// Priority hint for external sorting or display ordering.
    pub priority: i32,
    /// Whether `cancel_current()` can remove this command. Non-interruptible
    pub interruptible: bool,
}

/// A FIFO queue of [`Command`] entries for sequential unit action scheduling.
pub struct CommandQueue {
    /// The underlying double-ended queue of commands.
    pub(crate) commands: VecDeque<Command>,
}

impl CommandQueue {
    /// Creates a new empty command queue.
    pub fn new() -> Self {
        log_msg!(debug, CQ01);
        Self {
            commands: VecDeque::new(),
        }
    }

    /// Appends a command to the back of the queue.
    pub fn enqueue(&mut self, cmd: Command) {
        log_msg!(debug, CQ02);
        self.commands.push_back(cmd);
    }

    /// Inserts a command at the front (interrupts current without clearing).
    pub fn push_front(&mut self, cmd: Command) {
        self.commands.push_front(cmd);
    }

    /// Clears the queue and enqueues one new command.
    pub fn replace(&mut self, cmd: Command) {
        self.commands.clear();
        self.commands.push_back(cmd);
    }

    /// Cancels the current (front) command if i's interruptible.
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
        let count = self.commands.len();
        self.commands.clear();
        log_msg!(debug, CQ03, "{}", count);
    }

    /// Returns the number of queued commands.
    pub fn count(&self) -> usize {
        self.commands.len()
    }

    /// Returns whether the queue is empty.
    pub fn is_empty(&self) -> bool {
        self.commands.is_empty()
    }

    /// Returns the type of the front command, if any.
    pub fn current_type(&self) -> Option<&str> {
        self.commands.front().map(|c| c.kind.as_str())
    }

    /// Returns the target coordinates of the front command.
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

    /// Appends a new command built from raw parameters. Used by the Lua API.
    pub fn enqueue_raw(
        &mut self,
        kind: String,
        tx: f32,
        ty: f32,
        priority: i32,
        interruptible: bool,
        callback: RegistryKey,
    ) {
        self.enqueue(Command {
            kind,
            target_x: tx,
            target_y: ty,
            priority,
            interruptible,
            callback,
        });
    }

    /// Inserts at the front from raw parameters. Used by the Lua API.
    pub fn push_front_raw(
        &mut self,
        kind: String,
        tx: f32,
        ty: f32,
        priority: i32,
        interruptible: bool,
        callback: RegistryKey,
    ) {
        self.push_front(Command {
            kind,
            target_x: tx,
            target_y: ty,
            priority,
            interruptible,
            callback,
        });
    }

    /// Clears the queue and replaces with a single command from raw parameters. Used by the Lua API.
    pub fn replace_raw(
        &mut self,
        kind: String,
        tx: f32,
        ty: f32,
        priority: i32,
        interruptible: bool,
        callback: RegistryKey,
    ) {
        self.replace(Command {
            kind,
            target_x: tx,
            target_y: ty,
            priority,
            interruptible,
            callback,
        });
    }
}

impl Default for CommandQueue {
    fn default() -> Self {
        Self::new()
    }
}
