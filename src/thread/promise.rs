//! Single-result future for one-shot background computation.
//!
//! A [`Promise`] runs user-provided Lua code in a background thread and
//! exposes the result through a channel. The user code signals completion by
//! pushing a value to `lurek.thread.getChannel("__promise_result")`.
//!
//! # Example Lua worker code
//! ```lua
//! local result = arg[1] * arg[1]          -- compute something from args
//! lurek.thread.getChannel("__promise_result"):push(result)
//! ```

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use crate::thread::channel::{Channel, ChannelValue};
use crate::thread::worker::LuaThread;

/// Execution state of a [`Promise`].
///
/// # Variants
/// - `Pending` — Pending variant.
/// - `Done` — Done variant.
/// - `Error` — Error variant.
#[derive(Debug, Clone, PartialEq)]
pub enum PromiseState {
    /// Computation has not yet completed.
    Pending,
    /// Result is available in the result channel.
    Done,
    /// Computation completed with an error.
    Error(String),
}

/// A one-shot async computation that produces a single `ChannelValue` result.
///
/// The worker thread is started immediately on construction. Call [`Promise::is_done`]
/// to poll for completion, [`Promise::result`] to retrieve the value, and
/// [`Promise::get_error`] to check for errors.
///
/// The user code must push its result to the `__promise_result` named channel:
/// ```lua
/// lurek.thread.getChannel("__promise_result"):push(my_result)
/// ```
///
/// # Fields
/// - `state` — `Arc<Mutex<PromiseState>>`.
/// - `result_channel` — `Arc<Channel>`.
/// - `worker` — `Arc<Mutex<LuaThread>>`.
pub struct Promise {
    /// Cached execution state; updated lazily when `is_done()` is called.
    state: Arc<Mutex<PromiseState>>,
    /// Result arrives on this channel when the worker pushes to `__promise_result`.
    pub result_channel: Arc<Channel>,
    /// The underlying background worker thread.
    worker: Arc<Mutex<LuaThread>>,
}

impl Promise {
    /// Create and immediately start a promise executing `code`.
    ///
    /// `args` are available to the worker via the `arg` global table.
    /// The result channel is registered as `__promise_result` in the worker's
    /// named channel map so it can be accessed via `lurek.thread.getChannel`.
    ///
    /// # Parameters
    /// - `code` — `String`.
    /// - `args` — `Vec<ChannelValue>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(code: String, args: Vec<ChannelValue>) -> Self {
        let named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> =
            Arc::new(Mutex::new(HashMap::new()));
        let result_channel = Channel::new();
        named_channels
            .lock()
            .unwrap()
            .insert("__promise_result".into(), result_channel.clone());

        let mut worker = LuaThread::new(code, named_channels);
        let _ = worker.start(args);

        Self {
            state: Arc::new(Mutex::new(PromiseState::Pending)),
            result_channel,
            worker: Arc::new(Mutex::new(worker)),
        }
    }

    /// Check if the promise has a result ready, without blocking.
    ///
    /// Updates the cached `state` to `Done` or `Error` when a terminal
    /// condition is detected.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_done(&self) -> bool {
        if self.result_channel.get_count() > 0 {
            *self.state.lock().unwrap() = PromiseState::Done;
            return true;
        }
        if let Some(err) = self.worker.lock().unwrap().get_error() {
            *self.state.lock().unwrap() = PromiseState::Error(err);
            return true;
        }
        // Give the spawned worker a chance to run in busy polling loops.
        std::thread::yield_now();
        if self.result_channel.get_count() > 0 {
            *self.state.lock().unwrap() = PromiseState::Done;
            return true;
        }
        if let Some(err) = self.worker.lock().unwrap().get_error() {
            *self.state.lock().unwrap() = PromiseState::Error(err);
            return true;
        }
        false
    }

    /// Retrieve the result value if ready. Does not block.
    ///
    /// Pops one value from the result channel. Returns `None` if the
    /// promise has not yet completed or no value was pushed.
    ///
    /// # Returns
    /// `Option<ChannelValue>`.
    pub fn result(&self) -> Option<ChannelValue> {
        self.result_channel.pop()
    }

    /// Returns the error string if the worker thread failed, otherwise `None`.
    ///
    /// # Returns
    /// `Option<String>`.
    pub fn get_error(&self) -> Option<String> {
        self.worker.lock().unwrap().get_error()
    }
}
