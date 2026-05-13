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
struct LuaGraph {
    inner: Rc<RefCell<Graph>>,
    callbacks: Rc<RefCell<HashMap<String, LuaRegistryKey>>>,
}
#[derive(Clone)]
struct LuaNode {
    graph: Rc<RefCell<Graph>>,
    id: u64,
}
#[derive(Clone)]
struct LuaEdge {
    graph: Rc<RefCell<Graph>>,
    id: u64,
}
#[derive(Clone)]
struct LuaGraphItem {
    graph: Rc<RefCell<Graph>>,
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
impl LuaUserData for LuaGraphItem {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GraphItem({})", this.id))
        });
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
        methods.add_method("type", |_, _, ()| Ok("LGraphItem"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGraphItem" || name == "GraphItem" || name == "Object")
        });
    }
}
impl LuaUserData for LuaEdge {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GraphEdge({})", this.id))
        });
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
                    id: edge.from_node,
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
                    id: edge.to_node,
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
        methods.add_method("type", |_, _, ()| Ok("LGraphEdge"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGraphEdge" || name == "GraphEdge" || name == "Object")
        });
    }
}
impl LuaUserData for LuaNode {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GraphNode({})", this.id))
        });
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
        methods.add_method("type", |_, _, ()| Ok("LGraphNode"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGraphNode" || name == "GraphNode" || name == "Object")
        });
    }
}
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
        methods.add_method("hasNode", |_, this, node_ud: LuaAnyUserData| {
            let node = node_ud.borrow::<LuaNode>()?;
            Ok(this.inner.borrow().has_node(node.id))
        });
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
        methods.add_method("getNodeCount", |_, this, ()| {
            Ok(this.inner.borrow().get_node_count())
        });
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
        methods.add_method("removeEdge", |_, this, edge_ud: LuaAnyUserData| {
            let edge = edge_ud.borrow::<LuaEdge>()?;
            Ok(this.inner.borrow_mut().remove_edge(edge.id))
        });
        methods.add_method("hasEdge", |_, this, edge_ud: LuaAnyUserData| {
            let edge = edge_ud.borrow::<LuaEdge>()?;
            Ok(this.inner.borrow().has_edge(edge.id))
        });
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
        methods.add_method("getEdgeCount", |_, this, ()| {
            Ok(this.inner.borrow().get_edge_count())
        });
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
        methods.add_method("removeItem", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            Ok(this.inner.borrow_mut().remove_item(item.id))
        });
        methods.add_method("hasItem", |_, this, item_ud: LuaAnyUserData| {
            let item = item_ud.borrow::<LuaGraphItem>()?;
            Ok(this.inner.borrow().has_item(item.id))
        });
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
        methods.add_method("getItemCount", |_, this, ()| {
            Ok(this.inner.borrow().get_item_count())
        });
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
        methods.add_method("update", |lua, this, dt: f64| {
            let events = this.inner.borrow_mut().update(dt);
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });
        methods.add_method("step", |lua, this, ()| {
            let events = this.inner.borrow_mut().step();
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });
        methods.add_method("tickParallel", |lua, this, dt: f64| {
            let events = this.inner.borrow_mut().update_parallel(dt);
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });
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
        methods.add_method(
            "getDistance",
            |_, this, (from_ud, to_ud): (LuaAnyUserData, LuaAnyUserData)| {
                let from = from_ud.borrow::<LuaNode>()?;
                let to = to_ud.borrow::<LuaNode>()?;
                Ok(this.inner.borrow().get_distance(from.id, to.id))
            },
        );
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
        methods.add_method("hasCycle", |_, this, ()| {
            Ok(this.inner.borrow().has_cycle())
        });
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
        methods.add_method("mst", |lua, this, ()| {
            let edge_ids = this.inner.borrow().mst_kruskal();
            let t = lua.create_table()?;
            for (i, eid) in edge_ids.iter().enumerate() {
                t.set(i + 1, *eid)?;
            }
            Ok(t)
        });
        methods.add_method("colorGraph", |lua, this, ()| {
            let colors = this.inner.borrow().color_graph();
            let t = lua.create_table()?;
            for (node_id, color) in &colors {
                t.set(*node_id, *color as u64)?;
            }
            Ok(t)
        });
        methods.add_method("isBipartite", |_lua, this, ()| {
            Ok(this.inner.borrow().is_bipartite())
        });
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
        methods.add_method("processDemand", |lua, this, ()| {
            let events = this.inner.borrow_mut().process_demand();
            let cbs = this.callbacks.borrow();
            dispatch_events(lua, &this.inner, &cbs, events)
        });
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
        methods.add_method("type", |_, _, ()| Ok("LGraph"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGraph" || name == "Graph" || name == "Object")
        });
    }
}
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
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
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
