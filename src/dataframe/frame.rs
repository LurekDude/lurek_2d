//! Core DataFrame and Database types with CellValue cells.

use std::cmp::Ordering;
use std::collections::HashMap;

/// A single cell value in a DataFrame column.
///
/// # Variants
/// - `Nil` — Nil variant.
/// - `Number` — Number variant.
/// - `Text` — Text variant.
/// - `Bool` — Bool variant.
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
    /// Returns `true` if this cell is `Nil`.
    ///
    /// # Returns
    /// `bool`.
    pub fn is_nil(&self) -> bool {
        matches!(self, CellValue::Nil)
    }

    /// Returns the contained number, or `None`.
    ///
    /// # Returns
    /// `Option<f64>`.
    pub fn as_number(&self) -> Option<f64> {
        match self {
            CellValue::Number(n) => Some(*n),
            _ => None,
        }
    }

    /// Returns the contained text as a string slice, or `None`.
    ///
    /// # Returns
    /// `Option<&str>`.
    pub fn as_text(&self) -> Option<&str> {
        match self {
            CellValue::Text(s) => Some(s.as_str()),
            _ => None,
        }
    }

    /// Returns the contained boolean, or `None`.
    ///
    /// # Returns
    /// `Option<bool>`.
    pub fn as_bool(&self) -> Option<bool> {
        match self {
            CellValue::Bool(b) => Some(*b),
            _ => None,
        }
    }

    /// Comparison for sorting. Nil sorts to end; among non-nil values
    ///
    /// # Parameters
    /// - `other` — `&CellValue`.
    ///
    /// # Returns
    /// `Ordering`.
    /// the ordering is Number < Text < Bool for cross-type comparison.
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
///
/// # Variants
/// - `Name` — Name variant.
/// - `Index` — Index variant.
///
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
///
/// # Fields
/// - `column_names` — `Vec<String>`.
/// - `data` — `Vec<Vec<CellValue>>`.
///
/// Data is stored as `data[col_index][row_index]`. All public methods
/// that accept row indices use **0-based** indexing; the Lua binding
/// layer is responsible for converting from 1-based.
pub struct DataFrame {
    pub(crate) column_names: Vec<String>,
    pub(crate) data: Vec<Vec<CellValue>>,
}

/// Named catalog of DataFrames.
pub struct Database {
    tables: HashMap<String, DataFrame>,
}

// ---------------------------------------------------------------------------
// Simple xorshift64 RNG for deterministic random data generation
// ---------------------------------------------------------------------------

/// Minimal xorshift64 PRNG for deterministic data generation.
struct Xorshift64 {
    state: u64,
}

impl Xorshift64 {
    /// Create a new RNG with the given seed. Seed of 0 is replaced with 1.
    fn new(seed: u64) -> Self {
        Self {
            state: if seed == 0 { 1 } else { seed },
        }
    }

    /// Return the next pseudo-random u64.
    fn next_u64(&mut self) -> u64 {
        let mut x = self.state;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.state = x;
        x
    }

    /// Return a random f64 in [0, 1).
    fn next_f64(&mut self) -> f64 {
        (self.next_u64() & 0x001F_FFFF_FFFF_FFFF) as f64 / (1u64 << 53) as f64
    }

    /// Return a random usize in [0, max).
    fn next_usize(&mut self, max: usize) -> usize {
        (self.next_u64() % max as u64) as usize
    }
}

// ---------------------------------------------------------------------------
// DataFrame implementation
// ---------------------------------------------------------------------------

impl DataFrame {
    /// Create an empty DataFrame with no columns or rows.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            column_names: Vec::new(),
            data: Vec::new(),
        }
    }

    /// Return the number of rows.
    ///
    /// # Returns
    /// `usize`.
    pub fn nrows(&self) -> usize {
        if self.data.is_empty() {
            0
        } else {
            self.data[0].len()
        }
    }

    /// Return the number of columns.
    ///
    /// # Returns
    /// `usize`.
    pub fn ncols(&self) -> usize {
        self.column_names.len()
    }

    /// Return the column names.
    ///
    /// # Returns
    /// `&[String]`.
    pub fn columns(&self) -> &[String] {
        &self.column_names
    }

    /// Alias for `nrows()`.
    ///
    /// # Returns
    /// `usize`.
    pub fn count(&self) -> usize {
        self.nrows()
    }

    /// Resolve a `ColRef` to a 0-based column index.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<usize, String>`.
    ///
    /// `ColRef::Index` is treated as 1-based; this method subtracts 1.
    /// Returns an error if the column is not found or the index is out of range.
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
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `default` — `CellValue`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn add_column(&mut self, name: &str, default: CellValue) -> Result<(), String> {
        if self.column_names.contains(&name.to_string()) {
            return Err(format!("column already exists: {name}"));
        }
        let n = self.nrows();
        self.column_names.push(name.to_string());
        self.data.push(vec![default; n]);
        Ok(())
    }

    /// Remove a column by reference.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn remove_column(&mut self, col: ColRef) -> Result<(), String> {
        let idx = self.resolve_col(col)?;
        self.column_names.remove(idx);
        self.data.remove(idx);
        Ok(())
    }

    /// Rename a column.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    /// - `new_name` — `&str`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn rename_column(&mut self, col: ColRef, new_name: &str) -> Result<(), String> {
        let idx = self.resolve_col(col)?;
        if self.column_names.contains(&new_name.to_string()) {
            return Err(format!("column already exists: {new_name}"));
        }
        self.column_names[idx] = new_name.to_string();
        Ok(())
    }

    /// Return a reference to the column data.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<&[CellValue], String>`.
    pub fn get_column(&self, col: ColRef) -> Result<&[CellValue], String> {
        let idx = self.resolve_col(col)?;
        Ok(&self.data[idx])
    }

    /// Add a row from name-value pairs. Missing columns receive `Nil`.
    ///
    /// # Parameters
    /// - `values` — `&[(String, CellValue)]`.
    ///
    /// # Returns
    /// `usize`.
    /// Returns the 0-based row index of the new row.
    pub fn add_row(&mut self, values: &[(String, CellValue)]) -> usize {
        let row_idx = self.nrows();
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

    /// Remove a row by 0-based index.
    ///
    /// # Parameters
    /// - `row` — `usize`.
    ///
    /// # Returns
    /// `Result<(), String>`.
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
    ///
    /// # Parameters
    /// - `row` — `usize`.
    ///
    /// # Returns
    /// `Result<Vec<(String, CellValue)>, String>`.
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

    /// Get a single cell value (0-based row, ColRef for column).
    ///
    /// # Parameters
    /// - `row` — `usize`.
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<CellValue, String>`.
    pub fn get_value(&self, row: usize, col: ColRef) -> Result<CellValue, String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        if row >= n {
            return Err(format!("row index {row} out of range (0..{n})"));
        }
        Ok(self.data[ci][row].clone())
    }

    /// Set a single cell value (0-based row, ColRef for column).
    ///
    /// # Parameters
    /// - `row` — `usize`.
    /// - `col` — `ColRef`.
    /// - `val` — `CellValue`.
    ///
    /// # Returns
    /// `Result<(), String>`.
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
    ///
    /// # Returns
    /// `DataFrame`.
    pub fn clone_df(&self) -> DataFrame {
        DataFrame {
            column_names: self.column_names.clone(),
            data: self.data.clone(),
        }
    }

    /// Create a DataFrame from raw column names and column-major data.
    ///
    /// # Parameters
    /// - `column_names` — `Vec<String>`.
    /// - `data` — `Vec<Vec<CellValue>>`.
    ///
    /// # Returns
    /// `Self`.
    ///
    /// Used internally by query/serial code. Columns and data must have
    /// matching lengths, and all column vectors must have the same length.
    pub fn from_raw(column_names: Vec<String>, data: Vec<Vec<CellValue>>) -> Self {
        Self { column_names, data }
    }

    /// Get a reference to the underlying column-major data.
    ///
    /// # Returns
    /// `&Vec<Vec<CellValue>>`.
    pub fn raw_data(&self) -> &Vec<Vec<CellValue>> {
        &self.data
    }

    /// Generate a DataFrame with random data.
    ///
    /// # Parameters
    /// - `defs` — `&[(String, String)]`.
    /// - `n_rows` — `usize`.
    /// - `seed` — `Option<u64>`.
    ///
    /// # Returns
    /// `DataFrame`.
    ///
    /// `defs` is a slice of `(column_name, type_hint)` pairs. Supported type hints:
    /// `"int"`, `"float"`, `"bool"`, `"name"`, `"id"`, `"string"`, `"email"`,
    /// `"date"`, `"phone"`, `"uuid"`, `"sentence"`.
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
    /// Create an empty database.
    ///
    /// # Returns
    /// `Self`.
    pub fn new() -> Self {
        Self {
            tables: HashMap::new(),
        }
    }

    /// Add or replace a table.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    /// - `df` — `DataFrame`.
    pub fn add_table(&mut self, name: &str, df: DataFrame) {
        self.tables.insert(name.to_string(), df);
    }

    /// Get a shared reference to a table by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&DataFrame>`.
    pub fn get_table(&self, name: &str) -> Option<&DataFrame> {
        self.tables.get(name)
    }

    /// Get a mutable reference to a table by name.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Option<&mut DataFrame>`.
    pub fn get_table_mut(&mut self, name: &str) -> Option<&mut DataFrame> {
        self.tables.get_mut(name)
    }

    /// Remove a table by name. Returns error if not found.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn remove_table(&mut self, name: &str) -> Result<(), String> {
        if self.tables.remove(name).is_none() {
            return Err(format!("table not found: {name}"));
        }
        Ok(())
    }

    /// Check whether a table with the given name exists.
    ///
    /// # Parameters
    /// - `name` — `&str`.
    ///
    /// # Returns
    /// `bool`.
    pub fn has_table(&self, name: &str) -> bool {
        self.tables.contains_key(name)
    }

    /// Return the names of all tables, sorted alphabetically.
    ///
    /// # Returns
    /// `Vec<String>`.
    pub fn list_tables(&self) -> Vec<String> {
        let mut names: Vec<String> = self.tables.keys().cloned().collect();
        names.sort();
        names
    }

    /// Return the number of tables.
    ///
    /// # Returns
    /// `usize`.
    pub fn table_count(&self) -> usize {
        self.tables.len()
    }

    /// Remove all tables.
    pub fn clear(&mut self) {
        self.tables.clear();
    }

    /// Merge all tables from `other` into this database.
    ///
    /// # Parameters
    /// - `other` — `Database`.
    /// On name conflict, the table from `other` overwrites.
    pub fn merge(&mut self, other: Database) {
        for (name, df) in other.tables {
            self.tables.insert(name, df);
        }
    }
}

impl Default for Database {
    fn default() -> Self {
        Self::new()
    }
}
