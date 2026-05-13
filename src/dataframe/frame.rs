//! Scope: Core DataFrame and Database types with cell-level access.
//! This file defines CellValue, ColRef, DataFrame, Database, and basic row/column operations.
//! It owns cell storage, row iteration, and column indexing semantics.

use std::cmp::Ordering;
use std::collections::HashMap;

use crate::dataframe::rng::Xorshift64;

/// A single cell value in a DataFrame column.
#[derive(Debug, Clone, PartialEq)]
pub enum CellValue {
    /// Missing / null value.
    Nil,
    /// 64-bit floating-point number.
    Number(f64),
    /// UTF-8 string.
    Text(String),
    /// Boolean value.
    Bool(bool),
}

impl CellValue {
    /// Return `true` when the value is `Nil`.
    pub fn is_nil(&self) -> bool {
        matches!(self, CellValue::Nil)
    }

    /// Return the contained number, or `None`.
    pub fn as_number(&self) -> Option<f64> {
        match self {
            CellValue::Number(n) => Some(*n),
            _ => None,
        }
    }

    /// Return the contained text as a string slice, or `None`.
    pub fn as_text(&self) -> Option<&str> {
        match self {
            CellValue::Text(s) => Some(s.as_str()),
            _ => None,
        }
    }

    /// Return the contained boolean, or `None`.
    pub fn as_bool(&self) -> Option<bool> {
        match self {
            CellValue::Bool(b) => Some(*b),
            _ => None,
        }
    }

    /// Comparison for sorting. Nil sorts to end; among non-nil values
    pub fn cmp_for_sort(&self, other: &CellValue) -> Ordering {
        match (self, other) {
            (CellValue::Nil, CellValue::Nil) => Ordering::Equal,
            (CellValue::Nil, _) => Ordering::Greater,
            (_, CellValue::Nil) => Ordering::Less,
            (CellValue::Number(a), CellValue::Number(b)) => {
                a.partial_cmp(b).unwrap_or(Ordering::Equal)
            }
            (CellValue::Text(a), CellValue::Text(b)) => a.cmp(b),
            (CellValue::Bool(a), CellValue::Bool(b)) => a.cmp(b),
            // Cross-type: Number < Text < Bool
            (CellValue::Number(_), _) => Ordering::Less,
            (_, CellValue::Number(_)) => Ordering::Greater,
            (CellValue::Text(_), CellValue::Bool(_)) => Ordering::Less,
            (CellValue::Bool(_), CellValue::Text(_)) => Ordering::Greater,
        }
    }
}

impl std::fmt::Display for CellValue {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            CellValue::Nil => write!(f, "nil"),
            CellValue::Number(n) => {
                if *n == (*n as i64) as f64 && n.is_finite() {
                    write!(f, "{}", *n as i64)
                } else {
                    write!(f, "{n}")
                }
            }
            CellValue::Text(s) => write!(f, "{s}"),
            CellValue::Bool(b) => write!(f, "{b}"),
        }
    }
}

/// Column reference: string name or 1-based integer index.
/// When constructed from Lua, `Index` holds the raw 1-based value.
/// `DataFrame::resolve_col` converts it to a 0-based column index.
#[derive(Debug, Clone)]
pub enum ColRef {
    /// Reference by column name.
    Name(String),
    /// Reference by 1-based column index.
    Index(usize),
}

/// In-memory column-major tabular data.
/// Data is stored as `data[col_index][row_index]`. All public methods
/// that accept row indices use **0-based** indexing; the Lua binding
/// layer is responsible for converting from 1-based.
#[derive(Clone)]
pub struct DataFrame {
    pub(crate) column_names: Vec<String>,
    pub(crate) data: Vec<Vec<CellValue>>,
}

/// Borrowing row iterator for [`DataFrame`].
/// Yields one row at a time as a vector of `(column_name, cell_ref)` pairs,
/// avoiding full-table materialization.
pub struct DataFrameRowIter<'a> {
    df: &'a DataFrame,
    next_row: usize,
}

impl<'a> Iterator for DataFrameRowIter<'a> {
    type Item = Vec<(&'a str, &'a CellValue)>;

    fn next(&mut self) -> Option<Self::Item> {
        if self.next_row >= self.df.nrows() {
            return None;
        }

        let row_index = self.next_row;
        self.next_row += 1;

        let row = self
            .df
            .column_names
            .iter()
            .enumerate()
            .map(|(ci, name)| (name.as_str(), &self.df.data[ci][row_index]))
            .collect();
        Some(row)
    }
}

/// Named catalog of DataFrames.
pub struct Database {
    tables: HashMap<String, DataFrame>,
}

// ---------------------------------------------------------------------------
// DataFrame implementation
// ---------------------------------------------------------------------------

impl DataFrame {
    /// Create an empty DataFrame with no columns or rows.
    pub fn new() -> Self {
        log::debug!("dataframe: new empty DataFrame created");
        Self {
            column_names: Vec::new(),
            data: Vec::new(),
        }
    }

    /// Return the number of rows.
    pub fn nrows(&self) -> usize {
        if self.data.is_empty() {
            0
        } else {
            self.data[0].len()
        }
    }

    /// Return the number of columns.
    pub fn ncols(&self) -> usize {
        self.column_names.len()
    }

    /// Return the column names.
    pub fn columns(&self) -> &[String] {
        &self.column_names
    }

    /// Return the row count.
    pub fn count(&self) -> usize {
        self.nrows()
    }

    /// Resolve a `ColRef` to a 0-based column index.
    pub fn resolve_col(&self, col: ColRef) -> Result<usize, String> {
        match col {
            ColRef::Name(ref name) => self
                .column_names
                .iter()
                .position(|n| n == name)
                .ok_or_else(|| format!("column not found: {name}")),
            ColRef::Index(i) => {
                if i == 0 || i > self.column_names.len() {
                    Err(format!(
                        "column index {i} out of range (1..{})",
                        self.column_names.len()
                    ))
                } else {
                    Ok(i - 1)
                }
            }
        }
    }

    /// Add a new column, filling existing rows with `default`.
    pub fn add_column(&mut self, name: &str, default: CellValue) -> Result<(), String> {
        if self.column_names.contains(&name.to_string()) {
            return Err(format!("column already exists: {name}"));
        }
        let n = self.nrows();
        self.column_names.push(name.to_string());
        self.data.push(vec![default; n]);
        Ok(())
    }

    /// Remove a column resolved by `ColRef` and return an error when it is missing.
    pub fn remove_column(&mut self, col: ColRef) -> Result<(), String> {
        let idx = self.resolve_col(col)?;
        self.column_names.remove(idx);
        self.data.remove(idx);
        Ok(())
    }

    /// Rename a column.
    pub fn rename_column(&mut self, col: ColRef, new_name: &str) -> Result<(), String> {
        let idx = self.resolve_col(col)?;
        if self.column_names.contains(&new_name.to_string()) {
            return Err(format!("column already exists: {new_name}"));
        }
        self.column_names[idx] = new_name.to_string();
        Ok(())
    }

    /// Return a reference to the column data resolved by `ColRef`.
    pub fn get_column(&self, col: ColRef) -> Result<&[CellValue], String> {
        let idx = self.resolve_col(col)?;
        Ok(&self.data[idx])
    }

    /// Add a row from name-value pairs. Missing columns receive `Nil`.
    pub fn add_row(&mut self, values: &[(String, CellValue)]) -> usize {
        let row_idx = self.nrows();
        // Auto-create any columns that appear in this row but don't yet exist
        for (key, _) in values.iter() {
            if !self.column_names.contains(key) {
                self.column_names.push(key.clone());
                self.data.push(vec![CellValue::Nil; row_idx]);
            }
        }
        // Build a lookup for provided values
        let lookup: HashMap<&str, &CellValue> =
            values.iter().map(|(k, v)| (k.as_str(), v)).collect();
        for (ci, name) in self.column_names.iter().enumerate() {
            let val = lookup
                .get(name.as_str())
                .cloned()
                .cloned()
                .unwrap_or(CellValue::Nil);
            self.data[ci].push(val);
        }
        row_idx
    }

    /// Remove a row by 0-based index and return an error when it is out of range.
    pub fn remove_row(&mut self, row: usize) -> Result<(), String> {
        let n = self.nrows();
        if row >= n {
            return Err(format!("row index {row} out of range (0..{n})"));
        }
        for col in &mut self.data {
            col.remove(row);
        }
        Ok(())
    }

    /// Get a full row as name-value pairs (0-based index).
    pub fn get_row(&self, row: usize) -> Result<Vec<(String, CellValue)>, String> {
        let n = self.nrows();
        if row >= n {
            return Err(format!("row index {row} out of range (0..{n})"));
        }
        Ok(self
            .column_names
            .iter()
            .enumerate()
            .map(|(ci, name)| (name.clone(), self.data[ci][row].clone()))
            .collect())
    }

    /// Iterate rows lazily as borrowed `(column_name, cell)` pairs.
    pub fn iter_rows(&self) -> DataFrameRowIter<'_> {
        DataFrameRowIter {
            df: self,
            next_row: 0,
        }
    }

    /// Get a single cell value (0-based row, ColRef for column).
    pub fn get_value(&self, row: usize, col: ColRef) -> Result<CellValue, String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        if row >= n {
            return Err(format!("row index {row} out of range (0..{n})"));
        }
        Ok(self.data[ci][row].clone())
    }

    /// Set a single cell value (0-based row, ColRef for column).
    pub fn set_value(&mut self, row: usize, col: ColRef, val: CellValue) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        if row >= n {
            return Err(format!("row index {row} out of range (0..{n})"));
        }
        self.data[ci][row] = val;
        Ok(())
    }

    /// Deep-clone this DataFrame.
    pub fn clone_df(&self) -> DataFrame {
        DataFrame {
            column_names: self.column_names.clone(),
            data: self.data.clone(),
        }
    }

    /// Return a mutable reference to a column's cell data, resolved by `ColRef`.
    pub fn column_data_mut(&mut self, col: ColRef) -> Result<&mut Vec<CellValue>, String> {
        let ci = self.resolve_col(col)?;
        Ok(&mut self.data[ci])
    }

    /// Create a DataFrame from raw column names and column-major data.
    pub fn from_raw(column_names: Vec<String>, data: Vec<Vec<CellValue>>) -> Self {
        Self { column_names, data }
    }

    /// Create a DataFrame from row-major values using explicit column names.
    pub fn from_rows(column_names: Vec<String>, rows: Vec<Vec<CellValue>>) -> Result<Self, String> {
        if column_names.is_empty() {
            if rows.is_empty() {
                return Ok(Self::new());
            }
            return Err(
                "from_rows: column_names cannot be empty when rows are provided".to_string(),
            );
        }

        for (i, row) in rows.iter().enumerate() {
            if row.len() != column_names.len() {
                return Err(format!(
                    "from_rows: row {i} has {} values but expected {}",
                    row.len(),
                    column_names.len()
                ));
            }
        }

        let mut data = vec![Vec::with_capacity(rows.len()); column_names.len()];
        for row in rows {
            for (ci, cell) in row.into_iter().enumerate() {
                data[ci].push(cell);
            }
        }

        Ok(Self::from_raw(column_names, data))
    }

    /// Get a reference to the underlying column-major data.
    pub fn raw_data(&self) -> &Vec<Vec<CellValue>> {
        &self.data
    }

    /// Generate a DataFrame with random data.
    pub fn random(defs: &[(String, String)], n_rows: usize, seed: Option<u64>) -> DataFrame {
        let mut rng = Xorshift64::new(seed.unwrap_or(0));

        let names_pool = [
            "Alice", "Bob", "Charlie", "Diana", "Eve", "Frank", "Grace", "Hank", "Ivy", "Jack",
            "Kate", "Leo", "Mia", "Nick", "Olivia", "Pat", "Quinn", "Rose", "Sam", "Tina", "Uma",
            "Vic", "Wendy", "Xena", "Yuri", "Zoe",
        ];
        let domains = ["example.com", "mail.org", "test.net", "demo.io"];
        let words = [
            "the", "quick", "brown", "fox", "jumps", "over", "lazy", "dog", "a", "big", "red",
            "cat", "runs", "fast", "slow", "happy", "sad", "warm", "cold", "bright", "dark",
            "small", "large", "old",
        ];
        let alpha = b"abcdefghijklmnopqrstuvwxyz0123456789";

        let column_names: Vec<String> = defs.iter().map(|(name, _)| name.clone()).collect();
        let mut data: Vec<Vec<CellValue>> = Vec::with_capacity(defs.len());

        for (_, hint) in defs {
            let mut col = Vec::with_capacity(n_rows);
            for row_i in 0..n_rows {
                let val = match hint.as_str() {
                    "int" => CellValue::Number((rng.next_u64() % 1001) as f64),
                    "float" => CellValue::Number(rng.next_f64()),
                    "bool" => CellValue::Bool(rng.next_u64().is_multiple_of(2)),
                    "name" => {
                        let idx = rng.next_usize(names_pool.len());
                        CellValue::Text(names_pool[idx].to_string())
                    }
                    "id" => CellValue::Number((row_i + 1) as f64),
                    "string" => {
                        let s: String = (0..8)
                            .map(|_| alpha[rng.next_usize(alpha.len())] as char)
                            .collect();
                        CellValue::Text(s)
                    }
                    "email" => {
                        let handle: String =
                            (0..6).map(|_| alpha[rng.next_usize(26)] as char).collect();
                        let domain = domains[rng.next_usize(domains.len())];
                        CellValue::Text(format!("{handle}@{domain}"))
                    }
                    "date" => {
                        let year = 2000 + (rng.next_u64() % 25) as u32;
                        let month = 1 + (rng.next_u64() % 12) as u32;
                        let day = 1 + (rng.next_u64() % 28) as u32;
                        CellValue::Text(format!("{year:04}-{month:02}-{day:02}"))
                    }
                    "phone" => {
                        let a = rng.next_u64() % 900 + 100;
                        let b = rng.next_u64() % 900 + 100;
                        let c = rng.next_u64() % 9000 + 1000;
                        CellValue::Text(format!("+1-{a}-{b}-{c}"))
                    }
                    "uuid" => {
                        let hex_chars = b"0123456789abcdef";
                        let hex = |rng: &mut Xorshift64, n: usize| -> String {
                            (0..n)
                                .map(|_| hex_chars[rng.next_usize(16)] as char)
                                .collect()
                        };
                        let u = format!(
                            "{}-{}-{}-{}-{}",
                            hex(&mut rng, 8),
                            hex(&mut rng, 4),
                            hex(&mut rng, 4),
                            hex(&mut rng, 4),
                            hex(&mut rng, 12)
                        );
                        CellValue::Text(u)
                    }
                    "sentence" => {
                        let n_words = 4 + rng.next_usize(7); // 4-10 words
                        let sentence: Vec<&str> = (0..n_words)
                            .map(|_| words[rng.next_usize(words.len())])
                            .collect();
                        let mut s = sentence.join(" ");
                        // Capitalize first letter
                        if let Some(first) = s.get_mut(0..1) {
                            first.make_ascii_uppercase();
                        }
                        CellValue::Text(s)
                    }
                    _ => CellValue::Text(format!("unknown_type:{hint}")),
                };
                col.push(val);
            }
            data.push(col);
        }

        DataFrame { column_names, data }
    }

    /// Create a new `DataFrame` with an extra computed column.
    pub fn with_eval(&self, col_name: &str, expr: &str) -> Result<DataFrame, String> {
        let tokens = tokenize_expr(expr)?;
        // Validate all column references exist.
        for tok in &tokens {
            if let ExprToken::ColRef(name) = tok {
                if !self.column_names.contains(name) {
                    return Err(format!("with_eval: unknown column '{name}' in expression"));
                }
            }
        }
        let n_rows = if self.data.is_empty() {
            0
        } else {
            self.data[0].len()
        };
        let mut computed: Vec<CellValue> = Vec::with_capacity(n_rows);
        for row_idx in 0..n_rows {
            let val = eval_expr_row(&tokens, self, row_idx)?;
            computed.push(CellValue::Number(val));
        }
        let mut result = self.clone();
        result.column_names.push(col_name.to_string());
        result.data.push(computed);
        Ok(result)
    }

    /// Reshapes this DataFrame from long to wide format (pivot table).
    pub fn pivot_table(
        &self,
        row_key: ColRef,
        col_key: ColRef,
        value_key: ColRef,
        agg_fn: &str,
    ) -> Result<DataFrame, String> {
        let ri = self.resolve_col(row_key)?;
        let ci = self.resolve_col(col_key)?;
        let vi = self.resolve_col(value_key)?;
        let n = self.nrows();

        // Collect unique row-key and col-key values (insertion order).
        let mut row_vals: Vec<CellValue> = Vec::new();
        let mut col_vals: Vec<CellValue> = Vec::new();
        for row in 0..n {
            let rv = self.data[ri][row].clone();
            if !row_vals.contains(&rv) {
                row_vals.push(rv);
            }
            let cv = self.data[ci][row].clone();
            if !col_vals.contains(&cv) {
                col_vals.push(cv);
            }
        }

        // Build result columns: first = row-key label, then one per unique col-key value.
        let mut out_names: Vec<String> = Vec::with_capacity(1 + col_vals.len());
        out_names.push(self.column_names[ri].clone());
        for cv in &col_vals {
            out_names.push(format!("{cv}"));
        }

        let n_rows = row_vals.len();
        let n_out_cols = 1 + col_vals.len();
        let mut out_data: Vec<Vec<CellValue>> = vec![vec![CellValue::Nil; n_rows]; n_out_cols];

        // Fill row-label column.
        for (r, rv) in row_vals.iter().enumerate() {
            out_data[0][r] = rv.clone();
        }

        // Accumulate values into buckets keyed by (row_idx, col_idx).
        let mut buckets: Vec<Vec<Vec<f64>>> = vec![vec![Vec::new(); col_vals.len()]; n_rows];
        let mut first_vals: Vec<Vec<Option<CellValue>>> = vec![vec![None; col_vals.len()]; n_rows];
        let mut last_vals: Vec<Vec<Option<CellValue>>> = vec![vec![None; col_vals.len()]; n_rows];

        for row in 0..n {
            let rv = &self.data[ri][row];
            let cv = &self.data[ci][row];
            let vv = &self.data[vi][row];
            let Some(r_idx) = row_vals.iter().position(|x| x == rv) else {
                continue;
            };
            let Some(c_idx) = col_vals.iter().position(|x| x == cv) else {
                continue;
            };
            if let CellValue::Number(num) = vv {
                buckets[r_idx][c_idx].push(*num);
            }
            if first_vals[r_idx][c_idx].is_none() {
                first_vals[r_idx][c_idx] = Some(vv.clone());
            }
            last_vals[r_idx][c_idx] = Some(vv.clone());
        }

        // Aggregate and fill output data.
        for r_idx in 0..n_rows {
            for c_idx in 0..col_vals.len() {
                let vals = &buckets[r_idx][c_idx];
                let cell = match agg_fn {
                    "sum" => {
                        if vals.is_empty() {
                            CellValue::Nil
                        } else {
                            CellValue::Number(vals.iter().sum::<f64>())
                        }
                    }
                    "count" => CellValue::Number(vals.len() as f64),
                    "first" => first_vals[r_idx][c_idx].clone().unwrap_or(CellValue::Nil),
                    "last" => last_vals[r_idx][c_idx].clone().unwrap_or(CellValue::Nil),
                    _ => {
                        // "mean" is the default
                        if vals.is_empty() {
                            CellValue::Nil
                        } else {
                            CellValue::Number(vals.iter().sum::<f64>() / vals.len() as f64)
                        }
                    }
                };
                out_data[c_idx + 1][r_idx] = cell;
            }
        }

        log::debug!(
            "dataframe: pivot_table → {} rows × {} cols",
            n_rows,
            n_out_cols
        );
        Ok(DataFrame::from_raw(out_names, out_data))
    }

    /// Appends a rolling mean column to a copy of this DataFrame.
    pub fn rolling_mean(
        &self,
        src_col: ColRef,
        window: usize,
        result_col: &str,
    ) -> Result<DataFrame, String> {
        if window == 0 {
            return Err("rolling_mean: window must be >= 1".to_string());
        }
        let ci = self.resolve_col(src_col)?;
        let n = self.nrows();
        let src = &self.data[ci];
        let mut new_col: Vec<CellValue> = Vec::with_capacity(n);
        for i in 0..n {
            let start = i.saturating_sub(window - 1);
            let nums: Vec<f64> = (start..=i)
                .filter_map(|j| {
                    if let CellValue::Number(v) = &src[j] {
                        Some(*v)
                    } else {
                        None
                    }
                })
                .collect();
            if nums.is_empty() {
                new_col.push(CellValue::Nil);
            } else {
                new_col.push(CellValue::Number(
                    nums.iter().sum::<f64>() / nums.len() as f64,
                ));
            }
        }
        let mut out = self.clone_df();
        if out.column_names.contains(&result_col.to_string()) {
            return Err(format!(
                "rolling_mean: column '{result_col}' already exists"
            ));
        }
        out.column_names.push(result_col.to_string());
        out.data.push(new_col);
        log::debug!("dataframe: rolling_mean window={window} → '{result_col}'");
        Ok(out)
    }

    /// Appends a rolling sum column to a copy of this DataFrame.
    /// For each row `i`, sums the `window` most recent rows (including row `i`).
    /// Rows before a full window use the available data. Non-`Number` cells
    /// within the window contribute `0.0`. If the entire window is non-numeric
    /// the result is `Nil`.
    #[allow(clippy::needless_range_loop)]
    pub fn rolling_sum(
        &self,
        src_col: ColRef,
        window: usize,
        result_col: &str,
    ) -> Result<DataFrame, String> {
        if window == 0 {
            return Err("rolling_sum: window must be >= 1".to_string());
        }
        let ci = self.resolve_col(src_col)?;
        let n = self.nrows();
        let src = &self.data[ci];
        let mut new_col: Vec<CellValue> = Vec::with_capacity(n);
        for i in 0..n {
            let start = i.saturating_sub(window - 1);
            let mut sum = 0.0f64;
            let mut has_any = false;
            for j in start..=i {
                if let CellValue::Number(v) = &src[j] {
                    sum += v;
                    has_any = true;
                }
            }
            new_col.push(if has_any {
                CellValue::Number(sum)
            } else {
                CellValue::Nil
            });
        }
        let mut out = self.clone_df();
        if out.column_names.contains(&result_col.to_string()) {
            return Err(format!("rolling_sum: column '{result_col}' already exists"));
        }
        out.column_names.push(result_col.to_string());
        out.data.push(new_col);
        log::debug!("dataframe: rolling_sum window={window} → '{result_col}'");
        Ok(out)
    }

    /// Appends a dense-rank column to a copy of this DataFrame.
    pub fn rank_column(
        &self,
        src_col: ColRef,
        order: &str,
        result_col: &str,
    ) -> Result<DataFrame, String> {
        let ci = self.resolve_col(src_col)?;
        let n = self.nrows();
        let src = &self.data[ci];

        // Collect (row_index, value) for numeric cells only.
        let mut indexed: Vec<(usize, f64)> = (0..n)
            .filter_map(|i| {
                if let CellValue::Number(v) = &src[i] {
                    Some((i, *v))
                } else {
                    None
                }
            })
            .collect();

        // Sort by value according to the requested order.
        if order == "desc" {
            indexed.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        } else {
            indexed.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal));
        }

        // Assign dense ranks (tied values share the same rank, no gaps).
        let mut ranks: Vec<CellValue> = vec![CellValue::Number(0.0); n];
        let mut rank = 1usize;
        let mut prev_val: Option<f64> = None;
        let mut prev_rank = 1usize;
        for (row_idx, val) in &indexed {
            if Some(*val) == prev_val {
                ranks[*row_idx] = CellValue::Number(prev_rank as f64);
            } else {
                ranks[*row_idx] = CellValue::Number(rank as f64);
                prev_rank = rank;
                prev_val = Some(*val);
                rank += 1;
            }
        }

        let mut out = self.clone_df();
        if out.column_names.contains(&result_col.to_string()) {
            return Err(format!("rank_column: column '{result_col}' already exists"));
        }
        out.column_names.push(result_col.to_string());
        out.data.push(ranks);
        log::debug!("dataframe: rank_column order={order} → '{result_col}'");
        Ok(out)
    }
}

// ---------------------------------------------------------------------------
// Expression evaluator (internal helpers for with_eval)
// ---------------------------------------------------------------------------

#[derive(Debug, Clone)]
enum ExprToken {
    Num(f64),
    ColRef(String),
    Op(char),
    LParen,
    RParen,
}

/// Tokenises an arithmetic expression string.
fn tokenize_expr(expr: &str) -> Result<Vec<ExprToken>, String> {
    let mut tokens = Vec::new();
    let mut chars = expr.chars().peekable();
    while let Some(&c) = chars.peek() {
        match c {
            ' ' | '\t' => {
                chars.next();
            }
            '+' | '-' | '*' | '/' => {
                tokens.push(ExprToken::Op(c));
                chars.next();
            }
            '(' => {
                tokens.push(ExprToken::LParen);
                chars.next();
            }
            ')' => {
                tokens.push(ExprToken::RParen);
                chars.next();
            }
            '0'..='9' | '.' => {
                let mut s = String::new();
                while let Some(&d) = chars.peek() {
                    if d.is_ascii_digit() || d == '.' {
                        s.push(d);
                        chars.next();
                    } else {
                        break;
                    }
                }
                let v: f64 = s
                    .parse()
                    .map_err(|_| format!("with_eval: invalid number '{s}'"))?;
                tokens.push(ExprToken::Num(v));
            }
            'a'..='z' | 'A'..='Z' | '_' => {
                let mut s = String::new();
                while let Some(&d) = chars.peek() {
                    if d.is_alphanumeric() || d == '_' {
                        s.push(d);
                        chars.next();
                    } else {
                        break;
                    }
                }
                tokens.push(ExprToken::ColRef(s));
            }
            other => return Err(format!("with_eval: unexpected character '{other}'")),
        }
    }
    Ok(tokens)
}

/// Evaluates a flat (no parentheses) token sequence for a single row using
fn eval_expr_row(tokens: &[ExprToken], df: &DataFrame, row_idx: usize) -> Result<f64, String> {
    // Convert tokens to values, resolving column references.
    let mut values: Vec<f64> = Vec::new();
    let mut ops: Vec<char> = Vec::new();
    let mut expect_value = true;
    for tok in tokens {
        match tok {
            ExprToken::Num(v) => {
                if !expect_value {
                    return Err("with_eval: unexpected number".to_string());
                }
                values.push(*v);
                expect_value = false;
            }
            ExprToken::ColRef(name) => {
                if !expect_value {
                    return Err(format!("with_eval: unexpected column '{name}'"));
                }
                let col_idx = df
                    .column_names
                    .iter()
                    .position(|c| c == name)
                    .ok_or_else(|| format!("with_eval: column '{name}' not found"))?;
                let v = match df.data[col_idx].get(row_idx) {
                    Some(CellValue::Number(f)) => *f,
                    _ => 0.0,
                };
                values.push(v);
                expect_value = false;
            }
            ExprToken::Op(op) => {
                if expect_value && *op == '-' {
                    // Unary minus: push a -1 multiplier
                    values.push(-1.0);
                    ops.push('*');
                } else {
                    if expect_value {
                        return Err(format!("with_eval: unexpected operator '{op}'"));
                    }
                    ops.push(*op);
                    expect_value = true;
                }
            }
            ExprToken::LParen | ExprToken::RParen => {
                // Parentheses not yet supported in the simple evaluator.
                return Err("with_eval: parentheses are not supported".to_string());
            }
        }
    }
    if expect_value {
        return Err("with_eval: expression ends with operator".to_string());
    }
    // Apply * and / first.
    let mut i = 0;
    while i < ops.len() {
        if ops[i] == '*' || ops[i] == '/' {
            let r = if ops[i] == '*' {
                values[i] * values[i + 1]
            } else if values[i + 1] == 0.0 {
                return Err("with_eval: division by zero".to_string());
            } else {
                values[i] / values[i + 1]
            };
            values[i] = r;
            values.remove(i + 1);
            ops.remove(i);
        } else {
            i += 1;
        }
    }
    // Apply + and -.
    let mut result = values[0];
    for (op, &v) in ops.iter().zip(values[1..].iter()) {
        match op {
            '+' => result += v,
            '-' => result -= v,
            _ => {}
        }
    }
    Ok(result)
}

impl Default for DataFrame {
    fn default() -> Self {
        Self::new()
    }
}

// ---------------------------------------------------------------------------
// Database implementation
// ---------------------------------------------------------------------------

impl Database {
    /// Create an empty database with no tables.
    pub fn new() -> Self {
        Self {
            tables: HashMap::new(),
        }
    }

    /// Add a table by name or replace the existing table with the same name.
    pub fn add_table(&mut self, name: &str, df: DataFrame) {
        self.tables.insert(name.to_string(), df);
    }

    /// Get a shared reference to a table by name.
    pub fn get_table(&self, name: &str) -> Option<&DataFrame> {
        self.tables.get(name)
    }

    /// Get a mutable reference to a table by name.
    pub fn get_table_mut(&mut self, name: &str) -> Option<&mut DataFrame> {
        self.tables.get_mut(name)
    }

    /// Remove a table by name; return error if not found.
    pub fn remove_table(&mut self, name: &str) -> Result<(), String> {
        if self.tables.remove(name).is_none() {
            return Err(format!("table not found: {name}"));
        }
        Ok(())
    }

    /// Check whether a table with the given name exists.
    pub fn has_table(&self, name: &str) -> bool {
        self.tables.contains_key(name)
    }

    /// Return the names of all tables, sorted alphabetically.
    pub fn list_tables(&self) -> Vec<String> {
        let mut names: Vec<String> = self.tables.keys().cloned().collect();
        names.sort();
        names
    }

    /// Return the number of tables.
    pub fn table_count(&self) -> usize {
        self.tables.len()
    }

    /// Remove all tables. After this call the container is in the same state as immediately after construction.
    pub fn clear(&mut self) {
        self.tables.clear();
    }

    /// Merge all tables from `other` into this database.
    pub fn merge(&mut self, other: Database) {
        for (name, df) in other.tables {
            self.tables.insert(name, df);
        }
    }

    /// Deep-clone this Database and all contained DataFrames.
    pub fn clone_db(&self) -> Database {
        let mut db = Database::new();
        for (name, df) in &self.tables {
            db.add_table(name, df.clone_df());
        }
        db
    }
}

impl Default for Database {
    fn default() -> Self {
        Self::new()
    }
}

// ---------------------------------------------------------------------------
// Aggregation function type
// ---------------------------------------------------------------------------

/// Aggregation function variants for group-by and pivot operations.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum AggFn {
    /// Arithmetic mean of numeric values in the group.
    Mean,
    /// Sum of numeric values in the group.
    Sum,
    /// Minimum numeric value in the group.
    Min,
    /// Maximum numeric value in the group.
    Max,
    /// Count of non-nil values in the group.
    Count,
    /// First value encountered in the group (preserves order).
    First,
    /// Last value encountered in the group (preserves order).
    Last,
}

impl AggFn {
    /// Parse a string into an `AggFn`.
    pub fn parse(s: &str) -> Result<Self, String> {
        match s.to_lowercase().as_str() {
            "mean" => Ok(Self::Mean),
            "sum" => Ok(Self::Sum),
            "min" => Ok(Self::Min),
            "max" => Ok(Self::Max),
            "count" => Ok(Self::Count),
            "first" => Ok(Self::First),
            "last" => Ok(Self::Last),
            other => Err(format!(
                "unknown aggregation function '{}'; expected mean|sum|min|max|count|first|last",
                other
            )),
        }
    }
}
