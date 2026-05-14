//! Single-value async result container backed by a one-shot `LuaThread`. Owns
//! `PromiseState` and `Promise`. Does not own scheduling or channel routing;
//! the worker pushes its result to `__promise_result` and Promise polls it.
//! Depends on `channel` and `worker`.

use crate::thread::channel::{Channel, ChannelValue};
use crate::thread::worker::LuaThread;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

/// Lifecycle state of a `Promise`.
#[derive(Debug, Clone, PartialEq)]
pub enum PromiseState {
    /// The worker has not yet pushed a result.
    Pending,
    /// A result value is available in `result_channel`.
    Done,
    /// The worker terminated with an error message.
    Error(String),
}

/// One-shot async computation: spawns a `LuaThread`, exposes the result via a channel.
pub struct Promise {
    /// Last observed lifecycle state, updated by `is_done`.
    state: Arc<Mutex<PromiseState>>,
    /// Channel through which the worker publishes its result; always named `__promise_result`.
    pub result_channel: Arc<Channel>,
    /// The underlying worker thread.
    worker: Arc<Mutex<LuaThread>>,
}
impl Promise {
    /// Spawn a `LuaThread` running `code` with `args` and return a pending `Promise`.
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
    /// Poll whether the worker has finished; update `state` to `Done` or `Error` and return `true` when complete.
    pub fn is_done(&self) -> bool {
        if self.result_channel.get_count() > 0 {
            *self.state.lock().unwrap() = PromiseState::Done;
            return true;
        }
        if let Some(err) = self.worker.lock().unwrap().get_error() {
            *self.state.lock().unwrap() = PromiseState::Error(err);
            return true;
        }
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
    /// Pop and return the result value; returns `None` when not yet done.
    pub fn result(&self) -> Option<ChannelValue> {
        self.result_channel.pop()
    }

    /// Return the worker's error message if it terminated with an error, or `None`.
    pub fn get_error(&self) -> Option<String> {
        self.worker.lock().unwrap().get_error()
    }
}
