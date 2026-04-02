//! Inventory: the top-level item storage with subsystem management.

use std::collections::HashMap;

use super::container::Container;
use super::item::{InventoryEntry, ItemStack};
use super::item_set::ItemSet;
use super::slot::Slot;

// ──────────────────────────────────────────────────────────────────────────────
// Inventory
// ──────────────────────────────────────────────────────────────────────────────

/// Active subsystem flags for an `Inventory`.
#[derive(Debug, Clone, Default)]
pub struct SubsystemFlags {
    /// Enforce weight limits.
    pub weight: bool,
    /// Enforce size constraints.
    pub size: bool,
    /// Respect stack limits.
    pub stacking: bool,
    /// Evaluate item sets.
    pub sets: bool,
}

/// Top-level inventory managing containers, equip slots, item sets, and callbacks.
#[derive(Debug, Clone)]
pub struct Inventory {
    /// Named storage containers.
    pub containers: HashMap<String, Container>,
    /// Ordered container name list for deterministic iteration.
    pub container_order: Vec<String>,
    /// Named equipment slots.
    pub equip_slots: HashMap<String, Slot>,
    /// Ordered equip slot names.
    pub equip_slot_order: Vec<String>,
    /// Registered item sets.
    pub item_sets: Vec<ItemSet>,
    /// Active subsystem flags.
    pub subsystems: SubsystemFlags,
}

impl Inventory {
    /// Create a new empty inventory.
    pub fn new() -> Self {
        Self {
            containers: HashMap::new(),
            container_order: Vec::new(),
            equip_slots: HashMap::new(),
            equip_slot_order: Vec::new(),
            item_sets: Vec::new(),
            subsystems: SubsystemFlags::default(),
        }
    }

    /// Add or replace a named container.
    pub fn add_container(&mut self, name: impl Into<String>, container: Container) {
        let name = name.into();
        if !self.container_order.contains(&name) {
            self.container_order.push(name.clone());
        }
        self.containers.insert(name, container);
    }

    /// Get a reference to a container by name.
    pub fn get_container(&self, name: &str) -> Option<&Container> {
        self.containers.get(name)
    }

    /// Get a mutable reference to a container by name.
    pub fn get_container_mut(&mut self, name: &str) -> Option<&mut Container> {
        self.containers.get_mut(name)
    }

    /// Remove a container. Returns `true` if it existed.
    pub fn remove_container(&mut self, name: &str) -> bool {
        if self.containers.remove(name).is_some() {
            self.container_order.retain(|n| n != name);
            true
        } else {
            false
        }
    }

    /// All container names in insertion order.
    pub fn container_names(&self) -> &[String] {
        &self.container_order
    }

    /// Add or replace a named equipment slot.
    pub fn add_equip_slot(&mut self, name: impl Into<String>, slot: Slot) {
        let name = name.into();
        if !self.equip_slot_order.contains(&name) {
            self.equip_slot_order.push(name.clone());
        }
        self.equip_slots.insert(name, slot);
    }

    /// Get a reference to an equip slot.
    pub fn get_equip_slot(&self, name: &str) -> Option<&Slot> {
        self.equip_slots.get(name)
    }

    /// Get a mutable equip slot.
    pub fn get_equip_slot_mut(&mut self, name: &str) -> Option<&mut Slot> {
        self.equip_slots.get_mut(name)
    }

    /// Remove an equip slot. Returns `true` if it existed.
    pub fn remove_equip_slot(&mut self, name: &str) -> bool {
        if self.equip_slots.remove(name).is_some() {
            self.equip_slot_order.retain(|n| n != name);
            true
        } else {
            false
        }
    }

    /// All equip slot names in insertion order.
    pub fn equip_slot_names(&self) -> &[String] {
        &self.equip_slot_order
    }

    /// Equip a stack into the named slot. Returns `false` if slot not found or item rejected.
    pub fn equip(&mut self, slot_name: &str, stack: ItemStack) -> bool {
        if let Some(slot) = self.equip_slots.get_mut(slot_name) {
            slot.set_stack(stack)
        } else {
            false
        }
    }

    /// Unequip a slot and return the item (not the full stack). Returns `None` if slot is empty.
    pub fn unequip(&mut self, slot_name: &str) -> Option<InventoryEntry> {
        let slot = self.equip_slots.get_mut(slot_name)?;
        let stack = slot.stack.take()?;
        Some(stack.item)
    }

    /// Enable a subsystem by name.
    /// Count total items of `item_type` across all containers.
    pub fn count_item(&self, item_type: &str) -> u32 {
        self.containers.values().map(|c| c.count_item(item_type)).sum()
    }

    /// Returns true if the inventory holds at least `qty` of `item_type` across all containers.
    pub fn has_item(&self, item_type: &str, qty: u32) -> bool {
        self.count_item(item_type) >= qty
    }

    /// Remove up to `qty` of `item_type` from whichever containers have it.
    /// Returns true if the full amount was consumed.
    pub fn remove_from_any(&mut self, item_type: &str, qty: u32) -> bool {
        if !self.has_item(item_type, qty) { return false; }
        let mut remaining = qty;
        for container in self.containers.values_mut() {
            if remaining == 0 { break; }
            let available = container.count_item(item_type);
            if available > 0 {
                let take = available.min(remaining);
                container.remove_item(item_type, take);
                remaining -= take;
            }
        }
        remaining == 0
    }

    pub fn enable_subsystem(&mut self, name: &str) {
        match name {
            "weight" => self.subsystems.weight = true,
            "size" => self.subsystems.size = true,
            "stacking" => self.subsystems.stacking = true,
            "sets" => self.subsystems.sets = true,
            _ => {}
        }
    }

    /// Disable a subsystem by name.
    pub fn disable_subsystem(&mut self, name: &str) {
        match name {
            "weight" => self.subsystems.weight = false,
            "size" => self.subsystems.size = false,
            "stacking" => self.subsystems.stacking = false,
            "sets" => self.subsystems.sets = false,
            _ => {}
        }
    }

    /// Check whether a subsystem is enabled.
    pub fn is_subsystem_enabled(&self, name: &str) -> bool {
        match name {
            "weight" => self.subsystems.weight,
            "size" => self.subsystems.size,
            "stacking" => self.subsystems.stacking,
            "sets" => self.subsystems.sets,
            _ => false,
        }
    }

    /// Add an item set.
    pub fn add_item_set(&mut self, set: ItemSet) {
        self.item_sets.push(set);
    }

    /// Get all registered item sets.
    pub fn get_item_sets(&self) -> &[ItemSet] {
        &self.item_sets
    }

    /// Get only currently active item sets (all requirements met).
    pub fn get_active_sets(&self) -> Vec<&ItemSet> {
        self.item_sets
            .iter()
            .filter(|s| s.is_active(&self.equip_slots))
            .collect()
    }

    /// Transfer a stack from one container/slot to another.
    /// All indices are 0-based internally.
    pub fn transfer(
        &mut self,
        from_container: &str,
        from_slot: usize,
        to_container: &str,
        to_slot: usize,
    ) -> bool {
        // Extract the stack from the source slot
        let stack = {
            let from = match self.containers.get_mut(from_container) {
                Some(c) => c,
                None => return false,
            };
            let slot = match from.slots.get_mut(from_slot) {
                Some(s) => s,
                None => return false,
            };
            match slot.stack.take() {
                Some(s) => s,
                None => return false,
            }
        };
        // Place into destination slot
        let placed = {
            let to = match self.containers.get_mut(to_container) {
                Some(c) => c,
                None => {
                    // restore source
                    if let Some(from) = self.containers.get_mut(from_container) {
                        if let Some(s) = from.slots.get_mut(from_slot) {
                            s.stack = Some(stack.clone());
                        }
                    }
                    return false;
                }
            };
            let slot = match to.slots.get_mut(to_slot) {
                Some(s) => s,
                None => {
                    // restore source
                    if let Some(from) = self.containers.get_mut(from_container) {
                        if let Some(s) = from.slots.get_mut(from_slot) {
                            s.stack = Some(stack.clone());
                        }
                    }
                    return false;
                }
            };
            slot.set_stack(stack.clone())
        };
        if !placed {
            // Return stack to source
            if let Some(from) = self.containers.get_mut(from_container) {
                if let Some(slot) = from.slots.get_mut(from_slot) {
                    slot.stack = Some(stack);
                }
            }
            false
        } else {
            true
        }
    }

    /// Swap items between two container slots. Returns `false` if either slot not found.
    pub fn swap(
        &mut self,
        container_a: &str,
        slot_a: usize,
        container_b: &str,
        slot_b: usize,
    ) -> bool {
        if container_a == container_b {
            let container = match self.containers.get_mut(container_a) {
                Some(c) => c,
                None => return false,
            };
            if slot_a >= container.slots.len() || slot_b >= container.slots.len() {
                return false;
            }
            container.slots.swap(slot_a, slot_b);
            return true;
        }
        // Extract both — Option::take via and_then, then unwrap with early return
        let stack_a = match self
            .containers
            .get_mut(container_a)
            .and_then(|c| c.slots.get_mut(slot_a))
            .map(|s| s.stack.take())
        {
            Some(v) => v,
            None => return false,
        };
        let stack_b = match self
            .containers
            .get_mut(container_b)
            .and_then(|c| c.slots.get_mut(slot_b))
            .map(|s| s.stack.take())
        {
            Some(v) => v,
            None => return false,
        };
        // Place them in swapped positions
        if let Some(sa) = stack_a.clone() {
            if let Some(c) = self.containers.get_mut(container_b) {
                if let Some(s) = c.slots.get_mut(slot_b) {
                    s.stack = Some(sa);
                }
            }
        }
        if let Some(sb) = stack_b.clone() {
            if let Some(c) = self.containers.get_mut(container_a) {
                if let Some(s) = c.slots.get_mut(slot_a) {
                    s.stack = Some(sb);
                }
            }
        }
        true
    }
}

impl Default for Inventory {
    fn default() -> Self {
        Self::new()
    }
}
