//! Grid movement helpers for dungeon-crawler style 4-direction movement.

/// Camera-relative movement action for 4-directional movement.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum GridMoveAction {
    Forward,
    Backward,
    Left,
    Right,
}

impl GridMoveAction {
    /// Parses Lua-facing action token.
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

/// Returns world-space delta for one movement action at the given dir and step.
///
/// Direction uses dungeon convention: 1=+X, 2=+Y, 3=-X, 4=-Y.
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

/// Attempts movement and returns `(x, y, moved)`.
///
/// Out-of-bounds targets are treated as blocked.
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
