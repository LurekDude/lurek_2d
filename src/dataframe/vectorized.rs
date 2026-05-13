//! Scope: Vectorized columnar storage and SIMD-friendly bulk operations.
//! This file defines ColumnStore, VecFrame, BinaryOp, and scalar/reduce operations.
//! It owns dense typed buffers, validity masks, and parallel numeric transforms.

use std::collections::HashMap;

use rayon::prelude::*;

use crate::dataframe::frame::{CellValue, DataFrame};

/// Typed flat-buffer column with an optional null/validity bitmap.
/// Each variant stores all values as a dense `Vec<T>`, keeping memory
/// contiguous for SIMD-friendly iteration.  The `validity` field, if
/// present, has the same length as `data`; a `false` entry marks a null.
#[derive(Debug, Clone)]
pub enum ColumnStore {
    /// 64-bit float column — primary numeric type.
    Float64 {
        /// Dense numeric data.
        data: Vec<f64>,
        /// Per-row validity mask (`true` = not null).  `None` = all valid.
        validity: Option<Vec<bool>>,
    },
    /// 64-bit integer column.
    Int64 {
        /// Dense integer data.
        data: Vec<i64>,
        /// Per-row validity mask (`true` = not null).  `None` = all valid.
        validity: Option<Vec<bool>>,
    },
    /// Boolean column.
    Bool {
        /// Dense boolean data.
        data: Vec<bool>,
        /// Per-row validity mask.
        validity: Option<Vec<bool>>,
    },
    /// UTF-8 text column.
    Text {
        /// Dense string data.
        data: Vec<String>,
        /// Per-row validity mask.
        validity: Option<Vec<bool>>,
    },
}

impl ColumnStore {
    /// Return the dtype name as a static string slice.
    pub fn dtype_name(&self) -> &'static str {
        match self {
            ColumnStore::Float64 { .. } => "float64",
            ColumnStore::Int64 { .. } => "int64",
            ColumnStore::Bool { .. } => "bool",
            ColumnStore::Text { .. } => "text",
        }
    }

    /// Return the number of rows in this column.
    pub fn len(&self) -> usize {
        match self {
            ColumnStore::Float64 { data, .. } => data.len(),
            ColumnStore::Int64 { data, .. } => data.len(),
            ColumnStore::Bool { data, .. } => data.len(),
            ColumnStore::Text { data, .. } => data.len(),
        }
    }

    /// Return `true` if the column has zero rows.
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }

    /// Return `true` if row `i` is valid (not null).
    pub fn is_valid(&self, i: usize) -> bool {
        let validity = match self {
            ColumnStore::Float64 { validity, .. } => validity,
            ColumnStore::Int64 { validity, .. } => validity,
            ColumnStore::Bool { validity, .. } => validity,
            ColumnStore::Text { validity, .. } => validity,
        };
        validity
            .as_ref()
            .is_none_or(|v| *v.get(i).unwrap_or(&false))
    }

    /// Collect valid (non-null) f64 values from a Float64 column.
    pub fn valid_f64s(&self) -> Option<Vec<f64>> {
        if let ColumnStore::Float64 { data, validity } = self {
            let vals: Vec<f64> = if let Some(v) = validity {
                data.iter()
                    .zip(v.iter())
                    .filter_map(|(x, ok)| if *ok { Some(*x) } else { None })
                    .collect()
            } else {
                data.clone()
            };
            Some(vals)
        } else {
            None
        }
    }

    /// Filter rows by a boolean mask, returning a new `ColumnStore`.
    pub fn filter(&self, mask: &[bool]) -> ColumnStore {
        match self {
            ColumnStore::Float64 { data, validity } => {
                let new_data: Vec<f64> = data
                    .iter()
                    .zip(mask.iter())
                    .filter_map(|(v, ok)| if *ok { Some(*v) } else { None })
                    .collect();
                let new_validity = validity.as_ref().map(|val| {
                    val.iter()
                        .zip(mask.iter())
                        .filter_map(|(v, ok)| if *ok { Some(*v) } else { None })
                        .collect()
                });
                ColumnStore::Float64 {
                    data: new_data,
                    validity: new_validity,
                }
            }
            ColumnStore::Int64 { data, validity } => {
                let new_data: Vec<i64> = data
                    .iter()
                    .zip(mask.iter())
                    .filter_map(|(v, ok)| if *ok { Some(*v) } else { None })
                    .collect();
                let new_validity = validity.as_ref().map(|val| {
                    val.iter()
                        .zip(mask.iter())
                        .filter_map(|(v, ok)| if *ok { Some(*v) } else { None })
                        .collect()
                });
                ColumnStore::Int64 {
                    data: new_data,
                    validity: new_validity,
                }
            }
            ColumnStore::Bool { data, validity } => {
                let new_data: Vec<bool> = data
                    .iter()
                    .zip(mask.iter())
                    .filter_map(|(v, ok)| if *ok { Some(*v) } else { None })
                    .collect();
                let new_validity = validity.as_ref().map(|val| {
                    val.iter()
                        .zip(mask.iter())
                        .filter_map(|(v, ok)| if *ok { Some(*v) } else { None })
                        .collect()
                });
                ColumnStore::Bool {
                    data: new_data,
                    validity: new_validity,
                }
            }
            ColumnStore::Text { data, validity } => {
                let new_data: Vec<String> = data
                    .iter()
                    .zip(mask.iter())
                    .filter_map(|(v, ok)| if *ok { Some(v.clone()) } else { None })
                    .collect();
                let new_validity = validity.as_ref().map(|val| {
                    val.iter()
                        .zip(mask.iter())
                        .filter_map(|(v, ok)| if *ok { Some(*v) } else { None })
                        .collect()
                });
                ColumnStore::Text {
                    data: new_data,
                    validity: new_validity,
                }
            }
        }
    }
}

/// Scalar arithmetic operation applied element-wise to an entire column.
/// All ops operate on Float64 columns; other column types return an error.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ScalarOp {
    /// Add a constant to every element.
    Add,
    /// Subtract a constant from every element.
    Sub,
    /// Multiply every element by a constant.
    Mul,
    /// Divide every element by a constant.
    Div,
    /// Set every element to its absolute value.
    Abs,
    /// Apply square root to every element.
    Sqrt,
    /// Compute floor of every element.
    Floor,
    /// Compute ceiling of every element.
    Ceil,
    /// Negate every element.
    Neg,
}

impl ScalarOp {
    /// Parse a string into a `ScalarOp`.
    pub fn parse(s: &str) -> Result<ScalarOp, String> {
        match s {
            "add" => Ok(ScalarOp::Add),
            "sub" => Ok(ScalarOp::Sub),
            "mul" => Ok(ScalarOp::Mul),
            "div" => Ok(ScalarOp::Div),
            "abs" => Ok(ScalarOp::Abs),
            "sqrt" => Ok(ScalarOp::Sqrt),
            "floor" => Ok(ScalarOp::Floor),
            "ceil" => Ok(ScalarOp::Ceil),
            "neg" => Ok(ScalarOp::Neg),
            other => Err(format!("unknown scalar op: {other}")),
        }
    }
}

/// Element-wise binary operation between two Float64 columns.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum BinaryOp {
    /// Element-wise addition.
    Add,
    /// Element-wise subtraction.
    Sub,
    /// Element-wise multiplication.
    Mul,
    /// Element-wise division.
    Div,
    /// Element-wise minimum.
    Min,
    /// Element-wise maximum.
    Max,
}

impl BinaryOp {
    /// Parse a string into a `BinaryOp`.
    pub fn parse(s: &str) -> Result<BinaryOp, String> {
        match s {
            "add" => Ok(BinaryOp::Add),
            "sub" => Ok(BinaryOp::Sub),
            "mul" => Ok(BinaryOp::Mul),
            "div" => Ok(BinaryOp::Div),
            "min" => Ok(BinaryOp::Min),
            "max" => Ok(BinaryOp::Max),
            other => Err(format!("unknown binary op: {other}")),
        }
    }
}

/// Column-level reduction operations.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ReduceOp {
    /// Sum of all valid values.
    Sum,
    /// Arithmetic mean of all valid values.
    Mean,
    /// Minimum value.
    Min,
    /// Maximum value.
    Max,
    /// Population standard deviation.
    Std,
    /// Population variance.
    Var,
    /// Count of valid (non-null) rows.
    Count,
}

impl ReduceOp {
    /// Parse a string into a `ReduceOp`.
    pub fn parse(s: &str) -> Result<ReduceOp, String> {
        match s {
            "sum" => Ok(ReduceOp::Sum),
            "mean" => Ok(ReduceOp::Mean),
            "min" => Ok(ReduceOp::Min),
            "max" => Ok(ReduceOp::Max),
            "std" => Ok(ReduceOp::Std),
            "var" => Ok(ReduceOp::Var),
            "count" => Ok(ReduceOp::Count),
            other => Err(format!("unknown reduce op: {other}")),
        }
    }
}

/// Comparison operator used in `VecFrame::filter_mask`.
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum CmpOp {
    /// Less than.
    Lt,
    /// Less than or equal.
    Le,
    /// Greater than.
    Gt,
    /// Greater than or equal.
    Ge,
    /// Equal.
    Eq,
    /// Not equal.
    Ne,
}

impl CmpOp {
    /// Parse a string into a `CmpOp`.
    pub fn parse(s: &str) -> Result<CmpOp, String> {
        match s {
            "<" | "lt" => Ok(CmpOp::Lt),
            "<=" | "le" => Ok(CmpOp::Le),
            ">" | "gt" => Ok(CmpOp::Gt),
            ">=" | "ge" => Ok(CmpOp::Ge),
            "==" | "eq" => Ok(CmpOp::Eq),
            "!=" | "~=" | "ne" => Ok(CmpOp::Ne),
            other => Err(format!("unknown comparison op: {other}")),
        }
    }
}

/// Typed-column vectorized DataFrame.
/// Each column is a [`ColumnStore`] — a dense typed `Vec` with an optional
/// null bitmap.  This layout enables:
/// - Auto-vectorization (SIMD) by the compiler for `f64` / `i64` arithmetic.
/// - Parallel multi-column operations via `rayon`.
/// Conversion helpers `VecFrame::from_dataframe` and `VecFrame::to_dataframe`
/// bridge between the flexible `CellValue`-based API and this fast numeric layer.
#[derive(Debug, Clone)]
pub struct VecFrame {
    column_names: Vec<String>,
    columns: Vec<ColumnStore>,
}

impl VecFrame {
    /// Create an empty `VecFrame` with no columns.
    pub fn new() -> Self {
        Self {
            column_names: Vec::new(),
            columns: Vec::new(),
        }
    }

    /// Return the number of rows.  All columns must have the same length;
    pub fn nrows(&self) -> usize {
        self.columns.first().map(|c| c.len()).unwrap_or(0)
    }

    /// Return the number of columns.
    pub fn ncols(&self) -> usize {
        self.column_names.len()
    }

    /// Return a slice of column names.
    pub fn columns(&self) -> &[String] {
        &self.column_names
    }

    /// Return the dtype name for a column, or `None` if the column is not found.
    pub fn col_type(&self, col: &str) -> Option<&'static str> {
        let idx = self.resolve(col).ok()?;
        Some(self.columns[idx].dtype_name())
    }

    /// Convert a [`DataFrame`] into a `VecFrame`.
    pub fn from_dataframe(df: &DataFrame) -> VecFrame {
        let mut vf = VecFrame::new();
        for (col_idx, name) in df.columns().iter().enumerate() {
            // borrow column data via raw_data
            let raw = df.raw_data();
            let cells = &raw[col_idx];
            let store = infer_column(cells);
            vf.column_names.push(name.clone());
            vf.columns.push(store);
        }
        vf
    }

    /// Convert this `VecFrame` back to a [`DataFrame`].
    pub fn to_dataframe(&self) -> DataFrame {
        let nrows = self.nrows();
        let mut col_data: Vec<Vec<CellValue>> = Vec::with_capacity(self.columns.len());
        for (i, store) in self.columns.iter().enumerate() {
            let _ = i;
            let cells: Vec<CellValue> = (0..nrows)
                .map(|row| {
                    if !store.is_valid(row) {
                        return CellValue::Nil;
                    }
                    match store {
                        ColumnStore::Float64 { data, .. } => CellValue::Number(data[row]),
                        ColumnStore::Int64 { data, .. } => CellValue::Number(data[row] as f64),
                        ColumnStore::Bool { data, .. } => CellValue::Bool(data[row]),
                        ColumnStore::Text { data, .. } => CellValue::Text(data[row].clone()),
                    }
                })
                .collect();
            col_data.push(cells);
        }
        DataFrame::from_raw(self.column_names.clone(), col_data)
    }

    /// Resolve a column name to a 0-based index.
    fn resolve(&self, col: &str) -> Result<usize, String> {
        self.column_names
            .iter()
            .position(|n| n == col)
            .ok_or_else(|| format!("column not found: {col}"))
    }

    /// Apply a scalar operation to every element of a Float64 column in-place.
    pub fn col_scalar_op(&mut self, col: &str, op: ScalarOp, val: f64) -> Result<(), String> {
        let idx = self.resolve(col)?;
        if let ColumnStore::Float64 { data, validity } = &mut self.columns[idx] {
            let vref = validity.as_ref();
            match op {
                ScalarOp::Add => {
                    for (i, x) in data.iter_mut().enumerate() {
                        if vref.is_none_or(|v| v[i]) {
                            *x += val;
                        }
                    }
                }
                ScalarOp::Sub => {
                    for (i, x) in data.iter_mut().enumerate() {
                        if vref.is_none_or(|v| v[i]) {
                            *x -= val;
                        }
                    }
                }
                ScalarOp::Mul => {
                    for (i, x) in data.iter_mut().enumerate() {
                        if vref.is_none_or(|v| v[i]) {
                            *x *= val;
                        }
                    }
                }
                ScalarOp::Div => {
                    if val == 0.0 {
                        return Err("division by zero in col_scalar_op".into());
                    }
                    for (i, x) in data.iter_mut().enumerate() {
                        if vref.is_none_or(|v| v[i]) {
                            *x /= val;
                        }
                    }
                }
                ScalarOp::Abs => {
                    for (i, x) in data.iter_mut().enumerate() {
                        if vref.is_none_or(|v| v[i]) {
                            *x = x.abs();
                        }
                    }
                }
                ScalarOp::Sqrt => {
                    for (i, x) in data.iter_mut().enumerate() {
                        if vref.is_none_or(|v| v[i]) {
                            *x = x.sqrt();
                        }
                    }
                }
                ScalarOp::Floor => {
                    for (i, x) in data.iter_mut().enumerate() {
                        if vref.is_none_or(|v| v[i]) {
                            *x = x.floor();
                        }
                    }
                }
                ScalarOp::Ceil => {
                    for (i, x) in data.iter_mut().enumerate() {
                        if vref.is_none_or(|v| v[i]) {
                            *x = x.ceil();
                        }
                    }
                }
                ScalarOp::Neg => {
                    for (i, x) in data.iter_mut().enumerate() {
                        if vref.is_none_or(|v| v[i]) {
                            *x = -(*x);
                        }
                    }
                }
            }
            Ok(())
        } else {
            Err(format!(
                "col_scalar_op: column '{col}' is not Float64 (type: {})",
                self.columns[idx].dtype_name()
            ))
        }
    }

    /// Clamp every element of a Float64 column to `[min_val, max_val]` in-place.
    pub fn col_clamp(&mut self, col: &str, min_val: f64, max_val: f64) -> Result<(), String> {
        let idx = self.resolve(col)?;
        if let ColumnStore::Float64 { data, validity } = &mut self.columns[idx] {
            let vref = validity.as_ref();
            for (i, x) in data.iter_mut().enumerate() {
                if vref.is_none_or(|v| v[i]) {
                    *x = x.clamp(min_val, max_val);
                }
            }
            Ok(())
        } else {
            Err(format!(
                "col_clamp: column '{col}' is not Float64 (type: {})",
                self.columns[idx].dtype_name()
            ))
        }
    }

    /// Compute `out_col[i] = left_col[i] op right_col[i]` for every row,
    pub fn col_binary_op(
        &mut self,
        out_col: &str,
        left_col: &str,
        op: BinaryOp,
        right_col: &str,
    ) -> Result<(), String> {
        let li = self.resolve(left_col)?;
        let ri = self.resolve(right_col)?;
        let nrows = self.nrows();

        // Extract both column data without keeping borrows alive
        let left_data: Vec<f64> = match &self.columns[li] {
            ColumnStore::Float64 { data, .. } => data.clone(),
            ColumnStore::Int64 { data, .. } => data.iter().map(|v| *v as f64).collect(),
            t => {
                return Err(format!(
                    "col_binary_op: left column '{left_col}' type '{}' is not numeric",
                    t.dtype_name()
                ))
            }
        };
        let right_data: Vec<f64> = match &self.columns[ri] {
            ColumnStore::Float64 { data, .. } => data.clone(),
            ColumnStore::Int64 { data, .. } => data.iter().map(|v| *v as f64).collect(),
            t => {
                return Err(format!(
                    "col_binary_op: right column '{right_col}' type '{}' is not numeric",
                    t.dtype_name()
                ))
            }
        };
        let left_valid = match &self.columns[li] {
            ColumnStore::Float64 { validity, .. } | ColumnStore::Int64 { validity, .. } => {
                validity.clone()
            }
            _ => None,
        };
        let right_valid = match &self.columns[ri] {
            ColumnStore::Float64 { validity, .. } | ColumnStore::Int64 { validity, .. } => {
                validity.clone()
            }
            _ => None,
        };

        // Compute output — nulls propagate
        let mut out_data = Vec::with_capacity(nrows);
        let mut out_validity: Option<Vec<bool>> = None;
        for i in 0..nrows {
            let l_ok = left_valid.as_ref().is_none_or(|v| v[i]);
            let r_ok = right_valid.as_ref().is_none_or(|v| v[i]);
            if !l_ok || !r_ok {
                out_data.push(0.0f64);
                out_validity.get_or_insert_with(|| vec![true; nrows])[i] = false;
            } else {
                let l = left_data[i];
                let r = right_data[i];
                let result = match op {
                    BinaryOp::Add => l + r,
                    BinaryOp::Sub => l - r,
                    BinaryOp::Mul => l * r,
                    BinaryOp::Div => {
                        if r == 0.0 {
                            out_data.push(f64::NAN);
                            if out_validity.is_none() {
                                out_validity = Some(vec![true; nrows]);
                            }
                            out_validity.as_mut().unwrap()[i] = false;
                            continue;
                        }
                        l / r
                    }
                    BinaryOp::Min => l.min(r),
                    BinaryOp::Max => l.max(r),
                };
                out_data.push(result);
            }
        }

        let store = ColumnStore::Float64 {
            data: out_data,
            validity: out_validity,
        };

        // Replace or append output column
        if let Some(oi) = self.column_names.iter().position(|n| n == out_col) {
            self.columns[oi] = store;
        } else {
            self.column_names.push(out_col.to_string());
            self.columns.push(store);
        }
        Ok(())
    }

    /// Reduce an entire Float64 column to a single scalar.
    pub fn col_reduce(&self, col: &str, op: ReduceOp) -> Result<Option<f64>, String> {
        let idx = self.resolve(col)?;
        let vals = match &self.columns[idx] {
            ColumnStore::Float64 { .. } => self.columns[idx]
                .valid_f64s()
                .ok_or_else(|| "impossible".to_string())?,
            ColumnStore::Int64 { data, validity } => {
                let base: Vec<f64> = data.iter().map(|v| *v as f64).collect();
                if let Some(v) = validity {
                    base.iter()
                        .zip(v.iter())
                        .filter_map(|(x, ok)| if *ok { Some(*x) } else { None })
                        .collect()
                } else {
                    base
                }
            }
            t => {
                return Err(format!(
                    "col_reduce: column '{col}' type '{}' is not numeric",
                    t.dtype_name()
                ))
            }
        };

        if vals.is_empty() {
            return Ok(None);
        }

        let result = match op {
            ReduceOp::Count => Some(vals.len() as f64),
            ReduceOp::Sum => Some(vals.iter().sum()),
            ReduceOp::Mean => Some(vals.iter().sum::<f64>() / vals.len() as f64),
            ReduceOp::Min => vals.iter().cloned().reduce(f64::min),
            ReduceOp::Max => vals.iter().cloned().reduce(f64::max),
            ReduceOp::Var => {
                let mean = vals.iter().sum::<f64>() / vals.len() as f64;
                let var = vals.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / vals.len() as f64;
                Some(var)
            }
            ReduceOp::Std => {
                let mean = vals.iter().sum::<f64>() / vals.len() as f64;
                let var = vals.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / vals.len() as f64;
                Some(var.sqrt())
            }
        };
        Ok(result)
    }

    /// Build a boolean row mask for `col[i] op val`.
    pub fn filter_mask(&self, col: &str, op: CmpOp, val: f64) -> Result<Vec<bool>, String> {
        let idx = self.resolve(col)?;
        let nrows = self.nrows();
        let mut mask = vec![false; nrows];
        match &self.columns[idx] {
            ColumnStore::Float64 { data, validity } => {
                for (i, x) in data.iter().enumerate() {
                    if validity.as_ref().is_none_or(|v| v[i]) {
                        mask[i] = cmp_f64(*x, op, val);
                    }
                }
            }
            ColumnStore::Int64 { data, validity } => {
                for (i, x) in data.iter().enumerate() {
                    if validity.as_ref().is_none_or(|v| v[i]) {
                        mask[i] = cmp_f64(*x as f64, op, val);
                    }
                }
            }
            t => {
                return Err(format!(
                    "filter_mask: column '{col}' type '{}' is not numeric",
                    t.dtype_name()
                ))
            }
        }
        Ok(mask)
    }

    /// Return a new `VecFrame` containing only rows where `mask[i]` is `true`.
    pub fn apply_mask(&self, mask: &[bool]) -> Result<VecFrame, String> {
        if mask.len() != self.nrows() {
            return Err(format!(
                "apply_mask: mask length {} != nrows {}",
                mask.len(),
                self.nrows()
            ));
        }
        let columns: Vec<ColumnStore> = self.columns.iter().map(|c| c.filter(mask)).collect();
        Ok(VecFrame {
            column_names: self.column_names.clone(),
            columns,
        })
    }

    /// Cast a column to a new type.
    pub fn col_cast(&mut self, col: &str, dtype: &str) -> Result<(), String> {
        let idx = self.resolve(col)?;
        let nrows = self.nrows();
        let new_store = match (self.columns[idx].dtype_name(), dtype) {
            ("float64", "int64") => {
                if let ColumnStore::Float64 { data, validity } = &self.columns[idx] {
                    ColumnStore::Int64 {
                        data: data.iter().map(|v| *v as i64).collect(),
                        validity: validity.clone(),
                    }
                } else {
                    unreachable!()
                }
            }
            ("int64", "float64") => {
                if let ColumnStore::Int64 { data, validity } = &self.columns[idx] {
                    ColumnStore::Float64 {
                        data: data.iter().map(|v| *v as f64).collect(),
                        validity: validity.clone(),
                    }
                } else {
                    unreachable!()
                }
            }
            ("float64", "text") => {
                if let ColumnStore::Float64 { data, validity } = &self.columns[idx] {
                    ColumnStore::Text {
                        data: data.iter().map(|v| format!("{v}")).collect(),
                        validity: validity.clone(),
                    }
                } else {
                    unreachable!()
                }
            }
            ("int64", "text") => {
                if let ColumnStore::Int64 { data, validity } = &self.columns[idx] {
                    ColumnStore::Text {
                        data: data.iter().map(|v| format!("{v}")).collect(),
                        validity: validity.clone(),
                    }
                } else {
                    unreachable!()
                }
            }
            (from, to) if from == to => return Ok(()),
            (from, to) => {
                let _ = nrows;
                return Err(format!("col_cast: cannot cast '{col}' from {from} to {to}"));
            }
        };
        self.columns[idx] = new_store;
        Ok(())
    }

    /// Reduce multiple columns in parallel using `rayon`, returning a map of
    pub fn par_reduce(&self, cols: &[&str], op: ReduceOp) -> HashMap<String, Option<f64>> {
        cols.par_iter()
            .map(|col| {
                let result = self.col_reduce(col, op).ok().flatten();
                (col.to_string(), result)
            })
            .collect()
    }

    /// Apply a scalar operation in parallel to multiple Float64 columns.
    pub fn par_scalar_op(&mut self, cols: &[&str], op: ScalarOp, val: f64) -> Result<(), String> {
        // Collect indices; validate first so we don't partially mutate on error.
        let indices: Result<Vec<usize>, String> = cols.iter().map(|c| self.resolve(c)).collect();
        let indices = indices?;

        // Parallel mutable access: split columns into indexed slices.
        // We build a separate data vec, apply in parallel, then write back.
        let updates: Vec<(usize, Vec<f64>)> = indices
            .par_iter()
            .filter_map(|&idx| {
                if let ColumnStore::Float64 { data, validity } = &self.columns[idx] {
                    let vref = validity.as_ref();
                    let new_data: Vec<f64> = data
                        .iter()
                        .enumerate()
                        .map(|(i, &x)| {
                            if vref.is_none_or(|v| v[i]) {
                                apply_scalar_f64(x, op, val)
                            } else {
                                x
                            }
                        })
                        .collect();
                    Some((idx, new_data))
                } else {
                    None
                }
            })
            .collect();

        for (idx, new_data) in updates {
            if let ColumnStore::Float64 { data, .. } = &mut self.columns[idx] {
                *data = new_data;
            }
        }
        Ok(())
    }
}

impl Default for VecFrame {
    fn default() -> Self {
        Self::new()
    }
}

/// Infer the `ColumnStore` type from a `Vec<CellValue>` column.
fn infer_column(cells: &[CellValue]) -> ColumnStore {
    // Determine dominant type in one pass
    let mut has_num = false;
    let mut has_bool = false;
    let mut has_text = false;
    let mut has_nil = false;
    for c in cells.iter() {
        match c {
            CellValue::Number(_) => has_num = true,
            CellValue::Bool(_) => has_bool = true,
            CellValue::Text(_) => has_text = true,
            CellValue::Nil => has_nil = true,
        }
    }

    // Decide type: pure bool, pure text, numeric (default for mixed/empty)
    let n = cells.len();
    if has_bool && !has_num && !has_text {
        // Bool column
        let mut data = Vec::with_capacity(n);
        let mut validity = if has_nil { Some(vec![true; n]) } else { None };
        for (i, c) in cells.iter().enumerate() {
            match c {
                CellValue::Bool(b) => data.push(*b),
                CellValue::Nil => {
                    data.push(false);
                    if let Some(v) = &mut validity {
                        v[i] = false;
                    }
                }
                _ => data.push(false),
            }
        }
        ColumnStore::Bool { data, validity }
    } else if has_text && !has_num && !has_bool {
        // Text column
        let mut data = Vec::with_capacity(n);
        let mut validity = if has_nil { Some(vec![true; n]) } else { None };
        for (i, c) in cells.iter().enumerate() {
            match c {
                CellValue::Text(s) => data.push(s.clone()),
                CellValue::Nil => {
                    data.push(String::new());
                    if let Some(v) = &mut validity {
                        v[i] = false;
                    }
                }
                _ => data.push(String::new()),
            }
        }
        ColumnStore::Text { data, validity }
    } else {
        // Float64 (numeric or mixed — bools become 0/1, text becomes NaN-validity)
        let mut data = Vec::with_capacity(n);
        let mut validity = if has_nil || has_text || has_bool {
            Some(vec![true; n])
        } else {
            None
        };
        for (i, c) in cells.iter().enumerate() {
            match c {
                CellValue::Number(v) => data.push(*v),
                CellValue::Nil => {
                    data.push(0.0);
                    if let Some(v) = &mut validity {
                        v[i] = false;
                    }
                }
                CellValue::Bool(b) => data.push(if *b { 1.0 } else { 0.0 }),
                CellValue::Text(_) => {
                    data.push(0.0);
                    if let Some(v) = &mut validity {
                        v[i] = false;
                    }
                }
            }
        }
        ColumnStore::Float64 { data, validity }
    }
}

/// Apply a single scalar op to one f64 value.
fn apply_scalar_f64(x: f64, op: ScalarOp, val: f64) -> f64 {
    match op {
        ScalarOp::Add => x + val,
        ScalarOp::Sub => x - val,
        ScalarOp::Mul => x * val,
        ScalarOp::Div => x / val,
        ScalarOp::Abs => x.abs(),
        ScalarOp::Sqrt => x.sqrt(),
        ScalarOp::Floor => x.floor(),
        ScalarOp::Ceil => x.ceil(),
        ScalarOp::Neg => -x,
    }
}

/// Apply a comparison operator to two f64 values.
fn cmp_f64(x: f64, op: CmpOp, val: f64) -> bool {
    match op {
        CmpOp::Lt => x < val,
        CmpOp::Le => x <= val,
        CmpOp::Gt => x > val,
        CmpOp::Ge => x >= val,
        CmpOp::Eq => (x - val).abs() < f64::EPSILON,
        CmpOp::Ne => (x - val).abs() >= f64::EPSILON,
    }
}
