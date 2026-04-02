//! InventoryEntry containers with configurable modes.

use super::item::{InventoryEntry, ItemStack};
use super::slot::{Slot, SlotState};

// ──────────────────────────────────────────────────────────────────────────────
// Container
// ──────────────────────────────────────────────────────────────────────────────

/// Container storage mode.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ContainerMode {
    /// Fixed number of slots that cannot grow.
    Fixed,
    /// Unlimited slots; grows on demand.
    Unlimited,
    /// Starts at a base count; can grow up to `max_slots`.
    Expandable,
}

impl ContainerMode {
    /// Parse from a Lua string.
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "fixed" => Some(ContainerMode::Fixed),
            "unlimited" => Some(ContainerMode::Unlimited),
            "expandable" => Some(ContainerMode::Expandable),
            _ => None,
        }
    }

    /// Return the canonical string representation.
    pub fn as_str(&self) -> &'static str {
        match self {
            ContainerMode::Fixed => "fixed",
            ContainerMode::Unlimited => "unlimited",
            ContainerMode::Expandable => "expandable",
        }
    }
}

/// A named collection of `Slot`s.
#[derive(Debug, Clone)]
pub struct Container {
    /// Human-readable container name.
    pub name: String,
    /// Storage mode.
    pub mode: ContainerMode,
    /// All slots.
    pub slots: Vec<Slot>,
    /// Weight limit; 0.0 = no limit.
    pub weight_limit: f64,
    /// Maximum slot count (relevant for `Expandable` mode).
    pub max_slots: u32,
}

impl Container {
    /// Create a new container with a given name, mode, and initial slot count.
    pub fn new(name: impl Into<String>, mode: ContainerMode, slot_count: u32) -> Self {
        let slots = (0..slot_count)
            .map(|_| Slot::new("any", SlotState::Active))
            .collect();
        Self {
            name: name.into(),
            mode,
            slots,
            weight_limit: 0.0,
            max_slots: slot_count,
        }
    }

    /// Number of slots.
    pub fn slot_count(&self) -> usize {
        self.slots.len()
    }

    /// Get a slot by 0-based index.
    pub fn get_slot(&self, index: usize) -> Option<&Slot> {
        self.slots.get(index)
    }

    /// Get a mutable slot by 0-based index.
    pub fn get_slot_mut(&mut self, index: usize) -> Option<&mut Slot> {
        self.slots.get_mut(index)
    }

    /// Append a slot (no-op if fixed and at max capacity).
    pub fn add_slot(&mut self, slot: Slot) {
        match self.mode {
            ContainerMode::Fixed => {
                if self.slots.len() < self.max_slots as usize {
                    self.slots.push(slot);
                }
            }
            _ => self.slots.push(slot),
        }
    }

    /// Remove a slot by 0-based index.
    pub fn remove_slot(&mut self, index: usize) {
        if index < self.slots.len() {
            self.slots.remove(index);
        }
    }

    /// Add `n` new empty slots (expandable mode only). Returns `true` if any were added.
    pub fn expand(&mut self, n: u32) -> bool {
        if self.mode != ContainerMode::Expandable {
            return false;
        }
        let before = self.slots.len();
        for _ in 0..n {
            if self.slots.len() >= self.max_slots as usize {
                break;
            }
            self.slots.push(Slot::new("any", SlotState::Active));
        }
        self.slots.len() > before
    }

    /// Total weight of all stacked items.
    pub fn current_weight(&self) -> f64 {
        self.slots
            .iter()
            .filter_map(|s| s.stack.as_ref())
            .map(|s| s.item.weight * s.quantity as f64)
            .sum()
    }

    /// Auto-place an item. Tries to merge into existing stacks first, then
    /// fills the first empty compatible slot. Returns `true` if placed.
    pub fn add_item(&mut self, item: InventoryEntry, quantity: u32) -> bool {
        let max_q = item.stack_limit;
        // Try merging into existing stacks
        let mut remaining = quantity;
        for slot in &mut self.slots {
            if let Some(stack) = &mut slot.stack {
                if stack.item.item_type == item.item_type && !stack.is_full() {
                    remaining = stack.add(remaining);
                }
            }
            if remaining == 0 {
                return true;
            }
        }
        // Place remainder in empty slots
        while remaining > 0 {
            let to_place = remaining.min(max_q);
            let placed = self
                .slots
                .iter_mut()
                .find(|s| s.is_empty() && s.can_accept(&item))
                .map(|s| {
                    s.stack = Some(ItemStack::new(item.clone(), to_place, max_q));
                    true
                })
                .unwrap_or(false);
            if !placed {
                return false;
            }
            remaining -= to_place;
        }
        true
    }

    /// Count all items of `item_type` across all slots in this container.
    pub fn count_item(&self, item_type: &str) -> u32 {
        self.slots.iter()
            .filter_map(|s| s.stack.as_ref())
            .filter(|st| st.item.item_type == item_type)
            .map(|st| st.quantity)
            .sum()
    }

    /// Returns true if this container holds at least `qty` of `item_type`.
    pub fn has_item(&self, item_type: &str, qty: u32) -> bool {
        self.count_item(item_type) >= qty
    }

    /// Remove up to `qty` items of `item_type`. Returns true if the full amount was removed.
    pub fn remove_item(&mut self, item_type: &str, qty: u32) -> bool {
        if !self.has_item(item_type, qty) { return false; }
        let mut remaining = qty;
        for slot in &mut self.slots {
            if remaining == 0 { break; }
            if let Some(stack) = slot.stack.as_mut() {
                if stack.item.item_type == item_type {
                    let take = stack.quantity.min(remaining);
                    stack.quantity -= take;
                    remaining -= take;
                    if stack.quantity == 0 {
                        slot.stack = None;
                    }
                }
            }
        }
        remaining == 0
    }

    /// Returns a summary of all occupied slots as (item_type, total_quantity) pairs,
    /// aggregating stacks of the same item type.
    pub fn to_item_list(&self) -> Vec<(String, u32)> {
        let mut map: std::collections::HashMap<String, u32> = std::collections::HashMap::new();
        for slot in &self.slots {
            if let Some(stack) = &slot.stack {
                *map.entry(stack.item.item_type.clone()).or_insert(0) += stack.quantity;
            }
        }
        let mut result: Vec<(String, u32)> = map.into_iter().collect();
        result.sort_by(|a, b| a.0.cmp(&b.0));
        result
    }
}
