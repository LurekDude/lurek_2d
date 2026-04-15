//! Dynamic axis-aligned bounding box (AABB) tree for broad-phase queries.
//!
//! [`AabbTree`] is a binary bounding-volume hierarchy (BVH) where each internal
//! node stores the merged AABB of its subtree.  Insertions use the Box2D-style
//! "best first" sibling-selection heuristic to minimise total AABB surface area.
//!
//! Typical use case: broad-phase collision detection for variable-size objects,
//! replacing a uniform [`super::SpatialHash`] when object sizes vary greatly.

use std::collections::HashMap;

// -------------------------------------------------------------------------------
// Public types
// -------------------------------------------------------------------------------

/// A single entry stored at a leaf node of the AABB tree.
///
/// # Fields
/// - `id` — Application-supplied 64-bit identifier.
/// - `min_x`, `min_y` — Minimum corner of the axis-aligned bounding box.
/// - `max_x`, `max_y` — Maximum corner of the axis-aligned bounding box.
pub struct AabbEntry {
    /// Application-supplied identifier, unique within the tree.
    pub id: u64,
    /// Left edge of the bounding box.
    pub min_x: f32,
    /// Bottom edge of the bounding box.
    pub min_y: f32,
    /// Right edge of the bounding box.
    pub max_x: f32,
    /// Top edge of the bounding box.
    pub max_y: f32,
}

// -------------------------------------------------------------------------------
// Private node types
// -------------------------------------------------------------------------------

/// Distinguishes leaf from internal branch nodes.
enum NodeKind {
    Leaf { entry_id: u64 },
    Branch { left: usize, right: usize },
}

/// A single node in the AABB tree (either a leaf or an internal branch).
struct Node {
    min_x: f32,
    min_y: f32,
    max_x: f32,
    max_y: f32,
    parent: Option<usize>,
    kind: NodeKind,
}

// -------------------------------------------------------------------------------
// AabbTree
// -------------------------------------------------------------------------------

/// A dynamic bounding-volume hierarchy for efficient AABB overlap queries.
///
/// Insertions place new entries as leaves and choose a sibling that minimises
/// total AABB area using the Box2D best-first heuristic.  Removals rebalance
/// the tree locally by collapsing the vacated parent node.
///
/// All queries are O(log n) on balanced trees and O(n) worst-case.
pub struct AabbTree {
    nodes: Vec<Option<Node>>,
    /// Maps entry id to the node-pool index of its leaf node.
    leaves: HashMap<u64, usize>,
    /// Stores the AABB entry data keyed by id.
    entries: HashMap<u64, AabbEntry>,
    root: Option<usize>,
    free_list: Vec<usize>,
}

// -------------------------------------------------------------------------------
// Helpers (module-private)
// -------------------------------------------------------------------------------

/// Returns the area of an AABB clamped to zero for degenerate boxes.
#[inline]
fn aabb_area(min_x: f32, min_y: f32, max_x: f32, max_y: f32) -> f32 {
    (max_x - min_x).max(0.0) * (max_y - min_y).max(0.0)
}

/// Returns the merged AABB of two axis-aligned boxes.
#[inline]
fn merged_bounds(
    ax1: f32,
    ay1: f32,
    ax2: f32,
    ay2: f32,
    bx1: f32,
    by1: f32,
    bx2: f32,
    by2: f32,
) -> (f32, f32, f32, f32) {
    (ax1.min(bx1), ay1.min(by1), ax2.max(bx2), ay2.max(by2))
}

/// Returns `true` when the two AABBs overlap (touching edges count as overlap).
#[inline]
fn aabbs_overlap(
    ax1: f32,
    ay1: f32,
    ax2: f32,
    ay2: f32,
    bx1: f32,
    by1: f32,
    bx2: f32,
    by2: f32,
) -> bool {
    !(ax2 < bx1 || ax1 > bx2 || ay2 < by1 || ay1 > by2)
}

// -------------------------------------------------------------------------------
// AabbTree impl
// -------------------------------------------------------------------------------

impl AabbTree {
    /// Creates an empty AABB tree.
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            leaves: HashMap::new(),
            entries: HashMap::new(),
            root: None,
            free_list: Vec::new(),
        }
    }

    /// Inserts an entry with the given AABB into the tree.
    ///
    /// If `id` already exists the existing entry is updated to the new AABB
    /// (equivalent to calling [`AabbTree::update`]).
    ///
    /// # Parameters
    /// - `id` — Unique 64-bit identifier for this entry.
    /// - `min_x`, `min_y` — Minimum corner of the AABB.
    /// - `max_x`, `max_y` — Maximum corner of the AABB.
    pub fn insert(&mut self, id: u64, min_x: f32, min_y: f32, max_x: f32, max_y: f32) {
        if self.entries.contains_key(&id) {
            // Already present — remove then re-insert (upsert semantics).
            self.remove(id);
        }
        self.entries.insert(
            id,
            AabbEntry {
                id,
                min_x,
                min_y,
                max_x,
                max_y,
            },
        );

        let leaf_idx = self.alloc_node(Node {
            min_x,
            min_y,
            max_x,
            max_y,
            parent: None,
            kind: NodeKind::Leaf { entry_id: id },
        });
        self.leaves.insert(id, leaf_idx);

        let root = match self.root {
            None => {
                self.root = Some(leaf_idx);
                return;
            }
            Some(r) => r,
        };

        // --- Find the best sibling using Box2D surface-area heuristic ---
        let sibling = self.find_best_sibling(root, min_x, min_y, max_x, max_y);

        // Read sibling data before any potential realloc.
        let (sib_min_x, sib_min_y, sib_max_x, sib_max_y, old_parent) = {
            let sib = self.nodes[sibling].as_ref().unwrap();
            (sib.min_x, sib.min_y, sib.max_x, sib.max_y, sib.parent)
        };

        // Merged AABB for the new branch node.
        let branch_min_x = sib_min_x.min(min_x);
        let branch_min_y = sib_min_y.min(min_y);
        let branch_max_x = sib_max_x.max(max_x);
        let branch_max_y = sib_max_y.max(max_y);

        let new_parent = self.alloc_node(Node {
            min_x: branch_min_x,
            min_y: branch_min_y,
            max_x: branch_max_x,
            max_y: branch_max_y,
            parent: old_parent,
            kind: NodeKind::Branch {
                left: sibling,
                right: leaf_idx,
            },
        });

        // Connect children to the new branch.
        self.nodes[sibling].as_mut().unwrap().parent = Some(new_parent);
        self.nodes[leaf_idx].as_mut().unwrap().parent = Some(new_parent);

        // Connect the new branch to the tree.
        match old_parent {
            None => {
                self.root = Some(new_parent);
            }
            Some(gp) => {
                let gp_node = self.nodes[gp].as_mut().unwrap();
                match &mut gp_node.kind {
                    NodeKind::Branch { left, right } => {
                        if *left == sibling {
                            *left = new_parent;
                        } else {
                            *right = new_parent;
                        }
                    }
                    NodeKind::Leaf { .. } => unreachable!("parent of a sibling must be a branch"),
                }
            }
        }

        // Walk up from the new branch refitting parent AABBs.
        self.refit_up(new_parent);
    }

    /// Removes the entry with the given `id` from the tree.
    ///
    /// Returns `true` if the entry was found and removed, `false` otherwise.
    ///
    /// # Parameters
    /// - `id` — The identifier of the entry to remove.
    pub fn remove(&mut self, id: u64) -> bool {
        let leaf_idx = match self.leaves.remove(&id) {
            Some(idx) => idx,
            None => return false,
        };
        self.entries.remove(&id);

        let leaf_parent = self.nodes[leaf_idx].as_ref().unwrap().parent;

        match leaf_parent {
            None => {
                // The leaf was the root.
                self.free_node(leaf_idx);
                self.root = None;
            }
            Some(parent_idx) => {
                // Identify the sibling and grandparent.
                let (sibling, parent_parent) = {
                    let parent = self.nodes[parent_idx].as_ref().unwrap();
                    let sibling = match &parent.kind {
                        NodeKind::Branch { left, right } => {
                            if *left == leaf_idx {
                                *right
                            } else {
                                *left
                            }
                        }
                        NodeKind::Leaf { .. } => unreachable!("parent of leaf must be a branch"),
                    };
                    (sibling, parent.parent)
                };

                // Promote the sibling past the removed parent.
                self.nodes[sibling].as_mut().unwrap().parent = parent_parent;

                match parent_parent {
                    None => {
                        self.root = Some(sibling);
                    }
                    Some(gp) => {
                        let gp_node = self.nodes[gp].as_mut().unwrap();
                        match &mut gp_node.kind {
                            NodeKind::Branch { left, right } => {
                                if *left == parent_idx {
                                    *left = sibling;
                                } else {
                                    *right = sibling;
                                }
                            }
                            NodeKind::Leaf { .. } => {
                                unreachable!("grandparent must be a branch")
                            }
                        }
                        self.refit_up(gp);
                    }
                }

                self.free_node(parent_idx);
                self.free_node(leaf_idx);
            }
        }

        true
    }

    /// Returns the ids of all entries whose AABBs overlap the query rectangle.
    ///
    /// # Parameters
    /// - `min_x`, `min_y` — Minimum corner of the query rectangle.
    /// - `max_x`, `max_y` — Maximum corner of the query rectangle.
    pub fn query(&self, min_x: f32, min_y: f32, max_x: f32, max_y: f32) -> Vec<u64> {
        let mut result = Vec::new();
        let root = match self.root {
            Some(r) => r,
            None => return result,
        };

        let mut stack = vec![root];
        while let Some(idx) = stack.pop() {
            let node = match &self.nodes[idx] {
                Some(n) => n,
                None => continue,
            };

            if !aabbs_overlap(
                node.min_x, node.min_y, node.max_x, node.max_y, min_x, min_y, max_x, max_y,
            ) {
                continue;
            }

            match &node.kind {
                NodeKind::Leaf { entry_id } => result.push(*entry_id),
                NodeKind::Branch { left, right } => {
                    stack.push(*left);
                    stack.push(*right);
                }
            }
        }

        result
    }

    /// Returns the ids of all entries whose AABBs contain the point `(x, y)`.
    ///
    /// # Parameters
    /// - `x` — Horizontal coordinate of the query point.
    /// - `y` — Vertical coordinate of the query point.
    pub fn query_point(&self, x: f32, y: f32) -> Vec<u64> {
        self.query(x, y, x, y)
    }

    /// Updates the AABB for an existing entry.
    ///
    /// Returns `true` if the entry existed and was updated, `false` otherwise.
    /// Internally performs a remove followed by a fresh insert.
    ///
    /// # Parameters
    /// - `id` — Identifier of the entry to update.
    /// - `min_x`, `min_y` — New minimum corner.
    /// - `max_x`, `max_y` — New maximum corner.
    pub fn update(&mut self, id: u64, min_x: f32, min_y: f32, max_x: f32, max_y: f32) -> bool {
        if !self.remove(id) {
            return false;
        }
        self.insert(id, min_x, min_y, max_x, max_y);
        true
    }

    /// Returns `true` if an entry with the given `id` exists in the tree.
    ///
    /// # Parameters
    /// - `id` — The identifier to look up.
    pub fn contains(&self, id: u64) -> bool {
        self.entries.contains_key(&id)
    }

    /// Returns the number of entries currently in the tree.
    pub fn len(&self) -> usize {
        self.entries.len()
    }

    /// Returns `true` if the tree contains no entries.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    /// Removes all entries and resets the tree to the empty state.
    pub fn clear(&mut self) {
        self.nodes.clear();
        self.leaves.clear();
        self.entries.clear();
        self.root = None;
        self.free_list.clear();
    }

    // -----------------------------------------------------------------------
    // Private helpers
    // -----------------------------------------------------------------------

    /// Allocates a new node in the pool, reusing freed slots when available.
    fn alloc_node(&mut self, node: Node) -> usize {
        if let Some(idx) = self.free_list.pop() {
            self.nodes[idx] = Some(node);
            idx
        } else {
            self.nodes.push(Some(node));
            self.nodes.len() - 1
        }
    }

    /// Returns a node slot to the free list.
    fn free_node(&mut self, idx: usize) {
        self.nodes[idx] = None;
        self.free_list.push(idx);
    }

    /// Finds the best sibling for a new leaf using the Box2D surface-area
    /// heuristic.  Traversal is pruned when a sub-tree's lower-bound cost
    /// cannot beat the current best.
    ///
    /// # Parameters
    /// - `start` — Root of the sub-tree to search (usually the global root).
    /// - `lx1..ly2` — AABB of the new leaf.
    fn find_best_sibling(
        &self,
        start: usize,
        lx1: f32,
        ly1: f32,
        lx2: f32,
        ly2: f32,
    ) -> usize {
        let leaf_area = aabb_area(lx1, ly1, lx2, ly2);

        let mut best = start;
        let mut best_cost = f32::MAX;

        // Stack elements: (node_index, inherited_cost_from_ancestors)
        let mut stack: Vec<(usize, f32)> = vec![(start, 0.0_f32)];

        while let Some((idx, inherited)) = stack.pop() {
            let node = match &self.nodes[idx] {
                Some(n) => n,
                None => continue,
            };
            let node_area = aabb_area(node.min_x, node.min_y, node.max_x, node.max_y);
            let (mx1, my1, mx2, my2) = merged_bounds(
                node.min_x, node.min_y, node.max_x, node.max_y, lx1, ly1, lx2, ly2,
            );
            let merged = aabb_area(mx1, my1, mx2, my2);
            let cost = merged + inherited;

            if cost < best_cost {
                best_cost = cost;
                best = idx;
            }

            // Prune: no descendant can beat best_cost if leaf_area + child_inherited >= best_cost.
            let child_inherited = inherited + (merged - node_area);
            if leaf_area + child_inherited < best_cost {
                if let NodeKind::Branch { left, right } = &node.kind {
                    stack.push((*left, child_inherited));
                    stack.push((*right, child_inherited));
                }
            }
        }

        best
    }

    /// Walks up the tree from `idx`, refitting each branch node's AABB to
    /// tightly enclose its two children.
    ///
    /// # Parameters
    /// - `idx` — Starting node index (typically the newly created branch).
    fn refit_up(&mut self, mut idx: usize) {
        loop {
            let (left_opt, right_opt, parent_opt) = {
                let node = self.nodes[idx].as_ref().unwrap();
                let (l, r) = match &node.kind {
                    NodeKind::Branch { left, right } => (Some(*left), Some(*right)),
                    NodeKind::Leaf { .. } => (None, None),
                };
                (l, r, node.parent)
            };

            if let (Some(left), Some(right)) = (left_opt, right_opt) {
                let (new_min_x, new_min_y, new_max_x, new_max_y) = {
                    let l = self.nodes[left].as_ref().unwrap();
                    let r = self.nodes[right].as_ref().unwrap();
                    (
                        l.min_x.min(r.min_x),
                        l.min_y.min(r.min_y),
                        l.max_x.max(r.max_x),
                        l.max_y.max(r.max_y),
                    )
                };
                let node = self.nodes[idx].as_mut().unwrap();
                node.min_x = new_min_x;
                node.min_y = new_min_y;
                node.max_x = new_max_x;
                node.max_y = new_max_y;
            }

            match parent_opt {
                Some(p) => idx = p,
                None => break,
            }
        }
    }
}
