//! 2D point-light data model — Tier 1 core engine module.
//!
//! Provides `Light2D`, a pure data container describing a circular point light
//! source in 2D space (position, radius, color, intensity, enabled flag).
//! No GPU resources are stored here; the renderer receives light data via
//! `DrawCommand` variants and performs all GPU work after the Lua callback returns.
//!
//! Also provides `LightBlendMode`, `FalloffMode`, `ShadowFilter` enums,
//! `LightType` (Point/Directional/Spot), `Attenuation` coefficients,
//! `FlickerConfig` built-in flicker effects, `Occluder` polygon shadow
//! casters, and `LightWorld` resource pool.
//!
//! ## Tier
//!
//! `light` is a **Tier 1 — Core Engine** module. It may import only `math` and
//! `engine`. It must not import other Tier 1 modules.

/// Custom attenuation coefficients for distance falloff.
pub mod attenuation;
/// How light color mixes with the scene.
pub mod blend_mode;
/// How light intensity decays from center to edge.
pub mod falloff;
/// Built-in flicker effect configuration.
pub mod flicker;
/// 2D point-light data container: position, radius, color, and intensity.
pub mod light2d;
/// Geometric light type: point, directional, or spot.
pub mod light_type;
/// Resource pool and state for the 2D lighting system.
pub mod light_world;
/// Polygon shadow caster that blocks light.
pub mod occluder;
/// Edge quality for shadow boundaries.
pub mod shadow;

pub use attenuation::Attenuation;
pub use blend_mode::LightBlendMode;
pub use falloff::FalloffMode;
pub use flicker::FlickerConfig;
pub use light2d::Light2D;
pub use light_type::LightType;
pub use light_world::LightWorld;
pub use occluder::Occluder;
pub use shadow::ShadowFilter;
