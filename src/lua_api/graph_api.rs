//! `luna.graph` Lua API bindings.
//!
//! Auto-generated skeleton from `src/graph/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaEdge ────────────────────────────────────────────────────────────

pub struct LuaEdge(/* TODO: add key + state fields */);


impl LuaEdge {
    /// Whether the edge is in cooldown. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return boolean
    pub fn is_on_cooldown(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Whether the given item type is allowed on this edge.
    ///
    /// @param t : str
    /// @return boolean
    pub fn is_item_type_allowed(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Whether transit capacity is full. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return boolean
    pub fn is_transit_full(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaEdge {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isOnCooldown", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isItemTypeAllowed", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isTransitFull", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaGraph ────────────────────────────────────────────────────────────

pub struct LuaGraph(/* TODO: add key + state fields */);


impl LuaGraph {
    /// Find weakly connected components (treating all edges as undirected).
    ///
    ///
    /// @return table
    pub fn get_components(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Detect whether the directed graph contains a cycle (DFS-based).
    ///
    ///
    /// @return boolean
    pub fn has_cycle(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Topological sort using Kahn's algorithm.
    ///
    ///
    /// @return table?
    pub fn topological_sort(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Whether a node with the given ID exists.
    ///
    /// @param node_id : integer
    /// @return boolean
    pub fn has_node(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get all node IDs. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return table
    pub fn get_node_ids(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of nodes. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_node_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Whether an edge with the given ID exists.
    ///
    /// @param edge_id : integer
    /// @return boolean
    pub fn has_edge(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get all edge IDs. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return table
    pub fn get_edge_ids(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of edges. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_edge_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Find an edge from `from` to `to` (returns the first match).
    ///
    /// @param from : integer
    /// @param to : integer
    /// @return integer?
    pub fn get_edge_between(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Whether an item with the given ID exists.
    ///
    /// @param item_id : integer
    /// @return boolean
    pub fn has_item(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get all item IDs. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return table
    pub fn get_item_ids(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the number of items. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_item_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Compute a statistics snapshot. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return GraphStats
    pub fn get_stats(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get IDs of edges leaving a node. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// @param node_id : integer
    /// @return table
    pub fn get_outgoing_edges(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get IDs of edges arriving at a node.
    ///
    /// @param node_id : integer
    /// @return table
    pub fn get_incoming_edges(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Whether a node with the given ID exists.
    ///
    /// @param node_id : integer
    /// @return boolean
    /// Get all node IDs.
    ///
    ///
    /// @return table
    /// Get the number of nodes.
    ///
    ///
    /// @return integer
    /// Whether an edge with the given ID exists.
    ///
    /// @param edge_id : integer
    /// @return boolean
    /// Get all edge IDs.
    ///
    ///
    /// @return table
    /// Get the number of edges.
    ///
    ///
    /// @return integer
    /// Find an edge from `from` to `to` (returns the first match).
    ///
    /// @param from : integer
    /// @param to : integer
    /// @return integer?
    /// Whether an item with the given ID exists.
    ///
    /// @param item_id : integer
    /// @return boolean
    /// Get all item IDs.
    ///
    ///
    /// @return table
    /// Get the number of items.
    ///
    ///
    /// @return integer
    /// Compute a statistics snapshot.
    ///
    ///
    /// @return GraphStats
    /// Get IDs of edges leaving a node.
    ///
    /// @param node_id : integer
    /// @return table
    /// Get IDs of edges arriving at a node.
    ///
    /// @param node_id : integer
    /// @return table
    /// Find the shortest path from `from` to `to` using Dijkstra's algorithm.
    /// Uses edge `weight` as cost. Returns `None` if no path exists.
    ///
    /// @param from : integer
    /// @param to : integer
    /// @return PathResult?
    pub fn find_path(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Find a path that only uses edges the given item can traverse.
    /// Filters by: edge active, item type allowed, not on cooldown.
    ///
    /// @param item_id : integer
    /// @param from : integer
    /// @param to : integer
    /// @return PathResult?
    pub fn find_path_for_item(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the shortest-path distance between two nodes, or `None` if unreachable.
    ///
    /// @param from : integer
    /// @param to : integer
    /// @return number?
    pub fn get_distance(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get all nodes reachable from `from`, optionally limited by max distance.
    ///
    /// @param from : integer
    /// @param max_dist : number?
    /// @return table
    pub fn get_reachable(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get direct outgoing neighbors of a node.
    ///
    /// @param node_id : integer
    /// @return table
    pub fn get_neighbors(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaGraph {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getComponents", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasCycle", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("topologicalSort", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasNode", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getNodeIds", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getNodeCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasEdge", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEdgeIds", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEdgeCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEdgeBetween", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasItem", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getItemIds", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getItemCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getStats", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getOutgoingEdges", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getIncomingEdges", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasNode", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getNodeIds", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getNodeCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasEdge", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEdgeIds", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEdgeCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getEdgeBetween", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasItem", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getItemIds", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getItemCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getStats", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getOutgoingEdges", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getIncomingEdges", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("findPath", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("findPathForItem", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDistance", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getReachable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getNeighbors", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("findPath", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("findPathForItem", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDistance", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getReachable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getNeighbors", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaGraphItem ────────────────────────────────────────────────────────────

pub struct LuaGraphItem(/* TODO: add key + state fields */);


impl LuaGraphItem {
    /// Whether the item is still alive. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return boolean
    pub fn is_alive(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the decay time (`-1.0` = no decay).
    ///
    ///
    /// @return number
    pub fn get_decay_time(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get remaining life in seconds. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return number
    pub fn get_remaining_life(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the priority value. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_priority(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaGraphItem {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isAlive", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDecayTime", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRemainingLife", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getPriority", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaNode ────────────────────────────────────────────────────────────

pub struct LuaNode(/* TODO: add key + state fields */);


impl LuaNode {
    /// Get the capacity (`-1` = unlimited). This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return integer
    pub fn get_capacity(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Whether the node is at capacity. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return boolean
    pub fn is_full(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Number of items currently at this node. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// @return integer
    pub fn item_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Check if a tag is present. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// @param tag : str
    /// @return boolean
    pub fn has_tag(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get all tags as a sorted vector. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// @return table
    pub fn get_tags(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Get the supply for a given item type.
    ///
    /// @param item_type : str
    /// @return Option<
    pub fn get_supply(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the available supply quantity for a type (returns 0 if not found).
    ///
    /// @param item_type : str
    /// @return integer
    pub fn get_available_supply(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get the demand for a given item type.
    ///
    /// @param item_type : str
    /// @return Option<
    pub fn get_demand(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaNode {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getCapacity", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("isFull", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("itemCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasTag", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getTags", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getSupply", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getAvailableSupply", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getDemand", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.graph.* functions ──────────────────────────────────────────

/// Add a node with the given type and capacity. Returns the new node ID.
///
/// @param node_type : str
/// @param capacity : integer
/// @return integer
pub fn add_node(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a node and all connected edges. Items at the node become `Unplaced`.
///
/// @param node_id : integer
/// @return boolean
pub fn remove_node(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a directed edge between two existing nodes. Returns the edge ID.
///
/// @param from : integer
/// @param to : integer
/// @param edge_type : str?
/// @return Result<u64
pub fn add_edge(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove an edge. Items in transit on it become `Unplaced`. Returns `true` if it existed.
///
/// @param edge_id : integer
/// @return boolean
pub fn remove_edge(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a new item (starts `Unplaced`). Returns the item ID.
///
/// @param item_type : str
/// @param decay_time : number
/// @return integer
pub fn create_item(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Try to add an existing item to a node, respecting capacity and overflow policy.
///
/// @param item_id : integer
/// @param node_id : integer
/// @return Result<bool
pub fn add_item_to_node(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove an item from the graph entirely. Returns the removed value if present, or `None` when the key did not exist.
///
/// @param item_id : integer
/// @return boolean
pub fn remove_item(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Send an item onto an edge (start transit). Returns `Ok(true)` if sent.
///
/// @param item_id : integer
/// @param edge_id : integer
/// @return Result<bool
pub fn send_item(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the edge type. Replaces the current type value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param t : str
pub fn set_type(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add an allowed item type. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// @param t : str
pub fn add_allowed_type(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove an allowed item type. Returns the removed value if present, or `None` when the key did not exist.
///
/// @param t : str
/// @return boolean
pub fn remove_allowed_type(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a node with the given type and capacity. Returns the new node ID.
///
/// @param node_type : str
/// @param capacity : integer
/// @return integer
/// Remove a node and all connected edges. Items at the node become `Unplaced`.
/// Returns `true` if the node existed.
///
/// @param node_id : integer
/// @return boolean
/// Add a directed edge between two existing nodes. Returns the edge ID.
///
/// @param from : integer
/// @param to : integer
/// @param edge_type : str?
/// @return Result<u64
/// Remove an edge. Items in transit on it become `Unplaced`. Returns `true` if it existed.
///
/// @param edge_id : integer
/// @return boolean
/// Create a new item (starts `Unplaced`). Returns the item ID.
///
/// @param item_type : str
/// @param decay_time : number
/// @return integer
/// Try to add an existing item to a node, respecting capacity and overflow policy.
/// Returns `Ok(true)` if placed, `Ok(false)` if rejected or destroyed, `Err` on invalid IDs.
///
/// @param item_id : integer
/// @param node_id : integer
/// @return Result<bool
/// Remove an item from the graph entirely.
///
/// @param item_id : integer
/// @return boolean
/// Send an item onto an edge (start transit). Returns `Ok(true)` if sent.
///
/// @param item_id : integer
/// @param edge_id : integer
/// @return Result<bool
/// Set the item type. Replaces the current type value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param item_type : str
/// Set the decay time. Also resets remaining life if positive.
///
///
/// @param t : number
pub fn set_decay_time(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set remaining life in seconds. Replaces the current remaining life value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param t : number
pub fn set_remaining_life(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the priority value. Replaces the current priority value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param p : integer
pub fn set_priority(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the current position. Replaces the current position value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param pos : ItemPosition
pub fn set_position(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set the node type. Replaces the current type value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param t : str
/// Set the capacity. Replaces the current capacity value; callers hold responsibility for maintaining consistency with related fields.
///
///
/// @param c : integer
pub fn set_capacity(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a tag. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// @param tag : str
pub fn add_tag(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a tag. Returns whether it was present.
///
/// @param tag : str
/// @return boolean
pub fn remove_tag(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a supply declaration. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// @param item_type : str
/// @param quantity : integer
pub fn add_supply(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove supply declarations for the given item type. Returns whether any were removed.
///
/// @param item_type : str
/// @return boolean
pub fn remove_supply(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a demand declaration. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// @param item_type : str
/// @param quantity : integer
/// @param priority : integer
pub fn add_demand(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove demand declarations for the given item type. Returns whether any were removed.
///
/// @param item_type : str
/// @return boolean
pub fn remove_demand(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set a conversion rule (keyed by input type).
///
///
/// @param rule : ConversionRule
pub fn set_conversion(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a conversion rule by input type. Returns whether it was present.
///
/// @param in_type : str
/// @return boolean
pub fn clear_conversion(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Push an item ID onto the back of the queue.
///
/// @param item_id : integer
/// @return boolean
pub fn enqueue(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Pop an item ID from the front of the queue.
///
///
/// @return integer?
pub fn dequeue(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Advance the simulation by `dt` seconds. Returns events for callback dispatch.
///
/// @param dt : number
/// @return table
pub fn update(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// One discrete simulation step (equivalent to `update(1.0)`).
///
///
/// @return table
pub fn step(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Process all demand/supply declarations. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// @return table
pub fn process_demand(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.graph` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("addNode", lua.create_function(add_node)?)?;
    tbl.set("removeNode", lua.create_function(remove_node)?)?;
    tbl.set("addEdge", lua.create_function(add_edge)?)?;
    tbl.set("removeEdge", lua.create_function(remove_edge)?)?;
    tbl.set("createItem", lua.create_function(create_item)?)?;
    tbl.set("addItemToNode", lua.create_function(add_item_to_node)?)?;
    tbl.set("removeItem", lua.create_function(remove_item)?)?;
    tbl.set("sendItem", lua.create_function(send_item)?)?;
    tbl.set("setType", lua.create_function(set_type)?)?;
    tbl.set("addAllowedType", lua.create_function(add_allowed_type)?)?;
    tbl.set("removeAllowedType", lua.create_function(remove_allowed_type)?)?;
    tbl.set("addNode", lua.create_function(add_node)?)?;
    tbl.set("removeNode", lua.create_function(remove_node)?)?;
    tbl.set("addEdge", lua.create_function(add_edge)?)?;
    tbl.set("removeEdge", lua.create_function(remove_edge)?)?;
    tbl.set("createItem", lua.create_function(create_item)?)?;
    tbl.set("addItemToNode", lua.create_function(add_item_to_node)?)?;
    tbl.set("removeItem", lua.create_function(remove_item)?)?;
    tbl.set("sendItem", lua.create_function(send_item)?)?;
    tbl.set("setType", lua.create_function(set_type)?)?;
    tbl.set("setDecayTime", lua.create_function(set_decay_time)?)?;
    tbl.set("setRemainingLife", lua.create_function(set_remaining_life)?)?;
    tbl.set("setPriority", lua.create_function(set_priority)?)?;
    tbl.set("setPosition", lua.create_function(set_position)?)?;
    tbl.set("setType", lua.create_function(set_type)?)?;
    tbl.set("setCapacity", lua.create_function(set_capacity)?)?;
    tbl.set("addTag", lua.create_function(add_tag)?)?;
    tbl.set("removeTag", lua.create_function(remove_tag)?)?;
    tbl.set("addSupply", lua.create_function(add_supply)?)?;
    tbl.set("removeSupply", lua.create_function(remove_supply)?)?;
    tbl.set("addDemand", lua.create_function(add_demand)?)?;
    tbl.set("removeDemand", lua.create_function(remove_demand)?)?;
    tbl.set("setConversion", lua.create_function(set_conversion)?)?;
    tbl.set("clearConversion", lua.create_function(clear_conversion)?)?;
    tbl.set("enqueue", lua.create_function(enqueue)?)?;
    tbl.set("dequeue", lua.create_function(dequeue)?)?;
    tbl.set("update", lua.create_function(update)?)?;
    tbl.set("step", lua.create_function(step)?)?;
    tbl.set("processDemand", lua.create_function(process_demand)?)?;
    luna.set("graph", tbl)?;
    Ok(())
}
