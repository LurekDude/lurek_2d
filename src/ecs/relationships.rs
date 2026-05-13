use crate::log_msg;
use crate::runtime::log_messages::{RL01, RL02, RL03};
use std::collections::HashMap;
#[derive(Debug, Clone)]
pub struct RelationType {
    pub name: String,
    pub levels: Vec<String>,
    pub default_level: String,
}
impl RelationType {
    pub fn new(name: &str, levels: Vec<String>, default_level: &str) -> Self {
        let effective_default = if levels.iter().any(|l| l == default_level) {
            default_level.to_string()
        } else if let Some(first) = levels.first() {
            first.clone()
        } else {
            default_level.to_string()
        };
        Self {
            name: name.to_string(),
            levels,
            default_level: effective_default,
        }
    }
    pub fn has_level(&self, level: &str) -> bool {
        self.levels.iter().any(|l| l == level)
    }
}
#[derive(Debug, Clone)]
pub struct Relationship {
    pub from_id: u32,
    pub to_id: u32,
    pub value: f64,
    pub type_levels: HashMap<String, String>,
}
impl Relationship {
    fn new(a: u32, b: u32) -> Self {
        let (from_id, to_id) = ordered(a, b);
        Self {
            from_id,
            to_id,
            value: 0.0,
            type_levels: HashMap::new(),
        }
    }
}
#[derive(Debug, Default)]
pub struct RelationshipManager {
    types: HashMap<String, RelationType>,
    relations: HashMap<(u32, u32), Relationship>,
    directed: HashMap<(u32, String), Vec<u32>>,
}
#[inline]
fn ordered(a: u32, b: u32) -> (u32, u32) {
    if a <= b {
        (a, b)
    } else {
        (b, a)
    }
}
impl RelationshipManager {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn define_type(&mut self, name: &str, levels: Vec<String>, default_level: &str) {
        log_msg!(debug, RL01, "{} ({} levels)", name, levels.len());
        self.types.insert(
            name.to_string(),
            RelationType::new(name, levels, default_level),
        );
    }
    pub fn remove_type(&mut self, name: &str) -> bool {
        if self.types.remove(name).is_some() {
            for rel in self.relations.values_mut() {
                rel.type_levels.remove(name);
            }
            log_msg!(debug, RL02, "{}", name);
            true
        } else {
            false
        }
    }
    pub fn get_type(&self, name: &str) -> Option<&RelationType> {
        self.types.get(name)
    }
    pub fn type_names(&self) -> Vec<String> {
        self.types.keys().cloned().collect()
    }
    fn ensure(&mut self, a: u32, b: u32) -> &mut Relationship {
        let key = ordered(a, b);
        self.relations.entry(key).or_insert_with(|| {
            log_msg!(trace, RL03, "({}, {})", a, b);
            Relationship::new(a, b)
        })
    }
    pub fn get_value(&self, a: u32, b: u32) -> f64 {
        self.relations
            .get(&ordered(a, b))
            .map(|r| r.value)
            .unwrap_or(0.0)
    }
    pub fn set_value(&mut self, a: u32, b: u32, value: f64) {
        self.ensure(a, b).value = value;
    }
    pub fn adjust_value(&mut self, a: u32, b: u32, delta: f64) {
        let rel = self.ensure(a, b);
        rel.value += delta;
    }
    pub fn set_level(&mut self, a: u32, b: u32, type_name: &str, level: &str) -> bool {
        match self.types.get(type_name) {
            None => false,
            Some(t) if !t.has_level(level) => false,
            Some(_) => {
                self.ensure(a, b)
                    .type_levels
                    .insert(type_name.to_string(), level.to_string());
                true
            }
        }
    }
    pub fn get_level(&self, a: u32, b: u32, type_name: &str) -> Option<String> {
        let def = self.types.get(type_name)?.default_level.clone();
        let level = self
            .relations
            .get(&ordered(a, b))
            .and_then(|r| r.type_levels.get(type_name))
            .cloned()
            .unwrap_or(def);
        Some(level)
    }
    pub fn has_relation(&self, a: u32, b: u32) -> bool {
        self.relations.contains_key(&ordered(a, b))
    }
    pub fn remove_relation(&mut self, a: u32, b: u32) -> bool {
        self.relations.remove(&ordered(a, b)).is_some()
    }
    pub fn all_relations_for(&self, entity_id: u32) -> Vec<&Relationship> {
        self.relations
            .values()
            .filter(|r| r.from_id == entity_id || r.to_id == entity_id)
            .collect()
    }
    pub fn all_relations(&self) -> impl Iterator<Item = &Relationship> {
        self.relations.values()
    }
    pub fn relation_count(&self) -> usize {
        self.relations.len()
    }
    pub fn add_link(&mut self, from: u32, name: &str, to: u32) {
        let targets = self.directed.entry((from, name.to_string())).or_default();
        if !targets.contains(&to) {
            targets.push(to);
        }
    }
    pub fn get_links(&self, from: u32, name: &str) -> &[u32] {
        self.directed
            .get(&(from, name.to_string()))
            .map(|v| v.as_slice())
            .unwrap_or(&[])
    }
    pub fn remove_link(&mut self, from: u32, name: &str, to: u32) {
        if let Some(targets) = self.directed.get_mut(&(from, name.to_string())) {
            targets.retain(|&id| id != to);
        }
    }
    pub fn clear_links(&mut self, from: u32, name: &str) {
        self.directed.remove(&(from, name.to_string()));
    }
    pub fn has_link(&self, from: u32, name: &str, to: u32) -> bool {
        self.directed
            .get(&(from, name.to_string()))
            .map(|v| v.contains(&to))
            .unwrap_or(false)
    }
}
