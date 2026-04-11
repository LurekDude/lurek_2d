# `graph` — Agent Reference

| Property | Value |
|----------|-------|
| **Tier** | Foundations |
| **Status** | Implemented |
| **Lua API** | `lurek.graph` |
| **Source** | `src/graph/` |
| **Rust Tests** | none found in the workspace |
| **Lua Tests** | none found in the workspace |
| **Architecture** | `docs/architecture/engine-architecture.md § Foundations` |

---

## Summary

The graph module owns directed node-edge-item networks plus the algorithms needed to simulate flow through them. It combines CRUD-style graph storage with routing, connected-component and cycle analysis, item transit, conversion rules, queueing, and supply-demand fulfillment.

This module exists for systems whose logic is relational rather than spatial, such as logistics networks, production chains, dependency graphs, or abstract game-economy flows. It is intentionally not a renderer or a world-space pathfinding system. The small render helper is only for debug visualization, and the legacy graph.rs and traversal.rs files are older on-disk copies rather than the active public surface declared by mod.rs.

**Scope boundary**: This module currently depends on `image`, `render`, `runtime`. It stays within the Foundations responsibility boundary defined in the architecture docs.

---

## Architecture

```
lurek.graph.* (Lua API — src/lua_api/graph_api.rs)
    |
    v
src/graph/mod.rs
    |- algorithms.rs - algorithms
    |- core.rs - core
    |- edge.rs - edge
    |- graph.rs - graph
    |- item.rs - item
    |- node.rs - node
    |- pathfinding.rs - pathfinding
    |- render.rs - render
    |- ...
```

---

## Source Files

| File | Purpose |
|------|---------|
| `algorithms.rs` | Adds connected-component, cycle-detection, and topological-sort helpers. |
| `core.rs` | Defines Graph and GraphStats plus node, edge, and item management operations. |
| `edge.rs` | Defines Edge, the directed connection with capacity, travel timing, cooldowns, weights, and item-type filters. |
| `graph.rs` | Older duplicate graph container file kept on disk but not declared by mod.rs. |
| `item.rs` | Defines GraphItem and ItemPosition for typed items that rest on nodes or travel across edges. |
| `mod.rs` | Declares the active graph submodules and re-exports the public graph, node, edge, item, and event types. |
| `node.rs` | Defines Node and the flow, overflow, conversion, supply, and demand types that give nodes gameplay meaning. |
| `pathfinding.rs` | Adds Dijkstra-based shortest-path, reachability, and neighbor queries. |
| `render.rs` | Generates debug render commands for visualizing graph state without making graph a rendering subsystem. |
| `simulation.rs` | Implements the main tick pipeline and emits GraphEvent values for transit, decay, conversion, queue, and routing activity. |
| `supply_demand.rs` | Matches demand declarations to supplies and routes created items through the graph. |
| `traversal.rs` | Older duplicate pathfinding file kept on disk but not declared by mod.rs. |

---

## Submodules

### `graph::algorithms`

Adds connected-component, cycle-detection, and topological-sort helpers.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `graph::core`

Defines Graph and GraphStats plus node, edge, and item management operations.

- **`GraphStats`** (struct): A read-only statistics snapshot captured from a [`Graph`] at a point in time.
- **`Graph`** (struct): A directed graph with typed nodes, edges, and flowing items.

### `graph::edge`

Defines Edge, the directed connection with capacity, travel timing, cooldowns, weights, and item-type filters.

- **`Edge`** (struct): A directed connection between two nodes in the graph.

### `graph::graph`

Older duplicate graph container file kept on disk but not declared by mod.rs.

- **`GraphStats`** (struct): Statistics snapshot of the graph state.
- **`Graph`** (struct): A directed graph with typed nodes, edges, and flowing items.

### `graph::item`

Defines GraphItem and ItemPosition for typed items that rest on nodes or travel across edges.

- **`ItemPosition`** (enum): The current location of a [`GraphItem`] within the simulation graph.
- **`GraphItem`** (struct): A typed entity that flows through the graph network.

### `graph::node`

Defines Node and the flow, overflow, conversion, supply, and demand types that give nodes gameplay meaning.

- **`OverflowPolicy`** (enum): What happens when items arrive at a full node.
- **`FlowMode`** (enum): How a node participates in automatic item flow.
- **`ConversionRule`** (struct): A rule that converts N input items of one type into M output items of another.
- **`Supply`** (struct): Declares that a node can produce items of a given type up to a specified quantity.
- **`Demand`** (struct): Declares that a node needs items of a given type, with a priority for fulfillment ordering.
- **`Node`** (struct): A vertex in the graph with capacity, flow control, conversion, and queuing.

### `graph::pathfinding`

Adds Dijkstra-based shortest-path, reachability, and neighbor queries.

- **`PathResult`** (struct): Result of a successful pathfinding query.

### `graph::render`

Generates debug render commands for visualizing graph state without making graph a rendering subsystem.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `graph::simulation`

Implements the main tick pipeline and emits GraphEvent values for transit, decay, conversion, queue, and routing activity.

- **`GraphEvent`** (enum): Events generated during simulation for the Lua callback layer to dispatch.

### `graph::supply_demand`

Matches demand declarations to supplies and routes created items through the graph.

- **No exported Rust types in this file**: this submodule is primarily supporting logic or free functions.

### `graph::traversal`

Older duplicate pathfinding file kept on disk but not declared by mod.rs.

- **`PathResult`** (struct): Result of a successful pathfinding query.

---

## Key Types

### Public Types

#### `Graph`

Central directed graph container that owns nodes, edges, items, and most module behavior through impl blocks.

#### `GraphStats`

Read-only state summary for graph size, activity, demand, supply, and queued items.

#### `Node`

Rich vertex type with capacity, flow mode, overflow policy, queueing, conversion rules, supplies, demands, and tags.

#### `Edge`

Directed connection that controls routing cost, travel time, cooldown, capacity, and allowed item types.

#### `GraphItem`

Typed entity that moves through the graph with lifetime, priority, and current position state.

#### `ItemPosition`

Enum describing whether an item is at a node, in transit on an edge, or unplaced.

#### `FlowMode`

Enum describing whether a node passively holds items or actively pushes and or pulls them.

#### `OverflowPolicy`

Enum describing how full nodes reject, destroy, or queue incoming items.

#### `GraphEvent`

Event enum emitted by simulation and demand processing for Lua callback dispatch.

#### `PathResult`

Shortest-path result containing ordered node IDs, edge IDs, and total path cost.

---

## Lua API

Exposed under `lurek.graph.*` by `src/lua_api/graph_api.rs`.

### Module Functions

| Function | Description |
|----------|-------------|
| `lurek.graph.newGraph` | Creates a new empty directed graph for item flow simulation. |

### `Edge` Methods

| Method | Description |
|--------|-------------|
| `edge:getType(...)` | Returns the edge type string. |
| `edge:setType(...)` | Sets the edge type string. |
| `edge:getFrom(...)` | Returns the source node handle. |
| `edge:getTo(...)` | Returns the destination node handle. |
| `edge:getCapacity(...)` | Returns the edge capacity (-1 = unlimited). |
| `edge:setCapacity(...)` | Sets the edge capacity (-1 = unlimited). |
| `edge:getThroughput(...)` | Returns items per second this edge can transfer. |
| `edge:setThroughput(...)` | Sets items per second this edge can transfer. |
| `edge:getTravelTime(...)` | Returns the travel time in seconds for items on this edge. |
| `edge:setTravelTime(...)` | Sets the travel time in seconds for items on this edge. |
| `edge:getWeight(...)` | Returns the pathfinding weight of this edge. |
| `edge:setWeight(...)` | Sets the pathfinding weight of this edge. |
| `edge:getSpeedModifier(...)` | Returns the speed modifier applied to items in transit. |
| `edge:setSpeedModifier(...)` | Sets the speed modifier applied to items in transit. |
| `edge:getCooldown(...)` | Returns the cooldown duration in seconds. |
| `edge:setCooldown(...)` | Sets the cooldown duration in seconds. |
| `edge:isOnCooldown(...)` | Returns true if the edge is currently on cooldown. |
| `edge:isBidirectional(...)` | Returns true if items can travel the edge in either direction. |
| `edge:setBidirectional(...)` | Sets whether items can travel the edge in either direction. |
| `edge:isActive(...)` | Returns true if the edge is active. |
| `edge:setActive(...)` | Sets the active state of this edge. |
| `edge:getItemsInTransit(...)` | Returns a table of GraphItem handles currently in transit on this edge. |
| `edge:addAllowedType(...)` | Adds an item type to the edge allow-list. |
| `edge:removeAllowedType(...)` | Removes an item type from the edge allow-list. |
| `edge:clearAllowedTypes(...)` | Clears the edge allow-list so all item types are permitted. |
| `edge:isItemTypeAllowed(...)` | Returns true if the given item type is allowed on this edge. |
| `edge:type(...)` | Returns the type name "GraphEdge". |
| `edge:typeOf(...)` | Returns true when the given name matches "GraphEdge" or a parent type. |

### `Graph` Methods

| Method | Description |
|--------|-------------|
| `graph:removeNode(...)` | Removes a node from the graph. |
| `graph:hasNode(...)` | Returns true if the node exists in the graph. |
| `graph:getNodes(...)` | Returns a table of all Node handles. |
| `graph:getNodeCount(...)` | Returns the number of nodes in the graph. |
| `graph:removeEdge(...)` | Removes an edge from the graph. |
| `graph:hasEdge(...)` | Returns true if the edge exists in the graph. |
| `graph:getEdges(...)` | Returns a table of all Edge handles. |
| `graph:getEdgeCount(...)` | Returns the number of edges in the graph. |
| `graph:removeItem(...)` | Removes an item from the graph entirely. |
| `graph:hasItem(...)` | Returns true if the item exists in the graph. |
| `graph:getItems(...)` | Returns a table of all GraphItem handles. |
| `graph:getItemCount(...)` | Returns the number of items in the graph. |
| `graph:update(...)` | Advances simulation by dt seconds and fires event callbacks. |
| `graph:step(...)` | Runs one discrete simulation step and fires event callbacks. |
| `graph:getNeighbors(...)` | Returns a table of direct neighbor Node handles. |
| `graph:getComponents(...)` | Returns weakly connected components as a table of tables of Node handles. |
| `graph:hasCycle(...)` | Returns true if the graph contains a directed cycle. |
| `graph:topologicalSort(...)` | Returns a topologically sorted table of Node handles, or nil if a cycle exists. |
| `graph:processDemand(...)` | Processes all supply/demand declarations and fires event callbacks. |
| `graph:getStats(...)` | Returns a statistics snapshot table. |
| `graph:type(...)` | Returns the type name of this object. |
| `graph:typeOf(...)` | Returns true if this object is of the given type. |

### `GraphItem` Methods

| Method | Description |
|--------|-------------|
| `graphitem:getType(...)` | Returns the item type string. |
| `graphitem:setType(...)` | Sets the item type string. |
| `graphitem:getDecayTime(...)` | Returns the decay time in seconds (-1 = immortal). |
| `graphitem:setDecayTime(...)` | Sets the decay time in seconds (-1 = immortal). |
| `graphitem:getRemainingLife(...)` | Returns the remaining life in seconds. |
| `graphitem:isAlive(...)` | Returns true if the item is alive. |
| `graphitem:kill(...)` | Marks the item as dead. |
| `graphitem:getPriority(...)` | Returns the item priority. |
| `graphitem:setPriority(...)` | Sets the item priority. |
| `graphitem:getPosition(...)` | Returns the item position: node userdata if at a node, (edge, progress) |
| `graphitem:type(...)` | Returns the type name of this object. |
| `graphitem:typeOf(...)` | Returns true if this object is of the given type. |

### `Node` Methods

| Method | Description |
|--------|-------------|
| `node:getType(...)` | Returns the node type string. |
| `node:setType(...)` | Sets the node type string. |
| `node:getCapacity(...)` | Returns the node capacity (-1 = unlimited). |
| `node:setCapacity(...)` | Sets the node capacity (-1 = unlimited). |
| `node:getItemCount(...)` | Returns the number of items currently at this node. |
| `node:isFull(...)` | Returns true if the node has reached its capacity. |
| `node:isActive(...)` | Returns true if the node is active. |
| `node:setActive(...)` | Sets the active state of this node. |
| `node:getOverflowPolicy(...)` | Returns the overflow policy as a string. |
| `node:setOverflowPolicy(...)` | Sets the overflow policy from a string. |
| `node:getFlowMode(...)` | Returns the flow mode as a string. |
| `node:setFlowMode(...)` | Sets the flow mode from a string. |
| `node:getPushRate(...)` | Returns items per second this node pushes. |
| `node:setPushRate(...)` | Sets items per second this node pushes. |
| `node:getPullRate(...)` | Returns items per second this node pulls. |
| `node:setPullRate(...)` | Sets items per second this node pulls. |
| `node:getPushFilter(...)` | Returns the push filter string, or nil if unset. |
| `node:setPushFilter(...)` | Sets the push filter string, or nil to clear. |
| `node:getPullFilter(...)` | Returns the pull filter string, or nil if unset. |
| `node:setPullFilter(...)` | Sets the pull filter string, or nil to clear. |
| `node:getProcessTime(...)` | Returns the processing time in seconds. |
| `node:setProcessTime(...)` | Sets the processing time in seconds. |
| `node:isQueueEnabled(...)` | Returns true if the node queue is enabled. |
| `node:setQueueEnabled(...)` | Enables or disables the node queue. |
| `node:getQueueCapacity(...)` | Returns the queue capacity (-1 = unlimited). |
| `node:setQueueCapacity(...)` | Sets the queue capacity (-1 = unlimited). |
| `node:getQueueSize(...)` | Returns the number of items currently in the queue. |
| `node:getItems(...)` | Returns a table of GraphItem handles at this node. |
| `node:getEdges(...)` | Returns a table of Edge handles connected to this node. |
| `node:clearConversion(...)` | Removes the conversion rule for the given input type. |
| `node:clearAllConversions(...)` | Removes all conversion rules from this node. |
| `node:addTag(...)` | Adds a tag to this node. |
| `node:removeTag(...)` | Removes a tag from this node. |
| `node:hasTag(...)` | Returns true if this node has the given tag. |
| `node:clearTags(...)` | Removes all tags from this node. |
| `node:getTags(...)` | Returns a table of tag strings on this node. |
| `node:removeSupply(...)` | Removes the supply declaration for the given item type. |
| `node:clearSupplies(...)` | Removes all supply declarations from this node. |
| `node:removeDemand(...)` | Removes the demand declaration for the given item type. |
| `node:clearDemands(...)` | Removes all demand declarations from this node. |
| `node:enqueue(...)` | Pushes an item into the node queue. |
| `node:dequeue(...)` | Pops the next item from the node queue, or nil if empty. |
| `node:type(...)` | Returns the type name "GraphNode". |
| `node:typeOf(...)` | Returns true when the given name matches "GraphNode" or a parent type. |

---

## Lua Examples

```lua
-- Minimal namespace check for lurek.graph.
if lurek.graph then
    -- Call the documented functions in the Lua API tables above.
end
```

---

## Item Summary

| Kind | Count |
|------|-------|
| `struct` | 12 |
| `enum` | 4 |
| `fn` (Lua API) | 107 |
| **Total** | **123** |

---

## References

| Module | Relationship | Notes |
|--------|--------------|-------|
| `image` | Imports or references `image` from `src/image/`. | Cross-group dependency from Foundations to Platform Services. |
| `render` | Imports or references `render` from `src/render/`. | Cross-group dependency from Foundations to Platform Services. |
| `runtime` | Imports or references `runtime` from `src/runtime/`. | Cross-group dependency from Foundations to Core Runtime. |

---

## Notes

- **Source of truth**: Keep this spec synchronized with `src/graph/`, the matching AGENT files, and any relevant Lua bindings.
- **Generation note**: This file was generated from current source and AGENT metadata, then intended for manual refinement when behavior changes.
