use crate::html::element::normalise_name;
use std::collections::BTreeMap;
#[derive(Clone, Debug)]
pub(crate) struct CssRule {
    pub(crate) selector: String,
    pub(crate) declarations: BTreeMap<String, String>,
    pub(crate) order: usize,
}
#[derive(Clone, Debug, Default)]
pub(crate) struct CssParseResult {
    pub(crate) declarations: BTreeMap<String, String>,
    pub(crate) warnings: Vec<String>,
}
pub(crate) fn parse_stylesheets(sources: &[String]) -> (Vec<CssRule>, Vec<String>) {
    let mut rules = Vec::new();
    let mut warnings = Vec::new();
    for source in sources {
        for block in source.split('}') {
            let Some((selector, body)) = block.split_once('{') else {
                continue;
            };
            let selector = selector.trim();
            if selector.is_empty() {
                continue;
            }
            let parsed = parse_declarations(body);
            warnings.extend(parsed.warnings);
            if !parsed.declarations.is_empty() {
                rules.push(CssRule {
                    selector: selector.to_string(),
                    declarations: parsed.declarations,
                    order: rules.len(),
                });
            }
        }
    }
    (rules, warnings)
}
pub(crate) fn parse_declarations(source: &str) -> CssParseResult {
    let mut result = CssParseResult::default();
    for declaration in source.split(';') {
        let Some((property, value)) = declaration.split_once(':') else {
            continue;
        };
        let property = normalise_name(property);
        let value = value.trim();
        if property.is_empty() || value.is_empty() {
            continue;
        }
        if is_supported_property(&property) {
            result.declarations.insert(property, value.to_string());
        } else {
            result
                .warnings
                .push(format!("unsupported CSS property '{property}'"));
        }
    }
    result
}
pub(crate) fn parse_length(value: Option<&str>, basis: f32) -> Option<f32> {
    let value = value?.trim();
    if value == "0" {
        return Some(0.0);
    }
    if let Some(px) = value.strip_suffix("px") {
        return px.trim().parse::<f32>().ok();
    }
    if let Some(percent) = value.strip_suffix('%') {
        return percent
            .trim()
            .parse::<f32>()
            .ok()
            .map(|number| basis * number / 100.0);
    }
    value.parse::<f32>().ok()
}
fn is_supported_property(property: &str) -> bool {
    matches!(
        property,
        "display"
            | "position"
            | "left"
            | "top"
            | "right"
            | "bottom"
            | "width"
            | "height"
            | "min-width"
            | "min-height"
            | "max-width"
            | "max-height"
            | "margin"
            | "padding"
            | "gap"
            | "border-width"
            | "border-color"
            | "border-radius"
            | "background-color"
            | "color"
            | "font-size"
            | "line-height"
            | "text-align"
            | "flex-direction"
            | "justify-content"
            | "align-items"
            | "overflow"
            | "pointer-events"
    )
}
