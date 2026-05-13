use super::SharedState;
use crate::docs;
use mlua::prelude::*;
use std::cell::RefCell;
use std::rc::Rc;
struct LuaSchema(docs::Schema);
impl LuaUserData for LuaSchema {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("validate", |lua, this, data: LuaTable| {
            let mut fields: Vec<(String, &'static str, String)> = Vec::new();
            for pair in data.clone().pairs::<String, LuaValue>() {
                let (k, v) = pair?;
                let (type_name, value_str): (&'static str, String) = match &v {
                    LuaValue::String(s) => ("string", s.to_str().unwrap_or("").to_string()),
                    LuaValue::Integer(n) => ("integer", n.to_string()),
                    LuaValue::Number(n) => ("number", n.to_string()),
                    LuaValue::Boolean(b) => ("boolean", b.to_string()),
                    LuaValue::Table(_) => ("table", "(table)".into()),
                    LuaValue::Function(_) => ("function", "(function)".into()),
                    LuaValue::UserData(_) => ("userdata", "(userdata)".into()),
                    _ => ("nil", "(nil)".into()),
                };
                fields.push((k, type_name, value_str));
            }
            let result = this.0.validate_pairs(&fields);
            let errors_tbl = lua.create_table()?;
            for (i, e) in result.errors.iter().enumerate() {
                let et = lua.create_table()?;
                et.set("field", e.field.clone())?;
                et.set("message", e.message.clone())?;
                errors_tbl.set(i + 1, et)?;
            }
            Ok((result.ok, errors_tbl))
        });
        methods.add_method("check", |_, this, data: LuaTable| {
            let mut fields: Vec<(String, &'static str, String)> = Vec::new();
            for pair in data.clone().pairs::<String, LuaValue>() {
                let (k, v) = pair?;
                let (type_name, value_str): (&'static str, String) = match &v {
                    LuaValue::String(s) => ("string", s.to_str().unwrap_or("").to_string()),
                    LuaValue::Integer(n) => ("integer", n.to_string()),
                    LuaValue::Number(n) => ("number", n.to_string()),
                    LuaValue::Boolean(b) => ("boolean", b.to_string()),
                    LuaValue::Table(_) => ("table", "(table)".into()),
                    LuaValue::Function(_) => ("function", "(function)".into()),
                    _ => ("nil", "(nil)".into()),
                };
                fields.push((k, type_name, value_str));
            }
            Ok(this.0.validate_pairs(&fields).ok)
        });
        methods.add_method("assert", |_, this, data: LuaTable| {
            let mut fields: Vec<(String, &'static str, String)> = Vec::new();
            for pair in data.clone().pairs::<String, LuaValue>() {
                let (k, v) = pair?;
                let (type_name, value_str): (&'static str, String) = match &v {
                    LuaValue::String(s) => ("string", s.to_str().unwrap_or("").to_string()),
                    LuaValue::Integer(n) => ("integer", n.to_string()),
                    LuaValue::Number(n) => ("number", n.to_string()),
                    LuaValue::Boolean(b) => ("boolean", b.to_string()),
                    LuaValue::Table(_) => ("table", "(table)".into()),
                    LuaValue::Function(_) => ("function", "(function)".into()),
                    _ => ("nil", "(nil)".into()),
                };
                fields.push((k, type_name, value_str));
            }
            let result = this.0.validate_pairs(&fields);
            if !result.ok {
                let msg = result
                    .errors
                    .iter()
                    .map(|e| e.message.clone())
                    .collect::<Vec<_>>()
                    .join("; ");
                return Err(LuaError::external(format!(
                    "schema validation failed: {msg}"
                )));
            }
            Ok(())
        });
        methods.add_method("getName", |_, this, ()| Ok(this.0.name.clone()));
        methods.add_method("getFields", |lua, this, ()| {
            let tbl = lua.create_table()?;
            let mut names: Vec<&String> = this.0.rules.keys().collect();
            names.sort();
            for (i, n) in names.iter().enumerate() {
                tbl.set(i + 1, n.as_str())?;
            }
            Ok(tbl)
        });
        methods.add_method("type", |_, _, ()| Ok("LSchema"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LSchema" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct DocEntry(docs::DocEntry);
impl LuaUserData for DocEntry {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getName", |_, this, ()| Ok(this.0.name.clone()));
        methods.add_method("getQualifiedName", |_, this, ()| {
            Ok(this.0.qualified_name.clone())
        });
        methods.add_method("getModule", |_, this, ()| Ok(this.0.module.clone()));
        methods.add_method("getKind", |_, this, ()| Ok(this.0.kind.clone()));
        methods.add_method("getDescription", |_, this, ()| {
            Ok(this.0.description.clone())
        });
        methods.add_method("getParameters", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, p) in this.0.parameters.iter().enumerate() {
                let pt = lua.create_table()?;
                pt.set("name", p.name.clone())?;
                pt.set("type", p.type_name.clone())?;
                pt.set("description", p.description.clone())?;
                pt.set("optional", p.optional)?;
                if let Some(ref d) = p.default {
                    pt.set("default", d.clone())?;
                }
                tbl.set(i + 1, pt)?;
            }
            Ok(tbl)
        });
        methods.add_method("getReturns", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, r) in this.0.returns.iter().enumerate() {
                let rt = lua.create_table()?;
                rt.set("type", r.type_name.clone())?;
                rt.set("description", r.description.clone())?;
                tbl.set(i + 1, rt)?;
            }
            Ok(tbl)
        });
        methods.add_method("getExample", |_, this, ()| Ok(this.0.example.clone()));
        methods.add_method("getSince", |_, this, ()| Ok(this.0.since.clone()));
        methods.add_method("getDeprecated", |_, this, ()| Ok(this.0.deprecated.clone()));
        methods.add_method("getScore", |_, this, ()| Ok(docs::quality_score(&this.0)));
        methods.add_method("hasDescription", |_, this, ()| {
            Ok(!this.0.description.is_empty())
        });
        methods.add_method("hasParameters", |_, this, ()| {
            Ok(!this.0.parameters.is_empty())
        });
        methods.add_method("hasReturnType", |_, this, ()| {
            Ok(!this.0.returns.is_empty())
        });
        methods.add_method("hasExample", |_, this, ()| Ok(this.0.example.is_some()));
        methods.add_method("type", |_, _, ()| Ok("LDocEntry"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LDocEntry" || name == "Object")
        });
    }
}
#[derive(Clone)]
struct ApiCatalog(Vec<docs::DocEntry>);
impl ApiCatalog {
    fn modules(&self) -> Vec<String> {
        let mut mods: Vec<String> = self
            .0
            .iter()
            .map(|e| e.module.clone())
            .collect::<std::collections::HashSet<_>>()
            .into_iter()
            .collect();
        mods.sort();
        mods
    }
    fn entries_for_module(&self, module: &str) -> Vec<&docs::DocEntry> {
        self.0.iter().filter(|e| e.module == module).collect()
    }
    fn get_entry(&self, qualified_name: &str) -> Option<&docs::DocEntry> {
        self.0.iter().find(|e| e.qualified_name == qualified_name)
    }
}
impl LuaUserData for ApiCatalog {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getModules", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, m) in this.modules().iter().enumerate() {
                tbl.set(i + 1, m.clone())?;
            }
            Ok(tbl)
        });
        methods.add_method("getEntries", |lua, this, module: Option<String>| {
            let tbl = lua.create_table()?;
            let entries: Vec<&docs::DocEntry> = match module.as_deref() {
                Some(m) => this.entries_for_module(m),
                None => this.0.iter().collect(),
            };
            for (i, e) in entries.iter().enumerate() {
                tbl.set(i + 1, DocEntry((*e).clone()))?;
            }
            Ok(tbl)
        });
        methods.add_method("getEntry", |_, this, qualified_name: String| {
            Ok(this.get_entry(&qualified_name).map(|e| DocEntry(e.clone())))
        });
        methods.add_method("getTypes", |lua, this, module_name: String| {
            let tbl = lua.create_table()?;
            let mut idx = 1;
            for e in &this.0 {
                if e.module == module_name && e.kind == "type" {
                    tbl.set(idx, e.name.clone())?;
                    idx += 1;
                }
            }
            Ok(tbl)
        });
        methods.add_method("getTypeMethods", |lua, this, qualified_name: String| {
            let tbl = lua.create_table()?;
            let prefix = format!("{}:", qualified_name);
            let mut idx = 1;
            for e in &this.0 {
                if e.qualified_name.starts_with(&prefix)
                    || (e.kind == "method" && e.qualified_name.starts_with(&qualified_name))
                {
                    tbl.set(idx, DocEntry(e.clone()))?;
                    idx += 1;
                }
            }
            Ok(tbl)
        });
        methods.add_method("entryCount", |_, this, module: Option<String>| {
            Ok(match module.as_deref() {
                Some(m) => this.0.iter().filter(|e| e.module == m).count(),
                None => this.0.len(),
            })
        });
        methods.add_method("merge", |_, this, other: LuaAnyUserData| {
            let other = other.borrow::<ApiCatalog>()?;
            let mut merged = this.0.clone();
            for e in &other.0 {
                if let Some(existing) = merged
                    .iter_mut()
                    .find(|x| x.qualified_name == e.qualified_name)
                {
                    *existing = e.clone();
                } else {
                    merged.push(e.clone());
                }
            }
            Ok(ApiCatalog(merged))
        });
        methods.add_method("filter", |_lua, this, predicate: LuaFunction| {
            let mut filtered = Vec::new();
            for e in &this.0 {
                let entry = DocEntry(e.clone());
                let keep: bool = predicate.call(entry)?;
                if keep {
                    filtered.push(e.clone());
                }
            }
            Ok(ApiCatalog(filtered))
        });
        methods.add_method("search", |lua, this, query: String| {
            let query_lower = query.to_lowercase();
            let tbl = lua.create_table()?;
            let mut idx = 1;
            for e in &this.0 {
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
        methods.add_method("toTable", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, e) in this.0.iter().enumerate() {
                let et = lua.create_table()?;
                et.set("name", e.name.clone())?;
                et.set("qualifiedName", e.qualified_name.clone())?;
                et.set("module", e.module.clone())?;
                et.set("kind", e.kind.clone())?;
                et.set("description", e.description.clone())?;
                et.set("score", docs::quality_score(e))?;
                tbl.set(i + 1, et)?;
            }
            Ok(tbl)
        });
        methods.add_method("toJSON", |_, this, ()| {
            let mut entries = Vec::new();
            for e in &this.0 {
                let mut map = serde_json::Map::new();
                map.insert("name".into(), serde_json::json!(e.name));
                map.insert("qualifiedName".into(), serde_json::json!(e.qualified_name));
                map.insert("module".into(), serde_json::json!(e.module));
                map.insert("kind".into(), serde_json::json!(e.kind));
                map.insert("description".into(), serde_json::json!(e.description));
                map.insert("score".into(), serde_json::json!(docs::quality_score(e)));
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
        methods.add_method("type", |_, _, ()| Ok("LApiCatalog"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LApiCatalog" || name == "Object")
        });
    }
}
struct ValidationReport(docs::ValidationReport);
impl LuaUserData for ValidationReport {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("isValid", |_, this, ()| Ok(this.0.missing.is_empty()));
        methods.add_method("getMissing", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, m) in this.0.missing.iter().enumerate() {
                tbl.set(i + 1, m.clone())?;
            }
            Ok(tbl)
        });
        methods.add_method("getPhantom", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, p) in this.0.phantom.iter().enumerate() {
                tbl.set(i + 1, p.clone())?;
            }
            Ok(tbl)
        });
        methods.add_method("getIncomplete", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (i, inc) in this.0.incomplete.iter().enumerate() {
                tbl.set(i + 1, inc.clone())?;
            }
            Ok(tbl)
        });
        methods.add_method("missingCount", |_, this, ()| Ok(this.0.missing.len()));
        methods.add_method("phantomCount", |_, this, ()| Ok(this.0.phantom.len()));
        methods.add_method("incompleteCount", |_, this, ()| Ok(this.0.incomplete.len()));
        methods.add_method("getSummary", |_, this, ()| {
            Ok(format!(
                "Missing: {}, Phantom: {}, Incomplete: {}",
                this.0.missing.len(),
                this.0.phantom.len(),
                this.0.incomplete.len()
            ))
        });
        methods.add_method("toTable", |lua, this, ()| {
            let tbl = lua.create_table()?;
            let missing = lua.create_table()?;
            for (i, m) in this.0.missing.iter().enumerate() {
                missing.set(i + 1, m.clone())?;
            }
            tbl.set("missing", missing)?;
            let phantom = lua.create_table()?;
            for (i, p) in this.0.phantom.iter().enumerate() {
                phantom.set(i + 1, p.clone())?;
            }
            tbl.set("phantom", phantom)?;
            let incomplete = lua.create_table()?;
            for (i, inc) in this.0.incomplete.iter().enumerate() {
                incomplete.set(i + 1, inc.clone())?;
            }
            tbl.set("incomplete", incomplete)?;
            Ok(tbl)
        });
        methods.add_method("toJSON", |_, this, ()| {
            let val = serde_json::json!({
                "missing": this.0.missing,
                "phantom": this.0.phantom,
                "incomplete": this.0.incomplete,
                "isValid": this.0.missing.is_empty()
            });
            Ok(serde_json::to_string_pretty(&val).unwrap_or_default())
        });
        methods.add_method("type", |_, _, ()| Ok("LValidationReport"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LValidationReport" || name == "Object")
        });
    }
}
struct QualityReport(docs::QualityReport);
impl LuaUserData for QualityReport {
    fn add_methods<'lua, M: LuaUserDataMethods<'lua, Self>>(methods: &mut M) {
        methods.add_method("getOverallScore", |_, this, ()| Ok(this.0.overall_score));
        methods.add_method("getGrade", |_, this, ()| {
            Ok(docs::quality_grade(this.0.overall_score).to_string())
        });
        methods.add_method("getModuleScores", |lua, this, ()| {
            let tbl = lua.create_table()?;
            for (k, v) in &this.0.module_scores {
                tbl.set(k.clone(), *v)?;
            }
            Ok(tbl)
        });
        methods.add_method("getWorst", |lua, this, count: Option<usize>| {
            let n = count.unwrap_or(10);
            let mut sorted = this.0.entries.clone();
            sorted.sort_by(|a, b| {
                docs::quality_score(a)
                    .partial_cmp(&docs::quality_score(b))
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            let tbl = lua.create_table()?;
            for (i, e) in sorted.iter().take(n).enumerate() {
                tbl.set(i + 1, DocEntry(e.clone()))?;
            }
            Ok(tbl)
        });
        methods.add_method("getBest", |lua, this, count: Option<usize>| {
            let n = count.unwrap_or(10);
            let mut sorted = this.0.entries.clone();
            sorted.sort_by(|a, b| {
                docs::quality_score(b)
                    .partial_cmp(&docs::quality_score(a))
                    .unwrap_or(std::cmp::Ordering::Equal)
            });
            let tbl = lua.create_table()?;
            for (i, e) in sorted.iter().take(n).enumerate() {
                tbl.set(i + 1, DocEntry(e.clone()))?;
            }
            Ok(tbl)
        });
        methods.add_method("getByGrade", |lua, this, grade: String| {
            let tbl = lua.create_table()?;
            let mut idx = 1;
            for e in &this.0.entries {
                if docs::quality_grade(docs::quality_score(e)) == grade {
                    tbl.set(idx, DocEntry(e.clone()))?;
                    idx += 1;
                }
            }
            Ok(tbl)
        });
        methods.add_method("getSummary", |_, this, ()| {
            let mut lines = vec![format!(
                "Overall: {} ({:.0}%)",
                docs::quality_grade(this.0.overall_score),
                this.0.overall_score * 100.0
            )];
            let mut mods: Vec<(&String, &f64)> = this.0.module_scores.iter().collect();
            mods.sort_by_key(|(k, _)| *k);
            for (m, s) in mods {
                lines.push(format!("  {}: {:.0}%", m, s * 100.0));
            }
            Ok(lines.join("\n"))
        });
        methods.add_method("toTable", |lua, this, ()| {
            let tbl = lua.create_table()?;
            tbl.set("overallScore", this.0.overall_score)?;
            tbl.set("grade", docs::quality_grade(this.0.overall_score))?;
            let mods = lua.create_table()?;
            for (k, v) in &this.0.module_scores {
                mods.set(k.clone(), *v)?;
            }
            tbl.set("moduleScores", mods)?;
            Ok(tbl)
        });
        methods.add_method("toJSON", |_, this, ()| {
            let val = serde_json::json!({
                "overallScore": this.0.overall_score,
                "grade": docs::quality_grade(this.0.overall_score),
                "moduleScores": this.0.module_scores
            });
            Ok(serde_json::to_string_pretty(&val).unwrap_or_default())
        });
        methods.add_method("type", |_, _, ()| Ok("LQualityReport"));
        methods.add_method("typeOf", |_, _, name: String| {
            Ok(name == "LQualityReport" || name == "Object")
        });
    }
}
struct DocsState {
    entries: Vec<docs::DocEntry>,
}
impl DocsState {
    fn new() -> Self {
        Self {
            entries: Vec::new(),
        }
    }
}
fn compute_quality(entries: &[docs::DocEntry]) -> QualityReport {
    QualityReport(docs::QualityReport::from_entries(entries))
}
#[allow(clippy::only_used_in_recursion)]
fn scan_table(
    lua: &Lua,
    table: &LuaTable,
    prefix: &str,
    module_name: &str,
    entries: &mut Vec<docs::DocEntry>,
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
                entries.push(docs::DocEntry {
                    name: key,
                    qualified_name: qualified,
                    module: module_name.to_string(),
                    kind: "function".to_string(),
                    ..Default::default()
                });
            }
            LuaValue::Table(sub) => {
                scan_table(lua, sub, &qualified, &key, entries, depth + 1)?;
            }
            _ => {}
        }
    }
    Ok(())
}
pub fn register(
    lua: &Lua,
    lurek_table: &LuaTable,
    _state: Rc<RefCell<SharedState>>,
) -> LuaResult<()> {
    let docs_tbl = lua.create_table()?;
    let state = Rc::new(RefCell::new(DocsState::new()));
    docs_tbl.set(
        "scan",
        lua.create_function(|lua, _opts: Option<LuaTable>| {
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("lurek")?;
            let mut entries = Vec::new();
            scan_table(lua, &luna_tbl, "lurek", "lurek", &mut entries, 0)?;
            Ok(ApiCatalog(entries))
        })?,
    )?;
    docs_tbl.set(
        "scanModule",
        lua.create_function(|lua, module_name: String| {
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("lurek")?;
            let sub: LuaTable = luna_tbl.get(module_name.clone())?;
            let prefix = format!("lurek.{}", module_name);
            let mut entries = Vec::new();
            scan_table(lua, &sub, &prefix, &module_name, &mut entries, 0)?;
            Ok(ApiCatalog(entries))
        })?,
    )?;
    docs_tbl.set(
        "loadToml",
        lua.create_function(|lua, path: String| {
            let content = std::fs::read_to_string(&path)
                .map_err(|e| LuaError::RuntimeError(format!("failed to read {}: {}", path, e)))?;
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("lurek")?;
            let data_tbl: LuaTable = luna_tbl.get("data")?;
            let parse_fn: LuaFunction = data_tbl.get("parseToml")?;
            let parsed: LuaTable = parse_fn.call(content)?;
            let mut entries = Vec::new();
            if let Ok(api_entries) = parsed.get::<_, LuaTable>("entries") {
                for (_, et) in api_entries.pairs::<i64, LuaTable>().flatten() {
                    entries.push(docs::DocEntry {
                        name: et.get("name").unwrap_or_default(),
                        qualified_name: et.get("qualifiedName").unwrap_or_default(),
                        module: et.get("module").unwrap_or_default(),
                        kind: et.get("kind").unwrap_or_else(|_| "function".into()),
                        description: et.get("description").unwrap_or_default(),
                        example: et.get("example").ok(),
                        since: et.get("since").ok(),
                        deprecated: et.get("deprecated").ok(),
                        ..Default::default()
                    });
                }
            }
            Ok(ApiCatalog(entries))
        })?,
    )?;
    docs_tbl.set(
        "loadAll",
        lua.create_function(|lua, directory: String| {
            let mut all_entries = Vec::new();
            if let Ok(read_dir) = std::fs::read_dir(&directory) {
                for item in read_dir.flatten() {
                    let path = item.path();
                    if path.extension().is_some_and(|e| e == "toml") {
                        if let Ok(content) = std::fs::read_to_string(&path) {
                            let globals = lua.globals();
                            let luna_tbl: LuaTable = globals.get("lurek")?;
                            let data_tbl: LuaTable = luna_tbl.get("data")?;
                            let parse_fn: LuaFunction = data_tbl.get("parseToml")?;
                            if let Ok(parsed) = parse_fn.call::<_, LuaTable>(content) {
                                if let Ok(api_entries) = parsed.get::<_, LuaTable>("entries") {
                                    for (_, et) in api_entries.pairs::<i64, LuaTable>().flatten() {
                                        all_entries.push(docs::DocEntry {
                                            name: et.get("name").unwrap_or_default(),
                                            qualified_name: et
                                                .get("qualifiedName")
                                                .unwrap_or_default(),
                                            module: et.get("module").unwrap_or_default(),
                                            kind: et
                                                .get("kind")
                                                .unwrap_or_else(|_| "function".into()),
                                            description: et.get("description").unwrap_or_default(),
                                            example: et.get("example").ok(),
                                            since: et.get("since").ok(),
                                            deprecated: et.get("deprecated").ok(),
                                            ..Default::default()
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Ok(ApiCatalog(all_entries))
        })?,
    )?;
    let s = state.clone();
    docs_tbl.set(
        "describe",
        lua.create_function(move |_, (qualified_name, description): (String, String)| {
            let mut st = s.borrow_mut();
            if let Some(entry) = st
                .entries
                .iter_mut()
                .find(|e| e.qualified_name == qualified_name)
            {
                entry.description = description;
            } else {
                let parts: Vec<&str> = qualified_name.rsplitn(2, '.').collect();
                let name = parts[0].to_string();
                let module = if parts.len() > 1 {
                    parts[1].to_string()
                } else {
                    String::new()
                };
                st.entries.push(docs::DocEntry {
                    name,
                    qualified_name,
                    module,
                    kind: "function".to_string(),
                    description,
                    ..Default::default()
                });
            }
            Ok(())
        })?,
    )?;
    let s = state.clone();
    docs_tbl.set(
        "setParamInfo",
        lua.create_function(move |_, (qualified_name, params): (String, LuaTable)| {
            let mut st = s.borrow_mut();
            let mut param_list = Vec::new();
            for (_, pt) in params.pairs::<i64, LuaTable>().flatten() {
                param_list.push(docs::ParamInfo {
                    name: pt.get("name").unwrap_or_default(),
                    type_name: pt.get("type").unwrap_or_default(),
                    description: pt.get("description").unwrap_or_default(),
                    optional: pt.get("optional").unwrap_or(false),
                    default: pt.get("default").ok(),
                });
            }
            if let Some(entry) = st
                .entries
                .iter_mut()
                .find(|e| e.qualified_name == qualified_name)
            {
                entry.parameters = param_list;
            }
            Ok(())
        })?,
    )?;
    let s = state.clone();
    docs_tbl.set(
        "setReturnInfo",
        lua.create_function(move |_, (qualified_name, returns): (String, LuaTable)| {
            let mut st = s.borrow_mut();
            let mut return_list = Vec::new();
            for (_, rt) in returns.pairs::<i64, LuaTable>().flatten() {
                return_list.push(docs::ReturnInfo {
                    type_name: rt.get("type").unwrap_or_default(),
                    description: rt.get("description").unwrap_or_default(),
                });
            }
            if let Some(entry) = st
                .entries
                .iter_mut()
                .find(|e| e.qualified_name == qualified_name)
            {
                entry.returns = return_list;
            }
            Ok(())
        })?,
    )?;
    let s = state.clone();
    docs_tbl.set(
        "getCatalog",
        lua.create_function(move |_, ()| Ok(ApiCatalog(s.borrow().entries.clone())))?,
    )?;
    let s = state.clone();
    docs_tbl.set(
        "resetCatalog",
        lua.create_function(move |_, ()| {
            s.borrow_mut().entries.clear();
            Ok(())
        })?,
    )?;
    docs_tbl.set(
        "validate",
        lua.create_function(|lua, catalog_ud: Option<LuaAnyUserData>| {
            let doc_entries = catalog_ud
                .map(|ud| ud.borrow::<ApiCatalog>().map(|c| c.0.clone()))
                .transpose()?
                .unwrap_or_default();
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("lurek")?;
            let mut live_entries = Vec::new();
            scan_table(lua, &luna_tbl, "lurek", "lurek", &mut live_entries, 0)?;
            let live_names: std::collections::HashSet<String> = live_entries
                .iter()
                .map(|e| e.qualified_name.clone())
                .collect();
            let doc_names: std::collections::HashSet<String> = doc_entries
                .iter()
                .map(|e| e.qualified_name.clone())
                .collect();
            let mut missing: Vec<String> = live_names.difference(&doc_names).cloned().collect();
            missing.sort();
            let mut phantom: Vec<String> = doc_names.difference(&live_names).cloned().collect();
            phantom.sort();
            let mut incomplete: Vec<String> = doc_entries
                .iter()
                .filter(|e| {
                    e.description.is_empty()
                        || (e.kind != "value" && e.parameters.is_empty() && e.returns.is_empty())
                })
                .map(|e| e.qualified_name.clone())
                .collect();
            incomplete.sort();
            Ok(ValidationReport(docs::ValidationReport {
                missing,
                phantom,
                incomplete,
            }))
        })?,
    )?;
    docs_tbl.set(
        "validateModule",
        lua.create_function(
            |lua, (module_name, catalog_ud): (String, Option<LuaAnyUserData>)| {
                let doc_entries = catalog_ud
                    .map(|ud| ud.borrow::<ApiCatalog>().map(|c| c.0.clone()))
                    .transpose()?
                    .unwrap_or_default();
                let globals = lua.globals();
                let luna_tbl: LuaTable = globals.get("lurek")?;
                let sub: LuaTable = luna_tbl.get(module_name.clone())?;
                let prefix = format!("lurek.{}", module_name);
                let mut live_entries = Vec::new();
                scan_table(lua, &sub, &prefix, &module_name, &mut live_entries, 0)?;
                let live_names: std::collections::HashSet<String> = live_entries
                    .iter()
                    .map(|e| e.qualified_name.clone())
                    .collect();
                let doc_names: std::collections::HashSet<String> = doc_entries
                    .iter()
                    .filter(|e| e.module == module_name)
                    .map(|e| e.qualified_name.clone())
                    .collect();
                let mut missing: Vec<String> = live_names.difference(&doc_names).cloned().collect();
                missing.sort();
                let mut phantom: Vec<String> = doc_names.difference(&live_names).cloned().collect();
                phantom.sort();
                let mut incomplete: Vec<String> = doc_entries
                    .iter()
                    .filter(|e| e.module == module_name)
                    .filter(|e| {
                        e.description.is_empty()
                            || (e.kind != "value"
                                && e.parameters.is_empty()
                                && e.returns.is_empty())
                    })
                    .map(|e| e.qualified_name.clone())
                    .collect();
                incomplete.sort();
                Ok(ValidationReport(docs::ValidationReport {
                    missing,
                    phantom,
                    incomplete,
                }))
            },
        )?,
    )?;
    docs_tbl.set(
        "checkStaleness",
        lua.create_function(|lua, (_catalog_ud, source_dir): (LuaAnyUserData, String)| {
            let tbl = lua.create_table()?;
            let stale = lua.create_table()?;
            let current = lua.create_table()?;
            let missing_tbl = lua.create_table()?;
            if let Ok(read_dir) = std::fs::read_dir(&source_dir) {
                let mut idx = 1;
                for item in read_dir.flatten() {
                    let path = item.path();
                    if path.extension().is_some_and(|e| e == "rs" || e == "lua") {
                        current.set(idx, path.to_string_lossy().to_string())?;
                        idx += 1;
                    }
                }
            }
            tbl.set("stale", stale)?;
            tbl.set("current", current)?;
            tbl.set("missing", missing_tbl)?;
            Ok(tbl)
        })?,
    )?;
    let s = state.clone();
    docs_tbl.set(
        "quality",
        lua.create_function(move |_, catalog_ud: Option<LuaAnyUserData>| {
            let entries = match catalog_ud {
                Some(ud) => ud.borrow::<ApiCatalog>()?.0.clone(),
                None => s.borrow().entries.clone(),
            };
            Ok(compute_quality(&entries))
        })?,
    )?;
    let s = state.clone();
    docs_tbl.set(
        "qualityModule",
        lua.create_function(
            move |_, (module_name, catalog_ud): (String, Option<LuaAnyUserData>)| {
                let all = match catalog_ud {
                    Some(ud) => ud.borrow::<ApiCatalog>()?.0.clone(),
                    None => s.borrow().entries.clone(),
                };
                let filtered: Vec<docs::DocEntry> = all
                    .into_iter()
                    .filter(|e| e.module == module_name)
                    .collect();
                Ok(compute_quality(&filtered))
            },
        )?,
    )?;
    docs_tbl.set(
        "coverage",
        lua.create_function(|lua, catalog_ud: Option<LuaAnyUserData>| {
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("lurek")?;
            let mut live = Vec::new();
            scan_table(lua, &luna_tbl, "lurek", "lurek", &mut live, 0)?;
            let total = live.len();
            let documented = match catalog_ud {
                Some(ud) => ud.borrow::<ApiCatalog>()?.0.len(),
                None => 0,
            };
            Ok((documented, total))
        })?,
    )?;
    docs_tbl.set(
        "coverageModule",
        lua.create_function(
            |lua, (module_name, catalog_ud): (String, Option<LuaAnyUserData>)| {
                let globals = lua.globals();
                let luna_tbl: LuaTable = globals.get("lurek")?;
                let sub: LuaTable = luna_tbl.get(module_name.clone())?;
                let prefix = format!("lurek.{}", module_name);
                let mut live = Vec::new();
                scan_table(lua, &sub, &prefix, &module_name, &mut live, 0)?;
                let total = live.len();
                let documented = match catalog_ud {
                    Some(ud) => ud
                        .borrow::<ApiCatalog>()?
                        .0
                        .iter()
                        .filter(|e| e.module == module_name)
                        .count(),
                    None => 0,
                };
                Ok((documented, total))
            },
        )?,
    )?;
    docs_tbl.set(
        "exportCompletions",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            docs::export_completions(&catalog.0, &path).map_err(LuaError::RuntimeError)
        })?,
    )?;
    docs_tbl.set(
        "exportHover",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            docs::export_hover(&catalog.0, &path).map_err(LuaError::RuntimeError)
        })?,
    )?;
    docs_tbl.set(
        "exportSignatures",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            docs::export_signatures(&catalog.0, &path).map_err(LuaError::RuntimeError)
        })?,
    )?;
    docs_tbl.set(
        "exportAll",
        lua.create_function(|_, (catalog_ud, output_dir): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            docs::export_all(&catalog.0, &output_dir).map_err(LuaError::RuntimeError)
        })?,
    )?;
    docs_tbl.set(
        "exportMarkdown",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            let mut md = String::from("# API Reference\n\n");
            let mods = catalog.modules();
            for module in &mods {
                md.push_str(&format!("## {}\n\n", module));
                for e in catalog.entries_for_module(module) {
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
                                if p.optional { " -- optional" } else { "" }
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
    docs_tbl.set(
        "exportCheatsheet",
        lua.create_function(|_, (catalog_ud, path): (LuaAnyUserData, String)| {
            let catalog = catalog_ud.borrow::<ApiCatalog>()?;
            let mut lines = Vec::new();
            let mods = catalog.modules();
            for module in &mods {
                lines.push(format!("# {}", module));
                for e in catalog.entries_for_module(module) {
                    let param_names: Vec<String> =
                        e.parameters.iter().map(|p| p.name.clone()).collect();
                    let sig = if param_names.is_empty() {
                        format!("{}()", e.qualified_name)
                    } else {
                        format!("{}({})", e.qualified_name, param_names.join(", "))
                    };
                    let desc = if e.description.is_empty() {
                        String::new()
                    } else {
                        format!(" -- {}", e.description)
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
    docs_tbl.set(
        "schema",
        lua.create_function(|_, (rules, name): (LuaTable, Option<String>)| {
            use crate::docs::{FieldRule, FieldType, Schema};
            let schema_name = name.unwrap_or_else(|| "schema".to_string());
            let mut schema = Schema::new(&schema_name);
            let strict: bool = rules.get("__strict").unwrap_or(false);
            schema.strict = strict;
            for pair in rules.clone().pairs::<String, LuaValue>() {
                let (field, rule_val) = pair?;
                if field.starts_with('_') {
                    continue;
                }
                let mut rule = FieldRule::default();
                if let LuaValue::Table(rt) = rule_val {
                    let type_str: String = rt.get("type").unwrap_or_else(|_| "any".to_string());
                    rule.field_type = FieldType::from_str(&type_str);
                    rule.required = rt.get("required").unwrap_or(false);
                    rule.min = rt.get::<_, f64>("min").ok();
                    rule.max = rt.get::<_, f64>("max").ok();
                    rule.min_len = rt.get::<_, usize>("minLen").ok();
                    rule.max_len = rt.get::<_, usize>("maxLen").ok();
                    rule.description = rt.get("description").unwrap_or_default();
                    if let Ok(enum_tbl) = rt.get::<_, LuaTable>("enum") {
                        for v in enum_tbl.clone().sequence_values::<String>().flatten() {
                            rule.enum_values.push(v);
                        }
                    }
                } else if let LuaValue::String(s) = rule_val {
                    rule.field_type = FieldType::from_str(s.to_str().unwrap_or("any"));
                }
                schema.add_rule(&field, rule);
            }
            Ok(LuaSchema(schema))
        })?,
    )?;
    docs_tbl.set(
        "schemaFromToml",
        lua.create_function(|_, toml_text: String| {
            let schema = docs::Schema::from_toml(&toml_text).map_err(LuaError::RuntimeError)?;
            Ok(LuaSchema(schema))
        })?,
    )?;
    docs_tbl.set(
        "reflectLive",
        lua.create_function(|lua, ns: Option<String>| {
            let globals = lua.globals();
            let luna_tbl: LuaTable = globals.get("lurek")?;
            let result = lua.create_table()?;
            fn reflect_sub<'a>(lua: &'a Lua, tbl: LuaTable<'a>) -> LuaResult<LuaTable<'a>> {
                let items = lua.create_table()?;
                let mut idx = 1usize;
                for pair in tbl.pairs::<String, LuaValue>() {
                    let (key, val) = pair?;
                    let item = lua.create_table()?;
                    item.set("name", key.clone())?;
                    let type_name = match &val {
                        LuaValue::Function(_) => "function",
                        LuaValue::Table(_) => "table",
                        LuaValue::Boolean(_) => "boolean",
                        LuaValue::Integer(_) => "integer",
                        LuaValue::Number(_) => "number",
                        LuaValue::String(_) => "string",
                        LuaValue::UserData(_) => "userdata",
                        _ => "other",
                    };
                    item.set("type", type_name)?;
                    items.set(idx, item)?;
                    idx += 1;
                }
                Ok(items)
            }
            match ns {
                Some(ref ns_name) => {
                    if let Ok(sub) = luna_tbl.get::<_, LuaTable>(ns_name.clone()) {
                        let items = reflect_sub(lua, sub)?;
                        result.set(ns_name.clone(), items)?;
                    }
                }
                None => {
                    for pair in luna_tbl.pairs::<String, LuaValue>() {
                        let (key, val) = pair?;
                        if let LuaValue::Table(sub) = val {
                            let items = reflect_sub(lua, sub)?;
                            result.set(key, items)?;
                        }
                    }
                }
            }
            Ok(result)
        })?,
    )?;
    docs_tbl.set(
        "reflectTable",
        lua.create_function(|lua, (tbl, name): (LuaTable, Option<String>)| {
            let prefix = name.unwrap_or_default();
            let items = lua.create_table()?;
            let mut idx = 1usize;
            for pair in tbl.clone().pairs::<LuaValue, LuaValue>() {
                let (k, v) = pair?;
                let key_str = match &k {
                    LuaValue::String(s) => s.to_str().unwrap_or("?").to_string(),
                    LuaValue::Integer(n) => n.to_string(),
                    LuaValue::Number(n) => n.to_string(),
                    _ => "(other)".to_string(),
                };
                let qualified = if prefix.is_empty() {
                    key_str.clone()
                } else {
                    format!("{}.{}", prefix, key_str)
                };
                let item = lua.create_table()?;
                item.set("name", key_str)?;
                item.set("qualifiedName", qualified)?;
                match &v {
                    LuaValue::Function(_) => {
                        item.set("type", "function")?;
                    }
                    LuaValue::Table(_) => {
                        item.set("type", "table")?;
                    }
                    LuaValue::Boolean(_) => {
                        item.set("type", "boolean")?;
                    }
                    LuaValue::Integer(_) => {
                        item.set("type", "integer")?;
                    }
                    LuaValue::Number(_) => {
                        item.set("type", "number")?;
                    }
                    LuaValue::String(_) => {
                        item.set("type", "string")?;
                    }
                    LuaValue::UserData(_) => {
                        item.set("type", "userdata")?;
                    }
                    LuaValue::Nil => {
                        item.set("type", "nil")?;
                    }
                    _ => {
                        item.set("type", "other")?;
                    }
                }
                items.set(idx, item)?;
                idx += 1;
            }
            Ok(items)
        })?,
    )?;
    lurek_table.set("docs", docs_tbl)?;
    Ok(())
}
