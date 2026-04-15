//! XML parsing for Lurek2D (read-only).
//!
//! Converts an XML string into a `SerialValue` tree using `roxmltree`.
//! Only decoding is supported — XML encoding is out of scope for the `serial` module.
//! No mlua imports — all Lua bridging lives in `src/lua_api/serial_api.rs`.

use super::lua_table::SerialValue;
use crate::log_msg;
use crate::runtime::log_messages::SR06_XML_OK;
use indexmap::IndexMap;

// ── Node conversion ───────────────────────────────────────────────────────────

/// Recursively convert a `roxmltree::Node` into a `SerialValue::Map`.
///
/// The resulting map has the following string keys:
/// - `"tag"` — element tag name (string).
/// - `"attrs"` — map of attribute name → value string (omitted when empty).
/// - `"text"` — concatenated direct text content (omitted when blank).
/// - `"children"` — sequence of child element maps (omitted when empty).
fn node_to_serial(node: roxmltree::Node) -> SerialValue {
    let mut map: IndexMap<String, SerialValue> = IndexMap::new();

    // tag name
    map.insert("tag".to_string(), SerialValue::Str(node.tag_name().name().to_string()));

    // attributes
    let attrs: IndexMap<String, SerialValue> = node
        .attributes()
        .map(|a| (a.name().to_string(), SerialValue::Str(a.value().to_string())))
        .collect();
    if !attrs.is_empty() {
        map.insert("attrs".to_string(), SerialValue::Map(attrs));
    }

    // direct text content (merged across adjacent text nodes)
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

    // child elements (non-text nodes only)
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

// ── Public API ────────────────────────────────────────────────────────────────

/// Parse an XML string into a `SerialValue` tree.
///
/// Returns the document root element as a `SerialValue::Map` with keys
/// `tag`, `attrs` (optional), `text` (optional), and `children` (optional).
///
/// # Parameters
/// - `s` — `&str`. XML text.
///
/// # Returns
/// `Result<SerialValue, String>`.
pub fn decode(s: &str) -> Result<SerialValue, String> {
    let doc = roxmltree::Document::parse(s)
        .map_err(|e| format!("XML parse error: {e}"))?;
    log_msg!(debug, SR06_XML_OK);
    Ok(node_to_serial(doc.root_element()))
}
