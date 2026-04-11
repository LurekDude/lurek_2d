# patterns

## Module Info
- Module name: `patterns`
- Module group: `Foundations`
- Spec path: `docs/specs/patterns.md`
- Lua API path(s): `src/lua_api/patterns_api.rs`
- Rust test path(s): `tests/rust/unit/patterns_tests.rs`
- Lua test path(s): `tests/lua/unit/test_patterns.lua`; `tests/lua/stress/test_patterns_stress.lua`

## Module Purpose
The `patterns` module owns reusable coordination primitives for Lurek2D gameplay code. It gathers small, pure-Rust building blocks such as event buses, state trackers, queues, registries, object pools, throttles, blackboards, and similar logic helpers that can be shared across many higher-level systems.

This module exists so common gameplay-control patterns do not have to be reimplemented ad hoc in Lua or buried inside unrelated engine modules. Most types here intentionally store only the domain-side bookkeeping and metadata, while the Lua API layer adds callback storage, registry keys, and UserData wrappers on top.

`patterns` intentionally does not own the engine's global event system, ECS state, AI decision policies, or task-graph execution. It provides generic mechanics and containers; feature modules are responsible for deciding when and why to use them.

## Files
- `mod.rs`: Declares the patterns submodules and re-exports the public helper types.
- `blackboard.rs`: Implements a shared typed key-value board with revision tracking for cross-system facts.
- `command_stack.rs`: Tracks undo and redo history metadata, including cursor position and batching state.
- `event_bus.rs`: Implements named event-subscription metadata with priority ordering and one-shot listeners.
- `factory.rs`: Implements a constructor-name registry with optional alias resolution.
- `funnel.rs`: Implements a time-windowed event collector that can batch inputs before flushing.
- `object_pool.rs`: Implements slot bookkeeping for reusable pooled objects, including idle and active tracking.
- `observer.rs`: Implements per-key watcher metadata for reactive property changes.
- `priority_queue.rs`: Implements a stable highest-priority-first queue for small agenda or turn-order workloads.
- `ring.rs`: Implements a fixed-capacity circular history buffer for numeric or string-tagged entries.
- `service_locator.rs`: Implements a named-service presence registry used by the Lua layer to store actual values.
- `simple_state.rs`: Implements a lightweight named-state tracker with a single active state and no validated transition graph.
- `state_machine.rs`: Implements a fuller finite-state machine with registered states, explicit transition rules, and history.
- `throttle.rs`: Implements leading-edge throttle and trailing-edge debounce timers for callback rate limiting.

## Key Types
- `Blackboard`: Shared fact store for lightweight cross-system coordination. It is useful when multiple systems need to read and write the same named state without a direct dependency.
- `BlackboardValue`: Tagged value enum stored inside a `Blackboard`. It keeps the shared state surface small and predictable.
- `CommandStack`: Undo and redo metadata tracker. The Lua layer attaches the actual callbacks, but this type owns the history rules.
- `CommandEntry`: Single recorded command inside a `CommandStack`. It carries the user-visible label and undo capability metadata.
- `EventBus`: Named pub-sub registry that orders listeners by priority. It is the local coordination primitive for systems that need scoped event routing.
- `Subscription`: Metadata record for one event-bus listener. It keeps listener identity, target event, and once behavior explicit.
- `Factory`: Named constructor registry. It helps scripts instantiate families of objects without hard-coding constructor tables everywhere.
- `ObjectPool`: Slot manager for reusable objects. It separates active and idle handles so higher-level code can reduce allocation churn.
- `Observer`: Per-key subscription registry for reactive property changes. Use it when changes should be keyed to specific names rather than free-form events.
- `ObserverEntry`: Metadata for one observer subscription. It tracks watcher identity, watched key, and once semantics.
- `PriorityQueue`: Stable priority queue for small scheduling and agenda workloads. It favors simple predictable ordering over heap complexity.
- `PriorityItem`: Entry stored inside a `PriorityQueue`. It carries priority plus stable insertion sequencing.
- `Ring`: Fixed-capacity rolling history buffer. It is useful for recent-input, combo, telemetry, or score-history style workflows.
- `RingEntry`: One retained ring-buffer entry with optional numeric or string payload and a tag.
- `ServiceLocator`: Named-service registry. The domain type tracks registration while the Lua layer stores the actual service values.
- `SimpleState`: Minimal state tracker with one active named state. It is the simpler choice when callers do not need validated transition rules.
- `StateMachine`: Transition-aware finite-state machine with registered states and visit history. Use it when transition structure matters.
- `TransitionRule`: Declares one allowed transition in a `StateMachine`. It keeps edge validation and optional guard presence explicit.
- `Throttle`: Leading-edge rate limiter that decides when a callback is allowed to fire.
- `Debounce`: Trailing-edge idle timer that delays firing until input settles.
- `Funnel`: Batch collector that groups time-adjacent events before a flush.
- `FunnelEntry`: Single buffered record inside a `Funnel`.