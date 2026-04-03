//! Upgrade tree: directed acyclic graph for weapon/item progression (Monster Hunter pattern).
//!
//! This module is part of Luna2D's `crafting` subsystem and provides the implementation
//! details for upgrade-related operations and data management.
//! Key types exported from this module: `UpgradeNode`, `UpgradeTree`.
//! Primary functions: `new()`, `new()`, `add_node()`, `add_edge()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::collections::HashMap;

/// A single node in an upgrade tree. Consult the module-level documentation for the broader usage context and preconditions.
///
/// # Fields
/// - `id`, `name`, `description`: Node identity and display text.
/// - `cost`: Material costs keyed by item type.
/// - `prerequisites`: Required node IDs that must already be unlocked.
/// - `unlocked`: Whether the node is currently unlocked.
/// - `children`: IDs of directly reachable upgrades.
/// - `recipe_id`, `output_item_type`: Recipe and output links tied to the node.
/// - `metadata`: Arbitrary caller-defined values.
#[derive(Debug, Clone)]
pub struct UpgradeNode {
    pub id: String,
    pub name: String,
    pub description: String,
    /// Material cost: item_type → quantity.
    pub cost: HashMap<String, u32>,
    pub prerequisites: Vec<String>,
    pub unlocked: bool,
    /// Children in the upgrade DAG.
    pub children: Vec<String>,
    /// Recipe ID associated with this upgrade node.
    pub recipe_id: String,
    /// Output item type produced when this upgrade is applied.
    pub output_item_type: String,
    pub metadata: HashMap<String, String>,
}

impl UpgradeNode {
    /// Create an upgrade node with empty costs and relationships.
    ///
    /// # Parameters
    /// - `id`: Stable node identifier.
    /// - `name`: Display name for the node.
    ///
    /// # Returns
    /// A locked upgrade node with empty costs and children.
    pub fn new(id: impl Into<String>, name: impl Into<String>) -> Self {
        Self {
            id: id.into(),
            name: name.into(),
            description: String::new(),
            cost: HashMap::new(),
            prerequisites: Vec::new(),
            unlocked: false,
            children: Vec::new(),
            recipe_id: String::new(),
            output_item_type: String::new(),
            metadata: HashMap::new(),
        }
    }
}

/// Directed acyclic graph of upgrades for weapons or equipment.
///
/// # Fields
/// - `name`: Display name for the tree.
/// - `nodes`: Upgrade nodes keyed by node ID.
/// - `order`: Node IDs in insertion order.
#[derive(Debug, Default)]
pub struct UpgradeTree {
    pub name: String,
    nodes: HashMap<String, UpgradeNode>,
    order: Vec<String>,
}

impl UpgradeTree {
    /// Create an empty upgrade tree. Returns a fully initialised instance with all fields set to their initial values.
    ///
    /// # Parameters
    /// - `name`: Display name for the tree.
    ///
    /// # Returns
    /// An empty upgrade tree.
    pub fn new(name: impl Into<String>) -> Self {
        Self { name: name.into(), nodes: HashMap::new(), order: Vec::new() }
    }

    /// Add a node to the tree. The insertion is O(1) amortised unless a resize is triggered.
    ///
    /// # Parameters
    /// - `node`: Upgrade node to insert.
    pub fn add_node(&mut self, node: UpgradeNode) {
        if !self.order.contains(&node.id) { self.order.push(node.id.clone()); }
        self.nodes.insert(node.id.clone(), node);
    }

    /// Add a directed edge from `from_id` → `to_id`.
    ///
    /// # Parameters
    /// - `from_id`: Parent node ID.
    /// - `to_id`: Child node ID.
    pub fn add_edge(&mut self, from_id: &str, to_id: &str) {
        if let Some(n) = self.nodes.get_mut(from_id) {
            if !n.children.contains(&to_id.to_string()) {
                n.children.push(to_id.to_string());
            }
        }
    }

    /// Get an immutable node reference by ID. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id`: Node identifier to query.
    ///
    /// # Returns
    /// The matching node, if present.
    pub fn get_node(&self, id: &str) -> Option<&UpgradeNode> { self.nodes.get(id) }

    /// Get a mutable node reference by ID. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Parameters
    /// - `id`: Node identifier to query.
    ///
    /// # Returns
    /// A mutable reference to the matching node, if present.
    pub fn get_node_mut(&mut self, id: &str) -> Option<&mut UpgradeNode> { self.nodes.get_mut(id) }

    /// Returns the children (next upgrades) of a node.
    ///
    /// # Parameters
    /// - `id`: Node identifier to query.
    ///
    /// # Returns
    /// Child node IDs in stored order, or an empty vector if the node is missing.
    pub fn get_children(&self, id: &str) -> Vec<&str> {
        self.nodes.get(id)
            .map(|n| n.children.iter().map(|s| s.as_str()).collect())
            .unwrap_or_default()
    }

    /// Returns node IDs with no incoming edges (tree roots).
    ///
    /// # Returns
    /// Root node IDs in insertion order.
    pub fn get_root_nodes(&self) -> Vec<&str> {
        let has_parent: std::collections::HashSet<&str> = self.nodes.values()
            .flat_map(|n| n.children.iter().map(|s| s.as_str()))
            .collect();
        self.order.iter()
            .filter(|id| !has_parent.contains(id.as_str()))
            .map(|id| id.as_str())
            .collect()
    }

    /// Returns true if a node can be unlocked (all prerequisites unlocked, not yet unlocked).
    ///
    /// # Parameters
    /// - `id`: Node identifier to test.
    ///
    /// # Returns
    /// `true` if the node exists, is still locked, and all prerequisites are unlocked.
    pub fn can_unlock(&self, id: &str) -> bool {
        if let Some(node) = self.nodes.get(id) {
            if node.unlocked { return false; }
            node.prerequisites.iter().all(|p| {
                self.nodes.get(p.as_str()).map(|n| n.unlocked).unwrap_or(false)
            })
        } else {
            false
        }
    }

    /// Unlock a node. Returns `false` if prerequisites not met or already unlocked.
    ///
    /// # Parameters
    /// - `id`: Node identifier to unlock.
    ///
    /// # Returns
    /// `true` if the node transitioned to unlocked.
    pub fn unlock(&mut self, id: &str) -> bool {
        if self.can_unlock(id) {
            if let Some(node) = self.nodes.get_mut(id) {
                node.unlocked = true;
                return true;
            }
        }
        false
    }

    /// Re-lock a previously unlocked node. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `id`: Node identifier to reset.
    ///
    /// # Returns
    /// `true` if the node exists.
    pub fn reset_node(&mut self, id: &str) -> bool {
        if let Some(node) = self.nodes.get_mut(id) {
            node.unlocked = false;
            true
        } else {
            false
        }
    }

    /// Returns all currently unlocked node IDs.
    ///
    /// # Returns
    /// Node IDs for every unlocked node.
    pub fn get_unlocked_ids(&self) -> Vec<String> {
        self.nodes.iter().filter(|(_, n)| n.unlocked).map(|(id, _)| id.clone()).collect()
    }

    /// Return node IDs in insertion order. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Returns
    /// A slice of node IDs in tree order.
    pub fn node_ids(&self) -> &[String] { &self.order }

    /// Return the number of nodes in the tree.
    ///
    /// # Returns
    /// The total node count.
    pub fn count(&self) -> usize { self.nodes.len() }

    /// Returns the parent of the given node (the node whose children include `id`).
    ///
    /// # Parameters
    /// - `id`: Node identifier whose parent should be located.
    ///
    /// # Returns
    /// The parent node ID, if one exists.
    pub fn get_parent(&self, id: &str) -> Option<&str> {
        self.nodes.values()
            .find(|n| n.children.iter().any(|c| c == id))
            .map(|n| n.id.as_str())
    }

    /// Returns shortest path of node IDs from `from` to `to` (BFS), or empty if unreachable.
    ///
    /// # Parameters
    /// - `from`: Starting node ID.
    /// - `to`: Destination node ID.
    ///
    /// # Returns
    /// The shortest path of node IDs, or an empty vector if no path exists.
    pub fn get_path(&self, from: &str, to: &str) -> Vec<String> {
        use std::collections::VecDeque;
        if from == to { return vec![from.to_string()]; }
        let mut queue: VecDeque<Vec<String>> = VecDeque::new();
        let mut visited = std::collections::HashSet::new();
        queue.push_back(vec![from.to_string()]);
        while let Some(path) = queue.pop_front() {
            let current = path.last().unwrap().clone();
            if visited.contains(&current) { continue; }
            visited.insert(current.clone());
            if let Some(node) = self.nodes.get(&current) {
                for child in &node.children {
                    if child == to {
                        let mut result = path.clone();
                        result.push(child.clone());
                        return result;
                    }
                    if !visited.contains(child) {
                        let mut new_path = path.clone();
                        new_path.push(child.clone());
                        queue.push_back(new_path);
                    }
                }
            }
        }
        Vec::new()
    }

    /// Returns all nodes in insertion order. This accessor incurs no allocation; call it freely in hot paths.
    ///
    /// # Returns
    /// Immutable node references in insertion order.
    pub fn get_all_nodes(&self) -> Vec<&UpgradeNode> {
        self.order.iter().filter_map(|id| self.nodes.get(id.as_str())).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn upgrade_tree() {
        let mut tree = UpgradeTree::new("weapon");
        let root = UpgradeNode::new("forge1", "Basic Forge");
        tree.add_node(root);
        assert!(tree.can_unlock("forge1"));
        tree.unlock("forge1");
        assert!(!tree.can_unlock("forge1"));
    }

    #[test]
    fn upgrade_tree_edges_and_roots() {
        let mut tree = UpgradeTree::new("sword_line");
        tree.add_node(UpgradeNode::new("iron1", "Iron Sword I"));
        tree.add_node(UpgradeNode::new("iron2", "Iron Sword II"));
        tree.add_node(UpgradeNode::new("steel1", "Steel Sword"));
        tree.add_edge("iron1", "iron2");
        tree.add_edge("iron2", "steel1");

        let roots = tree.get_root_nodes();
        assert_eq!(roots, vec!["iron1"]);
        assert_eq!(tree.get_children("iron1"), vec!["iron2"]);
    }
}
