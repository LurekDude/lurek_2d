use super::SharedState;
use crate::dataframe::frame::{AggFn, CellValue, ColRef, DataFrame, Database};
use crate::dataframe::lazy::LazyQuery;
use crate::dataframe::serial;
use crate::dataframe::sql;
use crate::dataframe::vectorized::{BinaryOp, CmpOp, ReduceOp, ScalarOp, VecFrame};
use mlua::prelude::*;
use std::cell::{Cell, RefCell};
use std::rc::Rc;
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
fn cell_to_lua<'lua>(lua: &'lua Lua, cell: &CellValue) -> LuaResult<LuaValue<'lua>> {
    match cell {
        CellValue::Nil => Ok(LuaValue::Nil),
        CellValue::Number(n) => Ok(LuaValue::Number(*n)),
        CellValue::Text(s) => Ok(LuaValue::String(lua.create_string(s)?)),
        CellValue::Bool(b) => Ok(LuaValue::Boolean(*b)),
    }
}
fn validate_row(row: usize) -> LuaResult<usize> {
    if row == 0 {
        return Err(LuaError::RuntimeError("row index must be >= 1".into()));
    }
    Ok(row - 1)
}
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
        methods.add_method("type", |_, _, ()| Ok("LGroupedFrame"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LGroupedFrame" || name == "Object")
        });
    }
}
pub struct LuaDataFrame {
    inner: Rc<RefCell<DataFrame>>,
}
impl LuaDataFrame {
    fn new(df: DataFrame) -> Self {
        Self {
            inner: Rc::new(RefCell::new(df)),
        }
    }
}
impl LuaUserData for LuaDataFrame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("nrows", |_, this, ()| Ok(this.inner.borrow().nrows()));
        methods.add_method("ncols", |_, this, ()| Ok(this.inner.borrow().ncols()));
        methods.add_method("columns", |lua, this, ()| {
            let df = this.inner.borrow();
            let tbl = lua.create_table()?;
            for (i, name) in df.columns().iter().enumerate() {
                tbl.set(i + 1, name.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method("count", |_, this, ()| Ok(this.inner.borrow().count()));
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
        methods.add_method("removeColumn", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .remove_column(cr)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("rename", |_, this, (col, new_name): (LuaValue, String)| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .rename_column(cr, &new_name)
                .map_err(LuaError::RuntimeError)
        });
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
        methods.add_method("removeRow", |_, this, row: usize| {
            let r = validate_row(row)?;
            this.inner
                .borrow_mut()
                .remove_row(r)
                .map_err(LuaError::RuntimeError)
        });
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
        methods.add_method("getValue", |lua, this, (row, col): (usize, LuaValue)| {
            let r = validate_row(row)?;
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let cell = df.get_value(r, cr).map_err(LuaError::RuntimeError)?;
            cell_to_lua(lua, &cell)
        });
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
                let df = this.inner.borrow();
                let result = df
                    .sort(cr, ascending.unwrap_or(true))
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );
        methods.add_method("head", |_, this, n: Option<usize>| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.head(n.unwrap_or(5))))
        });
        methods.add_method("tail", |_, this, n: Option<usize>| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.tail(n.unwrap_or(5))))
        });
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
        methods.add_method("groupByObj", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let groups = df.group_by(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaGroupedFrame::new(groups))
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
                let df = this.inner.borrow();
                let other_borrow = other_df.inner.borrow();
                let result = df
                    .join(&other_borrow, tc, oc, jtype.as_deref().unwrap_or("inner"))
                    .map_err(LuaError::RuntimeError)?;
                Ok(LuaDataFrame::new(result))
            },
        );
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_df = other.borrow::<LuaDataFrame>()?;
            let other_borrow = other_df.inner.borrow();
            this.inner.borrow_mut().merge(&other_borrow);
            Ok(())
        });
        methods.add_method("countBy", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let result = df.count_by(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });
        methods.add_method("dropNil", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            let df = this.inner.borrow();
            let result = df.drop_nil(cr).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });
        methods.add_method("sample", |_, this, (n, seed): (usize, Option<u64>)| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.sample(n, seed)))
        });
        methods.add_method("describe", |_, this, ()| {
            let df = this.inner.borrow();
            Ok(LuaDataFrame::new(df.describe()))
        });
        methods.add_method("sum", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner.borrow().sum(cr).map_err(LuaError::RuntimeError)
        });
        methods.add_method("mean", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner.borrow().mean(cr).map_err(LuaError::RuntimeError)
        });
        methods.add_method("min", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .min_val(cr)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("max", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .max_val(cr)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("median", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .median(cr)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("stddev", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .stddev(cr)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("variance", |_, this, col: LuaValue| {
            let cr = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .variance(cr)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("fillNil", |_, this, (col, val): (LuaValue, LuaValue)| {
            let cr = lua_to_col_ref(col)?;
            let cv = lua_to_cell(val);
            this.inner
                .borrow_mut()
                .fill_nil(cr, cv)
                .map_err(LuaError::RuntimeError)
        });
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
        methods.add_method("toCSV", |_, this, ()| Ok(this.inner.borrow().to_csv()));
        methods.add_method("toJSON", |_, this, ()| Ok(this.inner.borrow().to_json()));
        methods.add_method("toBinary", |lua, this, ()| {
            let bytes = this.inner.borrow().to_binary();
            lua.create_string(&bytes)
        });
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
        methods.add_method("toString", |_, this, ()| {
            Ok(this.inner.borrow().to_string_table())
        });
        methods.add_method("query", |_, this, sql_str: String| {
            let df = this.inner.borrow();
            let result = sql::query_sql(&df, &sql_str).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });
        methods.add_method("clone", |_, this, ()| {
            Ok(LuaDataFrame::new(this.inner.borrow().clone_df()))
        });
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
        methods.add_method_mut("withCumsum", |_, this, (col, name): (LuaValue, String)| {
            let col_ref = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .with_cumsum(col_ref, &name)
                .map_err(LuaError::RuntimeError)
        });
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
        methods.add_method("corr", |_, this, (col_a, col_b): (LuaValue, LuaValue)| {
            let ca = lua_to_col_ref(col_a)?;
            let cb = lua_to_col_ref(col_b)?;
            this.inner
                .borrow()
                .corr(ca, cb)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("correlationMatrix", |_, this, ()| {
            let result = this.inner.borrow().correlation_matrix();
            Ok(LuaDataFrame::new(result))
        });
        methods.add_method_mut("zscoreCol", |_, this, (col, name): (LuaValue, String)| {
            let col_ref = lua_to_col_ref(col)?;
            this.inner
                .borrow_mut()
                .zscore_col(col_ref, &name)
                .map_err(LuaError::RuntimeError)
        });
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
        methods.add_method("modeVal", |lua, this, col: LuaValue| {
            let col_ref = lua_to_col_ref(col)?;
            let val = this
                .inner
                .borrow()
                .mode_val(col_ref)
                .map_err(LuaError::RuntimeError)?;
            cell_to_lua(lua, &val)
        });
        methods.add_method("entropy", |_, this, col: LuaValue| {
            let col_ref = lua_to_col_ref(col)?;
            this.inner
                .borrow()
                .entropy(col_ref)
                .map_err(LuaError::RuntimeError)
        });
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
        methods.add_method("type", |_, _, ()| Ok("LDataFrame"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDataFrame" || name == "DataFrame" || name == "Object")
        });
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
        methods.add_method("lazy", |_, this, ()| {
            let lq = this.inner.borrow().lazy();
            Ok(LuaLazyQuery { inner: lq })
        });
    }
}
pub struct LuaLazyQuery {
    inner: LazyQuery,
}
impl LuaUserData for LuaLazyQuery {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
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
        methods.add_method_mut("head", |_, this, n: usize| {
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery { inner: old.head(n) })
        });
        methods.add_method_mut("tail", |_, this, n: usize| {
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery { inner: old.tail(n) })
        });
        methods.add_method_mut("limit", |_, this, n: usize| {
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery {
                inner: old.limit(n),
            })
        });
        methods.add_method_mut("slice", |_, this, (start, end): (usize, usize)| {
            let s = start.saturating_sub(1);
            let e = end.saturating_sub(1);
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery {
                inner: old.slice(s, e),
            })
        });
        methods.add_method_mut("dropNil", |_, this, col: String| {
            let old = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            Ok(LuaLazyQuery {
                inner: old.drop_nil(&col),
            })
        });
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
        methods.add_method_mut("collect", |_, this, ()| {
            let lq = std::mem::replace(&mut this.inner, LazyQuery::tombstone());
            let df = lq.collect().map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        });
        methods.add_method("type", |_, _, ()| Ok("LLazyQuery"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LLazyQuery" || name == "LazyQuery" || name == "Object")
        });
    }
}
pub struct LuaDatabase {
    inner: Rc<RefCell<Database>>,
}
impl LuaUserData for LuaDatabase {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method(
            "addTable",
            |_, this, (name, df_ud): (String, LuaAnyUserData)| {
                let lua_df = df_ud.borrow::<LuaDataFrame>()?;
                let cloned = lua_df.inner.borrow().clone_df();
                this.inner.borrow_mut().add_table(&name, cloned);
                Ok(())
            },
        );
        methods.add_method("getTable", |_, this, name: String| {
            let db = this.inner.borrow();
            match db.get_table(&name) {
                Some(df) => Ok(Some(LuaDataFrame::new(df.clone_df()))),
                None => Ok(None),
            }
        });
        methods.add_method("removeTable", |_, this, name: String| {
            this.inner
                .borrow_mut()
                .remove_table(&name)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("hasTable", |_, this, name: String| {
            Ok(this.inner.borrow().has_table(&name))
        });
        methods.add_method("listTables", |lua, this, ()| {
            let db = this.inner.borrow();
            let names = db.list_tables();
            let tbl = lua.create_table()?;
            for (i, name) in names.iter().enumerate() {
                tbl.set(i + 1, name.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method("tableCount", |_, this, ()| {
            Ok(this.inner.borrow().table_count())
        });
        methods.add_method("clear", |_, this, ()| {
            this.inner.borrow_mut().clear();
            Ok(())
        });
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other_db = other.borrow::<LuaDatabase>()?;
            let cloned = other_db.inner.borrow().clone_db();
            this.inner.borrow_mut().merge(cloned);
            Ok(())
        });
        methods.add_method("toJSON", |_, this, ()| Ok(this.inner.borrow().to_json()));
        methods.add_method("query", |_, this, sql_str: String| {
            let db = this.inner.borrow();
            let result = sql::query_sql_database(&db, &sql_str).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(result))
        });
        methods.add_method("type", |_, _, ()| Ok("LDatabase"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDatabase" || name == "Database" || name == "Object")
        });
    }
}
#[derive(Clone)]
pub struct LuaVecFrame {
    inner: Rc<RefCell<VecFrame>>,
}
impl LuaVecFrame {
    pub fn new(vf: VecFrame) -> Self {
        Self {
            inner: Rc::new(RefCell::new(vf)),
        }
    }
}
impl LuaUserData for LuaVecFrame {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method_mut("colAdd", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Add, val)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("colSub", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Sub, val)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("colMul", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Mul, val)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("colDiv", |_, this, (col, val): (String, f64)| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Div, val)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("colAbs", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Abs, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("colSqrt", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Sqrt, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("colFloor", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Floor, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("colCeil", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Ceil, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut("colNeg", |_, this, col: String| {
            this.inner
                .borrow_mut()
                .col_scalar_op(&col, ScalarOp::Neg, 0.0)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method_mut(
            "colClamp",
            |_, this, (col, min_val, max_val): (String, f64, f64)| {
                this.inner
                    .borrow_mut()
                    .col_clamp(&col, min_val, max_val)
                    .map_err(LuaError::RuntimeError)
            },
        );
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
        methods.add_method("reduce", |_, this, (col, op): (String, String)| {
            let rop = ReduceOp::parse(&op).map_err(LuaError::RuntimeError)?;
            this.inner
                .borrow()
                .col_reduce(&col, rop)
                .map_err(LuaError::RuntimeError)
        });
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
        methods.add_method("colType", |_, this, col: String| {
            Ok(this.inner.borrow().col_type(&col).map(|s| s.to_string()))
        });
        methods.add_method_mut("colCast", |_, this, (col, dtype): (String, String)| {
            this.inner
                .borrow_mut()
                .col_cast(&col, &dtype)
                .map_err(LuaError::RuntimeError)
        });
        methods.add_method("nrows", |_, this, ()| Ok(this.inner.borrow().nrows()));
        methods.add_method("ncols", |_, this, ()| Ok(this.inner.borrow().ncols()));
        methods.add_method("columns", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, name) in this.inner.borrow().columns().iter().enumerate() {
                tbl.set(i + 1, name.clone())?;
            }
            Ok(tbl)
        });
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
        methods.add_method("toDataFrame", |_, this, ()| {
            Ok(LuaDataFrame::new(this.inner.borrow().to_dataframe()))
        });
        methods.add_method("type", |_, _, ()| Ok("LVecFrame"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "VecFrame" || name == "Object")
        });
    }
}
pub fn register(lua: &Lua, luna: &LuaTable, _state: Rc<RefCell<SharedState>>) -> LuaResult<()> {
    let tbl = lua.create_table()?;
    tbl.set(
        "newDataFrame",
        lua.create_function(|_, ()| Ok(LuaDataFrame::new(DataFrame::new())))?,
    )?;
    tbl.set(
        "newDatabase",
        lua.create_function(|_, ()| {
            Ok(LuaDatabase {
                inner: Rc::new(RefCell::new(Database::new())),
            })
        })?,
    )?;
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
    tbl.set(
        "fromCSV",
        lua.create_function(|_, s: String| {
            let df = serial::from_csv(&s).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;
    tbl.set(
        "fromJSON",
        lua.create_function(|_, s: String| {
            let df = serial::from_json(&s).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;
    tbl.set(
        "fromBinary",
        lua.create_function(|_, s: LuaString| {
            let df = serial::from_binary(s.as_bytes()).map_err(LuaError::RuntimeError)?;
            Ok(LuaDataFrame::new(df))
        })?,
    )?;
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
    tbl.set(
        "toVec",
        lua.create_function(|_, df: LuaAnyUserData| {
            let lua_df = df.borrow::<LuaDataFrame>()?;
            let vf = VecFrame::from_dataframe(&lua_df.inner.borrow());
            Ok(LuaVecFrame::new(vf))
        })?,
    )?;
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
