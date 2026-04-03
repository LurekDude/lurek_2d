//! Ordered item collection — a stack, pile, hand, queue, or any linear sequence of items.
//!
//! The last element is the "top" and the first element is the "bottom".
//! All semantics (draw pile, discard pile, hand, queue) are user-defined.

use crate::item::item::Item;

/// An ordered collection of items. Consult the module-level documentation for the broader usage context and preconditions.
///
/// `items[last]` = top, `items[0]` = bottom.
///
/// # Fields
/// - `name` — `String`.
/// - `items` — `Vec<Item>`.
/// - `capacity` — `Option<usize>`.
#[derive(Debug, Clone)]
pub struct Stack {
    /// Display name for this collection.
    pub name: String,
    /// The items; last = top, first = bottom.
    items: Vec<Item>,
    /// Optional capacity limit (`None` = unlimited).
    capacity: Option<usize>,
}

impl Stack {
    /// Create an empty, unlimited-capacity named stack.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            items: Vec::new(),
            capacity: None,
        }
    }

    /// Create an empty stack with a hard capacity limit.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    /// - `capacity` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn with_capacity(name: impl Into<String>, capacity: usize) -> Self {
        Self {
            name: name.into(),
            items: Vec::new(),
            capacity: Some(capacity),
        }
    }

    /// Number of items in the stack. Runs in O(1) time.
    ///
    /// # Returns
    /// `usize`.
    pub fn size(&self) -> usize {
        self.items.len()
    }

    /// Returns `true` if the stack is empty. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.items.is_empty()
    }

    /// Returns `true` if the stack is at capacity.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_full(&self) -> bool {
        self.capacity.is_some_and(|cap| self.items.len() >= cap)
    }

    /// The capacity limit, or `None` if unlimited.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn capacity(&self) -> Option<usize> {
        self.capacity
    }

    /// Set or remove the capacity limit. Replaces the current capacity value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `cap` — `Option<usize>`.
    pub fn set_capacity(&mut self, cap: Option<usize>) {
        self.capacity = cap;
    }

    // ── Push / Pop ────────────────────────────────────────────────────────────

    /// Add an item to the top (end).  Returns `false` if at capacity.
    ///
    /// # Parameters
    /// - `item` — `Item`.
    ///
    /// # Returns
    /// `bool`.
    pub fn push_top(&mut self, item: Item) -> bool {
        if self.is_full() {
            return false;
        }
        self.items.push(item);
        true
    }

    /// Add an item to the bottom (front).  Returns `false` if at capacity.
    ///
    /// # Parameters
    /// - `item` — `Item`.
    ///
    /// # Returns
    /// `bool`.
    pub fn push_bottom(&mut self, item: Item) -> bool {
        if self.is_full() {
            return false;
        }
        self.items.insert(0, item);
        true
    }

    /// Remove and return the top item, or `None` if empty.
    ///
    /// # Returns
    /// `Option<Item>`.
    pub fn pop_top(&mut self) -> Option<Item> {
        self.items.pop()
    }

    /// Remove and return the bottom item, or `None` if empty.
    ///
    /// # Returns
    /// `Option<Item>`.
    pub fn pop_bottom(&mut self) -> Option<Item> {
        if self.items.is_empty() {
            None
        } else {
            Some(self.items.remove(0))
        }
    }

    /// Remove and return `n` items from the top.  Returns fewer if the stack runs out.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<Item>`.
    pub fn pop_many(&mut self, n: usize) -> Vec<Item> {
        (0..n).filter_map(|_| self.pop_top()).collect()
    }

    // ── Peek ─────────────────────────────────────────────────────────────────

    /// Peek at the top item without removing it.
    ///
    /// # Returns
    /// `Option<&Item>`.
    pub fn peek_top(&self) -> Option<&Item> {
        self.items.last()
    }

    /// Peek at the bottom item without removing it.
    ///
    /// # Returns
    /// `Option<&Item>`.
    pub fn peek_bottom(&self) -> Option<&Item> {
        self.items.first()
    }

    /// Peek at the item at raw 0-based index (bottom = 0).
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&Item>`.
    pub fn peek_at(&self, index: usize) -> Option<&Item> {
        self.items.get(index)
    }

    // ── Insertion / Removal ───────────────────────────────────────────────────

    /// Insert an item at a 0-based position (clamped to stack length).
    /// Returns `false` if at capacity.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    /// - `item` — `Item`.
    ///
    /// # Returns
    /// `bool`.
    pub fn insert_at(&mut self, index: usize, item: Item) -> bool {
        if self.is_full() {
            return false;
        }
        let idx = index.min(self.items.len());
        self.items.insert(idx, item);
        true
    }

    /// Remove and return the item at a 0-based position.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<Item>`.
    pub fn remove_at(&mut self, index: usize) -> Option<Item> {
        if index < self.items.len() {
            Some(self.items.remove(index))
        } else {
            None
        }
    }

    /// Move the item at `from` to position `to` within this stack (0-based).
    /// Returns `false` if indices are out of range.
    ///
    /// # Parameters
    /// - `from` — `usize`.
    /// - `o` — `usize`.
    ///
    /// # Returns
    /// `bool`.
    pub fn move_within(&mut self, from: usize, to: usize) -> bool {
        if from >= self.items.len() || to > self.items.len() {
            return false;
        }
        let item = self.items.remove(from);
        let dest = if to > from { to - 1 } else { to };
        self.items.insert(dest, item);
        true
    }

    /// Remove and return all items, leaving the stack empty.
    ///
    /// # Returns
    /// `Vec<Item>`.
    pub fn clear(&mut self) -> Vec<Item> {
        std::mem::take(&mut self.items)
    }

    // ── Search ────────────────────────────────────────────────────────────────

    /// Return the 0-based indices of items matching `item_type`.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    ///
    /// # Returns
    /// `Vec<usize>`.
    pub fn search_by_type(&self, item_type: &str) -> Vec<usize> {
        self.items
            .iter()
            .enumerate()
            .filter(|(_, i)| i.item_type == item_type)
            .map(|(idx, _)| idx)
            .collect()
    }

    /// Return the 0-based indices of items carrying the given tag.
    ///
    /// # Parameters
    /// - `ag` — `&str`.
    ///
    /// # Returns
    /// `Vec<usize>`.
    pub fn search_by_tag(&self, tag: &str) -> Vec<usize> {
        self.items
            .iter()
            .enumerate()
            .filter(|(_, i)| i.has_tag(tag))
            .map(|(idx, _)| idx)
            .collect()
    }

    /// Return the 0-based indices of items in the given category.
    ///
    /// # Parameters
    /// - `category` — `&str`.
    ///
    /// # Returns
    /// `Vec<usize>`.
    pub fn search_by_category(&self, category: &str) -> Vec<usize> {
        self.items
            .iter()
            .enumerate()
            .filter(|(_, i)| i.category == category)
            .map(|(idx, _)| idx)
            .collect()
    }

    /// Return the index of the first item matching `item_type`, or `None`.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn find_by_type(&self, item_type: &str) -> Option<usize> {
        self.items.iter().position(|i| i.item_type == item_type)
    }

    /// Return the index of the first item carrying a tag, or `None`.
    ///
    /// # Parameters
    /// - `ag` — `&str`.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn find_by_tag(&self, tag: &str) -> Option<usize> {
        self.items.iter().position(|i| i.has_tag(tag))
    }

    // ── Counts ────────────────────────────────────────────────────────────────

    /// Count items of the given type. Runs in O(1) time.
    ///
    /// # Parameters
    /// - `item_type` — `&str`.
    ///
    /// # Returns
    /// `usize`.
    pub fn count_by_type(&self, item_type: &str) -> usize {
        self.items
            .iter()
            .filter(|i| i.item_type == item_type)
            .count()
    }

    /// Count items in the given category. Runs in O(1) time.
    ///
    /// # Parameters
    /// - `category` — `&str`.
    ///
    /// # Returns
    /// `usize`.
    pub fn count_by_category(&self, category: &str) -> usize {
        self.items.iter().filter(|i| i.category == category).count()
    }

    /// Count items carrying the given tag. Runs in O(1) time.
    ///
    /// # Parameters
    /// - `ag` — `&str`.
    ///
    /// # Returns
    /// `usize`.
    pub fn count_by_tag(&self, tag: &str) -> usize {
        self.items.iter().filter(|i| i.has_tag(tag)).count()
    }

    // ── Sorting ───────────────────────────────────────────────────────────────

    /// Sort items in-place by a named stat (ascending).
    ///
    /// # Parameters
    /// - `stat` — `&str`.
    pub fn sort_by_stat(&mut self, stat: &str) {
        self.items.sort_by(|a, b| {
            a.get_stat(stat)
                .partial_cmp(&b.get_stat(stat))
                .unwrap_or(std::cmp::Ordering::Equal)
        });
    }

    /// Sort items in-place by a named stat (descending).
    ///
    /// # Parameters
    /// - `stat` — `&str`.
    pub fn sort_by_stat_desc(&mut self, stat: &str) {
        self.items.sort_by(|a, b| {
            b.get_stat(stat)
                .partial_cmp(&a.get_stat(stat))
                .unwrap_or(std::cmp::Ordering::Equal)
        });
    }

    /// Sort items in-place alphabetically by category.
    pub fn sort_by_category(&mut self) {
        self.items.sort_by(|a, b| a.category.cmp(&b.category));
    }

    /// Sort items in-place alphabetically by name.
    pub fn sort_by_name(&mut self) {
        self.items.sort_by(|a, b| a.name.cmp(&b.name));
    }

    // ── Shuffle ───────────────────────────────────────────────────────────────

    /// Shuffle the stack in-place using Fisher–Yates.
    pub fn shuffle(&mut self) {
        let n = self.items.len();
        for i in (1..n).rev() {
            let j = fastrand::usize(0..=i);
            self.items.swap(i, j);
        }
    }

    // ── Access ────────────────────────────────────────────────────────────────

    /// Read-only view of all items (bottom to top order).
    ///
    /// # Returns
    /// `&[Item]`.
    pub fn items(&self) -> &[Item] {
        &self.items
    }

    /// Mutable access to all items (bottom to top order).
    ///
    /// # Returns
    /// `&mut [Item]`.
    pub fn items_mut(&mut self) -> &mut [Item] {
        &mut self.items
    }

    /// Get item type names of the top `n` items (for reveal-top-N style mechanics).
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn peek_top_n_types(&self, n: usize) -> Vec<String> {
        self.items
            .iter()
            .rev()
            .take(n)
            .map(|i| i.item_type.clone())
            .collect()
    }
}
