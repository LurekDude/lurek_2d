#[allow(clippy::too_many_arguments)]
pub fn test_aabb(ax: f32, ay: f32, aw: f32, ah: f32, bx: f32, by: f32, bw: f32, bh: f32) -> bool {
    ax < bx + bw && ax + aw > bx && ay < by + bh && ay + ah > by
}
pub fn test_circles(ax: f32, ay: f32, ar: f32, bx: f32, by: f32, br: f32) -> bool {
    let dx = ax - bx;
    let dy = ay - by;
    let dist_sq = dx * dx + dy * dy;
    let r_sum = ar + br;
    dist_sq < r_sum * r_sum
}
pub fn test_point_aabb(px: f32, py: f32, ax: f32, ay: f32, aw: f32, ah: f32) -> bool {
    px >= ax && px < ax + aw && py >= ay && py < ay + ah
}
pub fn test_circle_aabb(cx: f32, cy: f32, cr: f32, ax: f32, ay: f32, aw: f32, ah: f32) -> bool {
    let closest_x = cx.clamp(ax, ax + aw);
    let closest_y = cy.clamp(ay, ay + ah);
    let dx = cx - closest_x;
    let dy = cy - closest_y;
    dx * dx + dy * dy < cr * cr
}
