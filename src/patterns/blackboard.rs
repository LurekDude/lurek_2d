use std::collections::HashMap;
use std::fmt;
#[derive(Debug, Clone, PartialEq)]
pub enum BlackboardValue {
    Bool(bool),
    Number(f64),
    Text(String),
    Nil,
}
impl fmt::Display for BlackboardValue {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            BlackboardValue::Bool(b) => write!(f, "{b}"),
            BlackboardValue::Number(n) => write!(f, "{n}"),
            BlackboardValue::Text(s) => write!(f, "{s}"),
            BlackboardValue::Nil => write!(f, "nil"),
        }
    }
}
#[derive(Debug)]
pub struct Blackboard {
    pub name: String,
    pub revision: u64,
    data: HashMap<String, BlackboardValue>,
    key_revisions: HashMap<String, u64>,
}
impl Blackboard {
    pub fn new(name: &str) -> Self {
        Self {
            name: name.to_string(),
            revision: 0,
            data: HashMap::new(),
            key_revisions: HashMap::new(),
        }
    }
    pub fn set_bool(&mut self, key: &str, value: bool) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data
            .insert(key.to_string(), BlackboardValue::Bool(value));
    }
    pub fn set_number(&mut self, key: &str, value: f64) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data
            .insert(key.to_string(), BlackboardValue::Number(value));
    }
    pub fn set_text(&mut self, key: &str, value: String) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data
            .insert(key.to_string(), BlackboardValue::Text(value));
    }
    pub fn clear(&mut self, key: &str) {
        self.revision += 1;
        self.key_revisions.insert(key.to_string(), self.revision);
        self.data.remove(key);
    }
    pub fn get(&self, key: &str) -> Option<&BlackboardValue> {
        self.data.get(key)
    }
    pub fn keys(&self) -> Vec<&str> {
        self.data.keys().map(String::as_str).collect()
    }
    pub fn snapshot(&self) -> Vec<(&str, &BlackboardValue)> {
        self.data.iter().map(|(k, v)| (k.as_str(), v)).collect()
    }
    pub fn has(&self, key: &str) -> bool {
        self.data.contains_key(key)
    }
    pub fn key_revision(&self, key: &str) -> u64 {
        self.key_revisions.get(key).copied().unwrap_or(0)
    }
    pub fn clear_all(&mut self) {
        self.revision += 1;
        self.data.clear();
        self.key_revisions.clear();
    }
    pub fn len(&self) -> usize {
        self.data.len()
    }
    pub fn is_empty(&self) -> bool {
        self.data.is_empty()
    }
}
