//! Ordered command queue for AI agents: enqueue, prioritise, and advance actions.
//! Owns `Command` (a single ordered action) and `CommandQueue` (the FIFO container).
//! Does not own execution logic; step/tick lives in `lua_api/ai_api.rs`.
//! Depends on `mlua::RegistryKey` for completion callbacks and log codes for tracing.
use crate::log_msg;
use crate::runtime::log_messages::{CQ01, CQ02, CQ03};
use mlua::RegistryKey;
use std::collections::VecDeque;
pub struct Command {
    /// String tag identifying the action type, e.g. `"move"` or `"attack"`.
    pub kind: String,
    /// Registry key of the Lua callback invoked when this command completes.
    pub callback: RegistryKey,
    /// World-space X target coordinate in pixels.
    pub target_x: f32,
    /// World-space Y target coordinate in pixels.
    pub target_y: f32,
    /// Scheduling priority; higher values are processed before lower ones.
    pub priority: i32,
    /// Whether this command can be cancelled by `cancel_current`.
    pub interruptible: bool,
}
pub struct CommandQueue {
    /// FIFO storage of pending commands.
    pub(crate) commands: VecDeque<Command>,
}
impl CommandQueue {
    /// Create an empty queue.
    pub fn new() -> Self {
        log_msg!(debug, CQ01);
        Self {
            commands: VecDeque::new(),
        }
    }
    /// Append `cmd` to the back of the queue.
    pub fn enqueue(&mut self, cmd: Command) {
        log_msg!(debug, CQ02);
        self.commands.push_back(cmd);
    }
    /// Insert `cmd` at the front, making it the next command to execute.
    pub fn push_front(&mut self, cmd: Command) {
        self.commands.push_front(cmd);
    }
    /// Clear the entire queue and enqueue `cmd` as the sole pending command.
    pub fn replace(&mut self, cmd: Command) {
        self.commands.clear();
        self.commands.push_back(cmd);
    }
    /// Pop the front command if it is interruptible; return `true` on success.
    pub fn cancel_current(&mut self) -> bool {
        if let Some(front) = self.commands.front() {
            if front.interruptible {
                self.commands.pop_front();
                return true;
            }
        }
        false
    }
    /// Discard all queued commands.
    pub fn clear(&mut self) {
        let count = self.commands.len();
        self.commands.clear();
        log_msg!(debug, CQ03, "{}", count);
    }
    /// Return the number of pending commands.
    pub fn count(&self) -> usize {
        self.commands.len()
    }
    /// Return `true` when the queue has no pending commands.
    pub fn is_empty(&self) -> bool {
        self.commands.is_empty()
    }
    /// Return the `kind` tag of the front command, or `None` if the queue is empty.
    pub fn current_type(&self) -> Option<&str> {
        self.commands.front().map(|c| c.kind.as_str())
    }
    /// Return the `(target_x, target_y)` of the front command; returns `(0, 0)` if empty.
    pub fn current_target(&self) -> (f32, f32) {
        self.commands
            .front()
            .map(|c| (c.target_x, c.target_y))
            .unwrap_or((0.0, 0.0))
    }
    /// Remove the front command as completed and expose the next one.
    pub fn advance(&mut self) {
        self.commands.pop_front();
    }
    /// Build a `Command` from raw parts and append it to the back of the queue.
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
    /// Build a `Command` from raw parts and insert it at the front of the queue.
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
    /// Build a `Command` from raw parts, clear the queue, and set it as the only entry.
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
/// `Default` delegates to `CommandQueue::new`.
impl Default for CommandQueue {
    /// `Default` delegates to `CommandQueue::new`.
    fn default() -> Self {
        Self::new()
    }
}
