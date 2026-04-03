//! Inventory: the top-level item storage with subsystem management.
//!
//! This module is part of Luna2D's `inventory` subsystem and provides the implementation
//! details for inventory-related operations and data management.
//! Key types exported from this module: `SubsystemFlags`, `Inventory`.
//! Primary functions: `new()`, `add_container()`, `get_container()`, `get_container_mut()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

use super::container::Container;
use super::item::{InventoryEntry, ItemStack};
use super::item_set::ItemSet;
use super::slot::Slot;

// ──────────────────────────────────────────────────────────────────────────────
// Inventory
// ──────────────────────────────────────────────────────────────────────────────

/// Active subsystem flags for an `Inventory`.
///
/// # Fields
/// - `weight` — `bool`.
/// - `size` — `bool`.
/// - `stacking` — `bool`.
/// - `sets` — `bool`.
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
///
/// # Fields
/// - `containers` — `HashMap<String`.
/// - `container_order` — `Vec<String>`.
/// - `equip_slots` — `HashMap<String`.
/// - `equip_slot_order` — `Vec<String>`.
/// - `item_sets` — `Vec<ItemSet>`.
/// - `subsystems` — `SubsystemFlags`.
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
    /// Create a new empty inventory. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Returns
    /// `Self`.
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

    /// Add or replace a named container. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `container` — `Container`.
    pub fn add_container(&mut self, name: impl Into<String>, container: Container) {
        let name = name.into();
        if !self.container_order.contains(&name) {
            self.container_order.push(name.clone());
        }
        self.containers.insert(name, container);
    }

    /// Get a reference to a container by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&Container>`.
    pub fn get_container(&self, name: &str) -> Option<&Container> {
        self.containers.get(name)
    }

    /// Get a mutable reference to a container by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut Container>`.
    pub fn get_container_mut(&mut self, name: &str) -> Option<&mut Container> {
        self.containers.get_mut(name)
    }

    /// Remove a container. Returns `true` if it existed.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_container(&mut self, name: &str) -> bool {
        if self.containers.remove(name).is_some() {
            self.container_order.retain(|n| n != name);
            true
        } else {
            false
        }
    }

    /// All container names in insertion order. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// `&[String]`.
    pub fn container_names(&self) -> &[String] {
        &self.container_order
    }

    /// Add or replace a named equipment slot. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `slot` — `Slot`.
    pub fn add_equip_slot(&mut self, name: impl Into<String>, slot: Slot) {
        let name = name.into();
        if !self.equip_slot_order.contains(&name) {
            self.equip_slot_order.push(name.clone());
        }
        self.equip_slots.insert(name, slot);
    }

    /// Get a reference to an equip slot. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&Slot>`.
    pub fn get_equip_slot(&self, name: &str) -> Option<&Slot> {
        self.equip_slots.get(name)
    }

    /// Get a mutable equip slot. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut Slot>`.
    pub fn get_equip_slot_mut(&mut self, name: &str) -> Option<&mut Slot> {
        self.equip_slots.get_mut(name)
    }

    /// Remove an equip slot. Returns `true` if it existed.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_equip_slot(&mut self, name: &str) -> bool {
        if self.equip_slots.remove(name).is_some() {
            self.equip_slot_order.retain(|n| n != name);
            true
        } else {
            false
        }
    }

    /// All equip slot names in insertion order.
    ///
    /// # Returns
    /// `&[String]`.
    pub fn equip_slot_names(&self) -> &[String] {
        &self.equip_slot_order
    }

    /// Equip a stack into the named slot. Returns `false` if slot not found or item rejected.
    ///
    /// # Parameters
    /// - `slot_name` — `&str`.
    /// - `stack` — `ItemStack`.
    ///
    /// # Returns
    /// `bool`.
    pub fn equip(&mut self, slot_name: &str, stack: ItemStack) -> bool {
        if let Some(slot) = self.equip_slots.get_mut(slot_name) {
            slot.set_stack(stack)
        } else {
            false
        }
    }

    /// Unequip a slot and return the item (not the full stack). Returns `None` if slot is empty.
    ///
    /// # Parameters
    /// - `slot_name` — `&str`.
    ///
    /// # Returns
    /// `Option<InventoryEntry>`.
    pub fn unequip(&mut self, slot_name: &str) -> Option<InventoryEntry> {
        let slot = self.equip_slots.get_mut(slot_name)?;
        let stack = slot.stack.take()?;
        Some(stack.item)
    }

    /// Enable a subsystem by name. Runs in O(1) time.
    /// Count total items of `item_type` across all containers.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    ///
    /// # Returns
    /// `u32`.
    pub fn count_item(&self, item_type: &str) -> u32 {
        self.containers
            .values()
            .map(|c| c.count_item(item_type))
            .sum()
    }

    /// Returns true if the inventory holds at least `qty` of `item_type` across all containers.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    /// - `qty` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_item(&self, item_type: &str, qty: u32) -> bool {
        self.count_item(item_type) >= qty
    }

    /// Remove up to `qty` of `item_type` from whichever containers have it.
    /// Returns true if the full amount was consumed.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    /// - `qty` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_from_any(&mut self, item_type: &str, qty: u32) -> bool {
        if !self.has_item(item_type, qty) {
            return false;
        }
        let mut remaining = qty;
        for container in self.containers.values_mut() {
            if remaining == 0 {
                break;
            }
            let available = container.count_item(item_type);
            if available > 0 {
                let take = available.min(remaining);
                container.remove_item(item_type, take);
                remaining -= take;
            }
        }
        remaining == 0
    }

    /// Enable or disable the named inventory sub-system (weight, size, stacking, sets).
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn enable_subsystem(&mut self, name: &str) {
        match name {
            "weight" => self.subsystems.weight = true,
            "size" => self.subsystems.size = true,
            "stacking" => self.subsystems.stacking = true,
            "sets" => self.subsystems.sets = true,
            _ => {}
        }
    }

    /// Disable a subsystem by name. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    pub fn disable_subsystem(&mut self, name: &str) {
        match name {
            "weight" => self.subsystems.weight = false,
            "size" => self.subsystems.size = false,
            "stacking" => self.subsystems.stacking = false,
            "sets" => self.subsystems.sets = false,
            _ => {}
        }
    }

    /// Check whether a subsystem is enabled. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_subsystem_enabled(&self, name: &str) -> bool {
        match name {
            "weight" => self.subsystems.weight,
            "size" => self.subsystems.size,
            "stacking" => self.subsystems.stacking,
            "sets" => self.subsystems.sets,
            _ => false,
        }
    }

    /// Add an item set. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `set` — `ItemSet`.
    pub fn add_item_set(&mut self, set: ItemSet) {
        self.item_sets.push(set);
    }

    /// Get all registered item sets. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `&[ItemSet]`.
    pub fn get_item_sets(&self) -> &[ItemSet] {
        &self.item_sets
    }

    /// Get only currently active item sets (all requirements met).
    ///
    /// # Returns
    /// `Vec<&ItemSet>`.
    pub fn get_active_sets(&self) -> Vec<&ItemSet> {
        self.item_sets
            .iter()
            .filter(|s| s.is_active(&self.equip_slots))
            .collect()
    }

    /// Transfer a stack from one container/slot to another.
    /// All indices are 0-based internally.
    ///
    /// # Parameters
    /// - `from_container` — `&str`.
    /// - `from_slot` — `usize`.
    /// - `o_container` — `&str`.
    /// - `o_slot` — `usize`.
    ///
    /// # Returns
    /// `bool`.
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

    /// Split `quantity` items from a stack in `container` at `slot_idx` into the next
    /// empty slot in the same container. Returns `true` if the split succeeded.
    ///
    /// # Parameters
    /// - `container` — `&str`.
    /// - `slot_idx` — `usize`.
    /// - `quantity` — `u32`.
    ///
    /// # Returns
    /// `bool`.
    pub fn split_stack(&mut self, container: &str, slot_idx: usize, quantity: u32) -> bool {
        let c = match self.containers.get_mut(container) {
            Some(c) => c,
            None => return false,
        };
        let split = match c.slots.get_mut(slot_idx) {
            Some(s) => match &mut s.stack {
                Some(stack) => stack.split(quantity),
                None => None,
            },
            None => return false,
        };
        if let Some(new_stack) = split {
            // Place into first empty slot
            for slot in &mut c.slots {
                if slot.is_empty() && slot.can_accept(&new_stack.item) {
                    slot.stack = Some(new_stack);
                    return true;
                }
            }
            // No free slot — undo the split by adding back
            if let Some(s) = c.slots.get_mut(slot_idx) {
                if let Some(stack) = &mut s.stack {
                    stack.quantity += quantity;
                }
            }
            false
        } else {
            false
        }
    }

    /// Merge the stack at `from_slot` into `to_slot` within the same container.
    /// Returns `true` if any items were merged.
    ///
    /// # Parameters
    /// - `container` — `&str`.
    /// - `from_slot` — `usize`.
    /// - `o_slot` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn merge_stacks(&mut self, container: &str, from_slot: usize, to_slot: usize) -> bool {
        let c = match self.containers.get_mut(container) {
            Some(c) => c,
            None => return false,
        };
        if from_slot == to_slot || from_slot >= c.slots.len() || to_slot >= c.slots.len() {
            return false;
        }
        // Take source stack
        let from_stack = match c.slots[from_slot].stack.take() {
            Some(s) => s,
            None => return false,
        };
        // Merge into destination
        match &mut c.slots[to_slot].stack {
            Some(dest) => {
                if dest.item.item_type != from_stack.item.item_type {
                    // Type mismatch — restore source
                    c.slots[from_slot].stack = Some(from_stack);
                    return false;
                }
                let leftover = dest.add(from_stack.quantity);
                if leftover > 0 {
                    c.slots[from_slot].stack = Some(ItemStack::new(
                        from_stack.item,
                        leftover,
                        from_stack.max_quantity,
                    ));
                }
                true
            }
            None => {
                // Destination empty — just move
                c.slots[to_slot].stack = Some(from_stack);
                true
            }
        }
    }

    /// Swap items between two container slots. Returns `false` if either slot not found.
    ///
    /// # Parameters
    /// - `container_a` — `&str`.
    /// - `slot_a` — `usize`.
    /// - `container_b` — `&str`.
    /// - `slot_b` — `usize`.
    ///
    /// # Returns
    /// `bool`.
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
