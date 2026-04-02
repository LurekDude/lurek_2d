//! Item sets, set requirements, and subsystem flags.

use std::collections::HashMap;
use super::slot::Slot;

// ──────────────────────────────────────────────────────────────────────────────
// ItemSet
// ──────────────────────────────────────────────────────────────────────────────

/// A single requirement in an `ItemSet`.
#[derive(Debug, Clone)]
pub struct SetRequirement {
    /// The tag that must be present on an equipped item.
    pub tag: String,
    /// Limit matching to a specific equip slot name ("" = any).
    pub slot_filter: String,
}

/// A named set defining bonus conditions: all requirements must be satisfied simultaneously.
#[derive(Debug, Clone)]
pub struct ItemSet {
    /// Display name.
    pub name: String,
    /// List of tag requirements.
    pub requirements: Vec<SetRequirement>,
}

impl ItemSet {
    /// Create a new item set with the given name.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            requirements: Vec::new(),
        }
    }

    /// Add a requirement.
    pub fn add_requirement(&mut self, tag: impl Into<String>, slot_filter: impl Into<String>) {
        self.requirements.push(SetRequirement {
            tag: tag.into(),
            slot_filter: slot_filter.into(),
        });
    }

    /// Check whether all requirements are met given the equip slots from an `Inventory`.
    pub fn is_active(&self, equip_slots: &HashMap<String, Slot>) -> bool {
        for req in &self.requirements {
            let found = equip_slots.iter().any(|(slot_name, slot)| {
                // If slot_filter is non-empty, check the slot name
                if !req.slot_filter.is_empty() && slot_name != &req.slot_filter {
                    return false;
                }
                slot.get_item()
                    .map(|item| item.has_tag(&req.tag))
                    .unwrap_or(false)
            });
            if !found {
                return false;
            }
        }
        true
    }
}
