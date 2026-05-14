use crate::log_msg;
use crate::runtime::log_messages::{RL01, RL02, RL03};
use std::collections::HashMap;
#[derive(Debug, Clone)]
/// Declares a named relationship kind and the allowed level labels for it.
pub struct RelationType {
    /// Stable relationship type name used as the lookup key.
    pub name: String,
    /// Ordered list of valid level labels for this relationship type.
    pub levels: Vec<String>,
    /// Fallback level returned when a relation has no explicit value for this type.
    pub default_level: String,
}
impl RelationType {
    /// Creates a relationship type and coerces the default level to a valid entry when possible.
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
    /// Returns whether the supplied level label is valid for this relationship type.
    pub fn has_level(&self, level: &str) -> bool {
        self.levels.iter().any(|l| l == level)
    }
}
#[derive(Debug, Clone)]
/// Stores pairwise relationship data for an unordered entity pair.
pub struct Relationship {
    /// First packed entity id in canonical sorted order.
    pub from_id: u32,
    /// Second packed entity id in canonical sorted order.
    pub to_id: u32,
    /// Numeric affinity or score assigned to this relationship.
    pub value: f64,
    /// Per-type level labels assigned to this relationship.
    pub type_levels: HashMap<String, String>,
}
impl Relationship {
    /// Creates an empty relationship record for the given entity pair.
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
/// Owns relationship types, pairwise relation records, and directed named links.
pub struct RelationshipManager {
    /// Registered relationship type definitions keyed by name.
    types: HashMap<String, RelationType>,
    /// Unordered pairwise relationships keyed by canonical entity ids.
    relations: HashMap<(u32, u32), Relationship>,
    /// Directed link targets keyed by source entity id and link name.
    directed: HashMap<(u32, String), Vec<u32>>,
}
#[inline]
/// Returns an entity pair in deterministic ascending order for map keys.
fn ordered(a: u32, b: u32) -> (u32, u32) {
    if a <= b {
        (a, b)
    } else {
        (b, a)
    }
}
impl RelationshipManager {
    /// Creates an empty relationship manager.
    pub fn new() -> Self {
        Self::default()
    }
    /// Registers or replaces a named relationship type definition.
    pub fn define_type(&mut self, name: &str, levels: Vec<String>, default_level: &str) {
        log_msg!(debug, RL01, "{} ({} levels)", name, levels.len());
        self.types.insert(
            name.to_string(),
            RelationType::new(name, levels, default_level),
        );
    }
    /// Removes a relationship type and clears its assigned levels from all relations.
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
    /// Returns the relationship type definition for the given name.
    pub fn get_type(&self, name: &str) -> Option<&RelationType> {
        self.types.get(name)
    }
    /// Returns the set of registered relationship type names.
    pub fn type_names(&self) -> Vec<String> {
        self.types.keys().cloned().collect()
    }
    /// Returns the relation entry for a pair, creating it on first access.
    fn ensure(&mut self, a: u32, b: u32) -> &mut Relationship {
        let key = ordered(a, b);
        self.relations.entry(key).or_insert_with(|| {
            log_msg!(trace, RL03, "({}, {})", a, b);
            Relationship::new(a, b)
        })
    }
    /// Returns the numeric relationship value for a pair, defaulting to zero.
    pub fn get_value(&self, a: u32, b: u32) -> f64 {
        self.relations
            .get(&ordered(a, b))
            .map(|r| r.value)
            .unwrap_or(0.0)
    }
    /// Sets the numeric relationship value for a pair.
    pub fn set_value(&mut self, a: u32, b: u32, value: f64) {
        self.ensure(a, b).value = value;
    }
    /// Adds a delta to the numeric relationship value for a pair.
    pub fn adjust_value(&mut self, a: u32, b: u32, delta: f64) {
        let rel = self.ensure(a, b);
        rel.value += delta;
    }
    /// Assigns a per-type level label to a relation when the type and level are valid.
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
    /// Returns the explicit or default level label for a relation type on a pair.
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
    /// Returns whether any relation record exists for the pair.
    pub fn has_relation(&self, a: u32, b: u32) -> bool {
        self.relations.contains_key(&ordered(a, b))
    }
    /// Deletes the stored relation record for the pair.
    pub fn remove_relation(&mut self, a: u32, b: u32) -> bool {
        self.relations.remove(&ordered(a, b)).is_some()
    }
    /// Returns all relationship records that involve the given entity id.
    pub fn all_relations_for(&self, entity_id: u32) -> Vec<&Relationship> {
        self.relations
            .values()
            .filter(|r| r.from_id == entity_id || r.to_id == entity_id)
            .collect()
    }
    /// Iterates over every stored pairwise relationship.
    pub fn all_relations(&self) -> impl Iterator<Item = &Relationship> {
        self.relations.values()
    }
    /// Returns the total number of stored pairwise relationships.
    pub fn relation_count(&self) -> usize {
        self.relations.len()
    }
    /// Adds a directed named link from one entity to another without duplicates.
    pub fn add_link(&mut self, from: u32, name: &str, to: u32) {
        let targets = self.directed.entry((from, name.to_string())).or_default();
        if !targets.contains(&to) {
            targets.push(to);
        }
    }
    /// Returns the directed link targets for a source entity and link name.
    pub fn get_links(&self, from: u32, name: &str) -> &[u32] {
        self.directed
            .get(&(from, name.to_string()))
            .map(|v| v.as_slice())
            .unwrap_or(&[])
    }
    /// Removes one directed link target from a source entity and link name.
    pub fn remove_link(&mut self, from: u32, name: &str, to: u32) {
        if let Some(targets) = self.directed.get_mut(&(from, name.to_string())) {
            targets.retain(|&id| id != to);
        }
    }
    /// Removes all directed link targets for a source entity and link name.
    pub fn clear_links(&mut self, from: u32, name: &str) {
        self.directed.remove(&(from, name.to_string()));
    }
    /// Returns whether a directed link target exists for the source entity and link name.
    pub fn has_link(&self, from: u32, name: &str, to: u32) -> bool {
        self.directed
            .get(&(from, name.to_string()))
            .map(|v| v.contains(&to))
            .unwrap_or(false)
    }
}
