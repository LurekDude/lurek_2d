//! Inventory system — slot-based item containers, equipment slots, item sets,
//! subsystem toggles (weight, size, stacking, sets), and callback hooks.

use std::collections::HashMap;

// ──────────────────────────────────────────────────────────────────────────────
// Item
// ──────────────────────────────────────────────────────────────────────────────

/// A single item definition with type, tags, weight, size, and stack limit.
#[derive(Debug, Clone)]
pub struct Item {
    /// The item type identifier string.
    pub item_type: String,
    /// Tags applied to the item (e.g. "weapon", "consumable").
    pub tags: Vec<String>,
    /// Item weight used by the weight subsystem.
    pub weight: f64,
    /// Width in grid units.
    pub size_w: u32,
    /// Height in grid units.
    pub size_h: u32,
    /// Maximum number of items in a single stack (1 = non-stackable).
    pub stack_limit: u32,
}

impl Item {
    /// Create a new item with a given type identifier.
    pub fn new(item_type: impl Into<String>) -> Self {
        Self {
            item_type: item_type.into(),
            tags: Vec::new(),
            weight: 0.0,
            size_w: 1,
            size_h: 1,
            stack_limit: 1,
        }
    }

    /// Check whether this item has the given tag.
    pub fn has_tag(&self, tag: &str) -> bool {
        self.tags.iter().any(|t| t == tag)
    }

    /// Add a tag to this item if not already present.
    pub fn add_tag(&mut self, tag: impl Into<String>) {
        let tag = tag.into();
        if !self.has_tag(&tag) {
            self.tags.push(tag);
        }
    }

    /// Remove a tag. Returns `true` if the tag was removed.
    pub fn remove_tag(&mut self, tag: &str) -> bool {
        let before = self.tags.len();
        self.tags.retain(|t| t != tag);
        self.tags.len() < before
    }

    /// Clone this item (reference fields are Lua-side only and not copied).
    pub fn clone_no_refs(&self) -> Self {
        self.clone()
    }
}

// ──────────────────────────────────────────────────────────────────────────────
// ItemStack
// ──────────────────────────────────────────────────────────────────────────────

/// A counted stack of a single Item type.
#[derive(Debug, Clone)]
pub struct ItemStack {
    /// The underlying item definition.
    pub item: Item,
    /// Current quantity in the stack.
    pub quantity: u32,
    /// Maximum quantity this stack can hold.
    pub max_quantity: u32,
}

impl ItemStack {
    /// Create a new stack wrapping `item` with the given quantity and max.
    pub fn new(item: Item, quantity: u32, max_quantity: u32) -> Self {
        let max_quantity = max_quantity.max(1);
        Self {
            item,
            quantity: quantity.min(max_quantity),
            max_quantity,
        }
    }

    /// Whether the stack is full.
    pub fn is_full(&self) -> bool {
        self.quantity >= self.max_quantity
    }

    /// Add `n` items. Returns the leftover count that did not fit.
    pub fn add(&mut self, n: u32) -> u32 {
        let space = self.max_quantity.saturating_sub(self.quantity);
        let added = n.min(space);
        self.quantity += added;
        n - added
    }

    /// Remove `n` items. Returns the count actually removed.
    pub fn remove(&mut self, n: u32) -> u32 {
        let removed = n.min(self.quantity);
        self.quantity -= removed;
        removed
    }

    /// Split off `n` items into a new stack. Returns `None` if `n == 0` or `n > quantity`.
    pub fn split(&mut self, n: u32) -> Option<ItemStack> {
        if n == 0 || n > self.quantity {
            return None;
        }
        self.quantity -= n;
        Some(ItemStack::new(self.item.clone(), n, self.max_quantity))
    }

    /// Merge `other` into this stack. Returns leftover from `other`.
    pub fn merge(&mut self, other: &mut ItemStack) -> u32 {
        let leftover = self.add(other.quantity);
        other.quantity = leftover;
        leftover
    }
}

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
    pub fn can_accept(&self, item: &Item) -> bool {
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
    pub fn get_item(&self) -> Option<&Item> {
        self.stack.as_ref().map(|s| &s.item)
    }
}

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
    pub fn add_item(&mut self, item: Item, quantity: u32) -> bool {
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
    pub fn unequip(&mut self, slot_name: &str) -> Option<Item> {
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

// ──────────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    fn make_sword() -> Item {
        let mut item = Item::new("sword");
        item.weight = 5.0;
        item.add_tag("weapon");
        item.stack_limit = 1;
        item
    }

    #[test]
    fn item_tags() {
        let mut item = make_sword();
        assert!(item.has_tag("weapon"));
        item.add_tag("rare");
        assert!(item.has_tag("rare"));
        assert!(item.remove_tag("rare"));
        assert!(!item.has_tag("rare"));
    }

    #[test]
    fn item_stack_add_remove() {
        let item = make_sword();
        let mut stack = ItemStack::new(item, 1, 5);
        let overflow = stack.add(3);
        assert_eq!(overflow, 0);
        assert_eq!(stack.quantity, 4);
        let removed = stack.remove(2);
        assert_eq!(removed, 2);
        assert_eq!(stack.quantity, 2);
    }

    #[test]
    fn item_stack_overflow() {
        let item = Item::new("arrow");
        let mut stack = ItemStack::new(item, 10, 10);
        let leftover = stack.add(5);
        assert_eq!(leftover, 5);
        assert!(stack.is_full());
    }

    #[test]
    fn stack_split() {
        let item = Item::new("potion");
        let mut stack = ItemStack::new(item, 5, 10);
        let split = stack.split(2).unwrap();
        assert_eq!(split.quantity, 2);
        assert_eq!(stack.quantity, 3);
    }

    #[test]
    fn slot_can_accept() {
        let slot = Slot::new("weapon", SlotState::Active);
        let sword = make_sword();
        assert!(slot.can_accept(&sword));
        let mut shield = Item::new("shield");
        shield.item_type = "shield".into();
        assert!(!slot.can_accept(&shield));
    }

    #[test]
    fn container_add_item() {
        let mut c = Container::new("backpack", ContainerMode::Fixed, 5);
        c.max_slots = 5;
        let item = Item::new("potion");
        let result = c.add_item(item, 1);
        assert!(result);
    }

    #[test]
    fn inventory_transfer() {
        let mut inv = Inventory::new();
        let mut c1 = Container::new("bag1", ContainerMode::Fixed, 2);
        c1.max_slots = 2;
        let mut c2 = Container::new("bag2", ContainerMode::Fixed, 2);
        c2.max_slots = 2;
        let item = Item::new("gem");
        c1.slots[0].stack = Some(ItemStack::new(item, 1, 5));
        inv.add_container("bag1", c1);
        inv.add_container("bag2", c2);
        assert!(inv.transfer("bag1", 0, "bag2", 0));
        assert!(inv.containers["bag1"].slots[0].is_empty());
        assert!(!inv.containers["bag2"].slots[0].is_empty());
    }

    #[test]
    fn inventory_equip_unequip() {
        let mut inv = Inventory::new();
        inv.add_equip_slot("weapon", Slot::new("weapon", SlotState::Active));
        let sword = make_sword();
        let stack = ItemStack::new(sword, 1, 1);
        assert!(inv.equip("weapon", stack));
        let item = inv.unequip("weapon");
        assert!(item.is_some());
        assert_eq!(item.unwrap().item_type, "sword");
    }

    #[test]
    fn item_set_is_active() {
        let mut inv = Inventory::new();
        let mut slot = Slot::new("weapon", SlotState::Active);
        let sword = make_sword();
        slot.stack = Some(ItemStack::new(sword, 1, 1));
        inv.add_equip_slot("weapon", slot);
        let mut set = ItemSet::new("warrior_set");
        set.add_requirement("weapon", "weapon");
        assert!(set.is_active(&inv.equip_slots));
    }
}
