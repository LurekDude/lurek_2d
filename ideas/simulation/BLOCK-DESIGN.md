# Block Graph Simulator — Core Block Design

> **Status**: Design v5.0 — left/right port model, VALUE_IN (⊕) aggregation port,
> layered composability (L0 atomic — LN composite), custom data types, pool constraints,
> multi-step scripts with delegation, container processing modes, logical block types.
> Restructured: domain blueprints → DOMAIN-BLUEPRINTS.md, visualization → VISUALIZATION-GUIDE.md,
> full mechanics reference → MECHANICS-GUIDE.md.
> This document is the source of truth for block anatomy, port semantics, and engine mechanics.

---

## 1. Philosophy

### 1.1 The core idea

The simulator models **business processes as networks of blocks**.
Each block has one strict contract: items arrive on the **LEFT side** (inputs), work happens
inside, results leave from the **RIGHT side** (outputs). Flow always runs left → right —
from raw input through processing to delivered value.

Everything is expressed in one vocabulary: **data — signal — value — filter — script**.

### 1.2 Building from simple to complex

The most powerful idea in the design is **composability**: blocks are built from blocks.
You start with the smallest useful pieces and assemble them into progressively larger ones.

**Layer 0 — Atomic blocks** are indivisible. Each contains a real SCRIPT (⬡) that does one job:
a `programmer` writes one task, a `stamping_press` stamps one part, a `compliance_check` calls one
API endpoint. Atomic blocks are the **vocabulary** — every more complex block is spelled with them.

**Layer 1 — Simple composites** package a group of atomic blocks into a single reusable unit.
A `dev_team` composite might contain `estimator` + `coder` + `reviewer` atomic blocks.
From the outside it looks and behaves **exactly like any other block**: ports on left and right,
value emitted, signals fired. The inner structure is hidden until you explicitly drill in.

```
  dev_team (Layer-1 composite) shown from outside:
  ─────────────────────────────────────────────────────────────────────
  ▲ trigger_in.sprint_start          ▼ event_out.sprint_done
  ◇ filter_in.velocity        [subgraph]      ⊖ value_cost  (team salary/sprint)
  □ in: feature                      ○ value_out.story_points_shipped
                                          □ out: deployed_feature
```

**Layer 2 — Composites of composites** group Layer-1 blocks into a department or system.
A `software_department` might contain `dev_team` + `qa_team` + `ops_team`.
Each inner composite hides its own sub-teams. The department looks like **one single block**
to the delivery director. Drill in twice to reach individual programmers.

**Layer N** — there is no depth limit. Production models routinely use 4—5 layers:

| Layer | Contents              | Real-world examples                       |
|-------|-----------------------|-------------------------------------------|
| L0    | Atomic (has SCRIPT)   | programmer, machine, API call, check       |
| L1    | Group of L0           | team, production cell, microservice       |
| L2    | Group of L1           | department, factory floor, backend        |
| L3    | Group of L2           | business unit, manufacturing site        |
| L4+   | Group of L(n-1)       | company, enterprise, value chain          |

Design **top-down** (define what each layer exposes as ports) and build **bottom-up** (start
with atomic blocks, verify them, then wrap them into composites layer by layer).

### 1.3 How containers connect layers

Every block — atomic or composite — has an **internal container** (queue) at its entry.
Items land in this queue and wait until the SCRIPT's conditions are met.

In a composite, the container chain looks like this:

```
 Parent graph sends item
         |
         v
 [LEFT boundary wall]
         |   (no buffer here — boundary IS the wire into the first inner block)
         v
 [Inner block A: container] ---(SCRIPT fires)---> output
         |
         v
 [Inner block B: container] ---(SCRIPT fires)---> output
         |
         v
 [RIGHT boundary wall]
         |
         v
 Parent graph receives item
```

Each inner block **queues independently**:
- If block B is slow, items build up in **B's own queue** — block A sees no slowdown.
- Backpressure, aging, overflow, and priority rules apply **per block at every layer**.
- A bottleneck shows as a visually full queue **on the exact slow block** in the UI.
- Composite boundaries do not add an extra queue: the boundary wire goes directly into the
  first inner block's container.

Drilling into any composite in the live simulation shows real-time queue depths for every
inner block simultaneously.

### 1.4 How value flows up through layers

Each atomic block emits value when its script fires:

- **VALUE_COST (⊖)** — the running cost (labor time, machine time, API fee, energy)
- **VALUE_OUT (○)** — revenue or savings produced

Those outputs connect to the parent composite's **VALUE_IN (⊕)** port on the LEFT.
The composite sums incoming value and re-emits the total through its own ⊖/○ to the layer above.

```
 [coder]    ⊖ cost:50  ───────┐
 [reviewer] ⊖ cost:30  ───────┤
 [tester]   ⊖ cost:40  ───────┤──> dev_team ⊕VALUE_IN ──> aggregate ──> ⊖ cost:120
                                   │                                             ○ value:200
 [coder]    ○ value:200 ──────┘
```

At the top-level graph, the P&L of the entire nested operation is visible as a single pair
of numbers on the root composite's ⊖/○ output ports.

---

## 2. Port Types

Every block follows one strict rule: **left side = inputs, right side = outputs**.
The graph flows **left → right**. Port **shape** signals the kind at a glance.
Multiple ports of the same kind are allowed — each gets a distinct `id`.

| Port kind  | Symbol | Shape        | Side   | Multiplicity         | Direction     |
| ---------- | ------ | ------------ | ------ | -------------------- | ------------- |
| DATA_IN    | □      | Square       | LEFT   | 0..N  (one per type) | In            |
| TRIGGER_IN | ▲      | Triangle     | LEFT   | 0..N  (each named)   | In            |
| FILTER_IN  | ◇      | Diamond      | LEFT   | 0..N  (each named)   | In            |
| VALUE_IN   | ⊕      | Plus-circle  | LEFT   | 0..N  (each named)   | In (value)    |
| DATA_OUT   | □      | Square       | RIGHT  | 0..N  (one per type) | Out           |
| EVENT_OUT  | ▼      | Triangle     | RIGHT  | 0..N  (each named)   | Out           |
| VALUE_COST | ⊖      | Minus-circle | RIGHT  | 0..1                 | Out (cost)    |
| VALUE_OUT  | ○      | Circle       | RIGHT  | 0..N  (each named)   | Out (value)   |
| SCRIPT     | ⬡      | Hexagon      | CENTER | 1 (internal)         | Internal only |

### Left side — inputs (top → bottom)

1. **TRIGGER_IN** (▲) — one or more named trigger inputs.
   Names like `start`, `override`, `heartbeat`, `reset` let different upstream blocks address
   distinct behavioral responses in the same block. `start` may require a full queue to fire;
   `override` can force immediate execution; `heartbeat` proves the block is alive.
   All TRIGGER_IN ports sit at the top of the left edge.

2. **FILTER_IN** (◇) — one or more named filter inputs.
   A filter can do three things independently: **gate** items (only let matching items through),
   **transform** items (set fields, derive values, add metadata), or **inject script parameters**
   (change quality thresholds, batch sizes, routing tables at runtime without redeploying).
   Using multiple filter inputs lets different controller blocks manage different aspects: one injects
   the quality policy, another injects the current SLA schedule.

3. **DATA_IN** (□) — one per incoming data type.
   The data type name is the port identity. A block with `data_in: [order, component]` has two
   square ports: one labelled `order`, one labelled `component`. Items enter the block’s container queue.

4. **VALUE_IN** (⊕) — receives aggregated value flows from child blocks.
   Primarily used by **composite blocks**: inner blocks' VALUE_COST (⊖) and VALUE_OUT (○)
   wires connect here. The composite sums all incoming value and re-emits the aggregate
   through its own ⊖/○ output ports to the layer above.
   Atomic blocks rarely need VALUE_IN unless they explicitly model a cost-roll-up step.
   Multiple named ids separate cost streams: e.g. `labor`, `material`, `api_fees`.

### Right side — outputs (top → bottom)

1. **EVENT_OUT** (▼) — one or more named output signals.
   Signals carry no payload — they just propagate "something happened" to downstream triggers.
   Multiple named events cover distinct outcomes: `done` for success, `failed` for error, `sla_breach`
   for latency warnings, `alert` for monitoring hooks. A downstream block subscribes by signal name on
   its TRIGGER_IN. One event can fan out to multiple TRIGGER_INs simultaneously.

2. **VALUE_COST** (⊖) — at most one per block.
   Emitted every time the script fires. Always an expenditure. Connects to a value ledger or parent
   block's VALUE_IN. Models labor cost, machine time, energy consumption, API charges, license fees.

3. **VALUE_OUT** (○) — one or more named value emitters.
   Emitted on script completion. Can be positive (revenue created, savings achieved) or negative
   (waste, rework cost, penalty). Multiple names: `revenue`, `waste`, `commission`, `penalty`.

4. **DATA_OUT** (□) — one per produced data type.
   Items produced by the script exit right. The type name is the port identity.
   Multiple output types allow routing: `out:product` for good items, `out:rejected` for defects.

### Port naming in YAML

```yaml
# Block: 2 triggers + 1 filter + 2 data-in on LEFT
#         2 events + cost + 2 value-out + 2 data-out on RIGHT
ports:
  # LEFT side (inputs) ──────────────────────────────────────────────────
  trigger_in:
    - id: start           # ▲ fires when queue has enough items
    - id: override        # ▲ force-start regardless of queue / lock state
  filter_in:
    - id: quality_params  # ◇ injects min_quality threshold at runtime
  data_in:
    - type: component     # □ one port per named incoming type
    - type: worker_hours  # □ worker resource tokens
  value_in:
    - id: all             # ⊕ receives VALUE_COST + VALUE_OUT from all inner blocks
    # RIGHT side (outputs) ─────────────────────────────────────────────────
  event_out:
    - id: done            # ▼ emitted on success
    - id: failed          # ▼ emitted on failure -> alerts / circuit breaker
  value_cost:
    amount: 50.0          # ⊖ cost charged each time the script runs
  value_out:
    - id: revenue         # ○ positive value per completed unit
    - id: waste           # ○ negative value (scrap / material loss)
  data_out:
    - type: product       # □ good items go right to the next block
    - type: rejected      # □ defects route to rework
```

### Port rules

- **Direction rule**: left = receives; right = emits. No DATA_OUT on left; no DATA_IN on right.
- **DATA ports**: one per data type (type name = port identity; no `id` field needed).
- **TRIGGER_IN / FILTER_IN / EVENT_OUT / VALUE_OUT**: any count; each identified by an `id`.
- **VALUE_COST**: at most one — the total running cost per script fire.
- **SCRIPT** (⬡): internal processing core — never on an edge.
- **VALUE_IN (⊕)**: receives value from child blocks; declared primarily by composite blocks to aggregate inner ⊖/○ flows.

---

> See [VISUALIZATION-GUIDE.md](VISUALIZATION-GUIDE.md) §3 for composite canvas visualization.

---

## 3. Data System

### 3.1 Data objects

Data is a **typed object** (like an envelope with a label and payload).
One data type can be **converted** into another inside a block (via script).

```yaml
data_types:
  - type: order           # external customer order
  - type: work_order      # internal production order
  - type: component       # physical part
  - type: worker_hours    # time resource (float: hours)
  - type: machine_cycle   # machine run record
  - type: invoice         # billing document
```

Each data type can carry an optional `item_class` annotation that describes the real-world
nature of the thing flowing through the graph. See §17.2 for the full list.

```yaml
data_types:
  - type: feature_request
    item_class: work_item      # §17.2 — a task or work order flowing through the pipeline
  - type: trained_model
    item_class: knowledge_unit # an ML model artefact produced and passed downstream
  - type: pallet
    item_class: physical_good  # a physical unit in a warehouse flow
```

### 3.2 Data conversions

A script can declare conversions. This is how value is added (an order becomes a product):

```yaml
conversions:
  - from: work_order
    to: product
    requires_script: proc_machining
    cost_per_unit: 25.0      # VALUE emitted per conversion
```

### 3.3 Container

Every block has an **internal container** — a queue of data items waiting to be processed.

```yaml
container:
  capacity: 10               # max items held (0 = unlimited)
  strategy: fifo             # fifo | lifo | priority
  priority_field: urgency    # field on item payload used for priority sort
  overflow: drop_oldest      # drop_oldest | drop_newest | block | error
```

The script only runs when container has **enough data to meet its requirements**.

### 3.4 Custom data types

Data is fully customizable — each data entry is a **name + quantity pair**.
Blocks define what data types they accept and produce. Any name is valid:

```yaml
data_types:
  - type: wood
    quantity: 5
  - type: metal
    quantity: 4
  - type: information
    quantity: 7000
  - type: purchase_order
    quantity: 1
```

### 3.5 Data stockpiling

Blocks can **accumulate (stockpile)** data items inside their container.
Data does not have to be processed immediately — it can build up until
conditions are met (enough materials, a trigger signal, or both).

### 3.6 Pool constraints

Define minimum and maximum pool sizes for materials inside a container:

```yaml
container:
  capacity: 100
  pool_rules:
    wood:
      min_to_start: 5    # need at least 5 wood to begin processing
      max_stockpile: 50   # won't accept more than 50 wood
    metal:
      min_to_start: 3
      max_stockpile: 30
```

### 3.7 Processing prerequisites

Processing begins only when **both** conditions are met:

1. Required data quantities are present (per `pool_rules` `min_to_start`)
2. A trigger signal is received (unless `auto_trigger: true` is set — then receiving data alone is enough)

```yaml
script:
  auto_trigger: false   # default: requires signal to start
  # auto_trigger: true  # process every time enough data arrives
```

### 3.8 Random variation (normal simulation)

Simulation elements can have randomized parameters that represent **normal business
variation** (not anomalies). For example, a customer block might order 3–7 items
randomly each cycle:

```yaml
schedule:
  interval: 5            # every 5 ticks
  variation:
    type: uniform         # uniform | normal | poisson
    min: 3
    max: 7
  data_template:
    type: purchase_order
    quantity_range: [1, 5]   # random quantity per order
```

---

## 4. Script System

### 4.1 What a script does

The SCRIPT (⬡) is the processing core of a block. It:
1. Reads items from the container
2. Optionally checks conditions (requirements)
3. Transforms data (consumes inputs, produces outputs)
4. Emits events
5. Produces value (cost or revenue)

### 4.2 Script trigger conditions

A script can start when:

```yaml
script:
  id: proc_assembly
  fires_on: any              # any | all | trigger_only | data_only
  # any     : fires when trigger OR enough data arrives
  # all     : fires only when BOTH trigger AND enough data are present
  # trigger_only: fires only on trigger (ignores data count)
  # data_only: fires only when required data is present (ignores triggers)
```

### 4.3 Data requirements

```yaml
script:
  requires:
    - type: component
      count: 2               # needs 2 components
      attribute: quality     # optional: attribute check
      min_value: 0.8         # attribute must be >= 0.8
    - type: worker_hours
      count: 4
      attribute: skill_level
      min_value: 3           # skill level requirement
```

If requirements are not met: items stay in container, script waits.

### 4.4 Multi-step scripts

A script can have sequential steps. Each step can produce intermediate outputs or fail:

```yaml
script:
  id: proc_production_line
  steps:
    - id: step_prepare
      duration_ms: 500       # simulated processing time
      output: intermediate_part
      fail_chance: 0.0
    - id: step_machine
      duration_ms: 1200
      output: machined_part
      fail_chance: 0.15      # 15% chance of failure (machine breakdown)
      on_fail: emit_event    # emit event_out on failure (alert maintenance)
    - id: step_inspect
      duration_ms: 300
      output: inspected_part
      fail_chance: 0.10
      on_fail: reject        # reject the item (goes to rejected log)
```

### 4.5 Script parameters (from FILTER_IN ◇)

A filter can carry parameters that modify the script at runtime:

```yaml
# Filter edge delivers a filter object to FILTER_IN port
# The script reads these parameters:
filter_params:
  - name: speed_multiplier   # e.g. 0.5 = half speed (overtime reduction)
    default: 1.0
  - name: quality_threshold  # minimum quality to pass inspection
    default: 0.7
  - name: batch_size         # override default batch size
    default: 1
```

### 4.6 Multi-step scripts with complex conditions

Each step in a script can have its own conditions, durations, and dependencies:

```yaml
script:
  fires_on: signal
  steps:
    - id: gather_materials
      action: consume
      requires:
        data: {wood: 5, metal: 3}
      duration: 2                    # takes 2 ticks

    - id: wait_for_batch
      action: wait
      condition:
        type: accumulate
        data: {component: 5}        # wait until 5 components accumulated
      timeout: 20                   # fail if not met within 20 ticks

    - id: assemble
      action: process
      depends_on: [gather_materials, wait_for_batch]   # both must complete
      duration:
        type: uniform
        min: 3
        max: 8                      # random duration 3-8 ticks
      fail_chance: 0.05

    - id: external_validation
      action: delegate
      target_block: quality_lab     # this step IS another block
      send_data: {sample: 1}
      send_signal: start_inspection
      wait_for_signal: inspection_complete   # wait for QA block to signal back
      timeout: 30

    - id: package
      action: process
      depends_on: [assemble, external_validation]
      duration: 1
```

### 4.7 Step types

| Type | Behaviour |
|------|-----------|
| `consume` | Consume data from container |
| `process` | Execute processing logic with duration + fail_chance |
| `wait` | Wait for a condition (time, data accumulation, external signal) |
| `delegate` | Send data + signal to another block, wait for response signal |
| `emit` | Produce output data and/or signals |

### 4.8 Step conditions

- `depends_on: [step_ids]` — wait for listed steps to complete
- `condition.type: accumulate` — wait for N items of a data type
- `condition.type: time_elapsed` — wait for N ticks
- `condition.type: signal_received` — wait for a named signal
- `timeout` — max ticks before step fails

### 4.9 Nested block delegation

A step can reference another block as a sub-process. When reached:

1. Data is sent to the target block's input
2. A trigger signal is sent to the target block
3. The step waits for a response signal from the target block
4. If timeout expires, the step fails

This makes scripts composable — complex processes can reference other blocks
as processing steps.

---

## 5. Signal System

### 5.1 Trigger (▲ TRIGGER_IN — top-left)

A **trigger** is a signal that tells the block to start its script.
It carries NO data. It just says "go".

```yaml
trigger_in:
  signal_type: start_shift
  # when received: fire script immediately (if data requirements met, or if fires_on: any)
```

### 5.2 Event (▼ EVENT_OUT — bottom-right)

When the script **completes** (all steps done) or **fails**, it emits an event.
The event can trigger downstream blocks.

```yaml
event_out:
  on_complete: job_done      # signal type emitted on successful completion
  on_fail: job_failed        # signal type emitted on script failure
  on_step: step_completed    # signal type emitted after each step (optional)
  payload:                   # what to attach to the signal
    - duration_ms            # actual run duration
    - items_processed        # how many items were processed
    - quality_avg            # average quality of produced items
```

### 5.3 Signal routing rules

Signals follow their own edges (dashed amber lines in UI).
One EVENT_OUT can fan out to **multiple** TRIGGER_INs.
A TRIGGER_IN can receive signals from **multiple** sources (OR logic by default).

```yaml
signal_logic: any           # any: fire on first received | all: wait for all sources
signal_timeout_ms: 5000     # if waiting for "all": fail after timeout
```

---

## 6. Value System

### 6.1 VALUE_COST (⊖ right side) — cost of running

Emitted by the block each time its script runs.
Always represents an expenditure (negative value in the ledger).

```yaml
value_cost:
  amount: 25.00              # cost per script run
  currency: EUR
  type: labor                # label: labor | material | energy | overhead
```

### 6.2 VALUE_OUT (○ right side) — value produced

Emitted on script completion. Can be positive (revenue) or negative (additional cost).

```yaml
value_out:
  amount: 120.00             # value per completion
  formula: items_processed * unit_price   # optional: formula using script output vars
  type: revenue              # revenue | material_used | waste
```

### 6.3 Value aggregation

Value flows through **value edges** to VALUE_COST / VALUE_OUT ports of parent blocks
or to a VALUE_ACCUMULATOR node (special sink that sums values).

```yaml
# Special node type: value_accumulator
- id: project_budget
  type: value_accumulator
  label: "Project P&L"
  # sums all connected value edges, shows running total
```

### 6.4 Value as data

A value can also be **packaged as data** and sent through DATA edges.
Example: a contract block produces a "contract" data object that carries a value field.

---

### 6.5 VALUE_IN (⊕ left side) — receives aggregated child value

Used by **composite blocks** to collect value flows emitted by inner blocks.
The composite sums all connected VALUE_COST (⊖) and VALUE_OUT (○) arriving at VALUE_IN
and re-emits the aggregate through its own right-side output ports.

```yaml
value_in:
  - id: all          # single ⊕ port — aggregates everything
  # or split by stream:
  - id: labor_costs  # ⊕ receives only labor VALUE_COST from inner workers
  - id: material     # ⊕ receives material-tagged VALUE_COST
  - id: revenue      # ⊕ receives VALUE_OUT (positive value)
```

This is how cost and revenue propagate automatically through every layer of composite hierarchy.
At the top-level graph, a single ⊖/○ pair on the root block shows the full P&L.

---

## 7. Filter System

### 7.1 Filter (◇ FILTER_IN — top-right)

A filter can do two things:
1. **Gate incoming data**: only allow items that pass a condition
2. **Modify script parameters**: change how the script behaves

```yaml
filter:
  mode: gate                 # gate | param | both
  condition: "item.quality >= 0.7 && item.type == 'component'"
  # items failing condition: rejected (counted in rejected_count)
  # items passing: added to container normally
```

### 7.2 Data routing with filter

A filter can **route** data to different DATA_OUT ports:

```yaml
filter:
  mode: route
  routes:
    - condition: "item.urgency == 'high'"
      output_port: data_out_priority
    - condition: "item.urgency == 'low'"
      output_port: data_out_standard
    - default: data_out_standard
```

### 7.3 Filter as transformer

A filter can **modify** items before they enter the container:

```yaml
filter:
  mode: transform
  transforms:
    - field: priority
      formula: "item.value > 1000 ? 'high' : 'normal'"
    - field: estimated_hours
      formula: "item.complexity * 8"
```

---

## 8. Block States

Every block has a state machine:

```
IDLE ──(data arrives / trigger)──▶ WAITING
WAITING ──(requirements met)──────▶ PROCESSING
WAITING ──(timeout)───────────────▶ IDLE  (items stay in container)
PROCESSING ──(step complete)──────▶ PROCESSING (next step)
PROCESSING ──(all steps done)─────▶ IDLE + emit EVENT_OUT + emit VALUE_OUT
PROCESSING ──(step failed)────────▶ FAILED + emit EVENT_OUT(on_fail)
FAILED ──(retry trigger)──────────▶ PROCESSING
FAILED ──(no retry)───────────────▶ IDLE (items discarded or returned)
```

State is visible in the UI (block border color):
- IDLE: gray border
- WAITING: yellow border
- PROCESSING: blue animated border
- FAILED: red border

---

## 9. Resource Locking

A block can **lock** while processing — won't accept new triggers until current run finishes:

```yaml
concurrency: 1              # max parallel script runs (1 = locked while processing)
# concurrency: 3            # can process 3 items in parallel
# concurrency: 0            # unlimited (pipeline style)
```

---

## 10. Batch Processing

A script can wait for N items before running:

```yaml
script:
  batch_size: 5              # collect 5 items then run once
  batch_timeout_ms: 10000    # run even if fewer items after this timeout
```

---

## 11. Composite Blocks

A composite block is a block whose SCRIPT is replaced by a inner subgraph.
It exposes its internal DATA_IN / DATA_OUT ports as boundary objects in the drill view.

```yaml
- id: dept_production
  type: composite
  label: "Production Dept"
  # Port declarations (what the parent graph sees):
  ports:
    data_in:  [ production_plan ]
    data_out: [ product ]
    trigger_in:  true
    event_out:   true
    filter_in:   false
    value_cost:  { amount: 200, type: labor }
    value_out:   null
  children:
    # Boundary port nodes — pinned to canvas edge, not movable
    boundary_nodes:
      - id: dept_production.__in_production_plan
        type: boundary_in
        port_kind: data
        data_type: production_plan
        position: left         # which canvas edge
      - id: dept_production.__out_product
        type: boundary_out
        port_kind: data
        data_type: product
        position: right
      - id: dept_production.__trigger
        type: boundary_in
        port_kind: signal
        position: top_left
      - id: dept_production.__event
        type: boundary_out
        port_kind: signal
        position: bottom_right
    nodes: [ ... ]
    edges: [ ... ]
```

### 11.1 Layer model

Composite blocks nest freely. There is no depth limit.

| Layer | Contains              | Typical real-world unit                   |
|-------|-----------------------|-------------------------------------------|
| L0    | Atomic (SCRIPT ⬡)  | programmer, machine, API call, check       |
| L1    | Group of L0 atomics   | team, production cell, microservice       |
| L2    | Group of L1 composites| department, factory floor, platform       |
| L3    | Group of L2 composites| business unit, site, product line         |
| L4+   | Group of L(N-1)       | company, enterprise, value stream         |

**Design top-down, build bottom-up:**
1. Decide what ports each layer should expose (what does a "department" look like from the board?).
2. Build atomics first — verify they work correctly in isolation.
3. Wrap verified atomics into Layer-1 composites.
4. Test each composite as a black box using only its declared ports.
5. Combine composites into the next layer up.

### 11.2 Container and queue flow through layers

Each block at every layer has its **own independent container queue**.
Flow through a 2-layer composite (atomic blocks inside a composite):

```
 Parent graph item arrives at composite LEFT wall
         |
         v    (no buffering at composite boundary — it is a direct wire)
 [Atomic A: container = 0/50 items]
         |
  SCRIPT fires when conditions met
         |
         v
 [Atomic B: container = 3/50 items   <-- bottleneck visible here]
         |
  SCRIPT fires
         |
         v
 Parent graph item exits at composite RIGHT wall
```

Key behaviours:
- Full queue on **block B** is visible, block A is unaffected.
- **Backpressure** from B propagates upstream through B's own `backpressure:` config.
- **Aging** escalates items stuck in B's queue independently of A.
- Drilling into the composite shows **live queue depths** for every inner block.
- The composite has **no queue of its own** — its boundary walls are transparent wires.

For a **3-layer** composite: the same rules apply at each level. Drilling into L2 shows L1 composites;
drilling into an L1 composite shows its atomics. Queue depth is visible at every level.

### 11.3 Value aggregation through layers

Inner blocks emit VALUE_COST (⊖) and VALUE_OUT (○) to the RIGHT.
Those wires connect to the **parent composite's VALUE_IN (⊕)** on the LEFT.
The composite sums them and re-emits via its own ⊖/○ to the grandparent.

```yaml
# Layer 0: atomic programmer block
- id: coder
  ports:
    value_cost: { amount: 80.0 }     # ⊖ -> dev_team.value_in
    value_out:
      - id: story_points             # ○ -> dev_team.value_in

# Layer 1: dev_team composite aggregates the above
- id: dev_team
  type: composite
  ports:
    value_in:
      - id: all                      # ⊕ LEFT: receives all inner ⊖/○
    value_cost: { aggregate: true }  # ⊖ RIGHT: re-emits summed cost to dept
    value_out:
      - id: throughput               # ○ RIGHT: re-emits summed revenue to dept
        aggregate: true

# Layer 2: software_dept contains dev_team + others
- id: software_dept
  type: composite
  ports:
    value_in:
      - id: all                      # ⊕ LEFT: receives dev_team + qa_team + ops costs
    value_cost: { aggregate: true }  # ⊖ RIGHT: total dept cost to C-suite dashboard
    value_out:
      - id: throughput
        aggregate: true              # ○ RIGHT: total dept revenue
```

---

## 12. Extended Mechanics Library

The following 33 mechanics compose freely with any block type.

> Full mechanics reference with YAML snippets: [MECHANICS-GUIDE.md](MECHANICS-GUIDE.md)

| # | Mechanic | Models |
|---|----------|--------|
| 13.1 | Skill requirement on data | Worker skill checks on data attributes |
| 13.2 | Machine / resource state | Health degradation, failure, repair |
| 13.3 | Time-based scheduling | Auto-trigger on interval |
| 13.4 | Conditional event routing | Route signals by script outcome |
| 13.5 | Value formula | Dynamic value from script variables |
| 13.6 | Data conversion inside block | Type transformation with ratio |
| 13.7 | Conditional branching (router) | Route data by item attributes |
| 13.8 | Accumulator / counter | Count items, emit trigger at threshold |
| 13.9 | Priority queue | Process items in priority order |
| 13.10 | Data enrichment (join) | Wait for multiple streams, join by key |
| 13.11 | Item aging & priority escalation | SLA creep, expiry, dead-letter |
| 13.12 | Shared resource pool | Competing blocks, contention, starvation |
| 13.13 | Backpressure propagation | Upstream throttle on downstream congestion |
| 13.14 | Circuit breaker | Open/half-open/closed on failure count |
| 13.15 | Compensation / saga pattern | Distributed rollback on downstream failure |
| 13.16 | Parallel split & join (fork-join) | Fan-out N branches, barrier merge |
| 13.17 | Time windows (schedule gate) | Accept items only during configured hours |
| 13.18 | Item cost accumulation | Per-item cost ledger stamped by each block |
| 13.19 | Adaptive concurrency (auto-scale) | Self-adjusting parallelism by queue depth |
| 13.20 | Rate limiter / token bucket | Throughput cap, burst absorption |
| 13.21 | Probabilistic outcomes (Monte Carlo) | Weighted outcome distributions |
| 13.22 | Audit trail on item | Full provenance, tamper detection |
| 13.23 | Simulation context & scenarios | Global parameters, what-if overrides |
| 13.24 | Dead letter queue & replay | Error recovery, manual intervention |
| 13.25 | Observation tap (non-consuming) | Monitor without affecting main flow |
| 13.26 | Versioned item types (schema evolution) | Schema migration between versions |
| 13.27 | Human-in-the-loop (approval gate) | Manual review with timeout escalation |
| 13.28 | Simulation clock & fast-forward | Logical clock, speed control, warm-up |
| 13.29 | Warmup period | Block prep time before processing begins |
| 13.30 | Yield rate | Fractional item loss during processing — waste, shrinkage |
| 13.31 | Preventive maintenance | Scheduled downtime every N ticks |
| 13.32 | Block priority | Tick-order control — lower number processed first |
| 13.33 | Energy cost | Continuous cost per active tick — power draw, standby |

---

## 13. YAML Block Schema (reference)

All fields optional unless marked `*`. Covers all mechanics from §4–§13.

```yaml
# Full block definition schema
- id: block_id               # * unique identifier
  label: "Display Name"      # * human-readable name
  type: processor            # * source | processor | sink | composite | router
                             #   accumulator | value_accumulator | split | join
                             #   tap | dead_letter

  block_class: process       # §17 real-world entity category (optional, purely semantic)
                             # person | role | team | software | hardware | infrastructure
                             # facility | vehicle | equipment | data_store | knowledge
                             # process | service | asset

  description: "..."         # shown in tooltip

  # ── Port declarations ──────────────────────────────────────────────────────
  ports:
    data_in:  [ type_a, type_b ]
    data_out: [ type_c ]

    trigger_in:   true
    event_out:
      on_complete: signal_type_ok
      on_fail:     signal_type_err
      routes:                       # §13.4 conditional event routing
        - condition: "result.quality >= 0.9"
          signal: product_premium
        - default: product_standard

    filter_in: true

    value_cost:
      amount: 50.0
      type: labor                   # labor | material | energy | overhead

    value_out:
      formula: "items * unit_price - waste * disposal_cost"  # §13.5 formula
      type: revenue
      variables:
        unit_price: 120.0
        disposal_cost: 15.0

  # ── Container ──────────────────────────────────────────────────────────────
  container:
    capacity: 10
    strategy: fifo                  # fifo | lifo | priority
    priority_field: urgency
    priority_map:                   # §13.9 priority queue
      urgent: 100
      high: 70
      normal: 40
      low: 10
    overflow: drop_oldest           # drop_oldest | drop_newest | block | error

    aging:                          # §13.11 item aging & escalation
      field: age_ms
      escalation_rules:
        - after_ms: 3600000
          set_priority: high
        - after_ms: 86400000
          set_priority: urgent
          emit_event: sla_breach
      expiry_ms: 172800000
      on_expire: dead_letter        # dead_letter | reject | emit_event

    backpressure:                   # §13.13 backpressure propagation
      threshold_pct: 80
      signal: slow_down
      pause_threshold_pct: 95
      resume_threshold_pct: 50

  # ── Script ─────────────────────────────────────────────────────────────────
  script:
    id: proc_name
    fires_on: any                   # any | all | trigger_only | data_only
    batch_size: 1                   # §11 batch processing
    batch_timeout_ms: 0

    concurrency:                    # §10 / §13.19 adaptive concurrency
      mode: fixed                   # fixed | adaptive
      value: 1
      min: 1
      max: 10
      target_queue_depth: 5
      cooldown_ms: 10000

    requires:                       # §5.3 data requirements + §13.1 skill
      - type: worker_hours
        count: 4
        attribute: skill_level
        min_value: 3

    requires_resource:              # §13.12 shared resource pool
      pool: pool_engineers
      slots: 2
      on_unavailable: queue         # queue | skip | fail
      release_on: complete

    steps:                          # §5.4 multi-step scripts
      - id: step_1
        duration_ms: 500
        output: intermediate
        fail_chance: 0.0
        on_fail: reject             # reject | emit_event | compensate

    converts:                       # §13.6 data conversion
      - from: input_type
        to: output_type
        ratio: 1

    join:                           # §13.10 data enrichment join
      - type: order
        key_field: order_id
      - type: inventory_check
        key_field: order_id
      - match: both_required

    outcome_distribution:           # §13.21 probabilistic outcomes
      - outcome: pass_premium
        probability: 0.15
        output_type: product_premium
        value_multiplier: 1.5
      - outcome: scrap
        probability: 0.05
        emit_event: item_scrapped

    cost_stamp:                     # §13.18 item cost accumulation
      label: processing_cost
      amount_formula: "duration_ms / 1000 * hourly_rate"
      variables:
        hourly_rate: 85.0
      accumulate_on: item

    audit_stamp:                    # §13.22 audit trail
      enabled: true
      fields: [ block_id, timestamp, operator_id, duration_ms, outcome ]
      tamper_detect: hash

    human_approval:                 # §13.27 human-in-the-loop
      required: false
      notify: [ role_manager ]
      timeout_ms: 172800000
      on_timeout: escalate
      escalate_to: role_director
      ui_action: approval_form

    saga_id: null                   # §13.15 saga / compensation
    compensation:
      trigger_signal: saga_rollback
      steps: []

  # ── Filter ─────────────────────────────────────────────────────────────────
  filter:
    mode: gate                      # gate | route | transform | param | both
    condition: "item.quality >= 0.7"
    routes:                         # §8.2 routing mode
      - condition: "item.urgency == 'high'"
        output_port: data_out_priority
      - default: data_out_standard
    transforms:                     # §8.3 transform mode
      - field: priority
        formula: "item.value > 1000 ? 'high' : 'normal'"

  # ── Resource health ────────────────────────────────────────────────────────
  resource:                         # §13.2 machine/resource health
    health: 1.0
    degradation_per_run: 0.05
    failure_threshold: 0.2
    repair_signal: maintenance_done
    repair_amount: 1.0

  # ── Circuit breaker ────────────────────────────────────────────────────────
  circuit_breaker:                  # §13.14
    mode: count                     # count | rate
    fail_threshold: 5
    half_open_after_ms: 30000
    success_to_close: 2
    on_open: emit_event
    on_close: emit_event

  # ── Rate limiter ───────────────────────────────────────────────────────────
  rate_limiter:                     # §13.20
    type: token_bucket
    tokens_per_second: 10
    burst_capacity: 50
    on_throttle: queue              # queue | drop | redirect
    emit_on_drop: rate_exceeded

  # ── Time window gate ───────────────────────────────────────────────────────
  time_window:                      # §13.17
    timezone: Europe/Berlin
    windows:
      - days: [ Mon, Tue, Wed, Thu, Fri ]
        start: "08:00"
        end: "17:00"
    outside_window: queue           # queue | reject | reroute
    reroute_to: null

  # ── Auto-schedule ──────────────────────────────────────────────────────────
  schedule:                         # §13.3
    interval_ms: 0
    start_delay_ms: 0

  # ── Observation tap ────────────────────────────────────────────────────────
  tap:                              # §13.25 — only when type: tap
    source_edge: { from: block_a, to: block_b }
    copy_to: analytics_bus
    sample_rate: 1.0
    transform:
      - field: pii_email
        action: mask

  # ── Dead letter ────────────────────────────────────────────────────────────
  dead_letter:                      # §13.24 — only when type: dead_letter
    accepts_from: all
    replay:
      enabled: true
      target_block: manual_review
      operator_required: true

  # ── Fork-join ──────────────────────────────────────────────────────────────
  # When type: split
  fan_out: 3
  output_ports: [ out_a, out_b, out_c ]
  item_copy: true

  # When type: join
  expects_ports: [ in_a, in_b, in_c ]
  join_mode: all_required           # all_required | majority | first_wins
  key_field: request_id
  timeout_ms: 86400000
  on_timeout: emit_event

  # ── Composite children ─────────────────────────────────────────────────────
  drillable: true
  children:
    boundary_nodes: [ ... ]
    nodes: [ ... ]
    edges: [ ... ]
    signals: [ ... ]

  # ── Entity classification ──────────────────────────────────────────────────
  block_class: process           # §17.1 — optional real-world entity class
  owner: alice.smith             # optional: person or team responsible for this block
  domain: engineering            # optional: business domain label (HR, Finance, Engineering…)
  tags: [ core, critical_path ]  # optional: free-form tags for filtering / analysis
```

---

## 17. Block Class & Item Type Taxonomy

---

### 17.1 Block class reference

`block_class` is an **orthogonal, semantic annotation** on a node — it says what real-world entity
the block *represents*, independent of the engine mechanics controlled by `type`.

**Key rule**: `block_class` never changes engine behavior. The engine stores it, emits it in block
state, and diagram renderers use it for color/icon/filtering — but routing, timing, and failure
logic are always controlled by `type` alone.

The 15 canonical classes cover every major industry domain (manufacturing, pharma, IT, logistics,
banking, insurance). They are deliberately generic so a single class works across domains.

| `block_class` | Represents | Typical `type` pairings | Industry examples |
|---|---|---|---|
| `person` | Individual human — employee, patient, contractor, customer | process, source, sink | *dev_alice* (IT), *nurse_triage* (healthcare), *client_intake* (banking) |
| `role` | Abstract job function / position (not a specific individual) | process, router | *compliance_officer* (banking/pharma), *scrum_master* (IT), *shift_supervisor* (manufacturing) |
| `team` | Organized group — department, squad, ward, crew | composite, process | *software_team* (IT), *fulfillment_crew* (logistics), *icu_unit* (healthcare) |
| `knowledge` | Embedded know-how — skill, training, procedure, BOM, SOP, policy | process, filter | *python_skill* (IT), *bom_v3* (manufacturing), *fda_sop* (pharma), *aml_policy* (banking) |
| `software` | Application, SaaS, microservice, algorithm, API | process, router, source, sink | *github_actions* (IT), *erp_system* (manufacturing), *claims_engine* (insurance) |
| `hardware` | Physical computing device, PLC, server, IoT sensor | process, source | *barcode_scanner* (logistics), *plc_line_1* (manufacturing), *infusion_pump* (healthcare) |
| `infrastructure` | Network, cloud platform, VPN, datacenter, pipeline | composite, process | *vpc_prod* (IT), *scada_network* (manufacturing), *vpn_gateway* (any), *kafka_cluster* (IT) |
| `facility` | Physical location — factory, warehouse, office, lab, branch | composite, source, sink | *warehouse_a* (logistics), *clean_room_2* (pharma), *branch_nyc* (banking) |
| `equipment` | Specialized instrument or machinery | process | *cnc_press* (manufacturing), *mri_scanner* (healthcare), *hplc_analyzer* (pharma), *3d_printer* (IT/mfg) |
| `vehicle` | Transport — truck, drone, conveyor, AGV, forklift | process, source | *delivery_van* (logistics), *conveyor_b* (manufacturing), *cargo_drone* (any) |
| `material` | Raw material, chemical stock, component inventory, consumable | source, process | *steel_coil_stock* (manufacturing), *api_chemical* (pharma), *server_parts* (IT), *cash_vault* (banking) |
| `data_store` | Persistent data repository — database, CRM, ERP, data lake, ledger | source, process, sink | *orders_db* (any), *fda_registry* (pharma), *general_ledger* (banking), *claims_archive* (insurance) |
| `financial_instrument` | Account, fund, bond, insurance policy, loan, portfolio | source, process, sink | *loan_pool* (banking), *insured_portfolio* (insurance), *trading_book* (finance), *research_budget* (pharma) |
| `regulation` | Compliance rule, audit gate, standards body, approval authority | process, router | *fda_approval_gate* (pharma), *aml_check* (banking), *iso_9001_audit* (manufacturing), *gdpr_filter* (IT) |
| `service` | External vendor, shared service, utility, outsourced function | process, sink | *logistics_vendor* (any), *cloud_dns* (IT), *trial_cro* (pharma), *clearinghouse* (banking) |

---

### 17.2 Item types — playbook-level data registry

Data flowing between blocks is called **data**. Each unit of data has a named **item type**
and carries a quantity. Item types are defined once per playbook in a top-level `item_types:`
section and referenced by `inputs:` / `outputs:` fields on each node.

```yaml
item_types:
  - id: man_hours          # unique identifier — used in inputs/outputs
    unit: hours            # optional: display unit (hrs, kg, units, ...)
    description: "Qualified engineering time produced by a developer"

  - id: lumber
    unit: board_ft

  - id: milk
    unit: gallons

  - id: feature_request
    unit: tickets
    description: "A user story or work item flowing through the sprint pipeline"

  - id: trained_model
    unit: artefacts
    description: "ML model produced after training run and passed to validation"

  - id: api_batch
    unit: records
```

**Rules:**
- `id` is the only required field. It becomes the data type name (lowercase snake_case).
- `unit` is optional display metadata — never changes routing or engine behavior.
- `description` is optional — rendered in tooltip hover on the item type badge.
- Item types not declared in `item_types:` still flow (engine doesn't validate) — but declaring
  them makes the diagram tooltip and side panel show richer context.
- An item type carries a quantity (an integer or float); the `unit` gives it meaning.

**Cross-domain item type examples:**

| Domain | Item types |
|---|---|
| Manufacturing | `steel_sheet`, `welded_frame`, `finished_unit`, `qa_rejection`, `rework_order` |
| Big pharma | `drug_substance`, `batch_record`, `stability_sample`, `fda_submission`, `lab_result` |
| IT / software | `feature_request`, `pull_request`, `test_report`, `deployment`, `incident_ticket` |
| Logistics | `shipment`, `pallet`, `delivery_proof`, `return_parcel`, `tracking_event` |
| Banking | `loan_application`, `credit_score`, `transaction`, `kyc_document`, `regulatory_report` |
| Insurance | `claim_submission`, `adjudication_record`, `policy`, `payout`, `risk_assessment` |
| Healthcare | `patient_referral`, `lab_order`, `discharge_summary`, `prescription`, `imaging_result` |

---

### 17.3 Annotated YAML example — software sprint pipeline

This example models a sprint delivery pipeline using `block_class` and `item_types:`. Nothing
in the annotation changes engine behavior.

```yaml
item_types:
  - id: feature_request
    unit: tickets
    description: "User story from the product backlog"
  - id: man_hours
    unit: hours
    description: "Engineering time produced by a qualified developer"
  - id: reviewed_code
    unit: PRs
    description: "Pull request passing CI and peer review"
  - id: deployment
    unit: releases
    description: "Successful feature deployment to production"

nodes:
  - id: backlog
    label: "Product Backlog"
    type: source
    block_class: data_store         # a Jira/Linear board — persistent data store
    auto_rate: 2
    domain: product
    outputs: [ feature_request ]

  - id: dev_alice
    label: "Dev — Alice"
    type: process
    block_class: person             # individual developer
    domain: engineering
    inputs:  [ feature_request ]
    outputs: [ man_hours ]
    processing_ticks: 4

  - id: python_skill
    label: "Python Expertise"
    type: process
    block_class: knowledge          # skill / competency block
    domain: engineering
    inputs:  [ man_hours ]          # raw hours come in
    outputs: [ reviewed_code ]      # qualified, reviewed work comes out
    processing_ticks: 2
    fail_chance: 0.05               # 5 % rework rate

  - id: ci_pipeline
    label: "CI/CD Pipeline"
    type: process
    block_class: software           # GitHub Actions / Jenkins
    domain: engineering
    inputs:  [ reviewed_code ]
    outputs: [ deployment ]
    processing_ticks: 1
    fail_chance: 0.08

  - id: production
    label: "Production"
    type: sink
    block_class: infrastructure     # cloud environment receiving deployments
    domain: engineering
    inputs:  [ deployment ]
```

---

### 17.4 Class vs type — disambiguation

| Dimension | `type` | `block_class` |
|---|---|---|
| Purpose | Engine mechanic — controls simulation behavior | Semantic label — human/analyst context |
| Required? | Yes | No |
| Affects routing? | Yes | No |
| Affects engine timing? | Yes | No |
| Affects diagrams? | Shape, ports | Color, icon, label tag, filter |
| Examples | `process`, `composite`, `router`, `source`, `sink` | `person`, `software`, `facility`, `knowledge` |

A single `type: process` block can be `block_class: person` (Alice coding), `block_class: software`
(an automated CI check), `block_class: equipment` (a CNC press), or `block_class: regulation`
(an FDA compliance gate). Engine behavior is identical; domain context is explicit.

---

### 17.5 Industry domain patterns

| Industry | Primary `block_class` values | Typical item types |
|---|---|---|
| **Manufacturing** | `facility`, `equipment`, `material`, `vehicle`, `role` | `raw_material`, `work_order`, `finished_unit`, `qa_rejection` |
| **Big Pharma** | `facility`, `equipment`, `regulation`, `role`, `data_store` | `batch_record`, `drug_substance`, `lab_result`, `fda_submission` |
| **IT / Software** | `person`, `team`, `software`, `infrastructure`, `data_store` | `feature_request`, `man_hours`, `pull_request`, `deployment` |
| **Logistics** | `facility`, `vehicle`, `equipment`, `service`, `hardware` | `shipment`, `pallet`, `delivery_proof`, `return_parcel` |
| **Banking** | `role`, `software`, `financial_instrument`, `regulation`, `data_store` | `loan_application`, `transaction`, `kyc_document`, `regulatory_report` |
| **Insurance** | `role`, `software`, `financial_instrument`, `regulation`, `service` | `claim_submission`, `policy`, `payout`, `risk_assessment` |
| **Healthcare** | `person`, `role`, `equipment`, `facility`, `regulation` | `patient_referral`, `lab_order`, `prescription`, `discharge_summary` |
| **VPN / Networks** | `infrastructure`, `hardware`, `software`, `regulation`, `service` | `network_packet`, `alert_event`, `config_change`, `incident_ticket` |



## 14. Edge Schema (reference)

```yaml
# Data edge (solid colored line)
- { from: block_a, to: block_b, itemType: component, edge_type: data }

# Signal edge (dashed amber line, triangle ports)
- { from: block_a.event_out, to: block_b.trigger_in, edge_type: signal, signalType: job_done }

# Filter edge (dashed purple line, diamond port)
- { from: param_source, to: block_b.filter_in, edge_type: filter }

# Value edge (dashed green line, circle port)
- { from: block_a.value_out, to: ledger.value_in, edge_type: value }

# Backpressure signal edge (dashed red line — special system edge)
- { from: block_b.backpressure_out, to: block_a.throttle_in, edge_type: backpressure }

# Resource claim edge (dotted gray line — pool membership)
- { from: block_a, to: pool_engineers, edge_type: resource, slots: 2 }

# Compensation edge (dashed orange line — saga rollback path)
- { from: saga_coordinator.rollback_out, to: block_a.compensation_in, edge_type: compensation }

# Tap edge (dotted teal line — non-consuming copy)
- { from: block_a.tap_out, to: analytics_bus, edge_type: tap, sample_rate: 0.1 }
```

### Edge visual reference

| Edge type    | Line style | Color               | Carries                     |
| ------------ | ---------- | ------------------- | --------------------------- |
| data         | solid      | varies by item type | typed items                 |
| signal       | dashed     | amber               | trigger / event signals     |
| filter       | dashed     | purple              | filter params / gate        |
| value        | dashed     | green               | cost / revenue amounts      |
| backpressure | dashed     | red                 | throttle / pause control    |
| resource     | dotted     | gray                | pool slot claims            |
| compensation | dashed     | orange              | saga rollback instructions  |
| tap          | dotted     | teal                | item copies (non-consuming) |

---

> See [DOMAIN-BLUEPRINTS.md](DOMAIN-BLUEPRINTS.md) §1 for the software feature pipeline example.

> See [VISUALIZATION-GUIDE.md](VISUALIZATION-GUIDE.md) §1 for visual port positions and block layout.

> See [DOMAIN-BLUEPRINTS.md](DOMAIN-BLUEPRINTS.md) §2 for cross-cutting simulation patterns.

> See [DOMAIN-BLUEPRINTS.md](DOMAIN-BLUEPRINTS.md) §3 for 15 real-world domain blueprints.

> See [DOMAIN-BLUEPRINTS.md](DOMAIN-BLUEPRINTS.md) §4 for extended YAML graph examples.

> See [DOMAIN-BLUEPRINTS.md](DOMAIN-BLUEPRINTS.md) §5 for layered composite examples.

---

## 15. Container Processing Modes

Every composite block has a `container_mode` field that controls how incoming items are handled
relative to the composite's own script and its children subgraph.

### 15.1 Mode table

| Mode | Script runs? | Children run? | When to use |
|------|:---:|:---:|---|
| `passthrough` | no | no | Composite is a pure visual grouping; items skip all processing |
| `script_only` | yes | no | Composite has meaningful outer logic; inner blocks are decorative |
| `internal_only` | no | yes | Children do all the work; composite has no outer logic (default) |
| `script_then_internal` | yes — first | yes — after | Pre-screen or enrich at composite level, then route into children |
| `internal_then_script` | yes — after | yes — first | Children process items, then composite script validates or transforms exit output |

### 15.2 Behaviour diagrams

**passthrough**: item crosses composite boundary without touching any queue.
```
 --> [composite boundary] --> next node
```

**script_only**: inner subgraph is bypassed; the composite acts like an atomic block.
```
 --> [composite SCRIPT] --> output
      (children ignored)
```

**internal_only** _(default)_: item is delivered directly to the entry child.
```
 --> [entry child queue] --> ... --> [exit child] --> output
```

**script_then_internal**: composite script runs first (can enrich or gate the item), then the
processed item enters the inner subgraph.
```
 --> [composite SCRIPT] --> [entry child queue] --> ... --> output
```

**internal_then_script**: children process the item to completion, then the composite script
runs a final check or transformation at the composite's exit boundary.
```
 --> [entry child queue] --> ... --> [exit child] --> [composite SCRIPT] --> output
```

### 15.3 YAML declaration

```yaml
- id: warehouse
  label: Warehouse
  type: composite
  container_mode: script_then_internal   # override default
  inputs: [order]
  outputs: [product]
  children:
    nodes: [pick, qc, pack]
    edges: [...]
```

Omitting `container_mode` is identical to `internal_only`.

### 15.4 Choosing a mode

- **passthrough** — Use for organisational grouping (a cost centre or business unit whose
  composite boundary exists only for P&L roll-up).
- **script_only** — Use when the composite owns a heavyweight computation (model inference,
  aggregation) and the subgraph is architectural documentation, not executed logic.
- **internal_only** — Default for standard pipeline composites: the outer composite is a
  delivery contract, the inner blocks execute.
- **script_then_internal** — Use for pre-admission gates (authentication, validation, circuit
  breaker) before items enter a more expensive subgraph.
- **internal_then_script** — Use for post-processing pipelines (packaging, auditing, shipping
  confirmation) that must run after all inner steps succeed.

---

## 16. Logical Operation Block Types

Logical blocks are built-in node types that model routing, filtering, combining, and control
operations without requiring a custom SCRIPT. The `type` field in YAML determines visual shape,
colour, and built-in behaviour.

### 16.1 Type reference

| Type | Visual | Shape | Colour | Built-in behaviour |
|------|--------|-------|--------|---|
| `filter` | FILTER | Diamond | Amber `#f69443` | Passes items matching condition; rejects others |
| `transform` | XFORM | Rect, purple | `#a371f7` | Re-maps item fields; emits enriched item |
| `route` | ROUTE | Diamond | Sky `#4ea6dc` | Directs item to one of N outputs based on field value |
| `fork` | FORK | Rect, teal | `#26a69a` | Duplicates item to all outputs simultaneously |
| `merge` | MERGE | Rect, orange | `#f08030` | Accumulates N items; emits one merged item |
| `gate` | GATE | Rect, red | `#f85149` | Holds items until a TRIGGER_IN signal opens it |
| `delay` | DELAY | Rect, grey | `#6e7681` | Holds items for a configured number of ticks |
| `counter` | COUNT | Rect, yellow | `#d29922` | Counts throughput; fires EVENT_OUT at threshold |

### 16.2 Block descriptions

#### `filter`
Evaluates each item against an expression. Items that pass are forwarded to `out:accepted`;
items that fail go to `out:rejected`. Diamond shape signals "decision here".
```yaml
- id: validate_order
  type: filter
  inputs: [order]
  outputs: [order]
  reject_rate: 0.1          # 10% rejection in simulation
  steps:
    - {id: s1, type: expr, label: "Value check", expr: "item.value > 0"}
    - {id: s2, type: branch, label: "Route",
       branches: [{cond: "pass", next: "out:order"}, {cond: "fail", next: "out:rejected"}]}
```

#### `transform`
Applies a transformation to each item (field mapping, enrichment, type conversion). Purple
signals "data shape changes here".
```yaml
- id: enrich_order
  type: transform
  inputs: [raw_order]
  outputs: [order]
  steps:
    - {id: s1, type: assign, label: "Add timestamp", assign: "item.processed_at = now()"}
    - {id: s2, type: assign, label: "Format amount", assign: "item.amount_fmt = fmt(amount)"}
```

#### `route`
Reads a routing field and sends the item to matching output. Diamond shape (like filter):
"the path is decided here". Each output port corresponds to one route key.
```yaml
- id: region_router
  type: route
  inputs: [order]
  outputs: [order_eu, order_us, order_apac]
  steps:
    - {id: s1, type: branch, label: "Region",
       branches: [{cond: "EU", next: "out:order_eu"},
                  {cond: "US", next: "out:order_us"},
                  {cond: "APAC", next: "out:order_apac"}]}
```

#### `fork`
Clones one item into one copy per output port. Use for fan-out across parallel pipelines.
```yaml
- id: event_fan_out
  type: fork
  inputs: [event]
  outputs: [event_analytics, event_billing, event_audit]
```

#### `merge`
Waits until `min_queue` items are in its container, then emits a single merged item.
Use for batch collection, buffering, or join synchronisation.
```yaml
- id: batch_collector
  type: merge
  inputs: [part]
  outputs: [batch]
  min_queue: 5          # wait for 5 parts before emitting one batch
```

#### `gate`
Blocks all items until a TRIGGER_IN signal opens it. Once open, passes all queued items.
Can be configured to close again after `gate_drain` items (for pulse-release).
```yaml
- id: release_gate
  type: gate
  inputs: [product]
  outputs: [product]
  trigger_in: [open, close]
```

#### `delay`
Holds items for `delay_ticks` simulation ticks before forwarding. Models processing latency,
SLA buffers, or time-based release schedules.
```yaml
- id: cooling_period
  type: delay
  inputs: [result]
  outputs: [result]
  delay_ticks: 3        # hold for 3 ticks (~3 seconds in simulation)
```

#### `counter`
Counts items passing through. Fires `event_out.threshold_reached` at each multiple of
`count_threshold`. Use for capacity monitoring, KPI milestones, pacing.
```yaml
- id: order_counter
  type: counter
  inputs: [order]
  outputs: [order]
  count_threshold: 100      # fires signal every 100 items
  signal_outputs: [threshold_reached]
```

### 16.3 Combining logical blocks

Logical blocks compose naturally into pipeline control structures:

**Filter-then-fork pattern** — validate, then fan out to analytics and fulfilment:
```
order -> [validate:filter] -> [fan_out:fork] -> fulfillment_pipeline
                                             -> analytics_sink
```

**Merge-then-delay pattern** — collect a batch, then apply a release delay:
```
part -> [batch:merge, min_queue=10] -> [hold:delay, ticks=2] -> shipping
```

**Gated release with counter** — release in pulses when counter threshold signals gate open:
```
product -> [count:counter] -> [gate:gate] -> delivery
                    +--signal.threshold_reached--> gate.trigger_in.open
```

---

*End of Block Design v5.0*
*Core systems: §1–§11 | Mechanics index: §12 | Schema: §13–§14 | Container modes: §15 | Logical blocks: §16*
*Domain blueprints: DOMAIN-BLUEPRINTS.md | Visualization: VISUALIZATION-GUIDE.md | Full mechanics: MECHANICS-GUIDE.md*
