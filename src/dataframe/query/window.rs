//! - Rolling mean, sum, min, and max over configurable window size
//! - Dense rank computation with average-rank tie-breaking
//! - Row-to-row percent change calculation
//! - Cumulative sum across ordered rows

use crate::dataframe::frame::{CellValue, ColRef, DataFrame};
impl DataFrame {
    #[allow(clippy::needless_range_loop)]
    /// Compute rolling mean and append output column.
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
    /// Compute rolling sum and append output column.
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
    /// Compute rolling minimum and append output column.
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
    /// Compute rolling maximum and append output column.
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
    /// Compute rank over numeric column and append output column.
    pub fn with_rank(&mut self, col: ColRef, ascending: bool, name: &str) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        let data = self.raw_data();
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
    /// Compute row-to-row percent change and append output column.
    pub fn with_pct_change(&mut self, col: ColRef, name: &str) -> Result<(), String> {
        let ci = self.resolve_col(col)?;
        let n = self.nrows();
        let data = self.raw_data();
        let vals: Vec<CellValue> = (0..n)
            .map(|i| {
                if i == 0 {
                    return CellValue::Nil;
                }
                match (data[ci][i - 1].as_number(), data[ci][i].as_number()) {
                    (Some(prev), Some(curr)) if prev != 0.0 => {
                        CellValue::Number((curr - prev) / prev)
                    }
                    _ => CellValue::Nil,
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
    /// Compute cumulative sum and append output column.
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
}
