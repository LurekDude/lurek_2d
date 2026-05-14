//! Own core tabular data types for the dataframe module: typed cell values, column selectors,
//! column-major frame storage, row iteration, named-table database container, and aggregation
//! mode enum. Query, sort, serialization, and vectorized logic live in sibling files and extend
//! the types here through separate `impl` blocks. Primary consumer is `src/lua_api/dataframe_api.rs`.
//! No graphics, audio, or physics logic belongs here.

use crate::dataframe::rng::Xorshift64;
use std::cmp::Ordering;
use std::collections::HashMap;
#[derive(Debug, Clone, PartialEq)]
/// Hold typed value stored in one dataframe cell.
pub enum CellValue {
    /// Represent missing value.
    Nil,
    /// Represent numeric value.
    Number(f64),
    /// Represent string value.
    Text(String),
    /// Represent boolean value.
    Bool(bool),
}
impl CellValue {
    /// Return true when cell is nil.
    pub fn is_nil(&self) -> bool {
        matches!(self, CellValue::Nil)
    }
    /// Return numeric value when cell stores number.
    pub fn as_number(&self) -> Option<f64> {
        match self {
            CellValue::Number(n) => Some(*n),
            _ => None,
        }
    }
    /// Return text slice when cell stores text.
    pub fn as_text(&self) -> Option<&str> {
        match self {
            CellValue::Text(s) => Some(s.as_str()),
            _ => None,
        }
    }
    /// Return bool value when cell stores boolean.
    pub fn as_bool(&self) -> Option<bool> {
        match self {
            CellValue::Bool(b) => Some(*b),
            _ => None,
        }
    }
    /// Compare values for deterministic sort ordering.
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
            (CellValue::Number(_), _) => Ordering::Less,
            (_, CellValue::Number(_)) => Ordering::Greater,
            (CellValue::Text(_), CellValue::Bool(_)) => Ordering::Less,
            (CellValue::Bool(_), CellValue::Text(_)) => Ordering::Greater,
        }
    }
}
/// Implement `Display` for `CellValue` used by string-table rendering and debug output.
impl std::fmt::Display for CellValue {
    /// Format one cell value as user-facing text.
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
#[derive(Debug, Clone)]
/// Select column by name or one-based index.
pub enum ColRef {
    /// Select column by exact name.
    Name(String),
    /// Select column by one-based position.
    Index(usize),
}
#[derive(Clone)]
/// Hold columnar dataframe storage.
pub struct DataFrame {
    /// Store ordered column names.
    pub(crate) column_names: Vec<String>,
    /// Store column-major cell values.
    pub(crate) data: Vec<Vec<CellValue>>,
}
/// Iterate rows as vectors of column-name and cell references.
pub struct DataFrameRowIter<'a> {
    /// Store source dataframe reference.
    df: &'a DataFrame,
    /// Store next row index to emit.
    next_row: usize,
}
impl<'a> Iterator for DataFrameRowIter<'a> {
    type Item = Vec<(&'a str, &'a CellValue)>;
    /// Return next row view or `None` when iteration ends.
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
/// Hold named tables for SQL-like database queries.
pub struct Database {
    /// Store table map keyed by table name.
    tables: HashMap<String, DataFrame>,
}
impl DataFrame {
    /// Create empty dataframe.
    pub fn new() -> Self {
        log::debug!("dataframe: new empty DataFrame created");
        Self {
            column_names: Vec::new(),
            data: Vec::new(),
        }
    }
    /// Return number of rows.
    pub fn nrows(&self) -> usize {
        if self.data.is_empty() {
            0
        } else {
            self.data[0].len()
        }
    }
    /// Return number of columns.
    pub fn ncols(&self) -> usize {
        self.column_names.len()
    }
    /// Return ordered column names.
    pub fn columns(&self) -> &[String] {
        &self.column_names
    }
    /// Return row count alias.
    pub fn count(&self) -> usize {
        self.nrows()
    }
    /// Resolve column selector to zero-based index.
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
    /// Add new column filled with default values.
    pub fn add_column(&mut self, name: &str, default: CellValue) -> Result<(), String> {
        if self.column_names.contains(&name.to_string()) {
            return Err(format!("column already exists: {name}"));
        }
        let n = self.nrows();
        self.column_names.push(name.to_string());
        self.data.push(vec![default; n]);
        Ok(())
    }
    /// Remove selected column.
    pub fn remove_column(&mut self, col: ColRef) -> Result<(), String> {
        let idx = self.resolve_col(col)?;
        self.column_names.remove(idx);
        self.data.remove(idx);
        Ok(())
    }
    /// Rename selected column.
    pub fn rename_column(&mut self, col: ColRef, new_name: &str) -> Result<(), String> {
        let idx = self.resolve_col(col)?;
        if self.column_names.contains(&new_name.to_string()) {
            return Err(format!("column already exists: {new_name}"));
        }
        self.column_names[idx] = new_name.to_string();
        Ok(())
    }
    /// Return selected column slice.
    pub fn get_column(&self, col: ColRef) -> Result<&[CellValue], String> {
        let idx = self.resolve_col(col)?;
        Ok(&self.data[idx])
    }
    /// Append row from sparse key-value input and return row index.
    pub fn add_row(&mut self, values: &[(String, CellValue)]) -> usize {
        let row_idx = self.nrows();
        for (key, _) in values.iter() {
            if !self.column_names.contains(key) {
                self.column_names.push(key.clone());
                self.data.push(vec![CellValue::Nil; row_idx]);
            }
        }
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
    /// Remove row by index.
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
    /// Return cloned row values by index.
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
    /// Return iterator over row views.
    pub fn iter_rows(&self) -> DataFrameRowIter<'_> {
        DataFrameRowIter {
            df: self,
            next_row: 0,
        }
    }
    /// Return cloned cell value at row and column.
    pub fn get_value(&self, row: usize, col: ColRef) -> Result<CellValue, String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        if row >= n {
            return Err(format!("row index {row} out of range (0..{n})"));
        }
        Ok(self.data[ci][row].clone())
    }
    /// Set cell value at row and column.
    pub fn set_value(&mut self, row: usize, col: ColRef, val: CellValue) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        if row >= n {
            return Err(format!("row index {row} out of range (0..{n})"));
        }
        self.data[ci][row] = val;
        Ok(())
    }
    /// Clone dataframe deeply.
    pub fn clone_df(&self) -> DataFrame {
        DataFrame {
            column_names: self.column_names.clone(),
            data: self.data.clone(),
        }
    }
    /// Return mutable column vector for selected column.
    pub fn column_data_mut(&mut self, col: ColRef) -> Result<&mut Vec<CellValue>, String> {
        let ci = self.resolve_col(col)?;
        Ok(&mut self.data[ci])
    }
    /// Build dataframe from raw column names and data vectors.
    pub fn from_raw(column_names: Vec<String>, data: Vec<Vec<CellValue>>) -> Self {
        Self { column_names, data }
    }
    /// Build dataframe from row-major data.
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
    /// Return raw column storage reference.
    pub fn raw_data(&self) -> &Vec<Vec<CellValue>> {
        &self.data
    }
    /// Generate random dataframe from typed column definitions.
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
                        let n_words = 4 + rng.next_usize(7);
                        let sentence: Vec<&str> = (0..n_words)
                            .map(|_| words[rng.next_usize(words.len())])
                            .collect();
                        let mut s = sentence.join(" ");
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
    /// Evaluate arithmetic expression per row and append result column.
    pub fn with_eval(&self, col_name: &str, expr: &str) -> Result<DataFrame, String> {
        let tokens = tokenize_expr(expr)?;
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
    /// Build pivot table from row key, column key, and value key.
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
        let mut out_names: Vec<String> = Vec::with_capacity(1 + col_vals.len());
        out_names.push(self.column_names[ri].clone());
        for cv in &col_vals {
            out_names.push(format!("{cv}"));
        }
        let n_rows = row_vals.len();
        let n_out_cols = 1 + col_vals.len();
        let mut out_data: Vec<Vec<CellValue>> = vec![vec![CellValue::Nil; n_rows]; n_out_cols];
        for (r, rv) in row_vals.iter().enumerate() {
            out_data[0][r] = rv.clone();
        }
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
    /// Compute rolling mean and return dataframe with appended column.
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
    #[allow(clippy::needless_range_loop)]
    /// Compute rolling sum and return dataframe with appended column.
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
    /// Compute rank for numeric column and return dataframe with rank column.
    pub fn rank_column(
        &self,
        src_col: ColRef,
        order: &str,
        result_col: &str,
    ) -> Result<DataFrame, String> {
        let ci = self.resolve_col(src_col)?;
        let n = self.nrows();
        let src = &self.data[ci];
        let mut indexed: Vec<(usize, f64)> = (0..n)
            .filter_map(|i| {
                if let CellValue::Number(v) = &src[i] {
                    Some((i, *v))
                } else {
                    None
                }
            })
            .collect();
        if order == "desc" {
            indexed.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        } else {
            indexed.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal));
        }
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
#[derive(Debug, Clone)]
/// Store tokenized arithmetic expression items for `with_eval`.
enum ExprToken {
    /// Store numeric literal.
    Num(f64),
    /// Store column reference token.
    ColRef(String),
    /// Store arithmetic operator token.
    Op(char),
    /// Store left parenthesis token.
    LParen,
    /// Store right parenthesis token.
    RParen,
}
/// Tokenize arithmetic expression string for per-row evaluation.
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
/// Evaluate tokenized arithmetic expression for one dataframe row.
fn eval_expr_row(tokens: &[ExprToken], df: &DataFrame, row_idx: usize) -> Result<f64, String> {
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
                return Err("with_eval: parentheses are not supported".to_string());
            }
        }
    }
    if expect_value {
        return Err("with_eval: expression ends with operator".to_string());
    }
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
/// Implement `Default` for `DataFrame` by delegating to `DataFrame::new`.
impl Default for DataFrame {
    /// Create default empty dataframe.
    fn default() -> Self {
        Self::new()
    }
}
impl Database {
    /// Create empty database.
    pub fn new() -> Self {
        Self {
            tables: HashMap::new(),
        }
    }
    /// Insert or replace table by name.
    pub fn add_table(&mut self, name: &str, df: DataFrame) {
        self.tables.insert(name.to_string(), df);
    }
    /// Return immutable table reference by name.
    pub fn get_table(&self, name: &str) -> Option<&DataFrame> {
        self.tables.get(name)
    }
    /// Return mutable table reference by name.
    pub fn get_table_mut(&mut self, name: &str) -> Option<&mut DataFrame> {
        self.tables.get_mut(name)
    }
    /// Remove table by name.
    pub fn remove_table(&mut self, name: &str) -> Result<(), String> {
        if self.tables.remove(name).is_none() {
            return Err(format!("table not found: {name}"));
        }
        Ok(())
    }
    /// Return true when table exists.
    pub fn has_table(&self, name: &str) -> bool {
        self.tables.contains_key(name)
    }
    /// Return sorted list of table names.
    pub fn list_tables(&self) -> Vec<String> {
        let mut names: Vec<String> = self.tables.keys().cloned().collect();
        names.sort();
        names
    }
    /// Return number of tables.
    pub fn table_count(&self) -> usize {
        self.tables.len()
    }
    /// Remove all tables.
    pub fn clear(&mut self) {
        self.tables.clear();
    }
    /// Merge another database into self by table name.
    pub fn merge(&mut self, other: Database) {
        for (name, df) in other.tables {
            self.tables.insert(name, df);
        }
    }
    /// Clone database deeply.
    pub fn clone_db(&self) -> Database {
        let mut db = Database::new();
        for (name, df) in &self.tables {
            db.add_table(name, df.clone_df());
        }
        db
    }
}
/// Implement `Default` for `Database` by delegating to `Database::new`.
impl Default for Database {
    /// Create default empty database.
    fn default() -> Self {
        Self::new()
    }
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
/// Select aggregation mode for grouped operations.
pub enum AggFn {
    /// Compute arithmetic mean.
    Mean,
    /// Compute numeric sum.
    Sum,
    /// Compute numeric minimum.
    Min,
    /// Compute numeric maximum.
    Max,
    /// Compute non-nil count.
    Count,
    /// Select first seen value.
    First,
    /// Select last seen value.
    Last,
}
impl AggFn {
    /// Parse aggregation label and return mode or error.
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
