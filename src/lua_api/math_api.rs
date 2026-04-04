use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::math::bezier::BezierCurve;
use crate::math::srgb;
use crate::math::easing;
use crate::math::noise;
use crate::math::polygon;
use crate::math::random::RandomGenerator;
use crate::math::transform::Transform;
use crate::math::vec2::Vec2;
use crate::math::geometry;
use crate::pathfinding::grid::Grid;
use crate::math::noise::{
    DistType, FractalType, MapGenOptions, NoiseGenerator, NoiseKind,
};
use crate::procgen;
use crate::raycaster::Raycaster2D;
use crate::raycaster::{cast_ray_2d, distance_shade, extract_minimap, field_of_view, project_column, Segment};
use crate::math::spatial_hash::SpatialHash;
use crate::tilemap::tile_walker::{Facing, TileWalker};
use crate::math::tween::Tween;

/// Lua wrapper for `RandomGenerator` so it can be used as UserData.
struct LuaRandomGenerator {
    inner: RefCell<RandomGenerator>,
}

impl LuaUserData for LuaRandomGenerator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method(
            "random",
            |_, this, (min, max): (Option<f64>, Option<f64>)| {
                let mut rng = this.inner.borrow_mut();
                match (min, max) {
                    (Some(lo), Some(hi)) => {
                        // If both are integers (no fractional part), return integer
                        if lo.fract() == 0.0 && hi.fract() == 0.0 {
                            Ok(rng.random_int(lo as i64, hi as i64) as f64)
                        } else {
                            Ok(rng.random_float(lo, hi))
                        }
                    }
                    (Some(hi), None) => {
                        if hi.fract() == 0.0 {
                            Ok(rng.random_int(1, hi as i64) as f64)
                        } else {
                            Ok(rng.random() * hi)
                        }
                    }
                    _ => Ok(rng.random()),
                }
            },
        );

        methods.add_method(
            "randomNormal",
            |_, this, (stddev, mean): (Option<f64>, Option<f64>)| {
                let mut rng = this.inner.borrow_mut();
                Ok(rng.random_normal(stddev.unwrap_or(1.0), mean.unwrap_or(0.0)))
            },
        );

        /// Seeds this random generator with the given integer, resetting its sequence.
        ///
        /// # Parameters
        /// - `seed` — Integer seed value. Use 0 to seed from system time.
        methods.add_method("setSeed", |_, this, seed: u64| {
            this.inner.borrow_mut().set_seed(seed);
            Ok(())
        });

        /// Returns the current random seed value.
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.borrow().get_seed()));

        /// Returns the full PRNG state as a string for later restoration.
        methods.add_method("getState", |_, this, ()| {
            Ok(this.inner.borrow().get_state())
        });

        /// Restores the PRNG state from a string returned by getState.
        methods.add_method("setState", |_, this, state: String| {
            this.inner
                .borrow_mut()
                .set_state(&state)
                .map_err(LuaError::RuntimeError)
        });
    }
}

/// Lua wrapper for `Transform` so it can be used as UserData.
struct LuaTransform {
    inner: RefCell<Transform>,
}

impl LuaUserData for LuaTransform {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Applies a translation offset to the internal matrix.
        ///
        /// # Parameters
        /// - `dx` — Horizontal offset in pixels.
        /// - `dy` — Vertical offset in pixels.
        methods.add_method("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.borrow_mut().translate(dx, dy);
            Ok(())
        });

        /// Applies a rotation by the given angle to the internal matrix.
        ///
        /// # Parameters
        /// - `angle` — Rotation angle in radians.
        methods.add_method("rotate", |_, this, angle: f32| {
            this.inner.borrow_mut().rotate(angle);
            Ok(())
        });

        /// Applies a scale factor to the transform's internal matrix.
        ///
        /// # Parameters
        /// - `sx` — Horizontal scale factor.
        /// - `sy` — Vertical scale factor (defaults to sx if omitted).
        methods.add_method("scale", |_, this, (sx, sy): (f32, Option<f32>)| {
            let sy = sy.unwrap_or(sx);
            this.inner.borrow_mut().scale(sx, sy);
            Ok(())
        });

        /// Applies a shear (skew) transformation to the internal matrix.
        ///
        /// # Parameters
        /// - `kx` — Horizontal shear factor.
        /// - `ky` — Vertical shear factor.
        methods.add_method("shear", |_, this, (kx, ky): (f32, f32)| {
            this.inner.borrow_mut().shear(kx, ky);
            Ok(())
        });

        /// Resets the internal matrix to the identity (no transform applied).
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });

        #[allow(clippy::type_complexity)]
        methods.add_method(
            "setTransformation",
            |_,
             this,
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
                this.inner.borrow_mut().set_transformation(
                    x.unwrap_or(0.0),
                    y.unwrap_or(0.0),
                    angle.unwrap_or(0.0),
                    sx.unwrap_or(1.0),
                    sy.unwrap_or(1.0),
                    ox.unwrap_or(0.0),
                    oy.unwrap_or(0.0),
                    kx.unwrap_or(0.0),
                    ky.unwrap_or(0.0),
                );
                Ok(())
            },
        );

        /// Transforms a point (x, y) by this matrix and returns the result.
        ///
        /// # Parameters
        /// - `x` — Input X coordinate.
        /// - `y` — Input Y coordinate.
        ///
        /// # Returns
        /// Transformed x, y coordinates.
        methods.add_method("transformPoint", |_, this, (x, y): (f32, f32)| {
            let (rx, ry) = this.inner.borrow().transform_point(x, y);
            Ok((rx, ry))
        });

        /// Applies the inverse of this transform to the given point.
        ///
        /// # Parameters
        /// - `x` — Input X coordinate.
        /// - `y` — Input Y coordinate.
        ///
        /// # Returns
        /// Inverse-transformed x, y coordinates.
        methods.add_method("inverseTransformPoint", |_, this, (x, y): (f32, f32)| {
            let (rx, ry) = this.inner.borrow().inverse_transform_point(x, y);
            Ok((rx, ry))
        });

        /// Returns a new Transform that is the mathematical inverse of this one.
        ///
        /// # Returns
        /// A new Transform whose matrix is the inverse.
        methods.add_method("inverse", |lua, this, ()| {
            let inv = this.inner.borrow().inverse();
            let ud = lua.create_userdata(LuaTransform {
                inner: RefCell::new(inv),
            })?;
            Ok(ud)
        });

        /// Returns an independent deep copy of this transform object.
        ///
        /// # Returns
        /// A new Transform with identical matrix state.
        methods.add_method("clone", |lua, this, ()| {
            let cloned = *this.inner.borrow();
            let ud = lua.create_userdata(LuaTransform {
                inner: RefCell::new(cloned),
            })?;
            Ok(ud)
        });

        /// Returns the 16 matrix elements of the 4x4 transform in column-major order.
        ///
        /// # Returns
        /// 16 numbers representing the matrix elements.
        methods.add_method("getMatrix", |lua, this, ()| {
            let m = this.inner.borrow().matrix().m;
            let tbl = lua.create_table()?;
            let mut idx = 1;
            for row in &m {
                for &val in row {
                    tbl.set(idx, val)?;
                    idx += 1;
                }
            }
            Ok(tbl)
        });
    }
}

/// Lua wrapper for `BezierCurve` so it can be used as UserData.
struct LuaBezierCurve {
    inner: RefCell<BezierCurve>,
}

impl LuaUserData for LuaBezierCurve {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Evaluates the curve at parameter t in [0, 1] and returns the world point.
        ///
        /// # Parameters
        /// - `t` — Curve parameter in the range [0, 1].
        ///
        /// # Returns
        /// x, y coordinates of the point on the curve.
        methods.add_method("evaluate", |_, this, t: f32| {
            let p = this.inner.borrow().evaluate(t);
            Ok((p.x, p.y))
        });

        /// Subdivides the curve to the given depth and returns the sample points.
        ///
        /// # Parameters
        /// - `depth` — Subdivision depth; higher values yield smoother output.
        ///
        /// # Returns
        /// Flat list of (x, y) sample coordinates.
        methods.add_method("render", |lua, this, segments: Option<usize>| {
            let points = this.inner.borrow().render(segments.unwrap_or(5));
            let table = lua.create_table()?;
            for (i, p) in points.iter().enumerate() {
                table.set(i * 2 + 1, p.x)?;
                table.set(i * 2 + 2, p.y)?;
            }
            Ok(table)
        });

        methods.add_method(
            "renderSegment",
            |lua, this, (t_start, t_end, segments): (f32, f32, Option<usize>)| {
                let points =
                    this.inner
                        .borrow()
                        .render_segment(t_start, t_end, segments.unwrap_or(5));
                let table = lua.create_table()?;
                for (i, p) in points.iter().enumerate() {
                    table.set(i * 2 + 1, p.x)?;
                    table.set(i * 2 + 2, p.y)?;
                }
                Ok(table)
            },
        );

        /// Returns a new BezierCurve that is the derivative (degree reduced) of this curve.
        ///
        /// # Returns
        /// New BezierCurve representing the tangent/derivative curve.
        methods.add_method("getDerivative", |lua, this, ()| {
            let deriv = this.inner.borrow().get_derivative();
            let ud = lua.create_userdata(LuaBezierCurve {
                inner: RefCell::new(deriv),
            })?;
            Ok(ud)
        });

        /// Returns the position of the control point at the given index.
        ///
        /// # Parameters
        /// - `i` — 1-based index of the control point.
        ///
        /// # Returns
        /// x, y coordinates of the control point.
        methods.add_method("getControlPoint", |_, this, index: usize| {
            let curve = this.inner.borrow();
            // similar game engine uses 1-based indexing
            let idx = index.checked_sub(1).ok_or_else(|| {
                LuaError::RuntimeError("Control point index must be >= 1".to_string())
            })?;
            match curve.get_control_point(idx) {
                Some(p) => Ok((p.x, p.y)),
                None => Err(LuaError::RuntimeError(format!(
                    "Control point index {} out of range",
                    index
                ))),
            }
        });

        methods.add_method(
            "setControlPoint",
            |_, this, (index, x, y): (usize, f32, f32)| {
                let mut curve = this.inner.borrow_mut();
                let idx = index.checked_sub(1).ok_or_else(|| {
                    LuaError::RuntimeError("Control point index must be >= 1".to_string())
                })?;
                if !curve.set_control_point(idx, Vec2::new(x, y)) {
                    return Err(LuaError::RuntimeError(format!(
                        "Control point index {} out of range",
                        index
                    )));
                }
                Ok(())
            },
        );

        methods.add_method(
            "insertControlPoint",
            |_, this, (x, y, index): (f32, f32, Option<usize>)| {
                let mut curve = this.inner.borrow_mut();
                // Convert 1-based Lua index to 0-based
                let idx = index.map(|i| i.saturating_sub(1));
                curve.insert_control_point(Vec2::new(x, y), idx);
                Ok(())
            },
        );

        /// Removes the control point at the given index from the curve.
        ///
        /// # Parameters
        /// - `i` — 1-based index of the control point to remove.
        methods.add_method("removeControlPoint", |_, this, index: usize| {
            let mut curve = this.inner.borrow_mut();
            let idx = index.checked_sub(1).ok_or_else(|| {
                LuaError::RuntimeError("Control point index must be >= 1".to_string())
            })?;
            if !curve.remove_control_point(idx) {
                return Err(LuaError::RuntimeError(
                    "Cannot remove control point: minimum 2 required".to_string(),
                ));
            }
            Ok(())
        });

        /// Returns the total number of control points in the curve.
        ///
        /// # Returns
        /// Count of control points as an integer.
        methods.add_method("getControlPointCount", |_, this, ()| {
            Ok(this.inner.borrow().get_control_point_count())
        });

        /// Shifts every control point by the given (dx, dy) offset in place.
        ///
        /// # Parameters
        /// - `dx` — Horizontal offset in pixels.
        /// - `dy` — Vertical offset in pixels.
        methods.add_method("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.borrow_mut().translate(dx, dy);
            Ok(())
        });

        methods.add_method(
            "rotate",
            |_, this, (angle, ox, oy): (f32, Option<f32>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .rotate(angle, ox.unwrap_or(0.0), oy.unwrap_or(0.0));
                Ok(())
            },
        );

        methods.add_method(
            "scale",
            |_, this, (s, ox, oy): (f32, Option<f32>, Option<f32>)| {
                this.inner
                    .borrow_mut()
                    .scale(s, ox.unwrap_or(0.0), oy.unwrap_or(0.0));
                Ok(())
            },
        );
    }
}

/// Parse a flat table of coordinates into Vec2 pairs.
fn parse_vec2_table(table: &LuaTable) -> LuaResult<Vec<Vec2>> {
    let len = table.len()? as usize;
    if !len.is_multiple_of(2) {
        return Err(LuaError::RuntimeError(
            "Table must contain an even number of values (x, y pairs)".to_string(),
        ));
    }
    let mut points = Vec::with_capacity(len / 2);
    for i in (0..len).step_by(2) {
        let x: f32 = table.get(i + 1)?;
        let y: f32 = table.get(i + 2)?;
        points.push(Vec2::new(x, y));
    }
    Ok(points)
}

// ── Types merged from math_ext_api ──────────────────────────────────────
// ---------------------------------------------------------------------------
// 1. LuaVec2
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `Vec2`.
struct LuaVec2 {
    inner: RefCell<Vec2>,
}

impl LuaUserData for LuaVec2 {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the x.
        ///
        /// # Parameters
        /// - `x` — `number`.
        ///
        /// # Returns
        /// The current x.
        methods.add_method("getX", |_, this, ()| Ok(this.inner.borrow().x));
        /// Returns the y.
        ///
        /// # Parameters
        /// - `x` — `number`.
        ///
        /// # Returns
        /// The current y.
        methods.add_method("getY", |_, this, ()| Ok(this.inner.borrow().y));
        /// Sets the x.
        ///
        /// # Parameters
        /// - `x` — `number`.
        methods.add_method("setX", |_, this, x: f32| {
            this.inner.borrow_mut().x = x;
            Ok(())
        });
        /// Sets the y.
        ///
        /// # Parameters
        /// - `y` — `number`.
        methods.add_method("setY", |_, this, y: f32| {
            this.inner.borrow_mut().y = y;
            Ok(())
        });
        /// Returns the current value.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        ///
        /// # Returns
        /// The current get.
        methods.add_method("get", |_, this, ()| {
            let v = *this.inner.borrow();
            Ok((v.x, v.y))
        });
        /// Sets the value.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        methods.add_method("set", |_, this, (x, y): (f32, f32)| {
            let mut v = this.inner.borrow_mut();
            v.x = x;
            v.y = y;
            Ok(())
        });
        /// Returns the length.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        ///
        /// # Returns
        /// The current length.
        methods.add_method("getLength", |_, this, ()| Ok(this.inner.borrow().length()));
        /// Returns the length squared.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        ///
        /// # Returns
        /// The current length squared.
        methods.add_method("getLengthSquared", |_, this, ()| {
            Ok(this.inner.borrow().length_squared())
        });
        /// Returns the angle.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        ///
        /// # Returns
        /// The current angle.
        methods.add_method("getAngle", |_, this, ()| Ok(this.inner.borrow().angle()));
        /// Dot on this Vec2.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            Ok(a.dot(b))
        });
        /// Cross on this Vec2.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("cross", |_, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            Ok(a.x * b.y - a.y * b.x)
        });
        /// Returns the distance.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        ///
        /// # Returns
        /// The current distance.
        methods.add_method("getDistance", |_, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            Ok(a.distance(b))
        });
        /// Returns the normalized.
        ///
        /// # Parameters
        /// - `angle` — `number`.
        ///
        /// # Returns
        /// The current normalized.
        methods.add_method("getNormalized", |lua, this, ()| {
            let n = this.inner.borrow().normalize();
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(n),
            })
        });
        /// Returns the rotated.
        ///
        /// # Parameters
        /// - `angle` — `number`.
        ///
        /// # Returns
        /// The current rotated.
        methods.add_method("getRotated", |lua, this, angle: f32| {
            let v = *this.inner.borrow();
            let cos = angle.cos();
            let sin = angle.sin();
            let r = Vec2::new(v.x * cos - v.y * sin, v.x * sin + v.y * cos);
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(r),
            })
        });
        /// Returns the perpendicular.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        /// - `t` — `number`.
        ///
        /// # Returns
        /// The current perpendicular.
        methods.add_method("getPerpendicular", |lua, this, ()| {
            let v = *this.inner.borrow();
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(Vec2::new(-v.y, v.x)),
            })
        });
        /// Interpolates between start and target values.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        /// - `t` — `number`.
        methods.add_method("lerp", |lua, this, (other, t): (LuaAnyUserData, f32)| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(a.lerp(b, t)),
            })
        });
        /// Returns a deep copy of this object.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(*this.inner.borrow()),
            })
        });

        // Metamethods
        methods.add_meta_method(LuaMetaMethod::Add, |lua, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(a + b),
            })
        });
        methods.add_meta_method(LuaMetaMethod::Sub, |lua, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(a - b),
            })
        });
        methods.add_meta_method(LuaMetaMethod::Mul, |lua, this, val: LuaValue| {
            let a = *this.inner.borrow();
            match &val {
                LuaValue::UserData(ud) => {
                    let b = *ud.borrow::<LuaVec2>()?.inner.borrow();
                    lua.create_userdata(LuaVec2 {
                        inner: RefCell::new(Vec2::new(a.x * b.x, a.y * b.y)),
                    })
                }
                _ => {
                    let s: f32 = lua.unpack(val)?;
                    lua.create_userdata(LuaVec2 {
                        inner: RefCell::new(a * s),
                    })
                }
            }
        });
        methods.add_meta_method(LuaMetaMethod::Div, |lua, this, val: LuaValue| {
            let a = *this.inner.borrow();
            match &val {
                LuaValue::UserData(ud) => {
                    let b = *ud.borrow::<LuaVec2>()?.inner.borrow();
                    lua.create_userdata(LuaVec2 {
                        inner: RefCell::new(Vec2::new(a.x / b.x, a.y / b.y)),
                    })
                }
                _ => {
                    let s: f32 = lua.unpack(val)?;
                    lua.create_userdata(LuaVec2 {
                        inner: RefCell::new(a / s),
                    })
                }
            }
        });
        methods.add_meta_method(LuaMetaMethod::Unm, |lua, this, ()| {
            let v = *this.inner.borrow();
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(Vec2::new(-v.x, -v.y)),
            })
        });
        methods.add_meta_method(LuaMetaMethod::Eq, |_, this, other: LuaAnyUserData| {
            let a = *this.inner.borrow();
            let b = *other.borrow::<LuaVec2>()?.inner.borrow();
            Ok(a == b)
        });
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            let v = *this.inner.borrow();
            Ok(format!("Vec2({}, {})", v.x, v.y))
        });
    }
}

// ---------------------------------------------------------------------------
// 2. LuaNoiseGenerator
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `NoiseGenerator`.
struct LuaNoiseGenerator {
    inner: RefCell<NoiseGenerator>,
}

impl LuaUserData for LuaNoiseGenerator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Sets the seed.
        ///
        /// # Parameters
        /// - `seed` — `integer`.
        methods.add_method("setSeed", |_, this, seed: u64| {
            this.inner.borrow_mut().set_seed(seed);
            Ok(())
        });
        /// Returns the seed.
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
        ///
        /// # Returns
        /// The current seed.
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.borrow().seed()));

        /// Perlin noise on this NoiseGenerator.
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
        methods.add_method("perlinNoise", |_, this, args: LuaMultiValue| {
            let gen = this.inner.borrow();
            let n = args.len();
            let vals: Vec<f64> = args
                .into_iter()
                .map(|v| match v {
                    LuaValue::Number(n) => Ok(n),
                    LuaValue::Integer(i) => Ok(i as f64),
                    _ => Err(LuaError::RuntimeError("expected number".into())),
                })
                .collect::<LuaResult<Vec<_>>>()?;
            match n {
                1 => Ok(gen.perlin_1d(vals[0])),
                2 => Ok(gen.perlin_2d(vals[0], vals[1])),
                3 => Ok(gen.perlin_3d(vals[0], vals[1], vals[2])),
                4 => Ok(gen.perlin_4d(vals[0], vals[1], vals[2], vals[3])),
                _ => Err(LuaError::RuntimeError(
                    "perlinNoise expects 1-4 arguments".into(),
                )),
            }
        });

        /// Simplex noise on this NoiseGenerator.
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
        methods.add_method("simplexNoise", |_, this, args: LuaMultiValue| {
            let gen = this.inner.borrow();
            let n = args.len();
            let vals: Vec<f64> = args
                .into_iter()
                .map(|v| match v {
                    LuaValue::Number(n) => Ok(n),
                    LuaValue::Integer(i) => Ok(i as f64),
                    _ => Err(LuaError::RuntimeError("expected number".into())),
                })
                .collect::<LuaResult<Vec<_>>>()?;
            match n {
                1 => Ok(gen.simplex_1d(vals[0])),
                2 => Ok(gen.simplex_2d(vals[0], vals[1])),
                3 => Ok(gen.simplex_3d(vals[0], vals[1], vals[2])),
                _ => Err(LuaError::RuntimeError(
                    "simplexNoise expects 1-3 arguments".into(),
                )),
            }
        });

        methods.add_method(
            "worleyNoise",
            |_, this, (x, y, z, dist_type, f2): (f64, f64, Option<f64>, Option<String>, Option<bool>)| {
                let gen = this.inner.borrow();
                let dt = match dist_type.as_deref() {
                    Some("manhattan") => DistType::Manhattan,
                    Some("chebyshev") => DistType::Chebyshev,
                    _ => DistType::Euclidean,
                };
                let use_f2 = f2.unwrap_or(false);
                match z {
                    Some(z) => Ok(gen.worley_3d(x, y, z, dt, use_f2)),
                    None => Ok(gen.worley_2d(x, y, dt, use_f2)),
                }
            },
        );

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
                let gen = this.inner.borrow();
                let k = parse_noise_kind(kind.as_deref());
                Ok(gen.fbm(
                    x,
                    y,
                    octaves.unwrap_or(4),
                    lac.unwrap_or(2.0),
                    pers.unwrap_or(0.5),
                    k,
                ))
            },
        );

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
                let gen = this.inner.borrow();
                let k = parse_noise_kind(kind.as_deref());
                Ok(gen.ridged(
                    x,
                    y,
                    octaves.unwrap_or(4),
                    lac.unwrap_or(2.0),
                    pers.unwrap_or(0.5),
                    k,
                ))
            },
        );

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
                let gen = this.inner.borrow();
                let k = parse_noise_kind(kind.as_deref());
                Ok(gen.turbulence(
                    x,
                    y,
                    octaves.unwrap_or(4),
                    lac.unwrap_or(2.0),
                    pers.unwrap_or(0.5),
                    k,
                ))
            },
        );

        methods.add_method(
            "warpDomain",
            |_, this, (x, y, strength): (f64, f64, f64)| {
                let gen = this.inner.borrow();
                let (wx, wy) = gen.warp_domain(x, y, strength);
                Ok((wx, wy))
            },
        );

        methods.add_method(
            "generateMap",
            |lua, this, (width, height, opts_table): (u32, u32, Option<LuaTable>)| {
                let gen = this.inner.borrow();
                let opts = if let Some(t) = opts_table {
                    MapGenOptions {
                        scale_x: t.get::<_, Option<f64>>("scaleX")?.unwrap_or(1.0),
                        scale_y: t.get::<_, Option<f64>>("scaleY")?.unwrap_or(1.0),
                        octaves: t.get::<_, Option<u32>>("octaves")?.unwrap_or(4),
                        lacunarity: t.get::<_, Option<f64>>("lacunarity")?.unwrap_or(2.0),
                        persistence: t.get::<_, Option<f64>>("persistence")?.unwrap_or(0.5),
                        kind: parse_noise_kind(t.get::<_, Option<String>>("kind")?.as_deref()),
                        fractal: parse_fractal_type(
                            t.get::<_, Option<String>>("fractal")?.as_deref(),
                        ),
                        offset_x: t.get::<_, Option<f64>>("offsetX")?.unwrap_or(0.0),
                        offset_y: t.get::<_, Option<f64>>("offsetY")?.unwrap_or(0.0),
                    }
                } else {
                    MapGenOptions::default()
                };
                let map = gen.generate_map(width, height, &opts);
                let tbl = lua.create_table_with_capacity(map.len(), 0)?;
                for (i, v) in map.iter().enumerate() {
                    tbl.raw_set(i + 1, *v)?;
                }
                Ok(tbl)
            },
        );
    }
}

fn parse_noise_kind(s: Option<&str>) -> NoiseKind {
    match s {
        Some("simplex") => NoiseKind::Simplex,
        _ => NoiseKind::Perlin,
    }
}

fn parse_fractal_type(s: Option<&str>) -> FractalType {
    match s {
        Some("ridged") => FractalType::Ridged,
        Some("turbulence") => FractalType::Turbulence,
        _ => FractalType::Fbm,
    }
}

// ---------------------------------------------------------------------------
// 3. LuaGrid
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `Grid`.
struct LuaGrid {
    inner: RefCell<Grid>,
}

impl LuaUserData for LuaGrid {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the width.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `w` — `boolean`.
        ///
        /// # Returns
        /// The current width.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width()));
        /// Returns the height.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `w` — `boolean`.
        ///
        /// # Returns
        /// The current height.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height()));
        /// Returns the dimensions.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `w` — `boolean`.
        ///
        /// # Returns
        /// The current dimensions.
        methods.add_method("getDimensions", |_, this, ()| {
            let g = this.inner.borrow();
            Ok((g.width(), g.height()))
        });
        // 1-based coords in Lua
        /// Sets the walkable.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `w` — `boolean`.
        methods.add_method("setWalkable", |_, this, (x, y, w): (u32, u32, bool)| {
            this.inner.borrow_mut().set_walkable(x - 1, y - 1, w);
            Ok(())
        });
        /// Returns `true` if walkable.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isWalkable", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_walkable(x - 1, y - 1))
        });
        /// Sets the cost.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `cost` — `number`.
        methods.add_method("setCost", |_, this, (x, y, cost): (u32, u32, f32)| {
            this.inner.borrow_mut().set_cost(x - 1, y - 1, cost);
            Ok(())
        });
        /// Returns the cost.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current cost.
        methods.add_method("getCost", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cost(x - 1, y - 1))
        });

        methods.add_method(
            "findPath",
            |lua,
             this,
             (sx, sy, ex, ey, algo, diagonal): (
                u32,
                u32,
                u32,
                u32,
                Option<String>,
                Option<bool>,
            )| {
                let g = this.inner.borrow();
                let diag = diagonal.unwrap_or(false);
                let sx0 = sx - 1;
                let sy0 = sy - 1;
                let ex0 = ex - 1;
                let ey0 = ey - 1;
                let path = match algo.as_deref() {
                    Some("dijkstra") => g.find_path_dijkstra(sx0, sy0, ex0, ey0, diag),
                    Some("bfs") => g.find_path_bfs(sx0, sy0, ex0, ey0, diag),
                    _ => g.find_path_astar(sx0, sy0, ex0, ey0, diag),
                };
                match path {
                    Some(p) => {
                        let tbl = lua.create_table_with_capacity(p.len(), 0)?;
                        for (i, (px, py)) in p.iter().enumerate() {
                            let pt = lua.create_table_with_capacity(0, 2)?;
                            /// X on this Grid.
                            ///
                            /// # Returns
                            /// The result.
                            pt.set("x", px + 1)?;
                            /// Y on this Grid.
                            ///
                            /// # Returns
                            /// The result.
                            pt.set("y", py + 1)?;
                            tbl.raw_set(i + 1, pt)?;
                        }
                        Ok(LuaValue::Table(tbl))
                    }
                    None => Ok(LuaValue::Nil),
                }
            },
        );

        /// Build flow field on this Grid.
        ///
        /// # Parameters
        /// - `gx` — `integer`.
        /// - `gy` — `integer`.
        methods.add_method("buildFlowField", |lua, this, (gx, gy): (u32, u32)| {
            let g = this.inner.borrow();
            let field = g.build_flow_field(gx - 1, gy - 1);
            let w = g.width();
            let tbl = lua.create_table_with_capacity(field.len(), 0)?;
            for (i, (dx, dy)) in field.iter().enumerate() {
                let x = (i as u32 % w) + 1;
                let y = (i as u32 / w) + 1;
                let entry = lua.create_table_with_capacity(0, 4)?;
                /// X on this Grid.
                ///
                /// # Returns
                /// The result.
                entry.set("x", x)?;
                /// Y on this Grid.
                ///
                /// # Returns
                /// The result.
                entry.set("y", y)?;
                /// Dx on this Grid.
                ///
                /// # Returns
                /// The result.
                entry.set("dx", *dx)?;
                /// Dy on this Grid.
                ///
                /// # Returns
                /// The result.
                entry.set("dy", *dy)?;
                tbl.raw_set(i + 1, entry)?;
            }
            Ok(tbl)
        });
    }
}

// ---------------------------------------------------------------------------
// 4. LuaSpatialHash
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `SpatialHash`.
struct LuaSpatialHash {
    inner: RefCell<SpatialHash>,
}

fn to_string_id(val: &LuaValue) -> LuaResult<String> {
    match val {
        LuaValue::String(s) => Ok(s.to_str()?.to_string()),
        LuaValue::Integer(i) => Ok(format!("{i}")),
        LuaValue::Number(n) => Ok(format!("{n}")),
        _ => Err(LuaError::RuntimeError("id must be string or number".into())),
    }
}

impl LuaUserData for LuaSpatialHash {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the cell size.
        ///
        /// # Parameters
        /// - `id` — `any`.
        /// - `x` — `number`.
        /// - `y` — `number`.
        /// - `w` — `number`.
        /// - `h` — `number`.
        ///
        /// # Returns
        /// The current cell size.
        methods.add_method("getCellSize", |_, this, ()| {
            Ok(this.inner.borrow().cell_size())
        });
        methods.add_method(
            "insert",
            |_, this, (id, x, y, w, h): (LuaValue, f32, f32, f32, f32)| {
                let key = to_string_id(&id)?;
                this.inner.borrow_mut().insert(key, x, y, w, h);
                Ok(())
            },
        );
        /// Removes the entry from the collection.
        ///
        /// # Parameters
        /// - `id` — `any`.
        /// - `x` — `number`.
        /// - `y` — `number`.
        /// - `w` — `number`.
        /// - `h` — `number`.
        methods.add_method("remove", |_, this, id: LuaValue| {
            let key = to_string_id(&id)?;
            this.inner.borrow_mut().remove(&key);
            Ok(())
        });
        methods.add_method(
            "update",
            |_, this, (id, x, y, w, h): (LuaValue, f32, f32, f32, f32)| {
                let key = to_string_id(&id)?;
                this.inner.borrow_mut().update(key, x, y, w, h);
                Ok(())
            },
        );
        /// Removes all entries.
        ///
        /// # Parameters
        /// - `x` — `number`.
        /// - `y` — `number`.
        /// - `w` — `number`.
        /// - `h` — `number`.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        methods.add_method(
            "queryRect",
            |lua, this, (x, y, w, h): (f32, f32, f32, f32)| {
                let ids = this.inner.borrow().query_rect(x, y, w, h);
                let tbl = lua.create_table_with_capacity(ids.len(), 0)?;
                for (i, id) in ids.iter().enumerate() {
                    tbl.raw_set(i + 1, id.as_str())?;
                }
                Ok(tbl)
            },
        );
        /// Query circle on this SpatialHash.
        ///
        /// # Parameters
        /// - `cx` — `number`.
        /// - `cy` — `number`.
        /// - `r` — `number`.
        methods.add_method("queryCircle", |lua, this, (cx, cy, r): (f32, f32, f32)| {
            let ids = this.inner.borrow().query_circle(cx, cy, r);
            let tbl = lua.create_table_with_capacity(ids.len(), 0)?;
            for (i, id) in ids.iter().enumerate() {
                tbl.raw_set(i + 1, id.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method(
            "querySegment",
            |lua, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
                let ids = this.inner.borrow().query_segment(x1, y1, x2, y2);
                let tbl = lua.create_table_with_capacity(ids.len(), 0)?;
                for (i, id) in ids.iter().enumerate() {
                    tbl.raw_set(i + 1, id.as_str())?;
                }
                Ok(tbl)
            },
        );
        /// Returns the item count.
        ///
        /// # Returns
        /// The current item count.
        methods.add_method("getItemCount", |_, this, ()| {
            Ok(this.inner.borrow().item_count())
        });
    }
}

// ---------------------------------------------------------------------------
// 5. LuaRaycaster2D
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `Raycaster2D`.
///
/// Uses `Rc<RefCell<…>>` so `LuaTileWalker` can share the same raycaster.
struct LuaRaycaster2D {
    inner: Rc<RefCell<Raycaster2D>>,
}

impl LuaUserData for LuaRaycaster2D {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the width.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `val` — `integer`.
        ///
        /// # Returns
        /// The current width.
        methods.add_method("getWidth", |_, this, ()| Ok(this.inner.borrow().width()));
        /// Returns the height.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `val` — `integer`.
        ///
        /// # Returns
        /// The current height.
        methods.add_method("getHeight", |_, this, ()| Ok(this.inner.borrow().height()));
        /// Returns the dimensions.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `val` — `integer`.
        ///
        /// # Returns
        /// The current dimensions.
        methods.add_method("getDimensions", |_, this, ()| {
            let rc = this.inner.borrow();
            Ok((rc.width(), rc.height()))
        });
        // 1-based cell access
        /// Sets the cell.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        /// - `val` — `integer`.
        methods.add_method("setCell", |_, this, (x, y, val): (u32, u32, u32)| {
            this.inner.borrow_mut().set_cell(x - 1, y - 1, val);
            Ok(())
        });
        /// Returns the cell.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current cell.
        methods.add_method("getCell", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().get_cell(x - 1, y - 1))
        });
        /// Sets the cells.
        ///
        /// # Parameters
        /// - `data` — `table`.
        methods.add_method("setCells", |_, this, data: LuaTable| {
            let len = data.raw_len();
            let mut vec = Vec::with_capacity(len);
            for i in 1..=len {
                let v: u32 = data.raw_get(i)?;
                vec.push(v);
            }
            this.inner.borrow_mut().set_cells(vec);
            Ok(())
        });
        /// Returns `true` if blocked.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isBlocked", |_, this, (x, y): (u32, u32)| {
            Ok(this.inner.borrow().is_blocked(x - 1, y - 1))
        });

        // World-space raycasting (float coords, not adjusted)
        methods.add_method(
            "castRay",
            |_, this, (ox, oy, angle, max_dist): (f32, f32, f32, Option<f32>)| {
                let rc = this.inner.borrow();
                let md = max_dist.unwrap_or(64.0);
                match rc.cast_ray(ox, oy, angle, md) {
                    Some(hit) => Ok((
                        LuaValue::Number(hit.distance as f64),
                        LuaValue::Integer(hit.cell_value as i64),
                        LuaValue::Integer(hit.side as i64),
                        LuaValue::Number(hit.tex_u as f64),
                        LuaValue::Number(hit.hit_x as f64),
                        LuaValue::Number(hit.hit_y as f64),
                    )),
                    None => Ok((
                        LuaValue::Nil,
                        LuaValue::Nil,
                        LuaValue::Nil,
                        LuaValue::Nil,
                        LuaValue::Nil,
                        LuaValue::Nil,
                    )),
                }
            },
        );

        methods.add_method(
            "castRays",
            |lua, this, (ox, oy, angle, fov, count, max_dist): (f32, f32, f32, f32, u32, Option<f32>)| {
                let rc = this.inner.borrow();
                let md = max_dist.unwrap_or(64.0);
                let hits = rc.cast_rays(ox, oy, angle, fov, count, md);
                let tbl = lua.create_table_with_capacity(hits.len(), 0)?;
                for (i, h) in hits.iter().enumerate() {
                    let entry = lua.create_table_with_capacity(0, 7)?;
                    /// Distance on this Raycaster2D.
                    ///
                    /// # Returns
                    /// The result.
                    entry.set("distance", h.distance)?;
                    /// Cell value on this Raycaster2D.
                    ///
                    /// # Returns
                    /// The result.
                    entry.set("cellValue", h.cell_value)?;
                    /// Side on this Raycaster2D.
                    ///
                    /// # Returns
                    /// The result.
                    entry.set("side", h.side)?;
                    /// Tex u on this Raycaster2D.
                    ///
                    /// # Returns
                    /// The result.
                    entry.set("texU", h.tex_u)?;
                    /// Hit x on this Raycaster2D.
                    ///
                    /// # Returns
                    /// The result.
                    entry.set("hitX", h.hit_x)?;
                    /// Hit y on this Raycaster2D.
                    ///
                    /// # Returns
                    /// The result.
                    entry.set("hitY", h.hit_y)?;
                    /// Hit on this Raycaster2D.
                    ///
                    /// # Returns
                    /// The result.
                    entry.set("hit", h.hit)?;
                    tbl.raw_set(i + 1, entry)?;
                }
                Ok(tbl)
            },
        );

        methods.add_method(
            "castRaysFlat",
            |lua, this, (ox, oy, angle, fov, count, max_dist): (f32, f32, f32, f32, u32, Option<f32>)| {
                let rc = this.inner.borrow();
                let md = max_dist.unwrap_or(64.0);
                let flat = rc.cast_rays_flat(ox, oy, angle, fov, count, md);
                let tbl = lua.create_table_with_capacity(flat.len(), 0)?;
                for (i, v) in flat.iter().enumerate() {
                    tbl.raw_set(i + 1, *v)?;
                }
                Ok(tbl)
            },
        );

        methods.add_method(
            "lineOfSight",
            |_, this, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
                Ok(this.inner.borrow().line_of_sight(x1, y1, x2, y2))
            },
        );

        methods.add_method(
            "projectSprite",
            |_, this, (sx, sy, px, py, pa, fov, screen_w): (f32, f32, f32, f32, f32, f32, f32)| {
                let rc = this.inner.borrow();
                let sp = rc.project_sprite(sx, sy, px, py, pa, fov, screen_w);
                Ok((sp.screen_x, sp.scale, sp.distance, sp.visible))
            },
        );

        methods.add_method(
            "extractMinimap",
            |lua,
             this,
             (px, py, pa, view_radius, cell_size, wr, wg, wb, wa, fr, fg, fb, fa, pr, pg, pb, pa2): (
                f32, f32, f32, u32, u32,
                u8, u8, u8, u8,
                u8, u8, u8, u8,
                u8, u8, u8, u8,
            )| {
                let rc = this.inner.borrow();
                let (pixels, w, h) = extract_minimap(
                    &rc, px, py, pa,
                    view_radius, cell_size,
                    [wr, wg, wb, wa],
                    [fr, fg, fb, fa],
                    [pr, pg, pb, pa2],
                );
                let tbl = lua.create_table_with_capacity(pixels.len(), 0)?;
                for (i, byte) in pixels.into_iter().enumerate() {
                    tbl.raw_set(i + 1, byte)?;
                }
                Ok((tbl, w, h))
            },
        );
    }
}

// ---------------------------------------------------------------------------
// 6. LuaTileWalker
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `TileWalker`.
struct LuaTileWalker {
    inner: RefCell<TileWalker>,
}

impl LuaUserData for LuaTileWalker {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // 1-based position
        /// Returns the position.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        ///
        /// # Returns
        /// The current position.
        methods.add_method("getPosition", |_, this, ()| {
            let w = this.inner.borrow();
            Ok((w.x() + 1, w.y() + 1))
        });
        /// Sets the position.
        ///
        /// # Parameters
        /// - `x` — `integer`.
        /// - `y` — `integer`.
        methods.add_method("setPosition", |_, this, (x, y): (i32, i32)| {
            this.inner.borrow_mut().set_position(x - 1, y - 1);
            Ok(())
        });
        /// Returns the facing.
        ///
        /// # Parameters
        /// - `facing` — `string`.
        ///
        /// # Returns
        /// The current facing.
        methods.add_method("getFacing", |_, this, ()| {
            Ok(this.inner.borrow().facing().to_str().to_string())
        });
        /// Sets the facing.
        ///
        /// # Parameters
        /// - `facing` — `string`.
        methods.add_method("setFacing", |_, this, facing: String| {
            let f = Facing::parse(&facing)
                .ok_or_else(|| LuaError::RuntimeError(format!("invalid facing: {facing}")))?;
            this.inner.borrow_mut().set_facing(f);
            Ok(())
        });
        /// Returns the facing angle.
        ///
        /// # Returns
        /// The current facing angle.
        methods.add_method("getFacingAngle", |_, this, ()| {
            Ok(this.inner.borrow().facing().angle())
        });
        /// Returns the facing direction.
        ///
        /// # Returns
        /// The current facing direction.
        methods.add_method("getFacingDirection", |_, this, ()| {
            let f = this.inner.borrow().facing();
            Ok((f.dx(), f.dy()))
        });
        /// Move forward on this TileWalker.
        ///
        /// # Returns
        /// The result.
        methods.add_method("moveForward", |_, this, ()| {
            Ok(this.inner.borrow_mut().move_forward())
        });
        /// Move backward on this TileWalker.
        ///
        /// # Returns
        /// The result.
        methods.add_method("moveBackward", |_, this, ()| {
            Ok(this.inner.borrow_mut().move_backward())
        });
        /// Strafe left on this TileWalker.
        ///
        /// # Returns
        /// The result.
        methods.add_method("strafeLeft", |_, this, ()| {
            Ok(this.inner.borrow_mut().strafe_left())
        });
        /// Strafe right on this TileWalker.
        ///
        /// # Returns
        /// The result.
        methods.add_method("strafeRight", |_, this, ()| {
            Ok(this.inner.borrow_mut().strafe_right())
        });
        /// Turn left on this TileWalker.
        ///
        /// # Returns
        /// The result.
        methods.add_method("turnLeft", |_, this, ()| {
            this.inner.borrow_mut().turn_left();
            Ok(())
        });
        /// Turn right on this TileWalker.
        ///
        /// # Returns
        /// The result.
        methods.add_method("turnRight", |_, this, ()| {
            this.inner.borrow_mut().turn_right();
            Ok(())
        });
        /// Turn around on this TileWalker.
        ///
        /// # Parameters
        /// - `rc_ud` — `userdata`.
        methods.add_method("turnAround", |_, this, ()| {
            this.inner.borrow_mut().turn_around();
            Ok(())
        });
        /// Sets the raycaster.
        ///
        /// # Parameters
        /// - `rc_ud` — `userdata`.
        methods.add_method("setRaycaster", |_, this, rc_ud: LuaAnyUserData| {
            let lua_rc = rc_ud.borrow::<LuaRaycaster2D>()?;
            this.inner
                .borrow_mut()
                .set_raycaster(Rc::clone(&lua_rc.inner));
            Ok(())
        });
        /// Returns `true` if move forward.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canMoveForward", |_, this, ()| {
            Ok(this.inner.borrow().can_move_forward())
        });
        /// Returns `true` if move backward.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canMoveBackward", |_, this, ()| {
            Ok(this.inner.borrow().can_move_backward())
        });
        /// Returns `true` if strafe left.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canStrafeLeft", |_, this, ()| {
            Ok(this.inner.borrow().can_strafe_left())
        });
        /// Returns `true` if strafe right.
        ///
        /// # Parameters
        /// - `t` — `number`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("canStrafeRight", |_, this, ()| {
            Ok(this.inner.borrow().can_strafe_right())
        });
        /// Begin move on this TileWalker.
        ///
        /// # Parameters
        /// - `t` — `number`.
        methods.add_method("beginMove", |_, this, ()| {
            this.inner.borrow_mut().begin_move();
            Ok(())
        });
        /// Returns the interpolated position.
        ///
        /// # Parameters
        /// - `t` — `number`.
        ///
        /// # Returns
        /// The current interpolated position.
        methods.add_method("getInterpolatedPosition", |_, this, t: f32| {
            let (ix, iy) = this.inner.borrow().get_interpolated_position(t);
            // Return 1-based
            Ok((ix + 1.0, iy + 1.0))
        });
        /// Returns the interpolated angle.
        ///
        /// # Parameters
        /// - `tx` — `integer`.
        /// - `ty` — `integer`.
        ///
        /// # Returns
        /// The current interpolated angle.
        methods.add_method("getInterpolatedAngle", |_, this, t: f32| {
            Ok(this.inner.borrow().get_interpolated_angle(t))
        });
        // 1-based target coords
        /// Returns the relative facing.
        ///
        /// # Parameters
        /// - `tx` — `integer`.
        /// - `ty` — `integer`.
        ///
        /// # Returns
        /// The current relative facing.
        methods.add_method("getRelativeFacing", |_, this, (tx, ty): (i32, i32)| {
            Ok(this
                .inner
                .borrow()
                .get_relative_facing(tx - 1, ty - 1)
                .to_string())
        });
    }
}

// ---------------------------------------------------------------------------
// 7. LuaTween
// ---------------------------------------------------------------------------

/// Lua UserData wrapper for `Tween`.
struct LuaTween {
    inner: RefCell<Tween>,
}

impl LuaUserData for LuaTween {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Adds value to the collection.
        ///
        /// # Parameters
        /// - `start` — `number`.
        /// - `target` — `number`.
        methods.add_method("addValue", |_, this, (start, target): (f64, f64)| {
            let idx = this.inner.borrow_mut().add_value(start, target);
            Ok(idx + 1) // 1-based
        });
        /// Advances the simulation by `dt` seconds.
        ///
        /// # Parameters
        /// - `dt` — `number`.
        methods.add_method("update", |_, this, dt: f64| {
            Ok(this.inner.borrow_mut().update(dt))
        });
        /// Returns the value.
        ///
        /// # Parameters
        /// - `index` — `integer` optional.
        ///
        /// # Returns
        /// The current value.
        methods.add_method("getValue", |lua, this, index: Option<i64>| {
            let tw = this.inner.borrow();
            match index {
                Some(i) => Ok(LuaValue::Number(tw.get_value((i - 1) as usize))),
                None => {
                    let vals = tw.get_all_values();
                    let tbl = lua.create_table_with_capacity(vals.len(), 0)?;
                    for (idx, v) in vals.iter().enumerate() {
                        tbl.raw_set(idx + 1, *v)?;
                    }
                    Ok(LuaValue::Table(tbl))
                }
            }
        });
        /// Returns the value count.
        ///
        /// # Parameters
        /// - `time` — `number`.
        ///
        /// # Returns
        /// The current value count.
        methods.add_method("getValueCount", |_, this, ()| {
            Ok(this.inner.borrow().value_count())
        });
        /// Resets state to initial values.
        ///
        /// # Parameters
        /// - `time` — `number`.
        methods.add_method("reset", |_, this, ()| {
            this.inner.borrow_mut().reset();
            Ok(())
        });
        /// Sets the value.
        ///
        /// # Parameters
        /// - `time` — `number`.
        methods.add_method("set", |_, this, time: f64| {
            this.inner.borrow_mut().set_time(time);
            Ok(())
        });
        /// Returns the clock.
        ///
        /// # Returns
        /// The current clock.
        methods.add_method("getClock", |_, this, ()| Ok(this.inner.borrow().clock()));
        /// Returns the duration.
        ///
        /// # Returns
        /// The current duration.
        methods.add_method("getDuration", |_, this, ()| {
            Ok(this.inner.borrow().duration())
        });
        /// Returns `true` if complete.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isComplete", |_, this, ()| {
            Ok(this.inner.borrow().is_complete())
        });
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Read a flat `{x1, y1, x2, y2, ...}` Lua table into a `Vec<f32>`.
fn read_flat_f32(tbl: &LuaTable) -> LuaResult<Vec<f32>> {
    let len = tbl.raw_len();
    let mut out = Vec::with_capacity(len);
    for i in 1..=len {
        out.push(tbl.raw_get::<_, f32>(i)?);
    }
    Ok(out)
}

/// Read a `{{x, y}, {x, y}, ...}` or `{{x=, y=}, ...}` table into `Vec<(f32, f32)>`.
fn read_points_f32(tbl: &LuaTable) -> LuaResult<Vec<(f32, f32)>> {
    let len = tbl.raw_len();
    let mut out = Vec::with_capacity(len);
    for i in 1..=len {
        let pt: LuaTable = tbl.raw_get(i)?;
        // Try named keys first, then positional
        let x: f32 = pt
            .get::<_, Option<f32>>("x")?
            .unwrap_or_else(|| pt.raw_get(1).unwrap_or(0.0));
        let y: f32 = pt
            .get::<_, Option<f32>>("y")?
            .unwrap_or_else(|| pt.raw_get(2).unwrap_or(0.0));
        out.push((x, y));
    }
    Ok(out)
}

/// Read a `{{x, y}, {x, y}, ...}` table into `Vec<(f64, f64)>`.
fn read_points_f64(tbl: &LuaTable) -> LuaResult<Vec<(f64, f64)>> {
    let len = tbl.raw_len();
    let mut out = Vec::with_capacity(len);
    for i in 1..=len {
        let pt: LuaTable = tbl.raw_get(i)?;
        let x: f64 = pt
            .get::<_, Option<f64>>("x")?
            .unwrap_or_else(|| pt.raw_get(1).unwrap_or(0.0));
        let y: f64 = pt
            .get::<_, Option<f64>>("y")?
            .unwrap_or_else(|| pt.raw_get(2).unwrap_or(0.0));
        out.push((x, y));
    }
    Ok(out)
}

/// Read a `{{x1,y1,x2,y2}, ...}` table into `Vec<Segment>`.
fn read_segments(tbl: &LuaTable) -> LuaResult<Vec<Segment>> {
    let len = tbl.raw_len();
    let mut out = Vec::with_capacity(len);
    for i in 1..=len {
        let seg: LuaTable = tbl.raw_get(i)?;
        let x1: f32 = seg.raw_get(1)?;
        let y1: f32 = seg.raw_get(2)?;
        let x2: f32 = seg.raw_get(3)?;
        let y2: f32 = seg.raw_get(4)?;
        out.push(Segment { x1, y1, x2, y2 });
    }
    Ok(out)
}

// ---------------------------------------------------------------------------
// Register
// ---------------------------------------------------------------------------

// Registers extended math API bindings on the `luna.math` table.
//
// # Parameters
// - `lua` — `&Lua`.
// - `luna_table` — `&LuaTable`.
//
// # Returns
// `LuaResult<()>`.

// ── End merged math_ext_api types ────────────────────────────────────────

/// Registers `luna.math.*` into the Lua VM, including Vec2, noise, tween, spatial hash,
/// raycasting, tile-walking, and all standard math utilities.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let math_api = lua.create_table()?;

    /// Pi.
    math_api.set("pi", std::f64::consts::PI)?;

    // ── Global RandomGenerator ─────────────────────────────────────────
    let global_rng = Rc::new(RefCell::new(RandomGenerator::new()));

    /// Returns a pseudo-random number. No args: [0,1). One arg max: [1,max]. Two args min,max: [min,max].
    let rng = global_rng.clone();
    math_api.set(
        "random",
        lua.create_function(move |_, (min, max): (Option<f64>, Option<f64>)| {
            let mut rng = rng.borrow_mut();
            match (min, max) {
                (Some(lo), Some(hi)) => {
                    if lo.fract() == 0.0 && hi.fract() == 0.0 {
                        Ok(rng.random_int(lo as i64, hi as i64) as f64)
                    } else {
                        Ok(rng.random_float(lo, hi))
                    }
                }
                (Some(hi), None) => {
                    if hi.fract() == 0.0 {
                        Ok(rng.random_int(1, hi as i64) as f64)
                    } else {
                        Ok(rng.random() * hi)
                    }
                }
                _ => Ok(rng.random()),
            }
        })?,
    )?;

    /// Returns a normally distributed random number.
    let rng = global_rng.clone();
    math_api.set(
        "randomNormal",
        lua.create_function(move |_, (stddev, mean): (Option<f64>, Option<f64>)| {
            let mut rng = rng.borrow_mut();
            Ok(rng.random_normal(stddev.unwrap_or(1.0), mean.unwrap_or(0.0)))
        })?,
    )?;

    /// Seeds the engine global random number generator with the given integer.
    ///
    /// # Parameters
    /// - `seed` — Integer seed value; use 0 to seed from system time.
    let rng = global_rng.clone();
    math_api.set(
        "setRandomSeed",
        lua.create_function(move |_, seed: u64| {
            rng.borrow_mut().set_seed(seed);
            Ok(())
        })?,
    )?;

    /// Returns the current seed of the engine global random number generator.
    ///
    /// # Returns
    /// Current seed as an integer.
    let rng = global_rng.clone();
    math_api.set(
        "getRandomSeed",
        lua.create_function(move |_, ()| Ok(rng.borrow().get_seed()))?,
    )?;

    // ── RandomGenerator constructor ────────────────────────────────────
    /// Creates an independent random generator with its own seed.
    math_api.set(
        "newRandomGenerator",
        lua.create_function(|lua, seed: Option<u64>| {
            let gen = match seed {
                Some(s) => RandomGenerator::with_seed(s),
                None => RandomGenerator::new(),
            };
            let ud = lua.create_userdata(LuaRandomGenerator {
                inner: RefCell::new(gen),
            })?;
            Ok(ud)
        })?,
    )?;

    // ── Transform constructor ──────────────────────────────────────────
    #[allow(clippy::type_complexity)]
    /// Creates a new affine Transform object.
    math_api.set(
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
                let transform = if x.is_some() || angle.is_some() {
                    Transform::from_components(
                        x.unwrap_or(0.0),
                        y.unwrap_or(0.0),
                        angle.unwrap_or(0.0),
                        sx.unwrap_or(1.0),
                        sy.unwrap_or(1.0),
                        ox.unwrap_or(0.0),
                        oy.unwrap_or(0.0),
                        kx.unwrap_or(0.0),
                        ky.unwrap_or(0.0),
                    )
                } else {
                    Transform::new()
                };
                let ud = lua.create_userdata(LuaTransform {
                    inner: RefCell::new(transform),
                })?;
                Ok(ud)
            },
        )?,
    )?;

    // ── BezierCurve constructor ────────────────────────────────────────
    /// Creates a new Bezier curve from the given control points.
    math_api.set(
        "newBezierCurve",
        lua.create_function(|lua, args: LuaMultiValue| {
            let points = if args.len() == 1 {
                // Single table argument
                if let Some(table) = args.get(0).and_then(|v| v.as_table()) {
                    parse_vec2_table(table)?
                } else {
                    return Err(LuaError::RuntimeError(
                        "Expected a table of coordinates".to_string(),
                    ));
                }
            } else {
                // Flat coordinate arguments
                if !args.len().is_multiple_of(2) || args.len() < 4 {
                    return Err(LuaError::RuntimeError(
                        "Expected pairs of x,y coordinates (minimum 2 points)".to_string(),
                    ));
                }
                let mut points = Vec::with_capacity(args.len() / 2);
                for chunk in args.iter().collect::<Vec<_>>().chunks(2) {
                    let x: f32 = lua.unpack(chunk[0].clone())?;
                    let y: f32 = lua.unpack(chunk[1].clone())?;
                    points.push(Vec2::new(x, y));
                }
                points
            };
            if points.len() < 2 {
                return Err(LuaError::RuntimeError(
                    "BezierCurve needs at least 2 control points".to_string(),
                ));
            }
            let ud = lua.create_userdata(LuaBezierCurve {
                inner: RefCell::new(BezierCurve::new(points)),
            })?;
            Ok(ud)
        })?,
    )?;

    // ── Polygon utilities ──────────────────────────────────────────────
    /// Triangulates a simple polygon and returns index triples.
    math_api.set(
        "triangulate",
        lua.create_function(|lua, args: LuaMultiValue| {
            let verts = if args.len() == 1 {
                if let Some(table) = args.get(0).and_then(|v| v.as_table()) {
                    parse_vec2_table(table)?
                } else {
                    return Err(LuaError::RuntimeError(
                        "Expected a table of coordinates".to_string(),
                    ));
                }
            } else {
                if !args.len().is_multiple_of(2) || args.len() < 6 {
                    return Err(LuaError::RuntimeError(
                        "Expected pairs of x,y coordinates (minimum 3 points)".to_string(),
                    ));
                }
                let mut points = Vec::with_capacity(args.len() / 2);
                for chunk in args.iter().collect::<Vec<_>>().chunks(2) {
                    let x: f32 = lua.unpack(chunk[0].clone())?;
                    let y: f32 = lua.unpack(chunk[1].clone())?;
                    points.push(Vec2::new(x, y));
                }
                points
            };

            let triangles = polygon::triangulate(&verts).map_err(LuaError::RuntimeError)?;

            let result = lua.create_table()?;
            for (i, tri) in triangles.iter().enumerate() {
                let tri_table = lua.create_table()?;
                tri_table.set(1, tri[0].x)?;
                tri_table.set(2, tri[0].y)?;
                tri_table.set(3, tri[1].x)?;
                tri_table.set(4, tri[1].y)?;
                tri_table.set(5, tri[2].x)?;
                tri_table.set(6, tri[2].y)?;
                result.set(i + 1, tri_table)?;
            }
            Ok(result)
        })?,
    )?;

    /// Returns whether a polygon described by points is convex.
    math_api.set(
        "isConvex",
        lua.create_function(|lua, args: LuaMultiValue| {
            let verts = if args.len() == 1 {
                if let Some(table) = args.get(0).and_then(|v| v.as_table()) {
                    parse_vec2_table(table)?
                } else {
                    return Err(LuaError::RuntimeError(
                        "Expected a table of coordinates".to_string(),
                    ));
                }
            } else {
                if !args.len().is_multiple_of(2) || args.len() < 6 {
                    return Err(LuaError::RuntimeError(
                        "Expected pairs of x,y coordinates (minimum 3 points)".to_string(),
                    ));
                }
                let mut points = Vec::with_capacity(args.len() / 2);
                for chunk in args.iter().collect::<Vec<_>>().chunks(2) {
                    let x: f32 = lua.unpack(chunk[0].clone())?;
                    let y: f32 = lua.unpack(chunk[1].clone())?;
                    points.push(Vec2::new(x, y));
                }
                points
            };

            Ok(polygon::is_convex(&verts))
        })?,
    )?;

    // ── Color space conversion ─────────────────────────────────────────
    /// Converts a sRGB gamma-encoded channel value to linear light intensity.
    ///
    /// # Parameters
    /// - `c` — Gamma-encoded channel value in [0, 1].
    ///
    /// # Returns
    /// Linear-light value in [0, 1].
    math_api.set(
        "gammaToLinear",
        lua.create_function(|_, args: LuaMultiValue| {
            match args.len() {
                1 => {
                    let c: f32 = args
                        .get(0)
                        .and_then(|v| v.as_f32())
                        .ok_or_else(|| LuaError::RuntimeError("Expected number".to_string()))?;
                    Ok(LuaMultiValue::from_vec(vec![LuaValue::Number(
                        srgb::gamma_to_linear(c) as f64,
                    )]))
                }
                3 | 4 => {
                    let r: f32 = args
                        .get(0)
                        .and_then(|v| v.as_f32())
                        .ok_or_else(|| LuaError::RuntimeError("Expected number".to_string()))?;
                    let g: f32 = args
                        .get(1)
                        .and_then(|v| v.as_f32())
                        .ok_or_else(|| LuaError::RuntimeError("Expected number".to_string()))?;
                    let b: f32 = args
                        .get(2)
                        .and_then(|v| v.as_f32())
                        .ok_or_else(|| LuaError::RuntimeError("Expected number".to_string()))?;
                    let mut result = vec![
                        LuaValue::Number(srgb::gamma_to_linear(r) as f64),
                        LuaValue::Number(srgb::gamma_to_linear(g) as f64),
                        LuaValue::Number(srgb::gamma_to_linear(b) as f64),
                    ];
                    if let Some(a) = args.get(3).and_then(|v| v.as_f32()) {
                        result.push(LuaValue::Number(a as f64)); // alpha passed through
                    }
                    Ok(LuaMultiValue::from_vec(result))
                }
                _ => Err(LuaError::RuntimeError(
                    "Expected 1, 3, or 4 arguments".to_string(),
                )),
            }
        })?,
    )?;

    /// Converts a linear-light channel value to sRGB gamma-encoded space.
    ///
    /// # Parameters
    /// - `c` — Linear-light value in [0, 1].
    ///
    /// # Returns
    /// Gamma-encoded value in [0, 1].
    math_api.set(
        "linearToGamma",
        lua.create_function(|_, args: LuaMultiValue| {
            match args.len() {
                1 => {
                    let c: f32 = args
                        .get(0)
                        .and_then(|v| v.as_f32())
                        .ok_or_else(|| LuaError::RuntimeError("Expected number".to_string()))?;
                    Ok(LuaMultiValue::from_vec(vec![LuaValue::Number(
                        srgb::linear_to_gamma(c) as f64,
                    )]))
                }
                3 | 4 => {
                    let r: f32 = args
                        .get(0)
                        .and_then(|v| v.as_f32())
                        .ok_or_else(|| LuaError::RuntimeError("Expected number".to_string()))?;
                    let g: f32 = args
                        .get(1)
                        .and_then(|v| v.as_f32())
                        .ok_or_else(|| LuaError::RuntimeError("Expected number".to_string()))?;
                    let b: f32 = args
                        .get(2)
                        .and_then(|v| v.as_f32())
                        .ok_or_else(|| LuaError::RuntimeError("Expected number".to_string()))?;
                    let mut result = vec![
                        LuaValue::Number(srgb::linear_to_gamma(r) as f64),
                        LuaValue::Number(srgb::linear_to_gamma(g) as f64),
                        LuaValue::Number(srgb::linear_to_gamma(b) as f64),
                    ];
                    if let Some(a) = args.get(3).and_then(|v| v.as_f32()) {
                        result.push(LuaValue::Number(a as f64)); // alpha passed through
                    }
                    Ok(LuaMultiValue::from_vec(result))
                }
                _ => Err(LuaError::RuntimeError(
                    "Expected 1, 3, or 4 arguments".to_string(),
                )),
            }
        })?,
    )?;

    // ── Noise ──────────────────────────────────────────────────────────
    /// Returns a smooth noise value (1D, 2D, or 3D).
    math_api.set(
        "noise",
        lua.create_function(
            |_, (x, y, z, w): (f32, Option<f32>, Option<f32>, Option<f32>)| {
                let seed = 0u32;
                let raw = match (y, z, w) {
                    (None, _, _) => noise::perlin2d(x, 0.0, seed),
                    (Some(y), None, _) => noise::perlin2d(x, y, seed),
                    (Some(y), Some(z), None) => noise::perlin3d(x, y, z, seed),
                    (Some(y), Some(z), Some(w)) => noise::perlin4d(x, y, z, w, seed),
                };
                // Remap from [-1, 1] to [0, 1]
                Ok((raw + 1.0) / 2.0)
            },
        )?,
    )?;

    // ── Easing ─────────────────────────────────────────────────────────
    /// Applies an easing function to t in [0,1].
    math_api.set(
        "ease",
        lua.create_function(|_, (name, t): (String, f32)| {
            easing::apply(&name, t)
                .ok_or_else(|| LuaError::RuntimeError(format!("Unknown easing function: {}", name)))
        })?,
    )?;

    // ── Basic math functions (existing) ────────────────────────────────
    /// Returns the sine of the given angle in radians.
    ///
    /// # Parameters
    /// - `angle` — Angle in radians.
    ///
    /// # Returns
    /// Sine value in the range [-1, 1].
    math_api.set("sin", lua.create_function(|_, x: f64| Ok(x.sin()))?)?;
    /// Returns the cosine of the given angle in radians.
    ///
    /// # Parameters
    /// - `angle` — Angle in radians.
    ///
    /// # Returns
    /// Cosine value in the range [-1, 1].
    math_api.set("cos", lua.create_function(|_, x: f64| Ok(x.cos()))?)?;
    /// Returns the tangent of the given angle in radians.
    ///
    /// # Parameters
    /// - `angle` — Angle in radians.
    ///
    /// # Returns
    /// Tangent value.
    math_api.set("tan", lua.create_function(|_, x: f64| Ok(x.tan()))?)?;
    /// Returns the angle in radians between the positive x-axis and (y, x).
    ///
    /// # Parameters
    /// - `y` — Y component.
    /// - `x` — X component.
    ///
    /// # Returns
    /// Angle in radians in the range (-pi, pi].
    math_api.set(
        "atan2",
        lua.create_function(|_, (y, x): (f64, f64)| Ok(y.atan2(x)))?,
    )?;
    /// Returns the positive square root of x.
    ///
    /// # Parameters
    /// - `x` — Non-negative input number.
    ///
    /// # Returns
    /// sqrt(x) as a number.
    math_api.set("sqrt", lua.create_function(|_, x: f64| Ok(x.sqrt()))?)?;
    /// Returns the absolute (non-negative) value of x.
    ///
    /// # Parameters
    /// - `x` — Input number.
    ///
    /// # Returns
    /// abs(x) as a number.
    math_api.set("abs", lua.create_function(|_, x: f64| Ok(x.abs()))?)?;
    /// Returns the largest integer less than or equal to x (rounds down).
    ///
    /// # Parameters
    /// - `x` — Input number.
    ///
    /// # Returns
    /// floor(x) as an integer.
    math_api.set("floor", lua.create_function(|_, x: f64| Ok(x.floor()))?)?;
    /// Returns the smallest integer greater than or equal to x (rounds up).
    ///
    /// # Parameters
    /// - `x` — Input number.
    ///
    /// # Returns
    /// ceil(x) as an integer.
    math_api.set("ceil", lua.create_function(|_, x: f64| Ok(x.ceil()))?)?;
    /// Returns the smallest value from the given list of numbers.
    ///
    /// # Parameters
    /// - `...` — One or more numeric arguments.
    ///
    /// # Returns
    /// The minimum value.
    math_api.set(
        "min",
        lua.create_function(|_, (a, b): (f64, f64)| Ok(a.min(b)))?,
    )?;
    /// Returns the largest value from the given list of numbers.
    ///
    /// # Parameters
    /// - `...` — One or more numeric arguments.
    ///
    /// # Returns
    /// The maximum value.
    math_api.set(
        "max",
        lua.create_function(|_, (a, b): (f64, f64)| Ok(a.max(b)))?,
    )?;
    /// Clamps a value between min and max.
    math_api.set(
        "clamp",
        lua.create_function(|_, (x, lo, hi): (f64, f64, f64)| Ok(x.max(lo).min(hi)))?,
    )?;

    /// Returns the Euclidean distance between two points.
    math_api.set(
        "distance",
        lua.create_function(|_, (x1, y1, x2, y2): (f64, f64, f64, f64)| {
            let dx = x2 - x1;
            let dy = y2 - y1;
            Ok((dx * dx + dy * dy).sqrt())
        })?,
    )?;

    /// Linearly interpolates between a and b by t.
    math_api.set(
        "lerp",
        lua.create_function(|_, (a, b, t): (f64, f64, f64)| Ok(a + (b - a) * t))?,
    )?;

    /// Normalizes an angle in radians into the canonical range [-pi, pi].
    ///
    /// # Parameters
    /// - `angle` — Angle in radians.
    ///
    /// # Returns
    /// Equivalent angle in the range [-pi, pi].
    math_api.set(
        "normalize",
        lua.create_function(|_, (x, y): (f64, f64)| {
            let len = (x * x + y * y).sqrt();
            if len > 0.0 {
                Ok((x / len, y / len))
            } else {
                Ok((0.0, 0.0))
            }
        })?,
    )?;


    // ── Functions merged from math_ext_api ──────────────────────────────

    // ── Factory functions ──────────────────────────────────────────────

    /// Creates a new 2-component vector object with x and y fields.
    ///
    /// # Parameters
    /// - `x` — X component (default 0).
    /// - `y` — Y component (default 0).
    ///
    /// # Returns
    /// New Vec2 object.
    #[allow(unused_doc_comments)]
    math_api.set(
        "newVec2",
        lua.create_function(|lua, (x, y): (Option<f32>, Option<f32>)| {
            lua.create_userdata(LuaVec2 {
                inner: RefCell::new(Vec2::new(x.unwrap_or(0.0), y.unwrap_or(0.0))),
            })
        })?,
    )?;

    /// Standalone simplex noise: returns a value in approximately `[-1, 1]` for 1–3 coordinates.
    ///
    /// Equivalent to calling `luna.math.newNoiseGenerator(0):simplexNoise(...)`.
    ///
    /// # Parameters
    /// - `x` — X coordinate.
    /// - `y` — Y coordinate (optional, defaults to 0).
    /// - `z` — Z coordinate (optional; enables 3-D mode).
    ///
    /// # Returns
    /// Noise value in approximately `[-1.0, 1.0]`.
    math_api.set(
        "simplexNoise",
        lua.create_function(|_, args: LuaMultiValue| {
            let vals: Vec<f32> = args
                .iter()
                .filter_map(|v| match v {
                    LuaValue::Number(n) => Some(*n as f32),
                    LuaValue::Integer(n) => Some(*n as f32),
                    _ => None,
                })
                .collect();
            match vals.len() {
                1 => Ok(noise::simplex_noise_2d(vals[0], 0.0) as f64),
                2 => Ok(noise::simplex_noise_2d(vals[0], vals[1]) as f64),
                3 => Ok(noise::simplex_noise_3d(vals[0], vals[1], vals[2]) as f64),
                _ => Err(LuaError::RuntimeError(
                    "simplexNoise expects 1-3 arguments".into(),
                )),
            }
        })?,
    )?;

    /// Creates a reusable Perlin/simplex noise generator with a given seed.
    ///
    /// # Parameters
    /// - `seed` — Integer seed for the noise generator.
    ///
    /// # Returns
    /// New NoiseGenerator object.
    #[allow(unused_doc_comments)]
    math_api.set(
        "newNoiseGenerator",
        lua.create_function(|lua, seed: Option<u64>| {
            lua.create_userdata(LuaNoiseGenerator {
                inner: RefCell::new(NoiseGenerator::new(seed.unwrap_or(0))),
            })
        })?,
    )?;

    /// luna.math.newGrid(width, height, defaultCost)
    #[allow(unused_doc_comments)]
    math_api.set(
        "newGrid",
        lua.create_function(|lua, (w, h, cost): (u32, u32, Option<f32>)| {
            lua.create_userdata(LuaGrid {
                inner: RefCell::new(Grid::new(w, h, cost.unwrap_or(1.0))),
            })
        })?,
    )?;

    /// Creates a spatial hash grid for fast broad-phase proximity and overlap queries.
    ///
    /// # Parameters
    /// - `cellSize` — Width and height of each hash cell in world units.
    ///
    /// # Returns
    /// New SpatialHash object.
    #[allow(unused_doc_comments)]
    math_api.set(
        "newSpatialHash",
        lua.create_function(|lua, cell_size: f32| {
            lua.create_userdata(LuaSpatialHash {
                inner: RefCell::new(SpatialHash::new(cell_size)),
            })
        })?,
    )?;

    /// luna.math.newRaycaster2D(width, height)
    #[allow(unused_doc_comments)]
    math_api.set(
        "newRaycaster2D",
        lua.create_function(|lua, (w, h): (u32, u32)| {
            lua.create_userdata(LuaRaycaster2D {
                inner: Rc::new(RefCell::new(Raycaster2D::new(w, h))),
            })
        })?,
    )?;

    /// luna.math.newTileWalker(x, y, facing)
    #[allow(unused_doc_comments)]
    math_api.set(
        "newTileWalker",
        lua.create_function(|lua, (x, y, facing): (i32, i32, Option<String>)| {
            let f = facing
                .as_deref()
                .and_then(Facing::parse)
                .unwrap_or(Facing::North);
            lua.create_userdata(LuaTileWalker {
                inner: RefCell::new(TileWalker::new(x - 1, y - 1, f)),
            })
        })?,
    )?;

    /// luna.math.newTween(duration, easing)
    #[allow(unused_doc_comments)]
    math_api.set(
        "newTween",
        lua.create_function(|lua, (duration, easing): (f64, Option<String>)| {
            lua.create_userdata(LuaTween {
                inner: RefCell::new(Tween::new(duration, easing.as_deref().unwrap_or("linear"))),
            })
        })?,
    )?;

    // ── Geometry functions (14) ────────────────────────────────────────

    /// luna.math.angleBetween(x1, y1, x2, y2)
    #[allow(unused_doc_comments)]
    math_api.set(
        "angleBetween",
        lua.create_function(|_, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            Ok(geometry::angle_between(x1, y1, x2, y2))
        })?,
    )?;

    /// luna.math.circleContainsPoint(cx, cy, r, px, py)
    #[allow(unused_doc_comments)]
    math_api.set(
        "circleContainsPoint",
        lua.create_function(|_, (cx, cy, r, px, py): (f32, f32, f32, f32, f32)| {
            Ok(geometry::circle_contains_point(cx, cy, r, px, py))
        })?,
    )?;

    /// luna.math.circleIntersectsCircle(x1, y1, r1, x2, y2, r2)
    #[allow(unused_doc_comments)]
    math_api.set(
        "circleIntersectsCircle",
        lua.create_function(
            |_, (x1, y1, r1, x2, y2, r2): (f32, f32, f32, f32, f32, f32)| {
                Ok(geometry::circle_intersects_circle(x1, y1, r1, x2, y2, r2))
            },
        )?,
    )?;

    /// luna.math.circleIntersectsLine(cx, cy, r, lx1, ly1, lx2, ly2)
    #[allow(unused_doc_comments)]
    math_api.set(
        "circleIntersectsLine",
        lua.create_function(
            |_, (cx, cy, r, lx1, ly1, lx2, ly2): (f32, f32, f32, f32, f32, f32, f32)| {
                let (hit, p1, p2) = geometry::circle_intersects_line(cx, cy, r, lx1, ly1, lx2, ly2);
                Ok((
                    hit,
                    p1.map(|(x, _)| x),
                    p1.map(|(_, y)| y),
                    p2.map(|(x, _)| x),
                    p2.map(|(_, y)| y),
                ))
            },
        )?,
    )?;

    /// luna.math.circleIntersectsSegment(cx, cy, r, sx1, sy1, sx2, sy2)
    #[allow(unused_doc_comments)]
    math_api.set(
        "circleIntersectsSegment",
        lua.create_function(
            |_, (cx, cy, r, sx1, sy1, sx2, sy2): (f32, f32, f32, f32, f32, f32, f32)| {
                let (hit, p1, p2) =
                    geometry::circle_intersects_segment(cx, cy, r, sx1, sy1, sx2, sy2);
                Ok((
                    hit,
                    p1.map(|(x, _)| x),
                    p1.map(|(_, y)| y),
                    p2.map(|(x, _)| x),
                    p2.map(|(_, y)| y),
                ))
            },
        )?,
    )?;

    /// Returns the signed area of a simple polygon described by its vertex list.
    ///
    /// # Parameters
    /// - `vertices` — Table of {x, y} tables or flat coordinate array.
    ///
    /// # Returns
    /// Signed area as a number (negative if clockwise, positive if counter-clockwise).
    #[allow(unused_doc_comments)]
    math_api.set(
        "polygonArea",
        lua.create_function(|_, tbl: LuaTable| {
            let verts = read_flat_f32(&tbl)?;
            Ok(geometry::polygon_area(&verts))
        })?,
    )?;

    /// luna.math.polygonCentroid(vertices)
    #[allow(unused_doc_comments)]
    math_api.set(
        "polygonCentroid",
        lua.create_function(|_, tbl: LuaTable| {
            let verts = read_flat_f32(&tbl)?;
            let (cx, cy) = geometry::polygon_centroid(&verts);
            Ok((cx, cy))
        })?,
    )?;

    /// luna.math.segmentIntersectsSegment(x1, y1, x2, y2, x3, y3, x4, y4)
    #[allow(unused_doc_comments)]
    math_api.set(
        "segmentIntersectsSegment",
        lua.create_function(
            |_, (x1, y1, x2, y2, x3, y3, x4, y4): (f32, f32, f32, f32, f32, f32, f32, f32)| {
                let (hit, pt) =
                    geometry::segment_intersects_segment(x1, y1, x2, y2, x3, y3, x4, y4);
                Ok((hit, pt.map(|(x, _)| x), pt.map(|(_, y)| y)))
            },
        )?,
    )?;

    /// luna.math.closestPointOnSegment(px, py, x1, y1, x2, y2)
    #[allow(unused_doc_comments)]
    math_api.set(
        "closestPointOnSegment",
        lua.create_function(
            |_, (px, py, x1, y1, x2, y2): (f32, f32, f32, f32, f32, f32)| {
                let (cx, cy) = geometry::closest_point_on_segment(px, py, x1, y1, x2, y2);
                Ok((cx, cy))
            },
        )?,
    )?;

    /// luna.math.pointInPolygon(vertices, px, py)
    #[allow(unused_doc_comments)]
    math_api.set(
        "pointInPolygon",
        lua.create_function(|_, (tbl, px, py): (LuaTable, f32, f32)| {
            let verts = read_flat_f32(&tbl)?;
            Ok(geometry::point_in_polygon(&verts, px, py))
        })?,
    )?;

    /// luna.math.lineIntersect(x1, y1, x2, y2, x3, y3, x4, y4)
    #[allow(unused_doc_comments)]
    math_api.set(
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

    /// luna.math.bresenham(x1, y1, x2, y2)
    #[allow(unused_doc_comments)]
    math_api.set(
        "bresenham",
        lua.create_function(|lua, (x1, y1, x2, y2): (i32, i32, i32, i32)| {
            let pts = geometry::bresenham(x1, y1, x2, y2);
            let tbl = lua.create_table_with_capacity(pts.len() * 2, 0)?;
            for (i, (x, y)) in pts.iter().enumerate() {
                tbl.raw_set(i * 2 + 1, *x)?;
                tbl.raw_set(i * 2 + 2, *y)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// Computes and returns the convex hull of a set of 2D points as an ordered vertex list.
    ///
    /// # Parameters
    /// - `points` — Table of {x, y} point tables or flat coordinate array.
    ///
    /// # Returns
    /// Ordered table of {x, y} hull vertex tables (counter-clockwise).
    #[allow(unused_doc_comments)]
    math_api.set(
        "convexHull",
        lua.create_function(|lua, tbl: LuaTable| {
            let verts = read_flat_f32(&tbl)?;
            let hull = geometry::convex_hull(&verts);
            let out = lua.create_table_with_capacity(hull.len(), 0)?;
            for (i, v) in hull.iter().enumerate() {
                out.raw_set(i + 1, *v)?;
            }
            Ok(out)
        })?,
    )?;

    /// luna.math.delaunayTriangulate(points)
    #[allow(unused_doc_comments)]
    math_api.set(
        "delaunayTriangulate",
        lua.create_function(|lua, tbl: LuaTable| {
            let pts = read_points_f64(&tbl)?;
            let triangles = geometry::delaunay_triangulate(&pts);
            let out = lua.create_table_with_capacity(triangles.len(), 0)?;
            for (i, tri) in triangles.iter().enumerate() {
                let t = lua.create_table_with_capacity(6, 0)?;
                for (j, v) in tri.iter().enumerate() {
                    t.raw_set(j + 1, *v)?;
                }
                out.raw_set(i + 1, t)?;
            }
            Ok(out)
        })?,
    )?;

    // ── Raycasting functions (4) ───────────────────────────────────────

    /// luna.math.castRay2D(ox, oy, dx, dy, maxDist, segments)
    #[allow(unused_doc_comments)]
    math_api.set(
        "castRay2D",
        lua.create_function(
            |_, (ox, oy, dx, dy, max_dist, segs_tbl): (f32, f32, f32, f32, f32, LuaTable)| {
                let segs = read_segments(&segs_tbl)?;
                match cast_ray_2d(ox, oy, dx, dy, max_dist, &segs) {
                    Some((hx, hy, idx)) => Ok((Some(hx), Some(hy), Some(idx as i64 + 1))),
                    None => Ok((None, None, None)),
                }
            },
        )?,
    )?;

    /// luna.math.fieldOfView(ox, oy, segments, radius)
    #[allow(unused_doc_comments)]
    math_api.set(
        "fieldOfView",
        lua.create_function(
            |lua, (ox, oy, segs_tbl, radius): (f32, f32, LuaTable, f32)| {
                let segs = read_segments(&segs_tbl)?;
                let poly = field_of_view(ox, oy, &segs, radius);
                let tbl = lua.create_table_with_capacity(poly.len(), 0)?;
                for (i, v) in poly.iter().enumerate() {
                    tbl.raw_set(i + 1, *v)?;
                }
                Ok(tbl)
            },
        )?,
    )?;

    /// luna.math.projectColumn(distance, fov, screenHeight)
    #[allow(unused_doc_comments)]
    math_api.set(
        "projectColumn",
        lua.create_function(|_, (distance, fov, screen_h): (f32, f32, f32)| {
            let (wh, ds, de) = project_column(distance, fov, screen_h);
            Ok((wh, ds, de))
        })?,
    )?;

    /// luna.math.distanceShade(distance, maxDistance)
    #[allow(unused_doc_comments)]
    math_api.set(
        "distanceShade",
        lua.create_function(|_, (distance, max_dist): (f32, f32)| {
            Ok(distance_shade(distance, max_dist))
        })?,
    )?;

    // ── Procedural generation functions (5) ────────────────────────────

    /// luna.math.cellularAutomata(width, height, opts)
    #[allow(unused_doc_comments)]
    math_api.set(
        "cellularAutomata",
        lua.create_function(|lua, (w, h, opts_tbl): (u32, u32, Option<LuaTable>)| {
            let opts = if let Some(t) = opts_tbl {
                procgen::CellularOpts {
                    fill: t.get::<_, Option<f32>>("fill")?.unwrap_or(0.45),
                    iterations: t.get::<_, Option<u32>>("iterations")?.unwrap_or(5),
                    birth: t.get::<_, Option<u32>>("birth")?.unwrap_or(6),
                    survive: t.get::<_, Option<u32>>("survive")?.unwrap_or(4),
                    seed: t.get::<_, Option<u64>>("seed")?.unwrap_or(12345),
                }
            } else {
                procgen::CellularOpts::default()
            };
            let grid = procgen::cellular_automata(w, h, &opts);
            let tbl = lua.create_table_with_capacity(grid.len(), 0)?;
            for (i, v) in grid.iter().enumerate() {
                tbl.raw_set(i + 1, *v as i64)?;
            }
            Ok(tbl)
        })?,
    )?;

    /// luna.math.voronoiDiagram(width, height, points, opts)
    #[allow(unused_doc_comments)]
    math_api.set(
        "voronoiDiagram",
        lua.create_function(
            |lua, (w, h, pts_tbl, opts_tbl): (u32, u32, LuaTable, Option<LuaTable>)| {
                let pts = read_points_f32(&pts_tbl)?;
                let opts = if let Some(t) = opts_tbl {
                    procgen::VoronoiOpts {
                        warp_scale: t.get::<_, Option<f32>>("warpScale")?.unwrap_or(0.1),
                        warp_strength: t.get::<_, Option<f32>>("warpStrength")?.unwrap_or(0.0),
                        seed: t.get::<_, Option<u64>>("seed")?.unwrap_or(0),
                    }
                } else {
                    procgen::VoronoiOpts::default()
                };
                let (regions, distances, second_distances) =
                    procgen::voronoi_diagram(w, h, &pts, &opts);
                let reg_tbl = lua.create_table_with_capacity(regions.len(), 0)?;
                for (i, v) in regions.iter().enumerate() {
                    reg_tbl.raw_set(i + 1, *v + 1)?; // 1-based point index
                }
                let dist_tbl = lua.create_table_with_capacity(distances.len(), 0)?;
                for (i, v) in distances.iter().enumerate() {
                    dist_tbl.raw_set(i + 1, *v)?;
                }
                let sd_tbl = lua.create_table_with_capacity(second_distances.len(), 0)?;
                for (i, v) in second_distances.iter().enumerate() {
                    sd_tbl.raw_set(i + 1, *v)?;
                }
                Ok((reg_tbl, dist_tbl, sd_tbl))
            },
        )?,
    )?;

    /// luna.math.floodFill(data, width, height, sx, sy, threshold, mode)
    #[allow(unused_doc_comments)]
    math_api.set(
        "floodFill",
        lua.create_function(
            |lua,
             (data_tbl, w, h, sx, sy, threshold, mode): (
                LuaTable,
                u32,
                u32,
                u32,
                u32,
                u8,
                Option<String>,
            )| {
                let len = data_tbl.raw_len();
                let mut data = Vec::with_capacity(len);
                for i in 1..=len {
                    data.push(data_tbl.raw_get::<_, u8>(i)?);
                }
                let above = mode.as_deref() == Some("above");
                // 1-based to 0-based
                let result = procgen::flood_fill(&data, w, h, sx - 1, sy - 1, threshold, above);
                let tbl = lua.create_table_with_capacity(result.len(), 0)?;
                for (i, v) in result.iter().enumerate() {
                    tbl.raw_set(i + 1, *v as i64)?;
                }
                Ok(tbl)
            },
        )?,
    )?;

    /// luna.math.poissonDisk(width, height, minDist, maxAttempts, seed)
    #[allow(unused_doc_comments)]
    math_api.set(
        "poissonDisk",
        lua.create_function(
            |lua,
             (w, h, min_dist, max_attempts, seed): (f32, f32, f32, Option<u32>, Option<u64>)| {
                let pts = procgen::poisson_disk(
                    w,
                    h,
                    min_dist,
                    max_attempts.unwrap_or(30),
                    seed.unwrap_or(0),
                );
                let tbl = lua.create_table_with_capacity(pts.len(), 0)?;
                for (i, (px, py)) in pts.iter().enumerate() {
                    let pt = lua.create_table_with_capacity(0, 2)?;
                    /// X on this Tween.
                    ///
                    /// # Returns
                    /// The result.
                    pt.set("x", *px)?;
                    /// Y on this Tween.
                    ///
                    /// # Returns
                    /// The result.
                    pt.set("y", *py)?;
                    tbl.raw_set(i + 1, pt)?;
                }
                Ok(tbl)
            },
        )?,
    )?;

    /// luna.math.perlinNoisePeriodic(x, y, px, py)
    #[allow(unused_doc_comments)]
    math_api.set(
        "perlinNoisePeriodic",
        lua.create_function(|_, (x, y, px, py): (f64, f64, f64, f64)| {
            Ok(procgen::perlin_noise_periodic(x, y, px, py))
        })?,
    )?;

    /// Math.
    luna.set("math", math_api)?;
    Ok(())
}
