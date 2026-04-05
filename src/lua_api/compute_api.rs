//! `luna.compute` Lua API bindings.
//!
//! Auto-generated skeleton from `src/compute/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaNdArray ────────────────────────────────────────────────────────────

pub struct LuaNdArray(/* TODO: add key + state fields */);


impl LuaNdArray {
    /// Read element at flat index as f64 (works for any dtype).
    ///
    /// @param flat : integer
    /// @return number
    pub fn get_f64(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Read element at flat index as i32. Only meaningful for Int32 arrays.
    ///
    /// @param flat : integer
    /// @return integer
    pub fn get_i32(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Convert a multi-dimensional index to a flat element offset.
    ///
    /// @param indices : [usize]
    /// @return Result<usize
    pub fn flat_index(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Returns the element data type of this array.
    ///
    ///
    /// @return DataType
    pub fn dtype(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the total number of elements in this array.
    ///
    ///
    /// @return integer
    pub fn size(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the number of dimensions (1, 2, or 3).
    ///
    ///
    /// @return integer
    pub fn ndim(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaNdArray {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getF64", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getI32", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("flatIndex", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("dtype", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("size", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("ndim", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.compute.* functions ──────────────────────────────────────────

/// Parse a dtype from a string name (`"float32"`, `"float64"`, `"int32"`).
///
/// @param s : str
/// @return Result<Self
pub fn parse(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Number of bytes per element for this dtype.
///
///
/// @return integer
pub fn byte_size(_lua: &Lua, _: ()) -> LuaResult<()> {
    todo!()
}

/// Create a zero-initialized NdArray. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param shape : [usize]
/// @param dtype : DataType
/// @return Result<Self
pub fn zeros(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create an NdArray filled with ones (1.0 for floats, 1 for int32).
///
/// @param shape : [usize]
/// @param dtype : DataType
/// @return Result<Self
pub fn ones(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a 1D NdArray with values from `start` to `stop` (exclusive) with given step.
///
/// @param start : number
/// @param stop : number
/// @param step : number
/// @param dtype : DataType
/// @return Result<Self
pub fn range(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create an NdArray from a slice of f64 values, converting to the target dtype.
///
/// @param values : [f64]
/// @param shape : [usize]
/// @param dtype : DataType
/// @return Result<Self
pub fn from_slice(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Write a value (as f64) to the flat index, converting to the array's dtype.
///
///
/// @param flat : integer
/// @param val : number
pub fn set_f64(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Write an i32 value at the flat index. Only meaningful for Int32 arrays.
///
///
/// @param flat : integer
/// @param val : integer
pub fn set_i32(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Compute row-major strides for a given shape.
///
/// @param shape : [usize]
/// @return table
pub fn compute_strides(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise addition of two arrays (same shape and dtype).
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn add(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a scalar to every element. The insertion is O(1) amortised unless a resize is triggered.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn add_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise subtraction of two arrays (same shape and dtype).
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn sub(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Subtract a scalar from every element. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn sub_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise multiplication of two arrays (same shape and dtype).
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn mul(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Multiply every element by a scalar. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn mul_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise division of two arrays (same shape and dtype).
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn div(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Divide every element by a scalar. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn div_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Raise every element to a scalar exponent.
///
/// @param a : NdArray
/// @param exp : number
/// @return Result<NdArray
pub fn pow_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise square root. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @return Result<NdArray
pub fn sqrt(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise absolute value. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @return Result<NdArray
pub fn abs(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise negation. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @return Result<NdArray
pub fn neg(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Clamp every element to `[min_val, max_val]`.
///
/// @param a : NdArray
/// @param min_val : number
/// @param max_val : number
/// @return Result<NdArray
pub fn clamp(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise equality comparison of two arrays. Returns Float32 with 0/1.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn eq(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise equality comparison against a scalar. Returns Float32.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn eq_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise not-equal comparison of two arrays. Returns Float32.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn neq(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise not-equal comparison against a scalar. Returns Float32.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn neq_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise greater-than comparison of two arrays. Returns Float32.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn gt(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise greater-than comparison against a scalar. Returns Float32.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn gt_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise less-than comparison of two arrays. Returns Float32.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn lt(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise less-than comparison against a scalar. Returns Float32.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn lt_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise greater-than-or-equal comparison of two arrays. Returns Float32.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn gte(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise greater-than-or-equal comparison against a scalar. Returns Float32.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn gte_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise less-than-or-equal comparison of two arrays. Returns Float32.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn lte(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Element-wise less-than-or-equal comparison against a scalar. Returns Float32.
///
/// @param a : NdArray
/// @param s : number
/// @return Result<NdArray
pub fn lte_scalar(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Threshold mask: returns Float32 array with 1.0 where `a >= val`, 0.0 otherwise.
///
/// @param a : NdArray
/// @param val : number
/// @return Result<NdArray
pub fn threshold(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Conditional selection: where `cond != 0`, choose from `a`; otherwise from `b`.
///
/// @param cond : NdArray
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn where_mask(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Count the number of non-zero elements. Runs in O(1) time.
///
/// @param a : NdArray
/// @return integer
pub fn count_nonzero(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Return the flat index of the minimum element (0-based).
///
/// @param a : NdArray
/// @return integer
pub fn argmin(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Return the flat index of the maximum element (0-based).
///
/// @param a : NdArray
/// @return integer
pub fn argmax(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns `true` if any element is non-zero.
///
/// @param a : NdArray
/// @return boolean
pub fn any(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Returns `true` if all elements are non-zero.
///
/// @param a : NdArray
/// @return boolean
pub fn all(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sum of all elements. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @return number
pub fn sum(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Mean of all elements. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @return number
pub fn mean(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Minimum value across all elements. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @return number
pub fn min_val(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Maximum value across all elements. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @return number
pub fn max_val(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Sum along a given axis, producing an array with that axis removed.
///
/// @param a : NdArray
/// @param axis : integer
/// @return Result<NdArray
pub fn sum_axis(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Mean along a given axis. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @param axis : integer
/// @return Result<NdArray
pub fn mean_axis(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Minimum along a given axis. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @param axis : integer
/// @return Result<NdArray
pub fn min_axis(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Maximum along a given axis. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @param axis : integer
/// @return Result<NdArray
pub fn max_axis(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Reshape an array to a new shape with the same total element count.
///
/// @param a : NdArray
/// @param new_shape : [usize]
/// @return Result<NdArray
pub fn reshape(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Transpose a 2D array (swap rows and columns).
///
/// @param a : NdArray
/// @return Result<NdArray
pub fn transpose_2d(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Fill all elements of an array with a value (in-place).
///
///
/// @param a : mut NdArray
/// @param val : number
pub fn fill(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Clone an array (convenience wrapper). Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @return NdArray
pub fn clone_array(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bitwise AND of two Int32 arrays. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn bitwise_and(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bitwise OR of two Int32 arrays. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn bitwise_or(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bitwise XOR of two Int32 arrays. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn bitwise_xor(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bitwise NOT of an Int32 array. Consult the module-level documentation for the broader usage context and preconditions.
///
/// @param a : NdArray
/// @return Result<NdArray
pub fn bitwise_not(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bitwise left shift of an Int32 array by `amount` bits.
///
/// @param a : NdArray
/// @param amount : integer
/// @return Result<NdArray
pub fn bitwise_lshift(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Bitwise right shift (arithmetic) of an Int32 array by `amount` bits.
///
/// @param a : NdArray
/// @param amount : integer
/// @return Result<NdArray
pub fn bitwise_rshift(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// 2D convolution with zero-padding (same-size output).
///
/// @param input : NdArray
/// @param kernel : NdArray
/// @return Result<NdArray
pub fn convolve2d(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Morphological dilation with a Manhattan-diamond structuring element.
///
/// @param a : NdArray
/// @param radius : integer
/// @return Result<NdArray
pub fn dilate(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Morphological erosion with a Manhattan-diamond structuring element.
///
/// @param a : NdArray
/// @param radius : integer
/// @return Result<NdArray
pub fn erode(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Flood fill using BFS with 4-connectivity.
///
/// @param a : NdArray
/// @param row : integer
/// @param col : integer
/// @param val : number
/// @return Result<NdArray
pub fn flood_fill(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Extract a rectangular sub-region from a 2D array.
///
/// @param a : NdArray
/// @param row : integer
/// @param col : integer
/// @param sub_rows : integer
/// @param sub_cols : integer
/// @return Result<NdArray
pub fn get_region(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Copy a source 2D array into a target 2D array at position `(row, col)`.
///
/// @param a : mut NdArray
/// @param row : integer
/// @param col : integer
/// @param src : NdArray
/// @return Result<()
pub fn set_region(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Matrix multiplication of two 2D arrays: (m,k) × (k,n) → (m,n).
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<NdArray
pub fn matmul(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Dot product of two 1D arrays (same length). Returns a scalar.
///
/// @param a : NdArray
/// @param b : NdArray
/// @return Result<f64
pub fn dot(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.compute` API table.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("parse", lua.create_function(parse)?)?;
    tbl.set("byteSize", lua.create_function(byte_size)?)?;
    tbl.set("zeros", lua.create_function(zeros)?)?;
    tbl.set("ones", lua.create_function(ones)?)?;
    tbl.set("range", lua.create_function(range)?)?;
    tbl.set("fromSlice", lua.create_function(from_slice)?)?;
    tbl.set("setF64", lua.create_function(set_f64)?)?;
    tbl.set("setI32", lua.create_function(set_i32)?)?;
    tbl.set("computeStrides", lua.create_function(compute_strides)?)?;
    tbl.set("add", lua.create_function(add)?)?;
    tbl.set("addScalar", lua.create_function(add_scalar)?)?;
    tbl.set("sub", lua.create_function(sub)?)?;
    tbl.set("subScalar", lua.create_function(sub_scalar)?)?;
    tbl.set("mul", lua.create_function(mul)?)?;
    tbl.set("mulScalar", lua.create_function(mul_scalar)?)?;
    tbl.set("div", lua.create_function(div)?)?;
    tbl.set("divScalar", lua.create_function(div_scalar)?)?;
    tbl.set("powScalar", lua.create_function(pow_scalar)?)?;
    tbl.set("sqrt", lua.create_function(sqrt)?)?;
    tbl.set("abs", lua.create_function(abs)?)?;
    tbl.set("neg", lua.create_function(neg)?)?;
    tbl.set("clamp", lua.create_function(clamp)?)?;
    tbl.set("eq", lua.create_function(eq)?)?;
    tbl.set("eqScalar", lua.create_function(eq_scalar)?)?;
    tbl.set("neq", lua.create_function(neq)?)?;
    tbl.set("neqScalar", lua.create_function(neq_scalar)?)?;
    tbl.set("gt", lua.create_function(gt)?)?;
    tbl.set("gtScalar", lua.create_function(gt_scalar)?)?;
    tbl.set("lt", lua.create_function(lt)?)?;
    tbl.set("ltScalar", lua.create_function(lt_scalar)?)?;
    tbl.set("gte", lua.create_function(gte)?)?;
    tbl.set("gteScalar", lua.create_function(gte_scalar)?)?;
    tbl.set("lte", lua.create_function(lte)?)?;
    tbl.set("lteScalar", lua.create_function(lte_scalar)?)?;
    tbl.set("threshold", lua.create_function(threshold)?)?;
    tbl.set("whereMask", lua.create_function(where_mask)?)?;
    tbl.set("countNonzero", lua.create_function(count_nonzero)?)?;
    tbl.set("argmin", lua.create_function(argmin)?)?;
    tbl.set("argmax", lua.create_function(argmax)?)?;
    tbl.set("any", lua.create_function(any)?)?;
    tbl.set("all", lua.create_function(all)?)?;
    tbl.set("sum", lua.create_function(sum)?)?;
    tbl.set("mean", lua.create_function(mean)?)?;
    tbl.set("minVal", lua.create_function(min_val)?)?;
    tbl.set("maxVal", lua.create_function(max_val)?)?;
    tbl.set("sumAxis", lua.create_function(sum_axis)?)?;
    tbl.set("meanAxis", lua.create_function(mean_axis)?)?;
    tbl.set("minAxis", lua.create_function(min_axis)?)?;
    tbl.set("maxAxis", lua.create_function(max_axis)?)?;
    tbl.set("reshape", lua.create_function(reshape)?)?;
    tbl.set("transpose2d", lua.create_function(transpose_2d)?)?;
    tbl.set("fill", lua.create_function(fill)?)?;
    tbl.set("cloneArray", lua.create_function(clone_array)?)?;
    tbl.set("bitwiseAnd", lua.create_function(bitwise_and)?)?;
    tbl.set("bitwiseOr", lua.create_function(bitwise_or)?)?;
    tbl.set("bitwiseXor", lua.create_function(bitwise_xor)?)?;
    tbl.set("bitwiseNot", lua.create_function(bitwise_not)?)?;
    tbl.set("bitwiseLshift", lua.create_function(bitwise_lshift)?)?;
    tbl.set("bitwiseRshift", lua.create_function(bitwise_rshift)?)?;
    tbl.set("convolve2d", lua.create_function(convolve2d)?)?;
    tbl.set("dilate", lua.create_function(dilate)?)?;
    tbl.set("erode", lua.create_function(erode)?)?;
    tbl.set("floodFill", lua.create_function(flood_fill)?)?;
    tbl.set("getRegion", lua.create_function(get_region)?)?;
    tbl.set("setRegion", lua.create_function(set_region)?)?;
    tbl.set("matmul", lua.create_function(matmul)?)?;
    tbl.set("dot", lua.create_function(dot)?)?;
    luna.set("compute", tbl)?;
    Ok(())
}
