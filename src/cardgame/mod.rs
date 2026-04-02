//! Card game back-end: cards, decks, zones, stacks, rules, scoring, economy,
//! turn management, trick-taking, hand evaluation, and event logging.
//!
//! Exposed to Lua via `luna.cardgame.*`.
//!
//! # Design philosophy
//!
//! Every stat name, resource name, phase name, and event tag is **user-defined**.
//! This module never interprets the meaning of any string key — that is the
//! game designer's job.  The engine provides the data structures and algorithms;
//! the game defines what they mean.

pub mod card;
pub mod deck;
pub mod economy;
pub mod event;
pub mod hand_eval;
pub mod player;
pub mod pool;
pub mod rules;
pub mod scoring;
pub mod stack;
pub mod trick;
pub mod turn;
pub mod zone;

// ── Re-export the most commonly used types at crate root ─────────────────────

pub use card::{
    Card, CardTypeDef,
    clear_card_types, define_card_type, get_card_type, get_card_type_names,
};
pub use deck::Deck;
pub use economy::{Pot, ResourcePool};
pub use event::{EventLog, GameEvent};
pub use hand_eval::{
    CardGroup, HandScore,
    find_n_of_a_kind, find_at_least_n_of_a_kind, find_sequences,
    find_flush_groups, group_by_stat_value, group_by_tag_prefix, group_by_category,
};
pub use player::Player;
pub use pool::{CardPool, CardPoolEntry};
pub use rules::{DeckBuilder, GameRules};
pub use scoring::{ScoreBoard, ScoreEntry};
pub use stack::{StackEntry, StackManager};
pub use trick::{TrickHistory, TrickSlot, TrickState};
pub use turn::TurnManager;
pub use zone::Zone;