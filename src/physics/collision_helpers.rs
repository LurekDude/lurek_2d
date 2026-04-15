//! Lightweight stateless geometric collision helpers.
//!
//! These functions perform fast, pure-math overlap tests without a physics world.
//! Intended for use cases like RPG, puzzle, or visual-novel games that only need
//! simple overlap detection rather than full rigid-body simulation.
//!
//! All functions are pure (no side effects). None import mlua — they are domain
//! logic only. The Lua binding lives in `src/lua_api/collision_api.rs`.

/// Returns `true` when two axis-aligned bounding boxes overlap.
///
/// Each box is specified by its top-left origin and size:
/// `(ax, ay, aw, ah)` for box A and `(bx, by, bw, bh)` for box B.
pub fn test_aabb(
    ax: f32,
    ay: f32,
    aw: f32,
    ah: f32,
    bx: f32,
    by: f32,
    bw: f32,
    bh: f32,
) -> bool {
    ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
}

/// Returns `true` when two circles overlap.
///
/// Each circle is specified by its centre `(ax, ay)` / `(bx, by)` and radius `ar` / `br`.
pub fn test_circles(ax: f32, ay: f32, ar: f32, bx: f32, by: f32, br: f32) -> bool {
    let dx = ax - bx;
    let dy = ay - by;
    let dist_sq = dx * dx + dy * dy;
    let r_sum = ar + br;
    dist_sq < r_sum * r_sum
}

/// Returns `true` when point `(px, py)` lies inside the AABB at origin `(ax, ay)` with size `(aw, ah)`.
pub fn test_point_aabb(px: f32, py: f32, ax: f32, ay: f32, aw: f32, ah: f32) -> bool {
    px >= ax && px < ax + aw && py >= ay && py < ay + ah
}

/// Returns `true` when a circle (centre `(cx, cy)`, radius `cr`) overlaps the AABB.
pub fn test_circle_aabb(cx: f32, cy: f32, cr: f32, ax: f32, ay: f32, aw: f32, ah: f32) -> bool {
    let closest_x = cx.clamp(ax, ax + aw);
    let closest_y = cy.clamp(ay, ay + ah);
    let dx = cx - closest_x;
    let dy = cy - closest_y;
    dx * dx + dy * dy < cr * cr
}
