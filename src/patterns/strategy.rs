use std::collections::HashMap;
#[derive(Debug, Default, Clone)]
pub struct Strategy {
    strategies: HashMap<String, u64>,
    current: Option<String>,
    next_id: u64,
}
impl Strategy {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn register(&mut self, name: &str) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        self.strategies.insert(name.to_string(), id);
        id
    }
    pub fn set_current(&mut self, name: &str) -> bool {
        if self.strategies.contains_key(name) {
            self.current = Some(name.to_string());
            true
        } else {
            false
        }
    }
    pub fn get_current(&self) -> Option<&str> {
        self.current.as_deref()
    }
    pub fn get_current_id(&self) -> Option<u64> {
        self.current
            .as_ref()
            .and_then(|n| self.strategies.get(n))
            .copied()
    }
    pub fn has(&self, name: &str) -> bool {
        self.strategies.contains_key(name)
    }
    pub fn remove(&mut self, name: &str) -> bool {
        if self.strategies.remove(name).is_some() {
            if self.current.as_deref() == Some(name) {
                self.current = None;
            }
            true
        } else {
            false
        }
    }
    pub fn names(&self) -> Vec<String> {
        self.strategies.keys().cloned().collect()
    }
    pub fn clear(&mut self) {
        self.strategies.clear();
        self.current = None;
        self.next_id = 0;
    }
}
