#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BtStatus {
    Success,
    Failure,
    Running,
}
pub type NodeId = u32;
#[derive(Debug, Clone)]
pub enum NodeKind {
    Sequence,
    Selector,
    Parallel { min_success: usize },
    Inverter,
    Repeat { count: usize },
    Leaf { name: String },
}
#[derive(Debug, Clone)]
pub struct BtNode {
    pub id: NodeId,
    pub kind: NodeKind,
    pub children: Vec<NodeId>,
    pub label: String,
}
#[derive(Debug, Clone, Default)]
pub struct BehaviorTree {
    nodes: Vec<BtNode>,
    next_id: NodeId,
    pub root: Option<NodeId>,
}
impl BehaviorTree {
    pub fn new() -> Self {
        Self::default()
    }
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
    pub fn add_sequence(&mut self, label: &str) -> NodeId {
        self.alloc(NodeKind::Sequence, label)
    }
    pub fn add_selector(&mut self, label: &str) -> NodeId {
        self.alloc(NodeKind::Selector, label)
    }
    pub fn add_parallel(&mut self, min_success: usize, label: &str) -> NodeId {
        self.alloc(NodeKind::Parallel { min_success }, label)
    }
    pub fn add_inverter(&mut self, label: &str) -> NodeId {
        self.alloc(NodeKind::Inverter, label)
    }
    pub fn add_repeat(&mut self, count: usize, label: &str) -> NodeId {
        self.alloc(NodeKind::Repeat { count }, label)
    }
    pub fn add_leaf(&mut self, name: &str, label: &str) -> NodeId {
        self.alloc(
            NodeKind::Leaf {
                name: name.to_string(),
            },
            label,
        )
    }
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
    pub fn set_root(&mut self, id: NodeId) -> bool {
        if self.has_node(id) {
            self.root = Some(id);
            true
        } else {
            false
        }
    }
    pub fn has_node(&self, id: NodeId) -> bool {
        self.nodes.iter().any(|n| n.id == id)
    }
    pub fn get_node(&self, id: NodeId) -> Option<&BtNode> {
        self.nodes.iter().find(|n| n.id == id)
    }
    pub fn node_count(&self) -> usize {
        self.nodes.len()
    }
    pub fn node_ids(&self) -> Vec<NodeId> {
        self.nodes.iter().map(|n| n.id).collect()
    }
    pub fn clear(&mut self) {
        self.nodes.clear();
        self.next_id = 0;
        self.root = None;
    }
}
#[derive(Debug, Clone, Default)]
pub struct BtRunState {
    pub running: std::collections::HashSet<NodeId>,
    pub repeat_counters: std::collections::HashMap<NodeId, usize>,
}
impl BtRunState {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn reset(&mut self) {
        self.running.clear();
        self.repeat_counters.clear();
    }
}
