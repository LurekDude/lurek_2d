//! Behavior Tree with composite, decorator, and leaf nodes.
//!
//! A behavior tree is a hierarchical decision-making structure where each node
//! returns a [`BTStatus`] (Success, Failure, or Running) after being ticked.
//! The tree is traversed from root each frame. Composite nodes (Selector, Sequence,
//! Parallel) manage child execution order. Decorator nodes (Inverter, Repeater,
//! Succeeder) modify child results. Leaf nodes (Action, Condition) call Lua
//! callbacks to evaluate game state or perform actions.
//!
//! ## Running State and Multi-Frame Execution
//!
//! When a leaf node returns `Running`, composite nodes memo the running-child
//! index so the next tick resumes from that child instead of restarting from
//! the first child. This enables multi-frame behaviors like "walk to target"
//! that take several frames to complete.
//!
//! ## Lua Integration
//!
//! Leaf callbacks are stored as `mlua::RegistryKey` references:
//! - **Action**: `fn(agent_table, blackboard_table, dt) → "success" | "failure" | "running"`
//! - **Condition**: `fn(agent_table, blackboard_table) → bool`
//!
//! The tree itself does not call these callbacks — that happens at the
//! [`AIWorld`](crate::ai::world::AIWorld) level during `update(dt)`.

use mlua::RegistryKey;

/// Execution status returned by every behavior tree node after a tick.
///
/// The three-valued return type is the foundation of BT logic:
/// composites and decorators use it to decide whether to continue, abort,
/// or resume child traversal on the next frame.
///
/// # Variants
/// - `Success` — Success variant.
/// - `Failure` — Failure variant.
/// - `Running` — Running variant.
#[derive(Debug, Clone, PartialEq)]
pub enum BTStatus {
    /// The node completed its work successfully.
    Success,
    /// The node could not accomplish its task.
    Failure,
    /// The node is still executing and should be resumed next frame.
    /// Composite nodes store the index of the running child so they
    /// can skip completed siblings on the next tick.
    Running,
}

impl BTStatus {
    /// Converts a Lua status string into a `BTStatus`.
    ///
    /// Accepts `"success"` and `"failure"` literally; any other string
    /// (including `"running"`) maps to `Running`. This permissive default
    /// ensures that a Lua callback returning an unrecognized string keeps
    /// the behavior alive rather than silently succeeding or failing.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "success" => Self::Success,
            "failure" => Self::Failure,
            _ => Self::Running,
        }
    }

    /// Returns the canonical Lua string for this status.
    /// Round-trips with [`parse_str`](Self::parse_str).
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Success => "success",
            Self::Failure => "failure",
            Self::Running => "running",
        }
    }
}

/// Policy for determining when a Parallel composite node succeeds or fails.
///
/// Parallel nodes tick all children every frame (unlike Selector/Sequence which
/// stop on the first decisive result). The success and failure policies control
/// how individual child results are aggregated into an overall result.
///
/// # Variants
/// - `RequireOne` — RequireOne variant.
/// - `RequireAll` — RequireAll variant.
#[derive(Debug, Clone, PartialEq)]
pub enum ParallelPolicy {
    /// The parallel node succeeds/fails as soon as any single child meets the condition.
    RequireOne,
    /// The parallel node succeeds/fails only when every child meets the condition.
    RequireAll,
}

impl ParallelPolicy {
    /// Parses a Lua string (`"requireOne"` or `"requireAll"`) into a policy.
    /// Defaults to `RequireOne` for unrecognized strings.
    ///
    /// # Parameters
    /// - `s` — `&str`.
    ///
    /// # Returns
    /// `Self`.
    pub fn parse_str(s: &str) -> Self {
        match s {
            "requireAll" => Self::RequireAll,
            _ => Self::RequireOne,
        }
    }

    /// Returns the Lua string identifier for this policy.
    /// Round-trips with [`parse_str`](Self::parse_str).
    ///
    /// # Returns
    /// `&'static str`.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::RequireOne => "requireOne",
            Self::RequireAll => "requireAll",
        }
    }
}

/// A node in the behavior tree. Nodes are organized into three categories:
///
/// **Composites** (have multiple children):
/// - `Selector` — tries children left-to-right; returns `Success` on the first
///   child success, `Failure` if all children fail.
/// - `Sequence` — runs children left-to-right; returns `Failure` on the first
///   child failure, `Success` if all children succeed.
/// - `Parallel` — ticks all children every frame; result depends on the
///   `success_policy` and `failure_policy`.
///
/// **Decorators** (have exactly one child):
/// - `Inverter` — flips Success ↔ Failure, passes Running through unchanged.
/// - `Repeater` — repeats the child N times (0 = infinite loop).
/// - `Succeeder` — always returns Success regardless of child result.
/// - `Guard` — evaluates a Lua predicate; ticks the child only when it returns
///   `true`, otherwise returns `Failure` immediately.
///
/// **Leaves** (no children, call Lua callbacks):
/// - `Action` — calls `fn(agent, bb, dt) → "success"|"failure"|"running"`.
/// - `Condition` — calls `fn(agent, bb) → bool` (true → Success, false → Failure).
///
/// Composite nodes store a `running_idx` that memos which child was Running last
/// frame, allowing the tree to resume mid-sequence without restarting from the
/// first child.
///
/// # Variants
/// - `Selector` — Selector variant.
/// - `Sequence` — Sequence variant.
/// - `Parallel` — Parallel variant.
/// - `Inverter` — Inverter variant.
/// - `Repeater` — Repeater variant.
/// - `Succeeder` — Succeeder variant.
/// - `Action` — Action variant.
/// - `Condition` — Condition variant.
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
    /// Inverts Success ↔ Failure; passes Running through.
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
    /// Returns `Failure` immediately when the predicate returns `false`,
    /// otherwise delegates to the child and returns its status.
    /// Consistent with `Action` and `Condition`, the predicate is stored as a
    /// `RegistryKey` so the Lua API layer can invoke it directly.
    Guard {
        /// Lua predicate: `fn(agent, bb) → bool`.
        predicate: RegistryKey,
        /// The guarded child node.
        child: Box<BTNode>,
    },
    /// Leaf that calls a Lua function: `fn(agent, bb, dt) → "success"|"failure"|"running"`.
    Action {
        /// Registry key to the Lua callback.
        callback: RegistryKey,
    },
    /// Leaf predicate: `fn(agent, bb) → bool` (true → Success, false → Failure).
    Condition {
        /// Registry key to the Lua predicate.
        callback: RegistryKey,
    },
}

impl BTNode {
    /// Recursively resets all running-child memos and repeater counters.
    ///
    /// Call this when the tree needs to start fresh — e.g., when an agent
    /// changes decision model or when the tree is reassigned. After reset,
    /// the next tick will traverse from the root with `running_idx = 0` for
    /// all composites and `done = 0` for all repeaters.
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

    /// Returns the number of direct children this node has.
    ///
    /// - Composites (Selector, Sequence, Parallel): number of child nodes.
    /// - Decorators (Inverter, Repeater, Succeeder): always 1.
    /// - Leaves (Action, Condition): always 0.
    ///
    /// # Returns
    /// `usize`.
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
///
/// Wraps an optional root [`BTNode`] and caches the [`BTStatus`] from the last tick.
/// The `last_status` is useful for external code (e.g., the Lua API) to query
/// what the tree decided without re-ticking it.
///
/// An empty tree (root = None) is valid — it returns `Success` without doing anything.
///
/// # Fields
/// - `root` — `Option<BTNode>`.
/// - `last_status` — `BTStatus`.
pub struct BehaviorTree {
    /// The root node of the tree, or `None` for an empty tree.
    pub root: Option<BTNode>,
    /// The status returned by the most recent tick. Defaults to `Success`.
    pub last_status: BTStatus,
}

impl BehaviorTree {
    /// Creates a new behavior tree with no root node.
    /// `last_status` defaults to `Success`.
    ///
    /// # Returns
    /// `Self`.
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

// ---------------------------------------------------------------------------
// Debug introspection
// ---------------------------------------------------------------------------

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
///
/// Returned by [`BehaviorTree::debug_state`] and exposed to Lua via
/// `bt:getDebugState()`.
///
/// # Fields
/// - `node_count` — Total number of nodes in the tree (0 for an empty tree).
/// - `last_status` — The status string returned by the most recent tick.
pub struct BtDebugState {
    /// Total number of nodes in the tree (0 for an empty tree).
    pub node_count: usize,
    /// The status returned by the last tick: `"success"`, `"failure"`, or `"running"`.
    pub last_status: String,
}

impl BehaviorTree {
    /// Returns a diagnostic snapshot of this tree's current state.
    ///
    /// Useful for debugging and developer tooling: exposes the total node
    /// count and the result of the most recent tick without requiring
    /// access to the internal node tree.
    ///
    /// # Returns
    /// [`BtDebugState`].
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bt_status_conversions() {
        assert_eq!(BTStatus::Success.as_str(), "success");
        assert_eq!(BTStatus::Failure.as_str(), "failure");
        assert_eq!(BTStatus::Running.as_str(), "running");
    }

    #[test]
    fn parallel_policy_parse() {
        assert_eq!(
            ParallelPolicy::parse_str("requireAll"),
            ParallelPolicy::RequireAll
        );
        assert_eq!(
            ParallelPolicy::parse_str("requireOne"),
            ParallelPolicy::RequireOne
        );
        assert_eq!(
            ParallelPolicy::parse_str("unknown"),
            ParallelPolicy::RequireOne
        );
    }

    #[test]
    fn new_tree_has_no_root() {
        let bt = BehaviorTree::new();
        assert!(bt.root.is_none());
        let state = bt.debug_state();
        assert_eq!(state.node_count, 0);
    }
}
