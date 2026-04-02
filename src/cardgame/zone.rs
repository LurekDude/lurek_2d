//! Named play areas that hold cards (hand, battlefield, graveyard, exile, etc.).

use crate::cardgame::card::Card;

/// A named play area that holds cards with an optional capacity limit.
#[derive(Debug, Clone)]
pub struct Zone {
    /// Zone name (e.g. `"hand"`, `"battlefield"`, `"graveyard"`).
    pub name: String,
    /// Maximum cards this zone can hold (`0` = unlimited).
    pub capacity: usize,
    /// The cards currently in this zone.
    pub cards: Vec<Card>,
}

impl Zone {
    /// Create a new zone.  Use `capacity = 0` for unlimited.
    pub fn new(name: impl Into<String>, capacity: usize) -> Self {
        Self { name: name.into(), capacity, cards: Vec::new() }
    }

    /// Returns `true` if another card can be added without exceeding capacity.
    pub fn can_add(&self) -> bool {
        self.capacity == 0 || self.cards.len() < self.capacity
    }

    /// Add a card, stamping `card.zone` with the zone name.
    ///
    /// Returns `Err(card)` if the zone is at capacity.
    pub fn add(&mut self, mut card: Card) -> Result<(), Card> {
        if !self.can_add() {
            return Err(card);
        }
        card.zone = self.name.clone();
        self.cards.push(card);
        Ok(())
    }

    /// Remove and return the card at 0-based `index`.
    pub fn remove_at(&mut self, index: usize) -> Option<Card> {
        if index < self.cards.len() { Some(self.cards.remove(index)) } else { None }
    }

    /// Find the first card matching `card_type` and return its 0-based index.
    pub fn find_by_type(&self, card_type: &str) -> Option<usize> {
        self.cards.iter().position(|c| c.card_type == card_type)
    }

    /// Find the first card carrying `tag` and return its 0-based index.
    pub fn find_by_tag(&self, tag: &str) -> Option<usize> {
        self.cards.iter().position(|c| c.has_tag(tag))
    }

    /// Count cards of the given type.
    pub fn count_by_type(&self, card_type: &str) -> usize {
        self.cards.iter().filter(|c| c.card_type == card_type).count()
    }

    /// Count cards carrying the given tag.
    pub fn count_by_tag(&self, tag: &str) -> usize {
        self.cards.iter().filter(|c| c.has_tag(tag)).count()
    }

    /// Return the type strings of all cards.
    pub fn get_all_types(&self) -> Vec<String> {
        self.cards.iter().map(|c| c.card_type.clone()).collect()
    }

    /// Number of cards in this zone.
    pub fn size(&self) -> usize {
        self.cards.len()
    }

    /// Returns `true` if this zone holds no cards.
    pub fn is_empty(&self) -> bool {
        self.cards.is_empty()
    }

    /// Move the card at `index` to `target` zone.
    ///
    /// Returns `false` if the index is out of range or the target is full.
    pub fn move_to(&mut self, index: usize, target: &mut Zone) -> bool {
        if let Some(card) = self.remove_at(index) {
            match target.add(card) {
                Ok(()) => true,
                Err(card) => {
                    // put it back
                    self.cards.insert(index.min(self.cards.len()), card);
                    false
                }
            }
        } else {
            false
        }
    }

    /// Remove all tapped cards and return them.
    pub fn drain_tapped(&mut self) -> Vec<Card> {
        let mut out = Vec::new();
        self.cards.retain(|c| {
            if c.tapped { out.push(c.clone()); false } else { true }
        });
        out
    }

    /// Untap all cards in this zone.
    pub fn untap_all(&mut self) {
        for c in &mut self.cards {
            c.tapped = false;
        }
    }

    /// Return indices of cards for which `f` returns `true`.
    pub fn find_all<F>(&self, mut f: F) -> Vec<usize>
    where
        F: FnMut(&Card) -> bool,
    {
        self.cards.iter().enumerate().filter(|(_, c)| f(c)).map(|(i, _)| i).collect()
    }
}
