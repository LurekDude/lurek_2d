//! behavior tree execution model with composites, decorators, leaves, and debug state.
use mlua::RegistryKey;

/// Execution status returned by every behavior tree node after a tick.
#[derive(Debug, Clone, PartialEq)]
pub enum BTStatus {
    /// The node completed its work successfully.
    Success,
    /// The node could not accomplish its task.
    Failure,
    /// The node is still executing and should be resumed next frame.
    Running,
}

impl BTStatus {
    /// Converts a Lua status string into a `BTStatus`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "success" => Self::Success,
            "failure" => Self::Failure,
            _ => Self::Running,
        }
    }

    /// Return the canonical Lua string for this status.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Success => "success",
            Self::Failure => "failure",
            Self::Running => "running",
        }
    }
}

/// Policy for determining when a Parallel composite node succeeds or fails.
#[derive(Debug, Clone, PartialEq)]
pub enum ParallelPolicy {
    /// The parallel node succeeds/fails as soon as any single child meets the condition.
    RequireOne,
    /// The parallel node succeeds/fails only when every child meets the condition.
    RequireAll,
}

impl ParallelPolicy {
    /// Parse a Lua string (`"requireOne"` or `"requireAll"`) into a policy.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "requireAll" => Self::RequireAll,
            _ => Self::RequireOne,
        }
    }

    /// Return the Lua string identifier for this policy.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::RequireOne => "requireOne",
            Self::RequireAll => "requireAll",
        }
    }
}

/// A node in the behavior tree. Composites (Selector, Sequence, Parallel) route control to children;
/// decorators (Inverter, Repeater, Succeeder, Guard) wrap a single child node;
/// leaves (Action, Condition) invoke Lua callbacks directly.
pub enum BTNode {
    /// Tries children in order; returns success on first child success.
    Selector {
        /// Child nodes.
        children: Vec<BTNode>,
        /// Index of currently running child (for resume).
        running_idx: usize,
    },
    /// Runs children in order; returns failure on first child failure.
    Sequence {
        /// Child nodes.
        children: Vec<BTNode>,
        /// Index of currently running child (for resume).
        running_idx: usize,
    },
    /// Ticks all children every frame; result depends on policies.
    Parallel {
        /// Child nodes.
        children: Vec<BTNode>,
        /// When to declare overall success.
        success_policy: ParallelPolicy,
        /// When to declare overall failure.
        failure_policy: ParallelPolicy,
    },
    /// Inverts Success - Failure; passes Running through.
    Inverter {
        /// The single child node.
        child: Box<BTNode>,
    },
    /// Repeats child N times (0 = infinite).
    Repeater {
        /// The single child node.
        child: Box<BTNode>,
        /// Times to repeat (0 = infinite).
        count: u32,
        /// Number of repetitions completed so far.
        done: u32,
    },
    /// Always returns Success regardless of child result.
    Succeeder {
        /// The single child node.
        child: Box<BTNode>,
    },
    /// Guard decorator: evaluates a Lua predicate before ticking the child.
    Guard {
        /// Lua predicate: `fn(agent, bb) -> bool`.
        predicate: RegistryKey,
        /// The guarded child node.
        child: Box<BTNode>,
    },
    /// Leaf that calls a Lua function: `fn(agent, bb, dt) -> "success"|"failure"|"running"`.
    Action {
        /// Registry key to the Lua callback.
        callback: RegistryKey,
    },
    /// Leaf predicate: `fn(agent, bb) -> bool` (true -> Success, false -> Failure).
    Condition {
        /// Registry key to the Lua predicate.
        callback: RegistryKey,
    },
}

impl BTNode {
    /// Recursively resets all running-child memos and repeater counters.
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

    /// Return the number of direct children this node has.
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

/// Root container for a behavior tree instance.
pub struct BehaviorTree {
    /// The root node of the tree, or `None` for an empty tree.
    pub root: Option<BTNode>,
    /// The status returned by the most recent tick. Defaults to `Success`.
    pub last_status: BTStatus,
}

impl BehaviorTree {
    /// Create a new behavior tree with no root node.
    pub fn new() -> Self {
        Self {
            root: None,
            last_status: BTStatus::Success,
        }
    }
}

impl Default for BehaviorTree {
    fn default() -> Self {
        Self::new()
    }
}


/// Counts the total number of nodes in a `BTNode` subtree (inclusive of root).
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

/// A snapshot of a [`BehaviorTree`]'s current diagnostic state.
pub struct BtDebugState {
    /// Total number of nodes in the tree (0 for an empty tree).
    pub node_count: usize,
    /// The status returned by the last tick: `"success"`, `"failure"`, or `"running"`.
    pub last_status: String,
}

impl BehaviorTree {
    /// Return a diagnostic snapshot of this tree's current state.
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
