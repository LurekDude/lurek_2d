//! Ordered card collection — deck, hand, library, or similar pile.

use crate::cardgame::card::Card;

/// An ordered collection of cards.
///
/// The last element is the "top" and the first element is the "bottom",
/// matching common card-game conventions.
#[derive(Debug, Clone)]
pub struct Deck {
    /// Display name for this collection.
    pub name: String,
    /// The cards; `cards[last]` = top, `cards[0]` = bottom.
    pub cards: Vec<Card>,
}

impl Deck {
    /// Create an empty named deck.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), cards: Vec::new() }
    }

    /// Number of cards in the deck.
    pub fn size(&self) -> usize {
        self.cards.len()
    }

    /// Returns `true` if the deck is empty.
    pub fn is_empty(&self) -> bool {
        self.cards.is_empty()
    }

    /// Add a card to the top (end).
    pub fn push_top(&mut self, card: Card) {
        self.cards.push(card);
    }

    /// Add a card to the bottom (front).
    pub fn push_bottom(&mut self, card: Card) {
        self.cards.insert(0, card);
    }

    /// Remove and return the top card, or `None` if empty.
    pub fn draw(&mut self) -> Option<Card> {
        self.cards.pop()
    }

    /// Remove and return the bottom card, or `None` if empty.
    pub fn draw_bottom(&mut self) -> Option<Card> {
        if self.cards.is_empty() { None } else { Some(self.cards.remove(0)) }
    }

    /// Draw `n` cards from the top.  Returns fewer than `n` if the deck runs out.
    pub fn draw_many(&mut self, n: usize) -> Vec<Card> {
        (0..n).filter_map(|_| self.draw()).collect()
    }

    /// Peek at the top card without removing it.
    pub fn peek(&self) -> Option<&Card> {
        self.cards.last()
    }

    /// Insert a card at a 0-based position (clamped to deck length).
    pub fn insert_at(&mut self, index: usize, card: Card) {
        let idx = index.min(self.cards.len());
        self.cards.insert(idx, card);
    }

    /// Shuffle the deck in-place using Fisher–Yates.
    pub fn shuffle(&mut self) {
        let n = self.cards.len();
        for i in (1..n).rev() {
            let j = fastrand::usize(0..=i);
            self.cards.swap(i, j);
        }
    }

    /// Return the 0-based indices of cards carrying the given tag.
    pub fn search_by_tag(&self, tag: &str) -> Vec<usize> {
        self.cards
            .iter()
            .enumerate()
            .filter(|(_, c)| c.has_tag(tag))
            .map(|(i, _)| i)
            .collect()
    }

    /// Return the 0-based indices of cards matching `card_type`.
    pub fn search_by_type(&self, card_type: &str) -> Vec<usize> {
        self.cards
            .iter()
            .enumerate()
            .filter(|(_, c)| c.card_type == card_type)
            .map(|(i, _)| i)
            .collect()
    }

    /// Return index of the first card matching a tag.
    pub fn find_by_tag(&self, tag: &str) -> Option<usize> {
        self.cards.iter().position(|c| c.has_tag(tag))
    }

    /// Remove and return the card at 0-based `index`.
    pub fn remove_at(&mut self, index: usize) -> Option<Card> {
        if index < self.cards.len() { Some(self.cards.remove(index)) } else { None }
    }

    /// Move the card at `from` to position `to` (0-based) within this deck.
    pub fn move_within(&mut self, from: usize, to: usize) -> bool {
        if from >= self.cards.len() || to > self.cards.len() {
            return false;
        }
        let card = self.cards.remove(from);
        let dest = if to > from { to - 1 } else { to };
        self.cards.insert(dest, card);
        true
    }

    /// Count cards of the given type.
    pub fn count_by_type(&self, card_type: &str) -> usize {
        self.cards.iter().filter(|c| c.card_type == card_type).count()
    }

    /// Return the type strings of the top `n` cards (does not remove them).
    pub fn reveal_top(&self, n: usize) -> Vec<String> {
        self.cards.iter().rev().take(n).map(|c| c.card_type.clone()).collect()
    }

    /// Transfer all cards from `other` onto the top of this deck (preserving order).
    pub fn absorb(&mut self, other: &mut Deck) {
        self.cards.append(&mut other.cards);
    }

    /// Split this deck at `index` (0-based), returning the top portion as a new deck.
    pub fn split_at(&mut self, index: usize) -> Deck {
        let at = index.min(self.cards.len());
        let top = self.cards.split_off(at);
        Deck { name: format!("{}_split", self.name), cards: top }
    }
}
