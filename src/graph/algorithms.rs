//! - Connected-component discovery via undirected BFS traversal.
//! - Directed cycle detection using a three-color DFS walk.
//! - Kahn-style topological sort with deterministic tie-breaking.
//! - Kruskal minimum spanning forest using a union-find structure.
//! - Greedy graph coloring with sorted node-id processing order.
//! - Bipartiteness test through BFS two-coloring.
//! - A* shortest-path search using Euclidean node-position heuristics.
//! - All algorithms operate on the shared `Graph` adjacency representation.

use super::core::Graph;
use std::collections::{HashMap, HashSet, VecDeque};
impl Graph {
    /// Return connected components as sorted node-id groups.
    pub fn get_components(&self) -> Vec<Vec<u64>> {
        let mut visited: HashSet<u64> = HashSet::new();
        let mut components = Vec::new();
        let mut adj: HashMap<u64, HashSet<u64>> = HashMap::new();
        for &nid in self.nodes.keys() {
            adj.entry(nid).or_default();
        }
        for &from in self.nodes.keys() {
            for &edge_id in self.outgoing_edge_ids_slice(from) {
                if let Some(edge) = self.edges.get(&edge_id) {
                    adj.entry(edge.from_node).or_default().insert(edge.to_node);
                    adj.entry(edge.to_node).or_default().insert(edge.from_node);
                }
            }
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
    /// Return true when the directed graph contains a cycle.
    pub fn has_cycle(&self) -> bool {
        let mut white: HashSet<u64> = self.nodes.keys().copied().collect();
        let mut gray: HashSet<u64> = HashSet::new();
        let mut black: HashSet<u64> = HashSet::new();
        let mut adj: HashMap<u64, Vec<u64>> = HashMap::new();
        for &nid in self.nodes.keys() {
            adj.entry(nid).or_default();
        }
        for &from in self.nodes.keys() {
            for &edge_id in self.outgoing_edge_ids_slice(from) {
                if let Some(edge) = self.edges.get(&edge_id) {
                    adj.entry(edge.from_node).or_default().push(edge.to_node);
                }
            }
        }
        while let Some(&start) = white.iter().next() {
            if Self::dfs_cycle(start, &adj, &mut white, &mut gray, &mut black) {
                return true;
            }
        }
        false
    }
    /// Depth-first search helper that detects directed back edges.
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
                    return true;
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
    /// Return a topological ordering or None when the graph has a cycle.
    pub fn topological_sort(&self) -> Option<Vec<u64>> {
        let mut in_degree: HashMap<u64, usize> = HashMap::new();
        let mut adj: HashMap<u64, Vec<u64>> = HashMap::new();
        for &nid in self.nodes.keys() {
            in_degree.entry(nid).or_insert(0);
            adj.entry(nid).or_default();
        }
        for &from in self.nodes.keys() {
            for &edge_id in self.outgoing_edge_ids_slice(from) {
                if let Some(edge) = self.edges.get(&edge_id) {
                    adj.entry(edge.from_node).or_default().push(edge.to_node);
                    *in_degree.entry(edge.to_node).or_insert(0) += 1;
                }
            }
        }
        let mut queue: VecDeque<u64> = in_degree
            .iter()
            .filter(|(_, &deg)| deg == 0)
            .map(|(&id, _)| id)
            .collect();
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
            None
        }
    }
    /// Return edge ids in a Kruskal minimum spanning forest.
    pub fn mst_kruskal(&self) -> Vec<u64> {
        if self.nodes.is_empty() {
            return Vec::new();
        }
        let mut sorted_edges: Vec<(&u64, f64)> =
            self.edges.iter().map(|(id, e)| (id, e.weight)).collect();
        sorted_edges.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal));
        let mut parent: HashMap<u64, u64> = self.nodes.keys().map(|&id| (id, id)).collect();
        /// Find the disjoint-set representative for a node id.
        fn find(parent: &mut HashMap<u64, u64>, x: u64) -> u64 {
            if parent[&x] != x {
                let p = find(parent, parent[&x]);
                parent.insert(x, p);
            }
            parent[&x]
        }
        let mut result = Vec::new();
        for (&edge_id, _) in &sorted_edges {
            let edge = &self.edges[&edge_id];
            let rx = find(&mut parent, edge.from_node);
            let ry = find(&mut parent, edge.to_node);
            if rx != ry {
                parent.insert(rx, ry);
                result.push(edge_id);
            }
        }
        result
    }
    /// Assign greedy graph colors to node ids.
    pub fn color_graph(&self) -> HashMap<u64, usize> {
        let mut adj: HashMap<u64, Vec<u64>> = HashMap::new();
        for id in self.nodes.keys() {
            adj.entry(*id).or_default();
        }
        for &from in self.nodes.keys() {
            for &edge_id in self.outgoing_edge_ids_slice(from) {
                if let Some(edge) = self.edges.get(&edge_id) {
                    adj.entry(edge.from_node).or_default().push(edge.to_node);
                    adj.entry(edge.to_node).or_default().push(edge.from_node);
                }
            }
        }
        let mut colors: HashMap<u64, usize> = HashMap::new();
        let mut node_ids: Vec<u64> = self.nodes.keys().copied().collect();
        node_ids.sort_unstable();
        for id in node_ids {
            let used: HashSet<usize> = adj
                .get(&id)
                .map(|nbrs| nbrs.iter().filter_map(|n| colors.get(n)).copied().collect())
                .unwrap_or_default();
            let color = (0..).find(|c| !used.contains(c)).unwrap_or(0);
            colors.insert(id, color);
        }
        colors
    }
    /// Return true when the graph is bipartite.
    pub fn is_bipartite(&self) -> bool {
        let mut color: HashMap<u64, u8> = HashMap::new();
        let mut adj: HashMap<u64, Vec<u64>> = HashMap::new();
        for id in self.nodes.keys() {
            adj.entry(*id).or_default();
        }
        for &from in self.nodes.keys() {
            for &edge_id in self.outgoing_edge_ids_slice(from) {
                if let Some(edge) = self.edges.get(&edge_id) {
                    adj.entry(edge.from_node).or_default().push(edge.to_node);
                    adj.entry(edge.to_node).or_default().push(edge.from_node);
                }
            }
        }
        for &start in self.nodes.keys() {
            if color.contains_key(&start) {
                continue;
            }
            let mut queue = VecDeque::new();
            queue.push_back(start);
            color.insert(start, 0);
            while let Some(node) = queue.pop_front() {
                let node_color = color[&node];
                if let Some(neighbors) = adj.get(&node) {
                    for &nbr in neighbors {
                        if let Some(&c) = color.get(&nbr) {
                            if c == node_color {
                                return false;
                            }
                        } else {
                            color.insert(nbr, 1 - node_color);
                            queue.push_back(nbr);
                        }
                    }
                }
            }
        }
        true
    }
    /// Find an A* node path using supplied node positions as the heuristic source.
    pub fn astar_graph(
        &self,
        from: u64,
        to: u64,
        node_positions: &HashMap<u64, (f32, f32)>,
    ) -> Option<Vec<u64>> {
        use std::collections::BinaryHeap;
        /// Open-set entry used by A* search.
        #[derive(Clone)]
        struct ANode {
            /// Node id represented by this queue entry.
            id: u64,
            /// Estimated total cost through this node.
            f: f32,
        }
        /// Compare A* queue entries by estimated total cost.
        impl PartialEq for ANode {
            fn eq(&self, o: &Self) -> bool {
                self.f == o.f
            }
        }
        /// Marks A* queue entries as equatable.
        impl Eq for ANode {}
        /// Orders A* queue entries by lowest estimated total cost first.
        impl PartialOrd for ANode {
            fn partial_cmp(&self, o: &Self) -> Option<std::cmp::Ordering> {
                Some(self.cmp(o))
            }
        }
        /// Orders A* queue entries by lowest estimated total cost first.
        impl Ord for ANode {
            fn cmp(&self, o: &Self) -> std::cmp::Ordering {
                o.f.partial_cmp(&self.f)
                    .unwrap_or(std::cmp::Ordering::Equal)
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
        open.push(ANode {
            id: from,
            f: heuristic(from),
        });
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
            for &edge_id in self.outgoing_edge_ids_slice(id) {
                let Some(edge) = self.edges.get(&edge_id) else {
                    continue;
                };
                if !edge.active {
                    continue;
                }
                let nb = edge.to_node;
                if !self.nodes.contains_key(&nb) {
                    continue;
                }
                let new_g = cur_g + edge.weight.max(0.0) as f32;
                if new_g < *g_cost.get(&nb).unwrap_or(&f32::MAX) {
                    g_cost.insert(nb, new_g);
                    came_from.insert(nb, id);
                    open.push(ANode {
                        id: nb,
                        f: new_g + heuristic(nb),
                    });
                }
            }
            for &edge_id in self.incoming_edge_ids_slice(id) {
                let Some(edge) = self.edges.get(&edge_id) else {
                    continue;
                };
                if !edge.active || !edge.bidirectional {
                    continue;
                }
                let nb = edge.from_node;
                if !self.nodes.contains_key(&nb) {
                    continue;
                }
                let new_g = cur_g + edge.weight.max(0.0) as f32;
                if new_g < *g_cost.get(&nb).unwrap_or(&f32::MAX) {
                    g_cost.insert(nb, new_g);
                    came_from.insert(nb, id);
                    open.push(ANode {
                        id: nb,
                        f: new_g + heuristic(nb),
                    });
                }
            }
        }
        None
    }
}
