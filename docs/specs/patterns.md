# patterns

## General Info

- Module group: `Foundations`
- Source path: `src/patterns/`
- Lua API path(s): `src/lua_api/patterns_api.rs`
- Primary Lua namespace: `lurek.patterns`
- Rust test path(s): tests/rust/unit/patterns_tests.rs
- Lua test path(s): tests/lua/unit/test_patterns_core_unit.lua; tests/lua/stress/test_patterns_stress.lua

## Summary

The `patterns` module is documented from the current source tree and existing module reference data.

Recent scope extension: collection utilities now include richer generic object-management operations inspired by cardgame workflows but exposed as engine-wide neutral APIs (`LStack`, `LQueue`, `LList`, and `LMap`).

This module is mostly self-contained inside the Foundations group. Cross-module behavior should stay in the referenced Rust source files and Lua bindings rather than being duplicated here.

## Files

- `behavior_tree.rs`: Implements behavior tree node graph structures and run-state containers for Sequence/Selector/Parallel/Decorator/Leaf AI composition.
- `bimap.rs`: BiMap: bidirectional HashMap with bijection enforcement on `insert`.
- `blackboard.rs`: Implements a shared typed key-value board with revision tracking for cross-system facts.
- `collections.rs`: Fundamental ordered-collection and set ADTs for Lua scripting.
- `command_stack.rs`: Tracks undo and redo history metadata, including cursor position and batching state.
- `event_bus.rs`: Implements named event-subscription metadata with priority ordering and one-shot listeners.
- `factory.rs`: Implements a constructor-name registry with optional alias resolution.
- `funnel.rs`: Implements a time-windowed event collector that can batch inputs before flushing.
- `graph.rs`: Implements a lightweight directed/undirected weighted adjacency-list graph with BFS/DFS helpers.
- `mediator.rs`: Mediator pattern — pub/sub message channels.
- `mod.rs`: Declares the patterns submodules and re-exports the public helper types.
- `object_pool.rs`: Implements slot bookkeeping for reusable pooled objects, including idle and active tracking.
- `observer.rs`: Implements per-key watcher metadata for reactive property changes.
- `priority_queue.rs`: Implements a stable highest-priority-first queue for small agenda or turn-order workloads.
- `ring.rs`: Implements a fixed-capacity circular history buffer for numeric or string-tagged entries.
- `service_locator.rs`: Implements a named-service presence registry used by the Lua layer to store actual values.
- `simple_state.rs`: Implements a lightweight named-state tracker with a single active state and no validated transition graph.
- `state_machine.rs`: Implements a fuller finite-state machine with registered states, explicit transition rules, and history.
- `strategy.rs`: Strategy pattern — named, swappable behaviours.
- `throttle.rs`: Implements leading-edge throttle and trailing-edge debounce timers for callback rate limiting.
- `trie.rs`: Trie: string-key prefix index with DFS `prefix_search` and recursive `remove`.
- `weighted_random.rs`: Implements weighted entry pools with deterministic sample-based selection (`pick`, `pick_n`) and revision tracking.

## Types

- `BtStatus` (`enum`, `behavior_tree.rs`): Tick result status (`Success`, `Failure`, `Running`) for behavior tree nodes.
- `NodeId` (`type`, `behavior_tree.rs`): Integer identifier for a node within a `BehaviorTree`.
- `NodeKind` (`enum`, `behavior_tree.rs`): Structural node kind for behavior trees (Sequence/Selector/Parallel/Inverter/Repeat/Leaf).
- `BtNode` (`struct`, `behavior_tree.rs`): Node record in a behavior tree (kind, id, children, label).
- `BehaviorTree` (`struct`, `behavior_tree.rs`): ID-indexed behavior tree definition container.
- `BtRunState` (`struct`, `behavior_tree.rs`): Runtime state container for running nodes and repeat counters.
- `BiMap` (`struct`, `bimap.rs`): Bidirectional key–value map where look-ups can be made from either side.
- `BlackboardValue` (`enum`, `blackboard.rs`): Tagged value enum stored inside a `Blackboard`. It keeps the shared state surface small and predictable.
- `Blackboard` (`struct`, `blackboard.rs`): Shared fact store for lightweight cross-system coordination. It is useful when multiple systems need to read and write the same named state without a direct dependency.
- `StackMeta` (`struct`, `collections.rs`): Capacity metadata for a last-in-first-out stack.
- `QueueMeta` (`struct`, `collections.rs`): Capacity metadata for a first-in-first-out queue.
- `CommandEntry` (`struct`, `command_stack.rs`): Single recorded command inside a `CommandStack`. It carries the user-visible label and undo capability metadata.
- `CommandStack` (`struct`, `command_stack.rs`): Undo and redo metadata tracker. The Lua layer attaches the actual callbacks, but this type owns the history rules.
- `Subscription` (`struct`, `event_bus.rs`): Metadata record for one event-bus listener. It keeps listener identity, target event, and once behavior explicit.
- `EventBus` (`struct`, `event_bus.rs`): Named pub-sub registry that orders listeners by priority. It is the local coordination primitive for systems that need scoped event routing.
- `Factory` (`struct`, `factory.rs`): Named constructor registry. It helps scripts instantiate families of objects without hard-coding constructor tables everywhere.
- `FunnelEntry` (`struct`, `funnel.rs`): Single buffered record inside a `Funnel`.
- `Funnel` (`struct`, `funnel.rs`): Batch collector that groups time-adjacent events before a flush.
- `GraphNode` (`struct`, `graph.rs`): Node record in a graph with stable ID and optional label.
- `GraphEdge` (`struct`, `graph.rs`): Directed edge record with stable ID, endpoints, weight, and optional label.
- `Graph` (`struct`, `graph.rs`): Directed/undirected weighted graph with adjacency queries and traversal helpers.
- `Mediator` (`struct`, `mediator.rs`): Named-channel message broker.
- `ObjectPool` (`struct`, `object_pool.rs`): Slot manager for reusable objects. It separates active and idle handles so higher-level code can reduce allocation churn.
- `ObserverEntry` (`struct`, `observer.rs`): Metadata for one observer subscription. It tracks watcher identity, watched key, and once semantics.
- `Observer` (`struct`, `observer.rs`): Per-key subscription registry for reactive property changes. Use it when changes should be keyed to specific names rather than free-form events.
- `PriorityItem` (`struct`, `priority_queue.rs`): Entry stored inside a `PriorityQueue`. It carries priority plus stable insertion sequencing.
- `PriorityQueue` (`struct`, `priority_queue.rs`): Stable priority queue for small scheduling and agenda workloads. It favors simple predictable ordering over heap complexity.
- `Ring` (`struct`, `ring.rs`): Fixed-capacity rolling history buffer. It is useful for recent-input, combo, telemetry, or score-history style workflows.
- `RingEntry` (`struct`, `ring.rs`): One retained ring-buffer entry with optional numeric or string payload and a tag.
- `ServiceLocator` (`struct`, `service_locator.rs`): Named-service registry. The domain type tracks registration while the Lua layer stores the actual service values.
- `SimpleState` (`struct`, `simple_state.rs`): Minimal state tracker with one active named state. It is the simpler choice when callers do not need validated transition rules.
- `TransitionRule` (`struct`, `state_machine.rs`): Declares one allowed transition in a `StateMachine`. It keeps edge validation and optional guard presence explicit.
- `StateMachine` (`struct`, `state_machine.rs`): Transition-aware finite-state machine with registered states and visit history. Use it when transition structure matters.
- `Strategy` (`struct`, `strategy.rs`): Registry of named, interchangeable behaviours with a single active selection.
- `Throttle` (`struct`, `throttle.rs`): Leading-edge rate limiter that decides when a callback is allowed to fire.
- `Debounce` (`struct`, `throttle.rs`): Trailing-edge idle timer that delays firing until input settles.
- `Trie` (`struct`, `trie.rs`): Prefix-index trie keyed on `String`; supports `insert`, `search` (exact), `starts_with` (prefix Boolean), `prefix_search` (collect all matching keys), `remove` (prunes dead nodes). Foundations tier — no Lua binding.
- `WeightedEntry` (`struct`, `weighted_random.rs`): One weighted entry item in a selector pool.
- `WeightedRandom` (`struct`, `weighted_random.rs`): Deterministic sample-driven weighted selector with revision tracking.

## Functions

- `BehaviorTree::new` (`behavior_tree.rs`): Create an empty behavior tree.
- `BehaviorTree::add_sequence` (`behavior_tree.rs`): Add a Sequence node with `label`; return its `NodeId`.
- `BehaviorTree::add_selector` (`behavior_tree.rs`): Add a Selector node with `label`; return its `NodeId`.
- `BehaviorTree::add_parallel` (`behavior_tree.rs`): Add a Parallel node requiring `min_success` successes; return its `NodeId`.
- `BehaviorTree::add_inverter` (`behavior_tree.rs`): Add an Inverter node with `label`; return its `NodeId`.
- `BehaviorTree::add_repeat` (`behavior_tree.rs`): Add a Repeat node that loops its child up to `count` times; return its `NodeId`.
- `BehaviorTree::add_leaf` (`behavior_tree.rs`): Add a Leaf node with action `name` and debug `label`; return its `NodeId`.
- `BehaviorTree::add_child` (`behavior_tree.rs`): Attach `child_id` as the last child of `parent_id`; return false when either id is missing.
- `BehaviorTree::set_root` (`behavior_tree.rs`): Set the tree root to `id`; return false when `id` does not exist.
- `BehaviorTree::has_node` (`behavior_tree.rs`): Return true when a node with `id` exists in this tree.
- `BehaviorTree::get_node` (`behavior_tree.rs`): Return a reference to the node with `id`, or `None` if missing.
- `BehaviorTree::node_count` (`behavior_tree.rs`): Return the total number of allocated nodes.
- `BehaviorTree::node_ids` (`behavior_tree.rs`): Return all node identifiers in insertion order.
- `BehaviorTree::clear` (`behavior_tree.rs`): Remove all nodes and reset the root.
- `BtRunState::new` (`behavior_tree.rs`): Create an empty run state.
- `BtRunState::reset` (`behavior_tree.rs`): Clear all running-node markers and repeat counters.
- `BiMap::new` (`bimap.rs`): Create an empty `BiMap`.
- `BiMap::insert` (`bimap.rs`): Insert the `key`/`value` pair, removing any existing pair that shares the same key or value.
- `BiMap::get_by_key` (`bimap.rs`): Return the value associated with `key`, or `None`.
- `BiMap::get_by_value` (`bimap.rs`): Return the key associated with `value`, or `None`.
- `BiMap::contains_key` (`bimap.rs`): Return true when `key` is present.
- `BiMap::contains_value` (`bimap.rs`): Return true when `value` is present.
- `BiMap::remove_by_key` (`bimap.rs`): Remove the pair identified by `key`; return `(key, value)` or `None` when absent.
- `BiMap::remove_by_value` (`bimap.rs`): Remove the pair identified by `value`; return `(key, value)` or `None` when absent.
- `BiMap::len` (`bimap.rs`): Return the number of key-value pairs.
- `BiMap::is_empty` (`bimap.rs`): Return true when the map contains no pairs.
- `BiMap::clear` (`bimap.rs`): Remove all pairs from the map.
- `Blackboard::new` (`blackboard.rs`): Create an empty blackboard with `name`.
- `Blackboard::set_bool` (`blackboard.rs`): Write a `bool` to `key`, advancing revision counters.
- `Blackboard::set_number` (`blackboard.rs`): Write a `f64` to `key`, advancing revision counters.
- `Blackboard::set_text` (`blackboard.rs`): Write a `String` to `key`, advancing revision counters.
- `Blackboard::clear` (`blackboard.rs`): Remove `key` and advance revision counters.
- `Blackboard::get` (`blackboard.rs`): Return the value for `key`, or `None` if not set.
- `Blackboard::keys` (`blackboard.rs`): Return all keys as a slice of string references.
- `Blackboard::snapshot` (`blackboard.rs`): Return all `(key, value)` pairs as a vector.
- `Blackboard::has` (`blackboard.rs`): Return true when `key` is set.
- `Blackboard::key_revision` (`blackboard.rs`): Return the global revision at which `key` was last written, or `0` if never written.
- `Blackboard::clear_all` (`blackboard.rs`): Remove all keys and advance the global revision.
- `Blackboard::len` (`blackboard.rs`): Return the number of entries currently set.
- `Blackboard::is_empty` (`blackboard.rs`): Return true when no keys are set.
- `StackMeta::new` (`collections.rs`): Create metadata with `capacity` (`0` = unbounded).
- `StackMeta::is_full` (`collections.rs`): Return true when `len` is at or above a non-zero capacity limit.
- `QueueMeta::new` (`collections.rs`): Create metadata with `capacity` (`0` = unbounded).
- `QueueMeta::is_full` (`collections.rs`): Return true when `len` is at or above a non-zero capacity limit.
- `CommandStack::new` (`command_stack.rs`): Create a stack with `max_size` history limit (`0` = unbounded).
- `CommandStack::push` (`command_stack.rs`): Append a command named `name` with undo flag, truncating any redo future; return the new id.
- `CommandStack::peek_undo` (`command_stack.rs`): Return the id of the most recent undoable command without moving the cursor.
- `CommandStack::peek_redo` (`command_stack.rs`): Return the id of the next redoable command without moving the cursor.
- `CommandStack::step_undo` (`command_stack.rs`): Move the cursor back one step and return the id of the command to undo.
- `CommandStack::step_redo` (`command_stack.rs`): Move the cursor forward one step and return the id of the command to redo.
- `CommandStack::clear` (`command_stack.rs`): Clear all history and reset the cursor.
- `CommandStack::undo_count` (`command_stack.rs`): Return the number of undoable commands.
- `CommandStack::redo_count` (`command_stack.rs`): Return the number of redoable commands.
- `CommandStack::get_entry` (`command_stack.rs`): Return a reference to the entry with the given `id`, or `None`.
- `CommandStack::begin_batch` (`command_stack.rs`): Increment batch depth; commands pushed while depth > 0 are grouped.
- `CommandStack::end_batch` (`command_stack.rs`): Decrement batch depth; return the grouped id list when depth reaches 0.
- `EventBus::new` (`event_bus.rs`): Create an enabled bus named `name`.
- `EventBus::subscribe` (`event_bus.rs`): Register a listener for `event` with `priority` and `once` flag; return the subscription id.
- `EventBus::unsubscribe` (`event_bus.rs`): Remove the subscription with `id`; return true when it existed.
- `EventBus::get_listeners` (`event_bus.rs`): Return listener IDs for `event` sorted by descending priority; empty when bus is disabled.
- `EventBus::drain_once` (`event_bus.rs`): Remove all `once` subscriptions from `ids` and return the removed ids.
- `EventBus::clear_event` (`event_bus.rs`): Remove all subscriptions for `event`; return the removed ids.
- `EventBus::clear_all` (`event_bus.rs`): Remove all subscriptions; return all removed ids.
- `EventBus::listener_count` (`event_bus.rs`): Return the number of active subscriptions for exactly `event`.
- `EventBus::event_names` (`event_bus.rs`): Return all distinct event names with at least one subscriber, sorted alphabetically.
- `EventBus::total_count` (`event_bus.rs`): Return the total number of active subscriptions across all events.
- `Factory::new` (`factory.rs`): Create an empty factory.
- `Factory::register` (`factory.rs`): Register `name` as a known type.
- `Factory::unregister` (`factory.rs`): Remove `name` and any aliases pointing to it; return true when the type existed.
- `Factory::has` (`factory.rs`): Return true when `name` is a registered type or a known alias.
- `Factory::resolve` (`factory.rs`): Return the canonical name for `name`, following one level of alias if present.
- `Factory::add_alias` (`factory.rs`): Map `alias` to `canonical`; overwrites any previous mapping for that alias.
- `Factory::type_names` (`factory.rs`): Return all registered canonical type names sorted alphabetically.
- `Factory::clear` (`factory.rs`): Remove all types and aliases.
- `Funnel::new` (`funnel.rs`): Create a funnel named `name` with a `window`-second flush timer and `max_entries` count limit.
- `Funnel::push` (`funnel.rs`): Buffer a `(tag, value)` entry and return `(id, should_flush)` where `should_flush` signals an immediate flush.
- `Funnel::update` (`funnel.rs`): Advance internal time by `dt` seconds; return true when the flush window has elapsed.
- `Funnel::flush` (`funnel.rs`): Drain all buffered entries, reset the timer, and increment `flush_count`.
- `Funnel::pending` (`funnel.rs`): Return a slice of entries that have not yet been flushed.
- `Funnel::pending_count` (`funnel.rs`): Return the number of buffered entries.
- `Funnel::discard` (`funnel.rs`): Drop all buffered entries and reset the timer without incrementing `flush_count`.
- `Graph::new` (`graph.rs`): Create an empty directed graph.
- `Graph::new_undirected` (`graph.rs`): Create an empty undirected graph.
- `Graph::add_node` (`graph.rs`): Add a node with `label`; return the new node id.
- `Graph::remove_node` (`graph.rs`): Remove node `id` and all edges incident to it; return true when it existed.
- `Graph::get_node` (`graph.rs`): Return a reference to the node with `id`, or `None`.
- `Graph::has_node` (`graph.rs`): Return true when a node with `id` exists.
- `Graph::node_ids` (`graph.rs`): Return all node ids.
- `Graph::node_count` (`graph.rs`): Return the total number of nodes.
- `Graph::add_edge` (`graph.rs`): Add an edge from `from` to `to` with `weight` and `label`; return edge id, or `0` if either node is missing.
- `Graph::remove_edge` (`graph.rs`): Remove all edges with `id`; return true when at least one was removed.
- `Graph::get_edge` (`graph.rs`): Return a reference to the first edge with `id`, or `None`.
- `Graph::edges_from` (`graph.rs`): Return all edges originating from `from`.
- `Graph::edges_to` (`graph.rs`): Return all edges pointing to `to`.
- `Graph::edge_count` (`graph.rs`): Return the total number of stored edge entries.
- `Graph::neighbors` (`graph.rs`): Return the ids of all direct outgoing neighbours of `node_id`.
- `Graph::bfs` (`graph.rs`): Return node ids reachable from `start` in BFS order.
- `Graph::dfs` (`graph.rs`): Return node ids reachable from `start` in DFS order.
- `Graph::is_connected` (`graph.rs`): Return true when `to` is reachable from `from`.
- `Graph::clear` (`graph.rs`): Remove all nodes and edges.
- `Mediator::new` (`mediator.rs`): Create an empty mediator.
- `Mediator::register` (`mediator.rs`): Register a handler on `channel` and return its unique id.
- `Mediator::unregister` (`mediator.rs`): Remove handler `id` from `channel`; return true when it was found.
- `Mediator::get_handlers` (`mediator.rs`): Return all handler ids registered on `channel`.
- `Mediator::handler_count` (`mediator.rs`): Return the number of handlers on `channel`.
- `Mediator::channel_names` (`mediator.rs`): Return all known channel names.
- `Mediator::remove_channel` (`mediator.rs`): Remove `channel` and all its handlers.
- `Mediator::clear` (`mediator.rs`): Remove all channels and reset the id counter.
- `ObjectPool::new` (`object_pool.rs`): Create a pool named `name` with `capacity` limit (`0` = unbounded).
- `ObjectPool::acquire` (`object_pool.rs`): Acquire an id from the idle list or allocate a fresh one; return `None` when capacity is full.
- `ObjectPool::release` (`object_pool.rs`): Return `id` to the idle list; return false when `id` was not active.
- `ObjectPool::release_all` (`object_pool.rs`): Return all active ids to the idle list and return the list of released ids.
- `ObjectPool::prewarm` (`object_pool.rs`): Allocate up to `count` idle ids, respecting capacity; return the newly allocated ids.
- `ObjectPool::idle_count` (`object_pool.rs`): Return the number of idle (available) ids.
- `ObjectPool::active_count` (`object_pool.rs`): Return the number of currently active (checked-out) ids.
- `ObjectPool::total_count` (`object_pool.rs`): Return the total number of tracked ids (idle + active).
- `ObjectPool::is_active` (`object_pool.rs`): Return true when `id` is currently active.
- `Observer::new` (`observer.rs`): Create a named empty observer.
- `Observer::subscribe` (`observer.rs`): Register a subscription for `key`; when `once` is true it fires once then is removed; return its id.
- `Observer::unsubscribe` (`observer.rs`): Remove subscription with `id` across all keys; return true when it was found.
- `Observer::watchers_for` (`observer.rs`): Return ids of all watchers for `key` (plus `"*"` wildcards), removing any once-subscriptions.
- `Observer::clear_key` (`observer.rs`): Remove all subscriptions for `key`.
- `Observer::clear_all` (`observer.rs`): Remove all subscriptions.
- `Observer::subscription_count` (`observer.rs`): Return the total number of active subscriptions across all keys.
- `PriorityQueue::new` (`priority_queue.rs`): Create an empty priority queue named `name`.
- `PriorityQueue::push` (`priority_queue.rs`): Insert an item with `priority` and `label`; return its id.
- `PriorityQueue::peek` (`priority_queue.rs`): Return a reference to the highest-priority item without removing it.
- `PriorityQueue::pop` (`priority_queue.rs`): Remove and return the highest-priority item's id and priority.
- `PriorityQueue::remove` (`priority_queue.rs`): Remove the item with `id`; return true when it was found.
- `PriorityQueue::len` (`priority_queue.rs`): Return the number of items in the queue.
- `PriorityQueue::is_empty` (`priority_queue.rs`): Return true when the queue is empty.
- `PriorityQueue::items` (`priority_queue.rs`): Return all items in priority order.
- `PriorityQueue::clear` (`priority_queue.rs`): Remove all items.
- `Ring::new` (`ring.rs`): Create a ring buffer named `name` with `capacity` (clamped to minimum 1).
- `Ring::push_number` (`ring.rs`): Push a numeric entry with `tag`; evict oldest when full; return entry id.
- `Ring::push_string` (`ring.rs`): Push a string entry with `tag`; evict oldest when full; return entry id.
- `Ring::iter` (`ring.rs`): Return an iterator over all entries from oldest to newest.
- `Ring::latest` (`ring.rs`): Return the most recently pushed entry.
- `Ring::oldest` (`ring.rs`): Return the oldest entry still in the buffer.
- `Ring::len` (`ring.rs`): Return the current number of entries.
- `Ring::is_empty` (`ring.rs`): Return true when the buffer holds no entries.
- `Ring::is_full` (`ring.rs`): Return true when the buffer has reached capacity.
- `Ring::clear` (`ring.rs`): Remove all entries.
- `Ring::sum` (`ring.rs`): Return the sum of all numeric entries; non-numeric entries are ignored.
- `Ring::average` (`ring.rs`): Return the arithmetic mean of all numeric entries; return `0.0` when none exist.
- `ServiceLocator::new` (`service_locator.rs`): Create an empty service locator.
- `ServiceLocator::register` (`service_locator.rs`): Add `name` to the registered set.
- `ServiceLocator::unregister` (`service_locator.rs`): Remove `name`; return true when it existed.
- `ServiceLocator::has` (`service_locator.rs`): Return true when `name` is registered.
- `ServiceLocator::names` (`service_locator.rs`): Return all registered names in sorted order.
- `ServiceLocator::clear` (`service_locator.rs`): Unregister all services.
- `SimpleState::new` (`simple_state.rs`): Create an empty state set with no current state.
- `SimpleState::add` (`simple_state.rs`): Add `name` to the known set; return true when it was newly inserted.
- `SimpleState::remove` (`simple_state.rs`): Remove `name` and clear current if it matches; return true when it existed.
- `SimpleState::has` (`simple_state.rs`): Return true when `name` is in the known set.
- `SimpleState::current` (`simple_state.rs`): Return the current state name, or `None`.
- `SimpleState::set_current` (`simple_state.rs`): Set current to `name`; return false when `name` is not in the known set.
- `SimpleState::clear_current` (`simple_state.rs`): Clear the current state without removing it from the set.
- `SimpleState::states` (`simple_state.rs`): Return all known state names in sorted order.
- `SimpleState::state_count` (`simple_state.rs`): Return the total number of known states.
- `StateMachine::new` (`state_machine.rs`): Create a state machine with a single `initial` state as current.
- `StateMachine::add_state` (`state_machine.rs`): Declare a state with callback presence flags.
- `StateMachine::has_state` (`state_machine.rs`): Return true when `name` is a declared state.
- `StateMachine::state_names` (`state_machine.rs`): Return all declared state names in sorted order.
- `StateMachine::add_transition` (`state_machine.rs`): Register a labeled transition from `from` to `to` with an optional guard flag.
- `StateMachine::can_transition` (`state_machine.rs`): Return true when the transition list allows going from `from` to `to`, or when the list is empty.
- `StateMachine::get_transition` (`state_machine.rs`): Return the first matching transition rule from `from` to `to`, or `None`.
- `StateMachine::transition_to` (`state_machine.rs`): Transition to `to` if allowed; update history and `previous`; return false when blocked.
- `StateMachine::history` (`state_machine.rs`): Return the bounded history of visited states in chronological order.
- `StateMachine::reachable_from` (`state_machine.rs`): Return all states reachable directly from `from` by a registered transition.
- `StateMachine::has_update_callback` (`state_machine.rs`): Return true when `state` has a registered update callback.
- `Strategy::new` (`strategy.rs`): Create an empty strategy registry.
- `Strategy::register` (`strategy.rs`): Register `name` and return its assigned id.
- `Strategy::set_current` (`strategy.rs`): Set `name` as current; return false when it is not registered.
- `Strategy::get_current` (`strategy.rs`): Return the name of the current strategy, or `None`.
- `Strategy::get_current_id` (`strategy.rs`): Return the id of the current strategy, or `None`.
- `Strategy::has` (`strategy.rs`): Return true when `name` is registered.
- `Strategy::remove` (`strategy.rs`): Remove `name` and clear current if it matches; return true when it existed.
- `Strategy::names` (`strategy.rs`): Return all registered strategy names.
- `Strategy::clear` (`strategy.rs`): Remove all strategies, clear current, and reset ids.
- `Throttle::new` (`throttle.rs`): Create a throttle that fires every `interval` seconds.
- `Throttle::update` (`throttle.rs`): Advance by `dt` seconds; return true when the interval elapsed and a fire occurs.
- `Throttle::reset` (`throttle.rs`): Reset the elapsed counter, delaying the next fire by a full interval.
- `Throttle::progress` (`throttle.rs`): Return normalized progress toward the next fire in `0.0..=1.0`.
- `Debounce::new` (`throttle.rs`): Create a debounce that fires after `wait` seconds of inactivity.
- `Debounce::trigger` (`throttle.rs`): Arm the debounce, restarting the `wait` countdown.
- `Debounce::update` (`throttle.rs`): Advance by `dt` seconds; return true when `wait` expires and the pending event fires.
- `Debounce::cancel` (`throttle.rs`): Cancel a pending trigger without firing.
- `Trie::new` (`trie.rs`): Create an empty trie.
- `Trie::insert` (`trie.rs`): Insert `key` into the trie; empty keys are ignored.
- `Trie::search` (`trie.rs`): Return true when `key` exists as a complete word.
- `Trie::starts_with` (`trie.rs`): Return true when any inserted key starts with `prefix`.
- `Trie::prefix_search` (`trie.rs`): Return all keys that start with `prefix`.
- `Trie::remove` (`trie.rs`): Remove `key` from the trie; return true when it existed.
- `Trie::len` (`trie.rs`): Return the total number of complete keys stored.
- `Trie::is_empty` (`trie.rs`): Return true when no keys are stored.
- `WeightedRandom::new` (`weighted_random.rs`): Create an empty selector.
- `WeightedRandom::add` (`weighted_random.rs`): Add an entry with `weight` and `label`; return its id.
- `WeightedRandom::remove` (`weighted_random.rs`): Remove the entry with `id`; return true when it existed.
- `WeightedRandom::set_weight` (`weighted_random.rs`): Update the weight of entry `id`; return false when not found.
- `WeightedRandom::total_weight` (`weighted_random.rs`): Return the sum of all entry weights.
- `WeightedRandom::pick` (`weighted_random.rs`): Select one entry using normalized `sample` (0.0..1.0); return `None` when total weight is zero.
- `WeightedRandom::pick_n` (`weighted_random.rs`): Select up to `count` distinct entries without replacement using `samples`; return their ids.
- `WeightedRandom::entries` (`weighted_random.rs`): Return all entries in insertion order.
- `WeightedRandom::len` (`weighted_random.rs`): Return the number of entries.
- `WeightedRandom::is_empty` (`weighted_random.rs`): Return true when there are no entries.
- `WeightedRandom::get` (`weighted_random.rs`): Return the entry with `id`, or `None`.
- `WeightedRandom::clear` (`weighted_random.rs`): Remove all entries and increment revision.

## Lua API Reference

- Binding path(s): `src/lua_api/patterns_api.rs`
- Namespace: `lurek.patterns`

### Module Functions
- `lurek.patterns.newEventBus`: Create a new publish/subscribe event bus for decoupled communication between game systems.
- `lurek.patterns.newObjectPool`: Create a new object pool for reusing pre-allocated game objects to reduce allocation overhead.
- `lurek.patterns.newCommandStack`: Create a new undo/redo command stack for recording and reversing player or editor actions.
- `lurek.patterns.newServiceLocator`: Create a new service locator for registering and retrieving shared services by name at runtime.
- `lurek.patterns.newFactory`: Create a new factory for producing typed game objects from registered constructor functions.
- `lurek.patterns.newSimpleState`: Create a new finite state machine with enter/exit/update callbacks per state.
- `lurek.patterns.newBlackboard`: Create a new shared key-value blackboard supporting reactive watchers for game logic variables.
- `lurek.patterns.newObserver`: Create a new reactive observer that stores values and notifies subscribers when they change.
- `lurek.patterns.newThrottle`: Create a new throttle that limits how often an action can fire, enforcing a minimum interval.
- `lurek.patterns.newDebounce`: Create a new debounce that delays firing until input stops for a specified wait period.
- `lurek.patterns.newPriorityQueue`: Create a new priority queue that orders elements by numeric priority (highest first).
- `lurek.patterns.newRing`: Create a new fixed-size ring buffer for numeric or string values. Oldest entries are overwritten when full.
- `lurek.patterns.newFunnel`: Create a new batching funnel that collects events over a time window and flushes them together.
- `lurek.patterns.newRelationshipManager`: Create a new relationship manager for tracking numeric values and named levels between entity pairs.
- `lurek.patterns.newMediator`: Create a new mediator for channel-based message passing between decoupled game systems.
- `lurek.patterns.newStrategy`: Create a new strategy pattern container for hot-swappable algorithm implementations.
- `lurek.patterns.newStack`: Create a new LIFO stack with optional capacity limit.
- `lurek.patterns.newQueue`: Create a new FIFO queue with optional capacity limit.
- `lurek.patterns.newList`: Create a new dynamic array list with indexed access, insertion, removal, and search.
- `lurek.patterns.newSet`: Create a new string set with add/remove/has operations and set algebra (union, intersection).
- `lurek.patterns.newMap`: Create a new string-keyed dictionary (map) with keys/values/entries access and merge support.
- `lurek.patterns.newWeightedRandom`: Create a new weighted random selection pool. Add items with weights and pick random selections.
- `lurek.patterns.newBehaviorTree`: Create a new behavior tree for AI decision-making with sequences, selectors, parallels, and leaf actions.
- `lurek.patterns.newGraph`: Create a new graph data structure with directed or undirected edges, BFS, DFS, and connectivity queries.

### `LBehaviorTree` Methods
- `LBehaviorTree:addSequence`: Create a sequence composite node. All children must succeed for this node to succeed.
- `LBehaviorTree:addSelector`: Create a selector (fallback) composite node. Succeeds if any child succeeds.
- `LBehaviorTree:addParallel`: Create a parallel composite node that runs all children simultaneously.
- `LBehaviorTree:addInverter`: Create a decorator node that inverts its child's result (success ↔ failure).
- `LBehaviorTree:addRepeat`: Create a decorator node that repeats its child a fixed number of times.
- `LBehaviorTree:addLeaf`: Create a leaf (action) node that will invoke a named callback function on tick.
- `LBehaviorTree:addChild`: Attach a child node to a parent composite or decorator node.
- `LBehaviorTree:setRoot`: Designate a node as the tree's root. Tick evaluation starts here.
- `LBehaviorTree:setLeaf`: Register or replace the callback function for a named leaf. The function must return "success", "failure", or "running".
- `LBehaviorTree:tick`: Execute one tick of the behavior tree from the root. Returns the root node's status.
- `LBehaviorTree:resetState`: Reset the tree's running state. Use between encounters or when restarting AI logic.
- `LBehaviorTree:nodeCount`: Return the total number of nodes in the tree.
- `LBehaviorTree:clearAll`: Remove all nodes and leaf functions, resetting the tree to empty.

### `LBlackboard` Methods
- `LBlackboard:set`: Set a key to a value (boolean, number, string, or nil to clear). Notifies registered watchers if value changed.
- `LBlackboard:get`: Retrieve the value stored under a key. Returns nil if the key does not exist.
- `LBlackboard:has`: Check whether a key exists on the blackboard.
- `LBlackboard:clear`: Remove a single key from the blackboard.
- `LBlackboard:keys`: Return an array of all keys currently stored on the blackboard.
- `LBlackboard:watch`: Register a watcher callback that fires whenever the specified key changes. Use `"*"` to watch all keys.
- `LBlackboard:unwatch`: Remove a previously registered watcher by its ID.
- `LBlackboard:getRevision`: Return the current revision counter. Increments on every value change.
- `LBlackboard:snapshot`: Return a table containing all current key-value pairs as a snapshot. Useful for serialization or debug display.
- `LBlackboard:clearAll`: Remove all keys and values from the blackboard.

### `LCommandStack` Methods
- `LCommandStack:execute`: Execute a named command immediately, recording it in history. Discards any redo history ahead of the current position.
- `LCommandStack:undo`: Undo the most recent command by calling its undo function. Moves the pointer back in history.
- `LCommandStack:redo`: Redo a previously undone command by re-calling its execute function. Moves the pointer forward.
- `LCommandStack:canUndo`: Check whether an undo operation is possible (there is a command with an undo function behind the pointer).
- `LCommandStack:canRedo`: Check whether a redo operation is possible (there are commands ahead of the pointer).
- `LCommandStack:getHistorySize`: Return the total number of commands in the history (both undone and available for redo).
- `LCommandStack:getCurrentName`: Return the name of the most recently executed (or undone-to) command, or nil if history is empty.
- `LCommandStack:clearAll`: Discard all command history and free associated callbacks.

### `LDebounce` Methods
- `LDebounce:onFire`: Set the callback function to invoke when the debounce fires after the wait period.
- `LDebounce:trigger`: Signal input activity. Resets the wait timer so the debounce will fire after the full wait period of inactivity.
- `LDebounce:update`: Advance the debounce timer. If the wait period elapsed since last trigger, fires the callback and returns true.
- `LDebounce:cancel`: Cancel any pending debounce without firing. The callback will not be called until triggered again.
- `LDebounce:isPending`: Check whether the debounce is currently waiting to fire (has been triggered but wait period not yet elapsed).
- `LDebounce:getFireCount`: Return the total number of times this debounce has fired since creation.

### `LEventBus` Methods
- `LEventBus:on`: Subscribe a callback to a named event. Higher priority listeners fire first.
- `LEventBus:off`: Unsubscribe a listener by its subscription ID. Removes the callback from the event bus.
- `LEventBus:emit`: Emit an event, invoking all subscribed listeners in priority order with optional payload arguments.
- `LEventBus:clear`: Remove all listeners subscribed to a specific event name.
- `LEventBus:clearAll`: Remove all listeners from every event on this bus. Resets the bus to empty.
- `LEventBus:getListenerCount`: Return the number of active listeners for a given event name.
- `LEventBus:getEvents`: Return an array of all event names that have at least one listener.

### `LFactory` Methods
- `LFactory:register`: Register a constructor function for a given type name. Future `create()` calls with this type will invoke it.
- `LFactory:create`: Create a new object by type name, passing additional arguments to the constructor.
- `LFactory:has`: Check whether a constructor is registered for the given type name.
- `LFactory:alias`: Create an alias that maps to an existing type name. `create(alias)` will use the canonical constructor.
- `LFactory:getTypes`: Return an array of all registered type names.
- `LFactory:remove`: Unregister a type and discard its constructor function.
- `LFactory:clearAll`: Remove all registered types and constructors, resetting the factory.

### `LFunnel` Methods
- `LFunnel:onFlush`: Set the callback invoked when the funnel flushes. Receives an array of {tag, value} entries.
- `LFunnel:push`: Push a tagged event into the funnel. May trigger an immediate flush if the max entry count is reached.
- `LFunnel:update`: Advance the funnel's time window. Flushes and invokes the callback if the window elapsed.
- `LFunnel:flush`: Force an immediate flush of all pending entries, invoking the callback.
- `LFunnel:discard`: Discard all pending entries without flushing or calling the callback.
- `LFunnel:pendingCount`: Return the number of entries waiting to be flushed.
- `LFunnel:getFlushCount`: Return the total number of times this funnel has flushed since creation.

### `LGraph` Methods
- `LGraph:addNode`: Add a node to the graph with an optional label and payload value.
- `LGraph:removeNode`: Remove a node and all its connected edges. Returns true if the node existed.
- `LGraph:getNodeValue`: Retrieve the payload value stored on a node. Returns nil if no payload.
- `LGraph:addEdge`: Add a directed (or undirected) edge between two nodes with optional weight and label.
- `LGraph:removeEdge`: Remove an edge by its ID. Returns true if it existed.
- `LGraph:neighbors`: Return an array of node IDs directly connected to the given node.
- `LGraph:bfs`: Perform a breadth-first search from a node. Returns visited node IDs in BFS order.
- `LGraph:dfs`: Perform a depth-first search from a node. Returns visited node IDs in DFS order.
- `LGraph:isConnected`: Check whether there is any path from one node to another.
- `LGraph:hasNode`: Check whether a node with the given ID exists in the graph.
- `LGraph:nodeCount`: Return the total number of nodes in the graph.
- `LGraph:edgeCount`: Return the total number of edges in the graph.
- `LGraph:clearAll`: Remove all nodes, edges, and payloads from the graph.

### `LList` Methods
- `LList:add`: Append a value to the end of the list.
- `LList:push`: Append a value to the end of the list (alias for add).
- `LList:unshift`: Insert a value at the beginning of the list.
- `LList:get`: Get the value at a 1-based index. Returns nil if out of range.
- `LList:set`: Replace the value at a 1-based index. Errors if index is 0 or out of range.
- `LList:insert`: Insert a value at a 1-based index, shifting subsequent items right.
- `LList:remove`: Remove and return the value at a 1-based index. Returns nil if out of range.
- `LList:pop`: Remove and return the last value. Returns nil if empty.
- `LList:shift`: Remove and return the first value. Returns nil if empty.
- `LList:indexOf`: Find the 1-based index of the first occurrence of a value. Returns nil if not found.
- `LList:reverse`: Reverse the order of all items in the list in-place.
- `LList:len`: Return the number of items in the list.
- `LList:isEmpty`: Check whether the list is empty.
- `LList:contains`: Check whether the list contains a specific value.
- `LList:clear`: Remove all items from the list.
- `LList:toArray`: Return all items as an array table.

### `LMap` Methods
- `LMap:set`: Set a key-value pair in the map. Replaces any existing value for the same key.
- `LMap:get`: Retrieve the value for a key. Returns nil if the key does not exist.
- `LMap:has`: Check whether a key exists in the map.
- `LMap:remove`: Remove a key from the map. Returns true if it was present.
- `LMap:len`: Return the number of key-value pairs.
- `LMap:isEmpty`: Check whether the map has no entries.
- `LMap:keys`: Return an array of all keys in the map.
- `LMap:values`: Return an array of all values in the map.
- `LMap:entries`: Return an array of {key, value} tables for all entries.
- `LMap:merge`: Copy all entries from another LMap into this map. Existing keys are overwritten.
- `LMap:clear`: Remove all entries from the map.

### `LMediator` Methods
- `LMediator:on`: Register a handler callback on a named channel. Returns an ID for unregistration.
- `LMediator:off`: Unregister a handler from a channel by its ID.
- `LMediator:send`: Send a message to all handlers on a specific channel with optional payload arguments.
- `LMediator:broadcast`: Send a message to all handlers on all channels. Every registered handler receives the payload.
- `LMediator:handlerCount`: Return the number of handlers registered on a specific channel.
- `LMediator:channels`: Return an array of all channel names that have at least one handler.
- `LMediator:removeChannel`: Remove an entire channel and all its handlers.
- `LMediator:clear`: Remove all channels and handlers, resetting the mediator.

### `LObjectPool` Methods
- `LObjectPool:add`: Add an object to the pool's idle set, making it available for future acquisition.
- `LObjectPool:acquire`: Take an idle object from the pool and mark it active. Returns nil if the pool is empty.
- `LObjectPool:release`: Return an active object back to the pool's idle set so it can be reused.
- `LObjectPool:getActiveCount`: Return the number of objects currently checked out from the pool.
- `LObjectPool:getAvailableCount`: Return the number of idle objects ready for acquisition.
- `LObjectPool:getTotalCount`: Return the total number of objects managed by this pool (active + idle).
- `LObjectPool:clearAll`: Destroy all objects (active and idle) and reset the pool to empty.

### `LObserver` Methods
- `LObserver:set`: Set a value by key and notify all subscribers watching that key.
- `LObserver:get`: Retrieve the current value for a key. Returns nil if not set.
- `LObserver:subscribe`: Subscribe to changes on a specific key. The callback receives (key, newValue) on each change.
- `LObserver:unsubscribe`: Remove a subscription by its ID. The callback will no longer fire.
- `LObserver:getCount`: Return the total number of active subscriptions across all keys.

### `LPriorityQueue` Methods
- `LPriorityQueue:push`: Add an item with a numeric priority. Higher priority items are dequeued first.
- `LPriorityQueue:pop`: Remove and return the highest-priority item. Returns nil if the queue is empty.
- `LPriorityQueue:peek`: Return the highest-priority item without removing it. Returns nil if empty.
- `LPriorityQueue:len`: Return the number of items currently in the queue.
- `LPriorityQueue:isEmpty`: Check whether the queue contains no items.
- `LPriorityQueue:clearAll`: Remove all items from the queue.

### `LQueue` Methods
- `LQueue:enqueue`: Add a value to the back of the queue. Returns false if at capacity.
- `LQueue:enqueueFront`: Add a value to the front of the queue (priority insertion). Returns false if at capacity.
- `LQueue:dequeue`: Remove and return the front value. Returns nil if empty.
- `LQueue:dequeueBack`: Remove and return the back value. Returns nil if empty.
- `LQueue:front`: Return the front value without removing it. Returns nil if empty.
- `LQueue:back`: Return the back value without removing it. Returns nil if empty.
- `LQueue:peekAt`: Return the value at a 1-based index without removing it. Returns nil if out of range.
- `LQueue:insertAt`: Insert a value at a 1-based index in the queue. Returns false if at capacity.
- `LQueue:removeAt`: Remove and return the value at a 1-based index. Returns nil if out of range.
- `LQueue:len`: Return the current number of items in the queue.
- `LQueue:isEmpty`: Check whether the queue is empty.
- `LQueue:isFull`: Check whether the queue has reached its capacity limit.
- `LQueue:clear`: Remove all items from the queue.
- `LQueue:toArray`: Return all queue items as an array table (front to back).

### `LRelationshipManager` Methods
- `LRelationshipManager:defineType`: Define a relationship type with named levels (e.g. "friendship" with levels ["hostile", "neutral", "friendly"]).
- `LRelationshipManager:removeType`: Remove a relationship type definition.
- `LRelationshipManager:typeNames`: Return all defined relationship type names.
- `LRelationshipManager:setValue`: Set the numeric relationship value between two entity IDs.
- `LRelationshipManager:getValue`: Get the numeric relationship value between two entity IDs.
- `LRelationshipManager:adjustValue`: Add a delta to the relationship value between two entities.
- `LRelationshipManager:setLevel`: Set the named level for a relationship type between two entities.
- `LRelationshipManager:getLevel`: Get the named level for a relationship type between two entities.
- `LRelationshipManager:removePair`: Remove all relationship data between two entities.
- `LRelationshipManager:pairCount`: Return the total number of tracked entity pairs.

### `LRing` Methods
- `LRing:push`: Push a number or string value into the ring. Overwrites the oldest entry if the ring is full.
- `LRing:latest`: Return the most recently pushed entry as a table with id, tag, value, and text fields. Returns nil if empty.
- `LRing:toArray`: Return all entries in the ring as an ordered array of tables (oldest to newest).
- `LRing:sum`: Return the sum of all numeric values in the ring. Non-numeric entries contribute zero.
- `LRing:average`: Return the arithmetic mean of all numeric values in the ring.
- `LRing:len`: Return the number of entries currently in the ring.
- `LRing:isFull`: Check whether the ring has reached its maximum capacity.
- `LRing:clear`: Remove all entries from the ring.

### `LServiceLocator` Methods
- `LServiceLocator:provide`: Register a service instance under a given name. Replaces any previously registered service with the same name.
- `LServiceLocator:locate`: Retrieve a registered service by name. Returns nil if not found.
- `LServiceLocator:has`: Check whether a service with the given name is currently registered.
- `LServiceLocator:remove`: Unregister and discard a service by name.
- `LServiceLocator:getServices`: Return an array of all registered service names.
- `LServiceLocator:clearAll`: Remove all registered services and reset the locator.

### `LSet` Methods
- `LSet:add`: Add a string to the set. Returns true if it was not already present.
- `LSet:remove`: Remove a string from the set. Returns true if it was present.
- `LSet:has`: Check whether a string is in the set.
- `LSet:len`: Return the number of items in the set.
- `LSet:isEmpty`: Check whether the set is empty.
- `LSet:toArray`: Return all set items as an array table.
- `LSet:clear`: Remove all items from the set.
- `LSet:union`: Return a new set containing all items from both this set and another.
- `LSet:intersection`: Return a new set containing only items present in both this set and another.

### `LSimpleState` Methods
- `LSimpleState:addState`: Register a named state with optional enter, exit, and update callbacks.
- `LSimpleState:transitionTo`: Transition to a new state. Calls the current state's `exit` and the target state's `enter` callbacks.
- `LSimpleState:update`: Call the current state's update callback with the frame delta time.
- `LSimpleState:getCurrent`: Return the name of the currently active state, or nil if no state is set.
- `LSimpleState:hasState`: Check whether a state with the given name is registered.
- `LSimpleState:getStates`: Return an array of all registered state names.
- `LSimpleState:clearAll`: Remove all states and their callbacks, resetting the state machine.

### `LStack` Methods
- `LStack:push`: Push a value onto the top of the stack. Returns false if the stack is at capacity.
- `LStack:pushBottom`: Push a value onto the bottom of the stack. Returns false if at capacity.
- `LStack:pop`: Remove and return the top value. Returns nil if the stack is empty.
- `LStack:popBottom`: Remove and return the bottom value. Returns nil if empty.
- `LStack:popMany`: Pop up to `count` values from the top and return them as an array table.
- `LStack:peek`: Return the top value without removing it. Returns nil if empty.
- `LStack:peekBottom`: Return the bottom value without removing it. Returns nil if empty.
- `LStack:peekAt`: Return the value at a 1-based index without removing it. Returns nil if out of range.
- `LStack:insertAt`: Insert a value at a 1-based index in the stack, shifting items above it. Returns false if at capacity.
- `LStack:removeAt`: Remove and return the value at a 1-based index. Returns nil if out of range.
- `LStack:moveWithin`: Move an item from one 1-based index to another within the stack.
- `LStack:len`: Return the current number of items in the stack.
- `LStack:isEmpty`: Check whether the stack is empty.
- `LStack:isFull`: Check whether the stack has reached its capacity limit (if one was set).
- `LStack:clear`: Remove all items from the stack.
- `LStack:toArray`: Return all stack items as an array table (bottom to top).

### `LStrategy` Methods
- `LStrategy:register`: Register a named strategy implementation function.
- `LStrategy:set`: Switch to a named strategy. Future `execute()` calls will use this implementation.
- `LStrategy:execute`: Execute the currently active strategy, passing through all arguments and returning its results.
- `LStrategy:getCurrent`: Return the name of the currently active strategy, or nil if none set.
- `LStrategy:has`: Check whether a strategy with the given name is registered.
- `LStrategy:remove`: Remove a named strategy. If it was the active strategy, no strategy will be selected.
- `LStrategy:names`: Return an array of all registered strategy names.
- `LStrategy:clear`: Remove all strategies and reset the selection.

### `LThrottle` Methods
- `LThrottle:onFire`: Set the callback function to invoke each time the throttle fires.
- `LThrottle:update`: Advance the throttle timer. If the interval has elapsed, fires the callback and returns true.
- `LThrottle:reset`: Reset the throttle timer back to zero without firing.
- `LThrottle:getProgress`: Return how far through the current interval the throttle is (0.0 to 1.0).
- `LThrottle:getFireCount`: Return the total number of times this throttle has fired since creation.
- `LThrottle:setEnabled`: Enable or disable the throttle. When disabled, update() will not accumulate time.

### `LWeightedRandom` Methods
- `LWeightedRandom:add`: Add an item with a relative weight. Higher weight = higher selection probability.
- `LWeightedRandom:remove`: Remove an item by its ID. Returns true if it existed.
- `LWeightedRandom:setWeight`: Change the weight of an existing entry.
- `LWeightedRandom:pick`: Pick one item using a random sample value in [0, 1). Returns its value or nil.
- `LWeightedRandom:pickN`: Pick multiple unique items. Requires an array of random samples.
- `LWeightedRandom:totalWeight`: Return the sum of all entry weights.
- `LWeightedRandom:len`: Return the number of entries in the pool.
- `LWeightedRandom:isEmpty`: Check whether the pool has no entries.
- `LWeightedRandom:clearAll`: Remove all entries from the pool.
- `LWeightedRandom:getRevision`: Return the revision counter. Increments on any add/remove/weight change.

## References

- No top-level `crate::<module>` imports were detected in this module's Rust source files.

## Notes

- Keep this module reference synchronized with `src/patterns/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
- `Trie` and `BiMap` are **Foundations tier** utility types. Neither is exposed to Lua (`lurek.patterns.*`). They are re-exported from `src/patterns/mod.rs` for use by other engine modules.
