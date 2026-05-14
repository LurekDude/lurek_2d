//! 2D dynamic lighting system: point/spot/area lights, occlusion, shadows, and blending.
//! Owns the light world, light definitions, falloff curves, attenuation, flicker, blend modes,
//! occluder shapes, shadow filtering, and runtime transitions for light properties.
//! Does not own GPU pipelines — `LightWorld` produces RenderCommand payloads consumed by `src/render/`.
//! Key dependencies: `src/render/` for commands, `src/physics/` for occluder shape sources.

/// Attenuation curve definitions for light intensity decay.
pub mod attenuation;
/// Additive, multiply, and screen blend mode variants for light accumulation.
pub mod blend_mode;
/// Radial and custom falloff mode definitions.
pub mod falloff;
/// Flicker animation config for dynamic light variation.
pub mod flicker;
/// Core `Light2D` definition with all per-light properties.
pub mod light2d;
/// `LightType` enum distinguishing point, spot, and area lights.
pub mod light_type;
/// `LightWorld` accumulator that processes lights and emits render commands.
pub mod light_world;
/// Occluder shape used for shadow casting.
pub mod occluder;
/// Shadow filter quality and radius settings.
pub mod shadow;
/// Tween-style transition helpers for animating light properties.
pub mod transition;
/// Attenuation curve type for light intensity falloff.
pub use attenuation::Attenuation;
/// Blend mode enum for light compositing.
pub use blend_mode::LightBlendMode;
/// Falloff mode enum for radial intensity decay shape.
pub use falloff::FalloffMode;
/// Flicker config struct for animated light variation.
pub use flicker::FlickerConfig;
/// Core 2D light definition with position, color, and all optional properties.
pub use light2d::Light2D;
/// Light type discriminant for point, spot, and area variants.
pub use light_type::LightType;
/// Light world accumulator and normal-map hint types.
pub use light_world::{LightWorld, NormalMapLightHint};
/// Occluder shape for shadow casting by opaque geometry.
pub use occluder::Occluder;
/// Shadow filter settings controlling soft-shadow quality.
pub use shadow::ShadowFilter;
