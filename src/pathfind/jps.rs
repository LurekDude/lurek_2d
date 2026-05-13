use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
pub struct JpsGrid {
    pub width: u32,
    pub height: u32,
    blocked: Vec<bool>,
}
impl JpsGrid {
    pub fn new(width: u32, height: u32) -> Self {
        let n = (width * height) as usize;
        Self {
            width,
            height,
            blocked: vec![false; n],
        }
    }
    pub fn set_blocked(&mut self, x: u32, y: u32, blocked: bool) {
        if let Some(i) = self.idx(x, y) {
            self.blocked[i] = blocked;
        }
    }
    pub fn is_blocked(&self, x: u32, y: u32) -> bool {
        self.idx(x, y).is_none_or(|i| self.blocked[i])
    }
    pub fn find_path(&self, from: (u32, u32), to: (u32, u32)) -> Option<Vec<(u32, u32)>> {
        if self.is_blocked(from.0, from.1) || self.is_blocked(to.0, to.1) {
            return None;
        }
        if from == to {
            return Some(vec![from]);
        }
        let mut open: BinaryHeap<JpsNode> = BinaryHeap::new();
        let mut g_cost: HashMap<(u32, u32), f32> = HashMap::new();
        let mut came_from: HashMap<(u32, u32), (u32, u32)> = HashMap::new();
        g_cost.insert(from, 0.0);
        for dx in -1i32..=1 {
            for dy in -1i32..=1 {
                if dx == 0 && dy == 0 {
                    continue;
                }
                let g = g_cost[&from] + diagonal_cost(dx, dy);
                if let Some(jp) = self.jump(from.0 as i32, from.1 as i32, dx, dy, to) {
                    let jg = g_cost[&from] + self.dist_cost(from, jp);
                    if jg < *g_cost.get(&jp).unwrap_or(&f32::MAX) {
                        g_cost.insert(jp, jg);
                        came_from.insert(jp, from);
                        let h = octile(jp, to);
                        open.push(JpsNode { pos: jp, f: jg + h });
                    }
                }
                let _ = g;
            }
        }
        while let Some(JpsNode { pos, .. }) = open.pop() {
            if pos == to {
                return Some(expand_path(&came_from, to));
            }
            let cur_g = *g_cost.get(&pos).unwrap_or(&f32::MAX);
            let successors = self.identify_successors(pos, &came_from, to);
            for jp in successors {
                let new_g = cur_g + self.dist_cost(pos, jp);
                if new_g < *g_cost.get(&jp).unwrap_or(&f32::MAX) {
                    g_cost.insert(jp, new_g);
                    came_from.insert(jp, pos);
                    let h = octile(jp, to);
                    open.push(JpsNode {
                        pos: jp,
                        f: new_g + h,
                    });
                }
            }
        }
        None
    }
    fn identify_successors(
        &self,
        pos: (u32, u32),
        came_from: &HashMap<(u32, u32), (u32, u32)>,
        goal: (u32, u32),
    ) -> Vec<(u32, u32)> {
        let mut result = Vec::new();
        let neighbors = self.prune_neighbors(pos, came_from);
        for (nx, ny) in neighbors {
            let dx = (nx as i32 - pos.0 as i32).signum();
            let dy = (ny as i32 - pos.1 as i32).signum();
            if let Some(jp) = self.jump(pos.0 as i32, pos.1 as i32, dx, dy, goal) {
                result.push(jp);
            }
        }
        result
    }
    fn jump(&self, x: i32, y: i32, dx: i32, dy: i32, goal: (u32, u32)) -> Option<(u32, u32)> {
        let nx = x + dx;
        let ny = y + dy;
        if nx < 0 || ny < 0 || nx >= self.width as i32 || ny >= self.height as i32 {
            return None;
        }
        if self.is_blocked(nx as u32, ny as u32) {
            return None;
        }
        let cur = (nx as u32, ny as u32);
        if cur == goal {
            return Some(cur);
        }
        if self.has_forced_neighbor(nx, ny, dx, dy) {
            return Some(cur);
        }
        if dx != 0 && dy != 0 {
            if self.jump(nx, ny, dx, 0, goal).is_some() || self.jump(nx, ny, 0, dy, goal).is_some()
            {
                return Some(cur);
            }
            return self.jump(nx, ny, dx, dy, goal);
        }
        if dx != 0 {
            return self.jump(nx, ny, dx, 0, goal);
        }
        self.jump(nx, ny, 0, dy, goal)
    }
    fn has_forced_neighbor(&self, x: i32, y: i32, dx: i32, dy: i32) -> bool {
        if dx != 0 && dy != 0 {
            (self.is_blocked_i(x - dx, y) && !self.is_blocked_i(x - dx, y + dy))
                || (self.is_blocked_i(x, y - dy) && !self.is_blocked_i(x + dx, y - dy))
        } else if dx != 0 {
            (!self.is_blocked_i(x, y + 1) && self.is_blocked_i(x - dx, y + 1))
                || (!self.is_blocked_i(x, y - 1) && self.is_blocked_i(x - dx, y - 1))
        } else {
            (!self.is_blocked_i(x + 1, y) && self.is_blocked_i(x + 1, y - dy))
                || (!self.is_blocked_i(x - 1, y) && self.is_blocked_i(x - 1, y - dy))
        }
    }
    fn prune_neighbors(
        &self,
        pos: (u32, u32),
        came_from: &HashMap<(u32, u32), (u32, u32)>,
    ) -> Vec<(u32, u32)> {
        let parent = came_from.get(&pos);
        if parent.is_none() {
            return self.passable_neighbors(pos.0 as i32, pos.1 as i32);
        }
        let p = parent.unwrap();
        let dx = (pos.0 as i32 - p.0 as i32).signum();
        let dy = (pos.1 as i32 - p.1 as i32).signum();
        let x = pos.0 as i32;
        let y = pos.1 as i32;
        let mut neighbors = Vec::new();
        if dx != 0 && dy != 0 {
            if !self.is_blocked_i(x + dx, y) {
                neighbors.push((x + dx, y));
            }
            if !self.is_blocked_i(x, y + dy) {
                neighbors.push((x, y + dy));
            }
            if !self.is_blocked_i(x + dx, y + dy) {
                neighbors.push((x + dx, y + dy));
            }
            if self.is_blocked_i(x - dx, y) && !self.is_blocked_i(x - dx, y + dy) {
                neighbors.push((x - dx, y + dy));
            }
            if self.is_blocked_i(x, y - dy) && !self.is_blocked_i(x + dx, y - dy) {
                neighbors.push((x + dx, y - dy));
            }
        } else if dx != 0 {
            if !self.is_blocked_i(x + dx, y) {
                neighbors.push((x + dx, y));
            }
            if self.is_blocked_i(x, y + 1) { /* blocked above */
            } else if !self.is_blocked_i(x - dx, y + 1) {
            } else {
                neighbors.push((x + dx, y + 1));
            }
            if !self.is_blocked_i(x, y + 1) && self.is_blocked_i(x - dx, y + 1) {
                neighbors.push((x + dx, y + 1));
            }
            if !self.is_blocked_i(x, y - 1) && self.is_blocked_i(x - dx, y - 1) {
                neighbors.push((x + dx, y - 1));
            }
        } else {
            if !self.is_blocked_i(x, y + dy) {
                neighbors.push((x, y + dy));
            }
            if !self.is_blocked_i(x + 1, y) && self.is_blocked_i(x + 1, y - dy) {
                neighbors.push((x + 1, y + dy));
            }
            if !self.is_blocked_i(x - 1, y) && self.is_blocked_i(x - 1, y - dy) {
                neighbors.push((x - 1, y + dy));
            }
        }
        neighbors
            .into_iter()
            .filter(|&(nx, ny)| {
                nx >= 0 && ny >= 0 && nx < self.width as i32 && ny < self.height as i32
            })
            .map(|(nx, ny)| (nx as u32, ny as u32))
            .collect()
    }
    fn passable_neighbors(&self, x: i32, y: i32) -> Vec<(u32, u32)> {
        let mut result = Vec::new();
        for dx in -1i32..=1 {
            for dy in -1i32..=1 {
                if dx == 0 && dy == 0 {
                    continue;
                }
                let nx = x + dx;
                let ny = y + dy;
                if nx >= 0
                    && ny >= 0
                    && nx < self.width as i32
                    && ny < self.height as i32
                    && !self.is_blocked(nx as u32, ny as u32)
                {
                    result.push((nx as u32, ny as u32));
                }
            }
        }
        result
    }
    fn is_blocked_i(&self, x: i32, y: i32) -> bool {
        if x < 0 || y < 0 || x >= self.width as i32 || y >= self.height as i32 {
            return true;
        }
        self.is_blocked(x as u32, y as u32)
    }
    fn idx(&self, x: u32, y: u32) -> Option<usize> {
        if x < self.width && y < self.height {
            Some((y * self.width + x) as usize)
        } else {
            None
        }
    }
    fn dist_cost(&self, a: (u32, u32), b: (u32, u32)) -> f32 {
        let dx = (a.0 as i32 - b.0 as i32).abs();
        let dy = (a.1 as i32 - b.1 as i32).abs();
        let straight = (dx - dy).unsigned_abs() as f32;
        let diag = dx.min(dy) as f32;
        straight + diag * std::f32::consts::SQRT_2
    }
}
fn diagonal_cost(dx: i32, dy: i32) -> f32 {
    if dx != 0 && dy != 0 {
        std::f32::consts::SQRT_2
    } else {
        1.0
    }
}
fn octile(a: (u32, u32), b: (u32, u32)) -> f32 {
    let dx = (a.0 as i32 - b.0 as i32).unsigned_abs() as f32;
    let dy = (a.1 as i32 - b.1 as i32).unsigned_abs() as f32;
    (dx - dy).abs() + (dx.min(dy)) * std::f32::consts::SQRT_2
}
fn expand_path(came_from: &HashMap<(u32, u32), (u32, u32)>, goal: (u32, u32)) -> Vec<(u32, u32)> {
    let mut jump_path = vec![goal];
    let mut cur = goal;
    while let Some(&prev) = came_from.get(&cur) {
        jump_path.push(prev);
        cur = prev;
    }
    jump_path.reverse();
    let mut full_path = Vec::new();
    for w in jump_path.windows(2) {
        let (mut x, mut y) = (w[0].0 as i32, w[0].1 as i32);
        let (tx, ty) = (w[1].0 as i32, w[1].1 as i32);
        full_path.push((x as u32, y as u32));
        while x != tx || y != ty {
            x += (tx - x).signum();
            y += (ty - y).signum();
            full_path.push((x as u32, y as u32));
        }
    }
    full_path.dedup();
    full_path
}
#[derive(Clone)]
struct JpsNode {
    pos: (u32, u32),
    f: f32,
}
impl PartialEq for JpsNode {
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}
impl Eq for JpsNode {}
impl PartialOrd for JpsNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl Ord for JpsNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f.partial_cmp(&self.f).unwrap_or(Ordering::Equal)
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn trivial_path_same_cell() {
        let g = JpsGrid::new(5, 5);
        let p = g.find_path((2, 2), (2, 2));
        assert!(p.is_some());
        assert_eq!(p.unwrap().len(), 1);
    }
    #[test]
    fn straight_line_path() {
        let g = JpsGrid::new(10, 1);
        let p = g.find_path((0, 0), (9, 0));
        assert!(p.is_some());
        let path = p.unwrap();
        assert_eq!(*path.first().unwrap(), (0, 0));
        assert_eq!(*path.last().unwrap(), (9, 0));
    }
    #[test]
    fn wall_blocks_forces_detour() {
        let mut g = JpsGrid::new(5, 5);
        for y in 0..5 {
            g.set_blocked(2, y, true);
        }
        let p = g.find_path((0, 2), (4, 2));
        assert!(p.is_none(), "solid wall should block");
    }
    #[test]
    fn path_around_obstacle() {
        let mut g = JpsGrid::new(5, 5);
        g.set_blocked(2, 1, true);
        g.set_blocked(2, 2, true);
        g.set_blocked(2, 3, true);
        let p = g.find_path((0, 2), (4, 2));
        assert!(p.is_some());
    }
}
