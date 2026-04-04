//! Tile-based first-person movement controller with cardinal directions.

use std::cell::RefCell;
use std::f32::consts::PI;
use std::rc::Rc;

use crate::math::raycaster2d::Raycaster2D;

/// Cardinal facing direction.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Facing {
    /// Facing north (up, towards -Y).
    North = 0,
    /// Facing east (right, towards +X).
    East = 1,
    /// Facing south (down, towards +Y).
    South = 2,
    /// Facing west (left, towards -X).
    West = 3,
}

impl Facing {
    /// Parses a facing direction from a string (case-insensitive).
    pub fn parse(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "north" | "n" => Some(Facing::North),
            "east" | "e" => Some(Facing::East),
            "south" | "s" => Some(Facing::South),
            "west" | "w" => Some(Facing::West),
            _ => None,
        }
    }

    /// Returns the direction as a lowercase string.
    pub fn to_str(self) -> &'static str {
        match self {
            Facing::North => "north",
            Facing::East => "east",
            Facing::South => "south",
            Facing::West => "west",
        }
    }

    /// Returns the angle in radians. North=3PI/2, East=0, South=PI/2, West=PI.
    ///
    /// This uses standard math angles where east=0 and angles increase counter-clockwise,
    /// but in screen space (Y-down) east=0 and south=PI/2.
    pub fn angle(self) -> f32 {
        match self {
            Facing::North => 3.0 * PI / 2.0,
            Facing::East => 0.0,
            Facing::South => PI / 2.0,
            Facing::West => PI,
        }
    }

    /// Returns the X delta for one step in this direction.
    pub fn dx(self) -> i32 {
        match self {
            Facing::East => 1,
            Facing::West => -1,
            _ => 0,
        }
    }

    /// Returns the Y delta for one step in this direction.
    pub fn dy(self) -> i32 {
        match self {
            Facing::North => -1,
            Facing::South => 1,
            _ => 0,
        }
    }

    /// Returns the direction after turning left (counter-clockwise).
    fn turn_left(self) -> Facing {
        match self {
            Facing::North => Facing::West,
            Facing::West => Facing::South,
            Facing::South => Facing::East,
            Facing::East => Facing::North,
        }
    }

    /// Returns the direction after turning right (clockwise).
    fn turn_right(self) -> Facing {
        match self {
            Facing::North => Facing::East,
            Facing::East => Facing::South,
            Facing::South => Facing::West,
            Facing::West => Facing::North,
        }
    }

    /// Returns the opposite direction.
    fn opposite(self) -> Facing {
        match self {
            Facing::North => Facing::South,
            Facing::South => Facing::North,
            Facing::East => Facing::West,
            Facing::West => Facing::East,
        }
    }
}

/// Tile-based movement controller for first-person grid navigation.
///
/// Operates on integer grid coordinates with cardinal facing directions.
/// Optionally references a `Raycaster2D` for collision checking.
pub struct TileWalker {
    x: i32,
    y: i32,
    facing: Facing,
    prev_x: i32,
    prev_y: i32,
    prev_facing: Facing,
    raycaster: Option<Rc<RefCell<Raycaster2D>>>,
}

impl TileWalker {
    /// Creates a new tile walker at (x, y) facing the given direction. 0-based coordinates.
    pub fn new(x: i32, y: i32, facing: Facing) -> Self {
        Self {
            x,
            y,
            facing,
            prev_x: x,
            prev_y: y,
            prev_facing: facing,
            raycaster: None,
        }
    }

    /// Returns the current X coordinate.
    pub fn x(&self) -> i32 {
        self.x
    }

    /// Returns the current Y coordinate.
    pub fn y(&self) -> i32 {
        self.y
    }

    /// Returns the current facing direction.
    pub fn facing(&self) -> Facing {
        self.facing
    }

    /// Sets the position.
    pub fn set_position(&mut self, x: i32, y: i32) {
        self.x = x;
        self.y = y;
    }

    /// Sets the facing direction.
    pub fn set_facing(&mut self, facing: Facing) {
        self.facing = facing;
    }

    /// Attaches a raycaster for collision checking.
    pub fn set_raycaster(&mut self, rc: Rc<RefCell<Raycaster2D>>) {
        self.raycaster = Some(rc);
    }

    /// Checks if a target cell is passable (not blocked by raycaster).
    fn can_move_to(&self, tx: i32, ty: i32) -> bool {
        if let Some(ref rc) = self.raycaster {
            let rc = rc.borrow();
            if tx < 0 || ty < 0 || tx >= rc.width() as i32 || ty >= rc.height() as i32 {
                return false;
            }
            !rc.is_blocked(tx as u32, ty as u32)
        } else {
            true // no collision, always passable
        }
    }

    /// Returns true if the walker can move forward without actually moving.
    pub fn can_move_forward(&self) -> bool {
        self.can_move_to(self.x + self.facing.dx(), self.y + self.facing.dy())
    }

    /// Returns true if the walker can move backward without actually moving.
    pub fn can_move_backward(&self) -> bool {
        let back = self.facing.opposite();
        self.can_move_to(self.x + back.dx(), self.y + back.dy())
    }

    /// Returns true if the walker can strafe left without actually moving.
    pub fn can_strafe_left(&self) -> bool {
        let left = self.facing.turn_left();
        self.can_move_to(self.x + left.dx(), self.y + left.dy())
    }

    /// Returns true if the walker can strafe right without actually moving.
    pub fn can_strafe_right(&self) -> bool {
        let right = self.facing.turn_right();
        self.can_move_to(self.x + right.dx(), self.y + right.dy())
    }

    /// Moves forward one tile. Returns true if the move succeeded.
    pub fn move_forward(&mut self) -> bool {
        let tx = self.x + self.facing.dx();
        let ty = self.y + self.facing.dy();
        if self.can_move_to(tx, ty) {
            self.x = tx;
            self.y = ty;
            true
        } else {
            false
        }
    }

    /// Moves backward one tile. Returns true if the move succeeded.
    pub fn move_backward(&mut self) -> bool {
        let back = self.facing.opposite();
        let tx = self.x + back.dx();
        let ty = self.y + back.dy();
        if self.can_move_to(tx, ty) {
            self.x = tx;
            self.y = ty;
            true
        } else {
            false
        }
    }

    /// Strafes left one tile. Returns true if the move succeeded.
    pub fn strafe_left(&mut self) -> bool {
        let left = self.facing.turn_left();
        let tx = self.x + left.dx();
        let ty = self.y + left.dy();
        if self.can_move_to(tx, ty) {
            self.x = tx;
            self.y = ty;
            true
        } else {
            false
        }
    }

    /// Strafes right one tile. Returns true if the move succeeded.
    pub fn strafe_right(&mut self) -> bool {
        let right = self.facing.turn_right();
        let tx = self.x + right.dx();
        let ty = self.y + right.dy();
        if self.can_move_to(tx, ty) {
            self.x = tx;
            self.y = ty;
            true
        } else {
            false
        }
    }

    /// Turns left (counter-clockwise).
    pub fn turn_left(&mut self) {
        self.facing = self.facing.turn_left();
    }

    /// Turns right (clockwise).
    pub fn turn_right(&mut self) {
        self.facing = self.facing.turn_right();
    }

    /// Turns around (180 degrees).
    pub fn turn_around(&mut self) {
        self.facing = self.facing.opposite();
    }

    /// Snapshots the current state as the previous state for interpolation.
    pub fn begin_move(&mut self) {
        self.prev_x = self.x;
        self.prev_y = self.y;
        self.prev_facing = self.facing;
    }

    /// Returns the interpolated position between previous and current at time `t` in [0, 1].
    pub fn get_interpolated_position(&self, t: f32) -> (f32, f32) {
        let t = t.clamp(0.0, 1.0);
        let ix = self.prev_x as f32 + (self.x - self.prev_x) as f32 * t;
        let iy = self.prev_y as f32 + (self.y - self.prev_y) as f32 * t;
        (ix, iy)
    }

    /// Returns the interpolated angle between previous and current facing at time `t` in [0, 1].
    pub fn get_interpolated_angle(&self, t: f32) -> f32 {
        let t = t.clamp(0.0, 1.0);
        let a1 = self.prev_facing.angle();
        let a2 = self.facing.angle();

        // Shortest-path angle interpolation
        let mut diff = a2 - a1;
        if diff > PI {
            diff -= 2.0 * PI;
        } else if diff < -PI {
            diff += 2.0 * PI;
        }

        a1 + diff * t
    }

    /// Returns the relative direction from the walker to a target tile.
    ///
    /// Returns "front", "back", "left", or "right".
    pub fn get_relative_facing(&self, tx: i32, ty: i32) -> &'static str {
        let dx = tx - self.x;
        let dy = ty - self.y;

        let fwd_x = self.facing.dx();
        let fwd_y = self.facing.dy();

        // Check forward
        if dx == fwd_x && dy == fwd_y {
            return "front";
        }

        // Check backward
        let back = self.facing.opposite();
        if dx == back.dx() && dy == back.dy() {
            return "back";
        }

        // Check left
        let left = self.facing.turn_left();
        if dx == left.dx() && dy == left.dy() {
            return "left";
        }

        // Check right
        let right = self.facing.turn_right();
        if dx == right.dx() && dy == right.dy() {
            return "right";
        }

        // Default for non-adjacent tiles based on dominant direction
        let dot_fwd = dx * fwd_x + dy * fwd_y;
        if dot_fwd > 0 {
            "front"
        } else if dot_fwd < 0 {
            "back"
        } else {
            let cross = fwd_x * dy - fwd_y * dx;
            if cross > 0 {
                "right"
            } else {
                "left"
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;
    use std::rc::Rc;

    #[test]
    fn test_basic_movement() {
        let mut walker = TileWalker::new(3, 3, Facing::North);
        assert!(walker.move_forward());
        assert_eq!(walker.x(), 3);
        assert_eq!(walker.y(), 2);
    }

    #[test]
    fn test_turn_and_move() {
        let mut walker = TileWalker::new(3, 3, Facing::North);
        walker.turn_right();
        assert_eq!(walker.facing(), Facing::East);
        assert!(walker.move_forward());
        assert_eq!(walker.x(), 4);
        assert_eq!(walker.y(), 3);
    }

    #[test]
    fn test_collision_blocks_movement() {
        let rc = Rc::new(RefCell::new(Raycaster2D::new(8, 8)));
        rc.borrow_mut().set_cell(3, 2, 1); // wall north of (3,3)

        let mut walker = TileWalker::new(3, 3, Facing::North);
        walker.set_raycaster(rc);
        assert!(!walker.can_move_forward());
        assert!(!walker.move_forward());
        assert_eq!(walker.y(), 3); // didn't move
    }

    #[test]
    fn test_interpolation() {
        let mut walker = TileWalker::new(2, 2, Facing::East);
        walker.begin_move();
        walker.move_forward();
        let (ix, iy) = walker.get_interpolated_position(0.5);
        assert!((ix - 2.5).abs() < 1e-5);
        assert!((iy - 2.0).abs() < 1e-5);
    }

    #[test]
    fn test_facing_from_str() {
        assert_eq!(Facing::parse("north"), Some(Facing::North));
        assert_eq!(Facing::parse("E"), Some(Facing::East));
        assert_eq!(Facing::parse("SOUTH"), Some(Facing::South));
        assert_eq!(Facing::parse("invalid"), None);
    }

    #[test]
    fn test_strafe() {
        let mut walker = TileWalker::new(3, 3, Facing::North);
        assert!(walker.strafe_left());
        // Facing north, strafe left = west = x-1
        assert_eq!(walker.x(), 2);
        assert_eq!(walker.y(), 3);
    }

    #[test]
    fn test_turn_around() {
        let mut walker = TileWalker::new(1, 1, Facing::North);
        walker.turn_around();
        assert_eq!(walker.facing(), Facing::South);
    }

    #[test]
    fn test_relative_facing() {
        let walker = TileWalker::new(3, 3, Facing::North);
        assert_eq!(walker.get_relative_facing(3, 2), "front"); // north
        assert_eq!(walker.get_relative_facing(3, 4), "back"); // south
        assert_eq!(walker.get_relative_facing(2, 3), "left"); // west when facing north
        assert_eq!(walker.get_relative_facing(4, 3), "right"); // east when facing north
    }
}
