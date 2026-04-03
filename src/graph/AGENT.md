# `graph` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Tier 2 — Engine Extensions |
| **Lua API** | `luna.graph` |
| **Source** | `src/graph/` |
| **Tests** | `tests/graph_tests.rs` |
| **Lua Tests** | `tests/lua/unit/test_graph.lua` |

## Summary

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

## Source Files

| File | Purpose |
|------|---------|
| `algorithms.rs` | Graph algorithms — connected components, cycle detection, topological sort |
| `core.rs` | Top-level directed graph container with node, edge, and item management |
| `edge.rs` | Graph edge — a directed connection between nodes |
| `item.rs` | Graph item — a typed entity that flows through the network |
| `node.rs` | Graph node — a vertex with capacity, flow control, conversion rules, and queuing |
| `simulation.rs` | Simulation engine — update(dt) and step() for item flow, decay, transit, and... |
| `supply_demand.rs` | Supply/demand processing — match demands to supplies and route items |
| `traversal.rs` | Dijkstra pathfinding and reachability queries on the graph |

## Submodules

### `graph::algorithms`

Graph algorithms — connected components, cycle detection, topological sort.

### `graph::core`

Top-level directed graph container with node, edge, and item management.

- **`GraphStats`** (struct): Statistics snapshot of the graph state. Consult the module-level documentation for the broader usage context and...
- **`Graph`** (struct): A directed graph with typed nodes, edges, and flowing items.

### `graph::edge`

Graph edge — a directed connection between nodes.

- **`Edge`** (struct): A directed connection between two nodes in the graph.

### `graph::item`

Graph item — a typed entity that flows through the network.

- **`ItemPosition`** (enum): Where a `GraphItem` currently resides. Consult the module-level documentation for the broader usage context and...
- **`GraphItem`** (struct): A typed entity that flows through the graph network.

### `graph::node`

Graph node — a vertex with capacity, flow control, conversion rules, and queuing.

- **`OverflowPolicy`** (enum): What happens when items arrive at a full node.
- **`FlowMode`** (enum): How a node participates in automatic item flow.
- **`ConversionRule`** (struct): A rule that converts N input items of one type into M output items of another.
- **`Supply`** (struct): A supply declaration on a node. Consult the module-level documentation for the broader usage context and preconditions.
- **`Demand`** (struct): A demand declaration on a node. Consult the module-level documentation for the broader usage context and preconditions.
- **`Node`** (struct): A vertex in the graph with capacity, flow control, conversion, and queuing.

### `graph::simulation`

Simulation engine — update(dt) and step() for item flow, decay, transit, and conversions.

- **`GraphEvent`** (enum): Events generated during simulation for the Lua callback layer to dispatch.

### `graph::supply_demand`

Supply/demand processing — match demands to supplies and route items.

### `graph::traversal`

Dijkstra pathfinding and reachability queries on the graph.

- **`PathResult`** (struct): Result of a successful pathfinding query.

## Key Types

### Structs

#### `graph::node::ConversionRule`

A rule that converts N input items of one type into M output items of another.

#### `graph::node::Demand`

A demand declaration on a node. Consult the module-level documentation for the broader usage context and preconditions.

#### `graph::edge::Edge`

A directed connection between two nodes in the graph.

#### `graph::core::Graph`

A directed graph with typed nodes, edges, and flowing items.

#### `graph::item::GraphItem`

A typed entity that flows through the graph network.

#### `graph::core::GraphStats`

Statistics snapshot of the graph state. Consult the module-level documentation for the broader usage context and...

#### `graph::node::Node`

A vertex in the graph with capacity, flow control, conversion, and queuing.

#### `graph::traversal::PathResult`

Result of a successful pathfinding query.

#### `graph::node::Supply`

A supply declaration on a node. Consult the module-level documentation for the broader usage context and preconditions.

### Enums

#### `graph::node::FlowMode`

How a node participates in automatic item flow.

#### `graph::simulation::GraphEvent`

Events generated during simulation for the Lua callback layer to dispatch.

#### `graph::item::ItemPosition`

Where a `GraphItem` currently resides. Consult the module-level documentation for the broader usage context and...

#### `graph::node::OverflowPolicy`

What happens when items arrive at a full node.

## Lua API

Exposed under `luna.graph.*` by `src/lua_api/graph_api/`.

## Item Summary

| Kind | Count |
|------|-------|
| `enum` | 4 |
| `mod` | 8 |
| `struct` | 9 |
| **Total** | **21** |

