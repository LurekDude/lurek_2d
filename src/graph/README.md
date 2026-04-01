# `src/graph/` — Directed Graph with Item Flow Simulation

## Purpose

The graph module provides a general-purpose directed/undirected weighted graph
with a classical algorithm suite.  Game developers reach for it whenever their
data is naturally relational rather than spatial: dialogue trees where nodes
are lines and edges are player choices, quest dependency systems where
completing a quest unlocks others, skill trees, navigation mesh connectivity
analysis, and dungeon layout validation.  Any time the question is "can I get
from A to B?" or "what is the cheapest path through this network?" the graph
module is the right tool.

Nodes carry arbitrary Lua-table metadata (name, colour, position, game state)
and optional string labels.  Edges carry an optional f64 weight.  The graph
supports both directed and undirected modes; the algorithm suite includes BFS
(level-order traversal), DFS (pre- and post-order), Dijkstra shortest path,
A* with a Lua-supplied heuristic function, topological sort with cycle
detection, and Tarjan's strongly-connected-components for identifying
reachability clusters in a directed graph.

## Architecture

```
Graph (HashMap-based directed graph)
  │
  ├── Node ── 23+ fields
  │     ├── Capacity, throughput, OverflowPolicy
  │     ├── FlowMode (Push/Pull/Both/None)
  │     ├── ConversionRule (type A → type B)
  │     ├── Supply / Demand definitions
  │     ├── Queue (FIFO item buffer)
  │     └── Push/pull timers for rate limiting
  │
  ├── Edge ── weighted connections
  │     ├── travel_time, weight, speed_modifier
  │     ├── cooldown timer, bidirectional flag
  │     └── allowed_types filter (whitelist)
  │
  ├── GraphItem ── items that flow through the graph
  │     ├── ItemPosition: AtNode | InTransit | Unplaced
  │     ├── decay, priority, type_name
  │     └── payload HashMap
  │
  ├── algorithms.rs ── graph theory algorithms
  │     ├── get_components (BFS)
  │     ├── has_cycle (DFS 3-color)
  │     └── topological_sort (Kahn's algorithm)
  │
  ├── pathfinding.rs ── shortest path
  │     ├── find_path / find_path_for_item (Dijkstra)
  │     ├── get_distance, get_reachable, get_neighbors
  │     └── PathResult struct
  │
  ├── simulation.rs ── tick-based flow engine
  │     ├── update(dt) → Vec<GraphEvent>
  │     ├── 7-phase pipeline: decay → transit → cooldowns
  │     │   → push_flow → pull_flow → conversions → queues
  │     └── GraphEvent enum (11 variants)
  │
  └── supply_demand.rs ── economic simulation
        ├── process_demand() → Vec<GraphEvent>
        └── Priority-ordered demand fulfillment via pathfinding
```

### How It Works

The graph is backed by a `HashMap<NodeId, Vec<(NodeId, f64)>>` adjacency list.
This is efficient for sparse graphs — typical in games where most nodes have
two to eight neighbours — and makes `add_edge` O(1) amortised.  Node metadata
is stored in a parallel `HashMap<NodeId, LuaRegistryKey>` so the hot
adjacency data stays cache-friendly in BFS/DFS traversals.

A* accepts a Lua function reference as the heuristic, stored as a
`mlua::RegistryKey`.  The Lua call happens inside the Rust search loop; for
performance-critical graphs a built-in Euclidean distance heuristic avoids the
Lua boundary entirely and is selected by passing `nil` as the heuristic.

Topological sort uses Kahn's algorithm (BFS over in-degree counts) rather
than DFS post-order so that cycles can be detected and reported with the full
cycle node list rather than just a boolean flag.  Tarjan's SCC implementation
uses the standard iterative stack formulation to avoid recursion-depth limits
on very large graphs.

### Dependency Direction

```
graph/ ──────► (none)
```

**Leaf module** — zero Luna2D dependencies. Pure data structures and algorithms.

---

## File-by-File Analysis

### `mod.rs` — Module Root

Re-exports all public types from sub-modules.

**~20 lines** — re-exports.

---

### `core.rs` — `Graph` (Core Data Structure)

**~450 lines** | HashMap-based directed graph with nodes, edges, and items.

#### Struct: `Graph`

```rust
pub struct Graph {
    nodes: HashMap<u64, Node>,
    edges: HashMap<u64, Edge>,
    items: HashMap<u64, GraphItem>,
    next_id: u64,
    // ... statistics tracking
}
```

Methods: `new`, `add_node`, `add_edge`, `add_item`, `remove_node`/`edge`/`item`,
`get_node`/`edge`/`item` (and `_mut` variants), `node_count`, `edge_count`,
`item_count`, `get_stats` → `GraphStats`.

**Design**: Cascading deletion — removing a node also removes all connected edges
and items at that node. Uses `u64` IDs for stable references.

---

### `node.rs` — `Node` (Graph Vertex)

**~500 lines** | Feature-rich node with 23+ fields for flow simulation.

#### Key Fields

| Field | Type | Purpose |
|-------|------|---------|
| `capacity` | `u32` | Max items at this node |
| `throughput` | `f32` | Items per second |
| `overflow_policy` | `OverflowPolicy` | What happens when full |
| `flow_mode` | `FlowMode` | Push/Pull/Both/None |
| `conversion_rule` | `Option<ConversionRule>` | Type transformation |
| `supply` | `Option<Supply>` | Item generation |
| `demand` | `Option<Demand>` | Item consumption |
| `queue` | `VecDeque<u64>` | FIFO item buffer |

#### Enums

| Enum | Variants |
|------|----------|
| `OverflowPolicy` | Reject, DropOldest, DropNewest, Replace |
| `FlowMode` | Push, Pull, Both, None |
| `ConversionRule` | `from_type`, `to_type`, `ratio`, `time` |

---

### `edge.rs` — `Edge` (Graph Connection)

**~150 lines** | Weighted directional connection between nodes.

#### Key Fields

| Field | Type | Purpose |
|-------|------|---------|
| `from` / `to` | `u64` | Source/destination node IDs |
| `travel_time` | `f32` | Seconds for item transit |
| `weight` | `f32` | Pathfinding cost |
| `speed_modifier` | `f32` | Transit speed multiplier |
| `cooldown` | `f32` | Minimum time between sends |
| `bidirectional` | `bool` | Allow reverse traversal |
| `allowed_types` | `Option<HashSet<String>>` | Whitelist filter |

---

### `item.rs` — `GraphItem` (Flow Object)

**~150 lines** | Items that move through the graph.

#### Enum: `ItemPosition`

`AtNode(u64) | InTransit { from, to, progress } | Unplaced`

#### Key Fields

| Field | Type | Purpose |
|-------|------|---------|
| `type_name` | `String` | Item type for filtering |
| `position` | `ItemPosition` | Current location |
| `decay` | `Option<f32>` | Remaining lifetime |
| `priority` | `i32` | Processing priority |
| `payload` | `HashMap<String, f64>` | Custom data |

---

### `algorithms.rs` — Graph Algorithms

**~300 lines** | Classical graph theory algorithms.

| Function | Algorithm | Returns |
|----------|-----------|---------|
| `get_components(graph)` | BFS | Vec<Vec<u64>> (connected components) |
| `has_cycle(graph)` | DFS 3-color | bool |
| `topological_sort(graph)` | Kahn's algorithm | Option<Vec<u64>> (None if cyclic) |

---

### `pathfinding.rs` — Shortest Path

**~400 lines** | Dijkstra-based pathfinding with edge weight awareness.

| Function | Purpose |
|----------|---------|
| `find_path(graph, from, to)` | Shortest path by edge weight |
| `find_path_for_item(graph, item, from, to)` | Path respecting item type filters |
| `get_distance(graph, from, to)` | Path cost without full path |
| `get_reachable(graph, from)` | All reachable node IDs |
| `get_neighbors(graph, node)` | Direct neighbors |

---

### `simulation.rs` — Tick-Based Flow Simulation

**~449 lines** | Deterministic simulation pipeline with event collection.

#### 7-Phase Pipeline per `update(dt)`

1. **Decay** — reduce item lifetimes, destroy expired
2. **Transit** — advance in-transit items, deliver arrivals
3. **Cooldowns** — update edge cooldown timers
4. **Push flow** — nodes with FlowMode::Push send items along edges
5. **Pull flow** — nodes with FlowMode::Pull request items from neighbors
6. **Conversions** — apply ConversionRules at nodes
7. **Queues** — process node queues (FIFO)

#### Enum: `GraphEvent` (11 variants)

`ItemEnter | ItemLeave | ItemDecay | ItemConvert | ItemLost |
EdgeEnter | EdgeLeave | DemandFulfilled | SupplyDepleted |
ItemQueued | ItemDequeued`

---

### `supply_demand.rs` — Economic Simulation

**~132 lines** | Demand-priority fulfillment using pathfinding.

`process_demand()` iterates demands by priority, finds supply sources via
pathfinding, creates items and routes them. Returns events for fulfilled
demands and depleted supplies.

---

## Cross-Cutting Concerns

### Lua Integration

The Lua bridge lives in `src/lua_api/graph_api.rs`, exposing the graph under
`luna.graph.*` with UserData wrappers.

### Usage from Lua

```lua
-- Create a supply chain graph
local graph = luna.graph.newGraph()
local mine = graph:addNode({supply = {type = "ore", rate = 1.0}})
local factory = graph:addNode({conversion = {from = "ore", to = "metal", ratio = 2}})
local warehouse = graph:addNode({capacity = 100})

graph:addEdge(mine, factory, {travel_time = 5.0})
graph:addEdge(factory, warehouse, {travel_time = 3.0})

-- Simulate
local events = graph:update(dt)
```
