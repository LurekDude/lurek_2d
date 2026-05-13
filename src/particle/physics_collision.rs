use crate::particle::ParticleSystem;
use crate::physics::World;
pub fn collide_with_world(
    system: &mut ParticleSystem,
    world: &World,
    probe_radius: f32,
    restitution: f32,
) {
    let probe = probe_radius.max(0.5);
    let bounce = restitution.clamp(0.0, 1.0);
    for p in &mut system.particles {
        let wx = system.emitter_x + p.x;
        let wy = system.emitter_y + p.y;
        let hits = world.query_aabb(wx - probe, wy - probe, probe * 2.0, probe * 2.0);
        if !hits.is_empty() {
            p.vx = -p.vx * bounce;
            p.vy = -p.vy * bounce;
            p.x += p.vx * 0.016;
            p.y += p.vy * 0.016;
        }
    }
}
