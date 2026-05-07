//! DataFrame query, filter, sort, join, analytics, and mutation.
//!
//! This module is part of Lurek2D's `dataframe` subsystem and provides the implementation
//! details for query-related operations and data management.
//! Primary functions: `filter()`, `sort()`, `head()`, `tail()`.
//!
//! All public items are documented. See the parent module for architectural context
//! and the `lurek.*` Lua API for the scripting interface.

use crate::dataframe::frame::{AggFn, CellValue, ColRef, DataFrame};
use crate::dataframe::rng::Xorshift64;

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

    /// Return the first `n` rows.
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

    /// Return the last `n` rows.
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
            log::warn!("dataframe: right join not implemented; returning empty DataFrame");
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

    // -----------------------------------------------------------------------
    // Rolling window operations
    // -----------------------------------------------------------------------

    /// Add a new column containing the rolling mean of `col` with `window` rows.
    ///
    /// The output column name is `<col_name>_rolling_mean`. Rows with fewer than
    /// `window` predecessors contain `CellValue::Nil`.
    ///
    /// # Parameters
    /// - `col`    — `ColRef`.
    /// - `window` — `usize` window size (must be ≥ 1).
    /// - `name`   — `&str` name for the new column.
    ///
    /// # Returns
    /// `Result<(), String>`.
    #[allow(clippy::needless_range_loop)]
    pub fn with_rolling_mean(
        &mut self,
        col: ColRef,
        window: usize,
        name: &str,
    ) -> Result<(), String> {
        if window == 0 {
            return Err("with_rolling_mean: window must be ≥ 1".to_string());
        }
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        let data = self.raw_data();
        let vals: Vec<CellValue> = (0..n)
            .map(|i| {
                if i + 1 < window {
                    return CellValue::Nil;
                }
                let mut sum = 0.0_f64;
                let mut cnt = 0usize;
                for k in (i + 1 - window)..=i {
                    if let Some(v) = data[ci][k].as_number() {
                        sum += v;
                        cnt += 1;
                    }
                }
                if cnt == 0 {
                    CellValue::Nil
                } else {
                    CellValue::Number(sum / cnt as f64)
                }
            })
            .collect();
        self.add_column(name, CellValue::Nil)?;
        let new_ci = self.ncols() - 1;
        for (i, v) in vals.into_iter().enumerate() {
            self.data[new_ci][i] = v;
        }
        Ok(())
    }

    /// Add a new column containing the rolling sum of `col` with `window` rows.
    ///
    /// The output column name is provided by the caller. Rows with fewer than
    /// `window` predecessors contain `CellValue::Nil`.
    ///
    /// # Parameters
    /// - `col`    — `ColRef`.
    /// - `window` — `usize`.
    /// - `name`   — `&str` name for the new column.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn with_rolling_sum(
        &mut self,
        col: ColRef,
        window: usize,
        name: &str,
    ) -> Result<(), String> {
        if window == 0 {
            return Err("with_rolling_sum: window must be ≥ 1".to_string());
        }
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        let data = self.raw_data();
        let vals: Vec<CellValue> = (0..n)
            .map(|i| {
                if i + 1 < window {
                    return CellValue::Nil;
                }
                let sum: f64 = (i + 1 - window..=i)
                    .filter_map(|k| data[ci][k].as_number())
                    .sum();
                CellValue::Number(sum)
            })
            .collect();
        self.add_column(name, CellValue::Nil)?;
        let new_ci = self.ncols() - 1;
        for (i, v) in vals.into_iter().enumerate() {
            self.data[new_ci][i] = v;
        }
        Ok(())
    }

    /// Add a new column containing the rolling minimum of `col` with `window` rows.
    ///
    /// # Parameters
    /// - `col`    — `ColRef`.
    /// - `window` — `usize`.
    /// - `name`   — `&str` name for the new column.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn with_rolling_min(
        &mut self,
        col: ColRef,
        window: usize,
        name: &str,
    ) -> Result<(), String> {
        if window == 0 {
            return Err("with_rolling_min: window must be ≥ 1".to_string());
        }
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        let data = self.raw_data();
        let vals: Vec<CellValue> = (0..n)
            .map(|i| {
                if i + 1 < window {
                    return CellValue::Nil;
                }
                let min_val = (i + 1 - window..=i)
                    .filter_map(|k| data[ci][k].as_number())
                    .fold(f64::INFINITY, f64::min);
                if min_val == f64::INFINITY {
                    CellValue::Nil
                } else {
                    CellValue::Number(min_val)
                }
            })
            .collect();
        self.add_column(name, CellValue::Nil)?;
        let new_ci = self.ncols() - 1;
        for (i, v) in vals.into_iter().enumerate() {
            self.data[new_ci][i] = v;
        }
        Ok(())
    }

    /// Add a new column containing the rolling maximum of `col` with `window` rows.
    ///
    /// # Parameters
    /// - `col`    — `ColRef`.
    /// - `window` — `usize`.
    /// - `name`   — `&str` name for the new column.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn with_rolling_max(
        &mut self,
        col: ColRef,
        window: usize,
        name: &str,
    ) -> Result<(), String> {
        if window == 0 {
            return Err("with_rolling_max: window must be ≥ 1".to_string());
        }
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        let data = self.raw_data();
        let vals: Vec<CellValue> = (0..n)
            .map(|i| {
                if i + 1 < window {
                    return CellValue::Nil;
                }
                let max_val = (i + 1 - window..=i)
                    .filter_map(|k| data[ci][k].as_number())
                    .fold(f64::NEG_INFINITY, f64::max);
                if max_val == f64::NEG_INFINITY {
                    CellValue::Nil
                } else {
                    CellValue::Number(max_val)
                }
            })
            .collect();
        self.add_column(name, CellValue::Nil)?;
        let new_ci = self.ncols() - 1;
        for (i, v) in vals.into_iter().enumerate() {
            self.data[new_ci][i] = v;
        }
        Ok(())
    }

    // -----------------------------------------------------------------------
    // Derived column operations
    // -----------------------------------------------------------------------

    /// Add a new column containing the rank of each row's value in `col`.
    ///
    /// Rank is 1-based. Ties receive the average rank. Nil values get rank 0.
    ///
    /// # Parameters
    /// - `col`       — `ColRef`.
    /// - `ascending` — `bool` if true lowest value = rank 1.
    /// - `name`      — `&str` name for the rank column.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn with_rank(&mut self, col: ColRef, ascending: bool, name: &str) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        let data = self.raw_data();

        // Collect (original_index, value) for non-Nil rows
        let mut indexed: Vec<(usize, f64)> = (0..n)
            .filter_map(|i| data[ci][i].as_number().map(|v| (i, v)))
            .collect();

        if ascending {
            indexed.sort_by(|a, b| a.1.partial_cmp(&b.1).unwrap_or(std::cmp::Ordering::Equal));
        } else {
            indexed.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));
        }

        let mut rank_out = vec![CellValue::Nil; n];
        let mut i = 0;
        while i < indexed.len() {
            let v = indexed[i].1;
            let mut j = i + 1;
            while j < indexed.len() && (indexed[j].1 - v).abs() < f64::EPSILON {
                j += 1;
            }
            let avg_rank = (i + 1 + j) as f64 / 2.0;
            for item in indexed.iter().take(j).skip(i) {
                rank_out[item.0] = CellValue::Number(avg_rank);
            }
            i = j;
        }

        self.add_column(name, CellValue::Nil)?;
        let new_ci = self.ncols() - 1;
        for (i, v) in rank_out.into_iter().enumerate() {
            self.data[new_ci][i] = v;
        }
        Ok(())
    }

    /// Add a new column containing the percentage change from the previous row in `col`.
    ///
    /// The first row gets `CellValue::Nil`.
    ///
    /// # Parameters
    /// - `col`  — `ColRef`.
    /// - `name` — `&str` name for the new column.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn with_pct_change(&mut self, col: ColRef, name: &str) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        let data = self.raw_data();
        let vals: Vec<CellValue> = (0..n)
            .map(|i| {
                if i == 0 {
                    CellValue::Nil
                } else {
                    match (data[ci][i - 1].as_number(), data[ci][i].as_number()) {
                        (Some(prev), Some(curr)) if prev != 0.0 => {
                            CellValue::Number((curr - prev) / prev)
                        }
                        _ => CellValue::Nil,
                    }
                }
            })
            .collect();
        self.add_column(name, CellValue::Nil)?;
        let new_ci = self.ncols() - 1;
        for (i, v) in vals.into_iter().enumerate() {
            self.data[new_ci][i] = v;
        }
        Ok(())
    }

    /// Add a new column containing the cumulative sum of `col`.
    ///
    /// # Parameters
    /// - `col`  — `ColRef`.
    /// - `name` — `&str` name for the new column.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn with_cumsum(&mut self, col: ColRef, name: &str) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        let data = self.raw_data();
        let mut acc = 0.0_f64;
        let vals: Vec<CellValue> = (0..n)
            .map(|i| match data[ci][i].as_number() {
                Some(v) => {
                    acc += v;
                    CellValue::Number(acc)
                }
                None => CellValue::Nil,
            })
            .collect();
        self.add_column(name, CellValue::Nil)?;
        let new_ci = self.ncols() - 1;
        for (i, v) in vals.into_iter().enumerate() {
            self.data[new_ci][i] = v;
        }
        Ok(())
    }

    // -----------------------------------------------------------------------
    // Group aggregation
    // -----------------------------------------------------------------------

    /// Aggregate `agg_col` grouped by `group_col` using `agg_fn`.
    ///
    /// Returns a new DataFrame with two columns: the group key column and the
    /// aggregated value column named `<agg_col_name>_<fn>`.
    ///
    /// # Parameters
    /// - `group_col` — `ColRef`.
    /// - `agg_col`   — `ColRef`.
    /// - `agg_fn`    — `AggFn`.
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    #[allow(clippy::needless_range_loop)]
    pub fn group_agg(
        &self,
        group_col: ColRef,
        agg_col: ColRef,
        agg_fn: AggFn,
    ) -> Result<DataFrame, String> {
        let gci = self.resolve_col(group_col.clone())?;
        let aci = self.resolve_col(agg_col)?;
        let group_name = self.columns()[gci].clone();
        let agg_name_base = self.columns()[aci].clone();
        let agg_label = match agg_fn {
            AggFn::Mean => "mean",
            AggFn::Sum => "sum",
            AggFn::Min => "min",
            AggFn::Max => "max",
            AggFn::Count => "count",
            AggFn::First => "first",
            AggFn::Last => "last",
        };
        let out_col = format!("{}_{}", agg_name_base, agg_label);

        let data = self.raw_data();
        let n = self.nrows();

        // Collect groups preserving insertion order
        let mut key_order: Vec<String> = Vec::new();
        let mut groups: std::collections::HashMap<String, Vec<f64>> =
            std::collections::HashMap::new();
        let mut first_vals: std::collections::HashMap<String, CellValue> =
            std::collections::HashMap::new();
        let mut last_vals: std::collections::HashMap<String, CellValue> =
            std::collections::HashMap::new();
        let mut counts: std::collections::HashMap<String, u64> = std::collections::HashMap::new();

        for i in 0..n {
            let key = format!("{}", data[gci][i]);
            if !groups.contains_key(&key) {
                key_order.push(key.clone());
                groups.insert(key.clone(), Vec::new());
                first_vals.insert(key.clone(), data[aci][i].clone());
                counts.insert(key.clone(), 0);
            }
            if let Some(v) = data[aci][i].as_number() {
                groups.get_mut(&key).unwrap().push(v);
            }
            if !data[aci][i].is_nil() {
                *counts.get_mut(&key).unwrap() += 1;
            }
            last_vals.insert(key, data[aci][i].clone());
        }

        let mut key_col: Vec<CellValue> = Vec::new();
        let mut val_col: Vec<CellValue> = Vec::new();

        for key in &key_order {
            let nums = &groups[key];
            let agg_val = match agg_fn {
                AggFn::Mean => {
                    if nums.is_empty() {
                        CellValue::Nil
                    } else {
                        CellValue::Number(nums.iter().sum::<f64>() / nums.len() as f64)
                    }
                }
                AggFn::Sum => CellValue::Number(nums.iter().sum()),
                AggFn::Min => nums
                    .iter()
                    .copied()
                    .fold(None, |acc: Option<f64>, v| {
                        Some(acc.map_or(v, |a| a.min(v)))
                    })
                    .map(CellValue::Number)
                    .unwrap_or(CellValue::Nil),
                AggFn::Max => nums
                    .iter()
                    .copied()
                    .fold(None, |acc: Option<f64>, v| {
                        Some(acc.map_or(v, |a| a.max(v)))
                    })
                    .map(CellValue::Number)
                    .unwrap_or(CellValue::Nil),
                AggFn::Count => CellValue::Number(*counts.get(key).unwrap_or(&0) as f64),
                AggFn::First => first_vals.get(key).cloned().unwrap_or(CellValue::Nil),
                AggFn::Last => last_vals.get(key).cloned().unwrap_or(CellValue::Nil),
            };
            key_col.push(CellValue::Text(key.clone()));
            val_col.push(agg_val);
        }

        Ok(DataFrame::from_raw(
            vec![group_name, out_col],
            vec![key_col, val_col],
        ))
    }

    // -----------------------------------------------------------------------
    // Pivot table
    // -----------------------------------------------------------------------

    /// Create a pivot table: rows = unique values of `row_col`, columns = unique
    /// values of `col_col`, cells = values of `val_col` (first match per cell).
    ///
    /// Missing combinations produce `CellValue::Nil`.
    ///
    /// # Parameters
    /// - `row_col` — `ColRef` determines the output row labels.
    /// - `col_col` — `ColRef` determines the output column names.
    /// - `val_col` — `ColRef` source of cell values.
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    #[allow(clippy::needless_range_loop)]
    pub fn pivot(
        &self,
        row_col: ColRef,
        col_col: ColRef,
        val_col: ColRef,
    ) -> Result<DataFrame, String> {
        let rci = self.resolve_col(row_col)?;
        let cci = self.resolve_col(col_col)?;
        let vci = self.resolve_col(val_col)?;
        let data = self.raw_data();
        let n = self.nrows();

        // Collect unique row and column keys in encounter order
        let mut row_keys: Vec<String> = Vec::new();
        let mut col_keys: Vec<String> = Vec::new();
        let mut cells: std::collections::HashMap<(String, String), CellValue> =
            std::collections::HashMap::new();

        for i in 0..n {
            let rk = format!("{}", data[rci][i]);
            let ck = format!("{}", data[cci][i]);
            if !row_keys.contains(&rk) {
                row_keys.push(rk.clone());
            }
            if !col_keys.contains(&ck) {
                col_keys.push(ck.clone());
            }
            cells
                .entry((rk, ck))
                .or_insert_with(|| data[vci][i].clone());
        }

        // Build output columns
        let mut col_names: Vec<String> = vec![self.columns()[rci].clone()];
        col_names.extend(col_keys.iter().cloned());

        let row_data: Vec<CellValue> = row_keys
            .iter()
            .map(|k| CellValue::Text(k.clone()))
            .collect();
        let mut out_data: Vec<Vec<CellValue>> = vec![row_data];

        for ck in &col_keys {
            let col: Vec<CellValue> = row_keys
                .iter()
                .map(|rk| {
                    cells
                        .get(&(rk.clone(), ck.clone()))
                        .cloned()
                        .unwrap_or(CellValue::Nil)
                })
                .collect();
            out_data.push(col);
        }

        Ok(DataFrame::from_raw(col_names, out_data))
    }

    // -----------------------------------------------------------------------
    // Correlation
    // -----------------------------------------------------------------------

    /// Pearson correlation coefficient between two numeric columns.
    ///
    /// Rows where either column is Nil are skipped.
    ///
    /// # Parameters
    /// - `col_a` — `ColRef`.
    /// - `col_b` — `ColRef`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn corr(&self, col_a: ColRef, col_b: ColRef) -> Result<f64, String> {
        let cia = self.resolve_col(col_a)?;
        let cib = self.resolve_col(col_b)?;
        let data = self.raw_data();
        let n = self.nrows();

        let pairs: Vec<(f64, f64)> = (0..n)
            .filter_map(
                |i| match (data[cia][i].as_number(), data[cib][i].as_number()) {
                    (Some(a), Some(b)) => Some((a, b)),
                    _ => None,
                },
            )
            .collect();

        let k = pairs.len();
        if k < 2 {
            return Err("corr: need at least 2 paired non-nil rows".to_string());
        }
        let mean_a: f64 = pairs.iter().map(|(a, _)| a).sum::<f64>() / k as f64;
        let mean_b: f64 = pairs.iter().map(|(_, b)| b).sum::<f64>() / k as f64;
        let mut num = 0.0_f64;
        let mut ss_a = 0.0_f64;
        let mut ss_b = 0.0_f64;
        for (a, b) in &pairs {
            let da = a - mean_a;
            let db = b - mean_b;
            num += da * db;
            ss_a += da * da;
            ss_b += db * db;
        }
        let denom = (ss_a * ss_b).sqrt();
        if denom == 0.0 {
            return Err("corr: zero variance in one or both columns".to_string());
        }
        Ok(num / denom)
    }

    /// Build a correlation matrix DataFrame for all numeric columns.
    ///
    /// Returns a DataFrame with a leading "column" label column plus one
    /// numeric column per numeric source column.
    ///
    /// # Returns
    /// `DataFrame`.
    pub fn correlation_matrix(&self) -> DataFrame {
        let cols = self.columns();
        let data = self.raw_data();

        let num_cols: Vec<(usize, String)> = cols
            .iter()
            .enumerate()
            .filter(|(ci, _)| data[*ci].iter().any(|v| v.as_number().is_some()))
            .map(|(ci, name)| (ci, name.clone()))
            .collect();

        if num_cols.is_empty() {
            return DataFrame::new();
        }

        let n = self.nrows();
        let nc = num_cols.len();

        // For each pair compute correlation using paired valid rows
        let corr_data: Vec<Vec<f64>> = (0..nc)
            .map(|i| {
                (0..nc)
                    .map(|j| {
                        if i == j {
                            return 1.0;
                        }
                        let cia = num_cols[i].0;
                        let cib = num_cols[j].0;
                        let pairs: Vec<(f64, f64)> = (0..n)
                            .filter_map(|r| {
                                match (data[cia][r].as_number(), data[cib][r].as_number()) {
                                    (Some(a), Some(b)) => Some((a, b)),
                                    _ => None,
                                }
                            })
                            .collect();
                        if pairs.len() < 2 {
                            return f64::NAN;
                        }
                        let k = pairs.len() as f64;
                        let ma: f64 = pairs.iter().map(|(a, _)| a).sum::<f64>() / k;
                        let mb: f64 = pairs.iter().map(|(_, b)| b).sum::<f64>() / k;
                        let mut num = 0.0_f64;
                        let mut ssa = 0.0_f64;
                        let mut ssb = 0.0_f64;
                        for (a, b) in &pairs {
                            let da = a - ma;
                            let db = b - mb;
                            num += da * db;
                            ssa += da * da;
                            ssb += db * db;
                        }
                        let denom = (ssa * ssb).sqrt();
                        if denom == 0.0 {
                            0.0
                        } else {
                            num / denom
                        }
                    })
                    .collect()
            })
            .collect();

        // Build output DataFrame: column labels + one numeric column per source column
        let mut col_names: Vec<String> = vec!["column".to_string()];
        col_names.extend(num_cols.iter().map(|(_, n)| n.clone()));

        let label_col: Vec<CellValue> = num_cols
            .iter()
            .map(|(_, n)| CellValue::Text(n.clone()))
            .collect();
        let mut out_data: Vec<Vec<CellValue>> = vec![label_col];

        for (j, _) in num_cols.iter().enumerate() {
            let col: Vec<CellValue> = (0..nc)
                .map(|i| CellValue::Number(corr_data[i][j]))
                .collect();
            out_data.push(col);
        }

        DataFrame::from_raw(col_names, out_data)
    }

    // -----------------------------------------------------------------------
    // Normalisation columns
    // -----------------------------------------------------------------------

    /// Add a z-score column for a numeric column.
    ///
    /// Nil rows produce `CellValue::Nil`. Returns `Err` if std dev is zero.
    ///
    /// # Parameters
    /// - `col`  — `ColRef`.
    /// - `name` — `&str` name for the new column.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn zscore_col(&mut self, col: ColRef, name: &str) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        let nums: Vec<f64> = data[ci].iter().filter_map(|v| v.as_number()).collect();
        if nums.is_empty() {
            return Err("zscore_col: column has no numeric values".to_string());
        }
        let mean: f64 = nums.iter().sum::<f64>() / nums.len() as f64;
        let var: f64 = nums.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / nums.len() as f64;
        let std = var.sqrt();
        if std == 0.0 {
            return Err("zscore_col: standard deviation is zero".to_string());
        }
        let n = self.nrows();
        let vals: Vec<CellValue> = (0..n)
            .map(|i| match self.data[ci][i].as_number() {
                Some(v) => CellValue::Number((v - mean) / std),
                None => CellValue::Nil,
            })
            .collect();
        self.add_column(name, CellValue::Nil)?;
        let new_ci = self.ncols() - 1;
        for (i, v) in vals.into_iter().enumerate() {
            self.data[new_ci][i] = v;
        }
        Ok(())
    }

    /// Add a min-max normalised column for a numeric column.
    ///
    /// Values are scaled to [out_min, out_max]. Nil rows stay Nil.
    ///
    /// # Parameters
    /// - `col`     — `ColRef`.
    /// - `out_min` — `f64`.
    /// - `out_max` — `f64`.
    /// - `name`    — `&str` name for the new column.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn normalize_col(
        &mut self,
        col: ColRef,
        out_min: f64,
        out_max: f64,
        name: &str,
    ) -> Result<(), String> {
        if out_max <= out_min {
            return Err(format!(
                "normalize_col: out_max ({out_max}) must be > out_min ({out_min})"
            ));
        }
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        let nums: Vec<f64> = data[ci].iter().filter_map(|v| v.as_number()).collect();
        if nums.is_empty() {
            return Err("normalize_col: column has no numeric values".to_string());
        }
        let lo = nums.iter().cloned().fold(f64::INFINITY, f64::min);
        let hi = nums.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
        let span = hi - lo;
        let out_span = out_max - out_min;
        let n = self.nrows();
        let vals: Vec<CellValue> = (0..n)
            .map(|i| match self.data[ci][i].as_number() {
                Some(v) => {
                    let norm = if span == 0.0 { 0.5 } else { (v - lo) / span };
                    CellValue::Number(out_min + norm * out_span)
                }
                None => CellValue::Nil,
            })
            .collect();
        self.add_column(name, CellValue::Nil)?;
        let new_ci = self.ncols() - 1;
        for (i, v) in vals.into_iter().enumerate() {
            self.data[new_ci][i] = v;
        }
        Ok(())
    }

    // -----------------------------------------------------------------------
    // Outlier detection
    // -----------------------------------------------------------------------

    /// Return a new DataFrame containing only rows where `col` is an outlier.
    ///
    /// An outlier is defined as a value more than `threshold` standard deviations
    /// from the mean (z-score method).
    ///
    /// # Parameters
    /// - `col`       — `ColRef`.
    /// - `threshold` — `f64` number of standard deviations (default-friendly value: 2.0).
    ///
    /// # Returns
    /// `Result<DataFrame, String>`.
    pub fn outliers(&self, col: ColRef, threshold: f64) -> Result<DataFrame, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        let nums: Vec<f64> = data[ci].iter().filter_map(|v| v.as_number()).collect();
        if nums.is_empty() {
            return Ok(DataFrame::new());
        }
        let mean: f64 = nums.iter().sum::<f64>() / nums.len() as f64;
        let var: f64 = nums.iter().map(|v| (v - mean).powi(2)).sum::<f64>() / nums.len() as f64;
        let std = var.sqrt();
        let n = self.nrows();
        let outlier_indices: Vec<usize> = (0..n)
            .filter(|&i| {
                if let Some(v) = data[ci][i].as_number() {
                    std == 0.0 || ((v - mean) / std).abs() > threshold
                } else {
                    false
                }
            })
            .collect();
        Ok(self.extract_rows(&outlier_indices))
    }

    // -----------------------------------------------------------------------
    // Mode and entropy
    // -----------------------------------------------------------------------

    /// Return the most frequent value in a column, or `CellValue::Nil` if empty.
    ///
    /// For ties, the first-encountered most-frequent value wins.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<CellValue, String>`.
    pub fn mode_val(&self, col: ColRef) -> Result<CellValue, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        let mut counts: std::collections::HashMap<String, (CellValue, usize)> =
            std::collections::HashMap::new();
        let mut order: Vec<String> = Vec::new();
        for cell in &data[ci] {
            if cell.is_nil() {
                continue;
            }
            let key = format!("{cell}");
            let entry = counts.entry(key.clone()).or_insert_with(|| {
                order.push(key.clone());
                (cell.clone(), 0)
            });
            entry.1 += 1;
        }
        let best = order.iter().max_by_key(|k| counts[*k].1);
        Ok(best.map(|k| counts[k].0.clone()).unwrap_or(CellValue::Nil))
    }

    /// Shannon entropy (bits) of the value distribution in a column.
    ///
    /// Nil values are included as a distinct category. Returns 0.0 for an
    /// empty column.
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<f64, String>`.
    pub fn entropy(&self, col: ColRef) -> Result<f64, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        let total = data[ci].len() as f64;
        if total == 0.0 {
            return Ok(0.0);
        }
        let mut counts: std::collections::HashMap<String, usize> = std::collections::HashMap::new();
        for cell in &data[ci] {
            *counts.entry(format!("{cell}")).or_insert(0) += 1;
        }
        let entropy: f64 = counts
            .values()
            .map(|&c| {
                let p = c as f64 / total;
                -p * p.log2()
            })
            .sum();
        Ok(entropy)
    }

    // -----------------------------------------------------------------------
    // Batch / array interop
    // -----------------------------------------------------------------------

    /// Add multiple rows at once from a `Vec<Vec<CellValue>>`.
    ///
    /// Each inner `Vec` must have exactly `ncols()` elements.
    ///
    /// # Parameters
    /// - `rows` — `Vec<Vec<CellValue>>`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn add_row_batch(&mut self, rows: Vec<Vec<CellValue>>) -> Result<(), String> {
        let nc = self.ncols();
        for row in rows {
            if row.len() != nc {
                return Err(format!(
                    "add_row_batch: row has {} elements but DataFrame has {} columns",
                    row.len(),
                    nc
                ));
            }
            for (ci, val) in row.into_iter().enumerate() {
                self.data[ci].push(val);
            }
        }
        Ok(())
    }

    /// Return the numeric values of a column as `Vec<f64>` (nils → NaN).
    ///
    /// # Parameters
    /// - `col` — `ColRef`.
    ///
    /// # Returns
    /// `Result<Vec<f64>, String>`.
    pub fn get_column_as_f64(&self, col: ColRef) -> Result<Vec<f64>, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        Ok(data[ci]
            .iter()
            .map(|v| v.as_number().unwrap_or(f64::NAN))
            .collect())
    }

    /// Set all rows of a numeric column from a `Vec<f64>`.
    ///
    /// The vector length must equal `nrows()`. NaN values are stored as
    /// `CellValue::Nil`.
    ///
    /// # Parameters
    /// - `col`    — `ColRef`.
    /// - `values` — `Vec<f64>`.
    ///
    /// # Returns
    /// `Result<(), String>`.
    pub fn set_column_from_f64(&mut self, col: ColRef, values: Vec<f64>) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        if values.len() != n {
            return Err(format!(
                "set_column_from_f64: values length {} ≠ nrows {}",
                values.len(),
                n
            ));
        }
        for (i, v) in values.into_iter().enumerate() {
            self.data[ci][i] = if v.is_nan() {
                CellValue::Nil
            } else {
                CellValue::Number(v)
            };
        }
        Ok(())
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
