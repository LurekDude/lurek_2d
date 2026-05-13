use crate::thread::channel::{Channel, ChannelValue};
use crate::thread::worker::LuaThread;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use std::time::Instant;
pub struct ThreadPool {
    pub size: usize,
    workers: Vec<Arc<Mutex<LuaThread>>>,
    pub input: Arc<Channel>,
    pub output: Arc<Channel>,
    #[allow(dead_code)]
    named_channels: Arc<Mutex<HashMap<String, Arc<Channel>>>>,
}
impl ThreadPool {
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
    pub fn submit(&self, value: ChannelValue) {
        self.input.push(value);
    }
    pub fn collect(&self) -> Option<ChannelValue> {
        self.output.pop()
    }
    pub fn join(&mut self) {
        for worker in &self.workers {
            worker.lock().unwrap().wait();
        }
    }
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
    pub fn size(&self) -> usize {
        self.size
    }
}
