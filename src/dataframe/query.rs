//! DataFrame query, filter, sort, join, analytics, and mutation.
//!
//! This module is part of Luna2D's `dataframe` subsystem and provides the implementation
//! details for query-related operations and data management.
//! Primary functions: `filter()`, `sort()`, `head()`, `tail()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `luna.*` Lua API for the scripting interface.

use crate::dataframe::frame::{CellValue, ColRef, DataFrame};

// ---------------------------------------------------------------------------
// Simple xorshift64 RNG (duplicated here to avoid coupling to frame module)
// ---------------------------------------------------------------------------

/// Minimal xorshift64 PRNG for sample shuffling.
struct Xorshift64 {
    state: u64,
}

impl Xorshift64 {
    fn new(seed: u64) -> Self {
        Self {
            state: if seed == 0 { 1 } else { seed },
        }
    }

    fn next_u64(&mut self) -> u64 {
        let mut x = self.state;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.state = x;
        x
    }

    fn next_usize(&mut self, max: usize) -> usize {
        (self.next_u64() % max as u64) as usize
    }
}

// ---------------------------------------------------------------------------
// Query methods
// ---------------------------------------------------------------------------

impl DataFrame {
    /// Filter rows where `col op val` is true.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    /// - `op` — `&str`.
    /// - `val` — `&CellValue`.
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    ///
    /// Supported ops: `==`, `!=`, `<`, `<=`, `>`, `>=`, `contains`.
    pub fn filter(&self, col: ColRef, op: &str, val: &CellValue) -> Result<DataFrame, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();

        let mut keep = Vec::new();
        for (row, cell) in data[ci].iter().enumerate() {
            let passes = match op {
                "==" => cell == val,
                "!=" => cell != val,
                "<" => cell.cmp_for_sort(val) == std::cmp::Ordering::Less,
                "<=" => {
                    let ord = cell.cmp_for_sort(val);
                    ord == std::cmp::Ordering::Less || ord == std::cmp::Ordering::Equal
                }
                ">" => cell.cmp_for_sort(val) == std::cmp::Ordering::Greater,
                ">=" => {
                    let ord = cell.cmp_for_sort(val);
                    ord == std::cmp::Ordering::Greater || ord == std::cmp::Ordering::Equal
                }
                "contains" => {
                    if let (CellValue::Text(haystack), CellValue::Text(needle)) = (cell, val) {
                        haystack.contains(needle.as_str())
                    } else {
                        false
                    }
                }
                _ => return Err(format!("unsupported filter op: {op}")),
            };
            if passes {
                keep.push(row);
            }
        }

        Ok(self.extract_rows(&keep))
    }

    /// Sort by column, stable sort. Nils sort to end.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    /// - `ascending` — `bool`.
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    pub fn sort(&self, col: ColRef, ascending: bool) -> Result<DataFrame, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        let nrows = self.nrows();

        let mut indices: Vec<usize> = (0..nrows).collect();
        indices.sort_by(|&a, &b| {
            let ord = data[ci][a].cmp_for_sort(&data[ci][b]);
            if ascending {
                ord
            } else {
                ord.reverse()
            }
        });

        Ok(self.extract_rows(&indices))
    }

    /// Return the first `n` rows. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `DataFrame`.
    pub fn head(&self, n: usize) -> DataFrame {
        let take = n.min(self.nrows());
        let indices: Vec<usize> = (0..take).collect();
        self.extract_rows(&indices)
    }

    /// Return the last `n` rows. Consult the module-level documentation for the broader usage context and preconditions.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    ///
    /// # Returns
    /// `DataFrame`.
    pub fn tail(&self, n: usize) -> DataFrame {
        let nrows = self.nrows();
        let skip = nrows.saturating_sub(n);
        let indices: Vec<usize> = (skip..nrows).collect();
        self.extract_rows(&indices)
    }

    /// Return a slice of rows from `start` to `end` (0-based, inclusive on both ends).
    ///
    /// # Parameters
    /// - `start` — `usize`.
    /// - `end` — `usize`.
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    pub fn slice(&self, start: usize, end: usize) -> Result<DataFrame, String> {
        let nrows = self.nrows();
        if start >= nrows {
            return Err(format!("start index {start} out of range (0..{nrows})"));
        }
        let end = end.min(nrows.saturating_sub(1));
        if start > end {
            return Ok(DataFrame::from_raw(
                self.columns().to_vec(),
                vec![Vec::new(); self.ncols()],
            ));
        }
        let indices: Vec<usize> = (start..=end).collect();
        Ok(self.extract_rows(&indices))
    }

    /// Column projection: select a subset of columns.
    ///
    /// # Parameters
    /// - `cols` — `&[ColRef]`.
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    pub fn select_columns(&self, cols: &[ColRef]) -> Result<DataFrame, String> {
        let mut new_names = Vec::new();
        let mut new_data = Vec::new();
        let data = self.raw_data();

        for col in cols {
            let ci = self.resolve_col(col.clone())?;
            new_names.push(self.columns()[ci].clone());
            new_data.push(data[ci].clone());
        }

        Ok(DataFrame::from_raw(new_names, new_data))
    }

    /// Return unique values in a column (O(n^2) dedup).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<Vec<CellValue>, String>`.
    pub fn unique(&self, col: ColRef) -> Result<Vec<CellValue>, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        let mut result: Vec<CellValue> = Vec::new();
        for val in &data[ci] {
            if !result.iter().any(|v| v == val) {
                result.push(val.clone());
            }
        }
        Ok(result)
    }

    /// Group rows by the value in a column. Returns (group_key, sub-DataFrame) pairs.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<Vec<(CellValue, DataFrame)>, String>`.
    pub fn group_by(&self, col: ColRef) -> Result<Vec<(CellValue, DataFrame)>, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();

        let mut groups: Vec<(CellValue, Vec<usize>)> = Vec::new();
        for (row, key) in data[ci].iter().enumerate() {
            if let Some(g) = groups.iter_mut().find(|(k, _)| k == key) {
                g.1.push(row);
            } else {
                groups.push((key.clone(), vec![row]));
            }
        }

        let result = groups
            .into_iter()
            .map(|(key, rows)| (key, self.extract_rows(&rows)))
            .collect();
        Ok(result)
    }

    /// Join with another DataFrame on matching columns.
    ///
    /// # Parameters
    /// - `other` — `&DataFrame`.
    /// - `this_col` — `ColRef`.
    /// - `other_col` — `ColRef`.
    /// - `join_type` — `&str`.
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    ///
    ///
    /// `join_type`: `"inner"` or `"left"`. `"right"` logs a warning and returns empty.
    pub fn join(
        &self,
        other: &DataFrame,
        this_col: ColRef,
        other_col: ColRef,
        join_type: &str,
    ) -> Result<DataFrame, String> {
        if join_type == "right" {
            log::warn!("right join not yet implemented, returning empty DataFrame");
            let mut all_cols: Vec<String> = self.columns().to_vec();
            for name in other.columns() {
                if !all_cols.contains(name) {
                    all_cols.push(name.clone());
                }
            }
            return Ok(DataFrame::from_raw(
                all_cols.clone(),
                vec![Vec::new(); all_cols.len()],
            ));
        }

        let tci = self.resolve_col(this_col)?;
        let oci = other.resolve_col(other_col)?;
        let t_data = self.raw_data();
        let o_data = other.raw_data();

        // Build merged column list: all of self, then other columns not in self
        let mut col_names: Vec<String> = self.columns().to_vec();
        let mut other_col_indices: Vec<usize> = Vec::new();
        for (oi, name) in other.columns().iter().enumerate() {
            if !col_names.contains(name) {
                col_names.push(name.clone());
                other_col_indices.push(oi);
            }
        }

        let total_cols = col_names.len();
        let mut new_data: Vec<Vec<CellValue>> = vec![Vec::new(); total_cols];

        for (t_row, t_key) in t_data[tci].iter().enumerate() {
            let mut matched = false;

            #[allow(clippy::needless_range_loop)]
            for o_row in 0..o_data[oci].len() {
                if *t_key == o_data[oci][o_row] {
                    matched = true;
                    // Add self columns
                    for ci in 0..self.ncols() {
                        new_data[ci].push(t_data[ci][t_row].clone());
                    }
                    // Add other's extra columns
                    for (extra_i, &oi) in other_col_indices.iter().enumerate() {
                        new_data[self.ncols() + extra_i].push(o_data[oi][o_row].clone());
                    }
                }
            }

            if !matched && join_type == "left" {
                // Add self columns
                for ci in 0..self.ncols() {
                    new_data[ci].push(t_data[ci][t_row].clone());
                }
                // Nil for other's columns
                for extra_i in 0..other_col_indices.len() {
                    new_data[self.ncols() + extra_i].push(CellValue::Nil);
                }
            }
        }

        Ok(DataFrame::from_raw(col_names, new_data))
    }

    /// Append rows from another DataFrame in-place. Adds missing columns as Nil.
    ///
    /// # Parameters
    /// - `other` — `&DataFrame`.
    pub fn merge(&mut self, other: &DataFrame) {
        let my_nrows = self.nrows();
        let other_nrows = other.nrows();
        let other_data = other.raw_data();

        // Add any columns from other that we don't have
        for (oi, name) in other.columns().iter().enumerate() {
            if !self.columns().contains(name) {
                // New column: fill existing rows with Nil
                let mut col = vec![CellValue::Nil; my_nrows];
                col.extend(other_data[oi].iter().cloned());
                self.column_names.push(name.clone());
                self.data.push(col);
            }
        }

        // Append other's rows to existing columns
        for (ci, name) in self.columns().to_vec().iter().enumerate() {
            if let Some(oi) = other.columns().iter().position(|n| n == name) {
                self.data[ci].extend(other_data[oi].iter().cloned());
            } else {
                // This column doesn't exist in other — fill new rows with Nil
                self.data[ci].extend(std::iter::repeat_n(CellValue::Nil, other_nrows));
            }
        }
    }

    /// Count distinct values in a column, returning a DataFrame with "value" and "count" columns.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    pub fn count_by(&self, col: ColRef) -> Result<DataFrame, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();

        let mut counts: Vec<(CellValue, usize)> = Vec::new();
        for val in &data[ci] {
            if let Some(entry) = counts.iter_mut().find(|(k, _)| k == val) {
                entry.1 += 1;
            } else {
                counts.push((val.clone(), 1));
            }
        }

        let mut value_col = Vec::with_capacity(counts.len());
        let mut count_col = Vec::with_capacity(counts.len());
        for (val, cnt) in counts {
            value_col.push(val);
            count_col.push(CellValue::Number(cnt as f64));
        }

        Ok(DataFrame::from_raw(
            vec!["value".to_string(), "count".to_string()],
            vec![value_col, count_col],
        ))
    }

    /// Remove rows where the given column is Nil.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    pub fn drop_nil(&self, col: ColRef) -> Result<DataFrame, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        let indices: Vec<usize> = (0..self.nrows())
            .filter(|&row| !data[ci][row].is_nil())
            .collect();
        Ok(self.extract_rows(&indices))
    }

    /// Random sample of `n` rows using Fisher-Yates shuffle.
    ///
    /// # Parameters
    /// - `n` — `usize`.
    /// - `seed` — `Option<u64>`.
    ///
    /// # Returns
    /// `DataFrame`.
    pub fn sample(&self, n: usize, seed: Option<u64>) -> DataFrame {
        let nrows = self.nrows();
        if nrows == 0 || n == 0 {
            return DataFrame::from_raw(self.columns().to_vec(), vec![Vec::new(); self.ncols()]);
        }

        let mut rng = Xorshift64::new(seed.unwrap_or(0));
        let mut indices: Vec<usize> = (0..nrows).collect();

        // Fisher-Yates shuffle
        for i in (1..nrows).rev() {
            let j = rng.next_usize(i + 1);
            indices.swap(i, j);
        }

        let take = n.min(nrows);
        let selected: Vec<usize> = indices[..take].to_vec();
        self.extract_rows(&selected)
    }

    // -----------------------------------------------------------------------
    // Analytics (numeric columns only, skip nils)
    // -----------------------------------------------------------------------

    /// Sum of numeric values in a column (skipping nils).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn sum(&self, col: ColRef) -> Result<f64, String> {
        let nums = self.collect_numbers(col)?;
        Ok(nums.iter().sum())
    }

    /// Mean of numeric values in a column (skipping nils).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn mean(&self, col: ColRef) -> Result<f64, String> {
        let nums = self.collect_numbers(col)?;
        if nums.is_empty() {
            return Err("no numeric values for mean".to_string());
        }
        Ok(nums.iter().sum::<f64>() / nums.len() as f64)
    }

    /// Minimum numeric value in a column (skipping nils).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn min_val(&self, col: ColRef) -> Result<f64, String> {
        let nums = self.collect_numbers(col)?;
        nums.iter()
            .cloned()
            .min_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal))
            .ok_or_else(|| "no numeric values for min".to_string())
    }

    /// Maximum numeric value in a column (skipping nils).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn max_val(&self, col: ColRef) -> Result<f64, String> {
        let nums = self.collect_numbers(col)?;
        nums.iter()
            .cloned()
            .max_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal))
            .ok_or_else(|| "no numeric values for max".to_string())
    }

    /// Median of numeric values in a column (skipping nils).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn median(&self, col: ColRef) -> Result<f64, String> {
        let mut nums = self.collect_numbers(col)?;
        if nums.is_empty() {
            return Err("no numeric values for median".to_string());
        }
        nums.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
        let n = nums.len();
        if n % 2 == 0 {
            Ok((nums[n / 2 - 1] + nums[n / 2]) / 2.0)
        } else {
            Ok(nums[n / 2])
        }
    }

    /// Standard deviation of numeric values in a column (population stddev, skipping nils).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn stddev(&self, col: ColRef) -> Result<f64, String> {
        Ok(self.variance(col)?.sqrt())
    }

    /// Variance of numeric values in a column (population variance, skipping nils).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn variance(&self, col: ColRef) -> Result<f64, String> {
        let nums = self.collect_numbers(col)?;
        if nums.is_empty() {
            return Err("no numeric values for variance".to_string());
        }
        let mean = nums.iter().sum::<f64>() / nums.len() as f64;
        let var = nums.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / nums.len() as f64;
        Ok(var)
    }

    /// Descriptive statistics for all numeric columns.
    ///
    /// # Returns
    /// `DataFrame`.
    ///
    /// Returns a DataFrame with columns: "stat", and one column per numeric column,
    /// with rows: count, mean, std, min, 25%, 50%, 75%, max.
    pub fn describe(&self) -> DataFrame {
        let cols = self.columns();
        let data = self.raw_data();

        // Find numeric columns
        let mut num_cols: Vec<(usize, String)> = Vec::new();
        for (ci, name) in cols.iter().enumerate() {
            let has_number = data[ci].iter().any(|v| matches!(v, CellValue::Number(_)));
            if has_number {
                num_cols.push((ci, name.clone()));
            }
        }

        if num_cols.is_empty() {
            return DataFrame::new();
        }

        let stat_labels = ["count", "mean", "std", "min", "25%", "50%", "75%", "max"];
        let mut result_cols: Vec<String> = vec!["stat".to_string()];
        let mut result_data: Vec<Vec<CellValue>> = vec![stat_labels
            .iter()
            .map(|s| CellValue::Text(s.to_string()))
            .collect()];

        for (ci, name) in &num_cols {
            result_cols.push(name.clone());
            let mut nums: Vec<f64> = data[*ci].iter().filter_map(|v| v.as_number()).collect();
            nums.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));

            let count = nums.len() as f64;
            let mean = if nums.is_empty() {
                0.0
            } else {
                nums.iter().sum::<f64>() / count
            };
            let variance = if nums.is_empty() {
                0.0
            } else {
                nums.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / count
            };
            let std = variance.sqrt();
            let min = nums.first().copied().unwrap_or(0.0);
            let max = nums.last().copied().unwrap_or(0.0);
            let q25 = percentile(&nums, 25.0);
            let q50 = percentile(&nums, 50.0);
            let q75 = percentile(&nums, 75.0);

            result_data.push(vec![
                CellValue::Number(count),
                CellValue::Number(mean),
                CellValue::Number(std),
                CellValue::Number(min),
                CellValue::Number(q25),
                CellValue::Number(q50),
                CellValue::Number(q75),
                CellValue::Number(max),
            ]);
        }

        DataFrame::from_raw(result_cols, result_data)
    }

    // -----------------------------------------------------------------------
    // Nil handling
    // -----------------------------------------------------------------------

    /// Replace Nil values in a column with the given value (in-place).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    /// - `val` — `CellValue`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn fill_nil(&mut self, col: ColRef, val: CellValue) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let nrows = self.nrows();
        for row in 0..nrows {
            if self.data[ci][row].is_nil() {
                self.data[ci][row] = val.clone();
            }
        }
        Ok(())
    }

    // -----------------------------------------------------------------------
    // Internal helpers
    // -----------------------------------------------------------------------

    /// Extract rows by index into a new DataFrame.
    fn extract_rows(&self, indices: &[usize]) -> DataFrame {
        let data = self.raw_data();
        let new_data: Vec<Vec<CellValue>> = (0..self.ncols())
            .map(|ci| indices.iter().map(|&row| data[ci][row].clone()).collect())
            .collect();
        DataFrame::from_raw(self.columns().to_vec(), new_data)
    }

    /// Collect numeric values from a column (skipping nils).
    fn collect_numbers(&self, col: ColRef) -> Result<Vec<f64>, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        Ok(data[ci].iter().filter_map(|v| v.as_number()).collect())
    }
}

/// Linear interpolation percentile for sorted values.
fn percentile(sorted: &[f64], pct: f64) -> f64 {
    if sorted.is_empty() {
        return 0.0;
    }
    if sorted.len() == 1 {
        return sorted[0];
    }
    let rank = pct / 100.0 * (sorted.len() - 1) as f64;
    let lo = rank.floor() as usize;
    let hi = rank.ceil() as usize;
    let frac = rank - lo as f64;
    sorted[lo] * (1.0 - frac) + sorted[hi] * frac
}
