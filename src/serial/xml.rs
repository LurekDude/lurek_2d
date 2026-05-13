use super::lua_table::SerialValue;
use crate::log_msg;
use crate::runtime::log_messages::SR06_XML_OK;
use indexmap::IndexMap;
fn node_to_serial(node: roxmltree::Node) -> SerialValue {
    let mut map: IndexMap<String, SerialValue> = IndexMap::new();
    map.insert(
        "tag".to_string(),
        SerialValue::Str(node.tag_name().name().to_string()),
    );
    let attrs: IndexMap<String, SerialValue> = node
        .attributes()
        .map(|a| {
            (
                a.name().to_string(),
                SerialValue::Str(a.value().to_string()),
            )
        })
        .collect();
    if !attrs.is_empty() {
        map.insert("attrs".to_string(), SerialValue::Map(attrs));
    }
    let text: String = node
        .children()
        .filter(|n| n.is_text())
        .filter_map(|n| n.text())
        .collect::<Vec<_>>()
        .join("");
    let trimmed = text.trim();
    if !trimmed.is_empty() {
        map.insert("text".to_string(), SerialValue::Str(trimmed.to_string()));
    }
    let children: Vec<SerialValue> = node
        .children()
        .filter(|n| n.is_element())
        .map(node_to_serial)
        .collect();
    if !children.is_empty() {
        map.insert("children".to_string(), SerialValue::Seq(children));
    }
    SerialValue::Map(map)
}
pub fn decode(s: &str) -> Result<SerialValue, String> {
    let doc = roxmltree::Document::parse(s).map_err(|e| format!("XML parse error: {e}"))?;
    log_msg!(debug, SR06_XML_OK);
    Ok(node_to_serial(doc.root_element()))
}
