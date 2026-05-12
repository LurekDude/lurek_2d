//! Game programming patterns for Lurek2D Lua games.
//!
//! Provides twelve classic game-code patterns as UserData objects exposed to Lua
//! via `lurek.patterns.*`.  Callbacks are stored in the Lua API layer; this
//! module holds only pure-Rust state and logic.
//!
//! | Pattern | Type | Purpose |
//! |---|---|---|
//! | Event Bus | [`EventBus`] | Named-event pub/sub with priority ordering |
//! | Object Pool | [`ObjectPool`] | Slot-tracking pool to recycle Lua objects without GC pressure |
//! | Command Stack | [`CommandStack`] | Undo/redo history with batching support |
//! | Service Locator | [`ServiceLocator`] | Singleton-like named service registry |
//! | Factory | [`Factory`] | Type-name constructor registry with aliasing |
//! | State Machine | [`StateMachine`] | Finite-state machine with transition validation and history |
//! | Blackboard | [`Blackboard`] | Shared typed key-value store for AI and game system coordination |
//! | Observer | [`Observer`] | Reactive property subscriptions for per-key change watchers |
//! | Throttle / Debounce | [`Throttle`] / [`Debounce`] | Rate-limit and trailing-edge delay for callbacks |
//! | Priority Queue | [`PriorityQueue`] | Priority-ordered task queue for turn-based and agenda systems |
//! | Ring | [`Ring`] | Fixed-capacity circular history buffer |
//! | Funnel | [`Funnel`] | Time-windowed event aggregator / batch collector |
//!
//! This module is a **Tier 2** Engine Extension.  It may import from Tier 1
//! and Baseline but must never import from `lua_api`.
//!
//! ## Source files
//! | File | Contents |
//! |---|---|
//! | `event_bus.rs` | [`EventBus`], [`Subscription`] |
//! | `object_pool.rs` | [`ObjectPool`] |
//! | `command_stack.rs` | [`CommandStack`], [`CommandEntry`] |
//! | `service_locator.rs` | [`ServiceLocator`] |
//! | `factory.rs` | [`Factory`] |
//! | `state_machine.rs` | [`StateMachine`], [`TransitionRule`] |
//! | `blackboard.rs` | [`Blackboard`], [`BlackboardValue`] |
//! | `observer.rs` | [`Observer`], [`ObserverEntry`] |
//! | `throttle.rs` | [`Throttle`], [`Debounce`] |
//! | `priority_queue.rs` | [`PriorityQueue`], [`PriorityItem`] |
//! | `ring.rs` | [`Ring`], [`RingEntry`] |
//! | `funnel.rs` | [`Funnel`], [`FunnelEntry`] |

/// Behaviour tree nodes for composite AI logic (Sequence, Selector, Parallel, Leaf, Inverter, Repeat).
pub mod behavior_tree;
/// Bidirectional key–value map for two-way lookups.
pub mod bimap;
/// Shared typed key-value store for AI and game system coordination.
pub mod blackboard;
/// Fundamental ordered-collection and set ADTs (Stack, Queue metadata).
pub mod collections;
/// Undo/redo command history with batching support.
pub mod command_stack;
/// Named-event pub/sub bus with priority ordering.
pub mod event_bus;
/// Type-name constructor registry with aliasing.
pub mod factory;
/// Time-windowed event aggregator and batch collector.
pub mod funnel;
/// Generic directed/undirected weighted graph for pathfinding and relationship graphs.
pub mod graph;
/// Named-channel message broker for decoupled communication.
pub mod mediator;
/// Slot-tracking pool to recycle Lua objects without GC pressure.
pub mod object_pool;
/// Reactive property subscriptions for per-key change watchers.
pub mod observer;
/// Priority-ordered task queue for turn-based and agenda systems.
pub mod priority_queue;
/// Fixed-capacity circular history buffer.
pub mod ring;
/// Singleton-like named service registry.
pub mod service_locator;
/// Simplified single-active-state machine for basic state tracking.
pub mod simple_state;
/// Finite-state machine with transition validation and history.
pub mod state_machine;
/// Registry of named, swappable behaviours with a single active selection.
pub mod strategy;
/// Rate-limiter (throttle) and trailing-edge delay (debounce) for callbacks.
pub mod throttle;
/// String prefix-index trie for autocomplete and tag filtering.
pub mod trie;
/// Weighted random selector for loot tables, spawn probability, and weighted picks.
pub mod weighted_random;

pub use behavior_tree::{BehaviorTree, BtNode, BtRunState, BtStatus, NodeId, NodeKind};
pub use bimap::BiMap;
pub use blackboard::{Blackboard, BlackboardValue};
pub use collections::{QueueMeta, StackMeta};
pub use command_stack::{CommandEntry, CommandStack};
pub use event_bus::{EventBus, Subscription};
pub use factory::Factory;
pub use funnel::{Funnel, FunnelEntry};
pub use graph::{Graph, GraphEdge, GraphNode};
pub use mediator::Mediator;
pub use object_pool::ObjectPool;
pub use observer::{Observer, ObserverEntry};
pub use priority_queue::{PriorityItem, PriorityQueue};
pub use ring::{Ring, RingEntry};
pub use service_locator::ServiceLocator;
pub use simple_state::SimpleState;
pub use state_machine::{StateMachine, TransitionRule};
pub use strategy::Strategy;
pub use throttle::{Debounce, Throttle};
pub use trie::Trie;
pub use weighted_random::{WeightedEntry, WeightedRandom};
