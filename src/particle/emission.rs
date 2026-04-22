//! Particle spawn offset calculations for area distribution and emission shapes.

use super::config::{AreaDistribution, EmissionShape, ParticleConfig};
use super::math::{rand_normal, rand_range};

/// Compute an emission offset `(dx, dy)` based on the config's area distribution.
///
/// # Parameters
/// - `config` â€” `&ParticleConfig`.
///
/// # Returns
/// `(f32, f32)`.
pub fn emission_offset(config: &ParticleConfig) -> (f32, f32) {
    let (dx, dy) = match config.area_distribution {
        AreaDistribution::None => (0.0, 0.0),
        AreaDistribution::Uniform => {
            let x = rand_range(-config.area_width * 0.5, config.area_width * 0.5);
            let y = rand_range(-config.area_height * 0.5, config.area_height * 0.5);
            (x, y)
        }
        AreaDistribution::Normal => {
            let x = (rand_normal() * 0.25).clamp(-0.5, 0.5) * config.area_width;
            let y = (rand_normal() * 0.25).clamp(-0.5, 0.5) * config.area_height;
            (x, y)
        }
        AreaDistribution::Ellipse => {
            let angle = fastrand::f32() * 2.0 * std::f32::consts::PI;
            let r = fastrand::f32().sqrt();
            let x = angle.cos() * r * config.area_width * 0.5;
            let y = angle.sin() * r * config.area_height * 0.5;
            (x, y)
        }
        AreaDistribution::BorderEllipse => {
            let angle = fastrand::f32() * 2.0 * std::f32::consts::PI;
            let x = angle.cos() * config.area_width * 0.5;
            let y = angle.sin() * config.area_height * 0.5;
            (x, y)
        }
        AreaDistribution::BorderRectangle => {
            let perimeter = 2.0 * config.area_width + 2.0 * config.area_height;
            if perimeter < f32::EPSILON {
                return (0.0, 0.0);
            }
            let t = fastrand::f32() * perimeter;
            let hw = config.area_width * 0.5;
            let hh = config.area_height * 0.5;
            if t < config.area_width {
                (t - hw, -hh)
            } else if t < config.area_width + config.area_height {
                (hw, t - config.area_width - hh)
            } else if t < 2.0 * config.area_width + config.area_height {
                (hw - (t - config.area_width - config.area_height), hh)
            } else {
                (-hw, hh - (t - 2.0 * config.area_width - config.area_height))
            }
        }
    };

    // Rotate by area angle
    if config.area_angle.abs() > f32::EPSILON {
        let cos_a = config.area_angle.cos();
        let sin_a = config.area_angle.sin();
        (dx * cos_a - dy * sin_a, dx * sin_a + dy * cos_a)
    } else {
        (dx, dy)
    }
}

/// Compute an emission offset `(dx, dy)` based on the emission shape.
///
/// # Parameters
/// - `shape` â€” `&EmissionShape`.
///
/// # Returns
/// `(f32, f32)`.
pub fn emission_shape_offset(shape: &EmissionShape) -> (f32, f32) {
    match shape {
        EmissionShape::Point => (0.0, 0.0),
        EmissionShape::Circle { radius, fill } => {
            let angle = fastrand::f32() * 2.0 * std::f32::consts::PI;
            let r = if *fill {
                fastrand::f32().sqrt() * radius
            } else {
                *radius
            };
            (angle.cos() * r, angle.sin() * r)
        }
        EmissionShape::Rectangle { width, height } => {
            let x = rand_range(-width * 0.5, *width * 0.5);
            let y = rand_range(-height * 0.5, *height * 0.5);
            (x, y)
        }
        EmissionShape::Ring {
            inner_radius,
            outer_radius,
        } => {
            let angle = fastrand::f32() * 2.0 * std::f32::consts::PI;
            // Uniform distribution within ring by sampling radiusÂ˛
            let r_sq = rand_range(inner_radius * inner_radius, outer_radius * outer_radius);
            let r = r_sq.sqrt();
            (angle.cos() * r, angle.sin() * r)
        }
        EmissionShape::Line { length, angle } => {
            let t = rand_range(-0.5, 0.5);
            (t * length * angle.cos(), t * length * angle.sin())
        }
        EmissionShape::Cone {
            radius,
            angle,
            spread,
        } => {
            let a = angle + rand_range(-spread, *spread);
            let r = fastrand::f32().sqrt() * radius;
            (a.cos() * r, a.sin() * r)
        }
        EmissionShape::Star {
            points,
            outer_radius,
            inner_radius,
        } => {
            // Pick a random point on the star border by choosing a random angular segment
            let n = (*points).max(3) as f32;
            let step = std::f32::consts::PI / n; // angle per half-segment
            let segment = fastrand::u32(0..*points * 2); // each point has 2 half-edges
            let t = fastrand::f32(); // interpolate along the half-edge
            let a0 = segment as f32 * step;
            let a1 = a0 + step;
            let r0 = if segment % 2 == 0 {
                *outer_radius
            } else {
                *inner_radius
            };
            let r1 = if segment % 2 == 0 {
                *inner_radius
            } else {
                *outer_radius
            };
            // Lerp in Cartesian space along the star edge
            let x0 = a0.cos() * r0;
            let y0 = a0.sin() * r0;
            let x1 = a1.cos() * r1;
            let y1 = a1.sin() * r1;
            (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)
        }
        EmissionShape::Spiral {
            revolutions,
            radius,
        } => {
            // Archimedean spiral: r grows linearly with angle
            let max_angle = *revolutions * 2.0 * std::f32::consts::PI;
            let t = fastrand::f32();
            let angle = t * max_angle;
            let r = t * radius;
            (angle.cos() * r, angle.sin() * r)
        }
        // Custom shape: the Lua API layer applies the actual offset via callback.
        // Return (0, 0) here as a placeholder; the API layer overwrites these after emission.
        EmissionShape::Custom { .. } => (0.0, 0.0),
    }
}
