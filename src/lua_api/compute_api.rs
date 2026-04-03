//! Registers the `luna.compute.*` array computation API.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for compute api-related operations and data management.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use mlua::prelude::*;

use crate::compute::array::{DataType, NdArray};
use crate::compute::ops;
use crate::compute::spatial;
use crate::lua_api::lua_types::{add_type_methods, LunaType};

impl LunaType for NdArray {
    const TYPE_NAME: &'static str = "Array";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Array", "Object"];
}

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

/// Dispatch pattern for arithmetic/comparison ops that accept Array or number.
macro_rules! dispatch_arith {
    ($methods:ident, $name:expr, $arr_fn:path, $scalar_fn:path) => {
        $methods.add_method($name, |lua, this, value: LuaValue| {
            let result = match value {
                LuaValue::Number(n) => $scalar_fn(this, n).map_err(LuaError::RuntimeError)?,
                LuaValue::Integer(n) => {
                    $scalar_fn(this, n as f64).map_err(LuaError::RuntimeError)?
                }
                LuaValue::UserData(ud) => {
                    let other = ud.borrow::<NdArray>()?;
                    $arr_fn(this, &other).map_err(LuaError::RuntimeError)?
                }
                _ => return Err(LuaError::RuntimeError("expected Array or number".into())),
            };
            lua.create_userdata(result)
        });
    };
}

impl mlua::UserData for NdArray {
    fn add_methods<'lua, M: mlua::UserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- Inspection --
        /// Returns the shape.
        /// @return any
        ///
        /// # Returns
        /// The current shape.
        methods.add_method("getShape", |lua, this, ()| {
            let table = lua.create_table()?;
            for (i, &dim) in this.shape().iter().enumerate() {
                table.set(i + 1, dim)?;
            }
            Ok(table)
        });

        /// Returns the dimensions.
        /// @return any
        ///
        /// # Returns
        /// The current dimensions.
        methods.add_method("getDimensions", |_, this, ()| Ok(this.ndim()));

        /// Returns the size.
        /// @return integer
        ///
        /// # Returns
        /// The current size.
        methods.add_method("getSize", |_, this, ()| Ok(this.size()));

        /// Returns the data type.
        /// @return any
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
        ///
        /// # Returns
        /// The current data type.
        methods.add_method("getDataType", |_, this, ()| {
            Ok(this.dtype().name().to_string())
        });

        /// Returns `true` if on g p u.
        /// @return boolean
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isOnGPU", |_, _this, ()| Ok(false));

        // -- Element access (1-based) --
        /// Returns the current value.
        /// @param args : MultiValue
        /// @return any
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
        ///
        /// # Returns
        /// The current get.
        methods.add_method("get", |_, this, args: LuaMultiValue| {
            let indices: Vec<usize> = args
                .iter()
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
                .collect::<LuaResult<Vec<_>>>()?;
            let flat = this.flat_index(&indices).map_err(LuaError::RuntimeError)?;
            Ok(this.get_f64(flat))
        });

        /// Sets the value.
        /// @param args : MultiValue
        ///
        /// # Parameters
        /// - `args` — `LuaMultiValue`.
        methods.add_method_mut("set", |_, this, args: LuaMultiValue| {
            let args_vec: Vec<LuaValue> = args.into_vec();
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
            let indices: Vec<usize> = args_vec[..args_vec.len() - 1]
                .iter()
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
                .collect::<LuaResult<Vec<_>>>()?;
            let flat = this.flat_index(&indices).map_err(LuaError::RuntimeError)?;
            this.set_f64(flat, val);
            Ok(())
        });

        /// To table on this Object.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("toTable", |lua, this, ()| {
            let table = lua.create_table()?;
            for i in 0..this.size() {
                table.set(i + 1, this.get_f64(i))?;
            }
            Ok(table)
        });

        // -- Shape manipulation --
        /// Reshape on this Object.
        /// @param shape : any
        ///
        /// # Parameters
        /// - `shape` — `any`.
        methods.add_method("reshape", |lua, this, shape: LuaValue| {
            let s = parse_shape(shape)?;
            let result = ops::reshape(this, &s).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Returns a deep copy of this object.
        ///
        /// # Parameters
        /// - `val` — `number`.
        methods.add_method("clone", |lua, this, ()| lua.create_userdata(this.clone()));

        /// Transpose on this Object.
        ///
        /// # Parameters
        /// - `val` — `number`.
        methods.add_method("transpose", |lua, this, ()| {
            let result = ops::transpose_2d(this).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Fill on this Object.
        /// @param val : number
        ///
        /// # Parameters
        /// - `val` — `number`.
        methods.add_method_mut("fill", |_, this, val: f64| {
            ops::fill(this, val);
            Ok(())
        });

        // -- Arithmetic --
        dispatch_arith!(methods, "add", ops::add, ops::add_scalar);
        dispatch_arith!(methods, "sub", ops::sub, ops::sub_scalar);
        dispatch_arith!(methods, "mul", ops::mul, ops::mul_scalar);
        dispatch_arith!(methods, "div", ops::div, ops::div_scalar);

        /// Pow on this Object.
        /// @param exp : number
        ///
        /// # Parameters
        /// - `exp` — `number`.
        methods.add_method("pow", |lua, this, exp: f64| {
            let result = ops::pow_scalar(this, exp).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Sqrt on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("sqrt", |lua, this, ()| {
            let result = ops::sqrt(this).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Abs on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("abs", |lua, this, ()| {
            let result = ops::abs(this).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Neg on this Object.
        ///
        /// # Parameters
        /// - `min` — `number`.
        /// - `max` — `number`.
        methods.add_method("neg", |lua, this, ()| {
            let result = ops::neg(this).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Clamps the value within the allowed range.
        /// @param min : number
        /// @param max : number
        ///
        /// # Parameters
        /// - `min` — `number`.
        /// - `max` — `number`.
        methods.add_method("clamp", |lua, this, (min, max): (f64, f64)| {
            let result = ops::clamp(this, min, max).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        // -- Comparison --
        dispatch_arith!(methods, "eq", ops::eq, ops::eq_scalar);
        dispatch_arith!(methods, "neq", ops::neq, ops::neq_scalar);
        dispatch_arith!(methods, "gt", ops::gt, ops::gt_scalar);
        dispatch_arith!(methods, "lt", ops::lt, ops::lt_scalar);
        dispatch_arith!(methods, "gte", ops::gte, ops::gte_scalar);
        dispatch_arith!(methods, "lte", ops::lte, ops::lte_scalar);

        // -- Masking --
        /// Threshold on this Object.
        /// @param val : number
        ///
        /// # Parameters
        /// - `mask` — `userdata`.
        /// - `other` — `userdata`.
        methods.add_method("threshold", |lua, this, val: f64| {
            let result = ops::threshold(this, val).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        methods.add_method(
            "where",
            |lua, this, (mask, other): (LuaAnyUserData, LuaAnyUserData)| {
                let mask_arr = mask.borrow::<NdArray>()?;
                let other_arr = other.borrow::<NdArray>()?;
                let result =
                    ops::where_mask(&mask_arr, this, &other_arr).map_err(LuaError::RuntimeError)?;
                lua.create_userdata(result)
            },
        );

        // -- Counting --
        /// Returns the number of non zero.
        /// @return any
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("countNonZero", |_, this, ()| Ok(ops::count_nonzero(this)));

        /// Argmin on this Object.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("argmin", |_, this, ()| Ok(ops::argmin(this) + 1));

        /// Argmax on this Object.
        /// @return any
        ///
        /// # Parameters
        /// - `axis` — `integer` optional.
        methods.add_method("argmax", |_, this, ()| Ok(ops::argmax(this) + 1));

        /// Any on this Object.
        /// @return any
        ///
        /// # Parameters
        /// - `axis` — `integer` optional.
        methods.add_method("any", |_, this, ()| Ok(ops::any(this)));

        /// All on this Object.
        /// @return any
        ///
        /// # Parameters
        /// - `axis` — `integer` optional.
        methods.add_method("all", |_, this, ()| Ok(ops::all(this)));

        // -- Reductions --
        /// Sum on this Object.
        /// @param axis : integer?
        /// @return any
        ///
        /// # Parameters
        /// - `axis` — `integer` optional.
        methods.add_method("sum", |lua, this, axis: Option<i64>| match axis {
            None => Ok(LuaValue::Number(ops::sum(this))),
            Some(a) => {
                let arr = ops::sum_axis(this, (a - 1) as usize).map_err(LuaError::RuntimeError)?;
                Ok(LuaValue::UserData(lua.create_userdata(arr)?))
            }
        });

        /// Mean on this Object.
        /// @param axis : integer?
        /// @return any
        ///
        /// # Parameters
        /// - `axis` — `integer` optional.
        methods.add_method("mean", |lua, this, axis: Option<i64>| match axis {
            None => Ok(LuaValue::Number(ops::mean(this))),
            Some(a) => {
                let arr = ops::mean_axis(this, (a - 1) as usize).map_err(LuaError::RuntimeError)?;
                Ok(LuaValue::UserData(lua.create_userdata(arr)?))
            }
        });

        /// Min on this Object.
        /// @param axis : integer?
        /// @return any
        ///
        /// # Parameters
        /// - `axis` — `integer` optional.
        methods.add_method("min", |lua, this, axis: Option<i64>| match axis {
            None => Ok(LuaValue::Number(ops::min_val(this))),
            Some(a) => {
                let arr = ops::min_axis(this, (a - 1) as usize).map_err(LuaError::RuntimeError)?;
                Ok(LuaValue::UserData(lua.create_userdata(arr)?))
            }
        });

        /// Max on this Object.
        /// @param axis : integer?
        /// @return any
        ///
        /// # Parameters
        /// - `axis` — `integer` optional.
        methods.add_method("max", |lua, this, axis: Option<i64>| match axis {
            None => Ok(LuaValue::Number(ops::max_val(this))),
            Some(a) => {
                let arr = ops::max_axis(this, (a - 1) as usize).map_err(LuaError::RuntimeError)?;
                Ok(LuaValue::UserData(lua.create_userdata(arr)?))
            }
        });

        // -- Linear algebra --
        /// Matmul on this Object.
        /// @param other : userdata
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("matmul", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<NdArray>()?;
            let result = spatial::matmul(this, &other_arr).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Dot on this Object.
        /// @param other : userdata
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("dot", |_, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<NdArray>()?;
            spatial::dot(this, &other_arr).map_err(LuaError::RuntimeError)
        });

        // -- Bitwise (int32 only) --
        /// Bitwise and on this Object.
        /// @param other : userdata
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("bitwiseAnd", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<NdArray>()?;
            let result = ops::bitwise_and(this, &other_arr).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Bitwise or on this Object.
        /// @param other : userdata
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("bitwiseOr", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<NdArray>()?;
            let result = ops::bitwise_or(this, &other_arr).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Bitwise xor on this Object.
        /// @param other : userdata
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("bitwiseXor", |lua, this, other: LuaAnyUserData| {
            let other_arr = other.borrow::<NdArray>()?;
            let result = ops::bitwise_xor(this, &other_arr).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Bitwise not on this Object.
        ///
        /// # Parameters
        /// - `amount` — `integer`.
        methods.add_method("bitwiseNot", |lua, this, ()| {
            let result = ops::bitwise_not(this).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Bitwise l shift on this Object.
        /// @param amount : integer
        ///
        /// # Parameters
        /// - `amount` — `integer`.
        methods.add_method("bitwiseLShift", |lua, this, amount: u32| {
            let result = ops::bitwise_lshift(this, amount).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Bitwise r shift on this Object.
        /// @param amount : integer
        ///
        /// # Parameters
        /// - `amount` — `integer`.
        methods.add_method("bitwiseRShift", |lua, this, amount: u32| {
            let result = ops::bitwise_rshift(this, amount).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        // -- 2D Spatial (indices are 1-based in Lua) --
        /// Convolve2 d on this Object.
        /// @param kernel : userdata
        ///
        /// # Parameters
        /// - `kernel` — `userdata`.
        methods.add_method("convolve2D", |lua, this, kernel: LuaAnyUserData| {
            let kernel_arr = kernel.borrow::<NdArray>()?;
            let result = spatial::convolve2d(this, &kernel_arr).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Dilate on this Object.
        /// @param radius : integer
        ///
        /// # Parameters
        /// - `radius` — `integer`.
        methods.add_method("dilate", |lua, this, radius: usize| {
            let result = spatial::dilate(this, radius).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        /// Erode on this Object.
        /// @param radius : integer
        ///
        /// # Parameters
        /// - `row` — `integer`.
        /// - `col` — `integer`.
        /// - `val` — `number`.
        methods.add_method("erode", |lua, this, radius: usize| {
            let result = spatial::erode(this, radius).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(result)
        });

        methods.add_method(
            "floodFill",
            |lua, this, (row, col, val): (usize, usize, f64)| {
                let result = spatial::flood_fill(this, row - 1, col - 1, val)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(result)
            },
        );

        methods.add_method(
            "getRegion",
            |lua, this, (row, col, rows, cols): (usize, usize, usize, usize)| {
                let result = spatial::get_region(this, row - 1, col - 1, rows, cols)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(result)
            },
        );

        methods.add_method_mut(
            "setRegion",
            |_, this, (row, col, source): (usize, usize, LuaAnyUserData)| {
                let src = source.borrow::<NdArray>()?;
                spatial::set_region(this, row - 1, col - 1, &src)
                    .map_err(LuaError::RuntimeError)?;
                Ok(())
            },
        );

        // -- Type methods --
        add_type_methods(methods);
    }
}

/// Registers the `luna.compute` table with array factory functions.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let compute = lua.create_table()?;

    // luna.compute.newArray(shape, dtype?)
    // Create a new array initialized to zero with the given shape and optional dtype.
    /// New array.
    ///
    /// @param shape : any
    /// @param dtype : string?
    compute.set(
        "newArray",
        lua.create_function(|lua, (shape, dtype): (LuaValue, Option<String>)| {
            let s = parse_shape(shape)?;
            let dt = parse_dtype(dtype)?;
            let arr = NdArray::zeros(&s, dt).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(arr)
        })?,
    )?;

    // luna.compute.zeros(shape, dtype?)
    // Create a new array filled with zeros.
    /// Zeros.
    ///
    /// @param shape : any
    /// @param dtype : string?
    compute.set(
        "zeros",
        lua.create_function(|lua, (shape, dtype): (LuaValue, Option<String>)| {
            let s = parse_shape(shape)?;
            let dt = parse_dtype(dtype)?;
            let arr = NdArray::zeros(&s, dt).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(arr)
        })?,
    )?;

    // luna.compute.ones(shape, dtype?)
    // Create a new array filled with ones.
    /// Ones.
    ///
    /// @param shape : any
    /// @param dtype : string?
    compute.set(
        "ones",
        lua.create_function(|lua, (shape, dtype): (LuaValue, Option<String>)| {
            let s = parse_shape(shape)?;
            let dt = parse_dtype(dtype)?;
            let arr = NdArray::ones(&s, dt).map_err(LuaError::RuntimeError)?;
            lua.create_userdata(arr)
        })?,
    )?;

    // luna.compute.range(start, stop, step?, dtype?)
    // Create a 1D array with values from start to stop.
    /// Range.
    ///
    /// @param start : number
    /// @param stop : number
    /// @param step : number?
    /// @param dtype : string?
    compute.set(
        "range",
        lua.create_function(
            |lua, (start, stop, step, dtype): (f64, f64, Option<f64>, Option<String>)| {
                let st = step.unwrap_or(1.0);
                let dt = parse_dtype(dtype)?;
                let arr = NdArray::range(start, stop, st, dt).map_err(LuaError::RuntimeError)?;
                lua.create_userdata(arr)
            },
        )?,
    )?;

    // luna.compute.fromTable(tbl, shape?, dtype?)
    // Create an array from a Lua table of numbers.
    /// From table.
    ///
    /// @param tbl : table
    /// @param shape : any?
    /// @param dtype : string?
    compute.set(
        "fromTable",
        lua.create_function(
            |lua, (tbl, shape, dtype): (LuaTable, Option<LuaValue>, Option<String>)| {
                let mut values = Vec::new();
                for i in 1..=tbl.len()? {
                    let v: f64 = tbl.get(i)?;
                    values.push(v);
                }
                let dt = parse_dtype(dtype)?;
                let s = match shape {
                    Some(sv) => parse_shape(sv)?,
                    None => vec![values.len()],
                };
                let arr = NdArray::from_slice(&values, &s, dt).map_err(LuaError::RuntimeError)?;
                lua.create_userdata(arr)
            },
        )?,
    )?;

    /// Compute on this Object.
    ///
    /// # Returns
    /// The result.
    luna.set("compute", compute)?;
    Ok(())
}
