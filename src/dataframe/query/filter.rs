//! Filtering, sorting, joining, sampling operators.

use crate::dataframe::frame::{CellValue, ColRef, DataFrame};
use crate::dataframe::rng::Xorshift64;

impl DataFrame {
    /// Filter rows where `col op val` is true.
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
    pub fn head(&self, n: usize) -> DataFrame {
        let take = n.min(self.nrows());
        self.extract_rows(&(0..take).collect::<Vec<_>>())
    }

    /// Return the last `n` rows.
    pub fn tail(&self, n: usize) -> DataFrame {
        let nrows = self.nrows();
        let skip = nrows.saturating_sub(n);
        self.extract_rows(&(skip..nrows).collect::<Vec<_>>())
    }

    /// Return a 0-based inclusive slice `[start, end]`.
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
        Ok(self.extract_rows(&(start..=end).collect::<Vec<_>>()))
    }

    /// Column projection: select a subset of columns.
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

    /// Return unique values in a column (O(n²) dedup, preserves order).
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

    /// Group rows by the value in a column.
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

        Ok(groups
            .into_iter()
            .map(|(key, rows)| (key, self.extract_rows(&rows)))
            .collect())
    }

    /// Join with another DataFrame on matching key columns.
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
                    for ci in 0..self.ncols() {
                        new_data[ci].push(t_data[ci][t_row].clone());
                    }
                    for (extra_i, &oi) in other_col_indices.iter().enumerate() {
                        new_data[self.ncols() + extra_i].push(o_data[oi][o_row].clone());
                    }
                }
            }

            if !matched && join_type == "left" {
                for ci in 0..self.ncols() {
                    new_data[ci].push(t_data[ci][t_row].clone());
                }
                for extra_i in 0..other_col_indices.len() {
                    new_data[self.ncols() + extra_i].push(CellValue::Nil);
                }
            }
        }

        Ok(DataFrame::from_raw(col_names, new_data))
    }

    /// Append rows from `other` in-place. Adds missing columns as Nil.
    pub fn merge(&mut self, other: &DataFrame) {
        let my_nrows = self.nrows();
        let other_nrows = other.nrows();
        let other_data = other.raw_data();

        for (oi, name) in other.columns().iter().enumerate() {
            if !self.columns().contains(name) {
                let mut col = vec![CellValue::Nil; my_nrows];
                col.extend(other_data[oi].iter().cloned());
                self.column_names.push(name.clone());
                self.data.push(col);
            }
        }

        for (ci, name) in self.columns().to_vec().iter().enumerate() {
            if let Some(oi) = other.columns().iter().position(|n| n == name) {
                self.data[ci].extend(other_data[oi].iter().cloned());
            } else {
                self.data[ci].extend(std::iter::repeat_n(CellValue::Nil, other_nrows));
            }
        }
    }

    /// Count distinct values in a column; return a `(value, count)` DataFrame.
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

        let (value_col, count_col): (Vec<_>, Vec<_>) = counts
            .into_iter()
            .map(|(v, c)| (v, CellValue::Number(c as f64)))
            .unzip();

        Ok(DataFrame::from_raw(
            vec!["value".to_string(), "count".to_string()],
            vec![value_col, count_col],
        ))
    }

    /// Remove rows where `col` is Nil.
    pub fn drop_nil(&self, col: ColRef) -> Result<DataFrame, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        let indices: Vec<usize> = (0..self.nrows())
            .filter(|&row| !data[ci][row].is_nil())
            .collect();
        Ok(self.extract_rows(&indices))
    }

    /// Random sample of `n` rows (Fisher-Yates).
    pub fn sample(&self, n: usize, seed: Option<u64>) -> DataFrame {
        let nrows = self.nrows();
        if nrows == 0 || n == 0 {
            return DataFrame::from_raw(self.columns().to_vec(), vec![Vec::new(); self.ncols()]);
        }

        let mut rng = Xorshift64::new(seed.unwrap_or(0));
        let mut indices: Vec<usize> = (0..nrows).collect();
        for i in (1..nrows).rev() {
            let j = rng.next_usize(i + 1);
            indices.swap(i, j);
        }

        let take = n.min(nrows);
        self.extract_rows(&indices[..take])
    }

    // -----------------------------------------------------------------------
    // Aggregation
    // -----------------------------------------------------------------------

    /// Sum of numeric values in a column (skipping nils).
    pub fn sum(&self, col: ColRef) -> Result<f64, String> {
        Ok(self.collect_numbers(col)?.iter().sum())
    }

    /// Mean of numeric values in a column (skipping nils).
    pub fn mean(&self, col: ColRef) -> Result<f64, String> {
        let nums = self.collect_numbers(col)?;
        if nums.is_empty() {
            return Err("no numeric values for mean".to_string());
        }
        Ok(nums.iter().sum::<f64>() / nums.len() as f64)
    }

    /// Minimum numeric value in a column (skipping nils).
    pub fn min_val(&self, col: ColRef) -> Result<f64, String> {
        let nums = self.collect_numbers(col)?;
        nums.iter()
            .cloned()
            .min_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal))
            .ok_or_else(|| "no numeric values for min".to_string())
    }

    /// Maximum numeric value in a column (skipping nils).
    pub fn max_val(&self, col: ColRef) -> Result<f64, String> {
        let nums = self.collect_numbers(col)?;
        nums.iter()
            .cloned()
            .max_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal))
            .ok_or_else(|| "no numeric values for max".to_string())
    }

    /// Median of numeric values (skipping nils).
    pub fn median(&self, col: ColRef) -> Result<f64, String> {
        let mut nums = self.collect_numbers(col)?;
        if nums.is_empty() {
            return Err("no numeric values for median".to_string());
        }
        nums.sort_by(|a, b| a.partial_cmp(b).unwrap_or(std::cmp::Ordering::Equal));
        let n = nums.len();
        Ok(if n % 2 == 0 {
            (nums[n / 2 - 1] + nums[n / 2]) / 2.0
        } else {
            nums[n / 2]
        })
    }

    /// Population standard deviation (skipping nils).
    pub fn stddev(&self, col: ColRef) -> Result<f64, String> {
        Ok(self.variance(col)?.sqrt())
    }

    /// Population variance (skipping nils).
    pub fn variance(&self, col: ColRef) -> Result<f64, String> {
        let nums = self.collect_numbers(col)?;
        if nums.is_empty() {
            return Err("no numeric values for variance".to_string());
        }
        let mean = nums.iter().sum::<f64>() / nums.len() as f64;
        Ok(nums.iter().map(|x| (x - mean).powi(2)).sum::<f64>() / nums.len() as f64)
    }

    /// Descriptive statistics for all numeric columns.
    pub fn describe(&self) -> DataFrame {
        let cols = self.columns();
        let data = self.raw_data();

        let num_cols: Vec<(usize, String)> = cols
            .iter()
            .enumerate()
            .filter(|(ci, _)| data[*ci].iter().any(|v| matches!(v, CellValue::Number(_))))
            .map(|(ci, n)| (ci, n.clone()))
            .collect();

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
            let q25 = super::analytics::percentile(&nums, 25.0);
            let q50 = super::analytics::percentile(&nums, 50.0);
            let q75 = super::analytics::percentile(&nums, 75.0);

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

    /// Replace Nil values in a column with `val` (in-place).
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
    pub(super) fn extract_rows(&self, indices: &[usize]) -> DataFrame {
        let data = self.raw_data();
        let new_data: Vec<Vec<CellValue>> = (0..self.ncols())
            .map(|ci| indices.iter().map(|&row| data[ci][row].clone()).collect())
            .collect();
        DataFrame::from_raw(self.columns().to_vec(), new_data)
    }

    /// Collect numeric values from a column (skipping nils).
    pub(super) fn collect_numbers(&self, col: ColRef) -> Result<Vec<f64>, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        Ok(data[ci].iter().filter_map(|v| v.as_number()).collect())
    }

    // -----------------------------------------------------------------------
    // Batch / array interop
    // -----------------------------------------------------------------------

    /// Add multiple rows at once. Each inner `Vec` must have exactly `ncols()` elements.
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

    /// Return a column's numeric values as `Vec<f64>` (nils → NaN).
    pub fn get_column_as_f64(&self, col: ColRef) -> Result<Vec<f64>, String> {
        let ci = self.resolve_col(col)?;
        let data = self.raw_data();
        Ok(data[ci]
            .iter()
            .map(|v| v.as_number().unwrap_or(f64::NAN))
            .collect())
    }

    /// Set all rows of a numeric column from a `Vec<f64>` (NaN → Nil).
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
