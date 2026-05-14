//! Grid-aligned movement helpers for dungeon-crawler-style player movement.
//! Provides four-directional move deltas relative to a player's facing direction
//! and a bounded try_move helper that checks tile collisions. Used by game scripts
//! via `lurek.raycaster`. Does not own physics or continuous collision detection.

/// Discrete movement intent for a single step on the grid.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum GridMoveAction {
    /// Move one step in the current facing direction.
    Forward,
    /// Move one step opposite to the current facing direction.
    Backward,
    /// Strafe one step to the left of the current facing direction.
    Left,
    /// Strafe one step to the right of the current facing direction.
    Right,
}
impl GridMoveAction {
    /// Parse a string token into a `GridMoveAction`; return `None` for unrecognised tokens.
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
/// Return the world-space `(dx, dy)` delta for `action` given facing direction `dir` (1=E,2=S,3=W,4=N) scaled by `step`.
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
/// Attempt to move from `(px, py)` by `(dx, dy)` on a grid of `width × height`;
/// return the new position and `true` on success, or the original position and `false` if blocked.
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
