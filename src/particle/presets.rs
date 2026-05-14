
use crate::particle::{EmissionShape, ParticleConfig};
/// Return a `ParticleConfig` producing an upward fire effect with turbulence and RGB fade.
pub fn fire() -> ParticleConfig {
    ParticleConfig {
        emission_rate: 80.0,
        lifetime_min: 0.25,
        lifetime_max: 0.8,
        speed_min: 20.0,
        speed_max: 90.0,
        direction: -std::f32::consts::FRAC_PI_2,
        spread: 0.8,
        gravity_y: -18.0,
        sizes: vec![8.0, 5.0, 1.0],
        colors: vec![
            [1.0, 0.85, 0.35, 1.0],
            [1.0, 0.35, 0.1, 0.8],
            [0.25, 0.05, 0.0, 0.0],
        ],
        emission_shape: EmissionShape::Circle {
            radius: 6.0,
            fill: true,
        },
        turbulence: 20.0,
        ..ParticleConfig::default()
    }
}
/// Return a `ParticleConfig` producing rising smoke with growing size and fading alpha.
pub fn smoke() -> ParticleConfig {
    ParticleConfig {
        emission_rate: 30.0,
        lifetime_min: 1.0,
        lifetime_max: 2.5,
        speed_min: 5.0,
        speed_max: 25.0,
        direction: -std::f32::consts::FRAC_PI_2,
        spread: 1.2,
        gravity_y: -8.0,
        sizes: vec![6.0, 12.0, 18.0],
        colors: vec![
            [0.2, 0.2, 0.2, 0.7],
            [0.3, 0.3, 0.3, 0.45],
            [0.4, 0.4, 0.4, 0.0],
        ],
        emission_shape: EmissionShape::Circle {
            radius: 10.0,
            fill: true,
        },
        drag: 0.03,
        ..ParticleConfig::default()
    }
}
/// Return a `ParticleConfig` producing fast downward rain streaks.
pub fn rain() -> ParticleConfig {
    ParticleConfig {
        emission_rate: 220.0,
        lifetime_min: 0.4,
        lifetime_max: 0.9,
        speed_min: 260.0,
        speed_max: 380.0,
        direction: std::f32::consts::FRAC_PI_2,
        spread: 0.15,
        sizes: vec![2.0, 2.0],
        colors: vec![[0.7, 0.85, 1.0, 0.8], [0.7, 0.85, 1.0, 0.0]],
        ..ParticleConfig::default()
    }
}
/// Return a `ParticleConfig` producing slow-drifting white snowflakes with turbulence.
pub fn snow() -> ParticleConfig {
    ParticleConfig {
        emission_rate: 60.0,
        lifetime_min: 2.5,
        lifetime_max: 5.0,
        speed_min: 12.0,
        speed_max: 35.0,
        direction: std::f32::consts::FRAC_PI_2,
        spread: 0.7,
        sizes: vec![2.0, 3.0, 1.5],
        colors: vec![[1.0, 1.0, 1.0, 0.95], [1.0, 1.0, 1.0, 0.0]],
        turbulence: 8.0,
        ..ParticleConfig::default()
    }
}
/// Return a `ParticleConfig` for a burst-only spark explosion; set `emission_rate > 0` or call `emit` manually.
pub fn sparks() -> ParticleConfig {
    ParticleConfig {
        emission_rate: 0.0,
        lifetime_min: 0.12,
        lifetime_max: 0.35,
        speed_min: 140.0,
        speed_max: 260.0,
        spread: std::f32::consts::PI,
        sizes: vec![3.0, 1.0],
        colors: vec![[1.0, 0.9, 0.5, 1.0], [1.0, 0.25, 0.05, 0.0]],
        ..ParticleConfig::default()
    }
}
