//! `luna.dataframe` Lua API bindings.
//!
//! Auto-generated skeleton from `src/dataframe/` Rust docstrings.
//! Fill in the `todo!()` bodies with actual implementation.
//! Every `pub fn` has `@param`/`@return` tags for `gen_lua_api.py`.
//!
use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;
use mlua::{UserData, UserDataMethods};

use crate::engine::SharedState;

// ── LuaCellValue ────────────────────────────────────────────────────────────

pub struct LuaCellValue(/* TODO: add key + state fields */);


impl LuaCellValue {
    /// Returns `true` if this cell is `Nil`. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @return boolean
    pub fn is_nil(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the contained number, or `None`.
    ///
    ///
    /// # Returns
    /// `number?`.
    ///
    /// @return number?
    pub fn as_number(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the contained text as a string slice, or `None`.
    ///
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @return Option<
    pub fn as_text(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Returns the contained boolean, or `None`.
    ///
    ///
    /// # Returns
    /// `boolean?`.
    ///
    /// @return boolean?
    pub fn as_bool(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Comparison for sorting. Nil sorts to end; among non-nil values
    ///
    ///
    /// # Parameters
    /// - `other` — `CellValue` ...
    ///
    /// # Returns
    /// `Ordering`.
    ///
    /// @param other : CellValue
    /// @return Ordering
    pub fn cmp_for_sort(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaCellValue {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isNil", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("asNumber", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("asText", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("asBool", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("cmpForSort", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaDataFrame ────────────────────────────────────────────────────────────

pub struct LuaDataFrame(/* TODO: add key + state fields */);


impl LuaDataFrame {
    /// Return the number of rows. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn nrows(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Return the number of columns. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn ncols(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Alias for `nrows()`; returns the row count in O(1) time.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Resolve a `ColRef` to a 0-based column index.
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<usize`.
    ///
    /// @param col : ColRef
    /// @return Result<usize
    pub fn resolve_col(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return a reference to the column data. This accessor incurs no allocation; call it freely in hot paths.
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<`.
    ///
    /// @param col : ColRef
    /// @return Result<
    pub fn get_column(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get a full row as name-value pairs (0-based index).
    ///
    ///
    /// # Parameters
    /// - `row` — `integer` ...
    ///
    /// # Returns
    /// `Result<Vec<(String`.
    ///
    /// @param row : integer
    /// @return Result<Vec<(String
    pub fn get_row(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Get a single cell value (0-based row, ColRef for column).
    ///
    ///
    /// # Parameters
    /// - `row` — `integer` ...
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<CellValue`.
    ///
    /// @param row : integer
    /// @param col : ColRef
    /// @return Result<CellValue
    pub fn get_value(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Deep-clone this DataFrame. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `DataFrame`.
    ///
    /// @return DataFrame
    pub fn clone_df(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Filter rows where `col op val` is true.
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    /// - `op` — `str` ...
    /// - `val` — `CellValue` ...
    ///
    /// # Returns
    /// `Result<DataFrame`.
    ///
    /// @param col : ColRef
    /// @param op : str
    /// @param val : CellValue
    /// @return Result<DataFrame
    pub fn filter(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Sort by column, stable sort. Nils sort to end.
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    /// - `ascending` — `boolean` ...
    ///
    /// # Returns
    /// `Result<DataFrame`.
    ///
    /// @param col : ColRef
    /// @param ascending : boolean
    /// @return Result<DataFrame
    pub fn sort(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the first `n` rows. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Parameters
    /// - `n` — `integer` ...
    ///
    /// # Returns
    /// `DataFrame`.
    ///
    /// @param n : integer
    /// @return DataFrame
    pub fn head(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the last `n` rows. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Parameters
    /// - `n` — `integer` ...
    ///
    /// # Returns
    /// `DataFrame`.
    ///
    /// @param n : integer
    /// @return DataFrame
    pub fn tail(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return a slice of rows from `start` to `end` (0-based, inclusive on both ends).
    ///
    ///
    /// # Parameters
    /// - `start` — `integer` ...
    /// - `end` — `integer` ...
    ///
    /// # Returns
    /// `Result<DataFrame`.
    ///
    /// @param start : integer
    /// @param end : integer
    /// @return Result<DataFrame
    pub fn slice(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Column projection: select a subset of columns.
    ///
    ///
    /// # Parameters
    /// - `cols` — `[ColRef]` ...
    ///
    /// # Returns
    /// `Result<DataFrame`.
    ///
    /// @param cols : [ColRef]
    /// @return Result<DataFrame
    pub fn select_columns(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return unique values in a column (O(n^2) dedup).
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<Vec<CellValue>`.
    ///
    /// @param col : ColRef
    /// @return Result<Vec<CellValue>
    pub fn unique(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Group rows by the value in a column. Returns (group_key, sub-DataFrame) pairs.
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<Vec<(CellValue`.
    ///
    /// @param col : ColRef
    /// @return Result<Vec<(CellValue
    pub fn group_by(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Count distinct values in a column, returning a DataFrame with "value" and "count" columns.
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<DataFrame`.
    ///
    /// @param col : ColRef
    /// @return Result<DataFrame
    pub fn count_by(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Remove rows where the given column is Nil.
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<DataFrame`.
    ///
    /// @param col : ColRef
    /// @return Result<DataFrame
    pub fn drop_nil(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Random sample of `n` rows using Fisher-Yates shuffle.
    ///
    ///
    /// # Parameters
    /// - `n` — `integer` ...
    /// - `seed` — `integer?` ...
    ///
    /// # Returns
    /// `DataFrame`.
    ///
    /// @param n : integer
    /// @param seed : integer?
    /// @return DataFrame
    pub fn sample(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Sum of numeric values in a column (skipping nils).
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<f64`.
    ///
    /// @param col : ColRef
    /// @return Result<f64
    pub fn sum(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Mean of numeric values in a column (skipping nils).
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<f64`.
    ///
    /// @param col : ColRef
    /// @return Result<f64
    pub fn mean(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Minimum numeric value in a column (skipping nils).
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<f64`.
    ///
    /// @param col : ColRef
    /// @return Result<f64
    pub fn min_val(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Maximum numeric value in a column (skipping nils).
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<f64`.
    ///
    /// @param col : ColRef
    /// @return Result<f64
    pub fn max_val(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Median of numeric values in a column (skipping nils).
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<f64`.
    ///
    /// @param col : ColRef
    /// @return Result<f64
    pub fn median(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Standard deviation of numeric values in a column (population stddev, skipping nils).
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<f64`.
    ///
    /// @param col : ColRef
    /// @return Result<f64
    pub fn stddev(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Variance of numeric values in a column (population variance, skipping nils).
    ///
    ///
    /// # Parameters
    /// - `col` — `ColRef` ...
    ///
    /// # Returns
    /// `Result<f64`.
    ///
    /// @param col : ColRef
    /// @return Result<f64
    pub fn variance(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Descriptive statistics for all numeric columns.
    ///
    ///
    /// # Returns
    /// `DataFrame`.
    ///
    /// @return DataFrame
    pub fn describe(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Serialize to CSV string (RFC 4180). Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `string`.
    ///
    /// @return string
    pub fn to_csv(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Serialize to JSON string (array-of-objects format).
    ///
    ///
    /// # Returns
    /// `string`.
    ///
    /// @return string
    pub fn to_json(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Serialize to LVDF binary format. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn to_binary(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Format the DataFrame as an ASCII table for debug display.
    ///
    ///
    /// # Returns
    /// `string`.
    ///
    /// @return string
    pub fn to_string_table(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaDataFrame {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("nrows", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("ncols", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("count", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("resolveCol", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getColumn", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getRow", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("getValue", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("cloneDf", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("filter", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("sort", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("head", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("tail", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("slice", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("selectColumns", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("unique", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("groupBy", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("countBy", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("dropNil", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("sample", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("sum", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("mean", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("minVal", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("maxVal", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("median", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("stddev", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("variance", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("describe", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("toCsv", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("toJson", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("toBinary", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("toStringTable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── LuaDatabase ────────────────────────────────────────────────────────────

pub struct LuaDatabase(/* TODO: add key + state fields */);


impl LuaDatabase {
    /// Get a shared reference to a table by name.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `Option<`.
    ///
    /// @param name : str
    /// @return Option<
    pub fn get_table(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Check whether a table with the given name exists.
    ///
    ///
    /// # Parameters
    /// - `name` — `str` ...
    ///
    /// # Returns
    /// `boolean`.
    ///
    /// @param name : str
    /// @return boolean
    pub fn has_table(&self, _lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
        todo!()
    }
    /// Return the names of all tables, sorted alphabetically.
    ///
    ///
    /// # Returns
    /// `table`.
    ///
    /// @return table
    pub fn list_tables(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
    /// Return the number of tables. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    ///
    /// # Returns
    /// `integer`.
    ///
    /// @return integer
    pub fn table_count(&self, _lua: &Lua, _: ()) -> LuaResult<()> {
        todo!()
    }
}

impl UserData for LuaDatabase {
    fn add_methods<'lua, M: UserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getTable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("hasTable", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("listTables", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
        methods.add_method("tableCount", |_lua, _this, _: ()| -> LuaResult<()> { todo!() });
    }
}

// ── luna.dataframe.* functions ──────────────────────────────────────────

/// Add a new column, filling existing rows with `default`.
///
///
/// # Parameters
/// - `name` — `str` ...
/// - `default` — `CellValue` ...
///
/// # Returns
/// `Result<()`.
///
/// @param name : str
/// @param default : CellValue
/// @return Result<()
pub fn add_column(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a column by reference. Returns the removed value if present, or `None` when the key did not exist.
///
///
/// # Parameters
/// - `col` — `ColRef` ...
///
/// # Returns
/// `Result<()`.
///
/// @param col : ColRef
/// @return Result<()
pub fn remove_column(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Rename a column. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `col` — `ColRef` ...
/// - `new_name` — `str` ...
///
/// # Returns
/// `Result<()`.
///
/// @param col : ColRef
/// @param new_name : str
/// @return Result<()
pub fn rename_column(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add a row from name-value pairs. Missing columns receive `Nil`.
///
///
/// # Parameters
/// - `values` — `[(String, CellValue)]` ...
///
/// # Returns
/// `integer`.
///
/// @param values : [(String, CellValue)]
/// @return integer
pub fn add_row(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a row by 0-based index. Returns the removed value if present, or `None` when the key did not exist.
///
///
/// # Parameters
/// - `row` — `integer` ...
///
/// # Returns
/// `Result<()`.
///
/// @param row : integer
/// @return Result<()
pub fn remove_row(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Set a single cell value (0-based row, ColRef for column).
///
///
/// # Parameters
/// - `row` — `integer` ...
/// - `col` — `ColRef` ...
/// - `val` — `CellValue` ...
///
/// # Returns
/// `Result<()`.
///
/// @param row : integer
/// @param col : ColRef
/// @param val : CellValue
/// @return Result<()
pub fn set_value(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Create a DataFrame from raw column names and column-major data.
///
///
/// # Parameters
/// - `column_names` — `table` ...
/// - `data` — `table` ...
///
/// # Returns
/// `Self`.
///
/// @param column_names : table
/// @param data : table
/// @return Self
pub fn from_raw(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Generate a DataFrame with random data. Consult the module-level documentation for the broader usage context and preconditions.
///
///
/// # Parameters
/// - `defs` — `[(String, String)]` ...
/// - `n_rows` — `integer` ...
/// - `seed` — `integer?` ...
///
/// # Returns
/// `DataFrame`.
///
/// @param defs : [(String, String)]
/// @param n_rows : integer
/// @param seed : integer?
/// @return DataFrame
pub fn random(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Add or replace a table. The insertion is O(1) amortised unless a resize is triggered.
///
///
/// # Parameters
/// - `name` — `str` ...
/// - `df` — `DataFrame` ...
///
/// @param name : str
/// @param df : DataFrame
pub fn add_table(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Get a mutable reference to a table by name.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// # Returns
/// `Option<`.
///
/// @param name : str
/// @return Option<
pub fn get_table_mut(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Remove a table by name. Returns error if not found.
///
///
/// # Parameters
/// - `name` — `str` ...
///
/// # Returns
/// `Result<()`.
///
/// @param name : str
/// @return Result<()
pub fn remove_table(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Merge all tables from `other` into this database.
///
///
/// # Parameters
/// - `other` — `Database` ...
///
/// @param other : Database
pub fn merge(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Join with another DataFrame on matching columns.
///
///
/// # Parameters
/// - `other` — `DataFrame` ...
/// - `this_col` — `ColRef` ...
/// - `other_col` — `ColRef` ...
/// - `join_type` — `str` ...
///
/// # Returns
/// `Result<DataFrame`.
///
/// @param other : DataFrame
/// @param this_col : ColRef
/// @param other_col : ColRef
/// @param join_type : str
/// @return Result<DataFrame
pub fn join(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Append rows from another DataFrame in-place. Adds missing columns as Nil.
///
///
/// # Parameters
/// - `other` — `DataFrame` ...
///
/// @param other : DataFrame
/// Replace Nil values in a column with the given value (in-place).
///
///
/// # Parameters
/// - `col` — `ColRef` ...
/// - `val` — `CellValue` ...
///
/// # Returns
/// `Result<()`.
///
/// @param col : ColRef
/// @param val : CellValue
/// @return Result<()
pub fn fill_nil(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse a CSV string into a DataFrame. Returns a fully initialised instance with all fields set to their initial values.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Result<DataFrame`.
///
/// @param s : str
/// @return Result<DataFrame
pub fn from_csv(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Parse JSON (array-of-objects) into a DataFrame.
///
///
/// # Parameters
/// - `s` — `str` ...
///
/// # Returns
/// `Result<DataFrame`.
///
/// @param s : str
/// @return Result<DataFrame
pub fn from_json(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Deserialize a DataFrame from LVDF binary format.
///
///
/// # Parameters
/// - `data` — `[u8]` ...
///
/// # Returns
/// `Result<DataFrame`.
///
/// @param data : [u8]
/// @return Result<DataFrame
pub fn from_binary(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Execute a SQL query on a single DataFrame.
///
///
/// # Parameters
/// - `df` — `DataFrame` ...
/// - `sql` — `str` ...
///
/// # Returns
/// `Result<DataFrame`.
///
/// @param df : DataFrame
/// @param sql : str
/// @return Result<DataFrame
pub fn query_sql(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Execute a SQL query on a Database (supports FROM and JOIN).
///
///
/// # Parameters
/// - `db` — `Database` ...
/// - `sql` — `str` ...
///
/// # Returns
/// `Result<DataFrame`.
///
/// @param db : Database
/// @param sql : str
/// @return Result<DataFrame
pub fn query_sql_database(_lua: &Lua, _args: LuaMultiValue<'_>) -> LuaResult<()> {
    todo!()
}

/// Registers the `luna.dataframe` API table.
///
/// # Parameters
/// - `lua` — `&Lua` The Lua VM.
/// - `luna` — `&LuaTable<'_>` The top-level `luna` table.
/// - `state` — `Rc<RefCell<SharedState>>` Shared engine state.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(
    lua: &Lua,
    luna: &mlua::Table,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set("addColumn", lua.create_function(add_column)?)?;
    tbl.set("removeColumn", lua.create_function(remove_column)?)?;
    tbl.set("renameColumn", lua.create_function(rename_column)?)?;
    tbl.set("addRow", lua.create_function(add_row)?)?;
    tbl.set("removeRow", lua.create_function(remove_row)?)?;
    tbl.set("setValue", lua.create_function(set_value)?)?;
    tbl.set("fromRaw", lua.create_function(from_raw)?)?;
    tbl.set("random", lua.create_function(random)?)?;
    tbl.set("addTable", lua.create_function(add_table)?)?;
    tbl.set("getTableMut", lua.create_function(get_table_mut)?)?;
    tbl.set("removeTable", lua.create_function(remove_table)?)?;
    tbl.set("merge", lua.create_function(merge)?)?;
    tbl.set("join", lua.create_function(join)?)?;
    tbl.set("merge", lua.create_function(merge)?)?;
    tbl.set("fillNil", lua.create_function(fill_nil)?)?;
    tbl.set("fromCsv", lua.create_function(from_csv)?)?;
    tbl.set("fromJson", lua.create_function(from_json)?)?;
    tbl.set("fromBinary", lua.create_function(from_binary)?)?;
    tbl.set("querySql", lua.create_function(query_sql)?)?;
    tbl.set("querySqlDatabase", lua.create_function(query_sql_database)?)?;
    luna.set("dataframe", tbl)?;
    Ok(())
}
