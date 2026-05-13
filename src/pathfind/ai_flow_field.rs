use std::collections::VecDeque;
pub struct FlowField {
    pub width: usize,
    pub height: usize,
    directions: Vec<(f32, f32)>,
    distances: Vec<f32>,
    pub goal: Option<(usize, usize)>,
    walkable: Vec<bool>,
}
impl FlowField {
    pub fn new(width: usize, height: usize, walkable: Vec<bool>) -> Self {
        let total = width * height;
        Self {
            width,
            height,
            directions: vec![(0.0, 0.0); total],
            distances: vec![f32::INFINITY; total],
            goal: None,
            walkable,
        }
    }
    pub fn set_goal(&mut self, gx: usize, gy: usize) {
        self.goal = Some((gx, gy));
        self.compute();
    }
    pub fn compute(&mut self) {
        let total = self.width * self.height;
        self.distances = vec![f32::INFINITY; total];
        self.directions = vec![(0.0, 0.0); total];
        let (gx, gy) = match self.goal {
            Some(g) => g,
            None => return,
        };
        if gx >= self.width || gy >= self.height {
            return;
        }
        let goal_idx = gy * self.width + gx;
        if !self.walkable[goal_idx] {
            return;
        }
        self.distances[goal_idx] = 0.0;
        let mut queue = VecDeque::new();
        queue.push_back((gx, gy));
        while let Some((cx, cy)) = queue.pop_front() {
            let curr_dist = self.distances[cy * self.width + cx];
            for &(dx, dy) in &[
                (-1i32, 0),
                (1, 0),
                (0, -1),
                (0, 1),
                (-1, -1),
                (-1, 1),
                (1, -1),
                (1, 1),
            ] {
                let nx = cx as i32 + dx;
                let ny = cy as i32 + dy;
                if nx < 0 || ny < 0 || nx >= self.width as i32 || ny >= self.height as i32 {
                    continue;
                }
                let nux = nx as usize;
                let nuy = ny as usize;
                let nidx = nuy * self.width + nux;
                if !self.walkable[nidx] {
                    continue;
                }
                let step = if dx != 0 && dy != 0 { 1.414 } else { 1.0 };
                let new_dist = curr_dist + step;
                if new_dist < self.distances[nidx] {
                    self.distances[nidx] = new_dist;
                    queue.push_back((nux, nuy));
                }
            }
        }
        for y in 0..self.height {
            for x in 0..self.width {
                let idx = y * self.width + x;
                if self.distances[idx] == f32::INFINITY || (x == gx && y == gy) {
                    continue;
                }
                let mut best_dir = (0.0f32, 0.0f32);
                let mut best_dist = self.distances[idx];
                for &(dx, dy) in &[
                    (-1i32, 0),
                    (1, 0),
                    (0, -1),
                    (0, 1),
                    (-1, -1),
                    (-1, 1),
                    (1, -1),
                    (1, 1),
                ] {
                    let nx = x as i32 + dx;
                    let ny = y as i32 + dy;
                    if nx < 0 || ny < 0 || nx >= self.width as i32 || ny >= self.height as i32 {
                        continue;
                    }
                    let nidx = ny as usize * self.width + nx as usize;
                    if self.distances[nidx] < best_dist {
                        best_dist = self.distances[nidx];
                        best_dir = (dx as f32, dy as f32);
                    }
                }
                let mag = (best_dir.0 * best_dir.0 + best_dir.1 * best_dir.1).sqrt();
                if mag > 0.001 {
                    self.directions[idx] = (best_dir.0 / mag, best_dir.1 / mag);
                }
            }
        }
    }
    pub fn get_direction(&self, x: usize, y: usize) -> (f32, f32) {
        if x < self.width && y < self.height {
            self.directions[y * self.width + x]
        } else {
            (0.0, 0.0)
        }
    }
    pub fn get_distance(&self, x: usize, y: usize) -> f32 {
        if x < self.width && y < self.height {
            self.distances[y * self.width + x]
        } else {
            f32::INFINITY
        }
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    fn open_grid(w: usize, h: usize) -> Vec<bool> {
        vec![true; w * h]
    }
    #[test]
    fn new_field_has_no_goal() {
        let ff = FlowField::new(4, 4, open_grid(4, 4));
        assert!(ff.goal.is_none());
    }
    #[test]
    fn set_goal_computes_directions() {
        let mut ff = FlowField::new(4, 4, open_grid(4, 4));
        ff.set_goal(3, 3);
        assert_eq!(ff.goal, Some((3, 3)));
        assert_eq!(ff.get_distance(3, 3), 0.0);
        assert!(ff.get_distance(0, 0) > 0.0);
        assert!(ff.get_distance(0, 0) < f32::INFINITY);
    }
    #[test]
    fn blocked_goal_stays_infinity() {
        let mut walkable = open_grid(3, 3);
        walkable[2 * 3 + 2] = false;
        let mut ff = FlowField::new(3, 3, walkable);
        ff.set_goal(2, 2);
        assert_eq!(ff.get_distance(0, 0), f32::INFINITY);
    }
    #[test]
    fn direction_points_toward_goal() {
        let mut ff = FlowField::new(5, 1, open_grid(5, 1));
        ff.set_goal(4, 0);
        let (dx, _dy) = ff.get_direction(0, 0);
        assert!(dx > 0.0, "should point right toward goal");
    }
    #[test]
    fn out_of_bounds_returns_defaults() {
        let ff = FlowField::new(2, 2, open_grid(2, 2));
        assert_eq!(ff.get_direction(10, 10), (0.0, 0.0));
        assert_eq!(ff.get_distance(10, 10), f32::INFINITY);
    }
}
