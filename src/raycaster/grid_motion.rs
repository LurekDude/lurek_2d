#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum GridMoveAction {
    Forward,
    Backward,
    Left,
    Right,
}
impl GridMoveAction {
    pub fn parse(token: &str) -> Option<Self> {
        match token {
            "forward" => Some(Self::Forward),
            "back" | "backward" => Some(Self::Backward),
            "left" | "strafe_left" => Some(Self::Left),
            "right" | "strafe_right" => Some(Self::Right),
            _ => None,
        }
    }
}
pub fn dir4_delta(dir: u8, action: GridMoveAction, step: f32) -> (f32, f32) {
    let d = match dir {
        1 => (1.0, 0.0),
        2 => (0.0, 1.0),
        3 => (-1.0, 0.0),
        4 => (0.0, -1.0),
        _ => (1.0, 0.0),
    };
    let (fx, fy) = match action {
        GridMoveAction::Forward => d,
        GridMoveAction::Backward => (-d.0, -d.1),
        GridMoveAction::Left => (d.1, -d.0),
        GridMoveAction::Right => (-d.1, d.0),
    };
    (fx * step, fy * step)
}
pub fn try_move(
    width: u32,
    height: u32,
    px: f32,
    py: f32,
    dx: f32,
    dy: f32,
    is_blocked: impl Fn(u32, u32) -> bool,
) -> (f32, f32, bool) {
    let tx = px + dx;
    let ty = py + dy;
    if !tx.is_finite() || !ty.is_finite() || tx < 0.0 || ty < 0.0 {
        return (px, py, false);
    }
    let gx = tx.floor() as u32;
    let gy = ty.floor() as u32;
    if gx >= width || gy >= height || is_blocked(gx, gy) {
        return (px, py, false);
    }
    (tx, ty, true)
}
