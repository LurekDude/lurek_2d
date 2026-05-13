use crate::thread::channel::{Channel, ChannelValue};
use crate::thread::worker::LuaThread;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
#[derive(Debug, Clone, PartialEq)]
pub enum PromiseState {
    Pending,
    Done,
    Error(String),
}
pub struct Promise {
    state: Arc<Mutex<PromiseState>>,
    pub result_channel: Arc<Channel>,
    worker: Arc<Mutex<LuaThread>>,
}
impl Promise {
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
    pub fn result(&self) -> Option<ChannelValue> {
        self.result_channel.pop()
    }
    pub fn get_error(&self) -> Option<String> {
        self.worker.lock().unwrap().get_error()
    }
}
