//! Ordered card collection — a stack, pile, hand, zone, or any linear sequence of cards.
//!
//! The last element is the "top" and the first element is the "bottom".
//! All semantics (draw pile, discard pile, hand, battlefield, graveyard) are user-defined.

use crate::cardgame::card::Card;

/// An ordered collection of cards. Consult the module-level documentation for the broader usage context and preconditions.
///
/// `cards[last]` = top, `cards[0]` = bottom.
/// Can serve as a Deck, Zone, Hand, or any other container.
///
/// # Fields
/// - `name` — `String`.
/// - `cards` — `Vec<Card>`.
/// - `capacity` — `Option<usize>`.
/// - `ordered` — `bool`.
/// - `public` — `bool`.
#[derive(Debug, Clone)]
pub struct Stack {
    /// Display name for this collection.
    pub name: String,
    /// The cards; last = top, first = bottom.
    cards: Vec<Card>,
    /// Optional capacity limit (`None` = unlimited).
    capacity: Option<usize>,
    /// Whether this zone preserves insertion order.
    ordered: bool,
    /// Whether cards in this zone are visible to all players.
    public: bool,
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
            cards: Vec::new(),
            capacity: None,
            ordered: true,
            public: false,
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
            cards: Vec::new(),
            capacity: Some(capacity),
            ordered: true,
            public: false,
        }
    }

    /// Number of items in the stack. Runs in O(1) time.
    ///
    /// # Returns
    /// `usize`.
    pub fn size(&self) -> usize {
        self.cards.len()
    }

    /// Returns `true` if the stack is empty. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_empty(&self) -> bool {
        self.cards.is_empty()
    }

    /// Returns `true` if the stack is at capacity.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_full(&self) -> bool {
        self.capacity.is_some_and(|cap| self.cards.len() >= cap)
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
    /// - `card` — `Card`.
    ///
    /// # Returns
    /// `bool`.
    pub fn push_top(&mut self, card: Card) -> bool {
        if self.is_full() {
            return false;
        }
        self.cards.push(card);
        true
    }

    /// Add an item to the bottom (front).  Returns `false` if at capacity.
    ///
    /// # Parameters
    /// - `card` — `Card`.
    ///
    /// # Returns
    /// `bool`.
    pub fn push_bottom(&mut self, card: Card) -> bool {
        if self.is_full() {
            return false;
        }
        self.cards.insert(0, card);
        true
    }

    /// Remove and return the top item, or `None` if empty.
    ///
    /// # Returns
    /// `Option<Card>`.
    pub fn pop_top(&mut self) -> Option<Card> {
        self.cards.pop()
    }

    /// Remove and return the bottom item, or `None` if empty.
    ///
    /// # Returns
    /// `Option<Card>`.
    pub fn pop_bottom(&mut self) -> Option<Card> {
        if self.cards.is_empty() {
            None
        } else {
            Some(self.cards.remove(0))
        }
    }

    /// Remove and return `n` items from the top.  Returns fewer if the stack runs out.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<Card>`.
    pub fn pop_many(&mut self, n: usize) -> Vec<Card> {
        (0..n).filter_map(|_| self.pop_top()).collect()
    }

    // ── Peek ─────────────────────────────────────────────────────────────────

    /// Peek at the top item without removing it.
    ///
    /// # Returns
    /// `Option<&Card>`.
    pub fn peek_top(&self) -> Option<&Card> {
        self.cards.last()
    }

    /// Peek at the bottom item without removing it.
    ///
    /// # Returns
    /// `Option<&Card>`.
    pub fn peek_bottom(&self) -> Option<&Card> {
        self.cards.first()
    }

    /// Peek at the item at raw 0-based index (bottom = 0).
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<&Card>`.
    pub fn peek_at(&self, index: usize) -> Option<&Card> {
        self.cards.get(index)
    }

    // ── Insertion / Removal ───────────────────────────────────────────────────

    /// Insert an item at a 0-based position (clamped to stack length).
    /// Returns `false` if at capacity.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    /// - `card` — `Card`.
    ///
    /// # Returns
    /// `bool`.
    pub fn insert_at(&mut self, index: usize, card: Card) -> bool {
        if self.is_full() {
            return false;
        }
        let idx = index.min(self.cards.len());
        self.cards.insert(idx, card);
        true
    }

    /// Remove and return the item at a 0-based position.
    ///
    /// # Parameters
    /// - `index` — `usize`.
    ///
    /// # Returns
    /// `Option<Card>`.
    pub fn remove_at(&mut self, index: usize) -> Option<Card> {
        if index < self.cards.len() {
            Some(self.cards.remove(index))
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
        if from >= self.cards.len() || to > self.cards.len() {
            return false;
        }
        let card = self.cards.remove(from);
        let dest = if to > from { to - 1 } else { to };
        self.cards.insert(dest, card);
        true
    }

    /// Remove and return all items, leaving the stack empty.
    ///
    /// # Returns
    /// `Vec<Card>`.
    pub fn clear(&mut self) -> Vec<Card> {
        std::mem::take(&mut self.cards)
    }

    // ── Search ────────────────────────────────────────────────────────────────

    /// Return the 0-based indices of items matching `card_type`.
    ///
    /// # Parameters
    /// - `card_type` — `&str`.
    ///
    /// # Returns
    /// `Vec<usize>`.
    pub fn search_by_type(&self, card_type: &str) -> Vec<usize> {
        self.cards
            .iter()
            .enumerate()
            .filter(|(_, i)| i.card_type == card_type)
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
        self.cards
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
        self.cards
            .iter()
            .enumerate()
            .filter(|(_, i)| i.category == category)
            .map(|(idx, _)| idx)
            .collect()
    }

    /// Return the index of the first item matching `card_type`, or `None`.
    ///
    /// # Parameters
    /// - `card_type` — `&str`.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn find_by_type(&self, card_type: &str) -> Option<usize> {
        self.cards.iter().position(|i| i.card_type == card_type)
    }

    /// Return the index of the first item carrying a tag, or `None`.
    ///
    /// # Parameters
    /// - `ag` — `&str`.
    ///
    /// # Returns
    /// `Option<usize>`.
    pub fn find_by_tag(&self, tag: &str) -> Option<usize> {
        self.cards.iter().position(|i| i.has_tag(tag))
    }

    // ── Counts ────────────────────────────────────────────────────────────────

    /// Count items of the given type. Runs in O(1) time.
    ///
    /// # Parameters
    /// - `card_type` — `&str`.
    ///
    /// # Returns
    /// `usize`.
    pub fn count_by_type(&self, card_type: &str) -> usize {
        self.cards
            .iter()
            .filter(|i| i.card_type == card_type)
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
        self.cards.iter().filter(|i| i.category == category).count()
    }

    /// Count items carrying the given tag. Runs in O(1) time.
    ///
    /// # Parameters
    /// - `ag` — `&str`.
    ///
    /// # Returns
    /// `usize`.
    pub fn count_by_tag(&self, tag: &str) -> usize {
        self.cards.iter().filter(|i| i.has_tag(tag)).count()
    }

    // ── Sorting ───────────────────────────────────────────────────────────────

    /// Sort items in-place by a named stat (ascending).
    ///
    /// # Parameters
    /// - `stat` — `&str`.
    pub fn sort_by_stat(&mut self, stat: &str) {
        self.cards.sort_by(|a, b| {
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
        self.cards.sort_by(|a, b| {
            b.get_stat(stat)
                .partial_cmp(&a.get_stat(stat))
                .unwrap_or(std::cmp::Ordering::Equal)
        });
    }

    /// Sort items in-place alphabetically by category.
    pub fn sort_by_category(&mut self) {
        self.cards.sort_by(|a, b| a.category.cmp(&b.category));
    }

    /// Sort items in-place alphabetically by name.
    pub fn sort_by_name(&mut self) {
        self.cards.sort_by(|a, b| a.name.cmp(&b.name));
    }

    // ── Shuffle ───────────────────────────────────────────────────────────────

    /// Shuffle the stack in-place using Fisher–Yates.
    pub fn shuffle(&mut self) {
        let n = self.cards.len();
        for i in (1..n).rev() {
            let j = fastrand::usize(0..=i);
            self.cards.swap(i, j);
        }
    }

    // ── Access ────────────────────────────────────────────────────────────────

    /// Read-only view of all items (bottom to top order).
    ///
    /// # Returns
    /// `&[Card]`.
    pub fn items(&self) -> &[Card] {
        &self.cards
    }

    /// Mutable access to all items (bottom to top order).
    ///
    /// # Returns
    /// `&mut [Card]`.
    pub fn items_mut(&mut self) -> &mut [Card] {
        &mut self.cards
    }

    /// Get card type names of the top `n` cards (for reveal-top-N style mechanics).
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn peek_top_n_types(&self, n: usize) -> Vec<String> {
        self.cards
            .iter()
            .rev()
            .take(n)
            .map(|i| i.card_type.clone())
            .collect()
    }

    // ── Zone Properties ───────────────────────────────────────────────────────

    /// Whether this zone preserves insertion order.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_ordered(&self) -> bool {
        self.ordered
    }

    /// Set whether this zone preserves insertion order.
    ///
    /// # Parameters
    /// - `ordered` — `bool`.
    pub fn set_ordered(&mut self, ordered: bool) {
        self.ordered = ordered;
    }

    /// Whether cards in this zone are visible to all players.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_public(&self) -> bool {
        self.public
    }

    /// Set whether cards in this zone are visible to all players.
    ///
    /// # Parameters
    /// - `public` — `bool`.
    pub fn set_public(&mut self, public: bool) {
        self.public = public;
    }
    /// Rename this stack. Replaces the current name value; callers hold responsibility for maintaining consistency with related fields.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    pub fn set_name(&mut self, name: impl Into<String>) {
        self.name = name.into();
    }

    /// Remove and return the first card matching the given ID.  Returns `true` if found.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    ///
    /// # Returns
    /// `Option<Card>`.
    pub fn remove_by_id(&mut self, id: u64) -> Option<Card> {
        let pos = self.cards.iter().position(|c| c.id == id);
        pos.map(|i| self.cards.remove(i))
    }

    /// Return `true` if a card with this ID is in the stack.
    ///
    /// # Parameters
    /// - `id` — `u64`.
    ///
    /// # Returns
    /// `bool`.
    pub fn contains_id(&self, id: u64) -> bool {
        self.cards.iter().any(|c| c.id == id)
    }

    /// Return all cards with the given category (clones).
    ///
    /// # Parameters
    /// - `category` — `&str`.
    ///
    /// # Returns
    /// `Vec<Card>`.
    pub fn find_by_category_all(&self, category: &str) -> Vec<Card> {
        self.cards.iter().filter(|c| c.category == category).cloned().collect()
    }

    /// Return all cards with the given type name (clones).
    ///
    /// # Parameters
    /// - `ype_name` — `&str`.
    ///
    /// # Returns
    /// `Vec<Card>`.
    pub fn find_by_type_all(&self, type_name: &str) -> Vec<Card> {
        self.cards.iter().filter(|c| c.card_type == type_name).cloned().collect()
    }

    /// Return a snapshot (clone of all cards) for serialization.
    ///
    /// # Returns
    /// `Vec<Card>`.
    pub fn snapshot_cards(&self) -> Vec<Card> {
        self.cards.clone()
    }

    /// Replace all cards from a snapshot. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `cards` — `Vec<Card>`.
    pub fn restore_cards(&mut self, cards: Vec<Card>) {
        self.cards = cards;
    }

}
