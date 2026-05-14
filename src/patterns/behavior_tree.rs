
/// Tick result returned by a behavior tree node.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BtStatus {
    /// Node completed successfully.
    Success,
    /// Node completed with failure.
    Failure,
    /// Node is still executing.
    Running,
}
/// Integer identifier for a node within a `BehaviorTree`.
pub type NodeId = u32;

/// Structural type of a behavior tree node.
#[derive(Debug, Clone)]
pub enum NodeKind {
    /// Run children left-to-right; succeed only if all succeed.
    Sequence,
    /// Run children left-to-right; succeed on first success.
    Selector,
    /// Run all children; succeed when at least `min_success` succeed.
    Parallel { min_success: usize },
    /// Invert the single child's result.
    Inverter,
    /// Repeat the single child up to `count` times.
    Repeat { count: usize },
    /// Terminal leaf identified by action `name`.
    Leaf { name: String },
}
/// A single node in the behavior tree with its structural kind and child list.
#[derive(Debug, Clone)]
pub struct BtNode {
    /// Unique identifier within the owning `BehaviorTree`.
    pub id: NodeId,
    /// Structural variant that determines tick semantics.
    pub kind: NodeKind,
    /// Ordered child node identifiers.
    pub children: Vec<NodeId>,
    /// Human-readable debug label.
    pub label: String,
}
/// Builder for constructing a behavior tree by allocating nodes and linking children.
#[derive(Debug, Clone, Default)]
pub struct BehaviorTree {
    /// Allocated nodes in insertion order.
    nodes: Vec<BtNode>,
    /// Next available identifier.
    next_id: NodeId,
    /// Optional root node identifier.
    pub root: Option<NodeId>,
}
/// Construction and query methods for `BehaviorTree`.
impl BehaviorTree {
    /// Create an empty behavior tree.
    pub fn new() -> Self {
        Self::default()
    }
    /// Allocate a new node with `kind` and `label`; return its `NodeId`.
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
    /// Add a Sequence node with `label`; return its `NodeId`.
    pub fn add_sequence(&mut self, label: &str) -> NodeId {
        self.alloc(NodeKind::Sequence, label)
    }
    /// Add a Selector node with `label`; return its `NodeId`.
    pub fn add_selector(&mut self, label: &str) -> NodeId {
        self.alloc(NodeKind::Selector, label)
    }
    /// Add a Parallel node requiring `min_success` successes; return its `NodeId`.
    pub fn add_parallel(&mut self, min_success: usize, label: &str) -> NodeId {
        self.alloc(NodeKind::Parallel { min_success }, label)
    }
    /// Add an Inverter node with `label`; return its `NodeId`.
    pub fn add_inverter(&mut self, label: &str) -> NodeId {
        self.alloc(NodeKind::Inverter, label)
    }
    /// Add a Repeat node that loops its child up to `count` times; return its `NodeId`.
    pub fn add_repeat(&mut self, count: usize, label: &str) -> NodeId {
        self.alloc(NodeKind::Repeat { count }, label)
    }
    /// Add a Leaf node with action `name` and debug `label`; return its `NodeId`.
    pub fn add_leaf(&mut self, name: &str, label: &str) -> NodeId {
        self.alloc(
            NodeKind::Leaf {
                name: name.to_string(),
            },
            label,
        )
    }
    /// Attach `child_id` as the last child of `parent_id`; return false when either id is missing.
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
    /// Set the tree root to `id`; return false when `id` does not exist.
    pub fn set_root(&mut self, id: NodeId) -> bool {
        if self.has_node(id) {
            self.root = Some(id);
            true
        } else {
            false
        }
    }
    /// Return true when a node with `id` exists in this tree.
    pub fn has_node(&self, id: NodeId) -> bool {
        self.nodes.iter().any(|n| n.id == id)
    }
    /// Return a reference to the node with `id`, or `None` if missing.
    pub fn get_node(&self, id: NodeId) -> Option<&BtNode> {
        self.nodes.iter().find(|n| n.id == id)
    }
    /// Return the total number of allocated nodes.
    pub fn node_count(&self) -> usize {
        self.nodes.len()
    }
    /// Return all node identifiers in insertion order.
    pub fn node_ids(&self) -> Vec<NodeId> {
        self.nodes.iter().map(|n| n.id).collect()
    }
    /// Remove all nodes and reset the root.
    pub fn clear(&mut self) {
        self.nodes.clear();
        self.next_id = 0;
        self.root = None;
    }
}
/// Per-tick runtime state for an executing `BehaviorTree`.
#[derive(Debug, Clone, Default)]
pub struct BtRunState {
    /// Nodes currently in `Running` state from the last tick.
    pub running: std::collections::HashSet<NodeId>,
    /// Per-node repeat counters for `Repeat` nodes.
    pub repeat_counters: std::collections::HashMap<NodeId, usize>,
}
/// Methods for `BtRunState`.
impl BtRunState {
    /// Create an empty run state.
    pub fn new() -> Self {
        Self::default()
    }
    /// Clear all running-node markers and repeat counters.
    pub fn reset(&mut self) {
        self.running.clear();
        self.repeat_counters.clear();
    }
}
