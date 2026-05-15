//! `lurek.math` -- Math bindings for vectors, splines, random generators, transforms, curves, tweens, spatial queries, noise generation, circles, AABB trees, rectangle packing, easing, geometry, polygon operations, colors, and scalar helpers.

use super::SharedState;
use crate::math::color::hsl_to_rgb;
use crate::math::color::{gamma_to_linear, linear_to_gamma};
use crate::math::easing;
use crate::math::geometry;
use crate::math::noise_functions;
use crate::math::polygon;
use crate::math::AabbTree;
use crate::math::BezierCurve;
use crate::math::Circle;
use crate::math::NoiseGenerator;
use crate::math::RandomGenerator;
use crate::math::Rect;
use crate::math::RectPacker;
use crate::math::SpatialHash;
use crate::math::Transform;
use crate::math::Tween;
use crate::math::Vec2;
use crate::math::Vec3;
use crate::math::{clamp, inverse_lerp, lerp, remap, sign, smoothstep};
use crate::math::{CatmullRomSpline, HermiteSpline};
use crate::math::{DistType, FractalType, MapGenOptions, NoiseKind};
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Lua-side wrapper for a 2D vector.
pub struct LuaVec2 {
    /// Wrapped 2D vector value.
    pub inner: Vec2,
}
/// Provides Lua fields and methods for 2D vector math.
impl LuaUserData for LuaVec2 {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        /// X component of the vector.
        fields.add_field_method_get("x", |_, this| Ok(this.inner.x as f64));
        fields.add_field_method_set("x", |_, this, v: f64| {
            this.inner.x = v as f32;
            Ok(())
        });
        /// Y component of the vector.
        fields.add_field_method_get("y", |_, this| Ok(this.inner.y as f64));
        fields.add_field_method_set("y", |_, this, v: f64| {
            this.inner.y = v as f32;
            Ok(())
        });
    }
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- dot --
        /// Returns the dot product with another vector.
        /// @param | other | LVec2 | Other vector handle.
        /// @return | number | Dot product.
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner.dot(o.inner) as f64)
        });
        // -- length --
        /// Returns this vector length.
        /// @return | number | Vector length.
        methods.add_method("length", |_, this, ()| Ok(this.inner.length() as f64));
        // -- x --
        /// Returns this vector x component.
        /// @return | number | X component.
        methods.add_method("x", |_, this, ()| Ok(this.inner.x as f64));
        // -- y --
        /// Returns this vector y component.
        /// @return | number | Y component.
        methods.add_method("y", |_, this, ()| Ok(this.inner.y as f64));
        // -- lengthSquared --
        /// Returns this vector squared length.
        /// @return | number | Squared vector length.
        methods.add_method("lengthSquared", |_, this, ()| {
            Ok(this.inner.length_squared() as f64)
        });
        // -- normalize --
        /// Returns a normalized copy of this vector.
        /// @return | LVec2 | Normalized vector handle.
        methods.add_method("normalize", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.normalize(),
            })
        });
        // -- normalized --
        /// Returns a normalized copy of this vector.
        /// @return | LVec2 | Normalized vector handle.
        methods.add_method("normalized", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.normalize(),
            })
        });
        // -- lerp --
        /// Returns a vector interpolated toward another vector.
        /// @param | other | LVec2 | Target vector handle.
        /// @param | t | number | Interpolation factor.
        /// @return | LVec2 | Interpolated vector handle.
        methods.add_method("lerp", |lua, this, (other, t): (LuaAnyUserData, f64)| {
            let o = other.borrow::<LuaVec2>()?;
            lua.create_userdata(LuaVec2 {
                inner: this.inner.lerp(o.inner, t as f32),
            })
        });
        // -- distance --
        /// Returns distance to another vector.
        /// @param | other | LVec2 | Other vector handle.
        /// @return | number | Distance.
        methods.add_method("distance", |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner.distance(o.inner) as f64)
        });
        // -- angle --
        /// Returns this vector angle.
        /// @return | number | Angle in radians.
        methods.add_method("angle", |_, this, ()| Ok(this.inner.angle() as f64));
        // -- rotate --
        /// Returns this vector rotated by an angle.
        /// @param | angle | number | Rotation angle in radians.
        /// @return | LVec2 | Rotated vector handle.
        methods.add_method("rotate", |lua, this, angle: f64| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.rotate(angle as f32),
            })
        });
        // -- perpendicular --
        /// Returns a perpendicular vector.
        /// @return | LVec2 | Perpendicular vector handle.
        methods.add_method("perpendicular", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.perpendicular(),
            })
        });
        // -- cross --
        /// Returns the scalar 2D cross product with another vector.
        /// @param | other | LVec2 | Other vector handle.
        /// @return | number | Cross product.
        methods.add_method("cross", |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner.cross(o.inner) as f64)
        });
        // -- fromAngle --
        /// Creates a unit vector from an angle.
        /// @param | radians | number | Angle in radians.
        /// @return | LVec2 | New vector handle.
        methods.add_function("fromAngle", |lua, radians: f64| {
            lua.create_userdata(LuaVec2 {
                inner: Vec2::from_angle(radians as f32),
            })
        });
        // -- reflect --
        /// Returns this vector reflected around a normal vector.
        /// @param | normal | LVec2 | Normal vector handle.
        /// @return | LVec2 | Reflected vector handle.
        methods.add_method("reflect", |lua, this, normal: LuaAnyUserData| {
            let n = normal.borrow::<LuaVec2>()?;
            lua.create_userdata(LuaVec2 {
                inner: this.inner.reflect(n.inner),
            })
        });
        methods.add_meta_method(LuaMetaMethod::Add, |lua, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            lua.create_userdata(LuaVec2 {
                inner: this.inner + o.inner,
            })
        });
        methods.add_meta_method(LuaMetaMethod::Sub, |lua, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            lua.create_userdata(LuaVec2 {
                inner: this.inner - o.inner,
            })
        });
        methods.add_meta_method(LuaMetaMethod::Mul, |lua, this, scalar: f64| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner * scalar as f32,
            })
        });
        methods.add_meta_method(LuaMetaMethod::Unm, |lua, this, ()| {
            lua.create_userdata(LuaVec2 { inner: -this.inner })
        });
        methods.add_meta_method(LuaMetaMethod::Eq, |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner == o.inner)
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("Vec2({}, {})", this.inner.x, this.inner.y))
        });
        // -- type --
        /// Returns the Lua-visible type name for this vector handle.
        /// @return | string | The string `LVec2`.
        methods.add_method("type", |_, _, ()| Ok("LVec2"));
        // -- typeOf --
        /// Returns whether this vector handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LVec2` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LVec2" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a 3D vector.
pub struct LuaVec3 {
    /// Wrapped 3D vector value.
    pub inner: Vec3,
}
/// Provides Lua fields and methods for 3D vector math.
impl LuaUserData for LuaVec3 {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        /// X component of the vector.
        fields.add_field_method_get("x", |_, this| Ok(this.inner.x));
        fields.add_field_method_set("x", |_, this, v: f32| {
            this.inner.x = v;
            Ok(())
        });
        /// Y component of the vector.
        fields.add_field_method_get("y", |_, this| Ok(this.inner.y));
        fields.add_field_method_set("y", |_, this, v: f32| {
            this.inner.y = v;
            Ok(())
        });
        /// Z component of the vector.
        fields.add_field_method_get("z", |_, this| Ok(this.inner.z));
        fields.add_field_method_set("z", |_, this, v: f32| {
            this.inner.z = v;
            Ok(())
        });
    }
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- length --
        /// Returns this vector length.
        /// @return | number | Vector length.
        methods.add_method("length", |_, this, ()| Ok(this.inner.length()));
        // -- lengthSquared --
        /// Returns this vector squared length.
        /// @return | number | Squared vector length.
        methods.add_method("lengthSquared", |_, this, ()| {
            Ok(this.inner.length_squared())
        });
        // -- normalize --
        /// Returns a normalized copy of this vector.
        /// @return | LVec3 | Normalized vector handle.
        methods.add_method("normalize", |lua, this, ()| {
            lua.create_userdata(LuaVec3 {
                inner: this.inner.normalize(),
            })
        });
        // -- dot --
        /// Returns the dot product with another vector.
        /// @param | other | LVec3 | Other vector handle.
        /// @return | number | Dot product.
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            Ok(this.inner.dot(v.inner))
        });
        // -- cross --
        /// Returns the 3D cross product with another vector.
        /// @param | other | LVec3 | Other vector handle.
        /// @return | LVec3 | Cross product vector handle.
        methods.add_method("cross", |lua, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner.cross(v.inner),
            })
        });
        // -- lerp --
        /// Returns a vector interpolated toward another vector.
        /// @param | other | LVec3 | Target vector handle.
        /// @param | t | number | Interpolation factor.
        /// @return | LVec3 | Interpolated vector handle.
        methods.add_method("lerp", |lua, this, (other, t): (LuaAnyUserData, f32)| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner.lerp(v.inner, t),
            })
        });
        // -- distance --
        /// Returns distance to another vector.
        /// @param | other | LVec3 | Other vector handle.
        /// @return | number | Distance.
        methods.add_method("distance", |_, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            Ok(this.inner.distance(v.inner))
        });
        // -- add --
        /// Returns the sum with another vector.
        /// @param | other | LVec3 | Other vector handle.
        /// @return | LVec3 | Sum vector handle.
        methods.add_method("add", |lua, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner + v.inner,
            })
        });
        // -- sub --
        /// Returns the difference from another vector.
        /// @param | other | LVec3 | Other vector handle.
        /// @return | LVec3 | Difference vector handle.
        methods.add_method("sub", |lua, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner - v.inner,
            })
        });
        // -- scale --
        /// Returns this vector multiplied by a scalar.
        /// @param | s | number | Scale factor.
        /// @return | LVec3 | Scaled vector handle.
        methods.add_method("scale", |lua, this, s: f32| {
            lua.create_userdata(LuaVec3 {
                inner: this.inner * s,
            })
        });
        // -- splat --
        /// Creates a vector with all components set to one value.
        /// @param | v | number | Component value.
        /// @return | LVec3 | New vector handle.
        methods.add_function("splat", |lua, v: f32| {
            lua.create_userdata(LuaVec3 {
                inner: Vec3::splat(v),
            })
        });
        // -- type --
        /// Returns the Lua-visible type name for this vector handle.
        /// @return | string | The string `LVec3`.
        methods.add_method("type", |_, _, ()| Ok("LVec3"));
        // -- typeOf --
        /// Returns whether this vector handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LVec3` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LVec3" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a Catmull-Rom spline.
pub struct LuaCatmullRom {
    /// Wrapped Catmull-Rom spline data.
    inner: CatmullRomSpline,
}
/// Provides Lua methods for Catmull-Rom spline sampling and point edits.
impl LuaUserData for LuaCatmullRom {
    #[allow(clippy::map_identity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- sample --
        /// Samples the spline at normalized parameter `t`.
        /// @param | t | number | Normalized spline parameter.
        /// @return | number | Sample x coordinate.
        /// @return | number | Sample y coordinate.
        methods.add_method("sample", |_, this, t: f32| {
            let (x, y) = this.inner.sample(t);
            Ok((x, y))
        });
        // -- sampleSegment --
        /// Samples one spline segment at local parameter `t`.
        /// @param | seg | integer | Zero-based segment index.
        /// @param | t | number | Segment-local parameter.
        /// @return | number | Sample x coordinate.
        /// @return | number | Sample y coordinate.
        methods.add_method("sampleSegment", |_, this, (seg, t): (usize, f32)| {
            let (x, y) = this.inner.sample_segment(seg, t);
            Ok((x, y))
        });
        // -- len --
        /// Returns the number of points in the spline.
        /// @return | integer | Point count.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        // -- addPoint --
        /// Adds a point to the spline.
        /// @param | x | number | Point x coordinate.
        /// @param | y | number | Point y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addPoint", |_, this, (x, y): (f32, f32)| {
            this.inner.add_point((x, y));
            Ok(())
        });
        // -- removePoint --
        /// Removes a point by zero-based index and returns its coordinates.
        /// @param | idx | integer | Zero-based point index.
        /// @return | number | Removed point x coordinate.
        /// @return | number | Removed point y coordinate.
        methods.add_method_mut("removePoint", |_, this, idx: usize| {
            this.inner
                .remove_point(idx)
                .map(|(x, y)| (x, y))
                .ok_or_else(|| LuaError::RuntimeError("index out of bounds".into()))
        });
            // -- type --
            /// Returns the Lua-visible type name for this spline handle.
            /// @return | string | The string `LCatmullRom`.
        methods.add_method("type", |_, _, ()| Ok("LCatmullRom"));
            // -- typeOf --
            /// Returns whether this spline handle matches a supported type name.
            /// @param | name | string | Type name to compare against `LCatmullRom` and `Object`.
            /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCatmullRom" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a Hermite spline.
pub struct LuaHermite {
    /// Wrapped Hermite spline data.
    inner: HermiteSpline,
}
/// Provides Lua methods for Hermite spline sampling.
impl LuaUserData for LuaHermite {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- sample --
        /// Samples the spline at normalized parameter `t`.
        /// @param | t | number | Normalized spline parameter.
        /// @return | number | Sample x coordinate.
        /// @return | number | Sample y coordinate.
        methods.add_method("sample", |_, this, t: f32| {
            let (x, y) = this.inner.sample(t);
            Ok((x, y))
        });
        // -- type --
        /// Returns the Lua-visible type name for this spline handle.
        /// @return | string | The string `LHermite`.
        methods.add_method("type", |_, _, ()| Ok("LHermite"));
        // -- typeOf --
        /// Returns whether this spline handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LHermite` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHermite" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a deterministic random generator.
pub struct LuaRandomGenerator {
    /// Wrapped random generator state.
    inner: RandomGenerator,
}
/// Provides Lua methods for random generation and seed/state control.
impl LuaUserData for LuaRandomGenerator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- random --
        /// Returns a random floating-point value from the generator.
        /// @return | number | Random value.
        methods.add_method_mut("random", |_, this, ()| Ok(this.inner.random()));
        // -- randomFloat --
        /// Returns a random floating-point value in a range.
        /// @param | min | number | Minimum value.
        /// @param | max | number | Maximum value.
        /// @return | number | Random value in range.
        methods.add_method_mut("randomFloat", |_, this, (min, max): (f64, f64)| {
            Ok(this.inner.random_float(min, max))
        });
        // -- randomInt --
        /// Returns a random integer in a range.
        /// @param | min | integer | Minimum value.
        /// @param | max | integer | Maximum value.
        /// @return | integer | Random integer in range.
        methods.add_method_mut("randomInt", |_, this, (min, max): (i64, i64)| {
            Ok(this.inner.random_int(min, max))
        });
        // -- randomNormal --
        /// Returns a normally distributed random value.
        /// @param | stddev | number | Optional standard deviation, defaulting to 1.0.
        /// @param | mean | number | Optional mean, defaulting to 0.0.
        /// @return | number | Random normal value.
        methods.add_method_mut(
            "randomNormal",
            |_, this, (stddev, mean): (Option<f64>, Option<f64>)| {
                Ok(this
                    .inner
                    .random_normal(stddev.unwrap_or(1.0), mean.unwrap_or(0.0)))
            },
        );
        // -- getSeed --
        /// Returns this generator seed.
        /// @return | integer | Seed value.
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.get_seed()));
        // -- setSeed --
        /// Resets this generator to a seed value.
        /// @param | seed | integer | Seed value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSeed", |_, this, seed: u64| {
            this.inner.set_seed(seed);
            Ok(())
        });
        // -- getState --
        /// Returns this generator serialized state string.
        /// @return | string | Generator state.
        methods.add_method("getState", |_, this, ()| Ok(this.inner.get_state()));
        // -- setState --
        /// Restores this generator from a serialized state string.
        /// @param | state | string | Generator state string.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setState", |_, this, state: String| {
            this.inner.set_state(&state).map_err(LuaError::external)?;
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this random generator handle.
        /// @return | string | The string `LRandomGenerator`.
        methods.add_method("type", |_, _, ()| Ok("LRandomGenerator"));
        // -- typeOf --
        /// Returns whether this random generator handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LRandomGenerator` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LRandomGenerator" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a 2D transform matrix.
pub struct LuaTransform {
    /// Wrapped transform value.
    inner: Transform,
}
/// Provides Lua methods for transform composition and coordinate conversion.
impl LuaUserData for LuaTransform {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- translate --
        /// Applies a translation to this transform.
        /// @param | dx | number | X translation.
        /// @param | dy | number | Y translation.
        /// @return | nil | No value is returned.
        methods.add_method_mut("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.translate(dx, dy);
            Ok(())
        });
        // -- rotate --
        /// Applies a rotation to this transform.
        /// @param | angle | number | Rotation angle.
        /// @return | nil | No value is returned.
        methods.add_method_mut("rotate", |_, this, angle: f32| {
            this.inner.rotate(angle);
            Ok(())
        });
        // -- scale --
        /// Applies scale to this transform.
        /// @param | sx | number | X scale.
        /// @param | sy | number | Optional Y scale, defaulting to `sx`.
        /// @return | nil | No value is returned.
        methods.add_method_mut("scale", |_, this, (sx, sy): (f32, Option<f32>)| {
            this.inner.scale(sx, sy.unwrap_or(sx));
            Ok(())
        });
        // -- shear --
        /// Applies shear to this transform.
        /// @param | kx | number | X shear.
        /// @param | ky | number | Y shear.
        /// @return | nil | No value is returned.
        methods.add_method_mut("shear", |_, this, (kx, ky): (f32, f32)| {
            this.inner.shear(kx, ky);
            Ok(())
        });
        // -- reset --
        /// Resets this transform to identity.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });
        #[allow(clippy::too_many_arguments, clippy::type_complexity)]
        // -- setTransformation --
        /// Replaces this transform from position, rotation, scale, origin, and shear components.
        /// @param | x | number | X translation.
        /// @param | y | number | Y translation.
        /// @param | angle | number | Optional rotation angle, defaulting to 0.
        /// @param | sx | number | Optional X scale, defaulting to 1.
        /// @param | sy | number | Optional Y scale, defaulting to `sx`.
        /// @param | ox | number | Optional origin x, defaulting to 0.
        /// @param | oy | number | Optional origin y, defaulting to 0.
        /// @param | kx | number | Optional X shear, defaulting to 0.
        /// @param | ky | number | Optional Y shear, defaulting to 0.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "setTransformation",
            |_,
             this,
             (x, y, angle, sx, sy, ox, oy, kx, ky): (
                f32,
                f32,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                this.inner.set_transformation(
                    x,
                    y,
                    angle.unwrap_or(0.0),
                    sx.unwrap_or(1.0),
                    sy.unwrap_or(sx.unwrap_or(1.0)),
                    ox.unwrap_or(0.0),
                    oy.unwrap_or(0.0),
                    kx.unwrap_or(0.0),
                    ky.unwrap_or(0.0),
                );
                Ok(())
            },
        );
        // -- transformPoint --
        /// Transforms a point by this transform.
        /// @param | x | number | Input x coordinate.
        /// @param | y | number | Input y coordinate.
        /// @return | number | Transformed x coordinate.
        /// @return | number | Transformed y coordinate.
        methods.add_method("transformPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.transform_point(x, y))
        });
        // -- inverseTransformPoint --
        /// Transforms a point by this transform's inverse.
        /// @param | x | number | Input x coordinate.
        /// @param | y | number | Input y coordinate.
        /// @return | number | Inverse-transformed x coordinate.
        /// @return | number | Inverse-transformed y coordinate.
        methods.add_method("inverseTransformPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.inverse_transform_point(x, y))
        });
        // -- inverse --
        /// Returns this transform's inverse.
        /// @return | LTransform | Inverse transform handle.
        methods.add_method("inverse", |lua, this, ()| {
            lua.create_userdata(LuaTransform {
                inner: this.inner.inverse(),
            })
        });
        // -- clone --
        /// Returns a copy of this transform.
        /// @return | LTransform | Cloned transform handle.
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(LuaTransform { inner: this.inner })
        });
        // -- getMatrix --
        /// Returns this transform matrix as a flat array table.
        /// @return | table | Flat matrix values in row order.
        methods.add_method("getMatrix", |lua, this, ()| {
            let m = this.inner.matrix();
            let t = lua.create_table()?;
            let mut idx = 1;
            for row in &m.m {
                for &val in row {
                    t.set(idx, val)?;
                    idx += 1;
                }
            }
            Ok(t)
        });
        // -- decompose --
        /// Decomposes this transform into component values.
        /// @return | LuaValue | Transform decomposition tuple from the math module.
        methods.add_method("decompose", |_, this, ()| Ok(this.inner.decompose()));
        // -- type --
        /// Returns the Lua-visible type name for this transform handle.
        /// @return | string | The string `LTransform`.
        methods.add_method("type", |_, _, ()| Ok("LTransform"));
        // -- typeOf --
        /// Returns whether this transform handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LTransform` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTransform" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a Bezier curve.
pub struct LuaBezierCurve {
    /// Wrapped Bezier curve data.
    inner: BezierCurve,
}
/// Provides Lua methods for Bezier curve sampling and control point edits.
impl LuaUserData for LuaBezierCurve {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- evaluate --
        /// Evaluates this curve at normalized parameter `t`.
        /// @param | t | number | Normalized curve parameter.
        /// @return | number | Point x coordinate.
        /// @return | number | Point y coordinate.
        methods.add_method("evaluate", |_, this, t: f32| {
            let p = this.inner.evaluate(t);
            Ok((p.x, p.y))
        });
        // -- render --
        /// Returns sampled points along this curve.
        /// @param | segments | integer | Number of curve segments to sample.
        /// @return | table | Array table of `{x, y}` point arrays.
        methods.add_method("render", |lua, this, segments: usize| {
            let points = this.inner.render(segments);
            let t = lua.create_table()?;
            for (i, p) in points.iter().enumerate() {
                t.set(i + 1, vec![p.x, p.y])?;
            }
            Ok(t)
        });
        // -- getDerivative --
        /// Returns the derivative curve for this Bezier curve.
        /// @return | LBezierCurve | Derivative curve handle.
        methods.add_method("getDerivative", |lua, this, ()| {
            lua.create_userdata(LuaBezierCurve {
                inner: this.inner.get_derivative(),
            })
        });
        // -- getControlPoint --
        /// Returns a control point by one-based index.
        /// @param | index | integer | One-based control point index.
        /// @return | LuaValue | X coordinate, or nil when out of range.
        /// @return | LuaValue | Y coordinate, or nil when out of range.
        methods.add_method("getControlPoint", |_, this, index: usize| {
            if index == 0 {
                return Ok((None, None));
            }
            match this.inner.get_control_point(index - 1) {
                Some(p) => Ok((Some(p.x), Some(p.y))),
                None => Ok((None, None)),
            }
        });
        // -- setControlPoint --
        /// Sets a control point by one-based index.
        /// @param | index | integer | One-based control point index.
        /// @param | x | number | New x coordinate.
        /// @param | y | number | New y coordinate.
        /// @return | boolean | True when the control point exists.
        methods.add_method_mut(
            "setControlPoint",
            |_, this, (index, x, y): (usize, f32, f32)| {
                if index == 0 {
                    return Ok(false);
                }
                Ok(this.inner.set_control_point(index - 1, Vec2::new(x, y)))
            },
        );
        // -- insertControlPoint --
        /// Inserts a control point, optionally before a one-based index.
        /// @param | x | number | Point x coordinate.
        /// @param | y | number | Point y coordinate.
        /// @param | index | integer | Optional one-based insertion index.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "insertControlPoint",
            |_, this, (x, y, index): (f32, f32, Option<usize>)| {
                this.inner
                    .insert_control_point(Vec2::new(x, y), index.map(|i| i.saturating_sub(1)));
                Ok(())
            },
        );
        // -- removeControlPoint --
        /// Removes a control point by one-based index.
        /// @param | index | integer | One-based control point index.
        /// @return | boolean | True when a control point was removed.
        methods.add_method_mut("removeControlPoint", |_, this, index: usize| {
            if index == 0 {
                return Ok(false);
            }
            Ok(this.inner.remove_control_point(index - 1))
        });
        // -- getControlPointCount --
        /// Returns the number of control points in this curve.
        /// @return | integer | Control point count.
        methods.add_method("getControlPointCount", |_, this, ()| {
            Ok(this.inner.get_control_point_count())
        });
        // -- length --
        /// Returns the approximate curve length.
        /// @return | number | Curve length.
        methods.add_method("length", |_, this, ()| Ok(this.inner.length()));
        // -- evaluateAtDistance --
        /// Evaluates this curve at an approximate distance along the curve.
        /// @param | distance | number | Distance along the curve.
        /// @param | samples | integer | Optional sample count, defaulting to 128.
        /// @return | number | Point x coordinate.
        /// @return | number | Point y coordinate.
        methods.add_method(
            "evaluateAtDistance",
            |_, this, (distance, samples): (f32, Option<usize>)| {
                let p = this
                    .inner
                    .evaluate_at_distance(distance, samples.unwrap_or(128));
                Ok((p.x, p.y))
            },
        );
        // -- translate --
        /// Translates all control points.
        /// @param | dx | number | X translation.
        /// @param | dy | number | Y translation.
        /// @return | nil | No value is returned.
        methods.add_method_mut("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.translate(dx, dy);
            Ok(())
        });
        // -- rotate --
        /// Rotates all control points around an origin.
        /// @param | angle | number | Rotation angle.
        /// @param | ox | number | Origin x coordinate.
        /// @param | oy | number | Origin y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method_mut("rotate", |_, this, (angle, ox, oy): (f32, f32, f32)| {
            this.inner.rotate(angle, ox, oy);
            Ok(())
        });
        // -- scale --
        /// Scales all control points around an origin.
        /// @param | s | number | Scale factor.
        /// @param | ox | number | Origin x coordinate.
        /// @param | oy | number | Origin y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method_mut("scale", |_, this, (s, ox, oy): (f32, f32, f32)| {
            this.inner.scale(s, ox, oy);
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this Bezier curve handle.
        /// @return | string | The string `LBezierCurve`.
        methods.add_method("type", |_, _, ()| Ok("LBezierCurve"));
        // -- typeOf --
        /// Returns whether this Bezier curve handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LBezierCurve` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBezierCurve" || name == "Object")
        });
    }
}
/// Lua-side wrapper for numeric tween state.
pub struct LuaTween {
    /// Wrapped tween data.
    inner: Tween,
}
/// Provides Lua methods for tween updates, value reads, and time control.
impl LuaUserData for LuaTween {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Advances the tween clock and returns whether it is complete.
        /// @param | dt | number | Delta time in seconds.
        /// @return | boolean | True when the tween is complete.
        methods.add_method_mut("update", |_, this, dt: f64| Ok(this.inner.update(dt)));
        // -- reset --
        /// Resets the tween clock to the beginning.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });
        // -- getValue --
        /// Returns one tween value by one-based index or all values when no index is provided.
        /// @param | index | integer | Optional one-based value index.
        /// @return | LuaValue | Number value or array table of all values.
        methods.add_method("getValue", |lua, this, index: Option<usize>| match index {
            Some(i) => {
                if i == 0 {
                    return Ok(LuaValue::Number(0.0));
                }
                Ok(LuaValue::Number(this.inner.get_value(i - 1)))
            }
            None => {
                let vals = this.inner.get_all_values();
                let t = lua.create_table()?;
                for (i, v) in vals.iter().enumerate() {
                    t.set(i + 1, *v)?;
                }
                Ok(LuaValue::Table(t))
            }
        });
        // -- getAllValues --
        /// Returns all current tween values.
        /// @return | table | Array table of numeric tween values.
        methods.add_method("getAllValues", |lua, this, ()| {
            let vals = this.inner.get_all_values();
            let t = lua.create_table()?;
            for (i, v) in vals.iter().enumerate() {
                t.set(i + 1, *v)?;
            }
            Ok(t)
        });
        // -- isComplete --
        /// Returns whether this tween is complete.
        /// @return | boolean | True when complete.
        methods.add_method("isComplete", |_, this, ()| Ok(this.inner.is_complete()));
        // -- getValueCount --
        /// Returns the number of values animated by this tween.
        /// @return | integer | Tween value count.
        methods.add_method("getValueCount", |_, this, ()| Ok(this.inner.value_count()));
        // -- getEasingName --
        /// Returns this tween easing function name.
        /// @return | string | Easing function name.
        methods.add_method("getEasingName", |_, this, ()| {
            Ok(this.inner.easing_name().to_string())
        });
        // -- getDuration --
        /// Returns this tween duration.
        /// @return | number | Duration in seconds.
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.duration()));
        // -- getTime --
        /// Returns this tween clock time.
        /// @return | number | Current time in seconds.
        methods.add_method("getTime", |_, this, ()| Ok(this.inner.clock()));
        // -- getClock --
        /// Returns this tween clock time.
        /// @return | number | Current time in seconds.
        methods.add_method("getClock", |_, this, ()| Ok(this.inner.clock()));
        // -- setTime --
        /// Sets this tween clock time.
        /// @param | t | number | New time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTime", |_, this, t: f64| {
            this.inner.set_time(t);
            Ok(())
        });
        // -- set --
        /// Sets this tween clock time.
        /// @param | t | number | New time in seconds.
        /// @return | nil | No value is returned.
        methods.add_method_mut("set", |_, this, t: f64| {
            this.inner.set_time(t);
            Ok(())
        });
        // -- addValue --
        /// Adds a value track to this tween.
        /// @param | start | number | Start value.
        /// @param | target | number | Target value.
        /// @return | integer | One-based index of the new value track.
        methods.add_method_mut("addValue", |_, this, (start, target): (f64, f64)| {
            Ok(this.inner.add_value(start, target) + 1)
        });
        // -- type --
        /// Returns the Lua-visible type name for this tween handle.
        /// @return | string | The string `LTween`.
        methods.add_method("type", |_, _, ()| Ok("LTween"));
        // -- typeOf --
        /// Returns whether this tween handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LTween` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTween" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a spatial hash index.
pub struct LuaSpatialHash {
    /// Wrapped spatial hash data.
    inner: SpatialHash,
}
/// Provides Lua methods for spatial hash insertion and area queries.
impl LuaUserData for LuaSpatialHash {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- insert --
        /// Inserts an item rectangle into the spatial hash.
        /// @param | id | string | Item id.
        /// @param | x | number | Rectangle x coordinate.
        /// @param | y | number | Rectangle y coordinate.
        /// @param | w | number | Rectangle width.
        /// @param | h | number | Rectangle height.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "insert",
            |_, this, (id, x, y, w, h): (String, f32, f32, f32, f32)| {
                this.inner.insert(id, x, y, w, h);
                Ok(())
            },
        );
        // -- update --
        /// Updates an item rectangle in the spatial hash.
        /// @param | id | string | Item id.
        /// @param | x | number | Rectangle x coordinate.
        /// @param | y | number | Rectangle y coordinate.
        /// @param | w | number | Rectangle width.
        /// @param | h | number | Rectangle height.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "update",
            |_, this, (id, x, y, w, h): (String, f32, f32, f32, f32)| {
                this.inner.update(id, x, y, w, h);
                Ok(())
            },
        );
        // -- remove --
        /// Removes an item from the spatial hash.
        /// @param | id | string | Item id.
        /// @return | nil | No value is returned.
        methods.add_method_mut("remove", |_, this, id: String| {
            this.inner.remove(&id);
            Ok(())
        });
        // -- clear --
        /// Clears all items from the spatial hash.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- queryRect --
        /// Returns ids intersecting a query rectangle.
        /// @param | x | number | Query x coordinate.
        /// @param | y | number | Query y coordinate.
        /// @param | w | number | Query width.
        /// @param | h | number | Query height.
        /// @return | table | Array table of item ids.
        methods.add_method(
            "queryRect",
            |lua, this, (x, y, w, h): (f32, f32, f32, f32)| {
                let ids = this.inner.query_rect(x, y, w, h);
                let t = lua.create_table()?;
                for (i, id) in ids.iter().enumerate() {
                    t.set(i + 1, id.as_str())?;
                }
                Ok(t)
            },
        );
        // -- queryCircle --
        /// Returns ids intersecting a query circle.
        /// @param | cx | number | Circle center x coordinate.
        /// @param | cy | number | Circle center y coordinate.
        /// @param | radius | number | Circle radius.
        /// @return | table | Array table of item ids.
        methods.add_method(
            "queryCircle",
            |lua, this, (cx, cy, radius): (f32, f32, f32)| {
                let ids = this.inner.query_circle(cx, cy, radius);
                let t = lua.create_table()?;
                for (i, id) in ids.iter().enumerate() {
                    t.set(i + 1, id.as_str())?;
                }
                Ok(t)
            },
        );
        // -- querySegment --
        /// Returns ids intersecting a query line segment.
        /// @param | x1 | number | Segment start x coordinate.
        /// @param | y1 | number | Segment start y coordinate.
        /// @param | x2 | number | Segment end x coordinate.
        /// @param | y2 | number | Segment end y coordinate.
        /// @return | table | Array table of item ids.
        methods.add_method(
            "querySegment",
            |lua, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
                let ids = this.inner.query_segment(x1, y1, x2, y2);
                let t = lua.create_table()?;
                for (i, id) in ids.iter().enumerate() {
                    t.set(i + 1, id.as_str())?;
                }
                Ok(t)
            },
        );
        // -- getCellSize --
        /// Returns the spatial hash cell size.
        /// @return | number | Cell size.
        methods.add_method("getCellSize", |_, this, ()| Ok(this.inner.cell_size()));
        // -- getItemCount --
        /// Returns the number of items in the spatial hash.
        /// @return | integer | Item count.
        methods.add_method("getItemCount", |_, this, ()| Ok(this.inner.item_count()));
        // -- type --
        /// Returns the Lua-visible type name for this spatial hash handle.
        /// @return | string | The string `LSpatialHash`.
        methods.add_method("type", |_, _, ()| Ok("LSpatialHash"));
        // -- typeOf --
        /// Returns whether this spatial hash handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LSpatialHash` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpatialHash" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a procedural noise generator.
pub struct LuaNoiseGenerator {
    /// Wrapped noise generator state.
    inner: NoiseGenerator,
}
/// Resolves a Lua noise kind string into a noise kind enum.
fn resolve_noise_kind(name: &str) -> NoiseKind {
    match name.to_lowercase().as_str() {
        "simplex" => NoiseKind::Simplex,
        _ => NoiseKind::Perlin,
    }
}
/// Resolves a Lua distance type string into a distance type enum.
fn resolve_dist_type(name: &str) -> DistType {
    match name.to_lowercase().as_str() {
        "manhattan" => DistType::Manhattan,
        "chebyshev" => DistType::Chebyshev,
        _ => DistType::Euclidean,
    }
}
/// Resolves a Lua fractal type string into a fractal type enum.
fn resolve_fractal_type(name: &str) -> FractalType {
    match name.to_lowercase().as_str() {
        "ridged" => FractalType::Ridged,
        "turbulence" => FractalType::Turbulence,
        _ => FractalType::Fbm,
    }
}
/// Provides Lua methods for procedural noise sampling and map generation.
impl LuaUserData for LuaNoiseGenerator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- perlin1d --
        /// Samples 1D Perlin noise.
        /// @param | x | number | X coordinate.
        /// @return | number | Noise value.
        methods.add_method("perlin1d", |_, this, x: f64| Ok(this.inner.perlin_1d(x)));
        // -- perlin2d --
        /// Samples 2D Perlin noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @return | number | Noise value.
        methods.add_method("perlin2d", |_, this, (x, y): (f64, f64)| {
            Ok(this.inner.perlin_2d(x, y))
        });
        // -- perlin3d --
        /// Samples 3D Perlin noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @param | z | number | Z coordinate.
        /// @return | number | Noise value.
        methods.add_method("perlin3d", |_, this, (x, y, z): (f64, f64, f64)| {
            Ok(this.inner.perlin_3d(x, y, z))
        });
        // -- perlin4d --
        /// Samples 4D Perlin noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @param | z | number | Z coordinate.
        /// @param | w | number | W coordinate.
        /// @return | number | Noise value.
        methods.add_method("perlin4d", |_, this, (x, y, z, w): (f64, f64, f64, f64)| {
            Ok(this.inner.perlin_4d(x, y, z, w))
        });
        // -- simplex1d --
        /// Samples 1D simplex noise.
        /// @param | x | number | X coordinate.
        /// @return | number | Noise value.
        methods.add_method("simplex1d", |_, this, x: f64| Ok(this.inner.simplex_1d(x)));
        // -- simplex2d --
        /// Samples 2D simplex noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @return | number | Noise value.
        methods.add_method("simplex2d", |_, this, (x, y): (f64, f64)| {
            Ok(this.inner.simplex_2d(x, y))
        });
        // -- simplex3d --
        /// Samples 3D simplex noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @param | z | number | Z coordinate.
        /// @return | number | Noise value.
        methods.add_method("simplex3d", |_, this, (x, y, z): (f64, f64, f64)| {
            Ok(this.inner.simplex_3d(x, y, z))
        });
        // -- worley2d --
        /// Samples 2D Worley noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @param | dist_name | string | Optional distance type name.
        /// @param | f2 | boolean | Optional second-feature flag.
        /// @return | number | Noise value.
        methods.add_method(
            "worley2d",
            |_, this, (x, y, dist_name, f2): (f64, f64, Option<String>, Option<bool>)| {
                let dist = dist_name
                    .as_deref()
                    .map(resolve_dist_type)
                    .unwrap_or(DistType::Euclidean);
                Ok(this.inner.worley_2d(x, y, dist, f2.unwrap_or(false)))
            },
        );
        // -- worley3d --
        /// Samples 3D Worley noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @param | z | number | Z coordinate.
        /// @param | dist_name | string | Optional distance type name.
        /// @param | f2 | boolean | Optional second-feature flag.
        /// @return | number | Noise value.
        methods.add_method(
            "worley3d",
            |_, this, (x, y, z, dist_name, f2): (f64, f64, f64, Option<String>, Option<bool>)| {
                let dist = dist_name
                    .as_deref()
                    .map(resolve_dist_type)
                    .unwrap_or(DistType::Euclidean);
                Ok(this.inner.worley_3d(x, y, z, dist, f2.unwrap_or(false)))
            },
        );
        // -- fbm --
        /// Samples fractal Brownian motion noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @param | octaves | integer | Optional octave count, defaulting to 4.
        /// @param | lac | number | Optional lacunarity, defaulting to 2.0.
        /// @param | pers | number | Optional persistence, defaulting to 0.5.
        /// @param | kind | string | Optional noise kind name.
        /// @return | number | Noise value.
        methods.add_method(
            "fbm",
            |_,
             this,
             (x, y, octaves, lac, pers, kind): (
                f64,
                f64,
                Option<u32>,
                Option<f64>,
                Option<f64>,
                Option<String>,
            )| {
                let nk = kind
                    .as_deref()
                    .map(resolve_noise_kind)
                    .unwrap_or(NoiseKind::Perlin);
                Ok(this.inner.fbm(
                    x,
                    y,
                    octaves.unwrap_or(4),
                    lac.unwrap_or(2.0),
                    pers.unwrap_or(0.5),
                    nk,
                ))
            },
        );
        // -- ridged --
        /// Samples ridged fractal noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @param | octaves | integer | Optional octave count, defaulting to 4.
        /// @param | lac | number | Optional lacunarity, defaulting to 2.0.
        /// @param | pers | number | Optional persistence, defaulting to 0.5.
        /// @param | kind | string | Optional noise kind name.
        /// @return | number | Noise value.
        methods.add_method(
            "ridged",
            |_,
             this,
             (x, y, octaves, lac, pers, kind): (
                f64,
                f64,
                Option<u32>,
                Option<f64>,
                Option<f64>,
                Option<String>,
            )| {
                let nk = kind
                    .as_deref()
                    .map(resolve_noise_kind)
                    .unwrap_or(NoiseKind::Perlin);
                Ok(this.inner.ridged(
                    x,
                    y,
                    octaves.unwrap_or(4),
                    lac.unwrap_or(2.0),
                    pers.unwrap_or(0.5),
                    nk,
                ))
            },
        );
        // -- turbulence --
        /// Samples turbulence fractal noise.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @param | octaves | integer | Optional octave count, defaulting to 4.
        /// @param | lac | number | Optional lacunarity, defaulting to 2.0.
        /// @param | pers | number | Optional persistence, defaulting to 0.5.
        /// @param | kind | string | Optional noise kind name.
        /// @return | number | Noise value.
        methods.add_method(
            "turbulence",
            |_,
             this,
             (x, y, octaves, lac, pers, kind): (
                f64,
                f64,
                Option<u32>,
                Option<f64>,
                Option<f64>,
                Option<String>,
            )| {
                let nk = kind
                    .as_deref()
                    .map(resolve_noise_kind)
                    .unwrap_or(NoiseKind::Perlin);
                Ok(this.inner.turbulence(
                    x,
                    y,
                    octaves.unwrap_or(4),
                    lac.unwrap_or(2.0),
                    pers.unwrap_or(0.5),
                    nk,
                ))
            },
        );
        // -- warpDomain --
        /// Samples domain-warped noise coordinates.
        /// @param | x | number | X coordinate.
        /// @param | y | number | Y coordinate.
        /// @param | strength | number | Warp strength.
        /// @return | number | Warped noise value.
        methods.add_method(
            "warpDomain",
            |_, this, (x, y, strength): (f64, f64, f64)| Ok(this.inner.warp_domain(x, y, strength)),
        );
        // -- generateMap --
        /// Generates a noise map and returns it as a flat array table.
        /// @param | w | integer | Map width.
        /// @param | h | integer | Map height.
        /// @param | opts | table | Optional generation options including scale, octaves, kind, fractal, offset, and backend.
        /// @return | table | Flat array table of noise values.
        methods.add_method(
            "generateMap",
            |lua, this, (w, h, opts): (u32, u32, Option<LuaTable>)| {
                let map_opts = if let Some(t) = opts.as_ref() {
                    MapGenOptions {
                        scale_x: t.get::<_, Option<f64>>("scaleX")?.unwrap_or(1.0),
                        scale_y: t.get::<_, Option<f64>>("scaleY")?.unwrap_or(1.0),
                        octaves: t.get::<_, Option<u32>>("octaves")?.unwrap_or(4),
                        lacunarity: t.get::<_, Option<f64>>("lacunarity")?.unwrap_or(2.0),
                        persistence: t.get::<_, Option<f64>>("persistence")?.unwrap_or(0.5),
                        kind: t
                            .get::<_, Option<String>>("kind")?
                            .as_deref()
                            .map(resolve_noise_kind)
                            .unwrap_or(NoiseKind::Perlin),
                        fractal: t
                            .get::<_, Option<String>>("fractal")?
                            .as_deref()
                            .map(resolve_fractal_type)
                            .unwrap_or(FractalType::Fbm),
                        offset_x: t.get::<_, Option<f64>>("offsetX")?.unwrap_or(0.0),
                        offset_y: t.get::<_, Option<f64>>("offsetY")?.unwrap_or(0.0),
                    }
                } else {
                    MapGenOptions::default()
                };
                let backend = opts
                    .as_ref()
                    .and_then(|t| t.get::<_, Option<String>>("backend").ok().flatten())
                    .unwrap_or_else(|| "cpu".to_string());
                let data = if backend.eq_ignore_ascii_case("compute") {
                    this.inner.generate_map_compute(w, h, &map_opts)
                } else {
                    this.inner.generate_map(w, h, &map_opts)
                };
                let result = lua.create_table()?;
                for (i, v) in data.iter().enumerate() {
                    result.set(i + 1, *v)?;
                }
                Ok(result)
            },
        );
        // -- generateMapCompute --
        /// Generates a noise map through the compute backend and returns it as a flat array table.
        /// @param | w | integer | Map width.
        /// @param | h | integer | Map height.
        /// @param | opts | table | Optional generation options including scale, octaves, kind, fractal, and offset.
        /// @return | table | Flat array table of noise values.
        methods.add_method(
            "generateMapCompute",
            |lua, this, (w, h, opts): (u32, u32, Option<LuaTable>)| {
                let map_opts = if let Some(t) = opts {
                    MapGenOptions {
                        scale_x: t.get::<_, Option<f64>>("scaleX")?.unwrap_or(1.0),
                        scale_y: t.get::<_, Option<f64>>("scaleY")?.unwrap_or(1.0),
                        octaves: t.get::<_, Option<u32>>("octaves")?.unwrap_or(4),
                        lacunarity: t.get::<_, Option<f64>>("lacunarity")?.unwrap_or(2.0),
                        persistence: t.get::<_, Option<f64>>("persistence")?.unwrap_or(0.5),
                        kind: t
                            .get::<_, Option<String>>("kind")?
                            .as_deref()
                            .map(resolve_noise_kind)
                            .unwrap_or(NoiseKind::Perlin),
                        fractal: t
                            .get::<_, Option<String>>("fractal")?
                            .as_deref()
                            .map(resolve_fractal_type)
                            .unwrap_or(FractalType::Fbm),
                        offset_x: t.get::<_, Option<f64>>("offsetX")?.unwrap_or(0.0),
                        offset_y: t.get::<_, Option<f64>>("offsetY")?.unwrap_or(0.0),
                    }
                } else {
                    MapGenOptions::default()
                };
                let data = this.inner.generate_map_compute(w, h, &map_opts);
                let result = lua.create_table()?;
                for (i, v) in data.iter().enumerate() {
                    result.set(i + 1, *v)?;
                }
                Ok(result)
            },
        );
        // -- getSeed --
        /// Returns this noise generator seed.
        /// @return | integer | Seed value.
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.seed()));
        // -- setSeed --
        /// Sets this noise generator seed.
        /// @param | seed | integer | Seed value.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSeed", |_, this, seed: u64| {
            this.inner.set_seed(seed);
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this noise generator handle.
        /// @return | string | The string `LNoiseGenerator`.
        methods.add_method("type", |_, _, ()| Ok("LNoiseGenerator"));
        // -- typeOf --
        /// Returns whether this noise generator handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LNoiseGenerator` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNoiseGenerator" || name == "Object")
        });
    }
}
/// Lua-side wrapper for a circle primitive.
pub struct LuaCircle {
    /// Wrapped circle data.
    inner: Circle,
}
/// Provides Lua methods for circle measurements and intersections.
impl LuaUserData for LuaCircle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- area --
        /// Returns this circle area.
        /// @return | number | Circle area.
        methods.add_method("area", |_, this, ()| Ok(this.inner.area()));
        // -- perimeter --
        /// Returns this circle perimeter.
        /// @return | number | Circle perimeter.
        methods.add_method("perimeter", |_, this, ()| Ok(this.inner.perimeter()));
        // -- contains --
        /// Returns whether this circle contains a point.
        /// @param | px | number | Point x coordinate.
        /// @param | py | number | Point y coordinate.
        /// @return | boolean | True when the point is inside the circle.
        methods.add_method("contains", |_, this, (px, py): (f32, f32)| {
            Ok(this.inner.contains(px, py))
        });
        // -- intersects --
        /// Returns whether this circle intersects another circle.
        /// @param | other | LCircle | Other circle handle.
        /// @return | boolean | True when the circles intersect.
        methods.add_method("intersects", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaCircle>()?;
            Ok(this.inner.intersects(&other.inner))
        });
        // -- aabb --
        /// Returns this circle axis-aligned bounding box.
        /// @return | number | Minimum x coordinate.
        /// @return | number | Minimum y coordinate.
        /// @return | number | Maximum x coordinate.
        /// @return | number | Maximum y coordinate.
        methods.add_method("aabb", |_, this, ()| {
            let (x1, y1, x2, y2) = this.inner.aabb();
            Ok((x1, y1, x2, y2))
        });
        // -- x --
        /// Returns this circle center x coordinate.
        /// @return | number | Center x coordinate.
        methods.add_method("x", |_, this, ()| Ok(this.inner.x));
        // -- y --
        /// Returns this circle center y coordinate.
        /// @return | number | Center y coordinate.
        methods.add_method("y", |_, this, ()| Ok(this.inner.y));
        // -- radius --
        /// Returns this circle radius.
        /// @return | number | Radius.
        methods.add_method("radius", |_, this, ()| Ok(this.inner.radius));
        // -- type --
        /// Returns the Lua-visible type name for this circle handle.
        /// @return | string | The string `LCircle`.
        methods.add_method("type", |_, _, ()| Ok("LCircle"));
        // -- typeOf --
        /// Returns whether this circle handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LCircle` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCircle" || name == "Object")
        });
    }
}
/// Lua-side wrapper for an AABB tree spatial index.
pub struct LuaAabbTree {
    /// Wrapped AABB tree data.
    inner: AabbTree,
}
/// Lua-side wrapper for a rectangle packer.
pub struct LuaRectPacker {
    /// Wrapped rectangle packer data.
    inner: RectPacker,
}
/// Provides Lua methods for rectangle packing.
impl LuaUserData for LuaRectPacker {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- pack --
        /// Attempts to pack a rectangle and returns its placement coordinates.
        /// @param | w | integer | Rectangle width.
        /// @param | h | integer | Rectangle height.
        /// @param | id | string | Optional rectangle id.
        /// @return | LuaValue | X coordinate, or nil when packing fails.
        /// @return | LuaValue | Y coordinate, or nil when packing fails.
        methods.add_method_mut(
            "pack",
            |_, this, (w, h, id): (u32, u32, Option<String>)| match this.inner.pack(w, h, id) {
                Some(r) => Ok((Some(r.x), Some(r.y))),
                None => Ok((None::<u32>, None::<u32>)),
            },
        );
        // -- clear --
        /// Clears packed rectangles from this packer.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- occupancy --
        /// Returns occupied area ratio.
        /// @return | number | Occupancy ratio.
        methods.add_method("occupancy", |_, this, ()| Ok(this.inner.occupancy()));
        // -- getPacked --
        /// Returns packed rectangle records.
        /// @return | table | Array table with `x`, `y`, `w`, `h`, and optional `id` fields.
        methods.add_method("getPacked", |lua, this, ()| {
            let t = lua.create_table()?;
            for (i, r) in this.inner.packed_rects().iter().enumerate() {
                let row = lua.create_table()?;
                row.set("x", r.x)?;
                row.set("y", r.y)?;
                row.set("w", r.w)?;
                row.set("h", r.h)?;
                if let Some(id) = &r.id {
                    row.set("id", id.clone())?;
                }
                t.set(i + 1, row)?;
            }
            Ok(t)
        });
    }
}
/// Provides Lua methods for AABB tree spatial indexing.
impl LuaUserData for LuaAabbTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- insert --
        /// Inserts an AABB by id.
        /// @param | id | integer | Item id.
        /// @param | min_x | number | Minimum x coordinate.
        /// @param | min_y | number | Minimum y coordinate.
        /// @param | max_x | number | Maximum x coordinate.
        /// @param | max_y | number | Maximum y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "insert",
            |_, this, (id, min_x, min_y, max_x, max_y): (u64, f32, f32, f32, f32)| {
                this.inner.insert(id, min_x, min_y, max_x, max_y);
                Ok(())
            },
        );
        // -- remove --
        /// Removes an AABB by id.
        /// @param | id | integer | Item id.
        /// @return | boolean | True when the item existed.
        methods.add_method_mut("remove", |_, this, id: u64| Ok(this.inner.remove(id)));
        // -- query --
        /// Queries ids intersecting an AABB.
        /// @param | min_x | number | Minimum x coordinate.
        /// @param | min_y | number | Minimum y coordinate.
        /// @param | max_x | number | Maximum x coordinate.
        /// @param | max_y | number | Maximum y coordinate.
        /// @return | table | Array table of item ids.
        methods.add_method(
            "query",
            |lua, this, (min_x, min_y, max_x, max_y): (f32, f32, f32, f32)| {
                let ids = this.inner.query(min_x, min_y, max_x, max_y);
                let t = lua.create_table()?;
                for (i, id) in ids.iter().enumerate() {
                    t.set(i + 1, *id)?;
                }
                Ok(t)
            },
        );
        // -- queryPoint --
        /// Queries ids containing a point.
        /// @param | x | number | Point x coordinate.
        /// @param | y | number | Point y coordinate.
        /// @return | table | Array table of item ids.
        methods.add_method("queryPoint", |lua, this, (x, y): (f32, f32)| {
            let ids = this.inner.query_point(x, y);
            let t = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                t.set(i + 1, *id)?;
            }
            Ok(t)
        });
        // -- update --
        /// Updates an AABB by id.
        /// @param | id | integer | Item id.
        /// @param | min_x | number | Minimum x coordinate.
        /// @param | min_y | number | Minimum y coordinate.
        /// @param | max_x | number | Maximum x coordinate.
        /// @param | max_y | number | Maximum y coordinate.
        /// @return | boolean | True when the item existed.
        methods.add_method_mut(
            "update",
            |_, this, (id, min_x, min_y, max_x, max_y): (u64, f32, f32, f32, f32)| {
                Ok(this.inner.update(id, min_x, min_y, max_x, max_y))
            },
        );
        // -- contains --
        /// Returns whether the tree contains an id.
        /// @param | id | integer | Item id.
        /// @return | boolean | True when the id exists.
        methods.add_method("contains", |_, this, id: u64| Ok(this.inner.contains(id)));
        // -- len --
        /// Returns the number of items in the tree.
        /// @return | integer | Item count.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len() as i64));
        // -- isEmpty --
        /// Returns whether the tree has no items.
        /// @return | boolean | True when empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.is_empty()));
        // -- clear --
        /// Clears all items from the tree.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        // -- type --
        /// Returns the Lua-visible type name for this AABB tree handle.
        /// @return | string | The string `LAabbTree`.
        methods.add_method("type", |_, _, ()| Ok("LAabbTree"));
        // -- typeOf --
        /// Returns whether this AABB tree handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LAabbTree` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAabbTree" || name == "Object")
        });
    }
}
#[allow(clippy::type_complexity)]
/// Registers `lurek.math` constructors, scalar helpers, easing, geometry, polygon, color, and spatial functions.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newRandomGenerator --
    /// Creates a deterministic random generator with an optional seed.
    /// @param | seed | integer | Optional seed value.
    /// @return | LRandomGenerator | New random generator handle.
    tbl.set(
        "newRandomGenerator",
        lua.create_function(|lua, seed: Option<u64>| {
            let rng = match seed {
                Some(s) => RandomGenerator::with_seed(s),
                None => RandomGenerator::new(),
            };
            lua.create_userdata(LuaRandomGenerator { inner: rng })
        })?,
    )?;
    // -- newTransform --
    /// Creates an identity transform or a transform from optional components.
    /// @param | x | number | Optional x translation.
    /// @param | y | number | Optional y translation.
    /// @param | angle | number | Optional rotation angle.
    /// @param | sx | number | Optional x scale.
    /// @param | sy | number | Optional y scale.
    /// @param | ox | number | Optional origin x.
    /// @param | oy | number | Optional origin y.
    /// @param | kx | number | Optional x shear.
    /// @param | ky | number | Optional y shear.
    /// @return | LTransform | New transform handle.
    tbl.set(
        "newTransform",
        lua.create_function(
            |lua,
             (x, y, angle, sx, sy, ox, oy, kx, ky): (
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
                Option<f32>,
            )| {
                let t = if x.is_some() || y.is_some() {
                    let sx_val = sx.unwrap_or(1.0);
                    Transform::from_components(
                        x.unwrap_or(0.0),
                        y.unwrap_or(0.0),
                        angle.unwrap_or(0.0),
                        sx_val,
                        sy.unwrap_or(sx_val),
                        ox.unwrap_or(0.0),
                        oy.unwrap_or(0.0),
                        kx.unwrap_or(0.0),
                        ky.unwrap_or(0.0),
                    )
                } else {
                    Transform::new()
                };
                lua.create_userdata(LuaTransform { inner: t })
            },
        )?,
    )?;
    // -- newBezierCurve --
    /// Creates a Bezier curve from a flat point table.
    /// @param | points | table | Flat numeric table `{x1, y1, x2, y2, ...}` with at least two points.
    /// @return | LBezierCurve | New Bezier curve handle.
    tbl.set("newBezierCurve", lua.create_function(|lua, points: LuaTable| {
            let len = points.len()? as usize;
            if len < 4 || !len.is_multiple_of(2) {
                return Err(LuaError::external(
                    "newBezierCurve requires a flat table of at least 4 numbers (2 points): {x1,y1, x2,y2, ...}",
                ));
            }
            let mut pts = Vec::with_capacity(len / 2);
            for i in (1..=len).step_by(2) {
                let x: f32 = points.get(i)?;
                let y: f32 = points.get(i + 1)?;
                pts.push(Vec2::new(x, y));
            }
            lua.create_userdata(LuaBezierCurve {
                inner: BezierCurve::new(pts),
            })
        })?,
    )?;
    // -- newTween --
    /// Creates a tween with a duration and optional easing name.
    /// @param | duration | number | Tween duration in seconds.
    /// @param | easing_name | string | Optional easing name, defaulting to `linear`.
    /// @return | LTween | New tween handle.
    tbl.set(
        "newTween",
        lua.create_function(|lua, (duration, easing_name): (f64, Option<String>)| {
            let name = easing_name.as_deref().unwrap_or("linear");
            lua.create_userdata(LuaTween {
                inner: Tween::new(duration, name),
            })
        })?,
    )?;
    // -- newSpatialHash --
    /// Creates a spatial hash index with a cell size.
    /// @param | cell_size | number | Spatial hash cell size.
    /// @return | LSpatialHash | New spatial hash handle.
    tbl.set(
        "newSpatialHash",
        lua.create_function(|lua, cell_size: f32| {
            lua.create_userdata(LuaSpatialHash {
                inner: SpatialHash::new(cell_size),
            })
        })?,
    )?;
    // -- newNoiseGenerator --
    /// Creates a procedural noise generator with an optional seed.
    /// @param | seed | integer | Optional seed value, defaulting to 0.
    /// @return | LNoiseGenerator | New noise generator handle.
    tbl.set(
        "newNoiseGenerator",
        lua.create_function(|lua, seed: Option<u64>| {
            lua.create_userdata(LuaNoiseGenerator {
                inner: NoiseGenerator::new(seed.unwrap_or(0)),
            })
        })?,
    )?;
    // -- newRectPacker --
    /// Creates a rectangle packer.
    /// @param | width | integer | Packer width.
    /// @param | height | integer | Packer height.
    /// @param | padding | integer | Optional padding between rectangles.
    /// @return | LRectPacker | New rectangle packer handle.
    tbl.set(
        "newRectPacker",
        lua.create_function(|lua, (width, height, padding): (u32, u32, Option<u32>)| {
            lua.create_userdata(LuaRectPacker {
                inner: RectPacker::new(width, height, padding.unwrap_or(0)),
            })
        })?,
    )?;
    // -- perlin2d --
    /// Samples stateless 2D Perlin noise.
    /// @param | x | number | X coordinate.
    /// @param | y | number | Y coordinate.
    /// @param | seed | integer | Optional seed value, defaulting to 0.
    /// @return | number | Noise value.
    tbl.set(
        "perlin2d",
        lua.create_function(|_, (x, y, seed): (f32, f32, Option<u32>)| {
            Ok(noise_functions::perlin2d(x, y, seed.unwrap_or(0)))
        })?,
    )?;
    // -- perlin3d --
    /// Samples stateless 3D Perlin noise.
    /// @param | x | number | X coordinate.
    /// @param | y | number | Y coordinate.
    /// @param | z | number | Z coordinate.
    /// @param | seed | integer | Optional seed value, defaulting to 0.
    /// @return | number | Noise value.
    tbl.set(
        "perlin3d",
        lua.create_function(|_, (x, y, z, seed): (f32, f32, f32, Option<u32>)| {
            Ok(noise_functions::perlin3d(x, y, z, seed.unwrap_or(0)))
        })?,
    )?;
    // -- simplex2d --
    /// Samples stateless 2D simplex noise.
    /// @param | x | number | X coordinate.
    /// @param | y | number | Y coordinate.
    /// @param | seed | integer | Optional seed value, defaulting to 0.
    /// @return | number | Noise value.
    tbl.set(
        "simplex2d",
        lua.create_function(|_, (x, y, seed): (f32, f32, Option<u32>)| {
            Ok(noise_functions::simplex2d(x, y, seed.unwrap_or(0)))
        })?,
    )?;
    // -- fbm --
    /// Samples stateless fractal Brownian motion noise.
    /// @param | x | number | X coordinate.
    /// @param | y | number | Y coordinate.
    /// @param | seed | integer | Optional seed value, defaulting to 0.
    /// @param | octaves | integer | Optional octave count, defaulting to 4.
    /// @param | lac | number | Optional lacunarity, defaulting to 2.0.
    /// @param | gain | number | Optional gain, defaulting to 0.5.
    /// @return | number | Noise value.
    tbl.set(
        "fbm",
        lua.create_function(
            |_,
             (x, y, seed, octaves, lac, gain): (
                f32,
                f32,
                Option<u32>,
                Option<u32>,
                Option<f32>,
                Option<f32>,
            )| {
                Ok(noise_functions::fbm(
                    x,
                    y,
                    seed.unwrap_or(0),
                    octaves.unwrap_or(4),
                    lac.unwrap_or(2.0),
                    gain.unwrap_or(0.5),
                ))
            },
        )?,
    )?;
    // -- applyEasing --
    /// Applies a named easing function to a normalized value.
    /// @param | name | string | Easing function name.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "applyEasing",
        lua.create_function(|_, (name, t): (String, f32)| {
            easing::apply(&name, t)
                .ok_or_else(|| LuaError::external(format!("Unknown easing function: {}", name)))
        })?,
    )?;
    // -- linear --
    /// Applies linear easing.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "linear",
        lua.create_function(|_, t: f32| Ok(easing::linear(t)))?,
    )?;
    // -- inQuad --
    /// Applies quadratic ease-in.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_quad(t)))?,
    )?;
    // -- outQuad --
    /// Applies quadratic ease-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "outQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_quad(t)))?,
    )?;
    // -- inOutQuad --
    /// Applies quadratic ease-in-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_quad(t)))?,
    )?;
    // -- inCubic --
    /// Applies cubic ease-in.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_cubic(t)))?,
    )?;
    // -- outCubic --
    /// Applies cubic ease-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "outCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_cubic(t)))?,
    )?;
    // -- inOutCubic --
    /// Applies cubic ease-in-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_cubic(t)))?,
    )?;
    // -- inQuart --
    /// Applies quartic ease-in.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_quart(t)))?,
    )?;
    // -- outQuart --
    /// Applies quartic ease-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "outQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_quart(t)))?,
    )?;
    // -- inOutQuart --
    /// Applies quartic ease-in-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_quart(t)))?,
    )?;
    // -- inSine --
    /// Applies sine ease-in.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_sine(t)))?,
    )?;
    // -- outSine --
    /// Applies sine ease-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "outSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_sine(t)))?,
    )?;
    // -- inOutSine --
    /// Applies sine ease-in-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_sine(t)))?,
    )?;
    // -- inExpo --
    /// Applies exponential ease-in.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_expo(t)))?,
    )?;
    // -- outExpo --
    /// Applies exponential ease-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "outExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_expo(t)))?,
    )?;
    // -- inOutExpo --
    /// Applies exponential ease-in-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_expo(t)))?,
    )?;
    // -- inElastic --
    /// Applies elastic ease-in.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_elastic(t)))?,
    )?;
    // -- outElastic --
    /// Applies elastic ease-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "outElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_elastic(t)))?,
    )?;
    // -- outBounce --
    /// Applies bounce ease-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "outBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_bounce(t)))?,
    )?;
    // -- inBounce --
    /// Applies bounce ease-in.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_bounce(t)))?,
    )?;
    // -- inBack --
    /// Applies back ease-in.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_back(t)))?,
    )?;
    // -- outBack --
    /// Applies back ease-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "outBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_back(t)))?,
    )?;
    // -- inOutElastic --
    /// Applies elastic ease-in-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_elastic(t)))?,
    )?;
    // -- inOutBounce --
    /// Applies bounce ease-in-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_bounce(t)))?,
    )?;
    // -- inOutBack --
    /// Applies back ease-in-out.
    /// @param | t | number | Normalized input value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_back(t)))?,
    )?;
    // -- triangulate --
    /// Triangulates a flat polygon point table.
    /// @param | pts | table | Flat numeric table `{x1, y1, x2, y2, ...}` with at least three points.
    /// @return | table | Array table of flat triangle point tables.
    tbl.set(
        "triangulate",
        lua.create_function(|lua, pts: LuaTable| {
            let len = pts.len()? as usize;
            if len < 6 || !len.is_multiple_of(2) {
                return Err(LuaError::external(
                    "triangulate requires a flat table of at least 6 numbers (3 points)",
                ));
            }
            let mut verts = Vec::with_capacity(len / 2);
            for i in (1..=len).step_by(2) {
                let x: f32 = pts.get(i)?;
                let y: f32 = pts.get(i + 1)?;
                verts.push(Vec2::new(x, y));
            }
            let triangles = polygon::triangulate(&verts).map_err(LuaError::external)?;
            let result = lua.create_table()?;
            for (i, tri) in triangles.iter().enumerate() {
                let t = lua.create_table()?;
                t.set(1, tri[0].x)?;
                t.set(2, tri[0].y)?;
                t.set(3, tri[1].x)?;
                t.set(4, tri[1].y)?;
                t.set(5, tri[2].x)?;
                t.set(6, tri[2].y)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        })?,
    )?;
    // -- isConvex --
    /// Returns whether a flat polygon point table is convex.
    /// @param | pts | table | Flat numeric table `{x1, y1, x2, y2, ...}`.
    /// @return | boolean | True when the polygon is convex.
    tbl.set(
        "isConvex",
        lua.create_function(|_, pts: LuaTable| {
            let len = pts.len()? as usize;
            if len < 6 || !len.is_multiple_of(2) {
                return Ok(false);
            }
            let mut verts = Vec::with_capacity(len / 2);
            for i in (1..=len).step_by(2) {
                let x: f32 = pts.get(i)?;
                let y: f32 = pts.get(i + 1)?;
                verts.push(Vec2::new(x, y));
            }
            Ok(polygon::is_convex(&verts))
        })?,
    )?;
    // -- gammaToLinear --
    /// Converts a gamma-space channel to linear space.
    /// @param | c | number | Gamma-space channel value.
    /// @return | number | Linear-space channel value.
    tbl.set(
        "gammaToLinear",
        lua.create_function(|_, c: f32| Ok(gamma_to_linear(c)))?,
    )?;
    // -- linearToGamma --
    /// Converts a linear-space channel to gamma space.
    /// @param | c | number | Linear-space channel value.
    /// @return | number | Gamma-space channel value.
    tbl.set(
        "linearToGamma",
        lua.create_function(|_, c: f32| Ok(linear_to_gamma(c)))?,
    )?;
    // -- angleBetween --
    /// Returns the angle between two points.
    /// @param | x1 | number | First point x coordinate.
    /// @param | y1 | number | First point y coordinate.
    /// @param | x2 | number | Second point x coordinate.
    /// @param | y2 | number | Second point y coordinate.
    /// @return | number | Angle between points.
    tbl.set(
        "angleBetween",
        lua.create_function(|_, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            Ok(geometry::angle_between(x1, y1, x2, y2))
        })?,
    )?;
    // -- circleContainsPoint --
    /// Returns whether a circle contains a point.
    /// @param | cx | number | Circle center x coordinate.
    /// @param | cy | number | Circle center y coordinate.
    /// @param | r | number | Circle radius.
    /// @param | px | number | Point x coordinate.
    /// @param | py | number | Point y coordinate.
    /// @return | boolean | True when the point is inside the circle.
    tbl.set(
        "circleContainsPoint",
        lua.create_function(|_, (cx, cy, r, px, py): (f32, f32, f32, f32, f32)| {
            Ok(geometry::circle_contains_point(cx, cy, r, px, py))
        })?,
    )?;
    // -- circleIntersectsCircle --
    /// Returns whether two circles intersect.
    /// @return | boolean | True when the circles intersect.
    tbl.set(
        "circleIntersectsCircle",
        lua.create_function(
            |_, (x1, y1, r1, x2, y2, r2): (f32, f32, f32, f32, f32, f32)| {
                Ok(geometry::circle_intersects_circle(x1, y1, r1, x2, y2, r2))
            },
        )?,
    )?;
    // -- circleIntersectsLine --
    /// Returns circle-line intersection state and hit points when present.
    /// @return | boolean | True when the line intersects the circle.
    /// @return | LuaValue | First hit x coordinate, or nil.
    /// @return | LuaValue | First hit y coordinate, or nil.
    /// @return | LuaValue | Second hit x coordinate, or nil.
    /// @return | LuaValue | Second hit y coordinate, or nil.
    tbl.set(
        "circleIntersectsLine",
        lua.create_function(
            |_, (cx, cy, r, lx1, ly1, lx2, ly2): (f32, f32, f32, f32, f32, f32, f32)| {
                let (hit, p1, p2) = geometry::circle_intersects_line(cx, cy, r, lx1, ly1, lx2, ly2);
                if hit {
                    let (hx1, hy1) = p1.unwrap_or((0.0, 0.0));
                    let (hx2, hy2) = p2.unwrap_or((0.0, 0.0));
                    Ok((true, Some(hx1), Some(hy1), p2.map(|_| hx2), p2.map(|_| hy2)))
                } else {
                    Ok((false, None, None, None, None))
                }
            },
        )?,
    )?;
    // -- circleIntersectsSegment --
    /// Returns circle-segment intersection state and hit points when present.
    /// @return | boolean | True when the segment intersects the circle.
    /// @return | LuaValue | First hit x coordinate, or nil.
    /// @return | LuaValue | First hit y coordinate, or nil.
    /// @return | LuaValue | Second hit x coordinate, or nil.
    /// @return | LuaValue | Second hit y coordinate, or nil.
    tbl.set(
        "circleIntersectsSegment",
        lua.create_function(
            |_, (cx, cy, r, sx1, sy1, sx2, sy2): (f32, f32, f32, f32, f32, f32, f32)| {
                let (hit, p1, p2) =
                    geometry::circle_intersects_segment(cx, cy, r, sx1, sy1, sx2, sy2);
                if hit {
                    let (hx1, hy1) = p1.unwrap_or((0.0, 0.0));
                    let (hx2, hy2) = p2.unwrap_or((0.0, 0.0));
                    Ok((true, Some(hx1), Some(hy1), p2.map(|_| hx2), p2.map(|_| hy2)))
                } else {
                    Ok((false, None, None, None, None))
                }
            },
        )?,
    )?;
    // -- closestPointOnSegment --
    /// Returns the closest point on a segment to an input point.
    /// @return | number | Closest point x coordinate.
    /// @return | number | Closest point y coordinate.
    tbl.set(
        "closestPointOnSegment",
        lua.create_function(
            |_, (px, py, x1, y1, x2, y2): (f32, f32, f32, f32, f32, f32)| {
                Ok(geometry::closest_point_on_segment(px, py, x1, y1, x2, y2))
            },
        )?,
    )?;
    // -- convexHull --
    /// Computes the convex hull for a flat point table.
    /// @param | pts | table | Flat numeric point table.
    /// @return | table | Flat numeric hull point table.
    tbl.set(
        "convexHull",
        lua.create_function(|lua, pts: LuaTable| {
            let len = pts.len()? as usize;
            let mut flat: Vec<f32> = Vec::with_capacity(len);
            for i in 1..=(len as i64) {
                let v: f32 = pts.get(i)?;
                flat.push(v);
            }
            let hull = geometry::convex_hull(&flat);
            let result = lua.create_table()?;
            for (i, v) in hull.iter().enumerate() {
                result.set(i + 1, *v)?;
            }
            Ok(result)
        })?,
    )?;
    // -- delaunayTriangulate --
    /// Computes Delaunay triangles for a flat point table.
    /// @param | pts | table | Flat numeric point table.
    /// @return | table | Array table of triangle index tables.
    tbl.set(
        "delaunayTriangulate",
        lua.create_function(|lua, pts: LuaTable| {
            let len = pts.len()? as usize;
            let mut pairs: Vec<(f64, f64)> = Vec::with_capacity(len / 2);
            let mut i: i64 = 1;
            while i <= len as i64 {
                let x: f64 = pts.get(i)?;
                let y: f64 = pts.get(i + 1)?;
                pairs.push((x, y));
                i += 2;
            }
            let tris = geometry::delaunay_triangulate(&pairs);
            let result = lua.create_table()?;
            for (idx, tri) in tris.iter().enumerate() {
                let t = lua.create_table()?;
                for (j, v) in tri.iter().enumerate() {
                    t.set(j + 1, *v)?;
                }
                result.set(idx + 1, t)?;
            }
            Ok(result)
        })?,
    )?;
    // -- lineIntersect --
    /// Returns intersection point for two infinite lines when present.
    /// @return | LuaValue | Intersection x coordinate, or nil.
    /// @return | LuaValue | Intersection y coordinate, or nil.
    tbl.set(
        "lineIntersect",
        lua.create_function(
            |_, (x1, y1, x2, y2, x3, y3, x4, y4): (f32, f32, f32, f32, f32, f32, f32, f32)| {
                match geometry::line_intersect(x1, y1, x2, y2, x3, y3, x4, y4) {
                    Some((ix, iy)) => Ok((Some(ix), Some(iy))),
                    None => Ok((None, None)),
                }
            },
        )?,
    )?;
    // -- pointInPolygon --
    /// Returns whether a point lies inside a polygon.
    /// @param | pts | table | Flat numeric polygon point table.
    /// @param | px | number | Point x coordinate.
    /// @param | py | number | Point y coordinate.
    /// @return | boolean | True when the point is inside the polygon.
    tbl.set(
        "pointInPolygon",
        lua.create_function(|_, (pts, px, py): (LuaTable, f32, f32)| {
            let len = pts.len()? as usize;
            let mut flat: Vec<f32> = Vec::with_capacity(len);
            for i in 1..=(len as i64) {
                let v: f32 = pts.get(i)?;
                flat.push(v);
            }
            Ok(geometry::point_in_polygon(&flat, px, py))
        })?,
    )?;
    // -- polygonArea --
    /// Computes signed area for a flat polygon point table.
    /// @param | pts | table | Flat numeric polygon point table.
    /// @return | number | Polygon area.
    tbl.set(
        "polygonArea",
        lua.create_function(|_, pts: LuaTable| {
            let len = pts.len()? as usize;
            let mut flat: Vec<f32> = Vec::with_capacity(len);
            for i in 1..=(len as i64) {
                let v: f32 = pts.get(i)?;
                flat.push(v);
            }
            Ok(geometry::polygon_area(&flat))
        })?,
    )?;
    // -- polygonCentroid --
    /// Computes the centroid for a flat polygon point table.
    /// @param | pts | table | Flat numeric polygon point table.
    /// @return | number | Centroid x coordinate.
    /// @return | number | Centroid y coordinate.
    tbl.set(
        "polygonCentroid",
        lua.create_function(|_, pts: LuaTable| {
            let len = pts.len()? as usize;
            let mut flat: Vec<f32> = Vec::with_capacity(len);
            for i in 1..=(len as i64) {
                let v: f32 = pts.get(i)?;
                flat.push(v);
            }
            Ok(geometry::polygon_centroid(&flat))
        })?,
    )?;
    // -- segmentIntersectsSegment --
    /// Returns whether two segments intersect and their intersection point when present.
    /// @return | boolean | True when the segments intersect.
    /// @return | LuaValue | Intersection x coordinate, or nil.
    /// @return | LuaValue | Intersection y coordinate, or nil.
    tbl.set(
        "segmentIntersectsSegment",
        lua.create_function(
            |_, (x1, y1, x2, y2, x3, y3, x4, y4): (f32, f32, f32, f32, f32, f32, f32, f32)| {
                match geometry::segment_intersects_segment(x1, y1, x2, y2, x3, y3, x4, y4) {
                    (true, Some((ix, iy))) => Ok((true, Some(ix), Some(iy))),
                    _ => Ok((false, None, None)),
                }
            },
        )?,
    )?;
    // -- bresenham --
    /// Returns integer grid points along a Bresenham line.
    /// @return | table | Array table of `{x, y}` point tables.
    tbl.set(
        "bresenham",
        lua.create_function(|lua, (x1, y1, x2, y2): (i32, i32, i32, i32)| {
            let pts = geometry::bresenham(x1, y1, x2, y2);
            let result = lua.create_table()?;
            for (i, (px, py)) in pts.iter().enumerate() {
                let t = lua.create_table()?;
                t.set(1, *px)?;
                t.set(2, *py)?;
                result.set(i + 1, t)?;
            }
            Ok(result)
        })?,
    )?;
    tbl.set("pi", std::f64::consts::PI)?;
    tbl.set("tau", std::f64::consts::TAU)?;
    tbl.set("huge", f64::INFINITY)?;
    // -- rad --
    /// Converts degrees to radians.
    /// @param | deg | number | Angle in degrees.
    /// @return | number | Angle in radians.
    tbl.set(
        "rad",
        lua.create_function(|_, deg: f64| Ok(deg.to_radians()))?,
    )?;
    // -- deg --
    /// Converts radians to degrees.
    /// @param | rad | number | Angle in radians.
    /// @return | number | Angle in degrees.
    tbl.set(
        "deg",
        lua.create_function(|_, rad: f64| Ok(rad.to_degrees()))?,
    )?;
    // -- sin --
    /// Returns sine of an angle.
    /// @param | x | number | Angle in radians.
    /// @return | number | Sine value.
    tbl.set("sin", lua.create_function(|_, x: f64| Ok(x.sin()))?)?;
    // -- cos --
    /// Returns cosine of an angle.
    /// @param | x | number | Angle in radians.
    /// @return | number | Cosine value.
    tbl.set("cos", lua.create_function(|_, x: f64| Ok(x.cos()))?)?;
    // -- tan --
    /// Returns tangent of an angle.
    /// @param | x | number | Angle in radians.
    /// @return | number | Tangent value.
    tbl.set("tan", lua.create_function(|_, x: f64| Ok(x.tan()))?)?;
    // -- asin --
    /// Returns arcsine of a value.
    /// @param | x | number | Input value.
    /// @return | number | Angle in radians.
    tbl.set("asin", lua.create_function(|_, x: f64| Ok(x.asin()))?)?;
    // -- acos --
    /// Returns arccosine of a value.
    /// @param | x | number | Input value.
    /// @return | number | Angle in radians.
    tbl.set("acos", lua.create_function(|_, x: f64| Ok(x.acos()))?)?;
    // -- atan --
    /// Returns arctangent or two-argument arctangent.
    /// @param | y | number | Input value or y coordinate.
    /// @param | x | number | Optional x coordinate for atan2 behavior.
    /// @return | number | Angle in radians.
    tbl.set(
        "atan",
        lua.create_function(|_, (y, x): (f64, Option<f64>)| {
            Ok(match x {
                Some(xv) => y.atan2(xv),
                None => y.atan(),
            })
        })?,
    )?;
    // -- atan2 --
    /// Returns two-argument arctangent.
    /// @param | y | number | Y coordinate.
    /// @param | x | number | X coordinate.
    /// @return | number | Angle in radians.
    tbl.set(
        "atan2",
        lua.create_function(|_, (y, x): (f64, f64)| Ok(y.atan2(x)))?,
    )?;
    // -- sqrt --
    /// Returns square root of a value.
    /// @param | x | number | Input value.
    /// @return | number | Square root.
    tbl.set("sqrt", lua.create_function(|_, x: f64| Ok(x.sqrt()))?)?;
    // -- abs --
    /// Returns absolute value.
    /// @param | x | number | Input value.
    /// @return | number | Absolute value.
    tbl.set("abs", lua.create_function(|_, x: f64| Ok(x.abs()))?)?;
    // -- floor --
    /// Returns floor of a value.
    /// @param | x | number | Input value.
    /// @return | number | Floored value.
    tbl.set("floor", lua.create_function(|_, x: f64| Ok(x.floor()))?)?;
    // -- ceil --
    /// Returns ceiling of a value.
    /// @param | x | number | Input value.
    /// @return | number | Ceiling value.
    tbl.set("ceil", lua.create_function(|_, x: f64| Ok(x.ceil()))?)?;
    // -- round --
    /// Returns rounded value.
    /// @param | x | number | Input value.
    /// @return | number | Rounded value.
    tbl.set("round", lua.create_function(|_, x: f64| Ok(x.round()))?)?;
    // -- exp --
    /// Returns exponential of a value.
    /// @param | x | number | Input value.
    /// @return | number | Exponential value.
    tbl.set("exp", lua.create_function(|_, x: f64| Ok(x.exp()))?)?;
    // -- log --
    /// Returns natural logarithm or logarithm with a supplied base.
    /// @param | x | number | Input value.
    /// @param | b | number | Optional logarithm base.
    /// @return | number | Logarithm value.
    tbl.set(
        "log",
        lua.create_function(|_, (x, b): (f64, Option<f64>)| {
            Ok(match b {
                Some(base) => x.log(base),
                None => x.ln(),
            })
        })?,
    )?;
    // -- pow --
    /// Raises a value to a power.
    /// @param | x | number | Base value.
    /// @param | y | number | Exponent value.
    /// @return | number | Power result.
    tbl.set(
        "pow",
        lua.create_function(|_, (x, y): (f64, f64)| Ok(x.powf(y)))?,
    )?;
    // -- min --
    /// Returns the smallest supplied value.
    /// @param | args | number | One or more numeric values.
    /// @return | number | Minimum value.
    tbl.set(
        "min",
        lua.create_function(|_, args: mlua::Variadic<f64>| {
            args.iter().copied().reduce(f64::min).ok_or_else(|| {
                mlua::Error::RuntimeError("min() requires at least one argument".into())
            })
        })?,
    )?;
    // -- max --
    /// Returns the largest supplied value.
    /// @param | args | number | One or more numeric values.
    /// @return | number | Maximum value.
    tbl.set(
        "max",
        lua.create_function(|_, args: mlua::Variadic<f64>| {
            args.iter().copied().reduce(f64::max).ok_or_else(|| {
                mlua::Error::RuntimeError("max() requires at least one argument".into())
            })
        })?,
    )?;
    // -- fmod --
    /// Returns floating-point remainder.
    /// @param | x | number | Dividend.
    /// @param | y | number | Divisor.
    /// @return | number | Remainder.
    tbl.set(
        "fmod",
        lua.create_function(|_, (x, y): (f64, f64)| Ok(x % y))?,
    )?;
    // -- distance --
    /// Returns Euclidean distance between two points.
    /// @return | number | Distance.
    tbl.set(
        "distance",
        lua.create_function(|_, (x1, y1, x2, y2): (f64, f64, f64, f64)| {
            let dx = x2 - x1;
            let dy = y2 - y1;
            Ok((dx * dx + dy * dy).sqrt())
        })?,
    )?;
    // -- distanceSq --
    /// Returns squared Euclidean distance between two points.
    /// @return | number | Squared distance.
    tbl.set(
        "distanceSq",
        lua.create_function(|_, (x1, y1, x2, y2): (f64, f64, f64, f64)| {
            let dx = x2 - x1;
            let dy = y2 - y1;
            Ok(dx * dx + dy * dy)
        })?,
    )?;
    // -- random --
    /// Returns a Lua math random value, optionally scaled to one or two bounds.
    /// @param | a | number | Optional upper bound or lower bound.
    /// @param | b | number | Optional upper bound.
    /// @return | number | Random value.
    tbl.set(
        "random",
        lua.create_function(|lua, (a, b): (Option<f64>, Option<f64>)| {
            let math: mlua::Table = lua.globals().get("math")?;
            match (a, b) {
                (None, _) => {
                    let f: mlua::Function = math.get("random")?;
                    let v: f64 = f.call(())?;
                    Ok(v)
                }
                (Some(max), None) => {
                    let f: mlua::Function = math.get("random")?;
                    let v: f64 = f.call(())?;
                    Ok(v * max)
                }
                (Some(lo), Some(hi)) => {
                    let f: mlua::Function = math.get("random")?;
                    let v: f64 = f.call(())?;
                    Ok(lo + v * (hi - lo))
                }
            }
        })?,
    )?;
    // -- randomInt --
    /// Returns a Lua math random integer in an inclusive range.
    /// @param | lo | integer | Lower bound.
    /// @param | hi | integer | Upper bound.
    /// @return | integer | Random integer.
    tbl.set(
        "randomInt",
        lua.create_function(|lua, (lo, hi): (i64, i64)| {
            let math: mlua::Table = lua.globals().get("math")?;
            let f: mlua::Function = math.get("random")?;
            let v: i64 = f.call((lo, hi))?;
            Ok(v)
        })?,
    )?;
    // -- simplexNoise --
    /// Samples 2D or 3D simplex noise.
    /// @param | x | number | X coordinate.
    /// @param | y | number | Y coordinate.
    /// @param | z | number | Optional Z coordinate.
    /// @return | number | Noise value.
    tbl.set(
        "simplexNoise",
        lua.create_function(|_, (x, y, z): (f64, f64, Option<f64>)| {
            let v = match z {
                Some(zv) => noise_functions::simplex_noise_3d(x as f32, y as f32, zv as f32),
                None => noise_functions::simplex_noise_2d(x as f32, y as f32),
            };
            Ok(v as f64)
        })?,
    )?;
    // -- vec2 --
    /// Creates a 2D vector.
    /// @param | x | number | X component.
    /// @param | y | number | Y component.
    /// @return | LVec2 | New vector handle.
    tbl.set(
        "vec2",
        lua.create_function(|lua, (x, y): (f64, f64)| {
            lua.create_userdata(LuaVec2 {
                inner: Vec2::new(x as f32, y as f32),
            })
        })?,
    )?;
    // -- Vec2 --
    /// Creates a 2D vector.
    /// @param | x | number | X component.
    /// @param | y | number | Y component.
    /// @return | LVec2 | New vector handle.
    tbl.set(
        "Vec2",
        lua.create_function(|lua, (x, y): (f64, f64)| {
            lua.create_userdata(LuaVec2 {
                inner: Vec2::new(x as f32, y as f32),
            })
        })?,
    )?;
    // -- vec3 --
    /// Creates a 3D vector.
    /// @param | x | number | X component.
    /// @param | y | number | Y component.
    /// @param | z | number | Z component.
    /// @return | LVec3 | New vector handle.
    tbl.set(
        "vec3",
        lua.create_function(|lua, (x, y, z): (f32, f32, f32)| {
            lua.create_userdata(LuaVec3 {
                inner: Vec3::new(x, y, z),
            })
        })?,
    )?;
    // -- Vec3 --
    /// Creates a 3D vector.
    /// @param | x | number | X component.
    /// @param | y | number | Y component.
    /// @param | z | number | Z component.
    /// @return | LVec3 | New vector handle.
    tbl.set(
        "Vec3",
        lua.create_function(|lua, (x, y, z): (f32, f32, f32)| {
            lua.create_userdata(LuaVec3 {
                inner: Vec3::new(x, y, z),
            })
        })?,
    )?;
    // -- catmullRom --
    /// Creates a Catmull-Rom spline from point tables.
    /// @param | points | table | Array table of points with `x`/`y` fields or numeric indices.
    /// @return | LCatmullRom | New spline handle.
    tbl.set(
        "catmullRom",
        lua.create_function(|lua, points: LuaTable| {
            let mut pts: Vec<(f32, f32)> = Vec::new();
            for v in points.sequence_values::<LuaTable>() {
                let t = v?;
                let x: f32 = t.get("x").or_else(|_| t.get(1)).unwrap_or(0.0);
                let y: f32 = t.get("y").or_else(|_| t.get(2)).unwrap_or(0.0);
                pts.push((x, y));
            }
            lua.create_userdata(LuaCatmullRom {
                inner: CatmullRomSpline::new(pts),
            })
        })?,
    )?;
    // -- hermite --
    /// Creates a Hermite spline from endpoints and tangents.
    /// @return | LHermite | New Hermite spline handle.
    tbl.set("hermite", lua.create_function(|lua, (p0x, p0y, p1x, p1y, m0x, m0y, m1x, m1y): (f32, f32, f32, f32, f32, f32, f32, f32)| {
            let hs = HermiteSpline::new((p0x, p0y), (p1x, p1y), (m0x, m0y), (m1x, m1y));
            lua.create_userdata(LuaHermite { inner: hs })
        })?,
    )?;
    // -- lerp --
    /// Linearly interpolates between two values.
    /// @param | a | number | Start value.
    /// @param | b | number | End value.
    /// @param | t | number | Interpolation factor.
    /// @return | number | Interpolated value.
    tbl.set(
        "lerp",
        lua.create_function(|_, (a, b, t): (f32, f32, f32)| Ok(lerp(a, b, t)))?,
    )?;
    // -- remap --
    /// Remaps a value from one range to another.
    /// @return | number | Remapped value.
    tbl.set(
        "remap",
        lua.create_function(
            |_, (v, in_min, in_max, out_min, out_max): (f32, f32, f32, f32, f32)| {
                Ok(remap(v, in_min, in_max, out_min, out_max))
            },
        )?,
    )?;
    // -- clamp --
    /// Clamps a value to a range.
    /// @param | v | number | Input value.
    /// @param | min | number | Minimum value.
    /// @param | max | number | Maximum value.
    /// @return | number | Clamped value.
    tbl.set(
        "clamp",
        lua.create_function(|_, (v, min, max): (f32, f32, f32)| Ok(clamp(v, min, max)))?,
    )?;
    // -- sign --
    /// Returns the sign of a value.
    /// @param | v | number | Input value.
    /// @return | number | Sign value.
    tbl.set("sign", lua.create_function(|_, v: f32| Ok(sign(v)))?)?;
    // -- smoothstep --
    /// Applies smoothstep interpolation between two edges.
    /// @return | number | Smoothstep value.
    tbl.set(
        "smoothstep",
        lua.create_function(|_, (edge0, edge1, x): (f32, f32, f32)| {
            Ok(smoothstep(edge0, edge1, x))
        })?,
    )?;
    // -- inverseLerp --
    /// Returns the interpolation factor of a value between two bounds.
    /// @param | a | number | Start value.
    /// @param | b | number | End value.
    /// @param | v | number | Input value.
    /// @return | number | Interpolation factor.
    tbl.set(
        "inverseLerp",
        lua.create_function(|_, (a, b, v): (f32, f32, f32)| Ok(inverse_lerp(a, b, v)))?,
    )?;
    // -- hslToRgb --
    /// Converts HSL color values to RGBA channels.
    /// @return | number | Red channel.
    /// @return | number | Green channel.
    /// @return | number | Blue channel.
    /// @return | number | Alpha channel.
    tbl.set(
        "hslToRgb",
        lua.create_function(|_, (h, s, l): (f32, f32, f32)| {
            let c = hsl_to_rgb(h, s, l);
            Ok((c.r, c.g, c.b, c.a))
        })?,
    )?;
    // -- fromHex --
    /// Converts a hex color string to RGBA channels.
    /// @param | hex | string | Hex color string.
    /// @return | number | Red channel.
    /// @return | number | Green channel.
    /// @return | number | Blue channel.
    /// @return | number | Alpha channel.
    tbl.set(
        "fromHex",
        lua.create_function(|_, hex: String| {
            use crate::math::Color;
            Color::from_hex(&hex)
                .map(|c| (c.r, c.g, c.b, c.a))
                .ok_or_else(|| LuaError::RuntimeError(format!("invalid hex color: {}", hex)))
        })?,
    )?;
    // -- rgbToHsl --
    /// Converts RGB channels to HSL values.
    /// @return | number | Hue.
    /// @return | number | Saturation.
    /// @return | number | Lightness.
    tbl.set(
        "rgbToHsl",
        lua.create_function(|_, (r, g, b): (f32, f32, f32)| {
            use crate::math::Color;
            let c = Color::new(r, g, b, 1.0);
            Ok(c.to_hsl())
        })?,
    )?;
    // -- rectUnion --
    /// Returns the union rectangle for two rectangles.
    /// @return | number | Union x coordinate.
    /// @return | number | Union y coordinate.
    /// @return | number | Union width.
    /// @return | number | Union height.
    tbl.set(
        "rectUnion",
        lua.create_function(
            |_, (x1, y1, w1, h1, x2, y2, w2, h2): (f32, f32, f32, f32, f32, f32, f32, f32)| {
                let a = Rect::new(x1, y1, w1, h1);
                let b = Rect::new(x2, y2, w2, h2);
                let u = a.union(&b);
                Ok((u.x, u.y, u.width, u.height))
            },
        )?,
    )?;
    // -- rectFromCenter --
    /// Creates a rectangle tuple from center coordinates and size.
    /// @return | number | Rectangle x coordinate.
    /// @return | number | Rectangle y coordinate.
    /// @return | number | Rectangle width.
    /// @return | number | Rectangle height.
    tbl.set(
        "rectFromCenter",
        lua.create_function(|_, (cx, cy, w, h): (f32, f32, f32, f32)| {
            let r = Rect::from_center(cx, cy, w, h);
            Ok((r.x, r.y, r.width, r.height))
        })?,
    )?;
    // -- polygonClip --
    /// Clips a flat polygon point table against a plane.
    /// @return | table | Flat numeric clipped polygon point table.
    tbl.set(
        "polygonClip",
        lua.create_function(|lua, (pts, nx, ny, d): (LuaTable, f32, f32, f32)| {
            let len = pts.len()? as usize;
            if !len.is_multiple_of(2) {
                return Err(LuaError::RuntimeError(
                    "polygonClip: polygon table must contain an even number of values (x,y pairs)"
                        .into(),
                ));
            }
            let mut verts: Vec<(f32, f32)> = Vec::with_capacity(len / 2);
            for i in (0..len).step_by(2) {
                let x: f32 = pts.get(i + 1)?;
                let y: f32 = pts.get(i + 2)?;
                verts.push((x, y));
            }
            let clipped = polygon::polygon_clip(&verts, nx, ny, d);
            let result = lua.create_table()?;
            for (i, (x, y)) in clipped.iter().enumerate() {
                result.set(i * 2 + 1, *x)?;
                result.set(i * 2 + 2, *y)?;
            }
            Ok(result)
        })?,
    )?;
    // -- aabbTree --
    /// Creates an empty AABB tree.
    /// @return | LAabbTree | New AABB tree handle.
    tbl.set(
        "aabbTree",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAabbTree {
                inner: AabbTree::new(),
            })
        })?,
    )?;
    // -- newCircle --
    /// Creates a circle primitive.
    /// @param | x | number | Center x coordinate.
    /// @param | y | number | Center y coordinate.
    /// @param | radius | number | Circle radius.
    /// @return | LCircle | New circle handle.
    tbl.set(
        "newCircle",
        lua.create_function(|lua, (x, y, radius): (f32, f32, f32)| {
            lua.create_userdata(LuaCircle {
                inner: Circle::new(x, y, radius),
            })
        })?,
    )?;
    // -- polygonIntersection --
    /// Returns polygon intersection points for two polygon tables.
    /// @param | a | table | First polygon table of `{x, y}` points.
    /// @param | b | table | Second polygon table of `{x, y}` points.
    /// @return | table | Polygon table of result points.
    tbl.set(
        "polygonIntersection",
        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {
            let va = lua_table_to_poly(a)?;
            let vb = lua_table_to_poly(b)?;
            let result = polygon::polygon_intersection(&va, &vb);
            poly_to_lua_table(lua, &result)
        })?,
    )?;
    // -- polygonUnion --
    /// Returns polygon union points for two polygon tables.
    /// @param | a | table | First polygon table of `{x, y}` points.
    /// @param | b | table | Second polygon table of `{x, y}` points.
    /// @return | table | Polygon table of result points.
    tbl.set(
        "polygonUnion",
        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {
            let va = lua_table_to_poly(a)?;
            let vb = lua_table_to_poly(b)?;
            let result = polygon::polygon_union(&va, &vb);
            poly_to_lua_table(lua, &result)
        })?,
    )?;
    // -- polygonDifference --
    /// Returns polygon difference points for two polygon tables.
    /// @param | a | table | First polygon table of `{x, y}` points.
    /// @param | b | table | Second polygon table of `{x, y}` points.
    /// @return | table | Polygon table of result points.
    tbl.set(
        "polygonDifference",
        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {
            let va = lua_table_to_poly(a)?;
            let vb = lua_table_to_poly(b)?;
            let result = polygon::polygon_difference(&va, &vb);
            poly_to_lua_table(lua, &result)
        })?,
    )?;
    // -- voronoi --
    /// Builds Voronoi cells from a polygon-style point table.
    /// @param | points | table | Point table with `x` and `y` fields.
    /// @return | table | Array table of cells with `site` and `vertices` fields.
    tbl.set(
        "voronoi",
        lua.create_function(|lua, points: LuaTable| {
            let pts = lua_table_to_poly(points)?;
            let cells = crate::math::voronoi_from_points(&pts);
            let out = lua.create_table()?;
            for (i, cell) in cells.iter().enumerate() {
                let site_tbl = lua.create_table()?;
                site_tbl.set("x", cell.site.0)?;
                site_tbl.set("y", cell.site.1)?;
                let verts_tbl = lua.create_table()?;
                for (j, &(vx, vy)) in cell.vertices.iter().enumerate() {
                    let v = lua.create_table()?;
                    v.set("x", vx)?;
                    v.set("y", vy)?;
                    verts_tbl.set(j + 1, v)?;
                }
                let cell_tbl = lua.create_table()?;
                cell_tbl.set("site", site_tbl)?;
                cell_tbl.set("vertices", verts_tbl)?;
                out.set(i + 1, cell_tbl)?;
            }
            Ok(out)
        })?,
    )?;
    luna.set("math", tbl)?;
    Ok(())
}
/// Converts a Lua table of `{x, y}` points into a Rust polygon vector.
fn lua_table_to_poly(tbl: LuaTable) -> LuaResult<Vec<(f32, f32)>> {
    let mut pts = Vec::new();
    for pair in tbl.pairs::<i64, LuaTable>() {
        let (_, pt) = pair?;
        let x: f32 = pt.get("x")?;
        let y: f32 = pt.get("y")?;
        pts.push((x, y));
    }
    Ok(pts)
}
/// Converts a Rust polygon vector into a Lua table of `{x, y}` points.
fn poly_to_lua_table<'lua>(lua: &'lua Lua, pts: &[(f32, f32)]) -> LuaResult<LuaTable<'lua>> {
    let arr = lua.create_table()?;
    for (i, (x, y)) in pts.iter().enumerate() {
        let t = lua.create_table()?;
        t.set("x", *x)?;
        t.set("y", *y)?;
        arr.set(i + 1, t)?;
    }
    Ok(arr)
}
