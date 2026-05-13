use super::SharedState;
use crate::compute::analytics;
use crate::compute::array::{DataType, NdArray};
use crate::compute::linalg;
use crate::compute::ops;
use crate::compute::spatial;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
fn parse_shape(value: LuaValue) -> LuaResult<Vec<usize>> {
    let table = value
        .as_table()
        .ok_or_else(|| LuaError::RuntimeError("shape must be a table".into()))?;
    let mut shape = Vec::new();
    for i in 1..=table.len()? {
        let dim: i64 = table.get(i)?;
        if dim <= 0 {
            return Err(LuaError::RuntimeError(
                "shape dimensions must be positive".into(),
            ));
        }
        shape.push(dim as usize);
    }
    if shape.is_empty() {
        return Err(LuaError::RuntimeError("shape must not be empty".into()));
    }
    Ok(shape)
}
fn parse_dtype(s: Option<String>) -> LuaResult<DataType> {
    let name = s.as_deref().unwrap_or("float32");
    DataType::parse(name).map_err(LuaError::RuntimeError)
}
fn parse_lua_indices(args: &[LuaValue]) -> LuaResult<Vec<usize>> {
    args.iter()
        .map(|v| match v {
            LuaValue::Integer(n) => {
                if *n < 1 {
                    Err(LuaError::RuntimeError("index must be >= 1".into()))
                } else {
                    Ok((*n - 1) as usize)
                }
            }
            LuaValue::Number(n) => {
                let i = *n as i64;
                if i < 1 {
                    Err(LuaError::RuntimeError("index must be >= 1".into()))
                } else {
                    Ok((i - 1) as usize)
                }
            }
            _ => Err(LuaError::RuntimeError("indices must be integers".into())),
        })
        .collect()
}
macro_rules! dispatch_arith {
    ($methods:ident, $name:expr, $doc:expr, $arr_fn:path, $scalar_fn:path) => {
        $methods.add_method($name, |lua, this, value: LuaValue| {
            let result = match value {
                LuaValue::Number(n) => {
                    $scalar_fn(&this.inner, n).map_err(LuaError::RuntimeError)?
                }
                LuaValue::Integer(n) => {
                    $scalar_fn(&this.inner, n as f64).map_err(LuaError::RuntimeError)?
                }
                LuaValue::UserData(ud) => {
                    let other = ud.borrow::<LuaArray>()?;
                    $arr_fn(&this.inner, &other.inner).map_err(LuaError::RuntimeError)?
                }
                _ => return Err(LuaError::RuntimeError("expected Array or number".into())),
            };
            lua.create_userdata(LuaArray { inner: result })
        });
    };
}
pub struct LuaArray {
    inner: NdArray,
}
impl LuaUserData for LuaArray {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getShape", |lua, this, ()| {
            let table = lua.create_table()?;
            for (i, &dim) in this.inner.shape().iter().enumerate() {
                table.set(i + 1, dim)?;
            }
            Ok(table)
        });
        methods.add_method("getDimensions", |_, this, ()| Ok(this.inner.ndim()));
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.size()));
        methods.add_method("getDataType", |_, this, ()| {
            Ok(this.inner.dtype().name().to_string())
        });
        methods.add_method("isOnGPU", |_, _this, ()| Ok(false));
        methods.add_method("get", |_, this, args: LuaMultiValue| {
            let indices = parse_lua_indices(&args.into_vec())?;
            this.inner
                .get_by_indices(&indices)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("set", |_, this, args: LuaMultiValue| {
            let args_vec = args.into_vec();
            if args_vec.len() < 2 {
                return Err(LuaError::RuntimeError(
                    "set requires at least one index and a value".into(),
                ));
            }
            let val = match &args_vec[args_vec.len() - 1] {
                LuaValue::Number(n) => *n,
                LuaValue::Integer(n) => *n as f64,
                _ => {
                    return Err(LuaError::RuntimeError(
                        "last argument to set must be a number".into(),
                    ))
                }
            };
            let indices = parse_lua_indices(&args_vec[..args_vec.len() - 1])?;
            this.inner
                .set_by_indices(&indices, val)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("toTable", |lua, this, ()| {
            let values = this.inner.to_f64_vec();
            let table = lua.create_table()?;
            for (i, &v) in values.iter().enumerate() {
                table.set(i + 1, v)?;
            }
            Ok(table)
        });
        methods.add_method("reshape", |lua, this, shape: LuaValue| {
            let s = parse_shape(shape)?;
            let result = ops::reshape(&this.inner, &s).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(LuaArray {
                inner: this.inner.clone(),
            })
        });
        methods.add_method("transpose", |lua, this, ()| {
            let result = ops::transpose_2d(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method_mut("fill", |_, this, val: f64| {
            this.inner.fill(val);
            Ok(())
        });
        methods.add_method_mut("addInplace", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            ops::add_inplace(&mut this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("subInplace", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            ops::sub_inplace(&mut this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("mulInplace", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            ops::mul_inplace(&mut this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("divInplace", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            ops::div_inplace(&mut this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        dispatch_arith!(
            methods,
            "add",
            "Element-wise add.",
            ops::add,
            ops::add_scalar
        );
        dispatch_arith!(
            methods,
            "sub",
            "Element-wise sub.",
            ops::sub,
            ops::sub_scalar
        );
        dispatch_arith!(
            methods,
            "mul",
            "Element-wise mul.",
            ops::mul,
            ops::mul_scalar
        );
        dispatch_arith!(
            methods,
            "div",
            "Element-wise div.",
            ops::div,
            ops::div_scalar
        );
        methods.add_method("pow", |lua, this, exp: f64| {
            let result = ops::pow_scalar(&this.inner, exp).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("sqrt", |lua, this, ()| {
            let result = ops::sqrt(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("abs", |lua, this, ()| {
            let result = ops::abs(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("neg", |lua, this, ()| {
            let result = ops::neg(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("clamp", |lua, this, (min, max): (f64, f64)| {
            let result = ops::clamp(&this.inner, min, max).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        dispatch_arith!(methods, "eq", "Element-wise eq.", ops::eq, ops::eq_scalar);
        dispatch_arith!(
            methods,
            "neq",
            "Element-wise neq.",
            ops::neq,
            ops::neq_scalar
        );
        dispatch_arith!(methods, "gt", "Element-wise gt.", ops::gt, ops::gt_scalar);
        dispatch_arith!(methods, "lt", "Element-wise lt.", ops::lt, ops::lt_scalar);
        dispatch_arith!(
            methods,
            "gte",
            "Element-wise gte.",
            ops::gte,
            ops::gte_scalar
        );
        dispatch_arith!(
            methods,
            "lte",
            "Element-wise lte.",
            ops::lte,
            ops::lte_scalar
        );
        methods.add_method("threshold", |lua, this, val: f64| {
            let result = ops::threshold(&this.inner, val).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method(
            "where",
            |lua, this, (mask, other): (LuaAnyUserData, LuaAnyUserData)| {
                let mask_arr = mask.borrow::<LuaArray>()?;
                let other_arr = other.borrow::<LuaArray>()?;
                let result = ops::where_mask(&mask_arr.inner, &this.inner, &other_arr.inner)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: result })
            },
        );
        methods.add_method("countNonZero", |_, this, ()| {
            Ok(ops::count_nonzero(&this.inner))
        });
        methods.add_method("argmin", |_, this, ()| Ok(ops::argmin(&this.inner) + 1));
        methods.add_method("argmax", |_, this, ()| Ok(ops::argmax(&this.inner) + 1));
        methods.add_method("any", |_, this, ()| Ok(ops::any(&this.inner)));
        methods.add_method("all", |_, this, ()| Ok(ops::all(&this.inner)));
        methods.add_method("sum", |lua, this, axis: Option<i64>| match axis {
            None => Ok(LuaValue::Number(ops::sum(&this.inner))),
            Some(a) => {
                let arr =
                    ops::sum_axis(&this.inner, (a - 1) as usize).map_err(LuaError::RuntimeError)?;
                Ok(LuaValue::UserData(
                    lua.create_userdata(LuaArray { inner: arr })?,
                ))
            }
        });
        methods.add_method("mean", |lua, this, axis: Option<i64>| match axis {
            None => Ok(LuaValue::Number(ops::mean(&this.inner))),
            Some(a) => {
                let arr = ops::mean_axis(&this.inner, (a - 1) as usize)
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaValue::UserData(
                    lua.create_userdata(LuaArray { inner: arr })?,
                ))
            }
        });
        methods.add_method("min", |lua, this, axis: Option<i64>| match axis {
            None => Ok(LuaValue::Number(ops::min_val(&this.inner))),
            Some(a) => {
                let arr =
                    ops::min_axis(&this.inner, (a - 1) as usize).map_err(LuaError::RuntimeError)?;
                Ok(LuaValue::UserData(
                    lua.create_userdata(LuaArray { inner: arr })?,
                ))
            }
        });
        methods.add_method("max", |lua, this, axis: Option<i64>| match axis {
            None => Ok(LuaValue::Number(ops::max_val(&this.inner))),
            Some(a) => {
                let arr =
                    ops::max_axis(&this.inner, (a - 1) as usize).map_err(LuaError::RuntimeError)?;
                Ok(LuaValue::UserData(
                    lua.create_userdata(LuaArray { inner: arr })?,
                ))
            }
        });
        methods.add_method("matmul", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                spatial::matmul(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            spatial::dot(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        methods.add_method("bitwiseAnd", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                ops::bitwise_and(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("bitwiseOr", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                ops::bitwise_or(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("bitwiseXor", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                ops::bitwise_xor(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("bitwiseNot", |lua, this, ()| {
            let result = ops::bitwise_not(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("bitwiseLShift", |lua, this, amount: u32| {
            let result =
                ops::bitwise_lshift(&this.inner, amount).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("bitwiseRShift", |lua, this, amount: u32| {
            let result =
                ops::bitwise_rshift(&this.inner, amount).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("convolve2D", |lua, this, kernel: LuaAnyUserData| {
            let kernel_arr = kernel.borrow::<LuaArray>()?;
            let result = spatial::convolve2d(&this.inner, &kernel_arr.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("dilate", |lua, this, radius: usize| {
            let result = spatial::dilate(&this.inner, radius).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method("erode", |lua, this, radius: usize| {
            let result = spatial::erode(&this.inner, radius).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        methods.add_method(
            "floodFill",
            |lua, this, (row, col, val): (usize, usize, f64)| {
                let result = spatial::flood_fill(&this.inner, row - 1, col - 1, val)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: result })
            },
        );
        methods.add_method(
            "getRegion",
            |lua, this, (row, col, rows, cols): (usize, usize, usize, usize)| {
                let result = spatial::get_region(&this.inner, row - 1, col - 1, rows, cols)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: result })
            },
        );
        methods.add_method_mut(
            "setRegion",
            |_, this, (row, col, source): (usize, usize, LuaAnyUserData)| {
                let src = source.borrow::<LuaArray>()?;
                spatial::set_region(&mut this.inner, row - 1, col - 1, &src.inner)
                    .map_err(LuaError::RuntimeError)?;
                Ok(())
            },
        );
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(this.inner.display_string())
        });
        methods.add_method("cumsum", |lua, this, ()| {
            let r = analytics::cumsum(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method("diff", |lua, this, order: Option<usize>| {
            let r =
                analytics::diff(&this.inner, order.unwrap_or(1)).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method(
            "histogram",
            |lua, this, (bins, lo, hi): (usize, Option<f64>, Option<f64>)| {
                let bins_data = analytics::histogram(&this.inner, bins, lo, hi)
                    .map_err(LuaError::RuntimeError)?;
                let out = lua.create_table()?;
                for (i, (bin_lo, bin_hi, count)) in bins_data.iter().enumerate() {
                    let entry = lua.create_table()?;
                    entry.set("lo", *bin_lo)?;
                    entry.set("hi", *bin_hi)?;
                    entry.set("count", *count)?;
                    out.set(i + 1, entry)?;
                }
                Ok(out)
            },
        );
        methods.add_method("percentile", |_, this, p: f64| {
            analytics::percentile(&this.inner, p).map_err(LuaError::RuntimeError)
        });
        methods.add_method("covariance", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            analytics::covariance(&this.inner, &other.inner).map_err(LuaError::RuntimeError)
        });
        methods.add_method("pearsonCorr", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            analytics::pearson_corr(&this.inner, &other.inner).map_err(LuaError::RuntimeError)
        });
        methods.add_method("normalizeRange", |lua, this, (lo, hi): (f64, f64)| {
            let r =
                analytics::normalize_range(&this.inner, lo, hi).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method("zscore", |lua, this, ()| {
            let r = analytics::zscore(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method("convolve1d", |lua, this, kernel: LuaAnyUserData| {
            let kernel = kernel.borrow::<LuaArray>()?;
            let r = analytics::convolve1d(&this.inner, &kernel.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method("correlate1d", |lua, this, template: LuaAnyUserData| {
            let template = template.borrow::<LuaArray>()?;
            let r = analytics::correlate1d(&this.inner, &template.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method("normalizeVec", |lua, this, ()| {
            let r = linalg::normalize_vec(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method("outer", |lua, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            let r = linalg::outer(&this.inner, &other.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method("cross2d", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            linalg::cross2d(&this.inner, &other.inner).map_err(LuaError::RuntimeError)
        });
        methods.add_method("transformPoints", |lua, this, pts: LuaAnyUserData| {
            let pts = pts.borrow::<LuaArray>()?;
            let r = linalg::transform_points(&this.inner, &pts.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method("sobel", |lua, this, ()| {
            let (gx, gy) = linalg::sobel(&this.inner).map_err(LuaError::RuntimeError)?;
            let t = lua.create_table()?;
            t.set("gx", lua.create_userdata(LuaArray { inner: gx })?)?;
            t.set("gy", lua.create_userdata(LuaArray { inner: gy })?)?;
            Ok(t)
        });
        methods.add_method("linsolve", |lua, this, b: LuaAnyUserData| {
            let b = b.borrow::<LuaArray>()?;
            let r = linalg::linsolve(&this.inner, &b.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        methods.add_method("luDecompose", |lua, this, ()| {
            let decomp = crate::compute::linalg::lu_decompose(&this.inner)
                .map_err(LuaError::RuntimeError)?;
            let result = lua.create_table()?;
            result.set("n", decomp.n as i64)?;
            result.set("det_sign", decomp.det_sign as i64)?;
            let perm_tbl = lua.create_table()?;
            for (i, &p) in decomp.perm.iter().enumerate() {
                perm_tbl.set(i + 1, p as i64 + 1)?;
            }
            result.set("perm", perm_tbl)?;
            let lu_tbl = lua.create_table()?;
            for (i, &v) in decomp.lu_data.iter().enumerate() {
                lu_tbl.set(i + 1, v)?;
            }
            result.set("lu_data", lu_tbl)?;
            Ok(result)
        });
        methods.add_method(
            "eigenPower",
            |lua, this, (max_iter, tol): (Option<u32>, Option<f64>)| {
                let (eigenvalue, vec) = crate::compute::linalg::eigenvalue_power(
                    &this.inner,
                    max_iter.unwrap_or(0),
                    tol.unwrap_or(0.0),
                )
                .map_err(LuaError::RuntimeError)?;
                let result = lua.create_table()?;
                result.set("value", eigenvalue)?;
                let v_tbl = lua.create_table()?;
                for (i, &x) in vec.iter().enumerate() {
                    v_tbl.set(i + 1, x)?;
                }
                result.set("vector", v_tbl)?;
                Ok(result)
            },
        );
        methods.add_method("map", |_lua, this, func: LuaFunction| {
            let src = &this.inner;
            let n = src.size();
            let mut out =
                NdArray::zeros(src.shape(), src.dtype()).map_err(LuaError::RuntimeError)?;
            for i in 0..n {
                let v = src.get_f64(i);
                let result: f64 = func.call(v)?;
                out.set_f64(i, result);
            }
            Ok(LuaArray { inner: out })
        });
        methods.add_method("eval", |lua, this, expr: String| {
            let src_code = format!("return function(x) return {} end", expr);
            let func: LuaFunction = lua.load(&src_code).eval()?;
            let src = &this.inner;
            let n = src.size();
            let mut out =
                NdArray::zeros(src.shape(), src.dtype()).map_err(LuaError::RuntimeError)?;
            for i in 0..n {
                let v = src.get_f64(i);
                let result: f64 = func.call(v)?;
                out.set_f64(i, result);
            }
            Ok(LuaArray { inner: out })
        });
        methods.add_method("reduce", |_, this, (func, init): (LuaFunction, f64)| {
            let src = &this.inner;
            let n = src.size();
            let mut acc = init;
            for i in 0..n {
                let v = src.get_f64(i);
                acc = func.call((acc, v))?;
            }
            Ok(acc)
        });
        methods.add_method("scan", |_lua, this, (func, init): (LuaFunction, f64)| {
            let src = &this.inner;
            let n = src.size();
            let mut out =
                NdArray::zeros(src.shape(), src.dtype()).map_err(LuaError::RuntimeError)?;
            let mut acc = init;
            for i in 0..n {
                let v = src.get_f64(i);
                acc = func.call((acc, v))?;
                out.set_f64(i, acc);
            }
            Ok(LuaArray { inner: out })
        });
        methods.add_method("type", |_, _, ()| Ok("LArray"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LArray" || name == "Array" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newArray",
        lua.create_function(|lua, (shape, dtype): (LuaValue, Option<String>)| {
            let s = parse_shape(shape)?;
            let dt = parse_dtype(dtype)?;
            let arr = NdArray::zeros(&s, dt).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: arr })
        })?,
    )?;
    tbl.set(
        "zeros",
        lua.create_function(|lua, (shape, dtype): (LuaValue, Option<String>)| {
            let s = parse_shape(shape)?;
            let dt = parse_dtype(dtype)?;
            let arr = NdArray::zeros(&s, dt).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: arr })
        })?,
    )?;
    tbl.set(
        "ones",
        lua.create_function(|lua, (shape, dtype): (LuaValue, Option<String>)| {
            let s = parse_shape(shape)?;
            let dt = parse_dtype(dtype)?;
            let arr = NdArray::ones(&s, dt).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: arr })
        })?,
    )?;
    tbl.set(
        "range",
        lua.create_function(
            |lua, (start, stop, step, dtype): (f64, f64, Option<f64>, Option<String>)| {
                let st = step.unwrap_or(1.0);
                let dt = parse_dtype(dtype)?;
                let arr = NdArray::range(start, stop, st, dt).map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: arr })
            },
        )?,
    )?;
    tbl.set(
        "fromTable",
        lua.create_function(
            |lua, (data, shape, dtype): (LuaTable, Option<LuaValue>, Option<String>)| {
                let mut values = Vec::new();
                for i in 1..=data.len()? {
                    let v: f64 = data.get(i)?;
                    values.push(v);
                }
                let dt = parse_dtype(dtype)?;
                let s = match shape {
                    Some(sv) => parse_shape(sv)?,
                    None => vec![values.len()],
                };
                let arr = NdArray::from_slice(&values, &s, dt).map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: arr })
            },
        )?,
    )?;
    tbl.set(
        "gaussianKernel",
        lua.create_function(|lua, (size, sigma): (usize, f64)| {
            let k = linalg::gaussian_kernel(size, sigma).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: k })
        })?,
    )?;
    tbl.set(
        "rotate2dMatrix",
        lua.create_function(|lua, angle_rad: f64| {
            let m = linalg::rotate2d_matrix(angle_rad).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: m })
        })?,
    )?;
    tbl.set(
        "affine2d",
        lua.create_function(
            |lua, (tx, ty, angle_rad, sx, sy): (f64, f64, f64, f64, f64)| {
                let m =
                    linalg::affine2d(tx, ty, angle_rad, sx, sy).map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: m })
            },
        )?,
    )?;
    tbl.set(
        "fft",
        lua.create_function(|lua, samples: LuaTable| {
            let data: Vec<f64> = samples.sequence_values::<f64>().flatten().collect();
            let output = crate::compute::fft::fft(&data);
            let t = lua.create_table()?;
            for (i, (re, im)) in output.iter().enumerate() {
                let pair = lua.create_table()?;
                pair.set("re", *re)?;
                pair.set("im", *im)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;
    tbl.set(
        "ifft",
        lua.create_function(|lua, freqs: LuaTable| {
            let pairs: Vec<(f64, f64)> = freqs
                .sequence_values::<LuaTable>()
                .flatten()
                .map(|entry| {
                    let re: f64 = entry.get("re").unwrap_or(0.0);
                    let im: f64 = entry.get("im").unwrap_or(0.0);
                    (re, im)
                })
                .collect();
            let output = crate::compute::fft::ifft(&pairs);
            let t = lua.create_table()?;
            for (i, v) in output.iter().enumerate() {
                t.set(i + 1, *v)?;
            }
            Ok(t)
        })?,
    )?;
    tbl.set(
        "fftMagnitude",
        lua.create_function(|lua, samples: LuaTable| {
            let data: Vec<f64> = samples.sequence_values::<f64>().flatten().collect();
            let mag = crate::compute::fft::fft_magnitude(&data);
            let t = lua.create_table()?;
            for (i, v) in mag.iter().enumerate() {
                t.set(i + 1, *v)?;
            }
            Ok(t)
        })?,
    )?;
    tbl.set(
        "getParThreshold",
        lua.create_function(|_, ()| Ok(crate::compute::get_par_threshold() as i64))?,
    )?;
    tbl.set(
        "setParThreshold",
        lua.create_function(|_, threshold: i64| {
            let new_threshold = (threshold as usize).max(1);
            let prev = crate::compute::set_par_threshold(new_threshold);
            Ok(prev as i64)
        })?,
    )?;
    lurek.set("compute", tbl)?;
    Ok(())
}
