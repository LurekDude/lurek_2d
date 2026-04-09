//! `lurek.math` — Math utilities: random generators, transforms, Bezier curves, tweening,
//! spatial hashing, noise, easing, polygon triangulation, and color-space conversion.

use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use super::SharedState;
use crate::math::color::{gamma_to_linear, linear_to_gamma};
use crate::math::easing;
use crate::math::geometry;
use crate::math::noise_functions;
use crate::math::polygon;
use crate::math::BezierCurve;
use crate::math::NoiseGenerator;
use crate::math::RandomGenerator;
use crate::math::SpatialHash;
use crate::math::Transform;
use crate::math::Tween;
use crate::math::Vec2;
use crate::math::{DistType, FractalType, MapGenOptions, NoiseKind};

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
        /// @return number
        methods.add_method_mut("random", |_, this, ()| Ok(this.inner.random()));

        // -- randomFloat --
        /// Returns a uniform random float in [min, max).
        /// @param min : number
        /// @param max : number
        /// @return number
        methods.add_method_mut("randomFloat", |_, this, (min, max): (f64, f64)| {
            Ok(this.inner.random_float(min, max))
        });

        // -- randomInt --
        /// Returns a uniform random integer in [min, max].
        /// @param min : integer
        /// @param max : integer
        /// @return integer
        methods.add_method_mut("randomInt", |_, this, (min, max): (i64, i64)| {
            Ok(this.inner.random_int(min, max))
        });

        // -- randomNormal --
        /// Returns a random number from a normal (Gaussian) distribution.
        /// @param stddev : number?
        /// @param mean : number?
        /// @return number
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
        /// @return integer
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.get_seed()));

        // -- setSeed --
        /// Sets the seed, fully resetting the generator state.
        /// @param seed : integer
        /// @return nil
        methods.add_method_mut("setSeed", |_, this, seed: u64| {
            this.inner.set_seed(seed);
            Ok(())
        });

        // -- getState --
        /// Serialises the generator state as a string for later restoration.
        /// @return string
        methods.add_method("getState", |_, this, ()| Ok(this.inner.get_state()));

        // -- setState --
        /// Restores the generator state from a previously serialised string.
        /// @param state : string
        /// @return nil
        methods.add_method_mut("setState", |_, this, state: String| {
            this.inner.set_state(&state).map_err(LuaError::external)?;
            Ok(())
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
        /// @param dx : number
        /// @param dy : number
        /// @return nil
        methods.add_method_mut("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.translate(dx, dy);
            Ok(())
        });

        // -- rotate --
        /// Applies a rotation in radians.
        /// @param angle : number
        /// @return nil
        methods.add_method_mut("rotate", |_, this, angle: f32| {
            this.inner.rotate(angle);
            Ok(())
        });

        // -- scale --
        /// Applies non-uniform scaling.
        /// @param sx : number
        /// @param sy : number?
        /// @return nil
        methods.add_method_mut("scale", |_, this, (sx, sy): (f32, Option<f32>)| {
            this.inner.scale(sx, sy.unwrap_or(sx));
            Ok(())
        });

        // -- shear --
        /// Applies shear factors.
        /// @param kx : number
        /// @param ky : number
        /// @return nil
        methods.add_method_mut("shear", |_, this, (kx, ky): (f32, f32)| {
            this.inner.shear(kx, ky);
            Ok(())
        });

        // -- reset --
        /// Resets the transform to identity.
        /// @return nil
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });

        // -- setTransformation --
        /// Replaces the transform with full transformation parameters.
        /// @param x : number
        /// @param y : number
        /// @param angle : number?
        /// @param sx : number?
        /// @param sy : number?
        /// @param ox : number?
        /// @param oy : number?
        /// @param kx : number?
        /// @param ky : number?
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
        /// @param x : number
        /// @param y : number
        /// @return number, number
        methods.add_method("transformPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.transform_point(x, y))
        });

        // -- inverseTransformPoint --
        /// Transforms a point from world space back to local space.
        /// @param x : number
        /// @param y : number
        /// @return number, number
        methods.add_method("inverseTransformPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.inverse_transform_point(x, y))
        });

        // -- inverse --
        /// Returns a new Transform that undoes this transform.
        /// @return Transform
        methods.add_method("inverse", |lua, this, ()| {
            lua.create_userdata(LuaTransform {
                inner: this.inner.inverse(),
            })
        });

        // -- clone --
        /// Returns a copy of this transform.
        /// @return Transform
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(LuaTransform { inner: this.inner })
        });

        // -- getMatrix --
        /// Returns the 3x3 matrix as a flat table of 9 numbers (row-major).
        /// @return table
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
        /// @param t : number
        /// @return number, number
        methods.add_method("evaluate", |_, this, t: f32| {
            let p = this.inner.evaluate(t);
            Ok((p.x, p.y))
        });

        // -- render --
        /// Renders the curve as a polyline with the given number of segments.
        /// @param segments : integer
        /// @return table
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
        /// @return BezierCurve
        methods.add_method("getDerivative", |lua, this, ()| {
            lua.create_userdata(LuaBezierCurve {
                inner: this.inner.get_derivative(),
            })
        });

        // -- getControlPoint --
        /// Returns the control point at 1-based index as (x, y), or nil.
        /// @param index : integer
        /// @return number?, number?
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
        /// @param index : integer
        /// @param x : number
        /// @param y : number
        /// @return boolean
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
        /// @param x : number
        /// @param y : number
        /// @param index : integer?
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
        /// @param index : integer
        /// @return boolean
        methods.add_method_mut("removeControlPoint", |_, this, index: usize| {
            if index == 0 {
                return Ok(false);
            }
            Ok(this.inner.remove_control_point(index - 1))
        });

        // -- getControlPointCount --
        /// Returns the number of control points.
        /// @return integer
        methods.add_method("getControlPointCount", |_, this, ()| {
            Ok(this.inner.get_control_point_count())
        });

        // -- length --
        /// Returns the approximate arc length of the curve.
        /// @return number
        methods.add_method("length", |_, this, ()| Ok(this.inner.length()));

        // -- translate --
        /// Translates all control points by (dx, dy).
        /// @param dx : number
        /// @param dy : number
        /// @return nil
        methods.add_method_mut("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.translate(dx, dy);
            Ok(())
        });

        // -- rotate --
        /// Rotates all control points around a pivot by angle radians.
        /// @param angle : number
        /// @param ox : number
        /// @param oy : number
        /// @return nil
        methods.add_method_mut("rotate", |_, this, (angle, ox, oy): (f32, f32, f32)| {
            this.inner.rotate(angle, ox, oy);
            Ok(())
        });

        // -- scale --
        /// Scales all control points around a pivot by factor s.
        /// @param s : number
        /// @param ox : number
        /// @param oy : number
        /// @return nil
        methods.add_method_mut("scale", |_, this, (s, ox, oy): (f32, f32, f32)| {
            this.inner.scale(s, ox, oy);
            Ok(())
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
        /// @param dt : number
        /// @return boolean
        methods.add_method_mut("update", |_, this, dt: f64| Ok(this.inner.update(dt)));

        // -- reset --
        /// Resets the clock to 0.
        /// @return nil
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });

        // -- getValue --
        /// Returns the interpolated value at 1-based index, or all values as a
        /// table when called with no argument.
        /// @param index : integer | nil
        /// @return number | table
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
        /// @return table
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
        /// @return boolean
        methods.add_method("isComplete", |_, this, ()| Ok(this.inner.is_complete()));

        // -- getValueCount --
        /// Returns the number of values in this tween.
        /// @return integer
        methods.add_method("getValueCount", |_, this, ()| Ok(this.inner.value_count()));

        // -- getEasingName --
        /// Returns the easing function name.
        /// @return string
        methods.add_method("getEasingName", |_, this, ()| {
            Ok(this.inner.easing_name().to_string())
        });

        // -- getDuration --
        /// Returns the tween duration in seconds.
        /// @return number
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.duration()));

        // -- getTime --
        /// Returns the current clock time.
        /// @return number
        methods.add_method("getTime", |_, this, ()| Ok(this.inner.clock()));

        // -- getClock --
        /// Alias for getTime(). Returns the current clock time.
        /// @return number
        methods.add_method("getClock", |_, this, ()| Ok(this.inner.clock()));

        // -- setTime --
        /// Sets the clock to a specific time, clamped to [0, duration].
        /// @param t : number
        /// @return nil
        methods.add_method_mut("setTime", |_, this, t: f64| {
            this.inner.set_time(t);
            Ok(())
        });

        // -- set --
        /// Alias for setTime(). Sets the clock to t, clamped to [0, duration].
        /// @param t : number
        /// @return nil
        methods.add_method_mut("set", |_, this, t: f64| {
            this.inner.set_time(t);
            Ok(())
        });

        // -- addValue --
        /// Adds a start/target value pair. Returns the 1-based index.
        /// @param start : number
        /// @param target : number
        /// @return integer
        methods.add_method_mut("addValue", |_, this, (start, target): (f64, f64)| {
            Ok(this.inner.add_value(start, target) + 1)
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
        /// @param id : string
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        methods.add_method_mut(
            "insert",
            |_, this, (id, x, y, w, h): (String, f32, f32, f32, f32)| {
                this.inner.insert(id, x, y, w, h);
                Ok(())
            },
        );

        // -- update --
        /// Updates an existing item's AABB.
        /// @param id : string
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        methods.add_method_mut(
            "update",
            |_, this, (id, x, y, w, h): (String, f32, f32, f32, f32)| {
                this.inner.update(id, x, y, w, h);
                Ok(())
            },
        );

        // -- remove --
        /// Removes an item by its ID.
        /// @param id : string
        /// @return nil
        methods.add_method_mut("remove", |_, this, id: String| {
            this.inner.remove(&id);
            Ok(())
        });

        // -- clear --
        /// Removes all items.
        /// @return nil
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });

        // -- queryRect --
        /// Returns IDs of items overlapping the query rectangle.
        /// @param x : number
        /// @param y : number
        /// @param w : number
        /// @param h : number
        /// @return table
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
        /// @param cx : number
        /// @param cy : number
        /// @param radius : number
        /// @return table
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

        // -- getCellSize --
        /// Returns the cell size.
        /// @return number
        methods.add_method("getCellSize", |_, this, ()| Ok(this.inner.cell_size()));

        // -- getItemCount --
        /// Returns the number of items in the hash.
        /// @return integer
        methods.add_method("getItemCount", |_, this, ()| Ok(this.inner.item_count()));
    }
}

// -------------------------------------------------------------------------------
// LuaNoiseGenerator UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a [`NoiseGenerator`].
pub struct LuaNoiseGenerator {
    inner: NoiseGenerator,
}

/// Resolves a noise kind string name to a [`NoiseKind`] enum.
fn resolve_noise_kind(name: &str) -> NoiseKind {
    match name.to_lowercase().as_str() {
        "simplex" => NoiseKind::Simplex,
        _ => NoiseKind::Perlin,
    }
}

/// Resolves a distance type string name to a [`DistType`] enum.
fn resolve_dist_type(name: &str) -> DistType {
    match name.to_lowercase().as_str() {
        "manhattan" => DistType::Manhattan,
        "chebyshev" => DistType::Chebyshev,
        _ => DistType::Euclidean,
    }
}

/// Resolves a fractal type string name to a [`FractalType`] enum.
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
        /// @param x : number
        /// @return number
        methods.add_method("perlin1d", |_, this, x: f64| Ok(this.inner.perlin_1d(x)));

        // -- perlin2d --
        /// Returns 2D Perlin noise at (x, y).
        /// @param x : number
        /// @param y : number
        /// @return number
        methods.add_method("perlin2d", |_, this, (x, y): (f64, f64)| {
            Ok(this.inner.perlin_2d(x, y))
        });

        // -- perlin3d --
        /// Returns 3D Perlin noise at (x, y, z).
        /// @param x : number
        /// @param y : number
        /// @param z : number
        /// @return number
        methods.add_method("perlin3d", |_, this, (x, y, z): (f64, f64, f64)| {
            Ok(this.inner.perlin_3d(x, y, z))
        });

        // -- perlin4d --
        /// Returns 4D Perlin noise at (x, y, z, w).
        /// @param x : number
        /// @param y : number
        /// @param z : number
        /// @param w : number
        /// @return number
        methods.add_method("perlin4d", |_, this, (x, y, z, w): (f64, f64, f64, f64)| {
            Ok(this.inner.perlin_4d(x, y, z, w))
        });

        // -- simplex1d --
        /// Returns 1D Simplex noise at x.
        /// @param x : number
        /// @return number
        methods.add_method("simplex1d", |_, this, x: f64| Ok(this.inner.simplex_1d(x)));

        // -- simplex2d --
        /// Returns 2D Simplex noise at (x, y).
        /// @param x : number
        /// @param y : number
        /// @return number
        methods.add_method("simplex2d", |_, this, (x, y): (f64, f64)| {
            Ok(this.inner.simplex_2d(x, y))
        });

        // -- simplex3d --
        /// Returns 3D Simplex noise at (x, y, z).
        /// @param x : number
        /// @param y : number
        /// @param z : number
        /// @return number
        methods.add_method("simplex3d", |_, this, (x, y, z): (f64, f64, f64)| {
            Ok(this.inner.simplex_3d(x, y, z))
        });

        // -- worley2d --
        /// Returns 2D Worley (cellular) noise at (x, y).
        /// @param x : number
        /// @param y : number
        /// @param distType : string?
        /// @param f2 : boolean?
        /// @return number
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
        /// @param x : number
        /// @param y : number
        /// @param z : number
        /// @param distType : string?
        /// @param f2 : boolean?
        /// @return number
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
        /// @param x : number
        /// @param y : number
        /// @param octaves : integer?
        /// @param lacunarity : number?
        /// @param persistence : number?
        /// @param kind : string?
        /// @return number
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
        /// @param x : number
        /// @param y : number
        /// @param octaves : integer?
        /// @param lacunarity : number?
        /// @param persistence : number?
        /// @param kind : string?
        /// @return number
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
        /// @param x : number
        /// @param y : number
        /// @param octaves : integer?
        /// @param lacunarity : number?
        /// @param persistence : number?
        /// @param kind : string?
        /// @return number
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
        /// @param x : number
        /// @param y : number
        /// @param strength : number
        /// @return number, number
        methods.add_method(
            "warpDomain",
            |_, this, (x, y, strength): (f64, f64, f64)| Ok(this.inner.warp_domain(x, y, strength)),
        );

        // -- generateMap --
        /// Generates a 2D noise map as a flat table (row-major).
        /// @param width : integer
        /// @param height : integer
        /// @param opts : table?
        /// @return table
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
        /// @return integer
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.seed()));

        // -- setSeed --
        /// Sets the seed and rebuilds the permutation table.
        /// @param seed : integer
        /// @return nil
        methods.add_method_mut("setSeed", |_, this, seed: u64| {
            this.inner.set_seed(seed);
            Ok(())
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.math` API table with the Lua VM.
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
/// @return LuaResult<()>
#[allow(clippy::type_complexity)]
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // ── Factory functions ────────────────────────────────────────────

    // -- newRandomGenerator --
    /// Creates a new random number generator with an optional seed.
    /// @param seed : integer?
    /// @return RandomGenerator
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
    /// @param x : number?
    /// @param y : number?
    /// @param angle : number?
    /// @param sx : number?
    /// @param sy : number?
    /// @param ox : number?
    /// @param oy : number?
    /// @param kx : number?
    /// @param ky : number?
    /// @return Transform
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
    /// @param points : table
    /// @return BezierCurve
    tbl.set(
        "newBezierCurve",
        lua.create_function(|lua, points: LuaTable| {
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
    /// @param duration : number
    /// @param easingName : string?
    /// @return Tween
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
    /// @param cellSize : number
    /// @return SpatialHash
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
    /// @param seed : integer?
    /// @return NoiseGenerator
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
    /// @param x : number
    /// @param y : number
    /// @param seed : integer?
    /// @return number
    tbl.set(
        "perlin2d",
        lua.create_function(|_, (x, y, seed): (f32, f32, Option<u32>)| {
            Ok(noise_functions::perlin2d(x, y, seed.unwrap_or(0)))
        })?,
    )?;

    // -- perlin3d --
    /// Returns 3D Perlin noise at (x, y, z) with the given seed.
    /// @param x : number
    /// @param y : number
    /// @param z : number
    /// @param seed : integer?
    /// @return number
    tbl.set(
        "perlin3d",
        lua.create_function(|_, (x, y, z, seed): (f32, f32, f32, Option<u32>)| {
            Ok(noise_functions::perlin3d(x, y, z, seed.unwrap_or(0)))
        })?,
    )?;

    // -- simplex2d --
    /// Returns 2D Simplex noise at (x, y) with the given seed.
    /// @param x : number
    /// @param y : number
    /// @param seed : integer?
    /// @return number
    tbl.set(
        "simplex2d",
        lua.create_function(|_, (x, y, seed): (f32, f32, Option<u32>)| {
            Ok(noise_functions::simplex2d(x, y, seed.unwrap_or(0)))
        })?,
    )?;

    // -- fbm --
    /// Returns fractal Brownian motion noise at (x, y).
    /// @param x : number
    /// @param y : number
    /// @param seed : integer?
    /// @param octaves : integer?
    /// @param lacunarity : number?
    /// @param gain : number?
    /// @return number
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
    /// @param name : string
    /// @param t : number
    /// @return number
    tbl.set(
        "applyEasing",
        lua.create_function(|_, (name, t): (String, f32)| {
            easing::apply(&name, t)
                .ok_or_else(|| LuaError::external(format!("Unknown easing function: {}", name)))
        })?,
    )?;

    // -- linear --
    /// Linear easing (identity).
    /// @param t : number
    /// @return number
    tbl.set(
        "linear",
        lua.create_function(|_, t: f32| Ok(easing::linear(t)))?,
    )?;

    // -- inQuad --
    /// Quadratic ease-in.
    /// @param t : number
    /// @return number
    tbl.set(
        "inQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_quad(t)))?,
    )?;

    // -- outQuad --
    /// Quadratic ease-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "outQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_quad(t)))?,
    )?;

    // -- inOutQuad --
    /// Quadratic ease-in-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "inOutQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_quad(t)))?,
    )?;

    // -- inCubic --
    /// Cubic ease-in — acceleration starts slowly then increases sharply.
    /// @param t : number
    /// @return number
    tbl.set(
        "inCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_cubic(t)))?,
    )?;

    // -- outCubic --
    /// Cubic ease-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "outCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_cubic(t)))?,
    )?;

    // -- inOutCubic --
    /// Cubic ease-in-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "inOutCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_cubic(t)))?,
    )?;

    // -- inQuart --
    /// Quartic ease-in.
    /// @param t : number
    /// @return number
    tbl.set(
        "inQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_quart(t)))?,
    )?;

    // -- outQuart --
    /// Quartic ease-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "outQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_quart(t)))?,
    )?;

    // -- inOutQuart --
    /// Quartic ease-in-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "inOutQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_quart(t)))?,
    )?;

    // -- inSine --
    /// Sinusoidal ease-in.
    /// @param t : number
    /// @return number
    tbl.set(
        "inSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_sine(t)))?,
    )?;

    // -- outSine --
    /// Sinusoidal ease-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "outSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_sine(t)))?,
    )?;

    // -- inOutSine --
    /// Sinusoidal ease-in-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "inOutSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_sine(t)))?,
    )?;

    // -- inExpo --
    /// Exponential ease-in.
    /// @param t : number
    /// @return number
    tbl.set(
        "inExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_expo(t)))?,
    )?;

    // -- outExpo --
    /// Exponential ease-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "outExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_expo(t)))?,
    )?;

    // -- inOutExpo --
    /// Exponential ease-in-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "inOutExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_expo(t)))?,
    )?;

    // -- inElastic --
    /// Elastic ease-in.
    /// @param t : number
    /// @return number
    tbl.set(
        "inElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_elastic(t)))?,
    )?;

    // -- outElastic --
    /// Elastic ease-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "outElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_elastic(t)))?,
    )?;

    // -- outBounce --
    /// Bounce ease-out.
    /// @param t : number
    /// @return number
    tbl.set(
        "outBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_bounce(t)))?,
    )?;

    // -- inBounce --
    /// Bounce ease-in.
    /// @param t : number
    /// @return number
    tbl.set(
        "inBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_bounce(t)))?,
    )?;

    // -- inBack --
    /// Back ease-in — overshoots slightly before settling at the target.
    /// @param t : number
    /// @return number
    tbl.set(
        "inBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_back(t)))?,
    )?;

    // -- outBack --
    /// Back ease-out — overshoots the target then snaps back into place.
    /// @param t : number
    /// @return number
    tbl.set(
        "outBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_back(t)))?,
    )?;

    // ── Geometry ─────────────────────────────────────────────────────

    // -- triangulate --
    /// Triangulates a simple polygon given as a flat table {x1,y1, x2,y2, ...}.
    /// Returns a table of triangle tables, each with 6 numbers.
    /// @param polygon : table
    /// @return table
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
    /// @param polygon : table
    /// @return boolean
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
    /// @param c : number
    /// @return number
    tbl.set(
        "gammaToLinear",
        lua.create_function(|_, c: f32| Ok(gamma_to_linear(c)))?,
    )?;

    // -- linearToGamma --
    /// Converts a linear-space value to gamma-encoded sRGB.
    /// @param c : number
    /// @return number
    tbl.set(
        "linearToGamma",
        lua.create_function(|_, c: f32| Ok(linear_to_gamma(c)))?,
    )?;

    // ── Geometry ────────────────────────────────────────────────────

    // -- angleBetween --
    /// Returns the angle in radians from (x1, y1) to (x2, y2).
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @return number
    tbl.set(
        "angleBetween",
        lua.create_function(|_, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            Ok(geometry::angle_between(x1, y1, x2, y2))
        })?,
    )?;

    // -- circleContainsPoint --
    /// Returns true if the point (px, py) lies inside the circle.
    /// @param cx : number
    /// @param cy : number
    /// @param r : number
    /// @param px : number
    /// @param py : number
    /// @return boolean
    tbl.set(
        "circleContainsPoint",
        lua.create_function(|_, (cx, cy, r, px, py): (f32, f32, f32, f32, f32)| {
            Ok(geometry::circle_contains_point(cx, cy, r, px, py))
        })?,
    )?;

    // -- circleIntersectsCircle --
    /// Returns true if two circles overlap.
    /// @param x1 : number
    /// @param y1 : number
    /// @param r1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @param r2 : number
    /// @return boolean
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
    /// @param cx : number
    /// @param cy : number
    /// @param r : number
    /// @param lx1 : number
    /// @param ly1 : number
    /// @param lx2 : number
    /// @param ly2 : number
    /// @return boolean, number?, number?, number?, number?
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
    /// @param cx : number
    /// @param cy : number
    /// @param r : number
    /// @param sx1 : number
    /// @param sy1 : number
    /// @param sx2 : number
    /// @param sy2 : number
    /// @return boolean, number?, number?, number?, number?
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
    /// @param px : number
    /// @param py : number
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @return number, number
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
    /// @param points : table
    /// @return table
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
    /// @param points : table
    /// @return table
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
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @param x3 : number
    /// @param y3 : number
    /// @param x4 : number
    /// @param y4 : number
    /// @return number?, number?
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
    /// @param polygon : table
    /// @param px : number
    /// @param py : number
    /// @return boolean
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
    /// @param polygon : table
    /// @return number
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
    /// @param polygon : table
    /// @return number, number
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
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @param x3 : number
    /// @param y3 : number
    /// @param x4 : number
    /// @param y4 : number
    /// @return boolean, number?, number?
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
    /// @param x1 : integer
    /// @param y1 : integer
    /// @param x2 : integer
    /// @param y2 : integer
    /// @return table
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
    /// @return number
    tbl.set("pi", std::f64::consts::PI)?;

    // -- tau --
    /// The mathematical constant τ = 2π ≈ 6.28318530717959.
    /// @return number
    tbl.set("tau", std::f64::consts::TAU)?;

    // -- huge --
    /// Positive infinity (math.huge equivalent).
    /// @return number
    tbl.set("huge", f64::INFINITY)?;

    // -- rad --
    /// Converts degrees to radians.
    /// @param deg : number
    /// @return number
    tbl.set(
        "rad",
        lua.create_function(|_, deg: f64| Ok(deg.to_radians()))?,
    )?;

    // -- deg --
    /// Converts radians to degrees.
    /// @param rad : number
    /// @return number
    tbl.set(
        "deg",
        lua.create_function(|_, rad: f64| Ok(rad.to_degrees()))?,
    )?;

    // -- sin --
    /// Returns the sine of x (radians).
    /// @param x : number
    /// @return number
    tbl.set("sin", lua.create_function(|_, x: f64| Ok(x.sin()))?)?;

    // -- cos --
    /// Returns the cosine of x (radians).
    /// @param x : number
    /// @return number
    tbl.set("cos", lua.create_function(|_, x: f64| Ok(x.cos()))?)?;

    // -- tan --
    /// Returns the tangent of x (radians).
    /// @param x : number
    /// @return number
    tbl.set("tan", lua.create_function(|_, x: f64| Ok(x.tan()))?)?;

    // -- asin --
    /// Returns the arcsine of x, in radians.
    /// @param x : number
    /// @return number
    tbl.set("asin", lua.create_function(|_, x: f64| Ok(x.asin()))?)?;

    // -- acos --
    /// Returns the arccosine of x, in radians.
    /// @param x : number
    /// @return number
    tbl.set("acos", lua.create_function(|_, x: f64| Ok(x.acos()))?)?;

    // -- atan --
    /// Returns the arctangent of x (or atan2(y, x) when two args given).
    /// @param y : number
    /// @param x : number?
    /// @return number
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
    /// @param y : number
    /// @param x : number
    /// @return number
    tbl.set(
        "atan2",
        lua.create_function(|_, (y, x): (f64, f64)| Ok(y.atan2(x)))?,
    )?;

    // -- sqrt --
    /// Returns the square root of x.
    /// @param x : number
    /// @return number
    tbl.set("sqrt", lua.create_function(|_, x: f64| Ok(x.sqrt()))?)?;

    // -- abs --
    /// Returns the absolute value of x.
    /// @param x : number
    /// @return number
    tbl.set("abs", lua.create_function(|_, x: f64| Ok(x.abs()))?)?;

    // -- floor --
    /// Returns the largest integer ≤ x.
    /// @param x : number
    /// @return number
    tbl.set("floor", lua.create_function(|_, x: f64| Ok(x.floor()))?)?;

    // -- ceil --
    /// Returns the smallest integer ≥ x.
    /// @param x : number
    /// @return number
    tbl.set("ceil", lua.create_function(|_, x: f64| Ok(x.ceil()))?)?;

    // -- round --
    /// Returns x rounded to the nearest integer (half-up).
    /// @param x : number
    /// @return number
    tbl.set("round", lua.create_function(|_, x: f64| Ok(x.round()))?)?;

    // -- exp --
    /// Returns e raised to the power x.
    /// @param x : number
    /// @return number
    tbl.set("exp", lua.create_function(|_, x: f64| Ok(x.exp()))?)?;

    // -- log --
    /// Returns the natural log of x, or log base b if b is supplied.
    /// @param x : number
    /// @param b : number?
    /// @return number
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
    /// @param x : number
    /// @param y : number
    /// @return number
    tbl.set(
        "pow",
        lua.create_function(|_, (x, y): (f64, f64)| Ok(x.powf(y)))?,
    )?;

    // -- min --
    /// Returns the smallest of the supplied numbers.
    /// @param ... : number
    /// @return number
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
    /// @param ... : number
    /// @return number
    tbl.set(
        "max",
        lua.create_function(|_, args: mlua::Variadic<f64>| {
            args.iter().copied().reduce(f64::max).ok_or_else(|| {
                mlua::Error::RuntimeError("max() requires at least one argument".into())
            })
        })?,
    )?;

    // -- clamp --
    /// Returns x clamped to [lo, hi].
    /// @param x   : number
    /// @param lo  : number
    /// @param hi  : number
    /// @return number
    tbl.set(
        "clamp",
        lua.create_function(|_, (x, lo, hi): (f64, f64, f64)| Ok(x.clamp(lo, hi)))?,
    )?;

    // -- sign --
    /// Returns -1, 0, or 1 depending on the sign of x.
    /// @param x : number
    /// @return number
    tbl.set(
        "sign",
        lua.create_function(|_, x: f64| {
            Ok(if x > 0.0 {
                1.0_f64
            } else if x < 0.0 {
                -1.0_f64
            } else {
                0.0_f64
            })
        })?,
    )?;

    // -- fmod --
    /// Returns the remainder of x / y (fmod).
    /// @param x : number
    /// @param y : number
    /// @return number
    tbl.set(
        "fmod",
        lua.create_function(|_, (x, y): (f64, f64)| Ok(x % y))?,
    )?;

    // -- lerp --
    /// Linear interpolation between a and b by fraction t.
    /// @param a : number
    /// @param b : number
    /// @param t : number
    /// @return number
    tbl.set(
        "lerp",
        lua.create_function(|_, (a, b, t): (f64, f64, f64)| Ok(a + (b - a) * t))?,
    )?;

    // -- distance --
    /// Returns the Euclidean distance between (x1,y1) and (x2,y2).
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @return number
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
    /// @param x1 : number
    /// @param y1 : number
    /// @param x2 : number
    /// @param y2 : number
    /// @return number
    tbl.set(
        "distanceSq",
        lua.create_function(|_, (x1, y1, x2, y2): (f64, f64, f64, f64)| {
            let dx = x2 - x1;
            let dy = y2 - y1;
            Ok(dx * dx + dy * dy)
        })?,
    )?;

    // -- random --
    /// Returns a pseudo-random number in [0,1) with no args,
    /// in [0, max) with one arg, or in [min, max) with two args.
    /// Uses Lua's built-in math.random for compatibility.
    /// @param min_or_max : number?
    /// @param max        : number?
    /// @return number
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
    /// @param lo : integer
    /// @param hi : integer
    /// @return integer
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
    /// @param x : number
    /// @param y : number
    /// @param z : number?
    /// @return number
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

    luna.set("math", tbl)?;
    Ok(())
}
