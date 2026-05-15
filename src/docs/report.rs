//! - Compute per-entry quality scores from completeness of description, params, and metadata.
//! - Convert scores to letter grades for human-readable reporting.
//! - Validate catalogs for missing, phantom, and incomplete entries.
//! - Aggregate module-level and overall quality metrics from a catalog snapshot.
//! - Support both catalog-based and standalone entry-based report construction.

use crate::docs::catalog::Catalog;
use crate::docs::entry::DocEntry;
use std::collections::HashMap;
/// Compute one entry quality ratio and return a score in the 0.0..=1.0 range.
pub fn quality_score(entry: &DocEntry) -> f64 {
    let mut total = 0u32;
    let mut passed = 0u32;
    total += 1;
    if !entry.description.is_empty() {
        passed += 1;
    }
    total += 1;
    if !entry.qualified_name.is_empty() {
        passed += 1;
    }
    if entry.kind != "value" {
        total += 1;
        if !entry.parameters.is_empty() || !entry.returns.is_empty() {
            passed += 1;
        }
    }
    total += 1;
    if entry.example.is_some() {
        passed += 1;
    }
    total += 1;
    if entry.since.is_some() {
        passed += 1;
    }
    if total == 0 {
        return 0.0;
    }
    passed as f64 / total as f64
}
/// Convert a quality score to a letter grade and return the grade label.
pub fn quality_grade(score: f64) -> &'static str {
    if score >= 0.9 {
        "A"
    } else if score >= 0.7 {
        "B"
    } else if score >= 0.5 {
        "C"
    } else if score >= 0.3 {
        "D"
    } else {
        "F"
    }
}
#[derive(Debug, Default)]
/// Collect missing, phantom, and incomplete documentation issue identifiers.
pub struct ValidationReport {
    /// Store qualified names that are expected but missing in generated docs.
    pub missing: Vec<String>,
    /// Store generated names that do not map to known API items.
    pub phantom: Vec<String>,
    /// Store entries that exist but fail required completeness checks.
    pub incomplete: Vec<String>,
}
impl ValidationReport {
    /// Create an empty validation report and return it.
    pub fn new() -> Self {
        Self::default()
    }
    /// Return true when no issue buckets contain any item.
    pub fn is_clean(&self) -> bool {
        self.missing.is_empty() && self.phantom.is_empty() && self.incomplete.is_empty()
    }
    /// Return the total number of aggregated issues across all buckets.
    pub fn total_issues(&self) -> usize {
        self.missing.len() + self.phantom.len() + self.incomplete.len()
    }
}
/// Store per-entry and per-module quality metrics for one catalog snapshot.
pub struct QualityReport {
    /// Store the full set of entries used for score computation.
    pub entries: Vec<DocEntry>,
    /// Store average quality score keyed by module name.
    pub module_scores: HashMap<String, f64>,
    /// Store average quality score across all entries.
    pub overall_score: f64,
}
impl QualityReport {
    /// Compute report metrics from a catalog and return the report.
    pub fn compute(catalog: &Catalog) -> Self {
        let entries: Vec<DocEntry> = catalog.all_entries().to_vec();
        let mut module_totals: HashMap<String, (f64, usize)> = HashMap::new();
        for entry in &entries {
            let score = quality_score(entry);
            let slot = module_totals
                .entry(entry.module.clone())
                .or_insert((0.0, 0));
            slot.0 += score;
            slot.1 += 1;
        }
        let module_scores: HashMap<String, f64> = module_totals
            .iter()
            .map(|(m, (sum, count))| {
                (
                    m.clone(),
                    if *count > 0 { sum / *count as f64 } else { 0.0 },
                )
            })
            .collect();
        let overall_score = if entries.is_empty() {
            0.0
        } else {
            entries.iter().map(quality_score).sum::<f64>() / entries.len() as f64
        };
        Self {
            entries,
            module_scores,
            overall_score,
        }
    }
    /// Return the letter grade for one module score or F when missing.
    pub fn module_grade(&self, module: &str) -> &'static str {
        quality_grade(self.module_scores.get(module).copied().unwrap_or(0.0))
    }
    /// Build a temporary catalog from entries and return a computed report.
    pub fn from_entries(entries: &[DocEntry]) -> Self {
        let catalog = Catalog::from_entries(entries);
        Self::compute(&catalog)
    }
}
