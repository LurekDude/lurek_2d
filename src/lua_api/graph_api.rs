//! `lurek.graph` -- Logistics graph bindings for nodes, directed edges, typed items, capacities, queues, conversion rules, supply and demand, pathfinding, reachability, graph algorithms, events, and Lua callbacks.

use crate::graph::pathfinding::PathResult;
use crate::graph::{ConversionRule, FlowMode, Graph, GraphEvent, ItemPosition, OverflowPolicy};
use crate::runtime::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;
use std::str::FromStr;
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
#[derive(Clone)]
/// Lua-side graph handle storing graph state and registered event callbacks.
struct LuaGraph {
    /// Shared mutable graph state used by node, edge, and item handles.
    inner: Rc<RefCell<Graph>>,
    /// Lua callback registry keys keyed by graph event name.
    callbacks: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}
#[derive(Clone)]
/// Lua-side node handle referencing one node id inside a graph.
struct LuaNode {
    /// Shared graph containing this node.
    graph: Rc<RefCell<Graph>>,
    /// Node identifier inside the graph.
    id: u64,
}
#[derive(Clone)]
/// Lua-side edge handle referencing one edge id inside a graph.
struct LuaEdge {
    /// Shared graph containing this edge.
    graph: Rc<RefCell<Graph>>,
    /// Edge identifier inside the graph.
    id: u64,
}
#[derive(Clone)]
/// Lua-side item handle referencing one item id inside a graph.
struct LuaGraphItem {
    /// Shared graph containing this item.
    graph: Rc<RefCell<Graph>>,
    /// Item identifier inside the graph.
    id: u64,
}
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
/// Converts a graph path result into Lua tables of node and edge handles plus total cost.
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
/// Provides Lua methods for inspecting and editing graph items.
impl LuaUserData for LuaGraphItem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GraphItem({})", this.id))
        });
        // -- getType --
        /// Returns the item type string used by filters, conversions, supplies, and demands.
        /// @return | string | Current item type.
        methods.add_method("getType", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_type().to_string()))
        });
        // -- setType --
        /// Changes the item type string used by graph routing and processing rules.
        /// @param | t | string | New item type.
        /// @return | nil | No value is returned.
        methods.add_method("setType", |_, this, t: String| {
            with_item_mut!(this, g, item, {
                item.set_type(&t);
                Ok(())
            })
        });
        // -- getDecayTime --
        /// Returns the total decay lifetime configured for this item.
        /// @return | number | Decay time in seconds, or the graph's sentinel for no decay.
        methods.add_method("getDecayTime", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_decay_time()))
        });
        // -- setDecayTime --
        /// Sets the total decay lifetime for this item.
        /// @param | t | number | Decay time in seconds, or the graph's sentinel for no decay.
        /// @return | nil | No value is returned.
        methods.add_method("setDecayTime", |_, this, t: f64| {
            with_item_mut!(this, g, item, {
                item.set_decay_time(t);
                Ok(())
            })
        });
        // -- getRemainingLife --
        /// Returns this item's remaining lifetime before decay.
        /// @return | number | Remaining lifetime in seconds.
        methods.add_method("getRemainingLife", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_remaining_life()))
        });
        // -- isAlive --
        /// Returns whether this item is still alive in the graph simulation.
        /// @return | boolean | True when the item has not decayed or been killed.
        methods.add_method("isAlive", |_, this, ()| {
            with_item!(this, g, item, Ok(item.is_alive()))
        });
        // -- kill --
        /// Marks this item as dead so graph processing can remove or ignore it.
        /// @return | nil | No value is returned.
        methods.add_method("kill", |_, this, ()| {
            with_item_mut!(this, g, item, {
                item.kill();
                Ok(())
            })
        });
        // -- getPriority --
        /// Returns this item's routing or queue priority.
        /// @return | integer | Item priority.
        methods.add_method("getPriority", |_, this, ()| {
            with_item!(this, g, item, Ok(item.get_priority()))
        });
        // -- setPriority --
        /// Sets this item's routing or queue priority.
        /// @param | p | integer | New item priority.
        /// @return | nil | No value is returned.
        methods.add_method("setPriority", |_, this, p: i32| {
            with_item_mut!(this, g, item, {
                item.set_priority(p);
                Ok(())
            })
        });
        // -- getPosition --
        /// Returns where this item is stored: a node, an edge plus progress, or no values when unplaced.
        /// @return | LuaValue | `LGraphNode` when at a node, `LGraphEdge` when in transit, or no value when unplaced.
        /// @return | number | Transit progress only when the first return is an edge.
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
        /// Returns the Lua-visible type name for this graph item handle.
        /// @return | string | The string `LGraphItem`.
        methods.add_method("type", |_, _, ()| Ok("LGraphItem"));
        // -- typeOf --
        /// Returns whether this graph item handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LGraphItem`, `GraphItem`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGraphItem" || name == "GraphItem" || name == "Object")
        });
    }
}
/// Provides Lua methods for inspecting and editing graph edges.
impl LuaUserData for LuaEdge {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GraphEdge({})", this.id))
        });
        // -- getType --
        /// Returns the edge type string used by routing and filters.
        /// @return | string | Current edge type.
        methods.add_method("getType", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.get_type().to_string()))
        });
        // -- setType --
        /// Sets the edge type string used by routing and filters.
        /// @param | t | string | New edge type.
        /// @return | nil | No value is returned.
        methods.add_method("setType", |_, this, t: String| {
            with_edge_mut!(this, g, edge, {
                edge.set_type(&t);
                Ok(())
            })
        });
        // -- getFrom --
        /// Returns the source node for this edge.
        /// @return | LGraphNode | Source node handle.
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
        /// Returns the destination node for this edge.
        /// @return | LGraphNode | Destination node handle.
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
        /// Returns this edge's maximum concurrent item capacity.
        /// @return | integer | Edge capacity.
        methods.add_method("getCapacity", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.capacity))
        });
        // -- setCapacity --
        /// Sets this edge's maximum concurrent item capacity.
        /// @param | c | integer | New edge capacity.
        /// @return | nil | No value is returned.
        methods.add_method("setCapacity", |_, this, c: i32| {
            with_edge_mut!(this, g, edge, {
                edge.capacity = c;
                Ok(())
            })
        });
        // -- getThroughput --
        /// Returns this edge's throughput value.
        /// @return | number | Current throughput.
        methods.add_method("getThroughput", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.throughput))
        });
        // -- setThroughput --
        /// Sets this edge's throughput value.
        /// @param | t | number | New throughput.
        /// @return | nil | No value is returned.
        methods.add_method("setThroughput", |_, this, t: f64| {
            with_edge_mut!(this, g, edge, {
                edge.throughput = t;
                Ok(())
            })
        });
        // -- getTravelTime --
        /// Returns the travel time for items moving across this edge.
        /// @return | number | Travel time in seconds.
        methods.add_method("getTravelTime", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.travel_time))
        });
        // -- setTravelTime --
        /// Sets the travel time for items moving across this edge.
        /// @param | t | number | Travel time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("setTravelTime", |_, this, t: f64| {
            with_edge_mut!(this, g, edge, {
                edge.travel_time = t;
                Ok(())
            })
        });
        // -- getWeight --
        /// Returns the pathfinding weight for this edge.
        /// @return | number | Edge weight.
        methods.add_method("getWeight", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.weight))
        });
        // -- setWeight --
        /// Sets the pathfinding weight for this edge.
        /// @param | w | number | Edge weight.
        /// @return | nil | No value is returned.
        methods.add_method("setWeight", |_, this, w: f64| {
            with_edge_mut!(this, g, edge, {
                edge.weight = w;
                Ok(())
            })
        });
        // -- getSpeedModifier --
        /// Returns this edge's speed modifier.
        /// @return | number | Speed modifier.
        methods.add_method("getSpeedModifier", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.speed_modifier))
        });
        // -- setSpeedModifier --
        /// Sets this edge's speed modifier.
        /// @param | m | number | Speed modifier.
        /// @return | nil | No value is returned.
        methods.add_method("setSpeedModifier", |_, this, m: f64| {
            with_edge_mut!(this, g, edge, {
                edge.speed_modifier = m;
                Ok(())
            })
        });
        // -- getCooldown --
        /// Returns this edge's cooldown timer value.
        /// @return | number | Cooldown in seconds.
        methods.add_method("getCooldown", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.cooldown))
        });
        // -- setCooldown --
        /// Sets this edge's cooldown timer value.
        /// @param | c | number | Cooldown in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("setCooldown", |_, this, c: f64| {
            with_edge_mut!(this, g, edge, {
                edge.cooldown = c;
                Ok(())
            })
        });
        // -- isOnCooldown --
        /// Returns whether this edge is currently on cooldown.
        /// @return | boolean | True when cooldown is active.
        methods.add_method("isOnCooldown", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.is_on_cooldown()))
        });
        // -- isBidirectional --
        /// Returns whether this edge allows travel in both directions.
        /// @return | boolean | True when the edge is bidirectional.
        methods.add_method("isBidirectional", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.bidirectional))
        });
        // -- setBidirectional --
        /// Sets whether this edge allows travel in both directions.
        /// @param | b | boolean | New bidirectional flag.
        /// @return | nil | No value is returned.
        methods.add_method("setBidirectional", |_, this, b: bool| {
            with_edge_mut!(this, g, edge, {
                edge.bidirectional = b;
                Ok(())
            })
        });
        // -- isActive --
        /// Returns whether this edge is active for routing and simulation.
        /// @return | boolean | True when the edge is active.
        methods.add_method("isActive", |_, this, ()| {
            with_edge!(this, g, edge, Ok(edge.active))
        });
        // -- setActive --
        /// Enables or disables this edge for routing and simulation.
        /// @param | a | boolean | New active flag.
        /// @return | nil | No value is returned.
        methods.add_method("setActive", |_, this, a: bool| {
            with_edge_mut!(this, g, edge, {
                edge.active = a;
                Ok(())
            })
        });
        // -- getItemsInTransit --
        /// Returns graph items currently traveling along this edge.
        /// @return | table | Array table of `LGraphItem` handles.
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
        /// Allows an item type to traverse this edge.
        /// @param | t | string | Item type to allow.
        /// @return | nil | No value is returned.
        methods.add_method("addAllowedType", |_, this, t: String| {
            with_edge_mut!(this, g, edge, {
                edge.add_allowed_type(&t);
                Ok(())
            })
        });
        // -- removeAllowedType --
        /// Removes an item type from this edge's allow-list.
        /// @param | t | string | Item type to remove.
        /// @return | boolean | True when the type was present.
        methods.add_method("removeAllowedType", |_, this, t: String| {
            with_edge_mut!(this, g, edge, Ok(edge.remove_allowed_type(&t)))
        });
        // -- clearAllowedTypes --
        /// Clears this edge's item type allow-list.
        /// @return | nil | No value is returned.
        methods.add_method("clearAllowedTypes", |_, this, ()| {
            with_edge_mut!(this, g, edge, {
                edge.clear_allowed_types();
                Ok(())
            })
        });
        // -- isItemTypeAllowed --
        /// Returns whether an item type may traverse this edge.
        /// @param | t | string | Item type to check.
        /// @return | boolean | True when the item type is allowed.
        methods.add_method("isItemTypeAllowed", |_, this, t: String| {
            with_edge!(this, g, edge, Ok(edge.is_item_type_allowed(&t)))
        });
        // -- type --
        /// Returns the Lua-visible type name for this graph edge handle.
        /// @return | string | The string `LGraphEdge`.
        methods.add_method("type", |_, _, ()| Ok("LGraphEdge"));
        // -- typeOf --
        /// Returns whether this graph edge handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LGraphEdge`, `GraphEdge`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGraphEdge" || name == "GraphEdge" || name == "Object")
        });
    }
}
/// Provides Lua methods for inspecting and editing graph nodes.
impl LuaUserData for LuaNode {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GraphNode({})", this.id))
        });
        // -- getType --
        /// Returns this node's type string.
        /// @return | string | Current node type.
        methods.add_method("getType", |_, this, ()| {
            with_node!(this, g, node, Ok(node.get_type().to_string()))
        });
        // -- setType --
        /// Sets this node's type string.
        /// @param | t | string | New node type.
        /// @return | nil | No value is returned.
        methods.add_method("setType", |_, this, t: String| {
            with_node_mut!(this, g, node, {
                node.set_type(&t);
                Ok(())
            })
        });
        // -- getCapacity --
        /// Returns this node's item capacity.
        /// @return | integer | Node capacity.
        methods.add_method("getCapacity", |_, this, ()| {
            with_node!(this, g, node, Ok(node.get_capacity()))
        });
        // -- setCapacity --
        /// Sets this node's item capacity.
        /// @param | c | integer | New node capacity.
        /// @return | nil | No value is returned.
        methods.add_method("setCapacity", |_, this, c: i32| {
            with_node_mut!(this, g, node, {
                node.set_capacity(c);
                Ok(())
            })
        });
        // -- getItemCount --
        /// Returns the number of items currently stored on this node.
        /// @return | integer | Item count.
        methods.add_method("getItemCount", |_, this, ()| {
            with_node!(this, g, node, Ok(node.item_count()))
        });
        // -- isFull --
        /// Returns whether this node has reached its item capacity.
        /// @return | boolean | True when the node is full.
        methods.add_method("isFull", |_, this, ()| {
            with_node!(this, g, node, Ok(node.is_full()))
        });
        // -- isActive --
        /// Returns whether this node is active for graph simulation.
        /// @return | boolean | True when the node is active.
        methods.add_method("isActive", |_, this, ()| {
            with_node!(this, g, node, Ok(node.active))
        });
        // -- setActive --
        /// Enables or disables this node for graph simulation.
        /// @param | a | boolean | New active flag.
        /// @return | nil | No value is returned.
        methods.add_method("setActive", |_, this, a: bool| {
            with_node_mut!(this, g, node, {
                node.active = a;
                Ok(())
            })
        });
        // -- getOverflowPolicy --
        /// Returns this node's overflow policy name.
        /// @return | string | Overflow policy string.
        methods.add_method("getOverflowPolicy", |_, this, ()| {
            with_node!(this, g, node, Ok(node.overflow_policy.to_str().to_string()))
        });
        // -- setOverflowPolicy --
        /// Sets this node's overflow policy from a policy name.
        /// @param | p | string | Overflow policy string.
        /// @return | nil | No value is returned.
        methods.add_method("setOverflowPolicy", |_, this, p: String| {
            let policy = OverflowPolicy::from_str(&p).map_err(LuaError::RuntimeError)?;
            with_node_mut!(this, g, node, {
                node.overflow_policy = policy;
                Ok(())
            })
        });
        // -- getFlowMode --
        /// Returns this node's flow mode name.
        /// @return | string | Flow mode string.
        methods.add_method("getFlowMode", |_, this, ()| {
            with_node!(this, g, node, Ok(node.flow_mode.to_str().to_string()))
        });
        // -- setFlowMode --
        /// Sets this node's flow mode from a mode name.
        /// @param | m | string | Flow mode string.
        /// @return | nil | No value is returned.
        methods.add_method("setFlowMode", |_, this, m: String| {
            let mode = FlowMode::from_str(&m).map_err(LuaError::RuntimeError)?;
            with_node_mut!(this, g, node, {
                node.flow_mode = mode;
                Ok(())
            })
        });
        // -- getPushRate --
        /// Returns this node's push rate.
        /// @return | number | Push rate.
        methods.add_method("getPushRate", |_, this, ()| {
            with_node!(this, g, node, Ok(node.push_rate))
        });
        // -- setPushRate --
        /// Sets this node's push rate.
        /// @param | r | number | New push rate.
        /// @return | nil | No value is returned.
        methods.add_method("setPushRate", |_, this, r: f64| {
            with_node_mut!(this, g, node, {
                node.push_rate = r;
                Ok(())
            })
        });
        // -- getPullRate --
        /// Returns this node's pull rate.
        /// @return | number | Pull rate.
        methods.add_method("getPullRate", |_, this, ()| {
            with_node!(this, g, node, Ok(node.pull_rate))
        });
        // -- setPullRate --
        /// Sets this node's pull rate.
        /// @param | r | number | New pull rate.
        /// @return | nil | No value is returned.
        methods.add_method("setPullRate", |_, this, r: f64| {
            with_node_mut!(this, g, node, {
                node.pull_rate = r;
                Ok(())
            })
        });
        // -- getPushFilter --
        /// Returns this node's optional push item-type filter.
        /// @return | LuaValue | Filter string, or nil when no push filter is set.
        methods.add_method("getPushFilter", |_, this, ()| {
            with_node!(this, g, node, Ok(node.push_filter.clone()))
        });
        // -- setPushFilter --
        /// Sets or clears this node's push item-type filter.
        /// @param | f | string | Optional item type filter string.
        /// @return | nil | No value is returned.
        methods.add_method("setPushFilter", |_, this, f: Option<String>| {
            with_node_mut!(this, g, node, {
                node.push_filter = f;
                Ok(())
            })
        });
        // -- getPullFilter --
        /// Returns this node's optional pull item-type filter.
        /// @return | LuaValue | Filter string, or nil when no pull filter is set.
        methods.add_method("getPullFilter", |_, this, ()| {
            with_node!(this, g, node, Ok(node.pull_filter.clone()))
        });
        // -- setPullFilter --
        /// Sets or clears this node's pull item-type filter.
        /// @param | f | string | Optional item type filter string.
        /// @return | nil | No value is returned.
        methods.add_method("setPullFilter", |_, this, f: Option<String>| {
            with_node_mut!(this, g, node, {
                node.pull_filter = f;
                Ok(())
            })
        });
        // -- getProcessTime --
        /// Returns the processing time used by this node's conversions.
        /// @return | number | Processing time in seconds.
        methods.add_method("getProcessTime", |_, this, ()| {
            with_node!(this, g, node, Ok(node.process_time))
        });
        // -- setProcessTime --
        /// Sets the processing time used by this node's conversions.
        /// @param | t | number | Processing time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("setProcessTime", |_, this, t: f64| {
            with_node_mut!(this, g, node, {
                node.process_time = t;
                Ok(())
            })
        });
        // -- isQueueEnabled --
        /// Returns whether this node's explicit queue is enabled.
        /// @return | boolean | True when queueing is enabled.
        methods.add_method("isQueueEnabled", |_, this, ()| {
            with_node!(this, g, node, Ok(node.queue_enabled))
        });
        // -- setQueueEnabled --
        /// Enables or disables this node's explicit queue.
        /// @param | e | boolean | New queue enabled flag.
        /// @return | nil | No value is returned.
        methods.add_method("setQueueEnabled", |_, this, e: bool| {
            with_node_mut!(this, g, node, {
                node.queue_enabled = e;
                Ok(())
            })
        });
        // -- getQueueCapacity --
        /// Returns this node's queue capacity.
        /// @return | integer | Queue capacity.
        methods.add_method("getQueueCapacity", |_, this, ()| {
            with_node!(this, g, node, Ok(node.queue_capacity))
        });
        // -- setQueueCapacity --
        /// Sets this node's queue capacity.
        /// @param | c | integer | Queue capacity.
        /// @return | nil | No value is returned.
        methods.add_method("setQueueCapacity", |_, this, c: i32| {
            with_node_mut!(this, g, node, {
                node.queue_capacity = c;
                Ok(())
            })
        });
        // -- getQueueSize --
        /// Returns the number of item ids currently queued at this node.
        /// @return | integer | Queue size.
        methods.add_method("getQueueSize", |_, this, ()| {
            with_node!(this, g, node, Ok(node.queue.len()))
        });
        // -- getItems --
        /// Returns item handles currently stored on this node.
        /// @return | table | Array table of `LGraphItem` handles.
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
        /// Returns edge handles connected to this node in the requested direction.
        /// @param | dir | string | Optional direction string, defaulting to `both`.
        /// @return | table | Array table of `LGraphEdge` handles.
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
        // -- setConversion --
        /// Configures an item conversion rule on this node.
        /// @param | in_type | string | Input item type.
        /// @param | out_type | string | Output item type.
        /// @param | in_count | integer | Optional input count, defaulting to 1.
        /// @param | out_count | integer | Optional output count, defaulting to 1.
        /// @return | nil | No value is returned.
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
        /// Removes a conversion rule by input item type.
        /// @param | in_type | string | Input item type.
        /// @return | boolean | True when a conversion rule was removed.
        methods.add_method("clearConversion", |_, this, in_type: String| {
            with_node_mut!(this, g, node, Ok(node.clear_conversion(&in_type)))
        });
        // -- clearAllConversions --
        /// Removes every conversion rule from this node.
        /// @return | nil | No value is returned.
        methods.add_method("clearAllConversions", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_all_conversions();
                Ok(())
            })
        });
        // -- addTag --
        /// Adds a tag to this node.
        /// @param | tag | string | Tag to add.
        /// @return | nil | No value is returned.
        methods.add_method("addTag", |_, this, tag: String| {
            with_node_mut!(this, g, node, {
                node.add_tag(&tag);
                Ok(())
            })
        });
        // -- removeTag --
        /// Removes a tag from this node.
        /// @param | tag | string | Tag to remove.
        /// @return | boolean | True when the tag was present.
        methods.add_method("removeTag", |_, this, tag: String| {
            with_node_mut!(this, g, node, Ok(node.remove_tag(&tag)))
        });
        // -- hasTag --
        /// Returns whether this node has a tag.
        /// @param | tag | string | Tag to check.
        /// @return | boolean | True when the tag is present.
        methods.add_method("hasTag", |_, this, tag: String| {
            with_node!(this, g, node, Ok(node.has_tag(&tag)))
        });
        // -- clearTags --
        /// Removes every tag from this node.
        /// @return | nil | No value is returned.
        methods.add_method("clearTags", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_tags();
                Ok(())
            })
        });
        // -- getTags --
        /// Returns all tags assigned to this node.
        /// @return | table | Array table of tag strings.
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
        // -- addSupply --
        /// Adds supply quantity for an item type on this node.
        /// @param | item_type | string | Item type supplied by the node.
        /// @param | quantity | integer | Supply quantity to add.
        /// @return | nil | No value is returned.
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
        /// Removes supply entry for an item type from this node.
        /// @param | item_type | string | Item type supply entry to remove.
        /// @return | boolean | True when supply existed.
        methods.add_method("removeSupply", |_, this, item_type: String| {
            with_node_mut!(this, g, node, Ok(node.remove_supply(&item_type)))
        });
        // -- clearSupplies --
        /// Removes every supply entry from this node.
        /// @return | nil | No value is returned.
        methods.add_method("clearSupplies", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_supplies();
                Ok(())
            })
        });
        // -- addDemand --
        /// Adds demand quantity and optional priority for an item type on this node.
        /// @param | item_type | string | Item type demanded by the node.
        /// @param | quantity | integer | Demand quantity to add.
        /// @param | priority | integer | Optional demand priority, defaulting to 0.
        /// @return | nil | No value is returned.
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
        /// Removes demand entry for an item type from this node.
        /// @param | item_type | string | Item type demand entry to remove.
        /// @return | boolean | True when demand existed.
        methods.add_method("removeDemand", |_, this, item_type: String| {
            with_node_mut!(this, g, node, Ok(node.remove_demand(&item_type)))
        });
        // -- clearDemands --
        /// Removes every demand entry from this node.
        /// @return | nil | No value is returned.
        methods.add_method("clearDemands", |_, this, ()| {
            with_node_mut!(this, g, node, {
                node.clear_demands();
                Ok(())
            })
        });
        // -- enqueue --
        /// Adds an item handle to this node's explicit queue.
        /// @param | item_ud | LGraphItem | Item handle to enqueue.
        /// @return | boolean | True when the item was queued.
        methods.add_method("enqueue", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            with_node_mut!(this, g, node, Ok(node.enqueue(item.id)))
        });
        // -- dequeue --
        /// Removes and returns the next item from this node's explicit queue.
        /// @return | LuaValue | `LGraphItem` handle, or nil when the queue is empty.
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
        /// Returns the Lua-visible type name for this graph node handle.
        /// @return | string | The string `LGraphNode`.
        methods.add_method("type", |_, _, ()| Ok("LGraphNode"));
        // -- typeOf --
        /// Returns whether this graph node handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LGraphNode`, `GraphNode`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGraphNode" || name == "GraphNode" || name == "Object")
        });
    }
}
/// Provides Lua methods for graph mutation, routing, algorithms, simulation, and callbacks.
impl LuaUserData for LuaGraph {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let g = this.inner.borrow();
            Ok(format!(
                "Graph(nodes={}, edges={}, items={})",
                g.get_node_count(),
                g.get_edge_count(),
                g.get_item_count()
            ))
        });
        // -- addNode --
        /// Creates a node with optional type and capacity.
        /// @param | node_type | string | Optional node type, defaulting to `default`.
        /// @param | capacity | integer | Optional capacity, defaulting to -1.
        /// @return | LGraphNode | New node handle.
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
        /// Removes a node and graph links associated with it.
        /// @param | node_ud | LGraphNode | Node handle to remove.
        /// @return | boolean | True when the node was removed.
        methods.add_method("removeNode", |_, this, node_ud: LuaAnyUserData| {
            let node_id = {
                let node = node_ud.borrow::<LuaNode>()?;
                node.id
            };
            if !this.inner.borrow().has_node(node_id) {
                return Err(LuaError::RuntimeError("node not found".into()));
            }
            Ok(this.inner.borrow_mut().remove_node(node_id))
        });
        // -- hasNode --
        /// Returns whether a node handle still exists in this graph.
        /// @param | node_ud | LGraphNode | Node handle to check.
        /// @return | boolean | True when the node exists.
        methods.add_method("hasNode", |_, this, node_ud: LuaAnyUserData| {
            let node = node_ud.borrow::<LuaNode>()?;
            Ok(this.inner.borrow().has_node(node.id))
        });
        // -- getNodes --
        /// Returns all nodes in this graph.
        /// @return | table | Array table of `LGraphNode` handles.
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
        /// Returns the number of nodes in this graph.
        /// @return | integer | Node count.
        methods.add_method("getNodeCount", |_, this, ()| {
            Ok(this.inner.borrow().get_node_count())
        });
        // -- addEdge --
        /// Creates an edge between two nodes with an optional edge type.
        /// @param | from_ud | LGraphNode | Source node handle.
        /// @param | to_ud | LGraphNode | Destination node handle.
        /// @param | edge_type | string | Optional edge type.
        /// @return | LGraphEdge | New edge handle.
        methods.add_method("addEdge", |_, this, (from_ud, to_ud, edge_type): (LuaAnyUserData, LuaAnyUserData, Option<String>)| {
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
        /// Removes an edge by handle.
        /// @param | edge_ud | LGraphEdge | Edge handle to remove.
        /// @return | boolean | True when the edge was removed.
        methods.add_method("removeEdge", |_, this, edge_ud: LuaAnyUserData| {
            let edge = edge_ud.borrow::<LuaEdge>()?;
            Ok(this.inner.borrow_mut().remove_edge(edge.id))
        });
        // -- hasEdge --
        /// Returns whether an edge handle still exists in this graph.
        /// @param | edge_ud | LGraphEdge | Edge handle to check.
        /// @return | boolean | True when the edge exists.
        methods.add_method("hasEdge", |_, this, edge_ud: LuaAnyUserData| {
            let edge = edge_ud.borrow::<LuaEdge>()?;
            Ok(this.inner.borrow().has_edge(edge.id))
        });
        // -- getEdges --
        /// Returns all edges in this graph.
        /// @return | table | Array table of `LGraphEdge` handles.
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
        /// Returns the number of edges in this graph.
        /// @return | integer | Edge count.
        methods.add_method("getEdgeCount", |_, this, ()| {
            Ok(this.inner.borrow().get_edge_count())
        });
        // -- getEdgeBetween --
        /// Returns the edge connecting two nodes when one exists.
        /// @param | from_ud | LGraphNode | Source node handle.
        /// @param | to_ud | LGraphNode | Destination node handle.
        /// @return | LuaValue | `LGraphEdge` handle, or nil when no edge connects the nodes.
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
        // -- createItem --
        /// Creates an unplaced graph item with optional type and decay time.
        /// @param | item_type | string | Optional item type, defaulting to `default`.
        /// @param | decay_time | number | Optional decay lifetime, defaulting to -1.0.
        /// @return | LGraphItem | New graph item handle.
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
        /// Places an item onto a node.
        /// @param | item_ud | LGraphItem | Item handle to place.
        /// @param | node_ud | LGraphNode | Destination node handle.
        /// @return | nil | No value is returned.
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
        /// Removes an item from this graph.
        /// @param | item_ud | LGraphItem | Item handle to remove.
        /// @return | boolean | True when the item was removed.
        methods.add_method("removeItem", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            Ok(this.inner.borrow_mut().remove_item(item.id))
        });
        // -- hasItem --
        /// Returns whether an item handle still exists in this graph.
        /// @param | item_ud | LGraphItem | Item handle to check.
        /// @return | boolean | True when the item exists.
        methods.add_method("hasItem", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            Ok(this.inner.borrow().has_item(item.id))
        });
        // -- getItems --
        /// Returns all items in this graph.
        /// @return | table | Array table of `LGraphItem` handles.
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
        /// Returns the number of items in this graph.
        /// @return | integer | Item count.
        methods.add_method("getItemCount", |_, this, ()| {
            Ok(this.inner.borrow().get_item_count())
        });
        // -- sendItem --
        /// Starts moving an item along an edge.
        /// @param | item_ud | LGraphItem | Item handle to send.
        /// @param | edge_ud | LGraphEdge | Edge handle to traverse.
        /// @return | nil | No value is returned.
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
        // -- update --
        /// Advances graph simulation by delta time and dispatches generated callbacks.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("update", |lua, this, dt: f64| {
            let events = this.inner.borrow_mut().update(dt);
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });
        // -- step --
        /// Runs one discrete graph simulation step and dispatches generated callbacks.
        /// @return | nil | No value is returned.
        methods.add_method("step", |lua, this, ()| {
            let events = this.inner.borrow_mut().step();
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });
        // -- tickParallel --
        /// Advances graph simulation through the parallel update path and dispatches generated callbacks.
        /// @param | dt | number | Delta time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method("tickParallel", |lua, this, dt: f64| {
            let events = this.inner.borrow_mut().update_parallel(dt);
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });
        // -- findPath --
        /// Finds a path between two nodes.
        /// @param | from_ud | LGraphNode | Start node handle.
        /// @param | to_ud | LGraphNode | Target node handle.
        /// @return | LuaValue | Path result table with nodes, edges, and cost, or nil when no path exists.
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
        /// Finds a path for a specific item between two nodes while respecting item constraints.
        /// @param | item_ud | LGraphItem | Item handle used for routing constraints.
        /// @param | from_ud | LGraphNode | Start node handle.
        /// @param | to_ud | LGraphNode | Target node handle.
        /// @return | LuaValue | Path result table with nodes, edges, and cost, or nil when no path exists.
        methods.add_method("findPathForItem", |lua, this, (item_ud, from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData, LuaAnyUserData)| {
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
        /// Returns graph distance between two nodes when reachable.
        /// @param | from_ud | LGraphNode | Start node handle.
        /// @param | to_ud | LGraphNode | Target node handle.
        /// @return | LuaValue | Distance number, or nil when no distance is available.
        methods.add_method(
            "getDistance",
            |_, this, (from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let to = to_ud.borrow::<LuaNode>()?;
                Ok(this.inner.borrow().get_distance(from.id, to.id))
            },
        );
        // -- getReachable --
        /// Returns nodes reachable from a start node within an optional maximum distance.
        /// @param | from_ud | LGraphNode | Start node handle.
        /// @param | max_dist | number | Optional maximum distance.
        /// @return | table | Array table of reachable `LGraphNode` handles.
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
        /// Returns neighbor nodes connected to a node.
        /// @param | node_ud | LGraphNode | Node handle to inspect.
        /// @return | table | Array table of neighboring `LGraphNode` handles.
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
        // -- getComponents --
        /// Returns connected components as arrays of node handles.
        /// @return | table | Array table of component tables containing `LGraphNode` handles.
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
        // -- subgraph --
        /// Creates a new graph containing a subset of nodes.
        /// @param | nodes | table | Array table of `LGraphNode` handles to include.
        /// @return | LGraph | New subgraph handle.
        methods.add_method("subgraph", |_, this, nodes: LuaTable| {
            let mut node_ids = Vec::new();
            for value in nodes.sequence_values::<LuaAnyUserData>() {
                let node_ud = value?;
                let node = node_ud.borrow::<LuaNode>()?;
                node_ids.push(node.id);
            }
            let sub = this.inner.borrow().subgraph(&node_ids);
            Ok(LuaGraph {
                inner: Rc::new(RefCell::new(sub)),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        });
        // -- hasCycle --
        /// Returns whether this graph contains a cycle.
        /// @return | boolean | True when the graph has a cycle.
        methods.add_method("hasCycle", |_, this, ()| {
            Ok(this.inner.borrow().has_cycle())
        });
        // -- topologicalSort --
        /// Returns nodes in topological order when the graph is acyclic.
        /// @return | LuaValue | Array table of `LGraphNode` handles, or nil when sorting is impossible.
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
        // -- mst --
        /// Computes a minimum spanning tree using Kruskal and returns edge ids.
        /// @return | table | Array table of edge ids included in the tree.
        methods.add_method("mst", |lua, this, ()| {
            let edge_ids = this.inner.borrow().mst_kruskal();
            let t = lua.create_table()?;
            for (i, eid) in edge_ids.iter().enumerate() {
                t.set(i + 1, *eid)?;
            }
            Ok(t)
        });
        // -- colorGraph --
        /// Computes graph coloring and returns color indices by node id.
        /// @return | table | Map table from node id to color index.
        methods.add_method("colorGraph", |lua, this, ()| {
            let colors = this.inner.borrow().color_graph();
            let t = lua.create_table()?;
            for (node_id, color) in &colors {
                t.set(*node_id, *color as u64)?;
            }
            Ok(t)
        });
        // -- isBipartite --
        /// Returns whether this graph is bipartite.
        /// @return | boolean | True when the graph is bipartite.
        methods.add_method("isBipartite", |_lua, this, ()| {
            Ok(this.inner.borrow().is_bipartite())
        });
        // -- astar --
        /// Runs A* pathfinding between two nodes.
        /// @param | from_node | LGraphNode | Start node handle.
        /// @param | to_node | LGraphNode | Target node handle.
        /// @return | LuaValue | Array table of `LGraphNode` handles, or nil when no path exists.
        methods.add_method(
            "astar",
            |lua, this, (from_node, to_node): (LuaAnyUserData, LuaAnyUserData)| {
                let from_id = from_node.borrow::<LuaNode>()?.id;
                let to_id = to_node.borrow::<LuaNode>()?.id;
                let positions = HashMap::new();
                match this.inner.borrow().astar_graph(from_id, to_id, &positions) {
                    None => Ok(LuaValue::Nil),
                    Some(path) => {
                        let t = lua.create_table()?;
                        for (i, &nid) in path.iter().enumerate() {
                            t.set(
                                i + 1,
                                lua.create_userdata(LuaNode {
                                    graph: this.inner.clone(),
                                    id: nid,
                                })?,
                            )?;
                        }
                        Ok(LuaValue::Table(t))
                    }
                }
            },
        );
        // -- processDemand --
        /// Processes graph supply and demand once and dispatches generated callbacks.
        /// @return | nil | No value is returned.
        methods.add_method("processDemand", |lua, this, ()| {
            let events = this.inner.borrow_mut().process_demand();
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });
        // -- getStats --
        /// Returns graph counts and aggregate supply-demand statistics.
        /// @return | table | Table with node, edge, item, activity, transit, demand, supply, and queue counts.
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
        // -- on --
        /// Registers a callback for a named graph event generated during simulation.
        /// @param | event_name | string | Event name from the valid graph event list.
        /// @param | func | function | Lua callback invoked with event-specific handles and values.
        /// @return | nil | No value is returned.
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
        /// Returns the Lua-visible type name for this graph handle.
        /// @return | string | The string `LGraph`.
        methods.add_method("type", |_, _, ()| Ok("LGraph"));
        // -- typeOf --
        /// Returns whether this graph handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LGraph`, `Graph`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGraph" || name == "Graph" || name == "Object")
        });
    }
}
/// Dispatches generated graph events to Lua callbacks registered on the graph.
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
/// Registers `lurek.graph` constructors.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newGraph --
    /// Creates an empty logistics graph with no nodes, edges, items, or callbacks.
    /// @return | LGraph | New graph handle.
    tbl.set(
        "newGraph",
        lua.create_function(|_, ()| {
            Ok(LuaGraph {
                inner: Rc::new(RefCell::new(Graph::new())),
                callbacks: Rc::new(RefCell::new(HashMap::new())),
            })
        })?,
    )?;
    lurek.set("graph", tbl)?;
    Ok(())
}
