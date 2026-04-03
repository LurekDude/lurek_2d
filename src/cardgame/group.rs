//! Group analysis — stat-based and tag-based grouping of item slices.
//!
//! All functions operate on plain `&[Card]` slices and return index-based groups
//! so that the caller can decide what to do with them without taking ownership.
//!
//! These utilities are domain-agnostic: "n-of-a-stat" works for poker hands,
//! board game scoring, loot classification, or any other scenario.

use std::collections::HashMap;
use crate::cardgame::card::Card;

// ─────────────────────────────────────────────────────────────────────────────
// CardGroup
// ─────────────────────────────────────────────────────────────────────────────

/// A labelled subset of an item slice, referenced by index.
///
/// Indices refer to positions in the original `&[Card]` slice passed to the
/// analysis function.
///
/// # Fields
/// - `label` — `String`.
/// - `indices` — `Vec<usize>`.
/// - `score` — `u32`.
#[derive(Debug, Clone)]
pub struct CardGroup {
    /// Human-readable label (user-defined or derived, e.g. `"triple|6"`).
    pub label: String,
    /// 0-based indices into the source item slice.
    pub indices: Vec<usize>,
    /// Optional numeric score for ranking groups against each other.
    pub score: u32,
}

impl CardGroup {
    /// Collect the actual items from the source slice.
    ///
    /// # Parameters
    /// - `src` — `&'a [Card]`.
    ///
    /// # Returns
    /// `Vec<&'a Card>`.
    pub fn items_from<'a>(&self, src: &'a [Card]) -> Vec<&'a Card> {
        self.indices.iter().filter_map(|&i| src.get(i)).collect()
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouping utilities
// ─────────────────────────────────────────────────────────────────────────────

/// Group item indices by the integer part of a named stat.
///
/// Returns a map from `stat_value as i64` to a list of 0-based indices.
///
/// # Parameters
/// - `items` — `&[Card]`.
/// - `stat` — `&str`.
///
/// # Returns
/// `HashMap<i64, Vec<usize>>`.
pub fn group_by_stat(items: &[Card], stat: &str) -> HashMap<i64, Vec<usize>> {
    let mut map: HashMap<i64, Vec<usize>> = HashMap::new();
    for (i, item) in items.iter().enumerate() {
        map.entry(item.get_stat(stat) as i64).or_default().push(i);
    }
    map
}

/// Group item indices by category. Consult the module-level documentation for the broader usage context and preconditions.
///
/// Returns a map from category string to a list of 0-based indices.
///
/// # Parameters
/// - `items` — `&[Card]`.
///
/// # Returns
/// `HashMap<String, Vec<usize>>`.
pub fn group_by_category(items: &[Card]) -> HashMap<String, Vec<usize>> {
    let mut map: HashMap<String, Vec<usize>> = HashMap::new();
    for (i, item) in items.iter().enumerate() {
        map.entry(item.category.clone()).or_default().push(i);
    }
    map
}

/// Group item indices by a tag prefix (the part before the first `:`).
///
/// Tags matching `prefix:value` are grouped under `prefix`.  Tags without the
/// prefix separator are grouped under the tag itself.
///
/// Example: items tagged `"suit:hearts"`, `"suit:spades"` both group under `"suit"`.
///
/// # Parameters
/// - `items` — `&[Card]`.
/// - `prefix` — `&str`.
///
/// # Returns
/// `HashMap<String, Vec<usize>>`.
pub fn group_by_tag_prefix(items: &[Card], prefix: &str) -> HashMap<String, Vec<usize>> {
    let search = format!("{}:", prefix);
    let mut map: HashMap<String, Vec<usize>> = HashMap::new();
    for (i, item) in items.iter().enumerate() {
        for tag in &item.tags {
            if tag.starts_with(&search) {
                let value = &tag[search.len()..];
                map.entry(value.to_string()).or_default().push(i);
                break;
            }
        }
    }
    map
}

// ─────────────────────────────────────────────────────────────────────────────
// Pattern-finding utilities
// ─────────────────────────────────────────────────────────────────────────────

/// Find all maximal groups where items share the exact same integer stat value,
/// and the group has exactly `n` members.
///
/// Analogous to "n-of-a-kind" in card games.  Useful for any matching scenario.
///
/// # Parameters
/// - `items` — `&[Card]`.
/// - `stat` — `&str`.
/// - `n` — `usize`.
///
/// # Returns
/// `Vec<CardGroup>`.
pub fn find_n_of_stat(items: &[Card], stat: &str, n: usize) -> Vec<CardGroup> {
    group_by_stat(items, stat)
        .into_iter()
        .filter(|(_, indices)| indices.len() == n)
        .map(|(val, indices)| CardGroup {
            label: format!("{}×{}|{}", n, stat, val),
            score: (n as u32) * 100 + val.unsigned_abs() as u32,
            indices,
        })
        .collect()
}

/// Find all groups where at least `n` items share the same integer stat value.
///
/// # Parameters
/// - `items` — `&[Card]`.
/// - `stat` — `&str`.
/// - `n` — `usize`.
///
/// # Returns
/// `Vec<CardGroup>`.
pub fn find_at_least_n_of_stat(items: &[Card], stat: &str, n: usize) -> Vec<CardGroup> {
    group_by_stat(items, stat)
        .into_iter()
        .filter(|(_, indices)| indices.len() >= n)
        .map(|(val, indices)| CardGroup {
            label: format!("{}+×{}|{}", n, stat, val),
            score: (indices.len() as u32) * 100 + val.unsigned_abs() as u32,
            indices,
        })
        .collect()
}

/// Find all runs (sequences of consecutive integer stat values) of length ≥ `min_run`.
///
/// Sorts items by stat value and identifies consecutive runs.
/// Returns one `CardGroup` per run.
///
/// # Parameters
/// - `items` — `&[Card]`.
/// - `stat` — `&str`.
/// - `in_run` — `usize`.
///
/// # Returns
/// `Vec<CardGroup>`.
pub fn find_sequences(items: &[Card], stat: &str, min_run: usize) -> Vec<CardGroup> {
    if items.is_empty() || min_run == 0 { return Vec::new(); }

    // Sort indices by stat value
    let mut pairs: Vec<(i64, usize)> = items.iter().enumerate()
        .map(|(i, item)| (item.get_stat(stat) as i64, i))
        .collect();
    pairs.sort_by_key(|(val, _)| *val);

    let mut runs: Vec<CardGroup> = Vec::new();
    let mut run_start = 0usize;
    let mut prev_val = pairs[0].0;

    for pos in 1..=pairs.len() {
        let is_consecutive = pos < pairs.len() && pairs[pos].0 == prev_val + 1;
        if !is_consecutive {
            let run_len = pos - run_start;
            if run_len >= min_run {
                let indices: Vec<usize> = pairs[run_start..pos].iter().map(|(_, i)| *i).collect();
                let start_val = pairs[run_start].0;
                runs.push(CardGroup {
                    label: format!("seq{}|{}+{}", run_len, stat, start_val),
                    score: (run_len as u32) * 100 + start_val.unsigned_abs() as u32,
                    indices,
                });
            }
            run_start = pos;
        }
        if pos < pairs.len() {
            prev_val = pairs[pos].0;
        }
    }
    runs
}

/// Find groups of items that all share the same tag-prefix value and contain
/// at least `min_size` members.
///
/// Analogous to "flush" detection: all items with the same `suit:hearts` tag
/// form one group.
///
/// # Parameters
/// - `items` — `&[Card]`.
/// - `ag_prefix` — `&str`.
/// - `in_size` — `usize`.
///
/// # Returns
/// `Vec<CardGroup>`.
pub fn find_tag_groups(items: &[Card], tag_prefix: &str, min_size: usize) -> Vec<CardGroup> {
    group_by_tag_prefix(items, tag_prefix)
        .into_iter()
        .filter(|(_, indices)| indices.len() >= min_size)
        .map(|(val, indices)| CardGroup {
            label: format!("tag-group:{}:{}|{}+", tag_prefix, val, min_size),
            score: indices.len() as u32,
            indices,
        })
        .collect()
}

// ─────────────────────────────────────────────────────────────────────────────
// Sort helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Return a sorted list of 0-based indices; does not modify the slice.
///
/// `ascending = true` → lowest stat first.
///
/// # Parameters
/// - `items` — `&[Card]`.
/// - `stat` — `&str`.
/// - `ascending` — `bool`.
///
/// # Returns
/// `Vec<usize>`.
pub fn sorted_indices_by_stat(items: &[Card], stat: &str, ascending: bool) -> Vec<usize> {
    let mut indices: Vec<usize> = (0..items.len()).collect();
    if ascending {
        indices.sort_by(|&a, &b| {
            items[a].get_stat(stat).partial_cmp(&items[b].get_stat(stat))
                .unwrap_or(std::cmp::Ordering::Equal)
        });
    } else {
        indices.sort_by(|&a, &b| {
            items[b].get_stat(stat).partial_cmp(&items[a].get_stat(stat))
                .unwrap_or(std::cmp::Ordering::Equal)
        });
    }
    indices
}

/// Return sorted indices grouped alphabetically by category.
///
/// # Parameters
/// - `items` — `&[Card]`.
///
/// # Returns
/// `Vec<usize>`.
pub fn sorted_indices_by_category(items: &[Card]) -> Vec<usize> {
    let mut indices: Vec<usize> = (0..items.len()).collect();
    indices.sort_by(|&a, &b| items[a].category.cmp(&items[b].category));
    indices
}
