//! Hierarchical Pathfinding A★ (HPA★) for fast long-range queries.
//!
//! Divides the grid into chunks, finds boundary entrances, builds an abstract
//! graph, and searches at the chunk level before refining to tile-level paths.

use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap, HashSet, VecDeque};

use crate::runtime::log_messages::{HP01, HP02, HP03};
use crate::log_msg;
use crate::pathfind::astar;
use crate::pathfind::nav_grid::NavGrid;

/// An edge in the abstract graph connecting two entrance nodes.
///
/// # Fields
/// - `to` — `usize`.
/// - `cost` — `f32`.
#[derive(Debug, Clone)]
pub struct AbstractEdge {
    /// Target node index in `AbstractGraph::nodes`.
    pub to: usize,
    /// Cost to traverse this edge (tile-level distance through the chunk).
    pub cost: f32,
}

/// A node in the abstract graph, representing an entrance point on a chunk boundary.
///
/// # Fields
/// - `x` — `u32`.
/// - `y` — `u32`.
/// - `chunk` — `(u32, u32)`.
#[derive(Debug, Clone)]
pub struct AbstractNode {
    /// Tile x-coordinate.
    pub x: u32,
    /// Tile y-coordinate.
    pub y: u32,
    /// Which chunk this entrance belongs to (chunk_col, chunk_row).
    pub chunk: (u32, u32),
}

/// A chunk region of the grid used during abstract graph construction.
///
/// # Fields
/// - `col` — `u32`.
/// - `row` — `u32`.
/// - `x` — `u32`.
/// - `y` — `u32`.
/// - `w` — `u32`.
/// - `h` — `u32`.
/// - `entrance_indices` — `Vec<usize>`.
#[derive(Debug, Clone)]
pub struct Chunk {
    /// Chunk column index.
    pub col: u32,
    /// Chunk row index.
    pub row: u32,
    /// Top-left tile x.
    pub x: u32,
    /// Top-left tile y.
    pub y: u32,
    /// Actual width in tiles (may be smaller at grid edge).
    pub w: u32,
    /// Actual height in tiles (may be smaller at grid edge).
    pub h: u32,
    /// Indices into `AbstractGraph::nodes` for entrances in this chunk.
    pub entrance_indices: Vec<usize>,
}

/// Pre-computed abstract graph for hierarchical A★ queries.
///
/// # Fields
/// - `nodes` — `Vec<AbstractNode>`.
/// - `edges` — `Vec<Vec<AbstractEdge>>`.
/// - `chunks` — `HashMap<(u32, u32), Chunk>`.
/// - `grid_width` — `u32`.
/// - `grid_height` — `u32`.
/// - `chunk_size` — `u32`.
#[derive(Debug, Clone)]
pub struct AbstractGraph {
    /// All entrance nodes.
    pub nodes: Vec<AbstractNode>,
    /// Adjacency list — `edges[i]` contains edges from node `i`.
    pub edges: Vec<Vec<AbstractEdge>>,
    /// Chunks indexed by `(col, row)`.
    pub chunks: HashMap<(u32, u32), Chunk>,
    /// Grid dimensions at build time.
    pub grid_width: u32,
    /// Grid height at build time.
    pub grid_height: u32,
    /// Chunk size at build time.
    pub chunk_size: u32,
}

/// Priority-queue node for the abstract A★ search.
#[derive(Debug, Clone)]
struct HpaNode {
    f: f32,
    g: f32,
    idx: usize,
}

impl PartialEq for HpaNode {
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}

impl Eq for HpaNode {}

impl Ord for HpaNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}

impl PartialOrd for HpaNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

/// Build the abstract graph from a `NavGrid`.
///
/// # Parameters
/// - `grid` — `&NavGrid`.
/// - `chunk_size` — `u32`.
///
/// # Returns
/// `AbstractGraph`.
///
/// Divides the grid into `chunk_size × chunk_size` regions, finds entrance
/// pairs on every inter-chunk boundary, and connects entrances within the
/// same chunk via local A★.
pub fn build_abstract(grid: &NavGrid, chunk_size: u32) -> AbstractGraph {
    let cs = chunk_size.max(2);
    let (gw, gh) = grid.get_dimensions();
    let cols = gw.div_ceil(cs);
    let rows = gh.div_ceil(cs);

    log_msg!(debug, HP01, "{}x{}", gw, gh);
    let mut graph = AbstractGraph {
        nodes: Vec::new(),
        edges: Vec::new(),
        chunks: HashMap::new(),
        grid_width: gw,
        grid_height: gh,
        chunk_size: cs,
    };

    // Create chunks
    for cr in 0..rows {
        for cc in 0..cols {
            let cx = cc * cs;
            let cy = cr * cs;
            let cw = cs.min(gw - cx);
            let ch = cs.min(gh - cy);
            graph.chunks.insert(
                (cc, cr),
                Chunk {
                    col: cc,
                    row: cr,
                    x: cx,
                    y: cy,
                    w: cw,
                    h: ch,
                    entrance_indices: Vec::new(),
                },
            );
        }
    }

    // Find entrances on horizontal boundaries (between row r and r+1)
    for cr in 0..rows.saturating_sub(1) {
        for cc in 0..cols {
            let chunk = graph.chunks[&(cc, cr)].clone();
            let boundary_y = chunk.y + chunk.h - 1;
            let below_y = boundary_y + 1;
            if below_y >= gh {
                continue;
            }
            find_boundary_entrances(
                grid,
                &mut graph,
                &BoundaryScan {
                    chunk_a: (cc, cr),
                    chunk_b: (cc, cr + 1),
                    range_start: chunk.x,
                    range_end: chunk.x + chunk.w,
                    coord_a: boundary_y,
                    coord_b: below_y,
                    horizontal: true,
                },
            );
        }
    }

    // Find entrances on vertical boundaries (between col c and c+1)
    for cr in 0..rows {
        for cc in 0..cols.saturating_sub(1) {
            let chunk = graph.chunks[&(cc, cr)].clone();
            let boundary_x = chunk.x + chunk.w - 1;
            let right_x = boundary_x + 1;
            if right_x >= gw {
                continue;
            }
            find_boundary_entrances(
                grid,
                &mut graph,
                &BoundaryScan {
                    chunk_a: (cc, cr),
                    chunk_b: (cc + 1, cr),
                    range_start: chunk.y,
                    range_end: chunk.y + chunk.h,
                    coord_a: boundary_x,
                    coord_b: right_x,
                    horizontal: false,
                },
            );
        }
    }

    log_msg!(debug, HP03);
    // Intra-chunk edges: connect all entrances within each chunk via local A★
    let chunk_keys: Vec<(u32, u32)> = graph.chunks.keys().cloned().collect();
    for key in chunk_keys {
        let indices = graph.chunks[&key].entrance_indices.clone();
        let len = indices.len();
        for i in 0..len {
            for j in (i + 1)..len {
                let a = indices[i];
                let b = indices[j];
                let ax = graph.nodes[a].x;
                let ay = graph.nodes[a].y;
                let bx = graph.nodes[b].x;
                let by = graph.nodes[b].y;

                let (path, complete) = astar::astar(grid, (ax, ay), (bx, by), 1, 0);
                if complete {
                    if let Some(ref p) = path {
                        let cost = path_cost_f32(p);
                        graph.edges[a].push(AbstractEdge { to: b, cost });
                        graph.edges[b].push(AbstractEdge { to: a, cost });
                    }
                }
            }
        }
    }

    log_msg!(debug, HP02);
    graph
}

/// Parameters for a boundary entrance scan.
struct BoundaryScan {
    chunk_a: (u32, u32),
    chunk_b: (u32, u32),
    range_start: u32,
    range_end: u32,
    coord_a: u32,
    coord_b: u32,
    horizontal: bool,
}

/// Find entrance pairs along a chunk boundary and add them to the graph.
fn find_boundary_entrances(grid: &NavGrid, graph: &mut AbstractGraph, scan: &BoundaryScan) {
    let BoundaryScan {
        chunk_a,
        chunk_b,
        range_start,
        range_end,
        coord_a,
        coord_b,
        horizontal,
    } = *scan;
    let mut i = range_start;
    while i < range_end {
        // Find start of a walkable run
        let (ax, ay, bx, by) = if horizontal {
            (i, coord_a, i, coord_b)
        } else {
            (coord_a, i, coord_b, i)
        };

        if grid.is_blocked(ax, ay) || grid.is_blocked(bx, by) {
            i += 1;
            continue;
        }

        // Find end of walkable run
        let run_start = i;
        while i < range_end {
            let (nax, nay, nbx, nby) = if horizontal {
                (i, coord_a, i, coord_b)
            } else {
                (coord_a, i, coord_b, i)
            };
            if grid.is_blocked(nax, nay) || grid.is_blocked(nbx, nby) {
                break;
            }
            i += 1;
        }
        let run_end = i;

        // Place entrance(s): one at each end of the run, or a single one if run_len <= 2
        let positions: Vec<u32> = if run_end - run_start <= 2 {
            vec![run_start]
        } else {
            vec![run_start, run_end - 1]
        };

        for pos in positions {
            let (eax, eay, ebx, eby) = if horizontal {
                (pos, coord_a, pos, coord_b)
            } else {
                (coord_a, pos, coord_b, pos)
            };

            let idx_a = get_or_create_node(graph, eax, eay, chunk_a);
            let idx_b = get_or_create_node(graph, ebx, eby, chunk_b);

            // Inter-chunk edge (cost 1 — adjacent cells)
            graph.edges[idx_a].push(AbstractEdge {
                to: idx_b,
                cost: 1.0,
            });
            graph.edges[idx_b].push(AbstractEdge {
                to: idx_a,
                cost: 1.0,
            });
        }
    }
}

/// Get the node index for a position, or create one if it doesn't exist.
fn get_or_create_node(graph: &mut AbstractGraph, x: u32, y: u32, chunk_key: (u32, u32)) -> usize {
    // Check if node already exists at this position
    for (i, n) in graph.nodes.iter().enumerate() {
        if n.x == x && n.y == y {
            return i;
        }
    }

    let idx = graph.nodes.len();
    graph.nodes.push(AbstractNode {
        x,
        y,
        chunk: chunk_key,
    });
    graph.edges.push(Vec::new());

    if let Some(chunk) = graph.chunks.get_mut(&chunk_key) {
        chunk.entrance_indices.push(idx);
    }

    idx
}

/// Sum of step costs along a path (f32 to handle diagonals).
fn path_cost_f32(path: &[(u32, u32)]) -> f32 {
    let mut cost = 0.0f32;
    for i in 1..path.len() {
        let dx = (path[i].0 as f32 - path[i - 1].0 as f32).abs();
        let dy = (path[i].1 as f32 - path[i - 1].1 as f32).abs();
        cost += (dx * dx + dy * dy).sqrt();
    }
    cost
}

/// Run HPA★ from `start` to `goal` on the abstract graph, then refine to tiles.
///
/// # Parameters
/// - `grid` — `&NavGrid`.
/// - `abstract_graph` — `&AbstractGraph`.
/// - `start` — `(u32, u32)`.
/// - `goal` — `(u32, u32)`.
/// - `unit_size` — `u32`.
///
/// # Returns
/// `Option<Vec<(u32, u32)>>`.
///
/// Returns `None` if no path exists. The returned path is tile-level.
pub fn hpa_star(
    grid: &NavGrid,
    abstract_graph: &AbstractGraph,
    start: (u32, u32),
    goal: (u32, u32),
    unit_size: u32,
) -> Option<Vec<(u32, u32)>> {
    // Insert start and goal as temporary nodes
    let cs = abstract_graph.chunk_size;

    let start_chunk = (start.0 / cs, start.1 / cs);
    let goal_chunk = (goal.0 / cs, goal.1 / cs);

    // Build a temporary extended graph
    let mut nodes = abstract_graph.nodes.clone();
    let mut edges = abstract_graph.edges.clone();

    let start_idx = nodes.len();
    nodes.push(AbstractNode {
        x: start.0,
        y: start.1,
        chunk: start_chunk,
    });
    edges.push(Vec::new());

    let goal_idx = nodes.len();
    nodes.push(AbstractNode {
        x: goal.0,
        y: goal.1,
        chunk: goal_chunk,
    });
    edges.push(Vec::new());

    // Connect start/goal to entrances in their chunks
    for &temp_idx in &[start_idx, goal_idx] {
        let chunk_key = nodes[temp_idx].chunk;
        if let Some(chunk) = abstract_graph.chunks.get(&chunk_key) {
            for &ent_idx in &chunk.entrance_indices {
                let (path, complete) = astar::astar(
                    grid,
                    (nodes[temp_idx].x, nodes[temp_idx].y),
                    (nodes[ent_idx].x, nodes[ent_idx].y),
                    unit_size,
                    0,
                );
                if complete {
                    if let Some(ref p) = path {
                        let cost = path_cost_f32(p);
                        edges[temp_idx].push(AbstractEdge { to: ent_idx, cost });
                        edges[ent_idx].push(AbstractEdge { to: temp_idx, cost });
                    }
                }
            }
        }
    }

    // If start and goal are in the same chunk, add direct edge
    if start_chunk == goal_chunk {
        let (path, complete) = astar::astar(grid, start, goal, unit_size, 0);
        if complete {
            if let Some(ref p) = path {
                let cost = path_cost_f32(p);
                edges[start_idx].push(AbstractEdge { to: goal_idx, cost });
            }
        }
    }

    // A★ on abstract graph
    let node_count = nodes.len();
    let mut g_costs = vec![f32::INFINITY; node_count];
    let mut came_from: Vec<usize> = vec![usize::MAX; node_count];
    let mut closed = vec![false; node_count];

    g_costs[start_idx] = 0.0;

    let mut open = BinaryHeap::new();
    open.push(HpaNode {
        f: octile_dist(
            nodes[start_idx].x,
            nodes[start_idx].y,
            nodes[goal_idx].x,
            nodes[goal_idx].y,
        ),
        g: 0.0,
        idx: start_idx,
    });

    while let Some(current) = open.pop() {
        if closed[current.idx] {
            continue;
        }
        closed[current.idx] = true;

        if current.idx == goal_idx {
            // Reconstruct abstract path
            let abstract_path = reconstruct_abstract(&came_from, start_idx, goal_idx, &nodes);
            // Refine to tile-level path
            return refine_path(grid, &abstract_path, unit_size);
        }

        for edge in &edges[current.idx] {
            if closed[edge.to] {
                continue;
            }
            let tentative_g = current.g + edge.cost;
            if tentative_g < g_costs[edge.to] {
                g_costs[edge.to] = tentative_g;
                came_from[edge.to] = current.idx;
                let h = octile_dist(
                    nodes[edge.to].x,
                    nodes[edge.to].y,
                    nodes[goal_idx].x,
                    nodes[goal_idx].y,
                );
                open.push(HpaNode {
                    f: tentative_g + h,
                    g: tentative_g,
                    idx: edge.to,
                });
            }
        }
    }

    Option::None
}

/// Check if `goal` is reachable from `start` using the abstract graph.
///
/// # Parameters
/// - `abstract_graph` — `&AbstractGraph`.
/// - `start` — `(u32, u32)`.
/// - `goal` — `(u32, u32)`.
///
/// # Returns
/// `bool`.
///
/// This is a fast connectivity check — it doesn't compute the actual path.
pub fn is_reachable(abstract_graph: &AbstractGraph, start: (u32, u32), goal: (u32, u32)) -> bool {
    let cs = abstract_graph.chunk_size;
    let start_chunk = (start.0 / cs, start.1 / cs);
    let goal_chunk = (goal.0 / cs, goal.1 / cs);

    if start_chunk == goal_chunk {
        return true; // Same chunk — assume reachable (caller can verify with local A*)
    }

    // BFS on chunk-level connectivity
    let mut visited: HashSet<(u32, u32)> = HashSet::new();
    let mut queue = VecDeque::new();
    visited.insert(start_chunk);
    queue.push_back(start_chunk);

    while let Some(current_chunk) = queue.pop_front() {
        if current_chunk == goal_chunk {
            return true;
        }

        // Find all chunks connected to current_chunk via abstract edges
        if let Some(chunk) = abstract_graph.chunks.get(&current_chunk) {
            for &ent_idx in &chunk.entrance_indices {
                for edge in &abstract_graph.edges[ent_idx] {
                    let target_chunk = abstract_graph.nodes[edge.to].chunk;
                    if visited.insert(target_chunk) {
                        queue.push_back(target_chunk);
                    }
                }
            }
        }
    }

    false
}

/// Octile heuristic distance.
fn octile_dist(x1: u32, y1: u32, x2: u32, y2: u32) -> f32 {
    let dx = (x1 as f32 - x2 as f32).abs();
    let dy = (y1 as f32 - y2 as f32).abs();
    let min = dx.min(dy);
    let max = dx.max(dy);
    min * std::f32::consts::SQRT_2 + (max - min)
}

/// Reconstruct the abstract-level path from came_from table.
fn reconstruct_abstract(
    came_from: &[usize],
    start: usize,
    goal: usize,
    nodes: &[AbstractNode],
) -> Vec<(u32, u32)> {
    let mut path = Vec::new();
    let mut cur = goal;
    loop {
        path.push((nodes[cur].x, nodes[cur].y));
        if cur == start {
            break;
        }
        let prev = came_from[cur];
        if prev == usize::MAX || prev == cur {
            break;
        }
        cur = prev;
    }
    path.reverse();
    path
}

/// Refine an abstract path into a full tile-level path using local A★ segments.
fn refine_path(
    grid: &NavGrid,
    abstract_path: &[(u32, u32)],
    unit_size: u32,
) -> Option<Vec<(u32, u32)>> {
    if abstract_path.is_empty() {
        return Option::None;
    }
    if abstract_path.len() == 1 {
        return Some(abstract_path.to_vec());
    }

    let mut full_path: Vec<(u32, u32)> = Vec::new();

    for i in 0..abstract_path.len() - 1 {
        let (path, complete) =
            astar::astar(grid, abstract_path[i], abstract_path[i + 1], unit_size, 0);
        if !complete {
            return Option::None;
        }
        if let Some(segment) = path {
            if full_path.is_empty() {
                full_path.extend_from_slice(&segment);
            } else {
                // Skip the first node to avoid duplicates at segment joins
                full_path.extend_from_slice(&segment[1..]);
            }
        }
    }

    if full_path.is_empty() {
        Option::None
    } else {
        Some(full_path)
    }
}
