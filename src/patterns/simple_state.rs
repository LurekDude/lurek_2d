use std::collections::HashSet;
pub struct SimpleState {
    states: HashSet<String>,
    current: Option<String>,
}
impl SimpleState {
    pub fn new() -> Self {
        Self {
            states: HashSet::new(),
            current: None,
        }
    }
    pub fn add(&mut self, name: &str) -> bool {
        self.states.insert(name.to_string())
    }
    pub fn remove(&mut self, name: &str) -> bool {
        let removed = self.states.remove(name);
        if self.current.as_deref() == Some(name) {
            self.current = None;
        }
        removed
    }
    pub fn has(&self, name: &str) -> bool {
        self.states.contains(name)
    }
    pub fn current(&self) -> Option<&str> {
        self.current.as_deref()
    }
    pub fn set_current(&mut self, name: &str) -> bool {
        if !self.states.contains(name) {
            return false;
        }
        self.current = Some(name.to_string());
        true
    }
    pub fn clear_current(&mut self) {
        self.current = None;
    }
    pub fn states(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.states.iter().map(String::as_str).collect();
        names.sort_unstable();
        names
    }
    pub fn state_count(&self) -> usize {
        self.states.len()
    }
}
impl Default for SimpleState {
    fn default() -> Self {
        Self::new()
    }
}
