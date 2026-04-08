# Rust Module Design — `src/blocksim/`

> See also: [ARCHITECTURE.md](ARCHITECTURE.md) · [LUA-API-DESIGN.md](LUA-API-DESIGN.md)

---

## 1. Design Principles

- **No heap allocation in the hot tick loop.** Block queues, item pools, resource ledgers, and monitor buffers are all pre-allocated from `SimSpec` at compile time. The tick loop only swaps pointers and updates counters.
- **Deterministic by construction.** Given identical spec and identical external inputs (approval resolutions, anomaly injections), two runs with the same seed must produce identical event logs and monitor samples.
- **No Lua in the tick loop.** The bridge calls Rust once per step via `luna.sim.step(n)`. Rust returns after `n` ticks. All script-level logic inside blocks uses a typed `ScriptTable` that the compiler resolves to enum-driven Rust code, not Lua closures.
- **Headless always.** Zero dependency on `SharedState`, wgpu, winit, rodio, or any OS display handle.
- **Errors via `SimError`.** All error paths return `SimError` variants; the bridge converts them to `LuaError::external` at the boundary.

---

## 2. Core Types

### 2.1 SimSpec

The validated, normalized representation of a simulation graph. Created by parsing Lua tables (from the bridge) or TOML text (via `luna.data.parseToml`). Immutable after construction.

```
SimSpec {
    blocks:     Vec<BlockSpec>
    edges:      Vec<EdgeSpec>
    monitors:   Vec<MonitorSpec>
    anomalies:  Vec<AnomalySpec>
    resources:  Vec<ResourceSpec>
    config:     SimConfig
}

BlockSpec {
    id:            String
    block_type:    BlockType
    block_class:   Option<String>       -- metadata only, no behavioral effect
    item_types:    Vec<String>          -- accepted item type filter
    ports:         Vec<PortSpec>
    container:     ContainerSpec
    script:        Option<ScriptSpec>
    circuit_breaker: Option<CircuitBreakerSpec>
    rate_limiter:  Option<RateLimiterSpec>
    time_window:   Option<TimeWindowSpec>
    resources:     Vec<ResourceRef>
    approval:      Option<ApprovalSpec>
    mechanics:     Vec<Mechanic>
}

PortSpec {
    id:        String
    side:      PortSide          -- Left | Right
    kind:      PortKind          -- Data | Trigger | Filter | Value | Event
    cardinality: Cardinality     -- One | Many
}

EdgeSpec {
    id:     String
    from:   PortRef              -- (block_id, port_id)
    to:     PortRef
    kind:   EdgeKind             -- Data | Value | Signal | Filter
}
```

### 2.2 ExecutionPlan

The compiled form of a `SimSpec`. Produced by `compiler.rs`. All strings are resolved to indices. Composites are flattened. Execution order is topologically sorted.

```
ExecutionPlan {
    nodes:         Vec<CompiledBlock>
    edges:         Vec<CompiledEdge>
    topo_order:    Vec<usize>       -- index into nodes, execution order per tick
    value_paths:   Vec<ValuePath>   -- pre-computed VALUE edge roll-up paths
    composite_map: HashMap<BlockId, CompositeScope>
    monitor_probes: Vec<MonitorProbe>
    anomaly_targets: HashMap<AnomalyId, AnomalyTargetRef>
}
```

### 2.3 SimRuntime

The live state of a running simulation. Created from an `ExecutionPlan`. All mutable state lives here.

```
SimRuntime {
    plan:          Arc<ExecutionPlan>
    clock:         SimClock
    queues:        QueueSet             -- per-block queues, indexed by CompiledBlock.id
    resource_pool: ResourceLedger
    anomaly_engine: AnomalyEngine
    monitor_engine: MonitorEngine
    approval_queue: ApprovalQueue
    dlq:            DeadLetterQueue
    circuit_breakers: Vec<CircuitBreakerState>
    event_log:      EventLog
    stats:          RunStats
}
```

### 2.4 Items

Items are the tokens of work flowing through the graph. They are typed, carry optional payload fields, and have a unique run-time id.

```
SimItem {
    id:         ItemId          -- u64, monotonic per run
    item_type:  InternedStr     -- resolved from spec at compile time
    payload:    ItemPayload     -- enum: None | Numeric(f64) | Tagged(SmallVec) | Composite(Box<ItemPayload>)
    origin:     BlockId         -- which block generated or re-emitted this item
    tick:       u64             -- tick at which item was created
}
```

### 2.5 BlockType enum

All supported block behaviors are encoded as strongly typed Rust variants. No arbitrary script execution — the compiler maps the spec's `type` field to one of these:

```
BlockType {
    Source,           -- emits items at a rate or on trigger
    Sink,             -- consumes items
    Transform,        -- 1:1 modification of item payload
    Gate,             -- conditional pass/block based on filter
    Router,           -- distributes items across output ports
    Splitter,         -- duplicates items to multiple outputs
    Merger,           -- collects from multiple inputs
    Buffer,           -- accumulates items up to capacity
    Batch,            -- collects N items then releases as group
    Timer,            -- emits items on clock intervals
    Counter,          -- counts items, optionally emits on threshold
    Resource,         -- acquires/releases from resource pool
    ValueAccumulator, -- accumulates value from VALUE edges
    Approver,         -- holds item until external approval
    Replayer,         -- re-injects DLQ items on command
    CompositeIn,      -- composite boundary: input wall
    CompositeOut,     -- composite boundary: output wall
    BlackBox,         -- opaque: input → fixed delay → same output
    RateLimit,        -- token-bucket or leaky-bucket governor
    CircuitBreaker,   -- three-state breaker managing downstream calls
    Priority,         -- priority queue ordering before downstream
    Maintenance,      -- scheduled downtime / offline periods
}
```

### 2.6 Mechanic enum

Extended mechanics are opt-in behaviors that augment a block's base type. Stacking is allowed; order matters.

```
Mechanic {
    Backpressure { threshold: usize, policy: BackpressurePolicy },
    TimeWindow { start: Time, end: Time, timezone: Option<Tz> },
    Warmup { items_needed: usize },
    Yield { probability: f64, seed: u64 },
    ConcurrencyLimit { max: usize },
    Energy { cost: f64, budget: f64 },
    ShadowMode { target_port: PortRef },
    CanaryMode { fraction: f64 },
    Replay { source: DlqRef },
    SchemaVersion { version: u32, router: SchemaRouter },
    Priority { field: String, direction: SortDirection },
    Bulkhead { max_concurrent: usize },
}
```

---

## 3. The Tick Pipeline

Each call to `SimRuntime::tick()` runs these 8 phases in order. Each phase iterates over `topo_order`.

| Phase | Name | What happens |
|---|---|---|
| 1 | `clock_advance` | Increment tick counter; evaluate calendar events; advance fast-forward multiplier |
| 2 | `anomaly_eval` | Evaluate inactive anomalies against trigger conditions; activate matching ones; expire active ones past their window |
| 3 | `circuit_check` | Evaluate circuit breaker half-open probes; transition states |
| 4 | `rate_limit` | Refill token buckets; check per-tick throughput against limiters |
| 5 | `block_exec` | For each block in topological order: dequeue eligible items, apply filters, execute block type logic, enqueue outputs, log events |
| 6 | `resource_release` | Release any resource locks held by items that completed this tick |
| 7 | `value_rollup` | Aggregate VALUE edge contributions up through composite hierarchies |
| 8 | `monitor_sample` | For each active monitor probe: read resolved state, compute sample, push to MonitorSample buffer; evaluate alert thresholds |

### Phase 5 detail: block execution loop

For each block in `topo_order`:
1. Check circuit breaker state → if OPEN, skip (items stay in queue)
2. Check time window → if outside window, skip
3. Check maintenance schedule → if in downtime, skip
4. Dequeue up to `container.capacity` items from input queues
5. Apply filter chain → may transform, drop, or route items
6. Execute `BlockType` logic:
   - For `Gate`: evaluate condition; pass or hold
   - For `Transform`: apply payload transformation
   - For `Batch`: accumulate until batch_size; emit batch or wait
   - For `Resource`: acquire resource lock; release on completion
   - For `Approver`: emit `ApprovalRequest`; hold item in approval queue
   - For `Composite*`: delegate to inner scope
   - etc.
7. Apply `Mechanic` stack in declaration order
8. Enqueue output items on target port queues
9. Apply anomaly effects if any active anomaly targets this block
10. Log `BLOCK_EXEC` event with item_count, tick, block_id

---

## 4. Anomaly Engine

### State machine per anomaly

```
Inactive → (trigger fires) → Active → (expiry condition met) → Expired
                                    → (cascade target fires) → Cascade → Active(new)
                                    → (circuit breaker OPEN) → Blocked
```

### Effect model

Anomalies do not execute arbitrary code. Their effects are constrained to:

| Effect system | What can be mutated |
|---|---|
| `block_state` | pause, drain, drop-all, offline a block |
| `script_param` | override a numeric or string param in block's ScriptSpec |
| `data` | corrupt or replace a specific item payload field |
| `signal` | inject a synthetic event into the event log |
| `value` | offset or multiply a value flowing through a specific edge |
| `filter` | temporarily force a filter to pass=all or pass=none |
| `container` | reduce or expand queue capacity |
| `port` | close/open a port (block that port from accepting new items) |

### Log events

- `ANOMALY_ACTIVATED { id, tick, trigger_reason }`
- `ANOMALY_EFFECT { id, tick, target, mutation }`
- `ANOMALY_BLOCKED { id, tick, blocked_by }`
- `ANOMALY_EXPIRED { id, tick, expiry_reason }`
- `ANOMALY_CASCADE { id, tick, triggered_anomaly_id }`

---

## 5. Monitor Engine

### Design constraints

- Monitor components are **read-only**. They never call `tick()` methods or mutate simulation state.
- All sampling happens at **end of tick**, after phase 8 of the tick pipeline.
- Monitor samples go into a **separate buffer** from the event log. They are not mixed.
- The buffer is a `Vec<MonitorSample>` with a configurable max-samples cap. When full, oldest samples drop (ring buffer).

### Monitor types (21 supported)

| Monitor type | What it samples |
|---|---|
| `queue_depth` | Item count in named queue at tick end |
| `throughput` | Items processed per tick by a block |
| `processing_time` | Moving average of ticks from dequeue to emit |
| `utilization` | Fraction of ticks a block was active vs idle |
| `resource_occupancy` | Fraction of resource pool in use |
| `error_rate` | ANOMALY_EFFECT events / total ticks in window |
| `backpressure_rate` | Fraction of ticks a block held items due to backpressure |
| `circuit_state` | Circuit breaker state sequence (CLOSED/OPEN/HALF_OPEN) |
| `value_flow` | Sum of VALUE edges arriving at a block per tick window |
| `dlq_depth` | DLQ item count at tick end |
| `approval_wait` | Items currently held in approval queue |
| `batch_fill` | Current batch accumulator as fraction of batch_size |
| `yield_rate` | Observed pass/fail fraction against configured probability |
| `energy_consumed` | Cumulative energy cost this run |
| `rate_limit_headroom` | Token bucket fill fraction |
| `anomaly_active` | Binary: is a named anomaly currently active |
| `cascade_count` | Total cascade activations per named anomaly since run start |
| `port_flow` | Items sent/received per named port per tick |
| `composite_boundary` | Items crossing composite boundary per tick |
| `event_rate` | Named event occurrences per window |
| `custom` | Lua-defined selector (sampled in Rust via registered probe function) |

### `MonitorSample` type

```
MonitorSample {
    monitor_id: InternedStr
    tick:       u64
    target:     Option<BlockId>
    value:      SampleValue     -- enum: Count(u64) | Rate(f64) | State(String) | Pair(f64, f64)
    alert:      Option<AlertFired>
}

AlertFired {
    rule:      String
    threshold: f64
    actual:    f64
    severity:  AlertSeverity   -- Info | Warn | Critical
}
```

---

## 6. DLQ and Replay

Items that cannot be routed — due to filter rejection, schema mismatch, or `dlq_on_error` policy — are captured to the `DeadLetterQueue`. The DLQ is a bounded `VecDeque<DlqEntry>` with a configurable max depth.

```
DlqEntry {
    item:       SimItem
    tick:       u64
    reason:     DlqReason         -- FilterReject | SchemaVersion | PortClosed | CapacityExceeded | AnomalyDrop
    origin:     BlockId
    destination: BlockId
}
```

Replay injects a DLQ entry back into the target block's input queue as if it arrived fresh. Replay respects filter rules and circuit breaker state. Events are logged as `DLQ_CAPTURED` and `DLQ_REPLAYED`.

---

## 7. Checkpoint and Deterministic Replay

A checkpoint is a serialized snapshot of the full `SimRuntime` state at a specific tick. The serialization format is internal (not a stable public format).

```
Checkpoint {
    tick:          u64
    queue_state:   Vec<QueueSnapshot>
    resource_state: Vec<ResourceSnapshot>
    anomaly_state: Vec<AnomalyStateSnapshot>
    circuit_state: Vec<CircuitBreakerStateSnapshot>
    clock_state:   ClockSnapshot
    approval_state: Vec<ApprovalSnapshot>
    dlq_state:     Vec<DlqEntry>
    rng_state:     RngState        -- for deterministic random mechanics
}
```

Two runs starting from the same `Checkpoint` with the same `ExecutionPlan` and same external inputs must produce identical output. This is a hard design requirement, not a soft goal.

---

## 8. Error Types

```
SimError {
    SpecParseFailed(String),
    ValidationError { field: String, message: String },
    CompilationFailed { reason: String },
    UnknownBlockId(String),
    UnknownPortId(String),
    TypeMismatch { expected: String, actual: String },
    CapacityExceeded { block_id: String, queue: String },
    ResourceNotAvailable { resource_id: String },
    ApprovalNotFound(ApprovalId),
    DlqFull,
    CheckpointCorrupt,
    ReplayFailed(String),
    AnomalyTargetNotFound(String),
    MonitorProbeFailed(String),
    RuntimePanic(String),    -- wraps recoverable panics; should be rare
}
```

All `SimError` variants convert to `LuaError::external` at the bridge boundary.
