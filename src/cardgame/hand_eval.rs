//! Poker-style hand evaluation utilities.
//!
//! The engine provides **grouping and pattern-detection primitives** only —
//! it never applies poker-specific ranking rules.  The game designer decides
//! which stat or tag represents a "rank", which represents a "suit", and what
//! combination of patterns constitutes a winning hand.

use std::collections::HashMap;
use crate::cardgame::card::Card;

// ─────────────────────────────────────────────────────────────────────────────
// Grouping utilities
// ─────────────────────────────────────────────────────────────────────────────

/// Group `cards` by the string value of a named stat (rounded to integer for grouping).
///
/// Returns a map of `stat_value_as_i64 → [card_indices]`.
pub fn group_by_stat_value(cards: &[Card], stat: &str) -> HashMap<i64, Vec<usize>> {
    let mut map: HashMap<i64, Vec<usize>> = HashMap::new();
    for (i, c) in cards.iter().enumerate() {
        let key = c.get_stat(stat) as i64;
        map.entry(key).or_default().push(i);
    }
    map
}

/// Group `cards` by a named tag value (first tag with prefix `tag_prefix:`).
///
/// Useful for "suit" grouping: tag cards with `"suit:hearts"` and group by `"suit"`.
pub fn group_by_tag_prefix(cards: &[Card], prefix: &str) -> HashMap<String, Vec<usize>> {
    let prefix_colon = format!("{}:", prefix);
    let mut map: HashMap<String, Vec<usize>> = HashMap::new();
    for (i, c) in cards.iter().enumerate() {
        for tag in &c.tags {
            if let Some(value) = tag.strip_prefix(&prefix_colon) {
                map.entry(value.to_owned()).or_default().push(i);
                break;
            }
        }
    }
    map
}

/// Group `cards` by their `category` field.
pub fn group_by_category(cards: &[Card]) -> HashMap<String, Vec<usize>> {
    let mut map: HashMap<String, Vec<usize>> = HashMap::new();
    for (i, c) in cards.iter().enumerate() {
        map.entry(c.category.clone()).or_default().push(i);
    }
    map
}

// ─────────────────────────────────────────────────────────────────────────────
// Pattern finders
// ─────────────────────────────────────────────────────────────────────────────

/// A matched group of cards sharing a pattern.
#[derive(Debug, Clone)]
pub struct CardGroup {
    /// User-supplied label for this group (e.g. `"pair"`, `"flush"`, `"sequence"`).
    pub label: String,
    /// 0-based indices of the matching cards within the original slice.
    pub indices: Vec<usize>,
    /// Numeric score hint assigned by the caller (higher = better).
    pub score: u32,
}

/// Find all groups of exactly `n` cards sharing the same stat value.
///
/// Returns one `CardGroup` per matching stat value.
pub fn find_n_of_a_kind(cards: &[Card], stat: &str, n: usize) -> Vec<CardGroup> {
    group_by_stat_value(cards, stat)
        .into_iter()
        .filter(|(_, idxs)| idxs.len() == n)
        .map(|(_, indices)| CardGroup {
            label: format!("{}-of-a-kind", n),
            indices,
            score: n as u32,
        })
        .collect()
}

/// Find all groups of **at least** `n` cards sharing the same stat value.
pub fn find_at_least_n_of_a_kind(cards: &[Card], stat: &str, n: usize) -> Vec<CardGroup> {
    group_by_stat_value(cards, stat)
        .into_iter()
        .filter(|(_, idxs)| idxs.len() >= n)
        .map(|(_, indices)| {
            let score = indices.len() as u32;
            CardGroup {
                label: format!("{}+ of-a-kind", n),
                indices,
                score,
            }
        })
        .collect()
}

/// Detect consecutive integer sequences in a `stat` (like straights in poker).
///
/// Returns each distinct sequence of length `min_run` or longer.
pub fn find_sequences(cards: &[Card], stat: &str, min_run: usize) -> Vec<CardGroup> {
    // Collect (value, index) pairs sorted by value.
    let mut pairs: Vec<(i64, usize)> = cards
        .iter()
        .enumerate()
        .map(|(i, c)| (c.get_stat(stat) as i64, i))
        .collect();
    pairs.sort_by_key(|(v, _)| *v);
    pairs.dedup_by_key(|(v, _)| *v);  // remove duplicate values for sequence detection

    let mut groups = Vec::new();
    let mut i = 0;
    while i < pairs.len() {
        let mut run = vec![pairs[i].1];
        let mut j = i + 1;
        while j < pairs.len() && pairs[j].0 == pairs[j - 1].0 + 1 {
            run.push(pairs[j].1);
            j += 1;
        }
        if run.len() >= min_run {
            let score = run.len() as u32;
            let label = format!("sequence-{}", run.len());
            groups.push(CardGroup {
                label,
                indices: run,
                score,
            });
        }
        i = j;
    }
    groups
}

/// Find "flush" groups: all cards in the same tag-prefix group (e.g. same suit).
///
/// Returns one `CardGroup` per suit that has at least `min_size` cards.
pub fn find_flush_groups(
    cards: &[Card],
    tag_prefix: &str,
    min_size: usize,
) -> Vec<CardGroup> {
    group_by_tag_prefix(cards, tag_prefix)
        .into_iter()
        .filter(|(_, idxs)| idxs.len() >= min_size)
        .map(|(suit, indices)| {
            let score = indices.len() as u32;
            CardGroup {
                label: format!("flush:{}", suit),
                indices,
                score,
            }
        })
        .collect()
}

// ─────────────────────────────────────────────────────────────────────────────
// HandScore
// ─────────────────────────────────────────────────────────────────────────────

/// A scored hand evaluation result.
///
/// Holds the matched groups and a total numeric score so that hands can be
/// compared with a simple `>`/`<`.  The game designer populates and compares
/// these; the engine never assigns built-in meaning to any score.
#[derive(Debug, Clone, Default)]
pub struct HandScore {
    /// Matched groups found in this hand.
    pub groups: Vec<CardGroup>,
    /// Total score — the caller computes this from `groups`.
    pub total: u32,
    /// Short description of the best pattern (e.g. `"full house"`).
    pub label: String,
}

impl HandScore {
    /// Create a `HandScore` with pre-computed fields.
    pub fn new(label: impl Into<String>, total: u32, groups: Vec<CardGroup>) -> Self {
        Self { label: label.into(), total, groups }
    }

    /// Returns `true` if this hand outscores `other`.
    pub fn beats(&self, other: &HandScore) -> bool {
        self.total > other.total
    }

    /// Returns `true` if both hands have the same total score.
    pub fn ties(&self, other: &HandScore) -> bool {
        self.total == other.total
    }
}
