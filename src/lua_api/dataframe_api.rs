//! `lurek.dataframe` -- DataFrame bindings for tabular rows, columns, grouping, joins, SQL queries, lazy pipelines, databases, vectorized frames, serialization, and statistics.

use super::SharedState;
use crate::dataframe::frame::{AggFn, CellValue, ColRef, DataFrame, Database};
use crate::dataframe::lazy::LazyQuery;
use crate::dataframe::serial;
use crate::dataframe::sql;
use crate::dataframe::vectorized::{BinaryOp, CmpOp, ReduceOp, ScalarOp, VecFrame};
use mlua::prelude::*;
use std::cell::{Cell, RefCell};
use std::rc::Rc;
/// Converts a Lua column name or one-based index into a column reference.
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
/// Converts a Lua scalar value into a dataframe cell value.
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
/// Converts a dataframe cell value into a Lua value.
fn cell_to_lua<'lua>(lua: &'lua Lua, cell: &CellValue) -> LuaResult<LuaValue<'lua>> {
    match cell {
        CellValue::Nil => Ok(LuaValue::Nil),
        CellValue::Number(n) => Ok(LuaValue::Number(*n)),
        CellValue::Text(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        CellValue::Bool(b) => Ok(LuaValue::Boolean(*b)),
    }
}
/// Converts a one-based Lua row index into a zero-based dataframe row index.
fn validate_row(row: usize) -> LuaResult<usize> {
    if row == 0 {
        return Err(LuaError::RuntimeError("row index must be >= 1".into()));
    }
    Ok(row - 1)
}
/// Lua-side grouped dataframe object containing group keys and subframes.
pub struct LuaGroupedFrame {
    /// Group key and dataframe pairs created by `groupByObj`.
    groups: Vec<(CellValue, DataFrame)>,
}
impl LuaGroupedFrame {
    /// Creates a grouped frame wrapper from precomputed groups.
    fn new(groups: Vec<(CellValue, DataFrame)>) -> Self {
        Self { groups }
    }
}
impl LuaUserData for LuaGroupedFrame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- aggregate --
        /// Aggregates one numeric column in every group by calling a Lua function with that group's numeric values.
        /// @param | col_name | string | Column name to aggregate in each group.
        /// @param | func | function | Function called with an array table of numeric values and returning a number.
        /// @return | LDataFrame | DataFrame containing `group_key` and the aggregated column.
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
        methods.add_meta_method(LuaMetaMethod::ToString, |_, this, ()| {
            Ok(format!("GroupedFrame({} groups)", this.groups.len()))
        });
        // -- type --
        /// Returns the Lua-visible type name for this grouped frame handle.
        /// @return | string | The string `LGroupedFrame`.
        methods.add_method("type", |_, _, ()| Ok("LGroupedFrame"));
        // -- typeOf --
        /// Returns whether this grouped frame handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LGroupedFrame` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGroupedFrame" || name == "Object")
        });
    }
}
/// Lua-side dataframe handle for tabular data with named columns and typed cells.
pub struct LuaDataFrame {
    /// Shared dataframe storage exposed through this userdata handle.
    inner: Rc<RefCell<DataFrame>>,
}
impl LuaDataFrame {
    /// Wraps a dataframe in shared Lua userdata state.
    fn new(df: DataFrame) -> Self {
        Self {
            inner: Rc::new(RefCell::new(df)),
        }
    }
}
impl LuaUserData for LuaDataFrame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- nrows --
        /// Returns the number of rows in this dataframe.
        /// @return | integer | Row count.
        methods.add_method("nrows", |_, this, ()| Ok(this.inner.borrow().nrows()));
        // -- ncols --
        /// Returns the number of columns in this dataframe.
        /// @return | integer | Column count.
        methods.add_method("ncols", |_, this, ()| Ok(this.inner.borrow().ncols()));
        // -- columns --
        /// Returns all column names in order.
        /// @return | table | Array table of column names.
        methods.add_method("columns", |lua, this, ()| {
            let df = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, name) in df.columns().iter().enumerate() {
                tbl.set(i + 1, name.as_str())?;
            }
            Ok(tbl)
        });
        // -- count --
        /// Returns the row count for this dataframe.
        /// @return | integer | Row count.
        methods.add_method("count", |_, this, ()| Ok(this.inner.borrow().count()));
        // -- addColumn --
        /// Adds a column with an optional default value.
        /// @param | name | string | Column name to create.
        /// @param | default | LuaValue? | Default cell value for existing rows; nil uses empty cells.
        /// @return | nil | No value is returned.
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
        /// Removes a column by name or one-based index.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | nil | No value is returned.
        methods.add_method("removeColumn", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .remove_column(cr)
                .map_err(LuaError::RuntimeError)
        });
        // -- rename --
        /// Renames a column by name or one-based index.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @param | new_name | string | New column name.
        /// @return | nil | No value is returned.
        methods.add_method("rename", |_, this, (col, new_name): (LuaValue, String)| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .rename_column(cr, &new_name)
                .map_err(LuaError::RuntimeError)
        });
        // -- getColumn --
        /// Returns a column as an array table.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | table | Array table of column values.
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
        /// Adds a row from an optional map table and returns its one-based row index.
        /// @param | row_tbl | table? | Optional table mapping column names to cell values.
        /// @return | integer | One-based index of the inserted row.
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
        /// Removes a row by one-based index.
        /// @param | row | integer | One-based row index to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeRow", |_, this, row: usize| {
            let r = validate_row(row)?;
            this.inner
                .borrow_mut()
                .remove_row(r)
                .map_err(LuaError::RuntimeError)
        });
        // -- getRow --
        /// Returns a row as a table keyed by column name.
        /// @param | row | integer | One-based row index to read.
        /// @return | table | Row table keyed by column name.
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
        /// Returns one cell value by one-based row and column reference.
        /// @param | row | integer | One-based row index.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | LuaValue | Cell value at the requested row and column.
        methods.add_method("getValue", |lua, this, (row, col): (usize, LuaValue)| {
            let r = validate_row(row)?;
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let cell = df.get_value(r, cr).map_err(LuaError::RuntimeError)?;
            cell_to_lua(lua, &cell)
        });
        // -- setValue --
        /// Sets one cell value by one-based row and column reference.
        /// @param | row | integer | One-based row index.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @param | val | LuaValue | Cell value to store.
        /// @return | nil | No value is returned.
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
        /// Returns rows whose column value matches a comparison.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @param | op | string | Comparison operator string.
        /// @param | val | LuaValue | Cell value used as the comparison target.
        /// @return | LDataFrame | New filtered dataframe.
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
        /// Returns rows sorted by a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @param | ascending | boolean? | True for ascending order; defaults to true.
        /// @return | LDataFrame | New sorted dataframe.
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
        /// Returns the first rows of this dataframe.
        /// @param | n | integer? | Number of rows to return; defaults to 5.
        /// @return | LDataFrame | New dataframe containing the first rows.
        methods.add_method("head", |_, this, n: Option<usize>| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.head(n.unwrap_or(5))))
        });
        // -- tail --
        /// Returns the last rows of this dataframe.
        /// @param | n | integer? | Number of rows to return; defaults to 5.
        /// @return | LDataFrame | New dataframe containing the last rows.
        methods.add_method("tail", |_, this, n: Option<usize>| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.tail(n.unwrap_or(5))))
        });
        // -- slice --
        /// Returns a one-based inclusive row slice.
        /// @param | start | integer | One-based start row.
        /// @param | end | integer | One-based end row.
        /// @return | LDataFrame | New dataframe containing the row slice.
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
        /// Returns a dataframe with selected columns.
        /// @param | ... | LuaValue | Column name strings or one-based column indices to keep.
        /// @return | LDataFrame | New dataframe containing selected columns.
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
        /// Returns unique values from a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | table | Array table of unique values.
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
        /// Groups rows by a column and returns a table from group key to dataframe.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | table | Table keyed by group values with dataframe handles as values.
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
        /// Groups rows by a column and returns a grouped-frame object.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | LGroupedFrame | Grouped frame handle.
        methods.add_method("groupByObj", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let groups = df.group_by(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaGroupedFrame::new(groups))
        });
        // -- join --
        /// Joins this dataframe with another dataframe by column references.
        /// @param | other | LDataFrame | Other dataframe to join.
        /// @param | this_col | LuaValue | Column reference in this dataframe.
        /// @param | other_col | LuaValue | Column reference in the other dataframe.
        /// @param | jtype | string? | Join type string; defaults to `inner`.
        /// @return | LDataFrame | New joined dataframe.
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
        /// Appends another dataframe into this dataframe in place.
        /// @param | other | LDataFrame | Dataframe whose rows are merged into this dataframe.
        /// @return | nil | No value is returned.
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_df = other.borrow::<LuaDataFrame>()?;
            let other_borrow = other_df.inner.borrow();
            this.inner.borrow_mut().merge(&other_borrow);
            Ok(())
        });
        // -- countBy --
        /// Counts occurrences of each value in a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | LDataFrame | New dataframe containing value counts.
        methods.add_method("countBy", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let result = df.count_by(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });
        // -- dropNil --
        /// Returns rows where the chosen column is not nil.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | LDataFrame | New dataframe without nil rows for the column.
        methods.add_method("dropNil", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let result = df.drop_nil(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });
        // -- sample --
        /// Returns a sampled dataframe.
        /// @param | n | integer | Number of rows to sample.
        /// @param | seed | integer? | Optional random seed.
        /// @return | LDataFrame | New sampled dataframe.
        methods.add_method("sample", |_, this, (n, seed): (usize, Option<u64>)| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.sample(n, seed)))
        });
        // -- describe --
        /// Returns summary statistics for numeric columns.
        /// @return | LDataFrame | New dataframe containing descriptive statistics.
        methods.add_method("describe", |_, this, ()| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.describe()))
        });
        // -- sum --
        /// Returns the numeric sum of a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | number | Column sum.
        methods.add_method("sum", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner.borrow().sum(cr).map_err(LuaError::RuntimeError)
        });
        // -- mean --
        /// Returns the numeric mean of a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | number | Column mean.
        methods.add_method("mean", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner.borrow().mean(cr).map_err(LuaError::RuntimeError)
        });
        // -- min --
        /// Returns the minimum value of a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | LuaValue | Minimum cell value.
        methods.add_method("min", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .min_val(cr)
                .map_err(LuaError::RuntimeError)
        });
        // -- max --
        /// Returns the maximum value of a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | LuaValue | Maximum cell value.
        methods.add_method("max", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .max_val(cr)
                .map_err(LuaError::RuntimeError)
        });
        // -- median --
        /// Returns the numeric median of a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | number | Column median.
        methods.add_method("median", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .median(cr)
                .map_err(LuaError::RuntimeError)
        });
        // -- stddev --
        /// Returns the numeric standard deviation of a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | number | Column standard deviation.
        methods.add_method("stddev", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .stddev(cr)
                .map_err(LuaError::RuntimeError)
        });
        // -- variance --
        /// Returns the numeric variance of a column.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @return | number | Column variance.
        methods.add_method("variance", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .variance(cr)
                .map_err(LuaError::RuntimeError)
        });
        // -- fillNil --
        /// Replaces nil cells in a column with a value.
        /// @param | col | LuaValue | Column name string or one-based column index.
        /// @param | val | LuaValue | Replacement cell value.
        /// @return | nil | No value is returned.
        methods.add_method("fillNil", |_, this, (col, val): (LuaValue, LuaValue)| {
            let cr = lua_to_col_ref(col)?;
            let cv = lua_to_cell(val);
            this.inner
                .borrow_mut()
                .fill_nil(cr, cv)
                .map_err(LuaError::RuntimeError)
        });
        // -- apply --
        /// Applies a Lua function to each value in a column in place.
        /// @param | col_val | LuaValue | Column name string or one-based column index.
        /// @param | func | function | Function called with each cell value and returning a replacement value.
        /// @return | nil | No value is returned.
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
        /// Serializes this dataframe to CSV text.
        /// @return | string | CSV text.
        methods.add_method("toCSV", |_, this, ()| Ok(this.inner.borrow().to_csv()));
        // -- toJSON --
        /// Serializes this dataframe to JSON text.
        /// @return | string | JSON text.
        methods.add_method("toJSON", |_, this, ()| Ok(this.inner.borrow().to_json()));
        // -- toBinary --
        /// Serializes this dataframe to binary data.
        /// @return | string | Binary string containing serialized dataframe data.
        methods.add_method("toBinary", |lua, this, ()| {
            let bytes = this.inner.borrow().to_binary();
            lua.create_string(&bytes)
        });
        // -- toTable --
        /// Converts this dataframe to an array table of row tables.
        /// @return | table | Array table of rows keyed by column name.
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
        // -- rows --
        /// Returns an iterator function over one-based row index and row table pairs.
        /// @return | function | Iterator function for Lua generic-for loops.
        methods.add_method("rows", |lua, this, ()| {
            let df_ref = Rc::clone(&this.inner);
            let idx_ref = Rc::new(Cell::new(0usize));
            let iter_idx = Rc::clone(&idx_ref);
            lua.create_function_mut(move |lua, (_state, _last): (LuaValue, LuaValue)| {
                let row = iter_idx.get();
                let df = df_ref.borrow();
                if row >= df.nrows() {
                    return Ok((LuaValue::Nil, LuaValue::Nil));
                }
                let row_tbl = lua.create_table()?;
                let cols = df.columns();
                let data = df.raw_data();
                for (ci, name) in cols.iter().enumerate() {
                    row_tbl.set(name.as_str(), cell_to_lua(lua, &data[ci][row])?)?;
                }
                iter_idx.set(row + 1);
                Ok((
                    LuaValue::Integer((row + 1) as i64),
                    LuaValue::Table(row_tbl),
                ))
            })
        });
        // -- toString --
        /// Formats this dataframe as a human-readable text table.
        /// @return | string | Text table representation.
        methods.add_method("toString", |_, this, ()| {
            Ok(this.inner.borrow().to_string_table())
        });
        // -- query --
        /// Runs a SQL-style query against this dataframe.
        /// @param | sql_str | string | SQL query text.
        /// @return | LDataFrame | Query result dataframe.
        methods.add_method("query", |_, this, sql_str: String| {
            let df = this.inner.borrow();
            let result = sql::query_sql(&df, &sql_str).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });
        // -- clone --
        /// Returns a deep copy of this dataframe.
        /// @return | LDataFrame | New dataframe containing copied data.
        methods.add_method("clone", |_, this, ()| {
            Ok(LuaDataFrame::new(this.inner.borrow().clone_df()))
        });
        // -- withRollingMean --
        /// Adds a rolling mean column in place.
        /// @param | col | LuaValue | Source column reference.
        /// @param | window | integer | Rolling window size.
        /// @param | name | string | Output column name.
        /// @return | nil | No value is returned.
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
        /// Adds a rolling sum column in place.
        /// @param | col | LuaValue | Source column reference.
        /// @param | window | integer | Rolling window size.
        /// @param | name | string | Output column name.
        /// @return | nil | No value is returned.
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
        /// Adds a rolling minimum column in place.
        /// @param | col | LuaValue | Source column reference.
        /// @param | window | integer | Rolling window size.
        /// @param | name | string | Output column name.
        /// @return | nil | No value is returned.
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
        /// Adds a rolling maximum column in place.
        /// @param | col | LuaValue | Source column reference.
        /// @param | window | integer | Rolling window size.
        /// @param | name | string | Output column name.
        /// @return | nil | No value is returned.
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
        /// Adds a rank column in place.
        /// @param | col | LuaValue | Source column reference.
        /// @param | asc | boolean? | True for ascending rank; defaults to true.
        /// @param | name | string | Output column name.
        /// @return | nil | No value is returned.
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
        /// Adds a percent-change column in place.
        /// @param | col | LuaValue | Source column reference.
        /// @param | name | string | Output column name.
        /// @return | nil | No value is returned.
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
        /// Adds a cumulative-sum column in place.
        /// @param | col | LuaValue | Source column reference.
        /// @param | name | string | Output column name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("withCumsum", |_, this, (col, name): (LuaValue, String)| {
            let col_ref = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .with_cumsum(col_ref, &name)
                .map_err(LuaError::RuntimeError)
        });
        // -- groupAgg --
        /// Groups by one column and aggregates another column.
        /// @param | group_col | LuaValue | Grouping column reference.
        /// @param | agg_col | LuaValue | Aggregated column reference.
        /// @param | fn_name | string | Aggregate function name.
        /// @return | LDataFrame | New grouped aggregate dataframe.
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
        /// Pivots rows into columns using row, column, and value fields.
        /// @param | row_col | LuaValue | Row key column reference.
        /// @param | col_col | LuaValue | Column key column reference.
        /// @param | val_col | LuaValue | Value column reference.
        /// @return | LDataFrame | New pivoted dataframe.
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
        /// Returns correlation between two numeric columns.
        /// @param | col_a | LuaValue | First column reference.
        /// @param | col_b | LuaValue | Second column reference.
        /// @return | number | Correlation value.
        methods.add_method("corr", |_, this, (col_a, col_b): (LuaValue, LuaValue)| {
            let ca = lua_to_col_ref(col_a)?;
            let cb = lua_to_col_ref(col_b)?;
            this.inner
                .borrow()
                .corr(ca, cb)
                .map_err(LuaError::RuntimeError)
        });
        // -- correlationMatrix --
        /// Returns a correlation matrix for numeric columns.
        /// @return | LDataFrame | Correlation matrix dataframe.
        methods.add_method("correlationMatrix", |_, this, ()| {
            let result = this.inner.borrow().correlation_matrix();
            Ok(LuaDataFrame::new(result))
        });
        // -- zscoreCol --
        /// Adds a z-score normalized column in place.
        /// @param | col | LuaValue | Source column reference.
        /// @param | name | string | Output column name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("zscoreCol", |_, this, (col, name): (LuaValue, String)| {
            let col_ref = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .zscore_col(col_ref, &name)
                .map_err(LuaError::RuntimeError)
        });
        // -- normalizeCol --
        /// Adds a range-normalized column in place.
        /// @param | col | LuaValue | Source column reference.
        /// @param | out_min | number | Output lower bound.
        /// @param | out_max | number | Output upper bound.
        /// @param | name | string | Output column name.
        /// @return | nil | No value is returned.
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
        /// Returns rows considered outliers for a numeric column.
        /// @param | col | LuaValue | Source column reference.
        /// @param | threshold | number? | Z-score threshold; defaults to 2.0.
        /// @return | LDataFrame | New dataframe containing outlier rows.
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
        /// Returns the mode value of a column.
        /// @param | col | LuaValue | Column reference.
        /// @return | LuaValue | Most common cell value.
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
        /// Returns entropy for a column.
        /// @param | col | LuaValue | Column reference.
        /// @return | number | Entropy value.
        methods.add_method("entropy", |_, this, col: LuaValue| {
            let col_ref = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .entropy(col_ref)
                .map_err(LuaError::RuntimeError)
        });
        // -- addRowBatch --
        /// Appends multiple rows from array-style row tables.
        /// @param | rows | table | Array of row arrays matching the dataframe column order.
        /// @return | nil | No value is returned.
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
        /// Returns a numeric column as an array of numbers.
        /// @param | col | LuaValue | Column reference.
        /// @return | table | Array table of numeric values.
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
        /// Replaces a numeric column from an array table of numbers.
        /// @param | col | LuaValue | Column reference.
        /// @param | values | table | Array table of numeric values.
        /// @return | nil | No value is returned.
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
        /// Returns the Lua-visible type name for this dataframe handle.
        /// @return | string | The string `LDataFrame`.
        methods.add_method("type", |_, _, ()| Ok("LDataFrame"));
        // -- typeOf --
        /// Returns whether this dataframe handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LDataFrame`, `DataFrame`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDataFrame" || name == "DataFrame" || name == "Object")
        });
        // -- withEval --
        /// Returns a dataframe with a column computed from an expression.
        /// @param | col_name | string | Output column name.
        /// @param | expr | string | Dataframe expression evaluated by the dataframe module.
        /// @return | LDataFrame | New dataframe with the evaluated column.
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
        /// Builds a pivot table using row key, column key, value column, and aggregate function.
        /// @param | row_key | LuaValue | Row key column reference.
        /// @param | col_key | LuaValue | Column key column reference.
        /// @param | value_key | LuaValue | Value column reference.
        /// @param | agg | string? | Aggregate function name; defaults to `mean`.
        /// @return | LDataFrame | New pivot table dataframe.
        methods.add_method("pivotTable", |_,
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
        /// Returns a dataframe with a rolling mean column.
        /// @param | col | LuaValue | Source column reference.
        /// @param | window | integer | Rolling window size.
        /// @param | result_col | string? | Output column name; defaults to `rolling_mean`.
        /// @return | LDataFrame | New dataframe with the rolling mean column.
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
        /// Returns a dataframe with a rolling sum column.
        /// @param | col | LuaValue | Source column reference.
        /// @param | window | integer | Rolling window size.
        /// @param | result_col | string? | Output column name; defaults to `rolling_sum`.
        /// @return | LDataFrame | New dataframe with the rolling sum column.
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
        /// Returns a dataframe with a rank column.
        /// @param | col | LuaValue | Source column reference.
        /// @param | order | string? | Rank order string; defaults to `asc`.
        /// @param | result_col | string? | Output column name; defaults to `rank`.
        /// @return | LDataFrame | New dataframe with the rank column.
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
        // -- lazy --
        /// Starts a lazy query pipeline from this dataframe.
        /// @return | LLazyQuery | New lazy query handle.
        methods.add_method("lazy", |_, this, ()| {
            let lq = this.inner.borrow().lazy();
            Ok(LuaLazyQuery { inner: lq })
        });
    }
}
/// Lua-side lazy dataframe query pipeline.
pub struct LuaLazyQuery {
    /// Owned lazy query plan that is consumed by chaining methods.
    inner: LazyQuery,
}
impl LuaUserData for LuaLazyQuery {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- filter --
        /// Adds a filter step to the lazy query.
        /// @param | col | string | Column name to filter.
        /// @param | op | string | Comparison operator string.
        /// @param | val | LuaValue | Filter comparison value.
        /// @return | LLazyQuery | New lazy query handle with the filter step.
        methods.add_method_mut(
            "filter",
            |_, this, (col, op, val): (String, String, LuaValue)| {
                let cell = lua_to_cell(val);
                let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
                Ok(LuaLazyQuery {
                    inner: old.filter(&col, &op, cell),
                })
            },
        );
        // -- sort --
        /// Adds a sort step to the lazy query.
        /// @param | col | string | Column name to sort by.
        /// @param | ascending | boolean? | True for ascending order; defaults to true.
        /// @return | LLazyQuery | New lazy query handle with the sort step.
        methods.add_method_mut(
            "sort",
            |_, this, (col, ascending): (String, Option<bool>)| {
                let asc = ascending.unwrap_or(true);
                let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
                Ok(LuaLazyQuery {
                    inner: old.sort(&col, asc),
                })
            },
        );
        // -- head --
        /// Adds a head limit step to the lazy query.
        /// @param | n | integer | Number of leading rows to keep.
        /// @return | LLazyQuery | New lazy query handle with the head step.
        methods.add_method_mut("head", |_, this, n: usize| {
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery { inner: old.head(n) })
        });
        // -- tail --
        /// Adds a tail limit step to the lazy query.
        /// @param | n | integer | Number of trailing rows to keep.
        /// @return | LLazyQuery | New lazy query handle with the tail step.
        methods.add_method_mut("tail", |_, this, n: usize| {
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery { inner: old.tail(n) })
        });
        // -- limit --
        /// Adds a row limit step to the lazy query.
        /// @param | n | integer | Maximum number of rows to keep.
        /// @return | LLazyQuery | New lazy query handle with the limit step.
        methods.add_method_mut("limit", |_, this, n: usize| {
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery {
                inner: old.limit(n),
            })
        });
        // -- slice --
        /// Adds a one-based row slice step to the lazy query.
        /// @param | start | integer | One-based start row.
        /// @param | end | integer | One-based end row.
        /// @return | LLazyQuery | New lazy query handle with the slice step.
        methods.add_method_mut("slice", |_, this, (start, end): (usize, usize)| {
            let s = start.saturating_sub(1);
            let e = end.saturating_sub(1);
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery {
                inner: old.slice(s, e),
            })
        });
        // -- dropNil --
        /// Adds a step that drops rows with nil values in a column.
        /// @param | col | string | Column name to test for nil values.
        /// @return | LLazyQuery | New lazy query handle with the drop-nil step.
        methods.add_method_mut("dropNil", |_, this, col: String| {
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery {
                inner: old.drop_nil(&col),
            })
        });
        // -- select --
        /// Adds a column selection step to the lazy query.
        /// @param | cols | table | Array table of column names to keep.
        /// @return | LLazyQuery | New lazy query handle with the select step.
        methods.add_method_mut("select", |_, this, cols: LuaTable| {
            let mut names: Vec<String> = Vec::new();
            for i in 1..=cols.len()? {
                names.push(cols.get(i)?);
            }
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery {
                inner: old.select(names),
            })
        });
        // -- collect --
        /// Executes the lazy query and returns a dataframe.
        /// @return | LDataFrame | Dataframe produced by the query plan.
        methods.add_method_mut("collect", |_, this, ()| {
            let lq = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            let df = lq.collect().map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        });
        // -- type --
        /// Returns the Lua-visible type name for this lazy query handle.
        /// @return | string | The string `LLazyQuery`.
        methods.add_method("type", |_, _, ()| Ok("LLazyQuery"));
        // -- typeOf --
        /// Returns whether this lazy query handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LLazyQuery`, `LazyQuery`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLazyQuery" || name == "LazyQuery" || name == "Object")
        });
    }
}
/// Lua-side in-memory database containing named dataframes.
pub struct LuaDatabase {
    /// Shared database storage exposed through this userdata handle.
    inner: Rc<RefCell<Database>>,
}
impl LuaUserData for LuaDatabase {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- addTable --
        /// Adds or replaces a named dataframe table in the database.
        /// @param | name | string | Table name.
        /// @param | df_ud | LDataFrame | Dataframe handle copied into the database.
        /// @return | nil | No value is returned.
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
        /// Returns a copy of a named table when it exists.
        /// @param | name | string | Table name to retrieve.
        /// @return | LuaValue | Dataframe handle, or nil when no table has that name.
        methods.add_method("getTable", |_, this, name: String| {
            let db = this.inner.borrow();
            match db.get_table(&name) {
                Some(df) => Ok(Some(LuaDataFrame::new(df.clone_df()))),
                None => Ok(None),
            }
        });
        // -- removeTable --
        /// Removes a named table from the database.
        /// @param | name | string | Table name to remove.
        /// @return | nil | No value is returned.
        methods.add_method("removeTable", |_, this, name: String| {
            this.inner
                .borrow_mut()
                .remove_table(&name)
                .map_err(LuaError::RuntimeError)
        });
        // -- hasTable --
        /// Returns whether a named table exists.
        /// @param | name | string | Table name to check.
        /// @return | boolean | True when the table exists.
        methods.add_method("hasTable", |_, this, name: String| {
            Ok(this.inner.borrow().has_table(&name))
        });
        // -- listTables --
        /// Returns all table names in the database.
        /// @return | table | Array table of table names.
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
        /// Returns the number of tables in the database.
        /// @return | integer | Table count.
        methods.add_method("tableCount", |_, this, ()| {
            Ok(this.inner.borrow().table_count())
        });
        // -- clear --
        /// Removes every table from the database.
        /// @return | nil | No value is returned.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        // -- merge --
        /// Merges another database into this database.
        /// @param | other | LDatabase | Database copied into this database.
        /// @return | nil | No value is returned.
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_db = other.borrow::<LuaDatabase>()?;
            let cloned = other_db.inner.borrow().clone_db();
            this.inner.borrow_mut().merge(cloned);
            Ok(())
        });
        // -- toJSON --
        /// Serializes the database to JSON text.
        /// @return | string | JSON text.
        methods.add_method("toJSON", |_, this, ()| Ok(this.inner.borrow().to_json()));
        // -- query --
        /// Runs a SQL-style query against the database tables.
        /// @param | sql_str | string | SQL query text.
        /// @return | LDataFrame | Query result dataframe.
        methods.add_method("query", |_, this, sql_str: String| {
            let db = this.inner.borrow();
            let result = sql::query_sql_database(&db, &sql_str).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });
        // -- type --
        /// Returns the Lua-visible type name for this database handle.
        /// @return | string | The string `LDatabase`.
        methods.add_method("type", |_, _, ()| Ok("LDatabase"));
        // -- typeOf --
        /// Returns whether this database handle matches a supported type name.
        /// @param | name | string | Type name to compare against `LDatabase`, `Database`, and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDatabase" || name == "Database" || name == "Object")
        });
    }
}
/// Lua-side vectorized dataframe handle for numeric column operations.
#[derive(Clone)]
pub struct LuaVecFrame {
    /// Shared vectorized frame storage exposed through this userdata handle.
    inner: Rc<RefCell<VecFrame>>,
}
impl LuaVecFrame {
    /// Wraps a vectorized frame in shared Lua userdata state.
    pub fn new(vf: VecFrame) -> Self {
        Self {
            inner: Rc::new(RefCell::new(vf)),
        }
    }
}
impl LuaUserData for LuaVecFrame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        // -- colAdd --
        /// Adds a scalar to a numeric column in place.
        /// @param | col | string | Column name.
        /// @param | val | number | Scalar value to add.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colAdd", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Add, val)
                .map_err(LuaError::RuntimeError)
        });
        // -- colSub --
        /// Subtracts a scalar from a numeric column in place.
        /// @param | col | string | Column name.
        /// @param | val | number | Scalar value to subtract.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colSub", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Sub, val)
                .map_err(LuaError::RuntimeError)
        });
        // -- colMul --
        /// Multiplies a numeric column by a scalar in place.
        /// @param | col | string | Column name.
        /// @param | val | number | Scalar multiplier.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colMul", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Mul, val)
                .map_err(LuaError::RuntimeError)
        });
        // -- colDiv --
        /// Divides a numeric column by a scalar in place.
        /// @param | col | string | Column name.
        /// @param | val | number | Scalar divisor.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colDiv", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Div, val)
                .map_err(LuaError::RuntimeError)
        });
        // -- colAbs --
        /// Applies absolute value to a numeric column in place.
        /// @param | col | string | Column name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colAbs", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Abs, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        // -- colSqrt --
        /// Applies square root to a numeric column in place.
        /// @param | col | string | Column name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colSqrt", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Sqrt, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        // -- colFloor --
        /// Applies floor to a numeric column in place.
        /// @param | col | string | Column name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colFloor", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Floor, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        // -- colCeil --
        /// Applies ceil to a numeric column in place.
        /// @param | col | string | Column name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colCeil", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Ceil, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        // -- colNeg --
        /// Negates a numeric column in place.
        /// @param | col | string | Column name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colNeg", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Neg, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        // -- colClamp --
        /// Clamps a numeric column in place.
        /// @param | col | string | Column name.
        /// @param | min_val | number | Minimum allowed value.
        /// @param | max_val | number | Maximum allowed value.
        /// @return | nil | No value is returned.
        methods.add_method_mut(
            "colClamp",
            |_, this, (col, min_val, max_val): (String, f64, f64)| {
                this.inner
                    .borrow_mut()
                    .col_clamp(&col, min_val, max_val)
                    .map_err(LuaError::RuntimeError)
            },
        );
        // -- colOp --
        /// Applies a binary column operation into an output column.
        /// @param | out_col | string | Output column name.
        /// @param | left_col | string | Left input column name.
        /// @param | op | string | Binary operation name.
        /// @param | right_col | string | Right input column name.
        /// @return | nil | No value is returned.
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
        // -- reduce --
        /// Reduces a numeric column with a named operation.
        /// @param | col | string | Column name.
        /// @param | op | string | Reduction operation name.
        /// @return | number | Reduction result.
        methods.add_method("reduce", |_, this, (col, op): (String, String)| {
            let rop = ReduceOp::parse(&op).map_err(LuaError::RuntimeError)?;
            this.inner
                .borrow()
                .col_reduce(&col, rop)
                .map_err(LuaError::RuntimeError)
        });
        // -- filterMask --
        /// Builds a boolean mask for a numeric column comparison.
        /// @param | col | string | Column name.
        /// @param | cmp_op | string | Comparison operation name.
        /// @param | val | number | Comparison value.
        /// @return | table | Array table of boolean mask values.
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
        // -- applyMask --
        /// Returns a vectorized frame filtered by a boolean mask table.
        /// @param | mask_tbl | table | Array table of booleans, one per row.
        /// @return | LVecFrame | New vectorized frame containing masked rows.
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
        // -- colType --
        /// Returns the data type name for a vectorized column.
        /// @param | col | string | Column name.
        /// @return | LuaValue | Column type name, or nil when the column is missing.
        methods.add_method("colType", |_, this, col: String| {
            Ok(this.inner.borrow().col_type(&col).map(|s| s.to_string()))
        });
        // -- colCast --
        /// Casts a vectorized column to another data type in place.
        /// @param | col | string | Column name.
        /// @param | dtype | string | Target data type name.
        /// @return | nil | No value is returned.
        methods.add_method_mut("colCast", |_, this, (col, dtype): (String, String)| {
            this.inner
                .borrow_mut()
                .col_cast(&col, &dtype)
                .map_err(LuaError::RuntimeError)
        });
        // -- nrows --
        /// Returns the number of rows in this vectorized frame.
        /// @return | integer | Row count.
        methods.add_method("nrows", |_, this, ()| Ok(this.inner.borrow().nrows()));
        // -- ncols --
        /// Returns the number of columns in this vectorized frame.
        /// @return | integer | Column count.
        methods.add_method("ncols", |_, this, ()| Ok(this.inner.borrow().ncols()));
        // -- columns --
        /// Returns all vectorized column names in order.
        /// @return | table | Array table of column names.
        methods.add_method("columns", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, name) in this.inner.borrow().columns().iter().enumerate() {
                tbl.set(i + 1, name.clone())?;
            }
            Ok(tbl)
        });
        // -- parReduce --
        /// Reduces multiple numeric columns in parallel.
        /// @param | cols_tbl | table | Array table of column names.
        /// @param | op | string | Reduction operation name.
        /// @return | table | Table mapping column names to reduction results or nil.
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
        // -- parScalarOp --
        /// Applies a scalar operation to multiple numeric columns in parallel.
        /// @param | cols_tbl | table | Array table of column names.
        /// @param | op | string | Scalar operation name.
        /// @param | val | number | Scalar value used by the operation.
        /// @return | nil | No value is returned.
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
        // -- toDataFrame --
        /// Converts this vectorized frame to a dataframe.
        /// @return | LDataFrame | New dataframe handle.
        methods.add_method("toDataFrame", |_, this, ()| {
            Ok(LuaDataFrame::new(this.inner.borrow().to_dataframe()))
        });
        // -- type --
        /// Returns the Lua-visible type name for this vectorized frame handle.
        /// @return | string | The string `LVecFrame`.
        methods.add_method("type", |_, _, ()| Ok("LVecFrame"));
        // -- typeOf --
        /// Returns whether this vectorized frame handle matches a supported type name.
        /// @param | name | string | Type name to compare against `VecFrame` and `Object`.
        /// @return | boolean | True when the supplied type name matches this handle.
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "VecFrame" || name == "Object")
        });
    }
}
/// Registers the `lurek.dataframe` API table with the Lua VM.
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    // -- newDataFrame --
    /// Creates an empty dataframe.
    /// @return | LDataFrame | New empty dataframe handle.
    tbl.set(
        "newDataFrame",
        lua.create_function(|_, ()| Ok(LuaDataFrame::new(DataFrame::new())))?,
    )?;
    // -- newDatabase --
    /// Creates an empty dataframe database.
    /// @return | LDatabase | New database handle.
    tbl.set(
        "newDatabase",
        lua.create_function(|_, ()| {
            Ok(LuaDatabase {
                inner: Rc::new(RefCell::new(Database::new())),
            })
        })?,
    )?;
    // -- fromTable --
    /// Creates a dataframe from an array table of row tables.
    /// @param | rows | table | Array of row tables keyed by column name.
    /// @return | LDataFrame | New dataframe handle.
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
    // -- fromRows --
    /// Creates a dataframe from column names and array-style rows.
    /// @param | columns_tbl | table | Array table of column names.
    /// @param | rows_tbl | table | Array table of row arrays.
    /// @return | LDataFrame | New dataframe handle.
    tbl.set(
        "fromRows",
        lua.create_function(|_, (columns_tbl, rows_tbl): (LuaTable, LuaTable)| {
            let mut columns: Vec<String> = Vec::new();
            for name in columns_tbl.sequence_values::<String>() {
                columns.push(name?);
            }
            let mut rows: Vec<Vec<CellValue>> = Vec::new();
            for row_value in rows_tbl.sequence_values::<LuaTable>() {
                let row_tbl = row_value?;
                let mut row_cells: Vec<CellValue> = Vec::new();
                for cell_value in row_tbl.sequence_values::<LuaValue>() {
                    row_cells.push(lua_to_cell(cell_value?));
                }
                rows.push(row_cells);
            }
            let df = DataFrame::from_rows(columns, rows).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;
    // -- fromCSV --
    /// Parses a dataframe from CSV text.
    /// @param | s | string | CSV text.
    /// @return | LDataFrame | New dataframe handle.
    tbl.set(
        "fromCSV",
        lua.create_function(|_, s: String| {
            let df = serial::from_csv(&s).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;
    // -- fromJSON --
    /// Parses a dataframe from JSON text.
    /// @param | s | string | JSON text.
    /// @return | LDataFrame | New dataframe handle.
    tbl.set(
        "fromJSON",
        lua.create_function(|_, s: String| {
            let df = serial::from_json(&s).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;
    // -- fromBinary --
    /// Parses a dataframe from binary data.
    /// @param | s | string | Binary dataframe payload.
    /// @return | LDataFrame | New dataframe handle.
    tbl.set(
        "fromBinary",
        lua.create_function(|_, s: LuaString| {
            let df = serial::from_binary(s.as_bytes()).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;
    // -- random --
    /// Creates a random dataframe from column definitions.
    /// @param | defs_tbl | table | Array table of `{name, hint}` column definitions.
    /// @param | n | integer | Number of rows to generate.
    /// @param | seed | integer? | Optional random seed.
    /// @return | LDataFrame | New random dataframe handle.
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
    /// Converts a dataframe to a vectorized frame.
    /// @param | df | LDataFrame | Dataframe handle to convert.
    /// @return | LVecFrame | New vectorized frame handle.
    tbl.set(
        "toVec",
        lua.create_function(|_, df: LuaAnyUserData| {
            let lua_df = df.borrow::<LuaDataFrame>()?;
            let vf = VecFrame::from_dataframe(&lua_df.inner.borrow());
            Ok(LuaVecFrame::new(vf))
        })?,
    )?;
    // -- fromVec --
    /// Converts a vectorized frame to a dataframe.
    /// @param | vf | LVecFrame | Vectorized frame handle to convert.
    /// @return | LDataFrame | New dataframe handle.
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
