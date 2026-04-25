//! `lurek.dataframe` — Column-major tabular data with query, analytics, and SQL.
//!
//! Exposes `DataFrame` (column-oriented table with filter, sort, group, join, pivot)
//! and `Database` (named collection of DataFrames with SQL query support). Supports
//! CSV/JSON serialization and aggregation functions (sum, mean, min, max, count).

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::dataframe::frame::{AggFn, CellValue, ColRef, DataFrame, Database};
use crate::dataframe::serial;
use crate::dataframe::sql;
use crate::dataframe::vectorized::{BinaryOp, CmpOp, ReduceOp, ScalarOp, VecFrame};

// -------------------------------------------------------------------------------
// Helpers
// -------------------------------------------------------------------------------

/// Convert a Lua value to a [`ColRef`] (column name or 1-based index).
fn lua_to_col_ref(v: LuaValue) -> LuaResult<ColRef> {
    match v {
        LuaValue::String(s) => Ok(ColRef::Name(s.to_str()?.to_string())),
        LuaValue::Integer(i) if i >= 1 => Ok(ColRef::Index(i as usize)),
        LuaValue::Number(n) if n >= 1.0 => Ok(ColRef::Index(n as usize)),
        _ => Err(LuaError::RuntimeError(
            "column must be a string name or 1-based integer".into(),
        )),
    }
}

/// Convert a Lua value to a [`CellValue`].
fn lua_to_cell(v: LuaValue) -> CellValue {
    match v {
        LuaValue::Nil => CellValue::Nil,
        LuaValue::Boolean(b) => CellValue::Bool(b),
        LuaValue::Integer(i) => CellValue::Number(i as f64),
        LuaValue::Number(n) => CellValue::Number(n),
        LuaValue::String(s) => CellValue::Text(s.to_str().unwrap_or("").to_string()),
        _ => CellValue::Nil,
    }
}

/// Convert a [`CellValue`] to a Lua value.
fn cell_to_lua<'lua>(lua: &'lua Lua, cell: &CellValue) -> LuaResult<LuaValue<'lua>> {
    match cell {
        CellValue::Nil => Ok(LuaValue::Nil),
        CellValue::Number(n) => Ok(LuaValue::Number(*n)),
        CellValue::Text(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        CellValue::Bool(b) => Ok(LuaValue::Boolean(*b)),
    }
}

/// Validate a 1-based Lua row index.
fn validate_row(row: usize) -> LuaResult<usize> {
    if row == 0 {
        return Err(LuaError::RuntimeError("row index must be >= 1".into()));
    }
    Ok(row - 1)
}

// ── LuaGroupedFrame ────────────────────────────────────────────────────────────

/// Lua-side wrapper around a grouped result from [`DataFrame::group_by`].
///
/// Supports `aggregate(col, fn)` to apply a Lua callback to each group's values.
pub struct LuaGroupedFrame {
    groups: Vec<(CellValue, DataFrame)>,
}

impl LuaGroupedFrame {
    fn new(groups: Vec<(CellValue, DataFrame)>) -> Self {
        Self { groups }
    }
}

impl LuaUserData for LuaGroupedFrame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- aggregate --
        /// Apply a Lua function to aggregate a column's values per group.
        /// @param col_name : string — column to aggregate
        /// @param fn : function(values: table) → number — receives array of column values, returns aggregate
        /// @return DataFrame — new dataframe with group keys and aggregated values
        methods.add_method(
            "aggregate",
            |lua, this, (col_name, func): (String, LuaFunction)| {
                let mut result = DataFrame::new();
                result
                    .add_column("group_key", CellValue::Nil)
                    .map_err(LuaError::RuntimeError)?;
                result
                    .add_column(&col_name, CellValue::Nil)
                    .map_err(LuaError::RuntimeError)?;
                for (key, sub_df) in &this.groups {
                    let col_ref = ColRef::Name(col_name.clone());
                    let cell_vals = sub_df.get_column(col_ref).map_err(LuaError::RuntimeError)?;
                    let vals_tbl = lua.create_table()?;
                    let mut idx = 0usize;
                    for cv in cell_vals {
                        if let Some(n) = cv.as_number() {
                            idx += 1;
                            vals_tbl.set(idx, n)?;
                        }
                    }
                    let agg: f64 = func.call(vals_tbl)?;
                    result.add_row(&[
                        ("group_key".to_string(), key.clone()),
                        (col_name.clone(), CellValue::Number(agg)),
                    ]);
                }
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- __tostring --
        /// Returns a human-readable string for debugging.
        /// @return string
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GroupedFrame({} groups)", this.groups.len()))
        });
    }
}

// -------------------------------------------------------------------------------
// LuaDataFrame UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a shared [`DataFrame`].
pub struct LuaDataFrame {
    inner: Rc<RefCell<DataFrame>>,
}

impl LuaDataFrame {
    /// Create a new wrapper from an owned [`DataFrame`].
    fn new(df: DataFrame) -> Self {
        Self {
            inner: Rc::new(RefCell::new(df)),
        }
    }
}

impl LuaUserData for LuaDataFrame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- nrows --
        /// Returns the number of rows.
        /// @return integer
        methods.add_method("nrows", |_, this, ()| Ok(this.inner.borrow().nrows()));

        // -- ncols --
        /// Returns the number of columns.
        /// @return integer
        methods.add_method("ncols", |_, this, ()| Ok(this.inner.borrow().ncols()));

        // -- columns --
        /// Returns a table of column names.
        /// @return table
        methods.add_method("columns", |lua, this, ()| {
            let df = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, name) in df.columns().iter().enumerate() {
                tbl.set(i + 1, name.as_str())?;
            }
            Ok(tbl)
        });

        // -- count --
        /// Returns the row count (alias for nrows).
        /// @return integer
        methods.add_method("count", |_, this, ()| Ok(this.inner.borrow().count()));

        // -- addColumn --
        /// Adds a new column with an optional default value.
        /// @param name : string
        /// @param default : LuaValue?
        /// @return nil
        methods.add_method(
            "addColumn",
            |_, this, (name, default): (String, Option<LuaValue>)| {
                let def = default.map(lua_to_cell).unwrap_or(CellValue::Nil);
                this.inner
                    .borrow_mut()
                    .add_column(&name, def)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- removeColumn --
        /// Removes a column by name or index.
        /// @param col : string|integer
        /// @return nil
        methods.add_method("removeColumn", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .remove_column(cr)
                .map_err(LuaError::RuntimeError)
        });

        // -- rename --
        /// Renames the column `old_name` to `new_name` in this DataFrame.
        /// @param col : string|integer
        /// @param new_name : string
        /// @return nil
        methods.add_method("rename", |_, this, (col, new_name): (LuaValue, String)| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .rename_column(cr, &new_name)
                .map_err(LuaError::RuntimeError)
        });

        // -- getColumn --
        /// Returns all values in a column as a table.
        /// @param col : string|integer
        /// @return table
        methods.add_method("getColumn", |lua, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let cells = df.get_column(cr).map_err(LuaError::RuntimeError)?;
            let tbl = lua.create_table()?;
            for (i, cell) in cells.iter().enumerate() {
                tbl.set(i + 1, cell_to_lua(lua, cell)?)?;
            }
            Ok(tbl)
        });

        // -- addRow --
        /// Adds a row from an optional table of name-value pairs, returns 1-based index.
        /// @param row_tbl : table?
        /// @return integer
        methods.add_method("addRow", |_, this, row_tbl: Option<LuaTable>| {
            let values: Vec<(String, CellValue)> = if let Some(tbl) = row_tbl {
                let mut v = Vec::new();
                for pair in tbl.pairs::<String, LuaValue>() {
                    let (key, val) = pair?;
                    v.push((key, lua_to_cell(val)));
                }
                v
            } else {
                Vec::new()
            };
            let row_0 = this.inner.borrow_mut().add_row(&values);
            Ok(row_0 + 1)
        });

        // -- removeRow --
        /// Removes a row by 1-based index.
        /// @param row : integer
        /// @return nil
        methods.add_method("removeRow", |_, this, row: usize| {
            let r = validate_row(row)?;
            this.inner
                .borrow_mut()
                .remove_row(r)
                .map_err(LuaError::RuntimeError)
        });

        // -- getRow --
        /// Returns a row as a table of name-value pairs.
        /// @param row : integer
        /// @return table
        methods.add_method("getRow", |lua, this, row: usize| {
            let r = validate_row(row)?;
            let df = this.inner.borrow();
            let pairs = df.get_row(r).map_err(LuaError::RuntimeError)?;
            let tbl = lua.create_table()?;
            for (name, cell) in &pairs {
                tbl.set(name.as_str(), cell_to_lua(lua, cell)?)?;
            }
            Ok(tbl)
        });

        // -- getValue --
        /// Returns a single cell value.
        /// @param row : integer
        /// @param col : string|integer
        /// @return LuaValue
        methods.add_method("getValue", |lua, this, (row, col): (usize, LuaValue)| {
            let r = validate_row(row)?;
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let cell = df.get_value(r, cr).map_err(LuaError::RuntimeError)?;
            cell_to_lua(lua, &cell)
        });

        // -- setValue --
        /// Sets a single cell value.
        /// @param row : integer
        /// @param col : string|integer
        /// @param val : LuaValue
        /// @return nil
        methods.add_method(
            "setValue",
            |_, this, (row, col, val): (usize, LuaValue, LuaValue)| {
                let r = validate_row(row)?;
                let cr = lua_to_col_ref(col)?;
                let cv = lua_to_cell(val);
                this.inner
                    .borrow_mut()
                    .set_value(r, cr, cv)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- filter --
        /// Filters rows where column matches a condition, returns a new DataFrame.
        /// @param col : string|integer
        /// @param op : string
        /// @param val : LuaValue
        /// @return DataFrame
        methods.add_method(
            "filter",
            |_, this, (col, op, val): (LuaValue, String, LuaValue)| {
                let cr = lua_to_col_ref(col)?;
                let cv = lua_to_cell(val);
                let df = this.inner.borrow();
                let result = df.filter(cr, &op, &cv).map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- sort --
        /// Sorts by column, returns a new DataFrame.
        /// @param col : string|integer
        /// @param ascending : boolean?
        /// @return DataFrame
        methods.add_method(
            "sort",
            |_, this, (col, ascending): (LuaValue, Option<bool>)| {
                let cr = lua_to_col_ref(col)?;
                let df = this.inner.borrow();
                let result = df
                    .sort(cr, ascending.unwrap_or(true))
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- head --
        /// Returns the first n rows (default 5).
        /// @param n : integer?
        /// @return DataFrame
        methods.add_method("head", |_, this, n: Option<usize>| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.head(n.unwrap_or(5))))
        });

        // -- tail --
        /// Returns the last n rows (default 5).
        /// @param n : integer?
        /// @return DataFrame
        methods.add_method("tail", |_, this, n: Option<usize>| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.tail(n.unwrap_or(5))))
        });

        // -- slice --
        /// Returns rows from start to end (1-based, inclusive).
        /// @param start : integer
        /// @param end_idx : integer
        /// @return DataFrame
        methods.add_method("slice", |_, this, (start, end): (usize, usize)| {
            if start == 0 || end == 0 {
                return Err(LuaError::RuntimeError("slice indices must be >= 1".into()));
            }
            let df = this.inner.borrow();
            let result = df
                .slice(start - 1, end - 1)
                .map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        // -- select --
        /// Selects a subset of columns, returns a new DataFrame.
        /// @param cols : string|integer...
        /// @return DataFrame
        methods.add_method("select", |_, this, cols: LuaMultiValue| {
            let col_refs: Vec<ColRef> = cols
                .into_iter()
                .map(lua_to_col_ref)
                .collect::<LuaResult<Vec<_>>>()?;
            let df = this.inner.borrow();
            let result = df
                .select_columns(&col_refs)
                .map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        // -- unique --
        /// Returns unique values in a column as a table.
        /// @param col : string|integer
        /// @return table
        methods.add_method("unique", |lua, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let vals = df.unique(cr).map_err(LuaError::RuntimeError)?;
            let tbl = lua.create_table()?;
            for (i, v) in vals.iter().enumerate() {
                tbl.set(i + 1, cell_to_lua(lua, v)?)?;
            }
            Ok(tbl)
        });

        // -- groupBy --
        /// Groups rows by column value, returns a table of DataFrames keyed by value.
        /// @param col : string|integer
        /// @return table
        methods.add_method("groupBy", |lua, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let groups = df.group_by(cr).map_err(LuaError::RuntimeError)?;
            let tbl = lua.create_table()?;
            for (key, sub_df) in groups {
                let lua_key = cell_to_lua(lua, &key)?;
                tbl.set(lua_key, LuaDataFrame::new(sub_df))?;
            }
            Ok(tbl)
        });

        // -- groupByObj --
        /// Groups rows by column value, returns a GroupedFrame object supporting aggregate().
        /// @param col : string|integer
        /// @return GroupedFrame
        methods.add_method("groupByObj", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let groups = df.group_by(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaGroupedFrame::new(groups))
        });

        // -- join --
        /// Joins with another DataFrame on matching columns.
        /// @param other : DataFrame
        /// @param this_col : string|integer
        /// @param other_col : string|integer
        /// @param join_type : string?
        /// @return DataFrame
        methods.add_method(
            "join",
            |_,
             this,
             (other, this_col, other_col, jtype): (
                LuaAnyUserData,
                LuaValue,
                LuaValue,
                Option<String>,
            )| {
                let other_df = other.borrow::<LuaDataFrame>()?;
                let tc = lua_to_col_ref(this_col)?;
                let oc = lua_to_col_ref(other_col)?;
                let df = this.inner.borrow();
                let other_borrow = other_df.inner.borrow();
                let result = df
                    .join(&other_borrow, tc, oc, jtype.as_deref().unwrap_or("inner"))
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- merge --
        /// Appends rows from another DataFrame in-place.
        /// @param other : DataFrame
        /// @return nil
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_df = other.borrow::<LuaDataFrame>()?;
            let other_borrow = other_df.inner.borrow();
            this.inner.borrow_mut().merge(&other_borrow);
            Ok(())
        });

        // -- countBy --
        /// Counts distinct values in a column, returns a DataFrame with value and count columns.
        /// @param col : string|integer
        /// @return DataFrame
        methods.add_method("countBy", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let result = df.count_by(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        // -- dropNil --
        /// Removes rows where the given column is nil, returns a new DataFrame.
        /// @param col : string|integer
        /// @return DataFrame
        methods.add_method("dropNil", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let result = df.drop_nil(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        // -- sample --
        /// Returns a random sample of n rows.
        /// @param n : integer
        /// @param seed : integer?
        /// @return DataFrame
        methods.add_method("sample", |_, this, (n, seed): (usize, Option<u64>)| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.sample(n, seed)))
        });

        // -- describe --
        /// Returns descriptive statistics for all numeric columns.
        /// @return DataFrame
        methods.add_method("describe", |_, this, ()| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.describe()))
        });

        // -- sum --
        /// Returns the sum of numeric values in a column.
        /// @param col : string|integer
        /// @return number
        methods.add_method("sum", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner.borrow().sum(cr).map_err(LuaError::RuntimeError)
        });

        // -- mean --
        /// Returns the mean of numeric values in a column.
        /// @param col : string|integer
        /// @return number
        methods.add_method("mean", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner.borrow().mean(cr).map_err(LuaError::RuntimeError)
        });

        // -- min --
        /// Returns the minimum numeric value in a column.
        /// @param col : string|integer
        /// @return number
        methods.add_method("min", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .min_val(cr)
                .map_err(LuaError::RuntimeError)
        });

        // -- max --
        /// Returns the maximum numeric value in a column.
        /// @param col : string|integer
        /// @return number
        methods.add_method("max", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .max_val(cr)
                .map_err(LuaError::RuntimeError)
        });

        // -- median --
        /// Returns the median of numeric values in a column.
        /// @param col : string|integer
        /// @return number
        methods.add_method("median", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .median(cr)
                .map_err(LuaError::RuntimeError)
        });

        // -- stddev --
        /// Returns the population standard deviation of numeric values in a column.
        /// @param col : string|integer
        /// @return number
        methods.add_method("stddev", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .stddev(cr)
                .map_err(LuaError::RuntimeError)
        });

        // -- variance --
        /// Returns the population variance of numeric values in a column.
        /// @param col : string|integer
        /// @return number
        methods.add_method("variance", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .variance(cr)
                .map_err(LuaError::RuntimeError)
        });

        // -- fillNil --
        /// Replaces nil values in a column with the given value.
        /// @param col : string|integer
        /// @param val : LuaValue
        /// @return nil
        methods.add_method("fillNil", |_, this, (col, val): (LuaValue, LuaValue)| {
            let cr = lua_to_col_ref(col)?;
            let cv = lua_to_cell(val);
            this.inner
                .borrow_mut()
                .fill_nil(cr, cv)
                .map_err(LuaError::RuntimeError)
        });

        // -- apply --
        /// Applies a function to each value in a column, replacing cells with results.
        /// @param col : string|integer
        /// @param func : function
        /// @return nil
        methods.add_method(
            "apply",
            |lua, this, (col_val, func): (LuaValue, LuaFunction)| {
                let col = lua_to_col_ref(col_val)?;
                let mut df = this.inner.borrow_mut();
                let cells = df.column_data_mut(col).map_err(LuaError::RuntimeError)?;
                for cell in cells.iter_mut() {
                    let lua_val = cell_to_lua(lua, cell)?;
                    let result: LuaValue = func.call(lua_val)?;
                    *cell = lua_to_cell(result);
                }
                Ok(())
            },
        );

        // -- toCSV --
        /// Serializes this DataFrame to a CSV string.
        /// @return string
        methods.add_method("toCSV", |_, this, ()| Ok(this.inner.borrow().to_csv()));

        // -- toJSON --
        /// Serializes this DataFrame to a JSON string.
        /// @return string
        methods.add_method("toJSON", |_, this, ()| Ok(this.inner.borrow().to_json()));

        // -- toBinary --
        /// Serializes this DataFrame to a binary LVDF string.
        /// @return string
        methods.add_method("toBinary", |lua, this, ()| {
            let bytes = this.inner.borrow().to_binary();
            lua.create_string(&bytes)
        });

        // -- toTable --
        /// Converts this DataFrame to a Lua table of row tables.
        /// @return table
        methods.add_method("toTable", |lua, this, ()| {
            let df = this.inner.borrow();
            let tbl = lua.create_table()?;
            let cols = df.columns();
            let data = df.raw_data();
            #[allow(clippy::needless_range_loop)]
            for row in 0..df.nrows() {
                let row_tbl = lua.create_table()?;
                for (ci, name) in cols.iter().enumerate() {
                    row_tbl.set(name.as_str(), cell_to_lua(lua, &data[ci][row])?)?;
                }
                tbl.set(row + 1, row_tbl)?;
            }
            Ok(tbl)
        });

        // -- toString --
        /// Returns a formatted string table representation.
        /// @return string
        methods.add_method("toString", |_, this, ()| {
            Ok(this.inner.borrow().to_string_table())
        });

        // -- query --
        /// Executes a SQL query against this DataFrame.
        /// @param sql_str : string
        /// @return DataFrame
        methods.add_method("query", |_, this, sql_str: String| {
            let df = this.inner.borrow();
            let result = sql::query_sql(&df, &sql_str).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        // -- clone --
        /// Returns a deep copy of this DataFrame.
        /// @return DataFrame
        methods.add_method("clone", |_, this, ()| {
            Ok(LuaDataFrame::new(this.inner.borrow().clone_df()))
        });

        // ── Analytics ──────────────────────────────────────────────────

        // -- withRollingMean --
        /// Add a rolling mean column. Rows with insufficient history get nil.
        /// @param col : string|integer
        /// @param window : integer
        /// @param name : string
        /// @return nil
        methods.add_method_mut(
            "withRollingMean",
            |_, this, (col, window, name): (LuaValue, usize, String)| {
                let col_ref = lua_to_col_ref(col)?;
                this.inner
                    .borrow_mut()
                    .with_rolling_mean(col_ref, window, &name)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- withRollingSum --
        /// Add a rolling sum column.
        /// @param col : string|integer
        /// @param window : integer
        /// @param name : string
        /// @return nil
        methods.add_method_mut(
            "withRollingSum",
            |_, this, (col, window, name): (LuaValue, usize, String)| {
                let col_ref = lua_to_col_ref(col)?;
                this.inner
                    .borrow_mut()
                    .with_rolling_sum(col_ref, window, &name)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- withRollingMin --
        /// Add a rolling minimum column.
        /// @param col : string|integer
        /// @param window : integer
        /// @param name : string
        /// @return nil
        methods.add_method_mut(
            "withRollingMin",
            |_, this, (col, window, name): (LuaValue, usize, String)| {
                let col_ref = lua_to_col_ref(col)?;
                this.inner
                    .borrow_mut()
                    .with_rolling_min(col_ref, window, &name)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- withRollingMax --
        /// Add a rolling maximum column.
        /// @param col : string|integer
        /// @param window : integer
        /// @param name : string
        /// @return nil
        methods.add_method_mut(
            "withRollingMax",
            |_, this, (col, window, name): (LuaValue, usize, String)| {
                let col_ref = lua_to_col_ref(col)?;
                this.inner
                    .borrow_mut()
                    .with_rolling_max(col_ref, window, &name)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- withRank --
        /// Add a rank column (1-based, ties averaged).
        /// @param col : string|integer
        /// @param ascending : boolean?
        /// @param name : string
        /// @return nil
        methods.add_method_mut(
            "withRank",
            |_, this, (col, asc, name): (LuaValue, Option<bool>, String)| {
                let col_ref = lua_to_col_ref(col)?;
                this.inner
                    .borrow_mut()
                    .with_rank(col_ref, asc.unwrap_or(true), &name)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- withPctChange --
        /// Add a percent-change-from-previous-row column.
        /// @param col : string|integer
        /// @param name : string
        /// @return nil
        methods.add_method_mut(
            "withPctChange",
            |_, this, (col, name): (LuaValue, String)| {
                let col_ref = lua_to_col_ref(col)?;
                this.inner
                    .borrow_mut()
                    .with_pct_change(col_ref, &name)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- withCumsum --
        /// Add a cumulative-sum column.
        /// @param col : string|integer
        /// @param name : string
        /// @return nil
        methods.add_method_mut("withCumsum", |_, this, (col, name): (LuaValue, String)| {
            let col_ref = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .with_cumsum(col_ref, &name)
                .map_err(LuaError::RuntimeError)
        });

        // -- groupAgg --
        /// Aggregate agg_col grouped by group_col using the named function.
        /// fn_name: "mean"|"sum"|"min"|"max"|"count"|"first"|"last"
        /// @param group_col : string|integer
        /// @param agg_col : string|integer
        /// @param fn_name : string
        /// @return DataFrame
        methods.add_method(
            "groupAgg",
            |_, this, (group_col, agg_col, fn_name): (LuaValue, LuaValue, String)| {
                let gc = lua_to_col_ref(group_col)?;
                let ac = lua_to_col_ref(agg_col)?;
                let agg_fn = AggFn::parse(&fn_name).map_err(LuaError::RuntimeError)?;
                let result = this
                    .inner
                    .borrow()
                    .group_agg(gc, ac, agg_fn)
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- pivot --
        /// Creates a wide pivot table by reshaping rows into columns.
        ///
        /// Groups rows by `row_col`, uses distinct values of `col_col` as new column
        /// headers, and fills cells with values from `val_col`.
        ///
        /// @param row_col : string|integer  Column whose values become row keys.
        /// @param col_col : string|integer  Column whose distinct values become headers.
        /// @param val_col : string|integer  Column to place in the pivot cells.
        /// @return DataFrame
        methods.add_method(
            "pivot",
            |_, this, (row_col, col_col, val_col): (LuaValue, LuaValue, LuaValue)| {
                let rc = lua_to_col_ref(row_col)?;
                let cc = lua_to_col_ref(col_col)?;
                let vc = lua_to_col_ref(val_col)?;
                let result = this
                    .inner
                    .borrow()
                    .pivot(rc, cc, vc)
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- corr --
        /// Pearson correlation coefficient between two numeric columns.
        /// @param col_a : string|integer
        /// @param col_b : string|integer
        /// @return number
        methods.add_method("corr", |_, this, (col_a, col_b): (LuaValue, LuaValue)| {
            let ca = lua_to_col_ref(col_a)?;
            let cb = lua_to_col_ref(col_b)?;
            this.inner
                .borrow()
                .corr(ca, cb)
                .map_err(LuaError::RuntimeError)
        });

        // -- correlationMatrix --
        /// Compute a correlation matrix for all numeric columns.
        /// @return DataFrame
        methods.add_method("correlationMatrix", |_, this, ()| {
            let result = this.inner.borrow().correlation_matrix();
            Ok(LuaDataFrame::new(result))
        });

        // -- zscoreCol --
        /// Add a z-score column for the given numeric column.
        /// @param col : string|integer
        /// @param name : string
        /// @return nil
        methods.add_method_mut("zscoreCol", |_, this, (col, name): (LuaValue, String)| {
            let col_ref = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .zscore_col(col_ref, &name)
                .map_err(LuaError::RuntimeError)
        });

        // -- normalizeCol --
        /// Add a min-max normalized column scaled to [out_min, out_max].
        /// @param col : string|integer
        /// @param out_min : number
        /// @param out_max : number
        /// @param name : string
        /// @return nil
        methods.add_method_mut(
            "normalizeCol",
            |_, this, (col, out_min, out_max, name): (LuaValue, f64, f64, String)| {
                let col_ref = lua_to_col_ref(col)?;
                this.inner
                    .borrow_mut()
                    .normalize_col(col_ref, out_min, out_max, &name)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- outliers --
        /// Return a new DataFrame with only outlier rows (|z-score| > threshold).
        /// @param col : string|integer
        /// @param threshold : number?
        /// @return DataFrame
        methods.add_method(
            "outliers",
            |_, this, (col, threshold): (LuaValue, Option<f64>)| {
                let col_ref = lua_to_col_ref(col)?;
                let result = this
                    .inner
                    .borrow()
                    .outliers(col_ref, threshold.unwrap_or(2.0))
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- modeVal --
        /// Return the most frequent value in a column (nil if empty).
        /// @param col : string|integer
        /// @return table|nil
        methods.add_method("modeVal", |lua, this, col: LuaValue| {
            let col_ref = lua_to_col_ref(col)?;
            let val = this
                .inner
                .borrow()
                .mode_val(col_ref)
                .map_err(LuaError::RuntimeError)?;
            cell_to_lua(lua, &val)
        });

        // -- entropy --
        /// Shannon entropy (bits) of the value distribution in a column.
        /// @param col : string|integer
        /// @return number
        methods.add_method("entropy", |_, this, col: LuaValue| {
            let col_ref = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .entropy(col_ref)
                .map_err(LuaError::RuntimeError)
        });

        // -- addRowBatch --
        /// Add multiple rows at once from a table of row tables.
        /// @param rows : table
        /// @return nil
        methods.add_method_mut("addRowBatch", |_, this, rows: LuaTable| {
            let nc = this.inner.borrow().ncols();
            let mut batch: Vec<Vec<CellValue>> = Vec::new();
            for pair in rows.sequence_values::<LuaTable>() {
                let row_tbl = pair?;
                let mut row: Vec<CellValue> = Vec::with_capacity(nc);
                for i in 1..=nc {
                    let v: LuaValue = row_tbl.get(i)?;
                    row.push(lua_to_cell(v));
                }
                batch.push(row);
            }
            this.inner
                .borrow_mut()
                .add_row_batch(batch)
                .map_err(LuaError::RuntimeError)
        });

        // -- getColumnAsF64 --
        /// Return a numeric column as a Lua array of numbers (nils → 0/nan).
        /// @param col : string|integer
        /// @return table
        methods.add_method("getColumnAsF64", |lua, this, col: LuaValue| {
            let col_ref = lua_to_col_ref(col)?;
            let vals = this
                .inner
                .borrow()
                .get_column_as_f64(col_ref)
                .map_err(LuaError::RuntimeError)?;
            let t = lua.create_table_with_capacity(vals.len(), 0)?;
            for (i, v) in vals.iter().enumerate() {
                t.set(i + 1, *v)?;
            }
            Ok(t)
        });

        // -- setColumnFromF64 --
        /// Set a numeric column from a Lua array of numbers.
        /// @param col : string|integer
        /// @param values : table
        /// @return nil
        methods.add_method_mut(
            "setColumnFromF64",
            |_, this, (col, values): (LuaValue, LuaTable)| {
                let col_ref = lua_to_col_ref(col)?;
                let mut vals: Vec<f64> = Vec::new();
                for pair in values.sequence_values::<f64>() {
                    vals.push(pair?);
                }
                this.inner
                    .borrow_mut()
                    .set_column_from_f64(col_ref, vals)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("DataFrame"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "DataFrame" || name == "Object")
        });

        // -- withEval --
        /// Returns a new DataFrame with an additional computed column named `col_name`.
        ///
        /// `expr` is a simple arithmetic expression referencing existing column names and
        /// numeric literals, supporting `+`, `-`, `*`, `/`.  For example:
        /// `"health + bonus * 0.5"` or `"speed - friction"`.
        ///
        /// Non-numeric cell values in referenced columns are treated as `0.0`.
        ///
        /// # Usage
        /// ```lua
        /// local df2 = df:withEval("total", "attack + bonus * 1.5")
        /// ```
        /// @param col_name : string
        /// @param expr : string
        /// @return DataFrame
        methods.add_method(
            "withEval",
            |lua, this, (col_name, expr): (String, String)| {
                let result = this
                    .inner
                    .borrow()
                    .with_eval(&col_name, &expr)
                    .map_err(LuaError::RuntimeError)?;
                lua.create_userdata(LuaDataFrame::new(result))
            },
        );

        // -- pivotTable --
        /// Reshapes a long-format DataFrame into wide format.
        ///
        /// Groups rows by `row_key`, creates one column per unique `col_key` value,
        /// and aggregates `value_key` cells using `agg` ("mean", "sum", "count",
        /// "first", or "last"). Missing combinations become `nil`.
        ///
        /// # Usage
        /// ```lua
        /// local wide = df:pivotTable("region", "product", "sales", "sum")
        /// ```
        /// @param row_key : string|integer
        /// @param col_key : string|integer
        /// @param value_key : string|integer
        /// @param agg : string?
        /// @return DataFrame
        methods.add_method(
            "pivotTable",
            |_,
             this,
             (row_key, col_key, value_key, agg): (
                LuaValue,
                LuaValue,
                LuaValue,
                Option<String>,
            )| {
                let rk = lua_to_col_ref(row_key)?;
                let ck = lua_to_col_ref(col_key)?;
                let vk = lua_to_col_ref(value_key)?;
                let agg_str = agg.as_deref().unwrap_or("mean");
                let df = this.inner.borrow();
                let result = df
                    .pivot_table(rk, ck, vk, agg_str)
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- rollingMean --
        /// Returns a new DataFrame with a rolling mean column appended.
        ///
        /// Each row value is the mean of the current and up to `window - 1`
        /// preceding rows. Partial windows at the start use available data.
        /// Non-numeric cells are skipped; all-non-numeric windows produce `nil`.
        ///
        /// # Usage
        /// ```lua
        /// local df2 = df:rollingMean("price", 3, "price_ma3")
        /// ```
        /// @param col : string|integer
        /// @param window : integer
        /// @param result_col : string?
        /// @return DataFrame
        methods.add_method(
            "rollingMean",
            |_, this, (col, window, result_col): (LuaValue, usize, Option<String>)| {
                let cr = lua_to_col_ref(col)?;
                let out_name = result_col.unwrap_or_else(|| "rolling_mean".to_string());
                let df = this.inner.borrow();
                let result = df
                    .rolling_mean(cr, window, &out_name)
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- rollingSum --
        /// Returns a new DataFrame with a rolling sum column appended.
        ///
        /// Each row value is the sum of the current and up to `window - 1`
        /// preceding rows. Partial windows at the start use available data.
        /// Non-numeric cells contribute 0; all-non-numeric windows produce `nil`.
        ///
        /// # Usage
        /// ```lua
        /// local df2 = df:rollingSum("score", 5, "score_rs5")
        /// ```
        /// @param col : string|integer
        /// @param window : integer
        /// @param result_col : string?
        /// @return DataFrame
        methods.add_method(
            "rollingSum",
            |_, this, (col, window, result_col): (LuaValue, usize, Option<String>)| {
                let cr = lua_to_col_ref(col)?;
                let out_name = result_col.unwrap_or_else(|| "rolling_sum".to_string());
                let df = this.inner.borrow();
                let result = df
                    .rolling_sum(cr, window, &out_name)
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        // -- rank --
        /// Returns a new DataFrame with a dense-rank column appended.
        ///
        /// Assigns 1-based ranks ordered by `col`. Tied values share the same rank
        /// (dense ranking, no gaps). Non-numeric cells receive rank 0.
        ///
        /// # Usage
        /// ```lua
        /// local df2 = df:rank("score", "desc", "rank")
        /// ```
        /// @param col : string|integer
        /// @param order : string?
        /// @param result_col : string?
        /// @return DataFrame
        methods.add_method(
            "rank",
            |_, this, (col, order, result_col): (LuaValue, Option<String>, Option<String>)| {
                let cr = lua_to_col_ref(col)?;
                let ord = order.as_deref().unwrap_or("asc");
                let out_name = result_col.unwrap_or_else(|| "rank".to_string());
                let df = this.inner.borrow();
                let result = df
                    .rank_column(cr, ord, &out_name)
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );
    }
}

// -------------------------------------------------------------------------------
// LuaDatabase UserData
// -------------------------------------------------------------------------------

/// Lua-side wrapper around a shared [`Database`].
pub struct LuaDatabase {
    inner: Rc<RefCell<Database>>,
}

impl LuaUserData for LuaDatabase {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addTable --
        /// Adds or replaces a table by cloning the given DataFrame.
        /// @param name : string
        /// @param df : DataFrame
        /// @return nil
        methods.add_method(
            "addTable",
            |_, this, (name, df_ud): (String, LuaAnyUserData)| {
                let lua_df = df_ud.borrow::<LuaDataFrame>()?;
                let cloned = lua_df.inner.borrow().clone_df();
                this.inner.borrow_mut().add_table(&name, cloned);
                Ok(())
            },
        );

        // -- getTable --
        /// Returns a copy of a table by name, or nil if not found.
        /// @param name : string
        /// @return DataFrame?
        methods.add_method("getTable", |_, this, name: String| {
            let db = this.inner.borrow();
            match db.get_table(&name) {
                Some(df) => Ok(Some(LuaDataFrame::new(df.clone_df()))),
                None => Ok(None),
            }
        });

        // -- removeTable --
        /// Drops the named table from this in-memory database if it exists.
        /// @param name : string
        /// @return nil
        methods.add_method("removeTable", |_, this, name: String| {
            this.inner
                .borrow_mut()
                .remove_table(&name)
                .map_err(LuaError::RuntimeError)
        });

        // -- hasTable --
        /// Returns true if a table with the given name exists.
        /// @param name : string
        /// @return boolean
        methods.add_method("hasTable", |_, this, name: String| {
            Ok(this.inner.borrow().has_table(&name))
        });

        // -- listTables --
        /// Returns a table of all table names.
        /// @return table
        methods.add_method("listTables", |lua, this, ()| {
            let db = this.inner.borrow();
            let names = db.list_tables();
            let tbl = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                tbl.set(i + 1, name.as_str())?;
            }
            Ok(tbl)
        });

        // -- tableCount --
        /// Returns the number of tables.
        /// @return integer
        methods.add_method("tableCount", |_, this, ()| {
            Ok(this.inner.borrow().table_count())
        });

        // -- clear --
        /// Drops every table from this in-memory database, leaving it empty.
        /// @return nil
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        // -- merge --
        /// Merges all tables from another Database into this one.
        /// @param other : Database
        /// @return nil
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_db = other.borrow::<LuaDatabase>()?;
            let cloned = other_db.inner.borrow().clone_db();
            this.inner.borrow_mut().merge(cloned);
            Ok(())
        });

        // -- toJSON --
        /// Serializes all tables to a JSON object string.
        /// @return string
        methods.add_method("toJSON", |_, this, ()| Ok(this.inner.borrow().to_json()));

        // -- query --
        /// Executes a SQL query against the database tables.
        /// @param sql_str : string
        /// @return DataFrame
        methods.add_method("query", |_, this, sql_str: String| {
            let db = this.inner.borrow();
            let result = sql::query_sql_database(&db, &sql_str).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("Database"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "Database" || name == "Object")
        });
    }
}

// ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ──
// LuaVecFrame
// ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ── ──

/// Thin Lua wrapper around a [`VecFrame`]: typed-column vectorized DataFrame.
#[derive(Clone)]
pub struct LuaVecFrame {
    inner: Rc<RefCell<VecFrame>>,
}

impl LuaVecFrame {
    /// Create from a [`VecFrame`].
    pub fn new(vf: VecFrame) -> Self {
        Self {
            inner: Rc::new(RefCell::new(vf)),
        }
    }
}

impl LuaUserData for LuaVecFrame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // ── Scalar column operations ─────────────────────────────────────

        /// Add a scalar to every element of a Float64 column.
        /// @param col : string
        /// @param val : number
        methods.add_method_mut("colAdd", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Add, val)
                .map_err(LuaError::RuntimeError)
        });

        /// Subtract a scalar from every element of a Float64 column.
        /// @param col : string
        /// @param val : number
        methods.add_method_mut("colSub", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Sub, val)
                .map_err(LuaError::RuntimeError)
        });

        /// Multiply every element of a Float64 column by a scalar.
        /// @param col : string
        /// @param val : number
        methods.add_method_mut("colMul", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Mul, val)
                .map_err(LuaError::RuntimeError)
        });

        /// Divide every element of a Float64 column by a scalar.
        /// @param col : string
        /// @param val : number
        methods.add_method_mut("colDiv", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Div, val)
                .map_err(LuaError::RuntimeError)
        });

        /// Apply absolute value to every element of a Float64 column.
        /// @param col : string
        methods.add_method_mut("colAbs", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Abs, 0.0)
                .map_err(LuaError::RuntimeError)
        });

        /// Apply square root to every element of a Float64 column.
        /// @param col : string
        methods.add_method_mut("colSqrt", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Sqrt, 0.0)
                .map_err(LuaError::RuntimeError)
        });

        /// Apply floor to every element of a Float64 column.
        /// @param col : string
        methods.add_method_mut("colFloor", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Floor, 0.0)
                .map_err(LuaError::RuntimeError)
        });

        /// Apply ceiling to every element of a Float64 column.
        /// @param col : string
        methods.add_method_mut("colCeil", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Ceil, 0.0)
                .map_err(LuaError::RuntimeError)
        });

        /// Negate every element of a Float64 column.
        /// @param col : string
        methods.add_method_mut("colNeg", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Neg, 0.0)
                .map_err(LuaError::RuntimeError)
        });

        /// Clamp every element of a Float64 column to [min, max].
        /// @param col : string
        /// @param min_val : number
        /// @param max_val : number
        methods.add_method_mut(
            "colClamp",
            |_, this, (col, min_val, max_val): (String, f64, f64)| {
                this.inner
                    .borrow_mut()
                    .col_clamp(&col, min_val, max_val)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // ── Binary column operations ─────────────────────────────────────

        /// Compute out[i] = left[i] op right[i] for every row.
        /// op is one of: "add", "sub", "mul", "div", "min", "max".
        /// @param out_col : string
        /// @param left_col : string
        /// @param op : string
        /// @param right_col : string
        methods.add_method_mut(
            "colOp",
            |_, this, (out_col, left_col, op, right_col): (String, String, String, String)| {
                let bop = BinaryOp::parse(&op).map_err(LuaError::RuntimeError)?;
                this.inner
                    .borrow_mut()
                    .col_binary_op(&out_col, &left_col, bop, &right_col)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // ── Reductions ───────────────────────────────────────────────────

        /// Reduce an entire numeric column to a single value.
        /// op is one of: "sum", "mean", "min", "max", "std", "var", "count".
        /// @param col : string
        /// @param op : string
        /// @return number|nil
        methods.add_method("reduce", |_, this, (col, op): (String, String)| {
            let rop = ReduceOp::parse(&op).map_err(LuaError::RuntimeError)?;
            this.inner
                .borrow()
                .col_reduce(&col, rop)
                .map_err(LuaError::RuntimeError)
        });

        // ── Filter / mask ────────────────────────────────────────────────

        /// Build a boolean row mask: mask[i] = col[i] cmp_op val.
        /// cmp_op is one of: "<", "<=", ">", ">=", "==", "!=".
        /// @param col : string
        /// @param cmp_op : string
        /// @param val : number
        /// @return table  -- array of booleans
        methods.add_method(
            "filterMask",
            |lua, this, (col, cmp_op, val): (String, String, f64)| {
                let op = CmpOp::parse(&cmp_op).map_err(LuaError::RuntimeError)?;
                let mask = this
                    .inner
                    .borrow()
                    .filter_mask(&col, op, val)
                    .map_err(LuaError::RuntimeError)?;
                let tbl = lua.create_table()?;
                for (i, b) in mask.iter().enumerate() {
                    tbl.set(i + 1, *b)?;
                }
                Ok(tbl)
            },
        );

        /// Return a new VecFrame containing only the rows where mask[i] is true.
        /// @param mask : table  -- array of booleans (from filterMask)
        /// @return VecFrame
        methods.add_method("applyMask", |_, this, mask_tbl: LuaTable| {
            let len = mask_tbl.len()? as usize;
            let mut mask = Vec::with_capacity(len);
            for i in 1..=len {
                let b: bool = mask_tbl.get(i)?;
                mask.push(b);
            }
            let vf = this
                .inner
                .borrow()
                .apply_mask(&mask)
                .map_err(LuaError::RuntimeError)?;
            Ok(LuaVecFrame::new(vf))
        });

        // ── Type / cast ──────────────────────────────────────────────────

        /// Return the dtype name of a column: "float64", "int64", "bool", or "text".
        /// @param col : string
        /// @return string|nil
        methods.add_method("colType", |_, this, col: String| {
            Ok(this.inner.borrow().col_type(&col).map(|s| s.to_string()))
        });

        /// Cast a column to a new dtype: "float64", "int64", or "text".
        /// @param col : string
        /// @param dtype : string
        methods.add_method_mut("colCast", |_, this, (col, dtype): (String, String)| {
            this.inner
                .borrow_mut()
                .col_cast(&col, &dtype)
                .map_err(LuaError::RuntimeError)
        });

        // ── Shape ────────────────────────────────────────────────────────

        /// Return the number of rows.
        /// @return integer
        methods.add_method("nrows", |_, this, ()| Ok(this.inner.borrow().nrows()));

        /// Return the number of columns.
        /// @return integer
        methods.add_method("ncols", |_, this, ()| Ok(this.inner.borrow().ncols()));

        /// Return a table of column names.
        /// @return table
        methods.add_method("columns", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, name) in this.inner.borrow().columns().iter().enumerate() {
                tbl.set(i + 1, name.clone())?;
            }
            Ok(tbl)
        });

        // ── Parallel operations ──────────────────────────────────────────

        /// Reduce multiple columns in parallel, returning {col → value} table.
        /// op is one of: "sum", "mean", "min", "max", "std", "var", "count".
        /// @param cols : table  -- array of column name strings
        /// @param op : string
        /// @return table
        methods.add_method(
            "parReduce",
            |lua, this, (cols_tbl, op): (LuaTable, String)| {
                let rop = ReduceOp::parse(&op).map_err(LuaError::RuntimeError)?;
                let len = cols_tbl.len()? as usize;
                let cols: Vec<String> = (1..=len)
                    .map(|i| {
                        let s: String = cols_tbl.get(i)?;
                        LuaResult::Ok(s)
                    })
                    .collect::<LuaResult<_>>()?;
                let col_refs: Vec<&str> = cols.iter().map(|s| s.as_str()).collect();
                let results = this.inner.borrow().par_reduce(&col_refs, rop);
                let out = lua.create_table()?;
                for (k, v) in results {
                    match v {
                        Some(n) => out.set(k, n)?,
                        None => out.set(k, LuaValue::Nil)?,
                    }
                }
                Ok(out)
            },
        );

        /// Apply a scalar op in parallel to multiple Float64 columns.
        /// op is one of: "add", "sub", "mul", "div", "abs", "sqrt", "floor", "ceil", "neg".
        /// @param cols : table  -- array of column name strings
        /// @param op : string
        /// @param val : number
        methods.add_method_mut(
            "parScalarOp",
            |_, this, (cols_tbl, op, val): (LuaTable, String, f64)| {
                let sop = ScalarOp::parse(&op).map_err(LuaError::RuntimeError)?;
                let len = cols_tbl.len()? as usize;
                let cols: Vec<String> = (1..=len)
                    .map(|i| {
                        let s: String = cols_tbl.get(i)?;
                        LuaResult::Ok(s)
                    })
                    .collect::<LuaResult<_>>()?;
                let col_refs: Vec<&str> = cols.iter().map(|s| s.as_str()).collect();
                this.inner
                    .borrow_mut()
                    .par_scalar_op(&col_refs, sop, val)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // ── Conversion ───────────────────────────────────────────────────

        /// Convert this VecFrame back to a DataFrame.
        /// @return DataFrame
        methods.add_method("toDataFrame", |_, this, ()| {
            Ok(LuaDataFrame::new(this.inner.borrow().to_dataframe()))
        });

        // ── Type helpers ─────────────────────────────────────────────────

        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("VecFrame"));

        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "VecFrame" || name == "Object")
        });
    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `lurek.dataframe` API table with the Lua VM.
///
/// @param lua : &Lua
/// @param luna : &LuaTable
/// @param _state : Rc<RefCell<SharedState>>
///
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;

    // -- newDataFrame --
    /// Creates a new empty DataFrame.
    /// @return DataFrame
    tbl.set(
        "newDataFrame",
        lua.create_function(|_, ()| Ok(LuaDataFrame::new(DataFrame::new())))?,
    )?;

    // -- newDatabase --
    /// Creates a new empty Database.
    /// @return Database
    tbl.set(
        "newDatabase",
        lua.create_function(|_, ()| {
            Ok(LuaDatabase {
                inner: Rc::new(RefCell::new(Database::new())),
            })
        })?,
    )?;

    // -- fromTable --
    /// Creates a DataFrame from an array of row tables.
    /// @param rows : table
    /// @return DataFrame
    tbl.set(
        "fromTable",
        lua.create_function(|_, rows: LuaTable| {
            let mut df = DataFrame::new();
            let len = rows.len()?;
            for i in 1..=len {
                let row: LuaTable = rows.get(i)?;
                if i == 1 {
                    for pair in row.clone().pairs::<String, LuaValue>() {
                        let (key, _) = pair?;
                        df.add_column(&key, CellValue::Nil)
                            .map_err(LuaError::RuntimeError)?;
                    }
                }
                let mut values = Vec::new();
                for pair in row.pairs::<String, LuaValue>() {
                    let (key, val) = pair?;
                    values.push((key, lua_to_cell(val)));
                }
                df.add_row(&values);
            }
            Ok(LuaDataFrame::new(df))
        })?,
    )?;

    // -- fromCSV --
    /// Parses a CSV string into a DataFrame.
    /// @param s : string
    /// @return DataFrame
    tbl.set(
        "fromCSV",
        lua.create_function(|_, s: String| {
            let df = serial::from_csv(&s).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;

    // -- fromJSON --
    /// Parses a JSON string into a DataFrame.
    /// @param s : string
    /// @return DataFrame
    tbl.set(
        "fromJSON",
        lua.create_function(|_, s: String| {
            let df = serial::from_json(&s).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;

    // -- fromBinary --
    /// Deserializes a binary LVDF string into a DataFrame.
    /// @param s : string
    /// @return DataFrame
    tbl.set(
        "fromBinary",
        lua.create_function(|_, s: LuaString| {
            let df = serial::from_binary(s.as_bytes()).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;

    // -- random --
    /// Generates a DataFrame with random data from column definitions.
    /// @param defs : table
    /// @param n : integer
    /// @param seed : integer?
    /// @return DataFrame
    tbl.set(
        "random",
        lua.create_function(|_, (defs_tbl, n, seed): (LuaTable, usize, Option<u64>)| {
            let mut defs = Vec::new();
            for i in 1..=defs_tbl.len()? {
                let pair: LuaTable = defs_tbl.get(i)?;
                let name: String = pair.get(1)?;
                let hint: String = pair.get(2)?;
                defs.push((name, hint));
            }
            Ok(LuaDataFrame::new(DataFrame::random(&defs, n, seed)))
        })?,
    )?;

    // -- toVec --
    /// Converts a DataFrame to a VecFrame for vectorized column operations.
    /// @param df : DataFrame
    /// @return VecFrame
    tbl.set(
        "toVec",
        lua.create_function(|_, df: LuaAnyUserData| {
            let lua_df = df.borrow::<LuaDataFrame>()?;
            let vf = VecFrame::from_dataframe(&lua_df.inner.borrow());
            Ok(LuaVecFrame::new(vf))
        })?,
    )?;

    // -- fromVec --
    /// Converts a VecFrame back to a DataFrame.
    /// @param vf : VecFrame
    /// @return DataFrame
    tbl.set(
        "fromVec",
        lua.create_function(|_, vf: LuaAnyUserData| {
            let lua_vf = vf.borrow::<LuaVecFrame>()?;
            let df = lua_vf.inner.borrow().to_dataframe();
            Ok(LuaDataFrame::new(df))
        })?,
    )?;

    luna.set("dataframe", tbl)?;
    Ok(())
}
