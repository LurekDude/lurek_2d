# Engine Coverage Map — Docs → `src/engine.py`

> **Purpose**: Authoritative traceability from every mechanic documented in `docs/BLOCK-DESIGN.md`
> and `docs/MECHANICS-GUIDE.md` to the exact class / method / line in `src/engine.py`.
>
> **Coverage key**
> | Symbol | Meaning |
> |--------|---------|
> | ✅ | Fully implemented — method/class exists and the mechanic is active |
> | ⚠️ | Partially implemented — core logic present but some YAML fields ignored |
> | ❌ | Not implemented — documented in design but absent from engine |
>
> **Source files**  
> Docs: `docs/BLOCK-DESIGN.md` (v5.0) · `docs/MECHANICS-GUIDE.md`  
> Engine: `src/engine.py`  
> Last audited: 2026-04-03

---

## 1. Infrastructure / Runtime Objects

| Mechanic / Concept | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| Simulation clock (tick → datetime) | `class SimulationClock` | 66–126 | ✅ | `tick_hours`, `advance()`, `set_tick()`, `is_weekend` |
| Work calendar (shift / holiday gate) | `class WorkCalendar` | 128–175 | ✅ | `is_work_time()`, `is_holiday()`, `reason_blocked()` |
| Event logger (JSONL output) | `class EventLogger` | 178–238 | ✅ | Per-file JSONL logging, `event_summary()` |
| Monitor logger (metrics JSONL) | `class MonitorLogger` | 240–257 | ✅ | Separate metrics log stream |
| Alert evaluator | `class AlertEvaluator` | 266–383 | ✅ | `evaluate()`, threshold / rate-of-change conditions |
| Monitor runtime | `class MonitorRuntime` | 386–430 | ✅ | Holds per-monitor state |

---

## 2. Core Data Objects

| Mechanic / Concept | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| **Item** — typed data object | `class Item` | 433–464 | ✅ | `id`, `type`, `data`, `priority`, `born_tick`, `age_ticks`, `audit_trail`, `cost_ledger`, `schema_version`, `saga_id`, `tags` |
| Item audit trail | `Item.stamp()` | 448 | ✅ | Stamped on every process/join/approve/reject |
| Item clone (tap) | `Item.clone()` | 452 | ✅ | Deep copy for tap edges |
| Item schema version | `Item.schema_version` | 438 | ✅ | Default `1`; routable via `schema_version` field |
| Signal object | `class Signal` | 466–474 | ✅ | `name`, `from_block`, `to_block`, `tick` |
| Value entry | `class ValueEntry` | — | ✅ | Inline in logger calls |
| Dead letter entry | `class DeadLetterEntry` | 477–494 | ✅ | `item`, `block_id`, `reason`, `tick`; `to_dict()` |
| In-flight particle | `class Particle` | 497–522 | ✅ | Transit delay (`PARTICLE_TICKS = 4`) |

---

## 3. Container (Queue)

> **Doc ref**: BLOCK-DESIGN §3.3 · MECHANICS-GUIDE s4.3

| Mechanic / Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `capacity` (max items) | `Container.__init__` | 639 | ✅ | `0 = unlimited` |
| `strategy: fifo` | `Container.pop()` | 677 | ✅ | `deque.popleft()` |
| `strategy: lifo` | `Container.pop()` | 677 | ✅ | Reversed append → popleft |
| `strategy: priority` | `Container.pop()` | 677 | ✅ | Sort by `-item.priority`, take top N |
| `overflow: drop_oldest` | `Container.push()` | 656 | ✅ | Remove head item, accept new |
| `overflow: drop_newest` | `Container.push()` | 656 | ✅ | Reject incoming item |
| `overflow: block` | `Container.push()` | 656 | ✅ | Returns `False`; combined with backpressure |
| Container aging | `Container.age_items()` | 692 | ✅ | `escalate_priority_by`, `interval_ticks` |
| Item max-age expiry | `Container.expired_items()` | 700 | ✅ | `max_age_ticks`; expired → DLQ |
| Backpressure flag | `Container._update_bp()` | 725 | ✅ | `bp_active` when `size >= threshold` |
| Qualifying peek/pop | `Container.peek_qualifying()` | 709 | ✅ | Used by skill-requirement check |
| `pool_rules` (min/max per type) | `Container.pool_rules_met()`, `Container.push()` | — | ✅ | `min_to_start` and `max_stockpile` enforced |
| `priority_field` (map values) | `Container._priority_key()`, `Container.priority_field` | — | ✅ | String→integer `priority_map` lookup implemented |

---

## 4. Script System — Trigger Conditions

> **Doc ref**: BLOCK-DESIGN §4 · MECHANICS-GUIDE s5

| Mechanic / Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `fires_on: data` (default) | `BlockRuntime.has_enough_data()` | 876 | ✅ | `container.size >= batch_size` |
| `fires_on: trigger` | `_ProcessingHandler.tick()` | 1094 | ✅ | Fires on `pending_triggers` only |
| `fires_on: both` | `_ProcessingHandler.tick()` | 1094 | ✅ | Both condition required |
| `fires_on: any` | `_ProcessingHandler.tick()` | 1094 | ✅ | Either condition |
| `signal_logic: all` | `_ProcessingHandler.tick()` | 1094 | ✅ | Wait for all expected signal types |
| `signal_logic: any` | `_ProcessingHandler.tick()` | 1094 | ✅ | (default) first signal fires |
| **Multi-step scripts** (`steps:`) | `BlockRuntime._script_steps`, `_ProcessingHandler.tick()` | — | ✅ | All step types implemented: `process`, `wait`, `emit`, `consume`, `delegate`; `depends_on` step deps supported |
| Step type `process` | `_ProcessingHandler.tick()` PROCESSING section | — | ✅ | Duration-based processing step |
| Step type `consume` | `_ProcessingHandler.tick()` | ~1434 | ✅ | Item consumption mid-script |
| Step type `wait` | `_ProcessingHandler.tick()` PROCESSING section | — | ✅ | Tick-based wait step |
| Step type `delegate` | `_ProcessingHandler.tick()` | ~1455 | ✅ | Cross-block delegation step |
| Step type `emit` | `_ProcessingHandler.tick()` PROCESSING section | — | ✅ | Signal emission step |
| `depends_on` (step deps) | `_ProcessingHandler.tick()`, `_step_completed` | ~1402 | ✅ | Step dependency graph with completion tracking |
| `condition.type: accumulate` | `_ProcessingHandler.tick()` | — | ✅ | Accumulate condition checking on steps |
| `condition.type: time_elapsed` | `_ProcessingHandler.tick()` | — | ✅ | Time-elapsed condition checking on steps |
| `condition.type: signal_received` | `_ProcessingHandler.tick()` | — | ✅ | Signal-received condition checking on steps |
| Step `timeout` | `_ProcessingHandler.tick()`, `_step_start_tick` | ~1362 | ✅ | Per-step timeout with `_step_start_tick` tracking |
| `auto_trigger: true` (data-driven) | `_auto_trigger_source()` | 2095 | ⚠️ | `auto_rate` field controls probability; `auto_trigger: true` boolean not explicitly parsed |

---

## 5. Script Fields — Data Requirements

> **Doc ref**: BLOCK-DESIGN §4.3 · MECHANICS-GUIDE s13.1

| Mechanic / Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `requires[].type` + `count` | `BlockRuntime.has_enough_data()` | 876 | ✅ | Batch size acts as `count` check |
| `requires[].attribute` + `min_value` (skill check) | `Container.peek_qualifying()` | 709 | ✅ | Attribute filtering on item data |
| `requires[].attribute` + `exact_value` | `Container.pop_qualifying()` | 716 | ✅ | Exact-match attribute pop |
| `requires_resource.pool` | `GraphEngine._acquire_pool()` | 2430 | ✅ | Acquires slot from `ResourcePool` |
| `requires_resource.slots` | `GraphEngine._acquire_pool()` | 2430 | ✅ | Number of slots to acquire |
| `requires_resource.on_unavailable` | `GraphEngine._acquire_pool()` | 2430 | ✅ | `queue`, `skip`, and `fail` modes implemented |
| `requires_resource.release_on` | `GraphEngine._release_pool()` | 2441 | ✅ | `complete` and `start` release modes implemented |

---

## 6. Signal System

> **Doc ref**: BLOCK-DESIGN §5 · MECHANICS-GUIDE s6

| Mechanic / Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `event_out.on_complete` | `GraphEngine._emit_event()` | 2339 | ✅ | Signal emitted after successful cycle |
| `event_out.on_fail` | `GraphEngine._emit_event()` | 2339 | ✅ | Signal emitted on failure |
| Signal fan-out (one → many) | `GraphEngine._emit_event()` | 2339 | ✅ | Delivered to all connected `trigger_in` blocks |
| Signal delivery (end-of-tick) | `GraphEngine._do_tick()` | 2010 | ✅ | Zero-tick delivery via `_pending_signals` |
| `signal_logic: any` / `all` | `_ProcessingHandler.tick()` | 1094 | ✅ | |
| Signal payload | `Signal.payload`, `GraphEngine._emit_event()` | — | ✅ | `payload` dict carried through signal system |
| `event_out.on_step` | `_ProcessingHandler.tick()` | ~1417 | ✅ | Per-step signal emission during multi-step scripts |

---

## 7. Value System

> **Doc ref**: BLOCK-DESIGN §6 · MECHANICS-GUIDE s7, s13.5, s13.18

| Mechanic / Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `value_cost.amount` | `GraphEngine._emit_value()` | 2386 | ✅ | Cost charged per cycle |
| `value_cost.type` | `GraphEngine._emit_value()` | 2386 | ✅ | Logged as `type` field |
| `value_out.amount` | `GraphEngine._emit_value()` | 2386 | ✅ | Revenue emitted per cycle |
| `value_out.type` | `GraphEngine._emit_value()` | 2386 | ✅ | |
| Value × batch size | `GraphEngine._emit_value()` | 2386 | ✅ | `amount * len(items)` |
| Per-item cost stamp | `Item.stamp()` via `_emit_value()` | 2386/448 | ✅ | `cost_ledger` on item |
| `value_out.formula` | `GraphEngine._evaluate_value_formula()` | 2364 | ✅ | Full arithmetic expression evaluation with variable substitution |
| `value_out.variables` | `GraphEngine._evaluate_value_formula()` | 2364 | ✅ | Variables substituted into formula expressions via safe eval |
| **VALUE_IN aggregation** (composite hierarchy) | `GraphEngine._emit_value()`, `BlockRuntime.value_in_total` | — | ✅ | Child value propagation to parent composite |
| `ValueAccumulatorHandler` | `class ValueAccumulatorHandler` | 1566 | ✅ | Node type `value_accumulator`; sums `value_cost` + `value_out` |
| `cost_stamp` YAML field | `Item.stamp()` via `_cost_stamp_amount()` | — | ✅ | Per-item cost stamping with custom formula support via `_cost_stamp_amount()` |
| `audit_stamp` YAML field | `Item.stamp()` | — | ✅ | Configurable via `audit_stamp.enabled` flag; `audit_stamp_enabled` toggle supported |

---

## 8. Filter / Gate System

> **Doc ref**: BLOCK-DESIGN §7 · MECHANICS-GUIDE s8

| Mechanic / Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `gate_open` flag | `BlockRuntime` (`gate_open`) | 744 | ✅ | API: `update_filter()` |
| `type: backpressure` edge → close gate | `GraphEngine._do_tick()` | 2010 | ✅ | Step 5 of tick loop |
| Filter block routing (`filter:mode: gate`) | `FilterHandler._handle_ready()` | 1529 | ✅ | Evaluates `filter.condition` |
| `filter:mode: route` (route to output ports) | `FilterHandler._handle_ready()` | 1529 | ✅ | `routes` evaluated with output port routing |
| Filter param injection (`filter:mode: param`) | `BlockRuntime.set_params()`, `_do_tick()` step 5b | — | ✅ | Runtime parameter injection via param edges |
| `filter:mode: transform` (field mutation) | `TransformHandler._handle_ready()` | — | ✅ | Transform handler with add/remove/rename/mask operations |

---

## 9. Block States

> **Doc ref**: BLOCK-DESIGN §8 · MECHANICS-GUIDE s9

| State | Engine symbol | Lines | Status |
|---|---|---|---|
| `IDLE` | `BlockState.IDLE` | 399/744 | ✅ |
| `WAITING` | `BlockState.WAITING` | 399/1094 | ✅ |
| `PROCESSING` | `BlockState.PROCESSING` | 399/1094 | ✅ |
| `FAILED` | `BlockState.FAILED` | 399/1392 | ✅ |
| `WARMUP` | `BlockState.WARMUP` | 399/744 | ✅ |
| `MAINTENANCE` | `BlockState.MAINTENANCE` | 399/1094 | ✅ |
| `CB_OPEN` | `BlockState.CB_OPEN` | 399/1094 | ✅ |
| `WAITING_APPROVAL` | `BlockState.WAITING_APPROVAL` | 399/1094 | ✅ |

---

## 10. Node Types (Logical Block Types)

> **Doc ref**: BLOCK-DESIGN §16 · MECHANICS-GUIDE s12, s13.7, s13.8, s13.10

| Type | Engine handler | Lines | Status | Notes |
|---|---|---|---|---|
| `source` | `SourceHandler` | 1076 | ✅ | `_auto_trigger_source()`, schedule, `auto_rate` |
| `sink` | `SinkHandler` | 1082 | ✅ | Receives items, stamps `"received"` |
| `process` | `ProcessHandler` → `_ProcessingHandler` | 1088 | ✅ | Full processing pipeline |
| `router` | `RouterHandler` → `_route_router()` | 1428/2238 | ✅ | Rules: `eq`, `neq`, `gt`, `lt`, `contains`; `default_route` |
| `join` | `JoinHandler` → `_try_join()` | 1438/2293 | ✅ | `join_key`, `wait_for`, merge |
| `composite` | `CompositeHandler` | 1445 | ✅ | `container_mode`, `_find_entry_child()` |
| `fork` | `ForkHandler` | 1452 | ✅ | One item → N copies via particles |
| `gate` | `GateHandler` | 1470 | ✅ | Opens on trigger, queues items when closed |
| `delay` | `DelayHandler` | 1490 | ✅ | `delay_ticks` countdown |
| `merge` | `MergeHandler` | 1508 | ✅ | Buffers until `count_threshold` then forwards batch |
| `filter` | `FilterHandler` | 1527 | ✅ | Expression-based pass/reject with `reject_rate` |
| `transform` | `TransformHandler` | — | ✅ | Full transform handler with field mutation operations |
| `accumulator` | `_ProcessingHandler` + `_check_counter()` | 1094/2453 | ✅ | `count_threshold` fires milestone |
| `counter` | `_ProcessingHandler` + `_check_counter()` | 1094/2453 | ✅ | Same as accumulator — milestone + passthrough |
| `value_accumulator` | `ValueAccumulatorHandler` | 1566 | ✅ | Sums all incoming `value_cost` / `value_out` |
| `dead_letter` | `DeadLetterHandler` | 2468 | ✅ | Dedicated `dead_letter` node type with `DeadLetterHandler` class |
| `tap` (edge type) | `GraphEngine._deliver_to_node()` | 2123 | ✅ | `sample_rate`, `item.clone()` |

---

## 11. Extended Mechanics (s13.1–s13.33)

### s13.1 — Skill Requirement on Data

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `requires[].attribute` + `min_value` | `Container.peek_qualifying()` / `pop_qualifying()` | 709, 716 | ✅ | Attribute-aware queue pop |

---

### s13.2 — Machine Health Degradation and Repair

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `resource.health` initial | `BlockRuntime.__init__` | 744 | ✅ | `health` field |
| `resource.degrade_per_run` | `BlockRuntime.resolve_outcome()` | 888 | ✅ | Decremented per cycle |
| `resource.fail_below` | `BlockRuntime.resolve_outcome()` | 888 | ✅ | Forces `"fail"` when `health <= fail_below` |
| `resource.repair_amount` | `GraphEngine.repair_block()` | 3430 | ✅ | `health += repair_amount` |
| Repair via API | `GraphEngine.repair_block()` | 3430 | ✅ | Flask: `POST /repair` |
| Health log `HEALTH_DEGRADED` | `_ProcessingHandler.tick()` | 1094 | ✅ | |
| Health log `HEALTH_FAILED` | `BlockRuntime.resolve_outcome()` | 888 | ✅ | |

---

### s13.3 — Time-Based Schedule Auto-Trigger

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `schedule.interval_ticks` | `GraphEngine._auto_trigger_source()` | 2095 | ✅ | Modulo check per tick |
| `schedule.start_delay_ticks` | `GraphEngine._auto_trigger_source()` | 2095 | ✅ | Offset before first fire |
| `auto_rate` | `GraphEngine._auto_trigger_source()` | 2095 | ✅ | Probabilistic per-tick firing |
| Work calendar gate on source | `GraphEngine._auto_trigger_source()` | 2095 | ✅ | `WorkCalendar.is_work_time()` |
| `schedule.variation` (random qty) | `_fire_source()`, `_auto_trigger_source()` | — | ✅ | `uniform`, `normal`, `poisson` variation on quantity |
| `data_template` (typed item payload) | `_fire_source()`, `_auto_trigger_source()` | — | ✅ | `data_template:` generates templated item payloads |
| `quantity_range` | `_fire_source()`, `_auto_trigger_source()` | — | ✅ | Random item quantity from `[min, max]` range |

---

### s13.4 — Conditional Event Routing

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `event_out.on_complete` | `GraphEngine._emit_event()` | 2339 | ✅ | |
| `event_out.on_fail` | `GraphEngine._emit_event()` | 2339 | ✅ | |
| `event_out.routes` (condition → signal) | `GraphEngine._emit_event()` | — | ✅ | Conditional signal routing by item data fields |

---

### s13.5 — Value Formula

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `value_out.formula` | `GraphEngine._evaluate_value_formula()` | 2364 | ✅ | Full arithmetic expression evaluation with variable substitution |
| `value_out.variables` | `GraphEngine._evaluate_value_formula()` | 2364 | ✅ | Variables substituted into formula expressions via safe eval |

---

### s13.6 — Data Type Conversion

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `script.converts` (map from→to) | `GraphEngine._apply_conversion()` | 2417 | ✅ | `item.type` remapped after processing |
| `converts.ratio` | `GraphEngine._apply_conversion()` | — | ✅ | Probability-based fractional conversion |

---

### s13.7 — Router Block

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `routes[].field` + `op` + `value` | `GraphEngine._route_router()` | 2238 | ✅ | Supported ops: `eq`, `neq`, `gt`, `lt`, `contains` |
| `routes[].to` | `GraphEngine._route_router()` | 2238 | ✅ | |
| `default_route` | `GraphEngine._route_router()` | 2238 | ✅ | Used when no rule matches |
| No match → DLQ (no `default_route`) | `GraphEngine._route_router()` / `_to_dlq()` | 2238/2468 | ✅ | |

---

### s13.8 — Counter and Accumulator

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `count_threshold` | `GraphEngine._check_counter()` | 2453 | ✅ | Milestone every N items |
| `MILESTONE_REACHED` log + signal | `GraphEngine._check_counter()` | 2453 | ✅ | `threshold_reached` signal emitted |
| Accumulator: hold until `count_threshold` | `MergeHandler._handle_ready()` | 1508 | ✅ | `merge` type accumulates and batch-releases |

---

### s13.9 — Priority Queue

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `container.strategy: priority` | `Container.pop()` | 677 | ✅ | Sort by `-item.priority` |
| `priority_field` YAML (map → int) | `Container._priority_key()`, `Container.priority_field` | — | ✅ | String→integer `priority_map` lookup implemented |

---

### s13.10 — Data Enrichment Join

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `join_key` | `GraphEngine._try_join()` | 2293 | ✅ | Groups items by `item.data[join_key]` |
| `wait_for` (list of types) | `GraphEngine._try_join()` | 2293 | ✅ | |
| Multi-stream merge | `GraphEngine._try_join()` | 2293 | ✅ | First item is base; others contribute `data`, `cost_ledger`, `audit_trail` |
| `join_mode: all_required` | `GraphEngine._try_join()` | 2293 | ✅ | Default behavior |
| `join_mode: majority` / `first_wins` | `GraphEngine._try_join()` | — | ✅ | `majority` and `first_wins` modes implemented |
| `join_timeout_ticks` | `GraphEngine._try_join()` | — | ✅ | Partial join after timeout expiry |

---

### s13.11 — Item Aging, Priority Escalation, and Max-Age Expiry

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `container.aging.interval_ticks` | `Container.age_items()` | 692 | ✅ | |
| `container.aging.escalate_priority_by` | `Container.age_items()` | 692 | ✅ | |
| `container.aging.max_age_ticks` | `Container.expired_items()` | 700 | ✅ | |
| Expired → DLQ | `GraphEngine._do_tick()` + `_to_dlq()` | 2010/2468 | ✅ | `reason: "max_age_exceeded"` |
| `on_expire: dead_letter` | `Container.expired_items()` | 700 | ✅ | Default path |
| `on_expire: emit_event` | `_ProcessingHandler.tick()`, `Container.aging_on_expire` | — | ✅ | Signal emission on item expiry |

---

### s13.12 — Shared Resource Pool

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `resources[].id` + `capacity` | `class ResourcePool` | 525 | ✅ | |
| `try_acquire(slots)` | `ResourcePool.try_acquire()` | 532 | ✅ | Thread-safe atomic acquire |
| `release(slots)` | `ResourcePool.release()` | 539 | ✅ | |
| `RESOURCE_BLOCKED` log | `GraphEngine._acquire_pool()` | 2430 | ✅ | |
| Pool state in `get_state()` | `GraphEngine.get_state()` | 3467 | ✅ | |
| `on_unavailable: skip` | `GraphEngine._acquire_pool()` | — | ✅ | Items skip processing when pool unavailable |
| `on_unavailable: fail` | `GraphEngine._acquire_pool()` | — | ✅ | Items fail when pool unavailable |

---

### s13.13 — Backpressure Propagation

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `container.backpressure.threshold` | `Container._update_bp()` | 725 | ✅ | `bp_active = True` when `size >= threshold` |
| `type: backpressure` edge | `GraphEngine._do_tick()` | 2010 | ✅ | Step 5: `target.gate_open = not source.bp_active` |
| Upstream gate closed on congestion | `_ProcessingHandler.tick()` | 1094 | ✅ | Checked via `gate_open` flag |
| `pause_threshold_pct` / `resume_threshold_pct` | `Container._update_bp()` | — | ✅ | Pause/resume threshold percentages for hysteresis |

---

### s13.14 — Circuit Breaker

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `circuit_breaker.failure_threshold` | `CircuitBreaker.record_failure()` | 608 | ✅ | |
| `circuit_breaker.cooldown_ticks` | `CircuitBreaker.is_allowing()` | 593 | ✅ | |
| States: `closed → open → half_open → closed` | `CircuitBreaker.state` | 590 | ✅ | Full state machine |
| `CB_OPEN` block state | `BlockState.CB_OPEN` | 399 | ✅ | |
| Probe cycle (half-open) | `CircuitBreaker.is_allowing()` | 593 | ✅ | One probe allowed in `half_open` |
| `on_open` / `on_close` events | `CircuitBreaker.on_open_event`, `consume_transition()` | — | ✅ | Signal emission on circuit breaker state transitions |
| `mode: rate` (rate-based tripping) | `CircuitBreaker._outcome_window` | — | ✅ | Rolling window rate-based circuit breaker |

---

### s13.15 — Compensation / Saga

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `saga_id` (block registration) | `GraphEngine._build_nodes()` | 1697 | ✅ | `_saga_blocks[saga_id]` registry |
| Manual trigger via `send_signal()` | `GraphEngine.send_signal()` | 3358 | ✅ | Compensation must be triggered explicitly |
| `compensation.steps` YAML | `_ProcessingHandler.tick()`, `compensation.actions` | — | ✅ | Automatic compensation signal dispatch on failure |
| Saga group state / rollback coordinator | `SagaCoordinator` | — | ✅ | Full saga state coordinator with `SagaCoordinator` class |

---

### s13.16 — Fork / Join (Parallel Split and Barrier)

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| **Fork**: one item → N particles | `ForkHandler._handle_ready()` | 1452 | ✅ | One particle per data edge |
| **Join**: `join_key` + `wait_for` | `JoinHandler._handle_ready()` → `_try_join()` | 1438/2293 | ✅ | |
| Multi-stream data merge | `GraphEngine._try_join()` | 2293 | ✅ | |
| `join_mode: all_required` | `GraphEngine._try_join()` | 2293 | ✅ | Default |
| `join_mode: majority` / `first_wins` | `GraphEngine._try_join()` | — | ✅ | `majority` and `first_wins` modes |

---

### s13.17 — Time Windows

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `time_window.open_ticks` | `BlockRuntime.in_time_window()` | 870 | ✅ | Checked before processing each tick |
| `time_window.period` | `BlockRuntime.in_time_window()` | 870 | ✅ | Modulo period |
| Outside-window → WAITING | `_ProcessingHandler.tick()` | 1094 | ✅ | |
| `outside_window: queue` | `_ProcessingHandler.tick()` | 1094 | ✅ | Default — items queue |
| `outside_window: reject` | `_ProcessingHandler.tick()` | — | ✅ | Reject-to-DLQ mode |
| `outside_window: reroute` | `_ProcessingHandler.tick()` | — | ✅ | Reroute to alternate output |
| Calendar-aware time window (timezone) | `WorkCalendar` | 128 | ✅ | `WorkCalendar` supports business hours + holidays with timezone parsing |

---

### s13.18 — Item Cost Accumulation

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `value_cost.amount` stamped on item | `GraphEngine._emit_value()` | 2386 | ✅ | `item.stamp(block_id, "processed", tick, cost)` |
| `item.cost_ledger` running total | `Item.stamp()` | 448 | ✅ | |
| `item.audit_trail` full history | `Item.stamp()` | 448 | ✅ | |
| `cost_stamp` YAML field | `Item.stamp()` via `_cost_stamp_amount()` | — | ✅ | Per-item cost stamping with custom formula support via `_cost_stamp_amount()` |

---

### s13.19 — Adaptive Concurrency

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `concurrency_cfg.min` / `max` | `BlockRuntime.adapt_concurrency()` | 879 | ✅ | |
| `concurrency_cfg.target_queue` | `BlockRuntime.adapt_concurrency()` | 879 | ✅ | Scale up when `> 2× target`; scale down when `< ½ target` |
| Called every tick | `GraphEngine._tick_block()` | 2084 | ✅ | `rt.adapt_concurrency(size)` |
| `concurrency_cfg.cooldown_ticks` | `BlockRuntime.adapt_concurrency()` | — | ✅ | Cooldown period between adaptive concurrency changes |

---

### s13.20 — Rate Limiter (Token Bucket)

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `rate_limiter.capacity` | `TokenBucket.__init__` | 557 | ✅ | |
| `rate_limiter.refill_rate` | `TokenBucket.tick_refill()` | 563 | ✅ | Per-tick refill |
| `rate_limiter.cost_per_item` | `TokenBucket.try_consume()` | 566 | ✅ | |
| `RATE_LIMITED` log | `_ProcessingHandler.tick()` | 1094 | ✅ | |
| `on_throttle: queue` | `_ProcessingHandler.tick()` | 1094 | ✅ | Default — stay WAITING |
| `on_throttle: drop` | `_ProcessingHandler.tick()` | — | ✅ | Items discarded when rate limited |
| `emit_on_drop` | `_ProcessingHandler.tick()` | — | ✅ | Signal emitted on item drop |

---

### s13.21 — Probabilistic Outcomes

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `fail_chance` | `BlockRuntime.resolve_outcome()` | 888 | ✅ | `random() < fail_chance → "fail"` |
| `reject_rate` | `BlockRuntime.resolve_outcome()` | 888 | ✅ | `random() < reject_rate → "reject"` |
| `outcome_distribution` (weighted outcomes) | `BlockRuntime.resolve_outcome()` | 888 | ✅ | Cumulative probability walk |
| Evaluation order: health → reject → fail → outcomes | `BlockRuntime.resolve_outcome()` | 888 | ✅ | |
| `max_retry` | `_ProcessingHandler.tick()` | 1094 | ✅ | Failed item retried up to N times; then → DLQ |

---

### s13.22 — Audit Trail on Item

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| Automatic stamping at `processed` | `Item.stamp()` | 448 | ✅ | Every cycle |
| Stamp at `rejected` | `GraphEngine._route_rejected()` | 2228 | ✅ | |
| Stamp at `joined` | `GraphEngine._try_join()` | 2293 | ✅ | |
| Stamp at `received` (sink) | `SinkHandler.tick()` | 1082 | ✅ | |
| Stamp at `approved` | `GraphEngine.approve_item()` | 3369 | ✅ | |
| `audit_stamp.enabled` YAML field | `BlockRuntime.audit_stamp_enabled` | — | ✅ | Configurable via `audit_stamp.enabled` YAML flag |
| `audit_stamp.tamper_detect: hash` | `Item.stamp()`, `Item._audit_hash` | — | ✅ | SHA-256 tamper-evident hash chain on audit trail |

---

### s13.23 — Simulation Context and Scenarios

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `simulation.context` initial values | `GraphEngine.__init__` | 1582 | ✅ | `_context` dict initialized from YAML |
| Context injected into new items | `GraphEngine._fire_source()` | 2106 | ✅ | `item.data.update(_context)` |
| Runtime update via API | `GraphEngine.set_context()` | 3442 | ✅ | |
| `GET /context` | `GraphEngine.get_context()` | 3447 | ✅ | |

---

### s13.24 — Dead Letter Queue and Replay

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| DLQ as global holding area | `GraphEngine._dlq` list | 1582 | ✅ | |
| Routes to DLQ: `max_retry`, `approval_rejected`, `no_route_matched`, `max_age_exceeded`, `rejected` | `GraphEngine._to_dlq()` | 2468 | ✅ | |
| DLQ cap (500 entries) | `GraphEngine._to_dlq()` | 2468 | ✅ | Oldest entries dropped |
| `GET /dlq` | `GraphEngine.get_dlq()` | 3451 | ✅ | |
| `POST /dlq/replay` | `GraphEngine.replay_dlq()` | 3402 | ✅ | Pushes item to target container |

---

### s13.25 — Observation Tap

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `type: tap` edge with `sample_rate` | `GraphEngine._deliver_to_node()` | 2123 | ✅ | `random() < sample_rate` → clone to tap target |
| `item.clone()` | `Item.clone()` | 452 | ✅ | Deep copy |
| `ITEM_TAPPED` log | `GraphEngine._deliver_to_node()` | 2123 | ✅ | |
| `transform` on tap (mask PII) | `GraphEngine._deliver_to_node()` | — | ✅ | Mask/add/remove/rename fields on tap clones |

---

### s13.26 — Versioned Item Types

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `item.schema_version` field | `class Item` | 438 | ✅ | Default `1` |
| Routable via `schema_version` field | `RouterHandler` / `_route_router()` | 1428/2238 | ✅ | Router reads `item.data` falling back to `item` attributes |
| Version migration (conversion blocks) | `GraphEngine._apply_conversion()` | 2417 | ✅ | Use `converts` field to remap types |

---

### s13.27 — Human-in-the-Loop Approval Gate

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `human_approval: true` | `BlockRuntime.__init__` | 744 | ✅ | Sets `_approval_items` dict |
| `WAITING_APPROVAL` state | `BlockState.WAITING_APPROVAL` | 399 | ✅ | |
| `APPROVAL_REQUESTED` log | `_ProcessingHandler.tick()` | 1094 | ✅ | |
| `engine.approve_item()` | `GraphEngine.approve_item()` | 3369 | ✅ | Flask: `POST /approve` |
| `engine.reject_approval()` | `GraphEngine.reject_approval()` | 3386 | ✅ | Flask: `POST /reject` |
| `GET /approvals` | `GraphEngine.get_approvals()` | 3455 | ✅ | |
| `human_approval.timeout_ticks` | `_ProcessingHandler.tick()` WAITING_APPROVAL section | — | ✅ | Auto-approve/reject/escalate after timeout |
| `human_approval.notify` (roles) | `_ProcessingHandler.tick()` | ~1823 | ✅ | Notification signals emitted to specified roles |
| `human_approval.escalate_to` | `_ProcessingHandler.tick()` WAITING_APPROVAL section | — | ✅ | Escalation on timeout |

---

### s13.28 — Simulation Clock and Fast-Forward

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `simulation.tick_hours` | `SimulationClock.__init__` | 71 | ✅ | `tick_hours` ratio |
| `simulation.speed` | `GraphEngine.set_speed()` | 1993 | ✅ | Ticks/second control |
| `fast_forward(ticks)` | `GraphEngine.fast_forward()` | 1996 | ✅ | Up to 2000 ticks synchronously |
| `SimulationClock` properties | `SimulationClock` | 66 | ✅ | `current_dt`, `hour`, `weekday`, `is_weekend`, `date_str`, `day_name`, `iso()` |
| `SIMULATION_DAY_CHANGE` event | `GraphEngine._do_tick()` | 2010 | ✅ | |
| `simulation.start_time` (ISO date) | `sim_runner.py`, `sim_parallel.py` | — | ✅ | ISO datetime parsing in sim_runner/sim_parallel → `SimulationClock` |
| Flask: `POST /speed` | `app.py` | — | ✅ | |
| Flask: `POST /fast-forward` | `app.py` | — | ✅ | |

---

### s13.29 — Warmup Period

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `warmup_ticks` | `BlockRuntime.__init__` | 744 | ✅ | `_warmup_remaining = warmup_ticks` |
| `WARMUP` state | `BlockState.WARMUP` | 399 | ✅ | |
| Countdown per tick | `_ProcessingHandler.tick()` | 1094 | ✅ | |
| `WARMUP_COMPLETE` / `BLOCK_WARMUP` logs | `_ProcessingHandler.tick()` | 1094 | ✅ | |
| Warmup restarts after maintenance | `_ProcessingHandler.tick()` | 1094 | ✅ | |

---

### s13.30 — Yield Rate

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `yield_rate` | `_ProcessingHandler._handle_ready()` | 1392 | ✅ | `random() > yield_rate → discard` per item |
| `YIELD_LOSS` log | `_ProcessingHandler._handle_ready()` | 1392 | ✅ | |
| Lost items not sent to DLQ | `_ProcessingHandler._handle_ready()` | 1392 | ✅ | Silent discard |

---

### s13.31 — Preventive Maintenance

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `maintenance_interval` | `_ProcessingHandler.tick()` | 1094 | ✅ | `_ticks_since_maint` counter |
| `maintenance_duration` | `_ProcessingHandler.tick()` | 1094 | ✅ | `_maint_remaining` countdown |
| `MAINTENANCE` state | `BlockState.MAINTENANCE` | 399 | ✅ | |
| `MAINTENANCE_STARTED`, `MAINTENANCE_ACTIVE`, `MAINTENANCE_COMPLETE` logs | `_ProcessingHandler.tick()` | 1094 | ✅ | |
| Warmup after maintenance | `_ProcessingHandler.tick()` | 1094 | ✅ | Re-enters `WARMUP` if `warmup_ticks > 0` |

---

### s13.32 — Block Priority (Tick Execution Order)

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `priority` field on node | `BlockRuntime.__init__` | 744 | ✅ | Default `50` |
| Sorted ascending before each tick | `GraphEngine._do_tick()` | 2010 | ✅ | `sorted(runtimes, key=lambda r: r.priority)` |

---

### s13.33 — Energy Cost

| Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `energy_cost` per active tick | `_ProcessingHandler.tick()` | 1094 | ✅ | Charged on all non-IDLE states |
| `ENERGY_CONSUMED` log | `_ProcessingHandler.tick()` | 1094 | ✅ | |
| `rt.energy_total` accumulator | `BlockRuntime.__init__` | 744 | ✅ | |
| energy_total in `get_state()` | `GraphEngine.get_state()` | 3467 | ✅ | `energy_total` included in summary state dict |

---

## 12. Composite Blocks and Container Modes

> **Doc ref**: BLOCK-DESIGN §11, §15

| Mechanic / Field | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `type: composite` routing | `CompositeHandler._handle_ready()` | 1447 | ✅ | |
| `container_mode: passthrough` | `CompositeHandler._handle_ready()` | 1447 | ✅ | Items sent directly to entry child |
| `container_mode: internal_only` | `CompositeHandler._handle_ready()` | 1447 | ✅ | Default |
| `container_mode: script_only` | `CompositeHandler._handle_ready()` | 1447 | ✅ | |
| `container_mode: script_then_internal` | `CompositeHandler._handle_ready()` | 1447 | ✅ | |
| `container_mode: internal_then_script` | `CompositeHandler._handle_ready()` | 1447 | ✅ | |
| Auto-detect entry child | `GraphEngine._find_entry_child()` | 2324 | ✅ | Node with no incoming data edges from siblings |
| Exit bubble-up (no sibling targets) | `GraphEngine._route_data_output()` | 2198 | ✅ | Output routed to parent composite's outgoing edges |
| `boundary_nodes` (pin to canvas edge) | `GraphEngine._find_entry_child()`, `_route_data_output()` | — | ✅ | Explicit entry/exit pin declarations on composites |
| `value_in` + composite value aggregation | `GraphEngine._emit_value()`, `BlockRuntime.value_in_total` | — | ✅ | Child value propagation to parent composite |
| Drillable composite live-view | — | — | ❌ | UI drill-in (not an engine concern; frontend feature) |

---

## 13. Port System

> **Doc ref**: BLOCK-DESIGN §2

| Port type | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `DATA_IN` / `DATA_OUT` | `GraphEngine._build_edges()` | 1716 | ✅ | Typed item routing via edges |
| `TRIGGER_IN` / `EVENT_OUT` (signals) | `GraphEngine._emit_event()` | 2339 | ✅ | Signal edges dispatched via `_pending_signals` |
| `FILTER_IN` (gate control) | `GraphEngine.update_filter()`, `BlockRuntime.set_params()` | 3419 | ✅ | Binary gate and parameter injection via param edges |
| `VALUE_COST` / `VALUE_OUT` | `GraphEngine._emit_value()` | 2386 | ✅ | Per-block totals tracked |
| `VALUE_IN` (composite aggregation) | `GraphEngine._emit_value()`, `BlockRuntime.value_in_total` | — | ✅ | Child value propagation to parent composite |
| Port metadata enrichment | `GraphEngine._enrich_edge_ports()` et al. | 1804 | ✅ | `from_port`, `to_port` enriched on all edges |

---

## 14. Anomaly System

> **Doc ref**: `docs/ANALYTICS-GUIDE.md` and engine-internal

| Component | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| `class AnomalyRuntime` | `AnomalyRuntime` | 910 | ✅ | Per-anomaly state machine |
| 24 anomaly types | `GraphEngine._anomaly_*` methods | 2482–3096 | ✅ | `flow_resistance`, `pressure_buildup`, `turbulence`, `leakage`, `cavitation`, `thermal_noise`, `heat_buildup`, `entropy_increase`, `phase_transition`, `impedance_mismatch`, `signal_attenuation`, `crosstalk`, `short_circuit`, `brownout`, `quantum_tunneling`, `superposition`, `entanglement`, `observer_effect`, `catalyst`, `corrosion`, `chain_reaction`, `saturation`, `byzantine_failure`, `clock_drift` |
| Pre-tick anomaly effects | `GraphEngine._anomaly_pre_tick()` | 2482 | ✅ | Modifies fail_chance, processing_ticks, auto_rate |
| Post-tick anomaly effects | `GraphEngine._anomaly_post_tick()` | 2524 | ✅ | |
| Anomaly condition evaluation | `AnomalyRuntime._eval_condition()` | 965 | ✅ | Threshold, rate-of-change, state-based triggers |
| Anomaly expiry | `AnomalyRuntime._eval_expiry()` | 1009 | ✅ | |

---

## 15. Monitor System

> **Doc ref**: `docs/ANALYTICS-GUIDE.md`

| Component | Engine symbol | Lines | Status | Notes |
|---|---|---|---|---|
| Monitor execution loop | `GraphEngine._run_monitors()` | 3097 | ✅ | Runs each monitor per tick |
| 21 monitor types | `GraphEngine._monitor_*` methods | 3143–3342 | ✅ | `queue_depth`, `state`, `throughput`, `latency`, `health`, `concurrency`, `error_rate`, `edge_flow`, `particle`, `backpressure`, `bottleneck`, `cost`, `revenue`, `efficiency`, `signal`, `circuit_breaker`, `resource_pool`, `resource_contention`, `dlq`, `approval_queue`, `anomaly` |
| Alert evaluation | `AlertEvaluator.evaluate()` | 313 | ✅ | Threshold + rate-of-change alerts |
| Monitor JSONL log | `MonitorLogger` | 240 | ✅ | |

---

## 16. Flask API Surface

> **Doc ref**: `app.py`

| Endpoint | Purpose | Status |
|---|---|---|
| `POST /start` | Start simulation | ✅ |
| `POST /stop` | Stop simulation | ✅ |
| `GET /state` | Full engine state snapshot | ✅ |
| `GET /events` | SSE event stream | ✅ |
| `POST /speed` | Set tick speed | ✅ |
| `POST /fast-forward` | Skip N ticks | ✅ |
| `POST /trigger` | Manually trigger a block | ✅ |
| `POST /signal` | Send named signal to block | ✅ |
| `POST /repair` | Repair degraded block | ✅ |
| `GET /context` / `POST /context` | Get/set simulation context | ✅ |
| `GET /dlq` | Inspect dead letter queue | ✅ |
| `POST /dlq/replay` | Replay DLQ item | ✅ |
| `GET /approvals` | List pending approvals | ✅ |
| `POST /approve` | Approve item | ✅ |
| `POST /reject` | Reject item | ✅ |
| `GET /config` | Return loaded YAML config | ✅ |

---

## 17. Resolved Gaps — All Implemented

All 28 gaps identified in the original audit have been implemented. The table below shows the resolution and validation test for each.

| # | Gap | Resolution | Test |
|---|---|---|---|
| G-01 | Multi-step scripts | All step types: `process`, `wait`, `emit`, `consume`, `delegate`; `depends_on` deps | test_77–85 |
| G-02 | VALUE_IN aggregation | Child value propagation to parent composite via `_emit_value()` | test_74 |
| G-03 | `pool_rules` | `min_to_start` and `max_stockpile` in `Container` | test_58 |
| G-04 | `simulation.start_time` | ISO datetime parsing in sim_runner/sim_parallel | test_51 |
| G-05 | Filter param injection | `BlockRuntime.set_params()` via param edges | test_67 |
| G-06 | `data_template` / `quantity_range` / `variation` | Source generates templated items with random quantities | test_68 |
| G-07 | `event_out.routes` | Conditional signal routing by item data fields | test_69 |
| G-08 | `human_approval.timeout_ticks` | Auto-approve/reject/escalate after timeout | test_70 |
| G-09 | `converts.ratio` | Probability-based fractional conversion | test_59 |
| G-10 | `join_mode` | `majority` and `first_wins` modes | test_60 |
| G-11 | `join_timeout_ticks` | Partial join after timeout expiry | test_61 |
| G-12 | `boundary_nodes` | Explicit entry/exit pin declarations on composites | test_75 |
| G-13 | `on_expire: emit_event` | Signal emission on item expiry | test_53 |
| G-14 | CB `mode: rate` | Rolling window rate-based circuit breaker | test_62 |
| G-15 | `on_throttle: drop` | Rate limiter item discard mode | test_63 |
| G-16 | `outside_window: reject/reroute` | Time window reject-to-DLQ and reroute modes | test_64 |
| G-17 | Audit hash chain | SHA-256 tamper-evident hash chain on audit trail | test_71 |
| G-18 | `tap.transform` | Mask/add/remove/rename fields on tap clones | test_72 |
| G-19 | Signal payload | Payload dict carried through signal system | test_52 |
| G-20 | `priority_map` | String→integer priority mapping in container | test_55 |
| G-21 | `value_out.formula` | Full arithmetic expression evaluation with variables | test_73 |
| G-22 | CB `on_open`/`on_close` events | Signal emission on circuit breaker transitions | test_54 |
| G-23 | Saga compensation DSL | Automatic compensation signal dispatch on failure | test_76 |
| G-24 | `on_unavailable: skip/fail` | Resource acquisition failure modes | test_65 |
| G-25 | `release_on: start` | Early resource release after acquisition | test_66 |
| G-26 | `concurrency_cfg.cooldown_ticks` | Cooldown between adaptive concurrency changes | test_56 |
| G-27 | BP hysteresis | Pause/resume threshold percentages | test_57 |
| G-28 | `data_template.quantity_range` | Combined with G-06 | test_68 |

| G-29 | `step type: consume` | Item consumption mid-script in `_ProcessingHandler.tick()` | test_78 |
| G-30 | `step type: delegate` | Cross-block delegation in `_ProcessingHandler.tick()` | test_79 |
| G-31 | `depends_on` (step deps) | Step dependency graph with `_step_completed` tracking | test_80 |
| G-32 | `condition.type: accumulate` | Accumulate condition on steps | test_81 |
| G-33 | `condition.type: time_elapsed` | Time-elapsed condition on steps | test_82 |
| G-34 | `condition.type: signal_received` | Signal-received condition on steps | test_83 |
| G-35 | Step `timeout` | Per-step timeout with `_step_start_tick` tracking | test_84 |
| G-36 | `event_out.on_step` | Per-step signal emission during multi-step scripts | test_85 |
| G-37 | `human_approval.notify` | Notification signals emitted to specified roles | test_86 |
| G-38 | `cost_stamp` formula | Custom formula-based cost stamping via `_cost_stamp_amount()` | test_87 |
| G-39 | `filter:mode: route` | Output port routing in filter handler | test_88 |
| G-40 | `audit_stamp.enabled` | Configurable audit stamp toggle | test_89 |
| G-41 | `dead_letter` node type | Dedicated `DeadLetterHandler` class | test_90 |
| G-42 | Saga coordinator | Full saga state coordinator with `SagaCoordinator` class | test_91 |
| G-43 | Calendar-aware timezone | Timezone parsing in `WorkCalendar` | test_92 |
| G-44 | `energy_total` in state | `energy_total` surfaced in `get_state()` summary | test_93 |

### Remaining Deferred Items

- Drillable composite live-view (UI feature — frontend concern)

---

*Generated by audit: `docs/BLOCK-DESIGN.md` v5.0 + `docs/MECHANICS-GUIDE.md` mapped to `src/engine.py` (2026-04-03, updated 2026-04-03 — all gaps resolved).*
