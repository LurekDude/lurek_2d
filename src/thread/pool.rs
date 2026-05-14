//! Fixed-size Lua worker thread pool. Owns `ThreadPool` which manages a set of
//! `LuaThread` workers sharing input and output `Channel`s. Does not own
//! individual thread lifecycle beyond start/wait; that lives in `worker`.
//! Depends on `channel` and `worker`.

use crate::thread::channel::{Channel, ChannelValue};
use crate::thread::worker::LuaThread;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::Instant;

/// A pool of `LuaThread` workers that share a single input and output `Channel`.
pub struct ThreadPool {
    /// Number of worker threads in the pool.
    pub size: usize,
    /// Worker thread handles used for join operations.
    workers: Vec<Arc<Mutex<LuaThread>>>,
    /// Shared input channel; callers push work items here.
    pub input: Arc<Channel>,
    /// Shared output channel; workers push results here.
    pub output: Arc<Channel>,
    /// Named channel registry shared with workers; used for `__pool_input`/`__pool_output` lookup.
    #[allow(dead_code)]
    named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>>,
}
impl ThreadPool {
    /// Create a pool of `size` workers, each executing `code`, wired to shared input/output channels.
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
    /// Push `value` onto the input channel for the next available worker.
    pub fn submit(&self, value: ChannelValue) {
        self.input.push(value);
    }

    /// Non-blocking pop from the output channel; return `None` when no result is ready.
    pub fn collect(&self) -> Option<ChannelValue> {
        self.output.pop()
    }

    /// Block until all workers finish their current work items.
    pub fn join(&mut self) {
        for worker in &self.workers {
            worker.lock().unwrap().wait();
        }
    }

    /// Block until all workers finish or `timeout_secs` elapses; return `false` if any worker did not finish in time.
    pub fn join_with_timeout(&mut self, timeout_secs: f64) -> bool {
        let timeout_secs = timeout_secs.max(0.0);
        let deadline = Instant::now() + std::time::Duration::from_secs_f64(timeout_secs);
        for worker in &self.workers {
            let now = Instant::now();
            if now >= deadline {
                return false;
            }
            let remaining = deadline.saturating_duration_since(now).as_secs_f64();
            if !worker.lock().unwrap().wait_timeout(remaining) {
                return false;
            }
        }
        true
    }
    /// Return the pool size (number of worker threads).
    pub fn size(&self) -> usize {
        self.size
    }
}
