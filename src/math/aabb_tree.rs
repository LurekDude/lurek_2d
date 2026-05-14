
use std::collections::HashMap;

/// Public leaf entry stored alongside a tree node, exposed for Lua query results.
pub struct AabbEntry {
    /// Unique numeric identifier for this entry, matching the Lua-side handle.
    pub id: u64,
    /// Left boundary of the axis-aligned bounding box.
    pub min_x: f32,
    /// Bottom boundary of the axis-aligned bounding box.
    pub min_y: f32,
    /// Right boundary of the axis-aligned bounding box.
    pub max_x: f32,
    /// Top boundary of the axis-aligned bounding box.
    pub max_y: f32,
}

/// Internal node payload classifying a node as leaf or branch.
enum NodeKind {
    /// Leaf holding the id of the entry it represents.
    Leaf { entry_id: u64 },
    /// Branch holding indices of its two child nodes.
    Branch { left: usize, right: usize },
}

/// Internal BVH tree node with an AABB, parent link, and payload kind.
struct Node {
    /// Left boundary of this node's bounding box.
    min_x: f32,
    /// Bottom boundary of this node's bounding box.
    min_y: f32,
    /// Right boundary of this node's bounding box.
    max_x: f32,
    /// Top boundary of this node's bounding box.
    max_y: f32,
    /// Index of the parent node, or `None` for the root.
    parent: Option<usize>,
    /// Leaf or branch classification with child indices or entry id.
    kind: NodeKind,
}

/// Dynamic AABB bounding-volume hierarchy; nodes pool supports free-list reuse.
pub struct AabbTree {
    /// Sparse node pool; `None` slots are freed and reusable.
    nodes: Vec<Option<Node>>,
    /// Maps entry id to its leaf node index in `nodes`.
    leaves: HashMap<u64, usize>,
    /// Maps entry id to its public `AabbEntry` for result data.
    entries: HashMap<u64, AabbEntry>,
    /// Index of the root node, or `None` when the tree is empty.
    root: Option<usize>,
    /// Indices of freed node slots available for reuse.
    free_list: Vec<usize>,
}

/// Return the area of an AABB; returns 0.0 for degenerate (negative-extent) boxes.
#[inline]
fn aabb_area(min_x: f32, min_y: f32, max_x: f32, max_y: f32) -> f32 {
    (max_x - min_x).max(0.0) * (max_y - min_y).max(0.0)
}

/// Return the smallest AABB enclosing two axis-aligned boxes.
#[inline]
#[allow(clippy::too_many_arguments)]
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

/// Return true when two axis-aligned boxes overlap (touching edges count as overlap).
#[inline]
#[allow(clippy::too_many_arguments)]
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

/// Return true when the box overlaps a circle using nearest-point clamping.
#[inline]
fn aabb_circle_overlap(
    min_x: f32,
    min_y: f32,
    max_x: f32,
    max_y: f32,
    cx: f32,
    cy: f32,
    radius: f32,
) -> bool {
    let nearest_x = cx.clamp(min_x, max_x);
    let nearest_y = cy.clamp(min_y, max_y);
    let dx = cx - nearest_x;
    let dy = cy - nearest_y;
    dx * dx + dy * dy <= radius * radius
}

/// Return true when a segment (x1,y1)-(x2,y2) overlaps the box via parametric slab test.
#[inline]
#[allow(clippy::too_many_arguments)]
fn aabb_segment_overlap(
    min_x: f32,
    min_y: f32,
    max_x: f32,
    max_y: f32,
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,
) -> bool {
    let mut t_min = 0.0_f32;
    let mut t_max = 1.0_f32;
    let dx = x2 - x1;
    if dx.abs() < 1e-8 {
        if x1 < min_x || x1 > max_x {
            return false;
        }
    } else {
        let inv = 1.0 / dx;
        let ta = (min_x - x1) * inv;
        let tb = (max_x - x1) * inv;
        let (ta, tb) = if ta <= tb { (ta, tb) } else { (tb, ta) };
        t_min = t_min.max(ta);
        t_max = t_max.min(tb);
        if t_min > t_max {
            return false;
        }
    }
    let dy = y2 - y1;
    if dy.abs() < 1e-8 {
        if y1 < min_y || y1 > max_y {
            return false;
        }
    } else {
        let inv = 1.0 / dy;
        let ta = (min_y - y1) * inv;
        let tb = (max_y - y1) * inv;
        let (ta, tb) = if ta <= tb { (ta, tb) } else { (tb, ta) };
        t_min = t_min.max(ta);
        t_max = t_max.min(tb);
        if t_min > t_max {
            return false;
        }
    }
    true
}
impl AabbTree {
    /// Construct an empty AABB tree with no entries.
    #[allow(clippy::new_without_default)]
    pub fn new() -> Self {
        Self {
            nodes: Vec::new(),
            leaves: HashMap::new(),
            entries: HashMap::new(),
            root: None,
            free_list: Vec::new(),
        }
    }
    /// Insert or replace entry `id` with the given AABB, refitting the tree upward.
    pub fn insert(&mut self, id: u64, min_x: f32, min_y: f32, max_x: f32, max_y: f32) {
        if self.entries.contains_key(&id) {
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
        let sibling = self.find_best_sibling(root, min_x, min_y, max_x, max_y);
        let (sib_min_x, sib_min_y, sib_max_x, sib_max_y, old_parent) = {
            let sib = self.nodes[sibling].as_ref().unwrap();
            (sib.min_x, sib.min_y, sib.max_x, sib.max_y, sib.parent)
        };
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
        self.nodes[sibling].as_mut().unwrap().parent = Some(new_parent);
        self.nodes[leaf_idx].as_mut().unwrap().parent = Some(new_parent);
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
        self.refit_up(new_parent);
    }
    /// Remove entry `id`; returns `true` when the entry existed.
    pub fn remove(&mut self, id: u64) -> bool {
        let leaf_idx = match self.leaves.remove(&id) {
            Some(idx) => idx,
            None => return false,
        };
        self.entries.remove(&id);
        let leaf_parent = self.nodes[leaf_idx].as_ref().unwrap().parent;
        match leaf_parent {
            None => {
                self.free_node(leaf_idx);
                self.root = None;
            }
            Some(parent_idx) => {
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
    /// Return ids of all entries whose AABB overlaps the given query box.
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
    /// Return ids of all entries whose AABB contains the point (x, y).
    pub fn query_point(&self, x: f32, y: f32) -> Vec<u64> {
        self.query(x, y, x, y)
    }
    /// Return ids of all entries whose AABB overlaps the circle, verified with exact circle test.
    pub fn query_circle(&self, cx: f32, cy: f32, radius: f32) -> Vec<u64> {
        let broad = self.query(cx - radius, cy - radius, cx + radius, cy + radius);
        broad
            .into_iter()
            .filter(|id| {
                if let Some(e) = self.entries.get(id) {
                    aabb_circle_overlap(e.min_x, e.min_y, e.max_x, e.max_y, cx, cy, radius)
                } else {
                    false
                }
            })
            .collect()
    }
    /// Return ids of all entries whose AABB overlaps the segment, verified with exact slab test.
    pub fn query_segment(&self, x1: f32, y1: f32, x2: f32, y2: f32) -> Vec<u64> {
        let (bmin_x, bmax_x) = if x1 <= x2 { (x1, x2) } else { (x2, x1) };
        let (bmin_y, bmax_y) = if y1 <= y2 { (y1, y2) } else { (y2, y1) };
        let broad = self.query(bmin_x, bmin_y, bmax_x, bmax_y);
        broad
            .into_iter()
            .filter(|id| {
                if let Some(e) = self.entries.get(id) {
                    aabb_segment_overlap(e.min_x, e.min_y, e.max_x, e.max_y, x1, y1, x2, y2)
                } else {
                    false
                }
            })
            .collect()
    }
    /// Remove and re-insert entry `id` with updated bounds; returns `false` when id is not present.
    pub fn update(&mut self, id: u64, min_x: f32, min_y: f32, max_x: f32, max_y: f32) -> bool {
        if !self.remove(id) {
            return false;
        }
        self.insert(id, min_x, min_y, max_x, max_y);
        true
    }
    /// Return true when entry `id` is currently stored in this tree.
    pub fn contains(&self, id: u64) -> bool {
        self.entries.contains_key(&id)
    }
    /// Return the number of entries currently stored.
    pub fn len(&self) -> usize {
        self.entries.len()
    }
    /// Return true when the tree contains no entries.
    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
    /// Remove all entries and reset the node pool.
    pub fn clear(&mut self) {
        self.nodes.clear();
        self.leaves.clear();
        self.entries.clear();
        self.root = None;
        self.free_list.clear();
    }
    /// Allocate a node from the free list or push a new slot; return its index.
    fn alloc_node(&mut self, node: Node) -> usize {
        if let Some(idx) = self.free_list.pop() {
            self.nodes[idx] = Some(node);
            idx
        } else {
            self.nodes.push(Some(node));
            self.nodes.len() - 1
        }
    }
    /// Return node `idx` to the free list by clearing its slot.
    fn free_node(&mut self, idx: usize) {
        self.nodes[idx] = None;
        self.free_list.push(idx);
    }
    /// Find the best existing node to pair with a new leaf using surface-area heuristic descent.
    fn find_best_sibling(&self, start: usize, lx1: f32, ly1: f32, lx2: f32, ly2: f32) -> usize {
        let leaf_area = aabb_area(lx1, ly1, lx2, ly2);
        let mut best = start;
        let mut best_cost = f32::MAX;
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
            let child_inherited = inherited + (merged - node_area);
            if leaf_area + child_inherited < best_cost {
                if let NodeKind::Branch { left, right } = &node.kind {
                    let left_node = self.nodes[*left].as_ref().unwrap();
                    let right_node = self.nodes[*right].as_ref().unwrap();
                    let left_merged = {
                        let (x1, y1, x2, y2) = merged_bounds(
                            left_node.min_x,
                            left_node.min_y,
                            left_node.max_x,
                            left_node.max_y,
                            lx1,
                            ly1,
                            lx2,
                            ly2,
                        );
                        aabb_area(x1, y1, x2, y2)
                    };
                    let right_merged = {
                        let (x1, y1, x2, y2) = merged_bounds(
                            right_node.min_x,
                            right_node.min_y,
                            right_node.max_x,
                            right_node.max_y,
                            lx1,
                            ly1,
                            lx2,
                            ly2,
                        );
                        aabb_area(x1, y1, x2, y2)
                    };
                    if left_merged <= right_merged {
                        stack.push((*right, child_inherited));
                        stack.push((*left, child_inherited));
                    } else {
                        stack.push((*left, child_inherited));
                        stack.push((*right, child_inherited));
                    }
                }
            }
        }
        best
    }
    /// Walk from `idx` to the root refitting each branch AABB to enclose its children.
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
