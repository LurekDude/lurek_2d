use std::collections::HashMap;
#[derive(Debug, Default, Clone)]
pub struct Mediator {
    channels: HashMap<String, Vec<u64>>,
    next_id: u64,
}
impl Mediator {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn register(&mut self, channel: &str) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        self.channels
            .entry(channel.to_string())
            .or_default()
            .push(id);
        id
    }
    pub fn unregister(&mut self, channel: &str, id: u64) -> bool {
        if let Some(handlers) = self.channels.get_mut(channel) {
            let before = handlers.len();
            handlers.retain(|&h| h != id);
            return handlers.len() < before;
        }
        false
    }
    pub fn get_handlers(&self, channel: &str) -> Vec<u64> {
        self.channels.get(channel).cloned().unwrap_or_default()
    }
    pub fn handler_count(&self, channel: &str) -> usize {
        self.channels.get(channel).map(|v| v.len()).unwrap_or(0)
    }
    pub fn channel_names(&self) -> Vec<String> {
        self.channels.keys().cloned().collect()
    }
    pub fn remove_channel(&mut self, channel: &str) {
        self.channels.remove(channel);
    }
    pub fn clear(&mut self) {
        self.channels.clear();
        self.next_id = 0;
    }
}
