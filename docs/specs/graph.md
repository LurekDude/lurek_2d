# graph

## General Info

- Module group: `Foundations`
- Source path: `src/graph/`
- Lua API path(s): `src/lua_api/graph_api.rs`
- Primary Lua namespace: `lurek.graph`
- Rust test path(s): tests/rust/unit/graph_tests.rs plus inline graph module tests
- Lua test path(s): tests/lua/unit/test_graph.lua and related graph stress and golden suites

## Summary

The `graph` module provides Lurek2D's directed flow-simulation graph system — a simulation substrate where typed items flow through a network of nodes connected by directed edges. Unlike a simple data-structure graph, this module models quantity transport: items accumulate in nodes, flow through edges at controlled rates, decay over time, and undergo conversion reactions at nodes. It is a Foundations tier module with no engine dependencies.

The core container is `Graph`, owning a `SlotMap` of `Node` instances and a `SlotMap` of `Edge` instances. `Node` stores the accumulated item inventory (a `Vec<Item>` with typed quantities), conversion rules (`ConversionRule` maps input item types to output types at a ratio), overflow policy (cap, spill, or reject), and flow mode (push vs pull). `Edge` stores capacity (max items per tick), cooldown timer, and type-filtering that restricts which `ItemType` values may traverse it.

Simulation is step-driven: `Graph::step(dt)` applies item decay (all items lose a configured fraction per second), processes pending conversions at nodes, applies push/pull flow across edges respecting capacity and cooldowns, and delivers queued items to their destination nodes. Supply/demand processing queries which nodes can provide items and which nodes need them, then resolves transfers.

`Item` and `ItemType` describe the cargo: `ItemType` is a user-defined string tag; `Item` carries a type and a quantity float. `FlowResult` reports the per-step simulation outcome (items moved, conversions fired, overflow events).

Graph algorithms from the `algorithms` submodule cover: connected component analysis, cycle detection, topological sort. `pathfinding` submodule provides Dijkstra shortest-path. The `render` submodule outputs `RenderCommand` entries for debug visualization of node/edge state.

**Scope boundary**: Foundations tier. No engine module imports. Lua bridge in `src/lua_api/graph_api.rs`.

## Files

- `algorithms.rs`: Adds connected-component, cycle-detection, and topological-sort helpers.
- `core.rs`: Defines Graph and GraphStats plus node, edge, and item management operations.
- `edge.rs`: Defines Edge, the directed connection with capacity, travel timing, cooldowns, weights, and item-type filters.
- `graph.rs`: Older duplicate graph container file kept on disk but not declared by mod.rs.
- `item.rs`: Defines GraphItem and ItemPosition for typed items that rest on nodes or travel across edges.
- `mod.rs`: Declares the active graph submodules and re-exports the public graph, node, edge, item, and event types.
- `node.rs`: Defines Node and the flow, overflow, conversion, supply, and demand types that give nodes gameplay meaning.
- `pathfinding.rs`: Adds Dijkstra-based shortest-path, reachability, and neighbor queries.
- `render.rs`: Generates debug render commands for visualizing graph state without making graph a rendering subsystem.
- `simulation.rs`: Implements the main tick pipeline and emits GraphEvent values for transit, decay, conversion, queue, and routing activity.
- `supply_demand.rs`: Matches demand declarations to supplies and routes created items through the graph.
- `traversal.rs`: Older duplicate pathfinding file kept on disk but not declared by mod.rs.

## Types

- `GraphStats` (`struct`, `core.rs`): Read-only state summary for graph size, activity, demand, supply, and queued items.
- `Graph` (`struct`, `core.rs`): Central directed graph container that owns nodes, edges, items, and most module behavior through impl blocks.
- `Edge` (`struct`, `edge.rs`): Directed connection that controls routing cost, travel time, cooldown, capacity, and allowed item types.
- `GraphStats` (`struct`, `graph.rs`): Read-only state summary for graph size, activity, demand, supply, and queued items.
- `Graph` (`struct`, `graph.rs`): Central directed graph container that owns nodes, edges, items, and most module behavior through impl blocks.
- `ItemPosition` (`enum`, `item.rs`): Enum describing whether an item is at a node, in transit on an edge, or unplaced.
- `GraphItem` (`struct`, `item.rs`): Typed entity that moves through the graph with lifetime, priority, and current position state.
- `OverflowPolicy` (`enum`, `node.rs`): Enum describing how full nodes reject, destroy, or queue incoming items.
- `FlowMode` (`enum`, `node.rs`): Enum describing whether a node passively holds items or actively pushes and or pulls them.
- `ConversionRule` (`struct`, `node.rs`): A rule that converts N input items of one type into M output items of another.
- `Supply` (`struct`, `node.rs`): Declares that a node can produce items of a given type up to a specified quantity.
- `Demand` (`struct`, `node.rs`): Declares that a node needs items of a given type, with a priority for fulfillment ordering.
- `Node` (`struct`, `node.rs`): Rich vertex type with capacity, flow mode, overflow policy, queueing, conversion rules, supplies, demands, and tags.
- `PathResult` (`struct`, `pathfinding.rs`): Shortest-path result containing ordered node IDs, edge IDs, and total path cost.
- `GraphEvent` (`enum`, `simulation.rs`): Event enum emitted by simulation and demand processing for Lua callback dispatch.
- `PathResult` (`struct`, `traversal.rs`): Shortest-path result containing ordered node IDs, edge IDs, and total path cost.

## Functions

- `Graph::get_components` (`algorithms.rs`): Find weakly connected components (treating all edges as undirected).
- `Graph::has_cycle` (`algorithms.rs`): Detect whether the directed graph contains a cycle (DFS-based).
- `Graph::topological_sort` (`algorithms.rs`): Topological sort using Kahn's algorithm.
- `Graph::mst_kruskal` (`algorithms.rs`): Kruskal's Minimum Spanning Tree.
- `Graph::astar_graph` (`algorithms.rs`): A* search from `from` to `to` using optional spatial positions for the heuristic.
- `Graph::new` (`core.rs`): Create an empty graph.
- `Graph::add_node` (`core.rs`): Add a node with the given type and capacity.
- `Graph::remove_node` (`core.rs`): Remove a node and all connected edges.
- `Graph::has_node` (`core.rs`): Whether a node with the given ID exists.
- `Graph::get_node_ids` (`core.rs`): Get all node IDs.
- `Graph::get_node_count` (`core.rs`): Get the number of nodes.
- `Graph::add_edge` (`core.rs`): Add a directed edge between two existing nodes.
- `Graph::remove_edge` (`core.rs`): Remove an edge.
- `Graph::has_edge` (`core.rs`): Whether an edge with the given ID exists.
- `Graph::get_edge_ids` (`core.rs`): Get all edge IDs.
- `Graph::get_edge_count` (`core.rs`): Get the number of edges.
- `Graph::get_edge_between` (`core.rs`): Find an edge from `from` to `to` (returns the first match).
- `Graph::create_item` (`core.rs`): Create a new item (starts `Unplaced`).
- `Graph::add_item_to_node` (`core.rs`): Try to add an existing item to a node, respecting capacity and overflow policy.
- `Graph::remove_item` (`core.rs`): Remove an item from the graph entirely.
- `Graph::has_item` (`core.rs`): Whether an item with the given ID exists.
- `Graph::get_item_ids` (`core.rs`): Get all item IDs.
- `Graph::get_item_count` (`core.rs`): Get the number of items.
- `Graph::send_item` (`core.rs`): Send an item onto an edge (start transit).
- `Graph::get_stats` (`core.rs`): Compute a statistics snapshot.
- `Graph::get_outgoing_edges` (`core.rs`): Get IDs of edges leaving a node.
- `Graph::get_incoming_edges` (`core.rs`): Get IDs of edges arriving at a node.
- `Graph::get_edges_by_direction` (`core.rs`): Returns edge IDs for a node filtered by direction string.
- `Graph::draw_to_image` (`core.rs`): Render the graph to an image with circular node layout.
- `Graph::serialize` (`core.rs`): Serialize the graph to a JSON-compatible `serde_json::Value` map.
- `Graph::deserialize` (`core.rs`): Deserialize a graph from a map produced by [`Graph::serialize`].
- `Edge::new` (`edge.rs`): Create a new edge with defaults.
- `Edge::get_type` (`edge.rs`): Get the edge type.
- `Edge::set_type` (`edge.rs`): Set the edge type.
- `Edge::is_on_cooldown` (`edge.rs`): Whether the edge is in cooldown.
- `Edge::is_item_type_allowed` (`edge.rs`): Whether the given item type is allowed on this edge.
- `Edge::add_allowed_type` (`edge.rs`): Add an allowed item type.
- `Edge::remove_allowed_type` (`edge.rs`): Remove an allowed item type.
- `Edge::clear_allowed_types` (`edge.rs`): Clear all allowed type restrictions (all types become allowed).
- `Edge::is_transit_full` (`edge.rs`): Whether transit capacity is full.
- `Graph::new` (`graph.rs`): Create an empty graph.
- `Graph::add_node` (`graph.rs`): Add a node with the given type and capacity.
- `Graph::remove_node` (`graph.rs`): Remove a node and all connected edges.
- `Graph::has_node` (`graph.rs`): Whether a node with the given ID exists.
- `Graph::get_node_ids` (`graph.rs`): Get all node IDs.
- `Graph::get_node_count` (`graph.rs`): Get the number of nodes.
- `Graph::add_edge` (`graph.rs`): Add a directed edge between two existing nodes.
- `Graph::remove_edge` (`graph.rs`): Remove an edge.
- `Graph::has_edge` (`graph.rs`): Whether an edge with the given ID exists.
- `Graph::get_edge_ids` (`graph.rs`): Get all edge IDs.
- `Graph::get_edge_count` (`graph.rs`): Get the number of edges.
- `Graph::get_edge_between` (`graph.rs`): Find an edge from `from` to `to` (returns the first match).
- `Graph::create_item` (`graph.rs`): Create a new item (starts `Unplaced`).
- `Graph::add_item_to_node` (`graph.rs`): Try to add an existing item to a node, respecting capacity and overflow policy.
- `Graph::remove_item` (`graph.rs`): Remove an item from the graph entirely.
- `Graph::has_item` (`graph.rs`): Whether an item with the given ID exists.
- `Graph::get_item_ids` (`graph.rs`): Get all item IDs.
- `Graph::get_item_count` (`graph.rs`): Get the number of items.
- `Graph::send_item` (`graph.rs`): Send an item onto an edge (start transit).
- `Graph::get_stats` (`graph.rs`): Compute a statistics snapshot.
- `Graph::get_outgoing_edges` (`graph.rs`): Get IDs of edges leaving a node.
- `Graph::get_incoming_edges` (`graph.rs`): Get IDs of edges arriving at a node.
- `GraphItem::new` (`item.rs`): Create a new item with the given type and decay time.
- `GraphItem::kill` (`item.rs`): Marks this item as dead; it will be removed from the graph on the next tick.
- `GraphItem::is_alive` (`item.rs`): Whether the item is still alive.
- `GraphItem::get_type` (`item.rs`): Get the item type.
- `GraphItem::set_type` (`item.rs`): Set the item type.
- `GraphItem::get_decay_time` (`item.rs`): Get the decay time (`-1.0` = no decay).
- `GraphItem::set_decay_time` (`item.rs`): Set the decay time.
- `GraphItem::get_remaining_life` (`item.rs`): Get remaining life in seconds.
- `GraphItem::set_remaining_life` (`item.rs`): Set remaining life in seconds.
- `GraphItem::get_priority` (`item.rs`): Get the priority value.
- `GraphItem::set_priority` (`item.rs`): Set the priority value.
- `GraphItem::get_position` (`item.rs`): Get the current position.
- `GraphItem::set_position` (`item.rs`): Set the current position.
- `OverflowPolicy::to_str` (`node.rs`): Canonical lowercase string representation.
- `FlowMode::to_str` (`node.rs`): Canonical lowercase string representation.
- `Node::new` (`node.rs`): Create a new node with defaults.
- `Node::get_type` (`node.rs`): Get the node type.
- `Node::set_type` (`node.rs`): Set the node type.
- `Node::get_capacity` (`node.rs`): Get the capacity (`-1` = unlimited).
- `Node::set_capacity` (`node.rs`): Set the capacity.
- `Node::is_full` (`node.rs`): Whether the node is at capacity.
- `Node::item_count` (`node.rs`): Returns the number of items currently sitting at this node.
- `Node::add_tag` (`node.rs`): Add a tag.
- `Node::remove_tag` (`node.rs`): Remove a tag.
- `Node::has_tag` (`node.rs`): Check if a tag is present.
- `Node::clear_tags` (`node.rs`): Remove all tags.
- `Node::get_tags` (`node.rs`): Get all tags as a sorted vector.
- `Node::add_supply` (`node.rs`): Add a supply declaration.
- `Node::remove_supply` (`node.rs`): Remove supply declarations for the given item type.
- `Node::clear_supplies` (`node.rs`): Remove all supply declarations.
- `Node::get_supply` (`node.rs`): Get the supply for a given item type.
- `Node::get_available_supply` (`node.rs`): Get the available supply quantity for a type (returns 0 if not found).
- `Node::add_demand` (`node.rs`): Add a demand declaration.
- `Node::remove_demand` (`node.rs`): Remove demand declarations for the given item type.
- `Node::clear_demands` (`node.rs`): Remove all demand declarations.
- `Node::get_demand` (`node.rs`): Get the demand for a given item type.
- `Node::set_conversion` (`node.rs`): Set a conversion rule (keyed by input type).
- `Node::clear_conversion` (`node.rs`): Remove a conversion rule by input type.
- `Node::clear_all_conversions` (`node.rs`): Remove all conversion rules.
- `Node::enqueue` (`node.rs`): Push an item ID onto the back of the queue.
- `Node::dequeue` (`node.rs`): Pop an item ID from the front of the queue.
- `Graph::find_path` (`pathfinding.rs`): Find the shortest path from `from` to `to` using Dijkstra's algorithm.
- `Graph::find_path_for_item` (`pathfinding.rs`): Find a path that only uses edges the given item can traverse.
- `Graph::get_distance` (`pathfinding.rs`): Get the shortest-path distance between two nodes, or `None` if unreachable.
- `Graph::get_reachable` (`pathfinding.rs`): Get all nodes reachable from `from`, optionally limited by max distance.
- `Graph::get_neighbors` (`pathfinding.rs`): Get direct outgoing neighbors of a node.
- `Graph::generate_render_commands` (`render.rs`): Generate debug render commands for the graph using a circular node layout.
- `Graph::update` (`simulation.rs`): Advance the simulation by `dt` seconds.
- `Graph::step` (`simulation.rs`): One discrete simulation step (equivalent to `update(1.0)`).
- `Graph::process_demand` (`supply_demand.rs`): Processes all demand/supply declarations, routing items from supply nodes to demand nodes.
- `Graph::find_path` (`traversal.rs`): Find the shortest path from `from` to `to` using Dijkstra's algorithm.
- `Graph::find_path_for_item` (`traversal.rs`): Find a path that only uses edges the given item can traverse.
- `Graph::get_distance` (`traversal.rs`): Get the shortest-path distance between two nodes, or `None` if unreachable.
- `Graph::get_reachable` (`traversal.rs`): Get all nodes reachable from `from`, optionally limited by max distance.
- `Graph::get_neighbors` (`traversal.rs`): Get direct outgoing neighbors of a node.

## Lua API Reference

- Binding path(s): `src/lua_api/graph_api.rs`
- Namespace: `lurek.graph`

### Module Functions
- `lurek.graph.newGraph`: Creates a new empty directed graph for item flow simulation.

### `Edge` Methods
- `Edge:getType`: Returns the edge type string.
- `Edge:setType`: Sets the edge type string.
- `Edge:getFrom`: Returns the source node handle.
- `Edge:getTo`: Returns the destination node handle.
- `Edge:getCapacity`: Returns the edge capacity (-1 = unlimited).
- `Edge:setCapacity`: Sets the edge capacity (-1 = unlimited).
- `Edge:getThroughput`: Returns items per second this edge can transfer.
- `Edge:setThroughput`: Sets items per second this edge can transfer.
- `Edge:getTravelTime`: Returns the travel time in seconds for items on this edge.
- `Edge:setTravelTime`: Sets the travel time in seconds for items on this edge.
- `Edge:getWeight`: Returns the pathfinding weight of this edge.
- `Edge:setWeight`: Sets the pathfinding weight of this edge.
- `Edge:getSpeedModifier`: Returns the speed modifier applied to items in transit.
- `Edge:setSpeedModifier`: Sets the speed modifier applied to items in transit.
- `Edge:getCooldown`: Returns the cooldown duration in seconds.
- `Edge:setCooldown`: Sets the cooldown duration in seconds.
- `Edge:isOnCooldown`: Returns true if the edge is currently on cooldown.
- `Edge:isBidirectional`: Returns true if items can travel the edge in either direction.
- `Edge:setBidirectional`: Sets whether items can travel the edge in either direction.
- `Edge:isActive`: Returns true if the edge is active.
- `Edge:setActive`: Sets the active state of this edge.
- `Edge:getItemsInTransit`: Returns a table of GraphItem handles currently in transit on this edge.
- `Edge:addAllowedType`: Adds an item type to the edge allow-list.
- `Edge:removeAllowedType`: Removes an item type from the edge allow-list.
- `Edge:clearAllowedTypes`: Clears the edge allow-list so all item types are permitted.
- `Edge:isItemTypeAllowed`: Returns true if the given item type is allowed on this edge.
- `Edge:type`: Returns the type name "GraphEdge".
- `Edge:typeOf`: Returns true when the given name matches "GraphEdge" or a parent type.

### `Graph` Methods
- `Graph:removeNode`: Removes a node from the graph.
- `Graph:hasNode`: Returns true if the node exists in the graph.
- `Graph:getNodes`: Returns a table of all Node handles.
- `Graph:getNodeCount`: Returns the number of nodes in the graph.
- `Graph:removeEdge`: Removes an edge from the graph.
- `Graph:hasEdge`: Returns true if the edge exists in the graph.
- `Graph:getEdges`: Returns a table of all Edge handles.
- `Graph:getEdgeCount`: Returns the number of edges in the graph.
- `Graph:removeItem`: Removes an item from the graph entirely.
- `Graph:hasItem`: Returns true if the item exists in the graph.
- `Graph:getItems`: Returns a table of all GraphItem handles.
- `Graph:getItemCount`: Returns the number of items in the graph.
- `Graph:update`: Advances simulation by dt seconds and fires event callbacks.
- `Graph:step`: Runs one discrete simulation step and fires event callbacks.
- `Graph:getNeighbors`: Returns a table of direct neighbor Node handles.
- `Graph:getComponents`: Returns weakly connected components as a table of tables of Node handles.
- `Graph:hasCycle`: Returns true if the graph contains a directed cycle.
- `Graph:topologicalSort`: Returns a topologically sorted table of Node handles, or nil if a cycle exists.
- `Graph:mst`: Returns edge IDs forming a minimum spanning tree (Kruskal, undirected view).
- `Graph:astar`: Finds the shortest path between two nodes using A*.
- `Graph:processDemand`: Processes all supply/demand declarations and fires event callbacks.
- `Graph:getStats`: Returns a statistics snapshot table.
- `Graph:type`: Returns the type name of this object.
- `Graph:typeOf`: Returns true if this object is of the given type.

### `GraphItem` Methods
- `GraphItem:getType`: Returns the item type string.
- `GraphItem:setType`: Sets the item type string.
- `GraphItem:getDecayTime`: Returns the decay time in seconds (-1 = immortal).
- `GraphItem:setDecayTime`: Sets the decay time in seconds (-1 = immortal).
- `GraphItem:getRemainingLife`: Returns the remaining life in seconds.
- `GraphItem:isAlive`: Returns true if the item is alive.
- `GraphItem:kill`: Marks the item as dead.
- `GraphItem:getPriority`: Returns the item priority.
- `GraphItem:setPriority`: Sets the item priority.
- `GraphItem:getPosition`: Returns the item position: node userdata if at a node, (edge, progress)
- `GraphItem:type`: Returns the type name of this object.
- `GraphItem:typeOf`: Returns true if this object is of the given type.

### `Node` Methods
- `Node:getType`: Returns the node type string.
- `Node:setType`: Sets the node type string.
- `Node:getCapacity`: Returns the node capacity (-1 = unlimited).
- `Node:setCapacity`: Sets the node capacity (-1 = unlimited).
- `Node:getItemCount`: Returns the number of items currently at this node.
- `Node:isFull`: Returns true if the node has reached its capacity.
- `Node:isActive`: Returns true if the node is active.
- `Node:setActive`: Sets the active state of this node.
- `Node:getOverflowPolicy`: Returns the overflow policy as a string.
- `Node:setOverflowPolicy`: Sets the overflow policy from a string.
- `Node:getFlowMode`: Returns the flow mode as a string.
- `Node:setFlowMode`: Sets the flow mode from a string.
- `Node:getPushRate`: Returns items per second this node pushes.
- `Node:setPushRate`: Sets items per second this node pushes.
- `Node:getPullRate`: Returns items per second this node pulls.
- `Node:setPullRate`: Sets items per second this node pulls.
- `Node:getPushFilter`: Returns the push filter string, or nil if unset.
- `Node:setPushFilter`: Sets the push filter string, or nil to clear.
- `Node:getPullFilter`: Returns the pull filter string, or nil if unset.
- `Node:setPullFilter`: Sets the pull filter string, or nil to clear.
- `Node:getProcessTime`: Returns the processing time in seconds.
- `Node:setProcessTime`: Sets the processing time in seconds.
- `Node:isQueueEnabled`: Returns true if the node queue is enabled.
- `Node:setQueueEnabled`: Enables or disables the node queue.
- `Node:getQueueCapacity`: Returns the queue capacity (-1 = unlimited).
- `Node:setQueueCapacity`: Sets the queue capacity (-1 = unlimited).
- `Node:getQueueSize`: Returns the number of items currently in the queue.
- `Node:getItems`: Returns a table of GraphItem handles at this node.
- `Node:getEdges`: Returns a table of Edge handles connected to this node.
- `Node:clearConversion`: Removes the conversion rule for the given input type.
- `Node:clearAllConversions`: Removes all conversion rules from this node.
- `Node:addTag`: Adds a tag to this node.
- `Node:removeTag`: Removes a tag from this node.
- `Node:hasTag`: Returns true if this node has the given tag.
- `Node:clearTags`: Removes all tags from this node.
- `Node:getTags`: Returns a table of tag strings on this node.
- `Node:removeSupply`: Removes the supply declaration for the given item type.
- `Node:clearSupplies`: Removes all supply declarations from this node.
- `Node:removeDemand`: Removes the demand declaration for the given item type.
- `Node:clearDemands`: Removes all demand declarations from this node.
- `Node:enqueue`: Pushes an item into the node queue.
- `Node:dequeue`: Pops the next item from the node queue, or nil if empty.
- `Node:type`: Returns the type name "GraphNode".
- `Node:typeOf`: Returns true when the given name matches "GraphNode" or a parent type.

## References

- `image`: Imports or references `image` from `src/image/`.
- `render`: Imports or references `render` from `src/render/`.
- `runtime`: Imports or references `runtime` from `src/runtime/`.

## Notes

- Keep this module reference synchronized with `src/graph/` and any matching Lua bindings.
- Summary paragraphs are manual prose. The collected Files, Types, Functions, Lua API Reference, and References sections can be regenerated when the source changes.
