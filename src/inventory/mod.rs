//! Inventory system — slot-based item containers, equipment slots, item sets,
//! subsystem toggles (weight, size, stacking, sets), and callback hooks.
//!
//! This module is part of Luna2D's `inventory` subsystem and provides the implementation
//! details for mod-related operations and data management.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

/// Item definition and item stacks.
pub mod item;
pub use item::*;

/// Inventory slot and slot state.
pub mod slot;
pub use slot::*;

/// Item containers.
pub mod container;
pub use container::*;

/// Item sets, set requirements, subsystem flags.
pub mod item_set;
pub use item_set::*;

/// Top-level inventory with subsystem management.
#[allow(clippy::module_inception)]
pub mod inventory;
pub use inventory::*;

// ──────────────────────────────────────────────────────────────────────────────
// Tests
// ──────────────────────────────────────────────────────────────────────────────

#[cfg(test)]
mod tests {
    use super::*;

    fn make_sword() -> InventoryEntry {
        let mut item = InventoryEntry::new("sword");
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
        let item = InventoryEntry::new("arrow");
        let mut stack = ItemStack::new(item, 10, 10);
        let leftover = stack.add(5);
        assert_eq!(leftover, 5);
        assert!(stack.is_full());
    }

    #[test]
    fn stack_split() {
        let item = InventoryEntry::new("potion");
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
        let mut shield = InventoryEntry::new("shield");
        shield.item_type = "shield".into();
        assert!(!slot.can_accept(&shield));
    }

    #[test]
    fn container_add_item() {
        let mut c = Container::new("backpack", ContainerMode::Fixed, 5);
        c.max_slots = 5;
        let item = InventoryEntry::new("potion");
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
        let item = InventoryEntry::new("gem");
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
