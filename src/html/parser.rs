//! Minimal HTML parser — converts a UTF-8 HTML string into the element arena used
//! by [`super::document::HtmlDocument`].
//!
//! The parser is intentionally lenient: unrecognised attributes are stored verbatim,
//! unclosed tags are implicitly closed, and unknown entities are passed through as-is.
//! This matches browser-grade fault tolerance for game UI markup.

use std::collections::BTreeMap;

use crate::html::element::{HtmlElement, HtmlElementId};

pub(crate) fn parse_into(
    html: &str,
    elements: &mut Vec<HtmlElement>,
    parent: HtmlElementId,
    warnings: &mut Vec<String>,
) -> Vec<HtmlElementId> {
    let mut roots = Vec::new();
    let mut stack = vec![parent];
    let mut cursor = 0;
    while cursor < html.len() {
        let Some(relative_start) = html[cursor..].find('<') else {
            push_text(elements, *stack.last().unwrap_or(&parent), &html[cursor..]);
            break;
        };
        let start = cursor + relative_start;
        push_text(
            elements,
            *stack.last().unwrap_or(&parent),
            &html[cursor..start],
        );
        let Some(relative_end) = html[start..].find('>') else {
            warnings.push("unterminated HTML tag".to_string());
            break;
        };
        let end = start + relative_end;
        let raw_tag = html[start + 1..end].trim();
        cursor = end + 1;
        if raw_tag.is_empty() || raw_tag.starts_with('!') || raw_tag.starts_with('?') {
            continue;
        }
        if raw_tag.starts_with("!--") {
            continue;
        }
        if raw_tag.starts_with('/') {
            if stack.len() > 1 {
                stack.pop();
            }
            continue;
        }
        let self_closing = raw_tag.ends_with('/');
        let tag_body = raw_tag.trim_end_matches('/').trim();
        let (tag_name, attr_source) = split_tag(tag_body);
        if tag_name.is_empty() {
            continue;
        }
        let tag_name = tag_name.to_ascii_lowercase();
        let attrs = parse_attributes(attr_source);
        let current_parent = *stack.last().unwrap_or(&parent);
        if tag_name == "body" && current_parent == parent && elements[parent].tag_name() == "body" {
            apply_attributes(&mut elements[parent], attrs);
            if !self_closing {
                stack.push(parent);
            }
            continue;
        }
        let id = elements.len();
        let mut element = HtmlElement::new(id, tag_name, Some(current_parent));
        apply_attributes(&mut element, attrs);
        elements.push(element);
        elements[current_parent].children.push(id);
        if current_parent == parent {
            roots.push(id);
        }
        if !self_closing && !elements[id].is_void_tag() {
            stack.push(id);
        }
    }
    roots
}

fn split_tag(source: &str) -> (&str, &str) {
    let mut parts = source.splitn(2, char::is_whitespace);
    let tag = parts.next().unwrap_or_default();
    let attrs = parts.next().unwrap_or_default();
    (tag, attrs)
}

fn parse_attributes(source: &str) -> BTreeMap<String, String> {
    let mut attrs = BTreeMap::new();
    let bytes = source.as_bytes();
    let mut cursor = 0;
    while cursor < bytes.len() {
        while cursor < bytes.len() && bytes[cursor].is_ascii_whitespace() {
            cursor += 1;
        }
        let name_start = cursor;
        while cursor < bytes.len() && !bytes[cursor].is_ascii_whitespace() && bytes[cursor] != b'='
        {
            cursor += 1;
        }
        if name_start == cursor {
            break;
        }
        let name = source[name_start..cursor].to_ascii_lowercase();
        while cursor < bytes.len() && bytes[cursor].is_ascii_whitespace() {
            cursor += 1;
        }
        let value = if cursor < bytes.len() && bytes[cursor] == b'=' {
            cursor += 1;
            while cursor < bytes.len() && bytes[cursor].is_ascii_whitespace() {
                cursor += 1;
            }
            if cursor < bytes.len() && (bytes[cursor] == b'\'' || bytes[cursor] == b'"') {
                let quote = bytes[cursor];
                cursor += 1;
                let value_start = cursor;
                while cursor < bytes.len() && bytes[cursor] != quote {
                    cursor += 1;
                }
                let value = decode_entities(&source[value_start..cursor]);
                if cursor < bytes.len() {
                    cursor += 1;
                }
                value
            } else {
                let value_start = cursor;
                while cursor < bytes.len() && !bytes[cursor].is_ascii_whitespace() {
                    cursor += 1;
                }
                decode_entities(&source[value_start..cursor])
            }
        } else {
            "true".to_string()
        };
        attrs.insert(name, value);
    }
    attrs
}

fn apply_attributes(element: &mut HtmlElement, attrs: BTreeMap<String, String>) {
    for (name, value) in attrs {
        element.set_attribute(&name, Some(value));
    }
}

fn push_text(elements: &mut [HtmlElement], element_id: HtmlElementId, text: &str) {
    let text = decode_entities(text);
    let collapsed = text.split_whitespace().collect::<Vec<_>>().join(" ");
    if collapsed.is_empty() {
        return;
    }
    let element = &mut elements[element_id];
    if !element.text.is_empty() {
        element.text.push(' ');
    }
    element.text.push_str(&collapsed);
}

pub(crate) fn escape_text(text: &str) -> String {
    text.replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
}

pub(crate) fn escape_attribute(text: &str) -> String {
    escape_text(text).replace('"', "&quot;")
}

fn decode_entities(text: &str) -> String {
    text.replace("&lt;", "<")
        .replace("&gt;", ">")
        .replace("&quot;", "\"")
        .replace("&#39;", "'")
        .replace("&amp;", "&")
}
