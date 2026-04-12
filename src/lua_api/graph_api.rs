//! `lurek.graph` — directed graph with item flow simulation.

use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::str::FromStr;

use crate::runtime::SharedState;
use crate::graph::pathfinding::PathResult;
use crate::graph::{ConversionRule, FlowMode, Graph, GraphEvent, ItemPosition, OverflowPolicy};

// ── Constants ───────────────────────────────────────────────────────────

/// Valid callback event names for `LuaGraph:on()`.
const VALID_EVENTS: &[&str] = &[
    "itemEnter",
    "itemLeave",
    "itemDecay",
    "itemConvert",
    "itemLost",
    "edgeEnter",
    "edgeLeave",
    "demandFulfilled",
    "supplyDepleted",
    "itemQueued",
    "itemDequeued",
];

// ── Wrapper Types ───────────────────────────────────────────────────────

/// Lua wrapper around a directed `Graph` with event callback registry.
#[derive(Clone)]
struct LuaGraph {
    inner: Rc<RefCell<Graph>>,
    callbacks: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}

/// Lua handle for a node inside a `Graph`.
#[derive(Clone)]
struct LuaNode {
    graph: Rc<RefCell<Graph>>,
    id: u64,
}

/// Lua handle for an edge inside a `Graph`.
#[derive(Clone)]
struct LuaEdge {
    graph: Rc<RefCell<Graph>>,
    id: u64,
}

/// Lua handle for an item inside a `Graph`.
#[derive(Clone)]
struct LuaGraphItem {
    graph: Rc<RefCell<Graph>>,
    id: u64,
}

// ── Helper Macros ───────────────────────────────────────────────────────

/// Borrow graph immutably, look up node by id, return error if missing.
macro_rules! with_node {
    ($this:expr, $g:ident, $node:ident, $body:expr) => {{
        let $g = $this.graph.borrow();
        let $node = $g
            .nodes
            .get(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("node not found".into()))?;
        $body
    }};
}

/// Borrow graph mutably, look up node by id, return error if missing.
macro_rules! with_node_mut {
    ($this:expr, $g:ident, $node:ident, $body:expr) => {{
        let mut $g = $this.graph.borrow_mut();
        let $node = $g
            .nodes
            .get_mut(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("node not found".into()))?;
        $body
    }};
}

/// Borrow graph immutably, look up edge by id, return error if missing.
macro_rules! with_edge {
    ($this:expr, $g:ident, $edge:ident, $body:expr) => {{
        let $g = $this.graph.borrow();
        let $edge = $g
            .edges
            .get(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("edge not found".into()))?;
        $body
    }};
}

/// Borrow graph mutably, look up edge by id, return error if missing.
macro_rules! with_edge_mut {
    ($this:expr, $g:ident, $edge:ident, $body:expr) => {{
        let mut $g = $this.graph.borrow_mut();
        let $edge = $g
            .edges
            .get_mut(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("edge not found".into()))?;
        $body
    }};
}

/// Borrow graph immutably, look up item by id, return error if missing.
macro_rules! with_item {
    ($this:expr, $g:ident, $item:ident, $body:expr) => {{
        let $g = $this.graph.borrow();
        let $item = $g
            .items
            .get(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("item not found".into()))?;
        $body
    }};
}

/// Borrow graph mutably, look up item by id, return error if missing.
macro_rules! with_item_mut {
    ($this:expr, $g:ident, $item:ident, $body:expr) => {{
        let mut $g = $this.graph.borrow_mut();
        let $item = $g
            .items
            .get_mut(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("item not found".into()))?;
        $body
    }};
}

// ── Helpers ─────────────────────────────────────────────────────────────

fn path_result_to_lua<'lua>(
    lua: &'lua Lua,
    graph: &Rc<RefCell<Graph>>,
    result: &PathResult,
) -> LuaResult<LuaTable<'lua>> {
    let table = lua.create_table()?;
    let nodes_table = lua.create_table()?;
    for (i, nid) in result.nodes.iter().enumerate() {
        nodes_table.set(
            i + 1,
            LuaNode {
                graph: graph.clone(),
                id: *nid,
            },
        )?;
    }
    table.set("nodes", nodes_table)?;
    let edges_table = lua.create_table()?;
    for (i, eid) in result.edges.iter().enumerate() {
        edges_table.set(
            i + 1,
            LuaEdge {
                graph: graph.clone(),
                id: *eid,
            },
        )?;
    }
    table.set("edges", edges_table)?;
    table.set("cost", result.cost)?;
    Ok(table)
}

// ── GraphItem UserData ──────────────────────────────────────────────────

impl LuaUserData for LuaGraphItem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- __tostring --
        /// Returns a debug string for this item.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GraphItem({})", this.id))
        });

        // -- getType --
        /// Returns the item type string.
        /// @return string
        methods.add_method("getType", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_type().to_string()))
        });

        // -- setType --
        /// Sets the item type string.
        /// @param t : string
        /// @return nil
        methods.add_method("setType", |_, this, t: String| {
            with_item_mut!(this, g, item, {
                item.set_type(&t);
                Ok(())
            })
        });

        // -- getDecayTime --
        /// Returns the decay time in seconds (-1 = immortal).
        /// @return number
        methods.add_method("getDecayTime", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_decay_time()))
        });

        // -- setDecayTime --
        /// Sets the decay time in seconds (-1 = immortal).
        /// @param t : number
        /// @return nil
        methods.add_method("setDecayTime", |_, this, t: f64| {
            with_item_mut!(this, g, item, {
                item.set_decay_time(t);
                Ok(())
            })
        });

        // -- getRemainingLife --
        /// Returns the remaining life in seconds.
        /// @return number
        methods.add_method("getRemainingLife", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_remaining_life()))
        });

        // -- isAlive --
        /// Returns true if the item is alive.
        /// @return boolean
        methods.add_method("isAlive", |_, this, ()| {
            with_item!(this, g, item, Ok(item.is_alive()))
        });

        // -- kill --
        /// Marks the item as dead.
        /// @return nil
        methods.add_method("kill", |_, this, ()| {
            with_item_mut!(this, g, item, {
                item.kill();
                Ok(())
            })
        });

        // -- getPriority --
        /// Returns the item priority.
        /// @return integer
        methods.add_method("getPriority", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_priority()))
        });

        // -- setPriority --
        /// Sets the item priority.
        /// @param p : integer
        /// @return nil
        methods.add_method("setPriority", |_, this, p: i32| {
            with_item_mut!(this, g, item, {
                item.set_priority(p);
                Ok(())
            })
        });

        // -- getPosition --
        /// Returns the item position: node userdata if at a node, (edge, progress)
        /// if in transit, or nothing if unplaced.
        /// @return Node|Edge|nil
        methods.add_method("getPosition", |lua, this, ()| -> LuaResult<LuaMultiValue> {
            let graph = this.graph.borrow();
            let item = graph
                .items
                .get(&this.id)
                .ok_or_else(|| LuaError::RuntimeError("item not found".into()))?;
            match &item.position {
                ItemPosition::AtNode(node_id) => {
                    Ok(LuaMultiValue::from_vec(vec![LuaValue::UserData(
                        lua.create_userdata(LuaNode {
                            graph: this.graph.clone(),
                            id: *node_id,
                        })?,
                    )]))
                }
                ItemPosition::InTransit { edge_id, progress } => Ok(LuaMultiValue::from_vec(vec![
                    LuaValue::UserData(lua.create_userdata(LuaEdge {
                        graph: this.graph.clone(),
                        id: *edge_id,
                    })?),
                    LuaValue::Number(*progress),
                ])),
                ItemPosition::Unplaced => Ok(LuaMultiValue::from_vec(vec![])),
            }
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("GraphItem"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "GraphItem" || name == "Object")
        });
    }
}

// ── Edge UserData ───────────────────────────────────────────────────────

impl LuaUserData for LuaEdge {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- __tostring --
        /// Returns a debug string for this edge.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GraphEdge({})", this.id))
        });

        // -- getType --
        /// Returns the edge type string.
        /// @return string
        methods.add_method("getType", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.get_type().to_string()))
        });

        // -- setType --
        /// Sets the edge type string.
        /// @param t : string
        /// @return nil
        methods.add_method("setType", |_, this, t: String| {
            with_edge_mut!(this, g, edge, {
                edge.set_type(&t);
                Ok(())
            })
        });

        // -- getFrom --
        /// Returns the source node handle.
        /// @return Node
        methods.add_method("getFrom", |_, this, ()| {
            with_edge!(
                this,
                g,
                edge,
                Ok(LuaNode {
                    graph: this.graph.clone(),
                    id: edge.from_node,
                })
            )
        });

        // -- getTo --
        /// Returns the destination node handle.
        /// @return Node
        methods.add_method("getTo", |_, this, ()| {
            with_edge!(
                this,
                g,
                edge,
                Ok(LuaNode {
                    graph: this.graph.clone(),
                    id: edge.to_node,
                })
            )
        });

        // -- getCapacity --
        /// Returns the edge capacity (-1 = unlimited).
        /// @return integer
        methods.add_method("getCapacity", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.capacity))
        });

        // -- setCapacity --
        /// Sets the edge capacity (-1 = unlimited).
        /// @param c : integer
        /// @return nil
        methods.add_method("setCapacity", |_, this, c: i32| {
            with_edge_mut!(this, g, edge, {
                edge.capacity = c;
                Ok(())
            })
        });

        // -- getThroughput --
        /// Returns items per second this edge can transfer.
        /// @return number
        methods.add_method("getThroughput", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.throughput))
        });

        // -- setThroughput --
        /// Sets items per second this edge can transfer.
        /// @param t : number
        /// @return nil
        methods.add_method("setThroughput", |_, this, t: f64| {
            with_edge_mut!(this, g, edge, {
                edge.throughput = t;
                Ok(())
            })
        });

        // -- getTravelTime --
        /// Returns the travel time in seconds for items on this edge.
        /// @return number
        methods.add_method("getTravelTime", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.travel_time))
        });

        // -- setTravelTime --
        /// Sets the travel time in seconds for items on this edge.
        /// @param t : number
        /// @return nil
        methods.add_method("setTravelTime", |_, this, t: f64| {
            with_edge_mut!(this, g, edge, {
                edge.travel_time = t;
                Ok(())
            })
        });

        // -- getWeight --
        /// Returns the pathfinding weight of this edge.
        /// @return number
        methods.add_method("getWeight", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.weight))
        });

        // -- setWeight --
        /// Sets the pathfinding weight of this edge.
        /// @param w : number
        /// @return nil
        methods.add_method("setWeight", |_, this, w: f64| {
            with_edge_mut!(this, g, edge, {
                edge.weight = w;
                Ok(())
            })
        });

        // -- getSpeedModifier --
        /// Returns the speed modifier applied to items in transit.
        /// @return number
        methods.add_method("getSpeedModifier", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.speed_modifier))
        });

        // -- setSpeedModifier --
        /// Sets the speed modifier applied to items in transit.
        /// @param m : number
        /// @return nil
        methods.add_method("setSpeedModifier", |_, this, m: f64| {
            with_edge_mut!(this, g, edge, {
                edge.speed_modifier = m;
                Ok(())
            })
        });

        // -- getCooldown --
        /// Returns the cooldown duration in seconds.
        /// @return number
        methods.add_method("getCooldown", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.cooldown))
        });

        // -- setCooldown --
        /// Sets the cooldown duration in seconds.
        /// @param c : number
        /// @return nil
        methods.add_method("setCooldown", |_, this, c: f64| {
            with_edge_mut!(this, g, edge, {
                edge.cooldown = c;
                Ok(())
            })
        });

        // -- isOnCooldown --
        /// Returns true if the edge is currently on cooldown.
        /// @return boolean
        methods.add_method("isOnCooldown", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.is_on_cooldown()))
        });

        // -- isBidirectional --
        /// Returns true if items can travel the edge in either direction.
        /// @return boolean
        methods.add_method("isBidirectional", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.bidirectional))
        });

        // -- setBidirectional --
        /// Sets whether items can travel the edge in either direction.
        /// @param b : boolean
        /// @return nil
        methods.add_method("setBidirectional", |_, this, b: bool| {
            with_edge_mut!(this, g, edge, {
                edge.bidirectional = b;
                Ok(())
            })
        });

        // -- isActive --
        /// Returns true if the edge is active.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.active))
        });

        // -- setActive --
        /// Sets the active state of this edge.
        /// @param a : boolean
        /// @return nil
        methods.add_method("setActive", |_, this, a: bool| {
            with_edge_mut!(this, g, edge, {
                edge.active = a;
                Ok(())
            })
        });

        // -- getItemsInTransit --
        /// Returns a table of GraphItem handles currently in transit on this edge.
        /// @return table
        methods.add_method("getItemsInTransit", |lua, this, ()| {
            let graph = this.graph.borrow();
            let edge = graph
                .edges
                .get(&this.id)
                .ok_or_else(|| LuaError::RuntimeError("edge not found".into()))?;
            let table = lua.create_table()?;
            for (i, iid) in edge.items_in_transit.iter().enumerate() {
                table.set(
                    i + 1,
                    LuaGraphItem {
                        graph: this.graph.clone(),
                        id: *iid,
                    },
                )?;
            }
            Ok(table)
        });

        // -- addAllowedType --
        /// Adds an item type to the edge allow-list.
        /// @param t : string
        /// @return nil
        methods.add_method("addAllowedType", |_, this, t: String| {
            with_edge_mut!(this, g, edge, {
                edge.add_allowed_type(&t);
                Ok(())
            })
        });

        // -- removeAllowedType --
        /// Removes an item type from the edge allow-list.
        /// @param t : string
        /// @return boolean
        methods.add_method("removeAllowedType", |_, this, t: String| {
            with_edge_mut!(this, g, edge, Ok(edge.remove_allowed_type(&t)))
        });

        // -- clearAllowedTypes --
        /// Clears the edge allow-list so all item types are permitted.
        /// @return nil
        methods.add_method("clearAllowedTypes", |_, this, ()| {
            with_edge_mut!(this, g, edge, {
                edge.clear_allowed_types();
                Ok(())
            })
        });

        // -- isItemTypeAllowed --
        /// Returns true if the given item type is allowed on this edge.
        /// @param t : string
        /// @return boolean
        methods.add_method("isItemTypeAllowed", |_, this, t: String| {
            with_edge!(this, g, edge, Ok(edge.is_item_type_allowed(&t)))
        });

        // -- type --
        /// Returns the type name "GraphEdge".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("GraphEdge"));
        // -- typeOf --
        /// Returns true when the given name matches "GraphEdge" or a parent type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "GraphEdge" || name == "Object")
        });
    }
}

// ── Node UserData ───────────────────────────────────────────────────────

impl LuaUserData for LuaNode {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- __tostring --
        /// Returns a debug string for this node.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GraphNode({})", this.id))
        });

        // ---- Properties ----

        // -- getType --
        /// Returns the node type string.
        /// @return string
        methods.add_method("getType", |_, this, ()| {
            with_node!(this, g, node, Ok(node.get_type().to_string()))
        });

        // -- setType --
        /// Sets the node type string.
        /// @param t : string
        /// @return nil
        methods.add_method("setType", |_, this, t: String| {
            with_node_mut!(this, g, node, {
                node.set_type(&t);
                Ok(())
            })
        });

        // -- getCapacity --
        /// Returns the node capacity (-1 = unlimited).
        /// @return integer
        methods.add_method("getCapacity", |_, this, ()| {
            with_node!(this, g, node, Ok(node.get_capacity()))
        });

        // -- setCapacity --
        /// Sets the node capacity (-1 = unlimited).
        /// @param c : integer
        /// @return nil
        methods.add_method("setCapacity", |_, this, c: i32| {
            with_node_mut!(this, g, node, {
                node.set_capacity(c);
                Ok(())
            })
        });

        // -- getItemCount --
        /// Returns the number of items currently at this node.
        /// @return integer
        methods.add_method("getItemCount", |_, this, ()| {
            with_node!(this, g, node, Ok(node.item_count()))
        });

        // -- isFull --
        /// Returns true if the node has reached its capacity.
        /// @return boolean
        methods.add_method("isFull", |_, this, ()| {
            with_node!(this, g, node, Ok(node.is_full()))
        });

        // -- isActive --
        /// Returns true if the node is active.
        /// @return boolean
        methods.add_method("isActive", |_, this, ()| {
            with_node!(this, g, node, Ok(node.active))
        });

        // -- setActive --
        /// Sets the active state of this node.
        /// @param a : boolean
        /// @return nil
        methods.add_method("setActive", |_, this, a: bool| {
            with_node_mut!(this, g, node, {
                node.active = a;
                Ok(())
            })
        });

        // ---- Overflow / Flow ----

        // -- getOverflowPolicy --
        /// Returns the overflow policy as a string.
        /// @return string
        methods.add_method("getOverflowPolicy", |_, this, ()| {
            with_node!(this, g, node, Ok(node.overflow_policy.to_str().to_string()))
        });

        // -- setOverflowPolicy --
        /// Sets the overflow policy from a string.
        /// @param p : string
        /// @return nil
        methods.add_method("setOverflowPolicy", |_, this, p: String| {
            let policy = OverflowPolicy::from_str(&p).map_err(LuaError::RuntimeError)?;
            with_node_mut!(this, g, node, {
                node.overflow_policy = policy;
                Ok(())
            })
        });

        // -- getFlowMode --
        /// Returns the flow mode as a string.
        /// @return string
        methods.add_method("getFlowMode", |_, this, ()| {
            with_node!(this, g, node, Ok(node.flow_mode.to_str().to_string()))
        });

        // -- setFlowMode --
        /// Sets the flow mode from a string.
        /// @param m : string
        /// @return nil
        methods.add_method("setFlowMode", |_, this, m: String| {
            let mode = FlowMode::from_str(&m).map_err(LuaError::RuntimeError)?;
            with_node_mut!(this, g, node, {
                node.flow_mode = mode;
                Ok(())
            })
        });

        // ---- Push / Pull ----

        // -- getPushRate --
        /// Returns items per second this node pushes.
        /// @return number
        methods.add_method("getPushRate", |_, this, ()| {
            with_node!(this, g, node, Ok(node.push_rate))
        });

        // -- setPushRate --
        /// Sets items per second this node pushes.
        /// @param r : number
        /// @return nil
        methods.add_method("setPushRate", |_, this, r: f64| {
            with_node_mut!(this, g, node, {
                node.push_rate = r;
                Ok(())
            })
        });

        // -- getPullRate --
        /// Returns items per second this node pulls.
        /// @return number
        methods.add_method("getPullRate", |_, this, ()| {
            with_node!(this, g, node, Ok(node.pull_rate))
        });

        // -- setPullRate --
        /// Sets items per second this node pulls.
        /// @param r : number
        /// @return nil
        methods.add_method("setPullRate", |_, this, r: f64| {
            with_node_mut!(this, g, node, {
                node.pull_rate = r;
                Ok(())
            })
        });

        // -- getPushFilter --
        /// Returns the push filter string, or nil if unset.
        /// @return string?
        methods.add_method("getPushFilter", |_, this, ()| {
            with_node!(this, g, node, Ok(node.push_filter.clone()))
        });

        // -- setPushFilter --
        /// Sets the push filter string, or nil to clear.
        /// @param f : string?
        /// @return nil
        methods.add_method("setPushFilter", |_, this, f: Option<String>| {
            with_node_mut!(this, g, node, {
                node.push_filter = f;
                Ok(())
            })
        });

        // -- getPullFilter --
        /// Returns the pull filter string, or nil if unset.
        /// @return string?
        methods.add_method("getPullFilter", |_, this, ()| {
            with_node!(this, g, node, Ok(node.pull_filter.clone()))
        });

        // -- setPullFilter --
        /// Sets the pull filter string, or nil to clear.
        /// @param f : string?
        /// @return nil
        methods.add_method("setPullFilter", |_, this, f: Option<String>| {
            with_node_mut!(this, g, node, {
                node.pull_filter = f;
                Ok(())
            })
        });

        // ---- Processing ----

        // -- getProcessTime --
        /// Returns the processing time in seconds.
        /// @return number
        methods.add_method("getProcessTime", |_, this, ()| {
            with_node!(this, g, node, Ok(node.process_time))
        });

        // -- setProcessTime --
        /// Sets the processing time in seconds.
        /// @param t : number
        /// @return nil
        methods.add_method("setProcessTime", |_, this, t: f64| {
            with_node_mut!(this, g, node, {
                node.process_time = t;
                Ok(())
            })
        });

        // ---- Queue ----

        // -- isQueueEnabled --
        /// Returns true if the node queue is enabled.
        /// @return boolean
        methods.add_method("isQueueEnabled", |_, this, ()| {
            with_node!(this, g, node, Ok(node.queue_enabled))
        });

        // -- setQueueEnabled --
        /// Enables or disables the node queue.
        /// @param e : boolean
        /// @return nil
        methods.add_method("setQueueEnabled", |_, this, e: bool| {
            with_node_mut!(this, g, node, {
                node.queue_enabled = e;
                Ok(())
            })
        });

        // -- getQueueCapacity --
        /// Returns the queue capacity (-1 = unlimited).
        /// @return integer
        methods.add_method("getQueueCapacity", |_, this, ()| {
            with_node!(this, g, node, Ok(node.queue_capacity))
        });

        // -- setQueueCapacity --
        /// Sets the queue capacity (-1 = unlimited).
        /// @param c : integer
        /// @return nil
        methods.add_method("setQueueCapacity", |_, this, c: i32| {
            with_node_mut!(this, g, node, {
                node.queue_capacity = c;
                Ok(())
            })
        });

        // -- getQueueSize --
        /// Returns the number of items currently in the queue.
        /// @return integer
        methods.add_method("getQueueSize", |_, this, ()| {
            with_node!(this, g, node, Ok(node.queue.len()))
        });

        // ---- Items & Edges ----

        // -- getItems --
        /// Returns a table of GraphItem handles at this node.
        /// @return table
        methods.add_method("getItems", |lua, this, ()| {
            let graph = this.graph.borrow();
            let node = graph
                .nodes
                .get(&this.id)
                .ok_or_else(|| LuaError::RuntimeError("node not found".into()))?;
            let table = lua.create_table()?;
            for (i, iid) in node.items.iter().enumerate() {
                table.set(
                    i + 1,
                    LuaGraphItem {
                        graph: this.graph.clone(),
                        id: *iid,
                    },
                )?;
            }
            Ok(table)
        });

        // -- getEdges --
        /// Returns a table of Edge handles connected to this node.
        /// @param dir : string?
        /// @return table
        methods.add_method("getEdges", |lua, this, dir: Option<String>| {
            let direction = dir.as_deref().unwrap_or("both");
            let ids = this
                .graph
                .borrow()
                .get_edges_by_direction(this.id, direction)
                .map_err(LuaError::runtime)?;
            let table = lua.create_table()?;
            for (i, eid) in ids.iter().enumerate() {
                table.set(
                    i + 1,
                    LuaEdge {
                        graph: this.graph.clone(),
                        id: *eid,
                    },
                )?;
            }
            Ok(table)
        });

        // ---- Conversion ----

        // -- setConversion --
        /// Adds or replaces a conversion rule on this node.
        /// @param in_type : string
        /// @param out_type : string
        /// @param in_count : integer?
        /// @param out_count : integer?
        methods.add_method(
            "setConversion",
            |_,
             this,
             (in_type, out_type, in_count, out_count): (
                String,
                String,
                Option<u32>,
                Option<u32>,
            )| {
                let rule = ConversionRule {
                    in_type,
                    out_type,
                    in_count: in_count.unwrap_or(1),
                    out_count: out_count.unwrap_or(1),
                };
                with_node_mut!(this, g, node, {
                    node.set_conversion(rule);
                    Ok(())
                })
            },
        );

        // -- clearConversion --
        /// Removes the conversion rule for the given input type.
        /// @param in_type : string
        /// @return nil
        methods.add_method("clearConversion", |_, this, in_type: String| {
            with_node_mut!(this, g, node, Ok(node.clear_conversion(&in_type)))
        });

        // -- clearAllConversions --
        /// Removes all conversion rules from this node.
        /// @return nil
        methods.add_method("clearAllConversions", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_all_conversions();
                Ok(())
            })
        });

        // ---- Tags ----

        // -- addTag --
        /// Adds a tag to this node.
        /// @param tag : string
        /// @return nil
        methods.add_method("addTag", |_, this, tag: String| {
            with_node_mut!(this, g, node, {
                node.add_tag(&tag);
                Ok(())
            })
        });

        // -- removeTag --
        /// Removes a tag from this node.
        /// @param tag : string
        /// @return boolean
        methods.add_method("removeTag", |_, this, tag: String| {
            with_node_mut!(this, g, node, Ok(node.remove_tag(&tag)))
        });

        // -- hasTag --
        /// Returns true if this node has the given tag.
        /// @param tag : string
        /// @return boolean
        methods.add_method("hasTag", |_, this, tag: String| {
            with_node!(this, g, node, Ok(node.has_tag(&tag)))
        });

        // -- clearTags --
        /// Removes all tags from this node.
        /// @return nil
        methods.add_method("clearTags", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_tags();
                Ok(())
            })
        });

        // -- getTags --
        /// Returns a table of tag strings on this node.
        /// @return table
        methods.add_method("getTags", |lua, this, ()| {
            let graph = this.graph.borrow();
            let node = graph
                .nodes
                .get(&this.id)
                .ok_or_else(|| LuaError::RuntimeError("node not found".into()))?;
            let tags = node.get_tags();
            let table = lua.create_table()?;
            for (i, tag) in tags.iter().enumerate() {
                table.set(i + 1, tag.as_str())?;
            }
            Ok(table)
        });

        // ---- Supply / Demand ----

        // -- addSupply --
        /// Declares a supply of the given item type and quantity at this node.
        /// @param item_type : string
        /// @param quantity : integer
        /// @return nil
        methods.add_method(
            "addSupply",
            |_, this, (item_type, quantity): (String, i32)| {
                with_node_mut!(this, g, node, {
                    node.add_supply(&item_type, quantity);
                    Ok(())
                })
            },
        );

        // -- removeSupply --
        /// Removes the supply declaration for the given item type.
        /// @param item_type : string
        /// @return boolean
        methods.add_method("removeSupply", |_, this, item_type: String| {
            with_node_mut!(this, g, node, Ok(node.remove_supply(&item_type)))
        });

        // -- clearSupplies --
        /// Removes all supply declarations from this node.
        /// @return nil
        methods.add_method("clearSupplies", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_supplies();
                Ok(())
            })
        });

        // -- addDemand --
        /// Declares a demand for the given item type, quantity, and priority.
        /// @param item_type : string
        /// @param quantity : integer
        /// @param priority : integer?
        methods.add_method(
            "addDemand",
            |_, this, (item_type, quantity, priority): (String, i32, Option<i32>)| {
                let p = priority.unwrap_or(0);
                with_node_mut!(this, g, node, {
                    node.add_demand(&item_type, quantity, p);
                    Ok(())
                })
            },
        );

        // -- removeDemand --
        /// Removes the demand declaration for the given item type.
        /// @param item_type : string
        /// @return boolean
        methods.add_method("removeDemand", |_, this, item_type: String| {
            with_node_mut!(this, g, node, Ok(node.remove_demand(&item_type)))
        });

        // -- clearDemands --
        /// Removes all demand declarations from this node.
        /// @return nil
        methods.add_method("clearDemands", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_demands();
                Ok(())
            })
        });

        // ---- Queue operations ----

        // -- enqueue --
        /// Pushes an item into the node queue.
        /// @param item_ud : GraphItem
        /// @return boolean
        methods.add_method("enqueue", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            with_node_mut!(this, g, node, Ok(node.enqueue(item.id)))
        });

        // -- dequeue --
        /// Pops the next item from the node queue, or nil if empty.
        /// @return GraphItem?
        methods.add_method("dequeue", |_, this, ()| {
            let mut graph = this.graph.borrow_mut();
            let node = graph
                .nodes
                .get_mut(&this.id)
                .ok_or_else(|| LuaError::RuntimeError("node not found".into()))?;
            match node.dequeue() {
                Some(iid) => Ok(Some(LuaGraphItem {
                    graph: this.graph.clone(),
                    id: iid,
                })),
                None => Ok(None),
            }
        });

        // -- type --
        /// Returns the type name "GraphNode".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("GraphNode"));
        // -- typeOf --
        /// Returns true when the given name matches "GraphNode" or a parent type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "GraphNode" || name == "Object")
        });
    }
}

// ── Graph UserData ──────────────────────────────────────────────────────

impl LuaUserData for LuaGraph {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- __tostring --
        /// Returns a debug string for this graph.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let g = this.inner.borrow();
            Ok(format!(
                "Graph(nodes={}, edges={}, items={})",
                g.get_node_count(),
                g.get_edge_count(),
                g.get_item_count()
            ))
        });

        // ── Node management ─────────────────────────────────────────

        // -- addNode --
        /// Adds a node and returns its handle.
        /// @param node_type : string?
        /// @param capacity : integer?
        /// @return Node
        methods.add_method(
            "addNode",
            |_, this, (node_type, capacity): (Option<String>, Option<i32>)| {
                let t = node_type.as_deref().unwrap_or("default");
                let c = capacity.unwrap_or(-1);
                let id = this.inner.borrow_mut().add_node(t, c);
                Ok(LuaNode {
                    graph: this.inner.clone(),
                    id,
                })
            },
        );

        // -- removeNode --
        /// Removes a node from the graph.
        /// @param node_ud : Node
        /// @return boolean
        methods.add_method("removeNode", |_, this, node_ud: LuaAnyUserData| {
            let node = node_ud.borrow::<LuaNode>()?;
            Ok(this.inner.borrow_mut().remove_node(node.id))
        });

        // -- hasNode --
        /// Returns true if the node exists in the graph.
        /// @param node_ud : Node
        /// @return boolean
        methods.add_method("hasNode", |_, this, node_ud: LuaAnyUserData| {
            let node = node_ud.borrow::<LuaNode>()?;
            Ok(this.inner.borrow().has_node(node.id))
        });

        // -- getNodes --
        /// Returns a table of all Node handles.
        /// @return table
        methods.add_method("getNodes", |lua, this, ()| {
            let graph = this.inner.borrow();
            let ids = graph.get_node_ids();
            let table = lua.create_table()?;
            for (i, nid) in ids.iter().enumerate() {
                table.set(
                    i + 1,
                    LuaNode {
                        graph: this.inner.clone(),
                        id: *nid,
                    },
                )?;
            }
            Ok(table)
        });

        // -- getNodeCount --
        /// Returns the number of nodes in the graph.
        /// @return integer
        methods.add_method("getNodeCount", |_, this, ()| {
            Ok(this.inner.borrow().get_node_count())
        });

        // ── Edge management ─────────────────────────────────────────

        // -- addEdge --
        /// Adds a directed edge between two nodes and returns its handle.
        /// @param from_ud : Node
        /// @param to_ud : Node
        /// @param edge_type : string?
        /// @return Edge
        methods.add_method(
            "addEdge",
            |_, this, (from_ud, to_ud, edge_type): (LuaAnyUserData, LuaAnyUserData, Option<String>)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let to = to_ud.borrow::<LuaNode>()?;
                let id = this
                    .inner
                    .borrow_mut()
                    .add_edge(from.id, to.id, edge_type.as_deref())
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaEdge {
                    graph: this.inner.clone(),
                    id,
                })
            },
        );

        // -- removeEdge --
        /// Removes an edge from the graph.
        /// @param edge_ud : Edge
        /// @return boolean
        methods.add_method("removeEdge", |_, this, edge_ud: LuaAnyUserData| {
            let edge = edge_ud.borrow::<LuaEdge>()?;
            Ok(this.inner.borrow_mut().remove_edge(edge.id))
        });

        // -- hasEdge --
        /// Returns true if the edge exists in the graph.
        /// @param edge_ud : Edge
        /// @return boolean
        methods.add_method("hasEdge", |_, this, edge_ud: LuaAnyUserData| {
            let edge = edge_ud.borrow::<LuaEdge>()?;
            Ok(this.inner.borrow().has_edge(edge.id))
        });

        // -- getEdges --
        /// Returns a table of all Edge handles.
        /// @return table
        methods.add_method("getEdges", |lua, this, ()| {
            let graph = this.inner.borrow();
            let ids = graph.get_edge_ids();
            let table = lua.create_table()?;
            for (i, eid) in ids.iter().enumerate() {
                table.set(
                    i + 1,
                    LuaEdge {
                        graph: this.inner.clone(),
                        id: *eid,
                    },
                )?;
            }
            Ok(table)
        });

        // -- getEdgeCount --
        /// Returns the number of edges in the graph.
        /// @return integer
        methods.add_method("getEdgeCount", |_, this, ()| {
            Ok(this.inner.borrow().get_edge_count())
        });

        // -- getEdgeBetween --
        /// Returns the edge between two nodes, or nil if none exists.
        /// @param from_ud : Node
        /// @param to_ud : Node
        /// @return Edge?
        methods.add_method(
            "getEdgeBetween",
            |_, this, (from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let to = to_ud.borrow::<LuaNode>()?;
                let graph = this.inner.borrow();
                match graph.get_edge_between(from.id, to.id) {
                    Some(eid) => Ok(Some(LuaEdge {
                        graph: this.inner.clone(),
                        id: eid,
                    })),
                    None => Ok(None),
                }
            },
        );

        // ── Item management ─────────────────────────────────────────

        // -- createItem --
        /// Creates a new unplaced item and returns its handle.
        /// @param item_type : string?
        /// @param decay_time : number?
        /// @return GraphItem
        methods.add_method(
            "createItem",
            |_, this, (item_type, decay_time): (Option<String>, Option<f64>)| {
                let t = item_type.as_deref().unwrap_or("default");
                let d = decay_time.unwrap_or(-1.0);
                let id = this.inner.borrow_mut().create_item(t, d);
                Ok(LuaGraphItem {
                    graph: this.inner.clone(),
                    id,
                })
            },
        );

        // -- addItem --
        /// Places an item at a node.
        /// @param item_ud : GraphItem
        /// @param node_ud : Node
        /// @return boolean
        methods.add_method(
            "addItem",
            |_, this, (item_ud, node_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let item = item_ud.borrow::<LuaGraphItem>()?;
                let node = node_ud.borrow::<LuaNode>()?;
                this.inner
                    .borrow_mut()
                    .add_item_to_node(item.id, node.id)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- removeItem --
        /// Removes an item from the graph entirely.
        /// @param item_ud : GraphItem
        /// @return boolean
        methods.add_method("removeItem", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            Ok(this.inner.borrow_mut().remove_item(item.id))
        });

        // -- hasItem --
        /// Returns true if the item exists in the graph.
        /// @param item_ud : GraphItem
        /// @return boolean
        methods.add_method("hasItem", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            Ok(this.inner.borrow().has_item(item.id))
        });

        // -- getItems --
        /// Returns a table of all GraphItem handles.
        /// @return table
        methods.add_method("getItems", |lua, this, ()| {
            let graph = this.inner.borrow();
            let ids = graph.get_item_ids();
            let table = lua.create_table()?;
            for (i, iid) in ids.iter().enumerate() {
                table.set(
                    i + 1,
                    LuaGraphItem {
                        graph: this.inner.clone(),
                        id: *iid,
                    },
                )?;
            }
            Ok(table)
        });

        // -- getItemCount --
        /// Returns the number of items in the graph.
        /// @return integer
        methods.add_method("getItemCount", |_, this, ()| {
            Ok(this.inner.borrow().get_item_count())
        });

        // -- sendItem --
        /// Sends an item onto an edge to begin transit.
        /// @param item_ud : GraphItem
        /// @param edge_ud : Edge
        /// @return boolean
        methods.add_method(
            "sendItem",
            |_, this, (item_ud, edge_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let item = item_ud.borrow::<LuaGraphItem>()?;
                let edge = edge_ud.borrow::<LuaEdge>()?;
                this.inner
                    .borrow_mut()
                    .send_item(item.id, edge.id)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // ── Simulation ──────────────────────────────────────────────

        // -- update --
        /// Advances simulation by dt seconds and fires event callbacks.
        /// @param dt : number
        /// @return nil
        methods.add_method("update", |lua, this, dt: f64| {
            let events = this.inner.borrow_mut().update(dt);
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });

        // -- step --
        /// Runs one discrete simulation step and fires event callbacks.
        /// @return nil
        methods.add_method("step", |lua, this, ()| {
            let events = this.inner.borrow_mut().step();
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });

        // ── Pathfinding ─────────────────────────────────────────────

        // -- findPath --
        /// Finds the shortest path between two nodes using Dijkstra.
        /// Returns a table with nodes, edges, cost fields, or nil if unreachable.
        /// @param from_ud : Node
        /// @param to_ud : Node
        /// @return table?
        methods.add_method(
            "findPath",
            |lua, this, (from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let to = to_ud.borrow::<LuaNode>()?;
                let graph = this.inner.borrow();
                match graph.find_path(from.id, to.id) {
                    Some(result) => Ok(Some(path_result_to_lua(lua, &this.inner, &result)?)),
                    None => Ok(None),
                }
            },
        );

        // -- findPathForItem --
        /// Finds the shortest path for a specific item, filtering by item type.
        /// Returns a table with nodes, edges, cost fields, or nil if unreachable.
        /// @param item_ud : GraphItem
        /// @param from_ud : Node
        /// @param to_ud : Node
        /// @return table?
        methods.add_method(
            "findPathForItem",
            |lua, this, (item_ud, from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData, LuaAnyUserData)| {
                let item = item_ud.borrow::<LuaGraphItem>()?;
                let from = from_ud.borrow::<LuaNode>()?;
                let to = to_ud.borrow::<LuaNode>()?;
                let graph = this.inner.borrow();
                match graph.find_path_for_item(item.id, from.id, to.id) {
                    Some(result) => Ok(Some(path_result_to_lua(lua, &this.inner, &result)?)),
                    None => Ok(None),
                }
            },
        );

        // -- getDistance --
        /// Returns the shortest path distance, or nil if unreachable.
        /// @param from_ud : Node
        /// @param to_ud : Node
        /// @return number?
        methods.add_method(
            "getDistance",
            |_, this, (from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let to = to_ud.borrow::<LuaNode>()?;
                Ok(this.inner.borrow().get_distance(from.id, to.id))
            },
        );

        // -- getReachable --
        /// Returns a table of Node handles reachable from the given node.
        /// @param from_ud : Node
        /// @param max_dist : number?
        /// @return table
        methods.add_method(
            "getReachable",
            |lua, this, (from_ud, max_dist): (LuaAnyUserData, Option<f64>)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let ids = this.inner.borrow().get_reachable(from.id, max_dist);
                let table = lua.create_table()?;
                for (i, nid) in ids.iter().enumerate() {
                    table.set(
                        i + 1,
                        LuaNode {
                            graph: this.inner.clone(),
                            id: *nid,
                        },
                    )?;
                }
                Ok(table)
            },
        );

        // -- getNeighbors --
        /// Returns a table of direct neighbor Node handles.
        /// @param node_ud : Node
        /// @return table
        methods.add_method("getNeighbors", |lua, this, node_ud: LuaAnyUserData| {
            let node = node_ud.borrow::<LuaNode>()?;
            let ids = this.inner.borrow().get_neighbors(node.id);
            let table = lua.create_table()?;
            for (i, nid) in ids.iter().enumerate() {
                table.set(
                    i + 1,
                    LuaNode {
                        graph: this.inner.clone(),
                        id: *nid,
                    },
                )?;
            }
            Ok(table)
        });

        // ── Algorithms ──────────────────────────────────────────────

        // -- getComponents --
        /// Returns weakly connected components as a table of tables of Node handles.
        /// @return table
        methods.add_method("getComponents", |lua, this, ()| {
            let graph = this.inner.borrow();
            let components = graph.get_components();
            let outer = lua.create_table()?;
            for (i, comp) in components.iter().enumerate() {
                let inner_table = lua.create_table()?;
                for (j, nid) in comp.iter().enumerate() {
                    inner_table.set(
                        j + 1,
                        LuaNode {
                            graph: this.inner.clone(),
                            id: *nid,
                        },
                    )?;
                }
                outer.set(i + 1, inner_table)?;
            }
            Ok(outer)
        });

        // -- hasCycle --
        /// Returns true if the graph contains a directed cycle.
        /// @return boolean
        methods.add_method("hasCycle", |_, this, ()| {
            Ok(this.inner.borrow().has_cycle())
        });

        // -- topologicalSort --
        /// Returns a topologically sorted table of Node handles, or nil if a cycle exists.
        /// @return table?
        methods.add_method("topologicalSort", |lua, this, ()| {
            let graph = this.inner.borrow();
            match graph.topological_sort() {
                Some(sorted) => {
                    let table = lua.create_table()?;
                    for (i, nid) in sorted.iter().enumerate() {
                        table.set(
                            i + 1,
                            LuaNode {
                                graph: this.inner.clone(),
                                id: *nid,
                            },
                        )?;
                    }
                    Ok(Some(table))
                }
                None => Ok(None),
            }
        });

        // ── Supply / Demand ─────────────────────────────────────────

        // -- processDemand --
        /// Processes all supply/demand declarations and fires event callbacks.
        /// @return nil
        methods.add_method("processDemand", |lua, this, ()| {
            let events = this.inner.borrow_mut().process_demand();
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });

        // ── Stats ───────────────────────────────────────────────────

        // -- getStats --
        /// Returns a statistics snapshot table.
        /// @return table
        methods.add_method("getStats", |lua, this, ()| {
            let stats = this.inner.borrow().get_stats();
            let table = lua.create_table()?;
            table.set("nodes", stats.nodes)?;
            table.set("edges", stats.edges)?;
            table.set("items", stats.items)?;
            table.set("activeNodes", stats.active_nodes)?;
            table.set("activeEdges", stats.active_edges)?;
            table.set("itemsInTransit", stats.items_in_transit)?;
            table.set("itemsOnNodes", stats.items_on_nodes)?;
            table.set("totalDemand", stats.total_demand)?;
            table.set("totalSupply", stats.total_supply)?;
            table.set("queuedItems", stats.queued_items)?;
            Ok(table)
        });

        // ── Callbacks ───────────────────────────────────────────────

        // -- on --
        /// Registers a callback for a graph simulation event.
        /// @param event_name : string
        /// @param func : function
        methods.add_method(
            "on",
            |lua, this, (event_name, func): (String, LuaFunction)| {
                if !VALID_EVENTS.contains(&event_name.as_str()) {
                    return Err(LuaError::RuntimeError(format!(
                        "unknown graph event: '{}'. Valid events: {}",
                        event_name,
                        VALID_EVENTS.join(", ")
                    )));
                }
                let key = lua.create_registry_value(func)?;
                this.callbacks.borrow_mut().insert(event_name, key);
                Ok(())
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Graph"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Graph" || name == "Object")
        });
    }
}

// ── Event Dispatch ──────────────────────────────────────────────────────

/// Dispatches a batch of simulation events to registered Lua callbacks.
fn dispatch_events(
    lua: &Lua,
    graph_rc: &Rc<RefCell<Graph>>,
    callbacks: &HashMap<String, LuaRegistryKey>,
    events: Vec<GraphEvent>,
) -> LuaResult<()> {
    for event in events {
        let (name, args): (&str, Vec<LuaValue>) = match event {
            GraphEvent::ItemEnter { item_id, node_id } => (
                "itemEnter",
                vec![
                    LuaValue::UserData(lua.create_userdata(LuaGraphItem {
                        graph: graph_rc.clone(),
                        id: item_id,
                    })?),
                    LuaValue::UserData(lua.create_userdata(LuaNode {
                        graph: graph_rc.clone(),
                        id: node_id,
                    })?),
                ],
            ),
            GraphEvent::ItemLeave { item_id, node_id } => (
                "itemLeave",
                vec![
                    LuaValue::UserData(lua.create_userdata(LuaGraphItem {
                        graph: graph_rc.clone(),
                        id: item_id,
                    })?),
                    LuaValue::UserData(lua.create_userdata(LuaNode {
                        graph: graph_rc.clone(),
                        id: node_id,
                    })?),
                ],
            ),
            GraphEvent::ItemDecay { item_id } => (
                "itemDecay",
                vec![LuaValue::UserData(lua.create_userdata(LuaGraphItem {
                    graph: graph_rc.clone(),
                    id: item_id,
                })?)],
            ),
            GraphEvent::ItemConvert {
                node_id,
                consumed,
                produced,
            } => {
                let mut args: Vec<LuaValue> =
                    vec![LuaValue::UserData(lua.create_userdata(LuaNode {
                        graph: graph_rc.clone(),
                        id: node_id,
                    })?)];
                let consumed_table = lua.create_table()?;
                for (i, cid) in consumed.iter().enumerate() {
                    consumed_table.set(
                        i + 1,
                        LuaGraphItem {
                            graph: graph_rc.clone(),
                            id: *cid,
                        },
                    )?;
                }
                args.push(LuaValue::Table(consumed_table));
                let produced_table = lua.create_table()?;
                for (i, pid) in produced.iter().enumerate() {
                    produced_table.set(
                        i + 1,
                        LuaGraphItem {
                            graph: graph_rc.clone(),
                            id: *pid,
                        },
                    )?;
                }
                args.push(LuaValue::Table(produced_table));
                ("itemConvert", args)
            }
            GraphEvent::ItemLost { item_id, node_id } => (
                "itemLost",
                vec![
                    LuaValue::UserData(lua.create_userdata(LuaGraphItem {
                        graph: graph_rc.clone(),
                        id: item_id,
                    })?),
                    LuaValue::UserData(lua.create_userdata(LuaNode {
                        graph: graph_rc.clone(),
                        id: node_id,
                    })?),
                ],
            ),
            GraphEvent::EdgeEnter { item_id, edge_id } => (
                "edgeEnter",
                vec![
                    LuaValue::UserData(lua.create_userdata(LuaGraphItem {
                        graph: graph_rc.clone(),
                        id: item_id,
                    })?),
                    LuaValue::UserData(lua.create_userdata(LuaEdge {
                        graph: graph_rc.clone(),
                        id: edge_id,
                    })?),
                ],
            ),
            GraphEvent::EdgeLeave { item_id, edge_id } => (
                "edgeLeave",
                vec![
                    LuaValue::UserData(lua.create_userdata(LuaGraphItem {
                        graph: graph_rc.clone(),
                        id: item_id,
                    })?),
                    LuaValue::UserData(lua.create_userdata(LuaEdge {
                        graph: graph_rc.clone(),
                        id: edge_id,
                    })?),
                ],
            ),
            GraphEvent::DemandFulfilled {
                demand_node,
                supply_node,
                item_type,
                count,
            } => (
                "demandFulfilled",
                vec![
                    LuaValue::UserData(lua.create_userdata(LuaNode {
                        graph: graph_rc.clone(),
                        id: demand_node,
                    })?),
                    LuaValue::UserData(lua.create_userdata(LuaNode {
                        graph: graph_rc.clone(),
                        id: supply_node,
                    })?),
                    LuaValue::String(lua.create_string(&item_type)?),
                    LuaValue::Integer(count as i64),
                ],
            ),
            GraphEvent::SupplyDepleted { node_id, item_type } => (
                "supplyDepleted",
                vec![
                    LuaValue::UserData(lua.create_userdata(LuaNode {
                        graph: graph_rc.clone(),
                        id: node_id,
                    })?),
                    LuaValue::String(lua.create_string(&item_type)?),
                ],
            ),
            GraphEvent::ItemQueued { item_id, node_id } => (
                "itemQueued",
                vec![
                    LuaValue::UserData(lua.create_userdata(LuaGraphItem {
                        graph: graph_rc.clone(),
                        id: item_id,
                    })?),
                    LuaValue::UserData(lua.create_userdata(LuaNode {
                        graph: graph_rc.clone(),
                        id: node_id,
                    })?),
                ],
            ),
            GraphEvent::ItemDequeued { item_id, node_id } => (
                "itemDequeued",
                vec![
                    LuaValue::UserData(lua.create_userdata(LuaGraphItem {
                        graph: graph_rc.clone(),
                        id: item_id,
                    })?),
                    LuaValue::UserData(lua.create_userdata(LuaNode {
                        graph: graph_rc.clone(),
                        id: node_id,
                    })?),
                ],
            ),
        };

        if let Some(key) = callbacks.get(name) {
            let func: LuaFunction = lua.registry_value(key)?;
            func.call::<_, ()>(LuaMultiValue::from_vec(args))?;
        }
    }
    Ok(())
}

// ── Registration ────────────────────────────────────────────────────────

/// Registers the `lurek.graph` API namespace.
///
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── newGraph ─────────────────────────────────────────────
    /// Creates a new empty directed graph for item flow simulation.
    /// @return Graph
    tbl.set(
        "newGraph",
        lua.create_function(|_, ()| {
            Ok(LuaGraph {
                inner: Rc::new(RefCell::new(Graph::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;

    luna.set("graph", tbl)?;
    Ok(())
}
