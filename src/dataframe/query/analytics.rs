
use crate::dataframe::frame::{CellValue, ColRef, DataFrame};
pub fn percentile(sorted: &[f64], pct: f64) -> f64 {
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
impl DataFrame {
    /// Compute z-score for numeric column and write result column.
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
    /// Normalize numeric column to output range and write result column.
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
    /// Return rows where absolute z-score exceeds threshold.
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
        let indices: Vec<usize> = (0..n)
            .filter(|&i| {
                if let Some(v) = data[ci][i].as_number() {
                    std == 0.0 || ((v - mean) / std).abs() > threshold
                } else {
                    false
                }
            })
            .collect();
        Ok(self.extract_rows(&indices))
    }
    /// Return most frequent non-nil value in selected column.
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
    /// Compute Shannon entropy over rendered cell values.
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
        Ok(counts
            .values()
            .map(|&c| {
                let p = c as f64 / total;
                -p * p.log2()
            })
            .sum())
    }
}
