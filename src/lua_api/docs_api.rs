//! Registers the `luna.docs.*` documentation management API.
//!
//! Provides engine-integrated documentation management: scanning runtime bindings,
//! loading TOML doc catalogs, validating completeness, computing quality metrics,
//! and exporting structured data for VS Code extension IntelliSense.

use std::cell::RefCell;
use std::collections::HashMap;
use std::rc::Rc;

use mlua::prelude::*;

// ---------------------------------------------------------------------------
// Data types
// ---------------------------------------------------------------------------

/// A single documented API entry.
#[derive(Clone, Debug)]
struct DocEntryData {
    name: String,
    qualified_name: String,
    module: String,
    kind: String,
    description: String,
    parameters: Vec<ParamInfo>,
    returns: Vec<ReturnInfo>,
    example: Option<String>,
    since: Option<String>,
    deprecated: Option<String>,
}

#[derive(Clone, Debug)]
struct ParamInfo {
    name: String,
    type_name: String,
    description: String,
    optional: bool,
    default: Option<String>,
}

#[derive(Clone, Debug)]
struct ReturnInfo {
    type_name: String,
    description: String,
}

impl DocEntryData {
    /// Quality score: description(40%) + params(25%) + returns(20%) + example(15%).
    fn score(&self) -> f64 {
        let mut s = 0.0;
        if !self.description.is_empty() {
            s += 0.40;
        }
        if !self.parameters.is_empty() {
            s += 0.25;
        }
        if !self.returns.is_empty() {
            s += 0.20;
        }
        if self.example.is_some() {
            s += 0.15;
        }
        s
    }

    fn grade(score: f64) -> &'static str {
        if score >= 0.9 {
            "A"
        } else if score >= 0.75 {
            "B"
        } else if score >= 0.6 {
            "C"
        } else if score >= 0.4 {
            "D"
        } else {
            "F"
        }
    }
}

/// A structured registry of documented API entries.
#[derive(Clone, Debug)]
struct ApiCatalogData {
    entries: Vec<DocEntryData>,
}

impl ApiCatalogData {
    fn new() -> Self {
        Self {
            entries: Vec::new(),
        }
    }

    fn modules(&self) -> Vec<String> {
        let mut mods: Vec<String> = self
            .entries
            .iter()
            .map(|e| e.module.clone())
            .collect::<std::collections::HashSet<_>>()
            .into_iter()
            .collect();
        mods.sort();
        mods
    }

    fn entries_for_module(&self, module: &str) -> Vec<&DocEntryData> {
        self.entries
            .iter()
            .filter(|e| e.module == module)
            .collect()
    }

    fn get_entry(&self, qualified_name: &str) -> Option<&DocEntryData> {
        self.entries.iter().find(|e| e.qualified_name == qualified_name)
    }

    fn entry_count(&self, module: Option<&str>) -> usize {
        match module {
            Some(m) => self.entries.iter().filter(|e| e.module == m).count(),
            None => self.entries.len(),
        }
    }
}

// ---------------------------------------------------------------------------
// UserData: DocEntry
// ---------------------------------------------------------------------------

/// Wraps a single doc entry for Lua access.
#[derive(Clone)]
struct DocEntry(DocEntryData);

impl LuaUserData for DocEntry {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the name.
        ///
        /// # Returns
        /// The current name.
        methods.add_method("getName", |_, this, ()| Ok(this.0.name.clone()));
        /// Returns the qualified name.
        ///
        /// # Returns
        /// The current qualified name.
        methods.add_method("getQualifiedName", |_, this, ()| {
            Ok(this.0.qualified_name.clone())
        });
        /// Returns the module.
        ///
        /// # Returns
        /// The current module.
        methods.add_method("getModule", |_, this, ()| Ok(this.0.module.clone()));
        /// Returns the kind.
        ///
        /// # Returns
        /// The current kind.
        methods.add_method("getKind", |_, this, ()| Ok(this.0.kind.clone()));
        /// Returns the description.
        ///
        /// # Returns
        /// The current description.
        methods.add_method("getDescription", |_, this, ()| {
            Ok(this.0.description.clone())
        });
        /// Returns the parameters.
        ///
        /// # Returns
        /// The current parameters.
        methods.add_method("getParameters", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, p) in this.0.parameters.iter().enumerate() {
                let pt = lua.create_table()?;
                /// Name on this Object.
                ///
                /// # Returns
                /// The result.
                pt.set("name", p.name.clone())?;
                pt.set("type", p.type_name.clone())?;
                /// Description on this Object.
                ///
                /// # Returns
                /// The result.
                pt.set("description", p.description.clone())?;
                /// Optional on this Object.
                ///
                /// # Returns
                /// The result.
                pt.set("optional", p.optional)?;
                if let Some(ref d) = p.default {
                    /// Default on this Object.
                    ///
                    /// # Returns
                    /// The result.
                    pt.set("default", d.clone())?;
                }
                tbl.set(i + 1, pt)?;
            }
            Ok(tbl)
        });
        /// Returns the returns.
        ///
        /// # Returns
        /// The current returns.
        methods.add_method("getReturns", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, r) in this.0.returns.iter().enumerate() {
                let rt = lua.create_table()?;
                rt.set("type", r.type_name.clone())?;
                /// Description on this Object.
                ///
                /// # Returns
                /// The result.
                rt.set("description", r.description.clone())?;
                tbl.set(i + 1, rt)?;
            }
            Ok(tbl)
        });
        /// Returns the example.
        ///
        /// # Returns
        /// The current example.
        methods.add_method("getExample", |_, this, ()| Ok(this.0.example.clone()));
        /// Returns the since.
        ///
        /// # Returns
        /// The current since.
        methods.add_method("getSince", |_, this, ()| Ok(this.0.since.clone()));
        /// Returns the deprecated.
        ///
        /// # Returns
        /// The current deprecated.
        methods.add_method("getDeprecated", |_, this, ()| {
            Ok(this.0.deprecated.clone())
        });
        /// Returns the score.
        ///
        /// # Returns
        /// The current score.
        methods.add_method("getScore", |_, this, ()| Ok(this.0.score()));
        /// Returns `true` if description.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasDescription", |_, this, ()| {
            Ok(!this.0.description.is_empty())
        });
        /// Returns `true` if parameters.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasParameters", |_, this, ()| {
            Ok(!this.0.parameters.is_empty())
        });
        /// Returns `true` if return type.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasReturnType", |_, this, ()| {
            Ok(!this.0.returns.is_empty())
        });
        /// Returns `true` if example.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("hasExample", |_, this, ()| Ok(this.0.example.is_some()));
    }
}

// ---------------------------------------------------------------------------
// UserData: ApiCatalog
// ---------------------------------------------------------------------------

/// Wraps a catalog of API entries for Lua access.
#[derive(Clone)]
struct ApiCatalog(ApiCatalogData);

impl LuaUserData for ApiCatalog {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the modules.
        ///
        /// # Returns
        /// The current modules.
        methods.add_method("getModules", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, m) in this.0.modules().iter().enumerate() {
                tbl.set(i + 1, m.clone())?;
            }
            Ok(tbl)
        });

        /// Returns the entries.
        ///
        /// # Parameters
        /// - `module` — `string` optional.
        ///
        /// # Returns
        /// The current entries.
        methods.add_method("getEntries", |lua, this, module: Option<String>| {
            let tbl = lua.create_table()?;
            let entries: Vec<&DocEntryData> = match module.as_deref() {
                Some(m) => this.0.entries_for_module(m),
                None => this.0.entries.iter().collect(),
            };
            for (i, e) in entries.iter().enumerate() {
                tbl.set(i + 1, DocEntry((*e).clone()))?;
            }
            Ok(tbl)
        });

        /// Returns the entry.
        ///
        /// # Parameters
        /// - `qualified_name` — `string`.
        ///
        /// # Returns
        /// The current entry.
        methods.add_method("getEntry", |_, this, qualified_name: String| {
            Ok(this.0.get_entry(&qualified_name).map(|e| DocEntry(e.clone())))
        });

        /// Returns the types.
        ///
        /// # Parameters
        /// - `module_name` — `string`.
        ///
        /// # Returns
        /// The current types.
        methods.add_method("getTypes", |lua, this, module_name: String| {
            let tbl = lua.create_table()?;
            let mut idx = 1;
            for e in &this.0.entries {
                if e.module == module_name && e.kind == "type" {
                    tbl.set(idx, e.name.clone())?;
                    idx += 1;
                }
            }
            Ok(tbl)
        });

        /// Returns the type methods.
        ///
        /// # Parameters
        /// - `qualified_name` — `string`.
        ///
        /// # Returns
        /// The current type methods.
        methods.add_method("getTypeMethods", |lua, this, qualified_name: String| {
            let tbl = lua.create_table()?;
            let prefix = format!("{}:", qualified_name);
            let mut idx = 1;
            for e in &this.0.entries {
                if e.qualified_name.starts_with(&prefix) || e.kind == "method" && e.qualified_name.starts_with(&qualified_name) {
                    tbl.set(idx, DocEntry(e.clone()))?;
                    idx += 1;
                }
            }
            Ok(tbl)
        });

        /// Entry count on this Object.
        ///
        /// # Parameters
        /// - `module` — `string` optional.
        methods.add_method("entryCount", |_, this, module: Option<String>| {
            Ok(this.0.entry_count(module.as_deref()))
        });

        /// Merge on this Object.
        ///
        /// # Parameters
        /// - `other` — `userdata`.
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<ApiCatalog>()?;
            let mut merged = this.0.clone();
            for e in &other.0.entries {
                if merged.get_entry(&e.qualified_name).is_none() {
                    merged.entries.push(e.clone());
                } else {
                    // Override existing
                    if let Some(existing) = merged
                        .entries
                        .iter_mut()
                        .find(|x| x.qualified_name == e.qualified_name)
                    {
                        *existing = e.clone();
                    }
                }
            }
            Ok(ApiCatalog(merged))
        });

        /// Returns a filtered subset.
        ///
        /// # Parameters
        /// - `predicate` — `function`.
        methods.add_method("filter", |lua, this, predicate: LuaFunction| {
            let mut filtered = ApiCatalogData::new();
            for e in &this.0.entries {
                let entry = DocEntry(e.clone());
                let keep: bool = predicate.call(entry)?;
                if keep {
                    filtered.entries.push(e.clone());
                }
            }
            Ok(ApiCatalog(filtered))
        });

        /// Search on this Object.
        ///
        /// # Parameters
        /// - `query` — `string`.
        methods.add_method("search", |lua, this, query: String| {
            let query_lower = query.to_lowercase();
            let tbl = lua.create_table()?;
            let mut idx = 1;
            for e in &this.0.entries {
                if e.name.to_lowercase().contains(&query_lower)
                    || e.qualified_name.to_lowercase().contains(&query_lower)
                    || e.description.to_lowercase().contains(&query_lower)
                {
                    tbl.set(idx, DocEntry(e.clone()))?;
                    idx += 1;
                }
            }
            Ok(tbl)
        });

        /// To table on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("toTable", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, e) in this.0.entries.iter().enumerate() {
                let et = lua.create_table()?;
                /// Name on this Object.
                ///
                /// # Returns
                /// The result.
                et.set("name", e.name.clone())?;
                /// Qualified name on this Object.
                ///
                /// # Returns
                /// The result.
                et.set("qualifiedName", e.qualified_name.clone())?;
                /// Module on this Object.
                ///
                /// # Returns
                /// The result.
                et.set("module", e.module.clone())?;
                /// Kind on this Object.
                ///
                /// # Returns
                /// The result.
                et.set("kind", e.kind.clone())?;
                /// Description on this Object.
                ///
                /// # Returns
                /// The result.
                et.set("description", e.description.clone())?;
                /// Score on this Object.
                ///
                /// # Returns
                /// The result.
                et.set("score", e.score())?;
                tbl.set(i + 1, et)?;
            }
            Ok(tbl)
        });

        /// To j s o n on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("toJSON", |_, this, ()| {
            let mut entries = Vec::new();
            for e in &this.0.entries {
                let mut map = serde_json::Map::new();
                map.insert("name".into(), serde_json::json!(e.name));
                map.insert("qualifiedName".into(), serde_json::json!(e.qualified_name));
                map.insert("module".into(), serde_json::json!(e.module));
                map.insert("kind".into(), serde_json::json!(e.kind));
                map.insert("description".into(), serde_json::json!(e.description));
                map.insert("score".into(), serde_json::json!(e.score()));
                let params: Vec<serde_json::Value> = e
                    .parameters
                    .iter()
                    .map(|p| {
                        serde_json::json!({
                            "name": p.name,
                            "type": p.type_name,
                            "description": p.description,
                            "optional": p.optional
                        })
                    })
                    .collect();
                map.insert("parameters".into(), serde_json::json!(params));
                let returns: Vec<serde_json::Value> = e
                    .returns
                    .iter()
                    .map(|r| {
                        serde_json::json!({
                            "type": r.type_name,
                            "description": r.description
                        })
                    })
                    .collect();
                map.insert("returns".into(), serde_json::json!(returns));
                entries.push(serde_json::Value::Object(map));
            }
            Ok(serde_json::to_string_pretty(&entries).unwrap_or_default())
        });
    }
}

// ---------------------------------------------------------------------------
// UserData: ValidationReport
// ---------------------------------------------------------------------------

/// Results of validating catalog completeness.
#[derive(Clone)]
struct ValidationReport {
    missing: Vec<String>,
    phantom: Vec<String>,
    incomplete: Vec<String>,
}

impl LuaUserData for ValidationReport {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns `true` if valid.
        ///
        /// # Returns
        /// `boolean`.
        methods.add_method("isValid", |_, this, ()| Ok(this.missing.is_empty()));
        /// Returns the missing.
        ///
        /// # Returns
        /// The current missing.
        methods.add_method("getMissing", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, m) in this.missing.iter().enumerate() {
                tbl.set(i + 1, m.clone())?;
            }
            Ok(tbl)
        });
        /// Returns the phantom.
        ///
        /// # Returns
        /// The current phantom.
        methods.add_method("getPhantom", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, p) in this.phantom.iter().enumerate() {
                tbl.set(i + 1, p.clone())?;
            }
            Ok(tbl)
        });
        /// Returns the incomplete.
        ///
        /// # Returns
        /// The current incomplete.
        methods.add_method("getIncomplete", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, inc) in this.incomplete.iter().enumerate() {
                tbl.set(i + 1, inc.clone())?;
            }
            Ok(tbl)
        });
        /// Missing count on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("missingCount", |_, this, ()| Ok(this.missing.len()));
        /// Phantom count on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("phantomCount", |_, this, ()| Ok(this.phantom.len()));
        /// Incomplete count on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("incompleteCount", |_, this, ()| Ok(this.incomplete.len()));
        /// Returns the summary.
        ///
        /// # Returns
        /// The current summary.
        methods.add_method("getSummary", |_, this, ()| {
            Ok(format!(
                "Missing: {}, Phantom: {}, Incomplete: {}",
                this.missing.len(),
                this.phantom.len(),
                this.incomplete.len()
            ))
        });
        /// To table on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("toTable", |lua, this, ()| {
            let tbl = lua.create_table()?;
            let missing = lua.create_table()?;
            for (i, m) in this.missing.iter().enumerate() {
                missing.set(i + 1, m.clone())?;
            }
            /// Missing on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("missing", missing)?;
            let phantom = lua.create_table()?;
            for (i, p) in this.phantom.iter().enumerate() {
                phantom.set(i + 1, p.clone())?;
            }
            /// Phantom on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("phantom", phantom)?;
            let incomplete = lua.create_table()?;
            for (i, inc) in this.incomplete.iter().enumerate() {
                incomplete.set(i + 1, inc.clone())?;
            }
            /// Incomplete on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("incomplete", incomplete)?;
            Ok(tbl)
        });
        /// To j s o n on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("toJSON", |_, this, ()| {
            let val = serde_json::json!({
                "missing": this.missing,
                "phantom": this.phantom,
                "incomplete": this.incomplete,
                "isValid": this.missing.is_empty()
            });
            Ok(serde_json::to_string_pretty(&val).unwrap_or_default())
        });
    }
}

// ---------------------------------------------------------------------------
// UserData: QualityReport
// ---------------------------------------------------------------------------

/// Quality metrics for API documentation.
#[derive(Clone)]
struct QualityReport {
    entries: Vec<DocEntryData>,
    module_scores: HashMap<String, f64>,
    overall_score: f64,
}

impl LuaUserData for QualityReport {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        /// Returns the overall score.
        ///
        /// # Returns
        /// The current overall score.
        methods.add_method("getOverallScore", |_, this, ()| Ok(this.overall_score));
        /// Returns the grade.
        ///
        /// # Returns
        /// The current grade.
        methods.add_method("getGrade", |_, this, ()| {
            Ok(DocEntryData::grade(this.overall_score).to_string())
        });
        /// Returns the module scores.
        ///
        /// # Parameters
        /// - `count` — `integer` optional.
        ///
        /// # Returns
        /// The current module scores.
        methods.add_method("getModuleScores", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (k, v) in &this.module_scores {
                tbl.set(k.clone(), *v)?;
            }
            Ok(tbl)
        });
        /// Returns the worst.
        ///
        /// # Parameters
        /// - `count` — `integer` optional.
        ///
        /// # Returns
        /// The current worst.
        methods.add_method("getWorst", |lua, this, count: Option<usize>| {
            let n = count.unwrap_or(10);
            let mut sorted = this.entries.clone();
            sorted.sort_by(|a, b| a.score().partial_cmp(&b.score()).unwrap_or(std::cmp::Ordering::Equal));
            let tbl = lua.create_table()?;
            for (i, e) in sorted.iter().take(n).enumerate() {
                tbl.set(i + 1, DocEntry(e.clone()))?;
            }
            Ok(tbl)
        });
        /// Returns the best.
        ///
        /// # Parameters
        /// - `count` — `integer` optional.
        ///
        /// # Returns
        /// The current best.
        methods.add_method("getBest", |lua, this, count: Option<usize>| {
            let n = count.unwrap_or(10);
            let mut sorted = this.entries.clone();
            sorted.sort_by(|a, b| b.score().partial_cmp(&a.score()).unwrap_or(std::cmp::Ordering::Equal));
            let tbl = lua.create_table()?;
            for (i, e) in sorted.iter().take(n).enumerate() {
                tbl.set(i + 1, DocEntry(e.clone()))?;
            }
            Ok(tbl)
        });
        /// Returns the by grade.
        ///
        /// # Parameters
        /// - `grade` — `string`.
        ///
        /// # Returns
        /// The current by grade.
        methods.add_method("getByGrade", |lua, this, grade: String| {
            let tbl = lua.create_table()?;
            let mut idx = 1;
            for e in &this.entries {
                if DocEntryData::grade(e.score()) == grade {
                    tbl.set(idx, DocEntry(e.clone()))?;
                    idx += 1;
                }
            }
            Ok(tbl)
        });
        /// Returns the summary.
        ///
        /// # Returns
        /// The current summary.
        methods.add_method("getSummary", |_, this, ()| {
            let mut lines = vec![format!(
                "Overall: {} ({:.0}%)",
                DocEntryData::grade(this.overall_score),
                this.overall_score * 100.0
            )];
            let mut mods: Vec<(&String, &f64)> = this.module_scores.iter().collect();
            mods.sort_by_key(|(k, _)| k.clone());
            for (m, s) in mods {
                lines.push(format!("  {}: {:.0}%", m, s * 100.0));
            }
            Ok(lines.join("\n"))
        });
        /// To table on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("toTable", |lua, this, ()| {
            let tbl = lua.create_table()?;
            /// Overall score on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("overallScore", this.overall_score)?;
            /// Grade on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("grade", DocEntryData::grade(this.overall_score))?;
            let mods = lua.create_table()?;
            for (k, v) in &this.module_scores {
                mods.set(k.clone(), *v)?;
            }
            /// Module scores on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("moduleScores", mods)?;
            Ok(tbl)
        });
        /// To j s o n on this Object.
        ///
        /// # Returns
        /// The result.
        methods.add_method("toJSON", |_, this, ()| {
            let val = serde_json::json!({
                "overallScore": this.overall_score,
                "grade": DocEntryData::grade(this.overall_score),
                "moduleScores": this.module_scores
            });
            Ok(serde_json::to_string_pretty(&val).unwrap_or_default())
        });
    }
}

// ---------------------------------------------------------------------------
// Internal state
// ---------------------------------------------------------------------------

/// State shared between all luna.docs closures via Rc<RefCell>.
struct DocsState {
    catalog: ApiCatalogData,
}

impl DocsState {
    fn new() -> Self {
        Self {
            catalog: ApiCatalogData::new(),
        }
    }

    fn compute_quality(&self, entries: &[DocEntryData]) -> QualityReport {
        if entries.is_empty() {
            return QualityReport {
                entries: vec![],
                module_scores: HashMap::new(),
                overall_score: 0.0,
            };
        }
        let total: f64 = entries.iter().map(|e| e.score()).sum();
        let overall = total / entries.len() as f64;

        let mut module_totals: HashMap<String, (f64, usize)> = HashMap::new();
        for e in entries {
            let entry = module_totals.entry(e.module.clone()).or_insert((0.0, 0));
            entry.0 += e.score();
            entry.1 += 1;
        }
        let module_scores: HashMap<String, f64> = module_totals
            .into_iter()
            .map(|(k, (sum, count))| (k, sum / count as f64))
            .collect();

        QualityReport {
            entries: entries.to_vec(),
            module_scores,
            overall_score: overall,
        }
    }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Walk a Lua table recursively to discover bindings.
fn scan_table(
    lua: &Lua,
    table: &LuaTable,
    prefix: &str,
    module_name: &str,
    entries: &mut Vec<DocEntryData>,
    depth: usize,
) -> LuaResult<()> {
    if depth > 5 || entries.len() > 50000 {
        return Ok(());
    }
    for pair in table.clone().pairs::<String, LuaValue>() {
        let (key, value) = pair?;
        let qualified = if prefix.is_empty() {
            key.clone()
        } else {
            format!("{}.{}", prefix, key)
        };

        match &value {
            LuaValue::Function(_) => {
                entries.push(DocEntryData {
                    name: key,
                    qualified_name: qualified,
                    module: module_name.to_string(),
                    kind: "function".to_string(),
                    description: String::new(),
                    parameters: vec![],
                    returns: vec![],
                    example: None,
                    since: None,
                    deprecated: None,
                });
            }
            LuaValue::Table(sub) => {
                // Recurse into sub-tables (sub-modules)
                scan_table(lua, sub, &qualified, &key, entries, depth + 1)?;
            }
            _ => {}
        }
    }
    Ok(())
}

// ---------------------------------------------------------------------------
// Registration
// ---------------------------------------------------------------------------

/// Registers the `luna.docs` namespace.
pub fn register(lua: &Lua, luna_table: &LuaTable) -> LuaResult<()> {
    let docs = lua.create_table()?;
    let state = Rc::new(RefCell::new(DocsState::new()));

    // ===== Catalog Management =====

    /// Scan the luna.* namespace to build an API catalog from live bindings.
    docs.set(
        "scan",
        lua.create_function(|lua, _opts: Option<LuaTable>| {
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("luna")?;
            let mut entries = Vec::new();
            scan_table(lua, &luna_tbl, "luna", "luna", &mut entries, 0)?;
            Ok(ApiCatalog(ApiCatalogData { entries }))
        })?,
    )?;

    /// Scan a single module's bindings.
    docs.set(
        "scanModule",
        lua.create_function(|lua, module_name: String| {
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("luna")?;
            let sub: LuaTable = luna_tbl.get(module_name.clone())?;
            let prefix = format!("luna.{}", module_name);
            let mut entries = Vec::new();
            scan_table(lua, &sub, &prefix, &module_name, &mut entries, 0)?;
            Ok(ApiCatalog(ApiCatalogData { entries }))
        })?,
    )?;

    /// Load a TOML doc file into an ApiCatalog.
    docs.set(
        "loadToml",
        lua.create_function(|lua, path: String| {
            // Read file content
            let content = std::fs::read_to_string(&path)
                .map_err(|e| LuaError::RuntimeError(format!("failed to read {}: {}", path, e)))?;

            // Parse TOML via luna.data.parseToml
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("luna")?;
            let data_tbl: LuaTable = luna_tbl.get("data")?;
            let parse_fn: LuaFunction = data_tbl.get("parseToml")?;
            let parsed: LuaTable = parse_fn.call(content)?;

            // Convert TOML table to entries
            let mut entries = Vec::new();
            if let Ok(api_entries) = parsed.get::<_, LuaTable>("entries") {
                for pair in api_entries.pairs::<i64, LuaTable>() {
                    if let Ok((_, entry_tbl)) = pair {
                        let name: String = entry_tbl.get("name").unwrap_or_default();
                        let qname: String = entry_tbl.get("qualifiedName").unwrap_or_default();
                        let module: String = entry_tbl.get("module").unwrap_or_default();
                        let kind: String = entry_tbl.get("kind").unwrap_or("function".into());
                        let desc: String = entry_tbl.get("description").unwrap_or_default();
                        let example: Option<String> = entry_tbl.get("example").ok();
                        let since: Option<String> = entry_tbl.get("since").ok();
                        let deprecated: Option<String> = entry_tbl.get("deprecated").ok();

                        entries.push(DocEntryData {
                            name,
                            qualified_name: qname,
                            module,
                            kind,
                            description: desc,
                            parameters: vec![],
                            returns: vec![],
                            example,
                            since,
                            deprecated,
                        });
                    }
                }
            }
            Ok(ApiCatalog(ApiCatalogData { entries }))
        })?,
    )?;

    /// Load all .toml files in a directory and merge.
    docs.set(
        "loadAll",
        lua.create_function(|lua, directory: String| {
            let mut all_entries = Vec::new();
            if let Ok(read_dir) = std::fs::read_dir(&directory) {
                for entry in read_dir.flatten() {
                    let path = entry.path();
                    if path.extension().map_or(false, |e| e == "toml") {
                        if let Ok(content) = std::fs::read_to_string(&path) {
                            let globals = lua.globals();
                            let luna_tbl: LuaTable = globals.get("luna")?;
                            let data_tbl: LuaTable = luna_tbl.get("data")?;
                            let parse_fn: LuaFunction = data_tbl.get("parseToml")?;
                            if let Ok(parsed) = parse_fn.call::<_, LuaTable>(content) {
                                if let Ok(entries) = parsed.get::<_, LuaTable>("entries") {
                                    for pair in entries.pairs::<i64, LuaTable>() {
                                        if let Ok((_, et)) = pair {
                                            all_entries.push(DocEntryData {
                                                name: et.get("name").unwrap_or_default(),
                                                qualified_name: et
                                                    .get("qualifiedName")
                                                    .unwrap_or_default(),
                                                module: et.get("module").unwrap_or_default(),
                                                kind: et
                                                    .get("kind")
                                                    .unwrap_or("function".into()),
                                                description: et
                                                    .get("description")
                                                    .unwrap_or_default(),
                                                parameters: vec![],
                                                returns: vec![],
                                                example: et.get("example").ok(),
                                                since: et.get("since").ok(),
                                                deprecated: et.get("deprecated").ok(),
                                            });
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Ok(ApiCatalog(ApiCatalogData {
                entries: all_entries,
            }))
        })?,
    )?;

    /// Inject a description for an API entry.
    let s = state.clone();
    docs.set(
        "describe",
        lua.create_function(move |_, (qualified_name, description): (String, String)| {
            let mut st = s.borrow_mut();
            if let Some(entry) = st
                .catalog
                .entries
                .iter_mut()
                .find(|e| e.qualified_name == qualified_name)
            {
                entry.description = description;
            } else {
                // Create a new entry
                let parts: Vec<&str> = qualified_name.rsplitn(2, '.').collect();
                let name = parts[0].to_string();
                let module = if parts.len() > 1 {
                    parts[1].to_string()
                } else {
                    String::new()
                };
                st.catalog.entries.push(DocEntryData {
                    name,
                    qualified_name,
                    module,
                    kind: "function".to_string(),
                    description,
                    parameters: vec![],
                    returns: vec![],
                    example: None,
                    since: None,
                    deprecated: None,
                });
            }
            Ok(())
        })?,
    )?;

    /// Set parameter info for an entry.
    let s = state.clone();
    docs.set(
        "setParamInfo",
        lua.create_function(move |_, (qualified_name, params): (String, LuaTable)| {
            let mut st = s.borrow_mut();
            let mut param_list = Vec::new();
            for pair in params.pairs::<i64, LuaTable>() {
                if let Ok((_, pt)) = pair {
                    param_list.push(ParamInfo {
                        name: pt.get("name").unwrap_or_default(),
                        type_name: pt.get("type").unwrap_or_default(),
                        description: pt.get("description").unwrap_or_default(),
                        optional: pt.get("optional").unwrap_or(false),
                        default: pt.get("default").ok(),
                    });
                }
            }
            if let Some(entry) = st
                .catalog
                .entries
                .iter_mut()
                .find(|e| e.qualified_name == qualified_name)
            {
                entry.parameters = param_list;
            }
            Ok(())
        })?,
    )?;

    /// Set return type info for an entry.
    let s = state.clone();
    docs.set(
        "setReturnInfo",
        lua.create_function(move |_, (qualified_name, returns): (String, LuaTable)| {
            let mut st = s.borrow_mut();
            let mut return_list = Vec::new();
            for pair in returns.pairs::<i64, LuaTable>() {
                if let Ok((_, rt)) = pair {
                    return_list.push(ReturnInfo {
                        type_name: rt.get("type").unwrap_or_default(),
                        description: rt.get("description").unwrap_or_default(),
                    });
                }
            }
            if let Some(entry) = st
                .catalog
                .entries
                .iter_mut()
                .find(|e| e.qualified_name == qualified_name)
            {
                entry.returns = return_list;
            }
            Ok(())
        })?,
    )?;

    /// Get the current internal catalog.
    let s = state.clone();
    docs.set(
        "getCatalog",
        lua.create_function(move |_, ()| Ok(ApiCatalog(s.borrow().catalog.clone())))?,
    )?;

    /// Reset the internal catalog.
    let s = state.clone();
    docs.set(
        "resetCatalog",
        lua.create_function(move |_, ()| {
            s.borrow_mut().catalog = ApiCatalogData::new();
            Ok(())
        })?,
    )?;

    // ===== Validation =====

    /// Validate catalog completeness against live bindings.
    docs.set(
        "validate",
        lua.create_function(|lua, catalog_ud: Option<LuaAnyUserData>| {
            let catalog = catalog_ud.map(|ud| ud.borrow::<ApiCatalog>().map(|c| c.clone())).transpose()?;
            // Scan live bindings
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("luna")?;
            let mut live_entries = Vec::new();
            scan_table(lua, &luna_tbl, "luna", "luna", &mut live_entries, 0)?;

            let live_names: std::collections::HashSet<String> =
                live_entries.iter().map(|e| e.qualified_name.clone()).collect();

            let cat = match catalog {
                Some(c) => c.0.clone(),
                None => ApiCatalogData::new(),
            };
            let doc_names: std::collections::HashSet<String> =
                cat.entries.iter().map(|e| e.qualified_name.clone()).collect();

            let missing: Vec<String> = live_names
                .difference(&doc_names)
                .cloned()
                .collect();
            let phantom: Vec<String> = doc_names
                .difference(&live_names)
                .cloned()
                .collect();
            let incomplete: Vec<String> = cat
                .entries
                .iter()
                .filter(|e| e.description.is_empty() || e.parameters.is_empty() || e.returns.is_empty())
                .map(|e| e.qualified_name.clone())
                .collect();

            Ok(ValidationReport {
                missing,
                phantom,
                incomplete,
            })
        })?,
    )?;

    /// Validate a single module.
    docs.set(
        "validateModule",
        lua.create_function(|lua, (module_name, catalog_ud): (String, Option<LuaAnyUserData>)| {
            let catalog = catalog_ud.map(|ud| ud.borrow::<ApiCatalog>().map(|c| c.clone())).transpose()?;
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("luna")?;
            let sub: LuaTable = luna_tbl.get(module_name.clone())?;
            let prefix = format!("luna.{}", module_name);
            let mut live_entries = Vec::new();
            scan_table(lua, &sub, &prefix, &module_name, &mut live_entries, 0)?;

            let live_names: std::collections::HashSet<String> =
                live_entries.iter().map(|e| e.qualified_name.clone()).collect();

            let cat = match catalog {
                Some(c) => c.0.clone(),
                None => ApiCatalogData::new(),
            };
            let doc_names: std::collections::HashSet<String> = cat
                .entries
                .iter()
                .filter(|e| e.module == module_name)
                .map(|e| e.qualified_name.clone())
                .collect();

            let missing: Vec<String> = live_names.difference(&doc_names).cloned().collect();
            let phantom: Vec<String> = doc_names.difference(&live_names).cloned().collect();
            let incomplete: Vec<String> = cat
                .entries
                .iter()
                .filter(|e| e.module == module_name)
                .filter(|e| e.description.is_empty() || e.parameters.is_empty() || e.returns.is_empty())
                .map(|e| e.qualified_name.clone())
                .collect();

            Ok(ValidationReport {
                missing,
                phantom,
                incomplete,
            })
        })?,
    )?;

    /// Compare catalog timestamps against source files.
    docs.set(
        "checkStaleness",
        lua.create_function(|lua, (_catalog_ud, source_dir): (LuaAnyUserData, String)| {
            let tbl = lua.create_table()?;
            let stale = lua.create_table()?;
            let current = lua.create_table()?;
            let missing_tbl = lua.create_table()?;
            // Basic implementation — check if source files exist
            if let Ok(read_dir) = std::fs::read_dir(&source_dir) {
                let mut idx = 1;
                for entry in read_dir.flatten() {
                    let path = entry.path();
                    if path.extension().map_or(false, |e| e == "rs" || e == "lua") {
                        current.set(idx, path.to_string_lossy().to_string())?;
                        idx += 1;
                    }
                }
            }
            /// Stale on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("stale", stale)?;
            /// Current on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("current", current)?;
            /// Missing on this Object.
            ///
            /// # Returns
            /// The result.
            tbl.set("missing", missing_tbl)?;
            Ok(tbl)
        })?,
    )?;

    // ===== Metrics =====

    /// Calculate quality metrics for a catalog.
    let s = state.clone();
    docs.set(
        "quality",
        lua.create_function(move |_, catalog_ud: Option<LuaAnyUserData>| {
            let st = s.borrow();
            let catalog = catalog_ud.map(|ud| ud.borrow::<ApiCatalog>().map(|c| c.clone())).transpose()?;
            let entries = match catalog {
                Some(c) => c.0.entries,
                None => st.catalog.entries.clone(),
            };
            Ok(st.compute_quality(&entries))
        })?,
    )?;

    /// Quality for a single module.
    let s = state.clone();
    docs.set(
        "qualityModule",
        lua.create_function(move |_, (module_name, catalog_ud): (String, Option<LuaAnyUserData>)| {
            let st = s.borrow();
            let catalog = catalog_ud.map(|ud| ud.borrow::<ApiCatalog>().map(|c| c.clone())).transpose()?;
            let all = match catalog {
                Some(c) => c.0.entries,
                None => st.catalog.entries.clone(),
            };
            let filtered: Vec<DocEntryData> = all
                .into_iter()
                .filter(|e| e.module == module_name)
                .collect();
            Ok(st.compute_quality(&filtered))
        })?,
    )?;

    /// Coverage: (documented, total).
    docs.set(
        "coverage",
        lua.create_function(|lua, catalog_ud: Option<LuaAnyUserData>| {
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("luna")?;
            let mut live = Vec::new();
            scan_table(lua, &luna_tbl, "luna", "luna", &mut live, 0)?;
            let total = live.len();

            let catalog = catalog_ud.map(|ud| ud.borrow::<ApiCatalog>().map(|c| c.clone())).transpose()?;
            let documented = match catalog {
                Some(c) => c.0.entries.len(),
                None => 0,
            };
            Ok((documented, total))
        })?,
    )?;

    /// Module-level coverage.
    docs.set(
        "coverageModule",
        lua.create_function(|lua, (module_name, catalog_ud): (String, Option<LuaAnyUserData>)| {
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("luna")?;
            let sub: LuaTable = luna_tbl.get(module_name.clone())?;
            let prefix = format!("luna.{}", module_name);
            let mut live = Vec::new();
            scan_table(lua, &sub, &prefix, &module_name, &mut live, 0)?;
            let total = live.len();

            let catalog = catalog_ud.map(|ud| ud.borrow::<ApiCatalog>().map(|c| c.clone())).transpose()?;
            let documented = match catalog {
                Some(c) => c.0.entries.iter().filter(|e| e.module == module_name).count(),
                None => 0,
            };
            Ok((documented, total))
        })?,
    )?;

    // ===== Export =====

    /// Export completions JSON for VS Code IntelliSense.
    docs.set(
        "exportCompletions",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            let completions: Vec<serde_json::Value> = catalog
                .0
                .entries
                .iter()
                .map(|e| {
                    serde_json::json!({
                        "label": e.name,
                        "kind": match e.kind.as_str() {
                            "function" | "method" => "Function",
                            "type" => "Class",
                            "enum" => "Enum",
                            _ => "Variable"
                        },
                        "detail": e.qualified_name,
                        "documentation": e.description
                    })
                })
                .collect();
            let json = serde_json::to_string_pretty(&completions).unwrap_or_default();
            std::fs::write(&path, json)
                .map_err(|e| LuaError::RuntimeError(format!("write error: {}", e)))?;
            Ok(())
        })?,
    )?;

    /// Export hover JSON.
    docs.set(
        "exportHover",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            let mut hover: HashMap<String, serde_json::Value> = HashMap::new();
            for e in &catalog.0.entries {
                hover.insert(
                    e.qualified_name.clone(),
                    serde_json::json!({
                        "name": e.qualified_name,
                        "description": e.description,
                        "kind": e.kind,
                        "parameters": e.parameters.iter().map(|p| {
                            serde_json::json!({"name": p.name, "type": p.type_name, "description": p.description})
                        }).collect::<Vec<_>>(),
                        "returns": e.returns.iter().map(|r| {
                            serde_json::json!({"type": r.type_name, "description": r.description})
                        }).collect::<Vec<_>>()
                    }),
                );
            }
            let json = serde_json::to_string_pretty(&hover).unwrap_or_default();
            std::fs::write(&path, json)
                .map_err(|e| LuaError::RuntimeError(format!("write error: {}", e)))?;
            Ok(())
        })?,
    )?;

    /// Export signatures JSON.
    docs.set(
        "exportSignatures",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            let mut sigs: HashMap<String, serde_json::Value> = HashMap::new();
            for e in &catalog.0.entries {
                if !e.parameters.is_empty() {
                    let params: Vec<serde_json::Value> = e
                        .parameters
                        .iter()
                        .map(|p| {
                            serde_json::json!({
                                "label": if p.optional {
                                    format!("{}?: {}", p.name, p.type_name)
                                } else {
                                    format!("{}: {}", p.name, p.type_name)
                                },
                                "documentation": p.description
                            })
                        })
                        .collect();
                    sigs.insert(
                        e.qualified_name.clone(),
                        serde_json::json!({
                            "label": e.qualified_name,
                            "parameters": params
                        }),
                    );
                }
            }
            let json = serde_json::to_string_pretty(&sigs).unwrap_or_default();
            std::fs::write(&path, json)
                .map_err(|e| LuaError::RuntimeError(format!("write error: {}", e)))?;
            Ok(())
        })?,
    )?;

    /// Export all three files to a directory.
    docs.set(
        "exportAll",
        lua.create_function(|_, (catalog_ud, output_dir): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            std::fs::create_dir_all(&output_dir)
                .map_err(|e| LuaError::RuntimeError(format!("mkdir error: {}", e)))?;

            // Completions
            let completions: Vec<serde_json::Value> = catalog
                .0
                .entries
                .iter()
                .map(|e| {
                    serde_json::json!({
                        "label": e.name,
                        "kind": match e.kind.as_str() {
                            "function" | "method" => "Function",
                            "type" => "Class",
                            _ => "Variable"
                        },
                        "detail": e.qualified_name,
                        "documentation": e.description
                    })
                })
                .collect();
            let path = format!("{}/completions.json", output_dir);
            std::fs::write(&path, serde_json::to_string_pretty(&completions).unwrap_or_default())
                .map_err(|e| LuaError::RuntimeError(format!("write error: {}", e)))?;

            // Hover
            let mut hover: HashMap<String, serde_json::Value> = HashMap::new();
            for e in &catalog.0.entries {
                hover.insert(
                    e.qualified_name.clone(),
                    serde_json::json!({
                        "name": e.qualified_name,
                        "description": e.description,
                        "kind": e.kind
                    }),
                );
            }
            let path = format!("{}/hover.json", output_dir);
            std::fs::write(&path, serde_json::to_string_pretty(&hover).unwrap_or_default())
                .map_err(|e| LuaError::RuntimeError(format!("write error: {}", e)))?;

            // Signatures
            let mut sigs: HashMap<String, serde_json::Value> = HashMap::new();
            for e in &catalog.0.entries {
                if !e.parameters.is_empty() {
                    let params: Vec<serde_json::Value> = e
                        .parameters
                        .iter()
                        .map(|p| serde_json::json!({"label": p.name, "documentation": p.description}))
                        .collect();
                    sigs.insert(
                        e.qualified_name.clone(),
                        serde_json::json!({"label": e.qualified_name, "parameters": params}),
                    );
                }
            }
            let path = format!("{}/signatures.json", output_dir);
            std::fs::write(&path, serde_json::to_string_pretty(&sigs).unwrap_or_default())
                .map_err(|e| LuaError::RuntimeError(format!("write error: {}", e)))?;

            Ok(())
        })?,
    )?;

    /// Export markdown API reference.
    docs.set(
        "exportMarkdown",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            let mut md = String::from("# API Reference\n\n");
            let mods = catalog.0.modules();
            for module in &mods {
                md.push_str(&format!("## {}\n\n", module));
                for e in catalog.0.entries_for_module(module) {
                    md.push_str(&format!("### `{}`\n\n", e.qualified_name));
                    if !e.description.is_empty() {
                        md.push_str(&format!("{}\n\n", e.description));
                    }
                    if !e.parameters.is_empty() {
                        md.push_str("**Parameters:**\n\n");
                        for p in &e.parameters {
                            md.push_str(&format!(
                                "- `{}` ({}){}\n",
                                p.name,
                                p.type_name,
                                if p.optional { " — optional" } else { "" }
                            ));
                        }
                        md.push('\n');
                    }
                    if !e.returns.is_empty() {
                        md.push_str("**Returns:** ");
                        let parts: Vec<String> = e
                            .returns
                            .iter()
                            .map(|r| format!("`{}`", r.type_name))
                            .collect();
                        md.push_str(&parts.join(", "));
                        md.push_str("\n\n");
                    }
                    md.push_str("---\n\n");
                }
            }
            std::fs::write(&path, md)
                .map_err(|e| LuaError::RuntimeError(format!("write error: {}", e)))?;
            Ok(())
        })?,
    )?;

    /// Export one-line-per-function cheatsheet.
    docs.set(
        "exportCheatsheet",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            let mut lines = Vec::new();
            let mods = catalog.0.modules();
            for module in &mods {
                lines.push(format!("# {}", module));
                for e in catalog.0.entries_for_module(module) {
                    let params: Vec<String> = e.parameters.iter().map(|p| p.name.clone()).collect();
                    let sig = if params.is_empty() {
                        format!("{}()", e.qualified_name)
                    } else {
                        format!("{}({})", e.qualified_name, params.join(", "))
                    };
                    let desc = if e.description.is_empty() {
                        String::new()
                    } else {
                        format!(" — {}", e.description)
                    };
                    lines.push(format!("  {}{}", sig, desc));
                }
                lines.push(String::new());
            }
            std::fs::write(&path, lines.join("\n"))
                .map_err(|e| LuaError::RuntimeError(format!("write error: {}", e)))?;
            Ok(())
        })?,
    )?;

    /// Docs on this Object.
    ///
    /// # Returns
    /// The result.
    luna_table.set("docs", docs)?;
    Ok(())
}
