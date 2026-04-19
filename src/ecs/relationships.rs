//! Generic relationship system for entities.
//!
//! Stores symmetric numeric relations and named-state levels between entity pairs.
//! Entity IDs are `u32` to match [`Universe`](super::Universe).
//!
//! This module is part of Lurek2D's `entity` subsystem and provides the implementation
//! details for relationships-related operations and data management.
//! Key types exported from this module: `RelationType`, `Relationship`, `RelationshipManager`.
//! Primary functions: `new()`, `has_level()`, `new()`, `define_type()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::HashMap;

use crate::runtime::log_messages::{RL01, RL02, RL03};
use crate::log_msg;

/// Definition of a named relation type with a fixed set of valid level strings.
///
/// # Example
/// ```text
/// define_type("diplomacy", &["war","neutral","alliance"], "neutral")
/// ```
///
/// # Fields
/// - `name` â€” `String`.
/// - `levels` â€” `Vec<String>`.
/// - `default_level` â€” `String`.
#[derive(Debug, Clone)]
pub struct RelationType {
    /// Name of this relation type (e.g. `"diplomacy"`, `"trade"`).
    pub name: String,
    /// Valid level strings for this type.
    pub levels: Vec<String>,
    /// The default level applied when no explicit level has been set.
    pub default_level: String,
}

impl RelationType {
    /// Create a new relation type. Panics in debug if `default_level` is not in `levels`.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
    /// - `levels` â€” `Vec<String>`.
    /// - `default_level` â€” `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: &str, levels: Vec<String>, default_level: &str) -> Self {
        debug_assert!(
            levels.iter().any(|l| l == default_level),
            "default_level '{default_level}' must be one of the declared levels"
        );
        Self {
            name: name.to_string(),
            levels,
            default_level: default_level.to_string(),
        }
    }

    /// Return `true` if `level` is a valid level for this type.
    ///
    /// # Parameters
    /// - `level` â€” `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_level(&self, level: &str) -> bool {
        self.levels.iter().any(|l| l == level)
    }
}

/// A relationship between two entities: numeric value plus per-type named levels.
///
/// The relationship is keyed as `(min(a, b), max(a, b))` so that `Aâ†”B` and `Bâ†”A` share
/// the same record. Code using [`RelationshipManager`] does not need to sort the IDs.
///
/// # Fields
/// - `from_id` â€” `u32`.
/// - `to_id` â€” `u32`.
/// - `value` â€” `f64`.
/// - `s` â€” ``type_name â†’ level_string`.`.
/// - `type_levels` â€” `HashMap<String`.
#[derive(Debug, Clone)]
pub struct Relationship {
    /// First entity ID (lower of the two).
    pub from_id: u32,
    /// Second entity ID (higher of the two).
    pub to_id: u32,
    /// The generic numeric relation value (e.g. âˆ’100 = hostile, +100 = allied).
    pub value: f64,
    /// Per-type named states: `type_name â†’ level_string`.
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

/// Manages all relation types and the per-pair relationship records.
///
/// # Fields
/// - `types` â€” `HashMap<String`.
/// - `relations` â€” `HashMap<(u32`.
#[derive(Debug, Default)]
pub struct RelationshipManager {
    types: HashMap<String, RelationType>,
    relations: HashMap<(u32, u32), Relationship>,
    /// Directed named links: `(from_entity, relation_name)` â†’ target entity IDs.
    directed: HashMap<(u32, String), Vec<u32>>,
}

/// Normalize a pair so the lower ID is always first.
#[inline]
fn ordered(a: u32, b: u32) -> (u32, u32) {
    if a <= b {
        (a, b)
    } else {
        (b, a)
    }
}

impl RelationshipManager {
    /// Create a new empty manager. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self::default()
    }

    // â”€â”€ Type definitions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Define a named relation type with a set of valid levels.
    ///
    /// Replaces any existing type with the same name.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
    /// - `levels` â€” `Vec<String>`.
    /// - `default_level` â€” `&str`.
    pub fn define_type(&mut self, name: &str, levels: Vec<String>, default_level: &str) {
        log_msg!(debug, RL01, "{} ({} levels)", name, levels.len());
        self.types.insert(
            name.to_string(),
            RelationType::new(name, levels, default_level),
        );
    }

    /// Remove a relation type. Returns `true` if it existed.
    ///
    /// Existing relationships keep their data but the removed type's levels
    /// are cleaned from all records.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
    ///
    /// # Returns
    /// `bool`.
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

    /// Get a reference to a relation type definition.
    ///
    /// # Parameters
    /// - `name` â€” `&str`.
    ///
    /// # Returns
    /// `Option<&RelationType>`.
    pub fn get_type(&self, name: &str) -> Option<&RelationType> {
        self.types.get(name)
    }

    /// Get the names of all defined relation types.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn type_names(&self) -> Vec<String> {
        self.types.keys().cloned().collect()
    }

    // â”€â”€ Value â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Get the relationship record for a pair (creating it at zero if absent).
    fn ensure(&mut self, a: u32, b: u32) -> &mut Relationship {
        let key = ordered(a, b);
        self.relations.entry(key).or_insert_with(|| {
            log_msg!(trace, RL03, "({}, {})", a, b);
            Relationship::new(a, b)
        })
    }

    /// Get the numeric relation value between two entities.
    ///
    /// # Parameters
    /// - `a` â€” `u32`.
    /// - `b` â€” `u32`.
    ///
    /// # Returns
    /// `f64`.
    pub fn get_value(&self, a: u32, b: u32) -> f64 {
        self.relations
            .get(&ordered(a, b))
            .map(|r| r.value)
            .unwrap_or(0.0)
    }

    /// Set the numeric relation value between two entities.
    ///
    /// # Parameters
    /// - `a` â€” `u32`.
    /// - `b` â€” `u32`.
    /// - `value` â€” `f64`.
    pub fn set_value(&mut self, a: u32, b: u32, value: f64) {
        self.ensure(a, b).value = value;
    }

    /// Adjust the numeric relation value by `delta`.
    ///
    /// # Parameters
    /// - `a` â€” `u32`.
    /// - `b` â€” `u32`.
    /// - `delta` â€” `f64`.
    pub fn adjust_value(&mut self, a: u32, b: u32, delta: f64) {
        let rel = self.ensure(a, b);
        rel.value += delta;
    }

    // â”€â”€ Named levels â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Set the named level for a relation type between two entities.
    ///
    /// Returns `false` if the type is unknown or the level is not valid for that type.
    ///
    /// # Parameters
    /// - `a` â€” `u32`.
    /// - `b` â€” `u32`.
    /// - `ype_name` â€” `&str`.
    /// - `level` â€” `&str`.
    ///
    /// # Returns
    /// `bool`.
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

    /// Get the level for a relation type between two entities.
    ///
    /// Falls back to the type's `default_level` if no explicit level has been set.
    /// Returns `None` if the type name is unknown.
    ///
    /// # Parameters
    /// - `a` â€” `u32`.
    /// - `b` â€” `u32`.
    /// - `ype_name` â€” `&str`.
    ///
    /// # Returns
    /// `Option<String>`.
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

    // â”€â”€ Query â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Return `true` if a relationship record exists for this pair.
    ///
    /// # Parameters
    /// - `a` â€” `u32`.
    /// - `b` â€” `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_relation(&self, a: u32, b: u32) -> bool {
        self.relations.contains_key(&ordered(a, b))
    }

    /// Remove a relationship record. Returns `true` if it existed.
    ///
    /// # Parameters
    /// - `a` â€” `u32`.
    /// - `b` â€” `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_relation(&mut self, a: u32, b: u32) -> bool {
        self.relations.remove(&ordered(a, b)).is_some()
    }

    /// Get all relationships involving a given entity.
    ///
    /// # Parameters
    /// - `entity_id` â€” `u32`.
    ///
    /// # Returns
    /// `Vec<&Relationship>`.
    pub fn all_relations_for(&self, entity_id: u32) -> Vec<&Relationship> {
        self.relations
            .values()
            .filter(|r| r.from_id == entity_id || r.to_id == entity_id)
            .collect()
    }

    /// Get all relationships as an iterator. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `impl Iterator<Item = &Relationship>`.
    pub fn all_relations(&self) -> impl Iterator<Item = &Relationship> {
        self.relations.values()
    }

    /// Get the total number of relationship records.
    ///
    /// # Returns
    /// `usize`.
    pub fn relation_count(&self) -> usize {
        self.relations.len()
    }

    // â”€â”€ Directed named links â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    /// Add a directed named link from `from` to `to`.
    ///
    /// Duplicates are silently ignored â€” calling `add_link(a, "owns", b)` twice
    /// results in a single entry.
    ///
    /// # Parameters
    /// - `from` â€” `u32`.
    /// - `name` â€” `&str`.
    /// - `to` â€” `u32`.
    pub fn add_link(&mut self, from: u32, name: &str, to: u32) {
        let targets = self.directed.entry((from, name.to_string())).or_default();
        if !targets.contains(&to) {
            targets.push(to);
        }
    }

    /// Return all targets reachable from `from` via the named directed link.
    ///
    /// # Parameters
    /// - `from` â€” `u32`.
    /// - `name` â€” `&str`.
    ///
    /// # Returns
    /// `&[u32]` â€” empty slice when no links of this name exist.
    pub fn get_links(&self, from: u32, name: &str) -> &[u32] {
        self.directed
            .get(&(from, name.to_string()))
            .map(|v| v.as_slice())
            .unwrap_or(&[])
    }

    /// Remove the directed link from `from` to `to`.
    ///
    /// # Parameters
    /// - `from` â€” `u32`.
    /// - `name` â€” `&str`.
    /// - `to` â€” `u32`.
    pub fn remove_link(&mut self, from: u32, name: &str, to: u32) {
        if let Some(targets) = self.directed.get_mut(&(from, name.to_string())) {
            targets.retain(|&id| id != to);
        }
    }

    /// Remove all directed links of the given name originating from `from`.
    ///
    /// # Parameters
    /// - `from` â€” `u32`.
    /// - `name` â€” `&str`.
    pub fn clear_links(&mut self, from: u32, name: &str) {
        self.directed.remove(&(from, name.to_string()));
    }

    /// Return `true` if a directed link from `from` to `to` via `name` exists.
    ///
    /// # Parameters
    /// - `from` â€” `u32`.
    /// - `name` â€” `&str`.
    /// - `to` â€” `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_link(&self, from: u32, name: &str, to: u32) -> bool {
        self.directed
            .get(&(from, name.to_string()))
            .map(|v| v.contains(&to))
            .unwrap_or(false)
    }
}

// Tests migrated to tests/rust/unit/ecs_tests.rs
