//! Behaviour tree nodes for game AI logic composition.
//!
//! The tree is constructed in Rust as a pure data structure.  Execution and
//! Lua callbacks are wired in the `patterns_api` binding layer.
//!
//! # Node kinds
//! | Kind | Short description |
//! |---|---|
//! | `Sequence` | Runs children left-to-right; fails on first failure. |
//! | `Selector` | Runs children left-to-right; succeeds on first success. |
//! | `Parallel` | Runs all children; result depends on `min_success`. |
//! | `Inverter` | Wraps one child and inverts its result. |
//! | `Repeat` | Repeats a child `n` times (0 = forever until failure). |
//! | `Leaf` | Terminal node executed by a Lua callback. |

/// Result returned by a behaviour tree tick.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BtStatus {
    /// The node succeeded this tick.
    Success,
    /// The node failed this tick.
    Failure,
    /// The node is still running; tick again next frame.
    Running,
}

/// Stable node ID. The tree assigns these in insertion order.
pub type NodeId = u32;

/// The structural kind of a node.
#[derive(Debug, Clone)]
pub enum NodeKind {
    /// Runs children in order; stops and fails on first failure.
    Sequence,
    /// Runs children in order; stops and succeeds on first success.
    Selector,
    /// Runs all children; succeeds when at least `min_success` succeed.
    Parallel { min_success: usize },
    /// Inverts the result of its single child.
    Inverter,
    /// Repeats its single child `count` times (0 = infinite).
    Repeat { count: usize },
    /// Terminal node — execution is delegated to a Lua callback in the API layer.
    Leaf { name: String },
}

/// A node in the behaviour tree.
#[derive(Debug, Clone)]
pub struct BtNode {
    /// Unique ID within the tree.
    pub id: NodeId,
    /// Structural kind.
    pub kind: NodeKind,
    /// IDs of direct children (empty for leaves).
    pub children: Vec<NodeId>,
    /// Optional human-readable label for debugging.
    pub label: String,
}

/// A lightweight, ID-indexed behaviour tree.
///
/// The tree owns its nodes.  Execution state (running status, repeat counters)
/// is stored separately in [`BtRunState`] so the tree itself can be shared or
/// reused across agents.
#[derive(Debug, Clone, Default)]
pub struct BehaviorTree {
    nodes: Vec<BtNode>,
    next_id: NodeId,
    /// ID of the root node, if any.
    pub root: Option<NodeId>,
}

impl BehaviorTree {
    /// Creates an empty [`BehaviorTree`].
    pub fn new() -> Self {
        Self::default()
    }

    // ── Node construction ──────────────────────────────────────────────────

    fn alloc(&mut self, kind: NodeKind, label: &str) -> NodeId {
        let id = self.next_id;
        self.next_id += 1;
        self.nodes.push(BtNode {
            id,
            kind,
            children: Vec::new(),
            label: label.to_string(),
        });
        id
    }

    /// Adds a `Sequence` node and returns its ID.
    pub fn add_sequence(&mut self, label: &str) -> NodeId {
        self.alloc(NodeKind::Sequence, label)
    }

    /// Adds a `Selector` node and returns its ID.
    pub fn add_selector(&mut self, label: &str) -> NodeId {
        self.alloc(NodeKind::Selector, label)
    }

    /// Adds a `Parallel` node and returns its ID.
    pub fn add_parallel(&mut self, min_success: usize, label: &str) -> NodeId {
        self.alloc(NodeKind::Parallel { min_success }, label)
    }

    /// Adds an `Inverter` decorator node and returns its ID.
    pub fn add_inverter(&mut self, label: &str) -> NodeId {
        self.alloc(NodeKind::Inverter, label)
    }

    /// Adds a `Repeat` decorator node and returns its ID.
    pub fn add_repeat(&mut self, count: usize, label: &str) -> NodeId {
        self.alloc(NodeKind::Repeat { count }, label)
    }

    /// Adds a `Leaf` node and returns its ID.
    pub fn add_leaf(&mut self, name: &str, label: &str) -> NodeId {
        self.alloc(
            NodeKind::Leaf {
                name: name.to_string(),
            },
            label,
        )
    }

    /// Attaches `child_id` as the last child of `parent_id`.
    /// Returns `false` when either ID is unknown.
    pub fn add_child(&mut self, parent_id: NodeId, child_id: NodeId) -> bool {
        if !self.has_node(child_id) {
            return false;
        }
        if let Some(p) = self.nodes.iter_mut().find(|n| n.id == parent_id) {
            p.children.push(child_id);
            true
        } else {
            false
        }
    }

    /// Sets the root node.  Returns `false` when the ID is unknown.
    pub fn set_root(&mut self, id: NodeId) -> bool {
        if self.has_node(id) {
            self.root = Some(id);
            true
        } else {
            false
        }
    }

    // ── Queries ────────────────────────────────────────────────────────────

    /// Returns `true` when a node with the given ID exists.
    pub fn has_node(&self, id: NodeId) -> bool {
        self.nodes.iter().any(|n| n.id == id)
    }

    /// Returns a reference to the node with the given ID.
    pub fn get_node(&self, id: NodeId) -> Option<&BtNode> {
        self.nodes.iter().find(|n| n.id == id)
    }

    /// Returns the number of nodes in the tree.
    pub fn node_count(&self) -> usize {
        self.nodes.len()
    }

    /// Returns all node IDs in insertion order.
    pub fn node_ids(&self) -> Vec<NodeId> {
        self.nodes.iter().map(|n| n.id).collect()
    }

    /// Resets the tree to an empty state.
    pub fn clear(&mut self) {
        self.nodes.clear();
        self.next_id = 0;
        self.root = None;
    }
}

/// Per-run execution state for a single agent ticking a [`BehaviorTree`].
///
/// Keep one `BtRunState` per agent so multiple agents can share a single tree
/// definition without interfering with each other.
#[derive(Debug, Clone, Default)]
pub struct BtRunState {
    /// Set of node IDs that returned `Running` in the previous tick.
    pub running: std::collections::HashSet<NodeId>,
    /// Repeat iteration counters, keyed by node ID.
    pub repeat_counters: std::collections::HashMap<NodeId, usize>,
}

impl BtRunState {
    /// Creates a fresh run state.
    pub fn new() -> Self {
        Self::default()
    }

    /// Clears all running and counter state (resets the tick).
    pub fn reset(&mut self) {
        self.running.clear();
        self.repeat_counters.clear();
    }
}
