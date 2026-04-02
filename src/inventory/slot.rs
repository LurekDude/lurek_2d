//! Inventory slots and slot state.

use super::item::{InventoryEntry, ItemStack};

// ──────────────────────────────────────────────────────────────────────────────
// Slot
// ──────────────────────────────────────────────────────────────────────────────

/// Valid state strings for a slot.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum SlotState {
    /// Slot is actively usable.
    Active,
    /// Slot is visible but locked.
    Passive,
    /// Slot is dormant / not yet unlocked.
    Idle,
}

impl SlotState {
    /// Parse from a Lua string.
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "active" => Some(SlotState::Active),
            "passive" => Some(SlotState::Passive),
            "idle" => Some(SlotState::Idle),
            _ => None,
        }
    }

    /// Return the canonical string representation.
    pub fn as_str(&self) -> &'static str {
        match self {
            SlotState::Active => "active",
            SlotState::Passive => "passive",
            SlotState::Idle => "idle",
        }
    }
}

/// A single inventory position that holds an optional `ItemStack`.
#[derive(Debug, Clone)]
pub struct Slot {
    /// Type filter; `"any"` accepts all item types.
    pub slot_type: String,
    /// Current slot state.
    pub state: SlotState,
    /// Grid width capacity.
    pub capacity_w: u32,
    /// Grid height capacity.
    pub capacity_h: u32,
    /// The held item stack, if any.
    pub stack: Option<ItemStack>,
}

impl Slot {
    /// Create a new slot with an optional type filter and state.
    pub fn new(slot_type: impl Into<String>, state: SlotState) -> Self {
        Self {
            slot_type: slot_type.into(),
            state,
            capacity_w: 1,
            capacity_h: 1,
            stack: None,
        }
    }

    /// Whether the slot currently holds no item.
    pub fn is_empty(&self) -> bool {
        self.stack.is_none()
    }

    /// Check whether this slot would accept the given item (type filter + size check).
    /// A slot accepts an item if it is "any", the slot type matches the item's type,
    /// or the item has a tag matching the slot type.
    pub fn can_accept(&self, item: &InventoryEntry) -> bool {
        if self.slot_type != "any"
            && self.slot_type != item.item_type
            && !item.tags.contains(&self.slot_type)
        {
            return false;
        }
        item.size_w <= self.capacity_w && item.size_h <= self.capacity_h
    }

    /// Place a stack in this slot. Returns `false` if the item is not accepted.
    pub fn set_stack(&mut self, stack: ItemStack) -> bool {
        if !self.can_accept(&stack.item) {
            return false;
        }
        self.stack = Some(stack);
        true
    }

    /// Remove and discard the held stack.
    pub fn clear(&mut self) {
        self.stack = None;
    }

    /// Get a reference to the held item, if any.
    pub fn get_item(&self) -> Option<&InventoryEntry> {
        self.stack.as_ref().map(|s| &s.item)
    }
}
