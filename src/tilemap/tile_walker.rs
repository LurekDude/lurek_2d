use std::f32::consts::PI;
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum Facing {
    North = 0,
    East = 1,
    South = 2,
    West = 3,
}
impl Facing {
    pub fn parse(s: &str) -> Option<Self> {
        match s.to_lowercase().as_str() {
            "north" | "n" => Some(Facing::North),
            "east" | "e" => Some(Facing::East),
            "south" | "s" => Some(Facing::South),
            "west" | "w" => Some(Facing::West),
            _ => None,
        }
    }
    pub fn to_str(self) -> &'static str {
        match self {
            Facing::North => "north",
            Facing::East => "east",
            Facing::South => "south",
            Facing::West => "west",
        }
    }
    pub fn angle(self) -> f32 {
        match self {
            Facing::North => 3.0 * PI / 2.0,
            Facing::East => 0.0,
            Facing::South => PI / 2.0,
            Facing::West => PI,
        }
    }
    pub fn dx(self) -> i32 {
        match self {
            Facing::East => 1,
            Facing::West => -1,
            _ => 0,
        }
    }
    pub fn dy(self) -> i32 {
        match self {
            Facing::North => -1,
            Facing::South => 1,
            _ => 0,
        }
    }
    fn turn_left(self) -> Facing {
        match self {
            Facing::North => Facing::West,
            Facing::West => Facing::South,
            Facing::South => Facing::East,
            Facing::East => Facing::North,
        }
    }
    fn turn_right(self) -> Facing {
        match self {
            Facing::North => Facing::East,
            Facing::East => Facing::South,
            Facing::South => Facing::West,
            Facing::West => Facing::North,
        }
    }
    fn opposite(self) -> Facing {
        match self {
            Facing::North => Facing::South,
            Facing::South => Facing::North,
            Facing::East => Facing::West,
            Facing::West => Facing::East,
        }
    }
}
pub struct TileWalker {
    x: i32,
    y: i32,
    facing: Facing,
    prev_x: i32,
    prev_y: i32,
    prev_facing: Facing,
}
impl TileWalker {
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
    pub fn x(&self) -> i32 {
        self.x
    }
    pub fn y(&self) -> i32 {
        self.y
    }
    pub fn facing(&self) -> Facing {
        self.facing
    }
    pub fn set_position(&mut self, x: i32, y: i32) {
        self.x = x;
        self.y = y;
    }
    pub fn set_facing(&mut self, facing: Facing) {
        self.facing = facing;
    }
    fn can_move_to(&self, _tx: i32, _ty: i32) -> bool {
        true
    }
    pub fn can_move_forward(&self) -> bool {
        self.can_move_to(self.x + self.facing.dx(), self.y + self.facing.dy())
    }
    pub fn can_move_backward(&self) -> bool {
        let back = self.facing.opposite();
        self.can_move_to(self.x + back.dx(), self.y + back.dy())
    }
    pub fn can_strafe_left(&self) -> bool {
        let left = self.facing.turn_left();
        self.can_move_to(self.x + left.dx(), self.y + left.dy())
    }
    pub fn can_strafe_right(&self) -> bool {
        let right = self.facing.turn_right();
        self.can_move_to(self.x + right.dx(), self.y + right.dy())
    }
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
    pub fn turn_left(&mut self) {
        self.facing = self.facing.turn_left();
    }
    pub fn turn_right(&mut self) {
        self.facing = self.facing.turn_right();
    }
    pub fn turn_around(&mut self) {
        self.facing = self.facing.opposite();
    }
    pub fn begin_move(&mut self) {
        self.prev_x = self.x;
        self.prev_y = self.y;
        self.prev_facing = self.facing;
    }
    pub fn get_interpolated_position(&self, t: f32) -> (f32, f32) {
        let t = t.clamp(0.0, 1.0);
        let ix = self.prev_x as f32 + (self.x - self.prev_x) as f32 * t;
        let iy = self.prev_y as f32 + (self.y - self.prev_y) as f32 * t;
        (ix, iy)
    }
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
