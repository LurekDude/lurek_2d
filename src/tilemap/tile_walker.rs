//! - Cardinal facing direction with angle, delta, and rotation helpers.
//! - Discrete grid walker with forward, backward, and strafe movement.
//! - Previous-state snapshot for smooth frame interpolation of position and heading.
//! - Relative-facing query to classify adjacent tiles as front, back, left, or right.
//! - Passability checks decoupled from actual collision data.

use std::f32::consts::PI;

/// Cardinal facing direction for a grid-aligned entity.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Facing {
    /// Facing toward decreasing Y (up on screen in top-down maps).
    North = 0,
    /// Facing toward increasing X (right on screen).
    East = 1,
    /// Facing toward increasing Y (down on screen).
    South = 2,
    /// Facing toward decreasing X (left on screen).
    West = 3,
}
/// Methods for parsing, converting, and rotating cardinal directions.
impl Facing {
    /// Parse a direction string (`"north"`, `"n"`, etc.); returns `None` on unknown input.
    pub fn parse(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "north" | "n" => Some(Facing::North),
            "east" | "e" => Some(Facing::East),
            "south" | "s" => Some(Facing::South),
            "west" | "w" => Some(Facing::West),
            _ => None,
        }
    }
    /// Return the lowercase canonical name for this direction.
    pub fn to_str(self) -> &'static str {
        match self {
            Facing::North => "north",
            Facing::East => "east",
            Facing::South => "south",
            Facing::West => "west",
        }
    }
    /// Return the heading angle in radians: East=0, South=π/2, West=π, North=3π/2.
    pub fn angle(self) -> f32 {
        match self {
            Facing::North => 3.0 * PI / 2.0,
            Facing::East => 0.0,
            Facing::South => PI / 2.0,
            Facing::West => PI,
        }
    }
    /// Return the X grid delta for one step in this direction: East=+1, West=-1, N/S=0.
    pub fn dx(self) -> i32 {
        match self {
            Facing::East => 1,
            Facing::West => -1,
            _ => 0,
        }
    }
    /// Return the Y grid delta for one step in this direction: South=+1, North=-1, E/W=0.
    pub fn dy(self) -> i32 {
        match self {
            Facing::North => -1,
            Facing::South => 1,
            _ => 0,
        }
    }
    /// Return the direction 90° counter-clockwise from `self`.
    fn turn_left(self) -> Facing {
        match self {
            Facing::North => Facing::West,
            Facing::West => Facing::South,
            Facing::South => Facing::East,
            Facing::East => Facing::North,
        }
    }
    /// Return the direction 90° clockwise from `self`.
    fn turn_right(self) -> Facing {
        match self {
            Facing::North => Facing::East,
            Facing::East => Facing::South,
            Facing::South => Facing::West,
            Facing::West => Facing::North,
        }
    }
    /// Return the direction 180° from `self`.
    fn opposite(self) -> Facing {
        match self {
            Facing::North => Facing::South,
            Facing::South => Facing::North,
            Facing::East => Facing::West,
            Facing::West => Facing::East,
        }
    }
}
/// A discrete grid walker that records its previous state for smooth frame interpolation.
pub struct TileWalker {
    /// Current grid X position.
    x: i32,
    /// Current grid Y position.
    y: i32,
    /// Current facing direction.
    facing: Facing,
    /// Grid X position at the last `begin_move` snapshot.
    prev_x: i32,
    /// Grid Y position at the last `begin_move` snapshot.
    prev_y: i32,
    /// Facing at the last `begin_move` snapshot.
    prev_facing: Facing,
}
/// Grid movement, rotation, interpolation, and relative-facing queries.
impl TileWalker {
    /// Create a `TileWalker` at `(x, y)` facing `facing`; previous state initialised to the same values.
    pub fn new(x: i32, y: i32, facing: Facing) -> Self {
        Self {
            x,
            y,
            facing,
            prev_x: x,
            prev_y: y,
            prev_facing: facing,
        }
    }
    /// Return current grid X. This function is part of the public API.
    pub fn x(&self) -> i32 {
        self.x
    }
    /// Return current grid Y. This function is part of the public API.
    pub fn y(&self) -> i32 {
        self.y
    }
    /// Return current facing direction.
    pub fn facing(&self) -> Facing {
        self.facing
    }
    /// Teleport to `(x, y)` without updating the previous-position snapshot.
    pub fn set_position(&mut self, x: i32, y: i32) {
        self.x = x;
        self.y = y;
    }
    /// Set facing without updating the previous-facing snapshot.
    pub fn set_facing(&mut self, facing: Facing) {
        self.facing = facing;
    }
    /// Internal passability check; always returns `true` — callers override with collision guards before calling movement methods.
    fn can_move_to(&self, _tx: i32, _ty: i32) -> bool {
        true
    }
    /// Return `true` when the tile one step forward is passable.
    pub fn can_move_forward(&self) -> bool {
        self.can_move_to(self.x + self.facing.dx(), self.y + self.facing.dy())
    }
    /// Return `true` when the tile one step backward is passable.
    pub fn can_move_backward(&self) -> bool {
        let back = self.facing.opposite();
        self.can_move_to(self.x + back.dx(), self.y + back.dy())
    }
    /// Return `true` when the tile one step to the left is passable.
    pub fn can_strafe_left(&self) -> bool {
        let left = self.facing.turn_left();
        self.can_move_to(self.x + left.dx(), self.y + left.dy())
    }
    /// Return `true` when the tile one step to the right is passable.
    pub fn can_strafe_right(&self) -> bool {
        let right = self.facing.turn_right();
        self.can_move_to(self.x + right.dx(), self.y + right.dy())
    }
    /// Move one step forward; returns `true` when movement succeeded.
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
    /// Move one step backward; returns `true` when movement succeeded.
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
    /// Strafe one step to the left; returns `true` when movement succeeded.
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
    /// Strafe one step to the right; returns `true` when movement succeeded.
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
    /// Rotate facing 90° counter-clockwise.
    pub fn turn_left(&mut self) {
        self.facing = self.facing.turn_left();
    }
    /// Rotate facing 90° clockwise.
    pub fn turn_right(&mut self) {
        self.facing = self.facing.turn_right();
    }
    /// Rotate facing 180°. This function is part of the public API.
    pub fn turn_around(&mut self) {
        self.facing = self.facing.opposite();
    }
    /// Snapshot current position and facing into `prev_*` for interpolation; call before each discrete move.
    pub fn begin_move(&mut self) {
        self.prev_x = self.x;
        self.prev_y = self.y;
        self.prev_facing = self.facing;
    }
    /// Linearly interpolate between `prev` and current position at blend factor `t` clamped to `[0, 1]`.
    pub fn get_interpolated_position(&self, t: f32) -> (f32, f32) {
        let t = t.clamp(0.0, 1.0);
        let ix = self.prev_x as f32 + (self.x - self.prev_x) as f32 * t;
        let iy = self.prev_y as f32 + (self.y - self.prev_y) as f32 * t;
        (ix, iy)
    }
    /// Interpolate heading angle between previous and current facing at `t`, handling wrap-around correctly.
    pub fn get_interpolated_angle(&self, t: f32) -> f32 {
        let t = t.clamp(0.0, 1.0);
        let a1 = self.prev_facing.angle();
        let a2 = self.facing.angle();
        let mut diff = a2 - a1;
        if diff > PI {
            diff -= 2.0 * PI;
        } else if diff < -PI {
            diff += 2.0 * PI;
        }
        a1 + diff * t
    }
    /// Return `"front"`, `"back"`, `"left"`, or `"right"` describing where `(tx, ty)` is relative to the walker.
    pub fn get_relative_facing(&self, tx: i32, ty: i32) -> &'static str {
        let dx = tx - self.x;
        let dy = ty - self.y;
        let fwd_x = self.facing.dx();
        let fwd_y = self.facing.dy();
        if dx == fwd_x && dy == fwd_y {
            return "front";
        }
        let back = self.facing.opposite();
        if dx == back.dx() && dy == back.dy() {
            return "back";
        }
        let left = self.facing.turn_left();
        if dx == left.dx() && dy == left.dy() {
            return "left";
        }
        let right = self.facing.turn_right();
        if dx == right.dx() && dy == right.dy() {
            return "right";
        }
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
