//! Item definition and item stack.

// ──────────────────────────────────────────────────────────────────────────────
// Item
// ──────────────────────────────────────────────────────────────────────────────

/// A single item definition with type, tags, weight, size, and stack limit.
#[derive(Debug, Clone)]
pub struct InventoryEntry {
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

impl InventoryEntry {
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
    pub item: InventoryEntry,
    /// Current quantity in the stack.
    pub quantity: u32,
    /// Maximum quantity this stack can hold.
    pub max_quantity: u32,
}

impl ItemStack {
    /// Create a new stack wrapping `item` with the given quantity and max.
    pub fn new(item: InventoryEntry, quantity: u32, max_quantity: u32) -> Self {
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
