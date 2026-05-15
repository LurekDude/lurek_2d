//! - CSS selector matching for the HTML element tree.
//! - Parse selector strings into tag, id, class, and combinator fragments.
//! - Support descendant and child combinators for ancestor-chain traversal.
//! - Match parsed selector chains against live elements by walking parent links.
//! - Provide the core predicate used by style resolution and query APIs.

use crate::html::element::{HtmlElement, HtmlElementId};
/// Selector relationship used between adjacent selector parts.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Combinator {
    /// Match any ancestor chain between selector parts.
    Descendant,
    /// Match only the direct parent between selector parts.
    Child,
}
/// A selector fragment with optional tag, id, and class filters.
#[derive(Clone, Debug, Default)]
struct SimpleSelector {
    /// Optional tag name filter.
    tag: Option<String>,
    /// Optional id filter.
    id: Option<String>,
    /// Required class names for the fragment.
    classes: Vec<String>,
}
/// A parsed selector fragment and the relationship to its left neighbor.
#[derive(Clone, Debug)]
struct SelectorPart {
    /// Matching terms for this fragment.
    selector: SimpleSelector,
    /// Relationship to the next fragment toward the root.
    combinator: Option<Combinator>,
}
/// Return whether a selector matches an element in the provided tree.
pub(crate) fn matches_selector(
    elements: &[HtmlElement],
    element_id: HtmlElementId,
    selector: &str,
) -> bool {
    let parts = parse_selector(selector);
    if parts.is_empty() {
        return false;
    }
    matches_part_chain(elements, element_id, &parts, parts.len() - 1)
}
/// Match the selector chain from the current part back toward the root.
fn matches_part_chain(
    elements: &[HtmlElement],
    element_id: HtmlElementId,
    parts: &[SelectorPart],
    part_index: usize,
) -> bool {
    let Some(element) = elements.get(element_id) else {
        return false;
    };
    if element.is_removed() || !matches_simple(element, &parts[part_index].selector) {
        return false;
    }
    if part_index == 0 {
        return true;
    }
    match parts[part_index]
        .combinator
        .unwrap_or(Combinator::Descendant)
    {
        Combinator::Child => element
            .parent()
            .is_some_and(|parent| matches_part_chain(elements, parent, parts, part_index - 1)),
        Combinator::Descendant => {
            let mut parent = element.parent();
            while let Some(parent_id) = parent {
                if matches_part_chain(elements, parent_id, parts, part_index - 1) {
                    return true;
                }
                parent = elements.get(parent_id).and_then(HtmlElement::parent);
            }
            false
        }
    }
}
/// Check whether a simple selector matches a single element.
fn matches_simple(element: &HtmlElement, selector: &SimpleSelector) -> bool {
    if let Some(tag) = &selector.tag {
        if element.tag_name() != tag {
            return false;
        }
    }
    if let Some(id) = &selector.id {
        if element.id_attribute() != Some(id.as_str()) {
            return false;
        }
    }
    selector
        .classes
        .iter()
        .all(|class_name| element.has_class(class_name))
}
/// Parse a selector string into selector parts and combinators.
fn parse_selector(selector: &str) -> Vec<SelectorPart> {
    let mut parts = Vec::new();
    let mut token = String::new();
    let mut next_combinator = None;
    for ch in selector.chars() {
        match ch {
            '>' => {
                push_part(&mut parts, &mut token, next_combinator.take());
                next_combinator = Some(Combinator::Child);
            }
            ch if ch.is_whitespace() => {
                push_part(&mut parts, &mut token, next_combinator.take());
                if !parts.is_empty() {
                    next_combinator = Some(Combinator::Descendant);
                }
            }
            _ => token.push(ch),
        }
    }
    push_part(&mut parts, &mut token, next_combinator.take());
    if let Some(first) = parts.first_mut() {
        first.combinator = None;
    }
    parts
}
/// Push the current selector token into the part list when it is non-empty.
fn push_part(parts: &mut Vec<SelectorPart>, token: &mut String, combinator: Option<Combinator>) {
    let trimmed = token.trim();
    if !trimmed.is_empty() {
        parts.push(SelectorPart {
            selector: parse_simple(trimmed),
            combinator,
        });
    }
    token.clear();
}
/// Parse a simple selector token into tag, id, and class filters.
fn parse_simple(token: &str) -> SimpleSelector {
    let mut selector = SimpleSelector::default();
    let mut cursor = 0;
    let chars = token.char_indices().collect::<Vec<_>>();
    while cursor < chars.len() {
        let (byte_index, ch) = chars[cursor];
        let start = byte_index + ch.len_utf8();
        let end = chars
            .iter()
            .skip(cursor + 1)
            .find_map(|(idx, next)| (*next == '#' || *next == '.').then_some(*idx))
            .unwrap_or(token.len());
        match ch {
            '#' => selector.id = Some(token[start..end].to_string()),
            '.' => selector.classes.push(token[start..end].to_string()),
            _ => {
                let end = chars
                    .iter()
                    .skip(cursor)
                    .find_map(|(idx, next)| (*next == '#' || *next == '.').then_some(*idx))
                    .unwrap_or(token.len());
                selector.tag = Some(token[..end].to_ascii_lowercase());
            }
        }
        cursor = chars
            .iter()
            .position(|(idx, _)| *idx >= end)
            .unwrap_or(chars.len());
    }
    selector
}
