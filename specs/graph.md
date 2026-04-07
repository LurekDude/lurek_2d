# `graph` — Agent Reference

| Property       | Value                                                |
|----------------|------------------------------------------------------|
| **Tier**       | Tier 2 — Reusable Engine Extensions                  |
| **Status**     | Implemented — Full                                   |
| **Lua API**    | `luna.graph`                                         |
| **Source**      | `src/graph/`                                         |
| **Rust Tests** | `tests/rust/unit/graph_tests.rs`                     |
| **Lua Tests**  | `tests/lua/unit/test_graph.lua`                      |
| **Architecture** | —                                                  |

## Summary

The graph module provides a general-purpose directed weighted graph with item flow simulation, Dijkstra pathfinding, and a classical algorithm suite. It is a Tier 2 engine extension that depends only on Baseline (`math`, `engine`) and no Tier 1 modules. Game developers use it whenever their data is naturally relational rather than spatial: dialogue trees where nodes are lines and edges are player choices, quest dependency systems where completing a quest unlocks others, skill trees, resource production pipelines, logistics networks, and dungeon layout validation.

Nodes are richly configurable vertices with capacity limits, overflow policies (reject, destroy, queue), flow modes (passive, push, pull, both), rate-limited push/pull timers, conversion rules that transform N items of type A into M items of type B, supply and demand declarations, FIFO queues, and freeform string tags. Edges are directed connections carrying weight (for pathfinding), travel time, speed modifiers, cooldown timers, capacity limits, bidirectional flags, and item-type allow-lists. Items are typed entities that flow through the network with optional decay timers, priority ordering, and position tracking (at-node, in-transit with progress fraction, or unplaced).

The simulation engine (`update(dt)`) processes seven phases per tick: decay → transit → cooldowns → push flow → pull flow → conversions → queue dequeue. Each phase emits `GraphEvent` variants that the Lua API dispatches to registered callbacks. A separate `process_demand()` pass matches demand declarations to supply declarations using priority ordering and shortest-path routing.

The module intentionally does NOT provide visual rendering helpers, spatial hashing, or A* with heuristics — for spatial pathfinding on grids, use `src/pathfinding/` instead. The graph module operates on abstract node IDs, not world-space coordinates.

## Architecture

```
Graph (HashMap-based directed graph)
  │
  ├── Node ── vertex with 22+ configurable fields
  │     ├── capacity, active, overflow_policy, flow_mode
  │     ├── push_rate, pull_rate, push_filter, pull_filter
  │     ├── process_time, queue_enabled, queue_capacity
  │     ├── ConversionRule (in_type → out_type, in_count:out_count)
  │     ├── Supply / Demand declarations
  │     ├── VecDeque<u64> queue (FIFO item buffer)
  │     ├── Vec<u64> items (currently held)
  │     └── HashSet<String> tags
  │
  ├── Edge ── directed connection with flow control
  │     ├── weight, travel_time, speed_modifier
  │     ├── capacity, throughput, cooldown, cooldown_timer
  │     ├── bidirectional flag, active flag
  │     ├── allowed_types filter (HashSet<String>)
  │     └── items_in_transit (Vec<u64>)
  │
  ├── GraphItem ── typed entity flowing through the network
  │     ├── ItemPosition: AtNode(u64) | InTransit{edge_id,progress} | Unplaced
  │     ├── item_type, decay_time, remaining_life, alive
  │     └── priority (i32)
  │
  ├── algorithms.rs ── graph theory algorithms (impl Graph)
  │     ├── get_components() → Vec<Vec<u64>> (BFS, weakly connected)
  │     ├── has_cycle() → bool (DFS 3-colour)
  │     └── topological_sort() → Option<Vec<u64>> (Kahn's algorithm)
  │
  ├── pathfinding.rs ── shortest-path queries (impl Graph)
  │     ├── find_path(from, to) → Option<PathResult> (Dijkstra)
  │     ├── find_path_for_item(item_id, from, to) → Option<PathResult>
  │     ├── get_distance(from, to) → Option<f64>
  │     ├── get_reachable(from, max_dist) → Vec<u64>
  │     └── get_neighbors(node_id) → Vec<u64>
  │
  ├── simulation.rs ── tick-based flow engine (impl Graph)
  │     ├── update(dt) → Vec<GraphEvent>
  │     ├── step() → Vec<GraphEvent>  (= update(1.0))
  │     └── 7-phase pipeline: decay → transit → cooldowns
  │         → push_flow → pull_flow → conversions → queues
  │
  └── supply_demand.rs ── economic simulation (impl Graph)
        ├── process_demand() → Vec<GraphEvent>
        └── Priority-ordered demand fulfillment via pathfinding
```

## Source Files

| File               | Purpose                                                                      |
|--------------------|------------------------------------------------------------------------------|
| `mod.rs`           | Module declarations, re-exports of public types                              |
| `algorithms.rs`    | Graph algorithms — connected components (BFS), cycle detection (DFS), topological sort (Kahn's) |
| `core.rs`          | `Graph` struct — node, edge, and item CRUD, stats, edge queries              |
| `edge.rs`          | `Edge` struct — directed connection with capacity, cooldown, type filtering  |
| `item.rs`          | `GraphItem` and `ItemPosition` — typed flowing entities with decay and priority |
| `node.rs`          | `Node`, `OverflowPolicy`, `FlowMode`, `ConversionRule`, `Supply`, `Demand`  |
| `pathfinding.rs`   | `PathResult` and Dijkstra shortest-path, reachability, neighbour queries     |
| `simulation.rs`    | `GraphEvent` enum and 7-phase simulation pipeline (`update`/`step`)          |
| `supply_demand.rs` | Supply/demand matching with priority-ordered fulfillment via pathfinding     |
| `graph.rs`         | Legacy duplicate of `core.rs` — not declared in `mod.rs`, dead code          |
| `traversal.rs`     | Legacy duplicate of `pathfinding.rs` — not declared in `mod.rs`, dead code   |

## Submodules

### `graph::algorithms`

Graph algorithms — connected components, cycle detection, topological sort. All methods are `impl Graph` extension methods.

### `graph::core`

Top-level directed graph container with node, edge, and item management.

- **`GraphStats`** (struct): Statistics snapshot with counts of nodes, edges, items, active entities, in-transit items, demand/supply totals, and queued items.
- **`Graph`** (struct): A directed graph with `HashMap<u64, Node>` nodes, `HashMap<u64, Edge>` edges, and `HashMap<u64, GraphItem>` items. Provides CRUD for all three entity types, `send_item` for starting transit, `get_stats` for aggregate metrics, and edge queries (`get_outgoing_edges`, `get_incoming_edges`, `get_edge_between`).

### `graph::edge`

Graph edge — a directed connection between two nodes with flow control.

- **`Edge`** (struct): A directed connection with weight, travel time, speed modifier, capacity, throughput, cooldown, bidirectional flag, item-type allow-list, and in-transit item tracking.

### `graph::item`

Graph item — a typed entity that flows through the network.

- **`ItemPosition`** (enum): Where a `GraphItem` resides — `AtNode(u64)`, `InTransit { edge_id, progress }`, or `Unplaced`.
- **`GraphItem`** (struct): A typed entity with `item_type`, `decay_time`, `remaining_life`, `alive` flag, `priority`, and `position`.

### `graph::node`

Graph node — a vertex with capacity, flow control, conversion rules, and queuing.

- **`OverflowPolicy`** (enum): What happens when items arrive at a full node — `Reject`, `Destroy`, or `Queue`.
- **`FlowMode`** (enum): How a node participates in automatic item flow — `Passive`, `Push`, `Pull`, or `Both`.
- **`ConversionRule`** (struct): Converts `in_count` items of `in_type` into `out_count` items of `out_type`.
- **`Supply`** (struct): A supply declaration with `item_type` and `quantity` (`-1` = unlimited).
- **`Demand`** (struct): A demand declaration with `item_type`, `quantity`, and `priority`.
- **`Node`** (struct): A vertex with 22+ fields covering capacity, active state, overflow policy, flow mode, push/pull rates and filters, process time, queue, items, conversion rules, demand/supply declarations, and tags.

### `graph::pathfinding`

Dijkstra pathfinding and reachability queries on the graph.

- **`PathResult`** (struct): Result of a successful pathfinding query with `nodes: Vec<u64>`, `edges: Vec<u64>`, and `cost: f64`.

### `graph::simulation`

Simulation engine — `update(dt)` and `step()` for item flow, decay, transit, and conversions.

- **`GraphEvent`** (enum): Events generated during simulation — 11 variants: `ItemEnter`, `ItemLeave`, `ItemDecay`, `ItemConvert`, `ItemLost`, `EdgeEnter`, `EdgeLeave`, `DemandFulfilled`, `SupplyDepleted`, `ItemQueued`, `ItemDequeued`.

### `graph::supply_demand`

Supply/demand processing — matches demands to supplies using priority ordering and Dijkstra pathfinding, creating and routing items automatically.

## Key Types

### Structs

#### `graph::node::ConversionRule`

A rule that converts `in_count` items of `in_type` into `out_count` items of `out_type`. Keyed by `in_type` in the node's `conversions` HashMap.

#### `graph::node::Demand`

A demand declaration on a node with `item_type`, `quantity`, and `priority` (higher = more urgent). Used by `process_demand()` to match supplies to demands.

#### `graph::node::Supply`

A supply declaration on a node with `item_type` and `quantity`. A quantity of `-1` means unlimited supply.

#### `graph::edge::Edge`

A directed connection between two nodes. Carries `weight` (pathfinding cost), `travel_time` (seconds for transit), `speed_modifier`, `capacity` (max in-transit items, `-1` = unlimited), `throughput`, `cooldown` / `cooldown_timer`, `bidirectional` flag, `active` flag, and `allowed_types` item-type whitelist.

#### `graph::core::Graph`

The top-level directed graph container. Stores nodes, edges, and items in `HashMap<u64, T>` with auto-incrementing IDs. Provides full CRUD for all entity types, `send_item` to start transit on an edge, `get_stats` for aggregate metrics, and edge connectivity queries.

#### `graph::item::GraphItem`

A typed entity that flows through the graph network. Has `item_type`, `decay_time` (`-1.0` = no decay), `remaining_life`, `alive` flag, `priority`, and `position` (`ItemPosition`).

#### `graph::core::GraphStats`

Statistics snapshot struct with 10 fields: `nodes`, `edges`, `items`, `active_nodes`, `active_edges`, `items_in_transit`, `items_on_nodes`, `total_demand`, `total_supply`, `queued_items`.

#### `graph::node::Node`

A vertex with 22+ fields: `id`, `node_type`, `capacity`, `active`, `overflow_policy`, `flow_mode`, `push_rate`, `pull_rate`, `push_filter`, `pull_filter`, `process_time`, `queue_enabled`, `queue_capacity`, `queue`, `items`, `conversions`, `demands`, `supplies`, `tags`, `push_timer`, `pull_timer`, `process_accumulator`.

#### `graph::pathfinding::PathResult`

Result of a successful pathfinding query. Contains `nodes: Vec<u64>` (ordered source→dest), `edges: Vec<u64>` (edges traversed), and `cost: f64` (sum of edge weights).

### Enums

#### `graph::node::FlowMode`

How a node participates in automatic item flow. Variants: `Passive` (no flow), `Push` (sends items out), `Pull` (pulls items in), `Both` (push and pull).

#### `graph::simulation::GraphEvent`

Events generated during simulation. 11 variants: `ItemEnter { item_id, node_id }`, `ItemLeave { item_id, node_id }`, `ItemDecay { item_id }`, `ItemConvert { node_id, consumed, produced }`, `ItemLost { item_id, node_id }`, `EdgeEnter { item_id, edge_id }`, `EdgeLeave { item_id, edge_id }`, `DemandFulfilled { demand_node, supply_node, item_type, count }`, `SupplyDepleted { node_id, item_type }`, `ItemQueued { item_id, node_id }`, `ItemDequeued { item_id, node_id }`.

#### `graph::item::ItemPosition`

Where a `GraphItem` currently resides. Variants: `AtNode(u64)`, `InTransit { edge_id: u64, progress: f64 }`, `Unplaced`.

#### `graph::node::OverflowPolicy`

What happens when items arrive at a full node. Variants: `Reject` (item stays put), `Destroy` (item killed), `Queue` (item placed in FIFO queue).

## Lua API

The Lua API is registered in `src/lua_api/graph_api.rs` under the `luna.graph` namespace. The single factory function `luna.graph.newGraph()` creates a `Graph` userdata. All other operations are methods on the returned Graph, Node, Edge, and GraphItem userdata handles.

### `luna.graph` namespace

| Function             | Returns    | Description                                |
|----------------------|------------|--------------------------------------------|
| `luna.graph.newGraph()` | `Graph` | Creates a new empty directed graph         |

### Graph methods

| Method                                         | Returns       | Description                                                    |
|------------------------------------------------|---------------|----------------------------------------------------------------|
| `g:addNode(type?, capacity?)`                  | `Node`        | Adds a node (defaults: type `"default"`, capacity `-1`)        |
| `g:removeNode(node)`                           | `boolean`     | Removes a node and all connected edges                         |
| `g:hasNode(node)`                              | `boolean`     | Whether the node exists                                        |
| `g:getNodes()`                                 | `table`       | All Node handles                                               |
| `g:getNodeCount()`                             | `integer`     | Number of nodes                                                |
| `g:addEdge(from, to, type?)`                   | `Edge`        | Adds a directed edge between two nodes                         |
| `g:removeEdge(edge)`                           | `boolean`     | Removes an edge                                                |
| `g:hasEdge(edge)`                              | `boolean`     | Whether the edge exists                                        |
| `g:getEdges()`                                 | `table`       | All Edge handles                                               |
| `g:getEdgeCount()`                             | `integer`     | Number of edges                                                |
| `g:getEdgeBetween(from, to)`                   | `Edge?`       | Edge between two nodes, or nil                                 |
| `g:createItem(type?, decay?)`                  | `GraphItem`   | Creates an unplaced item (defaults: `"default"`, `-1.0`)       |
| `g:addItem(item, node)`                        | `boolean`     | Places an item at a node                                       |
| `g:removeItem(item)`                           | `boolean`     | Removes an item entirely                                       |
| `g:hasItem(item)`                              | `boolean`     | Whether the item exists                                        |
| `g:getItems()`                                 | `table`       | All GraphItem handles                                          |
| `g:getItemCount()`                             | `integer`     | Number of items                                                |
| `g:sendItem(item, edge)`                       | `boolean`     | Starts item transit on an edge                                 |
| `g:update(dt)`                                 | `nil`         | Advances simulation by dt seconds, fires event callbacks       |
| `g:step()`                                     | `nil`         | One discrete simulation step (= `update(1.0)`)                 |
| `g:findPath(from, to)`                         | `table?`      | Dijkstra shortest path — `{nodes, edges, cost}` or nil         |
| `g:findPathForItem(item, from, to)`            | `table?`      | Shortest path filtered by item type/cooldown/active             |
| `g:getDistance(from, to)`                       | `number?`     | Shortest path distance, or nil                                 |
| `g:getReachable(from, maxDist?)`               | `table`       | All reachable Node handles                                     |
| `g:getNeighbors(node)`                         | `table`       | Direct neighbour Node handles                                  |
| `g:getComponents()`                            | `table`       | Weakly connected components (table of tables of Nodes)         |
| `g:hasCycle()`                                 | `boolean`     | Whether a directed cycle exists                                |
| `g:topologicalSort()`                          | `table?`      | Topological order of Nodes, or nil if cycle                    |
| `g:processDemand()`                            | `nil`         | Processes supply/demand declarations, fires event callbacks    |
| `g:getStats()`                                 | `table`       | Statistics snapshot table                                      |
| `g:on(event, func)`                            | `nil`         | Registers a callback for a simulation event                    |

### Node methods

| Method                                         | Returns       | Description                                           |
|------------------------------------------------|---------------|-------------------------------------------------------|
| `n:getType()`                                  | `string`      | Node type string                                      |
| `n:setType(t)`                                 | `nil`         | Set node type                                         |
| `n:getCapacity()`                              | `integer`     | Capacity (`-1` = unlimited)                           |
| `n:setCapacity(c)`                             | `nil`         | Set capacity                                          |
| `n:getItemCount()`                             | `integer`     | Items currently at node                               |
| `n:isFull()`                                   | `boolean`     | Whether at capacity                                   |
| `n:isActive()`                                 | `boolean`     | Whether active                                        |
| `n:setActive(a)`                               | `nil`         | Set active state                                      |
| `n:getOverflowPolicy()`                        | `string`      | `"reject"`, `"destroy"`, or `"queue"`                 |
| `n:setOverflowPolicy(p)`                       | `nil`         | Set from string                                       |
| `n:getFlowMode()`                              | `string`      | `"passive"`, `"push"`, `"pull"`, or `"both"`          |
| `n:setFlowMode(m)`                             | `nil`         | Set from string                                       |
| `n:getPushRate()` / `setPushRate(r)`           | `number`/`nil`| Push rate (items/sec)                                 |
| `n:getPullRate()` / `setPullRate(r)`           | `number`/`nil`| Pull rate (items/sec)                                 |
| `n:getPushFilter()` / `setPushFilter(f?)`      | `string?`/`nil`| Push type filter                                     |
| `n:getPullFilter()` / `setPullFilter(f?)`      | `string?`/`nil`| Pull type filter                                     |
| `n:getProcessTime()` / `setProcessTime(t)`     | `number`/`nil`| Queue processing time                                 |
| `n:isQueueEnabled()` / `setQueueEnabled(e)`    | `boolean`/`nil`| Queue toggle                                         |
| `n:getQueueCapacity()` / `setQueueCapacity(c)` | `integer`/`nil`| Queue capacity (`-1` = unlimited)                    |
| `n:getQueueSize()`                             | `integer`     | Items in queue                                        |
| `n:getItems()`                                 | `table`       | GraphItem handles at this node                        |
| `n:getEdges(dir?)`                             | `table`       | Edge handles — dir: `"in"`, `"out"`, `"both"` (default) |
| `n:setConversion(in, out, inN?, outN?)`        | `nil`         | Add/replace conversion rule                           |
| `n:clearConversion(in_type)`                   | `nil`         | Remove conversion by input type                       |
| `n:clearAllConversions()`                      | `nil`         | Remove all conversions                                |
| `n:addTag(tag)` / `removeTag(tag)`             | `nil`/`boolean`| Tag management                                       |
| `n:hasTag(tag)`                                | `boolean`     | Check tag                                             |
| `n:clearTags()` / `getTags()`                  | `nil`/`table` | Clear or list all tags                                |
| `n:addSupply(type, qty)`                       | `nil`         | Declare supply                                        |
| `n:removeSupply(type)` / `clearSupplies()`     | `boolean`/`nil`| Remove supply declarations                           |
| `n:addDemand(type, qty, priority?)`            | `nil`         | Declare demand (priority default 0)                   |
| `n:removeDemand(type)` / `clearDemands()`      | `boolean`/`nil`| Remove demand declarations                           |
| `n:enqueue(item)` / `dequeue()`               | `boolean`/`GraphItem?`| Queue operations                                |

### Edge methods

| Method                                         | Returns       | Description                                           |
|------------------------------------------------|---------------|-------------------------------------------------------|
| `e:getType()` / `setType(t)`                  | `string`/`nil`| Edge type                                             |
| `e:getFrom()` / `e:getTo()`                   | `Node`        | Source / destination node handles                     |
| `e:getCapacity()` / `setCapacity(c)`           | `integer`/`nil`| Transit capacity (`-1` = unlimited)                  |
| `e:getThroughput()` / `setThroughput(t)`       | `number`/`nil`| Items per second                                     |
| `e:getTravelTime()` / `setTravelTime(t)`       | `number`/`nil`| Seconds per item transit                              |
| `e:getWeight()` / `setWeight(w)`               | `number`/`nil`| Pathfinding cost                                     |
| `e:getSpeedModifier()` / `setSpeedModifier(m)` | `number`/`nil`| Speed multiplier                                     |
| `e:getCooldown()` / `setCooldown(c)`           | `number`/`nil`| Cooldown duration                                    |
| `e:isOnCooldown()`                             | `boolean`     | Currently cooling down                                |
| `e:isBidirectional()` / `setBidirectional(b)`  | `boolean`/`nil`| Two-way traversal                                    |
| `e:isActive()` / `setActive(a)`               | `boolean`/`nil`| Active state                                         |
| `e:getItemsInTransit()`                        | `table`       | GraphItem handles in transit                          |
| `e:addAllowedType(t)` / `removeAllowedType(t)`| `nil`/`boolean`| Item-type allow-list                                 |
| `e:clearAllowedTypes()`                        | `nil`         | Clear allow-list (allow all)                          |
| `e:isItemTypeAllowed(t)`                       | `boolean`     | Check allow-list                                      |

### GraphItem methods

| Method                                         | Returns       | Description                                           |
|------------------------------------------------|---------------|-------------------------------------------------------|
| `i:getType()` / `setType(t)`                  | `string`/`nil`| Item type                                             |
| `i:getDecayTime()` / `setDecayTime(t)`         | `number`/`nil`| Decay time (`-1` = immortal)                         |
| `i:getRemainingLife()`                         | `number`      | Seconds of life left                                  |
| `i:isAlive()`                                  | `boolean`     | Whether alive                                         |
| `i:kill()`                                     | `nil`         | Mark as dead                                          |
| `i:getPriority()` / `setPriority(p)`           | `integer`/`nil`| Flow/delivery ordering                               |
| `i:getPosition()`                              | `Node\|Edge,number\|nil` | Position: Node if at-node, Edge+progress if in-transit, nothing if unplaced |

### Callback events for `g:on(event, func)`

| Event              | Callback args                            | When fired                                    |
|--------------------|------------------------------------------|-----------------------------------------------|
| `"itemEnter"`      | `(item, node)`                           | Item arrived at a node                        |
| `"itemLeave"`      | `(item, node)`                           | Item left a node onto an edge                 |
| `"itemDecay"`      | `(item)`                                 | Item's remaining life reached zero            |
| `"itemConvert"`    | `(node, consumed_tbl, produced_tbl)`     | Conversion rule fired                         |
| `"itemLost"`       | `(item, node)`                           | Item destroyed by overflow policy             |
| `"edgeEnter"`      | `(item, edge)`                           | Item started transit on an edge               |
| `"edgeLeave"`      | `(item, edge)`                           | Item finished transit on an edge              |
| `"demandFulfilled"`| `(demand_node, supply_node, type, count)`| Demand satisfied by supply                    |
| `"supplyDepleted"` | `(node, item_type)`                      | Supply quantity reached zero                  |
| `"itemQueued"`     | `(item, node)`                           | Item placed in node queue                     |
| `"itemDequeued"`   | `(item, node)`                           | Item removed from node queue                  |

## Lua Examples

```lua
-- Build a simple resource pipeline: mine → smelter → warehouse
function luna.load()
    graph = luna.graph.newGraph()

    -- Create nodes with types and capacities
    mine      = graph:addNode("mine", -1)
    smelter   = graph:addNode("smelter", 5)
    warehouse = graph:addNode("warehouse", 20)

    -- Connect with directed edges
    local e1 = graph:addEdge(mine, smelter)
    e1:setTravelTime(2.0)
    e1:setWeight(1.0)

    local e2 = graph:addEdge(smelter, warehouse)
    e2:setTravelTime(1.5)

    -- Configure smelter: convert 2 ore into 1 ingot
    smelter:setFlowMode("both")
    smelter:setConversion("ore", "ingot", 2, 1)

    -- Mine pushes ore automatically
    mine:setFlowMode("push")
    mine:setPushRate(0.5)

    -- Register event callbacks
    graph:on("itemEnter", function(item, node)
        print(item:getType() .. " arrived at " .. node:getType())
    end)

    graph:on("itemConvert", function(node, consumed, produced)
        print("Smelted " .. #consumed .. " ore into " .. #produced .. " ingot")
    end)

    -- Seed initial resources
    for i = 1, 6 do
        local ore = graph:createItem("ore", -1)
        graph:addItem(ore, mine)
    end
end

function luna.update(dt)
    graph:update(dt)

    -- Check stats
    local stats = graph:getStats()
    if stats.itemsOnNodes > 0 then
        -- Find path from mine to warehouse
        local path = graph:findPath(mine, warehouse)
        if path then
            print("Path cost: " .. path.cost)
        end
    end
end
```

```lua
-- Supply/demand example: village demands food from farm
function luna.load()
    g = luna.graph.newGraph()

    local farm    = g:addNode("farm", -1)
    local village = g:addNode("village", 10)
    g:addEdge(farm, village)

    -- Farm supplies 5 food
    farm:addSupply("food", 5)
    -- Village demands 3 food at priority 1
    village:addDemand("food", 3, 1)

    g:on("demandFulfilled", function(demand_node, supply_node, item_type, count)
        print(count .. " " .. item_type .. " delivered")
    end)

    -- Process all supply/demand in one pass
    g:processDemand()
end
```

## Item Summary

| Kind       | Count |
|------------|-------|
| `struct`   | 9     |
| `enum`     | 4     |
| `fn`       | 50+   |
| **Total**  | **63+** |

## References

| Module        | Relationship | Notes                                                          |
|---------------|--------------|----------------------------------------------------------------|
| `engine`      | Imports from | Uses `log_messages` constants and `SharedState` (via lua_api)  |
| `math`        | Imports from | Baseline dependency (not directly used, but available)         |
| `lua_api`     | Imported by  | `graph_api.rs` binds the full API to `luna.graph`              |
| `pathfinding` | Similar      | `src/pathfinding/` provides grid-based A★/HPA★/flow fields for spatial navigation; `graph` provides abstract node-based Dijkstra on relational graphs |

## Notes

- **Dead files**: `graph.rs` and `traversal.rs` exist in `src/graph/` but are NOT declared in `mod.rs`. They are legacy duplicates of `core.rs` and `pathfinding.rs` respectively. Do not edit them — they are dead code.
- **All algorithms are `impl Graph`**: The `algorithms.rs`, `pathfinding.rs`, `simulation.rs`, and `supply_demand.rs` files add methods to `Graph` via `impl Graph` blocks rather than introducing new types. This keeps the API surface on a single type.
- **HashMap-based, not SlotMap**: Unlike most Luna2D resource pools, the graph uses `HashMap<u64, T>` with auto-incrementing IDs rather than `SlotMap`. This is intentional — graphs are self-contained userdata objects that do not participate in the engine's shared resource pool system.
- **Rc<RefCell<Graph>> in Lua**: The Lua wrapper (`LuaGraph`) holds `Rc<RefCell<Graph>>` internally. Node, Edge, and GraphItem handles all share the same `Rc`, meaning they are lightweight views into the same graph. Removing a node invalidates all handles to that node — methods will return "node not found" errors.
- **Event dispatch is synchronous**: `g:update(dt)` and `g:processDemand()` collect events first, then dispatch all callbacks after the simulation pass completes. Callbacks may safely read graph state but should avoid mutating the graph during dispatch to prevent borrow conflicts.
- **No rendering integration**: The graph module is entirely abstract. It does not produce `DrawCommand`s or interact with the graphics pipeline. Games must implement their own visual representation of graph state in `luna.draw()`.
- **Thread safety**: The graph is not thread-safe (`Rc<RefCell<>>` not `Arc<Mutex<>>`). It must be used from the main Lua VM only.
