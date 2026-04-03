//! Registers the `luna.dataframe.*` tabular data API.
//!
//! This module is part of Luna2D's `lua_api` subsystem and provides the implementation
//! details for dataframe api-related operations and data management.
//! Primary functions: `register()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use std::cell::RefCell;
use std::rc::Rc;

use mlua::prelude::*;

use crate::dataframe::frame::{CellValue, ColRef, DataFrame, Database};
use crate::dataframe::serial;
use crate::dataframe::sql;
use crate::lua_api::lua_types::{add_type_methods, LunaType};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Convert a Lua value to a [`ColRef`].
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

// ---------------------------------------------------------------------------
// LuaDataFrame
// ---------------------------------------------------------------------------

/// Lua userdata wrapper around a shared [`DataFrame`].
struct LuaDataFrame {
    /// Shared mutable DataFrame.
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

impl LunaType for LuaDataFrame {
    const TYPE_NAME: &'static str = "DataFrame";
    const TYPE_HIERARCHY: &'static [&'static str] = &["DataFrame", "Object"];
}

impl LuaUserData for LuaDataFrame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        // -- Schema ----------------------------------------------------------

        /// Nrows on this DataFrame.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("nrows", |_, this, ()| Ok(this.inner.borrow().nrows()));

        /// Ncols on this DataFrame.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("ncols", |_, this, ()| Ok(this.inner.borrow().ncols()));

        /// Columns on this DataFrame.
        /// @return table
        ///
        /// # Returns
        /// The result.
        methods.add_method("columns", |lua, this, ()| {
            let df = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, name) in df.columns().iter().enumerate() {
                tbl.set(i + 1, name.as_str())?;
            }
            Ok(tbl)
        });

        /// Returns the number of items.
        /// @return integer
        ///
        /// # Parameters
        /// - `name` — `string`.
        /// - `default` — `any` optional.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("count", |_, this, ()| Ok(this.inner.borrow().count()));

        // -- Column operations -----------------------------------------------

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

        /// Removes column from the collection.
        /// @param col : any
        ///
        /// # Parameters
        /// - `col` — `any`.
        methods.add_method("removeColumn", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .remove_column(cr)
                .map_err(LuaError::RuntimeError)
        });

        /// Rename on this DataFrame.
        /// @param col : any
        /// @param new_name : string
        ///
        /// # Parameters
        /// - `col` — `any`.
        /// - `new_name` — `string`.
        methods.add_method("rename", |_, this, (col, new_name): (LuaValue, String)| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .rename_column(cr, &new_name)
                .map_err(LuaError::RuntimeError)
        });

        /// Returns the column.
        /// @param col : any
        /// @return table
        ///
        /// # Parameters
        /// - `col` — `any`.
        ///
        /// # Returns
        /// The current column.
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

        // -- Row operations (1-based Lua → 0-based Rust) ---------------------

        /// Adds row to the collection.
        /// @param row_tbl : table?
        /// @return any
        ///
        /// # Parameters
        /// - `row_tbl` — `table` optional.
        methods.add_method("addRow", |_, this, row_tbl: Option<LuaTable>| {
            let mut df = this.inner.borrow_mut();
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
            let row_0 = df.add_row(&values);
            Ok(row_0 + 1) // return 1-based
        });

        /// Removes row from the collection.
        /// @param row : integer
        ///
        /// # Parameters
        /// - `row` — `integer`.
        methods.add_method("removeRow", |_, this, row: usize| {
            if row == 0 {
                return Err(LuaError::RuntimeError("row index must be >= 1".into()));
            }
            this.inner
                .borrow_mut()
                .remove_row(row - 1)
                .map_err(LuaError::RuntimeError)
        });

        /// Returns the row.
        /// @param row : integer
        /// @return table
        ///
        /// # Parameters
        /// - `row` — `integer`.
        ///
        /// # Returns
        /// The current row.
        methods.add_method("getRow", |lua, this, row: usize| {
            if row == 0 {
                return Err(LuaError::RuntimeError("row index must be >= 1".into()));
            }
            let df = this.inner.borrow();
            let pairs = df.get_row(row - 1).map_err(LuaError::RuntimeError)?;
            let tbl = lua.create_table()?;
            for (name, cell) in &pairs {
                tbl.set(name.as_str(), cell_to_lua(lua, cell)?)?;
            }
            Ok(tbl)
        });

        // -- Cell access (1-based row) ---------------------------------------

        /// Returns the value.
        /// @param row : integer
        /// @param col : any
        ///
        /// # Parameters
        /// - `row` — `integer`.
        /// - `col` — `any`.
        ///
        /// # Returns
        /// The current value.
        methods.add_method("getValue", |lua, this, (row, col): (usize, LuaValue)| {
            if row == 0 {
                return Err(LuaError::RuntimeError("row index must be >= 1".into()));
            }
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let cell = df.get_value(row - 1, cr).map_err(LuaError::RuntimeError)?;
            cell_to_lua(lua, &cell)
        });

        methods.add_method(
            "setValue",
            |_, this, (row, col, val): (usize, LuaValue, LuaValue)| {
                if row == 0 {
                    return Err(LuaError::RuntimeError("row index must be >= 1".into()));
                }
                let cr = lua_to_col_ref(col)?;
                let cv = lua_to_cell(val);
                this.inner
                    .borrow_mut()
                    .set_value(row - 1, cr, cv)
                    .map_err(LuaError::RuntimeError)
            },
        );

        // -- Query methods (return new LuaDataFrame) -------------------------

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

        methods.add_method(
            "sort",
            |_, this, (col, ascending): (LuaValue, Option<bool>)| {
                let cr = lua_to_col_ref(col)?;
                let asc = ascending.unwrap_or(true);
                let df = this.inner.borrow();
                let result = df.sort(cr, asc).map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        /// Head on this DataFrame.
        /// @param n : integer?
        /// @return any
        ///
        /// # Parameters
        /// - `n` — `integer` optional.
        methods.add_method("head", |_, this, n: Option<usize>| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.head(n.unwrap_or(5))))
        });

        /// Tail on this DataFrame.
        /// @param n : integer?
        /// @return any
        ///
        /// # Parameters
        /// - `start` — `integer`.
        /// - `end` — `integer`.
        methods.add_method("tail", |_, this, n: Option<usize>| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.tail(n.unwrap_or(5))))
        });

        /// Slice on this DataFrame.
        /// @param start : integer
        /// @param end : integer
        /// @return any
        ///
        /// # Parameters
        /// - `start` — `integer`.
        /// - `end` — `integer`.
        methods.add_method("slice", |_, this, (start, end): (usize, usize)| {
            // Lua 1-based inclusive → Rust 0-based inclusive
            if start == 0 || end == 0 {
                return Err(LuaError::RuntimeError("slice indices must be >= 1".into()));
            }
            let df = this.inner.borrow();
            let result = df
                .slice(start - 1, end - 1)
                .map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        /// Returns filtered rows or items matching the query.
        /// @param cols : MultiValue
        /// @return any
        ///
        /// # Parameters
        /// - `cols` — `LuaMultiValue`.
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

        /// Unique on this DataFrame.
        /// @param col : any
        /// @return table
        ///
        /// # Parameters
        /// - `col` — `any`.
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

        /// Group by on this DataFrame.
        /// @param col : any
        /// @return table
        ///
        /// # Parameters
        /// - `col` — `any`.
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
                let join_type = jtype.as_deref().unwrap_or("inner");
                let df = this.inner.borrow();
                let other_borrow = other_df.inner.borrow();
                let result = df
                    .join(&other_borrow, tc, oc, join_type)
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );

        /// Merge on this DataFrame.
        /// @param other : DataFrame
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_df = other.borrow::<LuaDataFrame>()?;
            let other_borrow = other_df.inner.borrow();
            this.inner.borrow_mut().merge(&other_borrow);
            Ok(())
        });

        /// Returns the number of by.
        /// @param col : any
        /// @return any
        ///
        /// # Parameters
        /// - `col` — `any`.
        ///
        /// # Returns
        /// `integer`.
        methods.add_method("countBy", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let result = df.count_by(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        /// Drop nil on this DataFrame.
        /// @param col : any
        /// @return any
        ///
        /// # Parameters
        /// - `n` — `integer`.
        /// - `seed` — `integer` optional.
        methods.add_method("dropNil", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let result = df.drop_nil(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        /// Sample on this DataFrame.
        /// @param n : integer
        /// @param seed : integer?
        /// @return any
        ///
        /// # Parameters
        /// - `n` — `integer`.
        /// - `seed` — `integer` optional.
        methods.add_method("sample", |_, this, (n, seed): (usize, Option<u64>)| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.sample(n, seed)))
        });

        /// Describe on this DataFrame.
        /// @return any
        ///
        /// # Parameters
        /// - `col` — `any`.
        methods.add_method("describe", |_, this, ()| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.describe()))
        });

        // -- Analytics (return scalar) ---------------------------------------

        /// Sum on this DataFrame.
        /// @param col : any
        ///
        /// # Parameters
        /// - `col` — `any`.
        methods.add_method("sum", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            df.sum(cr).map_err(LuaError::RuntimeError)
        });

        /// Mean on this DataFrame.
        /// @param col : any
        ///
        /// # Parameters
        /// - `col` — `any`.
        methods.add_method("mean", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            df.mean(cr).map_err(LuaError::RuntimeError)
        });

        /// Min on this DataFrame.
        /// @param col : any
        ///
        /// # Parameters
        /// - `col` — `any`.
        methods.add_method("min", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            df.min_val(cr).map_err(LuaError::RuntimeError)
        });

        /// Max on this DataFrame.
        /// @param col : any
        ///
        /// # Parameters
        /// - `col` — `any`.
        methods.add_method("max", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            df.max_val(cr).map_err(LuaError::RuntimeError)
        });

        /// Median on this DataFrame.
        /// @param col : any
        ///
        /// # Parameters
        /// - `col` — `any`.
        methods.add_method("median", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            df.median(cr).map_err(LuaError::RuntimeError)
        });

        /// Stddev on this DataFrame.
        /// @param col : any
        ///
        /// # Parameters
        /// - `col` — `any`.
        methods.add_method("stddev", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            df.stddev(cr).map_err(LuaError::RuntimeError)
        });

        /// Variance on this DataFrame.
        /// @param col : any
        ///
        /// # Parameters
        /// - `col` — `any`.
        methods.add_method("variance", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            df.variance(cr).map_err(LuaError::RuntimeError)
        });

        // -- Nil handling ----------------------------------------------------

        /// Fill nil on this DataFrame.
        /// @param col : any
        /// @param val : any
        ///
        /// # Parameters
        /// - `col` — `any`.
        /// - `val` — `any`.
        methods.add_method("fillNil", |_, this, (col, val): (LuaValue, LuaValue)| {
            let cr = lua_to_col_ref(col)?;
            let cv = lua_to_cell(val);
            this.inner
                .borrow_mut()
                .fill_nil(cr, cv)
                .map_err(LuaError::RuntimeError)
        });

        // -- Mutation --------------------------------------------------------

        methods.add_method(
            "apply",
            |lua, this, (col_val, func): (LuaValue, LuaFunction)| {
                let col = lua_to_col_ref(col_val)?;
                let mut df = this.inner.borrow_mut();
                let ci = df.resolve_col(col).map_err(LuaError::RuntimeError)?;
                let n = df.nrows();
                for row in 0..n {
                    let cell = &df.data[ci][row];
                    let lua_val = cell_to_lua(lua, cell)?;
                    let result: LuaValue = func.call(lua_val)?;
                    df.data[ci][row] = lua_to_cell(result);
                }
                Ok(())
            },
        );

        // -- Serialization ---------------------------------------------------

        /// To c s v on this DataFrame.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("toCSV", |_, this, ()| {
            let df = this.inner.borrow();
            Ok(df.to_csv())
        });

        /// To j s o n on this DataFrame.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("toJSON", |_, this, ()| {
            let df = this.inner.borrow();
            Ok(df.to_json())
        });

        /// To binary on this DataFrame.
        ///
        /// # Returns
        /// The result.
        methods.add_method("toBinary", |lua, this, ()| {
            let df = this.inner.borrow();
            let bytes = df.to_binary();
            lua.create_string(&bytes)
        });

        #[allow(clippy::needless_range_loop)]
        /// To table on this DataFrame.
        /// @return table
        ///
        /// # Returns
        /// The result.
        methods.add_method("toTable", |lua, this, ()| {
            let df = this.inner.borrow();
            let tbl = lua.create_table()?;
            let cols = df.columns();
            let data = df.raw_data();
            for row in 0..df.nrows() {
                let row_tbl = lua.create_table()?;
                for (ci, name) in cols.iter().enumerate() {
                    row_tbl.set(name.as_str(), cell_to_lua(lua, &data[ci][row])?)?;
                }
                tbl.set(row + 1, row_tbl)?;
            }
            Ok(tbl)
        });

        /// To string on this DataFrame.
        /// @return any
        ///
        /// # Parameters
        /// - `sql_str` — `string`.
        methods.add_method("toString", |_, this, ()| {
            let df = this.inner.borrow();
            Ok(df.to_string_table())
        });

        // -- SQL -------------------------------------------------------------

        /// Runs a query and returns matching results.
        /// @param sql_str : string
        /// @return any
        ///
        /// # Parameters
        /// - `sql_str` — `string`.
        methods.add_method("query", |_, this, sql_str: String| {
            let df = this.inner.borrow();
            let result = sql::query_sql(&df, &sql_str).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });

        // -- Clone -----------------------------------------------------------

        /// Returns a deep copy of this object.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("clone", |_, this, ()| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.clone_df()))
        });
    }
}

// ---------------------------------------------------------------------------
// LuaDatabase
// ---------------------------------------------------------------------------

/// Lua userdata wrapper around a shared [`Database`].
struct LuaDatabase {
    /// Shared mutable Database.
    inner: Rc<RefCell<Database>>,
}

impl LunaType for LuaDatabase {
    const TYPE_NAME: &'static str = "Database";
    const TYPE_HIERARCHY: &'static [&'static str] = &["Database", "Object"];
}

impl LuaUserData for LuaDatabase {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        add_type_methods(methods);

        methods.add_method(
            "addTable",
            |_, this, (name, df_ud): (String, LuaAnyUserData)| {
                let lua_df = df_ud.borrow::<LuaDataFrame>()?;
                let cloned = lua_df.inner.borrow().clone_df();
                this.inner.borrow_mut().add_table(&name, cloned);
                Ok(())
            },
        );

        /// Returns the table.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// The current table.
        methods.add_method("getTable", |_, this, name: String| {
            let db = this.inner.borrow();
            match db.get_table(&name) {
                Some(df) => Ok(Some(LuaDataFrame::new(df.clone_df()))),
                None => Ok(None),
            }
        });

        /// Removes table from the collection.
        /// @param name : string
        ///
        /// # Parameters
        /// - `name` — `string`.
        methods.add_method("removeTable", |_, this, name: String| {
            this.inner
                .borrow_mut()
                .remove_table(&name)
                .map_err(LuaError::RuntimeError)
        });

        /// Returns `true` if table.
        /// @param name : string
        /// @return any
        ///
        /// # Parameters
        /// - `name` — `string`.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasTable", |_, this, name: String| {
            Ok(this.inner.borrow().has_table(&name))
        });

        /// List tables on this Database.
        /// @return table
        ///
        /// # Returns
        /// The result.
        methods.add_method("listTables", |lua, this, ()| {
            let db = this.inner.borrow();
            let names = db.list_tables();
            let tbl = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                tbl.set(i + 1, name.as_str())?;
            }
            Ok(tbl)
        });

        /// Table count on this Database.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("tableCount", |_, this, ()| {
            Ok(this.inner.borrow().table_count())
        });

        /// Removes all entries.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });

        /// Merge on this Database.
        /// @param other : Database
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_db = other.borrow::<LuaDatabase>()?;
            // Build a new Database from the other's tables to pass owned
            let other_borrow = other_db.inner.borrow();
            let names = other_borrow.list_tables();
            let mut temp = Database::new();
            for name in &names {
                if let Some(df) = other_borrow.get_table(name) {
                    temp.add_table(name, df.clone_df());
                }
            }
            drop(other_borrow);
            this.inner.borrow_mut().merge(temp);
            Ok(())
        });

        /// To j s o n on this Database.
        /// @return any
        ///
        /// # Returns
        /// The result.
        methods.add_method("toJSON", |_, this, ()| {
            let db = this.inner.borrow();
            let names = db.list_tables();
            let mut out = String::from("{");
            for (i, name) in names.iter().enumerate() {
                if i > 0 {
                    out.push(',');
                }
                out.push('"');
                out.push_str(name);
                out.push_str("\":");
                if let Some(df) = db.get_table(name) {
                    out.push_str(&df.to_json());
                } else {
                    out.push_str("[]");
                }
            }
            out.push('}');
            Ok(out)
        });

        /// Runs a query and returns matching results.
        /// @param sql_str : string
        /// @return any
        ///
        /// # Parameters
        /// - `sql_str` — `string`.
        methods.add_method("query", |_, this, sql_str: String| {
            let db = this.inner.borrow();
            let result = sql::query_sql_database(&db, &sql_str).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });
    }
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Register the `luna.dataframe` namespace.
///
/// # Parameters
/// - `lua` — `&Lua`.
/// - `luna` — `&LuaTable`.
///
/// # Returns
/// `LuaResult<()>`.
pub fn register(lua: &Lua, luna: &LuaTable) -> LuaResult<()> {
    let df_table = lua.create_table()?;

    // luna.dataframe.newDataFrame()
    /// New data frame.
    ///
    /// @return any
    df_table.set(
        "newDataFrame",
        lua.create_function(|_, ()| Ok(LuaDataFrame::new(DataFrame::new())))?,
    )?;

    // luna.dataframe.newDatabase()
    /// New database.
    ///
    /// @return any
    df_table.set(
        "newDatabase",
        lua.create_function(|_, ()| {
            Ok(LuaDatabase {
                inner: Rc::new(RefCell::new(Database::new())),
            })
        })?,
    )?;

    // luna.dataframe.fromTable(t) — array of row-tables
    /// From table.
    ///
    /// @param tbl : table
    /// @return any
    df_table.set(
        "fromTable",
        lua.create_function(|_, tbl: LuaTable| {
            let mut df = DataFrame::new();
            let len = tbl.len()?;
            for i in 1..=len {
                let row: LuaTable = tbl.get(i)?;
                // First row: discover columns
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

    // luna.dataframe.fromCSV(str)
    /// From csv.
    ///
    /// @param s : string
    /// @return any
    df_table.set(
        "fromCSV",
        lua.create_function(|_, s: String| {
            let df = serial::from_csv(&s).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;

    // luna.dataframe.fromJSON(str)
    /// From json.
    ///
    /// @param s : string
    /// @return any
    df_table.set(
        "fromJSON",
        lua.create_function(|_, s: String| {
            let df = serial::from_json(&s).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;

    // luna.dataframe.fromBinary(str)
    /// From binary.
    ///
    /// @param s : string
    /// @return any
    df_table.set(
        "fromBinary",
        lua.create_function(|_, s: LuaString| {
            let df = serial::from_binary(s.as_bytes()).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;

    // luna.dataframe.random(defs, n, seed?)
    /// Random.
    ///
    /// @param defs_tbl : table
    /// @param n : integer
    /// @param seed : integer?
    /// @return any
    df_table.set(
        "random",
        lua.create_function(|_, (defs_tbl, n, seed): (LuaTable, usize, Option<u64>)| {
            let mut defs = Vec::new();
            for i in 1..=defs_tbl.len()? {
                let pair: LuaTable = defs_tbl.get(i)?;
                let name: String = pair.get(1)?;
                let hint: String = pair.get(2)?;
                defs.push((name, hint));
            }
            let df = DataFrame::random(&defs, n, seed);
            Ok(LuaDataFrame::new(df))
        })?,
    )?;

    /// Dataframe on this Database.
    ///
    /// # Returns
    /// The result.
    luna.set("dataframe", df_table)?;
    Ok(())
}
