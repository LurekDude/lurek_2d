//! `lurek.compute` â€” Dense N-dimensional numerical arrays with NumPy-style operations.
//!
//! Wraps [`NdArray`] as `Array` userdata supporting element-wise arithmetic, broadcasting,
//! reshape/transpose/slice, reduction (sum, mean, min, max), linear algebra (matmul, dot,
//! norm), spatial queries (nearest, radius search), and statistical analytics.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::compute::analytics;
use crate::compute::array::{DataType, NdArray};
use crate::compute::linalg;
use crate::compute::ops;
use crate::compute::spatial;

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Parse a Lua table of positive integers into a shape vector.
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

/// Parse an optional dtype string, defaulting to `"float32"`.
fn parse_dtype(s: Option<String>) -> LuaResult<DataType> {
    let name = s.as_deref().unwrap_or("float32");
    DataType::parse(name).map_err(LuaError::RuntimeError)
}

/// Parse Lua multi-value arguments into 0-based indices.
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

/// Dispatch pattern for arithmetic/comparison ops that accept Array or number.
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

// -------------------------------------------------------------------------------
// LuaArray UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around [`NdArray`].
pub struct LuaArray {
    inner: NdArray,
}

impl LuaUserData for LuaArray {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getShape --
        /// Returns the shape as a table of dimension sizes.
        /// @return table
        methods.add_method("getShape", |lua, this, ()| {
            let table = lua.create_table()?;
            for (i, &dim) in this.inner.shape().iter().enumerate() {
                table.set(i + 1, dim)?;
            }
            Ok(table)
        });

        // -- getDimensions --
        /// Returns the number of dimensions.
        /// @return integer
        methods.add_method("getDimensions", |_, this, ()| Ok(this.inner.ndim()));

        // -- getSize --
        /// Returns the total number of elements.
        /// @return integer
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.size()));

        // -- getDataType --
        /// Returns the element data type name.
        /// @return string
        methods.add_method("getDataType", |_, this, ()| {
            Ok(this.inner.dtype().name().to_string())
        });

        // -- isOnGPU --
        /// Returns false (CPU arrays only).
        /// @return boolean
        methods.add_method("isOnGPU", |_, _this, ()| Ok(false));

        // -- get --
        /// Returns the element at the given 1-based indices.
        /// @param indices : integer...
        /// @return number
        methods.add_method("get", |_, this, args: LuaMultiValue| {
            let indices = parse_lua_indices(&args.into_vec())?;
            this.inner
                .get_by_indices(&indices)
                .map_err(LuaError::RuntimeError)
        });

        // -- set --
        /// Sets the element at the given 1-based indices to a value.
        /// @param indices_and_value : integer..., number
        /// @return nil
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

        // -- toTable --
        /// Returns all elements as a flat table of numbers.
        /// @return table
        methods.add_method("toTable", |lua, this, ()| {
            let values = this.inner.to_f64_vec();
            let table = lua.create_table()?;
            for (i, &v) in values.iter().enumerate() {
                table.set(i + 1, v)?;
            }
            Ok(table)
        });

        // -- reshape --
        /// Returns a new array with the given shape and the same data.
        /// @param shape : table
        /// @return Array
        methods.add_method("reshape", |lua, this, shape: LuaValue| {
            let s = parse_shape(shape)?;
            let result = ops::reshape(&this.inner, &s).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- clone --
        /// Returns a deep copy of this array.
        /// @return Array
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(LuaArray {
                inner: this.inner.clone(),
            })
        });

        // -- transpose --
        /// Returns the transposed 2D array.
        /// @return Array
        methods.add_method("transpose", |lua, this, ()| {
            let result = ops::transpose_2d(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- fill --
        /// Fills all elements with the given value in-place.
        /// @param val : number
        /// @return nil
        methods.add_method_mut("fill", |_, this, val: f64| {
            ops::fill(&mut this.inner, val);
            Ok(())
        });

        // -- add --
        /// Element-wise addition with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(
            methods,
            "add",
            "Element-wise add.",
            ops::add,
            ops::add_scalar
        );

        // -- sub --
        /// Element-wise subtraction with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(
            methods,
            "sub",
            "Element-wise sub.",
            ops::sub,
            ops::sub_scalar
        );

        // -- mul --
        /// Element-wise multiplication with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(
            methods,
            "mul",
            "Element-wise mul.",
            ops::mul,
            ops::mul_scalar
        );

        // -- div --
        /// Element-wise division with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(
            methods,
            "div",
            "Element-wise div.",
            ops::div,
            ops::div_scalar
        );

        // -- pow --
        /// Raises each element to a scalar exponent.
        /// @param exp : number
        /// @return Array
        methods.add_method("pow", |lua, this, exp: f64| {
            let result = ops::pow_scalar(&this.inner, exp).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- sqrt --
        /// Element-wise square root.
        /// @return Array
        methods.add_method("sqrt", |lua, this, ()| {
            let result = ops::sqrt(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- abs --
        /// Element-wise absolute value.
        /// @return Array
        methods.add_method("abs", |lua, this, ()| {
            let result = ops::abs(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- neg --
        /// Returns a new Array with every element negated (multiplied by â’1).
        /// @return Array
        methods.add_method("neg", |lua, this, ()| {
            let result = ops::neg(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- clamp --
        /// Clamps each element to the given range.
        /// @param min : number
        /// @param max : number
        /// @return Array
        methods.add_method("clamp", |lua, this, (min, max): (f64, f64)| {
            let result = ops::clamp(&this.inner, min, max).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- eq --
        /// Element-wise equality with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(methods, "eq", "Element-wise eq.", ops::eq, ops::eq_scalar);

        // -- neq --
        /// Element-wise not-equal with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(
            methods,
            "neq",
            "Element-wise neq.",
            ops::neq,
            ops::neq_scalar
        );

        // -- gt --
        /// Element-wise greater-than with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(methods, "gt", "Element-wise gt.", ops::gt, ops::gt_scalar);

        // -- lt --
        /// Element-wise less-than with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(methods, "lt", "Element-wise lt.", ops::lt, ops::lt_scalar);

        // -- gte --
        /// Element-wise greater-or-equal with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(
            methods,
            "gte",
            "Element-wise gte.",
            ops::gte,
            ops::gte_scalar
        );

        // -- lte --
        /// Element-wise less-or-equal with an Array or scalar.
        /// @param other : Array|number
        /// @return Array
        dispatch_arith!(
            methods,
            "lte",
            "Element-wise lte.",
            ops::lte,
            ops::lte_scalar
        );

        // -- threshold --
        /// Returns a mask array with 1.0 where elements >= val, else 0.0.
        /// @param val : number
        /// @return Array
        methods.add_method("threshold", |lua, this, val: f64| {
            let result = ops::threshold(&this.inner, val).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- where --
        /// Selects elements from this where mask is nonzero, else from other.
        /// @param mask : Array
        /// @param other : Array
        /// @return Array
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

        // -- countNonZero --
        /// Returns the count of nonzero elements.
        /// @return integer
        methods.add_method("countNonZero", |_, this, ()| {
            Ok(ops::count_nonzero(&this.inner))
        });

        // -- argmin --
        /// Returns the 1-based flat index of the minimum element.
        /// @return integer
        methods.add_method("argmin", |_, this, ()| Ok(ops::argmin(&this.inner) + 1));

        // -- argmax --
        /// Returns the 1-based flat index of the maximum element.
        /// @return integer
        methods.add_method("argmax", |_, this, ()| Ok(ops::argmax(&this.inner) + 1));

        // -- any --
        /// Returns true if any element is nonzero.
        /// @return boolean
        methods.add_method("any", |_, this, ()| Ok(ops::any(&this.inner)));

        // -- all --
        /// Returns true if all elements are nonzero.
        /// @return boolean
        methods.add_method("all", |_, this, ()| Ok(ops::all(&this.inner)));

        // -- sum --
        /// Sum of all elements, or along an axis (1-based).
        /// @param axis : integer?
        /// @return nil
        /// number|Array
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

        // -- mean --
        /// Mean of all elements, or along an axis (1-based).
        /// @param axis : integer?
        /// @return nil
        /// number|Array
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

        // -- min --
        /// Minimum of all elements, or along an axis (1-based).
        /// @param axis : integer?
        /// @return nil
        /// number|Array
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

        // -- max --
        /// Maximum of all elements, or along an axis (1-based).
        /// @param axis : integer?
        /// @return nil
        /// number|Array
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

        // -- matmul --
        /// Matrix multiplication of two 2D arrays.
        /// @param other : Array
        /// @return Array
        methods.add_method("matmul", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                spatial::matmul(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- dot --
        /// Dot product of two 1D arrays.
        /// @param other : Array
        /// @return number
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            spatial::dot(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });

        // -- bitwiseAnd --
        /// Bitwise AND of two Int32 arrays.
        /// @param other : Array
        /// @return Array
        methods.add_method("bitwiseAnd", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                ops::bitwise_and(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- bitwiseOr --
        /// Bitwise OR of two Int32 arrays.
        /// @param other : Array
        /// @return Array
        methods.add_method("bitwiseOr", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                ops::bitwise_or(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- bitwiseXor --
        /// Bitwise XOR of two Int32 arrays.
        /// @param other : Array
        /// @return Array
        methods.add_method("bitwiseXor", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                ops::bitwise_xor(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- bitwiseNot --
        /// Bitwise NOT of an Int32 array.
        /// @return Array
        methods.add_method("bitwiseNot", |lua, this, ()| {
            let result = ops::bitwise_not(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- bitwiseLShift --
        /// Bitwise left shift of an Int32 array.
        /// @param amount : integer
        /// @return Array
        methods.add_method("bitwiseLShift", |lua, this, amount: u32| {
            let result =
                ops::bitwise_lshift(&this.inner, amount).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- bitwiseRShift --
        /// Bitwise right shift of an Int32 array.
        /// @param amount : integer
        /// @return Array
        methods.add_method("bitwiseRShift", |lua, this, amount: u32| {
            let result =
                ops::bitwise_rshift(&this.inner, amount).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- convolve2D --
        /// 2D convolution with zero-padding.
        /// @param kernel : Array
        /// @return Array
        methods.add_method("convolve2D", |lua, this, kernel: LuaAnyUserData| {
            let kernel_arr = kernel.borrow::<LuaArray>()?;
            let result = spatial::convolve2d(&this.inner, &kernel_arr.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- dilate --
        /// Morphological dilation with a diamond structuring element.
        /// @param radius : integer
        /// @return Array
        methods.add_method("dilate", |lua, this, radius: usize| {
            let result = spatial::dilate(&this.inner, radius).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- erode --
        /// Morphological erosion with a diamond structuring element.
        /// @param radius : integer
        /// @return Array
        methods.add_method("erode", |lua, this, radius: usize| {
            let result = spatial::erode(&this.inner, radius).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });

        // -- floodFill --
        /// Flood fill from a 1-based (row, col) with a new value.
        /// @param row : integer
        /// @param col : integer
        /// @param val : number
        /// @return Array
        methods.add_method(
            "floodFill",
            |lua, this, (row, col, val): (usize, usize, f64)| {
                let result = spatial::flood_fill(&this.inner, row - 1, col - 1, val)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: result })
            },
        );

        // -- getRegion --
        /// Extracts a rectangular sub-region (1-based row, col).
        /// @param row : integer
        /// @param col : integer
        /// @param rows : integer
        /// @param cols : integer
        /// @return Array
        methods.add_method(
            "getRegion",
            |lua, this, (row, col, rows, cols): (usize, usize, usize, usize)| {
                let result = spatial::get_region(&this.inner, row - 1, col - 1, rows, cols)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: result })
            },
        );

        // -- setRegion --
        /// Copies a source array into this array at the given 1-based position.
        /// @param row : integer
        /// @param col : integer
        /// @param source : Array
        /// @return nil
        methods.add_method_mut(
            "setRegion",
            |_, this, (row, col, source): (usize, usize, LuaAnyUserData)| {
                let src = source.borrow::<LuaArray>()?;
                spatial::set_region(&mut this.inner, row - 1, col - 1, &src.inner)
                    .map_err(LuaError::RuntimeError)?;
                Ok(())
            },
        );

        // -- __tostring --
        /// Returns a human-readable summary string.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(this.inner.display_string())
        });

        // â”€â”€ Analytics â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        // -- cumsum --
        /// Cumulative sum of all elements (flattened).
        /// @return Array
        methods.add_method("cumsum", |lua, this, ()| {
            let r = analytics::cumsum(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // -- diff --
        /// Discrete difference applied `order` times.
        /// @param order : integer?
        /// @return Array
        methods.add_method("diff", |lua, this, order: Option<usize>| {
            let r =
                analytics::diff(&this.inner, order.unwrap_or(1)).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // -- histogram --
        /// Compute a histogram. Returns a table of {lo, hi, count} tables.
        /// @param bins : integer
        /// @param lo : number?
        /// @param hi : number?
        /// @return table
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

        // -- percentile --
        /// Compute the p-th percentile (0â€“100).
        /// @param p : number
        /// @return number
        methods.add_method("percentile", |_, this, p: f64| {
            analytics::percentile(&this.inner, p).map_err(LuaError::RuntimeError)
        });

        // -- covariance --
        /// Population covariance with another 1D array.
        /// @param other : Array
        /// @return number
        methods.add_method("covariance", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            analytics::covariance(&this.inner, &other.inner).map_err(LuaError::RuntimeError)
        });

        // -- pearsonCorr --
        /// Pearson correlation coefficient with another 1D array.
        /// @param other : Array
        /// @return number
        methods.add_method("pearsonCorr", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            analytics::pearson_corr(&this.inner, &other.inner).map_err(LuaError::RuntimeError)
        });

        // -- normalizeRange --
        /// Linearly rescale values to [out_min, out_max].
        /// @param out_min : number
        /// @param out_max : number
        /// @return Array
        methods.add_method("normalizeRange", |lua, this, (lo, hi): (f64, f64)| {
            let r =
                analytics::normalize_range(&this.inner, lo, hi).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // -- zscore --
        /// Standardise values to zero mean and unit variance.
        /// @return Array
        methods.add_method("zscore", |lua, this, ()| {
            let r = analytics::zscore(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // -- convolve1d --
        /// 1D convolution with a kernel array (full output).
        /// @param kernel : Array
        /// @return Array
        methods.add_method("convolve1d", |lua, this, kernel: LuaAnyUserData| {
            let kernel = kernel.borrow::<LuaArray>()?;
            let r = analytics::convolve1d(&this.inner, &kernel.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // -- correlate1d --
        /// 1D cross-correlation with a template array (valid output).
        /// @param template : Array
        /// @return Array
        methods.add_method("correlate1d", |lua, this, template: LuaAnyUserData| {
            let template = template.borrow::<LuaArray>()?;
            let r = analytics::correlate1d(&this.inner, &template.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // â”€â”€ Linear algebra â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        // -- normalizeVec --
        /// L2-normalise a 1D vector.
        /// @return Array
        methods.add_method("normalizeVec", |lua, this, ()| {
            let r = linalg::normalize_vec(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // -- outer --
        /// Outer product of two 1D vectors â†’ 2D array [m, n].
        /// @param other : Array
        /// @return Array
        methods.add_method("outer", |lua, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            let r = linalg::outer(&this.inner, &other.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // -- cross2d --
        /// Signed 2D cross product with another length-2 array.
        /// @param other : Array
        /// @return number
        methods.add_method("cross2d", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            linalg::cross2d(&this.inner, &other.inner).map_err(LuaError::RuntimeError)
        });

        // -- transformPoints --
        /// Apply this 2Ă—2 or 3Ă—3 matrix to an [N,2] points array.
        /// @param points : Array
        /// @return Array
        methods.add_method("transformPoints", |lua, this, pts: LuaAnyUserData| {
            let pts = pts.borrow::<LuaArray>()?;
            let r = linalg::transform_points(&this.inner, &pts.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // -- sobel --
        /// Apply Sobel edge detection to a 2D array. Returns {gx=Array, gy=Array}.
        /// @return table
        methods.add_method("sobel", |lua, this, ()| {
            let (gx, gy) = linalg::sobel(&this.inner).map_err(LuaError::RuntimeError)?;
            let t = lua.create_table()?;
            t.set("gx", lua.create_userdata(LuaArray { inner: gx })?)?;
            t.set("gy", lua.create_userdata(LuaArray { inner: gy })?)?;
            Ok(t)
        });

        // -- linsolve --
        /// Solve AÂ·x = b where this array is A (square [n,n]) and b is a 1D vector.
        /// @param b : Array
        /// @return Array
        methods.add_method("linsolve", |lua, this, b: LuaAnyUserData| {
            let b = b.borrow::<LuaArray>()?;
            let r = linalg::linsolve(&this.inner, &b.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });

        // -- luDecompose --
        /// Decomposes this square matrix into L and U factors with partial pivoting.
        ///
        /// Returns a table `{perm = table, det_sign = int, n = int, lu_data = table}`.
        /// `perm` is a 1-indexed Lua array of row permutation indices.
        /// `lu_data` is a flat 1-indexed array of the combined LU buffer (row-major).
        /// @return table
        methods.add_method("luDecompose", |lua, this, ()| {
            let decomp = crate::compute::linalg::lu_decompose(&this.inner)
                .map_err(LuaError::RuntimeError)?;
            let result = lua.create_table()?;
            result.set("n", decomp.n as i64)?;
            result.set("det_sign", decomp.det_sign as i64)?;
            let perm_tbl = lua.create_table()?;
            for (i, &p) in decomp.perm.iter().enumerate() {
                perm_tbl.set(i + 1, p as i64 + 1)?; // 1-indexed for Lua
            }
            result.set("perm", perm_tbl)?;
            let lu_tbl = lua.create_table()?;
            for (i, &v) in decomp.lu_data.iter().enumerate() {
                lu_tbl.set(i + 1, v)?;
            }
            result.set("lu_data", lu_tbl)?;
            Ok(result)
        });

        // -- eigenPower --
        /// Computes the dominant eigenvalue and its eigenvector using power iteration.
        ///
        /// Returns a table `{value = f64, vector = table}` where `vector` is a
        /// 1-indexed Lua array of the L2-normalised dominant eigenvector.
        ///
        /// @param max_iter : int?   (default 1000)
        /// @param tol      : number? (default 1e-10)
        /// @return table
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

        // ── Lua extensibility hooks ───────────────────────────────────────────────

        // -- map --
        /// Apply a Lua callback element-wise, returning a new Array of the same shape.
        /// @param fn function(value: number) → number — called for each element
        /// @return Array — new array with transformed values
        methods.add_method("map", |lua, this, func: LuaFunction| {
            let src = &this.inner;
            let n = src.size();
            let mut out = NdArray::zeros(src.shape(), src.dtype())
                .map_err(LuaError::RuntimeError)?;
            for i in 0..n {
                let v = src.get_f64(i);
                let result: f64 = func.call(v)?;
                out.set_f64(i, result);
            }
            Ok(LuaArray { inner: out })
        });

        // -- eval --
        /// Evaluate a Lua expression string element-wise, returning a new Array.
        /// The expression receives `x` as the current element value.
        /// Example: `arr:eval("x * x + 1")`
        /// @param expr string — Lua expression using `x` as the input variable
        /// @return Array — new array with transformed values
        methods.add_method("eval", |lua, this, expr: String| {
            let src_code = format!("return function(x) return {} end", expr);
            let func: LuaFunction = lua.load(&src_code).eval()?;
            let src = &this.inner;
            let n = src.size();
            let mut out = NdArray::zeros(src.shape(), src.dtype())
                .map_err(LuaError::RuntimeError)?;
            for i in 0..n {
                let v = src.get_f64(i);
                let result: f64 = func.call(v)?;
                out.set_f64(i, result);
            }
            Ok(LuaArray { inner: out })
        });

        // -- reduce --
        /// Fold the array left-to-right with an accumulator.
        /// @param fn function(acc: number, value: number) → number — accumulator function
        /// @param init number — initial accumulator value
        /// @return number — final accumulated value
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

        // -- scan --
        /// Running accumulation — like reduce but returns every intermediate result.
        /// The output array has the same shape and dtype as the input.
        /// @param fn function(acc: number, value: number) → number — accumulator function
        /// @param init number — initial accumulator value
        /// @return Array — array of cumulative values (same length as input)
        methods.add_method("scan", |lua, this, (func, init): (LuaFunction, f64)| {
            let src = &this.inner;
            let n = src.size();
            let mut out = NdArray::zeros(src.shape(), src.dtype())
                .map_err(LuaError::RuntimeError)?;
            let mut acc = init;
            for i in 0..n {
                let v = src.get_f64(i);
                acc = func.call((acc, v))?;
                out.set_f64(i, acc);
            }
            Ok(LuaArray { inner: out })
        });

        // â”€â”€ Identity â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

        // -- type --
        /// Returns the type name "Array".
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Array"));
        // -- typeOf --
        /// Returns true when the given name matches "Array" or a parent type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Array" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.compute` API table with the Lua VM.
///
/// @param lua : &Lua
/// @param lurek : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newArray --
    /// Creates a zero-initialized array with the given shape and optional dtype.
    /// @param shape : table
    /// @param dtype : string?
    /// @return Array
    tbl.set(
        "newArray",
        lua.create_function(|lua, (shape, dtype): (LuaValue, Option<String>)| {
            let s = parse_shape(shape)?;
            let dt = parse_dtype(dtype)?;
            let arr = NdArray::zeros(&s, dt).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: arr })
        })?,
    )?;

    // -- zeros --
    /// Creates a zero-filled array with the given shape and optional dtype.
    /// @param shape : table
    /// @param dtype : string?
    /// @return Array
    tbl.set(
        "zeros",
        lua.create_function(|lua, (shape, dtype): (LuaValue, Option<String>)| {
            let s = parse_shape(shape)?;
            let dt = parse_dtype(dtype)?;
            let arr = NdArray::zeros(&s, dt).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: arr })
        })?,
    )?;

    // -- ones --
    /// Creates a one-filled array with the given shape and optional dtype.
    /// @param shape : table
    /// @param dtype : string?
    /// @return Array
    tbl.set(
        "ones",
        lua.create_function(|lua, (shape, dtype): (LuaValue, Option<String>)| {
            let s = parse_shape(shape)?;
            let dt = parse_dtype(dtype)?;
            let arr = NdArray::ones(&s, dt).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: arr })
        })?,
    )?;

    // -- range --
    /// Creates a 1D array from start to stop with optional step and dtype.
    /// @param start : number
    /// @param stop : number
    /// @param step : number?
    /// @param dtype : string?
    /// @return Array
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

    // -- fromTable --
    /// Creates an array from a Lua table of numbers with optional shape and dtype.
    /// @param data : table
    /// @param shape : table?
    /// @param dtype : string?
    /// @return Array
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

    // -- gaussianKernel --
    /// Creates a sizeĂ—size Gaussian kernel array.
    /// @param size : integer
    /// @param sigma : number
    /// @return Array
    tbl.set(
        "gaussianKernel",
        lua.create_function(|lua, (size, sigma): (usize, f64)| {
            let k = linalg::gaussian_kernel(size, sigma).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: k })
        })?,
    )?;

    // -- rotate2dMatrix --
    /// Creates a 2Ă—2 rotation matrix for the given angle in radians.
    /// @param angle_rad : number
    /// @return Array
    tbl.set(
        "rotate2dMatrix",
        lua.create_function(|lua, angle_rad: f64| {
            let m = linalg::rotate2d_matrix(angle_rad).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: m })
        })?,
    )?;

    // -- affine2d --
    /// Creates a 3Ă—3 homogeneous affine matrix.
    /// @param tx : number
    /// @param ty : number
    /// @param angle_rad : number
    /// @param sx : number
    /// @param sy : number
    /// @return Array
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

    // -- fft --
    /// Computes the discrete Fourier transform of a 1D real-valued sample array.
    ///
    /// The input is zero-padded to the next power of two. Returns an array of
    /// `{re = number, im = number}` tables â€” one per frequency bin.
    ///
    /// @param samples : table
    /// @return table
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

    // -- ifft --
    /// Computes the inverse discrete Fourier transform.
    ///
    /// Accepts a table of `{re, im}` complex-coefficient tables (as returned by
    /// `lurek.compute.fft`) and returns the reconstructed real-valued time-domain samples.
    ///
    /// @param freqs : table
    /// @return table
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

    // -- fftMagnitude --
    /// Returns the magnitude spectrum `|X[k]|` of a real-valued sample array.
    ///
    /// Equivalent to calling `fft` and computing the L2 norm of each complex
    /// coefficient. Useful for audio-amplitude analysis.
    ///
    /// @param samples : table
    /// @return table
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

    lurek.set("compute", tbl)?;
    Ok(())
}
