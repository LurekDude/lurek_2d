//! Validation and quality reports for doc entries.

use std::collections::HashMap;

use crate::docs::catalog::Catalog;
use crate::docs::entry::DocEntry;

/// Computes a quality score in `[0.0, 1.0]` for a single doc entry.
///
/// Scores one point each for: non-empty description, non-empty qualified_name,
/// at least one parameter or return (for non-value kinds), an example, and a
/// since field.  The final score is the fraction of applicable checks that pass.
pub fn quality_score(entry: &DocEntry) -> f64 {
    let mut total = 0u32;
    let mut passed = 0u32;

    // description
    total += 1;
    if !entry.description.is_empty() { passed += 1; }

    // qualified_name populated
    total += 1;
    if !entry.qualified_name.is_empty() { passed += 1; }

    // parameters or returns (only for non-value kinds)
    if entry.kind != "value" {
        total += 1;
        if !entry.parameters.is_empty() || !entry.returns.is_empty() { passed += 1; }
    }

    // example present
    total += 1;
    if entry.example.is_some() { passed += 1; }

    // since field present
    total += 1;
    if entry.since.is_some() { passed += 1; }

    if total == 0 { return 0.0; }
    passed as f64 / total as f64
}

/// Converts a quality score into a letter grade.
///
/// A ≥ 0.9, B ≥ 0.7, C ≥ 0.5, D ≥ 0.3, F < 0.3.
pub fn quality_grade(score: f64) -> &'static str {
    if score >= 0.9 { "A" }
    else if score >= 0.7 { "B" }
    else if score >= 0.5 { "C" }
    else if score >= 0.3 { "D" }
    else { "F" }
}

/// A report comparing a known API surface against catalog coverage.
#[derive(Debug, Default)]
pub struct ValidationReport {
    /// Qualified names that should have a doc entry but do not.
    pub missing: Vec<String>,
    /// Qualified names with a doc entry that are not present in the live API.
    pub phantom: Vec<String>,
    /// Qualified names whose doc entry is incomplete.
    pub incomplete: Vec<String>,
}

impl ValidationReport {
    /// Creates an empty validation report.
    pub fn new() -> Self {
        Self::default()
    }

    /// Returns `true` when the report has no issues.
    pub fn is_clean(&self) -> bool {
        self.missing.is_empty() && self.phantom.is_empty() && self.incomplete.is_empty()
    }

    /// Returns the total count of issues across all categories.
    pub fn total_issues(&self) -> usize {
        self.missing.len() + self.phantom.len() + self.incomplete.len()
    }
}

/// A quality report computed from all entries in a catalog.
pub struct QualityReport {
    /// Snapshot of all entries that were scored.
    pub entries: Vec<DocEntry>,
    /// Average quality score per module name.
    pub module_scores: HashMap<String, f64>,
    /// Weighted average quality score across all entries.
    pub overall_score: f64,
}

impl QualityReport {
    /// Computes quality scores for every entry in `catalog`.
    pub fn compute(catalog: &Catalog) -> Self {
        let entries: Vec<DocEntry> = catalog.all_entries().to_vec();

        let mut module_totals: HashMap<String, (f64, usize)> = HashMap::new();
        for entry in &entries {
            let score = quality_score(entry);
            let slot = module_totals.entry(entry.module.clone()).or_insert((0.0, 0));
            slot.0 += score;
            slot.1 += 1;
        }

        let module_scores: HashMap<String, f64> = module_totals
            .iter()
            .map(|(m, (sum, count))| (m.clone(), if *count > 0 { sum / *count as f64 } else { 0.0 }))
            .collect();

        let overall_score = if entries.is_empty() {
            0.0
        } else {
            entries.iter().map(quality_score).sum::<f64>() / entries.len() as f64
        };

        Self { entries, module_scores, overall_score }
    }

    /// Returns the letter grade for the given module.
    pub fn module_grade(&self, module: &str) -> &'static str {
        quality_grade(self.module_scores.get(module).copied().unwrap_or(0.0))
    }
}
