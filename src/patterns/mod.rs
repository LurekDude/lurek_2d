//! Game programming patterns for Luna2D Lua games.
//!
//! Provides five classic game-code patterns as UserData objects exposed to Lua
//! via `luna.patterns.*`.  Callbacks are stored in the Lua API layer; this
//! module holds only pure-Rust state and logic.
//!
//! | Pattern | Type | Purpose |
//! |---|---|---|
//! | Event Bus | [`EventBus`] | Named-event pub/sub with priority ordering and wildcard events |
//! | Object Pool | [`ObjectPool`] | Slot-tracking pool to recycle Lua objects without GC pressure |
//! | Command Stack | [`CommandStack`] | Undo/redo history with batching support |
//! | Service Locator | [`ServiceLocator`] | Singleton-like named service registry |
//! | Factory | [`Factory`] | Type-name constructor registry with aliasing |
//! | State Machine | [`StateMachine`] | Finite-state machine with transition validation and history |
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

pub mod command_stack;
pub mod event_bus;
pub mod factory;
pub mod object_pool;
pub mod service_locator;
pub mod simple_state;
pub mod state_machine;

pub use command_stack::{CommandEntry, CommandStack};
pub use event_bus::{EventBus, Subscription};
pub use factory::Factory;
pub use object_pool::ObjectPool;
pub use service_locator::ServiceLocator;
pub use simple_state::SimpleState;
pub use state_machine::{StateMachine, TransitionRule};
