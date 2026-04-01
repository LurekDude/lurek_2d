//! Behavior Tree with composite, decorator, and leaf nodes.
//!
//! All nodes return `BTStatus`. Composites memo the running-child index
//! to support multi-frame "running" states.

use mlua::RegistryKey;

/// Return status produced by every BT node after a tick.
///
/// # Variants
/// - `Success` — Success variant.
/// - `Failure` — Failure variant.
/// - `Running` — Running variant.
#[derive(Debug, Clone, PartialEq)]
pub enum BTStatus {
    /// Node completed successfully.
    Success,
    /// Node failed.
    Failure,
    /// Node is still running (will resume next tick).
    Running,
}

impl BTStatus {
    /// Parses a Lua status string.
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

    /// Returns the Lua string representation.
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

/// Parallel node success/failure policy.
///
/// # Variants
/// - `RequireOne` — RequireOne variant.
/// - `RequireAll` — RequireAll variant.
#[derive(Debug, Clone, PartialEq)]
pub enum ParallelPolicy {
    /// Succeeds/fails when any one child meets the condition.
    RequireOne,
    /// Succeeds/fails when all children meet the condition.
    RequireAll,
}

impl ParallelPolicy {
    /// Parses policy from Lua string.
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

    /// Returns the Lua string representation.
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

/// Recursive behavior-tree node.
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
    /// Recursively resets running-child memos and repeater counters.
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
            BTNode::Action { .. } | BTNode::Condition { .. } => {}
        }
    }

    /// Returns the number of children for composite nodes, 1 for decorators, 0 for leaves.
    ///
    /// # Returns
    /// `usize`.
    pub fn child_count(&self) -> usize {
        match self {
            BTNode::Selector { children, .. }
            | BTNode::Sequence { children, .. }
            | BTNode::Parallel { children, .. } => children.len(),
            BTNode::Inverter { .. } | BTNode::Repeater { .. } | BTNode::Succeeder { .. } => 1,
            BTNode::Action { .. } | BTNode::Condition { .. } => 0,
        }
    }
}

/// Root container holding the behavior tree and caching the last tick status.
///
/// # Fields
/// - `root` — `Option<BTNode>`.
/// - `last_status` — `BTStatus`.
pub struct BehaviorTree {
    /// The root node of the tree.
    pub root: Option<BTNode>,
    /// Status from the last tick.
    pub last_status: BTStatus,
}

impl BehaviorTree {
    /// Creates a new empty behavior tree.
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
