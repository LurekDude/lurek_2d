use crate::html::element::{HtmlElement, HtmlElementId};
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Combinator {
    Descendant,
    Child,
}
#[derive(Clone, Debug, Default)]
struct SimpleSelector {
    tag: Option<String>,
    id: Option<String>,
    classes: Vec<String>,
}
#[derive(Clone, Debug)]
struct SelectorPart {
    selector: SimpleSelector,
    combinator: Option<Combinator>,
}
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
