//! Registers the `luna.graph.*` directed-graph and item-flow simulation API.
//!
//! Exposes `LuaGraph`, `LuaNode`, `LuaEdge`, and `LuaGraphItem` UserData types
//! wrapping `crate::graph::Graph` with callback dispatch for simulation events.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::str::FromStr;

use mlua::prelude::*;

use crate::graph::{ConversionRule, FlowMode, Graph, GraphEvent, ItemPosition, OverflowPolicy};
use crate::lua_api::lua_types::{add_type_methods, LunaType};

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

// ---------------------------------------------------------------------------
// Wrapper types
// ---------------------------------------------------------------------------

/// Lua wrapper around a `Graph`. Holds a shared reference and a callback registry.
#[derive(Clone)]
struct LuaGraph {
    /// Shared graph instance.
    inner: Rc<RefCell<Graph>>,
    /// Registered event callbacks keyed by event name.
    callbacks: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}

/// Lua handle for a node inside a `Graph`.
#[derive(Clone)]
struct LuaNode {
    /// Shared graph that owns this node.
    graph: Rc<RefCell<Graph>>,
    /// The node's unique ID.
    id: u64,
}

/// Lua handle for an edge inside a `Graph`.
#[derive(Clone)]
struct LuaEdge {
    /// Shared graph that owns this edge.
    graph: Rc<RefCell<Graph>>,
    /// The edge's unique ID.
    id: u64,
}

/// Lua handle for an item inside a `Graph`.
#[derive(Clone)]
struct LuaGraphItem {
    /// Shared graph that owns this item.
    graph: Rc<RefCell<Graph>>,
    /// The item's unique ID.
    id: u64,
}

// ---------------------------------------------------------------------------
// LunaType impls
// ---------------------------------------------------------------------------

impl LunaType for LuaGraph {
    const TYPE_NAME: &'static str = "Graph";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Graph", "Object"];
}

impl LunaType for LuaNode {
    const TYPE_NAME: &'static str = "GraphNode";
    const TYPE_HIERARCHY: &'static [&'static str] = &["GraphNode", "Object"];
}

impl LunaType for LuaEdge {
    const TYPE_NAME: &'static str = "GraphEdge";
    const TYPE_HIERARCHY: &'static [&'static str] = &["GraphEdge", "Object"];
}

impl LunaType for LuaGraphItem {
    const TYPE_NAME: &'static str = "GraphItem";
    const TYPE_HIERARCHY: &'static [&'static str] = &["GraphItem", "Object"];
}

// ---------------------------------------------------------------------------
// Event dispatch helper
// ---------------------------------------------------------------------------

/// Dispatch a batch of `GraphEvent`s to registered Lua callbacks.
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

// ---------------------------------------------------------------------------
// LuaGraph UserData
// ---------------------------------------------------------------------------

impl LuaUserData for LuaGraph {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // ---- Node management ----

        // Add a node to the graph. Returns a LuaNode handle.
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

        // Remove a node from the graph.
        methods.add_method("removeNode", |_, this, node_ud: LuaAnyUserData| {
            let node = node_ud.borrow::<LuaNode>()?;
            Ok(this.inner.borrow_mut().remove_node(node.id))
        });

        // Check whether a node exists in the graph.
        methods.add_method("hasNode", |_, this, node_ud: LuaAnyUserData| {
            let node = node_ud.borrow::<LuaNode>()?;
            Ok(this.inner.borrow().has_node(node.id))
        });

        // Get all nodes as a table of LuaNode.
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

        // Get the number of nodes.
        methods.add_method("getNodeCount", |_, this, ()| {
            Ok(this.inner.borrow().get_node_count())
        });

        // ---- Edge management ----

        // Add a directed edge between two nodes.
        methods.add_method("addEdge", |_, this, (from_ud, to_ud, edge_type): (LuaAnyUserData, LuaAnyUserData, Option<String>)| {
            let from = from_ud.borrow::<LuaNode>()?;
            let to = to_ud.borrow::<LuaNode>()?;
            let id = this.inner.borrow_mut()
                .add_edge(from.id, to.id, edge_type.as_deref())
                .map_err(LuaError::RuntimeError)?;
            Ok(LuaEdge { graph: this.inner.clone(), id })
        });

        // Remove an edge from the graph.
        methods.add_method("removeEdge", |_, this, edge_ud: LuaAnyUserData| {
            let edge = edge_ud.borrow::<LuaEdge>()?;
            Ok(this.inner.borrow_mut().remove_edge(edge.id))
        });

        // Check whether an edge exists.
        methods.add_method("hasEdge", |_, this, edge_ud: LuaAnyUserData| {
            let edge = edge_ud.borrow::<LuaEdge>()?;
            Ok(this.inner.borrow().has_edge(edge.id))
        });

        // Get all edges as a table of LuaEdge.
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

        // Get the number of edges.
        methods.add_method("getEdgeCount", |_, this, ()| {
            Ok(this.inner.borrow().get_edge_count())
        });

        // Find an edge between two nodes.
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

        // ---- Item management ----

        // Create a new item inside the graph (starts Unplaced).
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

        // Place an existing item at a node.
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

        // Remove an item from the graph entirely.
        methods.add_method("removeItem", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            Ok(this.inner.borrow_mut().remove_item(item.id))
        });

        // Check whether an item exists.
        methods.add_method("hasItem", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            Ok(this.inner.borrow().has_item(item.id))
        });

        // Get all items as a table of LuaGraphItem.
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

        // Get the number of items.
        methods.add_method("getItemCount", |_, this, ()| {
            Ok(this.inner.borrow().get_item_count())
        });

        // Send an item onto an edge (start transit).
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

        // ---- Simulation ----

        // Advance simulation by dt seconds, dispatching event callbacks.
        methods.add_method("update", |lua, this, dt: f64| {
            let events = this.inner.borrow_mut().update(dt);
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });

        // Run one discrete simulation step, dispatching event callbacks.
        methods.add_method("step", |lua, this, ()| {
            let events = this.inner.borrow_mut().step();
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });

        // ---- Pathfinding ----

        // Find shortest path between two nodes.
        methods.add_method(
            "findPath",
            |lua, this, (from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let to = to_ud.borrow::<LuaNode>()?;
                let graph = this.inner.borrow();
                match graph.find_path(from.id, to.id) {
                    Some(result) => {
                        let table = lua.create_table()?;
                        let nodes_table = lua.create_table()?;
                        for (i, nid) in result.nodes.iter().enumerate() {
                            nodes_table.set(
                                i + 1,
                                LuaNode {
                                    graph: this.inner.clone(),
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
                                    graph: this.inner.clone(),
                                    id: *eid,
                                },
                            )?;
                        }
                        table.set("edges", edges_table)?;
                        table.set("cost", result.cost)?;
                        Ok(Some(table))
                    }
                    None => Ok(None),
                }
            },
        );

        // Find a path for a specific item (filters by item type).
        methods.add_method("findPathForItem", |lua, this, (item_ud, from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData, LuaAnyUserData)| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            let from = from_ud.borrow::<LuaNode>()?;
            let to = to_ud.borrow::<LuaNode>()?;
            let graph = this.inner.borrow();
            match graph.find_path_for_item(item.id, from.id, to.id) {
                Some(result) => {
                    let table = lua.create_table()?;
                    let nodes_table = lua.create_table()?;
                    for (i, nid) in result.nodes.iter().enumerate() {
                        nodes_table.set(i + 1, LuaNode { graph: this.inner.clone(), id: *nid })?;
                    }
                    table.set("nodes", nodes_table)?;
                    let edges_table = lua.create_table()?;
                    for (i, eid) in result.edges.iter().enumerate() {
                        edges_table.set(i + 1, LuaEdge { graph: this.inner.clone(), id: *eid })?;
                    }
                    table.set("edges", edges_table)?;
                    table.set("cost", result.cost)?;
                    Ok(Some(table))
                }
                None => Ok(None),
            }
        });

        // Get the shortest-path distance between two nodes.
        methods.add_method(
            "getDistance",
            |_, this, (from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let to = to_ud.borrow::<LuaNode>()?;
                let graph = this.inner.borrow();
                Ok(graph.get_distance(from.id, to.id))
            },
        );

        // Get all nodes reachable from a source, optionally limited by distance.
        methods.add_method(
            "getReachable",
            |lua, this, (from_ud, max_dist): (LuaAnyUserData, Option<f64>)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let graph = this.inner.borrow();
                let ids = graph.get_reachable(from.id, max_dist);
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

        // Get direct neighbors of a node.
        methods.add_method("getNeighbors", |lua, this, node_ud: LuaAnyUserData| {
            let node = node_ud.borrow::<LuaNode>()?;
            let graph = this.inner.borrow();
            let ids = graph.get_neighbors(node.id);
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

        // ---- Algorithms ----

        // Get weakly connected components.
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

        // Check whether the graph has a cycle.
        methods.add_method("hasCycle", |_, this, ()| {
            Ok(this.inner.borrow().has_cycle())
        });

        // Topological sort (returns nil if cycle exists).
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

        // ---- Supply/demand ----

        // Process supply/demand declarations, dispatching event callbacks.
        methods.add_method("processDemand", |lua, this, ()| {
            let events = this.inner.borrow_mut().process_demand();
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });

        // ---- Stats ----

        // Get a statistics snapshot as a table.
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

        // ---- Callbacks ----

        // Register an event callback.
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
    }
}

// ---------------------------------------------------------------------------
// LuaNode UserData
// ---------------------------------------------------------------------------

/// Helper macro: borrow graph immutably, get node by id, return error if not found.
macro_rules! with_node {
    ($this:expr, $graph:ident, $node:ident, $body:expr) => {{
        let $graph = $this.graph.borrow();
        let $node = $graph
            .nodes
            .get(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("node not found".into()))?;
        $body
    }};
}

/// Helper macro: borrow graph mutably, get node by id, return error if not found.
macro_rules! with_node_mut {
    ($this:expr, $graph:ident, $node:ident, $body:expr) => {{
        let mut $graph = $this.graph.borrow_mut();
        let $node = $graph
            .nodes
            .get_mut(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("node not found".into()))?;
        $body
    }};
}

impl LuaUserData for LuaNode {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // ---- Properties ----

        methods.add_method("getType", |_, this, ()| {
            with_node!(this, g, node, Ok(node.get_type().to_string()))
        });
        methods.add_method("setType", |_, this, t: String| {
            with_node_mut!(this, g, node, {
                node.set_type(&t);
                Ok(())
            })
        });

        methods.add_method("getCapacity", |_, this, ()| {
            with_node!(this, g, node, Ok(node.get_capacity()))
        });
        methods.add_method("setCapacity", |_, this, c: i32| {
            with_node_mut!(this, g, node, {
                node.set_capacity(c);
                Ok(())
            })
        });

        methods.add_method("getItemCount", |_, this, ()| {
            with_node!(this, g, node, Ok(node.item_count()))
        });

        methods.add_method("isFull", |_, this, ()| {
            with_node!(this, g, node, Ok(node.is_full()))
        });

        methods.add_method("isActive", |_, this, ()| {
            with_node!(this, g, node, Ok(node.active))
        });
        methods.add_method("setActive", |_, this, a: bool| {
            with_node_mut!(this, g, node, {
                node.active = a;
                Ok(())
            })
        });

        methods.add_method("getOverflowPolicy", |_, this, ()| {
            with_node!(this, g, node, Ok(node.overflow_policy.to_str().to_string()))
        });
        methods.add_method("setOverflowPolicy", |_, this, p: String| {
            let policy = OverflowPolicy::from_str(&p).map_err(LuaError::RuntimeError)?;
            with_node_mut!(this, g, node, {
                node.overflow_policy = policy;
                Ok(())
            })
        });

        methods.add_method("getFlowMode", |_, this, ()| {
            with_node!(this, g, node, Ok(node.flow_mode.to_str().to_string()))
        });
        methods.add_method("setFlowMode", |_, this, m: String| {
            let mode = FlowMode::from_str(&m).map_err(LuaError::RuntimeError)?;
            with_node_mut!(this, g, node, {
                node.flow_mode = mode;
                Ok(())
            })
        });

        methods.add_method("getPushRate", |_, this, ()| {
            with_node!(this, g, node, Ok(node.push_rate))
        });
        methods.add_method("setPushRate", |_, this, r: f64| {
            with_node_mut!(this, g, node, {
                node.push_rate = r;
                Ok(())
            })
        });

        methods.add_method("getPullRate", |_, this, ()| {
            with_node!(this, g, node, Ok(node.pull_rate))
        });
        methods.add_method("setPullRate", |_, this, r: f64| {
            with_node_mut!(this, g, node, {
                node.pull_rate = r;
                Ok(())
            })
        });

        methods.add_method("getPushFilter", |_, this, ()| {
            with_node!(this, g, node, Ok(node.push_filter.clone()))
        });
        methods.add_method("setPushFilter", |_, this, f: Option<String>| {
            with_node_mut!(this, g, node, {
                node.push_filter = f;
                Ok(())
            })
        });

        methods.add_method("getPullFilter", |_, this, ()| {
            with_node!(this, g, node, Ok(node.pull_filter.clone()))
        });
        methods.add_method("setPullFilter", |_, this, f: Option<String>| {
            with_node_mut!(this, g, node, {
                node.pull_filter = f;
                Ok(())
            })
        });

        methods.add_method("getProcessTime", |_, this, ()| {
            with_node!(this, g, node, Ok(node.process_time))
        });
        methods.add_method("setProcessTime", |_, this, t: f64| {
            with_node_mut!(this, g, node, {
                node.process_time = t;
                Ok(())
            })
        });

        methods.add_method("isQueueEnabled", |_, this, ()| {
            with_node!(this, g, node, Ok(node.queue_enabled))
        });
        methods.add_method("setQueueEnabled", |_, this, e: bool| {
            with_node_mut!(this, g, node, {
                node.queue_enabled = e;
                Ok(())
            })
        });

        methods.add_method("getQueueCapacity", |_, this, ()| {
            with_node!(this, g, node, Ok(node.queue_capacity))
        });
        methods.add_method("setQueueCapacity", |_, this, c: i32| {
            with_node_mut!(this, g, node, {
                node.queue_capacity = c;
                Ok(())
            })
        });

        methods.add_method("getQueueSize", |_, this, ()| {
            with_node!(this, g, node, Ok(node.queue.len()))
        });

        // ---- Items & Edges ----

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

        methods.add_method("getEdges", |lua, this, dir: Option<String>| {
            let graph = this.graph.borrow();
            if !graph.nodes.contains_key(&this.id) {
                return Err(LuaError::RuntimeError("node not found".into()));
            }
            let direction = dir.as_deref().unwrap_or("both");
            let mut ids = Vec::new();
            match direction {
                "in" => ids = graph.get_incoming_edges(this.id),
                "out" => ids = graph.get_outgoing_edges(this.id),
                "both" => {
                    ids.extend(graph.get_outgoing_edges(this.id));
                    ids.extend(graph.get_incoming_edges(this.id));
                    ids.sort();
                    ids.dedup();
                }
                _ => {
                    return Err(LuaError::RuntimeError(format!(
                        "invalid direction: '{}'. Use 'in', 'out', or 'both'",
                        direction
                    )))
                }
            }
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

        methods.add_method("clearConversion", |_, this, in_type: String| {
            with_node_mut!(this, g, node, Ok(node.clear_conversion(&in_type)))
        });

        methods.add_method("clearAllConversions", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_all_conversions();
                Ok(())
            })
        });

        // ---- Tags ----

        methods.add_method("addTag", |_, this, tag: String| {
            with_node_mut!(this, g, node, {
                node.add_tag(&tag);
                Ok(())
            })
        });
        methods.add_method("removeTag", |_, this, tag: String| {
            with_node_mut!(this, g, node, Ok(node.remove_tag(&tag)))
        });
        methods.add_method("hasTag", |_, this, tag: String| {
            with_node!(this, g, node, Ok(node.has_tag(&tag)))
        });
        methods.add_method("clearTags", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_tags();
                Ok(())
            })
        });
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

        // ---- Supply/Demand ----

        methods.add_method(
            "addSupply",
            |_, this, (item_type, quantity): (String, i32)| {
                with_node_mut!(this, g, node, {
                    node.add_supply(&item_type, quantity);
                    Ok(())
                })
            },
        );
        methods.add_method("removeSupply", |_, this, item_type: String| {
            with_node_mut!(this, g, node, Ok(node.remove_supply(&item_type)))
        });
        methods.add_method("clearSupplies", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_supplies();
                Ok(())
            })
        });

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
        methods.add_method("removeDemand", |_, this, item_type: String| {
            with_node_mut!(this, g, node, Ok(node.remove_demand(&item_type)))
        });
        methods.add_method("clearDemands", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_demands();
                Ok(())
            })
        });

        // ---- Queue ----

        methods.add_method("enqueue", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            with_node_mut!(this, g, node, Ok(node.enqueue(item.id)))
        });

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
    }
}

// ---------------------------------------------------------------------------
// LuaEdge UserData
// ---------------------------------------------------------------------------

/// Helper macro: borrow graph immutably, get edge by id.
macro_rules! with_edge {
    ($this:expr, $graph:ident, $edge:ident, $body:expr) => {{
        let $graph = $this.graph.borrow();
        let $edge = $graph
            .edges
            .get(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("edge not found".into()))?;
        $body
    }};
}

/// Helper macro: borrow graph mutably, get edge by id.
macro_rules! with_edge_mut {
    ($this:expr, $graph:ident, $edge:ident, $body:expr) => {{
        let mut $graph = $this.graph.borrow_mut();
        let $edge = $graph
            .edges
            .get_mut(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("edge not found".into()))?;
        $body
    }};
}

impl LuaUserData for LuaEdge {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // ---- Properties ----

        methods.add_method("getType", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.get_type().to_string()))
        });
        methods.add_method("setType", |_, this, t: String| {
            with_edge_mut!(this, g, edge, {
                edge.set_type(&t);
                Ok(())
            })
        });

        methods.add_method("getFrom", |_, this, ()| {
            with_edge!(
                this,
                g,
                edge,
                Ok(LuaNode {
                    graph: this.graph.clone(),
                    id: edge.from_node
                })
            )
        });
        methods.add_method("getTo", |_, this, ()| {
            with_edge!(
                this,
                g,
                edge,
                Ok(LuaNode {
                    graph: this.graph.clone(),
                    id: edge.to_node
                })
            )
        });

        methods.add_method("getCapacity", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.capacity))
        });
        methods.add_method("setCapacity", |_, this, c: i32| {
            with_edge_mut!(this, g, edge, {
                edge.capacity = c;
                Ok(())
            })
        });

        methods.add_method("getThroughput", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.throughput))
        });
        methods.add_method("setThroughput", |_, this, t: f64| {
            with_edge_mut!(this, g, edge, {
                edge.throughput = t;
                Ok(())
            })
        });

        methods.add_method("getTravelTime", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.travel_time))
        });
        methods.add_method("setTravelTime", |_, this, t: f64| {
            with_edge_mut!(this, g, edge, {
                edge.travel_time = t;
                Ok(())
            })
        });

        methods.add_method("getWeight", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.weight))
        });
        methods.add_method("setWeight", |_, this, w: f64| {
            with_edge_mut!(this, g, edge, {
                edge.weight = w;
                Ok(())
            })
        });

        methods.add_method("getSpeedModifier", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.speed_modifier))
        });
        methods.add_method("setSpeedModifier", |_, this, m: f64| {
            with_edge_mut!(this, g, edge, {
                edge.speed_modifier = m;
                Ok(())
            })
        });

        methods.add_method("getCooldown", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.cooldown))
        });
        methods.add_method("setCooldown", |_, this, c: f64| {
            with_edge_mut!(this, g, edge, {
                edge.cooldown = c;
                Ok(())
            })
        });

        methods.add_method("isOnCooldown", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.is_on_cooldown()))
        });

        methods.add_method("isBidirectional", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.bidirectional))
        });
        methods.add_method("setBidirectional", |_, this, b: bool| {
            with_edge_mut!(this, g, edge, {
                edge.bidirectional = b;
                Ok(())
            })
        });

        methods.add_method("isActive", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.active))
        });
        methods.add_method("setActive", |_, this, a: bool| {
            with_edge_mut!(this, g, edge, {
                edge.active = a;
                Ok(())
            })
        });

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

        // ---- Type filtering ----

        methods.add_method("addAllowedType", |_, this, t: String| {
            with_edge_mut!(this, g, edge, {
                edge.add_allowed_type(&t);
                Ok(())
            })
        });
        methods.add_method("removeAllowedType", |_, this, t: String| {
            with_edge_mut!(this, g, edge, Ok(edge.remove_allowed_type(&t)))
        });
        methods.add_method("clearAllowedTypes", |_, this, ()| {
            with_edge_mut!(this, g, edge, {
                edge.clear_allowed_types();
                Ok(())
            })
        });
        methods.add_method("isItemTypeAllowed", |_, this, t: String| {
            with_edge!(this, g, edge, Ok(edge.is_item_type_allowed(&t)))
        });
    }
}

// ---------------------------------------------------------------------------
// LuaGraphItem UserData
// ---------------------------------------------------------------------------

/// Helper macro: borrow graph immutably, get item by id.
macro_rules! with_item {
    ($this:expr, $graph:ident, $item:ident, $body:expr) => {{
        let $graph = $this.graph.borrow();
        let $item = $graph
            .items
            .get(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("item not found".into()))?;
        $body
    }};
}

/// Helper macro: borrow graph mutably, get item by id.
macro_rules! with_item_mut {
    ($this:expr, $graph:ident, $item:ident, $body:expr) => {{
        let mut $graph = $this.graph.borrow_mut();
        let $item = $graph
            .items
            .get_mut(&$this.id)
            .ok_or_else(|| LuaError::RuntimeError("item not found".into()))?;
        $body
    }};
}

impl LuaUserData for LuaGraphItem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // ---- Properties ----

        methods.add_method("getType", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_type().to_string()))
        });
        methods.add_method("setType", |_, this, t: String| {
            with_item_mut!(this, g, item, {
                item.set_type(&t);
                Ok(())
            })
        });

        methods.add_method("getDecayTime", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_decay_time()))
        });
        methods.add_method("setDecayTime", |_, this, t: f64| {
            with_item_mut!(this, g, item, {
                item.set_decay_time(t);
                Ok(())
            })
        });

        methods.add_method("getRemainingLife", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_remaining_life()))
        });

        methods.add_method("isAlive", |_, this, ()| {
            with_item!(this, g, item, Ok(item.is_alive()))
        });

        methods.add_method("kill", |_, this, ()| {
            with_item_mut!(this, g, item, {
                item.kill();
                Ok(())
            })
        });

        methods.add_method("getPriority", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_priority()))
        });
        methods.add_method("setPriority", |_, this, p: i32| {
            with_item_mut!(this, g, item, {
                item.set_priority(p);
                Ok(())
            })
        });

        // Multi-value return: AtNode → (LuaNode), InTransit → (LuaEdge, progress), Unplaced → ()
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
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Register the `luna.graph` API table.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let graph_table = lua.create_table()?;

    #[allow(unused_doc_comments)]
    /// Creates a new empty directed graph for item flow simulation.
    ///
    /// luna.graph.newGraph()
    graph_table.set(
        "newGraph",
        lua.create_function(|_, ()| {
            Ok(LuaGraph {
                inner: Rc::new(RefCell::new(Graph::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;

    luna.set("graph", graph_table)?;
    Ok(())
}
