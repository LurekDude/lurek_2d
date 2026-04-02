//! Generic item-centric data structures.
//!
//! Provides the building blocks for any system that manages a set of named,
//! tagged, stat-carrying objects (items) organised into stacks/piles.
//!
//! # Key types
//!
//! | Type | Purpose |
//! |---|---|
//! | [`Item`] | A named game object with stats, tags, counters, metadata |
//! | [`ItemTypeDef`] | Blueprint/template registered in the global type registry |
//! | [`Stack`] | Ordered collection of items (draw pile, hand, queue, …) |
//! | [`StackBuilder`] | Template-based stack construction with validation |
//! | [`StackManager`] | Collection of named stacks; coordinates movement |
//! | [`ItemPool`] | Weighted random pool of item types |
//! | [`Slot`] | Bounded single-position holder for items |
//! | [`StackHistory`] | Append-only change log |
//! | [`ItemGroup`] | Index-list for grouping analysis results |
//!
//! # No gameplay assumptions
//!
//! This module deliberately contains no player, turn, trick, rule, or scoring
//! semantics.  All such logic belongs in Lua scripts that use these structures.

#[allow(clippy::module_inception)]
pub mod item;
pub mod stack;
pub mod builder;
pub mod manager;
pub mod pool;
pub mod slot;
pub mod group;
pub mod history;

// Re-export everything flat for convenience
pub use item::{
    Item, ItemTypeDef,
    define_item_type, get_item_type, get_item_type_names, clear_item_types,
};
pub use stack::Stack;
pub use builder::{StackBuilder, BuildEntry};
pub use manager::StackManager;
pub use pool::{ItemPool, PoolEntry};
pub use slot::Slot;
pub use group::{
    ItemGroup,
    group_by_stat, group_by_category, group_by_tag_prefix,
    find_n_of_stat, find_at_least_n_of_stat, find_sequences, find_tag_groups,
    sorted_indices_by_stat, sorted_indices_by_category,
};
pub use history::{StackHistory, HistoryEntry, HistoryAction};
