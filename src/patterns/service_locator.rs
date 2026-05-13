use std::collections::HashSet;
#[derive(Debug, Default)]
pub struct ServiceLocator {
    pub services: HashSet<String>,
}
impl ServiceLocator {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn register(&mut self, name: &str) {
        self.services.insert(name.to_string());
    }
    pub fn unregister(&mut self, name: &str) -> bool {
        self.services.remove(name)
    }
    pub fn has(&self, name: &str) -> bool {
        self.services.contains(name)
    }
    pub fn names(&self) -> Vec<&str> {
        let mut names: Vec<&str> = self.services.iter().map(String::as_str).collect();
        names.sort();
        names
    }
    pub fn clear(&mut self) {
        self.services.clear();
    }
}
