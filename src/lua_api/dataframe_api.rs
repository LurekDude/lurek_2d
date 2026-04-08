//! `luna.dataframe` — Column-major tabular data with query, analytics, and SQL.

use super::SharedState;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;

use crate::dataframe::frame::{CellValue, ColRef, DataFrame, Database};
use crate::dataframe::serial;
use crate::dataframe::sql;

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
        methods.add_method("nrows", |_, this, ()| {
            Ok(this.inner.borrow().nrows())
        });

        // -- ncols --
        /// Returns the number of columns.
        /// @return integer
        methods.add_method("ncols", |_, this, ()| {
            Ok(this.inner.borrow().ncols())
        });

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
        methods.add_method("count", |_, this, ()| {
            Ok(this.inner.borrow().count())
        });

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
        /// Renames a column.
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
                    .join(
                        &other_borrow,
                        tc,
                        oc,
                        jtype.as_deref().unwrap_or("inner"),
                    )
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
        methods.add_method("toCSV", |_, this, ()| {
            Ok(this.inner.borrow().to_csv())
        });

        // -- toJSON --
        /// Serializes this DataFrame to a JSON string.
        /// @return string
        methods.add_method("toJSON", |_, this, ()| {
            Ok(this.inner.borrow().to_json())
        });

        // -- toBinary --
        /// Serializes this DataFrame to a binary LVDF string.
        /// @param lua : Lua
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

        // -- type --
        /// Returns the type name of this object.
        /// @return string
        methods.add_method("type", |_, _, ()| Ok("DataFrame"));

        // -- typeOf --
        /// Returns true if this object is of the given type.
        /// @param name : string
        /// @return boolean
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "DataFrame" || name == "Object"));

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
        /// Removes a table by name.
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
        /// Removes all tables.
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
        methods.add_method("toJSON", |_, this, ()| {
            Ok(this.inner.borrow().to_json())
        });

        // -- query --
        /// Executes a SQL query against the database tables.
        /// @param sql_str : string
        /// @return DataFrame
        methods.add_method("query", |_, this, sql_str: String| {
            let db = this.inner.borrow();
            let result =
                sql::query_sql_database(&db, &sql_str).map_err(LuaError::RuntimeError)?;
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
        methods.add_method("typeOf", |_, _, name: String| Ok(name == "Database" || name == "Object"));

    }
}

// -------------------------------------------------------------------------------
// Register
// -------------------------------------------------------------------------------

/// Registers the `luna.dataframe` API table with the Lua VM.
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

    luna.set("dataframe", tbl)?;
    Ok(())
}
