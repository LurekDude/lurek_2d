//! `lurek.math` - Math utilities for vectors, easing, noise, geometry, and interpolation.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

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
use crate::math::SpatialHash;
use crate::math::Transform;
use crate::math::Tween;
use crate::math::Vec2;
use crate::math::Vec3;
use crate::math::{clamp, inverse_lerp, lerp, remap, sign, smoothstep};
use crate::math::{CatmullRomSpline, HermiteSpline};
use crate::math::{DistType, FractalType, MapGenOptions, NoiseKind};

// -------------------------------------------------------------------------------
// LuaVec2 UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Vec2`] value type.
///
/// # Fields
/// - `inner` — `Vec2`.
pub struct LuaVec2 {
    pub inner: Vec2,
}

impl LuaUserData for LuaVec2 {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        // -- x --
        /// The horizontal component of the vector.
        fields.add_field_method_get("x", |_, this| Ok(this.inner.x as f64));
        fields.add_field_method_set("x", |_, this, v: f64| {
            this.inner.x = v as f32;
            Ok(())
        });
        // -- y --
        /// The vertical component of the vector.
        fields.add_field_method_get("y", |_, this| Ok(this.inner.y as f64));
        fields.add_field_method_set("y", |_, this, v: f64| {
            this.inner.y = v as f32;
            Ok(())
        });
    }

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- dot --
        /// Returns the dot product with another vector.
        /// @param | other | LVec2 | Vector to dot against this vector.
        /// @return | number | Dot product result.
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner.dot(o.inner) as f64)
        });

        // -- length --
        /// Returns the Euclidean length of the vector.
        /// @return | number | Vector length.
        methods.add_method("length", |_, this, ()| Ok(this.inner.length() as f64));

        // -- x --
        /// Returns the horizontal component of the vector.
        /// @return | number | Horizontal component value.
        methods.add_method("x", |_, this, ()| Ok(this.inner.x as f64));

        // -- y --
        /// Returns the vertical component of the vector.
        /// @return | number | Vertical component value.
        methods.add_method("y", |_, this, ()| Ok(this.inner.y as f64));

        // -- lengthSquared --
        /// Returns the squared length of the vector (faster than length).
        /// @return | number | Squared vector length.
        methods.add_method("lengthSquared", |_, this, ()| {
            Ok(this.inner.length_squared() as f64)
        });

        // -- normalize --
        /// Returns a unit-length copy of this vector. Returns zero if length is zero.
        /// @return | LVec2 | Normalized vector.
        methods.add_method("normalize", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.normalize(),
            })
        });

        // -- normalized --
        /// Compatibility alias for `normalize`.
        /// @return | LVec2 | Normalized vector.
        methods.add_method("normalized", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.normalize(),
            })
        });

        // -- lerp --
        /// Returns a linearly interpolated vector between this and other at parameter t.
        /// @param | other | LVec2 | Target vector.
        /// @param | t | number | Interpolation factor.
        /// @return | LVec2 | Interpolated vector.
        methods.add_method("lerp", |lua, this, (other, t): (LuaAnyUserData, f64)| {
            let o = other.borrow::<LuaVec2>()?;
            lua.create_userdata(LuaVec2 {
                inner: this.inner.lerp(o.inner, t as f32),
            })
        });

        // -- distance --
        /// Returns the Euclidean distance from this vector to another.
        /// @param | other | LVec2 | Vector to measure against.
        /// @return | number | Distance between the vectors.
        methods.add_method("distance", |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner.distance(o.inner) as f64)
        });

        // -- angle --
        /// Returns the angle of this vector in radians (atan2(y, x)).
        /// @return | number | Vector angle in radians.
        methods.add_method("angle", |_, this, ()| Ok(this.inner.angle() as f64));

        // -- rotate --
        /// Returns a new vector rotated by the given angle in radians.
        /// @param | angle | number | Rotation angle in radians.
        /// @return | LVec2 | Rotated vector.
        methods.add_method("rotate", |lua, this, angle: f64| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.rotate(angle as f32),
            })
        });

        // -- perpendicular --
        /// Returns the perpendicular vector (-y, x).
        /// @return | LVec2 | Perpendicular vector.
        methods.add_method("perpendicular", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.perpendicular(),
            })
        });

        // -- cross --
        /// Returns the 2D cross product (scalar) with another vector.
        /// @param | other | LVec2 | Vector to cross against this vector.
        /// @return | number | Scalar cross product result.
        methods.add_method("cross", |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner.cross(o.inner) as f64)
        });

        // -- fromAngle --
        /// Creates a unit vector from an angle in radians.
        /// @param | radians | number | Angle in radians.
        /// @return | LVec2 | Unit vector for the angle.
        methods.add_function("fromAngle", |lua, radians: f64| {
            lua.create_userdata(LuaVec2 {
                inner: Vec2::from_angle(radians as f32),
            })
        });

        // -- reflect --
        /// Reflects this vector off a surface with the given normal.
        /// @param | normal | LVec2 | Surface normal.
        /// @return | LVec2 | Reflected vector.
        methods.add_method("reflect", |lua, this, normal: LuaAnyUserData| {
            let n = normal.borrow::<LuaVec2>()?;
            lua.create_userdata(LuaVec2 {
                inner: this.inner.reflect(n.inner),
            })
        });

        // Metamethods
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
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LVec2"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LVec2" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaVec3 UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Vec3`] value type.
///
/// # Fields
/// - `inner` — `Vec3`.
pub struct LuaVec3 {
    pub inner: Vec3,
}

impl LuaUserData for LuaVec3 {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        // -- x --
        /// The X component of the vector.
        fields.add_field_method_get("x", |_, this| Ok(this.inner.x));
        fields.add_field_method_set("x", |_, this, v: f32| {
            this.inner.x = v;
            Ok(())
        });
        // -- y --
        /// The Y component of the vector.
        fields.add_field_method_get("y", |_, this| Ok(this.inner.y));
        fields.add_field_method_set("y", |_, this, v: f32| {
            this.inner.y = v;
            Ok(())
        });
        // -- z --
        /// The Z component of the vector.
        fields.add_field_method_get("z", |_, this| Ok(this.inner.z));
        fields.add_field_method_set("z", |_, this, v: f32| {
            this.inner.z = v;
            Ok(())
        });
    }

    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- length --
        /// Returns the Euclidean length of the vector.
        /// @return | number | Vector length.
        methods.add_method("length", |_, this, ()| Ok(this.inner.length()));

        // -- lengthSquared --
        /// Returns the squared Euclidean length (avoids sqrt).
        /// @return | number | Squared vector length.
        methods.add_method("lengthSquared", |_, this, ()| {
            Ok(this.inner.length_squared())
        });

        // -- normalize --
        /// Returns a unit-length version of this vector.
        /// @return | LVec3 | Normalized vector.
        methods.add_method("normalize", |lua, this, ()| {
            lua.create_userdata(LuaVec3 {
                inner: this.inner.normalize(),
            })
        });

        // -- dot --
        /// Dot product with another Vec3.
        /// @param | other | LVec3 | Vector to dot against this vector.
        /// @return | number | Dot product result.
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            Ok(this.inner.dot(v.inner))
        });

        // -- cross --
        /// Cross product with another Vec3.
        /// @param | other | LVec3 | Vector to cross against this vector.
        /// @return | LVec3 | Cross product vector.
        methods.add_method("cross", |lua, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner.cross(v.inner),
            })
        });

        // -- lerp --
        /// Linear interpolation towards another Vec3.
        /// @param | other | LVec3 | Target vector.
        /// @param | t | number | Interpolation factor.
        /// @return | LVec3 | Interpolated vector.
        methods.add_method("lerp", |lua, this, (other, t): (LuaAnyUserData, f32)| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner.lerp(v.inner, t),
            })
        });

        // -- distance --
        /// Euclidean distance to another Vec3.
        /// @param | other | LVec3 | Vector to measure against.
        /// @return | number | Distance between the vectors.
        methods.add_method("distance", |_, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            Ok(this.inner.distance(v.inner))
        });

        // -- add --
        /// Add another Vec3 and return the result.
        /// @param | other | LVec3 | Vector to add.
        /// @return | LVec3 | Sum of the vectors.
        methods.add_method("add", |lua, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner + v.inner,
            })
        });

        // -- sub --
        /// Subtract another Vec3 and return the result.
        /// @param | other | LVec3 | Vector to subtract.
        /// @return | LVec3 | Difference of the vectors.
        methods.add_method("sub", |lua, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner - v.inner,
            })
        });

        // -- scale --
        /// Scale this vector by a scalar and return the result.
        /// @param | s | number | Scale factor.
        /// @return | LVec3 | Scaled vector.
        methods.add_method("scale", |lua, this, s: f32| {
            lua.create_userdata(LuaVec3 {
                inner: this.inner * s,
            })
        });

        // -- splat --
        /// Creates a Vec3 with all components set to `v`.
        /// @param | v | number | Component value to use for all axes.
        /// @return | LVec3 | Vector with all components set to the value.
        methods.add_function("splat", |lua, v: f32| {
            lua.create_userdata(LuaVec3 {
                inner: Vec3::splat(v),
            })
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LVec3"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LVec3" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaCatmullRom UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`CatmullRomSpline`].
pub struct LuaCatmullRom {
    inner: CatmullRomSpline,
}

impl LuaUserData for LuaCatmullRom {
    #[allow(clippy::map_identity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- sample --
        /// Samples the spline at global parameter `t` in `[0, 1]`.
        /// @param | t | number | Spline parameter.
        /// @return | number | X coordinate at the sampled point.
        /// @return | number | Y coordinate at the sampled point.
        methods.add_method("sample", |_, this, t: f32| {
            let (x, y) = this.inner.sample(t);
            Ok((x, y))
        });

        // -- sampleSegment --
        /// Samples one segment at local parameter `t` in `[0, 1]`.
        /// @param | seg | integer | Segment index.
        /// @param | t | number | Segment-local parameter.
        /// @return | number | X coordinate at the sampled point.
        /// @return | number | Y coordinate at the sampled point.
        methods.add_method("sampleSegment", |_, this, (seg, t): (usize, f32)| {
            let (x, y) = this.inner.sample_segment(seg, t);
            Ok((x, y))
        });

        // -- len --
        /// Number of control points.
        /// @return | integer | Control point count.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));

        // -- addPoint --
        /// Appends a control point to the spline.
        /// @param | x | number | Control point x coordinate.
        /// @param | y | number | Control point y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addPoint", |_, this, (x, y): (f32, f32)| {
            this.inner.add_point((x, y));
            Ok(())
        });

        // -- removePoint --
        /// Removes the control point at `index` (0-based) and returns it.
        /// @param | index | integer | Zero-based control point index.
        /// @return | number | Removed point X coordinate.
        /// @return | number | Removed point Y coordinate.
        methods.add_method_mut("removePoint", |_, this, idx: usize| {
            this.inner
                .remove_point(idx)
                .map(|(x, y)| (x, y))
                .ok_or_else(|| LuaError::RuntimeError("index out of bounds".into()))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LCatmullRom"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCatmullRom" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaHermite UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`HermiteSpline`].
pub struct LuaHermite {
    inner: HermiteSpline,
}

impl LuaUserData for LuaHermite {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- sample --
        /// Samples the spline at parameter `t` in `[0, 1]`.
        /// @param | t | number | Spline parameter.
        /// @return | number | X coordinate at the sampled point.
        /// @return | number | Y coordinate at the sampled point.
        methods.add_method("sample", |_, this, t: f32| {
            let (x, y) = this.inner.sample(t);
            Ok((x, y))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LHermite"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHermite" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaRandomGenerator UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`RandomGenerator`].
pub struct LuaRandomGenerator {
    inner: RandomGenerator,
}

impl LuaUserData for LuaRandomGenerator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- random --
        /// Returns a uniform random number in [0, 1).
        /// @return | number | Random value.
        methods.add_method_mut("random", |_, this, ()| Ok(this.inner.random()));

        // -- randomFloat --
        /// Returns a uniform random float in [min, max).
        /// @param | min | number | Lower bound.
        /// @param | max | number | Upper bound.
        /// @return | number | Random value in the range.
        methods.add_method_mut("randomFloat", |_, this, (min, max): (f64, f64)| {
            Ok(this.inner.random_float(min, max))
        });

        // -- randomInt --
        /// Returns a uniform random integer in [min, max].
        /// @param | min | integer | Lower bound.
        /// @param | max | integer | Upper bound.
        /// @return | integer | Random integer in the range.
        methods.add_method_mut("randomInt", |_, this, (min, max): (i64, i64)| {
            Ok(this.inner.random_int(min, max))
        });

        // -- randomNormal --
        /// Returns a random number from a normal (Gaussian) distribution.
        /// @param | stddev | number? | Standard deviation override.
        /// @param | mean | number? | Mean override.
        /// @return | number | Random value from the distribution.
        methods.add_method_mut(
            "randomNormal",
            |_, this, (stddev, mean): (Option<f64>, Option<f64>)| {
                Ok(this
                    .inner
                    .random_normal(stddev.unwrap_or(1.0), mean.unwrap_or(0.0)))
            },
        );

        // -- getSeed --
        /// Returns the seed used to initialise this generator.
        /// @return | integer | Current seed value.
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.get_seed()));

        // -- setSeed --
        /// Sets the seed, fully resetting the generator state.
        /// @param | seed | integer | Seed value to apply.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSeed", |_, this, seed: u64| {
            this.inner.set_seed(seed);
            Ok(())
        });

        // -- getState --
        /// Serialises the generator state as a string for later restoration.
        /// @return | string | Serialized generator state.
        methods.add_method("getState", |_, this, ()| Ok(this.inner.get_state()));

        // -- setState --
        /// Restores the generator state from a previously serialised string.
        /// @param | state | string | Serialized generator state.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setState", |_, this, state: String| {
            this.inner.set_state(&state).map_err(LuaError::external)?;
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LRandomGenerator"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LRandomGenerator" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaTransform UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Transform`].
pub struct LuaTransform {
    inner: Transform,
}

impl LuaUserData for LuaTransform {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- translate --
        /// Applies translation to the transform.
        /// @param | dx | number | Horizontal offset.
        /// @param | dy | number | Vertical offset.
        /// @return | nil | No value is returned.
        methods.add_method_mut("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.translate(dx, dy);
            Ok(())
        });

        // -- rotate --
        /// Applies a rotation in radians.
        /// @param | angle | number | Rotation angle in radians.
        /// @return | nil | No value is returned.
        methods.add_method_mut("rotate", |_, this, angle: f32| {
            this.inner.rotate(angle);
            Ok(())
        });

        // -- scale --
        /// Applies non-uniform scaling.
        /// @param | sx | number | Horizontal scale factor.
        /// @param | sy | number? | Vertical scale factor.
        /// @return | nil | No value is returned.
        methods.add_method_mut("scale", |_, this, (sx, sy): (f32, Option<f32>)| {
            this.inner.scale(sx, sy.unwrap_or(sx));
            Ok(())
        });

        // -- shear --
        /// Applies horizontal and vertical shear factors to this transform matrix.
        /// @param | kx | number | Horizontal shear factor.
        /// @param | ky | number | Vertical shear factor.
        /// @return | nil | No value is returned.
        methods.add_method_mut("shear", |_, this, (kx, ky): (f32, f32)| {
            this.inner.shear(kx, ky);
            Ok(())
        });

        // -- reset --
        /// Resets the transform to identity.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });

        // -- setTransformation --
        /// Replaces the transform with full transformation parameters.
        /// @param | x | number | Translation x value.
        /// @param | y | number | Translation y value.
        /// @param | angle | number? | Rotation angle in radians.
        /// @param | sx | number? | Horizontal scale factor.
        /// @param | sy | number? | Vertical scale factor.
        /// @param | ox | number? | Origin x value.
        /// @param | oy | number? | Origin y value.
        /// @param | kx | number? | Horizontal shear factor.
        /// @param | ky | number? | Vertical shear factor.
        /// @return | nil | No value is returned.
        #[allow(clippy::too_many_arguments, clippy::type_complexity)]
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
        /// Transforms a point from local space to world space.
        /// @param | x | number | Local-space x coordinate.
        /// @param | y | number | Local-space y coordinate.
        /// @return | number | World-space X coordinate.
        /// @return | number | World-space Y coordinate.
        methods.add_method("transformPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.transform_point(x, y))
        });

        // -- inverseTransformPoint --
        /// Transforms a point from world space back to local space.
        /// @param | x | number | World-space x coordinate.
        /// @param | y | number | World-space y coordinate.
        /// @return | number | Local-space X coordinate.
        /// @return | number | Local-space Y coordinate.
        methods.add_method("inverseTransformPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.inverse_transform_point(x, y))
        });

        // -- inverse --
        /// Returns a new Transform that undoes this transform.
        /// @return | LTransform | Inverse transform.
        methods.add_method("inverse", |lua, this, ()| {
            lua.create_userdata(LuaTransform {
                inner: this.inner.inverse(),
            })
        });

        // -- clone --
        /// Returns a copy of this transform.
        /// @return | LTransform | Copy of this transform.
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(LuaTransform { inner: this.inner })
        });

        // -- getMatrix --
        /// Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
        /// @return | table | Row-major 3x3 matrix values.
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
        /// Decomposes this transform into translation, rotation, and scale.
        /// @return | number | Translation X component.
        /// @return | number | Translation Y component.
        /// @return | number | Rotation angle.
        /// @return | number | Scale X component.
        /// @return | number | Scale Y component.
        methods.add_method("decompose", |_, this, ()| Ok(this.inner.decompose()));

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LTransform"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTransform" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaBezierCurve UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`BezierCurve`].
pub struct LuaBezierCurve {
    inner: BezierCurve,
}

impl LuaUserData for LuaBezierCurve {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- evaluate --
        /// Evaluates the curve at parameter t, returning (x, y).
        /// @param | t | number | Curve parameter.
        /// @return | number | Evaluated X coordinate.
        /// @return | number | Evaluated Y coordinate.
        methods.add_method("evaluate", |_, this, t: f32| {
            let p = this.inner.evaluate(t);
            Ok((p.x, p.y))
        });

        // -- render --
        /// Renders the curve as a polyline with the given number of segments.
        /// @param | segments | integer | Number of polyline segments.
        /// @return | table | Rendered points as `{x, y}` arrays.
        methods.add_method("render", |lua, this, segments: usize| {
            let points = this.inner.render(segments);
            let t = lua.create_table()?;
            for (i, p) in points.iter().enumerate() {
                t.set(i + 1, vec![p.x, p.y])?;
            }
            Ok(t)
        });

        // -- getDerivative --
        /// Returns a new BezierCurve representing the first derivative.
        /// @return | LBezierCurve | First-derivative curve.
        methods.add_method("getDerivative", |lua, this, ()| {
            lua.create_userdata(LuaBezierCurve {
                inner: this.inner.get_derivative(),
            })
        });

        // -- getControlPoint --
        /// Returns the control point at 1-based index as (x, y), or nil.
        /// @param | index | integer | One-based control point index.
        /// @return | number | Control point X coordinate.
        /// @return | number | Control point Y coordinate.
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
        /// Sets the control point at 1-based index.
        /// @param | index | integer | One-based control point index.
        /// @param | x | number | Control point x coordinate.
        /// @param | y | number | Control point y coordinate.
        /// @return | boolean | True when the control point was updated.
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
        /// Inserts a control point. If index is given (1-based), inserts at that position.
        /// @param | x | number | Control point x coordinate.
        /// @param | y | number | Control point y coordinate.
        /// @param | index | integer? | Optional one-based insertion index.
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
        /// Removes a control point at 1-based index.
        /// @param | index | integer | One-based control point index.
        /// @return | boolean | True when the control point was removed.
        methods.add_method_mut("removeControlPoint", |_, this, index: usize| {
            if index == 0 {
                return Ok(false);
            }
            Ok(this.inner.remove_control_point(index - 1))
        });

        // -- getControlPointCount --
        /// Returns the number of control points.
        /// @return | integer | Control point count.
        methods.add_method("getControlPointCount", |_, this, ()| {
            Ok(this.inner.get_control_point_count())
        });

        // -- length --
        /// Returns the approximate arc length of the curve.
        /// @return | number | Approximate arc length.
        methods.add_method("length", |_, this, ()| Ok(this.inner.length()));

        // -- translate --
        /// Translates all control points by (dx, dy).
        /// @param | dx | number | Horizontal offset.
        /// @param | dy | number | Vertical offset.
        /// @return | nil | No value is returned.
        methods.add_method_mut("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.translate(dx, dy);
            Ok(())
        });

        // -- rotate --
        /// Rotates all control points around a pivot by angle radians.
        /// @param | angle | number | Rotation angle in radians.
        /// @param | ox | number | Pivot x coordinate.
        /// @param | oy | number | Pivot y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method_mut("rotate", |_, this, (angle, ox, oy): (f32, f32, f32)| {
            this.inner.rotate(angle, ox, oy);
            Ok(())
        });

        // -- scale --
        /// Scales all control points around a pivot by factor s.
        /// @param | s | number | Scale factor.
        /// @param | ox | number | Pivot x coordinate.
        /// @param | oy | number | Pivot y coordinate.
        /// @return | nil | No value is returned.
        methods.add_method_mut("scale", |_, this, (s, ox, oy): (f32, f32, f32)| {
            this.inner.scale(s, ox, oy);
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LBezierCurve"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBezierCurve" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaTween UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Tween`].
pub struct LuaTween {
    inner: Tween,
}

impl LuaUserData for LuaTween {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- update --
        /// Advances the clock by dt seconds. Returns true when complete.
        /// @param | dt | number | Time step in seconds.
        /// @return | boolean | True when the tween is complete.
        methods.add_method_mut("update", |_, this, dt: f64| Ok(this.inner.update(dt)));

        // -- reset --
        /// Resets the tween elapsed time to zero, restarting the animation.
        /// @return | nil | No value is returned.
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });

        // -- getValue --
        /// Returns the interpolated value at 1-based index, or all values when no index is given.
        /// @param | index | integer? | Optional one-based value index.
        /// @return | number | Value at the given index, or a table when no index is given.
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
        /// Returns all interpolated values as a table.
        /// @return | table | All tween values.
        methods.add_method("getAllValues", |lua, this, ()| {
            let vals = this.inner.get_all_values();
            let t = lua.create_table()?;
            for (i, v) in vals.iter().enumerate() {
                t.set(i + 1, *v)?;
            }
            Ok(t)
        });

        // -- isComplete --
        /// Returns true if the tween has finished.
        /// @return | boolean | True when the tween is complete.
        methods.add_method("isComplete", |_, this, ()| Ok(this.inner.is_complete()));

        // -- getValueCount --
        /// Returns the number of values in this tween.
        /// @return | integer | Number of tweened values.
        methods.add_method("getValueCount", |_, this, ()| Ok(this.inner.value_count()));

        // -- getEasingName --
        /// Returns the easing function name.
        /// @return | string | Easing function name.
        methods.add_method("getEasingName", |_, this, ()| {
            Ok(this.inner.easing_name().to_string())
        });

        // -- getDuration --
        /// Returns the tween duration in seconds.
        /// @return | number | Tween duration.
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.duration()));

        // -- getTime --
        /// Returns the current clock time.
        /// @return | number | Current tween time.
        methods.add_method("getTime", |_, this, ()| Ok(this.inner.clock()));

        // -- getClock --
        /// Alias for getTime(). Returns the current clock time.
        /// @return | number | Current tween time.
        methods.add_method("getClock", |_, this, ()| Ok(this.inner.clock()));

        // -- setTime --
        /// Sets the clock to a specific time, clamped to [0, duration].
        /// @param | t | number | New tween time.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setTime", |_, this, t: f64| {
            this.inner.set_time(t);
            Ok(())
        });

        // -- set --
        /// Alias for setTime(). Sets the clock to t, clamped to [0, duration].
        /// @param | t | number | New tween time.
        /// @return | nil | No value is returned.
        methods.add_method_mut("set", |_, this, t: f64| {
            this.inner.set_time(t);
            Ok(())
        });

        // -- addValue --
        /// Adds a start/target value pair. Returns the 1-based index.
        /// @param | start | number | Start value.
        /// @param | target | number | Target value.
        /// @return | integer | One-based value index.
        methods.add_method_mut("addValue", |_, this, (start, target): (f64, f64)| {
            Ok(this.inner.add_value(start, target) + 1)
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LTween"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTween" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaSpatialHash UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`SpatialHash`].
pub struct LuaSpatialHash {
    inner: SpatialHash,
}

impl LuaUserData for LuaSpatialHash {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- insert --
        /// Inserts an item with the given AABB.
        /// @param | id | string | Item identifier.
        /// @param | x | number | AABB x coordinate.
        /// @param | y | number | AABB y coordinate.
        /// @param | w | number | AABB width.
        /// @param | h | number | AABB height.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "insert",
            |_, this, (id, x, y, w, h): (String, f32, f32, f32, f32)| {
                this.inner.insert(id, x, y, w, h);
                Ok(())
            },
        );

        // -- update --
        /// Updates an existing item's AABB.
        /// @param | id | string | Item identifier.
        /// @param | x | number | AABB x coordinate.
        /// @param | y | number | AABB y coordinate.
        /// @param | w | number | AABB width.
        /// @param | h | number | AABB height.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "update",
            |_, this, (id, x, y, w, h): (String, f32, f32, f32, f32)| {
                this.inner.update(id, x, y, w, h);
                Ok(())
            },
        );

        // -- remove --
        /// Removes an item by its ID.
        /// @param | id | string | Item identifier.
        /// @return | nil | No value is returned.
        methods.add_method_mut("remove", |_, this, id: String| {
            this.inner.remove(&id);
            Ok(())
        });

        // -- clear --
        /// Removes all registered items from this spatial hash, leaving it empty.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- queryRect --
        /// Returns IDs of items overlapping the query rectangle.
        /// @param | x | number | Query rectangle x coordinate.
        /// @param | y | number | Query rectangle y coordinate.
        /// @param | w | number | Query rectangle width.
        /// @param | h | number | Query rectangle height.
        /// @return | table | Matching item IDs.
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
        /// Returns IDs of items overlapping the query circle.
        /// @param | cx | number | Circle center x coordinate.
        /// @param | cy | number | Circle center y coordinate.
        /// @param | radius | number | Circle radius.
        /// @return | table | Matching item IDs.
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
        /// Returns IDs of items whose AABBs are intersected by the line segment.
        /// @param | x1 | number | Segment start x coordinate.
        /// @param | y1 | number | Segment start y coordinate.
        /// @param | x2 | number | Segment end x coordinate.
        /// @param | y2 | number | Segment end y coordinate.
        /// @return | table | Matching item IDs.
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
        /// Returns the cell size used to partition the spatial hash grid.
        /// @return | number | Spatial hash cell size.
        methods.add_method("getCellSize", |_, this, ()| Ok(this.inner.cell_size()));

        // -- getItemCount --
        /// Returns the number of items in the hash.
        /// @return | integer | Number of stored items.
        methods.add_method("getItemCount", |_, this, ()| Ok(this.inner.item_count()));

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LSpatialHash"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpatialHash" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaNoiseGenerator UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`NoiseGenerator`].
pub struct LuaNoiseGenerator {
    inner: NoiseGenerator,
}

// Resolves a noise kind string name to a [`NoiseKind`] enum.
fn resolve_noise_kind(name: &str) -> NoiseKind {
    match name.to_lowercase().as_str() {
        "simplex" => NoiseKind::Simplex,
        _ => NoiseKind::Perlin,
    }
}

// Resolves a distance type string name to a [`DistType`] enum.
fn resolve_dist_type(name: &str) -> DistType {
    match name.to_lowercase().as_str() {
        "manhattan" => DistType::Manhattan,
        "chebyshev" => DistType::Chebyshev,
        _ => DistType::Euclidean,
    }
}

// Resolves a fractal type string name to a [`FractalType`] enum.
fn resolve_fractal_type(name: &str) -> FractalType {
    match name.to_lowercase().as_str() {
        "ridged" => FractalType::Ridged,
        "turbulence" => FractalType::Turbulence,
        _ => FractalType::Fbm,
    }
}

impl LuaUserData for LuaNoiseGenerator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- perlin1d --
        /// Returns 1D Perlin noise at x.
        /// @param | x | number | Sample x coordinate.
        /// @return | number | Noise value.
        methods.add_method("perlin1d", |_, this, x: f64| Ok(this.inner.perlin_1d(x)));

        // -- perlin2d --
        /// Returns 2D Perlin noise at (x, y).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @return | number | Noise value.
        methods.add_method("perlin2d", |_, this, (x, y): (f64, f64)| {
            Ok(this.inner.perlin_2d(x, y))
        });

        // -- perlin3d --
        /// Returns 3D Perlin noise at (x, y, z).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @param | z | number | Sample z coordinate.
        /// @return | number | Noise value.
        methods.add_method("perlin3d", |_, this, (x, y, z): (f64, f64, f64)| {
            Ok(this.inner.perlin_3d(x, y, z))
        });

        // -- perlin4d --
        /// Returns 4D Perlin noise at (x, y, z, w).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @param | z | number | Sample z coordinate.
        /// @param | w | number | Sample w coordinate.
        /// @return | number | Noise value.
        methods.add_method("perlin4d", |_, this, (x, y, z, w): (f64, f64, f64, f64)| {
            Ok(this.inner.perlin_4d(x, y, z, w))
        });

        // -- simplex1d --
        /// Returns 1D Simplex noise at x.
        /// @param | x | number | Sample x coordinate.
        /// @return | number | Noise value.
        methods.add_method("simplex1d", |_, this, x: f64| Ok(this.inner.simplex_1d(x)));

        // -- simplex2d --
        /// Returns 2D Simplex noise at (x, y).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @return | number | Noise value.
        methods.add_method("simplex2d", |_, this, (x, y): (f64, f64)| {
            Ok(this.inner.simplex_2d(x, y))
        });

        // -- simplex3d --
        /// Returns 3D Simplex noise at (x, y, z).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @param | z | number | Sample z coordinate.
        /// @return | number | Noise value.
        methods.add_method("simplex3d", |_, this, (x, y, z): (f64, f64, f64)| {
            Ok(this.inner.simplex_3d(x, y, z))
        });

        // -- worley2d --
        /// Returns 2D Worley (cellular) noise at (x, y).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @param | distType | string? | Optional distance metric name.
        /// @param | f2 | boolean? | Optional second-feature toggle.
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
        /// Returns 3D Worley (cellular) noise at (x, y, z).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @param | z | number | Sample z coordinate.
        /// @param | distType | string? | Optional distance metric name.
        /// @param | f2 | boolean? | Optional second-feature toggle.
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
        /// Returns fractal Brownian motion noise at (x, y).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @param | octaves | integer? | Optional octave count.
        /// @param | lacunarity | number? | Optional lacunarity value.
        /// @param | persistence | number? | Optional persistence value.
        /// @param | kind | string? | Optional base noise kind.
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
        /// Returns ridged multi-fractal noise at (x, y).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @param | octaves | integer? | Optional octave count.
        /// @param | lacunarity | number? | Optional lacunarity value.
        /// @param | persistence | number? | Optional persistence value.
        /// @param | kind | string? | Optional base noise kind.
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
        /// Returns turbulence noise at (x, y).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @param | octaves | integer? | Optional octave count.
        /// @param | lacunarity | number? | Optional lacunarity value.
        /// @param | persistence | number? | Optional persistence value.
        /// @param | kind | string? | Optional base noise kind.
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
        /// Applies domain warping, returning offset (x, y).
        /// @param | x | number | Sample x coordinate.
        /// @param | y | number | Sample y coordinate.
        /// @param | strength | number | Warp strength.
        /// @return | number | Warped X coordinate.
        /// @return | number | Warped Y coordinate.
        methods.add_method(
            "warpDomain",
            |_, this, (x, y, strength): (f64, f64, f64)| Ok(this.inner.warp_domain(x, y, strength)),
        );

        // -- generateMap --
        /// Generates a 2D noise map as a flat table (row-major).
        /// @param | width | integer | Map width.
        /// @param | height | integer | Map height.
        /// @param | opts | table? | Optional generation settings.
        /// @return | table | Flat row-major noise values.
        methods.add_method(
            "generateMap",
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
                let data = this.inner.generate_map(w, h, &map_opts);
                let result = lua.create_table()?;
                for (i, v) in data.iter().enumerate() {
                    result.set(i + 1, *v)?;
                }
                Ok(result)
            },
        );

        // -- getSeed --
        /// Returns the current seed.
        /// @return | integer | Current seed value.
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.seed()));

        // -- setSeed --
        /// Sets the seed and rebuilds the permutation table.
        /// @param | seed | integer | Seed value to apply.
        /// @return | nil | No value is returned.
        methods.add_method_mut("setSeed", |_, this, seed: u64| {
            this.inner.set_seed(seed);
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LNoiseGenerator"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNoiseGenerator" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

// -------------------------------------------------------------------------------
// LuaCircle UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`Circle`].
pub struct LuaCircle {
    inner: Circle,
}

impl LuaUserData for LuaCircle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- area --
        /// Returns the area of the circle (π r²).
        /// @return | number | Circle area.
        methods.add_method("area", |_, this, ()| Ok(this.inner.area()));

        // -- perimeter --
        /// Returns the circumference of the circle (2 π r).
        /// @return | number | Circle perimeter.
        methods.add_method("perimeter", |_, this, ()| Ok(this.inner.perimeter()));

        // -- contains --
        /// Returns true if the point (px, py) lies inside or on the boundary.
        /// @param | px | number | Point x coordinate.
        /// @param | py | number | Point y coordinate.
        /// @return | boolean | True when the point lies inside or on the circle.
        methods.add_method("contains", |_, this, (px, py): (f32, f32)| {
            Ok(this.inner.contains(px, py))
        });

        // -- intersects --
        /// Returns true if this circle overlaps another circle.
        /// @param | other | LCircle | Circle to test against.
        /// @return | boolean | True when the circles overlap.
        methods.add_method("intersects", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaCircle>()?;
            Ok(this.inner.intersects(&other.inner))
        });

        // -- aabb --
        /// Returns the axis-aligned bounding box as (min_x, min_y, max_x, max_y).
        /// @return | number | Minimum X coordinate.
        /// @return | number | Minimum Y coordinate.
        /// @return | number | Maximum X coordinate.
        /// @return | number | Maximum Y coordinate.
        methods.add_method("aabb", |_, this, ()| {
            let (x1, y1, x2, y2) = this.inner.aabb();
            Ok((x1, y1, x2, y2))
        });

        // -- x --
        /// Returns the circle centre X.
        /// @return | number | Circle center x coordinate.
        methods.add_method("x", |_, this, ()| Ok(this.inner.x));

        // -- y --
        /// Returns the circle centre Y.
        /// @return | number | Circle center y coordinate.
        methods.add_method("y", |_, this, ()| Ok(this.inner.y));

        // -- radius --
        /// Returns the circle radius.
        /// @return | number | Circle radius.
        methods.add_method("radius", |_, this, ()| Ok(this.inner.radius));

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LCircle"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCircle" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// LuaAabbTree UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around an [`AabbTree`].
///
/// # Fields
/// - `inner` — The underlying AABB tree.
pub struct LuaAabbTree {
    inner: AabbTree,
}

impl LuaUserData for LuaAabbTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- insert --
        /// Inserts an entry with the given AABB into the tree.
        /// @param | id | integer | Entry identifier.
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
        /// Removes the entry with the given id.
        /// @param | id | integer | Entry identifier.
        /// @return | boolean | True when the entry was removed.
        methods.add_method_mut("remove", |_, this, id: u64| Ok(this.inner.remove(id)));

        // -- query --
        /// Returns the ids of all entries whose AABBs overlap the query rectangle.
        /// @param | min_x | number | Query minimum x coordinate.
        /// @param | min_y | number | Query minimum y coordinate.
        /// @param | max_x | number | Query maximum x coordinate.
        /// @param | max_y | number | Query maximum y coordinate.
        /// @return | table | Matching entry IDs.
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
        /// Returns the ids of all entries whose AABBs contain the given point.
        /// @param | x | number | Point x coordinate.
        /// @param | y | number | Point y coordinate.
        /// @return | table | Matching entry IDs.
        methods.add_method("queryPoint", |lua, this, (x, y): (f32, f32)| {
            let ids = this.inner.query_point(x, y);
            let t = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                t.set(i + 1, *id)?;
            }
            Ok(t)
        });

        // -- update --
        /// Updates the AABB for an existing entry.
        /// @param | id | integer | Entry identifier.
        /// @param | min_x | number | Minimum x coordinate.
        /// @param | min_y | number | Minimum y coordinate.
        /// @param | max_x | number | Maximum x coordinate.
        /// @param | max_y | number | Maximum y coordinate.
        /// @return | boolean | True when the entry was updated.
        methods.add_method_mut(
            "update",
            |_, this, (id, min_x, min_y, max_x, max_y): (u64, f32, f32, f32, f32)| {
                Ok(this.inner.update(id, min_x, min_y, max_x, max_y))
            },
        );

        // -- contains --
        /// Returns true if an entry with the given id exists in the tree.
        /// @param | id | integer | Entry identifier.
        /// @return | boolean | True when the entry exists.
        methods.add_method("contains", |_, this, id: u64| Ok(this.inner.contains(id)));

        // -- len --
        /// Returns the number of entries in the tree.
        /// @return | integer | Entry count.
        methods.add_method("len", |_, this, ()| Ok(this.inner.len() as i64));

        // -- isEmpty --
        /// Returns true if the tree contains no entries.
        /// @return | boolean | True when the tree is empty.
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.is_empty()));

        // -- clear --
        /// Removes all entries from the tree.
        /// @return | nil | No value is returned.
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return | string | Lua-visible type name.
        methods.add_method("type", |_, _, ()| Ok("LAabbTree"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param | name | string | Type name to compare against.
        /// @return | boolean | True when the type name matches.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAabbTree" || name == "Object")
        });
    }
}

/// Registers the `lurek.math` API table with the Lua VM.
/// @param | lua | Lua | Lua state.
/// @param | luna | LuaTable | Root `lurek` table.
/// @param | _state | SharedState | Shared engine state.
/// @return | nil | No value is returned.
#[allow(clippy::type_complexity)]
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── Factory functions ────────────────────────────────────────────

    // -- newRandomGenerator --
    /// Creates a new random number generator with an optional seed.
    /// @param | seed | integer? | Optional seed value.
    /// @return | LRandomGenerator | New random generator.
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
    /// Creates a new Transform, optionally initialised from full parameters.
    /// @param | x | number? | Translation x value.
    /// @param | y | number? | Translation y value.
    /// @param | angle | number? | Rotation angle in radians.
    /// @param | sx | number? | Horizontal scale factor.
    /// @param | sy | number? | Vertical scale factor.
    /// @param | ox | number? | Origin x value.
    /// @param | oy | number? | Origin y value.
    /// @param | kx | number? | Horizontal shear factor.
    /// @param | ky | number? | Vertical shear factor.
    /// @return | LTransform | New transform.
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
    /// Creates a new BezierCurve from a flat table of coordinates {x1,y1, x2,y2, ...}.
    /// @param | points | table | Flat coordinate list.
    /// @return | LBezierCurve | New Bezier curve.
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
    /// Creates a new Tween with the given duration and easing name.
    /// @param | duration | number | Tween duration in seconds.
    /// @param | easingName | string? | Optional easing function name.
    /// @return | LTween | New tween.
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
    /// Creates a new SpatialHash with the given cell size.
    /// @param | cellSize | number | Spatial hash cell size.
    /// @return | LSpatialHash | New spatial hash.
    tbl.set(
        "newSpatialHash",
        lua.create_function(|lua, cell_size: f32| {
            lua.create_userdata(LuaSpatialHash {
                inner: SpatialHash::new(cell_size),
            })
        })?,
    )?;

    // -- newNoiseGenerator --
    /// Creates a new seeded noise generator.
    /// @param | seed | integer? | Optional seed value.
    /// @return | LNoiseGenerator | New noise generator.
    tbl.set(
        "newNoiseGenerator",
        lua.create_function(|lua, seed: Option<u64>| {
            lua.create_userdata(LuaNoiseGenerator {
                inner: NoiseGenerator::new(seed.unwrap_or(0)),
            })
        })?,
    )?;

    // ── Free noise functions ─────────────────────────────────────────

    // -- perlin2d --
    /// Returns 2D Perlin noise at (x, y) with the given seed.
    /// @param | x | number | Sample x coordinate.
    /// @param | y | number | Sample y coordinate.
    /// @param | seed | integer? | Optional seed override.
    /// @return | number | Noise value.
    tbl.set(
        "perlin2d",
        lua.create_function(|_, (x, y, seed): (f32, f32, Option<u32>)| {
            Ok(noise_functions::perlin2d(x, y, seed.unwrap_or(0)))
        })?,
    )?;

    // -- perlin3d --
    /// Returns 3D Perlin noise at (x, y, z) with the given seed.
    /// @param | x | number | Sample x coordinate.
    /// @param | y | number | Sample y coordinate.
    /// @param | z | number | Sample z coordinate.
    /// @param | seed | integer? | Optional seed override.
    /// @return | number | Noise value.
    tbl.set(
        "perlin3d",
        lua.create_function(|_, (x, y, z, seed): (f32, f32, f32, Option<u32>)| {
            Ok(noise_functions::perlin3d(x, y, z, seed.unwrap_or(0)))
        })?,
    )?;

    // -- simplex2d --
    /// Returns 2D Simplex noise at (x, y) with the given seed.
    /// @param | x | number | Sample x coordinate.
    /// @param | y | number | Sample y coordinate.
    /// @param | seed | integer? | Optional seed override.
    /// @return | number | Noise value.
    tbl.set(
        "simplex2d",
        lua.create_function(|_, (x, y, seed): (f32, f32, Option<u32>)| {
            Ok(noise_functions::simplex2d(x, y, seed.unwrap_or(0)))
        })?,
    )?;

    // -- fbm --
    /// Returns fractal Brownian motion noise at (x, y).
    /// @param | x | number | Sample x coordinate.
    /// @param | y | number | Sample y coordinate.
    /// @param | seed | integer? | Optional seed override.
    /// @param | octaves | integer? | Optional octave count.
    /// @param | lacunarity | number? | Optional lacunarity value.
    /// @param | gain | number? | Optional gain value.
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

    // ── Easing functions ─────────────────────────────────────────────

    // -- applyEasing --
    /// Applies a named easing function to progress value t.
    /// @param | name | string | Easing function name.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "applyEasing",
        lua.create_function(|_, (name, t): (String, f32)| {
            easing::apply(&name, t)
                .ok_or_else(|| LuaError::external(format!("Unknown easing function: {}", name)))
        })?,
    )?;

    // -- linear --
    /// Linear easing (identity).
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "linear",
        lua.create_function(|_, t: f32| Ok(easing::linear(t)))?,
    )?;

    // -- inQuad --
    /// Quadratic ease-in — acceleration that starts at zero and increases.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_quad(t)))?,
    )?;

    // -- outQuad --
    /// Quadratic ease-out — deceleration that starts fast and ends at zero.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "outQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_quad(t)))?,
    )?;

    // -- inOutQuad --
    /// Quadratic ease-in-out — slow start, fast middle, slow end.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_quad(t)))?,
    )?;

    // -- inCubic --
    /// Cubic ease-in — acceleration starts slowly then increases sharply.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_cubic(t)))?,
    )?;

    // -- outCubic --
    /// Cubic ease-out — rapid deceleration using a cubic power curve.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "outCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_cubic(t)))?,
    )?;

    // -- inOutCubic --
    /// Cubic ease-in-out — slow start and end with fast cubic middle.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_cubic(t)))?,
    )?;

    // -- inQuart --
    /// Quartic ease-in — strongly delayed acceleration using a power-of-4 curve.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_quart(t)))?,
    )?;

    // -- outQuart --
    /// Quartic ease-out — rapid deceleration using a power-of-4 curve.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "outQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_quart(t)))?,
    )?;

    // -- inOutQuart --
    /// Quartic ease-in-out — very slow start and end with a sharp middle peak.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_quart(t)))?,
    )?;

    // -- inSine --
    /// Sinusoidal ease-in — gentle acceleration based on a sine curve.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_sine(t)))?,
    )?;

    // -- outSine --
    /// Sinusoidal ease-out — gentle deceleration based on a cosine curve.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "outSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_sine(t)))?,
    )?;

    // -- inOutSine --
    /// Sinusoidal ease-in-out — smooth S-curve based on cosine interpolation.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_sine(t)))?,
    )?;

    // -- inExpo --
    /// Exponential ease-in — very slow start that accelerates sharply near the end.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_expo(t)))?,
    )?;

    // -- outExpo --
    /// Exponential ease-out — sharp initial speed that decelerates exponentially.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "outExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_expo(t)))?,
    )?;

    // -- inOutExpo --
    /// Exponential ease-in-out — very slow start and end with an exponential surge.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_expo(t)))?,
    )?;

    // -- inElastic --
    /// Elastic ease-in — spring-like overshoot at the beginning of the motion.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_elastic(t)))?,
    )?;

    // -- outElastic --
    /// Elastic ease-out — spring-like oscillation that settles at the target.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "outElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_elastic(t)))?,
    )?;

    // -- outBounce --
    /// Bounce ease-out — simulates a ball bouncing against the target value.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "outBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_bounce(t)))?,
    )?;

    // -- inBounce --
    /// Bounce ease-in — reverse bounce effect that accelerates into the motion.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_bounce(t)))?,
    )?;

    // -- inBack --
    /// Back ease-in — overshoots slightly before settling at the target.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_back(t)))?,
    )?;

    // -- outBack --
    /// Back ease-out — overshoots the target then snaps back into place.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "outBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_back(t)))?,
    )?;

    // -- inOutElastic --
    /// Elastic ease-in-out — spring-like oscillation on both ends.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_elastic(t)))?,
    )?;

    // -- inOutBounce --
    /// Bounce ease-in-out — bouncing motion on both ends.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_bounce(t)))?,
    )?;

    // -- inOutBack --
    /// Back ease-in-out — overshoot on both ends.
    /// @param | t | number | Progress value.
    /// @return | number | Eased value.
    tbl.set(
        "inOutBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_back(t)))?,
    )?;

    // ── Geometry ─────────────────────────────────────────────────────

    // -- triangulate --
    /// Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
    /// @param | polygon | table | Flat polygon vertex list.
    /// @return | table | Triangle tables with 6 numbers each.
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
    /// Returns true if the polygon (flat table {x1,y1,...}) is convex.
    /// @param | polygon | table | Flat polygon vertex list.
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

    // ── Color space ──────────────────────────────────────────────────

    // -- gammaToLinear --
    /// Converts a gamma-encoded sRGB value to linear space.
    /// @param | c | number | Gamma-encoded value.
    /// @return | number | Linear-space value.
    tbl.set(
        "gammaToLinear",
        lua.create_function(|_, c: f32| Ok(gamma_to_linear(c)))?,
    )?;

    // -- linearToGamma --
    /// Converts a linear-space value to gamma-encoded sRGB.
    /// @param | c | number | Linear-space value.
    /// @return | number | Gamma-encoded value.
    tbl.set(
        "linearToGamma",
        lua.create_function(|_, c: f32| Ok(linear_to_gamma(c)))?,
    )?;

    // ── Geometry ────────────────────────────────────────────────────

    // -- angleBetween --
    /// Returns the angle in radians from (x1, y1) to (x2, y2).
    /// @param | x1 | number | Start x coordinate.
    /// @param | y1 | number | Start y coordinate.
    /// @param | x2 | number | End x coordinate.
    /// @param | y2 | number | End y coordinate.
    /// @return | number | Angle in radians.
    tbl.set(
        "angleBetween",
        lua.create_function(|_, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            Ok(geometry::angle_between(x1, y1, x2, y2))
        })?,
    )?;

    // -- circleContainsPoint --
    /// Returns true if the point (px, py) lies inside the circle.
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
    /// Returns true if two circles overlap.
    /// @param | x1 | number | First circle center x coordinate.
    /// @param | y1 | number | First circle center y coordinate.
    /// @param | r1 | number | First circle radius.
    /// @param | x2 | number | Second circle center x coordinate.
    /// @param | y2 | number | Second circle center y coordinate.
    /// @param | r2 | number | Second circle radius.
    /// @return | boolean | True when the circles overlap.
    tbl.set(
        "circleIntersectsCircle",
        lua.create_function(
            |_, (x1, y1, r1, x2, y2, r2): (f32, f32, f32, f32, f32, f32)| {
                Ok(geometry::circle_intersects_circle(x1, y1, r1, x2, y2, r2))
            },
        )?,
    )?;

    // -- circleIntersectsLine --
    /// Tests an infinite line against a circle. Returns hit, then two optional hit-point pairs.
    /// @param | cx | number | Circle center x coordinate.
    /// @param | cy | number | Circle center y coordinate.
    /// @param | r | number | Circle radius.
    /// @param | lx1 | number | First line point x coordinate.
    /// @param | ly1 | number | First line point y coordinate.
    /// @param | lx2 | number | Second line point x coordinate.
    /// @param | ly2 | number | Second line point y coordinate.
    /// @return | boolean | True when the line intersects the circle.
    /// @return | number | First hit-point X coordinate.
    /// @return | number | First hit-point Y coordinate.
    /// @return | number | Second hit-point X coordinate.
    /// @return | number | Second hit-point Y coordinate.
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
    /// Tests a line segment against a circle. Returns hit, then two optional hit-point pairs.
    /// @param | cx | number | Circle center x coordinate.
    /// @param | cy | number | Circle center y coordinate.
    /// @param | r | number | Circle radius.
    /// @param | sx1 | number | Segment start x coordinate.
    /// @param | sy1 | number | Segment start y coordinate.
    /// @param | sx2 | number | Segment end x coordinate.
    /// @param | sy2 | number | Segment end y coordinate.
    /// @return | boolean | True when the segment intersects the circle.
    /// @return | number | First hit-point X coordinate.
    /// @return | number | First hit-point Y coordinate.
    /// @return | number | Second hit-point X coordinate.
    /// @return | number | Second hit-point Y coordinate.
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
    /// Returns the closest point on segment (x1,y1)-(x2,y2) to point (px,py).
    /// @param | px | number | Point x coordinate.
    /// @param | py | number | Point y coordinate.
    /// @param | x1 | number | Segment start x coordinate.
    /// @param | y1 | number | Segment start y coordinate.
    /// @param | x2 | number | Segment end x coordinate.
    /// @param | y2 | number | Segment end y coordinate.
    /// @return | number | Closest point X coordinate.
    /// @return | number | Closest point Y coordinate.
    tbl.set(
        "closestPointOnSegment",
        lua.create_function(
            |_, (px, py, x1, y1, x2, y2): (f32, f32, f32, f32, f32, f32)| {
                Ok(geometry::closest_point_on_segment(px, py, x1, y1, x2, y2))
            },
        )?,
    )?;

    // -- convexHull --
    /// Computes the convex hull of a flat {x1,y1,...} point list. Returns a flat table.
    /// @param | points | table | Flat point list.
    /// @return | table | Flat hull point list.
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
    /// Delaunay triangulation of a flat {x1,y1,...} point list. Returns a table of flat 6-number triangle tables.
    /// @param | points | table | Flat point list.
    /// @return | table | Triangle tables with 6 numbers each.
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
    /// Infinite line intersection. Returns (x, y) or (nil, nil) if lines are parallel.
    /// @param | x1 | number | First line start x coordinate.
    /// @param | y1 | number | First line start y coordinate.
    /// @param | x2 | number | First line end x coordinate.
    /// @param | y2 | number | First line end y coordinate.
    /// @param | x3 | number | Second line start x coordinate.
    /// @param | y3 | number | Second line start y coordinate.
    /// @param | x4 | number | Second line end x coordinate.
    /// @param | y4 | number | Second line end y coordinate.
    /// @return | number | Intersection X coordinate.
    /// @return | number | Intersection Y coordinate.
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
    /// Returns true if (px, py) is inside the polygon given as a flat {x1,y1,...} table.
    /// @param | polygon | table | Flat polygon vertex list.
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
    /// Returns the signed area of a polygon given as a flat {x1,y1,...} table.
    /// @param | polygon | table | Flat polygon vertex list.
    /// @return | number | Signed polygon area.
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
    /// Returns the centroid (cx, cy) of a polygon given as a flat {x1,y1,...} table.
    /// @param | polygon | table | Flat polygon vertex list.
    /// @return | number | Centroid X coordinate.
    /// @return | number | Centroid Y coordinate.
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
    /// Tests if two line segments intersect. Returns (hit, ix?, iy?).
    /// @param | x1 | number | First segment start x coordinate.
    /// @param | y1 | number | First segment start y coordinate.
    /// @param | x2 | number | First segment end x coordinate.
    /// @param | y2 | number | First segment end y coordinate.
    /// @param | x3 | number | Second segment start x coordinate.
    /// @param | y3 | number | Second segment start y coordinate.
    /// @param | x4 | number | Second segment end x coordinate.
    /// @param | y4 | number | Second segment end y coordinate.
    /// @return | boolean | True when the segments intersect.
    /// @return | number | Intersection X coordinate.
    /// @return | number | Intersection Y coordinate.
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
    /// Rasterizes a line from (x1,y1) to (x2,y2) using Bresenham's algorithm. Returns a table of {x,y} tables.
    /// @param | x1 | integer | Start x coordinate.
    /// @param | y1 | integer | Start y coordinate.
    /// @param | x2 | integer | End x coordinate.
    /// @param | y2 | integer | End y coordinate.
    /// @return | table | Rasterized `{x, y}` points.
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

    // ── Basic math functions (delegates to Lua built-in math.*) ─────────

    // -- pi --
    /// The mathematical constant π ≈ 3.14159265358979.
    /// @return | number | Constant value.
    tbl.set("pi", std::f64::consts::PI)?;

    // -- tau --
    /// The mathematical constant τ = 2π ≈ 6.28318530717959.
    /// @return | number | Constant value.
    tbl.set("tau", std::f64::consts::TAU)?;

    // -- huge --
    /// Positive infinity (math.huge equivalent).
    /// @return | number | Positive infinity.
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
    /// Returns the sine of x (radians).
    /// @param | x | number | Angle in radians.
    /// @return | number | Sine value.
    tbl.set("sin", lua.create_function(|_, x: f64| Ok(x.sin()))?)?;

    // -- cos --
    /// Returns the cosine of x (radians).
    /// @param | x | number | Angle in radians.
    /// @return | number | Cosine value.
    tbl.set("cos", lua.create_function(|_, x: f64| Ok(x.cos()))?)?;

    // -- tan --
    /// Returns the tangent of x (radians).
    /// @param | x | number | Angle in radians.
    /// @return | number | Tangent value.
    tbl.set("tan", lua.create_function(|_, x: f64| Ok(x.tan()))?)?;

    // -- asin --
    /// Returns the arcsine of x, in radians.
    /// @param | x | number | Input value.
    /// @return | number | Angle in radians.
    tbl.set("asin", lua.create_function(|_, x: f64| Ok(x.asin()))?)?;

    // -- acos --
    /// Returns the arccosine of x, in radians.
    /// @param | x | number | Input value.
    /// @return | number | Angle in radians.
    tbl.set("acos", lua.create_function(|_, x: f64| Ok(x.acos()))?)?;

    // -- atan --
    /// Returns the arctangent of x (or atan2(y, x) when two args given).
    /// @param | y | number | Y value.
    /// @param | x | number? | Optional x value for atan2.
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
    /// Returns atan(y/x) using the signs of both args to determine the quadrant.
    /// @param | y | number | Y value.
    /// @param | x | number | X value.
    /// @return | number | Angle in radians.
    tbl.set(
        "atan2",
        lua.create_function(|_, (y, x): (f64, f64)| Ok(y.atan2(x)))?,
    )?;

    // -- sqrt --
    /// Returns the square root of x.
    /// @param | x | number | Input value.
    /// @return | number | Square root.
    tbl.set("sqrt", lua.create_function(|_, x: f64| Ok(x.sqrt()))?)?;

    // -- abs --
    /// Returns the absolute value of x.
    /// @param | x | number | Input value.
    /// @return | number | Absolute value.
    tbl.set("abs", lua.create_function(|_, x: f64| Ok(x.abs()))?)?;

    // -- floor --
    /// Returns the largest integer ≤ x.
    /// @param | x | number | Input value.
    /// @return | number | Floored value.
    tbl.set("floor", lua.create_function(|_, x: f64| Ok(x.floor()))?)?;

    // -- ceil --
    /// Returns the smallest integer ≥ x.
    /// @param | x | number | Input value.
    /// @return | number | Ceiled value.
    tbl.set("ceil", lua.create_function(|_, x: f64| Ok(x.ceil()))?)?;

    // -- round --
    /// Returns x rounded to the nearest integer (half-up).
    /// @param | x | number | Input value.
    /// @return | number | Rounded value.
    tbl.set("round", lua.create_function(|_, x: f64| Ok(x.round()))?)?;

    // -- exp --
    /// Returns e raised to the power x.
    /// @param | x | number | Exponent value.
    /// @return | number | Result of `e^x`.
    tbl.set("exp", lua.create_function(|_, x: f64| Ok(x.exp()))?)?;

    // -- log --
    /// Returns the natural log of x, or log base b if b is supplied.
    /// @param | x | number | Input value.
    /// @param | b | number? | Optional logarithm base.
    /// @return | number | Logarithm result.
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
    /// Returns x raised to the power y.
    /// @param | x | number | Base value.
    /// @param | y | number | Exponent value.
    /// @return | number | Power result.
    tbl.set(
        "pow",
        lua.create_function(|_, (x, y): (f64, f64)| Ok(x.powf(y)))?,
    )?;

    // -- min --
    /// Returns the smallest of the supplied numbers.
    /// @param | ... | number | Numbers to compare.
    /// @return | number | Smallest supplied value.
    tbl.set(
        "min",
        lua.create_function(|_, args: mlua::Variadic<f64>| {
            args.iter().copied().reduce(f64::min).ok_or_else(|| {
                mlua::Error::RuntimeError("min() requires at least one argument".into())
            })
        })?,
    )?;

    // -- max --
    /// Returns the largest of the supplied numbers.
    /// @param | ... | number | Numbers to compare.
    /// @return | number | Largest supplied value.
    tbl.set(
        "max",
        lua.create_function(|_, args: mlua::Variadic<f64>| {
            args.iter().copied().reduce(f64::max).ok_or_else(|| {
                mlua::Error::RuntimeError("max() requires at least one argument".into())
            })
        })?,
    )?;

    // -- fmod --
    /// Returns the remainder of x / y (fmod).
    /// @param | x | number | Dividend value.
    /// @param | y | number | Divisor value.
    /// @return | number | Remainder value.
    tbl.set(
        "fmod",
        lua.create_function(|_, (x, y): (f64, f64)| Ok(x % y))?,
    )?;

    // -- distance --
    /// Returns the Euclidean distance between (x1,y1) and (x2,y2).
    /// @param | x1 | number | First point x coordinate.
    /// @param | y1 | number | First point y coordinate.
    /// @param | x2 | number | Second point x coordinate.
    /// @param | y2 | number | Second point y coordinate.
    /// @return | number | Euclidean distance.
    tbl.set(
        "distance",
        lua.create_function(|_, (x1, y1, x2, y2): (f64, f64, f64, f64)| {
            let dx = x2 - x1;
            let dy = y2 - y1;
            Ok((dx * dx + dy * dy).sqrt())
        })?,
    )?;

    // -- distanceSq --
    /// Returns the squared Euclidean distance between (x1,y1) and (x2,y2) (avoids sqrt).
    /// @param | x1 | number | First point x coordinate.
    /// @param | y1 | number | First point y coordinate.
    /// @param | x2 | number | Second point x coordinate.
    /// @param | y2 | number | Second point y coordinate.
    /// @return | number | Squared Euclidean distance.
    tbl.set(
        "distanceSq",
        lua.create_function(|_, (x1, y1, x2, y2): (f64, f64, f64, f64)| {
            let dx = x2 - x1;
            let dy = y2 - y1;
            Ok(dx * dx + dy * dy)
        })?,
    )?;

    // -- random --
    /// Returns a pseudo-random number using Lua's built-in `math.random` behavior.
    /// @param | min_or_max | number? | Optional upper bound, or lower bound when `max` is also set.
    /// @param | max | number? | Optional upper bound.
    /// @return | number | Random number.
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
                    // [0, max)
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
    /// Returns a pseudo-random integer in [lo, hi] (inclusive).
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
    /// Returns a simplex noise value in [-1, 1] for 2D or 3D coordinates.
    /// @param | x | number | Sample x coordinate.
    /// @param | y | number | Sample y coordinate.
    /// @param | z | number? | Optional sample z coordinate.
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
    /// Creates a 2D vector with x and y components.
    /// @param | x | number | X component.
    /// @param | y | number | Y component.
    /// @return | LVec2 | New vector.
    tbl.set(
        "vec2",
        lua.create_function(|lua, (x, y): (f64, f64)| {
            lua.create_userdata(LuaVec2 {
                inner: Vec2::new(x as f32, y as f32),
            })
        })?,
    )?;

    // -- Vec2 --
    /// Compatibility alias for `vec2`.
    /// @param | x | number | X component.
    /// @param | y | number | Y component.
    /// @return | LVec2 | New vector.
    tbl.set(
        "Vec2",
        lua.create_function(|lua, (x, y): (f64, f64)| {
            lua.create_userdata(LuaVec2 {
                inner: Vec2::new(x as f32, y as f32),
            })
        })?,
    )?;

    // -- vec3 --
    /// Creates a 3D vector `{x, y, z}` table with numeric components.
    /// @param | x | number | X component.
    /// @param | y | number | Y component.
    /// @param | z | number | Z component.
    /// @return | LVec3 | New vector.
    tbl.set(
        "vec3",
        lua.create_function(|lua, (x, y, z): (f32, f32, f32)| {
            lua.create_userdata(LuaVec3 {
                inner: Vec3::new(x, y, z),
            })
        })?,
    )?;

    // -- Vec3 --
    /// Compatibility alias for `vec3`.
    /// @param | x | number | X component.
    /// @param | y | number | Y component.
    /// @param | z | number | Z component.
    /// @return | LVec3 | New vector.
    tbl.set(
        "Vec3",
        lua.create_function(|lua, (x, y, z): (f32, f32, f32)| {
            lua.create_userdata(LuaVec3 {
                inner: Vec3::new(x, y, z),
            })
        })?,
    )?;

    // -- catmullRom --
    /// Creates a Catmull-Rom spline through the given control points.
    /// @param | points | table | Control points as `{x, y}` tables.
    /// @return | LCatmullRom | New spline.
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
    /// Creates a Hermite spline defined by two endpoints and tangents.
    /// @param | p0x | number | First endpoint x coordinate.
    /// @param | p0y | number | First endpoint y coordinate.
    /// @param | p1x | number | Second endpoint x coordinate.
    /// @param | p1y | number | Second endpoint y coordinate.
    /// @param | m0x | number | First tangent x component.
    /// @param | m0y | number | First tangent y component.
    /// @param | m1x | number | Second tangent x component.
    /// @param | m1y | number | Second tangent y component.
    /// @return | LHermite | New spline.
    tbl.set("hermite", lua.create_function(|lua, (p0x, p0y, p1x, p1y, m0x, m0y, m1x, m1y): (f32, f32, f32, f32, f32, f32, f32, f32)| {
            let hs = HermiteSpline::new((p0x, p0y), (p1x, p1y), (m0x, m0y), (m1x, m1y));
            lua.create_userdata(LuaHermite { inner: hs })
        })?,
    )?;

    // -- lerp --
    /// Linear interpolation between two numbers: a + (b - a) * t.
    /// @param | a | number | Start value.
    /// @param | b | number | End value.
    /// @param | t | number | Interpolation factor.
    /// @return | number | Interpolated value.
    tbl.set(
        "lerp",
        lua.create_function(|_, (a, b, t): (f32, f32, f32)| Ok(lerp(a, b, t)))?,
    )?;

    // -- remap --
    /// Remaps `v` from [in_min, in_max] to [out_min, out_max].
    /// @param | v | number | Value to remap.
    /// @param | in_min | number | Input range minimum.
    /// @param | in_max | number | Input range maximum.
    /// @param | out_min | number | Output range minimum.
    /// @param | out_max | number | Output range maximum.
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
    /// Clamps `v` between `min` and `max`.
    /// @param | v | number | Value to clamp.
    /// @param | min | number | Lower bound.
    /// @param | max | number | Upper bound.
    /// @return | number | Clamped value.
    tbl.set(
        "clamp",
        lua.create_function(|_, (v, min, max): (f32, f32, f32)| Ok(clamp(v, min, max)))?,
    )?;

    // -- sign --
    /// Returns -1, 0, or 1 depending on the sign of `v`.
    /// @param | v | number | Input value.
    /// @return | number | Sign result.
    tbl.set("sign", lua.create_function(|_, v: f32| Ok(sign(v)))?)?;

    // -- smoothstep --
    /// Hermite smoothstep between `edge0` and `edge1`.
    /// @param | edge0 | number | Lower edge.
    /// @param | edge1 | number | Upper edge.
    /// @param | x | number | Input value.
    /// @return | number | Smoothed interpolation value.
    tbl.set(
        "smoothstep",
        lua.create_function(|_, (edge0, edge1, x): (f32, f32, f32)| {
            Ok(smoothstep(edge0, edge1, x))
        })?,
    )?;

    // -- inverseLerp --
    /// Returns the interpolation parameter t for `v` in [a, b].
    /// @param | a | number | Start value.
    /// @param | b | number | End value.
    /// @param | v | number | Sample value.
    /// @return | number | Interpolation factor.
    tbl.set(
        "inverseLerp",
        lua.create_function(|_, (a, b, v): (f32, f32, f32)| Ok(inverse_lerp(a, b, v)))?,
    )?;

    // -- hslToRgb --
    /// Converts HSL (h: 0-360, s: 0-1, l: 0-1) to RGBA (r, g, b, a) floats.
    /// @param | h | number | Hue value.
    /// @param | s | number | Saturation value.
    /// @param | l | number | Lightness value.
    /// @return | number | Red component.
    /// @return | number | Green component.
    /// @return | number | Blue component.
    /// @return | number | Alpha component.
    tbl.set(
        "hslToRgb",
        lua.create_function(|_, (h, s, l): (f32, f32, f32)| {
            let c = hsl_to_rgb(h, s, l);
            Ok((c.r, c.g, c.b, c.a))
        })?,
    )?;

    // -- fromHex --
    /// Parses a hex color string (#RRGGBB or #RRGGBBAA) into (r, g, b, a) floats.
    /// @param | hex | string | Hex color string.
    /// @return | number | Red component.
    /// @return | number | Green component.
    /// @return | number | Blue component.
    /// @return | number | Alpha component.
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
    /// Converts RGBA floats to HSL (h: 0-360, s: 0-1, l: 0-1).
    /// @param | r | number | Red value.
    /// @param | g | number | Green value.
    /// @param | b | number | Blue value.
    /// @return | number | Hue value.
    /// @return | number | Saturation value.
    /// @return | number | Lightness value.
    tbl.set(
        "rgbToHsl",
        lua.create_function(|_, (r, g, b): (f32, f32, f32)| {
            use crate::math::Color;
            let c = Color::new(r, g, b, 1.0);
            Ok(c.to_hsl())
        })?,
    )?;

    // ── Rect utilities ──────────────────────────────────────────────

    // -- rectUnion --
    /// Returns the union (bounding box) of two rectangles.
    /// @param | x1 | number | First rectangle x coordinate.
    /// @param | y1 | number | First rectangle y coordinate.
    /// @param | w1 | number | First rectangle width.
    /// @param | h1 | number | First rectangle height.
    /// @param | x2 | number | Second rectangle x coordinate.
    /// @param | y2 | number | Second rectangle y coordinate.
    /// @param | w2 | number | Second rectangle width.
    /// @param | h2 | number | Second rectangle height.
    /// @return | number | Union rectangle X coordinate.
    /// @return | number | Union rectangle Y coordinate.
    /// @return | number | Union rectangle width.
    /// @return | number | Union rectangle height.
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
    /// Creates a rectangle centered at (cx, cy) with the given width and height.
    /// @param | cx | number | Center x coordinate.
    /// @param | cy | number | Center y coordinate.
    /// @param | w | number | Rectangle width.
    /// @param | h | number | Rectangle height.
    /// @return | number | Rectangle X coordinate.
    /// @return | number | Rectangle Y coordinate.
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
    /// Clips a polygon against a single half-plane using the Sutherland-Hodgman algorithm.
    /// @param | polygon | table | Flat polygon vertex list.
    /// @param | nx | number | Half-plane normal x component.
    /// @param | ny | number | Half-plane normal y component.
    /// @param | d | number | Half-plane distance value.
    /// @return | table | Clipped polygon as a flat `{x1, y1, ...}` table.
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
    /// Creates a new empty AABB tree for efficient broad-phase overlap queries.
    /// @return | LAabbTree | New AABB tree.
    tbl.set(
        "aabbTree",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAabbTree {
                inner: AabbTree::new(),
            })
        })?,
    )?;

    // -- newCircle --
    /// Creates a new Circle value type with the given centre and radius.
    /// @param | x | number | Centre x coordinate.
    /// @param | y | number | Centre y coordinate.
    /// @param | radius | number | Radius value.
    /// @return | LCircle | New circle.
    tbl.set(
        "newCircle",
        lua.create_function(|lua, (x, y, radius): (f32, f32, f32)| {
            lua.create_userdata(LuaCircle {
                inner: Circle::new(x, y, radius),
            })
        })?,
    )?;

    // ── Boolean polygon operations ────────────────────────────────────────────

    // -- polygonIntersection --
    /// Computes the intersection of two convex polygons.
    /// @param | a | table | First polygon as `{x, y}` tables.
    /// @param | b | table | Second polygon as `{x, y}` tables.
    /// @return | table | Intersection polygon as `{x, y}` tables.
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
    /// Computes the approximate union of two convex polygons as a convex hull.
    /// @param | a | table | First polygon as `{x, y}` tables.
    /// @param | b | table | Second polygon as `{x, y}` tables.
    /// @return | table | Union polygon as `{x, y}` tables.
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
    /// Computes the approximate difference `A - B` for convex polygon inputs.
    /// @param | a | table | First polygon as `{x, y}` tables.
    /// @param | b | table | Second polygon as `{x, y}` tables.
    /// @return | table | Difference polygon as `{x, y}` tables.
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
    /// Computes the Voronoi diagram for a list of 2-D seed points.
    /// @param | points | table | Seed points as `{x, y}` tables.
    /// @return | table | Cells with `site` and `vertices` tables.
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

// Converts a Lua table of `{x, y}` sub-tables to a `Vec<(f32, f32)>`.
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

// Converts a `Vec<(f32, f32)>` to a Lua array of `{x, y}` sub-tables.
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
