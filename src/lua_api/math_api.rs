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

/// Registers `luna.math.*` helpers (Vec2, distance, random, noise, transforms, etc.) into the Lua VM.
///
/// # Parameters
/// - `lua` — The active Lua VM instance.
/// - `luna` — The `luna` global table to attach functions to.
///
/// # Returns
/// `LuaResult<()>` — Ok if all functions were registered successfully; Lua error otherwise.
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

    /// Math.
    luna.set("math", math_api)?;
    Ok(())
}
