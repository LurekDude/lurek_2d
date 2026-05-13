use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
pub struct IsoGrid {
    pub width: u32,
    pub height: u32,
    blocked: Vec<bool>,
    cost: Vec<f32>,
}
impl IsoGrid {
    pub fn new(width: u32, height: u32) -> Self {
        let n = (width * height) as usize;
        Self {
            width,
            height,
            blocked: vec![false; n],
            cost: vec![1.0; n],
        }
    }
    pub fn set_blocked(&mut self, x: u32, y: u32, blocked: bool) {
        if let Some(i) = self.index(x, y) {
            self.blocked[i] = blocked;
        }
    }
    pub fn set_cost(&mut self, x: u32, y: u32, cost: f32) {
        if let Some(i) = self.index(x, y) {
            self.cost[i] = cost;
        }
    }
    pub fn find_path(&self, from: (u32, u32), to: (u32, u32)) -> Option<Vec<(u32, u32)>> {
        if self.is_blocked_or_oob(from.0, from.1) || self.is_blocked_or_oob(to.0, to.1) {
            return None;
        }
        if from == to {
            return Some(vec![from]);
        }
        let mut open: BinaryHeap<Node> = BinaryHeap::new();
        let mut g_cost: HashMap<(u32, u32), f32> = HashMap::new();
        let mut came_from: HashMap<(u32, u32), (u32, u32)> = HashMap::new();
        g_cost.insert(from, 0.0);
        open.push(Node { pos: from, f: 0.0 });
        while let Some(Node { pos, .. }) = open.pop() {
            if pos == to {
                return Some(reconstruct_path(&came_from, to));
            }
            let cur_g = *g_cost.get(&pos).unwrap_or(&f32::MAX);
            for nb in self.neighbors(pos.0, pos.1) {
                let nb_idx = self.index(nb.0, nb.1).unwrap();
                let new_g = cur_g + self.cost[nb_idx];
                if new_g < *g_cost.get(&nb).unwrap_or(&f32::MAX) {
                    g_cost.insert(nb, new_g);
                    came_from.insert(nb, pos);
                    let h = manhattan(nb, to) as f32;
                    open.push(Node {
                        pos: nb,
                        f: new_g + h,
                    });
                }
            }
        }
        None
    }
    pub fn line_of_sight(&self, from: (u32, u32), to: (u32, u32)) -> bool {
        let mut x = from.0 as i32;
        let mut y = from.1 as i32;
        let tx = to.0 as i32;
        let ty = to.1 as i32;
        let dx = (tx - x).abs();
        let dy = (ty - y).abs();
        let sx = if x < tx { 1 } else { -1 };
        let sy = if y < ty { 1 } else { -1 };
        let mut err = dx - dy;
        loop {
            if self.is_blocked_or_oob(x as u32, y as u32) {
                return false;
            }
            if x == tx && y == ty {
                break;
            }
            let e2 = 2 * err;
            if e2 > -dy {
                err -= dy;
                x += sx;
            }
            if e2 < dx {
                err += dx;
                y += sy;
            }
        }
        true
    }
    pub fn neighbors(&self, x: u32, y: u32) -> Vec<(u32, u32)> {
        let mut result = Vec::with_capacity(4);
        let dirs: [(i32, i32); 4] = [(1, 0), (-1, 0), (0, 1), (0, -1)];
        for (dx, dy) in dirs {
            let nx = x as i32 + dx;
            let ny = y as i32 + dy;
            if nx >= 0 && nx < self.width as i32 && ny >= 0 && ny < self.height as i32 {
                let nx = nx as u32;
                let ny = ny as u32;
                if !self.is_blocked_or_oob(nx, ny) {
                    result.push((nx, ny));
                }
            }
        }
        result
    }
    fn index(&self, x: u32, y: u32) -> Option<usize> {
        if x < self.width && y < self.height {
            Some((y * self.width + x) as usize)
        } else {
            None
        }
    }
    fn is_blocked_or_oob(&self, x: u32, y: u32) -> bool {
        self.index(x, y).is_none_or(|i| self.blocked[i])
    }
}
fn manhattan(a: (u32, u32), b: (u32, u32)) -> u32 {
    a.0.abs_diff(b.0) + a.1.abs_diff(b.1)
}
#[derive(Clone)]
struct Node {
    pos: (u32, u32),
    f: f32,
}
impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}
impl Eq for Node {}
impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for Node {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}
fn reconstruct_path(
    came_from: &HashMap<(u32, u32), (u32, u32)>,
    mut current: (u32, u32),
) -> Vec<(u32, u32)> {
    let mut path = vec![current];
    while let Some(&prev) = came_from.get(&current) {
        path.push(prev);
        current = prev;
    }
    path.reverse();
    path
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn new_grid_defaults() {
        let g = IsoGrid::new(5, 5);
        assert_eq!(g.width, 5);
        assert_eq!(g.height, 5);
        assert!(!g.is_blocked_or_oob(0, 0));
    }
    #[test]
    fn blocked_cell_no_path() {
        let mut g = IsoGrid::new(3, 3);
        g.set_blocked(1, 0, true);
        g.set_blocked(1, 1, true);
        g.set_blocked(1, 2, true);
        assert!(g.find_path((0, 0), (2, 0)).is_none());
    }
    #[test]
    fn trivial_same_cell() {
        let g = IsoGrid::new(3, 3);
        let path = g.find_path((1, 1), (1, 1)).unwrap();
        assert_eq!(path, vec![(1, 1)]);
    }
    #[test]
    fn simple_path_exists() {
        let g = IsoGrid::new(5, 5);
        let path = g.find_path((0, 0), (4, 4));
        assert!(path.is_some());
        let p = path.unwrap();
        assert_eq!(*p.first().unwrap(), (0, 0));
        assert_eq!(*p.last().unwrap(), (4, 4));
    }
    #[test]
    fn line_of_sight_clear() {
        let g = IsoGrid::new(5, 5);
        assert!(g.line_of_sight((0, 0), (4, 4)));
    }
    #[test]
    fn line_of_sight_blocked() {
        let mut g = IsoGrid::new(5, 5);
        g.set_blocked(2, 2, true);
        assert!(!g.line_of_sight((0, 0), (4, 4)));
    }
    #[test]
    fn neighbors_gives_4_directions() {
        let g = IsoGrid::new(5, 5);
        let n = g.neighbors(2, 2);
        assert_eq!(n.len(), 4);
    }
}
