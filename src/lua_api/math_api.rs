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
pub struct LuaVec2 {
    pub inner: Vec2,
}
impl LuaUserData for LuaVec2 {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        fields.add_field_method_get("x", |_, this| Ok(this.inner.x as f64));
        fields.add_field_method_set("x", |_, this, v: f64| {
            this.inner.x = v as f32;
            Ok(())
        });
        fields.add_field_method_get("y", |_, this| Ok(this.inner.y as f64));
        fields.add_field_method_set("y", |_, this, v: f64| {
            this.inner.y = v as f32;
            Ok(())
        });
    }
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner.dot(o.inner) as f64)
        });
        methods.add_method("length", |_, this, ()| Ok(this.inner.length() as f64));
        methods.add_method("x", |_, this, ()| Ok(this.inner.x as f64));
        methods.add_method("y", |_, this, ()| Ok(this.inner.y as f64));
        methods.add_method("lengthSquared", |_, this, ()| {
            Ok(this.inner.length_squared() as f64)
        });
        methods.add_method("normalize", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.normalize(),
            })
        });
        methods.add_method("normalized", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.normalize(),
            })
        });
        methods.add_method("lerp", |lua, this, (other, t): (LuaAnyUserData, f64)| {
            let o = other.borrow::<LuaVec2>()?;
            lua.create_userdata(LuaVec2 {
                inner: this.inner.lerp(o.inner, t as f32),
            })
        });
        methods.add_method("distance", |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner.distance(o.inner) as f64)
        });
        methods.add_method("angle", |_, this, ()| Ok(this.inner.angle() as f64));
        methods.add_method("rotate", |lua, this, angle: f64| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.rotate(angle as f32),
            })
        });
        methods.add_method("perpendicular", |lua, this, ()| {
            lua.create_userdata(LuaVec2 {
                inner: this.inner.perpendicular(),
            })
        });
        methods.add_method("cross", |_, this, other: LuaAnyUserData| {
            let o = other.borrow::<LuaVec2>()?;
            Ok(this.inner.cross(o.inner) as f64)
        });
        methods.add_function("fromAngle", |lua, radians: f64| {
            lua.create_userdata(LuaVec2 {
                inner: Vec2::from_angle(radians as f32),
            })
        });
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
        methods.add_method("type", |_, _, ()| Ok("LVec2"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LVec2" || name == "Object")
        });
    }
}
pub struct LuaVec3 {
    pub inner: Vec3,
}
impl LuaUserData for LuaVec3 {
    fn add_fields<'lua, F: LuaUserDataFields<'lua, Self>>(fields: &mut F) {
        fields.add_field_method_get("x", |_, this| Ok(this.inner.x));
        fields.add_field_method_set("x", |_, this, v: f32| {
            this.inner.x = v;
            Ok(())
        });
        fields.add_field_method_get("y", |_, this| Ok(this.inner.y));
        fields.add_field_method_set("y", |_, this, v: f32| {
            this.inner.y = v;
            Ok(())
        });
        fields.add_field_method_get("z", |_, this| Ok(this.inner.z));
        fields.add_field_method_set("z", |_, this, v: f32| {
            this.inner.z = v;
            Ok(())
        });
    }
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("length", |_, this, ()| Ok(this.inner.length()));
        methods.add_method("lengthSquared", |_, this, ()| {
            Ok(this.inner.length_squared())
        });
        methods.add_method("normalize", |lua, this, ()| {
            lua.create_userdata(LuaVec3 {
                inner: this.inner.normalize(),
            })
        });
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            Ok(this.inner.dot(v.inner))
        });
        methods.add_method("cross", |lua, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner.cross(v.inner),
            })
        });
        methods.add_method("lerp", |lua, this, (other, t): (LuaAnyUserData, f32)| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner.lerp(v.inner, t),
            })
        });
        methods.add_method("distance", |_, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            Ok(this.inner.distance(v.inner))
        });
        methods.add_method("add", |lua, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner + v.inner,
            })
        });
        methods.add_method("sub", |lua, this, other: LuaAnyUserData| {
            let v = other.borrow::<LuaVec3>()?;
            lua.create_userdata(LuaVec3 {
                inner: this.inner - v.inner,
            })
        });
        methods.add_method("scale", |lua, this, s: f32| {
            lua.create_userdata(LuaVec3 {
                inner: this.inner * s,
            })
        });
        methods.add_function("splat", |lua, v: f32| {
            lua.create_userdata(LuaVec3 {
                inner: Vec3::splat(v),
            })
        });
        methods.add_method("type", |_, _, ()| Ok("LVec3"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LVec3" || name == "Object")
        });
    }
}
pub struct LuaCatmullRom {
    inner: CatmullRomSpline,
}
impl LuaUserData for LuaCatmullRom {
    #[allow(clippy::map_identity)]
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("sample", |_, this, t: f32| {
            let (x, y) = this.inner.sample(t);
            Ok((x, y))
        });
        methods.add_method("sampleSegment", |_, this, (seg, t): (usize, f32)| {
            let (x, y) = this.inner.sample_segment(seg, t);
            Ok((x, y))
        });
        methods.add_method("len", |_, this, ()| Ok(this.inner.len()));
        methods.add_method_mut("addPoint", |_, this, (x, y): (f32, f32)| {
            this.inner.add_point((x, y));
            Ok(())
        });
        methods.add_method_mut("removePoint", |_, this, idx: usize| {
            this.inner
                .remove_point(idx)
                .map(|(x, y)| (x, y))
                .ok_or_else(|| LuaError::RuntimeError("index out of bounds".into()))
        });
        methods.add_method("type", |_, _, ()| Ok("LCatmullRom"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCatmullRom" || name == "Object")
        });
    }
}
pub struct LuaHermite {
    inner: HermiteSpline,
}
impl LuaUserData for LuaHermite {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("sample", |_, this, t: f32| {
            let (x, y) = this.inner.sample(t);
            Ok((x, y))
        });
        methods.add_method("type", |_, _, ()| Ok("LHermite"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LHermite" || name == "Object")
        });
    }
}
pub struct LuaRandomGenerator {
    inner: RandomGenerator,
}
impl LuaUserData for LuaRandomGenerator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("random", |_, this, ()| Ok(this.inner.random()));
        methods.add_method_mut("randomFloat", |_, this, (min, max): (f64, f64)| {
            Ok(this.inner.random_float(min, max))
        });
        methods.add_method_mut("randomInt", |_, this, (min, max): (i64, i64)| {
            Ok(this.inner.random_int(min, max))
        });
        methods.add_method_mut(
            "randomNormal",
            |_, this, (stddev, mean): (Option<f64>, Option<f64>)| {
                Ok(this
                    .inner
                    .random_normal(stddev.unwrap_or(1.0), mean.unwrap_or(0.0)))
            },
        );
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.get_seed()));
        methods.add_method_mut("setSeed", |_, this, seed: u64| {
            this.inner.set_seed(seed);
            Ok(())
        });
        methods.add_method("getState", |_, this, ()| Ok(this.inner.get_state()));
        methods.add_method_mut("setState", |_, this, state: String| {
            this.inner.set_state(&state).map_err(LuaError::external)?;
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LRandomGenerator"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LRandomGenerator" || name == "Object")
        });
    }
}
pub struct LuaTransform {
    inner: Transform,
}
impl LuaUserData for LuaTransform {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.translate(dx, dy);
            Ok(())
        });
        methods.add_method_mut("rotate", |_, this, angle: f32| {
            this.inner.rotate(angle);
            Ok(())
        });
        methods.add_method_mut("scale", |_, this, (sx, sy): (f32, Option<f32>)| {
            this.inner.scale(sx, sy.unwrap_or(sx));
            Ok(())
        });
        methods.add_method_mut("shear", |_, this, (kx, ky): (f32, f32)| {
            this.inner.shear(kx, ky);
            Ok(())
        });
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });
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
        methods.add_method("transformPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.transform_point(x, y))
        });
        methods.add_method("inverseTransformPoint", |_, this, (x, y): (f32, f32)| {
            Ok(this.inner.inverse_transform_point(x, y))
        });
        methods.add_method("inverse", |lua, this, ()| {
            lua.create_userdata(LuaTransform {
                inner: this.inner.inverse(),
            })
        });
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(LuaTransform { inner: this.inner })
        });
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
        methods.add_method("decompose", |_, this, ()| Ok(this.inner.decompose()));
        methods.add_method("type", |_, _, ()| Ok("LTransform"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTransform" || name == "Object")
        });
    }
}
pub struct LuaBezierCurve {
    inner: BezierCurve,
}
impl LuaUserData for LuaBezierCurve {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("evaluate", |_, this, t: f32| {
            let p = this.inner.evaluate(t);
            Ok((p.x, p.y))
        });
        methods.add_method("render", |lua, this, segments: usize| {
            let points = this.inner.render(segments);
            let t = lua.create_table()?;
            for (i, p) in points.iter().enumerate() {
                t.set(i + 1, vec![p.x, p.y])?;
            }
            Ok(t)
        });
        methods.add_method("getDerivative", |lua, this, ()| {
            lua.create_userdata(LuaBezierCurve {
                inner: this.inner.get_derivative(),
            })
        });
        methods.add_method("getControlPoint", |_, this, index: usize| {
            if index == 0 {
                return Ok((None, None));
            }
            match this.inner.get_control_point(index - 1) {
                Some(p) => Ok((Some(p.x), Some(p.y))),
                None => Ok((None, None)),
            }
        });
        methods.add_method_mut(
            "setControlPoint",
            |_, this, (index, x, y): (usize, f32, f32)| {
                if index == 0 {
                    return Ok(false);
                }
                Ok(this.inner.set_control_point(index - 1, Vec2::new(x, y)))
            },
        );
        methods.add_method_mut(
            "insertControlPoint",
            |_, this, (x, y, index): (f32, f32, Option<usize>)| {
                this.inner
                    .insert_control_point(Vec2::new(x, y), index.map(|i| i.saturating_sub(1)));
                Ok(())
            },
        );
        methods.add_method_mut("removeControlPoint", |_, this, index: usize| {
            if index == 0 {
                return Ok(false);
            }
            Ok(this.inner.remove_control_point(index - 1))
        });
        methods.add_method("getControlPointCount", |_, this, ()| {
            Ok(this.inner.get_control_point_count())
        });
        methods.add_method("length", |_, this, ()| Ok(this.inner.length()));
        methods.add_method(
            "evaluateAtDistance",
            |_, this, (distance, samples): (f32, Option<usize>)| {
                let p = this
                    .inner
                    .evaluate_at_distance(distance, samples.unwrap_or(128));
                Ok((p.x, p.y))
            },
        );
        methods.add_method_mut("translate", |_, this, (dx, dy): (f32, f32)| {
            this.inner.translate(dx, dy);
            Ok(())
        });
        methods.add_method_mut("rotate", |_, this, (angle, ox, oy): (f32, f32, f32)| {
            this.inner.rotate(angle, ox, oy);
            Ok(())
        });
        methods.add_method_mut("scale", |_, this, (s, ox, oy): (f32, f32, f32)| {
            this.inner.scale(s, ox, oy);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LBezierCurve"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LBezierCurve" || name == "Object")
        });
    }
}
pub struct LuaTween {
    inner: Tween,
}
impl LuaUserData for LuaTween {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("update", |_, this, dt: f64| Ok(this.inner.update(dt)));
        methods.add_method_mut("reset", |_, this, ()| {
            this.inner.reset();
            Ok(())
        });
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
        methods.add_method("getAllValues", |lua, this, ()| {
            let vals = this.inner.get_all_values();
            let t = lua.create_table()?;
            for (i, v) in vals.iter().enumerate() {
                t.set(i + 1, *v)?;
            }
            Ok(t)
        });
        methods.add_method("isComplete", |_, this, ()| Ok(this.inner.is_complete()));
        methods.add_method("getValueCount", |_, this, ()| Ok(this.inner.value_count()));
        methods.add_method("getEasingName", |_, this, ()| {
            Ok(this.inner.easing_name().to_string())
        });
        methods.add_method("getDuration", |_, this, ()| Ok(this.inner.duration()));
        methods.add_method("getTime", |_, this, ()| Ok(this.inner.clock()));
        methods.add_method("getClock", |_, this, ()| Ok(this.inner.clock()));
        methods.add_method_mut("setTime", |_, this, t: f64| {
            this.inner.set_time(t);
            Ok(())
        });
        methods.add_method_mut("set", |_, this, t: f64| {
            this.inner.set_time(t);
            Ok(())
        });
        methods.add_method_mut("addValue", |_, this, (start, target): (f64, f64)| {
            Ok(this.inner.add_value(start, target) + 1)
        });
        methods.add_method("type", |_, _, ()| Ok("LTween"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LTween" || name == "Object")
        });
    }
}
pub struct LuaSpatialHash {
    inner: SpatialHash,
}
impl LuaUserData for LuaSpatialHash {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "insert",
            |_, this, (id, x, y, w, h): (String, f32, f32, f32, f32)| {
                this.inner.insert(id, x, y, w, h);
                Ok(())
            },
        );
        methods.add_method_mut(
            "update",
            |_, this, (id, x, y, w, h): (String, f32, f32, f32, f32)| {
                this.inner.update(id, x, y, w, h);
                Ok(())
            },
        );
        methods.add_method_mut("remove", |_, this, id: String| {
            this.inner.remove(&id);
            Ok(())
        });
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
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
        methods.add_method("getCellSize", |_, this, ()| Ok(this.inner.cell_size()));
        methods.add_method("getItemCount", |_, this, ()| Ok(this.inner.item_count()));
        methods.add_method("type", |_, _, ()| Ok("LSpatialHash"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSpatialHash" || name == "Object")
        });
    }
}
pub struct LuaNoiseGenerator {
    inner: NoiseGenerator,
}
fn resolve_noise_kind(name: &str) -> NoiseKind {
    match name.to_lowercase().as_str() {
        "simplex" => NoiseKind::Simplex,
        _ => NoiseKind::Perlin,
    }
}
fn resolve_dist_type(name: &str) -> DistType {
    match name.to_lowercase().as_str() {
        "manhattan" => DistType::Manhattan,
        "chebyshev" => DistType::Chebyshev,
        _ => DistType::Euclidean,
    }
}
fn resolve_fractal_type(name: &str) -> FractalType {
    match name.to_lowercase().as_str() {
        "ridged" => FractalType::Ridged,
        "turbulence" => FractalType::Turbulence,
        _ => FractalType::Fbm,
    }
}
impl LuaUserData for LuaNoiseGenerator {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("perlin1d", |_, this, x: f64| Ok(this.inner.perlin_1d(x)));
        methods.add_method("perlin2d", |_, this, (x, y): (f64, f64)| {
            Ok(this.inner.perlin_2d(x, y))
        });
        methods.add_method("perlin3d", |_, this, (x, y, z): (f64, f64, f64)| {
            Ok(this.inner.perlin_3d(x, y, z))
        });
        methods.add_method("perlin4d", |_, this, (x, y, z, w): (f64, f64, f64, f64)| {
            Ok(this.inner.perlin_4d(x, y, z, w))
        });
        methods.add_method("simplex1d", |_, this, x: f64| Ok(this.inner.simplex_1d(x)));
        methods.add_method("simplex2d", |_, this, (x, y): (f64, f64)| {
            Ok(this.inner.simplex_2d(x, y))
        });
        methods.add_method("simplex3d", |_, this, (x, y, z): (f64, f64, f64)| {
            Ok(this.inner.simplex_3d(x, y, z))
        });
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
        methods.add_method(
            "warpDomain",
            |_, this, (x, y, strength): (f64, f64, f64)| Ok(this.inner.warp_domain(x, y, strength)),
        );
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
        methods.add_method("getSeed", |_, this, ()| Ok(this.inner.seed()));
        methods.add_method_mut("setSeed", |_, this, seed: u64| {
            this.inner.set_seed(seed);
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LNoiseGenerator"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LNoiseGenerator" || name == "Object")
        });
    }
}
pub struct LuaCircle {
    inner: Circle,
}
impl LuaUserData for LuaCircle {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("area", |_, this, ()| Ok(this.inner.area()));
        methods.add_method("perimeter", |_, this, ()| Ok(this.inner.perimeter()));
        methods.add_method("contains", |_, this, (px, py): (f32, f32)| {
            Ok(this.inner.contains(px, py))
        });
        methods.add_method("intersects", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaCircle>()?;
            Ok(this.inner.intersects(&other.inner))
        });
        methods.add_method("aabb", |_, this, ()| {
            let (x1, y1, x2, y2) = this.inner.aabb();
            Ok((x1, y1, x2, y2))
        });
        methods.add_method("x", |_, this, ()| Ok(this.inner.x));
        methods.add_method("y", |_, this, ()| Ok(this.inner.y));
        methods.add_method("radius", |_, this, ()| Ok(this.inner.radius));
        methods.add_method("type", |_, _, ()| Ok("LCircle"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LCircle" || name == "Object")
        });
    }
}
pub struct LuaAabbTree {
    inner: AabbTree,
}
pub struct LuaRectPacker {
    inner: RectPacker,
}
impl LuaUserData for LuaRectPacker {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "pack",
            |_, this, (w, h, id): (u32, u32, Option<String>)| match this.inner.pack(w, h, id) {
                Some(r) => Ok((Some(r.x), Some(r.y))),
                None => Ok((None::<u32>, None::<u32>)),
            },
        );
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method("occupancy", |_, this, ()| Ok(this.inner.occupancy()));
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
impl LuaUserData for LuaAabbTree {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut(
            "insert",
            |_, this, (id, min_x, min_y, max_x, max_y): (u64, f32, f32, f32, f32)| {
                this.inner.insert(id, min_x, min_y, max_x, max_y);
                Ok(())
            },
        );
        methods.add_method_mut("remove", |_, this, id: u64| Ok(this.inner.remove(id)));
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
        methods.add_method("queryPoint", |lua, this, (x, y): (f32, f32)| {
            let ids = this.inner.query_point(x, y);
            let t = lua.create_table()?;
            for (i, id) in ids.iter().enumerate() {
                t.set(i + 1, *id)?;
            }
            Ok(t)
        });
        methods.add_method_mut(
            "update",
            |_, this, (id, min_x, min_y, max_x, max_y): (u64, f32, f32, f32, f32)| {
                Ok(this.inner.update(id, min_x, min_y, max_x, max_y))
            },
        );
        methods.add_method("contains", |_, this, id: u64| Ok(this.inner.contains(id)));
        methods.add_method("len", |_, this, ()| Ok(this.inner.len() as i64));
        methods.add_method("isEmpty", |_, this, ()| Ok(this.inner.is_empty()));
        methods.add_method_mut("clear", |_, this, ()| {
            this.inner.clear();
            Ok(())
        });
        methods.add_method("type", |_, _, ()| Ok("LAabbTree"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LAabbTree" || name == "Object")
        });
    }
}
#[allow(clippy::type_complexity)]
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
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
    tbl.set(
        "newTween",
        lua.create_function(|lua, (duration, easing_name): (f64, Option<String>)| {
            let name = easing_name.as_deref().unwrap_or("linear");
            lua.create_userdata(LuaTween {
                inner: Tween::new(duration, name),
            })
        })?,
    )?;
    tbl.set(
        "newSpatialHash",
        lua.create_function(|lua, cell_size: f32| {
            lua.create_userdata(LuaSpatialHash {
                inner: SpatialHash::new(cell_size),
            })
        })?,
    )?;
    tbl.set(
        "newNoiseGenerator",
        lua.create_function(|lua, seed: Option<u64>| {
            lua.create_userdata(LuaNoiseGenerator {
                inner: NoiseGenerator::new(seed.unwrap_or(0)),
            })
        })?,
    )?;
    tbl.set(
        "newRectPacker",
        lua.create_function(|lua, (width, height, padding): (u32, u32, Option<u32>)| {
            lua.create_userdata(LuaRectPacker {
                inner: RectPacker::new(width, height, padding.unwrap_or(0)),
            })
        })?,
    )?;
    tbl.set(
        "perlin2d",
        lua.create_function(|_, (x, y, seed): (f32, f32, Option<u32>)| {
            Ok(noise_functions::perlin2d(x, y, seed.unwrap_or(0)))
        })?,
    )?;
    tbl.set(
        "perlin3d",
        lua.create_function(|_, (x, y, z, seed): (f32, f32, f32, Option<u32>)| {
            Ok(noise_functions::perlin3d(x, y, z, seed.unwrap_or(0)))
        })?,
    )?;
    tbl.set(
        "simplex2d",
        lua.create_function(|_, (x, y, seed): (f32, f32, Option<u32>)| {
            Ok(noise_functions::simplex2d(x, y, seed.unwrap_or(0)))
        })?,
    )?;
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
    tbl.set(
        "applyEasing",
        lua.create_function(|_, (name, t): (String, f32)| {
            easing::apply(&name, t)
                .ok_or_else(|| LuaError::external(format!("Unknown easing function: {}", name)))
        })?,
    )?;
    tbl.set(
        "linear",
        lua.create_function(|_, t: f32| Ok(easing::linear(t)))?,
    )?;
    tbl.set(
        "inQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_quad(t)))?,
    )?;
    tbl.set(
        "outQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_quad(t)))?,
    )?;
    tbl.set(
        "inOutQuad",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_quad(t)))?,
    )?;
    tbl.set(
        "inCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_cubic(t)))?,
    )?;
    tbl.set(
        "outCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_cubic(t)))?,
    )?;
    tbl.set(
        "inOutCubic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_cubic(t)))?,
    )?;
    tbl.set(
        "inQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_quart(t)))?,
    )?;
    tbl.set(
        "outQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_quart(t)))?,
    )?;
    tbl.set(
        "inOutQuart",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_quart(t)))?,
    )?;
    tbl.set(
        "inSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_sine(t)))?,
    )?;
    tbl.set(
        "outSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_sine(t)))?,
    )?;
    tbl.set(
        "inOutSine",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_sine(t)))?,
    )?;
    tbl.set(
        "inExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_expo(t)))?,
    )?;
    tbl.set(
        "outExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_expo(t)))?,
    )?;
    tbl.set(
        "inOutExpo",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_expo(t)))?,
    )?;
    tbl.set(
        "inElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_elastic(t)))?,
    )?;
    tbl.set(
        "outElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_elastic(t)))?,
    )?;
    tbl.set(
        "outBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_bounce(t)))?,
    )?;
    tbl.set(
        "inBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_bounce(t)))?,
    )?;
    tbl.set(
        "inBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_back(t)))?,
    )?;
    tbl.set(
        "outBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_out_back(t)))?,
    )?;
    tbl.set(
        "inOutElastic",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_elastic(t)))?,
    )?;
    tbl.set(
        "inOutBounce",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_bounce(t)))?,
    )?;
    tbl.set(
        "inOutBack",
        lua.create_function(|_, t: f32| Ok(easing::ease_in_out_back(t)))?,
    )?;
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
    tbl.set(
        "gammaToLinear",
        lua.create_function(|_, c: f32| Ok(gamma_to_linear(c)))?,
    )?;
    tbl.set(
        "linearToGamma",
        lua.create_function(|_, c: f32| Ok(linear_to_gamma(c)))?,
    )?;
    tbl.set(
        "angleBetween",
        lua.create_function(|_, (x1, y1, x2, y2): (f32, f32, f32, f32)| {
            Ok(geometry::angle_between(x1, y1, x2, y2))
        })?,
    )?;
    tbl.set(
        "circleContainsPoint",
        lua.create_function(|_, (cx, cy, r, px, py): (f32, f32, f32, f32, f32)| {
            Ok(geometry::circle_contains_point(cx, cy, r, px, py))
        })?,
    )?;
    tbl.set(
        "circleIntersectsCircle",
        lua.create_function(
            |_, (x1, y1, r1, x2, y2, r2): (f32, f32, f32, f32, f32, f32)| {
                Ok(geometry::circle_intersects_circle(x1, y1, r1, x2, y2, r2))
            },
        )?,
    )?;
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
    tbl.set(
        "closestPointOnSegment",
        lua.create_function(
            |_, (px, py, x1, y1, x2, y2): (f32, f32, f32, f32, f32, f32)| {
                Ok(geometry::closest_point_on_segment(px, py, x1, y1, x2, y2))
            },
        )?,
    )?;
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
    tbl.set(
        "rad",
        lua.create_function(|_, deg: f64| Ok(deg.to_radians()))?,
    )?;
    tbl.set(
        "deg",
        lua.create_function(|_, rad: f64| Ok(rad.to_degrees()))?,
    )?;
    tbl.set("sin", lua.create_function(|_, x: f64| Ok(x.sin()))?)?;
    tbl.set("cos", lua.create_function(|_, x: f64| Ok(x.cos()))?)?;
    tbl.set("tan", lua.create_function(|_, x: f64| Ok(x.tan()))?)?;
    tbl.set("asin", lua.create_function(|_, x: f64| Ok(x.asin()))?)?;
    tbl.set("acos", lua.create_function(|_, x: f64| Ok(x.acos()))?)?;
    tbl.set(
        "atan",
        lua.create_function(|_, (y, x): (f64, Option<f64>)| {
            Ok(match x {
                Some(xv) => y.atan2(xv),
                None => y.atan(),
            })
        })?,
    )?;
    tbl.set(
        "atan2",
        lua.create_function(|_, (y, x): (f64, f64)| Ok(y.atan2(x)))?,
    )?;
    tbl.set("sqrt", lua.create_function(|_, x: f64| Ok(x.sqrt()))?)?;
    tbl.set("abs", lua.create_function(|_, x: f64| Ok(x.abs()))?)?;
    tbl.set("floor", lua.create_function(|_, x: f64| Ok(x.floor()))?)?;
    tbl.set("ceil", lua.create_function(|_, x: f64| Ok(x.ceil()))?)?;
    tbl.set("round", lua.create_function(|_, x: f64| Ok(x.round()))?)?;
    tbl.set("exp", lua.create_function(|_, x: f64| Ok(x.exp()))?)?;
    tbl.set(
        "log",
        lua.create_function(|_, (x, b): (f64, Option<f64>)| {
            Ok(match b {
                Some(base) => x.log(base),
                None => x.ln(),
            })
        })?,
    )?;
    tbl.set(
        "pow",
        lua.create_function(|_, (x, y): (f64, f64)| Ok(x.powf(y)))?,
    )?;
    tbl.set(
        "min",
        lua.create_function(|_, args: mlua::Variadic<f64>| {
            args.iter().copied().reduce(f64::min).ok_or_else(|| {
                mlua::Error::RuntimeError("min() requires at least one argument".into())
            })
        })?,
    )?;
    tbl.set(
        "max",
        lua.create_function(|_, args: mlua::Variadic<f64>| {
            args.iter().copied().reduce(f64::max).ok_or_else(|| {
                mlua::Error::RuntimeError("max() requires at least one argument".into())
            })
        })?,
    )?;
    tbl.set(
        "fmod",
        lua.create_function(|_, (x, y): (f64, f64)| Ok(x % y))?,
    )?;
    tbl.set(
        "distance",
        lua.create_function(|_, (x1, y1, x2, y2): (f64, f64, f64, f64)| {
            let dx = x2 - x1;
            let dy = y2 - y1;
            Ok((dx * dx + dy * dy).sqrt())
        })?,
    )?;
    tbl.set(
        "distanceSq",
        lua.create_function(|_, (x1, y1, x2, y2): (f64, f64, f64, f64)| {
            let dx = x2 - x1;
            let dy = y2 - y1;
            Ok(dx * dx + dy * dy)
        })?,
    )?;
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
    tbl.set(
        "randomInt",
        lua.create_function(|lua, (lo, hi): (i64, i64)| {
            let math: mlua::Table = lua.globals().get("math")?;
            let f: mlua::Function = math.get("random")?;
            let v: i64 = f.call((lo, hi))?;
            Ok(v)
        })?,
    )?;
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
    tbl.set(
        "vec2",
        lua.create_function(|lua, (x, y): (f64, f64)| {
            lua.create_userdata(LuaVec2 {
                inner: Vec2::new(x as f32, y as f32),
            })
        })?,
    )?;
    tbl.set(
        "Vec2",
        lua.create_function(|lua, (x, y): (f64, f64)| {
            lua.create_userdata(LuaVec2 {
                inner: Vec2::new(x as f32, y as f32),
            })
        })?,
    )?;
    tbl.set(
        "vec3",
        lua.create_function(|lua, (x, y, z): (f32, f32, f32)| {
            lua.create_userdata(LuaVec3 {
                inner: Vec3::new(x, y, z),
            })
        })?,
    )?;
    tbl.set(
        "Vec3",
        lua.create_function(|lua, (x, y, z): (f32, f32, f32)| {
            lua.create_userdata(LuaVec3 {
                inner: Vec3::new(x, y, z),
            })
        })?,
    )?;
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
    tbl.set("hermite", lua.create_function(|lua, (p0x, p0y, p1x, p1y, m0x, m0y, m1x, m1y): (f32, f32, f32, f32, f32, f32, f32, f32)| {
            let hs = HermiteSpline::new((p0x, p0y), (p1x, p1y), (m0x, m0y), (m1x, m1y));
            lua.create_userdata(LuaHermite { inner: hs })
        })?,
    )?;
    tbl.set(
        "lerp",
        lua.create_function(|_, (a, b, t): (f32, f32, f32)| Ok(lerp(a, b, t)))?,
    )?;
    tbl.set(
        "remap",
        lua.create_function(
            |_, (v, in_min, in_max, out_min, out_max): (f32, f32, f32, f32, f32)| {
                Ok(remap(v, in_min, in_max, out_min, out_max))
            },
        )?,
    )?;
    tbl.set(
        "clamp",
        lua.create_function(|_, (v, min, max): (f32, f32, f32)| Ok(clamp(v, min, max)))?,
    )?;
    tbl.set("sign", lua.create_function(|_, v: f32| Ok(sign(v)))?)?;
    tbl.set(
        "smoothstep",
        lua.create_function(|_, (edge0, edge1, x): (f32, f32, f32)| {
            Ok(smoothstep(edge0, edge1, x))
        })?,
    )?;
    tbl.set(
        "inverseLerp",
        lua.create_function(|_, (a, b, v): (f32, f32, f32)| Ok(inverse_lerp(a, b, v)))?,
    )?;
    tbl.set(
        "hslToRgb",
        lua.create_function(|_, (h, s, l): (f32, f32, f32)| {
            let c = hsl_to_rgb(h, s, l);
            Ok((c.r, c.g, c.b, c.a))
        })?,
    )?;
    tbl.set(
        "fromHex",
        lua.create_function(|_, hex: String| {
            use crate::math::Color;
            Color::from_hex(&hex)
                .map(|c| (c.r, c.g, c.b, c.a))
                .ok_or_else(|| LuaError::RuntimeError(format!("invalid hex color: {}", hex)))
        })?,
    )?;
    tbl.set(
        "rgbToHsl",
        lua.create_function(|_, (r, g, b): (f32, f32, f32)| {
            use crate::math::Color;
            let c = Color::new(r, g, b, 1.0);
            Ok(c.to_hsl())
        })?,
    )?;
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
    tbl.set(
        "rectFromCenter",
        lua.create_function(|_, (cx, cy, w, h): (f32, f32, f32, f32)| {
            let r = Rect::from_center(cx, cy, w, h);
            Ok((r.x, r.y, r.width, r.height))
        })?,
    )?;
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
    tbl.set(
        "aabbTree",
        lua.create_function(|lua, ()| {
            lua.create_userdata(LuaAabbTree {
                inner: AabbTree::new(),
            })
        })?,
    )?;
    tbl.set(
        "newCircle",
        lua.create_function(|lua, (x, y, radius): (f32, f32, f32)| {
            lua.create_userdata(LuaCircle {
                inner: Circle::new(x, y, radius),
            })
        })?,
    )?;
    tbl.set(
        "polygonIntersection",
        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {
            let va = lua_table_to_poly(a)?;
            let vb = lua_table_to_poly(b)?;
            let result = polygon::polygon_intersection(&va, &vb);
            poly_to_lua_table(lua, &result)
        })?,
    )?;
    tbl.set(
        "polygonUnion",
        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {
            let va = lua_table_to_poly(a)?;
            let vb = lua_table_to_poly(b)?;
            let result = polygon::polygon_union(&va, &vb);
            poly_to_lua_table(lua, &result)
        })?,
    )?;
    tbl.set(
        "polygonDifference",
        lua.create_function(|lua, (a, b): (LuaTable, LuaTable)| {
            let va = lua_table_to_poly(a)?;
            let vb = lua_table_to_poly(b)?;
            let result = polygon::polygon_difference(&va, &vb);
            poly_to_lua_table(lua, &result)
        })?,
    )?;
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
