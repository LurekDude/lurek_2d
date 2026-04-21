# Lua API Design — `lurek.sim.*`

> See also: [ARCHITECTURE.md](ARCHITECTURE.md) · [RUST-MODULE-DESIGN.md](RUST-MODULE-DESIGN.md) · [CONFIG-DECOMPOSITION.md](CONFIG-DECOMPOSITION.md)

---

## 1. Design Principles

- All functions live under `lurek.sim.*` — no bare globals, no external prefixes.
- The API is **synchronous from the script's perspective**. `lurek.sim.step(n)` blocks until n ticks are complete.
- Callbacks are optional. A blank script that just calls `lurek.sim.create(spec)` and `lurek.sim.run(sim)` is valid.
- Background batch runs use `lurek.thread` with channels — the simulation kernel itself is not threaded.
- Sensible defaults everywhere. A beginner should not need to specify more than `blocks` and `edges` for a working scenario.
- Errors return `nil, err_string` (two-return convention) rather than throwing whenever the operation is recoverable.

---

## 2. Lifecycle API

### `lurek.sim.create(spec) → sim, err`

Create a new simulation instance from a spec table. Parses, validates, and compiles the spec on the Rust side.

```lua
local sim, err = lurek.sim.create({
    blocks = { ... },
    edges  = { ... },
})
if not sim then error(err) end
```

### `lurek.sim.destroy(sim)`

Explicitly free the simulation. Happens automatically on GC if not called.

### `lurek.sim.load_toml(toml_string) → sim, err`

Convenience: parse a TOML string (e.g., from `lurek.data.parseToml` or a file read) into a spec and create the simulation in one call.

```lua
local source = lurek.filesystem.read("scenarios/factory.toml")
local sim, err = lurek.sim.load_toml(source)
```

### `lurek.sim.save_checkpoint(sim) → checkpoint_string, err`

Serialize the full current runtime state to an opaque string. Pass back to `lurek.sim.restore_checkpoint` to replay from exactly this tick.

### `lurek.sim.restore_checkpoint(sim, checkpoint_string) → ok, err`

Restore a simulation runtime from a previously saved checkpoint. The `ExecutionPlan` (compiled spec) is reused; only runtime state is replaced.

---

## 3. Step and Run API

### `lurek.sim.step(sim, n) → stats, err`

Advance the simulation by `n` ticks. Returns a summary stats table.

```lua
local stats, err = lurek.sim.step(sim, 100)
-- stats.ticks_run     int
-- stats.items_emitted int
-- stats.items_sinked  int
-- stats.events_logged int
-- stats.monitors_sampled int
-- stats.anomalies_active int
-- stats.approvals_pending int
-- stats.dlq_depth int
```

### `lurek.sim.run(sim) → stats, err`

Run to natural end (all sources drained and all queues empty) or to the configured max_ticks limit.

### `lurek.sim.run_until(sim, condition_fn) → stats, err`

Run until `condition_fn(snapshot)` returns true or natural end is reached.

```lua
local stats, err = lurek.sim.run_until(sim, function(snap)
    return snap.sink_total >= 1000
end)
```

### `lurek.sim.reset(sim) → ok, err`

Reset to tick 0 without recompiling the spec. Clears all queues, counters, monitor buffers, anomaly state.

---

## 4. Inspection API

### `lurek.sim.snapshot(sim) → table`

Return a shallow snapshot of the entire current simulation state as a Lua table.

```lua
local snap = lurek.sim.snapshot(sim)
-- snap.tick             int
-- snap.running          bool
-- snap.blocks           {[block_id] = BlockSnap}
-- snap.resources        {[resource_id] = ResourceSnap}
-- snap.dlq_depth        int
-- snap.approvals_pending int

-- BlockSnap:
-- .queue_depth          int
-- .items_processed      int
-- .circuit_state        "closed"|"open"|"half_open"
-- .anomaly_active       bool | nil
-- .utilization          float  (0..1)
```

### `lurek.sim.block_state(sim, block_id) → table, err`

Returns detailed state for one block only (cheaper than a full snapshot for targeted inspection).

### `lurek.sim.tick(sim) → int`

Returns the current tick counter.

---

## 5. Monitor API

### `lurek.sim.drain_monitors(sim) → {MonitorSample}`

Return and clear the current monitor sample buffer as a Lua array. Each element is a table:

```lua
local samples = lurek.sim.drain_monitors(sim)
for _, s in ipairs(samples) do
    -- s.monitor_id  string
    -- s.tick        int
    -- s.target      string|nil   (block_id if applicable)
    -- s.value       number|string
    -- s.alert       nil | { rule, threshold, actual, severity }
end
```

### `lurek.sim.peek_monitors(sim) → {MonitorSample}`

Same as `drain_monitors` but does not clear the buffer.

---

## 6. Anomaly API

### `lurek.sim.inject_anomaly(sim, anomaly_id) → ok, err`

Manually force-activate a declared anomaly by id, bypassing its trigger condition. Useful for testing specific failure scenarios.

### `lurek.sim.expire_anomaly(sim, anomaly_id) → ok, err`

Force-expire an active anomaly immediately.

### `lurek.sim.anomaly_status(sim) → {[anomaly_id] = status_string}`

Returns `"inactive"`, `"active"`, `"blocked"`, or `"expired"` for all anomalies declared in the spec.

---

## 7. Approval API

### `lurek.sim.pending_approvals(sim) → {ApprovalRequest}`

Return all items currently waiting for approval:

```lua
local reqs = lurek.sim.pending_approvals(sim)
for _, r in ipairs(reqs) do
    -- r.approval_id  string
    -- r.block_id     string
    -- r.item_type    string
    -- r.held_since   int   (tick)
    -- r.metadata     table (from item payload)
end
```

### `lurek.sim.approve(sim, approval_id) → ok, err`

Release a held item, allowing it to proceed to the next block.

### `lurek.sim.reject(sim, approval_id, reason) → ok, err`

Send the held item to the DLQ instead of proceeding.

---

## 8. DLQ and Replay API

### `lurek.sim.dlq_entries(sim) → {DlqEntry}`

Inspect all items currently in the dead-letter queue.

### `lurek.sim.replay_dlq(sim, entry_id) → ok, err`

Re-inject a specific DLQ entry back into its original target block's input queue.

### `lurek.sim.replay_all_dlq(sim) → count, err`

Re-inject all DLQ entries in FIFO order.

### `lurek.sim.clear_dlq(sim) → count`

Remove all DLQ entries.

---

## 9. Event Log API

### `lurek.sim.drain_events(sim) → {SimEvent}`

Return and clear the event log buffer:

```lua
local events = lurek.sim.drain_events(sim)
for _, e in ipairs(events) do
    -- e.kind       string  e.g. "BLOCK_EXEC", "ANOMALY_ACTIVATED", "DLQ_CAPTURED"
    -- e.tick       int
    -- e.block_id   string|nil
    -- e.item_id    int|nil
    -- e.payload    table|nil
end
```

---

## 10. Clock and Speed Control

### `lurek.sim.set_speed(sim, multiplier)`

Set the real-time speed multiplier (affects wall-clock display only; no effect in headless step mode).

### `lurek.sim.fast_forward(sim, target_tick) → stats, err`

Step from current tick to `target_tick` with full acceleration (no real-time throttling).

### `lurek.sim.set_calendar(sim, calendar_table) → ok, err`

Override or update the simulation calendar (time-of-day, day-of-week, holiday tables).

---

## 11. Utility

### `lurek.sim.version() → string`

Returns the blocksim kernel version string (for diagnostics).

### `lurek.sim.validate_spec(spec_table) → ok, err_table`

Validate a spec table without compiling or creating a runtime. Returns an array of validation errors if any.

```lua
local ok, errs = lurek.sim.validate_spec(spec)
if not ok then
    for _, e in ipairs(errs) do
        print(e.field, e.message)
    end
end
```

---

## 12. Example: Minimal Run

```lua
local sim, err = lurek.sim.create({
    config = { max_ticks = 1000 },
    blocks = {
        { id = "source",    type = "source",    ports = {{ id = "out", side = "right", kind = "data" }},
          container = { emit_rate = 2 } },
        { id = "transform", type = "transform", ports = {{ id = "in", side = "left", kind = "data" },
                                                         { id = "out", side = "right", kind = "data" }} },
        { id = "sink",      type = "sink",      ports = {{ id = "in", side = "left", kind = "data" }} },
    },
    edges = {
        { from = "source.out",    to = "transform.in" },
        { from = "transform.out", to = "sink.in" },
    },
    monitors = {
        { id = "sink_total", type = "throughput", target = "sink" },
    },
})
assert(sim, err)

local stats = lurek.sim.run(sim)
print("Ticks:", stats.ticks_run)
print("Sinked:", stats.items_sinked)

local samples = lurek.sim.drain_monitors(sim)
for _, s in ipairs(samples) do
    print(s.monitor_id, s.tick, s.value)
end

lurek.sim.destroy(sim)
```

---

## 13. Example: Multi-run with Anomaly Comparison

```lua
local spec = lurek.data.parseToml(lurek.filesystem.read("scenarios/factory.toml"))

-- Baseline run
local baseline, err = lurek.sim.load_toml(lurek.data.encodeToml(spec))
assert(baseline, err)
lurek.sim.run(baseline)
local baseline_samples = lurek.sim.drain_monitors(baseline)
lurek.sim.destroy(baseline)

-- Anomaly run
local anomaly_spec = lurek.data.mergeTable(spec, {
    anomalies = {{ id = "machine_jam", type = "block_state", target = "press",
                   trigger = { after_tick = 300 }, effect = { pause = true },
                   expiry = { after_ticks = 50 } }}
})
local variant, err2 = lurek.sim.create(anomaly_spec)
assert(variant, err2)
lurek.sim.run(variant)
local variant_samples = lurek.sim.drain_monitors(variant)
lurek.sim.destroy(variant)

-- Post-run comparison using lurek.dataframe
local df_base = lurek.dataframe.fromArray(baseline_samples, {"monitor_id","tick","value"})
local df_var  = lurek.dataframe.fromArray(variant_samples,  {"monitor_id","tick","value"})
-- ... further analysis ...
```
