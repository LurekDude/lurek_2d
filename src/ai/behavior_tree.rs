use mlua::RegistryKey;
#[derive(Debug, Clone, PartialEq)]
pub enum BTStatus {
    /// Node completed its task successfully.
    Success,
    /// Node could not complete its task.
    Failure,
    /// Node is still in progress and must be ticked again next frame.
    Running,
}
impl BTStatus {
    /// Parse a string tag into `BTStatus`; unknown strings default to `Running`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "success" => Self::Success,
            "failure" => Self::Failure,
            _ => Self::Running,
        }
    }
    /// Return the canonical lowercase string tag for this status.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Success => "success",
            Self::Failure => "failure",
            Self::Running => "running",
        }
    }
}
#[derive(Debug, Clone, PartialEq)]
pub enum ParallelPolicy {
    /// Parallel succeeds as soon as any one child succeeds.
    RequireOne,
    /// Parallel succeeds only when all children succeed.
    RequireAll,
}
impl ParallelPolicy {
    /// Parse a string tag; unknown strings default to `RequireOne`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "requireAll" => Self::RequireAll,
            _ => Self::RequireOne,
        }
    }
    /// Return the canonical string tag for this policy.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::RequireOne => "requireOne",
            Self::RequireAll => "requireAll",
        }
    }
}
pub enum BTNode {
    /// Tries children in order; succeeds on the first child success, fails when all fail.
    Selector {
        /// Ordered list of child nodes.
        children: Vec<BTNode>,
        /// Index of the child currently in `Running` state; reset to 0 on restart.
        running_idx: usize,
    },
    /// Runs children in order; fails on the first child failure, succeeds when all pass.
    Sequence {
        /// Ordered list of child nodes.
        children: Vec<BTNode>,
        /// Index of the child currently in `Running` state; reset to 0 on restart.
        running_idx: usize,
    },
    /// Ticks all children each frame; result controlled by success and failure policies.
    Parallel {
        /// All child nodes ticked each update.
        children: Vec<BTNode>,
        /// Determines when the parallel node reports success.
        success_policy: ParallelPolicy,
        /// Determines when the parallel node reports failure.
        failure_policy: ParallelPolicy,
    },
    /// Flips child result: `Success` ↔ `Failure`; `Running` passes through unchanged.
    Inverter {
        /// The single child whose result is inverted.
        child: Box<BTNode>,
    },
    /// Runs its child `count` times before reporting `Success`.
    Repeater {
        /// The child to repeat.
        child: Box<BTNode>,
        /// Total repetition target; 0 means repeat indefinitely.
        count: u32,
        /// Number of repetitions completed so far.
        done: u32,
    },
    /// Always returns `Success` regardless of the child's result.
    Succeeder {
        /// The child whose result is overridden to `Success`.
        child: Box<BTNode>,
    },
    /// Evaluates a Lua predicate; runs child only when the predicate returns truthy.
    Guard {
        /// Registry key of the Lua predicate callback.
        predicate: RegistryKey,
        /// The child executed when the predicate passes.
        child: Box<BTNode>,
    },
    /// Leaf that calls a Lua callback and converts the return value to `BTStatus`.
    Action {
        /// Registry key of the Lua action callback.
        callback: RegistryKey,
    },
    /// Leaf that evaluates a Lua predicate: `true` → `Success`, `false` → `Failure`.
    Condition {
        /// Registry key of the Lua condition callback.
        callback: RegistryKey,
    },
}
impl BTNode {
    /// Reset all running indices and repetition counters in this subtree recursively.
    pub fn reset(&mut self) {
        match self {
            BTNode::Selector {
                children,
                running_idx,
            } => {
                *running_idx = 0;
                for child in children.iter_mut() {
                    child.reset();
                }
            }
            BTNode::Sequence {
                children,
                running_idx,
            } => {
                *running_idx = 0;
                for child in children.iter_mut() {
                    child.reset();
                }
            }
            BTNode::Parallel { children, .. } => {
                for child in children.iter_mut() {
                    child.reset();
                }
            }
            BTNode::Inverter { child } => child.reset(),
            BTNode::Repeater { child, done, .. } => {
                *done = 0;
                child.reset();
            }
            BTNode::Succeeder { child } => child.reset(),
            BTNode::Guard { child, .. } => child.reset(),
            BTNode::Action { .. } | BTNode::Condition { .. } => {}
        }
    }
    /// Return the number of direct children; leaf nodes return 0.
    pub fn child_count(&self) -> usize {
        match self {
            BTNode::Selector { children, .. }
            | BTNode::Sequence { children, .. }
            | BTNode::Parallel { children, .. } => children.len(),
            BTNode::Inverter { .. }
            | BTNode::Repeater { .. }
            | BTNode::Succeeder { .. }
            | BTNode::Guard { .. } => 1,
            BTNode::Action { .. } | BTNode::Condition { .. } => 0,
        }
    }
}
pub struct BehaviorTree {
    /// Top-level node; `None` if no tree has been built yet.
    pub root: Option<BTNode>,
    /// Result returned by the last completed tick.
    pub last_status: BTStatus,
}
impl BehaviorTree {
    /// Create an empty tree with `last_status` initialised to `Success`.
    pub fn new() -> Self {
        Self {
            root: None,
            last_status: BTStatus::Success,
        }
    }
}
/// `Default` delegates to `BehaviorTree::new`.
impl Default for BehaviorTree {
    /// `Default` delegates to `BehaviorTree::new`.
    fn default() -> Self {
        Self::new()
    }
}
/// Count all nodes in a subtree recursively, including the root node.
fn count_bt_nodes(node: &BTNode) -> usize {
    1 + match node {
        BTNode::Selector { children, .. }
        | BTNode::Sequence { children, .. }
        | BTNode::Parallel { children, .. } => children.iter().map(count_bt_nodes).sum(),
        BTNode::Inverter { child } | BTNode::Succeeder { child } | BTNode::Guard { child, .. } => {
            count_bt_nodes(child)
        }
        BTNode::Repeater { child, .. } => count_bt_nodes(child),
        BTNode::Action { .. } | BTNode::Condition { .. } => 0,
    }
}
pub struct BtDebugState {
    /// Total node count in the associated tree.
    pub node_count: usize,
    /// String form of the last tick status.
    pub last_status: String,
}
impl BehaviorTree {
    /// Build a `BtDebugState` snapshot from the current tree shape and status.
    pub fn debug_state(&self) -> BtDebugState {
        let node_count = match &self.root {
            Some(root) => count_bt_nodes(root),
            None => 0,
        };
        BtDebugState {
            node_count,
            last_status: self.last_status.as_str().to_string(),
        }
    }
}
