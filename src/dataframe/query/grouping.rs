//! - Grouped aggregation by key column with mean, sum, min, max, count, first, last
//! - Pivot transformation from row/column/value keys into cross-tabulated frame
//! - Pearson correlation between two numeric columns
//! - Full numeric-column correlation matrix generation

use crate::dataframe::frame::{AggFn, CellValue, ColRef, DataFrame};
impl DataFrame {
    #[allow(clippy::needless_range_loop)]
    /// Aggregate values by group key and return grouped result frame.
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
    #[allow(clippy::needless_range_loop)]
    /// Pivot row and column keys into cross-tabulated frame.
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
    /// Compute Pearson correlation between two numeric columns.
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
    /// Build numeric-column correlation matrix frame.
    pub fn correlation_matrix(&self) -> DataFrame {
        let cols = self.columns();
        let data = self.raw_data();
        let num_cols: Vec<(usize, String)> = cols
            .iter()
            .enumerate()
            .filter(|(ci, _)| data[*ci].iter().any(|v| v.as_number().is_some()))
            .map(|(ci, n)| (ci, n.clone()))
            .collect();
        if num_cols.is_empty() {
            return DataFrame::new();
        }
        let n = self.nrows();
        let nc = num_cols.len();
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
}
