//! Stack builder — template-based stack construction with validation.
//!
//! A `DeckBuilder` accumulates `BuildEntry` records (card type + count +
//! optional overrides) and either builds a ready-to-use `Stack` or validates
//! an existing stack against construction constraints.

use crate::cardgame::card::{get_card_type, Card};
use crate::cardgame::stack::Stack;
use std::collections::HashMap;

// ─────────────────────────────────────────────────────────────────────────────
// BuildEntry
// ─────────────────────────────────────────────────────────────────────────────

/// One "slot" in a stack template: an card type plus a count and optional overrides.
///
/// # Fields
/// - `type_name` — `String`.
/// - `count` — `usize`.
/// - `stat_overrides` — `HashMap<String`.
/// - `extra_tags` — `Vec<String>`.
/// - `extra_metadata` — `HashMap<String`.
#[derive(Debug, Clone, Default)]
pub struct BuildEntry {
    /// The card type name to instantiate.
    pub type_name: String,
    /// How many copies to include.
    pub count: usize,
    /// Stat overrides applied on top of the type's base stats.
    pub stat_overrides: HashMap<String, f64>,
    /// Extra tags added on top of the type's base tags.
    pub extra_tags: Vec<String>,
    /// Extra metadata merged on top of the type's base metadata.
    pub extra_metadata: HashMap<String, String>,
}

impl BuildEntry {
    /// Create a minimal build entry. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `ype_name` — `impl Into<String>`.
    /// - `count` — `usize`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(type_name: impl Into<String>, count: usize) -> Self {
        Self {
            type_name: type_name.into(),
            count,
            stat_overrides: HashMap::new(),
            extra_tags: Vec::new(),
            extra_metadata: HashMap::new(),
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// DeckBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a `Stack` from `BuildEntry` templates and validates construction constraints.
///
/// Constraints (min/max size, max copies per type, banned/required types) are
/// all optional and default to "unconstrained".
///
/// # Fields
/// - `name` — `String`.
/// - `entries` — `Vec<BuildEntry>`.
/// - `shuffle_on_build` — `bool`.
/// - `min_size` — `usize`.
/// - `max_size` — `usize`.
/// - `max_copies` — `usize`.
/// - `per_type_limits` — `HashMap<String`.
/// - `required_types` — `Vec<String>`.
/// - `banned_types` — `Vec<String>`.
/// - `banned_categories` — `Vec<String>`.
/// - `max_per_category` — `HashMap<String`.
/// - `s` — ``(tag`.
/// - `required_tags` — `Vec<(String`.
/// - `s` — ``(category`.
/// - `required_categories` — `Vec<(String`.
#[derive(Debug, Clone)]
pub struct DeckBuilder {
    /// Display name passed to the built stack.
    pub name: String,
    /// Template entries to build from.
    pub entries: Vec<BuildEntry>,
    /// Whether to shuffle the stack immediately after building.
    pub shuffle_on_build: bool,
    /// Minimum total items required (0 = no minimum).
    pub min_size: usize,
    /// Maximum total items allowed (0 = no maximum).
    pub max_size: usize,
    /// Maximum copies of a single type (0 = no limit).
    pub max_copies: usize,
    /// Per-type copy limits that override `max_copies`.
    pub per_type_limits: HashMap<String, usize>,
    /// Types that must appear at least once.
    pub required_types: Vec<String>,
    /// Types that are not permitted.
    pub banned_types: Vec<String>,
    /// Categories that are not permitted.
    pub banned_categories: Vec<String>,
    /// Maximum items of a given category (0 = no limit per category).
    pub max_per_category: HashMap<String, usize>,
    /// Tags that must appear at least `min` times: `(tag, min)`.
    pub required_tags: Vec<(String, usize)>,
    /// Categories with min/max constraints: `(category, min, max)`.
    pub required_categories: Vec<(String, usize, Option<usize>)>,
}

impl DeckBuilder {
    /// Create a new stack builder with unconstrained defaults.
    ///
    /// # Parameters
    /// - `name` — `impl Into<String>`.
    ///
    /// # Returns
    /// `Self`.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            entries: Vec::new(),
            shuffle_on_build: false,
            min_size: 0,
            max_size: 0,
            max_copies: 0,
            per_type_limits: HashMap::new(),
            required_types: Vec::new(),
            banned_types: Vec::new(),
            banned_categories: Vec::new(),
            max_per_category: HashMap::new(),
            required_tags: Vec::new(),
            required_categories: Vec::new(),
        }
    }

    /// Add `count` copies of `type_name` to the template.
    ///
    /// # Parameters
    /// - `ype_name` — `impl Into<String>`.
    /// - `count` — `usize`.
    pub fn add(&mut self, type_name: impl Into<String>, count: usize) {
        self.entries.push(BuildEntry::new(type_name, count));
    }

    /// Add entries with per-item stat overrides and extra tags.
    ///
    /// # Parameters
    /// - `ype_name` — `impl Into<String>`.
    /// - `count` — `usize`.
    /// - `stat_overrides` — `HashMap<String`.
    /// - `extra_tags` — `Vec<String>`.
    pub fn add_with(
        &mut self,
        type_name: impl Into<String>,
        count: usize,
        stat_overrides: HashMap<String, f64>,
        extra_tags: Vec<String>,
    ) {
        let mut entry = BuildEntry::new(type_name, count);
        entry.stat_overrides = stat_overrides;
        entry.extra_tags = extra_tags;
        self.entries.push(entry);
    }

    /// Require a type to appear at least once.
    ///
    /// # Parameters
    /// - `ype_name` — `impl Into<String>`.
    pub fn require_type(&mut self, type_name: impl Into<String>) {
        self.required_types.push(type_name.into());
    }

    /// Ban a type from the stack. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `ype_name` — `impl Into<String>`.
    pub fn ban_type(&mut self, type_name: impl Into<String>) {
        self.banned_types.push(type_name.into());
    }

    /// Remove a type from the banned list.  Returns true if it was present.
    ///
    /// # Parameters
    /// - `ype_name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn remove_banned_type(&mut self, type_name: &str) -> bool {
        let before = self.banned_types.len();
        self.banned_types.retain(|t| t != type_name);
        self.banned_types.len() < before
    }

    /// Set per-type copy limit overriding `max_copies`.
    ///
    /// # Parameters
    /// - `ype_name` — `impl Into<String>`.
    /// - `ax` — `usize`.
    pub fn set_max_copies_for_type(&mut self, type_name: impl Into<String>, max: usize) {
        self.per_type_limits.insert(type_name.into(), max);
    }

    /// Require at least `min` cards with the given tag.
    ///
    /// # Parameters
    /// - `ag` — `impl Into<String>`.
    /// - `in` — `usize`.
    pub fn add_required_tag(&mut self, tag: impl Into<String>, min: usize) {
        self.required_tags.push((tag.into(), min));
    }

    /// Require between `min` and `max` cards from the given category.
    ///
    /// # Parameters
    /// - `category` — `impl Into<String>`.
    /// - `in` — `usize`.
    /// - `ax` — `Option<usize>`.
    pub fn add_required_category(&mut self, category: impl Into<String>, min: usize, max: Option<usize>) {
        self.required_categories.push((category.into(), min, max));
    }

    // ── Validation ────────────────────────────────────────────────────────────

    /// Validate the current build entries against the configured constraints.
    ///
    /// Returns a list of human-readable error strings.  An empty vec means valid.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn validate_entries(&self) -> Vec<String> {
        let mut errors = Vec::new();
        let total: usize = self.entries.iter().map(|e| e.count).sum();

        if self.min_size > 0 && total < self.min_size {
            errors.push(format!(
                "too few items: {} < minimum {}",
                total, self.min_size
            ));
        }
        if self.max_size > 0 && total > self.max_size {
            errors.push(format!(
                "too many items: {} > maximum {}",
                total, self.max_size
            ));
        }

        // Count per type across all entries
        let mut type_counts: HashMap<&str, usize> = HashMap::new();
        for e in &self.entries {
            *type_counts.entry(&e.type_name).or_insert(0) += e.count;
        }

        for (type_name, &count) in &type_counts {
            if self.banned_types.iter().any(|b| b == type_name) {
                errors.push(format!("banned type included: {}", type_name));
            }
            let limit = self
                .per_type_limits
                .get(*type_name)
                .copied()
                .or(if self.max_copies > 0 {
                    Some(self.max_copies)
                } else {
                    None
                });
            if let Some(max) = limit {
                if count > max {
                    errors.push(format!(
                        "type '{}': {} copies exceeds limit of {}",
                        type_name, count, max
                    ));
                }
            }
        }

        for req in &self.required_types {
            if !type_counts.contains_key(req.as_str()) {
                errors.push(format!("required type missing: {}", req));
            }
        }

        // Required tag checks
        for (tag, min) in &self.required_tags {
            let count: usize = self.entries.iter().map(|e| {
                if let Some(def) = get_card_type(&e.type_name) {
                    if def.base_tags.contains(tag) { e.count } else { 0 }
                } else {
                    0
                }
            }).sum();
            if count < *min {
                errors.push(format!("required tag '{}': {} < minimum {}", tag, count, min));
            }
        }

        // Required category constraints
        for (cat, min, max_opt) in &self.required_categories {
            let count: usize = self.entries.iter().map(|e| {
                if let Some(def) = get_card_type(&e.type_name) {
                    if &def.category == cat { e.count } else { 0 }
                } else {
                    0
                }
            }).sum();
            if count < *min {
                errors.push(format!("required category '{}': {} < minimum {}", cat, count, min));
            }
            if let Some(max) = max_opt {
                if count > *max {
                    errors.push(format!("required category '{}': {} > maximum {}", cat, count, max));
                }
            }
        }

        // Category checks — look up categories from registry
        if !self.banned_categories.is_empty() || !self.max_per_category.is_empty() {
            let mut cat_counts: HashMap<String, usize> = HashMap::new();
            for e in &self.entries {
                if let Some(def) = get_card_type(&e.type_name) {
                    if !def.category.is_empty() {
                        *cat_counts.entry(def.category.clone()).or_insert(0) += e.count;
                    }
                }
            }
            for (cat, &count) in &cat_counts {
                if self.banned_categories.iter().any(|b| b == cat) {
                    errors.push(format!("banned category included: {}", cat));
                }
                if let Some(&max) = self.max_per_category.get(cat.as_str()) {
                    if max > 0 && count > max {
                        errors.push(format!(
                            "category '{}': {} items exceeds limit of {}",
                            cat, count, max
                        ));
                    }
                }
            }
        }

        errors
    }

    /// Validate an existing `Stack` against the constraints (e.g. verify a player-built deck).
    ///
    /// Returns a list of human-readable error strings.  An empty vec means valid.
    ///
    /// # Parameters
    /// - `stack` — `&Stack`.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn validate_stack(&self, stack: &Stack) -> Vec<String> {
        let mut errors = Vec::new();
        let total = stack.size();

        if self.min_size > 0 && total < self.min_size {
            errors.push(format!(
                "stack too small: {} < minimum {}",
                total, self.min_size
            ));
        }
        if self.max_size > 0 && total > self.max_size {
            errors.push(format!(
                "stack too large: {} > maximum {}",
                total, self.max_size
            ));
        }

        let items = stack.items();
        let mut type_counts: HashMap<&str, usize> = HashMap::new();
        let mut cat_counts: HashMap<&str, usize> = HashMap::new();
        for item in items {
            *type_counts.entry(&item.card_type).or_insert(0) += 1;
            if !item.category.is_empty() {
                *cat_counts.entry(&item.category).or_insert(0) += 1;
            }
        }

        for (type_name, &count) in &type_counts {
            if self.banned_types.iter().any(|b| b == type_name) {
                errors.push(format!("banned type in stack: {}", type_name));
            }
            let limit = self
                .per_type_limits
                .get(*type_name)
                .copied()
                .or(if self.max_copies > 0 {
                    Some(self.max_copies)
                } else {
                    None
                });
            if let Some(max) = limit {
                if count > max {
                    errors.push(format!(
                        "type '{}': {} copies exceeds limit of {}",
                        type_name, count, max
                    ));
                }
            }
        }

        for req in &self.required_types {
            if !type_counts.contains_key(req.as_str()) {
                errors.push(format!("required type missing from stack: {}", req));
            }
        }

        // Required tag checks on existing stack
        let items_vec = stack.items();
        for (tag, min) in &self.required_tags {
            let count = items_vec.iter().filter(|c| c.tags.contains(tag)).count();
            if count < *min {
                errors.push(format!("required tag '{}' in stack: {} < minimum {}", tag, count, min));
            }
        }

        // Required category constraints on existing stack
        for (cat, min, max_opt) in &self.required_categories {
            let count = items_vec.iter().filter(|c| &c.category == cat).count();
            if count < *min {
                errors.push(format!("required category '{}' in stack: {} < minimum {}", cat, count, min));
            }
            if let Some(max) = max_opt {
                if count > *max {
                    errors.push(format!("required category '{}' in stack: {} > maximum {}", cat, count, max));
                }
            }
        }

        for (cat, &count) in &cat_counts {
            if self.banned_categories.iter().any(|b| b == cat) {
                errors.push(format!("banned category in stack: {}", cat));
            }
            if let Some(&max) = self.max_per_category.get(*cat) {
                if max > 0 && count > max {
                    errors.push(format!(
                        "category '{}': {} items exceeds limit of {}",
                        cat, count, max
                    ));
                }
            }
        }

        errors
    }

    // ── Build ─────────────────────────────────────────────────────────────────

    /// Build a `Stack` from the current entries.
    ///
    /// Items are created by calling `Card::new(type_name)` (seeding from the
    /// global registry) and then applying any per-entry overrides.
    /// The stack name defaults to `self.name`.
    ///
    /// # Returns
    /// `Stack`.
    pub fn build(&self) -> Stack {
        self.build_named(&self.name)
    }

    /// Build a `Stack` with a custom name. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `stack_name` — `&str`.
    ///
    /// # Returns
    /// `Stack`.
    pub fn build_named(&self, stack_name: &str) -> Stack {
        let mut stack = Stack::new(stack_name);
        for entry in &self.entries {
            for _ in 0..entry.count {
                let mut item = Card::new(&entry.type_name);
                for (k, v) in &entry.stat_overrides {
                    item.set_stat(k, *v);
                }
                for tag in &entry.extra_tags {
                    item.add_tag(tag);
                }
                for (k, v) in &entry.extra_metadata {
                    item.set_meta(k, v);
                }
                stack.push_top(item);
            }
        }
        if self.shuffle_on_build {
            stack.shuffle();
        }
        stack
    }
}
