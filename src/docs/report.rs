use crate::docs::catalog::Catalog;
use crate::docs::entry::DocEntry;
use std::collections::HashMap;
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
pub struct ValidationReport {
    pub missing: Vec<String>,
    pub phantom: Vec<String>,
    pub incomplete: Vec<String>,
}
impl ValidationReport {
    pub fn new() -> Self {
        Self::default()
    }
    pub fn is_clean(&self) -> bool {
        self.missing.is_empty() && self.phantom.is_empty() && self.incomplete.is_empty()
    }
    pub fn total_issues(&self) -> usize {
        self.missing.len() + self.phantom.len() + self.incomplete.len()
    }
}
pub struct QualityReport {
    pub entries: Vec<DocEntry>,
    pub module_scores: HashMap<String, f64>,
    pub overall_score: f64,
}
impl QualityReport {
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
    pub fn module_grade(&self, module: &str) -> &'static str {
        quality_grade(self.module_scores.get(module).copied().unwrap_or(0.0))
    }
    pub fn from_entries(entries: &[DocEntry]) -> Self {
        let catalog = Catalog::from_entries(entries);
        Self::compute(&catalog)
    }
}
