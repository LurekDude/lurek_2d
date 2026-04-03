# Graph Flow Simulation — Threading Opportunities

## Module Covered
- `src/graph/` — directed graph, flow simulation, Dijkstra

---

## Current State

The graph module simulates flow through a directed graph of nodes and edges,
used for economy/logistics/network games. The simulation has 5 phases per
tick:

1. **Decay** — reduce item lifetime, remove expired items
2. **Transit** — advance items in transit, detect arrivals
3. **Production** — produce items at source nodes
4. **Push flow** — push available items toward demand nodes
5. **Pull flow** — pull items from supply nodes toward demand

---

## The `.retain()` Problem

The most common bottleneck in Rust simulation loops is `.retain()` being
called multiple times per tick on large `Vec` collections:

```rust
// Pseudocode: happens multiple times per simulation step
self.items_in_transit.retain(|item| item.remaining_life > 0.0);
self.items_in_transit.retain(|item| !item.arrived);
```

Each `.retain()` is O(n) and shifts remaining elements. **Two retains = 2n
element moves**. For 10,000 items: 20,000 element moves per tick.

### Fix: Single-Pass Partition

```rust
// One pass instead of two
let mut arrived = Vec::new();
let mut expired = Vec::new();
self.items_in_transit.retain(|item| {
    if item.remaining_life <= 0.0 { expired.push(item.id); false }
    else if item.arrived { arrived.push(item.id); false }
    else { true }
});
// Process arrived and expired separately
self.handle_arrivals(arrived);
self.handle_expired(expired);
```

**Result**: n copies instead of 2n — 2× speedup with zero threading.

---

## Opportunity 1: Parallel Decay Phase

Decay phase updates item lifetime independently per item:

```rust
// src/graph/simulation.rs
use rayon::prelude::*;

pub fn decay_phase(&mut self, dt: f64) {
    // Each item's lifetime update is independent
    self.items_in_transit.par_iter_mut().for_each(|item| {
        item.remaining_life -= dt;
    });
    // Collect expired IDs in parallel
    let expired: Vec<ItemId> = self.items_in_transit
        .par_iter()
        .filter(|item| item.remaining_life <= 0.0)
        .map(|item| item.id)
        .collect();
    // Single serial removal pass
    self.items_in_transit.retain(|item| item.remaining_life > 0.0);
}
```

**Threshold**: parallelize when item count > 1,000.

---

## Opportunity 2: Parallel Transit Phase

Item transit (advance position, check arrival) is independent per item:

```rust
pub fn transit_phase(&mut self, dt: f64) {
    // Parallel progress update
    self.items_in_transit.par_iter_mut().for_each(|item| {
        item.progress += item.speed * dt;
    });
    
    // Parallel arrival detection (read-only on items)
    let arrived: Vec<usize> = self.items_in_transit
        .par_iter()
        .enumerate()
        .filter(|(_, item)| item.progress >= 1.0)
        .map(|(i, _)| i)
        .collect();
    
    // Process arrivals serially (modifies node state)
    for idx in arrived.into_iter().rev() {
        let item = self.items_in_transit.swap_remove(idx);
        self.deliver_item(item);
    }
}
```

**Speedup**: 4× for 1,000+ items in transit.

---

## Opportunity 3: Parallel Push/Pull Flow

If nodes are independent (no shared item pool between push/pull operations),
process them in parallel:

```rust
pub fn push_phase(&self) -> Vec<PushAction> {
    // Read-only phase: compute what SHOULD be pushed
    self.nodes
        .par_iter()
        .filter(|(_, node)| node.is_producer() && node.has_available_items())
        .flat_map(|(node_id, node)| {
            node.out_edges.iter()
                .filter_map(|edge_id| {
                    let edge = &self.edges[edge_id];
                    if self.can_send(node_id, edge) {
                        Some(PushAction { from: *node_id, via: *edge_id, item: node.peek_item() })
                    } else { None }
                })
                .collect::<Vec<_>>()
        })
        .collect()
}
// Apply actions serially
pub fn apply_push_actions(&mut self, actions: Vec<PushAction>) { ... }
```

This read-then-apply pattern avoids data races while keeping computation parallel.

---

## Dijkstra Parallelism (Multi-Source)

For logistics games that run Dijkstra from multiple sources simultaneously
(find all paths from 5 supply nodes to all demand nodes):

```rust
// src/graph/algorithms.rs
pub fn multi_source_dijkstra(
    graph: &Graph,
    sources: &[NodeId],
) -> Vec<HashMap<NodeId, f64>> {
    sources
        .par_iter()
        .map(|&src| dijkstra_from(graph, src))
        .collect()
}
```

Each source's Dijkstra is fully independent. **5 sources → 5× throughput.**

---

## GPU Flow Simulation (Large Graphs)

For graphs with 10,000+ nodes (city-scale logistics/transport sims):

```wgsl
// flow_sim.wgsl
@group(0) @binding(0) var<storage, read> capacities: array<f32>;
@group(0) @binding(1) var<storage, read> supply: array<f32>;
@group(0) @binding(2) var<storage, read_write> flow: array<f32>;
@group(0) @binding(3) var<storage, read> adjacency: array<u32>; // packed edge list

@compute @workgroup_size(64)
fn step_flow(@builtin(global_invocation_id) id: vec3<u32>) {
    let node = id.x;
    let available = supply[node];
    // Distribute flow to outgoing edges
    let edge_start = adjacency[node * 2u];
    let edge_count = adjacency[node * 2u + 1u];
    let per_edge = available / f32(edge_count);
    for (var i = 0u; i < edge_count; i++) {
        let edge = adjacency[edge_start + i];
        atomicAdd(&flow[edge], bitcast<u32>(per_edge));
    }
}
```

---

## Impact Summary

| Optimization | Effort | Speedup | When |
|--------------|--------|---------|------|
| Single-pass retain | 1 day | 2× | Always |
| Parallel decay | 2 days | 4× | >1k items |
| Parallel transit | 2 days | 4× | >1k items |
| Parallel push/pull | 3 days | 4× | >100 nodes |
| Multi-source Dijkstra | 1 day | N× (N sources) | Multiple sources |
| GPU flow simulation | 2 weeks | 100× | >10k nodes |
