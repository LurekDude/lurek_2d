//! Thread pool of reusable worker Lua VMs.
//!
//! A [`ThreadPool`] manages N persistent worker threads that share a common
//! input/output channel pair. Submit tasks via [`ThreadPool::submit`] and
//! collect results via [`ThreadPool::collect`].
//!
//! Workers access tasks via `lurek.thread.getChannel("__pool_input")` and
//! deliver results via `lurek.thread.getChannel("__pool_output")`.

use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use crate::thread::channel::{Channel, ChannelValue};
use crate::thread::worker::LuaThread;

/// A pool of N persistent worker threads that accept tasks from a shared
/// input channel and send results to a shared output channel.
///
/// Workers execute identical user-provided Lua code. They are expected to
/// consume values from `lurek.thread.getChannel("__pool_input")` and push
/// results to `lurek.thread.getChannel("__pool_output")`.
///
/// # Fields
/// - `size` — `usize`.
/// - `workers` — `Vec<Arc<Mutex<LuaThread>>>`.
/// - `input` — `Arc<Channel>`.
/// - `output` — `Arc<Channel>`.
/// - `named_channels` — `Arc<Mutex<HashMap<String, Arc<Channel>>>>`.
pub struct ThreadPool {
    /// Number of worker threads in this pool.
    pub size: usize,
    /// Worker thread handles.
    workers: Vec<Arc<Mutex<LuaThread>>>,
    /// Shared task input channel (main → workers).
    pub input: Arc<Channel>,
    /// Shared result output channel (workers → main).
    pub output: Arc<Channel>,
    /// Named channels accessible to every worker in this pool.
    named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>>,
}

impl ThreadPool {
    /// Create a pool of `size` workers, all executing `code`.
    ///
    /// Workers share `__pool_input` and `__pool_output` named channels.
    /// Each worker VM starts immediately after construction.
    ///
    /// # Parameters
    /// - `size` — `usize`.
    /// - `code` — `String`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(size: usize, code: String) -> Self {
        let named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>> =
            Arc::new(Mutex::new(HashMap::new()));
        let input = Channel::new();
        let output = Channel::new();

        named_channels
            .lock()
            .unwrap()
            .insert("__pool_input".into(), input.clone());
        named_channels
            .lock()
            .unwrap()
            .insert("__pool_output".into(), output.clone());

        let mut workers = Vec::with_capacity(size);
        for _ in 0..size {
            let mut worker = LuaThread::new(code.clone(), named_channels.clone());
            let _ = worker.start(vec![]);
            workers.push(Arc::new(Mutex::new(worker)));
        }

        Self {
            size,
            workers,
            input,
            output,
            named_channels,
        }
    }

    /// Submit a value to the pool input channel.
    ///
    /// Workers receive this value via `lurek.thread.getChannel("__pool_input"):demand()`.
    ///
    /// # Parameters
    /// - `value` — `ChannelValue`.
    pub fn submit(&self, value: ChannelValue) {
        self.input.push(value);
    }

    /// Collect a result from the pool output channel (non-blocking).
    ///
    /// Returns `None` if no result is available yet.
    ///
    /// # Returns
    /// `Option<ChannelValue>`.
    pub fn collect(&self) -> Option<ChannelValue> {
        self.output.pop()
    }

    /// Block until all workers have finished execution.
    pub fn join(&mut self) {
        for worker in &self.workers {
            worker.lock().unwrap().wait();
        }
    }

    /// Returns the number of workers in this pool.
    ///
    /// # Returns
    /// `usize`.
    pub fn size(&self) -> usize {
        self.size
    }
}
