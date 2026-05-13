use super::lua_table::SerialValue;
use indexmap::IndexMap;
pub fn from_ini(s: &str) -> Result<SerialValue, String> {
    let mut root: IndexMap<String, SerialValue> = IndexMap::new();
    let mut sections: IndexMap<String, IndexMap<String, SerialValue>> = IndexMap::new();
    let mut current_section: Option<String> = None;
    for (line_no, raw_line) in s.lines().enumerate() {
        let line = raw_line.trim();
        if line.is_empty() || line.starts_with(';') || line.starts_with('#') {
            continue;
        }
        if line.starts_with('[') && line.ends_with(']') {
            let section = line[1..line.len() - 1].trim();
            if section.is_empty() {
                return Err(format!(
                    "INI parse error at line {}: empty section name",
                    line_no + 1
                ));
            }
            current_section = Some(section.to_string());
            sections.entry(section.to_string()).or_default();
            continue;
        }
        let Some((k, v)) = line.split_once('=') else {
            return Err(format!(
                "INI parse error at line {}: expected key=value",
                line_no + 1
            ));
        };
        let key = k.trim();
        if key.is_empty() {
            return Err(format!(
                "INI parse error at line {}: empty key",
                line_no + 1
            ));
        }
        let value = SerialValue::Str(v.trim().to_string());
        if let Some(section) = current_section.as_ref() {
            sections
                .entry(section.clone())
                .or_default()
                .insert(key.to_string(), value);
        } else {
            root.insert(key.to_string(), value);
        }
    }
    for (section, map) in sections {
        root.insert(section, SerialValue::Map(map));
    }
    Ok(SerialValue::Map(root))
}
