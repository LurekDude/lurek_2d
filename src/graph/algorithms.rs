//! Graph algorithms — connected components, cycle detection, topological sort.
//!
//! This module is part of Lurek2D's `graph` subsystem and provides the implementation
//! details for algorithms-related operations and data management.
//! Primary functions: `get_components()`, `has_cycle()`, `topological_sort()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use std::collections::{HashMap, HashSet, VecDeque};

use super::core::Graph;

impl Graph {
    /// Find weakly connected components (treating all edges as undirected).
    ///
    /// # Returns
    /// `Vec<Vec<u64>>`.
    /// Returns a vector of components, each a vector of node IDs.
    pub fn get_components(&self) -> Vec<Vec<u64>> {
        let mut visited: HashSet<u64> = HashSet::new();
        let mut components = Vec::new();

        // Build adjacency list (undirected)
        let mut adj: HashMap<u64, HashSet<u64>> = HashMap::new();
        for &nid in self.nodes.keys() {
            adj.entry(nid).or_default();
        }
        for edge in self.edges.values() {
            adj.entry(edge.from_node).or_default().insert(edge.to_node);
            adj.entry(edge.to_node).or_default().insert(edge.from_node);
        }

        for &nid in self.nodes.keys() {
            if visited.contains(&nid) {
                continue;
            }
            let mut component = Vec::new();
            let mut queue = VecDeque::new();
            queue.push_back(nid);
            visited.insert(nid);

            while let Some(current) = queue.pop_front() {
                component.push(current);
                if let Some(neighbors) = adj.get(&current) {
                    for &neighbor in neighbors {
                        if !visited.contains(&neighbor) {
                            visited.insert(neighbor);
                            queue.push_back(neighbor);
                        }
                    }
                }
            }
            component.sort();
            components.push(component);
        }

        components
    }

    /// Detect whether the directed graph contains a cycle (DFS-based).
    ///
    /// # Returns
    /// `bool`.
    pub fn has_cycle(&self) -> bool {
        let mut white: HashSet<u64> = self.nodes.keys().copied().collect(); // unvisited
        let mut gray: HashSet<u64> = HashSet::new(); // in current path
        let mut black: HashSet<u64> = HashSet::new(); // fully processed

        // Build directed adjacency list
        let mut adj: HashMap<u64, Vec<u64>> = HashMap::new();
        for &nid in self.nodes.keys() {
            adj.entry(nid).or_default();
        }
        for edge in self.edges.values() {
            adj.entry(edge.from_node).or_default().push(edge.to_node);
        }

        while let Some(&start) = white.iter().next() {
            if Self::dfs_cycle(start, &adj, &mut white, &mut gray, &mut black) {
                return true;
            }
        }
        false
    }

    /// Recursive DFS for cycle detection.
    fn dfs_cycle(
        node: u64,
        adj: &HashMap<u64, Vec<u64>>,
        white: &mut HashSet<u64>,
        gray: &mut HashSet<u64>,
        black: &mut HashSet<u64>,
    ) -> bool {
        white.remove(&node);
        gray.insert(node);

        if let Some(neighbors) = adj.get(&node) {
            for &next in neighbors {
                if black.contains(&next) {
                    continue;
                }
                if gray.contains(&next) {
                    return true; // back edge → cycle
                }
                if Self::dfs_cycle(next, adj, white, gray, black) {
                    return true;
                }
            }
        }

        gray.remove(&node);
        black.insert(node);
        false
    }

    /// Topological sort using Kahn's algorithm.
    ///
    /// # Returns
    /// `Option<Vec<u64>>`.
    /// Returns `None` if the graph contains a cycle.
    pub fn topological_sort(&self) -> Option<Vec<u64>> {
        // Build directed adjacency list and in-degree map
        let mut in_degree: HashMap<u64, usize> = HashMap::new();
        let mut adj: HashMap<u64, Vec<u64>> = HashMap::new();

        for &nid in self.nodes.keys() {
            in_degree.entry(nid).or_insert(0);
            adj.entry(nid).or_default();
        }
        for edge in self.edges.values() {
            adj.entry(edge.from_node).or_default().push(edge.to_node);
            *in_degree.entry(edge.to_node).or_insert(0) += 1;
        }

        // Start with nodes that have no incoming edges
        let mut queue: VecDeque<u64> = in_degree
            .iter()
            .filter(|(_, &deg)| deg == 0)
            .map(|(&id, _)| id)
            .collect();
        // Sort for deterministic output
        let mut sorted_start: Vec<u64> = queue.drain(..).collect();
        sorted_start.sort();
        for id in sorted_start {
            queue.push_back(id);
        }

        let mut result = Vec::new();
        while let Some(node) = queue.pop_front() {
            result.push(node);
            if let Some(neighbors) = adj.get(&node) {
                let mut next_nodes: Vec<u64> = Vec::new();
                for &next in neighbors {
                    if let Some(deg) = in_degree.get_mut(&next) {
                        *deg -= 1;
                        if *deg == 0 {
                            next_nodes.push(next);
                        }
                    }
                }
                next_nodes.sort();
                for n in next_nodes {
                    queue.push_back(n);
                }
            }
        }

        if result.len() == self.nodes.len() {
            Some(result)
        } else {
            None // cycle detected
        }
    }

    /// Kruskal's Minimum Spanning Tree.
    ///
    /// # Returns
    /// `Vec<u64>`.
    ///
    /// Treats all edges as undirected. Returns a list of edge IDs included in the MST.
    /// Returns an empty vec if the graph is empty or has no edges.
    pub fn mst_kruskal(&self) -> Vec<u64> {
        if self.nodes.is_empty() {
            return Vec::new();
        }

        // Collect and sort edges by weight (ascending)
        let mut sorted_edges: Vec<(&u64, f64)> = self.edges
            .iter()
            .map(|(id, e)| (id, e.weight))
            .collect();
        sorted_edges.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal));

        // Union-find with path compression
        let mut parent: HashMap<u64, u64> = self.nodes.keys().map(|&id| (id, id)).collect();

        fn find(parent: &mut HashMap<u64, u64>, x: u64) -> u64 {
            if parent[&x] != x {
                let p = find(parent, parent[&x]);
                parent.insert(x, p);
            }
            parent[&x]
        }

        let mut result = Vec::new();
        for (&edge_id, _) in &sorted_edges {
            let edge = &self.edges[edge_id];
            let rx = find(&mut parent, edge.from_node);
            let ry = find(&mut parent, edge.to_node);
            if rx != ry {
                parent.insert(rx, ry);
                result.push(*edge_id);
            }
        }
        result
    }

    /// A* search from `from` to `to` using optional spatial positions for the heuristic.
    ///
    /// # Parameters
    /// - `from` — `u64`.
    /// - `to` — `u64`.
    /// - `node_positions` — `&HashMap<u64, (f32, f32)>`.
    ///
    /// # Returns
    /// `Option<Vec<u64>>`.
    ///
    /// `node_positions` maps node IDs to `(x, y)` coordinates. An empty map degrades to
    /// Dijkstra (zero heuristic).
    ///
    /// Returns the ordered list of node IDs from `from` to `to`, or `None` if unreachable.
    pub fn astar_graph(
        &self,
        from: u64,
        to: u64,
        node_positions: &HashMap<u64, (f32, f32)>,
    ) -> Option<Vec<u64>> {
        use std::collections::BinaryHeap;

        #[derive(Clone)]
        struct ANode { id: u64, f: f32 }
        impl PartialEq for ANode { fn eq(&self, o: &Self) -> bool { self.f == o.f } }
        impl Eq for ANode {}
        impl PartialOrd for ANode {
            fn partial_cmp(&self, o: &Self) -> Option<std::cmp::Ordering> { Some(self.cmp(o)) }
        }
        impl Ord for ANode {
            fn cmp(&self, o: &Self) -> std::cmp::Ordering {
                o.f.partial_cmp(&self.f).unwrap_or(std::cmp::Ordering::Equal)
            }
        }

        if !self.nodes.contains_key(&from) || !self.nodes.contains_key(&to) {
            return None;
        }
        if from == to {
            return Some(vec![from]);
        }

        let goal_pos = node_positions.get(&to).copied();
        let heuristic = |id: u64| -> f32 {
            if let (Some((ax, ay)), Some((bx, by))) = (node_positions.get(&id), goal_pos) {
                ((ax - bx).powi(2) + (ay - by).powi(2)).sqrt()
            } else {
                0.0
            }
        };

        let mut g_cost: HashMap<u64, f32> = HashMap::new();
        let mut came_from: HashMap<u64, u64> = HashMap::new();
        let mut open: BinaryHeap<ANode> = BinaryHeap::new();

        g_cost.insert(from, 0.0);
        open.push(ANode { id: from, f: heuristic(from) });

        while let Some(ANode { id, .. }) = open.pop() {
            if id == to {
                let mut path = vec![to];
                let mut cur = to;
                while let Some(&prev) = came_from.get(&cur) {
                    path.push(prev);
                    cur = prev;
                }
                path.reverse();
                return Some(path);
            }
            let cur_g = *g_cost.get(&id).unwrap_or(&f32::MAX);

            for edge in self.edges.values() {
                if !edge.active { continue; }
                let nb = if edge.from_node == id { edge.to_node }
                    else if edge.bidirectional && edge.to_node == id { edge.from_node }
                    else { continue };
                if !self.nodes.contains_key(&nb) { continue; }

                let new_g = cur_g + edge.weight.max(0.0) as f32;
                if new_g < *g_cost.get(&nb).unwrap_or(&f32::MAX) {
                    g_cost.insert(nb, new_g);
                    came_from.insert(nb, id);
                    open.push(ANode { id: nb, f: new_g + heuristic(nb) });
                }
            }
        }
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn components_single() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        g.add_edge(a, b, None).unwrap();
        let comps = g.get_components();
        assert_eq!(comps.len(), 1);
        assert!(comps[0].contains(&a));
        assert!(comps[0].contains(&b));
    }

    #[test]
    fn components_multiple() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        let c = g.add_node("c", -1);
        let d = g.add_node("d", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(c, d, None).unwrap();
        let comps = g.get_components();
        assert_eq!(comps.len(), 2);
    }

    #[test]
    fn components_isolated() {
        let mut g = Graph::new();
        g.add_node("a", -1);
        g.add_node("b", -1);
        g.add_node("c", -1);
        let comps = g.get_components();
        assert_eq!(comps.len(), 3);
    }

    #[test]
    fn no_cycle_linear() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        let c = g.add_node("c", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(b, c, None).unwrap();
        assert!(!g.has_cycle());
    }

    #[test]
    fn has_cycle_simple() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(b, a, None).unwrap();
        assert!(g.has_cycle());
    }

    #[test]
    fn topological_sort_linear() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        let c = g.add_node("c", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(b, c, None).unwrap();
        let order = g.topological_sort().unwrap();
        assert_eq!(order, vec![a, b, c]);
    }

    #[test]
    fn topological_sort_cycle_returns_none() {
        let mut g = Graph::new();
        let a = g.add_node("a", -1);
        let b = g.add_node("b", -1);
        g.add_edge(a, b, None).unwrap();
        g.add_edge(b, a, None).unwrap();
        assert!(g.topological_sort().is_none());
    }

    #[test]
    fn empty_graph() {
        let g = Graph::new();
        assert!(g.get_components().is_empty());
        assert!(!g.has_cycle());
        assert_eq!(g.topological_sort(), Some(vec![]));
    }
}
