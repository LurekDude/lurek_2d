//! `lurek.compute` -- Compute bindings for multidimensional arrays, numeric operations, reductions, spatial filters, analytics, linear algebra, FFT helpers, and parallel threshold tuning.

use super::SharedState;
use crate::compute::analytics;
use crate::compute::array::{DataType, NdArray};
use crate::compute::linalg;
use crate::compute::ops;
use crate::compute::spatial;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
/// Parses a Lua shape table into positive array dimensions.
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
/// Parses an optional Lua dtype name into an array data type.
fn parse_dtype(s: Option<String>) -> LuaResult<DataType> {
    let name = s.as_deref().unwrap_or("float32");
    DataType::parse(name).map_err(LuaError::RuntimeError)
}
/// Converts one-based Lua indices into zero-based array indices.
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
/// Lua-side multidimensional numeric array handle.
pub struct LuaArray {
    /// Owned array data exposed through this userdata handle.
    inner: NdArray,
}
impl LuaUserData for LuaArray {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- getShape --
        /// Returns the array shape as one-based dimension table.
        /// @return | table | Array table of dimension sizes.
        methods.add_method("getShape", |lua, this, ()| {
            let table = lua.create_table()?;
            for (i, &dim) in this.inner.shape().iter().enumerate() {
                table.set(i + 1, dim)?;
            }
            Ok(table)
        });
        // -- getDimensions --
        /// Returns the number of array dimensions.
        /// @return | integer | Dimension count.
        methods.add_method("getDimensions", |_, this, ()| Ok(this.inner.ndim()));
        // -- getSize --
        /// Returns the total number of array elements.
        /// @return | integer | Element count.
        methods.add_method("getSize", |_, this, ()| Ok(this.inner.size()));
        // -- getDataType --
        /// Returns the element data type name as a string.
        /// @return | string | Data type name such as `float32`.
        methods.add_method("getDataType", |_, this, ()| {
            Ok(this.inner.dtype().name().to_string())
        });
        // -- isOnGPU --
        /// Returns whether this array is currently stored on the GPU.
        /// @return | boolean | Always false for the current CPU-backed implementation.
        methods.add_method("isOnGPU", |_, _this, ()| Ok(false));
        // -- get --
        /// Reads an array element using one-based indices.
        /// @param | ... | integer | One-based indices, one per dimension.
        /// @return | number | Element value at the requested index.
        methods.add_method("get", |_, this, args: LuaMultiValue| {
            let indices = parse_lua_indices(&args.into_vec())?;
            this.inner
                .get_by_indices(&indices)
                .map_err(LuaError::RuntimeError)
        });
        // -- set --
        /// Writes an array element using one-based indices followed by the value.
        /// @param | ... | any | One-based indices followed by the numeric value to store.
        /// @return | nil | No value is returned.
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
        /// Returns array values flattened into a Lua table.
        /// @return | table | Array table of numeric values in storage order.
        methods.add_method("toTable", |lua, this, ()| {
            let values = this.inner.to_f64_vec();
            let table = lua.create_table()?;
            for (i, &v) in values.iter().enumerate() {
                table.set(i + 1, v)?;
            }
            Ok(table)
        });
        // -- reshape --
        /// Returns a reshaped copy of this array.
        /// @param | shape | table | Array table of positive dimension sizes.
        /// @return | LArray | New array with the requested shape.
        methods.add_method("reshape", |lua, this, shape: LuaValue| {
            let s = parse_shape(shape)?;
            let result = ops::reshape(&this.inner, &s).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- clone --
        /// Returns an independent deep copy of this array.
        /// @return | LArray | New array with copied data and shape.
        methods.add_method("clone", |lua, this, ()| {
            lua.create_userdata(LuaArray {
                inner: this.inner.clone(),
            })
        });
        // -- transpose --
        /// Returns a transposed copy of a two-dimensional array.
        /// @return | LArray | New transposed array.
        methods.add_method("transpose", |lua, this, ()| {
            let result = ops::transpose_2d(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- fill --
        /// Fills this array in place with one value.
        /// @param | val | number | Value written to every element.
        /// @return | nil | No value is returned.
        methods.add_method_mut("fill", |_, this, val: f64| {
            this.inner.fill(val);
            Ok(())
        });
        // -- addInplace --
        /// Adds another array into this array in place.
        /// @param | other | LArray | Array with a compatible shape.
        /// @return | nil | No value is returned.
        methods.add_method_mut("addInplace", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            ops::add_inplace(&mut this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        // -- subInplace --
        /// Subtracts another array from this array in place.
        /// @param | other | LArray | Array with a compatible shape.
        /// @return | nil | No value is returned.
        methods.add_method_mut("subInplace", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            ops::sub_inplace(&mut this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        // -- mulInplace --
        /// Multiplies this array by another array in place.
        /// @param | other | LArray | Array with a compatible shape.
        /// @return | nil | No value is returned.
        methods.add_method_mut("mulInplace", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            ops::mul_inplace(&mut this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        // -- divInplace --
        /// Divides this array by another array in place.
        /// @param | other | LArray | Array with a compatible shape.
        /// @return | nil | No value is returned.
        methods.add_method_mut("divInplace", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            ops::div_inplace(&mut this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        // -- add --
        /// Returns element-wise addition with an array or scalar.
        /// @param | value | any | LArray or number used as the addend.
        /// @return | LArray | New array containing the addition result.
        dispatch_arith!(
            methods,
            "add",
            "Element-wise add.",
            ops::add,
            ops::add_scalar
        );
        // -- sub --
        /// Returns element-wise subtraction with an array or scalar.
        /// @param | value | any | LArray or number used as the subtrahend.
        /// @return | LArray | New array containing the subtraction result.
        dispatch_arith!(
            methods,
            "sub",
            "Element-wise sub.",
            ops::sub,
            ops::sub_scalar
        );
        // -- mul --
        /// Returns element-wise multiplication with an array or scalar.
        /// @param | value | any | LArray or number used as the multiplier.
        /// @return | LArray | New array containing the multiplication result.
        dispatch_arith!(
            methods,
            "mul",
            "Element-wise mul.",
            ops::mul,
            ops::mul_scalar
        );
        // -- div --
        /// Returns element-wise division with an array or scalar.
        /// @param | value | any | LArray or number used as the divisor.
        /// @return | LArray | New array containing the division result.
        dispatch_arith!(
            methods,
            "div",
            "Element-wise div.",
            ops::div,
            ops::div_scalar
        );
        // -- pow --
        /// Returns this array raised element-wise to a scalar exponent.
        /// @param | exp | number | Exponent applied to every element.
        /// @return | LArray | New array containing powered values.
        methods.add_method("pow", |lua, this, exp: f64| {
            let result = ops::pow_scalar(&this.inner, exp).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- sqrt --
        /// Returns element-wise square roots.
        /// @return | LArray | New array containing square root values.
        methods.add_method("sqrt", |lua, this, ()| {
            let result = ops::sqrt(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- abs --
        /// Returns element-wise absolute values.
        /// @return | LArray | New array containing absolute values.
        methods.add_method("abs", |lua, this, ()| {
            let result = ops::abs(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- neg --
        /// Returns element-wise negated values.
        /// @return | LArray | New array containing negated values.
        methods.add_method("neg", |lua, this, ()| {
            let result = ops::neg(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- clamp --
        /// Returns values clamped between minimum and maximum bounds.
        /// @param | min | number | Minimum allowed value.
        /// @param | max | number | Maximum allowed value.
        /// @return | LArray | New array containing clamped values.
        methods.add_method("clamp", |lua, this, (min, max): (f64, f64)| {
            let result = ops::clamp(&this.inner, min, max).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- eq --
        /// Returns element-wise equality comparison with an array or scalar.
        /// @param | value | any | LArray or number used for comparison.
        /// @return | LArray | New mask array containing comparison results.
        dispatch_arith!(methods, "eq", "Element-wise eq.", ops::eq, ops::eq_scalar);
        // -- neq --
        /// Returns element-wise inequality comparison with an array or scalar.
        /// @param | value | any | LArray or number used for comparison.
        /// @return | LArray | New mask array containing comparison results.
        dispatch_arith!(
            methods,
            "neq",
            "Element-wise neq.",
            ops::neq,
            ops::neq_scalar
        );
        // -- gt --
        /// Returns element-wise greater-than comparison with an array or scalar.
        /// @param | value | any | LArray or number used for comparison.
        /// @return | LArray | New mask array containing comparison results.
        dispatch_arith!(methods, "gt", "Element-wise gt.", ops::gt, ops::gt_scalar);
        // -- lt --
        /// Returns element-wise less-than comparison with an array or scalar.
        /// @param | value | any | LArray or number used for comparison.
        /// @return | LArray | New mask array containing comparison results.
        dispatch_arith!(methods, "lt", "Element-wise lt.", ops::lt, ops::lt_scalar);
        // -- gte --
        /// Returns element-wise greater-or-equal comparison with an array or scalar.
        /// @param | value | any | LArray or number used for comparison.
        /// @return | LArray | New mask array containing comparison results.
        dispatch_arith!(
            methods,
            "gte",
            "Element-wise gte.",
            ops::gte,
            ops::gte_scalar
        );
        // -- lte --
        /// Returns element-wise less-or-equal comparison with an array or scalar.
        /// @param | value | any | LArray or number used for comparison.
        /// @return | LArray | New mask array containing comparison results.
        dispatch_arith!(
            methods,
            "lte",
            "Element-wise lte.",
            ops::lte,
            ops::lte_scalar
        );
        // -- threshold --
        /// Returns a mask array where values above a threshold are selected.
        /// @param | val | number | Threshold value.
        /// @return | LArray | New mask array containing threshold results.
        methods.add_method("threshold", |lua, this, val: f64| {
            let result = ops::threshold(&this.inner, val).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- where --
        /// Selects values from this array or another array using a mask array.
        /// @param | mask | LArray | Mask array used to choose between arrays.
        /// @param | other | LArray | Array used where the mask is false.
        /// @return | LArray | New array containing selected values.
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
        /// Counts the number of non-zero elements in this array.
        /// @return | integer | Number of non-zero elements.
        methods.add_method("countNonZero", |_, this, ()| {
            Ok(ops::count_nonzero(&this.inner))
        });
        // -- argmin --
        /// Returns the one-based flat index of the minimum value.
        /// @return | integer | One-based index of the minimum element.
        methods.add_method("argmin", |_, this, ()| Ok(ops::argmin(&this.inner) + 1));
        // -- argmax --
        /// Returns the one-based flat index of the maximum value.
        /// @return | integer | One-based index of the maximum element.
        methods.add_method("argmax", |_, this, ()| Ok(ops::argmax(&this.inner) + 1));
        // -- any --
        /// Returns whether any element is non-zero.
        /// @return | boolean | True when at least one element is non-zero.
        methods.add_method("any", |_, this, ()| Ok(ops::any(&this.inner)));
        // -- all --
        /// Returns whether all elements are non-zero.
        /// @return | boolean | True when every element is non-zero.
        methods.add_method("all", |_, this, ()| Ok(ops::all(&this.inner)));
        // -- sum --
        /// Returns total sum or a summed array along a one-based axis.
        /// @param | axis | integer? | Optional one-based axis to reduce.
        /// @return | number|LArray | Scalar sum when no axis given, or reduced array along the axis.
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
        /// Returns total mean or a mean array along a one-based axis.
        /// @param | axis | integer? | Optional one-based axis to reduce.
        /// @return | number|LArray | Scalar mean when no axis given, or reduced array along the axis.
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
        /// Returns total minimum or a minimum array along a one-based axis.
        /// @param | axis | integer? | Optional one-based axis to reduce.
        /// @return | number|LArray | Scalar minimum when no axis given, or reduced array along the axis.
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
        /// Returns total maximum or a maximum array along a one-based axis.
        /// @param | axis | integer? | Optional one-based axis to reduce.
        /// @return | number|LArray | Scalar maximum when no axis given, or reduced array along the axis.
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
        /// Returns matrix multiplication of this array and another array.
        /// @param | other | LArray | Right-hand matrix array.
        /// @return | LArray | New array containing matrix multiplication result.
        methods.add_method("matmul", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                spatial::matmul(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- dot --
        /// Returns dot product with another array.
        /// @param | other | LArray | Array used as the right-hand operand.
        /// @return | number | Dot product result.
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            spatial::dot(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)
        });
        // -- bitwiseAnd --
        /// Returns element-wise bitwise AND with another array.
        /// @param | other | LArray | Array used as the right-hand operand.
        /// @return | LArray | New array containing bitwise AND results.
        methods.add_method("bitwiseAnd", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                ops::bitwise_and(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- bitwiseOr --
        /// Returns element-wise bitwise OR with another array.
        /// @param | other | LArray | Array used as the right-hand operand.
        /// @return | LArray | New array containing bitwise OR results.
        methods.add_method("bitwiseOr", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                ops::bitwise_or(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- bitwiseXor --
        /// Returns element-wise bitwise XOR with another array.
        /// @param | other | LArray | Array used as the right-hand operand.
        /// @return | LArray | New array containing bitwise XOR results.
        methods.add_method("bitwiseXor", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<LuaArray>()?;
            let result =
                ops::bitwise_xor(&this.inner, &other_arr.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- bitwiseNot --
        /// Returns element-wise bitwise NOT.
        /// @return | LArray | New array containing bitwise NOT results.
        methods.add_method("bitwiseNot", |lua, this, ()| {
            let result = ops::bitwise_not(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- bitwiseLShift --
        /// Returns element-wise left shift by a bit count.
        /// @param | amount | integer | Bit count to shift left.
        /// @return | LArray | New array containing shifted values.
        methods.add_method("bitwiseLShift", |lua, this, amount: u32| {
            let result =
                ops::bitwise_lshift(&this.inner, amount).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- bitwiseRShift --
        /// Returns element-wise right shift by a bit count.
        /// @param | amount | integer | Bit count to shift right.
        /// @return | LArray | New array containing shifted values.
        methods.add_method("bitwiseRShift", |lua, this, amount: u32| {
            let result =
                ops::bitwise_rshift(&this.inner, amount).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- convolve2D --
        /// Returns two-dimensional convolution with a kernel array.
        /// @param | kernel | LArray | Kernel array used for convolution.
        /// @return | LArray | New array containing convolution result.
        methods.add_method("convolve2D", |lua, this, kernel: LuaAnyUserData| {
            let kernel_arr = kernel.borrow::<LuaArray>()?;
            let result = spatial::convolve2d(&this.inner, &kernel_arr.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- dilate --
        /// Returns morphological dilation with a radius.
        /// @param | radius | integer | Dilation radius in cells.
        /// @return | LArray | New array containing dilation result.
        methods.add_method("dilate", |lua, this, radius: usize| {
            let result = spatial::dilate(&this.inner, radius).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- erode --
        /// Returns morphological erosion with a radius.
        /// @param | radius | integer | Erosion radius in cells.
        /// @return | LArray | New array containing erosion result.
        methods.add_method("erode", |lua, this, radius: usize| {
            let result = spatial::erode(&this.inner, radius).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: result })
        });
        // -- floodFill --
        /// Returns a flood-filled copy starting at a one-based row and column.
        /// @param | row | integer | One-based start row.
        /// @param | col | integer | One-based start column.
        /// @param | val | number | Replacement value.
        /// @return | LArray | New array containing flood-fill result.
        methods.add_method(
            "floodFill",
            |lua, this, (row, col, val): (usize, usize, f64)| {
                let result = spatial::flood_fill(&this.inner, row - 1, col - 1, val)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: result })
            },
        );
        // -- getRegion --
        /// Returns a rectangular region from this array.
        /// @param | row | integer | One-based start row.
        /// @param | col | integer | One-based start column.
        /// @param | rows | integer | Region row count.
        /// @param | cols | integer | Region column count.
        /// @return | LArray | New array containing the requested region.
        methods.add_method(
            "getRegion",
            |lua, this, (row, col, rows, cols): (usize, usize, usize, usize)| {
                let result = spatial::get_region(&this.inner, row - 1, col - 1, rows, cols)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaArray { inner: result })
            },
        );
        // -- setRegion --
        /// Writes a source array into this array at a one-based row and column.
        /// @param | row | integer | One-based destination row.
        /// @param | col | integer | One-based destination column.
        /// @param | source | LArray | Source array copied into this array.
        /// @return | nil | No value is returned.
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
        // -- cumsum --
        /// Returns cumulative sum over the flattened array.
        /// @return | LArray | New array containing cumulative sums.
        methods.add_method("cumsum", |lua, this, ()| {
            let r = analytics::cumsum(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- diff --
        /// Returns finite differences over the flattened array.
        /// @param | order | integer? | Difference order; defaults to 1.
        /// @return | LArray | New array containing differences.
        methods.add_method("diff", |lua, this, order: Option<usize>| {
            let r =
                analytics::diff(&this.inner, order.unwrap_or(1)).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- histogram --
        /// Returns histogram bins for the array values.
        /// @param | bins | integer | Number of histogram bins.
        /// @param | lo | number? | Optional lower bound.
        /// @param | hi | number? | Optional upper bound.
        /// @return | table | Array of bin tables with `lo`, `hi`, and `count` fields.
        methods.add_method(
            "histogram",
            |lua, this, (bins, lo, hi): (usize, Option<f64>, Option<f64>)| {
                let bins_data = analytics::histogram(&this.inner, bins, lo, hi)
                    .map_err(LuaError::RuntimeError)?;
                let out = lua.create_table()?;
                for (i, (bin_lo, bin_hi, count)) in bins_data.iter().enumerate() {
                    let entry = lua.create_table()?;
                    /// Performs the 'lo' operation.
                    /// @return | nil | No value is returned.
                    entry.set("lo", *bin_lo)?;
                    /// Performs the 'hi' operation.
                    /// @return | nil | No value is returned.
                    entry.set("hi", *bin_hi)?;
                    /// Performs the 'count' operation.
                    /// @return | nil | No value is returned.
                    entry.set("count", *count)?;
                    out.set(i + 1, entry)?;
                }
                Ok(out)
            },
        );
        // -- percentile --
        /// Returns a percentile value from the array.
        /// @param | p | number | Percentile between 0 and 100.
        /// @return | number | Percentile result.
        methods.add_method("percentile", |_, this, p: f64| {
            analytics::percentile(&this.inner, p).map_err(LuaError::RuntimeError)
        });
        // -- covariance --
        /// Returns covariance with another array.
        /// @param | other | LArray | Array used as the second variable.
        /// @return | number | Covariance value.
        methods.add_method("covariance", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            analytics::covariance(&this.inner, &other.inner).map_err(LuaError::RuntimeError)
        });
        // -- pearsonCorr --
        /// Returns Pearson correlation with another array.
        /// @param | other | LArray | Array used as the second variable.
        /// @return | number | Pearson correlation coefficient.
        methods.add_method("pearsonCorr", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            analytics::pearson_corr(&this.inner, &other.inner).map_err(LuaError::RuntimeError)
        });
        // -- normalizeRange --
        /// Returns array values normalized into a target range.
        /// @param | lo | number | Target lower bound.
        /// @param | hi | number | Target upper bound.
        /// @return | LArray | New normalized array.
        methods.add_method("normalizeRange", |lua, this, (lo, hi): (f64, f64)| {
            let r =
                analytics::normalize_range(&this.inner, lo, hi).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- zscore --
        /// Returns z-score normalized array values.
        /// @return | LArray | New z-score normalized array.
        methods.add_method("zscore", |lua, this, ()| {
            let r = analytics::zscore(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- convolve1d --
        /// Returns one-dimensional convolution with a kernel array.
        /// @param | kernel | LArray | Kernel array used for convolution.
        /// @return | LArray | New array containing convolution result.
        methods.add_method("convolve1d", |lua, this, kernel: LuaAnyUserData| {
            let kernel = kernel.borrow::<LuaArray>()?;
            let r = analytics::convolve1d(&this.inner, &kernel.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- correlate1d --
        /// Returns one-dimensional correlation with a template array.
        /// @param | template | LArray | Template array used for correlation.
        /// @return | LArray | New array containing correlation result.
        methods.add_method("correlate1d", |lua, this, template: LuaAnyUserData| {
            let template = template.borrow::<LuaArray>()?;
            let r = analytics::correlate1d(&this.inner, &template.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- normalizeVec --
        /// Returns this vector normalized to unit length.
        /// @return | LArray | New normalized vector array.
        methods.add_method("normalizeVec", |lua, this, ()| {
            let r = linalg::normalize_vec(&this.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- outer --
        /// Returns outer product with another vector array.
        /// @param | other | LArray | Vector array used as the second operand.
        /// @return | LArray | New array containing outer product result.
        methods.add_method("outer", |lua, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            let r = linalg::outer(&this.inner, &other.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- cross2d --
        /// Returns two-dimensional cross product with another vector.
        /// @param | other | LArray | Vector array used as the second operand.
        /// @return | number | Scalar 2D cross product result.
        methods.add_method("cross2d", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<LuaArray>()?;
            linalg::cross2d(&this.inner, &other.inner).map_err(LuaError::RuntimeError)
        });
        // -- transformPoints --
        /// Transforms a point array by this transform matrix.
        /// @param | pts | LArray | Point array to transform.
        /// @return | LArray | New array containing transformed points.
        methods.add_method("transformPoints", |lua, this, pts: LuaAnyUserData| {
            let pts = pts.borrow::<LuaArray>()?;
            let r = linalg::transform_points(&this.inner, &pts.inner)
                .map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- sobel --
        /// Computes Sobel gradients for this array.
        /// @return | table | Table with `gx` and `gy` gradient arrays.
        methods.add_method("sobel", |lua, this, ()| {
            let (gx, gy) = linalg::sobel(&this.inner).map_err(LuaError::RuntimeError)?;
            let t = lua.create_table()?;
            /// Performs the 'gx' operation.
            /// @return | nil | No value is returned.
            t.set("gx", lua.create_userdata(LuaArray { inner: gx })?)?;
            /// Performs the 'gy' operation.
            /// @return | nil | No value is returned.
            t.set("gy", lua.create_userdata(LuaArray { inner: gy })?)?;
            Ok(t)
        });
        // -- linsolve --
        /// Solves a linear system using this matrix and a right-hand side array.
        /// @param | b | LArray | Right-hand side array.
        /// @return | LArray | Solution array.
        methods.add_method("linsolve", |lua, this, b: LuaAnyUserData| {
            let b = b.borrow::<LuaArray>()?;
            let r = linalg::linsolve(&this.inner, &b.inner).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: r })
        });
        // -- luDecompose --
        /// Decomposes this matrix into LU data and permutation metadata.
        /// @return | table | Table containing `n`, `det_sign`, `perm`, and `lu_data` fields.
        methods.add_method("luDecompose", |lua, this, ()| {
            let decomp = crate::compute::linalg::lu_decompose(&this.inner)
                .map_err(LuaError::RuntimeError)?;
            let result = lua.create_table()?;
            /// Performs the 'n' operation.
            /// @return | nil | No value is returned.
            result.set("n", decomp.n as i64)?;
            /// Performs the 'det_sign' operation.
            /// @return | nil | No value is returned.
            result.set("det_sign", decomp.det_sign as i64)?;
            let perm_tbl = lua.create_table()?;
            for (i, &p) in decomp.perm.iter().enumerate() {
                perm_tbl.set(i + 1, p as i64 + 1)?;
            }
            /// Performs the 'perm' operation.
            /// @return | nil | No value is returned.
            result.set("perm", perm_tbl)?;
            let lu_tbl = lua.create_table()?;
            for (i, &v) in decomp.lu_data.iter().enumerate() {
                lu_tbl.set(i + 1, v)?;
            }
            /// Performs the 'lu_data' operation.
            /// @return | nil | No value is returned.
            result.set("lu_data", lu_tbl)?;
            Ok(result)
        });
        // -- eigenPower --
        /// Estimates dominant eigenvalue and eigenvector using power iteration.
        /// @param | max_iter | integer? | Maximum iteration count; zero uses the engine default.
        /// @param | tol | number? | Convergence tolerance; zero uses the engine default.
        /// @return | table | Table containing `value` and `vector` fields.
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
                /// Performs the 'value' operation.
                /// @return | nil | No value is returned.
                result.set("value", eigenvalue)?;
                let v_tbl = lua.create_table()?;
                for (i, &x) in vec.iter().enumerate() {
                    v_tbl.set(i + 1, x)?;
                }
                /// Performs the 'vector' operation.
                /// @return | nil | No value is returned.
                result.set("vector", v_tbl)?;
                Ok(result)
            },
        );
        // -- map --
        /// Maps each element through a Lua function and returns a new array.
        /// @param | func | function | Function called with each element value and returning a number.
        /// @return | LArray | New array containing mapped values.
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
        // -- eval --
        /// Maps each element through a Lua expression compiled as `function(x) return expression end`.
        /// @param | expr | string | Lua expression that can read the current element as `x`.
        /// @return | LArray | New array containing expression results.
        methods.add_method("eval", |lua, this, expr: String| {
            let src_code = format!("return function(x) return {} end", expr);
            // LUA-EVAL-JUSTIFIED: compute.Array:eval compiles a user expression into a per-element mapper.
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
        // -- reduce --
        /// Reduces array values with a Lua accumulator function.
        /// @param | func | function | Function called as `(accumulator, value)` and returning the next accumulator.
        /// @param | init | number | Initial accumulator value.
        /// @return | number | Final accumulator value.
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
        /// Produces prefix accumulator values with a Lua function.
        /// @param | func | function | Function called as `(accumulator, value)` and returning the next accumulator.
        /// @param | init | number | Initial accumulator value.
        /// @return | LArray | New array containing accumulator values.
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
        // -- type --
        /// Returns the Lua-visible type name for this array handle.
        /// @return | string | The string `LArray`.
        methods.add_method("type", |_, _, ()| Ok("LArray"));
        // -- typeOf --
        /// Returns whether this array handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LArray`, `Array`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LArray" || name == "Array" || name == "Object")
        });
    }
}
/// Registers the `lurek.compute` API table with the Lua VM.
pub fn register(lua: &Lua, lurek: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newArray --
    /// Creates a zero-filled array with the requested shape and data type.
    /// @param | shape | table | Array table of positive dimension sizes.
    /// @param | dtype | string? | Data type name; defaults to `float32`.
    /// @return | LArray | New zero-filled array handle.
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
    /// Creates a zero-filled array with the requested shape and data type.
    /// @param | shape | table | Array table of positive dimension sizes.
    /// @param | dtype | string? | Data type name; defaults to `float32`.
    /// @return | LArray | New zero-filled array handle.
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
    /// Creates a one-filled array with the requested shape and data type.
    /// @param | shape | table | Array table of positive dimension sizes.
    /// @param | dtype | string? | Data type name; defaults to `float32`.
    /// @return | LArray | New one-filled array handle.
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
    /// Creates a one-dimensional range array.
    /// @param | start | number | First value in the range.
    /// @param | stop | number | Stop value for the range.
    /// @param | step | number? | Step size; defaults to 1.0.
    /// @param | dtype | string? | Data type name; defaults to `float32`.
    /// @return | LArray | New range array handle.
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
    /// Creates an array from a flat Lua table and optional shape.
    /// @param | data | table | Array table of numeric values.
    /// @param | shape | table? | Optional array table of positive dimension sizes.
    /// @param | dtype | string? | Data type name; defaults to `float32`.
    /// @return | LArray | New array handle containing table values.
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
    /// Creates a square Gaussian kernel array.
    /// @param | size | integer | Kernel width and height.
    /// @param | sigma | number | Gaussian sigma value.
    /// @return | LArray | New Gaussian kernel array.
    tbl.set(
        "gaussianKernel",
        lua.create_function(|lua, (size, sigma): (usize, f64)| {
            let k = linalg::gaussian_kernel(size, sigma).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: k })
        })?,
    )?;
    // -- rotate2dMatrix --
    /// Creates a 2D rotation matrix from an angle in radians.
    /// @param | angle_rad | number | Rotation angle in radians.
    /// @return | LArray | New rotation matrix array.
    tbl.set(
        "rotate2dMatrix",
        lua.create_function(|lua, angle_rad: f64| {
            let m = linalg::rotate2d_matrix(angle_rad).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(LuaArray { inner: m })
        })?,
    )?;
    // -- affine2d --
    /// Creates a 2D affine transform matrix.
    /// @param | tx | number | Translation X component.
    /// @param | ty | number | Translation Y component.
    /// @param | angle_rad | number | Rotation angle in radians.
    /// @param | sx | number | Scale X component.
    /// @param | sy | number | Scale Y component.
    /// @return | LArray | New affine transform matrix array.
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
    /// Computes the FFT of real-valued samples.
    /// @param | samples | table | Array table of real-valued samples.
    /// @return | table | Array table of complex pairs with `re` and `im` fields.
    tbl.set(
        "fft",
        lua.create_function(|lua, samples: LuaTable| {
            let data: Vec<f64> = samples.sequence_values::<f64>().flatten().collect();
            let output = crate::compute::fft::fft(&data);
            let t = lua.create_table()?;
            for (i, (re, im)) in output.iter().enumerate() {
                let pair = lua.create_table()?;
                /// Performs the 're' operation.
                /// @return | nil | No value is returned.
                pair.set("re", *re)?;
                /// Performs the 'im' operation.
                /// @return | nil | No value is returned.
                pair.set("im", *im)?;
                t.set(i + 1, pair)?;
            }
            Ok(t)
        })?,
    )?;
    // -- ifft --
    /// Computes the inverse FFT of complex frequency pairs.
    /// @param | freqs | table | Array table of complex pairs with `re` and `im` fields.
    /// @return | table | Array table of reconstructed real-valued samples.
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
    /// Computes FFT magnitudes for real-valued samples.
    /// @param | samples | table | Array table of real-valued samples.
    /// @return | table | Array table of magnitude values.
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
    // -- getParThreshold --
    /// Returns the global compute parallelism threshold.
    /// @return | integer | Current parallel threshold.
    tbl.set(
        "getParThreshold",
        lua.create_function(|_, ()| Ok(crate::compute::get_par_threshold() as i64))?,
    )?;
    // -- setParThreshold --
    /// Sets the global compute parallelism threshold and returns the previous value.
    /// @param | threshold | integer | New threshold; values below one are clamped to one.
    /// @return | integer | Previous parallel threshold.
    tbl.set(
        "setParThreshold",
        lua.create_function(|_, threshold: i64| {
            let new_threshold = (threshold as usize).max(1);
            let prev = crate::compute::set_par_threshold(new_threshold);
            Ok(prev as i64)
        })?,
    )?;
    /// Performs the 'compute' operation.
    /// @return | nil | No value is returned.
    lurek.set("compute", tbl)?;
    Ok(())
}
