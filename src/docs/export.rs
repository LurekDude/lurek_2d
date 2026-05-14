use crate::docs::entry::DocEntry;
use std::collections::HashMap;
use std::fs::File;
use std::io::BufWriter;
use std::path::Path;
/// Map an entry kind to a completion item kind and return the resulting label.
fn completion_kind(kind: &str, include_enum: bool) -> &'static str {
    match kind {
        "function" | "method" => "Function",
        "type" => "Class",
        "enum" if include_enum => "Enum",
        _ => "Variable",
    }
}
/// Build completion payload rows and return them as JSON values.
fn build_completions(entries: &[DocEntry], include_enum: bool) -> Vec<serde_json::Value> {
    entries
        .iter()
        .map(|e| {
            serde_json::json!({
                "label": e.name,
                "kind": completion_kind(&e.kind, include_enum),
                "detail": e.qualified_name,
                "documentation": e.description
            })
        })
        .collect()
}
    /// Build hover payload data keyed by qualified name and return the map.
fn build_hover_map(entries: &[DocEntry], compact: bool) -> HashMap<String, serde_json::Value> {
    let mut hover: HashMap<String, serde_json::Value> = HashMap::new();
    for e in entries {
        let value = if compact {
            serde_json::json!({
                "name": e.qualified_name,
                "description": e.description,
                "kind": e.kind
            })
        } else {
            serde_json::json!({
                "name": e.qualified_name,
                "description": e.description,
                "kind": e.kind,
                "parameters": e.parameters.iter().map(|p| {
                    serde_json::json!({
                        "name": p.name,
                        "type": p.type_name,
                        "description": p.description
                    })
                }).collect::<Vec<_>>(),
                "returns": e.returns.iter().map(|r| {
                    serde_json::json!({
                        "type": r.type_name,
                        "description": r.description
                    })
                }).collect::<Vec<_>>()
            })
        };
        hover.insert(e.qualified_name.clone(), value);
    }
    hover
}
/// Build signature payload data keyed by qualified name and return the map.
fn build_signatures(entries: &[DocEntry], rich_labels: bool) -> HashMap<String, serde_json::Value> {
    let mut sigs: HashMap<String, serde_json::Value> = HashMap::new();
    for e in entries {
        if !e.parameters.is_empty() {
            let params: Vec<serde_json::Value> = e
                .parameters
                .iter()
                .map(|p| {
                    let label = if rich_labels {
                        if p.optional {
                            format!("{}?: {}", p.name, p.type_name)
                        } else {
                            format!("{}: {}", p.name, p.type_name)
                        }
                    } else {
                        p.name.clone()
                    };
                    serde_json::json!({
                        "label": label,
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
    sigs
}
/// Serialize one JSON value to a file path and return an error string on failure.
fn write_json_file<T: serde::Serialize>(path: impl AsRef<Path>, value: &T) -> Result<(), String> {
    let file = File::create(path.as_ref()).map_err(|e| format!("write error: {e}"))?;
    let mut writer = BufWriter::new(file);
    serde_json::to_writer_pretty(&mut writer, value).map_err(|e| format!("write error: {e}"))
}
/// Export completion payloads and return an error when writing fails.
pub fn export_completions(entries: &[DocEntry], path: &str) -> Result<(), String> {
    let completions = build_completions(entries, true);
    write_json_file(path, &completions)
}
/// Export hover payloads and return an error when writing fails.
pub fn export_hover(entries: &[DocEntry], path: &str) -> Result<(), String> {
    let hover = build_hover_map(entries, false);
    write_json_file(path, &hover)
}
/// Export signature payloads and return an error when writing fails.
pub fn export_signatures(entries: &[DocEntry], path: &str) -> Result<(), String> {
    let sigs = build_signatures(entries, true);
    write_json_file(path, &sigs)
}
/// Export all docs payload files into one directory and return an error on failure.
pub fn export_all(entries: &[DocEntry], output_dir: &str) -> Result<(), String> {
    std::fs::create_dir_all(output_dir).map_err(|e| format!("mkdir error: {}", e))?;
    let completions = build_completions(entries, false);
    let hover = build_hover_map(entries, true);
    let sigs = build_signatures(entries, false);
    write_json_file(format!("{}/completions.json", output_dir), &completions)?;
    write_json_file(format!("{}/hover.json", output_dir), &hover)?;
    write_json_file(format!("{}/signatures.json", output_dir), &sigs)?;
    Ok(())
}
