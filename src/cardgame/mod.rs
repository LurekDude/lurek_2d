//! Generic card-game-centric data structures.
//!
//! Provides the building blocks for any system that manages a set of named,
//! tagged, stat-carrying objects (cards) organised into stacks/piles.
//!
//! # Key types
//!
//! | Type | Purpose |
//! |---|---|
//! | [`Card`] | A named game object with stats, tags, counters, metadata |
//! | [`CardTypeDef`] | Blueprint/template registered in the global type registry |
//! | [`Stack`] | Ordered collection of cards (draw pile, hand, queue, …) |
//! | [`DeckBuilder`] | Template-based stack construction with validation |
//! | [`StackManager`] | Collection of named stacks; coordinates movement |
//! | [`CardPool`] | Weighted random pool of card types |
//! | [`Slot`] | Bounded single-position holder for cards |
//! | [`StackHistory`] | Append-only change log |
//! | [`CardGroup`] | Index-list for grouping analysis results |
//!
//! # No gameplay assumptions
//!
//! This module deliberately contains no player, turn, trick, rule, or scoring
//! semantics.  All such logic belongs in Lua scripts that use these structures.

#[allow(clippy::module_inception)]
/// Card sub-module.
pub mod card;
/// Stack sub-module.
pub mod stack;
/// Builder sub-module.
pub mod builder;
/// Manager sub-module.
pub mod manager;
/// Pool sub-module.
pub mod pool;
/// Slot sub-module.
pub mod slot;
/// Group sub-module.
pub mod group;
/// History sub-module.
pub mod history;

// Re-export everything flat for convenience
pub use card::{
    Card, CardTypeDef,
    define_card_type, get_card_type, get_card_type_names, clear_card_types,
};
pub use stack::Stack;
pub use builder::{DeckBuilder, BuildEntry};
pub use manager::StackManager;
pub use pool::{CardPool, PoolEntry};
pub use slot::Slot;
pub use group::{
    CardGroup,
    group_by_stat, group_by_category, group_by_tag_prefix,
    find_n_of_stat, find_at_least_n_of_stat, find_sequences, find_tag_groups,
    sorted_indices_by_stat, sorted_indices_by_category,
};
pub use history::{StackHistory, HistoryEntry, HistoryAction};
