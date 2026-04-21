# Configuration Decomposition

> Shows how every configuration concern from the source project maps to TOML, Lua, or Rust defaults in the Lurek2D target stack.

---

## Principle

The source project uses YAML as a single flat file for everything: block topology, behavioral params, anomaly profiles, monitor declarations, resource tables, and system-level config. In Lurek2D, these concerns are split across three layers with well-defined ownership:

| Layer | Format | Owned by | Role |
|---|---|---|---|
| Static authored data | TOML | Human author / file | Block catalogs, resource tables, schedules, thresholds, anomaly profiles |
| Runtime graph assembly | Lua | Script author | Wiring composites, selecting blueprints, parameterizing scenarios |
| Kernel hardcoded defaults | Rust | `SimConfig::default()` | Fallback values; never needs to be specified for basic use |

---

## 1. Simulation Config

### Source YAML

```yaml
config:
  max_ticks: 5000
  tick_unit: "minute"
  seed: 42
  warmup_ticks: 100
  fast_forward: false
```

### TOML target

```toml
# scenarios/config.toml
[config]
max_ticks   = 5000
tick_unit   = "minute"
seed        = 42
warmup_ticks = 100
fast_forward = false
```

### Lua assembly

```lua
local cfg = lurek.data.parseToml(lurek.filesystem.read("scenarios/config.toml"))
local sim = lurek.sim.create({ config = cfg.config, blocks = ..., edges = ... })
```

### Rust default

`SimConfig::default()` fills: `max_ticks = u64::MAX`, `tick_unit = "tick"`, `seed = 0`, `warmup_ticks = 0`, `fast_forward = false`.

---

## 2. Block Definitions

### Source YAML

```yaml
blocks:
  - id: press
    type: transform
    block_class: machine
    item_types: [raw_part]
    container:
      capacity: 5
      mode: fifo
    script:
      processing_time: 3
      output_type: pressed_part
    circuit_breaker:
      failure_threshold: 3
      recovery_timeout: 20
```

### TOML target (catalog pattern)

Large reusable block definitions live in a shared TOML catalog. Scenarios refer to them by `catalog_ref`:

```toml
# catalogs/machines.toml
[[blocks]]
id            = "press_template"
type          = "transform"
block_class   = "machine"
item_types    = ["raw_part"]

[blocks.container]
capacity = 5
mode     = "fifo"

[blocks.script]
processing_time = 3
output_type     = "pressed_part"

[blocks.circuit_breaker]
failure_threshold = 3
recovery_timeout  = 20
```

### Lua instantiation

Scenario scripts load the catalog and instantiate blocks by reference, overriding per-instance params:

```lua
local catalog = lurek.data.parseToml(lurek.filesystem.read("catalogs/machines.toml"))

local function machine(id, overrides)
    local spec = lurek.table.deepcopy(catalog.blocks_by_id[id])
    return lurek.table.merge(spec, overrides or {})
end

local blocks = {
    machine("press_template", { id = "press_A" }),
    machine("press_template", { id = "press_B", container = { capacity = 10 } }),
}
```

### Rule

- **Default values for block mechanics**: TOML.
- **Per-instance overrides and wiring**: Lua.
- **Hard kernel defaults** (e.g., container.capacity = 1 if not set): Rust `BlockSpec::default()`.

---

## 3. Edge / Topology

### Source YAML

```yaml
edges:
  - id: e1
    from: source.out
    to: press.in
    kind: data
  - id: e2
    from: press.out
    to: sink.in
    kind: data
```

### Target: Lua only

Topology wiring is pure Lua. Edges are always assembled at runtime, not stored in TOML. This is because edge topology is the most scenario-specific part of the description.

```lua
local edges = {
    { from = "source.out",  to = "press.in",  kind = "data" },
    { from = "press.out",   to = "sink.in",   kind = "data" },
}
```

### Composites

Composite wiring is assembled in Lua using helpers from `library/blocksim/`:

```lua
local blocksim = require("library.blocksim")

local manufacturing_line = blocksim.composite("line_A", {
    inner_blocks = { machine("press_template"), machine("weld_template") },
    inner_edges  = { { from = "press.out", to = "weld.in" } },
    left_port    = "press.in",
    right_port   = "weld.out",
})
```

---

## 4. Resources

### Source YAML

```yaml
resources:
  - id: operator
    total: 3
    replenish: tick
  - id: crane
    total: 1
    replenish: none
```

### TOML target

```toml
# catalogs/resources.toml
[[resources]]
id         = "operator"
total      = 3
replenish  = "tick"

[[resources]]
id         = "crane"
total      = 1
replenish  = "none"
```

### Rule

Resource pool definitions are always static authored data → **TOML**.
Resource acquisition rules are part of block definitions → **TOML** (block catalog) or **Lua** (per-instance override).

---

## 5. Monitors

### Source YAML

```yaml
monitors:
  - id: press_util
    type: utilization
    target: press
    interval: 10
    alert:
      rule: lt
      threshold: 0.7
      severity: warn
```

### TOML target

```toml
# scenarios/monitors.toml
[[monitors]]
id       = "press_util"
type     = "utilization"
target   = "press"
interval = 10

[monitors.alert]
rule      = "lt"
threshold = 0.7
severity  = "warn"
```

### Lua assembly

```lua
local monitors = lurek.data.parseToml(lurek.filesystem.read("scenarios/monitors.toml"))
local sim = lurek.sim.create({
    blocks = ..., edges = ...,
    monitors = monitors.monitors,
})
```

### Rule

Monitor instrument definitions are static per scenario → **TOML**.
Dynamic monitor enabling (turning on/off monitors at runtime) → **Lua** via `lurek.sim` API (TBD in V2).

---

## 6. Anomalies

### Source YAML

```yaml
anomalies:
  - id: machine_jam
    type: block_state
    target: press
    trigger:
      type: after_tick
      value: 300
    effect:
      pause: true
    expiry:
      type: after_ticks
      value: 50
```

### TOML target (anomaly profile catalog)

```toml
# catalogs/anomalies.toml
[[anomalies]]
id     = "machine_jam"
type   = "block_state"
target = "press"

[anomalies.trigger]
type  = "after_tick"
value = 300

[anomalies.effect]
pause = true

[anomalies.expiry]
type  = "after_ticks"
value = 50
```

### Lua: scenario selection

```lua
local profiles = lurek.data.parseToml(lurek.filesystem.read("catalogs/anomalies.toml"))

-- Baseline: no anomalies
local base_sim = lurek.sim.create({ blocks = blocks, edges = edges, monitors = monitors })

-- Anomaly scenario: select named profiles
local anomaly_sim = lurek.sim.create({
    blocks   = blocks,
    edges    = edges,
    monitors = monitors,
    anomalies = { profiles.by_id["machine_jam"] },
})
```

### Lua: ad-hoc runtime injection

For testing without pre-declaring an anomaly in the spec, inject at runtime:

```lua
lurek.sim.inject_anomaly(sim, "machine_jam")   -- force-activate a declared anomaly
```

Note: `inject_anomaly` only works for anomalies declared in the spec. Ad-hoc injection of anomalies not in the spec is not supported in V1.

---

## 7. KPI and Analytics Config

Analytics selection lives entirely in **Lua**, not TOML, because:
- KPI relationships (which monitors to compare, which filter rules to apply) are scenario-specific query logic.
- `lurek.dataframe` already accepts Lua tables and method chaining natively.

```lua
local function kpi_throughput(samples_df, block_id)
    return samples_df
        :filter(function(row) return row.monitor_id == "throughput_" .. block_id end)
        :groupBy("tick")
        :agg({ value = "avg" })
end
```

Static threshold values used to decide pass/fail in reports may live in TOML if they are project-level standards:

```toml
# standards/kpis.toml
[throughput]
min_avg = 5.0
[utilization]
target  = 0.85
```

---

## 8. Module Feature Flag

```toml
# conf.toml (game/project root)
[modules]
blocksim = true
```

Default: `false` (module is opt-in, consistent with `gui`, `terminal`, etc.).

When `false`: `lurek.sim` is nil; scripts using it get a clear nil-check error message from the bridge.

---

## 9. Configuration Decomposition Summary Table

| Configuration concern | Format | Location |
|---|---|---|
| Simulation lifecycle config (max_ticks, seed, etc.) | TOML | `scenarios/<name>/config.toml` |
| Block definitions / catalog | TOML | `catalogs/blocks/<domain>.toml` |
| Edge topology and wiring | Lua | Scenario script |
| Composite assembly | Lua | `library/blocksim/` helpers |
| Resource pool definitions | TOML | `catalogs/resources.toml` |
| Monitor instrument declarations | TOML | `scenarios/<name>/monitors.toml` |
| Anomaly profiles | TOML | `catalogs/anomalies/<domain>.toml` |
| Scenario variant selection | Lua | Scenario script |
| KPI analysis logic | Lua | Report script / `library/blocksim/` |
| KPI pass/fail thresholds | TOML | `standards/kpis.toml` |
| Engine module flag | TOML | `conf.toml` |
| Scheduling / calendar data | TOML | `catalogs/schedules.toml` |
| Maintenance window tables | TOML | `catalogs/maintenance.toml` |
| Blueprint patterns | Lua | `library/blocksim/blueprints/` |
| Multi-run orchestration | Lua | Scenario script |
| Live dashboard queries | Lua | Dashboard script |
